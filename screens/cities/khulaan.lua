-- Khulaan City Screen
-- The main navigation hub for Khulaan city locations
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")
local partyPanel = require("screens/ui_slices/partyPanel")

local khulaan = screenManager:createScreen("Khulaan")

function khulaan:init()
    -- Background image will be loaded in enter() function when city data is available
    self.townMapImage = nil
    
    -- Track if hover sound has been played to avoid repetition
    self.hoverSoundPlayed = false
    
    -- Initialize locations
    self.locations = {
        {
            name = "Tavern",
            description = "Visit the tavern to find quests, rumors and refreshment.",
            x = 563,
            y = 440,
            width = 120,
            height = 100,
            state = "tavern"
        },
        {
            name = "Guild",
            description = "The adventurers' guild offers official quests and services.",
            x = 309,
            y = 304,
            width = 120,
            height = 100,
            state = "guild"
        },
        {
            name = "Shop",
            description = "Purchase equipment, items and supplies.",
            x = 906,
            y = 237,
            width = 120,
            height = 100,
            state = "shop"
        },
        {
            name = "Smith",
            description = "Craft weapons and armor from monster parts.",
            x = 253,
            y = 474,
            width = 120,
            height = 100,
            state = "smith"
        },
        {
            name = "Dungeon",
            description = "Enter the dungeon to complete quests and find treasure.",
            x = 10,
            y = 103,
            width = 120,
            height = 100,
            state = "dungeon"
        },
        {
            name = "Inn",
            description = "Rest, recover, and enjoy special services at the adventurer's inn.",
            x = 411,
            y = 139,
            width = 120,
            height = 100,
            state = "inn"
        }
    }
    
    -- Initialize hover state
    self.hoverLocation = nil
    
    -- City data will be set when entering the screen
    self.cityData = nil
    
    -- Popup message element
    self.elements.popupMessage = {
        visible = false,
        message = "",
        title = "Notice",
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
            self.okButton.hovered = false
        end,
        
        show = function(self, message, title)
            if not self.okButton then self:init() end
            self.message = message
            if title then self.title = title end
            self.visible = true
        end,
        
        update = function(self, dt)
            if not self.visible then return end
            if self.okButton and self.okButton.update then
                self.okButton:update(dt)
            end
        end,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw panel background with fancy styling
            love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 12, 12)
            
            -- Draw fancy border
            love.graphics.setColor(0.8, 0.7, 0.4, 0.9)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 12, 12)
            love.graphics.rectangle("line", self.x+2, self.y+2, self.width-4, self.height-4, 10, 10)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 0.9, 0.6)
            local titleWidth = screenManager.fonts.medium:getWidth(self.title)
            love.graphics.print(
                self.title,
                self.x + (self.width - titleWidth) / 2,
                self.y + 20
            )
            
            -- Draw message text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.printf(self.message, self.x + 30, self.y + 50, self.width - 60, "center")
            
            -- Draw OK button
            self.okButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            if self.okButton:clicked(x, y, button) then return true end
            -- Consume clicks inside the panel even if not on button
            if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
               return true
            end
            return false
        end
    }
    
    -- Create UI elements
    self:createUI()
end

