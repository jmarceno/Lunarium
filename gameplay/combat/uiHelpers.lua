-- UI Helper Functions
local assetManager = require("assets/assetManager")
local damageTypes = require("gameplay/damageTypes")
local statusEffects = require("gameplay/statusEffects")

local function showActionButtons(self)
    self.elements.attackButton.visible = true
    self.elements.skillButton.visible = true
    self.elements.itemButton.visible = true
    self.elements.defendButton.visible = true
end

local function hideActionButtons(self)
    self.elements.attackButton.visible = false
    self.elements.skillButton.visible = false
    self.elements.itemButton.visible = false
    self.elements.defendButton.visible = false
end

local function hideSelectionLists(self)
    self.elements.skillList.visible = false
    self.elements.itemList.visible = false
    self.elements.partySelectList.visible = false
    if self.elements.enemySelectList then
        self.elements.enemySelectList.visible = false
    end
end

local function showConfirmBackButtons(self, showConfirm, showBack)
    self.elements.confirmButton.visible = showConfirm or false
    self.elements.backButton.visible = showBack or false
end

local function hideAllUI(self)
    hideActionButtons(self)
    hideSelectionLists(self)
    showConfirmBackButtons(self, false, false)
end

-- Draw status effect icons for a combatant
-- @param entity: table - The entity whose status effects to draw
-- @param x: number - The x-coordinate to start drawing
-- @param y: number - The y-coordinate to start drawing
-- @param spacing: number - Spacing between icons (default: 24)
-- @param maxIcons: number - Maximum number of icons to display (default: 5)
local function drawStatusEffects(entity, x, y, spacing, maxIcons)
    if not entity or not entity.status then
        return
    end
    
    spacing = spacing or 24
    maxIcons = maxIcons or 5
    
    local count = 0
    local iconX = x
    
    -- Draw each status effect icon
    for effectType, effect in pairs(entity.status) do
        -- Skip if we've reached the maximum number of icons
        if count >= maxIcons then
            break
        end
        
        local effectDef = statusEffects.effects[effectType]
        if effectDef then
            -- Load the icon
            local icon = assetManager:getImage(effectDef.icon)
            if icon then
                -- Draw icon background based on status type
                local bgColor = {0.2, 0.2, 0.2, 0.7} -- Default background
                if type(effectDef.statusType) == "function" then
                    -- Handle dynamic status type (e.g., speed_multiplier depends on value)
                    local statusType = effectDef.statusType(effect.multiplier or 1)
                    if statusType == "positive" then
                        bgColor = {0.2, 0.5, 0.2, 0.7} -- Green for positive
                    elseif statusType == "negative" then
                        bgColor = {0.5, 0.2, 0.2, 0.7} -- Red for negative
                    end
                else
                    -- Static status type
                    if effectDef.statusType == "positive" then
                        bgColor = {0.2, 0.5, 0.2, 0.7} -- Green for positive
                    elseif effectDef.statusType == "negative" then
                        bgColor = {0.5, 0.2, 0.2, 0.7} -- Red for negative
                    end
                end
                
                -- Draw background circle
                love.graphics.setColor(unpack(bgColor))
                love.graphics.circle("fill", iconX + (effectDef.iconSize or 24) / 2, y + (effectDef.iconSize or 24) / 2, (effectDef.iconSize or 24) / 2 + 1)
                
                -- Draw icon
                love.graphics.setColor(1, 1, 1, 1)
                local iconSize = effectDef.iconSize or 24
                love.graphics.draw(icon, iconX, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
                
                -- Draw value or duration counter, depending on effect type
                if effectType == "barrier" then
                    -- For barrier, display the remaining barrier strength
                    love.graphics.setColor(0.3, 0.7, 0.9, 1) -- Barrier color
                    love.graphics.print(tostring(math.floor(effect.strength)), iconX + iconSize - 12, y + iconSize - 12)
                elseif effect.multiplier and effect.multiplier ~= 1 then
                    -- For multiplier effects, show the multiplier value
                    local textColor = effect.multiplier > 1 and {0.2, 0.9, 0.2, 1} or {0.9, 0.2, 0.2, 1}
                    love.graphics.setColor(unpack(textColor))
                    
                    -- Format multiplier for display: 1.25 -> x1.25, 0.75 -> x0.75
                    local multiplierText = string.format("x%.2f", effect.multiplier):gsub("%.?0+$", "")
                    love.graphics.print(multiplierText, iconX + 2, y + iconSize - 12)
                    
                    -- Also show duration
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(tostring(effect.duration), iconX + iconSize - 8, y)
                else
                    -- For other effects, show duration and strength if relevant
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(tostring(effect.duration), iconX + iconSize - 8, y + iconSize - 12)
                    
                    -- If effect has strength > 1, show it in top right
                    if effect.strength and effect.strength > 1 then
                        love.graphics.print(tostring(effect.strength), iconX + iconSize - 8, y)
                    end
                end
                
                -- Move to next position
                iconX = iconX + spacing
                count = count + 1
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- If entity has a barrier, draw an overlay bar showing barrier health
    if entity.status and entity.status["barrier"] and entity.status["barrier"].strength > 0 then
        local barrierStrength = entity.status["barrier"].strength
        local maxHP = entity.maxHP or 100
        local barrierWidth = math.min(100, (barrierStrength / maxHP) * 100)
        
        -- Position barrier bar above the health bar
        love.graphics.setColor(0.3, 0.7, 0.9, 0.7) -- Translucent blue for barrier
        love.graphics.rectangle("fill", x, y - 15, barrierWidth, 5)
        
        -- Draw border
        love.graphics.setColor(0.2, 0.6, 0.8, 1)
        love.graphics.rectangle("line", x, y - 15, barrierWidth, 5)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Draw a damage type icon with effectiveness text
-- @param damageType: string - The type of damage
-- @param x: number - The x-coordinate to draw
-- @param y: number - The y-coordinate to draw
-- @param multiplier: number - The damage multiplier for resistance/vulnerability
-- @param size: number - Size of the icon (default: 32)
-- @param duration: number - How long to display (default: 1.5 seconds)
-- @return lifetime: number - How long the display should remain visible
local function drawDamageTypeIcon(damageType, x, y, multiplier, size, duration)
    if not damageType then 
        return 0
    end
    
    size = size or 32
    duration = duration or 1.5
    
    -- Get damage type definition
    local typeDef = damageTypes.types[damageType]
    if not typeDef then
        return 0
    end
    
    -- Load the icon
    local icon = assetManager:getImage(typeDef.icon)
    if not icon then
        return 0
    end
    
    -- Set color based on damage type
    love.graphics.setColor(unpack(typeDef.color))
    
    -- Draw background circle
    love.graphics.circle("fill", x + size/2, y + size/2, size/2 + 2)
    
    -- Draw icon
    love.graphics.setColor(1, 1, 1, 1)
    local iconSize = typeDef.iconSize or 24
    love.graphics.draw(icon, x + (size - iconSize)/2, y + (size - iconSize)/2, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
    
    -- Get and draw effectiveness text if applicable
    local text, textColor = damageTypes:getDisplayText(multiplier)
    if text then
        love.graphics.setColor(unpack(textColor))
        love.graphics.print(text, x + size + 5, y + size/2 - 8)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Return the duration to display
    return duration
end

return {
    showActionButtons = showActionButtons,
    hideActionButtons = hideActionButtons,
    hideSelectionLists = hideSelectionLists,
    showConfirmBackButtons = showConfirmBackButtons,
    hideAllUI = hideAllUI,
    drawStatusEffects = drawStatusEffects,
    drawDamageTypeIcon = drawDamageTypeIcon
}