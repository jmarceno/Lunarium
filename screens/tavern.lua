-- Tavern Screen
-- Where players can accept quests and haggle for better rewards
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local questSystem = require("gameplay/questSystem")
local reputationSystem = require("gameplay/reputationSystem")
local partyPanel = require("screens/ui_slices/partyPanel")

local tavern = screenManager:createScreen("Tavern")

function tavern:init()
    -- Initialize state
    self.state = "main" -- main, quest_details, haggle
    self.selectedQuest = nil
    self.questList = {}
    self.refreshTimer = 0
    self.haggleAttempts = 0
    self.maxHaggleAttempts = 3
    self.hagglePercentage = 0
    self.haggleSuccess = false
    self.originalReward = 0
    
    -- Load background image directly using love.graphics
    self.backgroundImage = love.graphics.newImage("assets/TavernScreen.png")
    
    -- Create UI elements
    self:createUI()
end

function tavern:createUI()
    -- Create quest list panel
    self.elements.questListPanel = {
        x = 100,
        y = 50,
        width = GAME.width - 200,
        height = GAME.height - 200,
        
        draw = function(self)
            -- Draw panel background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.7)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw screen title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("The Dragon's Rest Tavern", self.x, self.y + 20, self.width, "center")
            
            -- Draw current gold
            if GAME.gold then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Gold: " .. GAME.gold,
                    self.x + 50, self.y + 70
                )
            end
            
            -- Draw "Tavern Quests" section label
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.printf("Tavern Quests", self.x, self.y + 100, self.width, "center")
            
            -- Draw divider line
            love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
            love.graphics.line(
                self.x + 50, self.y + 130, 
                self.x + self.width - 50, self.y + 130
            )
            
            -- Draw quests
            for i, quest in ipairs(tavern.questList) do
                local questY = self.y + 150 + (i-1) * 80
                
                -- Skip if out of view
                if questY > self.y + self.height - 80 then
                    break
                end
                
                -- Draw quest entry background
                if quest == tavern.selectedQuest then
                    love.graphics.setColor(0.3, 0.3, 0.5)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle(
                    "fill",
                    self.x + 20, questY, 
                    self.width - 40, 70,
                    5, 5
                )
                
                -- Draw quest name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    quest.name,
                    self.x + 40, questY + 10
                )
                
                -- Draw quest difficulty
                love.graphics.setFont(screenManager.fonts.small)
                local diffText = "Level " .. quest.level .. " - "
                
                -- Add difficulty text based on value
                if quest.difficulty == questSystem.DIFFICULTY.EASY then
                    diffText = diffText .. "Easy"
                    love.graphics.setColor(0.2, 0.8, 0.2)
                elseif quest.difficulty == questSystem.DIFFICULTY.MEDIUM then
                    diffText = diffText .. "Medium"
                    love.graphics.setColor(0.8, 0.8, 0.2)
                elseif quest.difficulty == questSystem.DIFFICULTY.HARD then
                    diffText = diffText .. "Hard"
                    love.graphics.setColor(0.8, 0.4, 0.2)
                elseif quest.difficulty == questSystem.DIFFICULTY.VERY_HARD then
                    diffText = diffText .. "Very Hard"
                    love.graphics.setColor(0.8, 0.2, 0.2)
                elseif quest.difficulty == questSystem.DIFFICULTY.LEGENDARY then
                    diffText = diffText .. "Legendary"
                    love.graphics.setColor(0.8, 0.2, 0.8)
                end
                
                love.graphics.print(
                    diffText,
                    self.x + 40, questY + 40
                )
                
                -- Draw reward preview
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Reward: " .. quest.rewards.gold .. " gold",
                    self.x + self.width - 250, questY + 40
                )
            end
            
            -- Draw message if no quests
            if #tavern.questList == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                love.graphics.printf(
                    "No quests available at the moment.\nCheck back later!",
                    self.x + 40, self.y + 200,
                    self.width - 80, "center"
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check quest entries
                for i, quest in ipairs(tavern.questList) do
                    local questY = self.y + 150 + (i-1) * 80
                    
                    -- Skip if out of view
                    if questY > self.y + self.height - 80 then
                        break
                    end
                    
                    if y >= questY and y <= questY + 70 then
                        tavern:selectQuest(quest)
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create quest details panel
    self.elements.questDetailsPanel = {
        x = 100,
        y = 50,
        width = GAME.width - 200,
        height = GAME.height - 200,
        visible = false,
        
        draw = function(self)
            if not self.visible or not tavern.selectedQuest then
                return
            end
            
            local quest = tavern.selectedQuest
            
            -- Draw panel background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.7)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw screen title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("The Dragon's Rest Tavern", self.x, self.y + 20, self.width, "center")
            
            -- Draw current gold
            if GAME.gold then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Gold: " .. GAME.gold,
                    self.x + 50, self.y + 70
                )
            end
            
            -- Draw "Quest Details" section label
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.printf("Quest Details", self.x, self.y + 100, self.width, "center")
            
            -- Draw divider line
            love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
            love.graphics.line(
                self.x + 50, self.y + 130, 
                self.x + self.width - 50, self.y + 130
            )
            
            -- Draw quest name
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                quest.name,
                self.x + 20, self.y + 150,
                self.width - 40, "center"
            )
            
            -- Draw quest description
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 0.9)
            
            love.graphics.printf(
                quest.description,
                self.x + 50, self.y + 200,
                self.width - 100, "center"
            )
            
            -- Draw quest details
            love.graphics.setFont(screenManager.fonts.medium)
            
            -- Draw difficulty
            local diffText = "Difficulty: "
            
            -- Add difficulty text based on value
            if quest.difficulty == questSystem.DIFFICULTY.EASY then
                diffText = diffText .. "Easy"
                love.graphics.setColor(0.2, 0.8, 0.2)
            elseif quest.difficulty == questSystem.DIFFICULTY.MEDIUM then
                diffText = diffText .. "Medium"
                love.graphics.setColor(0.8, 0.8, 0.2)
            elseif quest.difficulty == questSystem.DIFFICULTY.HARD then
                diffText = diffText .. "Hard"
                love.graphics.setColor(0.8, 0.4, 0.2)
            elseif quest.difficulty == questSystem.DIFFICULTY.VERY_HARD then
                diffText = diffText .. "Very Hard"
                love.graphics.setColor(0.8, 0.2, 0.2)
            elseif quest.difficulty == questSystem.DIFFICULTY.LEGENDARY then
                diffText = diffText .. "Legendary"
                love.graphics.setColor(0.8, 0.2, 0.8)
            end
            
            love.graphics.print(
                diffText,
                self.x + 50, self.y + 280
            )
            
            -- Draw level
            love.graphics.setColor(0.7, 0.7, 1)
            
            love.graphics.print(
                "Recommended Level: " .. quest.level,
                self.x + 50, self.y + 310
            )
            
            -- Draw rewards section
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.print(
                "Rewards:",
                self.x + 50, self.y + 350
            )
            
            -- Draw gold reward
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 0)
            
            love.graphics.print(
                quest.rewards.gold .. " Gold",
                self.x + 70, self.y + 380
            )
            
            -- Draw item rewards
            if quest.rewards.items and #quest.rewards.items > 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Items:",
                    self.x + 70, self.y + 410
                )
                
                for i, item in ipairs(quest.rewards.items) do
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.8, 0.8, 1)
                    
                    local itemText = item.name
                    if item.count and item.count > 1 then
                        itemText = itemText .. " x" .. item.count
                    end
                    
                    love.graphics.print(
                        itemText,
                        self.x + 90, self.y + 410 + i * 25
                    )
                end
            end
            
            -- Draw buttons
            self.acceptButton:draw()
            self.haggleButton:draw()
            self.backButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check button clicks
            if self.acceptButton:clicked(x, y, button) then
                return true
            end
            
            if self.haggleButton:clicked(x, y, button) then
                return true
            end
            
            if self.backButton:clicked(x, y, button) then
                return true
            end
            
            return false
        end,
        
        init = function(self)
            -- Create buttons
            self.acceptButton = screenManager.UI.Button(
                self.x + self.width / 2 - 170, self.y + self.height - 70, 
                100, 40, "Accept", 
                function() tavern:acceptQuest() end
            )
            
            self.haggleButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + self.height - 70, 
                100, 40, "Haggle", 
                function() tavern:startHaggle() end
            )
            
            self.backButton = screenManager.UI.Button(
                self.x + self.width / 2 + 70, self.y + self.height - 70, 
                100, 40, "Back", 
                function() tavern:showMainScreen() end
            )
        end
    }
    
    -- Create haggle panel
    self.elements.hagglePanel = {
        x = 150,
        y = 150,
        width = 500,
        height = 300,
        visible = false,
        haggleChance = 0,
        haggleResult = nil,
        
        draw = function(self)
            if not self.visible then
                return
            end
            
            -- Draw panel background
            screenManager:drawPanel("Haggle for Better Reward", self.x, self.y, self.width, self.height)
            
            -- Draw haggle info
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                "Current reward: " .. tavern.selectedQuest.rewards.gold .. " gold",
                self.x + 20, self.y + 60,
                self.width - 40, "center"
            )
            
            love.graphics.printf(
                "Haggle attempts: " .. tavern.selectedQuest.haggleAttempts .. "/3",
                self.x + 20, self.y + 90,
                self.width - 40, "center"
            )
            
            -- Draw character's CHA stat
            if GAME.party and GAME.party[1] then
                local charisma = GAME.party[1].attributes.CHA or 5
                love.graphics.setColor(0.8, 0.9, 1)
                love.graphics.printf(
                    "Your Charisma: " .. charisma,
                    self.x + 20, self.y + 120,
                    self.width - 40, "center"
                )
            end
            
            -- Draw haggle result if available
            if self.haggleResult then
                if self.haggleResult.success then
                    love.graphics.setColor(0.2, 0.8, 0.2)
                    love.graphics.printf(
                        self.haggleResult.message,
                        self.x + 20, self.y + 150,
                        self.width - 40, "center"
                    )
                else
                    love.graphics.setColor(0.8, 0.2, 0.2)
                    love.graphics.printf(
                        self.haggleResult.message,
                        self.x + 20, self.y + 150,
                        self.width - 40, "center"
                    )
                end
            elseif tavern.selectedQuest.haggleAttempts < 3 then
                -- Draw haggle instructions and success chance
                love.graphics.setColor(0.8, 0.8, 0.2)
                love.graphics.printf(
                    "Try to negotiate for better rewards:",
                    self.x + 20, self.y + 150,
                    self.width - 40, "center"
                )
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(
                    "Success chance: " .. math.floor(self.haggleChance) .. "%",
                    self.x + 20, self.y + 175,
                    self.width - 40, "center"
                )
            else
                -- Maximum attempts reached
                love.graphics.setColor(0.8, 0.2, 0.2)
                love.graphics.printf(
                    "The quest giver refuses to haggle further.",
                    self.x + 20, self.y + 150,
                    self.width - 40, "center"
                )
            end
            
            -- Draw buttons
            if self.haggleResult or tavern.selectedQuest.haggleAttempts >= 3 then
                -- Show accept/close button
                self.acceptButton:draw()
            else
                -- Show haggle button
                self.haggleButton:draw()
            end
            
            -- Draw cancel button
            self.cancelButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check if we should show haggle button or accept button
            local showHaggleButton = not self.haggleResult and tavern.selectedQuest.haggleAttempts < 3
            
            -- Use proper button.clicked method
            if showHaggleButton then
                if self.haggleButton:clicked(x, y, button) then
                    -- Call the function directly instead of relying on the button callback
                    tavern:tryHaggle()
                    return true
                end
            else
                if self.acceptButton:clicked(x, y, button) then
                    tavern:acceptHaggle()
                    return true
                end
            end
            
            if self.cancelButton:clicked(x, y, button) then
                tavern:cancelHaggle()
                return true
            end
            
            return false
        end,
        
        init = function(self)
            -- Create buttons with empty callbacks since we're directly calling functions in clicked
            self.haggleButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + 200, 
                100, 40, "Haggle", 
                nil  -- No callback, we'll handle it in clicked method
            )
            
            self.acceptButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + 200, 
                100, 40, "Accept", 
                nil  -- No callback, we'll handle it in clicked method
            )
            
            self.cancelButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + 250, 
                100, 40, "Cancel", 
                nil  -- No callback, we'll handle it in clicked method
            )
        end,
        
        -- Calculate haggle success chance based on character's CHA
        calculateHaggleChance = function(self)
            if not GAME.party or not GAME.party[1] then
                return 30 -- Default chance
            end
            
            local character = GAME.party[1]
            local charisma = character.attributes.CHA or 5
            local baseChance = 30 + charisma * 3
            
            -- Reduce chance based on previous attempts
            local attempts = tavern.selectedQuest.haggleAttempts or 0
            local attemptsReduction = attempts * 15
            local finalChance = math.max(5, math.min(95, baseChance - attemptsReduction))
            
            self.haggleChance = finalChance
            return finalChance
        end
    }
    
    -- Initialize panels
    self.elements.questDetailsPanel:init()
    self.elements.hagglePanel:init()
    
    -- Create back button
    self.elements.backToTownButton = screenManager.UI.Button(
        GAME.width - 200, 20, 
        150, 40, "Back to Town", 
        function() self:returnToTown() end
    )
    self.elements.backToTownButton.visible = true
    
    -- Create refresh button
    self.elements.refreshButton = screenManager.UI.Button(
        50, 20,
        150, 40, "Refresh", 
        function() self:refreshQuests() end
    )
    self.elements.refreshButton.visible = true
    
    -- Set initial visibility state for all UI elements
    self:updateElementVisibility()
    
    -- Initialize party panel
    self.elements.partyPanel = partyPanel
    self.elements.partyPanel.visible = true