function khulaan:createUI()
    -- Create menu button
    self.elements.menuButton = screenManager.UI.Button(
        GAME.width - 170, 20, 150, 40, "Menu", 
        function() self:showMenu() end
    )
    self.elements.menuButton.visible = true
    self.elements.menuButton.hovered = false
    
    -- Create save button
    self.elements.saveButton = screenManager.UI.Button(
        GAME.width - 170, 70, 150, 40, "Save Game", 
        function() self:saveGame() end
    )
    self.elements.saveButton.visible = true
    self.elements.saveButton.hovered = false
    
    -- Create inventory button
    self.elements.inventoryButton = screenManager.UI.Button(
        GAME.width - 170, 120, 150, 40, "Inventory (I)", 
        function() self:openInventory() end
    )
    self.elements.inventoryButton.visible = true
    self.elements.inventoryButton.hovered = false
    
    -- Create character info button
    self.elements.characterInfoButton = screenManager.UI.Button(
        GAME.width - 170, 170, 150, 40, "Party Info", 
        function() 
            local gameState = require("states/gameState")
            gameState:changeState("characterInfo", { from = "khulaan" })
        end
    )
    self.elements.characterInfoButton.visible = true
    self.elements.characterInfoButton.hovered = false
    
    -- Create quest log button
    self.elements.questLogButton = screenManager.UI.Button(
        GAME.width - 170, 220, 150, 40, "Quest Log", 
        function() 
            local gameState = require("states/gameState")
            gameState:changeState("questLog", { from = "khulaan" })
        end
    )
    self.elements.questLogButton.visible = true
    self.elements.questLogButton.hovered = false
    
    -- Create world map button
    self.elements.worldMapButton = screenManager.UI.Button(
        GAME.width - 170, 270, 150, 40, "World Map", 
        function() 
            local gameState = require("states/gameState")
            gameState:changeState("overworld")
        end
    )
    self.elements.worldMapButton.visible = true
    self.elements.worldMapButton.hovered = false
    
    -- Create menu panel
    self.elements.menuPanel = {
        visible = false,
        x = GAME.width / 2 - 200,
        y = GAME.height / 2 - 150,
        width = 400,
        height = 300,
        buttons = {
            {
                text = "Settings",
                x = GAME.width / 2 - 100,
                y = GAME.height / 2 - 100,
                width = 200,
                height = 40,
                action = function() print("Settings not implemented yet") end
            },
            {
                text = "Main Menu",
                x = GAME.width / 2 - 100,
                y = GAME.height / 2 - 50,
                width = 200,
                height = 40,
                action = function() 
                    local gameState = require("states/gameState")
                    gameState:changeState("mainMenu")
                end
            },
            {
                text = "Close",
                x = GAME.width / 2 - 100,
                y = GAME.height / 2,
                width = 200,
                height = 40,
                action = function() self.elements.menuPanel.visible = false end
            }
        },
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw panel background
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Menu", self.x + 20, self.y + 20)
            
            -- Draw buttons
            for _, button in ipairs(self.buttons) do
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(button.text, button.x, button.y + 10, button.width, "center")
            end
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            for _, btn in ipairs(self.buttons) do
                if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                    btn.action()
                    return true
                end
            end
            
            -- Consume click inside panel
            if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
                return true
            end
            
            return false
        end
    }
    
    -- Initialize party panel
    self.elements.partyPanel = partyPanel
end

function khulaan:enter(params)
    -- Start playing town music
    assetManager:playMusic("town")
    
    -- Receive city data from params
    if params and params.cityData then
        self.cityData = params.cityData
        GAME.lastCity = self.cityData.name
        GAME.currentCityData = self.cityData
    else
        -- Fallback to loading from cities definitions
        local cities_definitions = require("data/cities_definitions")
        for _, city in ipairs(cities_definitions) do
            if city.name == "Khulaan - Heart of the Endless Steppe" then
                self.cityData = city
                GAME.lastCity = "Khulaan - Heart of the Endless Steppe"
                GAME.currentCityData = city
                break
            end
        end
    end
    
    -- Load city-specific background image
    if self.cityData and self.cityData.image then
        self.townMapImage = love.graphics.newImage(self.cityData.image)
    else
        error("City data or image path not found for Khulaan")
    end
    
    -- Check for completed quest notification
    if params and params.completedQuest then
        self.elements.popupMessage:show("Quest completed: " .. params.completedQuest.name, "Quest Complete!")
    end
end

