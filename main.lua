-- Main entry point for the game
local gameState = require("states/gameState")
local screens = require("screens/screenManager")
local assets = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")
local debugConsole = require("utils/debugConsole")

-- Initialize LUIS properly
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets") -- Point to the correct widgets directory

-- Make luis globally accessible
_G.luis = luis

-- Global game configuration
GAME = {
    width = 1280,
    height = 720,
    title = "Lunarium - A Simple Clasic Dungeon Crawler",
    version = "0.1",
    debug = false,
    showFPS = false,
    currentState = nil,
    prevState = nil,
    
    -- Set game volume settings
    setVolume = function(musicVolume, soundVolume, masterVolume)
        local assetManager = require("assets/assetManager")
        if masterVolume then
            assetManager:setMasterVolume(masterVolume)
        end
        if musicVolume then
            assetManager:setMusicVolume(musicVolume)
        end
        if soundVolume then
            assetManager.audioSettings.soundVolume = soundVolume
        end
    end
}

-- In main.lua, add this after GAME is defined but before other initializations
GAME.settings = {
    sound = {
        musicVolume = 0.3,
        sfxVolume = 0.5,
        masterVolume = 0.3
    },
    graphics = {
        fullscreen = false,
        texturesEnabled = false,
        resolution = "1280x720"
    },
    gameplay = {
        difficultyLevel = 2,
        autoSave = true
    },
    controls = {
        moveForward = "w",
        moveBackward = "s",
        turnLeft = "a",
        turnRight = "d",
        strafeLeft = "q",
        strafeRight = "e",
        attack = "space",
        useItem = "r",
        openMenu = "tab"
    }
}

-- Loading state flag
local isLoading = true
local loadingFont = nil
local loadingMessage = "Loading Data and Preparing Shaders..."
local loadingStartTime = 0
local minLoadingTime = 1.5 -- Minimum time to show loading screen in seconds

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter('nearest', 'nearest')
    
    -- LUIS Initialization
    luis.initJoysticks()
    luis.baseWidth = GAME.width
    luis.baseHeight = GAME.height
    love.window.setMode(luis.baseWidth, luis.baseHeight, { resizable=true })
    luis.setGridSize(32) -- Default grid size
    luis.updateScale()

    -- Setup loading font before any other initialization
    loadingFont = love.graphics.newFont(24)
    loadingStartTime = love.timer.getTime()
    
    -- Defer the rest of initialization to the update cycle
end

function love.update(dt)
    -- Handle loading sequence
    if isLoading then
        -- Calculate time elapsed since loading started
        local currentTime = love.timer.getTime()
        local timeElapsed = currentTime - loadingStartTime
        
        -- If this is the first update after load, initialize everything
        if timeElapsed > 0.1 and not GAME.initialized then
            -- Initialize systems
            assets:init()
            screens:init()
            gameState:init()
            
            assets:setButtonSoundVolume(0.1) 
            
            -- Initialize minion system
            local minionManager = require("gameplay/minionManager")
            minionManager:init()
            
            -- Initialize out-of-combat effects system
            local outOfCombatEffects = require("gameplay/outOfCombatEffects")
            
            -- Initialize debug console
            debugConsole:init()
            
            -- Save/load system
            if love.filesystem.getInfo("savefile.dat") then
                print("Loading save data...")
                GAME:loadGame()
                
                -- Load minion data
                minionManager:load()
            end

            -- Set initial volume
            GAME.setVolume(0.2)
            
            -- Set the initial game state to main menu
            gameState:changeState("mainMenu")
            
            GAME.initialized = true
        end
        
        -- Only finish loading after minimum time has passed AND initialization is done
        if timeElapsed >= minLoadingTime and GAME.initialized then
            isLoading = false
        end
        
        return
    end
    
    luis.update(dt) -- Added LUIS update
    luis.updateScale() -- Added LUIS scale update

    -- Update debug console
    debugConsole:update(dt)
    
    -- Update out-of-combat effects (status and buffs)
    local outOfCombatEffects = require("gameplay/outOfCombatEffects")
    outOfCombatEffects:update(dt)
    
    -- Update current screen
    if GAME.currentState then
        GAME.currentState:update(dt)
    end
end

