# Unique and Set Items Implementation Plan

## Original Prompt

```
We now need to implement unique items. They are magic items (only equipable items) that can have special behavior. This special behavior can trigger a different code path to change how a specific game rule works. Some examples are below. Keep in mind that they are just a limited set of examples and much more complex ones will be designed later. The idea is for those items to work the way that unique items work in Path of Exile, Last Epoch and Diablo 2 and the way that Legendary items work on Diablo 3 and Diablo 4

Examples of behaviors a unique item can have:
	- Change damage type
	- Cause an enemy type to take increased damage (of all types or specific type)
	- Cause a character/party member/all party members to take less damage (of all types or specific type)
	- Cause a character/party member/all party members to take more damage (of all types or specific type)
	- Give a character a skill that it not at in any jobs' skill list
	- Make it easier to find loot that is rarer
	- Apply a specific status to an enemy or party member
	- Make the character minions stronger
	- Make the character minions be more/less likely to be choosen as target by the enemies 

Now, with all these potential rules in memory, go throught the project code part responsible for combat, items, skills, monsters and characters, carefully analyze it and plan the best way to implement this system with the following priorities
1. Data and new code paths for these special items should be very well separated and organized to make it easy to add and remove them
2. Least amount of refactoring necessary. Big refactors cause all types of bugs and unpredictable behavior. We should keep changes to a minimum of
3. Easy of testing. We should have a way to quickly add these items to the party (during development only) so we can test the items.
4. As a bonus, try to plan a way to implement the system to support Set Items, those would work like how set items work in Diablo 2, Diablo 3, Last Epoch and Grim Dawn
```

## Implementation Plan Summary

This document outlines a comprehensive implementation plan for adding unique items and set items to the game, with minimal refactoring of existing code while maintaining a clean, modular design.

Key priorities addressed:
1. ✅ Well-separated data structures and code paths
2. ✅ Minimal refactoring of existing systems
3. ✅ Easy testing mechanisms
4. ✅ Support for set items as a bonus feature

## 1. Data Structure for Unique Items

The foundation of our implementation is a clear, extensible data structure for unique items:

```lua
-- Example unique item structure
UniqueGloryAmulet = {
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
            type = "damage_modifier",
            condition = {
                skill_element = "fire" -- This effect applies only to fire skills
            },
            effect = {
                damage_multiplier = 1.5 -- 50% increased fire damage
            }
        }
    }
}
```

This structure provides:
- Standard item properties compatible with the existing system
- A dedicated `uniqueEffects` array for special behaviors
- Conditional triggers that determine when effects activate
- Effect parameters that define what happens when triggered

## 2. New Module for Unique Item Handling

### A. Core Unique Item System Module

Create a new file: `gameplay/uniqueItemSystem.lua` to handle unique item functionality:

```lua
local uniqueItemSystem = {
    -- Registry of all available unique effect handlers
    effectHandlers = {}
}

-- Register effect handlers for different unique effects
function uniqueItemSystem:registerEffectHandler(effectType, handlerFunction)
    self.effectHandlers[effectType] = handlerFunction
end

-- Process unique item effects during combat
function uniqueItemSystem:processEffects(context)
    -- context contains: character, target, skill, baseDamage, etc.
    local character = context.character
    local modifiedValue = context.value -- Could be damage, healing, etc.
    
    -- Check all equipped items for unique effects
    for slot, item in pairs(character.equipment) do
        if item and item.unique and item.uniqueEffects then
            for _, effect in ipairs(item.uniqueEffects) do
                -- Get the handler for this effect type
                local handler = self.effectHandlers[effect.type]
                
                -- Apply the effect if handler exists and conditions are met
                if handler and self:checkEffectConditions(effect.condition, context) then
                    modifiedValue = handler(modifiedValue, effect.effect, context)
                end
            end
        end
    end
    
    return modifiedValue
end

-- Check if effect conditions are met
function uniqueItemSystem:checkEffectConditions(condition, context)
    if not condition then return true end -- No conditions means always active
    
    -- Check each condition
    for key, value in pairs(condition) do
        -- Example: skill_element condition
        if key == "skill_element" and context.skill and context.skill.element ~= value then
            return false
        end
        -- Example: enemy_type condition
        if key == "enemy_type" and context.target and context.target.type ~= value then
            return false
        end
        -- More conditions can be added here
    end
    
    return true -- All conditions passed
end

return uniqueItemSystem
```

### B. Effect Handler Registration

Register handlers for various effect types:

```lua
-- Example effect handlers
uniqueItemSystem:registerEffectHandler("damage_modifier", function(damage, effect, context)
    -- Apply damage modifier
    if effect.damage_multiplier then
        return damage * effect.damage_multiplier
    end
    return damage
end)

uniqueItemSystem:registerEffectHandler("damage_type_change", function(damage, effect, context)
    -- Change damage type
    if effect.new_element and context.skill then
        context.skill.element = effect.new_element
    end
    return damage
end)

uniqueItemSystem:registerEffectHandler("enemy_weakness", function(damage, effect, context)
    -- Apply increased damage to specific enemy types
    if effect.enemy_type and effect.multiplier and context.target.type == effect.enemy_type then
        return damage * effect.multiplier
    end
    return damage
end)

-- Additional handlers for other effect types...
```

## 3. Integration Points in Existing Code

### A. Combat System Integration

