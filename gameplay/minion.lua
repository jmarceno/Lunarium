-- Minion System
-- Handles summoned entities (undead, elementals, spirits)

local minion = {}

-- Minion types
minion.TYPES = {
    UNDEAD = "undead",       -- Persist across battles until duration expires or player exits dungeon
    ELEMENTAL = "elemental", -- Last until end of current battle
    SPIRIT = "spirit"        -- Provide passive buffs without taking combat actions
}

-- Base minion structure
function minion:createMinion(name, type, level, stats, duration, owner)
    local newMinion = {
        name = name,
        type = type,
        level = level or 1,
        owner = owner, -- Reference to the summoner
        
        -- Stats
        maxHP = stats.maxHP or 50,
        currentHP = stats.maxHP or 50,
        attackPower = stats.attackPower or 10,
        defense = stats.defense or 5,
        magicPower = stats.magicPower or 0,
        magicDefense = stats.magicDefense or 0,
        speed = stats.speed or 5,
        
        -- Combat status
        active = true,
        status = {},
        
        -- Duration
        duration = duration or 0, -- 0 means permanent until defeated (for elementals)
        battleStart = nil, -- Timestamp for when this minion was created
        
        -- Visual
        sprite = stats.sprite,
        color = stats.color or {0.7, 0.7, 0.7},
        
        -- Type-specific properties
        abilities = stats.abilities or {},
        passiveBuffs = stats.passiveBuffs or {}
    }
    
    -- Setup type-specific behaviors
    if type == minion.TYPES.UNDEAD then
        -- Undead minions persist but have a duration
        newMinion.takesActions = true
        newMinion.persistAcrossBattles = true
    elseif type == minion.TYPES.ELEMENTAL then
        -- Elementals expire at the end of battle
        newMinion.persistAcrossBattles = false
    elseif type == minion.TYPES.SPIRIT then
        -- Spirits provide passive buffs but don't take combat actions
        newMinion.takesActions = false
        -- Apply passive buffs to owner
        if owner then
            for stat, value in pairs(newMinion.passiveBuffs) do
                -- Note: This will be handled by the combat system during battle 
            end
        end
    else
        -- Default combat minion
        newMinion.takesActions = true
        newMinion.persistAcrossBattles = false
    end
    
    return newMinion
end

-- Update minion duration on dungeon tick
function minion:updateDuration(minionInstance, timeElapsed)
    if minionInstance.duration > 0 then
        minionInstance.duration = minionInstance.duration - timeElapsed
        
        -- Check if expired
        if minionInstance.duration <= 0 then
            minionInstance.active = false
            return true -- Indicates minion expired
        end
    end
    
    return false -- Minion still active
end

-- Get minion attributes that scale with summoner's stats
function minion:scaleWithSummoner(minionInstance)
    local owner = minionInstance.owner
    if not owner then return minionInstance end
    
    local multiplier = 1 + (minionInstance.level * 0.1) -- 10% increase per level
    
    if minionInstance.type == minion.TYPES.UNDEAD then
        -- Undead scale with INT and WIL
        minionInstance.maxHP = 30 + (owner.attributes.WIL * 3 * multiplier)
        minionInstance.attackPower = 5 + (owner.attributes.INT * multiplier)
    elseif minionInstance.type == minion.TYPES.ELEMENTAL then
        -- Elementals scale with INT 
        minionInstance.maxHP = 20 + (owner.attributes.INT * 2 * multiplier)
        minionInstance.attackPower = 8 + (owner.attributes.INT * 1.5 * multiplier)
        minionInstance.magicPower = 10 + (owner.attributes.INT * 2 * multiplier)
    elseif minionInstance.type == minion.TYPES.SPIRIT then
        -- Spirits scale with WIS
        -- For spirits, passiveBuffs are more important than stats
        for stat, value in pairs(minionInstance.passiveBuffs) do
            minionInstance.passiveBuffs[stat] = value * (1 + (owner.attributes.WIS * 0.02 * multiplier))
        end
    end
    
    -- Ensure current HP is updated if max HP changed
    minionInstance.currentHP = minionInstance.maxHP
    
    return minionInstance
end

return minion 