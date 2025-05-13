-- Unique Item System
-- Handles unique item effects, set bonuses, and their application

local setItemBonuses = require("data/items/set_bonuses")

local uniqueItemSystem = {
    -- Registry of all available unique effect handlers
    effectHandlers = {}
}

-- Register effect handlers for different unique effects
function uniqueItemSystem:registerEffectHandler(effectType, handlerFunction)
    self.effectHandlers[effectType] = handlerFunction
end

-- Process unique item effects. The 'context' object's structure is crucial and will vary.
-- It should always include 'eventType' to guide handlers.
function uniqueItemSystem:processEffects(context)
    -- context MUST contain: eventType (e.g., "CALCULATE_OUTGOING_DAMAGE", "CHARACTER_TAKES_DAMAGE", "LOOT_GENERATED", "MINION_SUMMONED")
    -- context MAY contain: character, target, skill, baseDamage, incomingDamage, lootTable, minionRef, etc., depending on eventType
    local character = context.character
    local modifiedValue = context.value -- Generic field, interpretation depends on eventType and handler

    if not character then return modifiedValue end -- Guard clause

    -- 1. Process unique item effects from equipped gear
    if character.equipment then
        for slot, item in pairs(character.equipment) do
            if item and item.unique and item.uniqueEffects then
                for _, effectInstance in ipairs(item.uniqueEffects) do
                    local handler = self.effectHandlers[effectInstance.type]
                    if handler and self:checkEffectConditions(effectInstance.condition, context) then
                        -- Handlers should be mindful of modifying context directly
                        modifiedValue = handler(modifiedValue, effectInstance.effect, context)
                    end
                end
            end
        end
    end
    
    -- 2. Process active set bonuses
    local activeSetEffects = self:getEquippedSetBonuses(character)
    for _, setEffectInstance in ipairs(activeSetEffects) do
        local handler = self.effectHandlers[setEffectInstance.type]
        -- Set bonuses can also have conditions, processed the same way
        if handler and self:checkEffectConditions(setEffectInstance.condition, context) then
            modifiedValue = handler(modifiedValue, setEffectInstance.effect, context)
        end
    end
    
    return modifiedValue
end

-- Check if effect conditions are met using a more flexible structure
function uniqueItemSystem:checkEffectConditions(condition, context)
    if not condition then return true end -- No conditions means always active

    local function evaluateClause(clause)
        -- Check character-specific conditions
        if context.character then
            if clause.type == "character_health_percentage" then
                local currentHpPercent = context.character.currentHP / context.character.maxHP
                if clause.comparison == "less_than" then return currentHpPercent < clause.value end
                if clause.comparison == "greater_than_or_equal_to" then return currentHpPercent >= clause.value end
            elseif clause.type == "character_status" then
                return context.character.status and context.character.status[clause.status] -- Check if character has the status
            end
        end

        -- Check target-specific conditions (if target exists in context)
        if context.target then
            if clause.type == "target_type" and context.target.type ~= clause.value then
                return false
            elseif clause.type == "target_status" then
                return context.target.status and context.target.status[clause.status] -- Check if target has the status
            elseif clause.type == "target_health_percentage" then
                local targetHpPercent = context.target.currentHP / context.target.maxHP
                if clause.comparison == "less_than" then return targetHpPercent < clause.value end
                if clause.comparison == "greater_than_or_equal_to" then return targetHpPercent >= clause.value end
            end
        end
        
        -- Check skill-specific conditions (if skill exists in context)
        if context.skill then
            if clause.type == "skill_element" and context.skill.element ~= clause.value then
                return false
            end
        end
        
        -- Default for unimplemented or irrelevant clause types in this simple example
        return true 
    end

    local function evaluate(cond)
        if cond.operator == "AND" then
            for _, clauseOrSubCondition in ipairs(cond.clauses) do
                if clauseOrSubCondition.operator then -- It's a sub-condition
                    if not evaluate(clauseOrSubCondition) then return false end
                else -- It's a direct clause
                    if not evaluateClause(clauseOrSubCondition) then return false end
                end
            end
            return true
        elseif cond.operator == "OR" then
            for _, clauseOrSubCondition in ipairs(cond.clauses) do
                if clauseOrSubCondition.operator then -- It's a sub-condition
                    if evaluate(clauseOrSubCondition) then return true end
                else -- It's a direct clause
                    if evaluateClause(clauseOrSubCondition) then return true end
                end
            end
            return false
        else -- Single condition (legacy or simple form)
            return evaluateClause(cond)
        end
    end

    return evaluate(condition)
