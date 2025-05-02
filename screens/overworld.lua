-- Overworld Screen
-- The main navigation hub between different game locations
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")

local overworld = screenManager:createScreen("Overworld")

function overworld:init()
    -- Initialize locations
    self.locations = {
        {
            name = "Tavern",
            description = "Visit the tavern to find quests, rumors and refreshment.",
            x = 250,
            y = 200,
            width = 120,
            height = 100,
            state = "tavern"
        },
        {
            name = "Guild",
            description = "The adventurers' guild offers official quests and services.",
            x = 550,
            y = 200,
            width = 120,
            height = 100,
            state = "guild"
        },
        {
            name = "Shop",
            description = "Purchase equipment, items and supplies.",
            x = 250,
            y = 350,
            width = 120,
            height = 100,
            state = "shop"
        },
        {
            name = "Smith",
            description = "Craft weapons and armor from monster parts.",
            x = 550,
            y = 350,
            width = 120,
            height = 100,
            state = "smith"
        },
        {
            name = "Dungeon",
            description = "Enter the dungeon to complete quests and find treasure.",
            x = 400,
            y = 275,
            width = 120,
            height = 100,
            state = "dungeon"
        }
    }
    
    -- Initialize hover state
    self.hoverLocation = nil
    
    -- Popup message element
    self.elements.popupMessage = {
        visible = false,
        message = "",
        x = GAME.width / 2 - 150,
        y = GAME.height / 2 - 50,
        width = 300,
        height = 100,
        okButton = nil,
        
        init = function(self)
            self.okButton = screenManager.UI.Button(
                self.x + self.width/2 - 50, self.y + self.height - 55, 
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
            screenManager:drawPanel(nil, self.x, self.y, self.width, self.height)
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1,1,1)
            love.graphics.printf(self.message, self.x + 10, self.y + 20, self.width - 20, "center")
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

function overworld:createUI()
    -- Create menu button
    self.elements.menuButton = screenManager.UI.Button(
        GAME.width - 170, 20, 150, 40, "Menu", 
        function() self:showMenu() end
    )
    self.elements.menuButton.visible = true
    
    -- Create save button
    self.elements.saveButton = screenManager.UI.Button(
        GAME.width - 170, 70, 150, 40, "Save Game", 
        function() self:saveGame() end
    )
    self.elements.saveButton.visible = true
    
    -- Create inventory button (in top bar)
    self.elements.inventoryButton = screenManager.UI.Button(
        GAME.width - 170, 120, 150, 40, "Inventory (I)", 
        function() self:openInventory() end
    )
    self.elements.inventoryButton.visible = true
    
    -- Create character info button (in top bar)
    self.elements.characterInfoButton = screenManager.UI.Button(
        GAME.width - 170, 170, 150, 40, "Character Info", 
        function() 
            local gameState = require("states/gameState")
            gameState:changeState("characterInfo")
        end
    )
    self.elements.characterInfoButton.visible = true
    
    -- Create quest log button (in top bar)
    self.elements.questLogButton = screenManager.UI.Button(
        GAME.width - 170, 220, 150, 40, "Quest Log", 
        function() 
            local gameState = require("states/gameState")
            gameState:changeState("questLog")
        end
    )
    self.elements.questLogButton.visible = true
    
    -- Create menu panel
    self.elements.menuPanel = {
        visible = false,
        x = GAME.width / 2 - 150,
        y = GAME.height / 2 - 200,
        width = 300,
        height = 300,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw panel background
            screenManager:drawPanel("Menu", self.x, self.y, self.width, self.height)
            
            -- Draw buttons
            for _, button in ipairs(self.buttons) do
                button:draw()
            end
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check button clicks
                for _, btn in ipairs(self.buttons) do
                    if btn:clicked(x, y, button) then
                        -- Play click sound
                        assetManager:playSound("click")
                        return true
                    end
                end
                
                return true
            else
                -- Close panel if clicked outside
                self.visible = false
                return true
            end
        end,
        
        mousereleased = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Handle button releases
            for _, btn in ipairs(self.buttons) do
                if btn.released then
                    btn:released(x, y, button)
                end
            end
            
            return true
        end,
        
        init = function(self)
            -- Create menu buttons
            self.buttons = {
                screenManager.UI.Button(
                    self.x + 50, self.y + 80, 
                    200, 40, "Resume Game", 
                    function() self.visible = false end
                ),
                
                screenManager.UI.Button(
                    self.x + 50, self.y + 130, 
                    200, 40, "Inventory", 
                    function() 
                        overworld:openInventory()
                        self.visible = false
                    end
                ),
                
                screenManager.UI.Button(
                    self.x + 50, self.y + 180, 
                    200, 40, "Save Game", 
                    function() 
                        overworld:saveGame()
                        self.visible = false
                    end
                ),
                
                screenManager.UI.Button(
                    self.x + 50, self.y + 230, 
                    200, 40, "Options", 
                    function() 
                        -- TODO: Implement options screen
                        self.visible = false
                    end
                ),
                
                screenManager.UI.Button(
                    self.x + 50, self.y + 280, 
                    200, 40, "Return to Title", 
                    function() 
                        local gameState = require("states/gameState")
                        gameState:changeState("mainMenu")
                    end
                )
            }
            
            -- Initialize button visibility
            for _, btn in ipairs(self.buttons) do
                btn.visible = true
            end
        end
    }
    
    -- Initialize menu panel
    self.elements.menuPanel:init()
    
    -- Create quest notification panel
    self.elements.questPanel = {
        visible = false,
        x = GAME.width / 2 - 200,
        y = GAME.height / 2 - 150,
        width = 400,
        height = 300,
        quest = nil,
        
        draw = function(self)
            if not self.visible or not self.quest then return end
            
            -- Draw panel background
            screenManager:drawPanel("Quest Complete!", self.x, self.y, self.width, self.height)
            
            -- Draw quest info
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                self.quest.name,
                self.x + 20, self.y + 60,
                self.width - 40, "center"
            )
            
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(0.8, 0.8, 0.8)
            
            love.graphics.printf(
                self.quest.description,
                self.x + 20, self.y + 100,
                self.width - 40, "center"
            )
            
            -- Draw rewards
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 0.5)
            
            love.graphics.print(
                "Rewards:",
                self.x + 20, self.y + 150
            )
            
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.print(
                "Gold: " .. self.quest.goldReward,
                self.x + 20, self.y + 180
            )
            
            if self.quest.itemRewards and #self.quest.itemRewards > 0 then
                love.graphics.print(
                    "Items:",
                    self.x + 20, self.y + 200
                )
                
                for i, item in ipairs(self.quest.itemRewards) do
                    love.graphics.print(
                        "- " .. item.name,
                        self.x + 40, self.y + 200 + i * 20
                    )
                end
            end
            
            -- Draw close button
            self.closeButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check close button
                if self.closeButton:clicked(x, y, button) then
                    return true
                end
                
                return true
            else
                -- Close panel if clicked outside
                self.visible = false
                return true
            end
        end,
        
        init = function(self)
            -- Create close button
            self.closeButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + self.height - 60, 
                100, 40, "Close", 
                function() self.visible = false end
            )
        end,
        
        showQuest = function(self, quest)
            self.quest = quest
            self.visible = true
        end
    }
    
    -- Initialize quest panel
    self.elements.questPanel:init()
    
    -- Create party status panel
    self.elements.partyPanel = {
        x = 20,
        y = GAME.height - 120,
        width = GAME.width - 40,
        height = 100,
        
        draw = function(self)
            -- Draw panel background
            love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw party members
            if GAME.party then
                for i, character in ipairs(GAME.party) do
                    local x = self.x + 10 + (i-1) * ((self.width - 20) / 4)
                    local width = (self.width - 20) / 4 - 10
                    
                    -- Draw character portrait
                    love.graphics.setColor(1, 1, 1)
                    if character.portraitId and assetManager.images.portraits[character.portraitId] then
                        love.graphics.draw(
                            assetManager.images.portraits[character.portraitId],
                            x, self.y + 10,
                            0, 0.5, 0.5
                        )
                    elseif assetManager.images.profiles[character.profileIndex] then
                        love.graphics.draw(
                            assetManager.images.profiles[character.profileIndex],
                            x, self.y + 10,
                            0, 0.5, 0.5
                        )
                    end
                    
                    -- Draw character name
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    local nameWidth = screenManager.fonts.small:getWidth(character.name)
                    if nameWidth > width - 50 then
                        -- Truncate name if too long
                        local truncName = ""
                        local j = 1
                        while screenManager.fonts.small:getWidth(truncName .. "...") < width - 50 and j <= #character.name do
                            truncName = truncName .. character.name:sub(j, j)
                            j = j + 1
                        end
                        love.graphics.print(truncName .. "...", x + 50, self.y + 10)
                    else
                        love.graphics.print(character.name, x + 50, self.y + 10)
                    end
                    
                    -- Draw character job and level
                    love.graphics.setColor(0.8, 0.8, 1)
                    local currentJobLevel = character.jobLevels[character.job] or 1 -- Default to 1 if somehow missing
                    love.graphics.print(
                        character.job .. " Lv." .. currentJobLevel,
                        x + 50, self.y + 30
                    )
                    
                    -- Draw HP and MP bars
                    -- HP bar
                    local barWidth = width - 10
                    local healthWidth = barWidth * (character.currentHP / character.maxHP)
                    
                    love.graphics.setColor(0.2, 0.2, 0.2)
                    love.graphics.rectangle("fill", x + 5, self.y + 50, barWidth, 10)
                    
                    love.graphics.setColor(0.8, 0.2, 0.2)
                    love.graphics.rectangle("fill", x + 5, self.y + 50, healthWidth, 10)
                    
                    -- MP bar
                    local manaWidth = barWidth * (character.currentMP / character.maxMP)
                    
                    love.graphics.setColor(0.2, 0.2, 0.2)
                    love.graphics.rectangle("fill", x + 5, self.y + 65, barWidth, 10)
                    
                    love.graphics.setColor(0.2, 0.2, 0.8)
                    love.graphics.rectangle("fill", x + 5, self.y + 65, manaWidth, 10)
                    
                    -- Draw HP and MP values
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        character.currentHP .. "/" .. character.maxHP,
                        x + 10, self.y + 80
                    )
                    
                    love.graphics.print(
                        character.currentMP .. "/" .. character.maxMP,
                        x + width / 2, self.y + 80
                    )
                end
            end
            
            -- Draw gold count
            if GAME.gold then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Gold: " .. GAME.gold,
                    self.x + self.width - 150, self.y - 30
                )
            end
            
            -- Draw inventory shortcut button
            if self.inventoryButton then
                self.inventoryButton:draw()
            end
        end,
        
        init = function(self)
            -- Create inventory shortcut button in the party panel
            self.inventoryButton = screenManager.UI.Button(
                self.x + self.width - 120, self.y + 10, 
                100, 30, "Inventory", 
                function() overworld:openInventory() end
            )
            self.inventoryButton.visible = true
        end
    }
