-- Skill System
-- Defines character skills and abilities

local skillSystem = {
    skills = {}
}

-- Import skill definitions
skillSystem.skills = require("data/skill_definitions")

-- Skill types
skillSystem.SKILL_TYPE = {
    PHYSICAL = "physical",
    MAGICAL = "magical",
    HEALING = "healing",
    SUPPORT = "support",
    UTILITY = "utility"
}

-- Target types
skillSystem.TARGET_TYPE = {
    SELF = "self",
    SINGLE_ALLY = "single_ally",
    ALL_ALLIES = "all_allies",
    SINGLE_ENEMY = "single_enemy",
    ALL_ENEMIES = "all_enemies",
    AREA = "area"
}

-- Get a skill by name
function skillSystem:getSkill(name)
    return self.skills[name]
end

-- Calculate skill effect
function skillSystem:calculateSkillEffect(skill, user, target, level)
    local effect = {}
    
    -- Copy base effect
    if skill.effect then
        for k, v in pairs(skill.effect) do
            effect[k] = v
        end
    end
    
    -- Apply level modifier if it exists
    if skill.levelModifier and type(skill.levelModifier) == "function" then
        local modifier = skill.levelModifier(level or 1)
        
        if type(modifier) == "number" then
            -- Simple numeric modifier
            effect.powerModifier = modifier
        elseif type(modifier) == "table" then
            -- Complex modifier affecting multiple properties
            for k, v in pairs(modifier) do
                if type(v) == "function" then
                    effect[k] = v(user)
                else
                    effect[k] = v
                end
            end
        elseif type(modifier) == "function" then
            -- Function modifier (for dynamic calculations)
            effect.customModifier = modifier
        end
    end
    
    return effect
end

