-- Raycaster Engine with Hardware Acceleration
-- Uses shaders for highly efficient rendering of the 3D environment
local assetManager = require("assets/assetManager")

-- Create a simple vector class for 2D operations (similar to HUMP library's vector)
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector:clone()
    return Vector.new(self.x, self.y)
end

function Vector:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector:normalize()
    local len = self:length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
    end
    return self
end

-- Define the raycaster module
local raycaster = {
    viewWidth = 1280,
    viewHeight = 720,
    fov = 60 * math.pi / 180, -- Convert to radians
    wallHeight = 1.0,
    maxDistance = 40,
    shadeDepth = 10, -- How far before walls are completely dark
    texturesEnabled = true,
    floorTexturesEnabled = true,
    entitiesEnabled = true,
    spriteVerticalOffset = 0.2, -- Vertical offset for sprites (higher values = lower position)
    
    -- Torch light effect parameters
    torchEnabled = false,
    torchIntensity = 0.9, -- Base intensity of the torch (0-1)
    torchRange = 5.0, -- How far the torch light reaches
    torchPulseSpeed = 1.0, -- Speed of torch light pulsation
    torchRedTint = 0.5, -- Amount of red tint in the torch light (0-1)
    globalDarkness = 0.6, -- Global darkness level (0-1, higher = darker)
    
    -- Camera properties
    camera = {
        x = 0,
        y = 0,
        angle = 0,
        tilt = 0,
        height = 0,
        plane = 0.66  -- camera plane distance (affects FOV)
    },
    
    -- Performance stats
    stats = {
        raycastTime = 0,
        wallsRenderTime = 0,
        floorRenderTime = 0,
        ceillingRenderTime = 0, 
        spritesRenderTime = 0,
        numChecks = 0,
        renderTime = 0
    },
    
    -- Torch light time tracker
    torchTime = 0
}

-- Load the shaders for hardware-accelerated rendering
local function loadShaders()
    -- Wall shader for efficient rendering of walls
    raycaster.wallShader = love.graphics.newShader([[
    #ifdef PIXEL
    #define MAIN_CANVAS 0

    struct RenderData {
        float textureId;
        float wallHeight;
        float u;
        float shade;
        float rayLength;
        float z;
    };

    uniform Image dataBuffer;
    uniform ArrayImage textures;
    uniform ArrayImage normalMaps;
    uniform float cameraOffset;
    uniform float cameraTilt;
    uniform float torchTime;
    uniform float torchIntensity;
    uniform float torchRange;
    uniform float torchRedTint;
    uniform float globalDarkness;
    uniform bool torchEnabled;
    uniform vec3 lightDir;

    RenderData extractRenderData(float screenU) {
        RenderData result;
        
        vec4 row1 = Texel(dataBuffer, vec2(screenU, 0));
        vec4 row2 = Texel(dataBuffer, vec2(screenU, 1));
        
        result.textureId = row1.r;
        result.wallHeight = row1.g;
        result.u = row1.b;
        result.shade = row1.a;
        result.rayLength = row2.r;
        result.z = row2.g;
        
        return result;
    }

    void effect() {
        vec2 screen_coords = love_PixelCoord;
        RenderData rd = extractRenderData((screen_coords.x)/love_ScreenSize.x);
        
        float ceilling = (love_ScreenSize.y/2.0) - (rd.wallHeight/2.0) + (cameraOffset / rd.rayLength) + cameraTilt;
        float floor = ceilling + rd.wallHeight;
        float v = (screen_coords.y-ceilling) / rd.wallHeight;
        
        if (screen_coords.y < ceilling || screen_coords.y > floor) {
            // Write a blank pixel and set max depth for areas that aren't walls
            love_Canvases[MAIN_CANVAS] = vec4(0);
            gl_FragDepth = 1;
        } else {
            // Get diffuse color from texture
            vec4 diffuseColor = Texel(textures, vec3(rd.u, v, rd.textureId));
            
            // Get normal from normal map
            vec3 normal = Texel(normalMaps, vec3(rd.u, v, rd.textureId)).rgb;
            
            // Transform normal from [0,1] to [-1,1] range
            normal = normal * 2.0 - 1.0;
            
            // Calculate lighting direction based on side (depends on ray direction)
            vec3 lighting;
            if (rd.textureId > 0.0) {
                // Determine lighting based on wall normal and light direction
                float diffuse = max(0.3, dot(normal, lightDir));
                
                // Apply base shade from distance and side
                lighting = vec3(diffuse * rd.shade);
            } else {
                // Fallback for non-textured walls
                lighting = vec3(rd.shade);
            }
            
            // Apply lighting to color
            vec3 colour = diffuseColor.rgb * lighting;
            
            // Apply global darkness
            colour *= (1.0 - globalDarkness);
            
            // Apply torch effect if enabled
            if (torchEnabled) {
                // Pulsating effect based on time
                float pulse = 0.5 + 0.5 * sin(torchTime);
                
                // Distance-based torch light (stronger near camera)
                float torchFactor = max(0.0, 1.0 - (rd.rayLength / torchRange));
                
                // Combine pulse with distance for torch intensity
                float intensity = torchIntensity * pulse * torchFactor;
                
                // Enhanced torch effect using normal map
                float normalFactor = max(0.0, dot(normal, vec3(0.0, 0.0, 1.0)));
                intensity *= (0.7 + 0.3 * normalFactor);
                
                // Apply red-tinted torch light
                colour.r += intensity * torchRedTint;
                colour.g += intensity * (1.0 - torchRedTint) * 0.5;
                colour.b += intensity * (1.0 - torchRedTint) * 0.2;
            }
            
            love_Canvases[MAIN_CANVAS] = vec4(colour, diffuseColor.a);
            gl_FragDepth = rd.z;
        }
    }
    #endif
    ]])

    -- Floor shader for hardware-accelerated floor rendering
    raycaster.floorShader = love.graphics.newShader([[
    #ifdef PIXEL
    uniform float width;
    uniform float height;
    uniform vec2 position;
    uniform ArrayImage textures;
    uniform ArrayImage normalMaps;
    uniform Image map;
    uniform ivec2 mapDimensions;
    uniform float fov;
    uniform float angle;
    uniform float cameraOffset;
    uniform float cameraTilt;
    uniform float shadeDepth;
    uniform float torchTime;
    uniform float torchIntensity;
    uniform float torchRange;
    uniform float torchRedTint;
    uniform float globalDarkness;
    uniform bool torchEnabled;
    uniform vec3 lightDir;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        float step = fov / width;
        float rayAngle = angle-(fov / 2.0f) + (screen_coords.x * step);
        vec2 dir = vec2(cos(rayAngle), sin(rayAngle));
        
        float offsetCorrection = (1*width-(height*2)) / 2;
        float z = (height+cameraOffset+offsetCorrection)/(screen_coords.y-cameraTilt-(height));
        float s = 1.0f - (z/shadeDepth);
        s = clamp(s, 0.0, 1.0); // Allow complete darkness at max distance
        float ppx = position.x + dir.x * (z/cos(rayAngle-angle));
        float ppy = position.y + dir.y * (z/cos(rayAngle-angle));
        float ux = floor(ppx);
        float uy = floor(ppy);          
        float u = ppx - ux;
        float v = ppy - uy;
        float tileId = Texel(map, vec2(ux +0.5, uy+0.5) / mapDimensions).r;
        
        vec3 colour;
        if (int(ux) < 0 || int(ux) >= mapDimensions.x || int(uy) < 0 || int(uy) >= mapDimensions.y || tileId < 0) {
            colour = vec3(0.4, 0.4, 0.2) * s; // Default color for out of bounds
        } else {
            // Get diffuse color from texture
            vec4 diffuseColor = Texel(textures, vec3(u, v, tileId));
            
            // Get normal from normal map
            vec3 normal = Texel(normalMaps, vec3(u, v, tileId)).rgb;
            
            // Transform normal from [0,1] to [-1,1] range
            normal = normal * 2.0 - 1.0;
            
            // Floor normal is up by default, but we can perturb it with the normal map
            // Blend between up vector and perturbed normal based on normal map intensity
            vec3 floorNormal = normalize(vec3(normal.xy * 0.5, 1.0));
            
            // Calculate diffuse lighting
            float diffuse = max(0.3, dot(floorNormal, lightDir));
            
            // Apply lighting and distance shading
            colour = diffuseColor.rgb * diffuse * s;
        }
        
        // Apply global darkness
        colour *= (1.0 - globalDarkness);
        
        // Apply torch effect if enabled
        if (torchEnabled) {
            // Pulsating effect based on time
            float pulse = 0.5 + 0.5 * sin(torchTime);
            
            // Distance-based torch light (stronger near camera)
            float torchFactor = max(0.0, 1.0 - (z / torchRange));
            
            // Combine pulse with distance for torch intensity
            float intensity = torchIntensity * pulse * torchFactor;
            
            // Apply red-tinted torch light
            colour.r += intensity * torchRedTint;
            colour.g += intensity * (1.0 - torchRedTint) * 0.5;
            colour.b += intensity * (1.0 - torchRedTint) * 0.2;
        }
        
        return vec4(colour, 1);
    }
    #endif
    ]])

    -- Ceiling shader for hardware-accelerated ceiling rendering
    raycaster.ceilingShader = love.graphics.newShader([[
    #ifdef PIXEL
    uniform float width;
    uniform float height;
    uniform vec2 position;
    uniform ArrayImage textures;
    uniform ArrayImage normalMaps;
    uniform Image map;
    uniform ivec2 mapDimensions;
    uniform float fov;
    uniform float angle;
    uniform float cameraOffset;
    uniform float cameraTilt;
    uniform float shadeDepth;
    uniform float torchTime;
    uniform float torchIntensity;
    uniform float torchRange;
    uniform float torchRedTint;
    uniform float globalDarkness;
    uniform bool torchEnabled;
    uniform vec3 lightDir;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        float step = fov / width;
        float rayAngle = angle-(fov / 2.0f) + (screen_coords.x * step);
        vec2 dir = vec2(cos(rayAngle), sin(rayAngle));
        
        float offsetCorrection = (1*width-(height*2)) / 2;
        float z = (height+cameraOffset+offsetCorrection)/(height - screen_coords.y + cameraTilt);
        
        float s = 1.0f - (z/shadeDepth);
        s = clamp(s, 0.0, 1.0); // Allow complete darkness at max distance
        
        float ppx = position.x + dir.x * (z/cos(rayAngle-angle));
        float ppy = position.y + dir.y * (z/cos(rayAngle-angle));
        
        float ux = floor(ppx);
        float uy = floor(ppy);
        
        float u = ppx - ux;
        float v = ppy - uy;
        
        float tileId = Texel(map, vec2(ux +0.5, uy+0.5) / mapDimensions).r;
        
        vec3 colour;
        if (int(ux) < 0 || int(ux) >= mapDimensions.x || int(uy) < 0 || int(uy) >= mapDimensions.y || tileId < 0) {
            colour = vec3(0.1, 0.1, 0.3) * s; // Default ceiling color
        } else {
            // Get diffuse color from texture
            vec4 diffuseColor = Texel(textures, vec3(u, v, tileId));
            
            // Get normal from normal map
            vec3 normal = Texel(normalMaps, vec3(u, v, tileId)).rgb;
            
            // Transform normal from [0,1] to [-1,1] range
            normal = normal * 2.0 - 1.0;
            
            // Ceiling normal is down by default, but we can perturb it with the normal map
            // Blend between down vector and perturbed normal based on normal map intensity
            vec3 ceilingNormal = normalize(vec3(normal.xy * 0.5, -1.0));
            
            // Calculate diffuse lighting (invert light direction for ceiling)
            float diffuse = max(0.3, dot(ceilingNormal, -lightDir));
            
            // Apply lighting and distance shading
            colour = diffuseColor.rgb * diffuse * s;
        }
        
        // Apply global darkness
        colour *= (1.0 - globalDarkness);
        
        // Apply torch effect if enabled
        if (torchEnabled) {
            // Pulsating effect based on time
            float pulse = 0.5 + 0.5 * sin(torchTime);
            
            // Distance-based torch light (stronger near camera)
            float torchFactor = max(0.0, 1.0 - (z / torchRange));
            
            // Combine pulse with distance for torch intensity
            float intensity = torchIntensity * pulse * torchFactor;
            
            // Apply red-tinted torch light
            colour.r += intensity * torchRedTint;
            colour.g += intensity * (1.0 - torchRedTint) * 0.5;
            colour.b += intensity * (1.0 - torchRedTint) * 0.2;
        }
        
        return vec4(colour, 1);
    }
    #endif
    ]])

    -- Sprite shader for rendering entities
    raycaster.spriteShader = love.graphics.newShader([[
    #ifdef VERTEX
    attribute float VertexDepth;
    
    varying float v_depth;

    vec4 position(mat4 transform_projection, vec4 vertex_position)
    {
        v_depth = VertexDepth;
        return transform_projection * vertex_position;
    }
    #endif

    #ifdef PIXEL
    varying float v_depth;
    uniform float shadeDepth;
    uniform float depth;
    uniform float torchTime;
    uniform float torchIntensity;
    uniform float torchRange;
    uniform float torchRedTint;
    uniform float globalDarkness;
    uniform bool torchEnabled;
    uniform vec3 lightDir;
    uniform Image normalMap;
    uniform bool hasNormalMap;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
    {
        vec4 texcolor = Texel(texture, texture_coords);
        if (texcolor.a < 0.1) discard;
        
        float shade = 1.0 - (v_depth / shadeDepth);
        shade = clamp(shade, 0.0, 1.0); // Allow complete darkness at max distance
        
        vec3 normal = vec3(0.0, 0.0, 1.0); // Default forward-facing normal
        
        // If normal map is available, use it
        if (hasNormalMap) {
            vec3 normalValue = Texel(normalMap, texture_coords).rgb;
            normal = normalValue * 2.0 - 1.0; // Convert from [0,1] to [-1,1]
        }
        
        // Calculate diffuse lighting
        float diffuse = max(0.3, dot(normal, lightDir));
        
        // Apply lighting
        vec3 colour = texcolor.rgb * diffuse * shade * color.rgb;
        
        // Apply global darkness
        colour *= (1.0 - globalDarkness);
        
        // Apply torch effect if enabled
        if (torchEnabled) {
            // Pulsating effect based on time
            float pulse = 0.5 + 0.5 * sin(torchTime);
            
            // Distance-based torch light (stronger near camera)
            float torchFactor = max(0.0, 1.0 - (v_depth / torchRange));
            
            // Combine pulse with distance for torch intensity
            float intensity = torchIntensity * pulse * torchFactor;
            
            // Enhanced torch effect using normal map if available
            if (hasNormalMap) {
                float normalFactor = max(0.0, dot(normal, vec3(0.0, 0.0, 1.0)));
                intensity *= (0.7 + 0.3 * normalFactor);
            }
            
            // Apply red-tinted torch light
            colour.r += intensity * torchRedTint;
            colour.g += intensity * (1.0 - torchRedTint) * 0.5;
            colour.b += intensity * (1.0 - torchRedTint) * 0.2;
        }
        
        gl_FragDepth = depth;
        return vec4(colour, texcolor.a * color.a);
    }
    #endif
    ]])
