-- Inn Screen (LUIS)
-- Handles UI for inn mechanics including rest, food, and drinks
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local innSystem = require("gameplay/innSystem")
local reputationSystem = require("gameplay/reputationSystem")
local partyPanelLuis = require("ui_elements/partyPanelLuis")

-- Get LUIS instance
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

local inn = screenManager:createScreen("Inn")

function inn:init()
    -- Initialize inn system
    innSystem:init()
    
    -- Current selected sections and items
    self.currentSection = "main" -- main, rooms, food, drinks, event
    self.selectedRoomIndex = 1
    self.selectedFoodIndex = 1
    self.selectedDrinkIndex = 1
    self.currentEventId = nil
    self.currentEvent = nil
    self.eventResult = nil
    
    -- Load background image directly using love.graphics
    self.backgroundImage = love.graphics.newImage("assets/InnScreen.png")
    
    -- Create LUIS layers
    luis.newLayer("innLayer")
    luis.newLayer("confirmationLayer")
    
    -- Create UI elements
    self:createUI()
    
    -- Setup party panel
    self.partyPanel = partyPanelLuis:create()
    luis.insertElement("innLayer", self.partyPanel.container)
end

function inn:createUI()
    -- Main container (covers most of the screen)
    local mainContainer = luis.createElement("innLayer", "FlexContainer", 32, 16, 4, 2, nil, "InnMain")
    
    -- Navigation buttons (top section)
    local navContainer = luis.newFlexContainer(32, 3, 1, 1, nil, "Navigation")
    
    local mainButton = luis.newButton("Welcome", 6, 2, function() self:showSection("main") end, nil, 1, 1)
    local roomsButton = luis.newButton("Rooms", 6, 2, function() self:showSection("rooms") end, nil, 1, 1)
    local foodButton = luis.newButton("Food", 6, 2, function() self:showSection("food") end, nil, 1, 1)
    local drinksButton = luis.newButton("Drinks", 6, 2, function() self:showSection("drinks") end, nil, 1, 1)
    local backButton = luis.newButton("Leave Inn", 8, 2, function() self:leaveInn() end, nil, 1, 1)
    
    navContainer:addChild(mainButton)
    navContainer:addChild(roomsButton)
    navContainer:addChild(foodButton)
    navContainer:addChild(drinksButton)
    navContainer:addChild(backButton)
    
    mainContainer:addChild(navContainer)
    
    -- Content area container
    self.contentContainer = luis.newFlexContainer(32, 12, 1, 1, nil, "Content")
    mainContainer:addChild(self.contentContainer)
    
    -- Store navigation buttons for highlighting
    self.navigationButtons = {
        main = mainButton,
        rooms = roomsButton,
        food = foodButton,
        drinks = drinksButton,
        back = backButton
    }
    
    -- Create different section UIs
    self:createMainSectionUI()
    self:createRoomsSectionUI()
    self:createFoodSectionUI()
    self:createDrinksSectionUI()
    
    -- Create confirmation dialog
    self:createConfirmationDialog()
    
    -- Start with main section
    self:showSection("main")
end

function inn:createMainSectionUI()
    -- Main section container
    self.mainSectionContainer = luis.newFlexContainer(30, 10, 1, 1, nil, "MainSection")
    
    -- Welcome message
    local welcomeLabel = luis.newLabel("Welcome to the Adventurer's Inn!", 28, 2, 1, 1, "center")
    self.mainSectionContainer:addChild(welcomeLabel)
    
    local messageLabel = luis.newLabel("How may I serve you today? Rest well to recover your strength!", 28, 2, 1, 1, "center")
    self.mainSectionContainer:addChild(messageLabel)
    
    -- Character status display
    self.statusContainer = luis.newFlexContainer(28, 6, 1, 1, nil, "CharacterStatus")
    self.characterStatusLabel = luis.newLabel("Character status will appear here", 28, 6, 1, 1, "left")
    self.statusContainer:addChild(self.characterStatusLabel)
    self.mainSectionContainer:addChild(self.statusContainer)
    
    self.contentContainer:addChild(self.mainSectionContainer)
end

function inn:createRoomsSectionUI()
    -- Rooms section container
    self.roomsSectionContainer = luis.newFlexContainer(30, 10, 1, 1, nil, "RoomsSection")
    
    -- Section title
    local titleLabel = luis.newLabel("Choose a Room", 28, 2, 1, 1, "center")
    self.roomsSectionContainer:addChild(titleLabel)
    
    -- Rooms list container
    self.roomsListContainer = luis.newFlexContainer(28, 6, 1, 1, nil, "RoomsList")
    self.roomsSectionContainer:addChild(self.roomsListContainer)
    
    -- Action button
    self.rentRoomButton = luis.newButton("Rent Room", 8, 2, function() self:rentSelectedRoom() end, nil, 1, 1)
    self.roomsSectionContainer:addChild(self.rentRoomButton)
    
    self.contentContainer:addChild(self.roomsSectionContainer)
