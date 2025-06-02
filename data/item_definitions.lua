-- Define item rarities
local RARITY = {
    UNCOMMON = "uncommon",
    SET = "set",
    RARE = "rare",
    COMMON = "common",
    EPIC = "epic",
    UNIQUE = "unique",
}

local itemDefinitions = {
    CopperAmulet = {
        name = "Copper Amulet",
        requirements = {},
        magicDefense = 3,
        slot = "amulet",
        type = "accessory",
        value = 80,
        defense = 2,
        jobs = {
            ["7"] = "BlackMage",
            ["6"] = "Ranger",
            ["5"] = "Rogue",
            ["4"] = "Cleric",
            ["9"] = "Paladin",
            ["8"] = "WhiteMage",
            ["3"] = "Mage",
            ["10"] = "Assassin",
            ["11"] = "Berserker",
            ["1"] = "Fighter",
            ["2"] = "Knight",
        },
        description = "A simple copper amulet with minor protective properties.",
        locations = {"Delzor", "Kael"}
    },
    Crossbow = {
        accuracy = 5,
        name = "Crossbow",
        requirements = {
            DEX = 8,
        },
        slot = "weapon",
        type = "weapon",
        attack = 14,
        subType = "crossbow",
        value = 240,
        jobs = {
            ["1"] = "Ranger",
            ["2"] = "Artificer",
        },
        description = "A precise mechanical ranged weapon that's easier to aim than a bow.",
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    ApprenticeStaff = {
        name = "Apprentice Staff",
        requirements = {
            INT = 5,
        },
        slot = "weapon",
        type = "weapon",
        attack = 4,
        subType = "staff",
        value = 120,
        jobs = {
            ["3"] = "WhiteMage",
            ["2"] = "BlackMage",
            ["1"] = "Mage",
        },
        description = "A basic staff for novice mages.",
        magicAttack = 12,
        locations = {"Delzor", "Kael"}
    },
    HealingStaff = {
        name = "Healing Staff",
        requirements = {
            WIS = 10,
        },
        slot = "weapon",
        type = "weapon",
        attack = 6,
        subType = "staff",
        value = 270,
        jobs = {
            ["1"] = "Cleric",
            ["2"] = "WhiteMage",
        },
        description = "A staff that enhances healing magic.",
        magicAttack = 15,
        locations = {"Delzor", "Kael"}
    },
    Antidote = {
        value = 20,
        name = "Antidote",
        description = "Cures poison status.",
        effect = {
            status = "poison",
            target = "single",
            type = "cure_status",
        },
        type = "consumable",
        locations = {"Delzor", "Kael"}
    },
    SacredBlade = {
        name = "Sacred Blade",
        requirements = {
            WIS = 15,
            STR = 18,
        },
        element = "holy",
        slot = "weapon",
        type = "weapon",
        attack = 30,
        subType = "sword",
        value = 5000,
        jobs = {
            ["1"] = "Paladin",
            ["2"] = "HolyKnight",
        },
        description = "A legendary sword imbued with holy power.",
        magicAttack = 20,
        locations = {"Delzor", "Kael"}
    },
    BattleAxe = {
        name = "Battle Axe",
        requirements = {
            STR = 12,
        },
        slot = "weapon",
        type = "weapon",
        attack = 20,
        subType = "axe",
        value = 250,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Berserker",
        },
        description = "A heavy axe that deals devastating damage.",
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    TribalArmor = {
        name = "Tribal Armor",
        requirements = {},
        magicDefense = 5,
        slot = "body",
        type = "armor",
        value = 220,
        defense = 8,
        jobs = {
            ["1"] = "Berserker",
        },
        description = "Lightweight armor decorated with tribal symbols.",
        locations = {"Delzor", "Kael"}
    },
    ElementalRod = {
        name = "Elemental Rod",
        requirements = {
            INT = 10,
        },
        slot = "weapon",
        type = "weapon",
        attack = 4,
        subType = "wand",
        value = 280,
        jobs = {
            ["1"] = "Mage",
            ["2"] = "BlackMage",
        },
        description = "A rod infused with elemental power.",
        magicAttack = 18,
        locations = {"Delzor", "Kael"}
    },
    ShadowGarb = {
        name = "Shadow Garb",
        requirements = {
            DEX = 12,
        },
        magicDefense = 6,
        slot = "body",
        type = "armor",
        value = 260,
        defense = 9,
        evasion = 10,
        jobs = {
            ["1"] = "Assassin",
        },
        description = "Dark clothing that helps conceal the wearer.",
        locations = {"Delzor", "Kael"}
    },
    HolyCrusaderArmor = {
        name = "Holy Crusader Armor",
        requirements = {
            WIS = 15,
            STR = 18,
        },
        magicDefense = 20,
        slot = "body",
        type = "armor",
        value = 5500,
        defense = 25,
        jobs = {
            ["1"] = "Paladin",
            ["2"] = "HolyKnight",
        },
        description = "Magnificent armor worn by the most devoted holy knights.",
        locations = {"Delzor", "Kael"}
    },
    AssassinDagger = {
        name = "Assassin Dagger",
        requirements = {
            DEX = 12,
        },
        slot = "weapon",
        type = "weapon",
        attack = 14,
        value = 260,
        subType = "dagger",
        jobs = {
            ["1"] = "Rogue",
            ["2"] = "Assassin",
        },
        description = "A lethal blade designed for swift kills.",
        critRate = 15,
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    MageRobe = {
        name = "Mage Robe",
        requirements = {
            INT = 10,
        },
        magicDefense = 14,
        slot = "body",
        type = "armor",
        value = 250,
        defense = 5,
        jobs = {
            ["1"] = "Mage",
            ["2"] = "BlackMage",
        },
        description = "A robe imbued with magical protection.",
        locations = {"Delzor", "Kael"}
    },
    ArchmageStaff = {
        name = "Archmage Staff",
        requirements = {
            WIS = 15,
            INT = 20,
        },
        slot = "weapon",
        type = "weapon",
        attack = 10,
        subType = "staff",
        value = 5200,
        jobs = {
            ["3"] = "Archmage",
            ["2"] = "WhiteMage",
            ["1"] = "BlackMage",
        },
        description = "A staff of immense magical power.",
        magicAttack = 35,
        locations = {"Delzor", "Kael"}
    },
    ApprenticeRobe = {
        name = "Apprentice Robe",
        requirements = {},
        magicDefense = 7,
        slot = "body",
        type = "armor",
        value = 95,
        defense = 2,
        jobs = {
            ["3"] = "WhiteMage",
            ["2"] = "BlackMage",
            ["1"] = "Mage",
        },
        description = "A simple robe that aids in channeling magic.",
        locations = {"Delzor", "Kael"}
    },
    Dagger = {
        name = "Dagger",
        requirements = {
            DEX = 5,
        },
        slot = "weapon",
        type = "weapon",
        attack = 6,
        subType = "dagger",
        value = 80,
        jobs = {
            ["1"] = "Rogue",
            ["2"] = "Assassin",
        },
        description = "Quick and easy to handle.",
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    LightLeather = {
        name = "Light Leather",
        requirements = {},
        magicDefense = 2,
        slot = "body",
        type = "armor",
        value = 85,
        defense = 4,
        jobs = {
            ["3"] = "Ranger",
            ["2"] = "Assassin",
            ["1"] = "Rogue",
        },
        description = "Flexible leather gear for agile fighters.",
        locations = {"Delzor", "Kael"}
    },
    ShadowbladeDaggers = {
        name = "Shadowblade Daggers",
        requirements = {
            DEX = 20,
            INT = 12,
        },
        slot = "weapon",
        type = "weapon",
        attack = 25,
        value = 5100,
        subType = "dagger",
        jobs = {
            ["1"] = "Assassin",
            ["2"] = "Shadowblade",
        },
        description = "Twin daggers that seem to be made of shadow itself.",
        critRate = 25,
        magicAttack = 15,
        locations = {"Delzor", "Kael"}
    },
    LeatherArmor = {
        name = "Leather Armor",
        requirements = {},
        magicDefense = 2,
        slot = "body",
        type = "armor",
        value = 90,
        defense = 6,
        jobs = {
            ["3"] = "Ranger",
            ["2"] = "Rogue",
            ["1"] = "Fighter",
        },
        description = "Basic protection made of hardened leather.",
        locations = {"Delzor", "Kael"}
    },
    IronRing = {
        value = 50,
        defense = 1,
        description = "A simple iron ring that provides minimal protection.",
        requirements = {},
        jobs = {
            ["7"] = "Rogue",
            ["6"] = "Cleric",
            ["5"] = "Mage",
            ["4"] = "Knight",
            ["9"] = "BlackMage",
            ["8"] = "Ranger",
            ["11"] = "Paladin",
            ["3"] = "Berserker",
            ["2"] = "Assassin",
            ["1"] = "Fighter",
            ["10"] = "WhiteMage",
        },
        slot = "ring",
        name = "Iron Ring",
        type = "accessory",
        locations = {"Delzor", "Kael"}
    },
    Toolkit = {
        name = "Toolkit",
        requirements = {
            INT = 8,
        },
        attributes = {
            DEX = 1,
            INT = 1,
        },
        slot = "offhand",
        type = "accessory",
        attack = 0,
        defense = 2,
        description = "A collection of tools for creating and maintaining mechanical devices.",
        value = 180,
        jobs = {
            ["1"] = "Artificer",
        },
        locations = {"Delzor", "Kael"}
    },
    RingOfDexterity = {
        name = "Ring of Dexterity",
        requirements = {
            DEX = 7,
        },
        attributes = {
            DEX = 2,
        },
        slot = "ring",
        type = "accessory",
        value = 200,
        evasion = 5,
        jobs = {
            ["3"] = "Assassin",
            ["2"] = "Ranger",
            ["1"] = "Rogue",
        },
        description = "A finely crafted ring that improves the wearer's agility.",
        locations = {"Delzor", "Kael"}
    },
    HealthPotion = {
        value = 30,
        name = "Health Potion",
        description = "Restores 50 HP.",
        effect = {
            amount = 50,
            target = "single",
            type = "heal",
        },
        type = "consumable",
        locations = {"Delzor", "Kael"}
    },
    Mace = {
        name = "Mace",
        requirements = {
            WIS = 4,
            STR = 4,
        },
        slot = "weapon",
        type = "weapon",
        attack = 8,
        subType = "mace",
        value = 110,
        jobs = {
            ["1"] = "Cleric",
            ["2"] = "Paladin",
        },
        description = "A blunt weapon favored by clerics.",
        magicAttack = 5,
        locations = {"Delzor", "Kael"}
    },
    Bow = {
        name = "Bow",
        requirements = {
            DEX = 10,
        },
        slot = "weapon",
        type = "weapon",
        attack = 12,
        subType = "bow",
        value = 230,
        jobs = {
            ["1"] = "Ranger",
        },
        description = "A reliable ranged weapon.",
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    DivineAegis = {
        name = "Divine Aegis",
        requirements = {
            WIS = 15,
            STR = 15,
        },
        magicDefense = 18,
        slot = "offhand",
        type = "armor",
        value = 4800,
        defense = 18,
        jobs = {
            ["1"] = "Paladin",
            ["2"] = "HolyKnight",
        },
        description = "A shield blessed by the gods.",
        locations = {"Delzor", "Kael"}
    },
    QuiverOfArrows = {
        attack = 4,
        jobs = {
            ["1"] = "Ranger",
        },
        requirements = {
            DEX = 10,
        },
        value = 170,
        description = "A collection of well-crafted arrows.",
        slot = "offhand",
        name = "Quiver of Arrows",
        type = "accessory",
        locations = {"Delzor", "Kael"}
    },
    EngineersCrossbow = {
        accuracy = 10,
        name = "Engineer's Crossbow",
        requirements = {
            DEX = 14,
            INT = 10,
        },
        slot = "weapon",
        type = "weapon",
        attack = 22,
        value = 480,
        subType = "crossbow",
        jobs = {
            ["1"] = "BallistaMaster",
        },
        description = "An advanced crossbow with mechanical improvements for increased power and accuracy.",
        critRate = 5,
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    Longsword = {
        name = "Longsword",
        requirements = {
            STR = 8,
        },
        slot = "weapon",
        type = "weapon",
        attack = 16,
        subType = "sword",
        value = 220,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "Knight",
            ["1"] = "Fighter",
        },
        description = "A longer blade with better reach.",
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    HolySymbol = {
        name = "Holy Symbol",
        description = "A symbol of divine power.",
        type = "accessory",
        slot = "offhand",
        attack = 0,
        magicAttack = 7,
        defense = 0,
        value = 85,
        jobs = {
            ["1"] = "Cleric",
            ["2"] = "Paladin",
            ["3"] = "WhiteMage",
            ["4"] = "Warrior",
        },
        sprite = nil,
        magicDefense = 4,
        requirements = {
            WIS = 5,
        },
        locations = {"Delzor", "Kael"}
    },
    SilverAmulet = {
        name = "Silver Amulet",
        requirements = {},
        magicDefense = 5,
        slot = "amulet",
        type = "accessory",
        value = 150,
        description = "A silver amulet that enhances the wearer's magic abilities.",
        jobs = {
            ["5"] = "Paladin",
            ["4"] = "WhiteMage",
            ["3"] = "BlackMage",
            ["2"] = "Cleric",
            ["1"] = "Mage",
        },
        magicAttack = 3,
        locations = {"Delzor", "Kael"}
    },
    MasterToolkit = {
        name = "Master Toolkit",
        requirements = {
            DEX = 10,
            INT = 14,
        },
        attributes = {
            DEX = 2,
            INT = 3,
        },
        slot = "offhand",
        type = "accessory",
        attack = 2,
        defense = 4,
        description = "An extensive collection of precision tools for engineering complex mechanical contraptions.",
        value = 350,
        jobs = {
            ["1"] = "BallistaMaster",
        },
        locations = {"Delzor", "Kael"}
    },
    WoodenShield = {
        name = "Wooden Shield",
        requirements = {
            STR = 4,
        },
        magicDefense = 1,
        slot = "offhand",
        type = "armor",
        value = 70,
        defense = 5,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "Knight",
            ["1"] = "Fighter",
        },
        description = "A basic wooden shield.",
        locations = {"Delzor", "Kael"}
    },
    KiteShield = {
        name = "Kite Shield",
        requirements = {
            STR = 10,
        },
        magicDefense = 3,
        slot = "offhand",
        type = "armor",
        value = 200,
        defense = 10,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "Knight",
            ["1"] = "Fighter",
        },
        description = "A large shield that offers excellent protection.",
        locations = {"Delzor", "Kael"}
    },
    ShortSword = {
        name = "Short Sword",
        requirements = {
            STR = 5,
        },
        slot = "weapon",
        type = "weapon",
        attack = 10,
        subType = "sword",
        value = 100,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "Knight",
            ["1"] = "Fighter",
            ["4"] = "Rogue",
        },
        description = "A simple but reliable blade.",
        magicAttack = 0,
        locations = {"Delzor", "Kael"}
    },
    Elixir = {
        value = 200,
        name = "Elixir",
        description = "Fully restores HP and MP.",
        effect = {
            type = "full_restore",
            target = "single",
        },
        type = "consumable",
        locations = {"Delzor", "Kael"}
    },
    BandOfStrength = {
        name = "Band of Strength",
        requirements = {
            STR = 6,
        },
        attributes = {
            STR = 2,
        },
        slot = "ring",
        type = "accessory",
        attack = 3,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "Knight",
            ["1"] = "Fighter",
            ["4"] = "Berserker",
        },
        value = 120,
        description = "A ring that enhances the wearer's physical power.",
        locations = {"Delzor", "Kael"}
    },
    ManaPotion = {
        value = 40,
        name = "Mana Potion",
        description = "Restores 30 MP.",
        effect = {
            amount = 30,
            target = "single",
            type = "restore_mp",
        },
        type = "consumable",
        locations = {"Delzor", "Kael"}
    },
    EngineerGarb = {
        name = "Engineer Garb",
        requirements = {
            DEX = 12,
            INT = 14,
        },
        magicDefense = 8,
        slot = "body",
        type = "armor",
        value = 460,
        defense = 14,
        jobs = {
            ["1"] = "BallistaMaster",
        },
        description = "Specialized outfit with numerous pockets and protective padding for handling mechanical contraptions.",
        locations = {"Delzor", "Kael"}
    },
    ArchmagerobeOfPower = {
        name = "Archmage Robe of Power",
        requirements = {
            WIS = 15,
            INT = 20,
        },
        magicDefense = 30,
        slot = "body",
        type = "armor",
        value = 5400,
        defense = 15,
        jobs = {
            ["3"] = "Archmage",
            ["2"] = "WhiteMage",
            ["1"] = "BlackMage",
        },
        description = "A masterfully crafted robe that enhances all magical abilities.",
        locations = {"Delzor", "Kael"}
    },
    ChainMail = {
        name = "Chain Mail",
        requirements = {
            STR = 8,
        },
        magicDefense = 3,
        slot = "body",
        type = "armor",
        value = 240,
        defense = 12,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "Knight",
            ["1"] = "Fighter",
        },
        description = "Armor made of interlocking metal rings.",
        locations = {"Delzor", "Kael"}
    },
    AmuletOfProtection = {
        name = "Amulet of Protection",
        requirements = {
            WIS = 8,
        },
        magicDefense = 6,
        slot = "amulet",
        type = "accessory",
        value = 250,
        defense = 4,
        jobs = {
            ["5"] = "WhiteMage",
            ["4"] = "Paladin",
            ["3"] = "Cleric",
            ["2"] = "Knight",
            ["1"] = "Fighter",
        },
        description = "An enchanted amulet that provides substantial defense.",
        locations = {"Delzor", "Kael"}
    },
    RangerLeathers = {
        name = "Ranger Leathers",
        requirements = {
            DEX = 10,
        },
        magicDefense = 5,
        slot = "body",
        type = "armor",
        value = 235,
        defense = 10,
        jobs = {
            ["1"] = "Ranger",
        },
        description = "Treated leather armor favored by rangers.",
        locations = {"Delzor", "Kael"}
    },
    AcolyteRobe = {
        name = "Acolyte Robe",
        requirements = {},
        magicDefense = 6,
        slot = "body",
        type = "armor",
        value = 90,
        defense = 3,
        jobs = {
            ["3"] = "Paladin",
            ["2"] = "WhiteMage",
            ["1"] = "Cleric",
        },
        description = "A robe worn by followers of the divine.",
        locations = {"Delzor", "Kael"}
    },
    ShadowWalkerCloak = {
        name = "Shadow Walker Cloak",
        requirements = {
            DEX = 20,
            INT = 12,
        },
        magicDefense = 18,
        slot = "body",
        type = "armor",
        value = 5300,
        defense = 18,
        evasion = 20,
        jobs = {
            ["1"] = "Assassin",
            ["2"] = "Shadowblade",
        },
        description = "A mysterious cloak that seems to bend light around the wearer.",
        locations = {"Delzor", "Kael"}
    },
    ThrowingKnives = {
        name = "Throwing Knives",
        requirements = {
            DEX = 12,
        },
        slot = "offhand",
        type = "weapon",
        attack = 8,
        subType = "dagger",
        value = 190,
        jobs = {
            ["1"] = "Rogue",
            ["2"] = "Assassin",
        },
        description = "A set of balanced knives for throwing.",
        locations = {"Delzor", "Kael"}
    },
    WhiteRobe = {
        name = "White Robe",
        requirements = {
            WIS = 10,
        },
        magicDefense = 12,
        slot = "body",
        type = "armor",
        value = 240,
        defense = 6,
        jobs = {
            ["1"] = "Cleric",
            ["2"] = "WhiteMage",
        },
        description = "A pristine robe that enhances healing magic.",
        locations = {"Delzor", "Kael"}
    },
    MageRing = {
        name = "Mage Ring",
        requirements = {
            INT = 6,
        },
        attributes = {
            INT = 2,
        },
        slot = "ring",
        type = "accessory",
        value = 180,
        description = "A ring infused with arcane energy that enhances spellcasting.",
        jobs = {
            ["3"] = "WhiteMage",
            ["2"] = "BlackMage",
            ["1"] = "Mage",
            ["4"] = "Cleric",
        },
        magicAttack = 5,
        locations = {"Delzor", "Kael"}
    },
}