end

-- Create a DDA ray casting result class
local RayCastResult = {
    collisionOccurred = false,
    collisionPoint = {x = 0, y = 0},
    collisionSide = 0, -- 0 for NS walls, 1 for EW walls
    rayLength = 0,
    totalChecks = 0,
    u = 0, -- Texture coordinate
    tileId = 0,
    side = 0,
    dx = 0,
    dy = 0,
    x = 0,
    y = 0
}

function RayCastResult:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RayCastResult:reset()
    self.collisionOccurred = false
    self.collisionPoint.x = 0
    self.collisionPoint.y = 0
    self.collisionSide = 0
    self.rayLength = 0
    self.totalChecks = 0
    self.u = 0
    self.tileId = 0
    self.side = 0
    self.dx = 0
    self.dy = 0
    self.x = 0
    self.y = 0
end

-- Initialize the raycaster
function raycaster:init(width, height)
    self.viewWidth = width or self.viewWidth
    self.viewHeight = height or self.viewHeight
    
    -- Calculate derived values
    self.halfHeight = self.viewHeight / 2
    self.halfWidth = self.viewWidth / 2
    
    -- Load shaders
    loadShaders()
    
    -- Create canvases for rendering
    self.canvas = love.graphics.newCanvas(self.viewWidth, self.viewHeight)
    self.depthBuffer = love.graphics.newCanvas(self.viewWidth, self.viewHeight, {type = "2d", format = "depth16", readable = true})
    self.spriteMode = {self.canvas, depthstencil = self.depthBuffer}
    self.justDepthBuffer = {depthstencil = self.depthBuffer}
    
    -- Create data buffer for wall rendering
    -- Data buffer layout:
    -- Row 0: [textureId, wallHeight, texture U, shade]
    -- Row 1: [rayLength, normalized z, rayDirX, rayDirY]
    self.dataBuffer = love.image.newImageData(self.viewWidth, 2, "rgba16f")
    self.dataBufferTexture = love.graphics.newImage(self.dataBuffer)
    
    -- Initialize camera
    self.camera.x = 2
    self.camera.y = 2
    self.camera.angle = 0
    self.camera.dirX = math.cos(self.camera.angle)
    self.camera.dirY = math.sin(self.camera.angle)
    self.camera.planeX = -self.camera.dirY * self.camera.plane
    self.camera.planeY = self.camera.dirX * self.camera.plane
    self.cameraPosition = {self.camera.x, self.camera.y}
    
    -- Initialize raycasting result
    self.result = RayCastResult:new()
    
    -- Setup wall shader
    self.wallShader:send("dataBuffer", self.dataBufferTexture)
    
    -- Setup floor and ceiling shaders
    self.floorShader:send("width", self.viewWidth)
    self.floorShader:send("height", self.halfHeight)
    self.floorShader:send("shadeDepth", self.shadeDepth)
    
    self.ceilingShader:send("width", self.viewWidth)
    self.ceilingShader:send("height", self.halfHeight)
    self.ceilingShader:send("shadeDepth", self.shadeDepth)
    
    -- Setup sprite rendering
    self.spriteShader:send("shadeDepth", self.shadeDepth)
    -- Initialize depth parameter
    self.spriteShader:send("depth", 0.5)
    
    -- Define wall colors (used as fallback if textures are disabled)
    self.wallColors = {
        { 0.8, 0.2, 0.2 },  -- Red
        { 0.2, 0.8, 0.2 },  -- Green
        { 0.2, 0.2, 0.8 },  -- Blue
        { 0.8, 0.8, 0.2 },  -- Yellow
        { 0.8, 0.2, 0.8 },  -- Magenta
        { 0.2, 0.8, 0.8 },  -- Cyan
        { 0.6, 0.3, 0.2 },  -- Brown
        { 0.5, 0.5, 0.5 },  -- Gray
        { 0.7, 0.7, 0.7 },  -- Light Gray
        { 0.3, 0.3, 0.3 }   -- Dark Gray
    }
    
    -- Create Z-buffer for depth testing
    self.zBuffer = {}
    for i = 1, self.viewWidth do
        self.zBuffer[i] = self.maxDistance
    end
    
    -- Mark as initialized
    self.initialized = true