end

function inn:createFoodSectionUI()
    -- Food section container
    self.foodSectionContainer = luis.newFlexContainer(30, 10, 1, 1, nil, "FoodSection")
    
    -- Section title
    local titleLabel = luis.newLabel("Inn Menu - Food", 28, 2, 1, 1, "center")
    self.foodSectionContainer:addChild(titleLabel)
    
    -- Food list container
    self.foodListContainer = luis.newFlexContainer(28, 6, 1, 1, nil, "FoodList")
    self.foodSectionContainer:addChild(self.foodListContainer)
    
    -- Action button
    self.buyFoodButton = luis.newButton("Order Food", 8, 2, function() self:buySelectedFood() end, nil, 1, 1)
    self.foodSectionContainer:addChild(self.buyFoodButton)
    
    self.contentContainer:addChild(self.foodSectionContainer)
end

function inn:createDrinksSectionUI()
    -- Drinks section container
    self.drinksSectionContainer = luis.newFlexContainer(30, 10, 1, 1, nil, "DrinksSection")
    
    -- Section title
    local titleLabel = luis.newLabel("Inn Menu - Drinks", 28, 2, 1, 1, "center")
    self.drinksSectionContainer:addChild(titleLabel)
    
    -- Drinks list container
    self.drinksListContainer = luis.newFlexContainer(28, 6, 1, 1, nil, "DrinksList")
    self.drinksSectionContainer:addChild(self.drinksListContainer)
    
    -- Action button
    self.buyDrinkButton = luis.newButton("Order Drink", 8, 2, function() self:buySelectedDrink() end, nil, 1, 1)
    self.drinksSectionContainer:addChild(self.buyDrinkButton)
    
    self.contentContainer:addChild(self.drinksSectionContainer)
end

function inn:createConfirmationDialog()
    -- Confirmation dialog (centered modal)
    local confirmContainer = luis.createElement("confirmationLayer", "FlexContainer", 20, 8, 10, 7, nil, "ConfirmDialog")
    
    -- Title and message
    self.confirmTitleLabel = luis.newLabel("Confirm Action", 18, 2, 1, 1, "center")
    self.confirmMessageLabel = luis.newLabel("Are you sure?", 18, 3, 1, 1, "center")
    
    confirmContainer:addChild(self.confirmTitleLabel)
    confirmContainer:addChild(self.confirmMessageLabel)
    
    -- Action buttons
    local buttonContainer = luis.newFlexContainer(18, 2, 1, 1, nil, "ConfirmButtons")
    
    self.confirmYesButton = luis.newButton("Yes", 6, 2, function() self:confirmAction() end, nil, 1, 1)
    self.confirmNoButton = luis.newButton("No", 6, 2, function() self:cancelAction() end, nil, 1, 1)
    
    buttonContainer:addChild(self.confirmYesButton)
    buttonContainer:addChild(self.confirmNoButton)
    confirmContainer:addChild(buttonContainer)
    
    -- Start with confirmation layer disabled
    luis.disableLayer("confirmationLayer")
end

function inn:updatePanelVisibility()
    -- Hide all panels
    self.elements.mainPanel.visible = false
    self.elements.roomsPanel.visible = false
    self.elements.foodPanel.visible = false
    self.elements.drinksPanel.visible = false
    self.elements.eventPanel.visible = false
    
    -- Hide all section-specific buttons
    self.elements.roomsButton.visible = false
    self.elements.foodButton.visible = false
    self.elements.drinksButton.visible = false
    self.elements.backButton.visible = false
    self.elements.rentRoomButton.visible = false
    self.elements.buyFoodButton.visible = false
    self.elements.buyDrinkButton.visible = false
    
    -- Show appropriate panels and buttons based on current section
    if self.currentSection == "main" then
        self.elements.mainPanel.visible = true
        self.elements.roomsButton.visible = true
        self.elements.foodButton.visible = true
        self.elements.drinksButton.visible = true
        self.elements.backButton.visible = true
    elseif self.currentSection == "rooms" then
        self.elements.roomsPanel.visible = true
        self.elements.backButton.visible = true
        self.elements.rentRoomButton.visible = true
    elseif self.currentSection == "food" then
        self.elements.foodPanel.visible = true
        self.elements.backButton.visible = true
        self.elements.buyFoodButton.visible = true
    elseif self.currentSection == "drinks" then
        self.elements.drinksPanel.visible = true
        self.elements.backButton.visible = true
        self.elements.buyDrinkButton.visible = true
    elseif self.currentSection == "event" then
        self.elements.eventPanel.visible = true
    end