end

function overworld:enter(params)
    -- Start playing town music
    assetManager:playMusic("town")
    
    -- Check for completed quest notification
    if params and params.completedQuest then
        self.elements.questPanel:showQuest(params.completedQuest)
    end
end

function overworld:update(dt)
    -- Update UI elements
    for _, element in pairs(self.elements) do
        if element.update then
            element:update(dt)
        end
    end
    
    -- Update hover state
    local mx, my = love.mouse.getPosition()
    self.hoverLocation = nil
    
    for _, location in ipairs(self.locations) do
        if mx >= location.x and mx <= location.x + location.width and
           my >= location.y and my <= location.y + location.height then
            self.hoverLocation = location
            break
        end
    end
end

function overworld:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw town map (placeholder for now)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 180, 150, 440, 250)
    
    -- Draw locations
    for _, location in ipairs(self.locations) do
        -- Determine color based on hover state
        if location == self.hoverLocation then
            love.graphics.setColor(0.4, 0.5, 0.8)
        else
            love.graphics.setColor(0.3, 0.3, 0.5)
        end
        
        -- Draw location
        love.graphics.rectangle(
            "fill", 
            location.x, location.y, 
            location.width, location.height,
            10, 10
        )
        
        -- Draw location name
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(1, 1, 1)
        
        local nameWidth = screenManager.fonts.small:getWidth(location.name)
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
        
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 10, 10)
        
        love.graphics.setColor(0.4, 0.4, 0.6)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 10, 10)
        
        -- Draw location name
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.setColor(1, 1, 1)
        
        local nameWidth = screenManager.fonts.medium:getWidth(self.hoverLocation.name)
        love.graphics.print(
            self.hoverLocation.name,
            infoX + (infoWidth - nameWidth) / 2,
            infoY + 15
        )
        
        -- Draw location description
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(0.9, 0.9, 0.9)
        
        love.graphics.printf(
            self.hoverLocation.description,
            infoX + 20, infoY + 50,
            infoWidth - 40, "center"
        )
    end
    
    -- Draw UI elements
    self.elements.menuButton:draw()
    self.elements.saveButton:draw()
    self.elements.inventoryButton:draw()
    self.elements.characterInfoButton:draw()
    self.elements.questLogButton:draw()
    self.elements.partyPanel:draw()
    self.elements.menuPanel:draw()
    self.elements.questPanel:draw()
    
    -- Draw popup last so it's on top
    self.elements.popupMessage:draw()
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(screenManager.colors.title)
    love.graphics.print("Town of Ravenholm", 20, 20)