end

function tavern:updateElementVisibility()
    -- Update element visibility based on current state
    if self.state == "main" then
        if self.elements.questDetailsPanel then
            self.elements.questDetailsPanel.visible = false
        end
        if self.elements.hagglePanel then
            self.elements.hagglePanel.visible = false
        end
        if self.elements.refreshButton then
            self.elements.refreshButton.visible = true
        end
    elseif self.state == "quest_details" then
        if self.elements.questDetailsPanel then
            self.elements.questDetailsPanel.visible = true
        end
        if self.elements.hagglePanel then
            self.elements.hagglePanel.visible = false
        end
        if self.elements.refreshButton then
            self.elements.refreshButton.visible = false
        end
    elseif self.state == "haggle" then
        if self.elements.questDetailsPanel then
            self.elements.questDetailsPanel.visible = true
        end
        if self.elements.hagglePanel then
            self.elements.hagglePanel.visible = true
        end
        if self.elements.refreshButton then
            self.elements.refreshButton.visible = false
        end
    end
    
    -- Back to town button is always visible
    if self.elements.backToTownButton then
        self.elements.backToTownButton.visible = true
    end
    
    if GAME.debug then
        print("Tavern UI visibility updated - State: " .. self.state)
    end
end

function tavern:enter()
    -- Start playing tavern music
    -- assetManager:playMusic("town") -- Use town music for now
    
    -- Ensure background image is loaded
    if not self.backgroundImage then
        self.backgroundImage = love.graphics.newImage("assets/TavernScreen.png")
    end
    
    -- Load quests
    self:loadQuests()
    
    -- Initialize state
    self.state = "main"
    self.selectedQuest = nil
    self.elements.questDetailsPanel.visible = false
    self.elements.hagglePanel.visible = false
    self.haggleAttempts = 0
    self.haggleSuccess = false
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:update(dt)
    -- Update refresh timer
    self.refreshTimer = self.refreshTimer + dt
    
    -- Auto refresh quests every 5 minutes of real time
    if self.refreshTimer >= 300 then
        self:refreshQuests()
        self.refreshTimer = 0
    end
