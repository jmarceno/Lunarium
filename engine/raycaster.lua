-- Raycaster Engine with Hardware Acceleration
-- Uses shaders for highly efficient rendering of the 3D environment
local assetManager = require("assets/assetManager")
local monsterData = require("gameplay/monsterData") -- Added require for monsterData

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
    
    -- CRT effect parameters
    crtEnabled = true,         -- CRT effect enabled by default
    crtHardScan = 0,        -- Hardness of scanline
    crtHardPix = -3.0,         -- Hardness of pixels in scanline
    crtWarp = {1.0/64.0, 1.0/64.0}, -- Display warp amount
    crtMaskDark = 0.5,         -- Shadow mask darkness
    crtMaskLight = 1.0,        -- Shadow mask lightness
    
    -- Torch light effect parameters
    torchEnabled = false,
    torchIntensity = 0.9, -- Base intensity of the torch (0-1)
    torchRange = 5.0, -- How far the torch light reaches
    torchPulseSpeed = 1.0, -- Speed of torch light pulsation
    torchRedTint = 0.5, -- Amount of red tint in the torch light (0-1)
    globalDarkness = 0.6, -- Global darkness level (0-1, higher = darker)
    
    -- Normal map blur effect
    normalMapBlur = 1.0, -- Intensity of blur effect applied to normal maps (0-1, higher = more blur)
    
    -- Enemy normal map blur settings
    enemyNormalMapBlurEnabled = false, -- Whether to apply blur to enemy normal maps
    enemyNormalMapBlur = 0.5, -- Intensity of blur effect for enemy normal maps (0-1, higher = more blur)
    
    -- Light direction for lighting calculations
    lightDirection = {0.9, 0.9, 0.9},
    
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

-- Normalize the light direction vector
local lightDirLength = math.sqrt(raycaster.lightDirection[1]^2 + raycaster.lightDirection[2]^2 + raycaster.lightDirection[3]^2)
raycaster.lightDirection[1] = raycaster.lightDirection[1] / lightDirLength
raycaster.lightDirection[2] = raycaster.lightDirection[2] / lightDirLength
raycaster.lightDirection[3] = raycaster.lightDirection[3] / lightDirLength

