-- Character Details Screen
-- Where players can view character stats and skills
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local characterSystem = require("gameplay/character")
local skillSystem = require("gameplay/skill")
local jobSystem = require("gameplay/job")

local characterDetails = screenManager:createScreen("Character Details")

function characterDetails:init()
    -- Initialize state
    self.state = "main" -- main, skills, attributes
    self.selectedCharacter = nil
    self.selectedSkill = nil
    self.selectedTab = "Stats"
    self.skillsScrollOffset = 0
    
    -- Tabs
    self.tabs = {
        "Stats",
        "Skills",
        "Equipment",
        "Job"
    }
    
    -- Create UI elements
    self:createUI()
end

function characterDetails:createUI()
    -- Create character selection tabs
    self.elements.characterTabs = {
        x = 20,
        y = 50,
        width = GAME.width - 40,
        height = 30,
        
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw character tabs
            if GAME.party then
                local tabWidth = self.width / #GAME.party
                
                for i, character in ipairs(GAME.party) do
                    local x = self.x + (i-1) * tabWidth
                    
                    -- Draw tab background
                    if characterDetails.selectedCharacter == character then
                        love.graphics.setColor(0.3, 0.5, 0.8)
                    else
                        love.graphics.setColor(0.3, 0.3, 0.5)
                    end
                    
                    love.graphics.rectangle("fill", x, self.y, tabWidth - 2, self.height, 5, 5)
                    
                    -- Draw character name
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    local nameWidth = screenManager.fonts.small:getWidth(character.name)
                    love.graphics.print(
                        character.name,
                        x + (tabWidth - nameWidth) / 2,
                        self.y + 5
                    )
                end
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within tabs
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check character tabs
                if GAME.party then
                    local tabWidth = self.width / #GAME.party
                    
                    for i, character in ipairs(GAME.party) do
                        local tabX = self.x + (i-1) * tabWidth
                        
                        if x >= tabX and x <= tabX + tabWidth - 2 then
                            characterDetails:selectCharacter(character)
                            return true
                        end
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create info tabs
    self.elements.infoTabs = {
        x = 20,
        y = 90,
        width = GAME.width - 40,
        height = 30,
        
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw tabs
            local tabWidth = self.width / #characterDetails.tabs
            
            for i, tab in ipairs(characterDetails.tabs) do
                local x = self.x + (i-1) * tabWidth
                
                -- Draw tab background
                if characterDetails.selectedTab == tab then
                    love.graphics.setColor(0.3, 0.5, 0.8)
                else
                    love.graphics.setColor(0.3, 0.3, 0.5)
                end
                
                love.graphics.rectangle("fill", x, self.y, tabWidth - 2, self.height, 5, 5)
                
                -- Draw tab name
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                
                local tabNameWidth = screenManager.fonts.small:getWidth(tab)
                love.graphics.print(
                    tab,
                    x + (tabWidth - tabNameWidth) / 2,
                    self.y + 5
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within tabs
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check tabs
                local tabWidth = self.width / #characterDetails.tabs
                
                for i, tab in ipairs(characterDetails.tabs) do
                    local tabX = self.x + (i-1) * tabWidth
                    
                    if x >= tabX and x <= tabX + tabWidth - 2 then
                        characterDetails:selectTab(tab)
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create stats panel
    self.elements.statsPanel = {
        x = 20,
        y = 130,
        width = GAME.width - 40,
        height = GAME.height - 200,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Character Stats", self.x, self.y, self.width, self.height)
            
            -- Draw character stats
            if characterDetails.selectedCharacter then
                local char = characterDetails.selectedCharacter
                
                -- Draw character profile
                love.graphics.setColor(1, 1, 1)
                if assetManager.images.profiles[char.profileIndex] then
                    love.graphics.draw(
                        assetManager.images.profiles[char.profileIndex],
                        self.x + 30, self.y + 50
                    )
                end
                
                -- Draw character name and job
                love.graphics.setFont(screenManager.fonts.large)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    char.name,
                    self.x + 110, self.y + 50
                )
                
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.8, 0.8, 1)
                
                love.graphics.print(
                    "Level " .. char.level .. " " .. char.job,
                    self.x + 110, self.y + 80
                )
                
                -- Draw experience
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.7, 0.7, 1)
                
                love.graphics.print(
                    "Experience: " .. char.experience .. " / " .. char.experienceToNext,
                    self.x + 110, self.y + 110
                )
                
                -- Draw HP and MP
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "HP: " .. char.currentHP .. " / " .. char.maxHP,
                    self.x + 250, self.y + 50
                )
                
                love.graphics.print(
                    "MP: " .. char.currentMP .. " / " .. char.maxMP,
                    self.x + 250, self.y + 80
                )
                
                -- Draw attributes
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Attributes",
                    self.x + 30, self.y + 150
                )
                
                love.graphics.setFont(screenManager.fonts.small)
                
                -- Draw each attribute
                local attrY = self.y + 180
                for _, attr in ipairs(characterSystem.attributes) do
                    love.graphics.setColor(0.9, 0.9, 0.9)
                    love.graphics.print(
                        attr .. ": " .. char.attributes[attr],
                        self.x + 50, attrY
                    )
                    attrY = attrY + 25
                end
                
                -- Draw derived stats
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Combat Stats",
                    self.x + 250, self.y + 150
                )
                
                love.graphics.setFont(screenManager.fonts.small)
                
                -- Calculate and draw combat stats
                local statY = self.y + 180
                
                -- Attack power
                local attackPower = characterSystem:calculateAttackPower(char)
                love.graphics.setColor(0.9, 0.9, 0.9)
                love.graphics.print(
                    "Attack Power: " .. attackPower,
                    self.x + 270, statY
                )
                statY = statY + 25
                
                -- Magic power
                local magicPower = characterSystem:calculateMagicPower(char)
                love.graphics.print(
                    "Magic Power: " .. magicPower,
                    self.x + 270, statY
                )
                statY = statY + 25
                
                -- Defense
                local defense = characterSystem:calculateDefense(char)
                love.graphics.print(
                    "Defense: " .. defense,
                    self.x + 270, statY
                )
                statY = statY + 25
                
                -- Magic defense
                local magicDefense = characterSystem:calculateMagicDefense(char)
                love.graphics.print(
                    "Magic Defense: " .. magicDefense,
                    self.x + 270, statY
                )
                statY = statY + 25
                
                -- Hit chance
                local meleeHit = characterSystem:calculateMeleeHitChance(
                    char.attributes.STR, char.attributes.DEX
                )
                love.graphics.print(
                    "Melee Hit: " .. math.floor(meleeHit) .. "%",
                    self.x + 270, statY
                )
                statY = statY + 25
                
                local rangedHit = characterSystem:calculateRangedHitChance(
                    char.attributes.DEX, char.attributes.STR
                )
                love.graphics.print(
                    "Ranged Hit: " .. math.floor(rangedHit) .. "%",
                    self.x + 270, statY
                )
            end
        end
    }
    
    -- Create skills panel
    self.elements.skillsPanel = {
        x = 20,
        y = 130,
        width = GAME.width - 40,
        height = GAME.height - 200,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Character Skills", self.x, self.y, self.width, self.height)
            
            -- Draw character skills
            if characterDetails.selectedCharacter then
                local char = characterDetails.selectedCharacter
                
                -- Draw skill points
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Skill Points: " .. char.skillPoints,
                    self.x + 30, self.y + 50
                )
                
                -- Group skills by type
                local skillsByType = {
                    physical = {},
                    magical = {},
                    healing = {},
                    support = {},
                    utility = {}
                }
                
                for skillName, skillInfo in pairs(char.skills) do
                    local skill = skillSystem:getSkill(skillName)
                    if skill then
                        table.insert(skillsByType[skill.type or "utility"], {
                            name = skillName,
                            info = skillInfo,
                            skill = skill
                        })
                    end
                end
                
                -- Sort skills by name within each type
                for _, skills in pairs(skillsByType) do
                    table.sort(skills, function(a, b)
                        return a.name < b.name
                    end)
                end
                
                -- Draw skills by type
                local typeOrder = {"physical", "magical", "healing", "support", "utility"}
                local typeNames = {
                    physical = "Physical Skills",
                    magical = "Magical Skills",
                    healing = "Healing Skills",
                    support = "Support Skills",
                    utility = "Utility Skills"
                }
                
                local skillY = self.y + 80
                local leftColumn = self.x + 30
                local rightColumn = self.x + self.width / 2 + 10
                local columnWidth = self.width / 2 - 40
                
                local currentColumn = leftColumn
                local currentWidth = columnWidth
                
                for _, skillType in ipairs(typeOrder) do
                    local skills = skillsByType[skillType]
                    
                    if #skills > 0 then
                        -- Draw skill type header
                        love.graphics.setFont(screenManager.fonts.medium)
                        love.graphics.setColor(1, 1, 1)
                        
                        love.graphics.print(
                            typeNames[skillType],
                            currentColumn, skillY
                        )
                        skillY = skillY + 30
                        
                        -- Draw skills
                        love.graphics.setFont(screenManager.fonts.small)
                        
                        for _, skillEntry in ipairs(skills) do
                            -- Background for selected skill
                            if characterDetails.selectedSkill == skillEntry then
                                love.graphics.setColor(0.3, 0.3, 0.5)
                                love.graphics.rectangle(
                                    "fill",
                                    currentColumn - 5, skillY - 2,
                                    currentWidth, 25,
                                    5, 5
                                )
                            end
                            
                            -- Skill name and level
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print(
                                skillEntry.name .. " (Lv. " .. skillEntry.info.level .. ")",
                                currentColumn, skillY
                            )
                            
                            -- MP cost
                            love.graphics.setColor(0.5, 0.5, 1)
                            love.graphics.print(
                                "MP: " .. skillEntry.skill.mpCost,
                                currentColumn + currentWidth - 70, skillY
                            )
                            
                            skillY = skillY + 25
                            
                            -- Switch to right column if reaching bottom
                            if skillY > self.y + self.height - 50 and currentColumn == leftColumn then
                                currentColumn = rightColumn
                                skillY = self.y + 80
                            end
                        end
                        
                        -- Add space after each type
                        skillY = skillY + 10
                    end
                end
                
                -- Draw skill details if a skill is selected
                if characterDetails.selectedSkill then
                    local skill = characterDetails.selectedSkill.skill
                    
                    -- Background for details
                    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
                    love.graphics.rectangle(
                        "fill",
                        self.x + 30, self.y + self.height - 140,
                        self.width - 60, 120,
                        10, 10
                    )
                    
                    -- Skill name
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        characterDetails.selectedSkill.name,
                        self.x + 40, self.y + self.height - 130
                    )
                    
                    -- Skill description
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.9, 0.9, 0.9)
                    
                    love.graphics.printf(
                        skill.description,
                        self.x + 40, self.y + self.height - 100,
                        self.width - 80, "left"
                    )
                    
                    -- Skill details
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.7, 0.7, 1)
                    
                    local detailsText = "Type: " .. skill.type
                    
                    if skill.element then
                        detailsText = detailsText .. " (" .. skill.element .. ")"
                    end
                    
                    detailsText = detailsText .. "  |  MP Cost: " .. skill.mpCost
                    
                    if skill.basePower then
                        detailsText = detailsText .. "  |  Power: " .. skill.basePower
                    end
                    
                    love.graphics.print(
                        detailsText,
                        self.x + 40, self.y + self.height - 50
                    )
                end
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height - 140 then
                
                -- Handle skill selection
                if characterDetails.selectedCharacter then
                    local char = characterDetails.selectedCharacter
                    
                    -- Group skills by type
                    local skillsByType = {
                        physical = {},
                        magical = {},
                        healing = {},
                        support = {},
                        utility = {}
                    }
                    
                    for skillName, skillInfo in pairs(char.skills) do
                        local skill = skillSystem:getSkill(skillName)
                        if skill then
                            table.insert(skillsByType[skill.type or "utility"], {
                                name = skillName,
                                info = skillInfo,
                                skill = skill
                            })
                        end
                    end
                    
                    -- Sort skills by name within each type
                    for _, skills in pairs(skillsByType) do
                        table.sort(skills, function(a, b)
                            return a.name < b.name
                        end)
                    end
                    
                    -- Check clicks on skills
                    local typeOrder = {"physical", "magical", "healing", "support", "utility"}
                    local skillY = self.y + 80
                    local leftColumn = self.x + 30
                    local rightColumn = self.x + self.width / 2 + 10
                    local columnWidth = self.width / 2 - 40
                    
                    local currentColumn = leftColumn
                    local currentWidth = columnWidth
                    
                    for _, skillType in ipairs(typeOrder) do
                        local skills = skillsByType[skillType]
                        
                        if #skills > 0 then
                            -- Skip header
                            skillY = skillY + 30
                            
                            -- Check skills
                            for _, skillEntry in ipairs(skills) do
                                if x >= currentColumn - 5 and x <= currentColumn - 5 + currentWidth and
                                   y >= skillY - 2 and y <= skillY - 2 + 25 then
                                    characterDetails:selectSkill(skillEntry)
                                    return true
                                end
                                
                                skillY = skillY + 25
                                
                                -- Switch to right column if reaching bottom
                                if skillY > self.y + self.height - 50 and currentColumn == leftColumn then
                                    currentColumn = rightColumn
                                    skillY = self.y + 80
                                end
                            end
                            
                            -- Add space after each type
                            skillY = skillY + 10
                        end
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create equipment panel
    self.elements.equipmentPanel = {
        x = 20,
        y = 130,
        width = GAME.width - 40,
        height = GAME.height - 200,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Character Equipment", self.x, self.y, self.width, self.height)
            
            -- Draw character equipment
            if characterDetails.selectedCharacter then
                local char = characterDetails.selectedCharacter
                
                -- Draw equipment slots
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Equipment",
                    self.x + 30, self.y + 50
                )
                
                -- Draw weapon slot
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.9, 0.9, 0.9)
                
                love.graphics.print(
                    "Weapon:",
                    self.x + 50, self.y + 90
                )
                
                -- Draw weapon details
                if char.equipment.weapon then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        char.equipment.weapon.name,
                        self.x + 150, self.y + 90
                    )
                    
                    love.graphics.print(
                        "Attack: " .. (char.equipment.weapon.attack or 0),
                        self.x + 150, self.y + 110
                    )
                    
                    if char.equipment.weapon.magicAttack then
                        love.graphics.print(
                            "Magic Attack: " .. char.equipment.weapon.magicAttack,
                            self.x + 150, self.y + 130
                        )
                    end
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    
                    love.graphics.print(
                        "None",
                        self.x + 150, self.y + 90
                    )
                end
                
                -- Draw offhand slot
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.9, 0.9, 0.9)
                
                love.graphics.print(
                    "Offhand:",
                    self.x + 350, self.y + 90
                )
                
                -- Draw offhand details
                if char.equipment.offhand then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        char.equipment.offhand.name,
                        self.x + 450, self.y + 90
                    )
                    
                    if char.equipment.offhand.defense then
                        love.graphics.print(
                            "Defense: " .. char.equipment.offhand.defense,
                            self.x + 450, self.y + 110
                        )
                    end
                    
                    if char.equipment.offhand.magicDefense then
                        love.graphics.print(
                            "Magic Defense: " .. char.equipment.offhand.magicDefense,
                            self.x + 450, self.y + 130
                        )
                    end
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    
                    love.graphics.print(
                        "None",
                        self.x + 450, self.y + 90
                    )
                end
                
                -- Draw armor slot
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.9, 0.9, 0.9)
                
                love.graphics.print(
                    "Armor:",
                    self.x + 50, self.y + 170
                )
                
                -- Draw armor details
                if char.equipment.body then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        char.equipment.body.name,
                        self.x + 150, self.y + 170
                    )
                    
                    if char.equipment.body.defense then
                        love.graphics.print(
                            "Defense: " .. char.equipment.body.defense,
                            self.x + 150, self.y + 190
                        )
                    end
                    
                    if char.equipment.body.magicDefense then
                        love.graphics.print(
                            "Magic Defense: " .. char.equipment.body.magicDefense,
                            self.x + 150, self.y + 210
                        )
                    end
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    
                    love.graphics.print(
                        "None",
                        self.x + 150, self.y + 170
                    )
                end
                
                -- Draw accessory slots
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.9, 0.9, 0.9)
                
                love.graphics.print(
                    "Accessory 1:",
                    self.x + 350, self.y + 170
                )
                
                -- Draw accessory 1 details
                if char.equipment.accessory1 then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        char.equipment.accessory1.name,
                        self.x + 450, self.y + 170
                    )
                    
                    -- Print various possible accessory stats
                    local statY = self.y + 190
                    if char.equipment.accessory1.defense then
                        love.graphics.print(
                            "Defense: " .. char.equipment.accessory1.defense,
                            self.x + 450, statY
                        )
                        statY = statY + 20
                    end
                    
                    if char.equipment.accessory1.magicDefense then
                        love.graphics.print(
                            "Magic Defense: " .. char.equipment.accessory1.magicDefense,
                            self.x + 450, statY
                        )
                    end
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    
                    love.graphics.print(
                        "None",
                        self.x + 450, self.y + 170
                    )
                end
                
                -- Draw accessory 2 slot
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.9, 0.9, 0.9)
                
                love.graphics.print(
                    "Accessory 2:",
                    self.x + 50, self.y + 250
                )
                
                -- Draw accessory 2 details
                if char.equipment.accessory2 then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        char.equipment.accessory2.name,
                        self.x + 150, self.y + 250
                    )
                    
                    -- Print various possible accessory stats
                    local statY = self.y + 270
                    if char.equipment.accessory2.defense then
                        love.graphics.print(
                            "Defense: " .. char.equipment.accessory2.defense,
                            self.x + 150, statY
                        )
                        statY = statY + 20
                    end
                    
                    if char.equipment.accessory2.magicDefense then
                        love.graphics.print(
                            "Magic Defense: " .. char.equipment.accessory2.magicDefense,
                            self.x + 150, statY
                        )
                    end
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    
                    love.graphics.print(
                        "None",
                        self.x + 150, self.y + 250
                    )
                end
            end
        end
    }
    
    -- Create job panel
    self.elements.jobPanel = {
        x = 20,
        y = 130,
        width = GAME.width - 40,
        height = GAME.height - 200,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Character Job", self.x, self.y, self.width, self.height)
            
            -- Draw character job info
            if characterDetails.selectedCharacter then
                local char = characterDetails.selectedCharacter
                
                -- Draw current job
                love.graphics.setFont(screenManager.fonts.large)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Current Job: " .. char.job,
                    self.x + 30, self.y + 50
                )
                
                -- Get job details
                local job = jobSystem:getJob(char.job)
                if job then
                    -- Draw job description
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(0.9, 0.9, 0.9)
                    
                    love.graphics.printf(
                        job.description,
                        self.x + 30, self.y + 90,
                        self.width - 60, "left"
                    )
                    
                    -- Draw job tier
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1)
                    
                    local tierText = "Tier " .. job.tier
                    if job.tier == 1 then
                        tierText = tierText .. " (Basic)"
                    elseif job.tier == 2 then
                        tierText = tierText .. " (Advanced)"
                    elseif job.tier == 3 then
                        tierText = tierText .. " (Master)"
                    end
                    
                    love.graphics.print(
                        tierText,
                        self.x + 30, self.y + 130
                    )
                    
                    -- Draw job progressions
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        "Possible Progression Paths:",
                        self.x + 30, self.y + 170
                    )
                    
                    -- Get available job progressions
                    local progressions = jobSystem:getJobProgressions(job.name)
                    
                    if #progressions > 0 then
                        love.graphics.setFont(screenManager.fonts.small)
                        
                        for i, nextJob in ipairs(progressions) do
                            local jobY = self.y + 200 + (i-1) * 60
                            
                            -- Draw job name
                            love.graphics.setColor(0.8, 0.8, 1)
                            love.graphics.print(
                                nextJob.name,
                                self.x + 50, jobY
                            )
                            
                            -- Draw job description
                            love.graphics.setColor(0.7, 0.7, 0.7)
                            love.graphics.printf(
                                nextJob.description,
                                self.x + 70, jobY + 20,
                                self.width - 150, "left"
                            )
                        end
                    else
                        love.graphics.setFont(screenManager.fonts.small)
                        love.graphics.setColor(0.7, 0.7, 0.7)
                        
                        love.graphics.print(
                            "No further job progressions available.",
                            self.x + 50, self.y + 200
                        )
                    end
                    
                    -- Draw job history
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        "Job History:",
                        self.x + self.width / 2, self.y + 170
                    )
                    
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    
                    for i, jobName in ipairs(char.jobHistory) do
                        love.graphics.print(
                            jobName,
                            self.x + self.width / 2 + 20, self.y + 200 + (i-1) * 25
                        )
                    end
                end
            end
        end
    }
    
    -- Create back button
    self.elements.backButton = screenManager.UI.Button(
        20, GAME.height - 60, 
        100, 40, "Back", 
        function() self:close() end
    )
