-- Main Menu Screen (LUIS)
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")

-- Get LUIS instance
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

local mainMenu = screenManager:createScreen("Main Menu")

function mainMenu:init()
    -- Initialize menu state
    self.state = "main" -- main, load, options, about
    self.saveProfiles = {}
    self.selectedProfile = nil
    
    -- Load main menu background image
    self.backgroundImage = love.graphics.newImage("assets/MainScreen.png")
    
    -- Create LUIS layers for different menu states
    luis.newLayer("mainMenuLayer")
    luis.newLayer("loadGameLayer")
    luis.newLayer("optionsLayer")
    luis.newLayer("aboutLayer")
    
    -- Create main menu UI elements
    self:createMainMenuUI()
    self:createLoadGameUI()
    self:createOptionsUI()
    self:createAboutUI()
    
    -- Start with main menu visible
    self:showMainMenu()
end

function mainMenu:createMainMenuUI()
    -- Main menu buttons positioned using grid (40x22 grid at 32px)
    local centerCol = 20  -- Center horizontal
    local startRow = 10   -- Start vertical position
    local buttonWidth = 6 -- 6 grid units wide
    local buttonHeight = 2 -- 2 grid units high
    
    -- Title (placeholder, drawn in custom draw method)
    
    -- Create main menu buttons
    luis.createElement("mainMenuLayer", "Button", "New Game", buttonWidth, buttonHeight, 
        function() self:startNewGame() end, nil, startRow, centerCol - 3)
    
    luis.createElement("mainMenuLayer", "Button", "Load Game", buttonWidth, buttonHeight, 
        function() self:showLoadGame() end, nil, startRow + 3, centerCol - 3)
    
    luis.createElement("mainMenuLayer", "Button", "Options", buttonWidth, buttonHeight, 
        function() self:showOptions() end, nil, startRow + 6, centerCol - 3)
    
    luis.createElement("mainMenuLayer", "Button", "About", buttonWidth, buttonHeight, 
        function() self:showAbout() end, nil, startRow + 9, centerCol - 3)
    
    luis.createElement("mainMenuLayer", "Button", "Quit", buttonWidth, buttonHeight, 
        function() love.event.quit() end, nil, startRow + 12, centerCol - 3)
end

function mainMenu:createLoadGameUI()
    -- Create FlexContainer for load game interface
    local mainContainer = luis.createElement("loadGameLayer", "FlexContainer", 30, 16, 3, 6, nil, "LoadGameMain")
    
    -- Profile list container (simplified for now - will need custom implementation)
    local profileContainer = luis.newFlexContainer(28, 10, 1, 1, nil, "ProfileList")
    mainContainer:addChild(profileContainer)
    
    -- Action buttons container
    local buttonContainer = luis.newFlexContainer(28, 4, 1, 1, nil, "LoadButtons")
    
    local loadButton = luis.newButton("Load", 6, 2, function() self:loadSelectedGame() end, nil, 1, 1)
    local deleteButton = luis.newButton("Delete", 6, 2, function() self:deleteSelectedGame() end, nil, 1, 1)
    local backButton = luis.newButton("Back", 6, 2, function() self:showMainMenu() end, nil, 1, 1)
    
    buttonContainer:addChild(loadButton)
    buttonContainer:addChild(deleteButton)
    buttonContainer:addChild(backButton)
    mainContainer:addChild(buttonContainer)
    
    -- Store references for later use
    self.loadGameUI = {
        mainContainer = mainContainer,
        profileContainer = profileContainer,
        loadButton = loadButton,
        deleteButton = deleteButton,
        backButton = backButton
    }
end