end

function tavern:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw tavern background image
    if self.backgroundImage then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.backgroundImage, 0, 0)
    else
        -- Fallback if image not loaded
        love.graphics.setColor(0.4, 0.3, 0.2)
        love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    end
    
    -- Draw state-specific UI
    if self.state == "main" then
        self.elements.questListPanel:draw()
        self.elements.refreshButton:draw()
    elseif self.state == "quest_details" then
        self.elements.questDetailsPanel:draw()
    elseif self.state == "haggle" then
        -- Draw background panels
        self.elements.questDetailsPanel:draw()
        self.elements.hagglePanel:draw()
    end
    
    -- Draw back button
    self.elements.backToTownButton:draw()
    
    -- Draw party panel if visible
    if self.elements.partyPanel and self.elements.partyPanel.visible then
        self.elements.partyPanel:draw()
    end
end

function tavern:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Debug click coordinates
    if GAME.debug then
        print("Tavern clicked at: " .. x .. "," .. y .. " - Current state: " .. self.state)
    end
    
    -- Pass to UI elements based on current state
    if self.state == "haggle" then
        -- Check haggle panel first
        if self.elements.hagglePanel.visible then
            if GAME.debug then
                print("Checking haggle panel clicks")
            end
            clickHandled = self.elements.hagglePanel:clicked(x, y, button)
            if clickHandled then
                -- Play click sound
                assetManager:playSound("click")
                if GAME.debug then
                    print("Haggle panel click handled")
                end
                return true
            end
        end
    end
    
    -- Check quest details panel
    if self.state == "quest_details" or self.state == "haggle" then
        if self.elements.questDetailsPanel.visible and not clickHandled then
            clickHandled = self.elements.questDetailsPanel:clicked(x, y, button)
            if clickHandled then
                -- Play click sound
                assetManager:playSound("click")
                return true
            end
        end
    end
    
    -- Check other panels and buttons
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false and 
           element ~= self.elements.questDetailsPanel and
           element ~= self.elements.hagglePanel then
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Tavern button clicked: " .. name)
                end
                
                clickHandled = true
                -- Don't break to allow hover effects
            end
        end
    end
    
    return clickHandled
