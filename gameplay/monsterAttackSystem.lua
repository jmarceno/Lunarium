local damageTypes = require("gameplay/damageTypes")
local statusEffects = require("gameplay/statusEffects")
local monsterAbilities = require("data/monsterAbilities")
local minionAbilities = require("data/minionAbilities")

local monsterAttackSystem = {}

-- Calculate attack damage based on attacker, ability, and target
-- @param ability: table - The full ability definition
-- @param attacker: table - The attacking entity
-- @param target: table - The target entity
-- @return damage: number - The calculated damage amount
-- @return multiplier: number - The resistance multiplier
-- @return damageType: string - The type of damage
function monsterAttackSystem:calculateDamage(ability, attacker, target)
    if not ability or not attacker or not target then
        return 0, 1.0, "physical"
    end
    
    -- Base attack power from attacker's stats
    local attackPower = 0
    
    -- Check if this is a physical or magical ability
    if ability.type == "physical" then
        attackPower = attacker.attackPower or attacker.stats.attack or 10
    elseif ability.type == "magical" then
        attackPower = attacker.magicAttackPower or attacker.stats.magicAttack or 8
    else
        -- Support abilities typically don't do damage
        return 0, 1.0, ability.damageType or "physical"
    end
    
    -- Get target's raw defense stat
    local rawDefense = target.defense or target.stats.defense or 5

    -- New damage calculation logic:
    local rawOffense = attackPower * 2 -- Scale attacker's stat (e.g., *2 similar to player skills)
    
    local effectiveDefense = 0
    if ability.type == "physical" then
        effectiveDefense = math.floor(rawDefense / 2)
    elseif ability.type == "magical" then
        effectiveDefense = math.floor(rawDefense / 3) -- Magic ignores more defense
    else -- Fallback for other damage-dealing types if any, default to physical reduction
        effectiveDefense = math.floor(rawDefense / 2)
    end

    -- Calculate damage using the new formula
    -- Damage = (AbilityBasePower / 100) * (ScaledAttackerStat - EffectivePlayerDefense)
    local damage = math.floor((ability.basePower / 100) * (rawOffense - effectiveDefense))
    damage = math.max(1, damage) -- Ensure minimum damage of 1
    
    -- Apply damage type modifier based on target resistances/vulnerabilities
    local damageType = ability.damageType or "physical"
    local multiplier = damageTypes:calculateModifier(damageType, target)
    
    -- Apply resistance/vulnerability multiplier
    damage = math.floor(damage * multiplier)
    damage = math.max(1, damage) -- Ensure minimum damage of 1
    
    -- Check if attacker has Strengthen status effect
    if attacker.status and attacker.status["strengthen"] then
        damage = math.floor(damage * 1.25) -- 25% more damage
    end
    
    -- Check if target has Vulnerable status effect
    if target.status and target.status["vulnerable"] then
        damage = math.floor(damage * 1.25) -- 25% more damage
    end
    
    -- Check if target has Protect status effect
    if target.status and target.status["protect"] then
        damage = math.floor(damage * 0.75) -- 25% less damage
    end
    
    return damage, multiplier, damageType
end

