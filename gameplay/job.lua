-- Job System
-- Defines character jobs, progressions, and abilities

-- Important:
-- All jobs that have name formed by two or more words, need to have those words Capitalized.
-- Example: "Black Mage" instead of "Blackmage", "White Mage" instead of "Whitemage"

local jobSystem = {
    jobs = {}
}

-- Job definitions
jobSystem.jobs = {
    -- Base jobs (tier 1)
    Fighter = {
        name = "Fighter",
        description = "A strong physical combatant skilled with weapons and armor.",
        tier = 1,
        attributeModifiers = {
            STR = 3,
            CON = 2,
            DEX = 1
        },
        startingSkills = {
            "Attack",
            "Defend",
            "PowerStrike"
        },
        availableSkills = {
            "Attack",
            "Defend",
            "PowerStrike",
            "DoubleSlash",
            "Taunt",
            "ShieldBash"
        },
        startingEquipment = {
            weapon = "ShortSword",
            offhand = "WoodenShield",
            body = "LeatherArmor"
        },
        requirements = nil -- No requirements for base jobs
    },

    Mage = {
        name = "Mage",
        description = "A spellcaster who harnesses the power of the elements.",
        tier = 1,
        attributeModifiers = {
            INT = 3,
            WIS = 2,
            WIL = 1
        },
        startingSkills = {
            "Attack",
            "FireBolt",
            "ManaShield"
        },
        availableSkills = {
            "Attack",
            "FireBolt",
            "ManaShield",
            "IceShard",
            "ThunderBolt",
            "MagicBarrier"
        },
        startingEquipment = {
            weapon = "ApprenticeStaff",
            body = "ApprenticeRobe"
        },
        requirements = nil
    },

    Rogue = {
        name = "Rogue",
        description = "A nimble combatant who excels at stealth and precision strikes.",
        tier = 1,
        attributeModifiers = {
            DEX = 3,
            CHA = 2,
            INT = 1
        },
        startingSkills = {
            "Attack",
            "Steal",
            "PreciseStrike"
        },
        availableSkills = {
            "Attack",
            "Steal",
            "PreciseStrike",
            "Backstab",
            "Evasion",
            "PoisonBlade"
        },
        startingEquipment = {
            weapon = "Dagger",
            offhand = "Dagger",
            body = "LightLeather"
        },
        requirements = nil
    },

    Necromancer = {
        name = "Necromancer",
        description = "Master of death who commands undead minions to do their bidding.",
        tier = 3,
        attributeModifiers = {
            INT = 4,
            WIL = 3,
            WIS = 2
        },
        startingSkills = {
            "RaiseSkeleton",
            "DarkCommand"
        },
        availableSkills = {
            "RaiseSkeleton",
            "RaiseZombie",
            "RaiseWraith",
            "DarkCommand",
            "DeathPact",
            "UnholyAura",
            "BoneArmor"
        },
        startingEquipment = {
            weapon = "NecromanticStaff",
            body = "NecromancerRobes"
        },
        requirements = {
            DarkMage = 2
        }
    },

    Cleric = {
        name = "Cleric",
        description = "A holy servant who can heal allies and smite enemies.",
        tier = 1,
        attributeModifiers = {
            WIS = 3,
            WIL = 2,
            CON = 1
        },
        startingSkills = {
            "Attack",
            "Heal",
            "DivineFavor"
        },
        availableSkills = {
            "Attack",
            "Heal",
            "DivineFavor",
            "Purify",
            "Smite",
            "Blessing"
        },
        startingEquipment = {
            weapon = "Mace",
            offhand = "HolySymbol",
            body = "AcolyteRobe"
        },
        requirements = nil
    },

    -- Advanced jobs (tier 2)
    Knight = {
        name = "Knight",
        description = "A heavily armored warrior who excels at defense and protection.",
        tier = 2,
        attributeModifiers = {
            STR = 2,
            CON = 3,
            WIL = 1
        },
        startingSkills = {
            "ShieldWall",
            "Provoke"
        },
        availableSkills = {
            "ShieldWall",
            "Provoke",
            "GuardianStance",
            "HolyStrike",
            "Bulwark",
            "ChivalricOath"
        },
        startingEquipment = {
            weapon = "Longsword",
            offhand = "KiteShield",
            body = "ChainMail"
        },
        requirements = {
            Fighter = 2
        }
    },

    Berserker = {
        name = "Berserker",
        description = "A wild warrior who sacrifices defense for pure offensive power.",
        tier = 2,
        attributeModifiers = {
            STR = 4,
            CON = 1,
            DEX = 1
        },
        startingSkills = {
            "Rage",
            "Cleave"
        },
        availableSkills = {
            "Rage",
            "Cleave",
            "Bloodlust",
            "WarCry",
            "Frenzy",
            "BrutalSwing"
        },
        startingEquipment = {
            weapon = "BattleAxe",
            body = "TribalArmor"
        },
        requirements = {
            Fighter = 10
        }
    },

    BlackMage = {
        name = "Black Mage",
        description = "A devastatingly powerful destructive magic specialist.",
        tier = 2,
        attributeModifiers = {
            INT = 4,
            WIL = 1,
            WIS = 1
        },
        startingSkills = {
            "Fireball",
            "ArcaneAmplify"
        },
        availableSkills = {
            "Fireball",
            "ArcaneAmplify",
            "Thunderstorm",
            "IceSpike",
            "DarkVoid",
            "MeteorShower"
        },
        startingEquipment = {
            weapon = "ElementalRod",
            body = "MageRobe"
        },
        requirements = {
            Mage = 10
        }
    },

    WhiteMage = {
        name = "White Mage",
        description = "A master of healing and supportive magic.",
        tier = 2,
        attributeModifiers = {
            WIS = 3,
            INT = 2,
            WIL = 1
        },
        startingSkills = {
            "GroupHeal",
            "Protection"
        },
        availableSkills = {
            "GroupHeal",
            "Protection",
            "Revive",
            "HolyLight",
            "Regen",
            "Barrier"
        },
        startingEquipment = {
            weapon = "HealingStaff",
            body = "WhiteRobe"
        },
        requirements = {
            Mage = 10,
            Cleric = 5
        }
    },

    Assassin = {
        name = "Assassin",
        description = "A deadly specialist in taking down targets quickly and quietly.",
        tier = 2,
        attributeModifiers = {
            DEX = 4,
            INT = 1,
            STR = 1
        },
        startingSkills = {
            "DeadlyStrike",
            "Vanish"
        },
        availableSkills = {
            "DeadlyStrike",
            "Vanish",
            "PoisonMastery",
            "ShadowStep",
            "VitalStrike",
            "Execution"
        },
        startingEquipment = {
            weapon = "AssassinDagger",
            offhand = "ThrowingKnives",
            body = "ShadowGarb"
        },
        requirements = {
            Rogue = 10
        }
    },

    Ranger = {
        name = "Ranger",
        description = "A skilled marksman who excels at ranged combat.",
        tier = 2,
        attributeModifiers = {
            DEX = 3,
            WIS = 2,
            CON = 1
        },
        startingSkills = {
            "PreciseShot",
            "TrapMastery"
        },
        availableSkills = {
            "PreciseShot",
            "TrapMastery",
            "MultiShot",
            "QuickDraw",
            "HawkEye",
            "CripplingShot"
        },
        startingEquipment = {
            weapon = "Bow",
            offhand = "QuiverOfArrows",
            body = "RangerLeathers"
        },
        requirements = {
            Rogue = 10,
            Fighter = 5
        }
    },

    Paladin = {
        name = "Paladin",
        description = "A holy knight who combines combat prowess with divine magic.",
        tier = 2,
        attributeModifiers = {
            STR = 2,
            WIS = 2,
            CON = 2
        },
        startingSkills = {
            "HolySmite",
            "LayOnHands"
        },
        availableSkills = {
            "HolySmite",
            "LayOnHands",
            "DivineFavor",
            "Consecration",
            "HolyProtection",
            "RighteousStrike"
        },
        startingEquipment = {
            weapon = "BlessedSword",
            offhand = "PaladinShield",
            body = "PaladinArmor"
        },
        requirements = {
            Fighter = 10,
            Cleric = 5
        }
    },

    DarkMage = {
        name = "Dark Mage",
        description = "A mage who delves into necromancy and dark magics.",
        tier = 2,
        attributeModifiers = {
            INT = 3,
            WIL = 3,
            WIS = 1
        },
        startingSkills = {
            "ShadowBolt",
            "DrainLife"
        },
        availableSkills = {
            "ShadowBolt",
            "DrainLife",
            "CurseOfWeakness",
            "SoulDrain",
            "DarkPact"
        },
        startingEquipment = {
            weapon = "DarkStaff",
            body = "DarkRobe"
        },
        requirements = {
            Mage = 3
        }
    },

    ElementalMage = {
        name = "Elemental Mage",
        description = "A mage who specializes in commanding the raw elemental forces.",
        tier = 2,
        attributeModifiers = {
            INT = 4,
            WIS = 2,
            DEX = 1
        },
        startingSkills = {
            "ElementalBurst",
            "ElementalAffinity"
        },
        availableSkills = {
            "ElementalBurst",
            "ElementalAffinity",
            "ElementalShield",
            "ElementalConversion",
            "ElementalFocus"
        },
        startingEquipment = {
            weapon = "ElementalOrb",
            body = "ElementalistRobe"
        },
        requirements = {
            Mage = 3
        }
    },

    SpiritSpeaker = {
        name = "Spirit Speaker",
        description = "A cleric who can commune with and channel spirits from beyond.",
        tier = 2,
        attributeModifiers = {
            WIS = 3,
            CHA = 3,
            WIL = 2
        },
        startingSkills = {
            "SpiritSight",
            "AncestralGuidance"
        },
        availableSkills = {
            "SpiritSight",
            "AncestralGuidance",
            "SpiritShield",
            "VoiceOfTheAncestors",
            "SoulResonance"
        },
        startingEquipment = {
            weapon = "SpiritCharm",
            body = "CeremonyRobes"
        },
        requirements = {
            Cleric = 10
        }
    },

    -- Master jobs (tier 3)
    HolyKnight = {
        name = "Holy Knight",
        description = "A divine warrior blessed with overwhelming holy power.",
        tier = 3,
        attributeModifiers = {
            STR = 3,
            WIS = 3,
            CON = 2,
            WIL = 2
        },
        startingSkills = {
            "DivineBlade",
            "SacredOath"
        },
        availableSkills = {
            "DivineBlade",
            "SacredOath",
            "HolyExplosion",
            "ImmortalSpirit",
            "JudgmentStrike",
            "SacredProtection"
        },
        startingEquipment = {
            weapon = "SacredBlade",
            offhand = "DivineAegis",
            body = "HolyCrusaderArmor"
        },
        requirements = {
            Paladin = 15,
            Knight = 10
        }
    },

    Archmage = {
        name = "Archmage",
        description = "A legendary mage who has mastered all forms of magic.",
        tier = 3,
        attributeModifiers = {
            INT = 4,
            WIS = 3,
            WIL = 3
        },
        startingSkills = {
            "ArcaneMastery",
            "ElementalConversion"
        },
        availableSkills = {
            "ArcaneMastery",
            "ElementalConversion",
            "TrueSpell",
            "ArcaneBarrage",
            "DimensionalRift",
            "TimeStop"
        },
        startingEquipment = {
            weapon = "ArchmageStaff",
            body = "ArchmagerobeOfPower"
        },
        requirements = {
            BlackMage = 15,
            WhiteMage = 10
        }
    },

    Shadowblade = {
        name = "Shadowblade",
        description = "A master assassin who has merged with the shadows themselves.",
        tier = 3,
        attributeModifiers = {
            DEX = 5,
            INT = 2,
            CHA = 3
        },
        startingSkills = {
            "ShadowMerge",
            "DeathMark"
        },
        availableSkills = {
            "ShadowMerge",
            "DeathMark",
            "PhantomStrike",
            "ShadowClones",
            "VoidWalk",
            "AssassinateNullifier"
        },
        startingEquipment = {
            weapon = "ShadowbladeDaggers",
            body = "ShadowWalkerCloak"
        },
        requirements = {
            Assassin = 15,
            BlackMage = 5
        }
    },

   

    Conjurer = {
        name = "Conjurer",
        description = "Elementalist who summons powerful elemental beings to fight alongside them.",
        tier = 3,
        attributeModifiers = {
            INT = 5,
            WIS = 2,
            DEX = 2
        },
        startingSkills = {
            "SummonFireElemental",
            "ElementalMastery"
        },
        availableSkills = {
            "SummonFireElemental",
            "SummonWaterElemental",
            "SummonEarthElemental",
            "SummonAirElemental",
            "ElementalMastery",
            "ElementalFusion",
            "ElementalSurge"
        },
        startingEquipment = {
            weapon = "ElementalTome",
            body = "ConjurerVestments"
        },
        requirements = {
            ElementalMage = 15
        }
    },

    Shaman = {
        name = "Shaman",
        description = "Spiritual leader who communes with ancestral and nature spirits for guidance and power.",
        tier = 3,
        attributeModifiers = {
            WIS = 4,
            CHA = 3,
            CON = 2
        },
        startingSkills = {
            "SummonAncestorSpirit",
            "SpiritCommunion"
        },
        availableSkills = {
            "SummonAncestorSpirit",
            "SummonNatureSpirit",
            "SummonGuardianSpirit",
            "SpiritCommunion",
            "SpiritVision",
            "SpiritualHealing",
            "TotemicBond"
        },
        startingEquipment = {
            weapon = "ShamanTotem",
            body = "SpiritualRegalia"
        },
        requirements = {
            SpiritSpeaker = 15
        }
    }
}

