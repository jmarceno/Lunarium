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
        icon = "assets/Icons/StatusEffects/burn.png", -- Updated to a proper icon
        iconSize = 24,
        statusType = "negative",
        canSpread = true,
        spreadChance = 0.5,
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
        icon = "assets/Icons/StatusEffects/bleed.png", -- Updated to a proper icon
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
        icon = "assets/Icons/StatusEffects/stun.png", -- Updated to a proper icon
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
        icon = "assets/Icons/StatusEffects/vulnerable.png", -- Updated to a proper icon
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
        icon = "assets/Icons/StatusEffects/strengthen.png", -- Updated to a proper icon
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
        icon = "assets/Icons/StatusEffects/protect.png", -- Updated to a proper icon
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
        icon = "assets/Icons/StatusEffects/silence.png", -- Updated to a proper icon
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
    -- New effects
    ["barrier"] = {
        name = "Barrier",
        description = "Absorbs damage before it affects HP",
        icon = "assets/Icons/StatusEffects/barrier.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is protected by a barrier!",
                value = 0,
                color = {0.4, 0.7, 1.0}
            }
        end
    },
    ["taunt"] = {
        name = "Taunt",
        description = "Forces enemies to target this character",
        icon = "assets/Icons/StatusEffects/taunt.png",
        iconSize = 24,
        statusType = "special",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is taunting enemies!",
                value = 0,
                color = {1.0, 0.4, 0.4}
            }
        end
    },
    ["untargetable"] = {
        name = "Untargetable",
        description = "Cannot be targeted by enemies",
        icon = "assets/Icons/StatusEffects/untargetable.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " cannot be targeted!",
                value = 0,
                color = {0.7, 0.7, 0.9}
            }
        end
    },
    ["attack_multiplier"] = {
        name = "Attack Boost",
        description = "Increases attack power",
        icon = "assets/Icons/StatusEffects/attack_up.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength, multiplier)
            return {
                message = entity.name .. "'s attack is increased!",
                value = 0,
                color = {0.9, 0.5, 0.2}
            }
        end
    },
    ["defense_multiplier"] = {
        name = "Defense Boost",
        description = "Increases defense",
        icon = "assets/Icons/StatusEffects/defense_up.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength, multiplier)
            return {
                message = entity.name .. "'s defense is increased!",
                value = 0,
                color = {0.5, 0.8, 0.5}
            }
        end
    },
    ["speed_multiplier"] = {
        name = "Speed Boost",
        description = "Increases speed",
        icon = "assets/Icons/StatusEffects/speed_up.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength, multiplier)
            return {
                message = entity.name .. "'s speed is increased!",
                value = 0,
                color = {0.3, 0.8, 0.8}
            }
        end
    },
    ["accuracy_multiplier"] = {
        name = "Accuracy Boost",
        description = "Increases accuracy",
        icon = "assets/Icons/StatusEffects/accuracy_up.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength, multiplier)
            return {
                message = entity.name .. "'s accuracy is increased!",
                value = 0,
                color = {0.8, 0.8, 0.2}
            }
        end
    },
    ["elementalResist"] = {
        name = "Elemental Resist",
        description = "Increases resistance to elemental damage",
        icon = "assets/Icons/StatusEffects/elemental_resist.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength, element)
            local elementText = element and (" to " .. element) or ""
            return {
                message = entity.name .. "'s elemental resistance" .. elementText .. " is increased!",
                value = 0,
                color = {0.6, 0.6, 1.0}
            }
        end
    },
    ["elementalPower"] = {
        name = "Elemental Power",
        description = "Increases elemental damage",
        icon = "assets/Icons/StatusEffects/elemental_power.png",
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength, element)
            local elementText = element and (" for " .. element) or ""
            return {
                message = entity.name .. "'s elemental power" .. elementText .. " is increased!",
                value = 0,
                color = {1.0, 0.6, 0.6}
            }
        end
    },
    -- Add mana shield effect definition
    ["mana_shield"] = {
        name = "Mana Shield",
        description = "Converts a portion of incoming damage to mana loss",
        icon = "assets/Icons/StatusEffects/barrier.png", -- Temporary icon, replace with proper one when available
        iconSize = 24,
        statusType = "positive",
        onTurnStart = function(entity, strength)
            return {
                message = entity.name .. " is protected by a mana shield!",
                value = 0,
                color = {0.4, 0.4, 1.0}
            }
        end
    }
}

