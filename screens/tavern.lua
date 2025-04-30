-- Tavern Screen
-- Where players can accept quests and haggle for better rewards
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local questSystem = require("gameplay/questSystem")

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
    
    -- Create UI elements
    self:createUI()
end

function tavern:createUI()
    -- Create quest list panel
    self.elements.questListPanel = {
        x = 50,
        y = 120,
        width = 700,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Tavern Quests", self.x, self.y, self.width, self.height)
            
            -- Draw quests
            for i, quest in ipairs(tavern.questList) do
                local questY = self.y + 50 + (i-1) * 70
                
                -- Skip if out of view
                if questY > self.y + self.height - 20 then
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
                    self.x + 10, questY, 
                    self.width - 20, 60,
                    5, 5
                )
                
                -- Draw quest name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    quest.name,
                    self.x + 20, questY + 10
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
                    self.x + 20, questY + 35
                )
                
                -- Draw reward preview
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Reward: " .. quest.rewards.gold .. " gold",
                    self.x + 500, questY + 35
                )
            end
            
            -- Draw message if no quests
            if #tavern.questList == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                love.graphics.printf(
                    "No quests available at the moment.\nCheck back later!",
                    self.x + 20, self.y + 150,
                    self.width - 40, "center"
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
                    local questY = self.y + 50 + (i-1) * 70
                    
                    -- Skip if out of view
                    if questY > self.y + self.height - 20 then
                        break
                    end
                    
                    if y >= questY and y <= questY + 60 then
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
        x = 50,
        y = 120,
        width = 700,
        height = 400,
        visible = false,
        
        draw = function(self)
            if not self.visible or not tavern.selectedQuest then
                return
            end
            
            local quest = tavern.selectedQuest
            
            -- Draw panel background
            screenManager:drawPanel("Quest Details", self.x, self.y, self.width, self.height)
            
            -- Draw quest name
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                quest.name,
                self.x + 20, self.y + 50,
                self.width - 40, "center"
            )
            
            -- Draw quest description
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 0.9)
            
            love.graphics.printf(
                quest.description,
                self.x + 30, self.y + 100,
                self.width - 60, "center"
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
                self.x + 30, self.y + 170
            )
            
            -- Draw level
            love.graphics.setColor(0.7, 0.7, 1)
            
            love.graphics.print(
                "Recommended Level: " .. quest.level,
                self.x + 30, self.y + 200
            )
            
            -- Draw rewards section
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.print(
                "Rewards:",
                self.x + 30, self.y + 240
            )
            
            -- Draw gold reward
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 0)
            
            love.graphics.print(
                quest.rewards.gold .. " Gold",
                self.x + 50, self.y + 270
            )
            
            -- Draw item rewards
            if quest.rewards.items and #quest.rewards.items > 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Items:",
                    self.x + 50, self.y + 300
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
                        self.x + 70, self.y + 300 + i * 25
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
                "Haggle attempts: " .. tavern.haggleAttempts .. "/" .. tavern.maxHaggleAttempts,
                self.x + 20, self.y + 90,
                self.width - 40, "center"
            )
            
            -- Draw success message if successful
            if tavern.haggleSuccess then
                love.graphics.setColor(0.2, 0.8, 0.2)
                
                love.graphics.printf(
                    "Success! The reward has been increased by " .. 
                    tavern.hagglePercentage .. "%!",
                    self.x + 20, self.y + 130,
                    self.width - 40, "center"
                )
            elseif tavern.haggleAttempts > 0 then
                -- Draw failure message
                love.graphics.setColor(0.8, 0.2, 0.2)
                
                love.graphics.printf(
                    "Failed! Try again or accept the current reward.",
                    self.x + 20, self.y + 130,
                    self.width - 40, "center"
                )
            end
            
            -- Draw haggle instructions
            if not tavern.haggleSuccess and tavern.haggleAttempts < tavern.maxHaggleAttempts then
                love.graphics.setColor(0.8, 0.8, 0.2)
                
                love.graphics.printf(
                    "Choose how much extra to ask for:",
                    self.x + 20, self.y + 160,
                    self.width - 40, "center"
                )
            end
            
            -- Draw buttons
            if tavern.haggleSuccess or tavern.haggleAttempts >= tavern.maxHaggleAttempts then
                -- Show accept button
                self.acceptButton:draw()
            else
                -- Show haggle option buttons
                self.lowHaggleButton:draw()
                self.mediumHaggleButton:draw()
                self.highHaggleButton:draw()
            end
            
            -- Draw cancel button
            self.cancelButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check button clicks
            if tavern.haggleSuccess or tavern.haggleAttempts >= tavern.maxHaggleAttempts then
                if self.acceptButton:clicked(x, y, button) then
                    return true
                end
            else
                if self.lowHaggleButton:clicked(x, y, button) then
                    return true
                end
                
                if self.mediumHaggleButton:clicked(x, y, button) then
                    return true
                end
                
                if self.highHaggleButton:clicked(x, y, button) then
                    return true
                end
            end
            
            if self.cancelButton:clicked(x, y, button) then
                return true
            end
            
            return false
        end,
        
        init = function(self)
            -- Create buttons
            self.lowHaggleButton = screenManager.UI.Button(
                self.x + 50, self.y + 200, 
                100, 40, "10% More", 
                function() tavern:tryHaggle(10) end
            )
            
            self.mediumHaggleButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + 200, 
                100, 40, "25% More", 
                function() tavern:tryHaggle(25) end
            )
            
            self.highHaggleButton = screenManager.UI.Button(
                self.x + self.width - 150, self.y + 200, 
                100, 40, "50% More", 
                function() tavern:tryHaggle(50) end
            )
            
            self.acceptButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + 200, 
                100, 40, "Accept", 
                function() tavern:acceptHaggle() end
            )
            
            self.cancelButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + 250, 
                100, 40, "Cancel", 
                function() tavern:cancelHaggle() end
            )
        end
    }
    
    -- Initialize panels
    self.elements.questDetailsPanel:init()
    self.elements.hagglePanel:init()
    
    -- Create back button
    self.elements.backToTownButton = screenManager.UI.Button(
        GAME.width - 170, GAME.height - 70, 
        150, 40, "Back to Town", 
        function() self:returnToTown() end
    )
    self.elements.backToTownButton.visible = true
    
    -- Create refresh button
    self.elements.refreshButton = screenManager.UI.Button(
        620, 70, 130, 40, "Refresh", 
        function() self:refreshQuests() end
    )
    self.elements.refreshButton.visible = true
    
    -- Set initial visibility state for all UI elements
    self:updateElementVisibility()
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
    
    -- Draw tavern interior (placeholder)
    love.graphics.setColor(0.4, 0.3, 0.2)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw tavern counter
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", 50, 20, 700, 80)
    
    -- Draw tavern notice board
    love.graphics.setColor(0.5, 0.4, 0.3)
    love.graphics.rectangle("fill", 40, 110, 720, 420)
    
    love.graphics.setColor(0.3, 0.2, 0.1)
    love.graphics.rectangle("line", 40, 110, 720, 420, 5, 5)
    
    -- Draw screen title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("The Dragon's Rest Tavern", 50, 30)
    
    -- Draw current gold
    if GAME.gold then
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.setColor(1, 1, 0)
        
        love.graphics.print(
            "Gold: " .. GAME.gold,
            50, 70
        )
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
end

