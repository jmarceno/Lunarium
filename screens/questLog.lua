-- Quest Log Screen
-- Where players can view their active and completed quests
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local questSystem = require("gameplay/questSystem")

local questLog = screenManager:createScreen("Quest Log")

function questLog:init()
    -- Initialize state
    self.state = "main"
    self.selectedQuest = nil
    self.category = "active" -- active, completed
    
    -- Create UI elements
    self:createUI()
end

function questLog:createUI()
    -- Create category tabs
    self.elements.activeTab = screenManager.UI.Button(
        150, 70, 170, 40, "Active Quests", 
        function() self:selectCategory("active") end
    )
    self.elements.activeTab.visible = true
    
    self.elements.completedTab = screenManager.UI.Button(
        450, 70, 170, 40, "Completed Quests", 
        function() self:selectCategory("completed") end
    )
    self.elements.completedTab.visible = true
    
    -- Create quest list panel
    self.elements.questListPanel = {
        x = 50,
        y = 120,
        width = 300,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Quests", self.x, self.y, self.width, self.height)
            
            -- Get quests based on selected category
            local quests = {}
            if questLog.category == "active" then
                quests = questSystem:getActiveQuests()
            else
                quests = questSystem:getCompletedQuests()
            end
            
            -- De-duplicate quests by ID
            local uniqueQuests = {}
            local questIds = {}
            
            for _, quest in ipairs(quests) do
                if not questIds[quest.id] then
                    questIds[quest.id] = true
                    table.insert(uniqueQuests, quest)
                end
            end
            
            -- Draw quests
            for i, quest in ipairs(uniqueQuests) do
                local questY = self.y + 50 + (i-1) * 70
                
                -- Skip if out of view
                if questY > self.y + self.height - 20 then
                    break
                end
                
                -- Draw quest entry background
                if quest == questLog.selectedQuest then
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
                
                -- Draw quest source
                love.graphics.setColor(0.7, 0.7, 1)
                love.graphics.print(
                    "Source: " .. (quest.source or "Unknown"),
                    self.x + 170, questY + 35
                )
            end
            
            -- Draw message if no quests
            if #uniqueQuests == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                if questLog.category == "active" then
                    love.graphics.printf(
                        "No active quests.\nVisit the Guild or Tavern to find quests!",
                        self.x + 20, self.y + 150,
                        self.width - 40, "center"
                    )
                else
                    love.graphics.printf(
                        "No completed quests.\nComplete quests to see them here!",
                        self.x + 20, self.y + 150,
                        self.width - 40, "center"
                    )
                end
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Get quests based on selected category
                local quests = {}
                if questLog.category == "active" then
                    quests = questSystem:getActiveQuests()
                else
                    quests = questSystem:getCompletedQuests()
                end
                
                -- De-duplicate quests by ID
                local uniqueQuests = {}
                local questIds = {}
                
                for _, quest in ipairs(quests) do
                    if not questIds[quest.id] then
                        questIds[quest.id] = true
                        table.insert(uniqueQuests, quest)
                    end
                end
                
                -- Check quest entries
                for i, quest in ipairs(uniqueQuests) do
                    local questY = self.y + 50 + (i-1) * 70
                    
                    -- Skip if out of view
                    if questY > self.y + self.height - 20 then
                        break
                    end
                    
                    if y >= questY and y <= questY + 60 then
                        questLog:selectQuest(quest)
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
        x = 370,
        y = 120,
        width = 380,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Quest Details", self.x, self.y, self.width, self.height)
            
            -- Draw quest details or placeholder message
            if questLog.selectedQuest then
                local quest = questLog.selectedQuest
                
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
                
                -- Draw quest objectives
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Objectives:",
                    self.x + 30, self.y + 180
                )
                
                -- Draw objectives list
                love.graphics.setFont(screenManager.fonts.small)
                
                if quest.objectives then
                    for i, objective in ipairs(quest.objectives) do
                        if objective.completed then
                            love.graphics.setColor(0.2, 0.8, 0.2)
                            love.graphics.print(
                                "✓ " .. objective.description,
                                self.x + 40, self.y + 200 + (i-1) * 25
                            )
                        else
                            love.graphics.setColor(0.7, 0.7, 0.7)
                            love.graphics.print(
                                "□ " .. objective.description,
                                self.x + 40, self.y + 200 + (i-1) * 25
                            )
                        end
                    end
                else
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    love.graphics.print(
                        "• Complete the quest",
                        self.x + 40, self.y + 200
                    )
                end
                
                -- Draw rewards section
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Rewards:",
                    self.x + 30, self.y + 280
                )
                
                -- Draw gold reward
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    quest.rewards.gold .. " Gold",
                    self.x + 50, self.y + 310
                )
                
                -- Draw item rewards
                if quest.rewards.items and #quest.rewards.items > 0 then
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        "Items:",
                        self.x + 50, self.y + 340
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
                            self.x + 70, self.y + 340 + i * 25
                        )
                    end
                end
            else
                -- No quest selected
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                love.graphics.printf(
                    "Select a quest to view details",
                    self.x + 20, self.y + 200,
                    self.width - 40, "center"
                )
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
    
    -- Set initial visibility state
    self:updateElementVisibility()
