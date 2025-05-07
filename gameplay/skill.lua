-- Skill System
-- Defines character skills and abilities

local skillSystem = {
    skills = {}
}

-- Import skill definitions
skillSystem.skills = require("gameplay/skill_definitions")

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
        
        local defense = 5  -- Default value if no defense found
        if target.defense ~= nil then
            defense = target.defense
        elseif target.attributes and target.attributes.CON then
            defense = target.attributes.CON / 2
        end
        
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
        
        local magicDefense = 5  -- Default value if no magic defense found
        if target.magicDefense ~= nil then
            magicDefense = target.magicDefense
        elseif target.attributes and target.attributes.WIL then
            magicDefense = target.attributes.WIL / 2
        end
        
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
        
        -- Make sure wisdom is a number
        wisdom = tonumber(wisdom) or 10
        
        damage = (power / 100) * (wisdom * 3)
        damage = math.max(1, damage)
    end
    
    -- Apply elemental modifiers
    if skill.element and target.elementalWeaknesses then
        local elementMultiplier = 1.0
        
        if target.elementalWeaknesses[skill.element] then
            elementMultiplier = target.elementalWeaknesses[skill.element]
        end
        
        damage = damage * elementMultiplier
    end
    
    -- Calculate critical hit
    local isCritical = false
    if skill.critChance then
        local critChance = skill.critChance
        
        -- Apply level modifier to crit chance
        if skill.levelModifier and type(skill.levelModifier) == "function" then
            local modifier = skill.levelModifier(level or 1)
            
            if type(modifier) == "table" and modifier.critChance then
                critChance = modifier.critChance
            end
        end
        
        if math.random() < critChance then
            damage = damage * (skill.critModifier or 1.5)
            isCritical = true
        end
    end
    
    return math.floor(damage), isCritical
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