-- Resolve an ability (attack or support) against target(s)
-- @param ability: table - The full ability definition
-- @param attacker: table - The attacking entity
-- @param target: table or table - The target entity/entities
-- @param combatContext: table - The combat system context for logging and state updates
-- @return logEntries: table - Table of log entries to be displayed
function monsterAttackSystem:resolveAbility(ability, attacker, targets, combatContext)
    -- Validate input
    if not ability or not attacker then
        return {}
    end
    
    -- Create log entries to return
    local logEntries = {}
    
    -- Get the full ability definition if passed an ID instead of a table
    local abilityDef = ability
    if type(ability) == "string" then
        abilityDef = monsterAbilities.definitions[ability] or minionAbilities.definitions[ability]
    end
    
    -- Exit if ability definition can't be found
    if not abilityDef then
        table.insert(logEntries, {
            message = attacker.name .. " failed to use an unknown ability!",
            color = {0.7, 0.7, 0.7}
        })
        return logEntries
    end
    
    -- Add ability usage to log
    table.insert(logEntries, {
        message = attacker.name .. " uses " .. abilityDef.name .. "!",
        color = {0.9, 0.9, 0.4}
    })
    
    -- Handle different target types (single, all, self, allies)
    local targetList = {}
    
    if abilityDef.target == "single_enemy" then
        -- Single target
        if targets and type(targets) ~= "table" then
            targetList = {targets} -- Wrap in table
        elseif targets then
            targetList = {targets[1]} -- Use first target
        end
    elseif abilityDef.target == "all_enemies" then
        -- All targets
        if targets and type(targets) ~= "table" then
            targetList = {targets} -- Wrap in table
        else
            targetList = targets or {}
        end
    elseif abilityDef.target == "self" then
        -- Self-targeting ability
        targetList = {attacker}
    elseif abilityDef.target == "all_allies" then
        -- Get all allies based on attacker's team
        if combatContext and combatContext.getAllies then
            targetList = combatContext:getAllies(attacker)
        else
            targetList = {attacker} -- Default to self if allies can't be determined
        end
    end
    
    -- Process ability for each target
    for _, target in ipairs(targetList) do
        -- Skip inactive targets
        if not target.active then
            goto continue
        end
        
        -- Handle different ability types
        if abilityDef.type == "physical" or abilityDef.type == "magical" then
            -- Offensive ability with damage
            
            -- Check if target is self and it's not a self-targeting ability
            if target == attacker and abilityDef.target ~= "self" then
                goto continue -- Skip damaging self
            end
            
            -- Calculate damage
            local damage, multiplier, damageType = self:calculateDamage(abilityDef, attacker, target)
            
            -- Check if target is immune
            if multiplier == 0 then
                table.insert(logEntries, {
                    message = target.name .. " is immune to " .. abilityDef.name .. "!",
                    color = {0.7, 0.7, 0.7}
                })
                goto continue
            end
            
            -- Apply damage to target
            target.currentHP = math.max(0, target.currentHP - damage)
            
            -- Get resistance text if needed
            local resistText, resistColor = damageTypes:getDisplayText(multiplier)
            
            -- Add damage message to log
            local message = target.name .. " takes " .. damage .. " " .. (damageType or "physical") .. " damage"
            if resistText then
                message = message .. " (" .. resistText .. ")"
            end
            message = message .. "!"
            
            table.insert(logEntries, {
                message = message,
                color = resistColor or {1, 0.5, 0.5}
            })
            
            -- Check if target is defeated
            if target.currentHP <= 0 then
                target.currentHP = 0
                target.active = false
                
                table.insert(logEntries, {
                    message = target.name .. " is defeated!",
                    color = {1, 0, 0}
                })
                
                -- Check for party defeat if needed
                if combatContext and target.isPlayer and combatContext.checkPartyDefeated then
                    combatContext:checkPartyDefeated()
                end
            end
            
            -- Apply status effect if ability has one and target is still alive
            if abilityDef.effect and target.active then
                if math.random() <= abilityDef.effect.chance then
                    local effectType = abilityDef.effect.type
                    local duration = abilityDef.effect.duration or 3
                    local strength = abilityDef.effect.strength or 1
                    
                    local applied = statusEffects:apply(effectType, target, duration, strength)
                    if applied then
                        table.insert(logEntries, {
                            message = target.name .. " is afflicted with " .. statusEffects.effects[effectType].name .. "!",
                            color = {0.8, 0.6, 0.8}
                        })
                    end
                end
            end
        elseif abilityDef.type == "support" and abilityDef.effect then
            -- Support ability with effect
            
            -- Apply status effect
            local effectType = abilityDef.effect.type
            local duration = abilityDef.effect.duration or 3
            local strength = abilityDef.effect.strength or 1
            
            local applied = statusEffects:apply(effectType, target, duration, strength)
            if applied then
                table.insert(logEntries, {
                    message = target.name .. " gains " .. statusEffects.effects[effectType].name .. "!",
                    color = {0.6, 0.8, 0.6}
                })
            end
        end
        
        ::continue::
    end
    
    return logEntries
end

-- Select an ability for a monster based on its ability list
-- @param monster: table - The monster entity
-- @return abilityId: string - The selected ability ID
function monsterAttackSystem:selectAbility(monster)
    -- Default to basic attack if no abilities defined
    if not monster.abilities or #monster.abilities == 0 then
        return "basic_physical_attack"
    end
    
    -- Filter abilities based on unlock level
    local availableAbilities = {}
    for _, abilityEntry in ipairs(monster.abilities) do
        local unlockLevel = abilityEntry.unlockLevel or 1
        if monster.stats.level >= unlockLevel then
            table.insert(availableAbilities, abilityEntry)
        end
    end
    
    -- If no abilities available (shouldn't happen), return basic attack
    if #availableAbilities == 0 then
        return "basic_physical_attack"
    end
    
    -- Calculate total chance
    local totalChance = 0
    for _, abilityEntry in ipairs(availableAbilities) do
        totalChance = totalChance + (abilityEntry.chanceToUse or 1)
    end
    
    -- Select an ability based on chance weights
    local randomValue = math.random() * totalChance
    local currentSum = 0
    
    for _, abilityEntry in ipairs(availableAbilities) do
        currentSum = currentSum + (abilityEntry.chanceToUse or 1)
        if randomValue <= currentSum then
            return abilityEntry.id
        end
    end
    
    -- Fallback to first ability if something goes wrong
    return availableAbilities[1].id
end

return monsterAttackSystem 