end

-- Set camera position
function raycaster:setCamera(x, y, angle)
    self.camera.x = x
    self.camera.y = y
    self.camera.angle = angle
    
    -- Update camera direction and plane vectors
    self.camera.dirX = math.cos(angle)
    self.camera.dirY = math.sin(angle)
    self.camera.planeX = -self.camera.dirY * self.camera.plane
    self.camera.planeY = self.camera.dirX * self.camera.plane
    
    -- Update camera position array for shaders
    self.cameraPosition[1] = x
    self.cameraPosition[2] = y
end

-- Move camera forward/backward
function raycaster:moveCamera(distance, map)
    local newX = self.camera.x + self.camera.dirX * distance
    local newY = self.camera.y + self.camera.dirY * distance
    
    -- Check collision with walls
    if map:isCellWalkable(math.floor(newX), math.floor(self.camera.y)) then
        self.camera.x = newX
        self.cameraPosition[1] = newX
    end
    
    if map:isCellWalkable(math.floor(self.camera.x), math.floor(newY)) then
        self.camera.y = newY
        self.cameraPosition[2] = newY
    end
end

-- Strafe camera left/right
function raycaster:strafeCamera(distance, map)
    local strafeX = -self.camera.dirY
    local strafeY = self.camera.dirX
    
    local newX = self.camera.x + strafeX * distance
    local newY = self.camera.y + strafeY * distance
    
    -- Check collision with walls
    if map:isCellWalkable(math.floor(newX), math.floor(self.camera.y)) then
        self.camera.x = newX
        self.cameraPosition[1] = newX
    end
    
    if map:isCellWalkable(math.floor(self.camera.x), math.floor(newY)) then
        self.camera.y = newY
        self.cameraPosition[2] = newY
    end
