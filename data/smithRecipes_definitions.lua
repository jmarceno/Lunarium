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
        locations = {"Delzor", "Kael"}
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
        locations = {"Delzor", "Kael"}
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
    }
}

return smithRecipes 