end

-- Get active set bonuses for a character based on equipped items
function uniqueItemSystem:getEquippedSetBonuses(character)
    local setsPieces = {}
    local activeBonuses = {} -- This will collect effect-like structures
    
    if not character or not character.equipment then return activeBonuses end

    -- Count equipped set pieces
    for slot, item in pairs(character.equipment) do
        if item and item.setItem and item.setName then
            setsPieces[item.setName] = (setsPieces[item.setName] or 0) + 1
        end
    end
    
    -- Check which set bonuses are active
    for setName, count in pairs(setsPieces) do
        if setItemBonuses[setName] then
            for pieceCountStr, bonusData in pairs(setItemBonuses[setName]) do
                local pieceCount = tonumber(pieceCountStr)
                if count >= pieceCount then
                    -- Add the bonus in a structure similar to uniqueEffects
                    table.insert(activeBonuses, {
                        id = setName .. "_SetBonus_" .. pieceCount, -- e.g., Firewalker_SetBonus_2
                        type = bonusData.type, -- e.g., "elemental_resistance"
                        condition = bonusData.condition, -- Set bonuses can also have conditions
                        effect = bonusData -- Pass the whole bonusData as the effect payload
                    })
                end
            end
        end
    end
    
    return activeBonuses
end

-- Register standard effect handlers
-- Example: Damage modifier handler
uniqueItemSystem:registerEffectHandler("damage_modifier", function(damage, effect, context)
    -- Assumes context.eventType is appropriate (e.g., "CALCULATE_OUTGOING_DAMAGE")
    if effect.damage_multiplier then
        return (damage or 0) * effect.damage_multiplier
    end
    return damage
end)

-- Example: Damage type change handler
uniqueItemSystem:registerEffectHandler("damage_type_change", function(damage, effect, context)
    -- Assumes context.eventType is "CALCULATE_OUTGOING_DAMAGE" and context.skill is a mutable copy
    if effect.new_element and context.skill then
        context.skill.element = effect.new_element
    end
    return damage
end)

-- Enemy weakness handler
uniqueItemSystem:registerEffectHandler("enemy_weakness", function(damage, effect, context)
    -- Assumes context.eventType is "CALCULATE_OUTGOING_DAMAGE" and context.target exists
    if context.target and effect.enemy_type and effect.multiplier and context.target.type == effect.enemy_type then
        return (damage or 0) * effect.multiplier
    end
    return damage
end)

-- Elemental resistance handler
uniqueItemSystem:registerEffectHandler("elemental_resistance", function(incomingDamage, effect, context)
    -- Assumes context.eventType is "CHARACTER_TAKES_DAMAGE"
    -- and context.damageType matches effect.element
    if context.damageType and effect.element and context.damageType == effect.element then
        return (incomingDamage or 0) * (1 - (effect.value or 0)) -- effect.value is 0.5 for 50% resistance
    end
    return incomingDamage
end)

-- Immunity handler
uniqueItemSystem:registerEffectHandler("immunity", function(incomingDamage, effect, context)
    -- Assumes context.eventType is "CHARACTER_TAKES_DAMAGE"
    -- and context.damageType matches effect.element
    if context.damageType and effect.element and context.damageType == effect.element then
        return 0 -- Complete immunity
    end
    return incomingDamage
end)

-- Minion buff handler
uniqueItemSystem:registerEffectHandler("minion_buff", function(minionStat, effect, context)
    -- Assumes context.eventType is "MINION_STAT_MODIFICATION"
    if effect.stat_multiplier and context.character then
        return (minionStat or 0) * effect.stat_multiplier
    end
    return minionStat
end)

-- Minion taunt handler
uniqueItemSystem:registerEffectHandler("minion_taunt", function(targetingScore, effect, context)
    -- Assumes context.eventType is "AI_TARGETING_SCORE" and context.character owns minions
    if effect.taunt_value then
        return targetingScore * effect.taunt_value -- Reduce chance of being targeted
    end
    return targetingScore
end)

-- Loot modifier handler
uniqueItemSystem:registerEffectHandler("loot_modifier", function(rarityChance, effect, context)
    -- Assumes context.eventType is "CALCULATE_LOOT_RARITY"
    if effect.rarity_multiplier then
        return rarityChance * effect.rarity_multiplier
    end
    return rarityChance
end)

-- Note: grant_skill doesn't need a handler that modifies a value
-- It's a passive effect queried by other systems

return uniqueItemSystem 