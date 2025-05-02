-- Main entry point for the game
local gameState = require("states/gameState")
local screens = require("screens/screenManager")
local assets = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")

-- Global game configuration
GAME = {
    width = 1280,
    height = 720,
    title = "Dungeon Crawler",
    version = "0.1",
    debug = false,
    currentState = nil,
    prevState = nil
}

-- In main.lua, add this after GAME is defined but before other initializations
GAME.settings = {
    sound = {
        musicVolume = 0.5,
        sfxVolume = 0.7,
        masterVolume = 0.8
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

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Initialize systems
    assets:init()
    screens:init()
    gameState:init()
    
    -- Set the initial game state to main menu
    gameState:changeState("mainMenu")
end

function love.update(dt)
    -- Update current screen
    if GAME.currentState then
        GAME.currentState:update(dt)
    end
end

function love.draw()
    -- Draw current screen
    if GAME.currentState then
        GAME.currentState:draw()
    end
    
    -- Draw debug info if enabled
    if GAME.debug then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.print("State: " .. gameState:getCurrentStateName(), 10, 30)
    end
end

function love.keypressed(key, scancode, isrepeat)
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
    -- Pass text input to current state
    if GAME.currentState and GAME.currentState.textinput then
        GAME.currentState:textinput(text)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
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
    -- Pass mouse release to current state
    if GAME.currentState and GAME.currentState.mousereleased then
        GAME.currentState:mousereleased(x, y, button, istouch, presses)
        
        if GAME.debug then
            print("Mouse released at " .. x .. "," .. y)
        end
    end
end

function love.wheelmoved(dx, dy)
    -- Pass mouse wheel movement to current state
    if GAME.currentState and GAME.currentState.wheelmoved then
        local handled = GAME.currentState:wheelmoved(dx, dy)
        
        if GAME.debug then
            if handled then
                print("Wheel moved: dx=" .. dx .. ", dy=" .. dy .. ", Handled by: " .. gameState:getCurrentStateName())
            else
                print("Wheel moved: dx=" .. dx .. ", dy=" .. dy .. ", Not Handled")
            end
        end
    end
end

function love.keyreleased(key)
    if key == "f1" then
        -- Toggle debug mode
        GAME.debug = not GAME.debug
        print("Debug mode: " .. (GAME.debug and "ON" or "OFF"))
    end
    
    -- Pass key release to current state
    if GAME.currentState and GAME.currentState.keyreleased then
        GAME.currentState:keyreleased(key)
    end
end

function love.quit()
    -- Handle game cleanup
    saveLoad:saveGameSettings()
    return false
end

function love.resize(width, height)
    -- Update game settings for resolution
    GAME.settings.graphics.resolution = width .. "x" .. height
    
    -- Tell the screen manager to handle the resize
    screens:handleResize(width, height)
end