function tavern:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Pass to UI elements based on current state
    if self.state == "haggle" then
        -- Check haggle panel first
        if self.elements.hagglePanel.visible then
            clickHandled = self.elements.hagglePanel:clicked(x, y, button)
            if clickHandled then
                -- Play click sound
                assetManager:playSound("click")
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
    
    -- Store original reward
    self.originalReward = self.selectedQuest.rewards.gold
    
    -- Reset haggle state
    self.haggleAttempts = 0
    self.haggleSuccess = false
    
    -- Show haggle panel
    self.state = "haggle"
    self.elements.hagglePanel.visible = true
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:tryHaggle(percentage)
    -- Increment haggle attempts
    self.haggleAttempts = self.haggleAttempts + 1
    
    -- Calculate success chance based on difficulty and percentage
    local baseChance = 0
    
    if percentage == 10 then
        baseChance = 70  -- 70% chance for small increase
    elseif percentage == 25 then
        baseChance = 40  -- 40% chance for medium increase
    elseif percentage == 50 then
        baseChance = 20  -- 20% chance for large increase
    end
    
    -- Adjust chance based on difficulty
    local difficultyModifier = 0
    
    if self.selectedQuest.difficulty == questSystem.DIFFICULTY.EASY then
        difficultyModifier = 10  -- +10% for easy quests
    elseif self.selectedQuest.difficulty == questSystem.DIFFICULTY.MEDIUM then
        difficultyModifier = 0   -- No modifier for medium
    elseif self.selectedQuest.difficulty == questSystem.DIFFICULTY.HARD then
        difficultyModifier = -10 -- -10% for hard
    elseif self.selectedQuest.difficulty == questSystem.DIFFICULTY.VERY_HARD then
        difficultyModifier = -20 -- -20% for very hard
    elseif self.selectedQuest.difficulty == questSystem.DIFFICULTY.LEGENDARY then
        difficultyModifier = -30 -- -30% for legendary
    end
    
    -- Calculate final chance
    local successChance = baseChance + difficultyModifier
    
    -- Check for success
    local roll = math.random(1, 100)
    
    if roll <= successChance then
        -- Success!
        self.haggleSuccess = true
        self.hagglePercentage = percentage
        
        -- Increase reward
        local increase = math.floor(self.originalReward * percentage / 100)
        self.selectedQuest.rewards.gold = self.originalReward + increase
        
        -- Play success sound
        assetManager:playSound("pickup")
    else
        -- Failure
        -- Play failure sound
        assetManager:playSound("hit")
    end
end

function tavern:acceptHaggle()
    -- Close haggle panel
    self.elements.hagglePanel.visible = false
    self.state = "quest_details"
    
    -- Update element visibility
    self:updateElementVisibility()
end

function tavern:cancelHaggle()
    -- Reset reward
    if self.selectedQuest then
        self.selectedQuest.rewards.gold = self.originalReward
    end
    
    -- Close haggle panel
    self.elements.hagglePanel.visible = false
    self.state = "quest_details"
    
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