end

-- Rotate camera
function raycaster:rotateCamera(angle)
    self.camera.angle = self.camera.angle + angle
    
    -- Update camera direction and plane vectors
    self.camera.dirX = math.cos(self.camera.angle)
    self.camera.dirY = math.sin(self.camera.angle)
    self.camera.planeX = -self.camera.dirY * self.camera.plane
    self.camera.planeY = self.camera.dirX * self.camera.plane
end

-- Cast a single ray using DDA (Digital Differential Analysis) algorithm
function raycaster:castRay(rayStart, rayDir, map, result)
    result:reset()
    
    -- Ray direction
    result.dx = rayDir.x
    result.dy = rayDir.y
    
    -- Calculate steps and initial side distances
    local rayUnitStepSize = {
        x = math.sqrt(1 + (rayDir.y/rayDir.x) * (rayDir.y/rayDir.x)),
        y = math.sqrt(1 + (rayDir.x/rayDir.y) * (rayDir.x/rayDir.y))
    }
    
    local mapCheck = {
        x = math.floor(rayStart.x),
        y = math.floor(rayStart.y)
    }
    
    local rayLength = {x = 0, y = 0}
    local step = {x = 0, y = 0}
    
    -- Calculate step and initial rayLength
    if rayDir.x < 0 then
        step.x = -1
        rayLength.x = (rayStart.x - mapCheck.x) * rayUnitStepSize.x
    else
        step.x = 1
        rayLength.x = (mapCheck.x + 1 - rayStart.x) * rayUnitStepSize.x
    end
    
    if rayDir.y < 0 then
        step.y = -1
        rayLength.y = (rayStart.y - mapCheck.y) * rayUnitStepSize.y
    else
        step.y = 1
        rayLength.y = (mapCheck.y + 1 - rayStart.y) * rayUnitStepSize.y
    end
    
    -- DDA algorithm
    local hitWall = false
    local distance = 0
    local side = 0 -- 0 for NS walls, 1 for EW walls
    local numChecks = 0
    
    while distance <= self.maxDistance and not hitWall do
        numChecks = numChecks + 1
        
        -- Jump to next map square
        if rayLength.x < rayLength.y then
            mapCheck.x = mapCheck.x + step.x
            distance = rayLength.x
            rayLength.x = rayLength.x + rayUnitStepSize.x
            side = 0
        else
            mapCheck.y = mapCheck.y + step.y
            distance = rayLength.y
            rayLength.y = rayLength.y + rayUnitStepSize.y
            side = 1
        end
        
        -- Check if ray has hit a wall
        local cellType = map:getCell(mapCheck.x, mapCheck.y)
        if cellType > 0 then
            hitWall = true
            
            result.tileId = map:getWallTexture(mapCheck.x, mapCheck.y) or cellType
            result.x = mapCheck.x
            result.y = mapCheck.y
            result.rayLength = distance
            result.totalChecks = numChecks
            result.side = side
            result.collisionOccurred = true
            
            -- Calculate exact hit position for texture mapping
            result.collisionPoint.x = rayStart.x + rayDir.x * distance
            result.collisionPoint.y = rayStart.y + rayDir.y * distance
            
            -- Calculate texture U coordinate based on the exact hit position
            if side == 0 then
                result.u = result.collisionPoint.y - math.floor(result.collisionPoint.y)
                if rayDir.x > 0 then result.u = 1 - result.u end
            else
                result.u = result.collisionPoint.x - math.floor(result.collisionPoint.x)
                if rayDir.y < 0 then result.u = 1 - result.u end
            end
        end
    end
    
    return hitWall
