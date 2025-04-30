-- Guild Screen
-- Where players can accept quests from the Adventurers' Guild
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local questSystem = require("gameplay/questSystem")

local guild = screenManager:createScreen("Adventurers' Guild")

function guild:init()
    -- Initialize state
    self.state = "main" -- main, quest_details
    self.selectedQuest = nil
    self.questList = {}
    self.refreshTimer = 0
    
    -- Create UI elements
    self:createUI()
end

function guild:createUI()
    -- Create quest list panel
    self.elements.questListPanel = {
        x = 50,
        y = 120,
        width = 700,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Available Quests", self.x, self.y, self.width, self.height)
            
            -- Draw quests
            for i, quest in ipairs(guild.questList) do
                local questY = self.y + 50 + (i-1) * 70
                
                -- Skip if out of view
                if questY > self.y + self.height - 20 then
                    break
                end
                
                -- Draw quest entry background
                if quest == guild.selectedQuest then
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
            if #guild.questList == 0 then
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
                for i, quest in ipairs(guild.questList) do
                    local questY = self.y + 50 + (i-1) * 70
                    
                    -- Skip if out of view
                    if questY > self.y + self.height - 20 then
                        break
                    end
                    
                    if y >= questY and y <= questY + 60 then
                        guild:selectQuest(quest)
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
            if not self.visible or not guild.selectedQuest then
                return
            end
            
            local quest = guild.selectedQuest
            
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
            self.backButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check button clicks
            if self.acceptButton:clicked(x, y, button) then
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
                self.x + self.width / 2 - 120, self.y + self.height - 70, 
                100, 40, "Accept", 
                function() guild:acceptQuest() end
            )
            
            self.backButton = screenManager.UI.Button(
                self.x + self.width / 2 + 20, self.y + self.height - 70, 
                100, 40, "Back", 
                function() guild:showMainScreen() end
            )
        end
    }
    
    -- Initialize panels
    self.elements.questDetailsPanel:init()
    
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
    
    -- Set initial visibility state
    self:updateElementVisibility()
end

function guild:updateElementVisibility()
    -- Update element visibility based on current state
    if self.state == "main" then
        if self.elements.questDetailsPanel then
            self.elements.questDetailsPanel.visible = false
        end
        if self.elements.refreshButton then
            self.elements.refreshButton.visible = true
        end
    elseif self.state == "quest_details" then
        if self.elements.questDetailsPanel then
            self.elements.questDetailsPanel.visible = true
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
        print("Guild UI visibility updated - State: " .. self.state)
    end
end

function guild:enter()
    -- Start playing guild music
    -- assetManager:playMusic("town") -- Use town music for now
    
    -- Load quests
    self:loadQuests()
    
    -- Initialize state
    self.state = "main"
    self.selectedQuest = nil
    
    -- Update element visibility
    self:updateElementVisibility()
end

function guild:update(dt)
    -- Update refresh timer
    self.refreshTimer = self.refreshTimer + dt
    
    -- Auto refresh quests every 5 minutes of real time
    if self.refreshTimer >= 300 then
        self:refreshQuests()
        self.refreshTimer = 0
    end
end

function guild:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw guild hall interior (placeholder)
    love.graphics.setColor(0.3, 0.25, 0.2)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw guild banner
    love.graphics.setColor(0.7, 0.2, 0.2)
    love.graphics.rectangle("fill", GAME.width / 2 - 100, 20, 200, 40)
    
    -- Draw notice board
    love.graphics.setColor(0.6, 0.5, 0.4)
    love.graphics.rectangle("fill", 40, 110, 720, 420)
    
    love.graphics.setColor(0.4, 0.3, 0.2)
    love.graphics.rectangle("line", 40, 110, 720, 420, 5, 5)
    
    -- Draw screen title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Adventurers' Guild", 50, 30)
    
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
    elseif self.state == "quest_details" then
        self.elements.questDetailsPanel:draw()
    end
    
    -- Draw back button
    self.elements.backToTownButton:draw()
end

function guild:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Check quest details panel if in that state
    if self.state == "quest_details" and self.elements.questDetailsPanel.visible then
        clickHandled = self.elements.questDetailsPanel:clicked(x, y, button)
        if clickHandled then
            -- Play click sound
            assetManager:playSound("click")
            return true
        end
    end
    
    -- Check quest list panel if in main state
    if self.state == "main" and not clickHandled then
        clickHandled = self.elements.questListPanel:clicked(x, y, button)
        if clickHandled then
            -- Play click sound
            assetManager:playSound("click")
            return true
        end
    end
    
    -- Check other UI elements
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false and 
           element ~= self.elements.questDetailsPanel and
           element ~= self.elements.questListPanel then
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Guild button clicked: " .. name)
                end
                
                clickHandled = true
                -- Don't break to allow hover effects
            end
        end
    end
    
    return clickHandled
end

function guild:mousereleased(x, y, button, istouch, presses)
    -- Handle mouse releases for UI elements
    if self.state == "quest_details" and self.elements.questDetailsPanel.visible then
        -- Check if any button in the quest details panel was released
        local acceptButton = self.elements.questDetailsPanel.acceptButton
        local backButton = self.elements.questDetailsPanel.backButton
        
        if acceptButton and acceptButton.released then
            acceptButton:released(x, y, button)
        end
        
        if backButton and backButton.released then
            backButton:released(x, y, button)
        end
    end
    
    -- Check back to town button
    if self.elements.backToTownButton and self.elements.backToTownButton.released then
        self.elements.backToTownButton:released(x, y, button)
    end
    
    -- Check refresh button if visible
    if self.state == "main" and self.elements.refreshButton and self.elements.refreshButton.released then
        self.elements.refreshButton:released(x, y, button)
    end
    
    if GAME.debug then
        print("Guild mouse released at: " .. x .. "," .. y)
    end
end

function guild:loadQuests()
    -- Get available quests
    self.questList = questSystem:getAvailableQuests("Guild")
    
    -- Sort quests by level
    table.sort(self.questList, function(a, b)
        if a.level == b.level then
            return a.difficulty < b.difficulty
        end
        return a.level < b.level
    end)
end

function guild:refreshQuests()
    -- Reset quest timer
    self.refreshTimer = 0
    
    -- Reset available quests
    questSystem:resetAvailableQuests()
    
    -- Reload quests
    self:loadQuests()
    
    -- Reset selection
    self.selectedQuest = nil
    
    -- Update element visibility
    self:updateElementVisibility()
end

function guild:selectQuest(quest)
    -- Select quest
    self.selectedQuest = quest
    
    -- Show quest details
    self.state = "quest_details"
    
    -- Update element visibility
    self:updateElementVisibility()
end

function guild:showMainScreen()
    -- Go back to main screen
    self.state = "main"
    
    -- Update element visibility
    self:updateElementVisibility()
end

function guild:acceptQuest()
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

function guild:returnToTown()
    -- Return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

return guild
