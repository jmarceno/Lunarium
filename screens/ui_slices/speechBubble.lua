-- Speech Bubble Drawing Utility
-- Module for drawing speech bubbles above character portraits in the party panel

local speechBubble = {}

-- Split text by line breaks (\n)
function speechBubble:splitLines(text)
    if not text or text == "" then
        return {}
    end
    
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    -- If no lines were found (text contains only newlines), return the original text
    if #lines == 0 then
        table.insert(lines, text)
    end
    
    return lines
end

-- Calculate bubble dimensions for given multi-line text
function speechBubble:calculateSize(text, maxWidth, font)
    if not text or text == "" then
        return 0, 0
    end
    
    local lines = self:splitLines(text)
    local totalHeight = 0
    local maxActualWidth = 0
    local lineHeight = font:getHeight()
    local padding = 16
    
    for _, line in ipairs(lines) do
        local lineWidth = font:getWidth(line)
        maxActualWidth = math.max(maxActualWidth, lineWidth)
        totalHeight = totalHeight + lineHeight
    end
    
    -- Add some spacing between lines
    if #lines > 1 then
        totalHeight = totalHeight + (#lines - 1) * 2
    end
    
    -- Add padding
    totalHeight = totalHeight + padding * 2
    maxActualWidth = math.min(maxActualWidth + padding * 2, maxWidth)
    
    return maxActualWidth, totalHeight
end

-- Draw a speech bubble at the specified position with multi-line text
function speechBubble:draw(text, x, y, maxWidth, characterIndex)
    if not text or text == "" then
        return
    end
    
    local font = love.graphics.getFont()
    local lines = self:splitLines(text)
    local bubbleWidth, bubbleHeight = self:calculateSize(text, maxWidth, font)
    local padding = 16 -- Consistent padding throughout the function
    
    -- Position bubble above the character portrait
    local bubbleX = x - bubbleWidth / 2
    local bubbleY = y - bubbleHeight - 15 -- 15 pixels above the portrait
    
    -- Make sure bubble doesn't go off screen
    bubbleX = math.max(5, math.min(bubbleX, love.graphics.getWidth() - bubbleWidth - 5))
    bubbleY = math.max(5, bubbleY)
    
    -- Draw bubble background
    love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
    love.graphics.rectangle("fill", bubbleX, bubbleY, bubbleWidth, bubbleHeight, 8, 8)
    
    -- Draw bubble border
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bubbleX, bubbleY, bubbleWidth, bubbleHeight, 8, 8)
    
    -- Draw speech bubble tail pointing to character
    local tailSize = 8
    local tailCenterX = x
    local tailStartY = bubbleY + bubbleHeight
    
    -- Ensure tail is within bubble bounds
    tailCenterX = math.max(bubbleX + tailSize, math.min(tailCenterX, bubbleX + bubbleWidth - tailSize))
    
    love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
    love.graphics.polygon("fill", 
        tailCenterX - tailSize, tailStartY,
        tailCenterX + tailSize, tailStartY,
        tailCenterX, tailStartY + tailSize
    )
    
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.polygon("line", 
        tailCenterX - tailSize, tailStartY,
        tailCenterX + tailSize, tailStartY,
        tailCenterX, tailStartY + tailSize
    )
    
    -- Draw text lines with proper padding
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    local textY = bubbleY + padding
    local lineHeight = font:getHeight()
    
    for _, line in ipairs(lines) do
        local lineWidth = font:getWidth(line)
        local textX = bubbleX + (bubbleWidth - lineWidth) / 2 -- Center text
        love.graphics.print(line, textX, textY)
        textY = textY + lineHeight + 2 -- Add small spacing between lines
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

return speechBubble 