end

function tavern:loadQuests()
    -- Get available quests
    self.questList = questSystem:getAvailableQuests("Tavern")
    
    -- Sort quests by level
    table.sort(self.questList, function(a, b)
        if a.level == b.level then
            return a.difficulty < b.difficulty
        end
        return a.level < b.level
    end)
end

function tavern:refreshQuests()
    -- Reset quest timer
    self.refreshTimer = 0
    
    -- Reset available quests
    questSystem:resetAvailableQuests()
    
    -- Reload quests
    self:loadQuests()
    
    -- Reset selection
    self.selectedQuest = nil
    self.elements.questDetailsPanel.visible = false
    self.state = "main"
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:selectQuest(quest)
    -- Select quest
    self.selectedQuest = quest
    
    -- Initialize haggleAttempts if not exists
    if not self.selectedQuest.haggleAttempts then
        self.selectedQuest.haggleAttempts = 0
    end
    
    -- Initialize canHaggle if not exists (Tavern quests can be haggled)
    if self.selectedQuest.canHaggle == nil then
        self.selectedQuest.canHaggle = (self.selectedQuest.giver == "Tavern")
    end
    
    -- Reset haggle result
    if self.elements.hagglePanel then
        self.elements.hagglePanel.haggleResult = nil
        self.elements.hagglePanel:calculateHaggleChance()
    end
    
    -- Show quest details
    self.state = "quest_details"
    self.elements.questDetailsPanel.visible = true
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:showMainScreen()
    -- Go back to main screen
    self.state = "main"
    self.elements.questDetailsPanel.visible = false
    self.elements.hagglePanel.visible = false
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:acceptQuest()
    if not self.selectedQuest then
        return
    end
    
    -- Accept quest
    if questSystem:acceptQuest(self.selectedQuest.id) then
        -- Play success sound
        assetManager:playSound("pickup")
        
        -- Return to town
        self:returnToTown()
    else
        -- Play error sound
        assetManager:playSound("hit")
    end
