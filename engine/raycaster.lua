-- Raycaster Engine
-- Implements a raycaster renderer for first-person dungeon view
local assetManager = require("assets/assetManager")

local raycaster = {
    viewWidth = 800,
    viewHeight = 600,
    fov = 60,
    wallHeight = 1.0,
    maxDistance = 20,
    texturesEnabled = false,
    
    -- Camera properties
    camera = {
        x = 0,
        y = 0,
        angle = 0,
        plane = 0.66  -- camera plane distance (affects FOV)
    }
}

function raycaster:init(width, height)
    self.viewWidth = width or self.viewWidth
    self.viewHeight = height or self.viewHeight
    
    -- Calculate derived values
    self.halfHeight = self.viewHeight / 2
    self.halfWidth = self.viewWidth / 2
    
    -- Create a canvas for rendering
    self.canvas = love.graphics.newCanvas(self.viewWidth, self.viewHeight)
    
    -- Initialize camera
    self.camera.x = 2
    self.camera.y = 2
    self.camera.angle = 0
    self.camera.dirX = math.cos(self.camera.angle)
    self.camera.dirY = math.sin(self.camera.angle)
    self.camera.planeX = -self.camera.dirY * self.camera.plane
    self.camera.planeY = self.camera.dirX * self.camera.plane
    
    -- Define wall colors
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
end

-- Move camera forward/backward
function raycaster:moveCamera(distance, map)
    local newX = self.camera.x + self.camera.dirX * distance
    local newY = self.camera.y + self.camera.dirY * distance
    
    -- Check collision with walls
    if map:isCellWalkable(math.floor(newX), math.floor(self.camera.y)) then
        self.camera.x = newX
    end
    
    if map:isCellWalkable(math.floor(self.camera.x), math.floor(newY)) then
        self.camera.y = newY
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
    end
    
    if map:isCellWalkable(math.floor(self.camera.x), math.floor(newY)) then
        self.camera.y = newY
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

-- Cast a single ray and return hit information
function raycaster:castRay(rayAngle, map)
    local rayDirX = math.cos(rayAngle)
    local rayDirY = math.sin(rayAngle)
    
    -- Current map cell
    local mapX = math.floor(self.camera.x)
    local mapY = math.floor(self.camera.y)
    
    -- Length of ray from current position to next x or y-side
    local deltaDistX = math.abs(1 / rayDirX)
    local deltaDistY = math.abs(1 / rayDirY)
    
    -- Direction to step in x or y direction (either +1 or -1)
    local stepX, stepY
    
    -- Length of ray from one side to next
    local sideDistX, sideDistY
    
    -- Calculate step and initial sideDist
    if rayDirX < 0 then
        stepX = -1
        sideDistX = (self.camera.x - mapX) * deltaDistX
    else
        stepX = 1
        sideDistX = (mapX + 1.0 - self.camera.x) * deltaDistX
    end
    
    if rayDirY < 0 then
        stepY = -1
        sideDistY = (self.camera.y - mapY) * deltaDistY
    else
        stepY = 1
        sideDistY = (mapY + 1.0 - self.camera.y) * deltaDistY
    end
    
    -- Perform DDA (Digital Differential Analysis)
    local hit = 0  -- Was a wall hit?
    local side     -- Was a NS or EW wall hit?
    local wallType -- Type of wall that was hit
    
    while hit == 0 and mapX >= 0 and mapY >= 0 and mapX < map.width and mapY < map.height do
        -- Jump to next map square, either in x or y direction
        if sideDistX < sideDistY then
            sideDistX = sideDistX + deltaDistX
            mapX = mapX + stepX
            side = 0
        else
            sideDistY = sideDistY + deltaDistY
            mapY = mapY + stepY
            side = 1
        end
        
        -- Check if ray has hit a wall
        wallType = map:getCell(mapX, mapY)
        if wallType > 0 then
            hit = 1
        end
    end
    
    -- Calculate distance projected on camera direction
    local perpWallDist
    if side == 0 then
        perpWallDist = (mapX - self.camera.x + (1 - stepX) / 2) / rayDirX
    else
        perpWallDist = (mapY - self.camera.y + (1 - stepY) / 2) / rayDirY
    end
    
    -- Calculate wall height and draw coordinates
    local lineHeight = math.min(self.viewHeight, math.floor(self.viewHeight / perpWallDist * self.wallHeight))
    
    local drawStart = math.floor(-lineHeight / 2 + self.viewHeight / 2)
    if drawStart < 0 then drawStart = 0 end
    
    local drawEnd = math.floor(lineHeight / 2 + self.viewHeight / 2)
    if drawEnd >= self.viewHeight then drawEnd = self.viewHeight - 1 end
    
    -- Calculate texture coordinates
    local wallX
    if side == 0 then
        wallX = self.camera.y + perpWallDist * rayDirY
    else
        wallX = self.camera.x + perpWallDist * rayDirX
    end
    wallX = wallX - math.floor(wallX)
    
    -- Return hit information
    return {
        distance = perpWallDist,
        height = lineHeight,
        drawStart = drawStart,
        drawEnd = drawEnd,
        side = side,
        wallType = wallType,
        wallX = wallX,
        mapX = mapX,
        mapY = mapY
    }
