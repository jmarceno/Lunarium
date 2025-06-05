local skillDefinitions = {
    Meditate = {
        description = "Heal self over 2 turns.",
        type = "healing",
        effect = {
            stat = "hp_regen",
            value = 15,
            duration = 2,
        },
        basePower = 0,
        mpCost = 4,
        name = "Meditate",
        target = "self",
        levelModifier = function(level)
            return { value = 15 + (level * 5), duration = 2 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    SummonAncestorSpirit = {
        description = "Summon an ancestor spirit to provide wisdom and protection.",
        type = "summon",
        summonStats = {
            name = "Ancestor Spirit",
            passiveBuffs = {
                wisdom_bonus = 5,
                magic_defense_bonus = 10,
            },
            color = {
                0.8,
                0.8,
                1.0,
            },
            maxHP = 30,
        },
        summonType = "spirit",
        mpCost = 20,
        name = "Summon Ancestor Spirit",
        maxLevel = 5,
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                passiveBuffs = {
                    wisdom_bonus = 5 + (level * 2),
                    magic_defense_bonus = 10 + (level * 3)
                },
                duration = 300 + (level * 60)
            }
        end,
        duration = 300,
    },
    Taunt = {
        description = "Force an enemy to attack you for 2 turns.",
        type = "utility",
        effect = {
            stat = "taunt",
            value = true,
            duration = 2,
        },
        basePower = 0,
        mpCost = 4,
        name = "Taunt",
        target = "single_enemy",
        castingTime = 0,
        levelModifier = function(level) return 1 + level end,
        maxLevel = 3,
    },
    InnerFocus = {
        description = "Buff self's evasion and accuracy for 3 turns.",
        type = "support",
        effect = {
            stats = {
                evasion = 10,
                accuracy = 10,
            },
            duration = 3,
        },
        basePower = 0,
        mpCost = 6,
        name = "Inner Focus",
        target = "self",
        levelModifier = function(level)
            return { evasion = 10 + (level * 2), accuracy = 10 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    MagicWard = {
        description = "Increases magic defense for 3 turns.",
        type = "support",
        effect = {
            stat = "magic_defense",
            value = 5,
            duration = 3,
        },
        basePower = 0,
        mpCost = 8,
        name = "Magic Ward",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 5 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    SummonGuardianSpirit = {
        description = "Summon a protective guardian spirit to enhance defense.",
        type = "summon",
        summonStats = {
            name = "Guardian Spirit",
            passiveBuffs = {
                defense_bonus = 10,
                damage_reduction = 0.1,
            },
            color = {
                0.7,
                0.7,
                0.9,
            },
            maxHP = 30,
        },
        summonType = "spirit",
        mpCost = 20,
        name = "Summon Guardian Spirit",
        maxLevel = 5,
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                passiveBuffs = {
                    defense_bonus = 10 + (level * 3),
                    damage_reduction = 0.1 + (level * 0.02)
                },
                duration = 300 + (level * 60)
            }
        end,
        duration = 300,
    },
    ShadowMerge = {
        description = "Merge with shadows, becoming untargetable for 2 turns.",
        type = "utility",
        effect = {
            stat = "untargetable",
            value = true,
            duration = 2,
        },
        basePower = 0,
        mpCost = 20,
        name = "Shadow Merge",
        target = "self",
        levelModifier = function(level) 
            return {
                duration = 2 + level
            }
        end,
        maxLevel = 3,
    },
    Enlightenment = {
        description = "Party-wide buff to all stats for 3 turns.",
        type = "support",
        effect = {
            stat = "all",
            value = 5,
            duration = 3,
        },
        basePower = 0,
        mpCost = 20,
        name = "Enlightenment",
        target = "all_allies",
        levelModifier = function(level)
            return { value = 5 + level, duration = 3 + level }
        end,
        maxLevel = 3,
    },
    BallistaPoisonMod = {
        name = "Ballista Poison Mod",
        description = "Modify a ballista to shoot poison-tipped projectiles for 2 turns.",
        type = "physical",
        target = "single_enemy",
        element = nil,
        mpCost = 15,
        basePower = 100,
        castingTime = 3,
        maxLevel = 3,
        incantationPhrases = {
            ["1"] = nil,
        },
        sprite = nil,
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                -- Save original abilities
                target.originalAbilities = target.abilities
                target.abilities = {"ballista_poison_shot"}
                target.elementalModDuration = 2
                
                -- Use minionManager to modify ballista
                combatSystem.minionManager:modifyBallistaAttack(target, "poison", 2)
                
                return {
                    {message = caster.name .. " modifies " .. target.name .. " with poison ammunition!", color = {0.5, 0.9, 0.5}}
                }
            end
            return {
                {message = "Failed to modify. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        levelModifier = function(level)
            return 1 + (level * 0.1) -- 10% more effectiveness per level
        end,
        targetFilter = "ballista",
    },
    SummonAirElemental = {
        description = "Summon a swift air elemental with evasive abilities.",
        type = "summon",
        summonStats = {
            defense = 6,
            magicPower = 16,
            speed = 18,
            attackPower = 14,
            maxHP = 60,
            name = "Air Elemental",
            color = {
                0.8,
                0.8,
                1.0,
            },
            abilities = {
                "LightningStrike",
                "GustOfWind",
            },
            magicDefense = 14,
        },
        summonType = "elemental",
        mpCost = 25,
        name = "Summon Air Elemental",
        maxLevel = 5,
        element = "air",
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end,
        duration = 0,
    },
    ElementalBurst = {
        description = "Releases a burst of elemental energy affecting all enemies.",
        type = "magical",
        basePower = 100,
        mpCost = 15,
        name = "Elemental Burst",
        element = "random",
        target = "all_enemies",
        formula = "magical",
        levelModifier = function(level) return 1 + (level * 0.1) end,
        maxLevel = 5,
    },
    GroupHeal = {
        description = "Restores HP to all allies.",
        type = "healing",
        incantationPhrases = {
            "By the light that binds us...",
            "Let healing energy flow through me...",
            "Restore what was broken!",
        },
        basePower = 80,
        mpCost = 20,
        name = "Group Heal",
        castingTime = 3,
        target = "all_allies",
        formula = "healing",
        levelModifier = function(level) return 1 + (level * 0.1) end,
        maxLevel = 5,
    },
    PalmThrust = {
        description = "A powerful strike with high critical chance.",
        type = "physical",
        target = "single_enemy",
        basePower = 120,
        mpCost = 10,
        name = "Palm Thrust",
        damageType = "bludgeoning",
        critChance = 0.3,
        formula = "physical",
        critModifier = 2.0,
        levelModifier = function(level)
            return { power = 1 + (level * 0.08), critChance = 0.3 + (level * 0.03) }
        end,
        maxLevel = 5,
    },
    DUNGEON_STUN_TRAP_EFFECT = {
        description = "Effect of a thrown stun trap",
        name = "Stun Trap Effect",
        type = "PRE_COMBAT_TRAP",
        effects = {
            {
                status_effect = "STUN",
                chance = 0.9,
                type = "APPLY_STATUS",
                duration = 1,
            },
        },
        target = "single_enemy",
    },
    DrainLife = {
        description = "Drains life from a target to heal the caster.",
        type = "magical",
        effect = {
            lifeDrain = true,
            drainPercent = 0.5,
        },
        basePower = 90,
        mpCost = 12,
        name = "Drain Life",
        element = "dark",
        target = "single_enemy",
        formula = "magical",
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                drainPercent = 0.5 + (level * 0.05)
            }
        end,
        maxLevel = 5,
    },
    GrandmastersFury = {
        description = "A devastating multi-hit attack.",
        type = "physical",
        basePower = 60,
        mpCost = 20,
        name = "Grandmaster's Fury",
        hits = 5,
        damageType = "bludgeoning",
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.08) end,
        maxLevel = 5,
    },
    Silence = {
        description = "Prevents enemy from casting spells for 2 turns.",
        type = "debuff",
        effect = {
            stat = "silence",
            value = true,
            duration = 2,
        },
        basePower = 0,
        mpCost = 7,
        name = "Silence",
        target = "single_enemy",
        levelModifier = function(level)
            return { duration = 2 + level } end,
        maxLevel = 3,
    },
    Wither = {
        description = "Deals damage over time for 3 turns.",
        type = "debuff",
        effect = {
            value = 20,
            type = "dot",
            duration = 3,
        },
        basePower = 20,
        mpCost = 8,
        name = "Wither",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = 20 + (level * 5), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    BlessingOfEndurance = {
        description = "Buff, increase max HP and defense for 3 turns.",
        type = "support",
        effect = {
            stats = {
                defense = 10,
                maxHP = 20,
            },
            duration = 3,
        },
        basePower = 0,
        mpCost = 10,
        name = "Blessing of Endurance",
        target = "single_ally",
        levelModifier = function(level)
            return { maxHP = 20 + (level * 5), defense = 10 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    PurifyingStrike = {
        description = "Attack that removes debuffs from self or ally.",
        type = "physical",
        effect = {
            removeDebuff = true,
        },
        basePower = 90,
        mpCost = 8,
        name = "Purifying Strike",
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.08) end,
        maxLevel = 5,
    },
    SummonEarthElemental = {
        description = "Summon a defensive earth elemental.",
        type = "summon",
        summonStats = {
            defense = 20,
            name = "Earth Elemental",
            color = {
                0.6,
                0.4,
                0.2,
            },
            maxHP = 100,
            speed = 5,
            abilities = {
                "RockThrow",
                "StoneArmor",
            },
            attackPower = 18,
            magicDefense = 10,
        },
        summonType = "elemental",
        mpCost = 25,
        name = "Summon Earth Elemental",
        maxLevel = 5,
        element = "earth",
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end,
        duration = 0,
    },
    PressurePoint = {
        description = "Strike a weak spot, reducing enemy attack and defense for 2 turns.",
        type = "debuff",
        effect = {
            stats = {
                attack = -5,
                defense = -5,
            },
            duration = 2,
        },
        basePower = 0,
        mpCost = 8,
        name = "Pressure Point",
        target = "single_enemy",
        levelModifier = function(level)
            return { attack = -5 - level, defense = -5 - level, duration = 2 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    CurseOfFrailty = {
        description = "Reduces enemy defense for 3 turns.",
        type = "debuff",
        effect = {
            stat = "defense",
            value = -3,
            duration = 3,
        },
        basePower = 0,
        mpCost = 8,
        name = "Curse of Frailty",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = -3 - level, duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    ChiWave = {
        description = "A wave of spiritual energy that damages all enemies.",
        type = "magical",
        basePower = 90,
        mpCost = 18,
        name = "Chi Wave",
        damageType = "force",
        target = "all_enemies",
        formula = "magical",
        levelModifier = function(level) return 1 + (level * 0.08) end,
        maxLevel = 5,
    },
    Hex = {
        description = "Applies a strong curse, reducing all stats for 3 turns.",
        type = "debuff",
        effect = {
            stat = "all",
            value = -2,
            duration = 3,
        },
        basePower = 0,
        mpCost = 10,
        name = "Hex",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = -2 - level, duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    SummonWaterElemental = {
        description = "Summon a water elemental with healing abilities.",
        type = "summon",
        summonStats = {
            defense = 10,
            magicPower = 18,
            speed = 8,
            attackPower = 12,
            maxHP = 80,
            name = "Water Elemental",
            color = {
                0.2,
                0.5,
                0.9,
            },
            abilities = {
                "WaterJet",
                "HealingRain",
            },
            magicDefense = 15,
        },
        summonType = "elemental",
        mpCost = 25,
        name = "Summon Water Elemental",
        maxLevel = 5,
        element = "water",
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end,
        duration = 0,
    },
    ShieldBash = {
        description = "Bash with shield for damage and chance to stun.",
        type = "physical",
        effect = {
            chance = 0.3,
            strength = 1,
            type = "stun",
            duration = 1,
        },
        basePower = 90,
        mpCost = 6,
        name = "Shield Bash",
        damageType = "bludgeoning",
        castingTime = 1,
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                chance = 0.3 + (level * 0.05)
            }
        end,
        maxLevel = 5,
    },
    DoubleSlash = {
        description = "Two quick strikes at 80% power each.",
        type = "physical",
        hits = 2,
        basePower = 80,
        mpCost = 8,
        name = "Double Slash",
        damageType = "slashing",
        target = "single_enemy",
        formula = "physical",
        castingTime = 1,
        levelModifier = function(level) return 1 + (level * 0.05) end,
        maxLevel = 5,
    },
    SummonBallista = {
        description = "Summon a ballista contraption that attacks enemies independently.",
        type = "summon",
        summonStats = {
            defense = 10,
            speed = 5,
            attackPower = 15,
            maxHP = 80,
            name = "Ballista",
            color = {
                0.8,
                0.7,
                0.5,
            },
            sprite = "ballista",
            abilities = {
                "ballista_normal_shot",
            },
            magicDefense = 5,
        },
        incantationPhrases = {
            "Gears and steel, assemble!",
            "By my craft, I command...",
            "Rise, mechanical guardian!",
        },
        basePower = 0,
        mpCost = 25,
        name = "Summon Ballista",
        castingTime = 3,
        target = "self",
        summonType = "ballista",
        levelModifier = function(level)
            return {
                statModifier = 1 + (level * 0.15),
                duration = 0 -- Permanent until destroyed
            }
        end,
        maxLevel = 5,
    },
    RaiseZombie = {
        description = "Summon a powerful but slow zombie to tank damage.",
        type = "summon",
        summonStats = {
            defense = 15,
            name = "Rotting Zombie",
            color = {
                0.2,
                0.6,
                0.2,
            },
            speed = 4,
            abilities = {
                "InfectedBite",
            },
            attackPower = 12,
            maxHP = 120,
        },
        summonType = "undead",
        mpCost = 25,
        name = "Raise Zombie",
        maxLevel = 5,
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2),
                duration = 600 + (level * 120)
            }
        end,
        duration = 600,
    },
    GreaterBlessing = {
        description = "Strong buff to all stats for 3 turns.",
        type = "support",
        effect = {
            stat = "all",
            value = 3,
            duration = 3,
        },
        basePower = 0,
        mpCost = 12,
        name = "Greater Blessing",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 3 + level, duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    Rage = {
        description = "Sacrifice defense for increased attack power.",
        type = "support",
        effect = {
            stats = {
                defense_multiplier = 0.7,
                attack_multiplier = 1.5,
            },
            duration = 3,
        },
        basePower = 0,
        mpCost = 10,
        name = "Rage",
        target = "self",
        levelModifier = function(level) 
            return {
                attack_multiplier = 1.5 + (level * 0.1)
            }
        end,
        maxLevel = 5,
    },
    Defend = {
        description = "Defensive stance that reduces damage taken.",
        type = "support",
        effect = {
            stat = "defense_multiplier",
            value = 1.5,
            duration = 1,
        },
        basePower = 0,
        mpCost = 0,
        name = "Defend",
        target = "self",
        castingTime = 0,
        levelModifier = function(level) return 1.5 + (level * 0.1) end,
        maxLevel = 3,
    },
    Steal = {
        description = "Attempt to steal an item from an enemy.",
        type = "utility",
        effect = {
            stealChance = 0.3,
        },
        basePower = 0,
        mpCost = 0,
        name = "Steal",
        target = "single_enemy",
        levelModifier = function(level) 
            return {
                stealChance = 0.3 + (level * 0.1)
            }
        end,
        maxLevel = 3,
    },
    DUNGEON_NET_TRAP_EFFECT = {
        description = "Effect of a thrown net trap",
        name = "Net Trap Effect",
        type = "PRE_COMBAT_TRAP",
        effects = {
            {
                status_effect = "SLOW",
                chance = 0.9,
                type = "APPLY_STATUS",
                duration = 2,
            },
        },
        target = "single_enemy",
    },
    DivineBlade = {
        description = "A holy attack that deals massive damage.",
        type = "physical",
        basePower = 200,
        mpCost = 25,
        name = "Divine Blade",
        element = "holy",
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.15) end,
        maxLevel = 5,
    },
    ManaShield = {
        description = "Creates a barrier that absorbs damage based on INT.",
        type = "support",
        incantationPhrases = {
            "By the power of my will...",
            "Shield me with arcane force!",
        },
        basePower = 0,
        mpCost = 15,
        name = "Mana Shield",
        castingTime = 2,
        target = "self",
        effect = {
            formula = function(caster) 
                return caster.attributes.INT * 5
            end,
            stat = "barrier",
            duration = 3,
        },
        levelModifier = function(level) 
            return function(caster)
                return caster.attributes.INT * (5 + level)
            end
        end,
        maxLevel = 5,
    },
    SpiritCommunion = {
        description = "Commune with spirits to recover MP and enhance spiritual abilities.",
        type = "support",
        effect = {
            mpRestoreValue = 20,
            restoreMP = true,
            enhanceSpiritBuffs = true,
            duration = 2,
        },
        basePower = 0,
        mpCost = 0,
        name = "Spirit Communion",
        target = "self",
        levelModifier = function(level) 
            return {
                mpRestoreValue = 20 + (level * 5),
                duration = 2 + level
            }
        end,
        maxLevel = 5,
    },
    Heal = {
        description = "Restores HP to one ally.",
        type = "healing",
        basePower = 100,
        mpCost = 8,
        name = "Heal",
        target = "single_ally",
        formula = "healing",
        levelModifier = function(level) return 1 + (level * 0.15) end,
        maxLevel = 5,
    },
    BallistaNetShot = {
        description = "Modify a ballista to shoot a net that can immobilize enemies.",
        type = "buff",
        targetFilter = "ballista",
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                -- Save original abilities
                target.originalAbilities = target.abilities
                target.abilities = {"ballista_net_shot"}
                target.elementalModDuration = 2
                
                -- Use minionManager to modify ballista
                combatSystem.minionManager:modifyBallistaAttack(target, "net", 2)
                
                return {
                    {message = caster.name .. " modifies " .. target.name .. " with net ammunition!", color = {0.7, 0.7, 0.7}}
                }
            end
            return {
                {message = "Failed to modify. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        basePower = 0,
        mpCost = 15,
        name = "Ballista Net Shot",
        target = "minion",
        castingTime = 1,
        levelModifier = function(level)
            return 1 + (level * 0.1) -- 10% more effectiveness per level
        end,
        maxLevel = 3,
    },
    IceShard = {
        description = "An ice attack with chance to slow the target.",
        type = "magical",
        basePower = 100,
        effect = {
            stat = "speed_multiplier",
            chance = 0.4,
            value = 0.7,
            duration = 2,
        },
        castingTime = 1,
        mpCost = 8,
        name = "Ice Shard",
        damageType = "ice",
        element = "ice",
        target = "single_enemy",
        formula = "magical",
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                chance = 0.4 + (level * 0.05)
            }
        end,
        maxLevel = 5,
    },
    DarkCommand = {
        description = "Enhance your undead minions with dark energy, increasing their power.",
        type = "support",
        effect = {
            stat = "attack_multiplier",
            value = 1.5,
            duration = 3,
        },
        basePower = 0,
        mpCost = 15,
        name = "Dark Command",
        target = "all_minions",
        levelModifier = function(level) 
            return {
                value = 1.5 + (level * 0.1),
                duration = 3 + level
            }
        end,
        maxLevel = 5,
    },
    ShieldWall = {
        description = "Greatly increases defense for 3 turns.",
        type = "support",
        effect = {
            stat = "defense_multiplier",
            value = 2.0,
            duration = 3,
        },
        basePower = 0,
        mpCost = 12,
        name = "Shield Wall",
        target = "self",
        levelModifier = function(level) 
            return {
                value = 2.0 + (level * 0.2)
            }
        end,
        maxLevel = 5,
    },
    MinorBlessing = {
        description = "Buffs one ally's main stat for 3 turns.",
        type = "support",
        effect = {
            stat = "main_stat",
            value = 2,
            duration = 3,
        },
        basePower = 0,
        mpCost = 6,
        name = "Minor Blessing",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 2 + level, duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    SpiritSight = {
        description = "Reveal hidden truths and enemy weaknesses through spiritual vision.",
        type = "support",
        effect = {
            revealWeakness = true,
            duration = 3,
        },
        basePower = 0,
        mpCost = 12,
        name = "Spirit Sight",
        target = "all_enemies",
        levelModifier = function(level) 
            return {
                duration = 3 + level
            }
        end,
        maxLevel = 3,
    },
    ThunderBolt = {
        description = "Lightning attack with increased critical hit chance.",
        type = "magical",
        basePower = 110,
        critChance = 0.2,
        critModifier = 2.0,
        incantationPhrases = {
            "Storms, heed my call!",
            "Strike down with thunder's might!",
        },
        castingTime = 2,
        mpCost = 10,
        name = "Thunder Bolt",
        damageType = "lightning",
        element = "lightning",
        formula = "magical",
        target = "single_enemy",
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.08),
                critChance = 0.2 + (level * 0.04)
            }
        end,
        maxLevel = 5,
    },
    DUNGEON_POISON_TRAP_EFFECT = {
        description = "Effect of a thrown poison trap",
        name = "Poison Trap Effect",
        type = "PRE_COMBAT_TRAP",
        effects = {
            {
                chance = 0.9,
                type = "APPLY_STATUS",
                base_damage = 5,
                status_effect = "POISON",
                duration = 3,
            },
        },
        target = "single_enemy",
    },
    Purify = {
        description = "Removes negative status effects from an ally.",
        name = "Purify",
        type = "healing",
        maxLevel = 3,
        target = "single_ally",
        mpCost = 6,
        effect = {
            healing = function(level, caster) 
                return caster.attributes.WIS * level * 2
            end,
            removeStatus = "negative",
        },
        basePower = 0,
    },
    PreciseStrike = {
        description = "A precise attack with increased critical hit chance.",
        type = "physical",
        useDexForCrit = true,
        basePower = 90,
        mpCost = 5,
        name = "Precise Strike",
        critChance = 0.25,
        critModifier = 2.5,
        formula = "physical",
        target = "single_enemy",
        levelModifier = function(level) 
            return {
                power = 1 + (level * 0.06)
            }
        end,
        maxLevel = 5,
    },
    Smite = {
        description = "Holy damage against a single enemy.",
        type = "magical",
        basePower = 130,
        mpCost = 10,
        name = "Smite",
        element = "holy",
        target = "single_enemy",
        formula = "magical",
        levelModifier = function(level) return 1 + (level * 0.12) end,
        maxLevel = 5,
    },
    DeathPact = {
        description = "Sacrifice an undead minion to heal yourself and gain a power boost.",
        type = "support",
        effect = {
            healPercent = 0.5,
            powerBoost = {
                stat = "attack_multiplier",
                value = 1.3,
                duration = 3,
            },
            sacrificeMinion = true,
        },
        basePower = 0,
        mpCost = 10,
        name = "Death Pact",
        target = "single_minion",
        levelModifier = function(level) 
            return {
                healPercent = 0.5 + (level * 0.1),
                powerBoost = {
                    value = 1.3 + (level * 0.1),
                    duration = 3 + level
                }
            }
        end,
        maxLevel = 5,
    },
    SummonFireElemental = {
        description = "Summon a fire elemental to burn enemies.",
        type = "summon",
        summonStats = {
            defense = 8,
            magicPower = 20,
            speed = 10,
            attackPower = 15,
            maxHP = 70,
            name = "Fire Elemental",
            color = {
                0.9,
                0.3,
                0.1,
            },
            abilities = {
                "Fireball",
                "BurningTouch",
            },
            magicDefense = 12,
        },
        summonType = "elemental",
        mpCost = 25,
        name = "Summon Fire Elemental",
        maxLevel = 5,
        element = "fire",
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2)
            }
        end,
        duration = 0,
    },
    BallistaOvercharge = {
        description = "Overcharge a ballista for its next shot, significantly increasing damage.",
        type = "buff",
        targetFilter = "ballista",
        incantationPhrases = {
            "Channel more power through the mechanisms...",
            "Overload the firing chamber!",
        },
        basePower = 0,
        mpCost = 20,
        name = "Ballista Overcharge",
        castingTime = 2,
        target = "minion",
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                -- Replace current ability with overcharge ability
                target.originalAbilities = target.abilities
                target.abilities = {"ballista_overcharge_shot"}
                target.overchargeCount = 1 -- Only lasts for one shot
                
                return {
                    {message = caster.name .. " overcharges " .. target.name .. "!", color = {1, 0.7, 0.2}}
                }
            end
            return {
                {message = "Failed to overcharge. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        levelModifier = function(level)
            return 1 + (level * 0.3) -- 30% more damage per level
        end,
        maxLevel = 3,
    },
    ElementalAffinity = {
        description = "Increases resistance to elemental damage and boosts elemental spell power.",
        type = "support",
        effect = {
            elementalResist = 0.2,
            elementalPower = 1.2,
            duration = 3,
        },
        basePower = 0,
        mpCost = 10,
        name = "Elemental Affinity",
        target = "self",
        levelModifier = function(level) 
            return {
                elementalResist = 0.2 + (level * 0.05),
                elementalPower = 1.2 + (level * 0.1),
                duration = 3 + level
            }
        end,
        maxLevel = 5,
    },
    DivineFavor = {
        description = "Increases an ally's attack and defense for 3 turns.",
        type = "support",
        effect = {
            stats = {
                defense_multiplier = 1.2,
                attack_multiplier = 1.2,
            },
            duration = 3,
        },
        basePower = 0,
        mpCost = 12,
        name = "Divine Favor",
        target = "single_ally",
        levelModifier = function(level) 
            return {
                attack_multiplier = 1.2 + (level * 0.05),
                defense_multiplier = 1.2 + (level * 0.05)
            }
        end,
        maxLevel = 5,
    },
    ArcaneMastery = {
        description = "Increases the power of all spells for 5 turns.",
        type = "support",
        effect = {
            stat = "magic_multiplier",
            value = 1.5,
            duration = 5,
        },
        basePower = 0,
        mpCost = 30,
        name = "Arcane Mastery",
        target = "self",
        levelModifier = function(level) 
            return {
                value = 1.5 + (level * 0.1)
            }
        end,
        maxLevel = 5,
    },
    RaiseWraith = {
        description = "Summon a spectral wraith with powerful dark magic.",
        type = "summon",
        summonStats = {
            defense = 8,
            magicPower = 25,
            speed = 9,
            attackPower = 10,
            maxHP = 80,
            name = "Shadow Wraith",
            color = {
                0.4,
                0.0,
                0.6,
            },
            abilities = {
                "SoulDrain",
                "ShadowBolt",
            },
            magicDefense = 18,
        },
        summonType = "undead",
        mpCost = 40,
        name = "Raise Wraith",
        maxLevel = 5,
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2),
                duration = 480 + (level * 60)
            }
        end,
        duration = 480,
    },
    Fortify = {
        description = "Increases defense for 3 turns.",
        type = "support",
        effect = {
            stat = "defense",
            value = 5,
            duration = 3,
        },
        basePower = 0,
        mpCost = 8,
        name = "Fortify",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 5 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    SummonNatureSpirit = {
        description = "Summon a nature spirit to enhance vitality and regeneration.",
        type = "summon",
        summonStats = {
            name = "Nature Spirit",
            passiveBuffs = {
                poison_resist = 0.5,
                hp_regeneration = 3,
            },
            color = {
                0.3,
                0.8,
                0.3,
            },
            maxHP = 30,
        },
        summonType = "spirit",
        mpCost = 20,
        name = "Summon Nature Spirit",
        maxLevel = 5,
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                passiveBuffs = {
                    hp_regeneration = 3 + level,
                    poison_resist = 0.5 + (level * 0.1)
                },
                duration = 300 + (level * 60)
            }
        end,
        duration = 300,
    },
    CurseOfWeakness = {
        description = "Weakens a target, reducing their attack power.",
        type = "magical",
        effect = {
            stat = "attack_multiplier",
            value = 0.7,
            duration = 3,
        },
        basePower = 0,
        mpCost = 10,
        name = "Curse of Weakness",
        element = "dark",
        target = "single_enemy",
        levelModifier = function(level) 
            return {
                value = 0.7 - (level * 0.05),
                duration = 3 + level
            }
        end,
        maxLevel = 5,
    },
    ShadowBolt = {
        description = "Unleashes a bolt of dark energy at a target.",
        type = "magical",
        basePower = 130,
        mpCost = 8,
        name = "Shadow Bolt",
        element = "dark",
        target = "single_enemy",
        formula = "magical",
        levelModifier = function(level) return 1 + (level * 0.1) end,
        maxLevel = 5,
    },
    Regeneration = {
        description = "Restores HP over 3 turns.",
        type = "healing",
        effect = {
            stat = "hp_regen",
            value = 10,
            duration = 3,
        },
        basePower = 0,
        mpCost = 10,
        name = "Regeneration",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 10 + (level * 3), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    AncestralGuidance = {
        description = "Call upon ancestral spirits to guide allies, increasing their accuracy.",
        type = "support",
        effect = {
            stat = "accuracy_multiplier",
            value = 1.3,
            duration = 3,
        },
        basePower = 0,
        mpCost = 15,
        name = "Ancestral Guidance",
        target = "all_allies",
        levelModifier = function(level) 
            return {
                value = 1.3 + (level * 0.1),
                duration = 3 + level
            }
        end,
        maxLevel = 5,
    },
    Attack = {
        description = "Basic attack with equipped weapon.",
        type = "physical",
        basePower = 100,
        mpCost = 0,
        name = "Attack",
        damageType = "physical",
        castingTime = 0,
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.05) end,
        maxLevel = 5,
    },
    IronBody = {
        description = "Increase defense for 3 turns.",
        type = "support",
        effect = {
            stat = "defense",
            value = 10,
            duration = 3,
        },
        basePower = 0,
        mpCost = 7,
        name = "Iron Body",
        target = "self",
        levelModifier = function(level)
            return { value = 10 + (level * 3), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    Focus = {
        description = "Increases self's magic power for 2 turns.",
        type = "support",
        effect = {
            stat = "magic_power",
            value = 3,
            duration = 2,
        },
        basePower = 0,
        mpCost = 4,
        name = "Focus",
        target = "self",
        levelModifier = function(level)
            return { value = 3 + level, duration = 2 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    ElementalMastery = {
        description = "Enhance the power of your elemental summons.",
        type = "support",
        effect = {
            stats = {
                attack_multiplier = 1.3,
                magic_multiplier = 1.3,
            },
            duration = 3,
        },
        basePower = 0,
        mpCost = 15,
        name = "Elemental Mastery",
        target = "all_minions",
        levelModifier = function(level) 
            return {
                attack_multiplier = 1.3 + (level * 0.1),
                magic_multiplier = 1.3 + (level * 0.1),
                duration = 3 + level
            }
        end,
        maxLevel = 5,
    },
    SacredPalm = {
        description = "A holy unarmed attack.",
        type = "magical",
        basePower = 110,
        mpCost = 10,
        name = "Sacred Palm",
        damageType = "holy",
        element = "holy",
        target = "single_enemy",
        formula = "magical",
        levelModifier = function(level) return 1 + (level * 0.08) end,
        maxLevel = 5,
    },
    ["BallistaElementalMod:Fire"] = {
        description = "Modify a ballista to shoot flaming projectiles for 2 turns.",
        type = "buff",
        targetFilter = "ballista",
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                -- Save original abilities
                target.originalAbilities = target.abilities
                target.abilities = {"ballista_fire_shot"}
                target.elementalModDuration = 2
                
                -- Use minionManager to modify ballista
                combatSystem.minionManager:modifyBallistaAttack(target, "fire", 2)
                
                return {
                    {message = caster.name .. " modifies " .. target.name .. " with fire ammunition!", color = {1, 0.5, 0.2}}
                }
            end
            return {
                {message = "Failed to modify. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        basePower = 0,
        mpCost = 15,
        name = "Ballista Fire Mod",
        target = "minion",
        castingTime = 1,
        levelModifier = function(level)
            return 1 + (level * 0.1) -- 10% more effectiveness per level
        end,
        maxLevel = 3,
    },
    CounterStance = {
        description = "Prepare to counterattack when hit for 2 turns.",
        type = "support",
        effect = {
            stat = "counter",
            value = true,
            duration = 2,
        },
        basePower = 0,
        mpCost = 8,
        name = "Counter Stance",
        target = "self",
        levelModifier = function(level)
            return { duration = 2 + level } end,
        maxLevel = 3,
    },
    UnarmedStrike = {
        description = "A basic unarmed attack.",
        type = "physical",
        basePower = 100,
        mpCost = 0,
        name = "Unarmed Strike",
        damageType = "bludgeoning",
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.05) end,
        maxLevel = 5,
    },
    DullBlade = {
        description = "Reduces enemy's physical damage for 3 turns.",
        type = "debuff",
        effect = {
            stat = "physical_damage",
            value = -10,
            duration = 3,
        },
        basePower = 0,
        mpCost = 6,
        name = "Dull Blade",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = -10 - (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    Clarity = {
        description = "Increases MP regen for 3 turns.",
        type = "support",
        effect = {
            stat = "mp_regen",
            value = 5,
            duration = 3,
        },
        basePower = 0,
        mpCost = 5,
        name = "Clarity",
        target = "self",
        levelModifier = function(level)
            return { value = 5 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    FireBolt = {
        description = "A basic fire attack spell.",
        type = "magical",
        castingTime = 2,
        formula = "magical",
        incantationPhrases = {
            "I call upon the flames of destruction...",
            "Let fire consume my enemies!!!",
        },
        basePower = 120,
        mpCost = 6,
        name = "Fire Bolt",
        damageType = "fire",
        element = "fire",
        target = "single_enemy",
        effect = {
            strength = 1,
            chance = 0.3,
            type = "burn",
            duration = 2,
        },
        levelModifier = function(level) return 1 + (level * 0.1) end,
        maxLevel = 5,
    },
    Renewal = {
        description = "Heal self or an ally.",
        type = "healing",
        basePower = 100,
        mpCost = 10,
        name = "Renewal",
        target = "single_ally",
        formula = "healing",
        levelModifier = function(level) return 1 + (level * 0.12) end,
        maxLevel = 5,
    },
    Flurry = {
        description = "A rapid series of unarmed strikes.",
        type = "physical",
        basePower = 50,
        mpCost = 10,
        name = "Flurry",
        hits = 3,
        damageType = "bludgeoning",
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.05) end,
        maxLevel = 5,
    },
    PowerStrike = {
        description = "A powerful strike that deals 150% damage.",
        type = "physical",
        basePower = 150,
        mpCost = 5,
        name = "Power Strike",
        damageType = "physical",
        castingTime = 1,
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.1) end,
        maxLevel = 5,
    },
    Haste = {
        description = "Increases speed for 3 turns.",
        type = "support",
        effect = {
            stat = "speed",
            value = 10,
            duration = 3,
        },
        basePower = 0,
        mpCost = 8,
        name = "Haste",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 10 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    Inspire = {
        description = "Increases attack for 3 turns.",
        type = "support",
        effect = {
            stat = "attack",
            value = 5,
            duration = 3,
        },
        basePower = 0,
        mpCost = 8,
        name = "Inspire",
        target = "single_ally",
        levelModifier = function(level)
            return { value = 5 + (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    Torment = {
        description = "Reduces healing received for 3 turns.",
        type = "debuff",
        effect = {
            stat = "healing_received",
            value = -25,
            duration = 3,
        },
        basePower = 0,
        mpCost = 8,
        name = "Torment",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = -25 - (level * 5), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    ChiBurst = {
        description = "A ranged burst of spiritual energy.",
        type = "magical",
        basePower = 120,
        mpCost = 10,
        name = "Chi Burst",
        damageType = "force",
        target = "single_enemy",
        formula = "magical",
        levelModifier = function(level) return 1 + (level * 0.08) end,
        maxLevel = 5,
    },
    Fireball = {
        description = "A powerful fire spell that hits all enemies.",
        type = "magical",
        incantationPhrases = {
            "By the ancient fires...",
            "I gather the flames of chaos...",
            "Explosion of infernal power!",
        },
        castingTime = 3,
        mpCost = 18,
        name = "Fireball",
        target = "all_enemies",
        element = "fire",
        formula = "magical",
        basePower = 90,
        levelModifier = function(level) return 1 + (level * 0.1) end,
        maxLevel = 5,
    },
    QuickRecovery = {
        description = "Removes a debuff from an ally.",
        name = "Quick Recovery",
        type = "support",
        basePower = 0,
        target = "single_ally",
        mpCost = 5,
        effect = {
            removeDebuff = true,
        },
        maxLevel = 3,
    },
    FlowingStance = {
        description = "Adopt a stance that increases dodge and counter chance for 2 turns.",
        type = "support",
        effect = {
            stats = {
                dodge = 15,
                counter = 15,
            },
            duration = 2,
        },
        basePower = 0,
        mpCost = 8,
        name = "Flowing Stance",
        target = "self",
        levelModifier = function(level)
            return { dodge = 15 + (level * 2), counter = 15 + (level * 2), duration = 2 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    Weaken = {
        description = "Reduces one enemy's attack for 3 turns.",
        type = "debuff",
        effect = {
            stat = "attack",
            value = -2,
            duration = 3,
        },
        basePower = 0,
        mpCost = 6,
        name = "Weaken",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = -2 - level, duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    EvilEye = {
        description = "Reduces enemy accuracy for 3 turns.",
        type = "debuff",
        effect = {
            stat = "accuracy",
            value = -10,
            duration = 3,
        },
        basePower = 0,
        mpCost = 6,
        name = "Evil Eye",
        target = "single_enemy",
        levelModifier = function(level)
            return { value = -10 - (level * 2), duration = 3 + math.floor(level/2) }
        end,
        maxLevel = 5,
    },
    ["BallistaElementalMod:Ice"] = {
        description = "Modify a ballista to shoot freezing projectiles for 2 turns.",
        type = "buff",
        targetFilter = "ballista",
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                -- Save original abilities
                target.originalAbilities = target.abilities
                target.abilities = {"ballista_ice_shot"}
                target.elementalModDuration = 2
                
                -- Use minionManager to modify ballista
                combatSystem.minionManager:modifyBallistaAttack(target, "ice", 2)
                
                return {
                    {message = caster.name .. " modifies " .. target.name .. " with ice ammunition!", color = {0.5, 0.7, 1}}
                }
            end
            return {
                {message = "Failed to modify. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        basePower = 0,
        mpCost = 15,
        name = "Ballista Ice Mod",
        target = "minion",
        castingTime = 1,
        levelModifier = function(level)
            return 1 + (level * 0.1) -- 10% more effectiveness per level
        end,
        maxLevel = 3,
    },
    PerfectBody = {
        description = "Massive self-buff to all stats and regeneration for 3 turns.",
        type = "support",
        effect = {
            stats = {
                WIL = 5,
                DEX = 5,
                CON = 5,
                STR = 5,
                hp_regen = 20,
            },
            duration = 3,
        },
        basePower = 0,
        mpCost = 20,
        name = "Perfect Body",
        target = "self",
        levelModifier = function(level)
            return { STR = 5 + level, DEX = 5 + level, WIL = 5 + level, CON = 5 + level, hp_regen = 20 + (level * 5), duration = 3 + level }
        end,
        maxLevel = 3,
    },
    RaiseSkeleton = {
        description = "Summon a skeletal warrior to fight for you.",
        type = "summon",
        summonStats = {
            defense = 10,
            name = "Skeleton Warrior",
            color = {
                0.8,
                0.8,
                0.8,
            },
            speed = 7,
            abilities = {
                "skeleton_bone_strike",
            },
            attackPower = 15,
            maxHP = 60,
        },
        summonType = "undead",
        mpCost = 20,
        name = "Raise Skeleton",
        maxLevel = 5,
        target = "none",
        basePower = 0,
        levelModifier = function(level) 
            return {
                statModifier = 1 + (level * 0.2),
                duration = 600 + (level * 120)
            }
        end,
        duration = 600,
    },
    BallistaRepair = {
        description = "Repair a damaged ballista, restoring its HP.",
        type = "heal",
        targetFilter = "ballista",
        incantationPhrases = {
            "Tools of my trade, mend what is broken...",
            "Restore function to this machine!",
        },
        basePower = 40,
        mpCost = 15,
        name = "Ballista Repair",
        castingTime = 2,
        target = "minion",
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                local healAmount = 40 * (1 + caster.skillLevels.BallistaRepair * 0.2)
                target.currentHP = math.min(target.maxHP, target.currentHP + healAmount)
                return {
                    {message = caster.name .. " repairs " .. target.name .. " for " .. math.floor(healAmount) .. " HP!", color = {0.5, 0.8, 0.5}}
                }
            end
            return {
                {message = "Failed to repair. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        levelModifier = function(level)
            return 1 + (level * 0.2) -- 20% more healing per level
        end,
        maxLevel = 5,
    },
    RapidStrikes = {
        description = "A flurry of quick blows.",
        type = "physical",
        basePower = 40,
        mpCost = 12,
        name = "Rapid Strikes",
        hits = 4,
        damageType = "bludgeoning",
        target = "single_enemy",
        formula = "physical",
        levelModifier = function(level) return 1 + (level * 0.05) end,
        maxLevel = 5,
    },
    ReloadBallista = {
        description = "Reload a ballista, restoring its ammo to maximum.",
        type = "utility",
        targetFilter = "ballista",
        effect = function(caster, target, combatSystem)
            if target and target.type == "ballista" then
                -- Use the minionManager to reload the ballista
                if combatSystem.minionManager:reloadBallista(target) then
                    return {
                        {message = caster.name .. " reloads " .. target.name .. "!", color = {0.7, 0.8, 0.9}}
                    }
                end
            end
            return {
                {message = "Failed to reload. Not a valid ballista target!", color = {1, 0.5, 0.5}}
            }
        end,
        basePower = 0,
        mpCost = 10,
        name = "Reload Ballista",
        target = "minion",
        castingTime = 1,
        levelModifier = function(level)
            return 1 -- No level scaling necessary
        end,
        maxLevel = 3,
    },
    SpiritVision = {
        description = "Gain insights from the spirit world, revealing enemy weaknesses and secrets.",
        type = "support",
        effect = {
            revealWeakness = true,
            accuracyBoost = 0.2,
            critChanceBoost = 0.1,
            duration = 4,
        },
        basePower = 0,
        mpCost = 15,
        name = "Spirit Vision",
        target = "all_enemies",
        levelModifier = function(level) 
            return {
                accuracyBoost = 0.2 + (level * 0.05),
                critChanceBoost = 0.1 + (level * 0.02),
                duration = 4 + level
            }
        end,
        maxLevel = 5,
    },
}

return skillDefinitions