-- Apply a status effect to an entity
-- @param effectType: string - The name of the effect to apply
-- @param entity: table - The entity to receive the effect
-- @param duration: number - How many turns the effect lasts
-- @param strength: number - The potency of the effect
-- @param chance: number - Probability of applying the effect (0.0 to 1.0)
-- @param extraParams: table - Additional parameters (e.g., multiplier, element)
function statusEffects:apply(effectType, entity, duration, strength, chance, extraParams)
    -- Initialize the status table if needed
    if not entity.status then
        entity.status = {}
    end
    
    -- Check if the effect exists
    if not self.effects[effectType] then
        return false, "Status effect type does not exist"
    end
    
    -- Handle chance roll if specified
    if chance and chance < 1.0 then
        if math.random() > chance then
            return false, "Status effect failed chance roll"
        end
    end
    
    -- Set default duration and strength
    duration = duration or 3
    strength = strength or 1
    
    -- Handle special case for barrier
    if effectType == "barrier" then
        local barrierHP = strength
        
        -- If entity already has a barrier, refresh it with the new value
        if entity.status[effectType] then
            entity.status[effectType].duration = duration
            entity.status[effectType].strength = barrierHP
            entity.status[effectType].extraParams = extraParams or entity.status[effectType].extraParams
        else
            -- Apply new barrier
            entity.status[effectType] = {
                duration = duration,
                strength = barrierHP,
                extraParams = extraParams or {}
            }
        end
        
        return true, "Barrier applied successfully"
    else
        -- For other status effects
        
        -- Check if the effect is already applied
        if entity.status[effectType] then
            -- Extend the duration if it would be longer
            entity.status[effectType].duration = math.max(
                entity.status[effectType].duration,
                duration
            )
            -- For stat multipliers, use the higher value rather than stacking
            if effectType:find("multiplier") and extraParams and extraParams.multiplier then
                entity.status[effectType].extraParams = entity.status[effectType].extraParams or {}
                entity.status[effectType].extraParams.multiplier = math.max(
                    extraParams.multiplier,
                    entity.status[effectType].extraParams.multiplier or 1.0
                )
            else
                -- For other effects, increase the strength
                entity.status[effectType].strength = entity.status[effectType].strength + strength
            end
            
            -- Store any extra parameters
            if extraParams then
                entity.status[effectType].extraParams = extraParams
            end
        else
            -- Apply the new effect
            entity.status[effectType] = {
                duration = duration,
                strength = strength,
                extraParams = extraParams or {}
            }
        end
    end
    
    return true, "Status effect applied successfully"
end

-- Helper function to check if an entity has a status effect
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect
-- @return boolean - True if the entity has the effect
function statusEffects:has(entity, effectType)
    if not entity or not entity.status then
        return false
    end
    
    return entity.status[effectType] ~= nil
end

-- Helper function to get a status effect's strength value
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect
-- @return number - The strength of the effect, or 0 if not present
function statusEffects:getValue(entity, effectType)
    if not entity or not entity.status or not entity.status[effectType] then
        return 0
    end
    
    return entity.status[effectType].strength or 0
end

-- Helper function to get a status effect's multiplier
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect
-- @return number - The multiplier value, or 1.0 if not present
function statusEffects:getMultiplier(entity, effectType)
    if not entity or not entity.status or not entity.status[effectType] then
        return 1.0
    end
    
    local effect = entity.status[effectType]
    if effect.extraParams and effect.extraParams.multiplier then
        return effect.extraParams.multiplier
    end
    
    return 1.0
end

-- Helper function to get a status effect's duration
-- @param entity: table - The entity to check
-- @param effectType: string - The name of the effect
-- @return number - The remaining duration, or 0 if not present
function statusEffects:getDuration(entity, effectType)
    if not entity or not entity.status or not entity.status[effectType] then
        return 0
    end
    
    return entity.status[effectType].duration or 0
end

