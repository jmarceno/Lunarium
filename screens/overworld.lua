-- Overworld Screen - Continent Map
-- The main navigation hub between different cities
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")
local cities_definitions = require("data/cities_definitions")

local overworld = screenManager:createScreen("Overworld")

function overworld:init()
    -- Load continent map image
    self.continentMapImage = assetManager:getImage("continentMap") or love.graphics.newImage("assets/temp_continent.jpg")
    
    -- Track if hover sound has been played to avoid repetition
    self.hoverSoundPlayed = false
    
    -- Initialize cities from definitions
    self.cities = {}
    for _, cityData in ipairs(cities_definitions) do
        -- Position cities on the map (we'll place them manually for now)
        local cityButton = {
            name = cityData.name,
            description = cityData.description,
            data = cityData,
            -- Position on continent map - customize these coordinates
            x = cityData.name == "Delzor" and 200 or 600,
            y = cityData.name == "Delzor" and 300 or 200,
            width = 150,
            height = 100,
            locked = false
        }
        table.insert(self.cities, cityButton)
    end
    
    -- Initialize hover state
    self.hoverCity = nil
    
    -- Create UI elements
    self:createUI()
end

function overworld:createUI()
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
            gameState:changeState("characterInfo")
        end
    )
    self.elements.characterInfoButton.visible = true
    self.elements.characterInfoButton.hovered = false
    
    -- Create quest log button
    self.elements.questLogButton = screenManager.UI.Button(
        GAME.width - 170, 220, 150, 40, "Quest Log", 
        function() 
            local gameState = require("states/gameState")
            gameState:changeState("questLog")
        end
    )
    self.elements.questLogButton.visible = true
    self.elements.questLogButton.hovered = false
    
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
                y = GAME.width / 2 - 0,
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
end

function overworld:enter(params)
    -- Initialize current city data if not set
    if not GAME.currentCityData then
        for _, city in ipairs(cities_definitions) do
            if city.name == GAME.lastCity then
                GAME.currentCityData = city
                break
            end
        end
        
        -- Fallback to Delzor
        if not GAME.currentCityData then
            GAME.lastCity = "Delzor"
            for _, city in ipairs(cities_definitions) do
                if city.name == "Delzor" then
                    GAME.currentCityData = city
                    break
                end
            end
        end
    end
end

function overworld:update(dt)
    -- Update UI elements
    for name, element in pairs(self.elements) do
        if element.update and element.visible ~= false then
            element:update(dt)
        end
    end
    
    -- Update city hover detection
    self:updateCityHover()
end

function overworld:updateCityHover()
    local mouseX, mouseY = love.mouse.getPosition()
    local prevHoverCity = self.hoverCity
    self.hoverCity = nil
    
    -- Check if mouse is over any city
    for _, city in ipairs(self.cities) do
        if mouseX >= city.x and mouseX <= city.x + city.width and
           mouseY >= city.y and mouseY <= city.y + city.height then
            self.hoverCity = city
            break
        end
    end
    
    -- Play hover sound if we started hovering over a new city
    if self.hoverCity and self.hoverCity ~= prevHoverCity then
        assetManager:playSound("button_hover")
    end
end

function overworld:draw()
    -- Draw continent map background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.continentMapImage, 0, 0, 0, 
        GAME.width / self.continentMapImage:getWidth(), 
        GAME.height / self.continentMapImage:getHeight())
    
    -- Draw cities
    for _, city in ipairs(self.cities) do
        self:drawCity(city)
    end
    
    -- Draw city information panel if hovering
    if self.hoverCity then
        self:drawCityInfo(self.hoverCity)
    end
    
    -- Draw UI elements
    self.elements.menuButton:draw()
    self.elements.saveButton:draw()
    self.elements.inventoryButton:draw()
    self.elements.characterInfoButton:draw()
    self.elements.questLogButton:draw()
    self.elements.menuPanel:draw()
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
    love.graphics.print("Continent of Lunarium", 22, 22)
    love.graphics.setColor(1, 0.9, 0.6)
    love.graphics.print("Continent of Lunarium", 20, 20)
    
    -- Draw reputation info
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(1, 1, 1)
    local totalReputation = (GAME.reputation and GAME.reputation.GUILD or 0) + (GAME.reputation and GAME.reputation.TAVERN or 0)
    love.graphics.print("Reputation: " .. totalReputation, 20, GAME.height - 30)
end

