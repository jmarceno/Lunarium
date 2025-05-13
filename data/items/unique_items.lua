-- Unique Items Definitions
-- This file contains all unique item definitions
-- Each unique item has standard item properties plus special unique effects

return {
    UniqueGloryAmuletID = {
        name = "Glory Amulet",
        description = "An ancient amulet that enhances fire magic.",
        type = "accessory",
        slot = "amulet",
        rarity = "unique", -- New rarity type for unique items
        defense = 5,
        magicDefense = 15,
        value = 5000,
        requirements = {
            INT = 20
        },
        jobs = {"Mage", "BlackMage"},
        
        -- New unique item properties
        unique = true,
        uniqueEffects = {
            -- Fire damage enhancement
            {
                id = "GloryAmuletFireBoost", 
                type = "damage_modifier",
                condition = {
                    operator = "AND",
                    clauses = {
                        { type = "skill_element", value = "fire" }
                    }
                },
                effect = {
                    damage_multiplier = 1.5 -- 50% increased fire damage
                }
            }
        }
    },
    
    UniqueDragonSlayerSword = {
        name = "Dragon Slayer",
        description = "A legendary sword that deals increased damage to dragon-type enemies.",
        type = "weapon",
        slot = "weapon",
        weaponType = "sword",
        rarity = "unique",
        attack = 45,
        defense = 5,
        value = 10000,
        requirements = {
            STR = 3
        },
        jobs = {"Fighter", "Paladin"},
        
        unique = true,
        uniqueEffects = {
            {
                id = "DragonSlayerEffect",
                type = "enemy_weakness",
                condition = {
                    operator = "AND",
                    clauses = {
                        { type = "target_type", value = "dragon" }
                    }
                },
                effect = {
                    enemy_type = "dragon",
                    multiplier = 2.0 -- Double damage against dragons
                }
            }
        }
    },
    
    UniqueCelestialOrb = {
        name = "Celestial Orb",
        description = "A mysterious orb that grants the power to call meteors.",
        type = "accessory",
        slot = "amulet",
        rarity = "unique",
        magicDefense = 10,
        magicAttack = 15,
        value = 8000,
        requirements = {
            INT = 25
        },
        jobs = {"Mage", "BlackMage", "WhiteMage"},
        
        unique = true,
        uniqueEffects = {
            {
                id = "CelestialOrbGrantMeteor",
                type = "grant_skill",
                effect = {
                    skillId = "MeteorShower" -- ID of the skill to grant
                }
            }
        }
    },
    
    UniqueProtectorPlate = {
        name = "Protector's Plate",
        description = "Ancient armor that reduces fire and ice damage.",
        type = "armor",
        slot = "body",
        rarity = "unique",
        defense = 25,
        magicDefense = 15,
        value = 7500,
        requirements = {
            CON = 20
        },
        jobs = {"Fighter", "Paladin", "Warrior"},
        
        unique = true,
        uniqueEffects = {
            {
                id = "ProtectorPlateFireResist",
                type = "elemental_resistance",
                effect = {
                    element = "fire",
                    value = 0.3 -- 30% reduced fire damage
                }
            },
            {
                id = "ProtectorPlateIceResist",
                type = "elemental_resistance",
                effect = {
                    element = "ice",
                    value = 0.3 -- 30% reduced ice damage
                }
            }
        }
    },
    
    UniqueTomeOfSummoning = {
        name = "Tome of Summoning",
        description = "An ancient book that enhances minions and summons.",
        type = "weapon",
        slot = "weapon",
        weaponType = "staff",
        rarity = "unique",
        attack = 15,
        magicAttack = 30,
        value = 8500,
        requirements = {
            INT = 28,
            WIS = 20
        },
        jobs = {"Mage", "Necromancer"},
        
        unique = true,
        uniqueEffects = {
            {
                id = "TomeMinionStrength",
                type = "minion_buff",
                effect = {
                    stat_multiplier = 1.3 -- 30% increase to minion stats
                }
            },
            {
                id = "TomeMinionTargeting",
                type = "minion_taunt",
                effect = {
                    taunt_value = 0.7 -- 30% less likely to be targeted instead of minions
                }
            }
        }
    },
    
    UniqueLuckyAmulet = {
        name = "Adventurer's Luck",
        description = "A charm that helps find rarer treasures.",
        type = "accessory",
        slot = "amulet",
        rarity = "unique",
        defense = 3,
        magicDefense = 8,
        value = 6000,
        requirements = {
            CHA = 18
        },
        jobs = {"Rogue", "Ranger"},
        
        unique = true,
        uniqueEffects = {
            {
                id = "LuckyAmuletRareLoot",
                type = "loot_modifier",
                effect = {
                    rarity_multiplier = 1.25 -- 25% more likely to find rare items
                }
            }
        }
    }
} 