-- Remove a status effect from an entity
-- @param entity: table - The entity to remove the effect from
-- @param effectType: string - The name of the effect to remove
-- @return boolean - True if the effect was removed
function statusEffects:remove(entity, effectType)
    if not entity or not entity.status or not entity.status[effectType] then
        return false
    end
    
    entity.status[effectType] = nil
    return true
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
        -- Check if effect exists in the effects table before trying to use it
        if self.effects[effectType] and self.effects[effectType].onTurnStart then
            -- Execute the turn start function for this effect
            local extraParams = effect.extraParams or {}
            local result = self.effects[effectType].onTurnStart(entity, effect.strength, extraParams)
            if result then
                table.insert(updates, result)
                
                -- If this is a damaging effect, apply damage (accounting for barrier)
                if result.value and result.value > 0 then
                    local damage = result.value
                    
                    -- Check if entity has a barrier
                    if entity.status["barrier"] then
                        local barrierStrength = entity.status["barrier"].strength
                        local damageToBarrier = math.min(barrierStrength, damage)
                        damage = damage - damageToBarrier
                        
                        -- Reduce barrier strength
                        entity.status["barrier"].strength = barrierStrength - damageToBarrier
                        
                        -- If barrier is depleted, remove it
                        if entity.status["barrier"].strength <= 0 then
                            entity.status["barrier"] = nil
                            table.insert(updates, {
                                message = entity.name .. "'s barrier is depleted!",
                                value = 0,
                                color = {0.7, 0.7, 1.0}
                            })
                        end
                    end
                    
                    -- Apply remaining damage to HP
                    if damage > 0 then
                        entity.currentHP = math.max(0, entity.currentHP - damage)
                    end
                    
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
        else
            -- Effect doesn't exist in the effects table, log warning if in debug mode
            if GAME.debug then
                print("WARNING: Missing effect definition or onTurnStart for " .. effectType)
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
    local uiFunctions = require("gameplay/combat/uiFunctions")
    
    for effectType, effect in pairs(entity.status) do
        -- Decrease the duration
        effect.duration = effect.duration - 1
        
        -- Check if the effect has expired
        if effect.duration <= 0 then
            -- Get effect name with safety check
            local effectName = "Unknown"
            if self.effects[effectType] then
                effectName = self.effects[effectType].name
            else
                -- If we don't have a definition for this effect, use a formatted version of the effect type
                effectName = effectType:gsub("_", " "):gsub("^%l", string.upper)
                if GAME.debug then
                    print("WARNING: Missing effect definition for " .. effectType)
                end
            end
            
            -- Create expiry message
            local message = entity.name .. " is no longer " .. effectName
            local messageColor = {0.7, 0.7, 0.7}
            
            -- Show floating text at an appropriate position
            -- For positioning, we need to determine where the entity is on screen
            local x, y
            if entity.isPlayer then
                -- For player characters, position near their UI element in combat
                x = 200 + (entity.index or 1) * 150  -- Approximate position based on party layout
                y = GAME.height - 200
            else
                -- For enemies, position near center of screen
                x = GAME.width / 2
                y = GAME.height / 3
            end
            
            -- Display floating text
            -- Look for the dungeon screen's floatingTexts collection in the current game state
            local floatingTexts = nil
            if GAME.currentState and GAME.currentState.floatingTexts then
                floatingTexts = GAME.currentState.floatingTexts
                uiFunctions.showFloatingText(message, x, y, messageColor, 2.0, floatingTexts)
            end
            
            -- Add to expired effects list for combat log
            entity.status[effectType] = nil
            table.insert(expired, {
                type = effectType,
                message = message,
                color = messageColor
            })
        end
    end
    
    return expired
end

-- Process spreading of status effects to allies
-- @param entities: table - All entities to check for spreadable effects
-- @param entityType: string - Type of entity ("party", "enemy", "minion")
-- @param combat: table - The combat instance for logging
-- @return spreads: table - A list of spread effects with messages
function statusEffects:processEffectSpreading(entities, entityType, combat)
    if not entities or #entities == 0 then
        return {}
    end
    
    local spreads = {}
    
    -- For each entity with active status
    for i, entity in ipairs(entities) do
        if entity.active and entity.status then
            -- Check each status effect
            for effectType, effect in pairs(entity.status) do
                -- Check if this effect can spread
                if self.effects[effectType] and self.effects[effectType].canSpread then
                    local spreadChance = self.effects[effectType].spreadChance or 0
                    
                    -- Roll to see if the effect spreads
                    if math.random() <= spreadChance then
                        -- Find valid targets (active allies)
                        local validTargets = {}
                        for j, target in ipairs(entities) do
                            if i ~= j and target.active and not self:has(target, effectType) then
                                table.insert(validTargets, target)
                            end
                        end
                        
                        -- If there are valid targets, choose one randomly
                        if #validTargets > 0 then
                            local targetIndex = math.random(1, #validTargets)
                            local target = validTargets[targetIndex]
                            
                            -- Apply the effect to the target with same duration and strength
                            local success, message = self:apply(
                                effectType, 
                                target, 
                                effect.duration, 
                                effect.strength, 
                                1.0, -- 100% chance since we already rolled
                                effect.extraParams
                            )
                            
                            if success then
                                local effectName = self.effects[effectType].name or effectType
                                local spreadMessage = effectName .. " spreads from " .. entity.name .. " to " .. target.name .. "!"
                                
                                -- Add to combat log if combat instance provided
                                if combat and combat.addLog then
                                    combat:addLog(spreadMessage, {1, 0.5, 0.2})
                                end
                                
                                -- Add to spreads list
                                table.insert(spreads, {
                                    source = entity,
                                    target = target,
                                    effectType = effectType,
                                    message = spreadMessage
                                })
                                
                                -- Show floating text if UI functions are available
                                local uiFunctions = require("gameplay/combat/uiFunctions")
                                if uiFunctions and GAME.currentState and GAME.currentState.floatingTexts then
                                    local x, y
                                    if target.isPlayer then
                                        x = 200 + (target.index or 1) * 150
                                        y = GAME.height - 200
                                    else
                                        x = GAME.width / 2
                                        y = GAME.height / 3
                                    end
                                    
                                    uiFunctions.showFloatingText(
                                        spreadMessage, 
                                        x, y, 
                                        {1, 0.5, 0.2}, 
                                        2.0, 
                                        GAME.currentState.floatingTexts
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return spreads
end

return statusEffects 