-- Load the shaders for hardware-accelerated rendering
local function loadShaders()
    -- Load CRT shader
    raycaster.crtShader = require("engine/shaders/crtShader")
    
    -- Load wall shader
    raycaster.wallShader = love.graphics.newShader(require("engine/shaders/wallShader"))
    
    -- Load floor shader
    raycaster.floorShader = love.graphics.newShader(require("engine/shaders/floorShader"))
    
    -- Load ceiling shader
    raycaster.ceilingShader = love.graphics.newShader(require("engine/shaders/ceilingShader"))
    
    -- Load sprite shader
    raycaster.spriteShader = love.graphics.newShader(require("engine/shaders/spriteShader"))
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
    
    -- Additional canvas for post-processing
    self.postProcessCanvas = love.graphics.newCanvas(self.viewWidth, self.viewHeight)
    
    -- Setup CRT shader parameters
    self.crtShader:send("hardScan", self.crtHardScan)
    self.crtShader:send("hardPix", self.crtHardPix)
    self.crtShader:send("warp", self.crtWarp)
    self.crtShader:send("maskDark", self.crtMaskDark)
    self.crtShader:send("maskLight", self.crtMaskLight)
    self.crtShader:send("textureSize", {self.viewWidth, self.viewHeight})
    
    -- Create data buffer for wall rendering
    -- Data buffer layout:
    -- Row 0: [textureId, wallHeight, texture U, shade]
    -- Row 1: [rayLength, normalized z, hintFactor, unused]
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
    -- Ensure ImageData objects exist for the map
    if not map.floorImageData then
        map.floorImageData = love.image.newImageData(map.width, map.height, "rgba16f")
        map.floorsTexture = love.graphics.newImage(map.floorImageData)
    end
    if not map.ceilingImageData then
        map.ceilingImageData = love.image.newImageData(map.width, map.height, "rgba16f")
        map.ceilingsTexture = love.graphics.newImage(map.ceilingImageData)
    end

    -- Always update floor and ceiling data textures
    -- This ensures dynamic data like hintFactor is refreshed each frame for floors.
    local floorImageData = map.floorImageData
    local ceilingImageData = map.ceilingImageData
        
    -- Fill textures with tile IDs and other dynamic data (like hintFactor for floors)
    for y = 0, map.height - 1 do
        for x = 0, map.width - 1 do
            local floorTile = map:getFloorTexture(x, y)
            local ceilingTile = map:getCeilingTexture(x, y)
            
            local floorId = type(floorTile) == "string" and assetManager.textureIds.floors[floorTile] or 0
            local ceilingId = type(ceilingTile) == "string" and assetManager.textureIds.ceilings[ceilingTile] or 0
            
            -- Get hint factor for floor (traps)
            local floorHintFactor = 0.0
            if map.getHintFactor then
                floorHintFactor = map:getHintFactor(x, y, "floor")
            end
            
            -- Debug mode for traps
            if GAME.debug and map.isTileTrap and map:isTileTrap(x, y) then
                floorHintFactor = -1.0  -- Special value for debug visualization
            end
            
            -- Store data: R = textureId, G = hintFactor, B and A unused
            floorImageData:setPixel(x, y, floorId, floorHintFactor, 0, 0)
            ceilingImageData:setPixel(x, y, ceilingId, 0, 0, 0) -- No ceiling traps for now
        end
    end
    
    -- Update textures from the image data
    map.floorsTexture:replacePixels(floorImageData)
    map.ceilingsTexture:replacePixels(ceilingImageData)
    
    -- Ensure map dimensions are set (usually done once, but good to have here)
    if not map.dimensions then
      map.dimensions = {map.width, map.height}
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
            
            -- Get hint factor for this wall segment
            local hintFactor = 0.0
            if map.getHintFactor then
                hintFactor = map:getHintFactor(self.result.x, self.result.y, "wall")
            end
            
            -- Check if we need to show debug markers
            if GAME.debug and map.isWallTrapRelated and map:isWallTrapRelated(self.result.x, self.result.y) then
                hintFactor = -1.0  -- Special value for debug visualization
            end
            
            -- Store wall rendering data in data buffer
            self.dataBuffer:setPixel(x, 0, textureId, wallHeight, self.result.u, shade)
            self.dataBuffer:setPixel(x, 1, correctedRayLength, correctedRayLength / self.maxDistance, hintFactor, 0)
            
            -- Update Z-buffer for sprite rendering
            self.zBuffer[x + 1] = correctedRayLength
        else
            -- Ray reached max length without hitting anything
            self.dataBuffer:setPixel(x, 0, 0, 0, 0, 0)
            self.dataBuffer:setPixel(x, 1, self.maxDistance, 1, 0, 0)
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
    local lightDir = self.lightDirection
    self.wallShader:send("lightDir", lightDir)
    
    -- Update shader uniforms for torch effect
    self.wallShader:send("torchTime", self.torchTime)
    self.wallShader:send("torchIntensity", self.torchIntensity)
    self.wallShader:send("torchRange", self.torchRange)
    self.wallShader:send("torchRedTint", self.torchRedTint)
    self.wallShader:send("globalDarkness", self.globalDarkness)
    self.wallShader:send("torchEnabled", self.torchEnabled)
    
    -- Send normal map blur amount
    self.wallShader:send("normalMapBlur", self.normalMapBlur)
    
    -- Send game debug flag
    self.wallShader:send("gameDebugActive", GAME.debug)
    
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
    local lightDir = self.lightDirection
    
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
    self.ceilingShader:send("wallMap", map.physicalLayoutTexture)
    self.ceilingShader:send("mapDimensions", map.dimensions)
    self.ceilingShader:send("lightDir", lightDir)
    
    -- Send shader uniforms for torch effect
    self.ceilingShader:send("torchTime", self.torchTime)
    self.ceilingShader:send("torchIntensity", self.torchIntensity)
    self.ceilingShader:send("torchRange", self.torchRange)
    self.ceilingShader:send("torchRedTint", self.torchRedTint)
    self.ceilingShader:send("globalDarkness", self.globalDarkness)
    self.ceilingShader:send("torchEnabled", self.torchEnabled)
    
    -- Send normal map blur amount
    self.ceilingShader:send("normalMapBlur", self.normalMapBlur)
    
    -- Send game debug flag
    self.ceilingShader:send("gameDebugActive", GAME.debug)
    
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
    self.floorShader:send("wallMap", map.physicalLayoutTexture)
    self.floorShader:send("mapDimensions", map.dimensions)
    self.floorShader:send("lightDir", lightDir)
    
    -- Send shader uniforms for torch effect
    self.floorShader:send("torchTime", self.torchTime)
    self.floorShader:send("torchIntensity", self.torchIntensity)
    self.floorShader:send("torchRange", self.torchRange)
    self.floorShader:send("torchRedTint", self.torchRedTint)
    self.floorShader:send("globalDarkness", self.globalDarkness)
    self.floorShader:send("torchEnabled", self.torchEnabled)
    
    -- Send normal map blur amount
    self.floorShader:send("normalMapBlur", self.normalMapBlur)
    
    -- Send game debug flag
    self.floorShader:send("gameDebugActive", GAME.debug)
    
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
    

    self.spriteShader:send("lightDir", self.lightDirection)
    
    -- Send shader uniforms for torch effect
    self.spriteShader:send("torchTime", self.torchTime)
    self.spriteShader:send("torchIntensity", self.torchIntensity)
    self.spriteShader:send("torchRange", self.torchRange)
    self.spriteShader:send("torchRedTint", self.torchRedTint)
    self.spriteShader:send("globalDarkness", self.globalDarkness)
    self.spriteShader:send("torchEnabled", self.torchEnabled)
    
    -- Send enemy-specific normal map blur settings
    self.spriteShader:send("enemyNormalMapBlurEnabled", self.enemyNormalMapBlurEnabled)
    self.spriteShader:send("enemyNormalMapBlur", self.enemyNormalMapBlur)
    
    -- Helper function to convert snake_case to camelCase
    local function toCamelCase(str)
        -- Special case: if the string is already camelCase, return it as is
        if not str:find("_") then
            return str
        end
        
        -- Convert snake_case to camelCase
        return str:gsub("_(%l)", function(c) return c:upper() end)
    end
    
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
            
            if entity.type == "monster" and entity.id then
                local monsterDefinition = monsterData:getMonsterData(entity.id)
                if monsterDefinition and monsterDefinition.sprite then
                    local spriteKey = monsterDefinition.sprite -- This is "GiantRat" or "EnragedPanther_BOSS"
                    texture = assetManager:getImage("monster", spriteKey)
                    if texture then
                        normalTexture = assetManager:getNormalMap("monster", spriteKey)
                    else
                        if GAME.debug then
                            print("Raycaster: Monster sprite not found for key: " .. spriteKey .. " (from entity.id: " .. entity.id .. ")")
                        end
                    end
                else
                    if GAME.debug then
                        print("Raycaster: Monster definition or sprite field missing for entity.id: " .. entity.id)
                    end
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
                    
                    -- Apply special coloring and transparency for hidden monsters in debug mode
                    if entity.hidden and GAME.debug and entity.type == "monster" then
                        -- Magenta tint for hidden monsters with 50% transparency in debug mode
                        love.graphics.setColor(1, 0, 1, 0.5)  -- Magenta with 50% opacity
                    else
                        love.graphics.setColor(shade, shade, shade)
                    end
                    
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
                    
                    -- Apply special coloring and transparency for hidden monsters in debug mode
                    if entity.hidden and GAME.debug and entity.type == "monster" then
                        -- Magenta color with 50% transparency for hidden monsters in debug mode
                        love.graphics.setColor(1, 0, 1, 0.5) -- Magenta with 50% opacity
                    else
                        -- Set color with correct shading
                        love.graphics.setColor(
                            entity.color[1] * shade,
                            entity.color[2] * shade,
                            entity.color[3] * shade,
                            entity.color[4] or 1
                        )
                    end
                    
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

