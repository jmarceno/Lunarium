local statusEffects = {}

-- Define all status effects with their properties
statusEffects.effects = {
    ["poison"] = {
        name = "Poison",
        description = "Takes damage at the start of each turn",
        icon = "assets/Icons/StatusEffects/poison.png",
        iconSize = 24,
        statusType = "negative",
        onTurnStart = function(entity, strength)
            local damage = strength * 3 -- Poison damage is 3 per stack per turn
            return {
                message = entity.name .. " takes " .. damage .. " poison damage!",
                value = damage,
                color = {0.4, 0.8, 0.4}
            }
        end
    },
    ["burn"] = {
        name = "Burn",
        description = "Takes fire damage at the start of each turn",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "negative",
        onTurnStart = function(entity, strength)
            local damage = strength * 4 -- Burn damage is 4 per stack per turn
            return {
                message = entity.name .. " takes " .. damage .. " burn damage!",
                value = damage,
                color = {0.9, 0.4, 0.1}
            }
        end
    },
    ["bleed"] = {
        name = "Bleed",
        description = "Takes physical damage at the start of each turn",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "negative",
        onTurnStart = function(entity, strength)
            local damage = strength * 3 -- Bleed damage is 3 per stack per turn
            return {
                message = entity.name .. " takes " .. damage .. " bleed damage!",
                value = damage,
                color = {0.9, 0.1, 0.1}
            }
        end
    },
    ["stun"] = {
        name = "Stun",
        description = "Cannot take actions",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "negative",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is stunned and cannot act!",
                value = 0,
                color = {0.8, 0.8, 0.2}
            }
        end
    },
    ["vulnerable"] = {
        name = "Vulnerable",
        description = "Takes 25% more damage",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "negative",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is vulnerable to attacks!",
                value = 0,
                color = {0.8, 0.4, 0.4}
            }
        end
    },
    ["strengthen"] = {
        name = "Strengthen",
        description = "Deals 25% more damage",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is strengthened!",
                value = 0,
                color = {0.4, 0.6, 0.9}
            }
        end
    },
    ["protect"] = {
        name = "Protect",
        description = "Takes 25% less damage",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is protected!",
                value = 0,
                color = {0.5, 0.8, 0.5}
            }
        end
    },
    ["silence"] = {
        name = "Silence",
        description = "Cannot use magical abilities",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "negative",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is silenced and cannot use magic!",
                value = 0,
                color = {0.6, 0.6, 0.8}
            }
        end
    }
}

-- Apply a status effect to an entity
-- @param effectType: string - The name of the effect to apply
-- @param entity: table - The entity to receive the effect
-- @param duration: number - How many turns the effect lasts
-- @param strength: number - The potency of the effect
function statusEffects:apply(effectType, entity, duration, strength)
    -- Initialize the status table if needed
    if not entity.status then
        entity.status = {}
    end
    
    -- Check if the effect exists
    if not self.effects[effectType] then
        return false, "Status effect type does not exist"
    end
    
    -- Set default duration and strength
    duration = duration or 3
    strength = strength or 1
    
    -- Check if the effect is already applied
    if entity.status[effectType] then
        -- Extend the duration if it would be longer
        entity.status[effectType].duration = math.max(
            entity.status[effectType].duration,
            duration
        )
        -- Increase the strength
        entity.status[effectType].strength = entity.status[effectType].strength + strength
    else
        -- Apply the new effect
        entity.status[effectType] = {
            duration = duration,
            strength = strength
        }
    end
    
    return true, "Status effect applied successfully"
end

-- Process status effects that trigger at turn start
-- @param entity: table - The entity whose effects to process
-- @return updates: table - A list of effect updates with messages
function statusEffects:processTurnStart(entity)
    if not entity or not entity.status then
        return {}
    end
    
    local updates = {}
    
    for effectType, effect in pairs(entity.status) do
        if self.effects[effectType] and self.effects[effectType].onTurnStart then
            -- Execute the turn start function for this effect
            local result = self.effects[effectType].onTurnStart(entity, effect.strength)
            if result then
                table.insert(updates, result)
                
                -- If this is a damaging effect, apply damage
                if result.value and result.value > 0 then
                    entity.currentHP = math.max(0, entity.currentHP - result.value)
                    
                    -- Check if entity is defeated by the status effect
                    if entity.currentHP <= 0 then
                        entity.active = false
                        table.insert(updates, {
                            message = entity.name .. " is defeated!",
                            value = 0,
                            color = {1, 0, 0}
                        })
                    end
                end
            end
        end
    end
    
    return updates
end

-- Process status effects at turn end (decrease duration, remove expired)
-- @param entity: table - The entity whose effects to process
-- @return expired: table - A list of effects that expired this turn
function statusEffects:processTurnEnd(entity)
    if not entity or not entity.status then
        return {}
    end
    
    local expired = {}
    
    for effectType, effect in pairs(entity.status) do
        -- Decrease the duration
        effect.duration = effect.duration - 1
        
        -- Check if the effect has expired
        if effect.duration <= 0 then
            entity.status[effectType] = nil
            table.insert(expired, {
                type = effectType,
                message = entity.name .. " is no longer " .. self.effects[effectType].name,
                color = {0.7, 0.7, 0.7}
            })
        end
    end
    
    return expired
end

return statusEffects 