end

function tavern:startHaggle()
    if not self.selectedQuest then
        return
    end
    
    -- Check if quest supports haggling
    if not self.selectedQuest.canHaggle then
        -- Play error sound
        assetManager:playSound("error")
        return
    end
    
    -- Calculate haggle chance
    self.elements.hagglePanel:calculateHaggleChance()
    
    -- Reset haggle result
    self.elements.hagglePanel.haggleResult = nil
    
    -- Store original reward
    self.originalReward = self.selectedQuest.rewards.gold
    
    -- Show haggle panel
    self.state = "haggle"
    self.elements.hagglePanel.visible = true
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:tryHaggle()
    if not self.selectedQuest then
        return
    end
    
    -- Find first party member to use for haggling
    local character = GAME.party[1]
    if not character then
        return
    end
    
    -- Make sure haggleAttempts is initialized
    if not self.selectedQuest.haggleAttempts then
        self.selectedQuest.haggleAttempts = 0
    end
    
    -- Attempt to haggle with the questgiver
    local success, message, successChance = questSystem:haggle(self.selectedQuest.id, character)
    
    -- Store haggle result
    self.elements.hagglePanel.haggleResult = {
        success = success,
        message = message,
        successChance = successChance
    }
    
    -- Play sound based on result
    if success then
        assetManager:playSound("pickup")
    else
        assetManager:playSound("hit")
    end
    
    -- Update haggle chance for UI display
    self.elements.hagglePanel:calculateHaggleChance()