-- Calculate damage for a skill
function skillSystem:calculateDamage(skill, user, target, level)
    -- Ensure we have a valid skill, user, and target
    if not skill or not user or not target then
        if GAME.debug then
            print("calculateDamage: Missing required parameters")
        end
        return 1, false -- Return minimum damage and no critical
    end

    local basePower = skill.basePower or 0
    local power = basePower
    
    -- Get statusEffects module if not directly passed
    local statusEffects = statusEffects or require("gameplay/statusEffects")
    
    -- Apply level modifier
    if skill.levelModifier and type(skill.levelModifier) == "function" then
        local modifier = skill.levelModifier(level or 1)
        
        if type(modifier) == "number" then
            power = power * modifier
        elseif type(modifier) == "table" and modifier.power then
            power = power * modifier.power
        end
    end
    
    -- Calculate damage based on formula
    local damage = 0
    
    if skill.formula == "physical" then
        -- Physical damage formula
        local attack = 10  -- Default value if no attack power found
        if user.attackPower ~= nil then
            attack = user.attackPower
        elseif user.attributes and user.attributes.STR then
            attack = user.attributes.STR
        end
        
        -- Apply attack multiplier from status effects
        attack = attack * statusEffects:getMultiplier(user, "attack_multiplier")
        
        local defense = 5  -- Default value if no defense found
        if target.defense ~= nil then
            defense = target.defense
        elseif target.attributes and target.attributes.CON then
            defense = target.attributes.CON / 2
        end
        
        -- Apply defense multiplier from status effects
        defense = defense * statusEffects:getMultiplier(target, "defense_multiplier")
        
        -- Make sure values are numbers
        attack = tonumber(attack) or 10
        defense = tonumber(defense) or 5
        
        damage = (power / 100) * (attack * 2 - defense)
        damage = math.max(1, damage)
        
    elseif skill.formula == "magical" then
        -- Magical damage formula
        local magicPower = 10  -- Default value if no magic power found
        if user.magicPower ~= nil then
            magicPower = user.magicPower
        elseif user.attributes and user.attributes.INT then
            magicPower = user.attributes.INT
        end
        
        -- Apply magic attack multiplier from status effects (using attack_multiplier)
        magicPower = magicPower * statusEffects:getMultiplier(user, "attack_multiplier")
        
        local magicDefense = 5  -- Default value if no magic defense found
        if target.magicDefense ~= nil then
            magicDefense = target.magicDefense
        elseif target.attributes and target.attributes.WIL then
            magicDefense = target.attributes.WIL / 2
        end
        
        -- Apply magic defense multiplier from status effects (using defense_multiplier)
        magicDefense = magicDefense * statusEffects:getMultiplier(target, "defense_multiplier")
        
        -- Make sure values are numbers
        magicPower = tonumber(magicPower) or 10
        magicDefense = tonumber(magicDefense) or 5
        
        damage = (power / 100) * (magicPower * 2.5 - magicDefense)
        damage = math.max(1, damage)
        
    elseif skill.formula == "healing" then
        -- Healing formula
        local wisdom = 10  -- Default value
        if user.attributes and user.attributes.WIS then
            wisdom = user.attributes.WIS
        end
        
        -- Enhanced scaling for high wisdom
        local wisdomMultiplier = 1.0 + ((wisdom - 10) * 0.05)  -- 5% bonus per point above 10
        wisdom = tonumber(wisdom) or 10
        
        damage = (power / 100) * (wisdom * 3) * wisdomMultiplier
        damage = math.max(1, damage)
    end
    
    -- Apply elemental modifiers
    if skill.element and target.elementalWeaknesses then
        local elementMultiplier = 1.0
        
        if target.elementalWeaknesses[skill.element] then
            elementMultiplier = target.elementalWeaknesses[skill.element]
        end
        
        -- Apply elemental resistance from status effects
        if statusEffects:has(target, "elementalResist") then
            local resistEffect = target.status.elementalResist
            local elementSpecific = resistEffect.extraParams and resistEffect.extraParams.element
            if not elementSpecific or elementSpecific == skill.element then
                -- If target has general elemental resist or specific resist to this element
                elementMultiplier = elementMultiplier * 0.75 -- Reduce damage by 25%
            end
        end
        
        -- Apply elemental power from status effects
        if statusEffects:has(user, "elementalPower") then
            local powerEffect = user.status.elementalPower
            local elementSpecific = powerEffect.extraParams and powerEffect.extraParams.element
            if not elementSpecific or elementSpecific == skill.element then
                -- If user has general elemental power boost or specific to this element
                elementMultiplier = elementMultiplier * 1.25 -- Increase damage by 25%
            end
        end
        
        damage = damage * elementMultiplier
    end
    
    -- Apply offensive status effects
    if statusEffects:has(user, "strengthen") then
        damage = damage * 1.25 -- 25% more damage
    end
    
    -- Apply defensive status effects
    if statusEffects:has(target, "vulnerable") then
        damage = damage * 1.25 -- 25% more damage when vulnerable
    end
    
    if statusEffects:has(target, "protect") then
        damage = damage * 0.75 -- 25% less damage when protected
    end
    
    -- Calculate critical hit
    local isCritical = false
    if skill.critChance then
        local critChance = skill.critChance
        
        -- DEX bonus for precision skills
        if skill.useDexForCrit and user.attributes and user.attributes.DEX then
            local dexBonus = user.attributes.DEX * 0.005  -- 0.5% per DEX point
            critChance = critChance + dexBonus
        end
        
        -- Apply accuracy multiplier from status effects (affects crit chance)
        critChance = critChance * statusEffects:getMultiplier(user, "accuracy_multiplier")
        
        if math.random() < critChance then
            damage = damage * (skill.critModifier or 1.5)
            isCritical = true
        end
    end
    
    return math.floor(damage), isCritical
end

-- Calculate hit chance for a skill
function skillSystem:calculateHitChance(skill, user, target)
    local baseHitChance = skill.baseHitChance or 85
    
    -- Get statusEffects module
    local statusEffects = statusEffects or require("gameplay/statusEffects")
    
    -- Apply accuracy multiplier from status effects
    local accuracyMultiplier = statusEffects:getMultiplier(user, "accuracy_multiplier")
    
    -- DEX bonus for precision
    local dexBonus = 0
    if user.attributes and user.attributes.DEX then
        dexBonus = user.attributes.DEX * 0.2
    end
    
    return math.min(95, baseHitChance + dexBonus) * accuracyMultiplier
end

-- Get all skills for a given job
function skillSystem:getJobSkills(jobName)
    local jobSkills = {}
    local jobSystem = require("gameplay/job")
    local job = jobSystem:getJob(jobName)
    
    if job and job.availableSkills then
        for _, skillName in ipairs(job.availableSkills) do
            local skill = self:getSkill(skillName)
            if skill then
                table.insert(jobSkills, skill)
            end
        end
    end
    
    return jobSkills
end

return skillSystem
