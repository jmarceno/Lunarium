-- Character Info Screen
-- Where players can view detailed information about party members
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local characterSystem = require("gameplay/character")
local itemSystem = require("gameplay/item")
local skillSystem = require("gameplay/skill")

local characterInfo = screenManager:createScreen("Character Info")

function characterInfo:init()
    -- Initialize state
    self.state = "main"
    self.selectedCharacter = nil
    self.activeTab = "stats" -- stats, equipment, skills
    self.scrollOffsetY = 0 -- Scroll offset for the info panel
    self.scrollSpeed = 20 -- How many pixels to scroll per mouse wheel tick
    
    -- Create UI elements
    self:createUI()
end

function characterInfo:createUI()
    -- Create character list (party members) - now a vertical list on the left
    self.elements.characterList = {
        x = 50,
        y = 90,
        width = 250, -- Slightly narrower to give more space to details panel
        height = 500, -- Taller to fit stacked characters
        
        draw = function(self)
            if not GAME.party or #GAME.party == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.printf("No characters in party", self.x, self.y + 30, self.width, "center")
                return
            end
            
            -- Draw character slots stacked vertically
            local charHeight = 120 -- Height per character slot
            local padding = 10 -- Padding between character slots
            
            for i, character in ipairs(GAME.party) do
                local y = self.y + (i-1) * (charHeight + padding)
                
                -- Draw selection background if selected
                if character == characterInfo.selectedCharacter then
                    love.graphics.setColor(0.3, 0.3, 0.6)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle("fill", self.x, y, self.width, charHeight, 5, 5)
                
                -- Set up portrait area
                local portraitScale = 1.4
                local portraitX = self.x + 15
                local portraitY = y + 15
                local textX = portraitX + 100 -- Start text after portrait
                local barWidth = self.width - 130 -- Bar width adjusted for left column
                
                -- Draw character portrait
                love.graphics.setColor(1, 1, 1)
                if character.portraitId and assetManager.images.portraits[character.portraitId] then
                    love.graphics.draw(
                        assetManager.images.portraits[character.portraitId],
                        portraitX, portraitY,
                        0, portraitScale, portraitScale
                    )
                elseif assetManager.images.profiles[character.profileIndex] then
                    love.graphics.draw(
                        assetManager.images.profiles[character.profileIndex],
                        portraitX, portraitY,
                        0, portraitScale, portraitScale
                    )
                end
                
                -- Draw character name
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                
                local nameWidth = screenManager.fonts.small:getWidth(character.name)
                if nameWidth > barWidth then
                    -- Truncate name if too long
                    local truncName = ""
                    local j = 1
                    while screenManager.fonts.small:getWidth(truncName .. "...") < barWidth and j <= #character.name do
                        truncName = truncName .. character.name:sub(j, j)
                        j = j + 1
                    end
                    love.graphics.print(truncName .. "...", textX, y + 20)
                else
                    love.graphics.print(character.name, textX, y + 20)
                end
                
                -- Draw character job and level
                love.graphics.setColor(0.8, 0.8, 1)
                local jobText = character.job .. " Lv." .. (character.jobLevels[character.job] or 1)
                love.graphics.print(jobText, textX, y + 40)
                
                -- Draw HP/MP bars with spacing
                -- HP bar
                local healthWidth = barWidth * (character.currentHP / character.maxHP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", textX, y + 73, barWidth, 10)
                love.graphics.setColor(0.8, 0.2, 0.2)
                love.graphics.rectangle("fill", textX, y + 73, healthWidth, 10)
                
                -- HP values
                love.graphics.setColor(1, 0.7, 0.7)
                love.graphics.print(
                    character.currentHP .. "/" .. character.maxHP,
                    textX + barWidth - 60, y + 73 - 14
                )
                
                -- MP bar
                local manaWidth = barWidth * (character.currentMP / character.maxMP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", textX, y + 95, barWidth, 10)
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", textX, y + 95, manaWidth, 10)
                
                -- MP values
                love.graphics.setColor(0.7, 0.7, 1)
                love.graphics.print(
                    character.currentMP .. "/" .. character.maxMP,
                    textX + barWidth - 60, y + 95 - 14
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            if not GAME.party or #GAME.party == 0 then return false end
            
            -- Check if click is within list
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Find which character was clicked
                local charHeight = 120
                local padding = 10
                
                for i, character in ipairs(GAME.party) do
                    local charY = self.y + (i-1) * (charHeight + padding)
                    
                    if y >= charY and y <= charY + charHeight then
                        characterInfo:selectCharacter(character)
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create tab buttons - now on the right column
    local detailsX = 330 -- X position for detail panels (moved further left)
    local tabY = 90 -- Y position for tabs
    
    self.elements.statsTab = screenManager.UI.Button(
        detailsX, tabY, 120, 30, "Stats",
        function() self:selectTab("stats") end
    )
    self.elements.statsTab.visible = true
    
    self.elements.equipmentTab = screenManager.UI.Button(
        detailsX + 130, tabY, 120, 30, "Equipment",
        function() self:selectTab("equipment") end
    )
    self.elements.equipmentTab.visible = true
    
    self.elements.skillsTab = screenManager.UI.Button(
        detailsX + 260, tabY, 120, 30, "Skills",
        function() self:selectTab("skills") end
    )
    self.elements.skillsTab.visible = true
    
    -- Create info panel - now taller on the right column and wider
    self.elements.infoPanel = {
        x = detailsX,
        y = tabY + 40, -- Just below tabs
        width = 820, -- Wider panel to use more screen space
        height = 450, -- Taller panel
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Character Details", self.x, self.y, self.width, self.height)
            
            -- Draw content based on active tab
            if not characterInfo.selectedCharacter then
                -- No character selected
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.printf(
                    "Select a character to view details",
                    self.x + 20, self.y + 150,
                    self.width - 40, "center"
                )
                return
            end
            
            local char = characterInfo.selectedCharacter
            local panelContentY = self.y + 50 -- Starting Y inside the panel, below title
            local panelVisibleHeight = self.height - 60 -- Visible area height
            
            -- Use scissor to clip content within the panel's visible area
            love.graphics.push("all")
            love.graphics.setScissor(self.x + 1, panelContentY, self.width - 2, panelVisibleHeight)
            
            -- Adjust all content drawing by scroll offset
            local currentY = panelContentY - characterInfo.scrollOffsetY 
            local contentHeight = 0 -- We will calculate this for clamping scroll

            if characterInfo.activeTab == "stats" then
                local startY = currentY
                
                -- Draw character attributes
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Attributes", self.x + 30, currentY)
                currentY = currentY + 30
                
                -- Draw attribute values
                love.graphics.setFont(screenManager.fonts.small)
                local attrs = {"STR", "INT", "CON", "WIL", "CHA", "DEX", "WIS"}
                local attrLabels = {
                    STR = "Strength", INT = "Intelligence", CON = "Constitution",
                    WIL = "Will", CHA = "Charisma", DEX = "Dexterity", WIS = "Wisdom"
                }
                for i, attr in ipairs(attrs) do
                    love.graphics.setColor(0.8, 0.8, 1)
                    love.graphics.print(attrLabels[attr], self.x + 50, currentY)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(char.attributes[attr], self.x + 200, currentY)
                    currentY = currentY + 25
                end
                currentY = currentY + 5 -- Padding
                
                -- Draw derived stats
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Combat Stats", self.x + 280, startY) -- Use startY for alignment
                
                love.graphics.setFont(screenManager.fonts.small)
                local combatStatY = startY + 30
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("HP", self.x + 300, combatStatY); love.graphics.setColor(1, 1, 1); love.graphics.print(char.currentHP .. " / " .. char.maxHP, self.x + 380, combatStatY); combatStatY = combatStatY + 25
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("MP", self.x + 300, combatStatY); love.graphics.setColor(1, 1, 1); love.graphics.print(char.currentMP .. " / " .. char.maxMP, self.x + 380, combatStatY); combatStatY = combatStatY + 25
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("Attack", self.x + 300, combatStatY); love.graphics.setColor(1, 1, 1); love.graphics.print(characterSystem:calculateAttackPower(char), self.x + 380, combatStatY); combatStatY = combatStatY + 25
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("Defense", self.x + 300, combatStatY); love.graphics.setColor(1, 1, 1); love.graphics.print(characterSystem:calculateDefense(char), self.x + 380, combatStatY); combatStatY = combatStatY + 25
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("Magic", self.x + 300, combatStatY); love.graphics.setColor(1, 1, 1); love.graphics.print(characterSystem:calculateMagicPower(char), self.x + 380, combatStatY); combatStatY = combatStatY + 25
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("Magic Def", self.x + 300, combatStatY); love.graphics.setColor(1, 1, 1); love.graphics.print(characterSystem:calculateMagicDefense(char), self.x + 380, combatStatY); combatStatY = combatStatY + 25

                -- Experience info
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Experience", self.x + 480, startY) -- Use startY
                
                love.graphics.setFont(screenManager.fonts.small)
                local expY = startY + 30
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("Current", self.x + 500, expY); love.graphics.setColor(1, 1, 1); love.graphics.print(char.experience, self.x + 600, expY); expY = expY + 25
                love.graphics.setColor(0.8, 0.8, 1); love.graphics.print("Next Level", self.x + 500, expY); love.graphics.setColor(1, 1, 1); love.graphics.print(char.experienceToNext, self.x + 600, expY); expY = expY + 25

                -- Draw a progress bar
                if char.experienceToNext > 0 then -- Avoid division by zero
                    local expRatio = char.experience / char.experienceToNext
                    local expWidth = 160 * math.min(1, math.max(0, expRatio)) -- Clamp ratio
                    love.graphics.setColor(0.2, 0.2, 0.3)
                    love.graphics.rectangle("fill", self.x + 500, expY, 160, 15)
                    love.graphics.setColor(0.4, 0.4, 0.8)
                    love.graphics.rectangle("fill", self.x + 500, expY, expWidth, 15)
                    expY = expY + 20
                end
                expY = expY + 5 -- Padding

                -- Job History section
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                -- Align Job History below the tallest column (Combat Stats or EXP)
                local jobHistoryY = math.max(currentY, combatStatY, expY) 
                love.graphics.print("Job History", self.x + 30, jobHistoryY)
                jobHistoryY = jobHistoryY + 30

                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 1)
                if char.jobLevels and next(char.jobLevels) then -- Check if table is not empty
                    -- Sort job names for consistent display
                    local sortedJobNames = {}
                    for name, _ in pairs(char.jobLevels) do
                        table.insert(sortedJobNames, name)
                    end
                    table.sort(sortedJobNames)

                    for _, jobName in ipairs(sortedJobNames) do
                        local jobLevel = char.jobLevels[jobName] or 0
                        -- DEBUG PRINT:
                        if GAME.debug then print("  Displaying Job History: Job=", jobName, " Stored Level=", jobLevel, " Type=", type(jobLevel)) end
                        -- Display job name and its specific level
                        local historyText = "- " .. jobName .. " Lv." .. jobLevel 
                        -- Highlight current job
                        if jobName == char.job then
                            love.graphics.setColor(1, 1, 0.5) -- Yellow for current job
                        else
                            love.graphics.setColor(0.8, 0.8, 1)
                        end
                        love.graphics.print(historyText, self.x + 50, jobHistoryY)
                        jobHistoryY = jobHistoryY + 20
                    end
                else
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    love.graphics.print("No job history", self.x + 50, jobHistoryY)
                    jobHistoryY = jobHistoryY + 20
                end
                love.graphics.setColor(1,1,1) -- Reset color

                -- Display Total Level
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Total Level: " .. characterSystem:_calculateTotalLevel(char), self.x + 280, jobHistoryY)
                jobHistoryY = jobHistoryY + 30
                
                -- Display Faction Reputation
                local reputationSystem = require("gameplay/reputationSystem")
                reputationSystem:init() -- Ensure reputation system is initialized
                
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Faction Reputation", self.x + 30, jobHistoryY)
                jobHistoryY = jobHistoryY + 30
                
                -- Display Guild reputation
                local guildRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.GUILD)
                local guildRepName = reputationSystem:getReputationLevelName(guildRepLevel)
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.print("Guild:", self.x + 50, jobHistoryY)
                
                -- Display with color based on reputation level
                if guildRepLevel >= reputationSystem.levels.FRIENDLY then
                    love.graphics.setColor(0.2, 1, 0.2) -- Green for good rep
                elseif guildRepLevel < reputationSystem.levels.NEUTRAL then
                    love.graphics.setColor(1, 0.2, 0.2) -- Red for bad rep
                else
                    love.graphics.setColor(1, 1, 1) -- White for neutral
                end
                love.graphics.print(guildRepName .. " (" .. reputationSystem:getReputation(reputationSystem.factions.GUILD) .. ")", self.x + 150, jobHistoryY)
                jobHistoryY = jobHistoryY + 25
                
                -- Display Tavern reputation
                local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
                local tavernRepName = reputationSystem:getReputationLevelName(tavernRepLevel)
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.print("Tavern:", self.x + 50, jobHistoryY)
                
                -- Display with color based on reputation level
                if tavernRepLevel >= reputationSystem.levels.FRIENDLY then
                    love.graphics.setColor(0.2, 1, 0.2) -- Green for good rep
                elseif tavernRepLevel < reputationSystem.levels.NEUTRAL then
                    love.graphics.setColor(1, 0.2, 0.2) -- Red for bad rep
                else
                    love.graphics.setColor(1, 1, 1) -- White for neutral
                end
                love.graphics.print(tavernRepName .. " (" .. reputationSystem:getReputation(reputationSystem.factions.TAVERN) .. ")", self.x + 150, jobHistoryY)
                jobHistoryY = jobHistoryY + 25
                
                -- Add reputation benefits explanation
                if guildRepLevel > reputationSystem.levels.NEUTRAL or tavernRepLevel > reputationSystem.levels.NEUTRAL then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.8, 0.9, 0.8)
                    love.graphics.print("* Higher reputation provides special benefits and discounts", self.x + 50, jobHistoryY)
                    jobHistoryY = jobHistoryY + 25
                end

                contentHeight = jobHistoryY - (panelContentY - characterInfo.scrollOffsetY) -- Total height of content
                
            elseif characterInfo.activeTab == "equipment" then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Equipment", self.x + 30, currentY)
                currentY = currentY + 30
                
                love.graphics.setFont(screenManager.fonts.small)
                local slots = {
                    {name = "Weapon", key = "weapon"}, {name = "Offhand", key = "offhand"},
                    {name = "Head", key = "head"}, {name = "Body", key = "body"},
                    {name = "Amulet", key = "amulet"}, {name = "Ring", key = "ring"}
                }
                local itemLineHeight = 40 -- Height per item slot

                for _, slot in ipairs(slots) do
                    -- Draw slot name
                    love.graphics.setColor(0.8, 0.8, 1)
                    love.graphics.print(slot.name, self.x + 50, currentY)
                    
                    -- Draw item or empty
                    local item = char.equipment[slot.key]
                    if item then
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print(item.name, self.x + 170, currentY)
                        
                        -- Draw item stats
                        local statText = ""
                        if item.attack then statText = statText .. "ATK: " .. item.attack .. " " end
                        if item.magicAttack then statText = statText .. "MAG: " .. item.magicAttack .. " " end
                        if item.defense then statText = statText .. "DEF: " .. item.defense .. " " end
                        if item.magicDefense then statText = statText .. "MDEF: " .. item.magicDefense .. " " end
                        
                        love.graphics.setColor(0.7, 0.7, 0.7)
                        love.graphics.print(statText, self.x + 350, currentY)
                    else
                        love.graphics.setColor(0.5, 0.5, 0.5)
                        love.graphics.print("None", self.x + 170, currentY)
                    end
                    currentY = currentY + itemLineHeight
                end
                contentHeight = currentY - (panelContentY - characterInfo.scrollOffsetY)

            elseif characterInfo.activeTab == "skills" then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Skills", self.x + 30, currentY)
                currentY = currentY + 30
                
                if not char.skills or not next(char.skills) then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    love.graphics.print("No skills learned", self.x + 50, currentY)
                    currentY = currentY + 20
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    local skillLineHeight = 45 -- Height per skill entry
                    
                    -- Sort skills alphabetically for consistent display
                    local sortedSkillNames = {}
                    for name, _ in pairs(char.skills) do
                        table.insert(sortedSkillNames, name)
                    end
                    table.sort(sortedSkillNames)

                    for _, skillName in ipairs(sortedSkillNames) do
                        local skillData = char.skills[skillName]
                        local skill = skillSystem:getSkill(skillName)
                        
                        if skill then
                            love.graphics.setColor(1, 1, 1); love.graphics.print(skill.name, self.x + 50, currentY)
                            love.graphics.setColor(0.2, 0.8, 0.2); love.graphics.print("Lv. " .. skillData.level, self.x + 250, currentY)
                            if skill.mpCost and skill.mpCost > 0 then
                                love.graphics.setColor(0.2, 0.2, 0.8); love.graphics.print("MP: " .. skill.mpCost, self.x + 300, currentY)
                            end
                            if skill.description then
                                love.graphics.setColor(0.7, 0.7, 0.7)
                                local desc = skill.description
                                if #desc > 50 then desc = desc:sub(1, 47) .. "..." end
                                love.graphics.print(desc, self.x + 50, currentY + 20)
                            end
                            currentY = currentY + skillLineHeight
                        end
                    end
                end
                contentHeight = currentY - (panelContentY - characterInfo.scrollOffsetY)
            end

            -- Store calculated content height for scroll clamping
            self.currentContentHeight = contentHeight
            
            -- Stop clipping
            love.graphics.pop() 
            
            -- Draw scrollbar (optional, basic indicator)
            local maxScroll = math.max(0, self.currentContentHeight - panelVisibleHeight)
            if maxScroll > 0 then
                local scrollbarX = self.x + self.width - 15
                local scrollbarHeight = panelVisibleHeight
                local handleHeight = math.max(20, scrollbarHeight * (panelVisibleHeight / self.currentContentHeight))
                local handleY = panelContentY + (characterInfo.scrollOffsetY / maxScroll) * (scrollbarHeight - handleHeight)
                
                -- Background track
                love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
                love.graphics.rectangle("fill", scrollbarX, panelContentY, 10, scrollbarHeight)
                -- Handle
                love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
                love.graphics.rectangle("fill", scrollbarX, handleY, 10, handleHeight)
            end
        end
    }
    
    -- Create back button
    self.elements.backToGameButton = screenManager.UI.Button(
        GAME.width - 170, GAME.height - 70, 
        150, 40, "Back to Game", 
        function() self:returnToGame() end
    )
    self.elements.backToGameButton.visible = true
    
    -- Initialize party panel
    if not self.elements.partyPanel then
        self.elements.partyPanel = {
            init = function(self)
                -- Initialize any party panel specific data
            end
        }
        self.elements.partyPanel:init()
    end
    
    -- Set initial tab highlighting
    self:updateTabHighlighting()
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

function characterInfo:enter(params)
    -- Store from parameter for proper navigation back
    if params and params.from then
        self.fromState = params.from
    else
        self.fromState = nil
    end
    
    -- Select first character if available
    if GAME.party and #GAME.party > 0 then
        self:selectCharacter(GAME.party[1])
    else
        self.selectedCharacter = nil
    end
    
    -- Set default tab
    self.activeTab = "stats"
    self.scrollOffsetY = 0 -- Reset scroll on entering screen
    self:updateTabHighlighting()
end

function characterInfo:update(dt)
    -- Nothing to update in real-time
end

function characterInfo:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    love.graphics.setColor(screenManager.colors.background)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw screen title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(screenManager.colors.title)
    love.graphics.print("Character Information", 50, 30)
    
    -- Draw separator line between columns
    love.graphics.setColor(0.7, 0.6, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(315, 90, 315, 590)
    
    -- Draw UI elements
    for name, element in pairs(self.elements) do
        if element.draw and element.visible ~= false then
            element:draw()
        end
    end
end

function characterInfo:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Check all UI elements
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false then
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Character Info button clicked: " .. name)
                end
                
                clickHandled = true
                -- Don't break to allow hover effects
            end
        end
    end
    
    return clickHandled
end

function characterInfo:mousereleased(x, y, button, istouch, presses)
    -- Handle mouse releases for UI elements
    for _, element in pairs(self.elements) do
        if element.released and element.visible ~= false then
            element:released(x, y, button)
        end
    end
    
    if GAME.debug then
        print("Character Info mouse released at: " .. x .. "," .. y)
    end
end

function characterInfo:selectCharacter(character)
    -- Select character
    self.selectedCharacter = character
    self.scrollOffsetY = 0 -- Reset scroll when character changes
    
    if GAME.debug then
        print("Selected character: " .. character.name)
    end
end

function characterInfo:selectTab(tab)
    -- Select tab
    self.activeTab = tab
    self.scrollOffsetY = 0 -- Reset scroll when tab changes
    
    -- Update tab highlighting
    self:updateTabHighlighting()
    
    if GAME.debug then
        print("Selected character info tab: " .. tab)
    end
end

function characterInfo:returnToGame()
    -- Use centralized helper function
    screenManager:returnToCurrentCity(self.fromState)
end

-- Add mouse wheel handling for scrolling
function characterInfo:wheelmoved(dx, dy)
    local panel = self.elements.infoPanel
    local mx, my = love.mouse.getPosition() -- Need mouse position to check if over the panel
    
    -- Check if mouse is over the info panel's content area
    if mx >= panel.x and mx <= panel.x + panel.width and
       my >= panel.y + 50 and my <= panel.y + panel.height - 10 then 
       
        local panelVisibleHeight = panel.height - 60 
        local contentHeight = panel.currentContentHeight or 0
        local maxScrollY = math.max(0, contentHeight - panelVisibleHeight)
        
        -- Adjust scroll offset based on vertical scroll (dy)
        self.scrollOffsetY = self.scrollOffsetY - dy * self.scrollSpeed
        
        -- Clamp scroll offset
        self.scrollOffsetY = math.max(0, math.min(self.scrollOffsetY, maxScrollY))
        
        if GAME.debug then
            print("Scrolled in CharInfo: dy=", dy, " newOffsetY=", self.scrollOffsetY, " maxScrollY=", maxScrollY, " contentHeight=", contentHeight)
        end
        return true -- Indicate event was handled
    end
    
    return false -- Event not handled by this screen
end

return characterInfo 