end

-- Prepare map data for GPU-based floor/ceiling rendering
function raycaster:prepareMapData(map)
    if not map.floorsTexture or not map.ceilingsTexture then
        -- Create floor and ceiling data textures
        local floorImageData = love.image.newImageData(map.width, map.height, "rgba16f")
        local ceilingImageData = love.image.newImageData(map.width, map.height, "rgba16f")
        
        -- Fill textures with tile IDs
        for y = 0, map.height - 1 do
            for x = 0, map.width - 1 do
                local floorTile = map:getFloorTexture(x, y)
                local ceilingTile = map:getCeilingTexture(x, y)
                
                local floorId = type(floorTile) == "string" and assetManager.textureIds.floors[floorTile] or 0
                local ceilingId = type(ceilingTile) == "string" and assetManager.textureIds.ceilings[ceilingTile] or 0
                
                floorImageData:setPixel(x, y, floorId, 0, 0, 0)
                ceilingImageData:setPixel(x, y, ceilingId, 0, 0, 0)
            end
        end
        
        -- Create textures from the image data
        map.floorsTexture = love.graphics.newImage(floorImageData)
        map.ceilingsTexture = love.graphics.newImage(ceilingImageData)
        map.dimensions = {map.width, map.height}
        
        -- Clean up image data
        floorImageData:release()
        ceilingImageData:release()
    end
    
    return map
