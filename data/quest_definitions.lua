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
        location = "Delzor",
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
        location = "Delzor",
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
        location = "Delzor",
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
        location = "Delzor",
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
        location = "Delzor",
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
        location = "Kael",
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
        location = "Kael",
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
        location = "Kael",
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
        location = "Kael",
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
        location = "Kael",
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
    },
    
    -- SAHRIQ QUESTS (Desert City, reputation needed: 400)
    {
        id = "desert_bandits",
        name = "Desert Bandits",
        description = "Bandits have been raiding the trade caravans crossing the desert. Clear them out.",
        type = "KILL",
        level = 4,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Guild",
        location = "Sahriq",
        objective = {
            type = "kill",
            targetId = "desert_bandit",
            targetName = "Desert Bandit",
            count = 8,
            current = 0
        },
        rewards = { gold = 200, items = {} },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 111111
    },
    {
        id = "oasis_protection",
        name = "Oasis Protection",
        description = "Protect the sacred oasis from being poisoned by hostile creatures.",
        type = "KILL",
        level = 5,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Tavern",
        location = "Sahriq",
        objective = {
            type = "kill",
            targetId = "poison_scorpion",
            targetName = "Poison Scorpion",
            count = 6,
            current = 0
        },
        rewards = { 
            gold = 250,
            items = {
                {
                    type = "consumable",
                    name = "Desert Remedy",
                    count = 2
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 222222
    },
    {
        id = "ancient_relic_hunt",
        name = "Ancient Relic Hunt",
        description = "Search the buried ruins for ancient artifacts before tomb robbers find them.",
        type = "COLLECT",
        level = 6,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Guild",
        location = "Sahriq",
        objective = {
            type = "collect",
            itemId = "item_desert_artifact",
            itemName = "Desert Artifact",
            count = 3,
            current = 0
        },
        rewards = {
            gold = 300,
            items = {
                {
                    type = "accessory",
                    name = "Sand Walker's Charm",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 333333
    },
    {
        id = "sandworm_menace",
        name = "The Great Sandworm",
        description = "A massive sandworm has been terrorizing the desert trade routes. Hunt it down.",
        type = "BOSS",
        level = 12,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        location = "Sahriq",
        objective = {
            type = "boss",
            bossId = "great_sandworm_boss",
            bossName = "Great Sandworm",
            locationId = 9,
            locationName = "Desert Depths",
            completed = false
        },
        rewards = {
            gold = 900,
            items = {
                {
                    type = "weapon",
                    name = "Sandworm Slayer",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 444444
    },
    {
        id = "caravan_escort_desert",
        name = "Desert Caravan Escort",
        description = "Escort a valuable spice caravan through the dangerous desert storms.",
        type = "ESCORT",
        level = 7,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        location = "Sahriq",
        objective = {
            type = "escort",
            npcId = 6,
            npcName = "Spice Merchant Hakim",
            locationId = 6,
            locationName = "Desert Pass",
            completed = false,
            failed = false
        },
        rewards = {
            gold = 450,
            items = {
                {
                    type = "consumable",
                    name = "Rare Spices",
                    count = 5
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 555555
    },
    {
        id = "djinn_binding",
        name = "The Bound Djinn",
        description = "A powerful djinn has been imprisoned in an ancient lamp. Free it or bind it further.",
        type = "BOSS",
        level = 11,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        location = "Sahriq",
        objective = {
            type = "boss",
            bossId = "desert_djinn_boss",
            bossName = "Desert Djinn",
            locationId = 10,
            locationName = "Enchanted Ruins",
            completed = false
        },
        rewards = {
            gold = 750,
            items = {
                {
                    type = "accessory",
                    name = "Djinn's Blessing",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 666666
    },
    
    -- KHULAAN QUESTS (Steppe City, reputation needed: 600)
    {
        id = "horse_thieves",
        name = "Horse Thieves",
        description = "Raiders have stolen the clan's prized horses. Track them down and recover the steeds.",
        type = "KILL",
        level = 8,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Guild",
        location = "Khulaan",
        objective = {
            type = "kill",
            targetId = "steppe_raider",
            targetName = "Steppe Raider",
            count = 10,
            current = 0
        },
        rewards = { gold = 350, items = {} },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 777777
    },
    {
        id = "spirit_wolf_hunt",
        name = "Spirit Wolf Pack",
        description = "Mystical wolves have been disturbing the ancestral burial grounds. Put their spirits to rest.",
        type = "KILL",
        level = 9,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Tavern",
        location = "Khulaan",
        objective = {
            type = "kill",
            targetId = "spirit_wolf",
            targetName = "Spirit Wolf",
            count = 7,
            current = 0
        },
        rewards = { 
            gold = 400,
            items = {
                {
                    type = "accessory",
                    name = "Wolf Spirit Totem",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 888888
    },
    {
        id = "shamanic_ingredients",
        name = "Shamanic Ingredients",
        description = "The tribe's shaman needs rare herbs that grow only in the windswept steppes.",
        type = "COLLECT",
        level = 10,
        difficulty = 2, -- questSystem.DIFFICULTY.MEDIUM
        giver = "Tavern",
        location = "Khulaan",
        objective = {
            type = "collect",
            itemId = "item_spirit_herb",
            itemName = "Spirit Herb",
            count = 4,
            current = 0
        },
        rewards = {
            gold = 450,
            items = {
                {
                    type = "consumable",
                    name = "Shamanic Brew",
                    count = 3
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 999999
    },
    {
        id = "sky_burial_guardian",
        name = "Sky Burial Guardian",
        description = "Ancient spirits guard the sky burial sites. Appease them or face their wrath.",
        type = "BOSS",
        level = 14,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        location = "Khulaan",
        objective = {
            type = "boss",
            bossId = "sky_guardian_boss",
            bossName = "Sky Guardian",
            locationId = 11,
            locationName = "Sacred Burial Grounds",
            completed = false
        },
        rewards = {
            gold = 1100,
            items = {
                {
                    type = "weapon",
                    name = "Ancestral Blade",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 101010
    },
    {
        id = "thunder_horse_taming",
        name = "Thunder Horse Taming",
        description = "Legend speaks of a divine horse that rides with the storms. Attempt to tame this mythical beast.",
        type = "BOSS",
        level = 13,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        location = "Khulaan",
        objective = {
            type = "boss",
            bossId = "thunder_horse_boss",
            bossName = "Thunder Horse",
            locationId = 12,
            locationName = "Storm Plains",
            completed = false
        },
        rewards = {
            gold = 950,
            items = {
                {
                    type = "accessory",
                    name = "Storm Rider's Cloak",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 111110
    },
    {
        id = "tribal_diplomacy",
        name = "Tribal Diplomacy",
        description = "Escort a diplomatic envoy to negotiate peace between warring tribes.",
        type = "ESCORT",
        level = 11,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        location = "Khulaan",
        objective = {
            type = "escort",
            npcId = 7,
            npcName = "Envoy Batbayar",
            locationId = 7,
            locationName = "Neutral Grounds",
            completed = false,
            failed = false
        },
        rewards = {
            gold = 600,
            items = {
                {
                    type = "accessory",
                    name = "Peacemaker's Medal",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 121212
    },
    
    -- VARGSTAD QUESTS (Mountain/Coastal City, reputation needed: 800)
    {
        id = "frost_giant_raids",
        name = "Frost Giant Raids",
        description = "Frost giants from the high peaks are raiding the mountain settlements. Drive them back.",
        type = "KILL",
        level = 12,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        location = "Vargstad",
        objective = {
            type = "kill",
            targetId = "frost_giant",
            targetName = "Frost Giant",
            count = 5,
            current = 0
        },
        rewards = { gold = 550, items = {} },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 131313
    },
    {
        id = "sea_serpent_menace",
        name = "Sea Serpent Menace",
        description = "A massive sea serpent is attacking merchant ships in the harbor. Hunt it down.",
        type = "BOSS",
        level = 16,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        location = "Vargstad",
        objective = {
            type = "boss",
            bossId = "sea_serpent_boss",
            bossName = "Ancient Sea Serpent",
            locationId = 13,
            locationName = "Deep Harbor",
            completed = false
        },
        rewards = {
            gold = 1300,
            items = {
                {
                    type = "weapon",
                    name = "Serpent's Bane Harpoon",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 141414
    },
    {
        id = "northern_lights_mystery",
        name = "Mystery of the Northern Lights",
        description = "Strange magical phenomena in the northern lights threaten to tear reality apart.",
        type = "EXPLORE",
        level = 14,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        location = "Vargstad",
        objective = {
            type = "explore",
            locationId = 14,
            locationName = "Aurora Peaks",
            completed = false
        },
        rewards = {
            gold = 700,
            items = {
                {
                    type = "accessory",
                    name = "Aurora Stone",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 151515
    },
    {
        id = "dragon_king_awakening",
        name = "The Dragon King's Awakening",
        description = "The legendary Dragon King has awakened from its millennium slumber. Face this ultimate challenge.",
        type = "BOSS",
        level = 20,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Guild",
        location = "Vargstad",
        objective = {
            type = "boss",
            bossId = "dragon_king_boss",
            bossName = "Dragon King",
            locationId = 15,
            locationName = "Dragon's Peak",
            completed = false
        },
        rewards = {
            gold = 2000,
            items = {
                {
                    type = "weapon",
                    name = "Dragonslayer",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 161616
    },
    {
        id = "viking_funeral_rites",
        name = "Viking Funeral Rites",
        description = "Honor the fallen warriors by completing the ancient funeral rites while defending against undead.",
        type = "ESCORT",
        level = 15,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        location = "Vargstad",
        objective = {
            type = "escort",
            npcId = 8,
            npcName = "Jarl Magnus",
            locationId = 8,
            locationName = "Sacred Fjord",
            completed = false,
            failed = false
        },
        rewards = {
            gold = 800,
            items = {
                {
                    type = "weapon",
                    name = "Honored Warrior's Axe",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 171717
    },
    {
        id = "kraken_depths",
        name = "Into the Kraken's Depths",
        description = "Dive into the deepest ocean trenches to face the legendary Kraken in its domain.",
        type = "BOSS",
        level = 18,
        difficulty = 3, -- questSystem.DIFFICULTY.HARD
        giver = "Tavern",
        location = "Vargstad",
        objective = {
            type = "boss",
            bossId = "kraken_boss",
            bossName = "Ancient Kraken",
            locationId = 16,
            locationName = "Abyssal Depths",
            completed = false
        },
        rewards = {
            gold = 1500,
            items = {
                {
                    type = "accessory",
                    name = "Kraken's Heart",
                    count = 1
                }
            }
        },
        status = "available", -- questSystem.STATUS.AVAILABLE
        seed = 181818
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
    {id = 8, name = "Slime Caverns"},
    {id = 9, name = "Desert Depths"},
    {id = 10, name = "Enchanted Ruins"},
    {id = 11, name = "Sacred Burial Grounds"},
    {id = 12, name = "Storm Plains"},
    {id = 13, name = "Deep Harbor"},
    {id = 14, name = "Aurora Peaks"},
    {id = 15, name = "Dragon's Peak"},
    {id = 16, name = "Abyssal Depths"}
}

local itemTargets = {
    {id = "item_rare_herb", name = "Rare Healing Herb"},
    {id = "item_magic_crystal", name = "Magic Crystal"},
    {id = "item_ancient_relic", name = "Ancient Relic"},
    {id = "item_dragon_scale", name = "Dragon Scale"},
    {id = "item_enchanted_gem", name = "Enchanted Gem"},
    {id = "item_desert_artifact", name = "Desert Artifact"},
    {id = "item_spirit_herb", name = "Spirit Herb"}
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
    {id = 5, name = "Prince Aldric"},
    {id = 6, name = "Spice Merchant Hakim"},
    {id = 7, name = "Envoy Batbayar"},
    {id = 8, name = "Jarl Magnus"}
}

local escortLocations = {
    {id = 1, name = "Trade Route"},
    {id = 2, name = "Mountain Pass"},
    {id = 3, name = "Ancient Road"},
    {id = 4, name = "Swamp Path"},
    {id = 5, name = "Royal Highway"},
    {id = 6, name = "Desert Pass"},
    {id = 7, name = "Neutral Grounds"},
    {id = 8, name = "Sacred Fjord"}
}

-- Make these tables accessible through the returned questData
questData.bossLocations = bossLocations
questData.itemTargets = itemTargets
questData.exploreLocations = exploreLocations
questData.escortNpcs = escortNpcs
questData.escortLocations = escortLocations

return questData