-- Toggle CRT effect
function raycaster:toggleCRT()
    self.crtEnabled = not self.crtEnabled
end

-- Update function to handle torch light time
function raycaster:update(dt)
    -- Update torch light time for pulsating effect
    self.torchTime = self.torchTime + dt * self.torchPulseSpeed
    
    -- Remove keyboard input check from here
    -- (Will be handled by keypressed callback)
end

-- Handle keypressed events
function raycaster:keypressed(key)
    if key == "f5" then
        self:toggleCRT()
        return true
    end
    return false
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
        -- Filter out hidden entities unless in debug mode
        local visibleEntities = {}
        for _, entity in ipairs(entities) do
            -- Only include entities that aren't hidden, or if they're hidden but debug mode is on
            if not entity.hidden or (entity.hidden and GAME.debug) then
                table.insert(visibleEntities, entity)
            end
        end
        
        -- Only render if we have visible entities
        if #visibleEntities > 0 then
            self:renderEntities(visibleEntities)
        end
    end
    
    -- Apply post-processing effects
    if self.crtEnabled then
        -- Copy the main canvas to post-process canvas
        love.graphics.setCanvas(self.postProcessCanvas)
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)
        love.graphics.setShader(self.crtShader)
        love.graphics.draw(self.canvas)
        love.graphics.setShader()
    end
    
    -- Reset canvas and draw to screen
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    
    -- Draw with CRT effect if enabled, otherwise draw directly
    if self.crtEnabled then
        love.graphics.draw(self.postProcessCanvas, 0, 0)
    else
        love.graphics.draw(self.canvas, 0, 0)
    end
    
    -- Update total render time
    self.stats.renderTime = love.timer.getTime() - startTime
    
    return self.crtEnabled and self.postProcessCanvas or self.canvas
end

return raycaster