end

-- Render walls using GPU shader
function raycaster:renderWalls(map)
    local position = {x = self.camera.x, y = self.camera.y}
    local angle = self.camera.angle
    local fov = self.fov
    
    local totalChecks = 0
    local angleStep = fov / self.viewWidth
    local startAngle = angle - (fov / 2)
    
    local start = love.timer.getTime()
    
    -- Cast rays and collect wall data
    for x = 0, self.viewWidth - 1 do
        local rayAngle = startAngle + (x * angleStep)
        local rayDir = {
            x = math.cos(rayAngle),
            y = math.sin(rayAngle)
        }
        
        -- Cast ray to find walls
        if self:castRay(position, rayDir, map, self.result) then
            -- Calculate perpendicular wall distance to avoid fisheye effect
            local correctedRayLength = self.result.rayLength * math.cos(rayAngle - angle)
            
            -- Calculate wall height on screen
            local wallHeight = (self.viewWidth) / correctedRayLength
            
            -- Calculate shade based on distance and side
            local shade = (1 - (0.5 * self.result.side)) * (1 - (correctedRayLength / self.shadeDepth))
            shade = math.max(0.0, shade) -- Allow complete darkness at max distance
            
            -- Get texture ID for the wall
            local textureId = 0
            if self.texturesEnabled and self.result.tileId then
                if type(self.result.tileId) == "string" then
                    textureId = assetManager.textureIds.walls[self.result.tileId] or 0
                else
                    textureId = self.result.tileId
                end
            end
            
            -- Store wall rendering data in data buffer
            self.dataBuffer:setPixel(x, 0, textureId, wallHeight, self.result.u, shade)
            self.dataBuffer:setPixel(x, 1, correctedRayLength, correctedRayLength / self.maxDistance, rayDir.x, rayDir.y)
            
            -- Update Z-buffer for sprite rendering
            self.zBuffer[x + 1] = correctedRayLength
        else
            -- Ray reached max length without hitting anything
            self.dataBuffer:setPixel(x, 0, 0, 0, 0, 0)
            self.dataBuffer:setPixel(x, 1, self.maxDistance, 1, rayDir.x, rayDir.y)
            self.zBuffer[x + 1] = self.maxDistance
        end
        
        totalChecks = totalChecks + self.result.totalChecks
    end
    
    local raycastTime = (love.timer.getTime() - start)
    start = love.timer.getTime()
    
    -- Update the texture with the wall data
    self.dataBufferTexture:replacePixels(self.dataBuffer)
    
    -- Render walls with shader
    love.graphics.setCanvas({self.canvas, depthstencil = self.depthBuffer})
    love.graphics.setDepthMode("always", true)
    love.graphics.setShader(self.wallShader)
    
    -- Send shader uniforms
    self.wallShader:send("cameraOffset", self.camera.height)
    self.wallShader:send("cameraTilt", self.camera.tilt)
    self.wallShader:send("textures", assetManager.texArrays.walls)
    self.wallShader:send("normalMaps", assetManager.texArrays.wallNormals)
    
    -- Calculate light direction (pointing slightly downwards)
    local lightDir = {0.2, 0.3, 0.9}
    local lightDirLength = math.sqrt(lightDir[1]^2 + lightDir[2]^2 + lightDir[3]^2)
    lightDir[1] = lightDir[1] / lightDirLength
    lightDir[2] = lightDir[2] / lightDirLength
    lightDir[3] = lightDir[3] / lightDirLength
    self.wallShader:send("lightDir", lightDir)
    
    -- Update shader uniforms for torch effect
    self.wallShader:send("torchTime", self.torchTime)
    self.wallShader:send("torchIntensity", self.torchIntensity)
    self.wallShader:send("torchRange", self.torchRange)
    self.wallShader:send("torchRedTint", self.torchRedTint)
    self.wallShader:send("globalDarkness", self.globalDarkness)
    self.wallShader:send("torchEnabled", self.torchEnabled)
    
    -- Draw walls
    love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.viewHeight)
    love.graphics.setShader()
    
    local renderTime = (love.timer.getTime() - start)
    
    -- Update stats
    self.stats.raycastTime = raycastTime
    self.stats.wallsRenderTime = renderTime
    self.stats.numChecks = totalChecks
end