Modify `playerActionFunctions.lua` to incorporate unique item effects:

```lua
-- Current code in playerActionFunctions.lua
damage, isCritical = skillSystem:calculateDamage(
    self.selectedSkill,
    currentChar,
    self.selectedTarget,
    currentChar.skills[self.selectedSkill.name].level
)

-- Modified code with unique item effects
damage, isCritical = skillSystem:calculateDamage(
    self.selectedSkill,
    currentChar,
    self.selectedTarget,
    currentChar.skills[self.selectedSkill.name].level
)

-- Apply unique item effects
damage = uniqueItemSystem:processEffects({
    character = currentChar,
    target = self.selectedTarget,
    skill = self.selectedSkill,
    value = damage,
    is_critical = isCritical
})
```

### B. Character System Enhancement

Add a method to check for unique item effects:

```lua
-- Add to character.lua
function character:getUniqueItemEffects(char, effectType)
    local effects = {}
    
    -- Check all equipped items
    for slot, item in pairs(char.equipment) do
        if item and item.unique and item.uniqueEffects then
            for _, effect in ipairs(item.uniqueEffects) do
                if effect.type == effectType then
                    table.insert(effects, effect)
                end
            end
        end
    end
    
    return effects
end
```

## 4. Special Skills Granted by Unique Items

Implement unique items that grant skills not normally available to a job:

```lua
-- Example unique item that grants a special skill
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
    
    -- Unique properties
    unique = true,
    uniqueEffects = {
        {
            type = "grant_skill",
            effect = {
                skill = "MeteorShower" -- This skill is normally not available to these jobs
            }
        }
    }
}

-- Add handler for granted skills
uniqueItemSystem:registerEffectHandler("grant_skill", function(_, effect, context)
    -- This is a special case that doesn't modify a value directly
    -- The skill will be added to available skills in the UI
    return _
end)
```

## 5. Testing System

### A. Debug Console Commands

We've implemented debug console commands to make testing easy:

```lua
-- Add item to player inventory
self:addCommand("add_item", function(args)
    if #args < 1 then
        return "Usage: add_item <itemName> [quantity]"
    end
    
    local itemName = args[1]
    local quantity = tonumber(args[2]) or 1
    local itemSystem = require("gameplay/item")
    -- Add item to inventory...
    
    return "Added " .. quantity .. "x " .. item.name .. " to inventory"
end)

-- Add unique item to inventory for testing
self:addCommand("add_unique", function(args)
    if #args < 1 then
        return "Usage: add_unique <uniqueItemName>"
    end
    
    local itemName = args[1]
    local itemSystem = require("gameplay/item")
    -- Add unique item to inventory...
    
    return "Added unique item: " .. item.name
end)

-- List all unique items
self:addCommand("list_uniques", function()
    local itemSystem = require("gameplay/item")
    local uniqueItems = {}
    -- List unique items...
    
    return "Available unique items:\n" .. table.concat(uniqueItems, "\n")
end)
```

## 6. Set Items Implementation

### A. Set Item Data Structure

```lua
-- Example set item structure
FirewalkerBoots = {
    name = "Firewalker Boots",
    description = "Boots that protect against fire and lava.",
    type = "armor",
    slot = "feet", -- Would need to add a new slot
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
}

-- Define set bonuses
local setItemBonuses = {
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
}
```

### B. Set Bonus Processing

```lua
-- Add to uniqueItemSystem.lua
function uniqueItemSystem:getEquippedSetBonuses(character)
    local setsPieces = {}
    local activeBonuses = {}
    
    -- Count equipped set pieces
    for slot, item in pairs(character.equipment) do
        if item and item.setItem and item.setName then
            setsPieces[item.setName] = (setsPieces[item.setName] or 0) + 1
        end
    end
    
    -- Check which set bonuses are active
    for setName, count in pairs(setsPieces) do
        if setItemBonuses[setName] then
            for pieceCount, bonus in pairs(setItemBonuses[setName]) do
                if count >= pieceCount then
                    table.insert(activeBonuses, bonus)
                end
            end
        end
    end
    
    return activeBonuses
end

-- Include set bonuses in effect processing
function uniqueItemSystem:processEffects(context)
    local character = context.character
    local modifiedValue = context.value
    
    -- Process unique item effects (existing code)
    
    -- Also process set bonuses
    local setEffects = self:getEquippedSetBonuses(character)
    for _, effect in ipairs(setEffects) do
        local handler = self.effectHandlers[effect.type]
        if handler then
            modifiedValue = handler(modifiedValue, effect, context)
        end
    end
    
    return modifiedValue
end
```

## Implementation Process

The proposed implementation will follow this sequence:

1. Create the `uniqueItemSystem.lua` module
2. Add unique item data structures to `item_definitions.lua`
3. Integrate unique item effects into combat calculations
4. Implement UI enhancements to display unique properties
5. Add set item functionality
6. Test thoroughly with debug commands

## Conclusion

This implementation plan provides a flexible, modular approach to unique and set items with minimal refactoring of existing code. The design emphasizes:

- Clear separation between standard item properties and unique effects
- Extensible effect handler system for easy addition of new behaviors
- Conditional activation of effects based on combat context
- Support for set bonuses with progressive rewards
- Easy testing through debug console commands

By following this plan, we can implement a robust unique item system that supports complex behaviors while maintaining code quality and minimizing the risk of introducing bugs. 