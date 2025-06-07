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
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
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
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
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
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
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
    
    -- SAHRIQ ITEMS (Desert City)
    DesertScimitar = {
        name = "Desert Scimitar",
        requirements = {
            STR = 10,
            DEX = 8,
        },
        slot = "weapon",
        type = "weapon",
        attack = 18,
        subType = "sword",
        value = 320,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Rogue",
            ["3"] = "Ranger",
        },
        description = "A curved blade perfectly balanced for desert combat.",
        magicAttack = 0,
        critRate = 8,
        locations = {"Sahriq"}
    },
    SandWalkerBoots = {
        name = "Sand Walker Boots",
        requirements = {
            DEX = 8,
        },
        magicDefense = 4,
        slot = "feet",
        type = "armor",
        value = 180,
        defense = 6,
        evasion = 8,
        jobs = {
            ["1"] = "Ranger",
            ["2"] = "Rogue",
            ["3"] = "Assassin",
        },
        description = "Specially crafted boots that allow silent movement across sand.",
        locations = {"Sahriq"}
    },
    DesertRobe = {
        name = "Desert Robe",
        requirements = {
            WIS = 8,
        },
        magicDefense = 10,
        slot = "body",
        type = "armor",
        value = 280,
        defense = 8,
        jobs = {
            ["1"] = "Mage",
            ["2"] = "BlackMage",
            ["3"] = "WhiteMage",
            ["4"] = "Cleric",
        },
        description = "A flowing robe that protects against desert heat and sandstorms.",
        locations = {"Sahriq"}
    },
    SandWalkersCharm = {
        name = "Sand Walker's Charm",
        requirements = {
            DEX = 6,
        },
        magicDefense = 4,
        slot = "amulet",
        type = "accessory",
        value = 220,
        defense = 3,
        evasion = 5,
        jobs = {
            ["1"] = "Ranger",
            ["2"] = "Rogue",
            ["3"] = "Fighter",
        },
        description = "A charm blessed by desert nomads that aids in navigation.",
        locations = {"Sahriq"}
    },
    DesertRemedy = {
        value = 45,
        name = "Desert Remedy",
        description = "A potent cure for desert ailments and poisons.",
        effect = {
            amount = 40,
            target = "single",
            type = "heal",
            status = "poison",
            statusType = "cure_status",
        },
        type = "consumable",
        locations = {"Sahriq"}
    },
    DjinnsBlessing = {
        name = "Djinn's Blessing",
        requirements = {
            WIS = 12,
        },
        attributes = {
            WIS = 3,
            INT = 2,
        },
        slot = "amulet",
        type = "accessory",
        value = 680,
        magicAttack = 8,
        magicDefense = 8,
        jobs = {
            ["1"] = "Mage",
            ["2"] = "BlackMage",
            ["3"] = "WhiteMage",
        },
        description = "A mystical amulet containing the essence of a grateful djinn.",
        locations = {"Sahriq"}
    },
    
    -- KHULAAN ITEMS (Steppe City)  
    SteppeSpear = {
        name = "Steppe Spear",
        requirements = {
            STR = 12,
            DEX = 10,
        },
        slot = "weapon",
        type = "weapon",
        attack = 22,
        subType = "spear",
        value = 420,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
            ["3"] = "Berserker",
        },
        description = "A long spear used by steppe warriors for mounted combat.",
        magicAttack = 0,
        locations = {"Khulaan"}
    },
    NomadLeathers = {
        name = "Nomad Leathers",
        requirements = {
            DEX = 12,
        },
        magicDefense = 8,
        slot = "body",
        type = "armor",
        value = 380,
        defense = 14,
        evasion = 6,
        jobs = {
            ["1"] = "Ranger",
            ["2"] = "Fighter",
            ["3"] = "Berserker",
        },
        description = "Tough leather armor worn by nomadic horsemen.",
        locations = {"Khulaan"}
    },
    WolfSpiritTotem = {
        name = "Wolf Spirit Totem",
        requirements = {
            WIS = 10,
        },
        attributes = {
            WIS = 2,
            DEX = 1,
        },
        slot = "offhand",
        type = "accessory",
        value = 350,
        magicAttack = 6,
        defense = 4,
        jobs = {
            ["1"] = "Ranger",
            ["2"] = "Cleric",
            ["3"] = "WhiteMage",
        },
        description = "A totem carved from sacred wolf bone, imbued with ancestral spirits.",
        locations = {"Khulaan"}
    },
    ShamanicBrew = {
        value = 80,
        name = "Shamanic Brew",
        description = "A mystical potion that restores both health and mana.",
        effect = {
            amount = 60,
            target = "single",
            type = "heal",
            mpAmount = 40,
            mpType = "restore_mp",
        },
        type = "consumable",
        locations = {"Khulaan"}
    },
    StormRidersCloak = {
        name = "Storm Rider's Cloak",
        requirements = {
            DEX = 14,
            WIS = 10,
        },
        magicDefense = 12,
        slot = "body",
        type = "armor",
        value = 580,
        defense = 16,
        evasion = 12,
        jobs = {
            ["1"] = "Ranger",
            ["2"] = "Rogue",
            ["3"] = "Assassin",
        },
        description = "A mystical cloak that seems to move with the wind itself.",
        locations = {"Khulaan"}
    },
    AncestralBlade = {
        name = "Ancestral Blade",
        requirements = {
            STR = 16,
            WIS = 12,
        },
        element = "spirit",
        slot = "weapon",
        type = "weapon",
        attack = 28,
        subType = "sword",
        value = 1200,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
            ["3"] = "Paladin",
        },
        description = "An ancient blade passed down through generations of steppe warriors.",
        magicAttack = 12,
        locations = {"Khulaan"}
    },
    
    -- VARGSTAD ITEMS (Mountain/Coastal City)
    FrostbiteAxe = {
        name = "Frostbite Axe",
        requirements = {
            STR = 16,
        },
        element = "ice",
        slot = "weapon",
        type = "weapon",
        attack = 26,
        subType = "axe",
        value = 620,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Berserker",
        },
        description = "An axe forged from ice-cold mountain steel.",
        magicAttack = 8,
        locations = {"Vargstad"}
    },
    VikingChainmail = {
        name = "Viking Chainmail",
        requirements = {
            STR = 14,
        },
        magicDefense = 6,
        slot = "body",
        type = "armor",
        value = 520,
        defense = 18,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
            ["3"] = "Berserker",
        },
        description = "Heavy chainmail worn by northern warriors.",
        locations = {"Vargstad"}
    },
    SeafoamTrident = {
        name = "Seafoam Trident",
        requirements = {
            STR = 14,
            DEX = 12,
        },
        element = "water",
        slot = "weapon",
        type = "weapon",
        attack = 24,
        subType = "spear",
        value = 580,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
        },
        description = "A three-pronged weapon imbued with the power of the sea.",
        magicAttack = 10,
        locations = {"Vargstad"}
    },
    AuroraStone = {
        name = "Aurora Stone",
        requirements = {
            WIS = 14,
        },
        attributes = {
            WIS = 4,
            INT = 3,
        },
        slot = "amulet",
        type = "accessory",
        value = 850,
        magicAttack = 12,
        magicDefense = 12,
        jobs = {
            ["1"] = "Mage",
            ["2"] = "BlackMage",
            ["3"] = "WhiteMage",
        },
        description = "A crystalline stone that captures the essence of the northern lights.",
        locations = {"Vargstad"}
    },
    KrakensHeart = {
        name = "Kraken's Heart",
        requirements = {
            STR = 18,
            WIS = 15,
        },
        attributes = {
            STR = 4,
            WIS = 3,
        },
        slot = "amulet",
        type = "accessory",
        value = 1500,
        attack = 8,
        magicAttack = 15,
        defense = 10,
        magicDefense = 15,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
            ["3"] = "Paladin",
            ["4"] = "Mage",
        },
        description = "The still-beating heart of an ancient sea monster, pulsing with dark power.",
        locations = {"Vargstad"}
    },
    Dragonslayer = {
        name = "Dragonslayer",
        requirements = {
            STR = 20,
            WIS = 16,
        },
        element = "dragon",
        slot = "weapon",
        type = "weapon",
        attack = 35,
        subType = "sword",
        value = 2500,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
            ["3"] = "Paladin",
        },
        description = "The ultimate weapon, forged specifically to slay dragons.",
        magicAttack = 25,
        critRate = 10,
        locations = {"Vargstad"}
    },
    
    -- Quest reward items for the new cities
    RareSpices = {
        value = 25,
        name = "Rare Spices",
        description = "Exotic spices that temporarily boost combat abilities.",
        effect = {
            amount = 10,
            target = "single",
            type = "buff_attack",
            duration = 3
        },
        type = "consumable",
        locations = {"Sahriq"}
    },
    PeacemakersMedal = {
        name = "Peacemaker's Medal",
        requirements = {
            WIS = 8,
        },
        attributes = {
            WIS = 2,
            INT = 1,
        },
        slot = "amulet",
        type = "accessory",
        value = 320,
        defense = 2,
        magicDefense = 4,
        jobs = {
            ["1"] = "Cleric",
            ["2"] = "Paladin",
            ["3"] = "WhiteMage",
        },
        description = "A medal awarded for successful diplomatic missions.",
        locations = {"Khulaan"}
    },
    HonoredWarriorsAxe = {
        name = "Honored Warrior's Axe",
        requirements = {
            STR = 16,
        },
        slot = "weapon",
        type = "weapon",
        attack = 24,
        subType = "axe",
        value = 680,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Berserker",
        },
        description = "An axe blessed in sacred funeral rites, wielded by honored warriors.",
        magicAttack = 6,
        locations = {"Vargstad"}
    },
    SerpentsBaneHarpoon = {
        name = "Serpent's Bane Harpoon",
        requirements = {
            STR = 14,
            DEX = 12,
        },
        element = "water",
        slot = "weapon",
        type = "weapon",
        attack = 26,
        subType = "spear",
        value = 780,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Ranger",
        },
        description = "A specialized harpoon designed for hunting sea monsters.",
        magicAttack = 8,
        critRate = 12,
        locations = {"Vargstad"}
    },
    SandwormSlayer = {
        name = "Sandworm Slayer",
        requirements = {
            STR = 14,
            DEX = 10,
        },
        element = "earth",
        slot = "weapon",
        type = "weapon",
        attack = 25,
        subType = "sword",
        value = 720,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
        },
        description = "A blade forged from sandworm chitin, effective against burrowing enemies.",
        magicAttack = 8,
        locations = {"Sahriq"}
    },
    SlimeCrusher = {
        name = "Slime Crusher",
        requirements = {
            STR = 12,
        },
        slot = "weapon",
        type = "weapon",
        attack = 20,
        subType = "mace",
        value = 480,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Cleric",
        },
        description = "A mace designed specifically for crushing gelatinous enemies.",
        magicAttack = 4,
        locations = {"Kael"}
    },
    NecromancersBane = {
        name = "Necromancer's Bane",
        requirements = {
            STR = 16,
            WIS = 12,
        },
        element = "holy",
        slot = "weapon",
        type = "weapon",
        attack = 28,
        subType = "sword",
        value = 950,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Knight",
            ["3"] = "Paladin",
        },
        description = "A holy blade that deals extra damage to undead creatures.",
        magicAttack = 15,
        locations = {"Kael"}
    },
    DemonResistantCloak = {
        name = "Demon-Resistant Cloak",
        requirements = {
            WIS = 10,
        },
        magicDefense = 15,
        slot = "body",
        type = "armor",
        value = 520,
        defense = 12,
        jobs = {
            ["1"] = "Mage",
            ["2"] = "BlackMage",
            ["3"] = "WhiteMage",
            ["4"] = "Cleric",
        },
        description = "A cloak woven with protective wards against demonic influence.",
        locations = {"Kael"}
    },
    HiveSplitter = {
        name = "Hive Splitter",
        requirements = {
            STR = 14,
            DEX = 10,
        },
        slot = "weapon",
        type = "weapon",
        attack = 23,
        subType = "axe",
        value = 640,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Berserker",
        },
        description = "An axe with serrated edges, perfect for breaking through insect carapaces.",
        magicAttack = 5,
        critRate = 8,
        locations = {"Kael"}
    },
    PanthersAgilityCharm = {
        name = "Panther's Agility Charm",
        requirements = {
            DEX = 12,
        },
        attributes = {
            DEX = 3,
        },
        slot = "amulet",
        type = "accessory",
        value = 480,
        evasion = 12,
        jobs = {
            ["1"] = "Rogue",
            ["2"] = "Assassin",
            ["3"] = "Ranger",
        },
        description = "A charm that grants the wearer the agility of a hunting panther.",
        locations = {"Kael"}
    },
    LuckyCharm = {
        name = "Lucky Charm",
        requirements = {},
        attributes = {
            DEX = 1,
            INT = 1,
        },
        slot = "amulet",
        type = "accessory",
        value = 180,
        evasion = 3,
        jobs = {
            ["1"] = "Fighter",
            ["2"] = "Rogue",
            ["3"] = "Mage",
            ["4"] = "Cleric",
        },
        description = "A small charm said to bring good fortune to its bearer.",
        locations = {"Delzor"}
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
    -- New crafting materials for city-specific recipes
    DesertSand = {
        value = 15,
        name = "Desert Sand",
        description = "Magical sand from the deep desert, used in crafting.",
        rarity = 2,
        type = "crafting_material",
        locations = {"Sahriq"}
    },
    IceCrystal = {
        value = 35,
        name = "Ice Crystal",
        description = "A crystal formed from eternal ice of the northern peaks.",
        rarity = 3,
        type = "crafting_material",
        locations = {"Vargstad"}
    },
    SeaPearl = {
        value = 50,
        name = "Sea Pearl",
        description = "A lustrous pearl from the deep ocean waters.",
        rarity = 3,
        type = "crafting_material",
        locations = {"Vargstad"}
    },
    -- Basic crafting materials available everywhere
    IronOre = {
        value = 8,
        name = "Iron Ore",
        description = "Raw iron ore used in smithing.",
        rarity = 1,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    Wood = {
        value = 5,
        name = "Wood",
        description = "Strong timber used in crafting weapons and tools.",
        rarity = 1,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    Coal = {
        value = 10,
        name = "Coal",
        description = "Fuel used in smithing for high-temperature forging.",
        rarity = 1,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    Cloth = {
        value = 6,
        name = "Cloth",
        description = "Woven fabric used in making robes and light armor.",
        rarity = 1,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    MonsterHide = {
        value = 12,
        name = "Monster Hide",
        description = "Tough hide from defeated monsters, used in armor crafting.",
        rarity = 2,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    MonsterBone = {
        value = 15,
        name = "Monster Bone",
        description = "Dense bone from large monsters, used in weapon crafting.",
        rarity = 2,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    MagicCrystal = {
        value = 25,
        name = "Magic Crystal",
        description = "A crystal infused with magical energy.",
        rarity = 2,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    SpiderSilk = {
        value = 18,
        name = "Spider Silk",
        description = "Strong silk from giant spiders, used in fine crafting.",
        rarity = 2,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    SilverOre = {
        value = 20,
        name = "Silver Ore",
        description = "Precious silver ore used in crafting holy items.",
        rarity = 2,
        type = "crafting_material",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
}

return {
    items = itemDefinitions,
    monsterParts = monsterParts,
    RARITY = RARITY,
}