end

function inn:hasTavernMug()
    -- Check if character has tavern mug item
    if GAME.party and GAME.party[1] and GAME.party[1].inventory then
        for _, item in ipairs(GAME.party[1].inventory) do
            if item.id == "item_tavern_mug" then
                return true
            end
        end
    end
    
    return false
end

function inn:enter()
    -- Enable inn layer
    luis.enableLayer("innLayer")
    
    -- Reset current section and selections
    self.currentSection = "main"
    self.selectedRoomIndex = 1
    self.selectedFoodIndex = 1
    self.selectedDrinkIndex = 1
    self.currentEvent = nil
    self.eventResult = nil
    
    -- Ensure background image is loaded
    if not self.backgroundImage then
        self.backgroundImage = love.graphics.newImage("assets/InnScreen.png")
    end
    
    -- Update party panel with current party data
    if GAME and GAME.party then
        self.partyPanel:update(GAME.party, false) -- false = not in combat
    end
    
    -- Update panel visibility
    self:updatePanelVisibility()
    
    -- Play ambient sound
    assetManager:playMusic("town")
end

function inn:exit()
    -- Disable inn layer
    luis.disableLayer("innLayer")
    luis.disableLayer("confirmationLayer")
end

function inn:update(dt)
    -- Update party panel
    if self.partyPanel and GAME and GAME.party then
        self.partyPanel:update(GAME.party, false)
    end
end

