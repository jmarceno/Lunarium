-- Character Info Screen (LUIS)
-- Where players can view detailed information about party members
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local characterSystem = require("gameplay/character")
local itemSystem = require("gameplay/item")
local skillSystem = require("gameplay/skill")

-- Get LUIS instance
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

local characterInfo = screenManager:createScreen("Character Info")

function characterInfo:init()
    -- Initialize state
    self.state = "main"
    self.selectedCharacter = nil
    self.activeTab = "stats" -- stats, equipment, skills
    self.scrollOffsetY = 0
    self.scrollSpeed = 20
    
    -- Create LUIS layers
    luis.newLayer("characterInfoLayer")
    
    -- Create UI elements
    self:createUI()
end

function characterInfo:createUI()
    -- Main container (40x22 grid)
    local mainContainer = luis.createElement("characterInfoLayer", "FlexContainer", 38, 20, 1, 1, nil, "CharacterInfoMain")
    
    -- Left sidebar for character selection
    local charactersContainer = luis.newFlexContainer(12, 18, 1, 1, nil, "CharactersList")
    
    -- Character list title
    local charactersTitle = luis.newLabel("Party Members", 12, 2, 1, 1, "center")
    charactersContainer:addChild(charactersTitle)
    
    -- Character selection area
    self.characterSelectContainer = luis.newFlexContainer(12, 14, 1, 1, nil, "CharacterSelect")
    charactersContainer:addChild(self.characterSelectContainer)
    
    -- Back button
    local backButton = luis.newButton("Back", 8, 2, function() self:goBack() end, nil, 1, 1)
    charactersContainer:addChild(backButton)
    
    mainContainer:addChild(charactersContainer)
    
    -- Right section for character details
    local detailsContainer = luis.newFlexContainer(26, 18, 1, 1, nil, "CharacterDetails")
    
    -- Tab buttons container
    local tabContainer = luis.newFlexContainer(26, 2, 1, 1, nil, "TabButtons")
    
    self.statsTabButton = luis.newButton("Stats", 8, 2, function() self:selectTab("stats") end, nil, 1, 1)
    self.equipmentTabButton = luis.newButton("Equipment", 8, 2, function() self:selectTab("equipment") end, nil, 1, 1)
    self.skillsTabButton = luis.newButton("Skills", 8, 2, function() self:selectTab("skills") end, nil, 1, 1)
    
    tabContainer:addChild(self.statsTabButton)
    tabContainer:addChild(self.equipmentTabButton)
    tabContainer:addChild(self.skillsTabButton)
    
    detailsContainer:addChild(tabContainer)
    
    -- Content area for the selected tab
    self.contentContainer = luis.newFlexContainer(26, 16, 1, 1, nil, "TabContent")
    detailsContainer:addChild(self.contentContainer)
    
    mainContainer:addChild(detailsContainer)
    
    -- Store references
    self.uiElements = {
        mainContainer = mainContainer,
        charactersContainer = charactersContainer,
        characterSelectContainer = self.characterSelectContainer,
        detailsContainer = detailsContainer,
        tabContainer = tabContainer,
        contentContainer = self.contentContainer,
        statsTabButton = self.statsTabButton,
        equipmentTabButton = self.equipmentTabButton,
        skillsTabButton = self.skillsTabButton,
        backButton = backButton
    }
    
    -- Create different tab content areas
    self:createStatsTabContent()
    self:createEquipmentTabContent()
    self:createSkillsTabContent()
    
    -- Initial setup
    self:refreshCharacterList()
    self:selectTab("stats")
end

function characterInfo:createStatsTabContent()
    -- Stats tab content container
    self.statsContainer = luis.newFlexContainer(24, 14, 1, 1, nil, "StatsContent")
    
    -- Character name and basic info
    self.characterNameLabel = luis.newLabel("No character selected", 24, 2, 1, 1, "center")
    self.statsContainer:addChild(self.characterNameLabel)
    
    -- Attributes section
    self.attributesLabel = luis.newLabel("Attributes", 24, 1, 1, 1, "left")
    self.statsContainer:addChild(self.attributesLabel)
    
    self.attributesContentLabel = luis.newLabel("", 24, 6, 1, 1, "left")
    self.statsContainer:addChild(self.attributesContentLabel)
    
    -- Combat stats section
    self.combatStatsLabel = luis.newLabel("Combat Stats", 24, 1, 1, 1, "left")
    self.statsContainer:addChild(self.combatStatsLabel)
    
    self.combatStatsContentLabel = luis.newLabel("", 24, 4, 1, 1, "left")
    self.statsContainer:addChild(self.combatStatsContentLabel)
    
    self.contentContainer:addChild(self.statsContainer)