-- Render floor and ceiling with GPU shaders
function raycaster:renderFloorAndCeiling(map)
    -- Prepare map data for GPU rendering if needed
    self:prepareMapData(map)
    
    -- Calculate light direction (pointing slightly downwards)
    local lightDir = {0.2, 0.3, 0.9}
    local lightDirLength = math.sqrt(lightDir[1]^2 + lightDir[2]^2 + lightDir[3]^2)
    lightDir[1] = lightDir[1] / lightDirLength
    lightDir[2] = lightDir[2] / lightDirLength
    lightDir[3] = lightDir[3] / lightDirLength
    
    -- Render ceiling
    local start = love.timer.getTime()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setShader(self.ceilingShader)
    
    -- Send shader uniforms for ceiling
    self.ceilingShader:send("position", self.cameraPosition)
    self.ceilingShader:send("textures", assetManager.texArrays.ceilings)
    self.ceilingShader:send("normalMaps", assetManager.texArrays.ceilingNormals)
    self.ceilingShader:send("fov", self.fov)
    self.ceilingShader:send("angle", self.camera.angle)
    self.ceilingShader:send("cameraTilt", self.camera.tilt)
    self.ceilingShader:send("cameraOffset", self.camera.height)
    self.ceilingShader:send("map", map.ceilingsTexture)
    self.ceilingShader:send("mapDimensions", map.dimensions)
    self.ceilingShader:send("lightDir", lightDir)
    
    -- Send shader uniforms for torch effect
    self.ceilingShader:send("torchTime", self.torchTime)
    self.ceilingShader:send("torchIntensity", self.torchIntensity)
    self.ceilingShader:send("torchRange", self.torchRange)
    self.ceilingShader:send("torchRedTint", self.torchRedTint)
    self.ceilingShader:send("globalDarkness", self.globalDarkness)
    self.ceilingShader:send("torchEnabled", self.torchEnabled)
    
    -- Draw ceiling
    love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.halfHeight + self.camera.tilt)
    
    self.stats.ceillingRenderTime = love.timer.getTime() - start
    
    -- Render floor
    start = love.timer.getTime()
    love.graphics.setShader(self.floorShader)
    
    -- Send shader uniforms for floor
    self.floorShader:send("position", self.cameraPosition)
    self.floorShader:send("textures", assetManager.texArrays.floors)
    self.floorShader:send("normalMaps", assetManager.texArrays.floorNormals)
    self.floorShader:send("fov", self.fov)
    self.floorShader:send("angle", self.camera.angle)
    self.floorShader:send("cameraTilt", self.camera.tilt)
    self.floorShader:send("cameraOffset", self.camera.height)
    self.floorShader:send("map", map.floorsTexture)
    self.floorShader:send("mapDimensions", map.dimensions)
    self.floorShader:send("lightDir", lightDir)
    
    -- Send shader uniforms for torch effect
    self.floorShader:send("torchTime", self.torchTime)
    self.floorShader:send("torchIntensity", self.torchIntensity)
    self.floorShader:send("torchRange", self.torchRange)
    self.floorShader:send("torchRedTint", self.torchRedTint)
    self.floorShader:send("globalDarkness", self.globalDarkness)
    self.floorShader:send("torchEnabled", self.torchEnabled)
    
    -- Draw floor
    love.graphics.rectangle("fill", 0, self.halfHeight + self.camera.tilt, self.viewWidth, self.halfHeight - self.camera.tilt)
    
    self.stats.floorRenderTime = love.timer.getTime() - start
    
    -- Reset shader
    love.graphics.setShader()
end

