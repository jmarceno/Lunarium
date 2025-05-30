-- Scaling utility module for maintaining proportional scaling
local scaling = {}

-- Target resolution (native game resolution)
scaling.targetWidth = 1280
scaling.targetHeight = 720

-- Current scaling values
scaling.scaleX = 1
scaling.scaleY = 1
scaling.offsetX = 0
scaling.offsetY = 0

-- Initialize the scaling system
function scaling:init()
    self:calculateScale()
end

-- Calculate the scale and offset values based on current window size
function scaling:calculateScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate scale factors for both dimensions
    local scaleX = windowWidth / self.targetWidth
    local scaleY = windowHeight / self.targetHeight
    
    -- Use the smaller scale to maintain aspect ratio
    local scale = math.min(scaleX, scaleY)
    
    self.scaleX = scale
    self.scaleY = scale
    
    -- Calculate offsets to center the game
    local scaledWidth = self.targetWidth * scale
    local scaledHeight = self.targetHeight * scale
    
    self.offsetX = (windowWidth - scaledWidth) / 2
    self.offsetY = (windowHeight - scaledHeight) / 2
end

-- Apply scaling transformation
function scaling:push()
    love.graphics.push()
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scaleX, self.scaleY)
end

-- Remove scaling transformation
function scaling:pop()
    love.graphics.pop()
end

-- Convert screen coordinates to game coordinates
function scaling:toGameCoords(screenX, screenY)
    local gameX = (screenX - self.offsetX) / self.scaleX
    local gameY = (screenY - self.offsetY) / self.scaleY
    return gameX, gameY
end

-- Convert game coordinates to screen coordinates
function scaling:toScreenCoords(gameX, gameY)
    local screenX = gameX * self.scaleX + self.offsetX
    local screenY = gameY * self.scaleY + self.offsetY
    return screenX, screenY
end

-- Check if a point is within the game area
function scaling:isInGameArea(screenX, screenY)
    local gameX, gameY = self:toGameCoords(screenX, screenY)
    return gameX >= 0 and gameX <= self.targetWidth and gameY >= 0 and gameY <= self.targetHeight
end

-- Get the current scale factor
function scaling:getScale()
    return self.scaleX, self.scaleY
end

-- Get the current offset values
function scaling:getOffset()
    return self.offsetX, self.offsetY
end

-- Get the target resolution
function scaling:getTargetResolution()
    return self.targetWidth, self.targetHeight
end

-- Update scaling when window is resized
function scaling:onResize(width, height)
    self:calculateScale()
end

-- Draw letterbox/pillarbox bars (optional, for visual polish)
function scaling:drawBars()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Draw black bars around the game area
    love.graphics.setColor(0, 0, 0, 1)
    
    -- Left and right bars
    if self.offsetX > 0 then
        love.graphics.rectangle("fill", 0, 0, self.offsetX, windowHeight)
        love.graphics.rectangle("fill", windowWidth - self.offsetX, 0, self.offsetX, windowHeight)
    end
    
    -- Top and bottom bars
    if self.offsetY > 0 then
        love.graphics.rectangle("fill", 0, 0, windowWidth, self.offsetY)
        love.graphics.rectangle("fill", 0, windowHeight - self.offsetY, windowWidth, self.offsetY)
    end
end

return scaling 