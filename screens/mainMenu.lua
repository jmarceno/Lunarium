-- Main Menu Screen
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")

local mainMenu = screenManager:createScreen("Main Menu")

function mainMenu:init()
    -- Initialize menu state
    self.state = "main" -- main, load, options, about
    self.saveProfiles = {}
    self.selectedProfile = nil
    
    -- Create menu buttons
    self.elements.newGameButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 - 100, 
        200, 50, "New Game", 
        function() self:startNewGame() end
    )
    
    self.elements.loadGameButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 - 40, 
        200, 50, "Load Game", 
        function() self:showLoadGame() end
    )
    
    self.elements.optionsButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 + 20, 
        200, 50, "Options", 
        function() self:showOptions() end
    )
    
    self.elements.aboutButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 + 80, 
        200, 50, "About", 
        function() self:showAbout() end
    )
    
    self.elements.quitButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 + 140, 
        200, 50, "Quit", 
        function() love.event.quit() end
    )
    
    -- Create back button for sub-menus
    self.elements.backButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height - 100, 
        200, 50, "Back", 
        function() self:showMainMenu() end
    )
    
    -- Initially hide the back button (only shown in submenu states)
    self.elements.backButton.visible = false
    
    -- Create profile list for load game screen
    self.elements.profileList = {
        x = GAME.width / 2 - 200,
        y = GAME.height / 2 - 150,
        width = 400,
        height = 300,
        selectedIndex = nil,
        
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw border
            love.graphics.setColor(0.4, 0.4, 0.6)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            
            -- Draw profiles
            love.graphics.setFont(screenManager.fonts.medium)
            
            for i, profile in ipairs(mainMenu.saveProfiles) do
                local itemY = self.y + 10 + (i-1) * 40
                
                -- Highlight selected profile
                if i == self.selectedIndex then
                    love.graphics.setColor(0.3, 0.3, 0.6)
                    love.graphics.rectangle("fill", self.x + 5, itemY, self.width - 10, 35)
                end
                
                -- Draw profile name
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(profile.name, self.x + 20, itemY + 5)
                
                -- Draw profile details
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 0.8)
                local detailText = "Level: " .. profile.level .. " • Last played: " .. profile.date
                love.graphics.print(detailText, self.x + 20, itemY + 30)
            end
            
            -- Draw message if no profiles
            if #mainMenu.saveProfiles == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.printf(
                    "No saved games found",
                    self.x, self.y + self.height / 2 - 15, 
                    self.width, "center"
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within bounds
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check which profile was clicked
                for i, profile in ipairs(mainMenu.saveProfiles) do
                    local itemY = self.y + 10 + (i-1) * 40
                    if y >= itemY and y <= itemY + 35 then
                        self.selectedIndex = i
                        mainMenu.selectedProfile = profile
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create load button for load game screen
    self.elements.loadButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height - 160, 
        200, 50, "Load", 
        function() self:loadSelectedGame() end
    )
    
    -- Create delete button for load game screen
    self.elements.deleteButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height - 230, 
        200, 50, "Delete", 
        function() self:deleteSelectedGame() end
    )
    
    -- Create options UI elements
    self.elements.musicVolumeSlider = screenManager.UI.Slider(
        GAME.width / 2 - 100, GAME.height / 2 - 100, 
        200, 0, 100, GAME.settings.sound.musicVolume * 100,
        function(value) 
            GAME.settings.sound.musicVolume = value / 100
        end
    )
    
    self.elements.sfxVolumeSlider = screenManager.UI.Slider(
        GAME.width / 2 - 100, GAME.height / 2 - 30, 
        200, 0, 100, GAME.settings.sound.sfxVolume * 100,
        function(value) 
            GAME.settings.sound.sfxVolume = value / 100
        end
    )
    
    self.elements.fullscreenToggle = {
        x = GAME.width / 2 - 100,
        y = GAME.height / 2 + 40,
        width = 200,
        height = 40,
        value = GAME.settings.graphics.fullscreen,
        
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw border
            love.graphics.setColor(0.4, 0.4, 0.6)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw label
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Fullscreen", self.x + 10, self.y + 10)
            
            -- Draw toggle box
            local boxSize = 20
            local boxX = self.x + self.width - boxSize - 10
            local boxY = self.y + (self.height - boxSize) / 2
            
            love.graphics.setColor(0.1, 0.1, 0.2)
            love.graphics.rectangle("fill", boxX, boxY, boxSize, boxSize)
            
            love.graphics.setColor(0.4, 0.4, 0.6)
            love.graphics.rectangle("line", boxX, boxY, boxSize, boxSize)
            
            -- Draw check if enabled
            if self.value then
                love.graphics.setColor(0.2, 0.8, 0.2)
                love.graphics.rectangle("fill", boxX + 3, boxY + 3, boxSize - 6, boxSize - 6)
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within bounds
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                self.value = not self.value
                GAME.settings.graphics.fullscreen = self.value
                
                -- Toggle fullscreen mode
                love.window.setFullscreen(self.value)
                
                return true
            end
            
            return false
        end
    }
    
    -- Create save settings button
    self.elements.saveSettingsButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 + 100, 
        200, 50, "Save Settings", 
        function() self:saveSettings() end
    )
