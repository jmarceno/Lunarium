-- Minion Manager
-- Manages summoned entities, their persistence and lifecycle

local minion = require("gameplay/minion")

local minionManager = {
    activeSummons = {}, -- Store active summons per character
    minionSlotsPerCharacter = 3, -- Maximum number of active summons per character
}

-- Initialize the minion manager
function minionManager:init()
    -- Initialize active summons table
    self.activeSummons = {}
    
    -- Ensure GAME.savefile.minions exists (for save/load)
    if GAME and GAME.savefile and not GAME.savefile.minions then
        GAME.savefile.minions = {}
    end
    
    return self
end

-- Add a new minion for a character
function minionManager:summonMinion(character, minionType, minionName, stats, duration)
    -- Initialize character's minion slot if not exists
    if not self.activeSummons[character.name] then
        self.activeSummons[character.name] = {}
    end
    
    -- Check if character has reached maximum summons
    if #self.activeSummons[character.name] >= self.minionSlotsPerCharacter then
        -- Replace oldest minion (or make a choice based on game logic)
        local oldestIdx = 1
        
        -- For spirits, replace same type if exists, otherwise replace oldest
        if minionType == minion.TYPES.SPIRIT then
            for i, m in ipairs(self.activeSummons[character.name]) do
                if m.type == minion.TYPES.SPIRIT then
                    oldestIdx = i
                    break
                end
            end
        end
        
        table.remove(self.activeSummons[character.name], oldestIdx)
    end
    
    -- Create new minion
    local newMinion = minion:createMinion(
        minionName,
        minionType,
        character.jobLevels[character.job] or 1, -- Use character's current job level
        stats,
        duration,
        character
    )
    
    -- Scale minion stats based on character
    newMinion = minion:scaleWithSummoner(newMinion)
    
    -- Save timestamp when the minion was created
    newMinion.battleStart = os.time()
    
    -- Add to active summons
    table.insert(self.activeSummons[character.name], newMinion)
    
    -- Return the created minion
    return newMinion
end

-- Get all active minions for a character
function minionManager:getActiveMinions(character)
    if not character or not character.name then
        return {}
    end
    
    return self.activeSummons[character.name] or {}
end

-- Remove an expired or defeated minion
function minionManager:removeMinion(character, minionIndex)
    if not character or not character.name or not self.activeSummons[character.name] then
        return false
    end
    
    if minionIndex > 0 and minionIndex <= #self.activeSummons[character.name] then
        table.remove(self.activeSummons[character.name], minionIndex)
        return true
    end
    
    return false
end

-- Clear all minions that don't persist across battles
function minionManager:clearNonPersistentMinions()
    for charName, minions in pairs(self.activeSummons) do
        -- Work through the minions in reverse to safely remove items
        for i = #minions, 1, -1 do
            if not minions[i].persistAcrossBattles then
                table.remove(minions, i)
            end
        end
    end
end

-- Update minion durations (call this during dungeon exploration)
function minionManager:updateDurations(timeElapsed)
    for charName, minions in pairs(self.activeSummons) do
        for i = #minions, 1, -1 do
            local expired = minion:updateDuration(minions[i], timeElapsed)
            if expired then
                table.remove(minions, i)
            end
        end
    end
end

-- Handle dungeon exit (clear undead minions)
function minionManager:onDungeonExit()
    print("minionManager: Clearing all minions when exiting dungeon")
    
    -- Count minions before clearing
    local totalMinions = 0
    for charName, minions in pairs(self.activeSummons) do
        totalMinions = totalMinions + #minions
    end
    
    print("minionManager: Removing " .. totalMinions .. " active minions")
    
    -- Clear all minions when exiting dungeon
    for charName, minions in pairs(self.activeSummons) do
        -- Print the character's minions being cleared
        if #minions > 0 then
            print("minionManager: Clearing " .. #minions .. " minions for character " .. charName)
        end
        
        -- Clear the minions
        self.activeSummons[charName] = {}
    end
    
    -- Verify all minions are gone
    local remainingMinions = 0
    for charName, minions in pairs(self.activeSummons) do
        remainingMinions = remainingMinions + #minions
    end
    
    if remainingMinions > 0 then
        print("WARNING: There are still " .. remainingMinions .. " minions after clearing!")
    else
        print("minionManager: All minions successfully cleared")
    end
end

-- Save minion data to game save
function minionManager:save()
    if not GAME or not GAME.savefile then return end
    
    GAME.savefile.minions = {}
    
    -- Copy minion data for save
    for charName, minions in pairs(self.activeSummons) do
        GAME.savefile.minions[charName] = {}
        
        for i, m in ipairs(minions) do
            table.insert(GAME.savefile.minions[charName], {
                name = m.name,
                type = m.type,
                level = m.level,
                maxHP = m.maxHP,
                currentHP = m.currentHP,
                attackPower = m.attackPower, 
                defense = m.defense,
                magicPower = m.magicPower,
                magicDefense = m.magicDefense,
                speed = m.speed,
                active = m.active,
                duration = m.duration,
                battleStart = m.battleStart,
                sprite = m.sprite, 
                color = m.color,
                abilities = m.abilities,
                passiveBuffs = m.passiveBuffs,
                persistAcrossBattles = m.persistAcrossBattles,
                takesActions = m.takesActions
            })
        end
    end
end

-- Load minion data from game save
function minionManager:load()
    if not GAME or not GAME.savefile or not GAME.savefile.minions then return end
    
    self.activeSummons = {}
    
    -- Restore minions from save data
    for charName, minions in pairs(GAME.savefile.minions) do
        self.activeSummons[charName] = {}
        
        for i, m in ipairs(minions) do
            -- We need to reconnect minions to their owners
            local ownerChar = nil
            for _, char in ipairs(GAME.party) do
                if char.name == charName then
                    ownerChar = char
                    break
                end
            end
            
            local loadedMinion = m
            loadedMinion.owner = ownerChar
            
            table.insert(self.activeSummons[charName], loadedMinion)
        end
    end
end

return minionManager 