function khulaan:update(dt)
    -- Get current mouse position and convert to game coordinates
    local rawMx, rawMy = love.mouse.getPosition()
    local scaling = require("utils/scaling")
    local mx, my = scaling:toGameCoords(rawMx, rawMy)
    
    -- Update UI elements
    for _, element in pairs(self.elements) do
        if element.update then
            element:update(dt)
        end
        
        -- Check for button hover (buttons have x, y, width, height, and clicked method)
        if element.clicked and element.visible ~= false and
           element.x and element.y and element.width and element.height then
            -- Check if mouse is over this button
            local isHovered = mx >= element.x and mx <= element.x + element.width and
                              my >= element.y and my <= element.y + element.height
                              
            -- Play sound when first hovering over a button
            if isHovered and not element.hovered then
                assetManager:playSound("button_hover")
                element.hovered = true
            elseif not isHovered and element.hovered then
                element.hovered = false
            end
        end
    end
    
    -- Update hover state
    local previousHoverLocation = self.hoverLocation
    self.hoverLocation = nil
    
    for _, location in ipairs(self.locations) do
        if mx >= location.x and mx <= location.x + location.width and
           my >= location.y and my <= location.y + location.height then
            self.hoverLocation = location
            break
        end
    end
    
    -- Play hover sound when hovering over a new location
    if self.hoverLocation ~= previousHoverLocation then
        if self.hoverLocation and not self.hoverSoundPlayed then
            assetManager:playSound("button_hover")
            self.hoverSoundPlayed = true
        elseif not self.hoverLocation then
            self.hoverSoundPlayed = false
        end
    end
end

function khulaan:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw town map - scale to fit screen while maintaining aspect ratio
    love.graphics.setColor(1, 1, 1)
    if self.townMapImage then
        local imageWidth, imageHeight = self.townMapImage:getDimensions()
        local scaleX = GAME.width / imageWidth
        local scaleY = GAME.height / imageHeight
        local scale = math.min(scaleX, scaleY) -- Use smaller scale to maintain aspect ratio
        
        local scaledWidth = imageWidth * scale
        local scaledHeight = imageHeight * scale
        local x = (GAME.width - scaledWidth) / 2
        local y = (GAME.height - scaledHeight) / 2
        
        love.graphics.draw(self.townMapImage, x, y, 0, scale, scale)
    end
    
    -- Draw locations
    for _, location in ipairs(self.locations) do
        -- Determine color based on hover state
        if location == self.hoverLocation then
            love.graphics.setColor(1, 1, 1, 0.3)  -- White highlight when hovering, but subtle
        else
            love.graphics.setColor(0.8, 0.8, 1, 0.3)  -- Very subtle indicator when not hovering
        end
        
        -- Draw location hit area
        love.graphics.rectangle(
            "fill", 
            location.x, location.y, 
            location.width, location.height,
            10, 10
        )
        
        -- Draw border when hovering
        if location == self.hoverLocation then
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.rectangle(
                "line", 
                location.x, location.y, 
                location.width, location.height,
                10, 10
            )
        end
        
        -- Always draw location name with different opacity based on hover state
        love.graphics.setFont(screenManager.fonts.medium)
        if location == self.hoverLocation then
            love.graphics.setColor(0, 0, 0, 0.9)  -- Opaque when hovering
        else
            love.graphics.setColor(0, 0, 0, 0.6)  -- Semi-transparent when not hovering
        end
        
        local nameWidth = screenManager.fonts.medium:getWidth(location.name)
        love.graphics.print(
            location.name,
            location.x + (location.width - nameWidth) / 2,
            location.y + location.height / 2 - 10
        )
    end
    
    -- Draw hover info
    if self.hoverLocation then
        -- Draw info box
        local infoWidth = 300
        local infoHeight = 100
        local infoX = GAME.width / 2 - infoWidth / 2
        local infoY = 500
        
        -- Draw background with semi-transparency
        love.graphics.setColor(0.15, 0.15, 0.2, 0.85)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 12, 12)
        
        -- Draw fancy border
        love.graphics.setColor(0.8, 0.7, 0.4, 0.9)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 12, 12)
        love.graphics.rectangle("line", infoX+2, infoY+2, infoWidth-4, infoHeight-4, 10, 10)
        
        -- Draw location name
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.setColor(0, 0, 0)
        
        local nameWidth = screenManager.fonts.medium:getWidth(self.hoverLocation.name)
        love.graphics.print(
            self.hoverLocation.name,
            infoX + (infoWidth - nameWidth) / 2,
            infoY + 15
        )
        
        -- Draw location description
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(0.95, 0.95, 0.95)
        
        love.graphics.printf(
            self.hoverLocation.description,
            infoX + 20, infoY + 50,
            infoWidth - 40, "center"
        )
        
        -- Draw "Click to enter" text
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(0.8, 0.9, 1, 0.7)
        love.graphics.printf(
            "Click to enter",
            infoX + 20, infoY + infoHeight - 25,
            infoWidth - 40, "center"
        )
    end
    
    -- Draw UI elements
    self.elements.menuButton:draw()
    self.elements.saveButton:draw()
    self.elements.inventoryButton:draw()
    self.elements.characterInfoButton:draw()
    self.elements.questLogButton:draw()
    self.elements.worldMapButton:draw()
    self.elements.partyPanel:draw()
    self.elements.menuPanel:draw()
    
    -- Draw popup last so it's on top
    self.elements.popupMessage:draw()
    
    -- Draw title with shadow effect
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
    local cityName = self.cityData and self.cityData.name or "Khulaan"
    love.graphics.print(cityName, 22, 22)
    love.graphics.setColor(1, 0.9, 0.6)
    love.graphics.print(cityName, 20, 20)
