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
    },
    -- Added missing effects
    ["barrier"] = {
        name = "Barrier",
        description = "Absorbs damage until depleted",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is protected by a barrier!",
                value = 0,
                color = {0.3, 0.7, 0.9}
            }
        end
    },
    ["taunt"] = {
        name = "Taunt",
        description = "Forces enemies to target this character",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "negative", -- negative for enemies, but can be positive for tanks
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is taunted!",
                value = 0,
                color = {0.9, 0.6, 0.2}
            }
        end
    },
    ["untargetable"] = {
        name = "Untargetable",
        description = "Cannot be targeted by enemy attacks",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " cannot be targeted!",
                value = 0,
                color = {0.6, 0.8, 0.9}
            }
        end
    },
    ["attack_multiplier"] = {
        name = "Attack Boost",
        description = "Increases attack power",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " has increased attack power!",
                value = 0,
                color = {0.9, 0.5, 0.3}
            }
        end
    },
    ["defense_multiplier"] = {
        name = "Defense Boost",
        description = "Increases defense",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " has increased defense!",
                value = 0,
                color = {0.5, 0.7, 0.4}
            }
        end
    },
    ["speed_multiplier"] = {
        name = "Speed Modifier",
        description = "Modifies speed (above 1 is faster, below 1 is slower)",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = function(value) return value > 1 and "positive" or "negative" end,
        onTurnStart = function(entity, strength, multiplier)
            local statusType = multiplier > 1 and "increased" or "decreased"
            return {
                message = entity.name .. " has " .. statusType .. " speed!",
                value = 0,
                color = multiplier > 1 and {0.4, 0.8, 0.6} or {0.8, 0.4, 0.4}
            }
        end
    },
    ["elementalPower"] = {
        name = "Elemental Power",
        description = "Increases damage of elemental attacks",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " has increased elemental power!",
                value = 0,
                color = {0.7, 0.4, 0.9}
            }
        end
    },
    ["elementalResist"] = {
        name = "Elemental Resistance",
        description = "Reduces damage from elemental attacks",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " has increased elemental resistance!",
                value = 0,
                color = {0.5, 0.3, 0.8}
            }
        end
    },
    ["accuracy_multiplier"] = {
        name = "Accuracy Modifier",
        description = "Modifies accuracy of attacks",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = function(value) return value > 1 and "positive" or "negative" end,
        onTurnStart = function(entity, strength, multiplier)
            local statusType = multiplier > 1 and "increased" or "decreased"
            return {
                message = entity.name .. " has " .. statusType .. " accuracy!",
                value = 0,
                color = multiplier > 1 and {0.6, 0.8, 0.3} or {0.8, 0.3, 0.3}
            }
        end
    },
    ["lifeDrain"] = {
        name = "Life Drain",
        description = "Heals for a portion of damage dealt",
        icon = "assets/Icons/StatusEffects/poison.png", -- Placeholder
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " has life drain!",
                value = 0,
                color = {0.8, 0.2, 0.5}
            }
        end
    }
}

