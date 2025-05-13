-- Set Items Definitions
-- This file contains all set item definitions
-- Each set item has standard item properties plus set-specific properties

return {
    -- Firewalker Set
    FirewalkerBoots = {
        name = "Firewalker Boots",
        description = "Boots that protect against fire and lava.",
        type = "armor",
        slot = "feet", -- Note: would need to add this slot to the equipment system
        rarity = "set",
        defense = 8,
        magicDefense = 12,
        value = 3000,
        requirements = {
            DEX = 15
        },
        jobs = {"Fighter", "Mage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Firewalker",
        setPiece = 1,
        setTotalPieces = 3
    },
    
    FirewalkerGloves = {
        name = "Firewalker Gloves",
        description = "Gloves that protect against fire and lava.",
        type = "armor",
        slot = "hands", -- Note: would need to add this slot to the equipment system
        rarity = "set",
        defense = 7,
        magicDefense = 10,
        value = 2800,
        requirements = {
            DEX = 12
        },
        jobs = {"Fighter", "Mage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Firewalker",
        setPiece = 2,
        setTotalPieces = 3
    },
    
    FirewalkerHelm = {
        name = "Firewalker Helm",
        description = "A helm that protects against fire and lava.",
        type = "armor",
        slot = "head",
        rarity = "set",
        defense = 10,
        magicDefense = 15,
        value = 3500,
        requirements = {
            CON = 18
        },
        jobs = {"Fighter", "Mage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Firewalker",
        setPiece = 3,
        setTotalPieces = 3
    },
    
    -- Frostbite Set
    FrostbiteGloves = {
        name = "Frostbite Gloves",
        description = "Gloves imbued with freezing magic.",
        type = "armor",
        slot = "hands", -- Note: would need to add this slot to the equipment system
        rarity = "set",
        defense = 6,
        magicDefense = 15,
        value = 3200,
        requirements = {
            INT = 15
        },
        jobs = {"Mage", "WhiteMage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Frostbite",
        setPiece = 1,
        setTotalPieces = 4
    },
    
    FrostbiteRobe = {
        name = "Frostbite Robe",
        description = "A robe imbued with freezing magic.",
        type = "armor",
        slot = "body",
        rarity = "set",
        defense = 8,
        magicDefense = 20,
        value = 4500,
        requirements = {
            INT = 18
        },
        jobs = {"Mage", "WhiteMage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Frostbite",
        setPiece = 2,
        setTotalPieces = 4
    },
    
    FrostbiteCirclet = {
        name = "Frostbite Circlet",
        description = "A circlet imbued with freezing magic.",
        type = "armor",
        slot = "head",
        rarity = "set",
        defense = 5,
        magicDefense = 18,
        value = 3800,
        requirements = {
            INT = 16
        },
        jobs = {"Mage", "WhiteMage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Frostbite",
        setPiece = 3,
        setTotalPieces = 4
    },
    
    FrostbiteWand = {
        name = "Frostbite Wand",
        description = "A wand imbued with freezing magic.",
        type = "weapon",
        slot = "weapon",
        weaponType = "wand",
        rarity = "set",
        attack = 12,
        magicAttack = 25,
        value = 5000,
        requirements = {
            INT = 20
        },
        jobs = {"Mage", "WhiteMage", "BlackMage"},
        
        -- Set item properties
        setItem = true,
        setName = "Frostbite",
        setPiece = 4,
        setTotalPieces = 4
    }
} 