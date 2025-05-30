local assetManager = require("assets/assetManager")
local statusEffects = require("gameplay/statusEffects")

local partyPanelLuis = {}

function partyPanelLuis:create()
    -- Calculate grid dimensions (40 units wide, 4 units high)
    local panelWidth = 40
    local panelHeight = 4
    
    -- Position at bottom of screen (assuming 22-unit high screen at grid size 32)
    local panelRow = 19  -- Bottom area
    local panelCol = 1   -- Left aligned
    
    -- Create main FlexContainer for the party panel
    self.container = luis.newFlexContainer(panelWidth, panelHeight, panelRow, panelCol, nil, "PartyPanel")
    
    -- Combat-specific properties
    self.activeCharacterIndex = nil
    self.inCombat = false
    self.combatParty = nil
    
    -- Character containers for each party member (4 max)
    self.characterContainers = {}
    
    -- Create individual character containers
    for i = 1, 4 do
        local charContainer = luis.newFlexContainer(9, 4, 1, 1, nil, "Character" .. i)
        
        -- Character portrait (icon)
        local portrait = luis.newIcon("assets/images/portraits/default.png", 2, 1, 1)
        charContainer:addChild(portrait)
        
        -- Character info container
        local infoContainer = luis.newFlexContainer(7, 4, 1, 1, nil, "CharInfo" .. i)
        
        -- Character name
        local nameLabel = luis.newLabel("", 7, 1, 1, 1, "left")
        infoContainer:addChild(nameLabel)
        
        -- Character job and level
        local jobLabel = luis.newLabel("", 7, 1, 1, 1, "left")
        infoContainer:addChild(jobLabel)
        
        -- HP progress bar
        local hpBar = luis.newProgressBar(0, 7, 1, 1, 1)
        infoContainer:addChild(hpBar)
        
        -- MP progress bar
        local mpBar = luis.newProgressBar(0, 7, 1, 1, 1)
        infoContainer:addChild(mpBar)
        
        charContainer:addChild(infoContainer)
        
        -- Status effects container
        local statusContainer = luis.newFlexContainer(7, 1, 1, 1, nil, "Status" .. i)
        infoContainer:addChild(statusContainer)
        
        -- Store references for easy access
        self.characterContainers[i] = {
            container = charContainer,
            portrait = portrait,
            nameLabel = nameLabel,
            jobLabel = jobLabel,
            hpBar = hpBar,
            mpBar = mpBar,
            statusContainer = statusContainer,
            infoContainer = infoContainer
        }
        
        self.container:addChild(charContainer)
    end
    
    return self.container
end

function partyPanelLuis:setActiveCharacter(index)
    self.activeCharacterIndex = index
    self:updateHighlight()
end

function partyPanelLuis:setCombatMode(isInCombat, party)
    self.inCombat = isInCombat
    self.combatParty = party
    self:updatePartyData()
end

function partyPanelLuis:updateHighlight()
    -- Update visual highlighting for active character in combat
    for i, charContainer in ipairs(self.characterContainers) do
        if self.activeCharacterIndex == i and self.inCombat then
            -- Apply a decorator or theme change to highlight active character
            charContainer.container:setDecorator("GlowDecorator", {0.3, 0.3, 0.7, 0.7}, 5)
        else
            -- Remove highlighting
            charContainer.container:setDecorator(nil)
        end
    end
end

function partyPanelLuis:updatePartyData()
    local party = self.combatParty or GAME.party
    if not party then return end
    
    for i, charContainer in ipairs(self.characterContainers) do
        local character = party[i]
        
        if character then
            -- Update character portrait
            if character.portraitId and assetManager.images.portraits[character.portraitId] then
                charContainer.portrait.iconPath = assetManager.images.portraits[character.portraitId]
            elseif assetManager.images.profiles[character.profileIndex] then
                charContainer.portrait.iconPath = assetManager.images.profiles[character.profileIndex]
            end
            
            -- Update character name
            charContainer.nameLabel.text = character.name
            
            -- Update job and level
            local currentJobLevel = character.jobLevels[character.job] or 1
            charContainer.jobLabel.text = character.job .. " Lv." .. currentJobLevel
            
            -- Update HP bar
            local hpPercent = character.currentHP / character.maxHP
            charContainer.hpBar.value = hpPercent * 100
            charContainer.hpBar.text = character.currentHP .. "/" .. character.maxHP
            
            -- Update MP bar
            local mpPercent = character.currentMP / character.maxMP
            charContainer.mpBar.value = mpPercent * 100
            charContainer.mpBar.text = character.currentMP .. "/" .. character.maxMP
            
            -- Update status effects
            self:updateStatusEffects(i, character)
            
            -- Make container visible
            charContainer.container:setVisible(true)
        else
            -- Hide unused character slots
            charContainer.container:setVisible(false)
        end
    end
    
    self:updateHighlight()
end

function partyPanelLuis:updateStatusEffects(characterIndex, character)
    local charContainer = self.characterContainers[characterIndex]
    if not charContainer or not character.status then return end
    
    -- Clear existing status effect icons
    charContainer.statusContainer.children = {}
    
    -- Add status effect icons
    local iconIndex = 0
    for effectType, effect in pairs(character.status) do
        if statusEffects.effects[effectType] and iconIndex < 5 then -- Limit to 5 status icons
            local effectInfo = statusEffects.effects[effectType]
            
            -- Create status icon
            local statusIcon = luis.newIcon("assets/images/status_effects/default.png", 1, 1, 1)
            
            -- Set icon based on effect type
            if effectInfo.icon and assetManager.images[effectInfo.icon] then
                statusIcon.iconPath = assetManager.images[effectInfo.icon]
            end
            
            -- Add tooltip or visual indicator for duration
            statusIcon.tooltip = effectInfo.name .. " (" .. effect.duration .. ")"
            
            charContainer.statusContainer:addChild(statusIcon)
            iconIndex = iconIndex + 1
        end
    end
end

function partyPanelLuis:show()
    if self.container then
        self.container:setVisible(true)
    end
end

function partyPanelLuis:hide()
    if self.container then
        self.container:setVisible(false)
    end
end

function partyPanelLuis:update()
    -- Update party data if needed
    self:updatePartyData()
end

return partyPanelLuis 