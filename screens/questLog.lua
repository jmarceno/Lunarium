-- Quest Log Screen (LUIS)
-- Where players can view their active and completed quests
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local questSystem = require("gameplay/questSystem")

-- Get LUIS instance
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

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
    self.showConfirmDialog = false
    
    -- Create LUIS layers
    luis.newLayer("questLogLayer")
    luis.newLayer("confirmDialogLayer")
    
    -- Create UI elements
    self:createUI()
end

function questLog:createUI()
    -- Main container (40x22 grid)
    local mainContainer = luis.createElement("questLogLayer", "FlexContainer", 36, 18, 2, 2, nil, "QuestLogMain")
    
    -- Left sidebar for categories
    local categoryContainer = luis.newFlexContainer(8, 16, 1, 1, nil, "Categories")
    
    -- Category title
    local categoryTitle = luis.newLabel("Categories", 8, 2, 1, 1, "center")
    categoryContainer:addChild(categoryTitle)
    
    -- Category buttons
    self.activeQuestsButton = luis.newButton("Active", 7, 2, function() self:selectCategory("active") end, nil, 1, 1)
    self.completedQuestsButton = luis.newButton("Completed", 7, 2, function() self:selectCategory("completed") end, nil, 1, 1)
    
    categoryContainer:addChild(self.activeQuestsButton)
    categoryContainer:addChild(self.completedQuestsButton)
    
    mainContainer:addChild(categoryContainer)
    
    -- Middle section for quest list
    local questListContainer = luis.newFlexContainer(12, 16, 1, 1, nil, "QuestList")
    
    -- Quest list title
    self.questListTitle = luis.newLabel("Active Quests", 12, 2, 1, 1, "center")
    questListContainer:addChild(self.questListTitle)
    
    -- Quest items container (scrollable area)
    self.questItemsContainer = luis.newFlexContainer(12, 12, 1, 1, nil, "QuestItems")
    questListContainer:addChild(self.questItemsContainer)
    
    -- Navigation buttons
    local navContainer = luis.newFlexContainer(12, 2, 1, 1, nil, "QuestNavigation")
    
    self.abandonQuestButton = luis.newButton("Abandon", 5, 2, function() self:abandonSelectedQuest() end, nil, 1, 1)
    navContainer:addChild(self.abandonQuestButton)
    
    questListContainer:addChild(navContainer)
    mainContainer:addChild(questListContainer)
    
    -- Right section for quest details
    local detailsContainer = luis.newFlexContainer(16, 16, 1, 1, nil, "QuestDetails")
    
    -- Details title
    self.detailsTitle = luis.newLabel("Quest Details", 16, 2, 1, 1, "center")
    detailsContainer:addChild(self.detailsTitle)
    
    -- Quest details content
    self.questDetailsLabel = luis.newLabel("Select a quest to view details", 16, 12, 1, 1, "left")
    detailsContainer:addChild(self.questDetailsLabel)
    
    -- Back button
    local backButton = luis.newButton("Back", 6, 2, function() self:goBack() end, nil, 1, 1)
    detailsContainer:addChild(backButton)
    
    mainContainer:addChild(detailsContainer)
    
    -- Store references
    self.uiElements = {
        mainContainer = mainContainer,
        categoryContainer = categoryContainer,
        questListContainer = questListContainer,
        detailsContainer = detailsContainer,
        activeQuestsButton = self.activeQuestsButton,
        completedQuestsButton = self.completedQuestsButton,
        questListTitle = self.questListTitle,
        questItemsContainer = self.questItemsContainer,
        abandonQuestButton = self.abandonQuestButton,
        detailsTitle = self.detailsTitle,
        questDetailsLabel = self.questDetailsLabel,
        backButton = backButton
    }
    
    -- Create confirmation dialog
    self:createConfirmationDialog()
    
    -- Initial setup
    self:selectCategory("active")
end

function questLog:createConfirmationDialog()
    -- Confirmation dialog (centered modal)
    local confirmContainer = luis.createElement("confirmDialogLayer", "FlexContainer", 20, 8, 10, 7, nil, "ConfirmDialog")
    
    -- Title and message
    self.confirmTitleLabel = luis.newLabel("Confirm Action", 18, 2, 1, 1, "center")
    self.confirmMessageLabel = luis.newLabel("Are you sure you want to abandon this quest?", 18, 3, 1, 1, "center")
    
    confirmContainer:addChild(self.confirmTitleLabel)
    confirmContainer:addChild(self.confirmMessageLabel)
    
    -- Action buttons
    local buttonContainer = luis.newFlexContainer(18, 2, 1, 1, nil, "ConfirmButtons")
    
    self.confirmYesButton = luis.newButton("Yes", 6, 2, function() self:confirmAbandonQuest() end, nil, 1, 1)
    self.confirmNoButton = luis.newButton("No", 6, 2, function() self:cancelAbandonQuest() end, nil, 1, 1)
    
    buttonContainer:addChild(self.confirmYesButton)
    buttonContainer:addChild(self.confirmNoButton)
    confirmContainer:addChild(buttonContainer)
    
    -- Start with confirmation layer disabled
    luis.disableLayer("confirmDialogLayer")
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

function questLog:enter()
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
    -- Return to game
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

return questLog 