function inn:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw inn background image
    if self.backgroundImage then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.backgroundImage, 0, 0)
    else
        -- Fallback color if image not available
        love.graphics.setColor(0.2, 0.15, 0.1)
        love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    end
    
    -- First draw main panel if visible (to ensure it's in the back)
    if self.elements.mainPanel and self.elements.mainPanel.visible then
        self.elements.mainPanel:draw()
    end
    
    -- Draw other panels
    if self.elements.roomsPanel and self.elements.roomsPanel.visible then
        self.elements.roomsPanel:draw()
    end
    
    if self.elements.foodPanel and self.elements.foodPanel.visible then
        self.elements.foodPanel:draw()
    end
    
    if self.elements.drinksPanel and self.elements.drinksPanel.visible then
        self.elements.drinksPanel:draw()
    end
    
    if self.elements.eventPanel and self.elements.eventPanel.visible then
        self.elements.eventPanel:draw()
    end
    
    -- Draw party panel if visible
    if self.elements.partyPanel and self.elements.partyPanel.visible then
        self.elements.partyPanel:draw()
    end
    
    -- Draw buttons last to ensure they're on top
    if self.elements.roomsButton and self.elements.roomsButton.visible then
        self.elements.roomsButton:draw()
    end
    
    if self.elements.foodButton and self.elements.foodButton.visible then
        self.elements.foodButton:draw()
    end
    
    if self.elements.drinksButton and self.elements.drinksButton.visible then
        self.elements.drinksButton:draw()
    end
    
    if self.elements.backButton and self.elements.backButton.visible then
        self.elements.backButton:draw()
    end
    
    if self.elements.rentRoomButton and self.elements.rentRoomButton.visible then
        self.elements.rentRoomButton:draw()
    end
    
    if self.elements.buyFoodButton and self.elements.buyFoodButton.visible then
        self.elements.buyFoodButton:draw()
    end
    
    if self.elements.buyDrinkButton and self.elements.buyDrinkButton.visible then
        self.elements.buyDrinkButton:draw()
    end
    
    -- Always draw popup message if visible (should be at the very top)
    self.elements.popupMessage:draw()
    
    -- Draw selection helper text if in a selection panel
    if self.currentSection == "rooms" or self.currentSection == "food" or self.currentSection == "drinks" then
        love.graphics.setColor(1, 1, 0.8, 0.8)
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.printf("Use W/S keys or click to select options", 
            GAME.width/2 - 200, GAME.height - 40, 400, "center")
    end
end

function inn:keypressed(key)
    if key == "escape" then
        if self.elements.popupMessage.visible then
            self.elements.popupMessage.visible = false
            return
        end
        
        if self.currentSection ~= "main" and self.currentSection ~= "event" then
            self.currentSection = "main"
            self:updatePanelVisibility()
        else
            -- Return to overworld
            local gameState = require("states/gameState")
            gameState:changeState("overworld")
        end
    elseif key == "w" or key == "s" then
        -- Handle option navigation with WASD keys
        if self.currentSection == "rooms" then
            local rooms = innSystem:getAvailableRoomTypes()
            if key == "w" then
                self.selectedRoomIndex = self.selectedRoomIndex > 1 and self.selectedRoomIndex - 1 or #rooms
            else -- s
                self.selectedRoomIndex = self.selectedRoomIndex < #rooms and self.selectedRoomIndex + 1 or 1
            end
            -- Play selection sound
            assetManager:playSound("hover", 0.3)
        elseif self.currentSection == "food" then
            local foods = innSystem.foodItems
            if key == "w" then
                self.selectedFoodIndex = self.selectedFoodIndex > 1 and self.selectedFoodIndex - 1 or #foods
            else -- s
                self.selectedFoodIndex = self.selectedFoodIndex < #foods and self.selectedFoodIndex + 1 or 1
            end
            -- Play selection sound
            assetManager:playSound("hover", 0.3)
        elseif self.currentSection == "drinks" then
            local drinks = innSystem.drinkItems
            if key == "w" then
                self.selectedDrinkIndex = self.selectedDrinkIndex > 1 and self.selectedDrinkIndex - 1 or #drinks
            else -- s
                self.selectedDrinkIndex = self.selectedDrinkIndex < #drinks and self.selectedDrinkIndex + 1 or 1
            end
            -- Play selection sound
            assetManager:playSound("hover", 0.3)
        end
    elseif key == "return" or key == "space" or key == "e" then
        -- Handle selection confirmation with Enter/Space/E
        if self.currentSection == "rooms" then
            self.elements.rentRoomButton:onClick()
        elseif self.currentSection == "food" then
            self.elements.buyFoodButton:onClick()
        elseif self.currentSection == "drinks" then
            self.elements.buyDrinkButton:onClick()
        end
    end
end

function inn:mousepressed(x, y, button)
    -- Check popup message first
    if self.elements.popupMessage.visible then
        if self.elements.popupMessage:clicked(x, y, button) then
            return
        end
    end
    
    -- Check panel clicks for selection
    if button == 1 then
        if self.currentSection == "rooms" and self.elements.roomsPanel.visible then
            local rooms = innSystem:getAvailableRoomTypes()
            for i, _ in ipairs(rooms) do
                local roomY = 130 + (i-1) * 90
                if x >= 150 and x <= GAME.width - 150 and
                   y >= roomY and y <= roomY + 80 then
                    -- Set selection
                    self.selectedRoomIndex = i
                    assetManager:playSound("click")
                    return
                end
            end
            
            -- Check if we clicked the purchase button
            if x >= GAME.width - 250 and x <= GAME.width - 100 and
               y >= GAME.height - 80 and y <= GAME.height - 40 then
                self.elements.rentRoomButton:onClick()
                return
            end
        elseif self.currentSection == "food" and self.elements.foodPanel.visible then
            local foods = innSystem.foodItems
            for i, _ in ipairs(foods) do
                local foodY = 130 + (i-1) * 90
                if x >= 150 and x <= GAME.width - 150 and
                   y >= foodY and y <= foodY + 80 then
                    -- Set selection
                    self.selectedFoodIndex = i
                    assetManager:playSound("click")
                    return
                end
            end
            
            -- Check if we clicked the purchase button
            if x >= GAME.width - 250 and x <= GAME.width - 100 and
               y >= GAME.height - 80 and y <= GAME.height - 40 then
                self.elements.buyFoodButton:onClick()
                return
            end
        elseif self.currentSection == "drinks" and self.elements.drinksPanel.visible then
            local drinks = innSystem.drinkItems
            for i, _ in ipairs(drinks) do
                local drinkY = 130 + (i-1) * 90
                if x >= 150 and x <= GAME.width - 150 and
                   y >= drinkY and y <= drinkY + 80 then
                    -- Set selection
                    self.selectedDrinkIndex = i
                    assetManager:playSound("click")
                    return
                end
            end
            
            -- Check if we clicked the purchase button
            if x >= GAME.width - 250 and x <= GAME.width - 100 and
               y >= GAME.height - 80 and y <= GAME.height - 40 then
                self.elements.buyDrinkButton:onClick()
                return
            end
        elseif self.currentSection == "event" and self.elements.eventPanel.visible then
            if self.elements.eventPanel:clicked(x, y, button) then
                return
            end
        end
    end
    
    -- Check buttons
    for _, element in pairs(self.elements) do
        if element.visible and element.clicked and element:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            return
        end
    end
end

function inn:mousereleased(x, y, button)
    for _, element in pairs(self.elements) do
        if element.visible and element.released then
            element:released(x, y, button)
        end
    end
end

return inn 