function love.draw()
    -- Draw loading screen
    if isLoading then
        love.graphics.clear(0.1, 0.1, 0.1)
        love.graphics.setFont(loadingFont)
        
        -- Get window dimensions directly from LÖVE
        local windowWidth, windowHeight = love.graphics.getDimensions()
        local textWidth = loadingFont:getWidth(loadingMessage)
        local textHeight = loadingFont:getHeight()
        
        -- Set text color to white
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
            loadingMessage,
            (windowWidth - textWidth) / 2,
            (windowHeight - textHeight) / 2
        )
        return
    end
    
    -- Draw current screen
    if GAME.currentState then
        GAME.currentState:draw()
    end
    
    luis.draw() -- Added LUIS draw

    -- Draw debug info if enabled
    if GAME.debug then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.print("State: " .. gameState:getCurrentStateName(), 10, 30)
    elseif GAME.showFPS then
        -- Just show FPS if showFPS is enabled without full debug mode
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    end
    
    -- Draw debug console on top of everything else
    debugConsole:draw()
end

function love.keypressed(key, scancode, isrepeat)
    -- Check if debug console is active
    if debugConsole.visible then
        -- Pass key presses to console
        debugConsole.inputField:keyPressed(key)
        return -- Stop processing other input when console is active
    end
    
    if luis.keypressed(key, scancode, isrepeat) then return end -- Added LUIS keypressed

    -- Toggle debug console with tilde key
    if key == "f3" then
        debugConsole:toggle()
        return
    end
    
    -- Handle key presses
    if key == "escape" then
        -- Handle escape key based on current state
        if gameState:getCurrentStateName() == "mainMenu" then
            love.event.quit()
        elseif gameState:getCurrentStateName() == "characterCreator" then
            gameState:changeState("mainMenu")
        end
    elseif key == "f1" then
        -- Toggle debug mode
        GAME.debug = not GAME.debug
    end
    
    -- Pass key press to current state
    if GAME.currentState and GAME.currentState.keypressed then
        GAME.currentState:keypressed(key, scancode, isrepeat)
    end
end

function love.textinput(text)
    -- Pass text input to console if visible
    if debugConsole.visible then
        debugConsole.inputField:textInput(text)
        return
    end
    
    if luis.textinput(text) then return end -- Added LUIS textinput

    -- Pass text input to current state
    if GAME.currentState and GAME.currentState.textinput then
        GAME.currentState:textinput(text)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if luis.mousepressed(x, y, button, istouch, presses) then return end -- Added LUIS mousepressed

    -- Pass mouse press to current state
    if GAME.currentState and GAME.currentState.mousepressed then
        local handled = GAME.currentState:mousepressed(x, y, button, istouch, presses)
        if GAME.debug then
            if handled then
                print("Click handled by: " .. gameState:getCurrentStateName() .. " at " .. x .. "," .. y)
            else
                print("Click not handled at " .. x .. "," .. y)
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if luis.mousereleased(x, y, button, istouch, presses) then return end -- Added LUIS mousereleased

    -- Pass mouse release to current state
    if GAME.currentState and GAME.currentState.mousereleased then
        GAME.currentState:mousereleased(x, y, button, istouch, presses)
        
        if GAME.debug then
            print("Mouse released at " .. x .. "," .. y)
        end
    end
end

function love.wheelmoved(x, y)
    if luis.wheelmoved(x, y) then return end
    if GAME.currentState and GAME.currentState.wheelmoved then
        GAME.currentState:wheelmoved(x, y)
    end
end

function love.keyreleased(key)
    if luis.keyreleased then luis.keyreleased(key) end
    -- Pass key release to current state
    if GAME.currentState and GAME.currentState.keyreleased then
        GAME.currentState:keyreleased(key)
    end
end

function love.quit()
    -- Handle game cleanup
    saveLoad:saveGameSettings()
    
    -- Save game data
    --GAME:saveGame()
    
    -- Save minion data
    --local minionManager = require("gameplay/minionManager")
    --minionManager:save()
    
    return false
end

function love.resize(width, height)
    -- Update game settings for resolution
    GAME.settings.graphics.resolution = width .. "x" .. height
    
    -- Update debug console dimensions
    debugConsole:updateDimensions()
    
    -- Tell the screen manager to handle the resize
    screens:handleResize(width, height)
end

function love.joystickadded(joystick)
    luis.initJoysticks()
end

function love.joystickremoved(joystick)
    luis.removeJoystick(joystick)
end

function love.gamepadpressed(joystick, button)
    luis.gamepadpressed(joystick, button)
    if GAME.currentState and GAME.currentState.gamepadpressed then
        GAME.currentState:gamepadpressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    luis.gamepadreleased(joystick, button)
    if GAME.currentState and GAME.currentState.gamepadreleased then
        GAME.currentState:gamepadreleased(joystick, button)
    end
end
