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
    
    -- Also hide item-specific buttons
    if self.elements.itemConfirmButton then
        self.elements.itemConfirmButton.visible = false
    end
    if self.elements.itemBackButton then
        self.elements.itemBackButton.visible = false
    end
    
    -- Hide confirm and back buttons
    if self.elements.confirmButton then
        self.elements.confirmButton.visible = false
    end
    if self.elements.backButton then
        self.elements.backButton.visible = false
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
                if effectDef.statusType == "positive" then
                    bgColor = {0.2, 0.5, 0.2, 0.7} -- Green for positive
                elseif effectDef.statusType == "negative" then
                    bgColor = {0.5, 0.2, 0.2, 0.7} -- Red for negative
                end
                
                -- Draw background circle
                love.graphics.setColor(unpack(bgColor))
                love.graphics.circle("fill", iconX + (effectDef.iconSize or 24) / 2, y + (effectDef.iconSize or 24) / 2, (effectDef.iconSize or 24) / 2 + 1)
                
                -- Draw icon
                love.graphics.setColor(1, 1, 1, 1)
                local iconSize = effectDef.iconSize or 24
                love.graphics.draw(icon, iconX, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
                
                -- Draw duration counter
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(effect.duration), iconX + iconSize - 8, y + iconSize - 12)
                
                -- Move to next position
                iconX = iconX + spacing
                count = count + 1
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
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