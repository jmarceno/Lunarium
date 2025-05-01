-- Skill System
-- Defines character skills and abilities

local skillSystem = {
    skills = {}
}

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

-- Skill definitions
skillSystem.skills = {
    -- Basic skills
    Attack = {
        name = "Attack",
        description = "A basic physical attack.",
        type = "physical",
        target = "single_enemy",
        mpCost = 0,
        basePower = 100,
        formula = "physical",
        maxLevel = 1,
        effect = nil
    },
    
    Defend = {
        name = "Defend",
        description = "Take a defensive stance, reducing damage taken by 50% until next turn.",
        type = "support",
        target = "self",
        mpCost = 0,
        basePower = 0,
        formula = nil,
        maxLevel = 1,
        effect = {
            stat = "defense_multiplier",
            value = 1.5,
            duration = 1
        }
    },
    
    -- Fighter skills
    PowerStrike = {
        name = "Power Strike",
        description = "A powerful strike that deals 150% damage.",
        type = "physical",
        target = "single_enemy",
        mpCost = 5,
        basePower = 150,
        formula = "physical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
    
    DoubleSlash = {
        name = "Double Slash",
        description = "Two quick strikes at 80% power each.",
        type = "physical",
        target = "single_enemy",
        mpCost = 8,
        basePower = 80,
        hits = 2,
        formula = "physical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.05) end
    },
    
    Taunt = {
        name = "Taunt",
        description = "Force an enemy to attack you for 2 turns.",
        type = "utility",
        target = "single_enemy",
        mpCost = 4,
        basePower = 0,
        formula = nil,
        maxLevel = 3,
        effect = {
            stat = "taunt",
            value = true,
            duration = 2
        },
        levelModifier = function(level) return 1 + level end
    },
    
    ShieldBash = {
        name = "Shield Bash",
        description = "Bash with shield for damage and chance to stun.",
        type = "physical",
        target = "single_enemy",
        mpCost = 6,
        basePower = 90,
        formula = "physical",
        maxLevel = 5,
        effect = {
            stat = "stun",
            chance = 0.3,
            duration = 1
        },
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                chance = 0.3 + (level * 0.05)
            }
        end
    },
    
    -- Mage skills
    FireBolt = {
        name = "Fire Bolt",
        description = "A basic fire attack spell.",
        type = "magical",
        element = "fire",
        target = "single_enemy",
        mpCost = 6,
        basePower = 120,
        formula = "magical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
    
    IceShard = {
        name = "Ice Shard",
        description = "An ice attack with chance to slow the target.",
        type = "magical",
        element = "ice",
        target = "single_enemy",
        mpCost = 8,
        basePower = 100,
        formula = "magical",
        maxLevel = 5,
        effect = {
            stat = "speed_multiplier",
            value = 0.7,
            chance = 0.4,
            duration = 2
        },
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                chance = 0.4 + (level * 0.05)
            }
        end
    },
    
    ThunderBolt = {
        name = "Thunder Bolt",
        description = "Lightning attack with increased critical hit chance.",
        type = "magical",
        element = "lightning",
        target = "single_enemy",
        mpCost = 10,
        basePower = 110,
        formula = "magical",
        critModifier = 2.0,
        critChance = 0.2,
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                critChance = 0.2 + (level * 0.04)
            }
        end
    },
    
    ManaShield = {
        name = "Mana Shield",
        description = "Creates a barrier that absorbs damage based on INT.",
        type = "support",
        target = "self",
        mpCost = 15,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        effect = {
            stat = "barrier",
            formula = function(caster) 
                return caster.attributes.INT * 5
            end,
            duration = 3
        },
        levelModifier = function(level) 
            return function(caster)
                return caster.attributes.INT * (5 + level)
            end
        end
    },
    
    -- Cleric skills
    Heal = {
        name = "Heal",
        description = "Restores HP to one ally.",
        type = "healing",
        target = "single_ally",
        mpCost = 8,
        basePower = 100,
        formula = "healing",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.15) end
    },
    
    DivineFavor = {
        name = "Divine Favor",
        description = "Increases an ally's attack and defense for 3 turns.",
        type = "support",
        target = "single_ally",
        mpCost = 12,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        effect = {
            stats = {
                attack_multiplier = 1.2,
                defense_multiplier = 1.2
            },
            duration = 3
        },
        levelModifier = function(level) 
            return {
                attack_multiplier = 1.2 + (level * 0.05),
                defense_multiplier = 1.2 + (level * 0.05)
            }
        end
    },
    
    Purify = {
        name = "Purify",
        description = "Removes negative status effects from an ally.",
        type = "healing",
        target = "single_ally",
        mpCost = 6,
        basePower = 0,
        formula = nil,
        maxLevel = 3,
        effect = {
            removeStatus = "negative",
            healing = function(level, caster) 
                return caster.attributes.WIS * level * 2
            end
        }
    },
    
    Smite = {
        name = "Smite",
        description = "Holy damage against a single enemy.",
        type = "magical",
        element = "holy",
        target = "single_enemy",
        mpCost = 10,
        basePower = 130,
        formula = "magical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.12) end
    },
    
    -- Rogue skills
    PreciseStrike = {
        name = "Precise Strike",
        description = "A precise attack with increased critical hit chance.",
        type = "physical",
        target = "single_enemy",
        mpCost = 5,
        basePower = 90,
        formula = "physical",
        critModifier = 2.5,
        critChance = 0.25,
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.06),
                critChance = 0.25 + (level * 0.05)
            }
        end
    },
    
    Steal = {
        name = "Steal",
        description = "Attempt to steal an item from an enemy.",
        type = "utility",
        target = "single_enemy",
        mpCost = 0,
        basePower = 0,
        formula = nil,
        maxLevel = 3,
        effect = {
            stealChance = 0.3
        },
        levelModifier = function(level) 
            return {
                stealChance = 0.3 + (level * 0.1)
            }
        end
    },
    
    -- Advanced job skills
    ShieldWall = {
        name = "Shield Wall",
        description = "Greatly increases defense for 3 turns.",
        type = "support",
        target = "self",
        mpCost = 12,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        effect = {
            stat = "defense_multiplier",
            value = 2.0,
            duration = 3
        },
        levelModifier = function(level) 
            return {
                value = 2.0 + (level * 0.2)
            }
        end
    },
    
    Rage = {
        name = "Rage",
        description = "Sacrifice defense for increased attack power.",
        type = "support",
        target = "self",
        mpCost = 10,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        effect = {
            stats = {
                attack_multiplier = 1.5,
                defense_multiplier = 0.7
            },
            duration = 3
        },
        levelModifier = function(level) 
            return {
                attack_multiplier = 1.5 + (level * 0.1)
            }
        end
    },
    
    Fireball = {
        name = "Fireball",
        description = "A powerful fire spell that hits all enemies.",
        type = "magical",
        element = "fire",
        target = "all_enemies",
        mpCost = 18,
        basePower = 90,
        formula = "magical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
    
    GroupHeal = {
        name = "Group Heal",
        description = "Restores HP to all allies.",
        type = "healing",
        target = "all_allies",
        mpCost = 20,
        basePower = 80,
        formula = "healing",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
    
    -- Master job skills
    DivineBlade = {
        name = "Divine Blade",
        description = "A holy attack that deals massive damage.",
        type = "physical",
        element = "holy",
        target = "single_enemy",
        mpCost = 25,
        basePower = 200,
        formula = "physical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.15) end
    },
    
    ArcaneMastery = {
        name = "Arcane Mastery",
        description = "Increases the power of all spells for 5 turns.",
        type = "support",
        target = "self",
        mpCost = 30,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        effect = {
            stat = "magic_multiplier",
            value = 1.5,
            duration = 5
        },
        levelModifier = function(level) 
            return {
                value = 1.5 + (level * 0.1)
            }
        end
    },
    
    ShadowMerge = {
        name = "Shadow Merge",
        description = "Merge with shadows, becoming untargetable for 2 turns.",
        type = "utility",
        target = "self",
        mpCost = 20,
        basePower = 0,
        formula = nil,
        maxLevel = 3,
        effect = {
            stat = "untargetable",
            value = true,
            duration = 2
        },
        levelModifier = function(level) 
            return {
                duration = 2 + level
            }
        end
    }
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
