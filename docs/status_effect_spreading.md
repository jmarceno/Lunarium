# Status Effect Spreading System

## Overview

The Status Effect Spreading System allows certain status effects to spread from one entity to its allies. This system adds an extra layer of strategy to combat by introducing the possibility of effects like "Burn" propagating through enemy groups or player teams.

## How It Works

1. After each entity completes its turn (player character, enemy, or minion), the system checks for spreadable status effects on that entity.

2. For each spreadable status effect, the system:
   - Rolls a check against the effect's `spreadChance` property
   - If successful, selects a random ally that doesn't already have the effect
   - Applies the effect to the chosen target with the same duration and strength

3. The spreading happens separately within each team:
   - Player characters can only spread effects to other player characters
   - Enemies can only spread effects to other enemies
   - Minions can only spread effects to other minions

4. This means in a battle with 4 party members, 2 minions, and 3 enemies, there could be up to 9 separate spread checks during a complete combat round.

## Implementation Details

### Status Effect Definition

To make a status effect spreadable, add the following properties to its definition in `gameplay/statusEffects.lua`:

```lua
["example_effect"] = {
    name = "Example Effect",
    description = "Does something and can spread to allies",
    icon = "assets/Icons/StatusEffects/example.png",
    iconSize = 24,
    statusType = "negative",
    canSpread = true,        -- Flag to enable spreading
    spreadChance = 0.5,      -- 50% chance to spread after entity's turn
    -- other properties...
}
```

### Key Functions

1. `statusEffects:processEffectSpreading(entities, entityType, combat)`
   - Located in `gameplay/statusEffects.lua`
   - Processes all entities for spreadable effects
   - Parameters:
     - `entities`: Table of entities to check
     - `entityType`: Type of entity ("party", "enemy", "minion")
     - `combat`: Combat instance for logging

2. Integration in `gameplay/combat/coreFunctions.lua`
   - Called within the `nextTurn` function after processing status effects for each entity type:
     - After a player character's turn
     - After a minion's turn
     - After an enemy's turn
   - Separates entities by type (party, enemies, minions)
   - Calls the processing function for the appropriate group

## Visual Feedback

When a status effect spreads, the system provides feedback in the form of:
1. A combat log message
2. A floating text message near the affected entity
3. Color-coded messages (orange for spreading effects)

## Example

The "Burn" status effect is configured to spread with a 50% chance:

```lua
["burn"] = {
    name = "Burn",
    description = "Takes fire damage at the start of each turn",
    icon = "assets/Icons/StatusEffects/burn.png",
    iconSize = 24,
    statusType = "negative",
    canSpread = true,
    spreadChance = 0.5,
    -- other properties...
}
```

If an enemy has the Burn effect, after each enemy's turn, there's a 50% chance it will spread to another random enemy that doesn't already have the effect.

## Considerations for Balance

When designing spreadable status effects, consider:
- The `spreadChance` value (higher values lead to more rapid spreading)
- The duration of the effect (longer effects have more opportunities to spread)
- The strength of the effect (powerful effects should have lower spread chances)
- Group size (effects spread more efficiently in larger groups)
- Turn frequency (effects will have more chances to spread in larger battles) 