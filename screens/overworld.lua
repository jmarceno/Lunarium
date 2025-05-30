-- Overworld Screen (LUIS)
-- The main navigation hub between different game locations
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")
local partyPanelLuis = require("ui_elements/partyPanelLuis")

-- Get LUIS instance
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

local overworld = screenManager:createScreen("Overworld")

function overworld:init()
    -- Load town map image
    self.townMapImage = assetManager:getImage("townMap") or love.graphics.newImage("assets/TownMap.png")
    
    -- Track if hover sound has been played to avoid repetition
    self.hoverSoundPlayed = false
    
    -- Initialize locations
    self.locations = {
        {
            name = "Tavern",
            description = "Visit the tavern to find quests, rumors and refreshment.",
            x = 600,
            y = 255,
            width = 120,
            height = 100,
            state = "tavern"
        },
        {
            name = "Guild",
            description = "The adventurers' guild offers official quests and services.",
            x = 900,
            y = 450,
            width = 120,
            height = 100,
            state = "guild"
        },
        {
            name = "Shop",
            description = "Purchase equipment, items and supplies.",
            x = 850,
            y = 250,
            width = 120,
            height = 100,
            state = "shop"
        },
        {
            name = "Smith",
            description = "Craft weapons and armor from monster parts.",
            x = 320,
            y = 460,
            width = 120,
            height = 100,
            state = "smith"
        },
        {
            name = "Dungeon",
            description = "Enter the dungeon to complete quests and find treasure.",
            x = 20,
            y = 170,
            width = 120,
            height = 100,
            state = "dungeon"
        },
        {
            name = "Inn",
            description = "Rest, recover, and enjoy special services at the adventurer's inn.",
            x = 300,
            y = 250,
            width = 120,
            height = 100,
            state = "inn"
        }
    }
    
    -- Initialize hover state
    self.hoverLocation = nil
    
    -- Create LUIS layers
    luis.newLayer("overworldLayer")
    luis.newLayer("popupLayer")
    
    -- Create UI elements
    self:createUI()
    
    -- Setup party panel
    self.partyPanel = partyPanelLuis:create()
    luis.insertElement("overworldLayer", self.partyPanel.container)
end

function overworld:createUI()
    -- Top-right UI panel container (40x22 grid, positioned at top-right)
    local topRightContainer = luis.createElement("overworldLayer", "FlexContainer", 10, 12, 30, 1, nil, "TopRightPanel")
    
    -- Create buttons in the top-right panel
    local menuButton = luis.newButton("Menu", 9, 2, function() self:showMenu() end, nil, 1, 1)
    topRightContainer:addChild(menuButton)
    
    local saveButton = luis.newButton("Save Game", 9, 2, function() self:saveGame() end, nil, 1, 1)
    topRightContainer:addChild(saveButton)
    
    local inventoryButton = luis.newButton("Inventory (I)", 9, 2, function() self:openInventory() end, nil, 1, 1)
    topRightContainer:addChild(inventoryButton)
    
    local partyInfoButton = luis.newButton("Party Info", 9, 2, function() 
        local gameState = require("states/gameState")
        gameState:changeState("characterInfo")
    end, nil, 1, 1)
    topRightContainer:addChild(partyInfoButton)
    
    local questLogButton = luis.newButton("Quest Log", 9, 2, function() 
        local gameState = require("states/gameState")
        gameState:changeState("questLog")
    end, nil, 1, 1)
    topRightContainer:addChild(questLogButton)
    
    -- Store references for later use
    self.uiElements = {
        topRightContainer = topRightContainer,
        menuButton = menuButton,
        saveButton = saveButton,
        inventoryButton = inventoryButton,
        partyInfoButton = partyInfoButton,
        questLogButton = questLogButton
    }
    
    -- Create popup/quest panel on separate layer
    self:createPopupPanel()
end

function overworld:createPopupPanel()
    -- Popup panel container (centered on screen)
    local popupContainer = luis.createElement("popupLayer", "FlexContainer", 20, 12, 10, 5, nil, "PopupPanel")
    
    -- Title label
    local titleLabel = luis.newLabel("Notice", 18, 2, 1, 1, "center")
    popupContainer:addChild(titleLabel)
    
    -- Message label (larger area for text)
    local messageLabel = luis.newLabel("", 18, 6, 1, 1, "center")
    popupContainer:addChild(messageLabel)
    
    -- OK button
    local okButton = luis.newButton("OK", 6, 2, function() self:hidePopup() end, nil, 1, 1)
    popupContainer:addChild(okButton)
    
    -- Store popup elements
    self.popupElements = {
        container = popupContainer,
        titleLabel = titleLabel,
        messageLabel = messageLabel,
        okButton = okButton
    }
    
    -- Start with popup layer disabled
    luis.disableLayer("popupLayer")
