-- Game state management
local gameState = {
    states = {},
    currentState = nil,
    currentStateName = ""
}

function gameState:init()
    -- Load all game states
    self.states = {
        mainMenu = require("screens/mainMenu"),
        characterCreator = require("screens/characterCreator"),
        overworld = require("screens/overworld"),
        dungeon = require("screens/dungeon"),
        tavern = require("screens/tavern"),
        guild = require("screens/guild"),
        shop = require("screens/shop"),
        smith = require("screens/smith")
    }
    
    -- Initialize all states
    for name, state in pairs(self.states) do
        if state.init then
            state:init()
        end
    end
end

function gameState:changeState(stateName, params)
    -- Check if state exists
    if not self.states[stateName] then
        error("State '" .. stateName .. "' does not exist")
        return
    end
    
    -- Exit current state if it exists
    if self.currentState and self.currentState.exit then
        self.currentState:exit()
    end
    
    -- Store previous state
    GAME.prevState = self.currentState
    
    -- Change to new state
    self.currentStateName = stateName
    self.currentState = self.states[stateName]
    GAME.currentState = self.currentState
    
    -- Enter new state
    if self.currentState.enter then
        self.currentState:enter(params)
    end
end

function gameState:getCurrentStateName()
    return self.currentStateName
end

function gameState:getPreviousState()
    return GAME.prevState
end

function gameState:returnToPreviousState(params)
    if GAME.prevState then
        local prevStateName = ""
        
        -- Find name of previous state
        for name, state in pairs(self.states) do
            if state == GAME.prevState then
                prevStateName = name
                break
            end
        end
        
        if prevStateName ~= "" then
            self:changeState(prevStateName, params)
        end
    end
end

return gameState