end

function characterInfo:createEquipmentTabContent()
    -- Equipment tab content container
    self.equipmentContainer = luis.newFlexContainer(24, 14, 1, 1, nil, "EquipmentContent")
    
    -- Equipment title
    self.equipmentTitleLabel = luis.newLabel("Equipment", 24, 2, 1, 1, "center")
    self.equipmentContainer:addChild(self.equipmentTitleLabel)
    
    -- Equipment details
    self.equipmentDetailsLabel = luis.newLabel("Select a character to view equipment", 24, 12, 1, 1, "left")
    self.equipmentContainer:addChild(self.equipmentDetailsLabel)
    
    self.contentContainer:addChild(self.equipmentContainer)
end

function characterInfo:createSkillsTabContent()
    -- Skills tab content container
    self.skillsContainer = luis.newFlexContainer(24, 14, 1, 1, nil, "SkillsContent")
    
    -- Skills title
    self.skillsTitleLabel = luis.newLabel("Skills", 24, 2, 1, 1, "center")
    self.skillsContainer:addChild(self.skillsTitleLabel)
    
    -- Skills details
    self.skillsDetailsLabel = luis.newLabel("Select a character to view skills", 24, 12, 1, 1, "left")
    self.skillsContainer:addChild(self.skillsDetailsLabel)
    
    self.contentContainer:addChild(self.skillsContainer)
end

function characterInfo:updateTabHighlighting()
    -- Update tab button appearances based on active tab
    if self.activeTab == "stats" then
        self.elements.statsTab.colors = {
            normal = {0.3, 0.3, 0.6},
            hover = {0.4, 0.4, 0.7},
            press = {0.2, 0.2, 0.5}
        }
    else
        self.elements.statsTab.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
    end
    
    if self.activeTab == "equipment" then
        self.elements.equipmentTab.colors = {
            normal = {0.3, 0.3, 0.6},
            hover = {0.4, 0.4, 0.7},
            press = {0.2, 0.2, 0.5}
        }
    else
        self.elements.equipmentTab.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
    end
    
    if self.activeTab == "skills" then
        self.elements.skillsTab.colors = {
            normal = {0.3, 0.3, 0.6},
            hover = {0.4, 0.4, 0.7},
            press = {0.2, 0.2, 0.5}
        }
    else
        self.elements.skillsTab.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
    end
end

function characterInfo:enter()
    -- Enable character info layer
    luis.enableLayer("characterInfoLayer")
    
    -- Refresh character list and select first character if available
    self:refreshCharacterList()
    if GAME.party and #GAME.party > 0 then
        self:selectCharacter(GAME.party[1])
    end
    
    -- Start with stats tab
    self:selectTab("stats")
end

function characterInfo:exit()
    -- Disable character info layer
    luis.disableLayer("characterInfoLayer")
end

function characterInfo:refreshCharacterList()
    -- Clear existing character buttons
    self.characterSelectContainer.children = {}
    
    if not GAME.party or #GAME.party == 0 then
        local noPartyLabel = luis.newLabel("No party members", 12, 2, 1, 1, "center")
        self.characterSelectContainer:addChild(noPartyLabel)
        return
    end
    
    -- Create buttons for each party member
    self.characterButtons = {}
    for i, character in ipairs(GAME.party) do
        local characterButton = luis.newButton(character.name, 11, 3, 
            function() self:selectCharacter(character) end, nil, 1, 1)
        
        self.characterSelectContainer:addChild(characterButton)
        self.characterButtons[i] = characterButton
    end
end

function characterInfo:selectCharacter(character)
    self.selectedCharacter = character
    
    -- Update character button highlighting
    if self.characterButtons then
        for i, button in ipairs(self.characterButtons) do
            if GAME.party[i] == character then
                button:setTheme({backgroundColor = {0.3, 0.5, 0.8}})
            else
                button:setTheme({backgroundColor = {0.2, 0.2, 0.3}})
            end
        end
    end
    
    -- Update content based on active tab
    self:updateTabContent()
end

function characterInfo:selectTab(tabName)
    self.activeTab = tabName
    
    -- Update tab button highlighting
    local activeColor = {0.3, 0.5, 0.8}
    local inactiveColor = {0.2, 0.2, 0.3}
    
    self.statsTabButton:setTheme({backgroundColor = tabName == "stats" and activeColor or inactiveColor})
    self.equipmentTabButton:setTheme({backgroundColor = tabName == "equipment" and activeColor or inactiveColor})
    self.skillsTabButton:setTheme({backgroundColor = tabName == "skills" and activeColor or inactiveColor})
    
    -- Show/hide appropriate containers
    self.statsContainer:setVisible(tabName == "stats")
    self.equipmentContainer:setVisible(tabName == "equipment")
    self.skillsContainer:setVisible(tabName == "skills")
    
    -- Update content
    self:updateTabContent()
