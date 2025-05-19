-- Quest Definitions
-- Contains all quest data definitions

local questData = {
    -- Easy quests
    {
        id = "rats_infestation",
        name = "Rat Infestation",
        description = "The sewers beneath the town are infested with giant rats. Clear them out before they spread disease.",
        type = "KILL",
        level = 1,
        difficulty = 1, -- questSystem.DIFFICULTY.EASY
        giver = "Tavern",
        objective = {
            type = "kill",
            targetId = "giant_rat",
            targetName = "Giant Rat",
            count = 5,
            current = 0
        },
        rewards = { gold = 50, items = {} },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 12345 -- Seed for dungeon generation
    },
    {
        id = "missing_supplies",
        name = "Missing Supplies",
        description = "A shipment of supplies has gone missing. Search the nearby cave.",
        type = "EXPLORE",
        level = 1,
        difficulty = 1, -- questSystem.DIFFICULTY.EASY
        giver = "Guild",
        objective = {
            type = "explore",
            locationId = 1,
            locationName = "Foggy Cave",
            completed = false
        },
        rewards = {
            gold = 30,
            items = {}
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 23456
    },
    
    -- Medium quests
    {
        id = "cultist_threat",
        name = "Cultist Threat",
        description = "A group of cultists has been spotted in the area. Investigate and eliminate the threat.",
        type = "KILL",
        level = 3,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Guild",
        objective = {
            type = "kill",
            targetId = "cultist", 
            targetName = "Cultist",
            count = 6,
            current = 0
        },
        rewards = { gold = 150, items = {} },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 34567
    },
    {
        id = "herb_collection",
        name = "Medicinal Herbs",
        description = "The town healer needs rare herbs found in the forest.",
        type = "COLLECT",
        level = 2,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Tavern",
        objective = {
            type = "collect",
            itemId = "item_rare_herb",
            itemName = "Rare Healing Herb",
            count = 5,
            current = 0
        },
        rewards = {
            gold = 180,
            items = {
                {
                    type = "consumable",
                    name = "HealingPotion",
                    count = 3
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 45678
    },
    
    -- Hard quests
    {
        id = "escort_merchant",
        name = "Merchant Escort",
        description = "Escort a merchant safely through the dangerous mountain pass.",
        type = "ESCORT",
        level = 5,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        objective = {
            type = "escort",
            npcId = 1,
            npcName = "Merchant Thomas",
            locationId = 3,
            locationName = "Mountain Pass",
            completed = false,
            failed = false
        },
        rewards = {
            gold = 350,
            items = {
                {
                    type = "accessory",
                    name = "Lucky Charm",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 56789
    },
    {
        id = "lich_battle",
        name = "The Lich",
        description = "An ancient necromancer known as the Lich has awakened. Stop his undead army from spreading.",
        type = "BOSS",
        level = 10,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        objective = {
            type = "boss",
            bossId = "lich_boss",
            bossName = "Lich",
            locationId = 3,
            locationName = "Ancient Crypt",
            completed = false
        },
        rewards = {
            gold = 800,
            items = {
                {
                    type = "weapon",
                    name = "Necromancer's Bane",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 67890
    },
    {
        id = "royal_demon_hunt",
        name = "Royal Demon Hunt",
        description = "A powerful entity known as the Royal Demon has emerged from the underworld. Defeat it before more demons arrive.",
        type = "BOSS",
        level = 8,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        objective = {
            type = "boss",
            bossId = "royal_demon_boss",
            bossName = "Royal Demon",
            locationId = 5,
            locationName = "Demon's Lair",
            completed = false
        },
        rewards = {
            gold = 600,
            items = {
                {
                    type = "armor",
                    name = "Demon-Resistant Cloak",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 78901
    },
    {
        id = "insect_invasion",
        name = "Insect Invasion",
        description = "Swarms of giant insects are attacking farms. Find and eliminate the Broodmother.",
        type = "BOSS",
        level = 9,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        objective = {
            type = "boss",
            bossId = "broodmother_boss",
            bossName = "Broodmother",
            locationId = 6,
            locationName = "Insect Hive",
            completed = false
        },
        rewards = {
            gold = 700,
            items = {
                {
                    type = "weapon",
                    name = "Hive Splitter",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 89012
    },
    {
        id = "raging_panther",
        name = "Raging Panther",
        description = "An unnaturally large and aggressive panther has been terrorizing travelers in the mountain pass.",
        type = "BOSS",
        level = 7,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        objective = {
            type = "boss",
            bossId = "enraged_panther_boss",
            bossName = "Enraged Panther",
            locationId = 7,
            locationName = "Mountain Pass",
            completed = false
        },
        rewards = {
            gold = 550,
            items = {
                {
                    type = "accessory",
                    name = "Panther's Agility Charm",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 90123
    },
    {
        id = "taming_the_slime",
        name = "Taming the Slime",
        description = "A powerful Royal Slime has emerged from the caverns, absorbing smaller slimes and growing larger.",
        type = "BOSS",
        level = 6,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        objective = {
            type = "boss",
            bossId = "royal_slime_boss",
            bossName = "Royal Slime",
            locationId = 8,
            locationName = "Slime Caverns",
            completed = false
        },
        rewards = {
            gold = 500,
            items = {
                {
                    type = "weapon",
                    name = "Slime Crusher",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 101234
    }
}

-- Location definitions for reference by quests
local bossLocations = {
    {id = 1, name = "Fungal Grove"},
    {id = 2, name = "Cultist Altar"},
    {id = 3, name = "Ancient Crypt"},
    {id = 4, name = "Dragon's Lair"},
    {id = 5, name = "Demon's Lair"},
    {id = 6, name = "Insect Hive"},
    {id = 7, name = "Mountain Pass"},
    {id = 8, name = "Slime Caverns"}
}

local itemTargets = {
    {id = "item_rare_herb", name = "Rare Healing Herb"},
    {id = "item_magic_crystal", name = "Magic Crystal"},
    {id = "item_ancient_relic", name = "Ancient Relic"},
    {id = "item_dragon_scale", name = "Dragon Scale"},
    {id = "item_enchanted_gem", name = "Enchanted Gem"}
}

local exploreLocations = {
    {id = 1, name = "Foggy Cave"},
    {id = 2, name = "Dark Forest"},
    {id = 3, name = "Ancient Ruins"},
    {id = 4, name = "Volcanic Cavern"},
    {id = 5, name = "Frozen Temple"}
}

local escortNpcs = {
    {id = 1, name = "Merchant Thomas"},
    {id = 2, name = "Scholar Eliza"},
    {id = 3, name = "Ambassador Krell"},
    {id = 4, name = "Priestess Lyra"},
    {id = 5, name = "Prince Aldric"}
}

local escortLocations = {
    {id = 1, name = "Trade Route"},
    {id = 2, name = "Mountain Pass"},
    {id = 3, name = "Ancient Road"},
    {id = 4, name = "Swamp Path"},
    {id = 5, name = "Royal Highway"}
}

-- Make these tables accessible through the returned questData
questData.bossLocations = bossLocations
questData.itemTargets = itemTargets
questData.exploreLocations = exploreLocations
questData.escortNpcs = escortNpcs
questData.escortLocations = escortLocations

return questData