end

function questLog:updateElementVisibility()
    -- All elements are visible in the quest log
    for name, element in pairs(self.elements) do
        if element.visible ~= nil then
            element.visible = true
        end
    end
    
    -- Update tab highlighting based on selected category
    if self.category == "active" then
        -- Update tab appearance
        self.elements.activeTab.colors = {
            normal = {0.3, 0.3, 0.6},
            hover = {0.4, 0.4, 0.7},
            press = {0.2, 0.2, 0.5}
        }
        self.elements.completedTab.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
    else
        -- Update tab appearance
        self.elements.activeTab.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
        self.elements.completedTab.colors = {
            normal = {0.3, 0.3, 0.6},
            hover = {0.4, 0.4, 0.7},
            press = {0.2, 0.2, 0.5}
        }
    end
    
    if GAME.debug then
        print("Quest Log UI visibility updated - Category: " .. self.category)
    end
end

function questLog:enter()
    -- Reset state
    self.category = "active"
    self.selectedQuest = nil
    
    -- Update element visibility
    self:updateElementVisibility()
end

function questLog:update(dt)
    -- Nothing to update in real-time for quest log
end

function questLog:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw parchment background
    love.graphics.setColor(screenManager.colors.background)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw screen title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(screenManager.colors.title)
    love.graphics.print("Quest Log", 50, 30)
    
    -- Draw UI elements
    for name, element in pairs(self.elements) do
        if element.draw and element.visible ~= false then
            element:draw()
        end
    end
end

function questLog:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Check all UI elements
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false then
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Quest Log button clicked: " .. name)
                end
                
                clickHandled = true
                -- Don't break to allow hover effects
            end
        end
    end
    
    return clickHandled
end

function questLog:mousereleased(x, y, button, istouch, presses)
    -- Handle mouse releases for UI elements
    
    -- Handle tab buttons
    if self.elements.activeTab and self.elements.activeTab.released then
        self.elements.activeTab:released(x, y, button)
    end
    
    if self.elements.completedTab and self.elements.completedTab.released then
        self.elements.completedTab:released(x, y, button)
    end
    
    -- Handle back to game button
    if self.elements.backToGameButton and self.elements.backToGameButton.released then
        self.elements.backToGameButton:released(x, y, button)
    end
    
    if GAME.debug then
        print("Quest Log mouse released at: " .. x .. "," .. y)
    end
end

function questLog:selectCategory(category)
    -- Select category
    self.category = category
    
    -- Reset selected quest
    self.selectedQuest = nil
    
    -- Update element visibility
    self:updateElementVisibility()
end

function questLog:selectQuest(quest)
    -- Select quest
    self.selectedQuest = quest
    
    if GAME.debug then
        print("Selected quest: " .. quest.name)
    end
end

function questLog:returnToGame()
    -- Return to game
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

return questLog 