end

function characterInfo:updateTabContent()
    if not self.selectedCharacter then return end
    
    local char = self.selectedCharacter
    
    if self.activeTab == "stats" then
        -- Update character name
        self.characterNameLabel.text = char.name .. " - " .. char.job .. " Lv." .. (char.jobLevels[char.job] or 1)
        
        -- Update attributes
        local attributesText = ""
        local attrs = {"STR", "INT", "CON", "WIL", "CHA", "DEX", "WIS"}
        local attrLabels = {
            STR = "Strength", INT = "Intelligence", CON = "Constitution",
            WIL = "Will", CHA = "Charisma", DEX = "Dexterity", WIS = "Wisdom"
        }
        
        for _, attr in ipairs(attrs) do
            attributesText = attributesText .. attrLabels[attr] .. ": " .. (char.attributes[attr] or 0) .. "\n"
        end
        self.attributesContentLabel.text = attributesText
        
        -- Update combat stats
        local combatStatsText = ""
        combatStatsText = combatStatsText .. "HP: " .. char.currentHP .. " / " .. char.maxHP .. "\n"
        combatStatsText = combatStatsText .. "MP: " .. char.currentMP .. " / " .. char.maxMP .. "\n"
        combatStatsText = combatStatsText .. "Attack: " .. characterSystem:calculateAttackPower(char) .. "\n"
        combatStatsText = combatStatsText .. "Defense: " .. characterSystem:calculateDefense(char) .. "\n"
        combatStatsText = combatStatsText .. "Magic: " .. characterSystem:calculateMagicPower(char) .. "\n"
        combatStatsText = combatStatsText .. "Magic Def: " .. characterSystem:calculateMagicDefense(char)
        self.combatStatsContentLabel.text = combatStatsText
        
    elseif self.activeTab == "equipment" then
        -- Update equipment details
        local equipmentText = ""
        local slots = {
            {name = "Weapon", key = "weapon"}, {name = "Offhand", key = "offhand"},
            {name = "Head", key = "head"}, {name = "Body", key = "body"},
            {name = "Amulet", key = "amulet"}, {name = "Ring", key = "ring"}
        }
        
        for _, slot in ipairs(slots) do
            local item = char.equipment and char.equipment[slot.key]
            equipmentText = equipmentText .. slot.name .. ": "
            if item then
                equipmentText = equipmentText .. item.name
                if item.attack then equipmentText = equipmentText .. " (ATK: " .. item.attack .. ")" end
                if item.defense then equipmentText = equipmentText .. " (DEF: " .. item.defense .. ")" end
            else
                equipmentText = equipmentText .. "None"
            end
            equipmentText = equipmentText .. "\n"
        end
        self.equipmentDetailsLabel.text = equipmentText
        
    elseif self.activeTab == "skills" then
        -- Update skills details
        local skillsText = ""
        if not char.skills or not next(char.skills) then
            skillsText = "No skills learned"
        else
            local sortedSkillNames = {}
            for name, _ in pairs(char.skills) do
                table.insert(sortedSkillNames, name)
            end
            table.sort(sortedSkillNames)
            
            for _, skillName in ipairs(sortedSkillNames) do
                local skillData = char.skills[skillName]
                local skill = skillSystem:getSkill(skillName)
                if skill then
                    skillsText = skillsText .. skill.name .. " Lv." .. skillData.level
                    if skill.mpCost and skill.mpCost > 0 then
                        skillsText = skillsText .. " (MP: " .. skill.mpCost .. ")"
                    end
                    skillsText = skillsText .. "\n"
                    if skill.description then
                        skillsText = skillsText .. "  " .. skill.description .. "\n"
                    end
                    skillsText = skillsText .. "\n"
                end
            end
        end
        self.skillsDetailsLabel.text = skillsText
    end
end

function characterInfo:goBack()
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

function characterInfo:update(dt)
    -- LUIS handles all UI updates automatically
end

function characterInfo:draw()
    -- Draw background
    love.graphics.clear(0.1, 0.1, 0.15)
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.title)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Character Information"
    local titleWidth = screenManager.fonts.title:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 20)
    
    -- LUIS handles all UI rendering automatically via main.lua
end

-- Remove all legacy UI input handling as LUIS handles it now

return characterInfo 