end

function khulaan:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Check popup first
    if self.elements.popupMessage.visible then
        return self.elements.popupMessage:clicked(x, y, button)
    end
    
    -- Check if menu panel is open
    if self.elements.menuPanel.visible then
        clickHandled = self.elements.menuPanel:clicked(x, y, button)
        if clickHandled then
            return true
        end
    end
    
    -- Check UI element clicks
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false and 
           element ~= self.elements.menuPanel then
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("button_click")
                
                if GAME.debug then
                    print("Button clicked: " .. name)
                end
                
                clickHandled = true
                -- Don't break to allow hover effects
            end
        end
    end
    
    -- Check location clicks if no UI element was clicked
    if not clickHandled and button == 1 and self.hoverLocation then
        -- Play click sound
        assetManager:playSound("button_click")
        
        self:selectLocation(self.hoverLocation)
        clickHandled = true
    end
    
    return clickHandled
end

function khulaan:showMenu()
    self.elements.menuPanel.visible = true
end

function khulaan:saveGame()
    -- Prepare save data
    local saveData = {
        party = GAME.party,
        inventory = GAME.inventory,
        gold = GAME.gold,
        quests = GAME.activeQuests,
        completedQuests = GAME.completedQuests,
        flags = GAME.flags,
        gameTime = GAME.gameTime or 0,
        lastCity = GAME.lastCity or "Khulaan"
    }
    
    -- Save game
    if saveLoad:saveGame(saveData) then
        print("Game saved successfully!")
    else
        print("Failed to save game!")
    end
end

function khulaan:selectLocation(location)
    -- Change to selected location
    local gameState = require("states/gameState")
    
    -- Prepare parameters to pass to the next state
    local params = { from = "khulaan" }
    
    -- Special handling for dungeon entry
    if location.state == "dungeon" then
        -- Check for active quests
        if not GAME.activeQuests or #GAME.activeQuests == 0 then
            self.elements.popupMessage:show("You need an active quest to enter the dungeon!\n\nVisit the Guild or Tavern.", "Dungeon Entry Restricted")            
            return -- Stop execution, don't change state
        end
        
        -- If entering dungeon, pass the first active quest
        params.quest = GAME.activeQuests[1]
        if GAME.debug then print("Passing quest to dungeon:", params.quest.name) end
    end
    
    -- Pass the location state and any relevant parameters
    gameState:changeState(location.state, params)
end

function khulaan:openInventory()
    local gameState = require("states/gameState")
    gameState:changeState("inventory", { from = "khulaan" })
end

function khulaan:keypressed(key, scancode, isrepeat)
    -- Check for inventory shortcut key
    if key == "i" then
        self:openInventory()
        return true
    end
    
    -- Handle other key presses
    return false
end

return khulaan 