end

function mainMenu:enter()
    -- Start playing menu music
    assetManager:playMusic("menu")
    
    -- Reset menu state
    self:showMainMenu()
    
    -- Load save profiles if entering load game screen
    if self.state == "load" then
        self:loadSaveProfiles()
    end
    
    -- Reset selected profile
    self.selectedProfile = nil
    self.elements.profileList.selectedIndex = nil
end

function mainMenu:update(dt)
    -- Update visible UI elements
    for _, element in pairs(self.elements) do
        if element.visible ~= false and element.update then
            element:update(dt)
        end
    end
end

function mainMenu:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw game title
    love.graphics.setFont(screenManager.fonts.title)
    love.graphics.setColor(screenManager.colors.title)
    local titleText = "Dungeon Crawler"
    local titleWidth = screenManager.fonts.title:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 50)
    
    -- Draw version
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("v" .. GAME.version, 10, GAME.height - 20)
    
    -- Draw state-specific UI
    if self.state == "main" then
        self:drawMainMenu()
    elseif self.state == "load" then
        self:drawLoadGame()
    elseif self.state == "options" then
        self:drawOptions()
    elseif self.state == "about" then
        self:drawAbout()
    end
end

function mainMenu:drawMainMenu()
    -- Set visibility for current state
    self.elements.newGameButton.visible = true
    self.elements.loadGameButton.visible = true
    self.elements.optionsButton.visible = true
    self.elements.aboutButton.visible = true
    self.elements.quitButton.visible = true
    self.elements.backButton.visible = false
    
    -- Hide other state elements
    if self.elements.loadButton then self.elements.loadButton.visible = false end
    if self.elements.deleteButton then self.elements.deleteButton.visible = false end
    if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = false end
    if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = false end
    if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = false end
    if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = false end
    
    -- Draw buttons
    self.elements.newGameButton:draw()
    self.elements.loadGameButton:draw()
    self.elements.optionsButton:draw()
    self.elements.aboutButton:draw()
    self.elements.quitButton:draw()
end

function mainMenu:drawLoadGame()
    -- Set visibility for current state
    self.elements.newGameButton.visible = false
    self.elements.loadGameButton.visible = false
    self.elements.optionsButton.visible = false
    self.elements.aboutButton.visible = false
    self.elements.quitButton.visible = false
    self.elements.backButton.visible = true
    
    if self.elements.loadButton then self.elements.loadButton.visible = true end
    if self.elements.deleteButton then self.elements.deleteButton.visible = true end
    
    -- Hide other state elements
    if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = false end
    if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = false end
    if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = false end
    if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = false end
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Load Game"
    local titleWidth = screenManager.fonts.large:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 120)
    
    -- Draw profile list
    self.elements.profileList:draw()
    
    -- Draw buttons
    self.elements.loadButton:draw()
    self.elements.deleteButton:draw()
    self.elements.backButton:draw()
end