function mainMenu:createOptionsUI()
    -- Create FlexContainer for options interface
    local mainContainer = luis.createElement("optionsLayer", "FlexContainer", 30, 16, 3, 6, nil, "OptionsMain")
    
    -- Music volume section
    local musicContainer = luis.newFlexContainer(28, 3, 1, 1, nil, "MusicVolume")
    local musicLabel = luis.newLabel("Music Volume", 10, 1, 1, 1, "left")
    local musicSlider = luis.newSlider(0, 100, GAME.settings.sound.musicVolume * 100, 15, 2, 
        function(value) GAME.settings.sound.musicVolume = value / 100 end, 1, 1)
    musicContainer:addChild(musicLabel)
    musicContainer:addChild(musicSlider)
    mainContainer:addChild(musicContainer)
    
    -- SFX volume section
    local sfxContainer = luis.newFlexContainer(28, 3, 1, 1, nil, "SFXVolume")
    local sfxLabel = luis.newLabel("SFX Volume", 10, 1, 1, 1, "left")
    local sfxSlider = luis.newSlider(0, 100, GAME.settings.sound.sfxVolume * 100, 15, 2, 
        function(value) GAME.settings.sound.sfxVolume = value / 100 end, 1, 1)
    sfxContainer:addChild(sfxLabel)
    sfxContainer:addChild(sfxSlider)
    mainContainer:addChild(sfxContainer)
    
    -- Fullscreen toggle section
    local fullscreenContainer = luis.newFlexContainer(28, 3, 1, 1, nil, "Fullscreen")
    local fullscreenLabel = luis.newLabel("Fullscreen", 10, 1, 1, 1, "left")
    local fullscreenSwitch = luis.newSwitch(GAME.settings.graphics.fullscreen, 4, 2,
        function(value) 
            GAME.settings.graphics.fullscreen = value
            love.window.setFullscreen(value)
        end, 1, 1)
    fullscreenContainer:addChild(fullscreenLabel)
    fullscreenContainer:addChild(fullscreenSwitch)
    mainContainer:addChild(fullscreenContainer)
    
    -- Button section
    local buttonContainer = luis.newFlexContainer(28, 4, 1, 1, nil, "OptionsButtons")
    local saveSettingsButton = luis.newButton("Save Settings", 8, 2, function() self:saveSettings() end, nil, 1, 1)
    local backButton = luis.newButton("Back", 6, 2, function() self:showMainMenu() end, nil, 1, 1)
    buttonContainer:addChild(saveSettingsButton)
    buttonContainer:addChild(backButton)
    mainContainer:addChild(buttonContainer)
    
    -- Store references
    self.optionsUI = {
        mainContainer = mainContainer,
        musicSlider = musicSlider,
        sfxSlider = sfxSlider,
        fullscreenSwitch = fullscreenSwitch,
        saveSettingsButton = saveSettingsButton,
        backButton = backButton
    }
end

function mainMenu:createAboutUI()
    -- Create simple about screen
    local mainContainer = luis.createElement("aboutLayer", "FlexContainer", 30, 16, 3, 6, nil, "AboutMain")
    
    -- About text (simplified)
    local aboutText = luis.newLabel("Lunarium v" .. GAME.version .. "\nA classic dungeon crawler", 28, 10, 1, 1, "center")
    local backButton = luis.newButton("Back", 6, 2, function() self:showMainMenu() end, nil, 1, 1)
    
    mainContainer:addChild(aboutText)
    mainContainer:addChild(backButton)
    
    self.aboutUI = {
        mainContainer = mainContainer,
        aboutText = aboutText,
        backButton = backButton
    }
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
end

function mainMenu:update(dt)
    -- LUIS handles all UI updates automatically
    -- Just update any custom logic here if needed
end

function mainMenu:draw()
    -- Draw background
    if self.backgroundImage then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.backgroundImage, 0, 0, 0, GAME.width / self.backgroundImage:getWidth(), GAME.height / self.backgroundImage:getHeight())
    else
        love.graphics.clear(screenManager.colors.background)
    end
    
    -- Draw game title (custom drawing over LUIS)
    love.graphics.setFont(screenManager.fonts.title)
    love.graphics.setColor(screenManager.colors.title)
    local titleText = "Lunarium"
    local titleWidth = screenManager.fonts.title:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 50)
    
    -- Draw version
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("v" .. GAME.version, 10, GAME.height - 20)
    
    -- LUIS handles all UI rendering automatically via main.lua
end

function mainMenu:showMainMenu()
    self.state = "main"
    luis.disableLayer("loadGameLayer")
    luis.disableLayer("optionsLayer")
    luis.disableLayer("aboutLayer")
    luis.enableLayer("mainMenuLayer")
end

function mainMenu:showLoadGame()
    self.state = "load"
    luis.disableLayer("mainMenuLayer")
    luis.disableLayer("optionsLayer")
    luis.disableLayer("aboutLayer")
    luis.enableLayer("loadGameLayer")
    self:loadSaveProfiles()
end

function mainMenu:showOptions()
    self.state = "options"
    luis.disableLayer("mainMenuLayer")
    luis.disableLayer("loadGameLayer")
    luis.disableLayer("aboutLayer")
    luis.enableLayer("optionsLayer")
end

function mainMenu:showAbout()
    self.state = "about"
    luis.disableLayer("mainMenuLayer")
    luis.disableLayer("loadGameLayer")
    luis.disableLayer("optionsLayer")
    luis.enableLayer("aboutLayer")
end

function mainMenu:loadSaveProfiles()
    -- Load save profiles
    self.saveProfiles = saveLoad:listSaveProfiles()
    self.selectedProfile = nil
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
        -- Apply loaded game data using the new function
        saveLoad:applyLoadedData(gameData)
        
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

-- LUIS handles all input events automatically
-- No need for manual mouse handling

return mainMenu
