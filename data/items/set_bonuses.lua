-- Set Bonuses Definitions
-- This file contains all set bonus effects
-- Each set has bonuses that activate at different piece thresholds

return {
    Firewalker = {
        [2] = { -- 2-piece bonus
            type = "elemental_resistance",
            element = "fire",
            value = 0.5 -- 50% reduced fire damage
        },
        [3] = { -- 3-piece bonus (complete set)
            type = "immunity",
            element = "fire" -- Complete immunity to fire damage
        }
    },
    
    Frostbite = {
        [2] = { -- 2-piece bonus
            type = "elemental_resistance",
            element = "ice",
            value = 0.3 -- 30% reduced ice damage
        },
        [3] = { -- 3-piece bonus
            type = "damage_modifier",
            condition = {
                operator = "AND",
                clauses = {
                    { type = "skill_element", value = "ice" }
                }
            },
            damage_multiplier = 1.3 -- 30% increased ice damage
        },
        [4] = { -- 4-piece bonus (complete set)
            type = "grant_skill",
            effect = {
                skillId = "Blizzard" -- Grants the Blizzard skill
            }
        }
    }
} 