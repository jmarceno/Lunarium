# Unique and Set Items System

This directory contains the data files for the unique and set items system.

## Overview

The unique items system allows for special equipment with custom effects that can significantly change game mechanics. Set items function similarly but provide additional bonuses when multiple pieces of the same set are equipped.

## Files

- `unique_items.lua`: Contains definitions for all unique items
- `set_items.lua`: Contains definitions for all set items
- `set_bonuses.lua`: Contains definitions for set bonuses when multiple pieces of a set are equipped

## How It Works

### Unique Items

Unique items have special effects defined in their `uniqueEffects` array. Each effect has:

- `id`: A unique identifier for the effect
- `type`: The type of effect (e.g., "damage_modifier", "elemental_resistance")
- `condition`: Optional conditions that determine when the effect is applied
- `effect`: Parameters for the effect

Example:
```lua
UniqueGloryAmuletID = {
    name = "Glory Amulet",
    description = "An ancient amulet that enhances fire magic.",
    type = "accessory",
    slot = "amulet",
    rarity = "unique",
    defense = 5,
    magicDefense = 15,
    value = 5000,
    requirements = { INT = 20 },
    jobs = {"Mage", "BlackMage"},
    
    unique = true,
    uniqueEffects = {
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
}
```

### Set Items

Set items belong to a set and provide bonuses when multiple pieces of the same set are equipped.

Example:
```lua
FirewalkerBoots = {
    name = "Firewalker Boots",
    description = "Boots that protect against fire and lava.",
    type = "armor",
    slot = "feet",
    rarity = "set",
    defense = 8,
    magicDefense = 12,
    value = 3000,
    requirements = { DEX = 15 },
    jobs = {"Fighter", "Mage", "BlackMage"},
    
    setItem = true,
    setName = "Firewalker",
    setPiece = 1,
    setTotalPieces = 3
}
```

### Set Bonuses

Set bonuses are defined in `set_bonuses.lua` and are applied when a character has multiple pieces of the same set equipped.

Example:
```lua
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
}
```

## Testing

Use the debug console commands to test unique and set items:

- `add_unique <uniqueItemId>`: Add a unique item to the inventory
- `list_uniques`: List all available unique items
- `add_set_item <setItemId>`: Add a set item to the inventory
- `list_set_items`: List all available set items
- `add_full_set <setName>`: Add all pieces of a set to the inventory

## Adding New Items

To add new unique or set items:

1. Define the item in `unique_items.lua` or `set_items.lua`
2. For set items, define the set bonuses in `set_bonuses.lua`
3. Register any new effect handlers in `gameplay/uniqueItemSystem.lua`

## Effect Types

The system supports various effect types:

- `damage_modifier`: Modifies outgoing damage
- `damage_type_change`: Changes the element type of a skill
- `enemy_weakness`: Increases damage against specific enemy types
- `elemental_resistance`: Reduces damage from certain elements
- `immunity`: Provides complete immunity to certain damage types
- `minion_buff`: Enhances minion stats
- `minion_taunt`: Changes how enemies target minions
- `loot_modifier`: Modifies loot drop rates
- `grant_skill`: Grants access to skills the character doesn't normally have 