end

function characterDetails:enter(params)
    -- Initialize state
    self.state = "main"
    self.selectedSkill = nil
    self.selectedTab = "Stats"
    
    -- Select character from params or first character
    if params and params.character then
        self.selectedCharacter = params.character
    elseif GAME.party and #GAME.party > 0 then
        self.selectedCharacter = GAME.party[1]
    else
        self.selectedCharacter = nil
    end
    
    -- Select tab from params
    if params and params.tab then
        self.selectedTab = params.tab
    end
end

function characterDetails:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(screenManager.colors.title)
    love.graphics.print("Character Details", 20, 10)
    
    -- Draw character tabs
    self.elements.characterTabs:draw()
    
    -- Draw info tabs
    self.elements.infoTabs:draw()
    
    -- Draw selected tab content
    if self.selectedTab == "Stats" then
        self.elements.statsPanel:draw()
    elseif self.selectedTab == "Skills" then
        self.elements.skillsPanel:draw()
    elseif self.selectedTab == "Equipment" then
        self.elements.equipmentPanel:draw()
    elseif self.selectedTab == "Job" then
        self.elements.jobPanel:draw()
    end
    
    -- Draw back button
    self.elements.backButton:draw()
end

function characterDetails:mousepressed(x, y, button, istouch, presses)
    -- Pass to character tabs first
    if self.elements.characterTabs:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        return
    end
    
    -- Pass to info tabs
    if self.elements.infoTabs:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        return
    end
    
    -- Pass to current panel
    if self.selectedTab == "Skills" and self.elements.skillsPanel:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        return
    end
    
    -- Pass to back button
    if self.elements.backButton:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        return
    end
end

function characterDetails:selectCharacter(character)
    -- Select character
    self.selectedCharacter = character
    self.selectedSkill = nil
end

function characterDetails:selectTab(tab)
    -- Select tab
    self.selectedTab = tab
    self.selectedSkill = nil
end

function characterDetails:selectSkill(skill)
    -- Select skill
    self.selectedSkill = skill
end

function characterDetails:close()
    -- Return to previous state
    local gameState = require("states/gameState")
    gameState:returnToPreviousState()
end

return characterDetails