-- Get a job definition by name
function jobSystem:getJob(name)
    name = name:gsub("%s+", "")
    return self.jobs[name]
end

-- Get all available jobs for a character
function jobSystem:getAvailableJobs(character)
    local available = {}

    -- Ensure character has required fields
    if not character then
        print("Warning: Called getAvailableJobs with nil character")
        return available
    end

    -- Ensure jobLevels exists
    if not character.jobLevels then
        print("Warning: Character " .. character.name .. " missing jobLevels table")
        character.jobLevels = {}
    end

    for name, job in pairs(self.jobs) do
        local canAccess = true
        
        -- Check requirements
        if job.requirements then
            for reqJob, reqLevel in pairs(job.requirements) do
                -- Check jobLevels table instead of jobHistory                
                -- Plase check comment at the top of the file to understand this
                reqJob = reqJob:gsub("(%l)(%u)", "%1 %2")
                -- print("Checking job (on class):", reqJob)
                local jobLevel = character.jobLevels[reqJob] or 0

                if jobLevel < reqLevel then
                    canAccess = false
                    break -- Stop checking requirements for this job
                end
            end
        end

        if canAccess then
            table.insert(available, job)
        end
    end

    -- Sort by tier
    table.sort(available, function(a, b)
        return a.tier < b.tier
    end)

    return available
end

-- Get base jobs (tier 1)
function jobSystem:getBaseJobs()
    local baseJobs = {}

    for name, job in pairs(self.jobs) do
        if job.tier == 1 then
            table.insert(baseJobs, job)
        end
    end

    return baseJobs
end

-- Get job progression options
function jobSystem:getJobProgressions(jobName)
    local progressions = {}
    local currentJob = self:getJob(jobName)

    if not currentJob then
        return {}
    end

    -- Get next tier jobs
    local nextTier = currentJob.tier + 1

    for name, job in pairs(self.jobs) do
        if job.tier == nextTier then
            -- Check if this job requires the current job
            if job.requirements and job.requirements[jobName] then
                table.insert(progressions, job)
            end
        end
    end

    return progressions
end

return jobSystem