function overworld:drawCity(city)
    -- Check if city is accessible based on reputation
    local totalReputation = (GAME.reputation and GAME.reputation.GUILD or 0) + (GAME.reputation and GAME.reputation.TAVERN or 0)
    local isAccessible = totalReputation >= city.data.reputationNeeded
    
    -- Determine colors based on accessibility and hover state
    local bgColor = isAccessible and {0.2, 0.5, 0.8, 0.7} or {0.3, 0.3, 0.3, 0.7}
    local borderColor = isAccessible and {0.4, 0.7, 1, 0.9} or {0.5, 0.5, 0.5, 0.9}
    local textColor = isAccessible and {1, 1, 1} or {0.6, 0.6, 0.6}
    
    -- Highlight if hovering
    if self.hoverCity == city and isAccessible then
        bgColor = {0.3, 0.6, 0.9, 0.8}
        borderColor = {0.5, 0.8, 1, 1}
    end
    
    -- Draw city button
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", city.x, city.y, city.width, city.height, 10, 10)
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("line", city.x, city.y, city.width, city.height, 10, 10)
    
    -- Draw city name
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(textColor)
    local nameWidth = screenManager.fonts.medium:getWidth(city.name)
    love.graphics.print(city.name, city.x + (city.width - nameWidth) / 2, city.y + 20)
    
    -- Draw reputation requirement if locked
    if not isAccessible then
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(0.8, 0.4, 0.4)
        local reqText = "Rep: " .. city.data.reputationNeeded
        local reqWidth = screenManager.fonts.small:getWidth(reqText)
        love.graphics.print(reqText, city.x + (city.width - reqWidth) / 2, city.y + 50)
    end
    
    -- Mark current city
    if GAME.lastCity == city.name then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.rectangle("line", city.x - 3, city.y - 3, city.width + 6, city.height + 6, 12, 12)
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.print("Current", city.x + 5, city.y + city.height + 5)
    end
end

function overworld:drawCityInfo(city)
    -- City info panel dimensions
    local infoWidth = 300
    local infoHeight = 120
    local infoX = GAME.width - infoWidth - 20
    local infoY = 300
    
    -- Draw info panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 10, 10)
    love.graphics.setColor(0.6, 0.6, 0.8, 0.8)
    love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 10, 10)
    
    -- Draw city name
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 0.9, 0.6)
    
    local nameWidth = screenManager.fonts.medium:getWidth(city.name)
    love.graphics.print(city.name, infoX + (infoWidth - nameWidth) / 2, infoY + 15)
    
    -- Draw city description
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.printf(city.description, infoX + 20, infoY + 50, infoWidth - 40, "center")
    
    -- Check accessibility
    local totalReputation = (GAME.reputation and GAME.reputation.GUILD or 0) + (GAME.reputation and GAME.reputation.TAVERN or 0)
    local isAccessible = totalReputation >= city.data.reputationNeeded
    
    if isAccessible then
        love.graphics.setColor(0.8, 0.9, 1, 0.7)
        love.graphics.printf("Click to travel", infoX + 20, infoY + infoHeight - 25, infoWidth - 40, "center")
    else
        love.graphics.setColor(0.8, 0.4, 0.4, 0.8)
        love.graphics.printf("Requires " .. city.data.reputationNeeded .. " reputation", infoX + 20, infoY + infoHeight - 25, infoWidth - 40, "center")
    end
end

function overworld:mousepressed(x, y, button, istouch, presses)
    -- Check menu panel first
    if self.elements.menuPanel.visible then
        return self.elements.menuPanel:clicked(x, y, button)
    end
    
    -- Check UI elements
    local clickHandled = false
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false and element ~= self.elements.menuPanel then
            if element:clicked(x, y, button) then
                assetManager:playSound("button_click")
                clickHandled = true
            end
        end
    end
    
    -- Check city clicks if no UI element was clicked
    if not clickHandled and button == 1 and self.hoverCity then
        -- Check if city is accessible
        local totalReputation = (GAME.reputation and GAME.reputation.GUILD or 0) + (GAME.reputation and GAME.reputation.TAVERN or 0)
        if totalReputation >= self.hoverCity.data.reputationNeeded then
            assetManager:playSound("button_click")
            self:selectCity(self.hoverCity)
            clickHandled = true
        end
    end
    
    return clickHandled
end

function overworld:selectCity(city)
    -- Update last city and current city data
    GAME.lastCity = city.name
    GAME.currentCityData = city.data
    
    -- Change to city screen
    local gameState = require("states/gameState")
    gameState:changeState(city.data.screen, { cityData = city.data })
end

function overworld:showMenu()
    self.elements.menuPanel.visible = true
end

function overworld:saveGame()
    -- Prepare save data
    local saveData = {
        party = GAME.party,
        inventory = GAME.inventory,
        gold = GAME.gold,
        quests = GAME.activeQuests,
        completedQuests = GAME.completedQuests,
        flags = GAME.flags,
        gameTime = GAME.gameTime or 0,
        lastCity = GAME.lastCity or "Delzor"
    }
    
    -- Save game
    if saveLoad:saveGame(saveData) then
        print("Game saved successfully!")
    else
        print("Failed to save game!")
    end
end

function overworld:openInventory()
    local gameState = require("states/gameState")
    gameState:changeState("inventory", { from = "overworld" })
end

function overworld:keypressed(key, scancode, isrepeat)
    if key == "i" then
        self:openInventory()
        return true
    end
    
    return false
end

return overworld
