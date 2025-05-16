local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local statusEffects = require("gameplay/statusEffects")

    
-- Create party status panel
local partyPanel = {
    x = 20,
    y = GAME.height - 120,
    width = GAME.width - 40,
    height = 100,
    
    -- Combat-specific properties
    activeCharacterIndex = nil,
    inCombat = false,
    combatParty = nil,
    
    -- Set active character index for combat highlighting
    setActiveCharacter = function(self, index)
        self.activeCharacterIndex = index
    end,
    
    -- Set combat mode
    setCombatMode = function(self, isInCombat, party)
        self.inCombat = isInCombat
        self.combatParty = party
    end,
    
    -- Draw party panel in combat mode
    drawCombat = function(self)
        -- Draw panel background
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
        
        -- Check if we have a valid combat party reference
        if not self.combatParty then return end
        
        -- Draw party members
        for i, character in ipairs(self.combatParty) do
            local x = self.x + 10 + (i-1) * ((self.width - 20) / 4)
            local width = (self.width - 20) / 4 - 10
            
            -- Set up portrait area
            local portraitScale = 1.1
            local portraitSpace = 80
            local textStartX = x + portraitSpace
            local barStartX = textStartX
            local barWidth = width - portraitSpace - 10
            
            -- Draw background for this character slot
            if self.activeCharacterIndex == i then
                -- Highlight active character with a blue background
                love.graphics.setColor(0.3, 0.3, 0.7, 0.7)
            else
                love.graphics.setColor(0.25, 0.25, 0.35, 0.5)
            end
            love.graphics.rectangle("fill", x, self.y + 10, width, 80, 5, 5)
            
            -- Draw character portrait
            love.graphics.setColor(1, 1, 1)
            if character.portraitId and assetManager.images.portraits[character.portraitId] then
                love.graphics.draw(
                    assetManager.images.portraits[character.portraitId],
                    x + 5, self.y + 15,
                    0, portraitScale, portraitScale
                )
            elseif assetManager.images.profiles[character.profileIndex] then
                love.graphics.draw(
                    assetManager.images.profiles[character.profileIndex],
                    x + 5, self.y + 15,
                    0, portraitScale, portraitScale
                )
            end
            
            -- Draw character name
            love.graphics.setFont(screenManager.fonts.small)
            
            -- Show active/inactive status through text color
            if character.active then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
            end
            
            local nameWidth = screenManager.fonts.small:getWidth(character.name)
            if nameWidth > width - portraitSpace - 10 then
                -- Truncate name if too long
                local truncName = ""
                local j = 1
                while screenManager.fonts.small:getWidth(truncName .. "...") < width - portraitSpace - 10 and j <= #character.name do
                    truncName = truncName .. character.name:sub(j, j)
                    j = j + 1
                end
                love.graphics.print(truncName .. "...", textStartX, self.y + 15)
            else
                love.graphics.print(character.name, textStartX, self.y + 15)
            end
            
            -- Draw character job and level
            love.graphics.setColor(0.8, 0.8, 1)
            local currentJobLevel = character.jobLevels[character.job] or 1 -- Default to 1 if somehow missing
            love.graphics.print(
                character.job .. " Lv." .. currentJobLevel,
                textStartX, self.y + 30
            )
            
            -- Draw HP and MP bars
            -- HP bar
            local healthWidth = barWidth * (character.currentHP / character.maxHP)
            
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", barStartX, self.y + 50, barWidth, 8)
            
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", barStartX, self.y + 50, healthWidth, 8)
            
            -- Draw barrier HP overlay if present
            if character.status and character.status["barrier"] then
                local barrierHP = character.status["barrier"].strength or 0
                local barrierWidth = math.min(barWidth, (barrierHP / character.maxHP) * barWidth)
                
                love.graphics.setColor(0.4, 0.7, 1.0, 0.7)
                love.graphics.rectangle("fill", barStartX, self.y + 50, barrierWidth, 8)
            end
            
            -- MP bar
            local manaWidth = barWidth * (character.currentMP / character.maxMP)
            
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", barStartX, self.y + 75, barWidth, 8)
            
            love.graphics.setColor(0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", barStartX, self.y + 75, manaWidth, 8)
            
            -- Draw HP and MP values as small text near bars
            love.graphics.setFont(screenManager.fonts.small)
            
            -- HP value
            love.graphics.setColor(1, 0.7, 0.7)
            love.graphics.print(
                character.currentHP .. "/" .. character.maxHP,
                barStartX + barWidth - 60, self.y + 50 - 14
            )
            
            -- MP value
            love.graphics.setColor(0.7, 0.7, 1)
            love.graphics.print(
                character.currentMP .. "/" .. character.maxMP,
                barStartX + barWidth - 60, self.y + 75 - 14
            )
            
            -- Draw status effect icons
            if character.status then
                local statusIconSize = 16
                local statusIconSpacing = 2
                local maxIconsPerRow = 5
                local iconStartX = textStartX
                local iconStartY = self.y + 60
                local iconIndex = 0
                
                for effectType, effect in pairs(character.status) do
                    if statusEffects.effects[effectType] then
                        local effectInfo = statusEffects.effects[effectType]
                        local row = math.floor(iconIndex / maxIconsPerRow)
                        local col = iconIndex % maxIconsPerRow
                        
                        local iconX = iconStartX + col * (statusIconSize + statusIconSpacing)
                        local iconY = iconStartY + row * (statusIconSize + statusIconSpacing)
                        
                        -- Draw icon background based on effect type
                        if effectInfo.statusType == "positive" then
                            love.graphics.setColor(0.2, 0.7, 0.3, 0.7)
                        elseif effectInfo.statusType == "negative" then
                            love.graphics.setColor(0.7, 0.3, 0.2, 0.7)
                        else
                            love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
                        end
                        
                        love.graphics.rectangle("fill", iconX, iconY, statusIconSize, statusIconSize, 2, 2)
                        
                        -- Draw the icon if available
                        if effectInfo.icon and assetManager.images[effectInfo.icon] then
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.draw(
                                assetManager.images[effectInfo.icon],
                                iconX, iconY,
                                0, statusIconSize / effectInfo.iconSize, statusIconSize / effectInfo.iconSize
                            )
                        else
                            -- Draw a letter as fallback
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print(
                                effectInfo.name:sub(1, 1),
                                iconX + 4, iconY
                            )
                        end
                        
                        -- Draw effect duration
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print(
                            tostring(effect.duration),
                            iconX + statusIconSize - 5, iconY + statusIconSize - 10,
                            0, 0.6, 0.6
                        )
                        
                        iconIndex = iconIndex + 1
                    end
                end
            end
        end
    end,
    
    draw = function(self)
        -- If in combat mode, use combat-specific drawing
        if self.inCombat then
            self:drawCombat()
            return
        end
        
        -- Draw panel background
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
        
        -- Draw party members
        if GAME.party then
            for i, character in ipairs(GAME.party) do
                local x = self.x + 10 + (i-1) * ((self.width - 20) / 4)
                local width = (self.width - 20) / 4 - 10
                
                -- Set up portrait area
                local portraitScale = 1.1
                local portraitSpace = 80
                local textStartX = x + portraitSpace
                local barStartX = textStartX
                local barWidth = width - portraitSpace - 10
                
                -- Draw background for this character slot
                love.graphics.setColor(0.25, 0.25, 0.35, 0.5)
                love.graphics.rectangle("fill", x, self.y + 10, width, 80, 5, 5)
                
                -- Draw character portrait
                love.graphics.setColor(1, 1, 1)
                if character.portraitId and assetManager.images.portraits[character.portraitId] then
                    love.graphics.draw(
                        assetManager.images.portraits[character.portraitId],
                        x + 5, self.y + 15,
                        0, portraitScale, portraitScale
                    )
                elseif assetManager.images.profiles[character.profileIndex] then
                    love.graphics.draw(
                        assetManager.images.profiles[character.profileIndex],
                        x + 5, self.y + 15,
                        0, portraitScale, portraitScale
                    )
                end
                
                -- Draw character name
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                
                local nameWidth = screenManager.fonts.small:getWidth(character.name)
                if nameWidth > width - portraitSpace - 10 then
                    -- Truncate name if too long
                    local truncName = ""
                    local j = 1
                    while screenManager.fonts.small:getWidth(truncName .. "...") < width - portraitSpace - 10 and j <= #character.name do
                        truncName = truncName .. character.name:sub(j, j)
                        j = j + 1
                    end
                    love.graphics.print(truncName .. "...", textStartX, self.y + 15)
                else
                    love.graphics.print(character.name, textStartX, self.y + 15)
                end
                
                -- Draw character job and level
                love.graphics.setColor(0.8, 0.8, 1)
                local currentJobLevel = character.jobLevels[character.job] or 1 -- Default to 1 if somehow missing
                love.graphics.print(
                    character.job .. " Lv." .. currentJobLevel,
                    textStartX, self.y + 30
                )
                
                -- Draw HP and MP bars
                -- HP bar
                local healthWidth = barWidth * (character.currentHP / character.maxHP)
                
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", barStartX, self.y + 50, barWidth, 8)
                
                love.graphics.setColor(0.8, 0.2, 0.2)
                love.graphics.rectangle("fill", barStartX, self.y + 50, healthWidth, 8)
                
                -- Draw barrier HP overlay if present
                if character.status and character.status["barrier"] then
                    local barrierHP = character.status["barrier"].strength or 0
                    local barrierWidth = math.min(barWidth, (barrierHP / character.maxHP) * barWidth)
                    
                    love.graphics.setColor(0.4, 0.7, 1.0, 0.7)
                    love.graphics.rectangle("fill", barStartX, self.y + 50, barrierWidth, 8)
                end
                
                -- MP bar
                local manaWidth = barWidth * (character.currentMP / character.maxMP)
                
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", barStartX, self.y + 75, barWidth, 8)
                
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", barStartX, self.y + 75, manaWidth, 8)
                
                -- Draw HP and MP values as small text near bars
                love.graphics.setFont(screenManager.fonts.small)
                
                -- HP value
                love.graphics.setColor(1, 0.7, 0.7)
                love.graphics.print(
                    character.currentHP .. "/" .. character.maxHP,
                    barStartX + barWidth - 60, self.y + 50 - 14
                )
                
                -- MP value
                love.graphics.setColor(0.7, 0.7, 1)
                love.graphics.print(
                    character.currentMP .. "/" .. character.maxMP,
                    barStartX + barWidth - 60, self.y + 75 - 14
                )
                
                -- Draw status effect icons
                if character.status then
                    local statusIconSize = 16
                    local statusIconSpacing = 2
                    local maxIconsPerRow = 5
                    local iconStartX = textStartX
                    local iconStartY = self.y + 60
                    local iconIndex = 0
                    
                    for effectType, effect in pairs(character.status) do
                        if statusEffects.effects[effectType] then
                            local effectInfo = statusEffects.effects[effectType]
                            local row = math.floor(iconIndex / maxIconsPerRow)
                            local col = iconIndex % maxIconsPerRow
                            
                            local iconX = iconStartX + col * (statusIconSize + statusIconSpacing)
                            local iconY = iconStartY + row * (statusIconSize + statusIconSpacing)
                            
                            -- Draw icon background based on effect type
                            if effectInfo.statusType == "positive" then
                                love.graphics.setColor(0.2, 0.7, 0.3, 0.7)
                            elseif effectInfo.statusType == "negative" then
                                love.graphics.setColor(0.7, 0.3, 0.2, 0.7)
                            else
                                love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
                            end
                            
                            love.graphics.rectangle("fill", iconX, iconY, statusIconSize, statusIconSize, 2, 2)
                            
                            -- Draw the icon if available
                            if effectInfo.icon and assetManager.images[effectInfo.icon] then
                                love.graphics.setColor(1, 1, 1)
                                love.graphics.draw(
                                    assetManager.images[effectInfo.icon],
                                    iconX, iconY,
                                    0, statusIconSize / effectInfo.iconSize, statusIconSize / effectInfo.iconSize
                                )
                            else
                                -- Draw a letter as fallback
                                love.graphics.setColor(1, 1, 1)
                                love.graphics.print(
                                    effectInfo.name:sub(1, 1),
                                    iconX + 4, iconY
                                )
                            end
                            
                            -- Draw effect duration
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print(
                                tostring(effect.duration),
                                iconX + statusIconSize - 5, iconY + statusIconSize - 10,
                                0, 0.6, 0.6
                            )
                            
                            iconIndex = iconIndex + 1
                        end
                    end
                end
            end
        end
    end
}

return partyPanel