end

function overworld:mousepressed(x, y, button, istouch, presses)
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
    
    -- Check if quest panel is open
    if self.elements.questPanel.visible then
        clickHandled = self.elements.questPanel:clicked(x, y, button)
        if clickHandled then
            return true
        end
    end
    
    -- Check UI element clicks
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false and 
           element ~= self.elements.menuPanel and
           element ~= self.elements.questPanel then
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
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
        self:selectLocation(self.hoverLocation)
        clickHandled = true
    end
    
    return clickHandled
end

function overworld:mousereleased(x, y, button, istouch, presses)
    -- Check if menu panel is open and has a mousereleased method
    if self.elements.menuPanel.visible and self.elements.menuPanel.mousereleased then
        self.elements.menuPanel:mousereleased(x, y, button)
    end

    -- Check if quest panel is open
    if self.elements.questPanel.visible and self.elements.questPanel.mousereleased then
        self.elements.questPanel:mousereleased(x, y, button)
    end
    
    -- Pass to other UI elements
    for name, element in pairs(self.elements) do
        if element.released and element.visible ~= false and 
           element ~= self.elements.menuPanel and
           element ~= self.elements.questPanel then
            element:released(x, y)
        end
    end
    
    if GAME.debug then
        print("Overworld mouse released at: " .. x .. "," .. y)
    end
end

function overworld:showMenu()
    -- Show menu panel
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
        gameTime = GAME.gameTime or 0
    }
    
    -- Save game
    if saveLoad:saveGame(saveData) then
        -- Show save confirmation
        -- For now, just print to console
        print("Game saved successfully!")
    else
        -- Show save error
        print("Failed to save game!")
    end
end

function overworld:selectLocation(location)
    -- Play click sound
    assetManager:playSound("click")
    
    -- Change to selected location
    local gameState = require("states/gameState")
    
    -- Prepare parameters to pass to the next state
    local params = {}
    
    -- Special handling for dungeon entry
    if location.state == "dungeon" then
        -- Check for active quests
        if not GAME.activeQuests or #GAME.activeQuests == 0 then
            -- Show popup message instead of printing
            self.elements.popupMessage:show("You need an active quest to enter the dungeon!\nVisit the Guild or Tavern.")
            -- TODO: Replace print with a proper UI message popup
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
