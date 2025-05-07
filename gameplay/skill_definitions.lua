-- Skill Definitions
-- Contains all skill definitions

local skillDefinitions = {
    -- Base skills
    Attack = {
        name = "Attack",
        description = "Basic attack with equipped weapon.",
        type = "physical",
        target = "single_enemy",
        mpCost = 0,
        basePower = 100,
        formula = "physical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.05) end
    },
    
    Defend = {
        name = "Defend",
        description = "Defensive stance that reduces damage taken.",
        type = "support",
        target = "self",
        mpCost = 0,
        basePower = 0,
        formula = nil,
        maxLevel = 3,
        effect = {
            stat = "defense_multiplier",
            value = 1.5,
            duration = 1
        },
        levelModifier = function(level) return 1.5 + (level * 0.1) end
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
    },
    
    -- Dark Mage skills
    ShadowBolt = {
        name = "Shadow Bolt",
        description = "Unleashes a bolt of dark energy at a target.",
        type = "magical",
        element = "dark",
        target = "single_enemy",
        mpCost = 8,
        basePower = 130,
        formula = "magical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
    
    DrainLife = {
        name = "Drain Life",
        description = "Drains life from a target to heal the caster.",
        type = "magical",
        element = "dark",
        target = "single_enemy",
        mpCost = 12,
        basePower = 90,
        formula = "magical",
        effect = {
            lifeDrain = true,
            drainPercent = 0.5 -- Percentage of damage dealt returned as healing
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                drainPercent = 0.5 + (level * 0.05)
            }
        end
    },
    
    CurseOfWeakness = {
        name = "Curse of Weakness",
        description = "Weakens a target, reducing their attack power.",
        type = "magical",
        element = "dark",
        target = "single_enemy",
        mpCost = 10,
        basePower = 0,
        effect = {
            stat = "attack_multiplier",
            value = 0.7,
            duration = 3
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                value = 0.7 - (level * 0.05),
                duration = 3 + level
            }
        end
    },
    
    -- Elemental Mage skills
    ElementalBurst = {
        name = "Elemental Burst",
        description = "Releases a burst of elemental energy affecting all enemies.",
        type = "magical",
        element = "random", -- Changes randomly between fire, ice, lightning
        target = "all_enemies",
        mpCost = 15,
        basePower = 100,
        formula = "magical",
        maxLevel = 5,
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
    
    ElementalAffinity = {
        name = "Elemental Affinity",
        description = "Increases resistance to elemental damage and boosts elemental spell power.",
        type = "support",
        target = "self",
        mpCost = 10,
        basePower = 0,
        effect = {
            elementalResist = 0.2,
            elementalPower = 1.2,
            duration = 3
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                elementalResist = 0.2 + (level * 0.05),
                elementalPower = 1.2 + (level * 0.1),
                duration = 3 + level
            }
        end
    },
    
    -- Spirit Speaker skills
    SpiritSight = {
        name = "Spirit Sight",
        description = "Reveal hidden truths and enemy weaknesses through spiritual vision.",
        type = "support",
        target = "all_enemies",
        mpCost = 12,
        basePower = 0,
        effect = {
            revealWeakness = true,
            duration = 3
        },
        maxLevel = 3,
        levelModifier = function(level) 
            return {
                duration = 3 + level
            }
        end
    },
    
    AncestralGuidance = {
        name = "Ancestral Guidance",
        description = "Call upon ancestral spirits to guide allies, increasing their accuracy.",
        type = "support",
        target = "all_allies",
        mpCost = 15,
        basePower = 0,
        effect = {
            stat = "accuracy_multiplier",
            value = 1.3,
            duration = 3
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                value = 1.3 + (level * 0.1),
                duration = 3 + level
            }
        end
    },
    
    -- Necromancer skills
    RaiseSkeleton = {
        name = "Raise Skeleton",
        description = "Summon a skeletal warrior to fight for you.",
        type = "summon",
        summonType = "undead",
        target = "none",
        mpCost = 20,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Skeleton Warrior",
            maxHP = 60,
            attackPower = 15,
            defense = 10,
            speed = 7,
            abilities = {"BoneStrike"},
            color = {0.8, 0.8, 0.8}
        },
        duration = 600, -- 10 minutes in seconds
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2),
                duration = 600 + (level * 120)
            }
        end
    },
    
    RaiseZombie = {
        name = "Raise Zombie",
        description = "Summon a powerful but slow zombie to tank damage.",
        type = "summon",
        summonType = "undead",
        target = "none",
        mpCost = 25,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Rotting Zombie",
            maxHP = 120,
            attackPower = 12,
            defense = 15,
            speed = 4,
            abilities = {"InfectedBite"},
            color = {0.2, 0.6, 0.2}
        },
        duration = 600, -- 10 minutes in seconds
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2),
                duration = 600 + (level * 120)
            }
        end
    },
    
    RaiseWraith = {
        name = "Raise Wraith",
        description = "Summon a spectral wraith with powerful dark magic.",
        type = "summon",
        summonType = "undead",
        target = "none",
        mpCost = 40,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Shadow Wraith",
            maxHP = 80,
            attackPower = 10,
            magicPower = 25,
            defense = 8,
            magicDefense = 18,
            speed = 9,
            abilities = {"SoulDrain", "ShadowBolt"},
            color = {0.4, 0.0, 0.6}
        },
        duration = 480, -- 8 minutes in seconds
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2),
                duration = 480 + (level * 60)
            }
        end
    },
    
    DarkCommand = {
        name = "Dark Command",
        description = "Enhance your undead minions with dark energy, increasing their power.",
        type = "support",
        target = "all_minions",
        mpCost = 15,
        basePower = 0,
        effect = {
            stat = "attack_multiplier",
            value = 1.5,
            duration = 3
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                value = 1.5 + (level * 0.1),
                duration = 3 + level
            }
        end
    },
    
    DeathPact = {
        name = "Death Pact",
        description = "Sacrifice an undead minion to heal yourself and gain a power boost.",
        type = "support",
        target = "single_minion",
        mpCost = 10,
        basePower = 0,
        effect = {
            sacrificeMinion = true,
            healPercent = 0.5, -- % of minion's max HP
            powerBoost = {
                stat = "attack_multiplier",
                value = 1.3,
                duration = 3
            }
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                healPercent = 0.5 + (level * 0.1),
                powerBoost = {
                    value = 1.3 + (level * 0.1),
                    duration = 3 + level
                }
            }
        end
    },
    
    -- Conjurer skills
    SummonFireElemental = {
        name = "Summon Fire Elemental",
        description = "Summon a fire elemental to burn enemies.",
        type = "summon",
        summonType = "elemental",
        element = "fire",
        target = "none",
        mpCost = 25,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Fire Elemental",
            maxHP = 70,
            attackPower = 15,
            magicPower = 20,
            defense = 8,
            magicDefense = 12,
            speed = 10,
            abilities = {"Fireball", "BurningTouch"},
            color = {0.9, 0.3, 0.1}
        },
        duration = 0, -- Lasts until battle ends
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end
    },
    
    SummonWaterElemental = {
        name = "Summon Water Elemental",
        description = "Summon a water elemental with healing abilities.",
        type = "summon",
        summonType = "elemental",
        element = "water",
        target = "none",
        mpCost = 25,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Water Elemental",
            maxHP = 80,
            attackPower = 12,
            magicPower = 18,
            defense = 10,
            magicDefense = 15,
            speed = 8,
            abilities = {"WaterJet", "HealingRain"},
            color = {0.2, 0.5, 0.9}
        },
        duration = 0, -- Lasts until battle ends
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end
    },
    
    SummonEarthElemental = {
        name = "Summon Earth Elemental",
        description = "Summon a defensive earth elemental.",
        type = "summon",
        summonType = "elemental",
        element = "earth",
        target = "none",
        mpCost = 25,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Earth Elemental",
            maxHP = 100,
            attackPower = 18,
            defense = 20,
            magicDefense = 10,
            speed = 5,
            abilities = {"RockThrow", "StoneArmor"},
            color = {0.6, 0.4, 0.2}
        },
        duration = 0, -- Lasts until battle ends
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end
    },
    
    SummonAirElemental = {
        name = "Summon Air Elemental",
        description = "Summon a swift air elemental with evasive abilities.",
        type = "summon",
        summonType = "elemental",
        element = "air",
        target = "none",
        mpCost = 25,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Air Elemental",
            maxHP = 60,
            attackPower = 14,
            magicPower = 16,
            defense = 6,
            magicDefense = 14,
            speed = 18,
            abilities = {"LightningStrike", "GustOfWind"},
            color = {0.8, 0.8, 1.0}
        },
        duration = 0, -- Lasts until battle ends
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end
    },
    
    ElementalMastery = {
        name = "Elemental Mastery",
        description = "Enhance the power of your elemental summons.",
        type = "support",
        target = "all_minions",
        mpCost = 15,
        basePower = 0,
        effect = {
            stats = {
                attack_multiplier = 1.3,
                magic_multiplier = 1.3
            },
            duration = 3
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                attack_multiplier = 1.3 + (level * 0.1),
                magic_multiplier = 1.3 + (level * 0.1),
                duration = 3 + level
            }
        end
    },
    
    -- Shaman skills
    SummonAncestorSpirit = {
        name = "Summon Ancestor Spirit",
        description = "Summon an ancestor spirit to provide wisdom and protection.",
        type = "summon",
        summonType = "spirit",
        target = "none",
        mpCost = 20,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Ancestor Spirit",
            maxHP = 30, -- Low HP as they don't engage in combat
            color = {0.8, 0.8, 1.0},
            passiveBuffs = {
                wisdom_bonus = 5,
                magic_defense_bonus = 10
            }
        },
        duration = 300, -- 5 minutes in seconds
        levelModifier = function(level) 
            return {
                passiveBuffs = {
                    wisdom_bonus = 5 + (level * 2),
                    magic_defense_bonus = 10 + (level * 3)
                },
                duration = 300 + (level * 60)
            }
        end
    },
    
    SummonNatureSpirit = {
        name = "Summon Nature Spirit",
        description = "Summon a nature spirit to enhance vitality and regeneration.",
        type = "summon",
        summonType = "spirit",
        target = "none",
        mpCost = 20,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Nature Spirit",
            maxHP = 30,
            color = {0.3, 0.8, 0.3},
            passiveBuffs = {
                hp_regeneration = 3,
                poison_resist = 0.5
            }
        },
        duration = 300, -- 5 minutes in seconds
        levelModifier = function(level) 
            return {
                passiveBuffs = {
                    hp_regeneration = 3 + level,
                    poison_resist = 0.5 + (level * 0.1)
                },
                duration = 300 + (level * 60)
            }
        end
    },
    
    SummonGuardianSpirit = {
        name = "Summon Guardian Spirit",
        description = "Summon a protective guardian spirit to enhance defense.",
        type = "summon",
        summonType = "spirit",
        target = "none",
        mpCost = 20,
        basePower = 0,
        formula = nil,
        maxLevel = 5,
        summonStats = {
            name = "Guardian Spirit",
            maxHP = 30,
            color = {0.7, 0.7, 0.9},
            passiveBuffs = {
                defense_bonus = 10,
                damage_reduction = 0.1
            }
        },
        duration = 300, -- 5 minutes in seconds
        levelModifier = function(level) 
            return {
                passiveBuffs = {
                    defense_bonus = 10 + (level * 3),
                    damage_reduction = 0.1 + (level * 0.02)
                },
                duration = 300 + (level * 60)
            }
        end
    },
    
    SpiritCommunion = {
        name = "Spirit Communion",
        description = "Commune with spirits to recover MP and enhance spiritual abilities.",
        type = "support",
        target = "self",
        mpCost = 0, -- Free to use
        basePower = 0,
        effect = {
            restoreMP = true,
            mpRestoreValue = 20,
            enhanceSpiritBuffs = true,
            duration = 2
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                mpRestoreValue = 20 + (level * 5),
                duration = 2 + level
            }
        end
    },
    
    SpiritVision = {
        name = "Spirit Vision",
        description = "Gain insights from the spirit world, revealing enemy weaknesses and secrets.",
        type = "support",
        target = "all_enemies",
        mpCost = 15,
        basePower = 0,
        effect = {
            revealWeakness = true,
            accuracyBoost = 0.2,
            critChanceBoost = 0.1,
            duration = 4
        },
        maxLevel = 5,
        levelModifier = function(level) 
            return {
                accuracyBoost = 0.2 + (level * 0.05),
                critChanceBoost = 0.1 + (level * 0.02),
                duration = 4 + level
            }
        end
    }
}

return skillDefinitions 