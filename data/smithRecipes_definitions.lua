-- Smith Recipes
-- Contains all crafting recipes for the blacksmith

local smithRecipes = {
    -- Weapon recipes
    {
        name = "Iron Sword",
        description = "A sturdy iron sword.",
        result = "ShortSword",
        materials = {
            ["Iron Ore"] = 3,
            ["Wood"] = 1
        },
        goldCost = 50,
        category = "Weapons",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    {
        name = "Steel Dagger",
        description = "A sharp dagger made of steel.",
        result = "Dagger",
        materials = {
            ["Iron Ore"] = 2,
            ["Coal"] = 1,
            ["Wood"] = 1
        },
        goldCost = 40,
        category = "Weapons",
        locations = {"Delzor", "Kael"}
    },
    {
        name = "Enchanted Staff",
        description = "A staff with magical properties.",
        result = "ApprenticeStaff",
        materials = {
            ["Wood"] = 2,
            ["Magic Crystal"] = 1
        },
        goldCost = 60,
        category = "Weapons",
        locations = {"Delzor", "Kael"}
    },
    {
        name = "Battle Axe",
        description = "A heavy battle axe for warriors.",
        result = "BattleAxe",
        materials = {
            ["Iron Ore"] = 4,
            ["Wood"] = 2,
            ["Monster Bone"] = 1
        },
        goldCost = 80,
        category = "Weapons",
        locations = {"Delzor", "Kael"}
    },
    
    -- Armor recipes
    {
        name = "Leather Armor",
        description = "Basic protective armor made of leather.",
        result = "LeatherArmor",
        materials = {
            ["Monster Hide"] = 3,
            ["Cloth"] = 1
        },
        goldCost = 45,
        category = "Armor",
        locations = {"Delzor", "Kael", "Sahriq", "Khulaan", "Vargstad"}
    },
    {
        name = "Chain Mail",
        description = "Armor made of interlocking metal rings.",
        result = "ChainMail",
        materials = {
            ["Iron Ore"] = 5,
            ["Coal"] = 2
        },
        goldCost = 120,
        category = "Armor",
        locations = {"Delzor", "Kael"}
    },
    {
        name = "Mage Robe",
        description = "A robe imbued with magical power.",
        result = "MageRobe",
        materials = {
            ["Cloth"] = 3,
            ["Magic Crystal"] = 2,
            ["Spider Silk"] = 1
        },
        goldCost = 100,
        category = "Armor",
        locations = {"Delzor", "Kael"}
    },
    
    -- Accessory recipes
    {
        name = "Wooden Shield",
        description = "A basic wooden shield.",
        result = "WoodenShield",
        materials = {
            ["Wood"] = 3,
            ["Iron Ore"] = 1
        },
        goldCost = 35,
        category = "Accessories",
        locations = {"Delzor", "Kael"}
    },
    {
        name = "Holy Symbol",
        description = "A symbol of divine power.",
        result = "HolySymbol",
        materials = {
            ["Silver Ore"] = 2,
            ["Magic Crystal"] = 1
        },
        goldCost = 70,
        category = "Accessories",
        locations = {"Delzor", "Kael"}
    },
    {
        name = "Kite Shield",
        description = "A large shield that offers excellent protection.",
        result = "KiteShield",
        materials = {
            ["Iron Ore"] = 4,
            ["Wood"] = 2,
            ["Monster Hide"] = 1
        },
        goldCost = 100,
        category = "Accessories",
        locations = {"Delzor", "Kael"}
    },
    
    -- SAHRIQ RECIPES (Desert City)
    {
        name = "Desert Scimitar",
        description = "A curved blade forged for desert warfare.",
        result = "DesertScimitar",
        materials = {
            ["Iron Ore"] = 3,
            ["Desert Sand"] = 2,
            ["Monster Bone"] = 1
        },
        goldCost = 120,
        category = "Weapons",
        locations = {"Sahriq"}
    },
    {
        name = "Desert Robe",
        description = "A flowing robe that protects against sandstorms.",
        result = "DesertRobe",
        materials = {
            ["Cloth"] = 4,
            ["Spider Silk"] = 2,
            ["Magic Crystal"] = 1
        },
        goldCost = 90,
        category = "Armor",
        locations = {"Sahriq"}
    },
    {
        name = "Sand Walker Boots",
        description = "Boots designed for silent movement across sand.",
        result = "SandWalkerBoots",
        materials = {
            ["Monster Hide"] = 3,
            ["Desert Sand"] = 1,
            ["Iron Ore"] = 1
        },
        goldCost = 70,
        category = "Armor",
        locations = {"Sahriq"}
    },
    
    -- KHULAAN RECIPES (Steppe City)
    {
        name = "Steppe Spear",
        description = "A long spear favored by horsemen.",
        result = "SteppeSpear",
        materials = {
            ["Iron Ore"] = 4,
            ["Wood"] = 3,
            ["Wolf Pelt"] = 1
        },
        goldCost = 150,
        category = "Weapons",
        locations = {"Khulaan"}
    },
    {
        name = "Nomad Leathers",
        description = "Tough armor worn by steppe nomads.",
        result = "NomadLeathers",
        materials = {
            ["Monster Hide"] = 4,
            ["Wolf Pelt"] = 2,
            ["Iron Ore"] = 1
        },
        goldCost = 130,
        category = "Armor",
        locations = {"Khulaan"}
    },
    {
        name = "Wolf Spirit Totem",
        description = "A sacred totem imbued with ancestral spirits.",
        result = "WolfSpiritTotem",
        materials = {
            ["Monster Bone"] = 2,
            ["Wolf Pelt"] = 1,
            ["Magic Crystal"] = 1
        },
        goldCost = 110,
        category = "Accessories",
        locations = {"Khulaan"}
    },
    
    -- VARGSTAD RECIPES (Mountain/Coastal City)
    {
        name = "Frostbite Axe",
        description = "An axe forged from ice-cold mountain steel.",
        result = "FrostbiteAxe",
        materials = {
            ["Iron Ore"] = 5,
            ["Ice Crystal"] = 3,
            ["Monster Bone"] = 2
        },
        goldCost = 200,
        category = "Weapons",
        locations = {"Vargstad"}
    },
    {
        name = "Viking Chainmail",
        description = "Heavy chainmail worn by northern warriors.",
        result = "VikingChainmail",
        materials = {
            ["Iron Ore"] = 6,
            ["Coal"] = 3,
            ["Monster Hide"] = 2
        },
        goldCost = 180,
        category = "Armor",
        locations = {"Vargstad"}
    },
    {
        name = "Seafoam Trident",
        description = "A trident imbued with the power of the sea.",
        result = "SeafoamTrident",
        materials = {
            ["Iron Ore"] = 4,
            ["Sea Pearl"] = 2,
            ["Magic Crystal"] = 2
        },
        goldCost = 220,
        category = "Weapons",
        locations = {"Vargstad"}
    }
}

return smithRecipes 