-- Apply a status effect to an entity
-- @param effectType: string - The name of the effect to apply
-- @param entity: table - The entity to receive the effect
-- @param duration: number - How many turns the effect lasts
-- @param strength: number - The potency of the effect (for flat values)
-- @param multiplier: number - The multiplier value (for multiplicative effects)
-- @param chance: number - The chance for the effect to apply (0-1)
function statusEffects:apply(effectType, entity, duration, strength, multiplier, chance)
    -- Initialize the status table if needed
    if not entity.status then
        entity.status = {}
    end
    
    -- Check if the effect exists
    if not self.effects[effectType] then
        return false, "Status effect type does not exist"
    end
    
    -- Apply chance roll if specified
    if chance and chance < 1 then
        if math.random() > chance then
            return false, "Failed chance roll"
        end
    end
    
    -- Set default values
    duration = duration or 3
    strength = strength or 1
    multiplier = multiplier or 1
    
    -- Check if the effect is already applied
    if entity.status[effectType] then
        -- Initialize strength if not present
        if entity.status[effectType].strength == nil then
            entity.status[effectType].strength = 0
        end
        
        -- Barrier is special - refresh to the new value if higher
        if effectType == "barrier" then
            if strength > entity.status[effectType].strength then
                entity.status[effectType].strength = strength
            end
            -- Always refresh the duration
            entity.status[effectType].duration = duration
        else
            -- For other effects, extend the duration if it would be longer
            entity.status[effectType].duration = math.max(
                entity.status[effectType].duration,
                duration
            )
            -- Increase the strength for flat effects
            if strength > 1 then
                entity.status[effectType].strength = entity.status[effectType].strength + strength
            end
            -- Set multiplier (overwrite, don't stack)
            if multiplier ~= 1 then
                entity.status[effectType].multiplier = multiplier
            end
        end
    else
        -- Apply the new effect
        entity.status[effectType] = {
            duration = duration,
            strength = strength
        }
        
        -- Add multiplier if provided
        if multiplier ~= 1 then
            entity.status[effectType].multiplier = multiplier
        end
    end
    
    return true, "Status effect applied successfully"
end

-- Remove a status effect from an entity
-- @param effectType: string - The name of the effect to remove
-- @param entity: table - The entity to remove the effect from
function statusEffects:remove(effectType, entity)
    if not entity or not entity.status or not entity.status[effectType] then
        return false, "Effect doesn't exist on entity"
    end
    
    entity.status[effectType] = nil
    return true, "Status effect removed successfully"
end

-- Check if an entity has a status effect
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect to check for
-- @return boolean - Whether the entity has the effect
function statusEffects:has(entity, effectType)
    return entity and 
           entity.status and 
           entity.status[effectType] ~= nil
end

-- Get the flat value of a status effect
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect to get
-- @return number - The strength/value of the effect, or 0 if not present
function statusEffects:getValue(entity, effectType)
    if not self:has(entity, effectType) then
        return 0
    end
    
    return entity.status[effectType].strength or 0
end

-- Get the multiplier value of a status effect
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect to get
-- @return number - The multiplier of the effect, or 1 if not present
function statusEffects:getMultiplier(entity, effectType)
    if not self:has(entity, effectType) then
        return 1
    end
    
    return entity.status[effectType].multiplier or 1
end

-- Get the remaining duration of a status effect
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect to get
-- @return number - The remaining duration of the effect, or 0 if not present
function statusEffects:getDuration(entity, effectType)
    if not self:has(entity, effectType) then
        return 0
    end
    
    return entity.status[effectType].duration or 0
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
            local result = self.effects[effectType].onTurnStart(entity, effect.strength, effect.multiplier)
            if result then
                table.insert(updates, result)
                
                -- If this is a damaging effect, apply damage
                if result.value and result.value > 0 then
                    -- Check for barrier first
                    local barrierAbsorbed = 0
                    if entity.status["barrier"] then
                        barrierAbsorbed = math.min(result.value, entity.status["barrier"].strength)
                        entity.status["barrier"].strength = entity.status["barrier"].strength - barrierAbsorbed
                        
                        -- Add barrier absorption message
                        if barrierAbsorbed > 0 then
                            table.insert(updates, {
                                message = entity.name .. "'s barrier absorbs " .. barrierAbsorbed .. " damage!",
                                value = 0,
                                color = {0.3, 0.7, 0.9}
                            })
                        end
                        
                        -- Remove barrier if depleted
                        if entity.status["barrier"].strength <= 0 then
                            self:remove("barrier", entity)
                            table.insert(updates, {
                                message = entity.name .. "'s barrier has broken!",
                                value = 0,
                                color = {0.7, 0.3, 0.9}
                            })
                        end
                    end
                    
                    -- Apply remaining damage to HP
                    local remainingDamage = result.value - barrierAbsorbed
                    if remainingDamage > 0 then
                        entity.currentHP = math.max(0, entity.currentHP - remainingDamage)
                        
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