end

function overworld:enter(params)
    -- Enable the overworld layer
    luis.enableLayer("overworldLayer")
    
    -- Start playing town music
    assetManager:playMusic("town")
    
    -- Update party panel with current party data
    if GAME and GAME.party then
        self.partyPanel:update(GAME.party, false) -- false = not in combat
    end
    
    -- Check for completed quest notification
    if params and params.completedQuest then
        self:showPopup(params.completedQuest.name .. " completed!", "Quest Complete")
    end
end

function overworld:exit()
    -- Disable layers when leaving
    luis.disableLayer("overworldLayer")
    luis.disableLayer("popupLayer")
end

function overworld:update(dt)
    -- Update party panel
    if self.partyPanel and GAME and GAME.party then
        self.partyPanel:update(GAME.party, false)
    end
    
    -- Handle location hover detection (for map areas)
    local mx, my = love.mouse.getPosition()
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

function overworld:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw town map
    love.graphics.setColor(1, 1, 1)
    local scale = 1
    local x = (GAME.width - self.townMapImage:getWidth() * scale) / 2
    local y = ((GAME.height - self.townMapImage:getHeight() * scale) / 2) - 100
    love.graphics.draw(self.townMapImage, x, y, 0, scale, scale)
    
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
            
            -- Draw location name when hovering
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0, 0, 0, 0.9)
            
            local nameWidth = screenManager.fonts.small:getWidth(location.name)
            love.graphics.print(
                location.name,
                location.x + (location.width - nameWidth) / 2,
                location.y + location.height / 2 - 10
            )
        end
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
        love.graphics.setColor(1, 0.9, 0.6)
        
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
    
    -- Draw title with shadow effect
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
    love.graphics.print("Town of Delzor", 22, 22)
    love.graphics.setColor(1, 0.9, 0.6)
    love.graphics.print("Town of Delzor", 20, 20)
end

function overworld:mousepressed(x, y, button, istouch, presses)
    -- Check location clicks
    if button == 1 and self.hoverLocation then
        -- Play click sound
        assetManager:playSound("button_click")
        self:selectLocation(self.hoverLocation)
        return true
    end
    
    return false
end

function overworld:showMenu()
    -- Create menu modal using popup layer
    self:showPopup("Menu functionality will be implemented later", "Menu")
end

function overworld:showPopup(message, title)
    -- Update popup content
    if self.popupElements then
        self.popupElements.titleLabel.text = title or "Notice"
        self.popupElements.messageLabel.text = message or ""
        
        -- Enable popup layer
        luis.enableLayer("popupLayer")
    end
end

function overworld:hidePopup()
    -- Disable popup layer
    luis.disableLayer("popupLayer")
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
        gameTime = GAME.gameTime or 0
    }
    
    -- Save game
    if saveLoad:saveGame(saveData) then
        -- Show save confirmation
        self:showPopup("Game saved successfully!", "Save Complete")
    else
        -- Show save error
        self:showPopup("Failed to save game!", "Save Error")
    end
end

function overworld:selectLocation(location)
    -- Change to selected location
    local gameState = require("states/gameState")
    
    -- Prepare parameters to pass to the next state
    local params = {}
    
    -- Special handling for dungeon entry
    if location.state == "dungeon" then
        -- Check for active quests
        if not GAME.activeQuests or #GAME.activeQuests == 0 then
            self:showPopup("You need an active quest to enter the dungeon!\n\nVisit the Guild or Tavern.", "Dungeon Entry Restricted")
            return -- Stop execution, don't change state
        end
        
        -- If entering dungeon, pass the first active quest
        params.quest = GAME.activeQuests[1]
        if GAME.debug then print("Passing quest to dungeon:", params.quest.name) end
    end
    
    -- Pass the location state and any relevant parameters
    gameState:changeState(location.state, params)
end

function overworld:openInventory()
    local gameState = require("states/gameState")
    gameState:changeState("inventory", { from = "overworld" })
end

function overworld:keypressed(key, scancode, isrepeat)
    -- Check for inventory shortcut key
    if key == "i" then
        self:openInventory()
        return true
    end
    
    -- Handle other key presses
    return false
end

return overworld
