-- Layout Helper
-- Provides utilities for adjusting UI layouts based on window size

local layoutHelper = {}

-- Calculate centered position based on element dimensions and window size
function layoutHelper:centerElement(elementWidth, elementHeight, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate centered position
    local x = math.floor((windowWidth - elementWidth) / 2) + offsetX
    local y = math.floor((windowHeight - elementHeight) / 2) + offsetY
    
    return x, y
end

-- Get horizontal position adjusted for window width
function layoutHelper:getHorizontalPosition(originalX, originalWidth, newWidth)
    local widthRatio = newWidth / GAME.width
    return math.floor(originalX * widthRatio)
end

-- Get vertical position adjusted for window height
function layoutHelper:getVerticalPosition(originalY, originalHeight, newHeight)
    local heightRatio = newHeight / GAME.height
    return math.floor(originalY * heightRatio)
end

-- Calculate a scaling factor based on the window size to maintain consistent UI size
function layoutHelper:getScaleFactor()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local widthRatio = windowWidth / GAME.width
    local heightRatio = windowHeight / GAME.height
    
    -- Use the smaller ratio to ensure UI fits within window
    return math.min(widthRatio, heightRatio)
end

-- Get a position scaled according to current window dimensions
function layoutHelper:getScaledPosition(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local widthRatio = windowWidth / GAME.width
    local heightRatio = windowHeight / GAME.height
    
    -- Calculate centered offsets if window aspect ratio differs from game aspect ratio
    local offsetX = 0
    local offsetY = 0
    
    if widthRatio > heightRatio then
        -- Window is wider than game aspect ratio
        offsetX = (windowWidth - (GAME.width * heightRatio)) / 2
        return math.floor(x * heightRatio + offsetX), math.floor(y * heightRatio)
    else
        -- Window is taller than game aspect ratio
        offsetY = (windowHeight - (GAME.height * widthRatio)) / 2
        return math.floor(x * widthRatio), math.floor(y * widthRatio + offsetY)
    end
end

return layoutHelper 