function mainMenu:drawOptions()
    -- Set visibility for current state
    self.elements.newGameButton.visible = false
    self.elements.loadGameButton.visible = false
    self.elements.optionsButton.visible = false
    self.elements.aboutButton.visible = false
    self.elements.quitButton.visible = false
    self.elements.backButton.visible = true
    
    if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = true end
    if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = true end
    if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = true end
    if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = true end
    
    -- Hide other state elements
    if self.elements.loadButton then self.elements.loadButton.visible = false end
    if self.elements.deleteButton then self.elements.deleteButton.visible = false end
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Options"
    local titleWidth = screenManager.fonts.large:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 120)
    
    -- Draw option labels
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Music Volume", GAME.width / 2 - 100, GAME.height / 2 - 130)
    love.graphics.print("SFX Volume", GAME.width / 2 - 100, GAME.height / 2 - 60)
    
    -- Draw sliders and toggles
    self.elements.musicVolumeSlider:draw()
    self.elements.sfxVolumeSlider:draw()
    self.elements.fullscreenToggle:draw()
    
    -- Draw buttons
    self.elements.saveSettingsButton:draw()
    self.elements.backButton:draw()
end

function mainMenu:drawAbout()
    -- Set visibility for current state
    self.elements.newGameButton.visible = false
    self.elements.loadGameButton.visible = false
    self.elements.optionsButton.visible = false
    self.elements.aboutButton.visible = false
    self.elements.quitButton.visible = false
    self.elements.backButton.visible = true
    
    -- Hide other state elements
    if self.elements.loadButton then self.elements.loadButton.visible = false end
    if self.elements.deleteButton then self.elements.deleteButton.visible = false end
    if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = false end
    if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = false end
    if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = false end
    if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = false end
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    local titleText = "About"
    local titleWidth = screenManager.fonts.large:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 120)
    
    -- Draw about text
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(0.9, 0.9, 0.9)
    
    local aboutText = "Dungeon Crawler is a first-person turn-based RPG.\n\n" ..
                      "Navigate through procedurally generated dungeons,\n" ..
                      "fight monsters, collect loot, and complete quests."
    
    love.graphics.printf(
        aboutText,
        GAME.width / 2 - 250, GAME.height / 2 - 100,
        500, "center"
    )
    
    -- Draw credits
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7)
    
    local creditsText = "Made with LÖVE (https://love2d.org)"
    
    love.graphics.printf(
        creditsText,
        GAME.width / 2 - 250, GAME.height / 2 + 50,
        500, "center"
    )
    
    -- Draw back button
    self.elements.backButton:draw()
end

function mainMenu:showMainMenu()
    self.state = "main"
    self:updateButtonVisibility()
end

function mainMenu:showLoadGame()
    self.state = "load"
    self:loadSaveProfiles()
    self:updateButtonVisibility()
end

function mainMenu:showOptions()
    self.state = "options"
    self:updateButtonVisibility()
end

function mainMenu:showAbout()
    self.state = "about"
    self:updateButtonVisibility()
end