local monsterParts = {
    SkeletonBone = {
        value = 20,
        name = "Skeleton Bone",
        description = "A bone from a reanimated skeleton.",
        rarity = 2,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    OgreHide = {
        value = 25,
        name = "Ogre Hide",
        description = "A tough piece of skin from an ogre.",
        rarity = 2,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    SpiderFang = {
        value = 10,
        name = "Spider Fang",
        description = "A venomous fang from a large spider.",
        rarity = 1,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    GoblinTooth = {
        value = 8,
        name = "Goblin Tooth",
        description = "A sharp tooth from a goblin.",
        rarity = 1,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    BatWing = {
        value = 6,
        name = "Bat Wing",
        description = "A wing from a cave bat.",
        rarity = 1,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    DemonHorn = {
        value = 90,
        name = "Demon Horn",
        description = "A twisted horn from a fearsome demon.",
        rarity = 4,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    PhoenixFeather = {
        value = 150,
        name = "Phoenix Feather",
        description = "A brilliant feather that radiates warmth.",
        rarity = 5,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    GhostEssence = {
        value = 45,
        name = "Ghost Essence",
        description = "The ethereal remnants of a ghost.",
        rarity = 3,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    BehemothHeart = {
        value = 200,
        name = "Behemoth Heart",
        description = "The massive heart of a behemoth.",
        rarity = 5,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    SlimeCrystal = {
        value = 5,
        name = "Slime Crystal",
        description = "A crystallized core of a slime monster.",
        rarity = 1,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    WolfPelt = {
        value = 30,
        name = "Wolf Pelt",
        description = "The pelt of a fierce wolf.",
        rarity = 2,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
    DragonScale = {
        value = 100,
        name = "Dragon Scale",
        description = "A shimmering scale from a dragon.",
        rarity = 4,
        type = "monster_part",
        locations = {"Delzor", "Kael"}
    },
}

return {
    items = itemDefinitions,
    monsterParts = monsterParts,
    RARITY = RARITY,
}