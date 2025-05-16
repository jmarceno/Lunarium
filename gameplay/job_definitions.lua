-- Job Definitions
-- Contains all job definitions

-- Important:
-- All jobs that have name formed by two or more words, need to have those words Capitalized.
-- Example: "Black Mage" instead of "Blackmage", "White Mage" instead of "Whitemage"

local jobDefinitions = {
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

    Mystic = {
        name = "Mystic",
        description = "A spiritualist who specializes in buffs and debuffs, manipulating the flow of battle.",
        tier = 1,
        attributeModifiers = {
            WIS = 2,
            CHA = 2,
            INT = 1
        },
        startingSkills = {
            "MinorBlessing",
            "Weaken",
            "Focus"
        },
        availableSkills = {
            "MinorBlessing",
            "Weaken",
            "Focus",
            "QuickRecovery",
            "DullBlade",
            "Clarity"
        },
        startingEquipment = {
            weapon = "SpiritRod",
            body = "MysticRobe"
        },
        requirements = nil
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

    Monk = {
        name = "Monk",
        description = "A martial artist who balances offense and defense through spiritual discipline and unarmed combat.",
        tier = 1,
        attributeModifiers = {
            DEX = 2,
            WIL = 2,
            CON = 1
        },
        startingSkills = {
            "UnarmedStrike",
            "InnerFocus",
            "Meditate"
        },
        availableSkills = {
            "UnarmedStrike",
            "InnerFocus",
            "Meditate",
            "CounterStance",
            "IronBody",
            "Flurry"
        },
        startingEquipment = {
            weapon = nil,
            body = "MonkRobe"
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

    Hexer = {
        name = "Hexer",
        description = "A master of curses and debilitating magic, specializing in weakening foes.",
        tier = 2,
        attributeModifiers = {
            WIL = 3,
            INT = 2,
            CHA = 1
        },
        startingSkills = {
            "Hex",
            "CurseOfFrailty"
        },
        availableSkills = {
            "Hex",
            "CurseOfFrailty",
            "Wither",
            "Silence",
            "EvilEye",
            "Torment"
        },
        startingEquipment = {
            weapon = "CursedTalisman",
            body = "HexersMantle"
        },
        requirements = {
            Mystic = 10
        }
    },

    Enchanter = {
        name = "Enchanter",
        description = "A specialist in powerful magical buffs, enhancing allies' abilities.",
        tier = 2,
        attributeModifiers = {
            WIS = 3,
            CHA = 2,
            INT = 1
        },
        startingSkills = {
            "GreaterBlessing",
            "Haste"
        },
        availableSkills = {
            "GreaterBlessing",
            "Haste",
            "Fortify",
            "Inspire",
            "MagicWard",
            "Regeneration"
        },
        startingEquipment = {
            weapon = "EnchantersStaff",
            body = "EnchantersRobe"
        },
        requirements = {
            Mystic = 10
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

    MartialArtist = {
        name = "Martial Artist",
        description = "A master of advanced martial techniques and physical prowess.",
        tier = 2,
        attributeModifiers = {
            DEX = 3,
            STR = 2,
            WIL = 1
        },
        startingSkills = {
            "ChiBurst",
            "PressurePoint"
        },
        availableSkills = {
            "ChiBurst",
            "PressurePoint",
            "RapidStrikes",
            "PalmThrust",
            "FlowingStance",
            "IronBody"
        },
        startingEquipment = {
            weapon = nil,
            body = "MartialGi"
        },
        requirements = {
            Monk = 10
        }
    },

    BattlePriest = {
        name = "Battle Priest",
        description = "A martial artist who blends divine magic and unarmed combat.",
        tier = 2,
        attributeModifiers = {
            WIL = 3,
            DEX = 2,
            WIS = 1
        },
        startingSkills = {
            "SacredPalm",
            "Renewal"
        },
        availableSkills = {
            "SacredPalm",
            "Renewal",
            "BlessingOfEndurance",
            "PurifyingStrike",
            "IronBody",
            "InnerFocus"
        },
        startingEquipment = {
            weapon = nil,
            body = "BlessedVestments"
        },
        requirements = {
            Monk = 5,
            Cleric = 5
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
            DarkMage = 2,
            Hexer = 2
        }
    },

    Grandmaster = {
        name = "Grandmaster",
        description = "The ultimate martial artist, master of body and spirit.",
        tier = 3,
        attributeModifiers = {
            DEX = 3,
            WIL = 3,
            STR = 2,
            CON = 2
        },
        startingSkills = {
            "GrandmastersFury",
            "PerfectBody"
        },
        availableSkills = {
            "GrandmastersFury",
            "PerfectBody",
            "ChiWave",
            "Enlightenment",
            "CounterStance",
            "IronBody",
            "Meditate"
        },
        startingEquipment = {
            weapon = nil,
            body = "GrandmastersRobe"
        },
        requirements = {
            MartialArtist = 15,
            BattlePriest = 10
        }
    }
}

return jobDefinitions