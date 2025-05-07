-- Inn Screen
-- Handles UI for inn mechanics including rest, food, and drinks
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local innSystem = require("gameplay/innSystem")
local reputationSystem = require("gameplay/reputationSystem")
local partyPanel = require("screens/ui_slices/partyPanel")

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
    
    -- Create UI elements
    self:createUI()
end

function inn:createUI()
    -- Main section elements
    self.elements.mainPanel = {
        visible = true,
        draw = function()
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 100, 50, GAME.width - 200, GAME.height - 200, 10, 10)
            
            -- Draw inn title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("The Adventurer's Inn", 100, 70, GAME.width - 200, "center")
            
            -- Draw innkeeper message
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 1)
            love.graphics.printf("Welcome to our humble establishment. How may I serve you today?", 150, 130, GAME.width - 300, "center")
            
            -- Draw character status
            if GAME.party and GAME.party[1] then
                local character = GAME.party[1]
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print("Name: " .. character.name, 150, 200)
                love.graphics.print("Level: " .. (character.jobLevels[character.job] or 1), 150, 225)
                love.graphics.print("Job: " .. character.job, 150, 250)
                
                -- Draw HP/MP
                love.graphics.print("HP: " .. character.currentHP .. "/" .. character.maxHP, 150, 275)
                love.graphics.print("MP: " .. character.currentMP .. "/" .. character.maxMP, 150, 300)
                
                -- Draw gold
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.print("Gold: " .. (GAME.gold or 0), 150, 335)
                
                -- Draw tavern reputation
                local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
                local repName = reputationSystem:getReputationLevelName(tavernRepLevel)
                love.graphics.setColor(0.8, 0.9, 1)
                love.graphics.print("Tavern Reputation: " .. repName, 150, 360)
            end
        end
    }
    
    -- Create room section panel
    self.elements.roomsPanel = {
        visible = false,
        draw = function()
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 100, 50, GAME.width - 200, GAME.height - 200, 10, 10)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("Inn Rooms", 100, 70, GAME.width - 200, "center")
            
            -- Draw room options
            local rooms = innSystem:getAvailableRoomTypes()
            
            for i, room in ipairs(rooms) do
                local y = 130 + (i-1) * 90
                
                -- Background for selection
                if i == self.selectedRoomIndex then
                    love.graphics.setColor(0.3, 0.3, 0.4, 0.7)
                    love.graphics.rectangle("fill", 150, y, GAME.width - 300, 80, 5, 5)
                end
                
                -- Room name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(room.name, 170, y + 10)
                
                -- Room cost
                love.graphics.setFont(screenManager.fonts.small)
                if room.discounted then
                    love.graphics.setColor(0.2, 1, 0.2)
                    love.graphics.print("Cost: " .. room.cost .. " gold (discounted)", 170, y + 40)
                else
                    love.graphics.setColor(1, 0.8, 0.2)
                    love.graphics.print("Cost: " .. room.cost .. " gold", 170, y + 40)
                end
                
                -- Room description
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.printf(room.description, 350, y + 10, GAME.width - 500, "left")
                
                -- Recovery values
                love.graphics.setColor(0.7, 0.9, 0.7)
                local recoveryText = "Recovery: "
                if room.hpRecovery > 0 then
                    recoveryText = recoveryText .. math.floor(room.hpRecovery * 100) .. "% HP, "
                end
                if room.mpRecovery > 0 then
                    recoveryText = recoveryText .. math.floor(room.mpRecovery * 100) .. "% MP"
                end
                love.graphics.print(recoveryText, 350, y + 40)
                
                -- Status effect removal
                if room.statusEffectRemoval then
                    love.graphics.setColor(0.7, 0.7, 1)
                    love.graphics.print("Removes status effects", 550, y + 40)
                end
            end
        end,
        
        clicked = function(x, y, button)
            if button == 1 then
                -- Check if clicking on a room
                local rooms = innSystem:getAvailableRoomTypes()
                
                for i, _ in ipairs(rooms) do
                    local roomY = 130 + (i-1) * 90
                    
                    if x >= 150 and x <= GAME.width - 150 and
                       y >= roomY and y <= roomY + 80 then
                        self.selectedRoomIndex = i
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Create food section panel
    self.elements.foodPanel = {
        visible = false,
        draw = function()
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 100, 50, GAME.width - 200, GAME.height - 200, 10, 10)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("Inn Food", 100, 70, GAME.width - 200, "center")
            
            -- Draw food options
            local foods = innSystem.foodItems
            
            for i, food in ipairs(foods) do
                local y = 130 + (i-1) * 90
                
                -- Background for selection
                if i == self.selectedFoodIndex then
                    love.graphics.setColor(0.3, 0.3, 0.4, 0.7)
                    love.graphics.rectangle("fill", 150, y, GAME.width - 300, 80, 5, 5)
                end
                
                -- Food name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(food.name, 170, y + 10)
                
                -- Food cost
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 0.8, 0.2)
                
                -- Apply discount
                local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
                local cost = food.cost
                
                if tavernRepLevel >= reputationSystem.levels.FRIENDLY then
                    cost = math.floor(cost * 0.9)
                    love.graphics.setColor(0.2, 1, 0.2)
                    love.graphics.print("Cost: " .. cost .. " gold (discounted)", 170, y + 40)
                else
                    love.graphics.print("Cost: " .. cost .. " gold", 170, y + 40)
                end
                
                -- Food description
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.printf(food.description, 350, y + 10, GAME.width - 500, "left")
                
                -- Effects
                love.graphics.setColor(0.7, 0.9, 0.7)
                local effectsText = "Effects: "
                
                for j, effect in ipairs(food.effects) do
                    if effect.type == "heal" then
                        effectsText = effectsText .. "Heal " .. effect.amount .. " HP"
                    elseif effect.type == "buff" then
                        effectsText = effectsText .. "+" .. effect.amount .. " " .. effect.stat .. " for " .. 
                                     math.floor(effect.duration / 60) .. " min"
                    end
                    
                    if j < #food.effects then
                        effectsText = effectsText .. ", "
                    end
                end
                
                love.graphics.print(effectsText, 350, y + 40)
            end
        end,
        
        clicked = function(x, y, button)
            if button == 1 then
                -- Check if clicking on a food item
                local foods = innSystem.foodItems
                
                for i, _ in ipairs(foods) do
                    local foodY = 130 + (i-1) * 90
                    
                    if x >= 150 and x <= GAME.width - 150 and
                       y >= foodY and y <= foodY + 80 then
                        self.selectedFoodIndex = i
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Create drinks section panel
    self.elements.drinksPanel = {
        visible = false,
        draw = function()
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 100, 50, GAME.width - 200, GAME.height - 200, 10, 10)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("Inn Drinks", 100, 70, GAME.width - 200, "center")
            
            -- Draw drink options
            local drinks = innSystem.drinkItems
            
            for i, drink in ipairs(drinks) do
                local y = 130 + (i-1) * 90
                
                -- Background for selection
                if i == self.selectedDrinkIndex then
                    love.graphics.setColor(0.3, 0.3, 0.4, 0.7)
                    love.graphics.rectangle("fill", 150, y, GAME.width - 300, 80, 5, 5)
                end
                
                -- Drink name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(drink.name, 170, y + 10)
                
                -- Drink cost
                love.graphics.setFont(screenManager.fonts.small)
                
                -- Apply discount
                local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
                local cost = drink.cost
                
                if tavernRepLevel >= reputationSystem.levels.FRIENDLY then
                    cost = math.floor(cost * 0.9)
                    love.graphics.setColor(0.2, 1, 0.2)
                    love.graphics.print("Cost: " .. cost .. " gold (discounted)", 170, y + 40)
                else
                    love.graphics.setColor(1, 0.8, 0.2)
                    love.graphics.print("Cost: " .. cost .. " gold", 170, y + 40)
                end
                
                -- Drink description
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.printf(drink.description, 350, y + 10, GAME.width - 500, "left")
                
                -- Effects
                love.graphics.setColor(0.7, 0.9, 0.7)
                local effectsText = "Effects: "
                
                for j, effect in ipairs(drink.effects) do
                    if effect.type == "restore_mp" then
                        effectsText = effectsText .. "Restore " .. effect.amount .. " MP"
                    elseif effect.type == "buff" then
                        effectsText = effectsText .. "+" .. effect.amount .. " " .. effect.stat .. " for " .. 
                                     math.floor(effect.duration / 60) .. " min"
                    end
                    
                    if j < #drink.effects then
                        effectsText = effectsText .. ", "
                    end
                end
                
                love.graphics.print(effectsText, 350, y + 40)
                
                -- Special note for tavern mug owners
                if self:hasTavernMug() then
                    love.graphics.setColor(1, 0.7, 0.3)
                    love.graphics.print("* Enhanced with Tavern Mug", 600, y + 40)
                end
            end
        end,
        
        clicked = function(x, y, button)
            if button == 1 then
                -- Check if clicking on a drink item
                local drinks = innSystem.drinkItems
                
                for i, _ in ipairs(drinks) do
                    local drinkY = 130 + (i-1) * 90
                    
                    if x >= 150 and x <= GAME.width - 150 and
                       y >= drinkY and y <= drinkY + 80 then
                        self.selectedDrinkIndex = i
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Create event panel
    self.elements.eventPanel = {
        visible = false,
        draw = function()
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.25, 0.9)
            love.graphics.rectangle("fill", 100, 100, GAME.width - 200, GAME.height - 200, 10, 10)
            
            if self.currentEvent then
                -- Draw event title
                love.graphics.setFont(screenManager.fonts.large)
                love.graphics.setColor(1, 0.5, 0.3)
                love.graphics.printf(self.currentEvent.name, 100, 120, GAME.width - 200, "center")
                
                -- Draw event description
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0.9)
                love.graphics.printf(self.currentEvent.description, 150, 180, GAME.width - 300, "center")
                
                -- Draw choices
                if not self.eventResult then
                    love.graphics.setFont(screenManager.fonts.medium)
                    
                    for i, choice in ipairs(self.currentEvent.choices) do
                        local y = 300 + (i-1) * 70
                        
                        -- Background for button
                        love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
                        love.graphics.rectangle("fill", GAME.width/2 - 200, y, 400, 50, 5, 5)
                        
                        -- Border
                        love.graphics.setColor(0.5, 0.5, 0.7)
                        love.graphics.rectangle("line", GAME.width/2 - 200, y, 400, 50, 5, 5)
                        
                        -- Choice text
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.printf(choice.text, GAME.width/2 - 190, y + 15, 380, "center")
                    end
                else
                    -- Draw event result
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(0.9, 1, 0.9)
                    love.graphics.printf(self.eventResult, 150, 300, GAME.width - 300, "center")
                    
                    -- "Continue" button
                    love.graphics.setColor(0.3, 0.5, 0.3, 0.8)
                    love.graphics.rectangle("fill", GAME.width/2 - 100, 400, 200, 50, 5, 5)
                    
                    -- Border
                    love.graphics.setColor(0.5, 0.7, 0.5)
                    love.graphics.rectangle("line", GAME.width/2 - 100, 400, 200, 50, 5, 5)
                    
                    -- Button text
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf("Continue", GAME.width/2 - 90, 415, 180, "center")
                end
            end
        end,
        
        clicked = function(x, y, button)
            if button == 1 and self.currentEvent then
                if not self.eventResult then
                    -- Check for choice selection
                    for i, _ in ipairs(self.currentEvent.choices) do
                        local choiceY = 300 + (i-1) * 70
                        
                        if x >= GAME.width/2 - 200 and x <= GAME.width/2 + 200 and
                           y >= choiceY and y <= choiceY + 50 then
                            
                            -- Handle event choice
                            local success, result = innSystem:handleEventOutcome(
                                self.currentEvent.id, 
                                i, 
                                GAME.party[1]
                            )
                            
                            if success then
                                self.eventResult = result
                                return true
                            end
                        end
                    end
                else
                    -- Check for continue button
                    if x >= GAME.width/2 - 100 and x <= GAME.width/2 + 100 and
                       y >= 400 and y <= 450 then
                        
                        -- Return to main screen
                        self.currentSection = "main"
                        self:updatePanelVisibility()
                        self.currentEvent = nil
                        self.eventResult = nil
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Create main menu buttons
    local buttonWidth = 180
    local buttonHeight = 50
    local buttonX = GAME.width/2 - buttonWidth/2
    local baseY = GAME.height - 250
    local buttonSpacing = 60
    
    -- Rooms button
    self.elements.roomsButton = screenManager.UI.Button(
        buttonX - buttonWidth - 20, baseY + buttonSpacing,
        buttonWidth, buttonHeight,
        "Rest Rooms",
        function()
            self.currentSection = "rooms"
            self:updatePanelVisibility()
        end
    )
    
    -- Food button
    self.elements.foodButton = screenManager.UI.Button(
        buttonX, baseY + buttonSpacing,
        buttonWidth, buttonHeight,
        "Order Food",
        function()
            self.currentSection = "food"
            self:updatePanelVisibility()
        end
    )
    
    -- Drinks button
    self.elements.drinksButton = screenManager.UI.Button(
        buttonX + buttonWidth + 20, baseY + buttonSpacing,
        buttonWidth, buttonHeight,
        "Order Drinks",
        function()
            self.currentSection = "drinks"
            self:updatePanelVisibility()
        end
    )
    
    -- Section-specific buttons
    
    -- Back button (common to most sections)
    self.elements.backButton = screenManager.UI.Button(
        100, GAME.height - 190,
        150, 40,
        "Back",
        function()
            if self.currentSection ~= "main" and self.currentSection ~= "event" then
                self.currentSection = "main"
                self:updatePanelVisibility()
            else
                -- Return to overworld
                local gameState = require("states/gameState")
                gameState:changeState("overworld")
            end
        end
    )
    
    -- Rent room button
    self.elements.rentRoomButton = screenManager.UI.Button(
        GAME.width - 250, GAME.height - 190,
        150, 40,
        "Rent Room",
        function()
            local rooms = innSystem:getAvailableRoomTypes()
            if self.selectedRoomIndex <= #rooms then
                local selectedRoom = rooms[self.selectedRoomIndex]
                
                if selectedRoom then
                    local success, message, event = innSystem:rest(GAME.party[1], selectedRoom.id)
                    
                    if success then
                        -- Show message
                        if event then
                            -- Show event panel
                            self.currentEvent = event
                            self.currentSection = "event"
                            self:updatePanelVisibility()
                        else
                            -- Show rest success message
                            self.elements.popupMessage:show(message)
                        end
                    else
                        -- Show error message
                        self.elements.popupMessage:show(message)
                    end
                end
            end
        end
    )
    -- Add onClick method to support keyboard selection
    self.elements.rentRoomButton.onClick = self.elements.rentRoomButton.callback
    
    -- Buy food button
    self.elements.buyFoodButton = screenManager.UI.Button(
        GAME.width - 250, GAME.height - 190,
        150, 40,
        "Buy Food",
        function()
            local foods = innSystem.foodItems
            if self.selectedFoodIndex <= #foods then
                local selectedFood = foods[self.selectedFoodIndex]
                
                if selectedFood then
                    local success, message = innSystem:purchaseFood(selectedFood.id, GAME.party[1])
                    
                    -- Show result message
                    self.elements.popupMessage:show(message)
                end
            end
        end
    )
    -- Add onClick method to support keyboard selection
    self.elements.buyFoodButton.onClick = self.elements.buyFoodButton.callback
    
    -- Buy drink button
    self.elements.buyDrinkButton = screenManager.UI.Button(
        GAME.width - 250, GAME.height - 190,
        150, 40,
        "Buy Drink",
        function()
            local drinks = innSystem.drinkItems
            if self.selectedDrinkIndex <= #drinks then
                local selectedDrink = drinks[self.selectedDrinkIndex]
                
                if selectedDrink then
                    local success, message = innSystem:purchaseDrink(selectedDrink.id, GAME.party[1])
                    
                    -- Show result message
                    self.elements.popupMessage:show(message)
                end
            end
        end
    )
    -- Add onClick method to support keyboard selection
    self.elements.buyDrinkButton.onClick = self.elements.buyDrinkButton.callback
    
    -- Popup message element
    self.elements.popupMessage = {
        visible = false,
        message = "",
        x = GAME.width / 2 - 200,
        y = GAME.height / 2 - 100,
        width = 400,
        height = 200,
        okButton = nil,
        
        init = function(self)
            self.okButton = screenManager.UI.Button(
                self.x + self.width/2 - 50, self.y + self.height - 60, 
                100, 40, "OK", function() self.visible = false end
            )
        end,
        
        show = function(self, message)
            if not self.okButton then self:init() end
            self.message = message
            self.visible = true
        end,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw panel background
            love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw border
            love.graphics.setColor(0.5, 0.5, 0.7)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw message
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(self.message, self.x + 20, self.y + 40, self.width - 40, "center")
            
            -- Draw OK button
            self.okButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            if self.okButton:clicked(x, y, button) then
                return true
            end
            
            return false
        end
    }
    
    -- Initialize popup message
    self.elements.popupMessage:init()
    
    -- Update panel visibility
    self:updatePanelVisibility()

    -- Initialize party panel
    self.elements.partyPanel = partyPanel
    self.elements.partyPanel.visible = true

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
    -- Reset current section and selections
    self.currentSection = "main"
    self.selectedRoomIndex = 1
    self.selectedFoodIndex = 1
    self.selectedDrinkIndex = 1
    self.currentEvent = nil
    self.eventResult = nil
    
    -- Update panel visibility
    self:updatePanelVisibility()
    
    -- Play ambient sound
    assetManager:playMusic("town")
end

function inn:exit()
    -- The music will be stopped by the next screen's playMusic call
    -- No need to explicitly stop it
end

function inn:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    if assetManager.images.backgrounds and assetManager.images.backgrounds.inn then
        love.graphics.draw(assetManager.images.backgrounds.inn, 0, 0, 0, 
            GAME.width / assetManager.images.backgrounds.inn:getWidth(),
            GAME.height / assetManager.images.backgrounds.inn:getHeight())
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