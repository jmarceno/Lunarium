-- Out of Combat Effects Manager
-- Handles ticking of status effects outside of combat
local statusEffects = require("gameplay/statusEffects")

local outOfCombatEffects = {}

-- Initialize time tracking variables
outOfCombatEffects.lastUpdateTime = 0
outOfCombatEffects.accumulatedTime = 0 -- in seconds

-- Update function to be called from a main update loop
-- @param dt: number - Delta time in seconds
function outOfCombatEffects:update(dt)
    -- Skip if no game time is set up
    if not GAME.gameTime then return end
    
    -- Skip if in combat
    if GAME.inCombat then return end
    
    -- Accumulate time
    self.accumulatedTime = self.accumulatedTime + dt
    
    -- Process effects every 60 seconds of real time
    if self.accumulatedTime >= 60 then
        -- Add a minute to the game time
        GAME.gameTime = GAME.gameTime + 1
        
        -- Process party status effects
        if GAME.party then
            for _, character in ipairs(GAME.party) do
                self:processCharacterEffects(character)
            end
        end
        
        -- Reset accumulated time, keeping any remainder
        self.accumulatedTime = self.accumulatedTime - 60
    end
end

-- Process a character's status effects
-- @param character: table - The character to process
function outOfCombatEffects:processCharacterEffects(character)
    -- Skip inactive characters
    if not character.active then return end
    
    -- Process status effects
    if character.status then
        local expiredEffects = {}
        local uiFunctions = require("gameplay/combat/uiFunctions")
        
        -- Check each status effect
        for effectType, effect in pairs(character.status) do
            -- Decrease duration
            effect.duration = effect.duration - 1
            
            -- Check if expired
            if effect.duration <= 0 then
                table.insert(expiredEffects, effectType)
            end
        end
        
        -- Remove expired effects
        for _, effectType in ipairs(expiredEffects) do
            -- Get effect name with safety check
            local effectName = "Unknown"
            if statusEffects.effects[effectType] then
                effectName = statusEffects.effects[effectType].name
            else
                -- If we don't have a definition for this effect, use a formatted version of the effect type
                effectName = effectType:gsub("_", " "):gsub("^%l", string.upper)
                if GAME.debug then
                    print("WARNING: Missing effect definition for " .. effectType)
                end
            end
            
            -- Create message
            local message = character.name .. "'s " .. effectName .. " effect expired"
            local messageColor = {0.7, 0.7, 0.7}
            
            -- Show floating text
            local x = GAME.width / 2
            local y = GAME.height - 100
            
            -- Show the floating text
            -- Look for the dungeon screen's floatingTexts collection
            local floatingTexts = nil
            if GAME.currentState and GAME.currentState.floatingTexts then
                floatingTexts = GAME.currentState.floatingTexts
                uiFunctions.showFloatingText(message, x, y, messageColor, 2.0, floatingTexts)
            end
            
            -- Remove the effect
            character.status[effectType] = nil
            
            -- Debug output
            if GAME.debug then
                print(message)
            end
        end
    end
    
    -- Process temporary buffs
    if character.temporaryBuffs then
        local expiredBuffs = {}
        local uiFunctions = require("gameplay/combat/uiFunctions")
        
        -- Check each temporary buff
        for i, buff in ipairs(character.temporaryBuffs) do
            -- Check if buff has a duration
            if buff.duration then
                -- Calculate time elapsed in minutes
                local timeElapsed = 1 -- 1 minute per tick
                
                -- Decrease duration
                buff.duration = buff.duration - timeElapsed
                
                -- Check if expired
                if buff.duration <= 0 then
                    table.insert(expiredBuffs, i)
                end
            end
        end
        
        -- Remove expired buffs (in reverse order to maintain indices)
        for i = #expiredBuffs, 1, -1 do
            local buffIndex = expiredBuffs[i]
            local buff = character.temporaryBuffs[buffIndex]
            
            -- Create message for the buff
            local buffName = buff.stat or "Unknown"
            local message = character.name .. "'s " .. buffName .. " buff expired"
            local messageColor = {0.9, 0.7, 0.2}
            
            -- Show floating text
            local x = GAME.width / 2
            local y = GAME.height - 120 -- Slightly higher than status effects
            
            -- Display the floating text
            -- Look for the dungeon screen's floatingTexts collection
            local floatingTexts = nil
            if GAME.currentState and GAME.currentState.floatingTexts then
                floatingTexts = GAME.currentState.floatingTexts
                uiFunctions.showFloatingText(message, x, y, messageColor, 2.0, floatingTexts)
            end
            
            -- Remove the buff
            table.remove(character.temporaryBuffs, buffIndex)
            
            -- Debug output
            if GAME.debug then
                print(message)
            end
        end
    end
end

return outOfCombatEffects 