end

-- Render the scene
function raycaster:render(map, entities)
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    
    -- Draw ceiling
    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.halfHeight)
    
    -- Draw floor
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", 0, self.halfHeight, self.viewWidth, self.halfHeight)
    
    -- Draw walls
    for x = 0, self.viewWidth - 1 do
        -- Calculate ray position and direction
        local cameraX = 2 * x / self.viewWidth - 1  -- x-coordinate in camera space
        local rayDirX = self.camera.dirX + self.camera.planeX * cameraX
        local rayDirY = self.camera.dirY + self.camera.planeY * cameraX
        local rayAngle = math.atan2(rayDirY, rayDirX)
        
        -- Cast the ray
        local hit = self:castRay(rayAngle, map)
        
        -- Choose wall color based on wall type and side
        local wallColor = self.wallColors[((hit.wallType - 1) % #self.wallColors) + 1]
        
        -- Make y-sides darker
        if hit.side == 1 then
            wallColor = {wallColor[1] * 0.7, wallColor[2] * 0.7, wallColor[3] * 0.7}
        end
        
        -- Set color and draw the vertical line
        love.graphics.setColor(wallColor)
        
        if self.texturesEnabled and assetManager.images.walls[hit.wallType] then
            -- Calculate texture x coordinate
            local texX = math.floor(hit.wallX * 64)
            if (hit.side == 0 and rayDirX > 0) or (hit.side == 1 and rayDirY < 0) then
                texX = 64 - texX - 1
            end
            
            -- Draw textured wall
            love.graphics.draw(
                assetManager.images.walls[hit.wallType],
                x, hit.drawStart,
                0, 1, (hit.drawEnd - hit.drawStart) / 64,
                texX, 0,
                1, 64
            )
        else
            -- Draw solid color wall
            love.graphics.line(x, hit.drawStart, x, hit.drawEnd)
        end
    end
    
    -- Draw entities
    if entities then
        -- Sort entities by distance (painter's algorithm)
        table.sort(entities, function(a, b)
            local distA = (a.x - self.camera.x)^2 + (a.y - self.camera.y)^2
            local distB = (b.x - self.camera.x)^2 + (b.y - self.camera.y)^2
            return distA > distB
        end)
        
        -- Draw each entity
        for _, entity in ipairs(entities) do
            -- Translate entity position to relative to camera
            local spriteX = entity.x - self.camera.x
            local spriteY = entity.y - self.camera.y
            
            -- Transform sprite with the inverse camera matrix
            -- [ planeX   dirX ] -1                                       [ dirY      -dirX ]
            -- [               ]       =  1/(planeX*dirY-dirX*planeY) *   [                 ]
            -- [ planeY   dirY ]                                          [ -planeY  planeX ]
            
            local invDet = 1.0 / (self.camera.planeX * self.camera.dirY - self.camera.dirX * self.camera.planeY)
            
            local transformX = invDet * (self.camera.dirY * spriteX - self.camera.dirX * spriteY)
            local transformY = invDet * (-self.camera.planeY * spriteX + self.camera.planeX * spriteY)
            
            local spriteScreenX = math.floor((self.viewWidth / 2) * (1 + transformX / transformY))
            
            -- Calculate sprite height and width
            local spriteHeight = math.abs(math.floor(self.viewHeight / transformY))
            local spriteWidth = spriteHeight
            
            -- Calculate drawing bounds
            local drawStartY = math.floor(-spriteHeight / 2 + self.viewHeight / 2)
            local drawEndY = math.floor(spriteHeight / 2 + self.viewHeight / 2)
            local drawStartX = math.floor(-spriteWidth / 2 + spriteScreenX)
            local drawEndX = math.floor(spriteWidth / 2 + spriteScreenX)
            
            -- Adjust bounds to be within screen
            drawStartY = math.max(0, drawStartY)
            drawEndY = math.min(self.viewHeight - 1, drawEndY)
            drawStartX = math.max(0, drawStartX)
            drawEndX = math.min(self.viewWidth - 1, drawEndX)
            
            -- Draw the sprite as a rectangle (placeholder for actual sprite)
            love.graphics.setColor(entity.color or {1, 0, 0})
            love.graphics.rectangle("fill", drawStartX, drawStartY, drawEndX - drawStartX, drawEndY - drawStartY)
        end
    end
    
    love.graphics.setCanvas()
    return self.canvas
end

return raycaster