end

function tavern:acceptHaggle()
    -- Close haggle panel and go back to quest details
    self.state = "quest_details"
    self.elements.hagglePanel.visible = false
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:cancelHaggle()
    -- Close haggle panel and go back to quest details
    self.state = "quest_details"
    self.elements.hagglePanel.visible = false
    self.elements.hagglePanel.haggleResult = nil
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:returnToTown()
    -- Return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

function tavern:mousereleased(x, y, button, istouch, presses)
    -- Handle mouse releases for UI elements based on current state
    if self.state == "haggle" and self.elements.hagglePanel.visible then
        -- Handle haggle panel button releases
        if self.haggleSuccess or self.haggleAttempts >= self.maxHaggleAttempts then
            if self.elements.hagglePanel.acceptButton and self.elements.hagglePanel.acceptButton.released then
                self.elements.hagglePanel.acceptButton:released(x, y, button)
            end
        else
            -- Handle haggle option buttons
            if self.elements.hagglePanel.lowHaggleButton and self.elements.hagglePanel.lowHaggleButton.released then
                self.elements.hagglePanel.lowHaggleButton:released(x, y, button)
            end
            
            if self.elements.hagglePanel.mediumHaggleButton and self.elements.hagglePanel.mediumHaggleButton.released then
                self.elements.hagglePanel.mediumHaggleButton:released(x, y, button)
            end
            
            if self.elements.hagglePanel.highHaggleButton and self.elements.hagglePanel.highHaggleButton.released then
                self.elements.hagglePanel.highHaggleButton:released(x, y, button)
            end
        end
        
        if self.elements.hagglePanel.cancelButton and self.elements.hagglePanel.cancelButton.released then
            self.elements.hagglePanel.cancelButton:released(x, y, button)
        end
    end
    
    -- Handle quest details panel button releases
    if (self.state == "quest_details" or self.state == "haggle") and self.elements.questDetailsPanel.visible then
        if self.elements.questDetailsPanel.acceptButton and self.elements.questDetailsPanel.acceptButton.released then
            self.elements.questDetailsPanel.acceptButton:released(x, y, button)
        end
        
        if self.elements.questDetailsPanel.haggleButton and self.elements.questDetailsPanel.haggleButton.released then
            self.elements.questDetailsPanel.haggleButton:released(x, y, button)
        end
        
        if self.elements.questDetailsPanel.backButton and self.elements.questDetailsPanel.backButton.released then
            self.elements.questDetailsPanel.backButton:released(x, y, button)
        end
    end
    
    -- Handle back to town button
    if self.elements.backToTownButton and self.elements.backToTownButton.released then
        self.elements.backToTownButton:released(x, y, button)
    end
    
    -- Handle refresh button if visible
    if self.state == "main" and self.elements.refreshButton and self.elements.refreshButton.released then
        self.elements.refreshButton:released(x, y, button)
    end
    
    if GAME.debug then
        print("Tavern mouse released at: " .. x .. "," .. y)
    end
end

return tavern