function mainMenu:updateButtonVisibility()
    -- Update button visibility based on current state
    if self.state == "main" then
        -- Main menu buttons
        self.elements.newGameButton.visible = true
        self.elements.loadGameButton.visible = true
        self.elements.optionsButton.visible = true
        self.elements.aboutButton.visible = true
        self.elements.quitButton.visible = true
        self.elements.backButton.visible = false
        
        -- Hide other state elements
        if self.elements.loadButton then self.elements.loadButton.visible = false end
        if self.elements.deleteButton then self.elements.deleteButton.visible = false end
        if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = false end
        if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = false end
        if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = false end
        if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = false end
    elseif self.state == "load" then
        -- Load game buttons
        self.elements.newGameButton.visible = false
        self.elements.loadGameButton.visible = false
        self.elements.optionsButton.visible = false
        self.elements.aboutButton.visible = false
        self.elements.quitButton.visible = false
        self.elements.backButton.visible = true
        
        if self.elements.loadButton then self.elements.loadButton.visible = true end
        if self.elements.deleteButton then self.elements.deleteButton.visible = true end
        
        -- Hide other state elements
        if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = false end
        if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = false end
        if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = false end
        if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = false end
    elseif self.state == "options" then
        -- Options buttons
        self.elements.newGameButton.visible = false
        self.elements.loadGameButton.visible = false
        self.elements.optionsButton.visible = false
        self.elements.aboutButton.visible = false
        self.elements.quitButton.visible = false
        self.elements.backButton.visible = true
        
        if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = true end
        if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = true end
        if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = true end
        if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = true end
        
        -- Hide other state elements
        if self.elements.loadButton then self.elements.loadButton.visible = false end
        if self.elements.deleteButton then self.elements.deleteButton.visible = false end
    elseif self.state == "about" then
        -- About buttons
        self.elements.newGameButton.visible = false
        self.elements.loadGameButton.visible = false
        self.elements.optionsButton.visible = false
        self.elements.aboutButton.visible = false
        self.elements.quitButton.visible = false
        self.elements.backButton.visible = true
        
        -- Hide other state elements
        if self.elements.loadButton then self.elements.loadButton.visible = false end
        if self.elements.deleteButton then self.elements.deleteButton.visible = false end
        if self.elements.musicVolumeSlider then self.elements.musicVolumeSlider.visible = false end
        if self.elements.sfxVolumeSlider then self.elements.sfxVolumeSlider.visible = false end
        if self.elements.fullscreenToggle then self.elements.fullscreenToggle.visible = false end
        if self.elements.saveSettingsButton then self.elements.saveSettingsButton.visible = false end
    end
end

function mainMenu:loadSaveProfiles()
    -- Load save profiles
    self.saveProfiles = saveLoad:listSaveProfiles()
    self.selectedProfile = nil
    self.elements.profileList.selectedIndex = nil
end

function mainMenu:startNewGame()
    -- Move to character creator screen
    local gameState = require("states/gameState")
    gameState:changeState("characterCreator", {newGame = true})
end

function mainMenu:loadSelectedGame()
    if not self.selectedProfile then
        return
    end
    
    -- Load selected game
    local gameData = saveLoad:loadProfile(self.selectedProfile.name)
    
    if gameData then
        -- Set game data
        GAME.party = gameData.party
        GAME.inventory = gameData.inventory
        GAME.gold = gameData.gold
        GAME.activeQuests = gameData.quests
        GAME.completedQuests = gameData.completedQuests
        GAME.flags = gameData.flags
        
        -- Move to overworld screen
        local gameState = require("states/gameState")
        gameState:changeState("overworld")
    end
end

function mainMenu:deleteSelectedGame()
    if not self.selectedProfile then
        return
    end
    
    -- Delete selected profile
    saveLoad:deleteProfile(self.selectedProfile.name)
    
    -- Reload profiles
    self:loadSaveProfiles()
end

function mainMenu:saveSettings()
    -- Save settings
    saveLoad:saveGameSettings()
    
    -- Go back to main menu
    self:showMainMenu()
end

function mainMenu:mousepressed(x, y, button, istouch, presses)
    -- Pass to UI elements that are visible for the current state
    local clickHandled = false
    
    for name, element in pairs(self.elements) do
        -- Only process visible elements
        if element.visible ~= false then
            -- Check for both clicked (buttons) and pressed (sliders, etc.)
            local handled = false
            if element.clicked then
                if element:clicked(x, y, button) then
                    handled = true
                end
            elseif element.pressed then
                if element:pressed(x, y, button) then -- Pass button arg if needed by pressed
                    handled = true
                end
            end

            if handled then
                -- Play click sound (consider different sound for slider interaction?)
                assetManager:playSound("click") 
                    
                if GAME.debug then
                    print("UI Element interacted: " .. name)
                end
                    
                clickHandled = true
                -- Important: If an element handles the press (like a slider starting a drag), 
                -- we might want to break the loop so other elements below it don't also react.
                -- However, the original code didn't break to allow hover effects. Let's keep that for now,
                -- but be aware this could be adjusted if needed.
                -- break 
            end
        end
    end
    
    return clickHandled
end

function mainMenu:mousereleased(x, y, button, istouch, presses)
    -- Pass to UI elements
    for _, element in pairs(self.elements) do
        if element.released then
            element:released(x, y)
        end
    end
end

return mainMenu
