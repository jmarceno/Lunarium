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
    self.questScroll = 0
    self.maxQuestScroll = 0
    self.selectedQuestIndex = 1
    self.questsPerView = 8
    self.showConfirmDialog = false -- Add confirmation dialog state
    
    -- Create UI elements
    self:createUI()
end

function questLog:createUI()
    -- Column 1: Category Buttons
    self.elements.categoryPanel = {
        x = 50,
        y = 120,
        width = 200,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Categories", self.x, self.y, self.width, self.height)
        end
    }
    
    -- Create category buttons
    self.elements.activeButton = screenManager.UI.Button(
        70, 180, 160, 40, "Active Quests", 
        function() questLog:selectCategory("active") end
    )
    self.elements.activeButton.visible = true
    
    self.elements.completedButton = screenManager.UI.Button(
        70, 230, 160, 40, "Completed Quests", 
        function() questLog:selectCategory("completed") end
    )
    self.elements.completedButton.visible = true
    
    -- Column 2: Quest List Panel
    self.elements.questListPanel = {
        x = 270,
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
            
            -- Update max scroll value
            questLog.maxQuestScroll = math.max(0, #uniqueQuests - questLog.questsPerView)
            
            -- Draw quests
            local startIndex = questLog.questScroll + 1
            local endIndex = math.min(startIndex + questLog.questsPerView - 1, #uniqueQuests)
            
            for i = startIndex, endIndex do
                local quest = uniqueQuests[i]
                local questY = self.y + 50 + (i - startIndex) * 40
                
                -- Draw quest entry background
                if i == questLog.selectedQuestIndex then
                    love.graphics.setColor(0.3, 0.3, 0.5)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle(
                    "fill",
                    self.x + 10, questY, 
                    self.width - 40, 35,
                    5, 5
                )
                
                -- Draw quest name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                -- Truncate long names
                local questName = quest.name
                if love.graphics.getFont():getWidth(questName) > self.width - 60 then
                    local truncatedName = ""
                    for i = 1, #questName do
                        if love.graphics.getFont():getWidth(truncatedName .. questName:sub(i,i) .. "...") > self.width - 60 then
                            truncatedName = truncatedName .. "..."
                            break
                        end
                        truncatedName = truncatedName .. questName:sub(i,i)
                    end
                    questName = truncatedName
                end
                
                love.graphics.print(
                    questName,
                    self.x + 20, questY + 5
                )
            end
            
            -- Draw scrollbar if needed
            if questLog.maxQuestScroll > 0 then
                -- Draw scrollbar background
                love.graphics.setColor(0.15, 0.15, 0.2)
                love.graphics.rectangle(
                    "fill",
                    self.x + self.width - 25, self.y + 50,
                    15, self.height - 70,
                    5, 5
                )
                
                -- Draw scrollbar handle
                local scrollbarHeight = (self.height - 70) * (questLog.questsPerView / #uniqueQuests)
                local scrollbarY = self.y + 50 + (self.height - 70 - scrollbarHeight) * (questLog.questScroll / questLog.maxQuestScroll)
                
                love.graphics.setColor(0.4, 0.4, 0.6)
                love.graphics.rectangle(
                    "fill",
                    self.x + self.width - 25, scrollbarY,
                    15, scrollbarHeight,
                    5, 5
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
            
            -- Check if click is within panel content area
            if x >= self.x + 10 and x <= self.x + self.width - 30 and
               y >= self.y + 50 and y <= self.y + self.height - 20 then
                
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
                
                -- Determine which quest was clicked
                local startIndex = questLog.questScroll + 1
                local endIndex = math.min(startIndex + questLog.questsPerView - 1, #uniqueQuests)
                
                for i = startIndex, endIndex do
                    local questY = self.y + 50 + (i - startIndex) * 40
                    
                    if y >= questY and y <= questY + 35 then
                        questLog.selectedQuestIndex = i
                        questLog:selectQuest(uniqueQuests[i])
                        return true
                    end
                end
                
                return true
            end
            
            -- Check scrollbar click
            if questLog.maxQuestScroll > 0 and
               x >= self.x + self.width - 25 and x <= self.x + self.width - 10 and
               y >= self.y + 50 and y <= self.y + self.height - 20 then
                
                -- Get quests based on category
                local quests = {}
                if questLog.category == "active" then
                    quests = questSystem:getActiveQuests()
                else
                    quests = questSystem:getCompletedQuests()
                end
                
                -- Calculate new scroll position
                local uniqueQuestsCount = 0
                local questIds = {}
                for _, quest in ipairs(quests) do
                    if not questIds[quest.id] then
                        questIds[quest.id] = true
                        uniqueQuestsCount = uniqueQuestsCount + 1
                    end
                end
                
                local scrollRatio = (y - (self.y + 50)) / (self.height - 70)
                local newScroll = math.floor(scrollRatio * questLog.maxQuestScroll)
                questLog.questScroll = math.max(0, math.min(questLog.maxQuestScroll, newScroll))
                
                return true
            end
            
            return false
        end,
        
        -- Add mouse wheel support
        wheelmoved = function(self, x, y)
            if y > 0 then
                -- Scroll up
                questLog.questScroll = math.max(0, questLog.questScroll - 1)
            elseif y < 0 then
                -- Scroll down
                questLog.questScroll = math.min(questLog.maxQuestScroll, questLog.questScroll + 1)
            end
            
            return true
        end
    }
    
    -- Column 3: Quest Details Panel
    self.elements.questDetailsPanel = {
        x = 590,
        y = 120,
        width = 560,
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
                    self.width - 60, "left" -- Left aligned for better readability
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
                                self.x + 40, self.y + 210 + (i-1) * 25
                            )
                        else
                            love.graphics.setColor(0.7, 0.7, 0.7)
                            love.graphics.print(
                                "□ " .. objective.description,
                                self.x + 40, self.y + 210 + (i-1) * 25
                            )
                        end
                    end
                else
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    love.graphics.print(
                        "• Complete the quest",
                        self.x + 40, self.y + 210
                    )
                end
                
                -- Draw rewards section
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Rewards:",
                    self.x + 30, self.y + 290
                )
                
                -- Draw gold reward
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    quest.rewards.gold .. " Gold",
                    self.x + 50, self.y + 320
                )
                
                -- Draw item rewards
                if quest.rewards.items and #quest.rewards.items > 0 then
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        "Items:",
                        self.x + 50, self.y + 350
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
                            self.x + 70, self.y + 350 + i * 25
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
    
    -- Create abandon quest button (positioned below quest details panel)
    self.elements.abandonQuestButton = screenManager.UI.Button(
        590 + 560/2 - 75, 540, -- Center horizontally below quest details panel
        150, 40, "Abandon Quest", 
        function() self:showAbandonConfirmation() end
    )
    self.elements.abandonQuestButton.visible = false -- Only visible for active quests
    self.elements.abandonQuestButton.colors = {
        normal = {0.8, 0.3, 0.3},
        hover = {0.9, 0.4, 0.4},
        press = {0.7, 0.2, 0.2}
    }
    
    -- Create confirmation dialog elements
    self.elements.confirmDialog = {
        x = GAME.width/2 - 250,
        y = GAME.height/2 - 100,
        width = 500,
        height = 200,
        visible = false,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw dialog background
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height) -- Overlay
            
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw dialog title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Abandon Quest?", self.x + 20, self.y + 20, self.width - 40, "center")
            
            -- Draw dialog text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.printf(
                "Are you sure you want to abandon this quest?\n\nYou will lose 5 reputation with the quest giver,\nbut the quest will be available to take again.",
                self.x + 30, self.y + 60, self.width - 60, "center"
            )
        end
    }
    
    -- Create confirmation dialog buttons
    self.elements.confirmYesButton = screenManager.UI.Button(
        GAME.width/2 - 120, GAME.height/2 + 50,
        100, 35, "Yes", 
        function() self:confirmAbandon() end
    )
    self.elements.confirmYesButton.visible = false
    self.elements.confirmYesButton.colors = {
        normal = {0.8, 0.3, 0.3},
        hover = {0.9, 0.4, 0.4},
        press = {0.7, 0.2, 0.2}
    }
    
    self.elements.confirmNoButton = screenManager.UI.Button(
        GAME.width/2 + 20, GAME.height/2 + 50,
        100, 35, "No", 
        function() self:cancelAbandon() end
    )
    self.elements.confirmNoButton.visible = false
    self.elements.confirmNoButton.colors = {
        normal = {0.3, 0.6, 0.3},
        hover = {0.4, 0.7, 0.4},
        press = {0.2, 0.5, 0.2}
    }
    
    -- Set initial visibility state
    self:updateElementVisibility()
end

function questLog:updateElementVisibility()
    -- Update button highlighting based on selected category
    if self.category == "active" then
        -- Update active button appearance with stronger visual cue
        self.elements.activeButton.colors = {
            normal = {0.4, 0.4, 0.8},
            hover = {0.5, 0.5, 0.9},
            press = {0.3, 0.3, 0.7}
        }
        -- Draw a highlight border around the active button
        self.elements.activeButton.drawCustom = function(self)
            -- First draw a highlight border
            love.graphics.setColor(0.6, 0.6, 1, 0.8)
            love.graphics.rectangle("line", self.x - 2, self.y - 2, self.width + 4, self.height + 4, 6, 6)
            
            -- Then draw the normal button
            -- Draw button background based on state
            local bgColor = self.colors.normal
            if self.pressed then
                bgColor = self.colors.press
            elseif self.hover then
                bgColor = self.colors.hover
            end
            
            love.graphics.setColor(bgColor)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw button text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            local textX = self.x + (self.width - love.graphics.getFont():getWidth(self.text)) / 2
            local textY = self.y + (self.height - love.graphics.getFont():getHeight()) / 2
            love.graphics.print(self.text, textX, textY)
            
            -- Draw selection indicator
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("►", self.x - 15, self.y + 10)
        end
        
        -- Reset completed button appearance
        self.elements.completedButton.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
        self.elements.completedButton.drawCustom = nil
        
        -- Show abandon quest button only if a quest is selected
        self.elements.abandonQuestButton.visible = (self.selectedQuest ~= nil)
    else
        -- Update completed button appearance with stronger visual cue
        self.elements.completedButton.colors = {
            normal = {0.4, 0.4, 0.8},
            hover = {0.5, 0.5, 0.9},
            press = {0.3, 0.3, 0.7}
        }
        -- Draw a highlight border around the completed button
        self.elements.completedButton.drawCustom = function(self)
            -- First draw a highlight border
            love.graphics.setColor(0.6, 0.6, 1, 0.8)
            love.graphics.rectangle("line", self.x - 2, self.y - 2, self.width + 4, self.height + 4, 6, 6)
            
            -- Then draw the normal button
            -- Draw button background based on state
            local bgColor = self.colors.normal
            if self.pressed then
                bgColor = self.colors.press
            elseif self.hover then
                bgColor = self.colors.hover
            end
            
            love.graphics.setColor(bgColor)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw button text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            local textX = self.x + (self.width - love.graphics.getFont():getWidth(self.text)) / 2
            local textY = self.y + (self.height - love.graphics.getFont():getHeight()) / 2
            love.graphics.print(self.text, textX, textY)
            
            -- Draw selection indicator
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("►", self.x - 15, self.y + 10)
        end
        
        -- Reset active button appearance
        self.elements.activeButton.colors = {
            normal = {0.2, 0.2, 0.3},
            hover = {0.3, 0.3, 0.4},
            press = {0.1, 0.1, 0.2}
        }
        self.elements.activeButton.drawCustom = nil
        
        -- Hide abandon quest button when viewing completed quests
        self.elements.abandonQuestButton.visible = false
    end
    
    if GAME.debug then
        print("Quest Log UI visibility updated - Category: " .. self.category)
    end
end

function questLog:enter(params)
    -- Store from parameter for proper navigation back
    if params and params.from then
        self.fromState = params.from
    else
        self.fromState = nil
    end
    
    -- Reset state
    self.category = "active"
    self.selectedQuest = nil
    self.questScroll = 0
    self.selectedQuestIndex = 1
    self.showConfirmDialog = false
    
    -- Hide confirmation dialog elements
    if self.elements.confirmDialog then
        self.elements.confirmDialog.visible = false
        self.elements.confirmYesButton.visible = false
        self.elements.confirmNoButton.visible = false
    end
    
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
    
    -- Create an ordered table to control drawing order
    local drawOrder = {
        "categoryPanel",       -- Draw panels first
        "questListPanel",
        "questDetailsPanel",
        "activeButton",        -- Draw buttons on top of panels
        "completedButton",
        "abandonQuestButton",  -- Add abandon quest button
        "backToGameButton",
        "confirmDialog",       -- Draw confirmation dialog on top
        "confirmYesButton",
        "confirmNoButton"
    }
    
    -- Draw UI elements in specific order
    for _, elementName in ipairs(drawOrder) do
        local element = self.elements[elementName]
        if element and element.visible ~= false then
            if element.drawCustom then
                -- Use custom drawing if available
                element:drawCustom()
            else
                element:draw()
            end
        end
    end
    
    -- Draw any remaining elements not in the ordered list
    for name, element in pairs(self.elements) do
        -- Skip elements that were already drawn in the ordered list
        if not table.contains(drawOrder, name) and element.visible ~= false then
            if element.drawCustom then
                element:drawCustom()
            else
                element:draw()
            end
        end
    end
    
    -- Draw navigation help text
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7)
    
    if self.showConfirmDialog then
        -- Show dialog-specific controls
        love.graphics.print("Press Y to confirm abandon or N/ESC to cancel", 50, GAME.height - 60)
    else
        -- Show normal navigation controls
        love.graphics.print("Use W/S or arrow keys to navigate quests", 50, GAME.height - 60)
        love.graphics.print("Use A/D to switch categories", 50, GAME.height - 40)
        
        if self.category == "active" and self.selectedQuest then
            love.graphics.print("Press X to abandon selected quest", 50, GAME.height - 20)
        end
    end
end

-- Helper function to check if a table contains a value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
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
    for name, element in pairs(self.elements) do
        if element.released and element.visible ~= false then
            element:released(x, y, button)
        end
    end
    
    if GAME.debug then
        print("Quest Log mouse released at: " .. x .. "," .. y)
    end
end

function questLog:wheelmoved(x, y)
    -- Forward wheel movement to questListPanel
    if self.elements.questListPanel and self.elements.questListPanel.wheelmoved then
        return self.elements.questListPanel:wheelmoved(x, y)
    end
    
    return false
end

function questLog:keypressed(key, scancode, isrepeat)
    -- Handle confirmation dialog first
    if self.showConfirmDialog then
        if key == "y" or key == "return" then
            -- Confirm abandon
            self:confirmAbandon()
            return true
        elseif key == "n" or key == "escape" then
            -- Cancel abandon
            self:cancelAbandon()
            return true
        end
        -- Block other inputs while dialog is open
        return true
    end
    
    -- Get quests for current category
    local quests = {}
    if self.category == "active" then
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
    
    local questCount = #uniqueQuests
    
    -- Handle keyboard navigation
    if key == "w" or key == "up" then
        -- Move selection up
        self.selectedQuestIndex = math.max(1, self.selectedQuestIndex - 1)
        
        -- Adjust scroll if needed
        if self.selectedQuestIndex <= self.questScroll then
            self.questScroll = math.max(0, self.selectedQuestIndex - 1)
        end
        
        -- Update selected quest
        if questCount > 0 and self.selectedQuestIndex <= questCount then
            self:selectQuest(uniqueQuests[self.selectedQuestIndex])
        end
        
        -- Play sound
        assetManager:playSound("button_hover")
        return true
        
    elseif key == "s" or key == "down" then
        -- Move selection down
        self.selectedQuestIndex = math.min(questCount, self.selectedQuestIndex + 1)
        
        -- Adjust scroll if needed
        if self.selectedQuestIndex > self.questScroll + self.questsPerView then
            self.questScroll = self.selectedQuestIndex - self.questsPerView
        end
        
        -- Update selected quest
        if questCount > 0 and self.selectedQuestIndex <= questCount then
            self:selectQuest(uniqueQuests[self.selectedQuestIndex])
        end
        
        -- Play sound
        assetManager:playSound("button_hover")
        return true
        
    elseif key == "a" or key == "left" then
        -- Switch to active quests category
        if self.category ~= "active" then
            self:selectCategory("active")
            -- Play sound
            assetManager:playSound("click")
        end
        return true
        
    elseif key == "d" or key == "right" then
        -- Switch to completed quests category
        if self.category ~= "completed" then
            self:selectCategory("completed")
            -- Play sound
            assetManager:playSound("click")
        end
        return true
        
    elseif key == "x" then
        -- Quick abandon quest shortcut (only for active quests with selection)
        if self.category == "active" and self.selectedQuest then
            self:showAbandonConfirmation()
        end
        return true
        
    elseif key == "escape" then
        -- Return to game
        self:returnToGame()
        return true
    end
    
    return false
end

function questLog:selectCategory(category)
    -- Select category
    self.category = category
    
    -- Reset scroll and selection
    self.questScroll = 0
    self.selectedQuestIndex = 1
    self.selectedQuest = nil
    
    -- Update element visibility
    self:updateElementVisibility()
    
    -- Get quests based on selected category
    local quests = {}
    if self.category == "active" then
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
    
    -- Select first quest if available
    if #uniqueQuests > 0 then
        self:selectQuest(uniqueQuests[1])
    end
end

function questLog:selectQuest(quest)
    -- Select quest
    self.selectedQuest = quest
    
    -- Update element visibility when quest selection changes
    self:updateElementVisibility()
    
    if GAME.debug then
        print("Selected quest: " .. quest.name)
    end
end

function questLog:showAbandonConfirmation()
    if not self.selectedQuest then
        return
    end
    
    -- Show confirmation dialog
    self.showConfirmDialog = true
    self.elements.confirmDialog.visible = true
    self.elements.confirmYesButton.visible = true
    self.elements.confirmNoButton.visible = true
    
    -- Play sound
    assetManager:playSound("click")
end

function questLog:confirmAbandon()
    if not self.selectedQuest then
        return
    end
    
    -- Abandon the quest
    local abandonedQuest = questSystem:abandonQuest(self.selectedQuest.id)
    
    if abandonedQuest then
        -- Play success sound
        assetManager:playSound("pickup")
        
        -- Clear selection
        self.selectedQuest = nil
        
        -- Hide confirmation dialog
        self:cancelAbandon()
        
        -- Update element visibility
        self:updateElementVisibility()
        
        if GAME.debug then
            print("Quest abandoned: " .. abandonedQuest.name)
        end
    else
        -- Play error sound
        assetManager:playSound("hit")
    end
end

function questLog:cancelAbandon()
    -- Hide confirmation dialog
    self.showConfirmDialog = false
    self.elements.confirmDialog.visible = false
    self.elements.confirmYesButton.visible = false
    self.elements.confirmNoButton.visible = false
    
    -- Play sound
    assetManager:playSound("click")
end

function questLog:returnToGame()
    -- Use centralized helper function
    screenManager:returnToCurrentCity(self.fromState)
end

return questLog 