-- Draw entities using sprite rendering
function raycaster:renderEntities(entities)
    if not entities or not self.entitiesEnabled then return end
    
    local start = love.timer.getTime()
    
    -- Setup for sprite rendering
    love.graphics.setCanvas(self.spriteMode)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setShader(self.spriteShader)
    
    -- Calculate light direction (pointing slightly downwards)
    local lightDir = {0.2, 0.3, 0.9}
    local lightDirLength = math.sqrt(lightDir[1]^2 + lightDir[2]^2 + lightDir[3]^2)
    lightDir[1] = lightDir[1] / lightDirLength
    lightDir[2] = lightDir[2] / lightDirLength
    lightDir[3] = lightDir[3] / lightDirLength
    self.spriteShader:send("lightDir", lightDir)
    
    -- Send shader uniforms for torch effect
    self.spriteShader:send("torchTime", self.torchTime)
    self.spriteShader:send("torchIntensity", self.torchIntensity)
    self.spriteShader:send("torchRange", self.torchRange)
    self.spriteShader:send("torchRedTint", self.torchRedTint)
    self.spriteShader:send("globalDarkness", self.globalDarkness)
    self.spriteShader:send("torchEnabled", self.torchEnabled)
    
    -- Sort entities by distance (farthest to closest for correct drawing order)
    table.sort(entities, function(a, b)
        local distA = (a.x - self.camera.x)^2 + (a.y - self.camera.y)^2
        local distB = (b.x - self.camera.x)^2 + (b.y - self.camera.y)^2
        return distA > distB
    end)
    
    -- Draw each entity
    for _, entity in ipairs(entities) do
        -- Calculate sprite position relative to camera
        local spriteX = entity.x - self.camera.x
        local spriteY = entity.y - self.camera.y
        
        -- Calculate sprite angle relative to camera direction
        local objAngle = math.atan2(spriteY, spriteX) - self.camera.angle
        
        -- Normalize angle to [-PI, PI]
        if objAngle < -math.pi then objAngle = objAngle + 2 * math.pi end
        if objAngle > math.pi then objAngle = objAngle - 2 * math.pi end
        
        -- Check if sprite is visible (in front of camera within FOV)
        local visible = math.abs(objAngle) < self.fov / 1.5
        
        if visible then
            -- Get sprite texture
            local texture = nil
            local normalTexture = nil
            
            -- Check for monster sprite - use asset manager
            if entity.type == "monster" and entity.id then
                if assetManager.images.monsterSprites and assetManager.images.monsterSprites[entity.id] then
                    texture = assetManager.images.monsterSprites[entity.id]
                    normalTexture = assetManager.normalMaps.monsterSprites[entity.id]
                end
            elseif entity.texture then
                texture = assetManager.images.entities[entity.texture]
            end
            
            -- Calculate perpendicular distance for correct scaling and depth
            local dist = math.sqrt(spriteX*spriteX + spriteY*spriteY)
            local perpDistance = dist * math.cos(objAngle)
            
            if perpDistance > 0 and perpDistance < self.maxDistance then
                if texture then
                    -- Apply proper depth for z-testing
                    love.graphics.setDepthMode("lequal", true)
                    
                    -- Calculate sprite dimensions
                    local fullHeight = self.viewWidth / perpDistance
                    local aspectRatio = texture:getHeight() / texture:getWidth()
                    local spriteHeight = fullHeight 
                    local spriteWidth = spriteHeight / aspectRatio
                    
                    -- Calculate screen position
                    local spriteScreenX = math.floor((self.viewWidth / 2) * (1 + (objAngle / (self.fov/2))))
                    local drawStartY = math.floor(self.halfHeight - spriteHeight / 2 + (self.camera.height / perpDistance) + self.camera.tilt + (spriteHeight * self.spriteVerticalOffset))
                    local drawStartX = math.floor(spriteScreenX - spriteWidth / 2)
                    
                    -- Calculate shade based on distance
                    local shade = 1.0 - (perpDistance / self.shadeDepth)
                    shade = math.max(0.0, shade) -- Allow complete darkness at max distance
                    love.graphics.setColor(shade, shade, shade)
                    
                    -- Send normal map for this sprite if available
                    if normalTexture then
                        self.spriteShader:send("normalMap", normalTexture)
                        self.spriteShader:send("hasNormalMap", true)
                    else
                        self.spriteShader:send("hasNormalMap", false)
                    end
                    
                    -- Set depth value for this sprite
                    self.spriteShader:send("depth", perpDistance / self.maxDistance)
                    
                    -- Draw the sprite with depth information
                    love.graphics.draw(
                        texture,
                        drawStartX, drawStartY,
                        0,
                        spriteWidth / texture:getWidth(),
                        spriteHeight / texture:getHeight()
                    )
                elseif entity.color then
                    -- Use a colored rectangle if no texture is available
                    -- Calculate sprite dimensions
                    local spriteHeight = math.floor(self.viewHeight / perpDistance)
                    local spriteWidth = spriteHeight
                    
                    -- Calculate screen position
                    local spriteScreenX = math.floor((self.viewWidth / 2) * (1 + (objAngle / (self.fov/2))))
                    local drawStartY = math.floor(self.halfHeight - spriteHeight / 2 + (self.camera.height / perpDistance) + self.camera.tilt + (spriteHeight * self.spriteVerticalOffset))
                    local drawStartX = math.floor(spriteScreenX - spriteWidth / 2)
                    
                    -- Clamp to screen bounds
                    local drawHeight = math.min(spriteHeight, self.viewHeight - drawStartY)
                    local drawWidth = math.min(spriteWidth, self.viewWidth - drawStartX)
                    
                    -- Calculate shade based on distance
                    local shade = 1.0 - (perpDistance / self.shadeDepth)
                    shade = math.max(0.0, shade) -- Allow complete darkness at max distance
                    
                    -- Set color with correct shading
                    love.graphics.setColor(
                        entity.color[1] * shade,
                        entity.color[2] * shade,
                        entity.color[3] * shade,
                        entity.color[4] or 1
                    )
                    
                    -- Set depth value for this sprite
                    self.spriteShader:send("depth", perpDistance / self.maxDistance)
                    
                    -- Draw a rectangle for the sprite
                    love.graphics.rectangle("fill", drawStartX, drawStartY, drawWidth, drawHeight)
                end
            end
        end
    end
    
    -- Reset shader and depth mode
    love.graphics.setShader()
    love.graphics.setDepthMode("always", false)
    
    self.stats.spritesRenderTime = love.timer.getTime() - start
end

-- Update function to handle torch light time
function raycaster:update(dt)
    -- Update torch light time for pulsating effect
    self.torchTime = self.torchTime + dt * self.torchPulseSpeed
end

-- Render the complete scene
function raycaster:render(map, entities)
    if not map or not self.initialized then return end
    
    -- Update torch light time
    self:update(love.timer.getDelta())
    
    -- Clear the depth buffer
    love.graphics.setCanvas(self.justDepthBuffer)
    love.graphics.clear()
    
    -- Clear the main canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)
    
    -- Start timing
    local startTime = love.timer.getTime()
    
    -- Render floor and ceiling first (if enabled)
    if self.floorTexturesEnabled then
        self:renderFloorAndCeiling(map)
    else
        -- Draw solid color floor and ceiling
        love.graphics.setCanvas(self.canvas)
        love.graphics.setColor(0.1, 0.1, 0.3) -- Ceiling color
        love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.halfHeight)
        love.graphics.setColor(0.4, 0.4, 0.2) -- Floor color
        love.graphics.rectangle("fill", 0, self.halfHeight, self.viewWidth, self.halfHeight)
    end
    
    -- Render walls
    self:renderWalls(map)
    
    -- Render entities
    if entities and #entities > 0 then
        self:renderEntities(entities)
    end
    
    -- Reset canvas and draw to screen
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0)
    
    -- Update total render time
    self.stats.renderTime = love.timer.getTime() - startTime
    
    return self.canvas
end

return raycaster
