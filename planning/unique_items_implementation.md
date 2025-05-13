# Unique and Set Items Implementation Plan
[REVISION 1.0.0 - Initial Document]
[REVISION 1.1.0 - Comprehensive Review and Enhancements]

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

This document outlines a comprehensive implementation plan for adding unique items and set items to the game, with minimal refactoring of existing code while maintaining a clean, modular design. This version (1.1.0) incorporates feedback from a detailed review to enhance clarity, robustness, and extensibility.

Key priorities addressed:
1. ✅ Well-separated data structures and code paths
2. ✅ Minimal refactoring of existing systems
3. ✅ Easy testing mechanisms
4. ✅ Support for set items as a bonus feature
5. ✅ Enhanced flexibility for effect conditions and types [REVISION 1.1.0]
6. ✅ Clearer data management and UI considerations [REVISION 1.1.0]

## 1. Data Structure for Unique Items

The foundation of our implementation is a clear, extensible data structure for unique items.

**[REVISION 1.1.0 - Addressed: Point 1 - Definition and Storage of Unique Items]**
### A. Unique Item Definition and Storage
Unique item definitions, like the example below, will reside in a dedicated Lua module, for example, `data/items/unique_items.lua`. This module will return a table of all unique items, indexed by a unique item ID (e.g., "UniqueGloryAmuletID"). The game's item system will load these definitions at startup and merge them into its master item list, making them accessible via their IDs.

```lua
-- Example unique item structure (in data/items/unique_items.lua)
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
                id = "GloryAmuletFireBoost", -- Unique ID for this specific effect instance
                type = "damage_modifier",
                -- [REVISION 1.1.0 - Addressed: Point 5 - Enhanced Conditions] See section 2.C for new condition structure
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
    -- ... other unique items
}
```

This structure provides:
- Standard item properties compatible with the existing system
- A dedicated `uniqueEffects` array for special behaviors
- Conditional triggers that determine when effects activate (now more flexible, see Section 2.C)
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

-- [REVISION 1.1.0 - Addressed: Point 2 - The `context` Object and Diverse Effects]
-- Process unique item effects. The 'context' object's structure is crucial and will vary.
-- It should always include 'eventType' to guide handlers.
function uniqueItemSystem:processEffects(context)
    -- context MUST contain: eventType (e.g., "CALCULATE_OUTGOING_DAMAGE", "CHARACTER_TAKES_DAMAGE", "LOOT_GENERATED", "MINION_SUMMONED")
    -- context MAY contain: character, target, skill, baseDamage, incomingDamage, lootTable, minionRef, etc., depending on eventType
    local character = context.character
    local modifiedValue = context.value -- Generic field, interpretation depends on eventType and handler

    if not character or not character.equipment then return modifiedValue end
    
    -- Check all equipped items for unique effects
    for slot, item in pairs(character.equipment) do
        if item and item.unique and item.uniqueEffects then
            for _, effectInstance in ipairs(item.uniqueEffects) do
                local handler = self.effectHandlers[effectInstance.type]
                
                if handler and self:checkEffectConditions(effectInstance.condition, context) then
                    -- [REVISION 1.1.0 - Addressed: Point 8 - Side Effects in Handlers]
                    -- Handlers should be mindful of modifying context directly.
                    -- If context fields are tables/objects, pass copies if mutation is not intended to be global.
                    modifiedValue = handler(modifiedValue, effectInstance.effect, context)
                end
            end
        end
    end
    
    return modifiedValue
end

-- [REVISION 1.1.0 - Addressed: Point 5 - Enhanced Conditions]
-- Check if effect conditions are met using a more flexible structure.
function uniqueItemSystem:checkEffectConditions(condition, context)
    if not condition then return true end -- No conditions means always active

    local function evaluateClause(clause)
        -- Check character-specific conditions
        if context.character then
            if clause.type == "character_health_percentage" then
                local currentHpPercent = context.character.currentHp / context.character.maxHp
                if clause.comparison == "less_than" then return currentHpPercent < clause.value end
                if clause.comparison == "greater_than_or_equal_to" then return currentHpPercent >= clause.value end
            elseif clause.type == "character_status" then
                return context.character:hasStatus(clause.status) -- Assumes a character:hasStatus() method
            end
        end

        -- Check target-specific conditions (if target exists in context)
        if context.target then
            if clause.type == "target_type" and context.target.type ~= clause.value then
                return false
            elseif clause.type == "target_status" then
                 return context.target:hasStatus(clause.status) -- Assumes a target:hasStatus() method
            elseif clause.type == "target_health_percentage" then
                local targetHpPercent = context.target.currentHp / context.target.maxHp
                if clause.comparison == "less_than" then return targetHpPercent < clause.value end
                if clause.comparison == "greater_than_or_equal_to" then return targetHpPercent >= clause.value end
            end
        end
        
        -- Check skill-specific conditions (if skill exists in context)
        if context.skill then
            if clause.type == "skill_element" and context.skill.element ~= clause.value then
                return false
            end
        end
        -- Add more clause type evaluations here (e.g., game_state, party_member_count, etc.)
        return true -- Default for unimplemented or irrelevant clause types in this simple example
    end

    local function evaluate(cond)
        if cond.operator == "AND" then
            for _, clauseOrSubCondition in ipairs(cond.clauses) do
                if clauseOrSubCondition.operator then -- It's a sub-condition
                    if not evaluate(clauseOrSubCondition) then return false end
                else -- It's a direct clause
                    if not evaluateClause(clauseOrSubCondition) then return false end
                end
            end
            return true
        elseif cond.operator == "OR" then
            for _, clauseOrSubCondition in ipairs(cond.clauses) do
                if clauseOrSubCondition.operator then -- It's a sub-condition
                    if evaluate(clauseOrSubCondition) then return true end
                else -- It's a direct clause
                    if evaluateClause(clauseOrSubCondition) then return true end
                end
            end
            return false
        else -- Single condition (legacy or simple form)
            return evaluateClause(cond)
        end
    end

    return evaluate(condition)
end

-- [REVISION 1.1.0 - Addressed: Point 2 - Diverse Effect Types]
### B. Handling Diverse Effect Types and Integration Points
The `uniqueItemSystem:processEffects` function is generic. Specific game systems will call it with an appropriately populated `context` object when a relevant event occurs.
For example:
- **Combat System:** Calls `processEffects` with `eventType = "CALCULATE_OUTGOING_DAMAGE"` before damage is finalized, or `eventType = "CHARACTER_TAKES_DAMAGE"` when damage is received.
- **Loot System:** Could call `processEffects` with `eventType = "LOOT_GENERATION_MODIFIERS"` to apply effects that alter loot rarity or quantity. `context` would include `character` and `currentLootTable`.
- **Minion System:** Could call `processEffects` with `eventType = "MINION_STAT_MODIFICATION"` upon minion summon or when its stats are recalculated. `context` would include `character` (owner) and `minionReference`.

This requires identifying all relevant integration points across game systems.

-- [REVISION 1.1.0 - Addressed: Point 8 - Side Effects in Handlers]
### C. Effect Handler Registration and Best Practices
Register handlers for various effect types. Handlers should be designed with the `context` object in mind and understand the `eventType`.

**Best Practice for Handlers:**
- **Idempotency where possible:** If a handler might be called multiple times for the same event, ensure it behaves correctly.
- **Scoped Modifications:** When modifying parts of the `context` (especially tables or objects like `context.skill`), be clear about the scope. If the modification should only apply to the current calculation instance, the handler or the calling system should ensure it operates on a copy or that the change is reverted. For example, `damage_type_change` should affect a temporary skill data copy for the current attack.
- **Return Values:** Handlers for value-modifying effects should return the modified value. Handlers for other types of effects (e.g., applying a status) might return a status code or nothing, relying on modifications to the `context` (e.g., `context.statusesToApply`).

```lua
-- Example effect handlers
uniqueItemSystem:registerEffectHandler("damage_modifier", function(damage, effect, context)
    -- Assumes context.eventType is appropriate (e.g., "CALCULATE_OUTGOING_DAMAGE")
    if effect.damage_multiplier then
        return (damage or 0) * effect.damage_multiplier
    end
    return damage
end)

uniqueItemSystem:registerEffectHandler("damage_type_change", function(damage, effect, context)
    -- Assumes context.eventType is "CALCULATE_OUTGOING_DAMAGE" and context.skill is a mutable copy for this instance
    if effect.new_element and context.skill then
        context.skill.element = effect.new_element
        -- This handler primarily causes a side-effect on a mutable part of the context.
        -- The 'damage' value itself might not change here, but the skill's properties do.
    end
    return damage
end)

uniqueItemSystem:registerEffectHandler("enemy_weakness", function(damage, effect, context)
    -- Assumes context.eventType is "CALCULATE_OUTGOING_DAMAGE" and context.target exists
    if context.target and effect.enemy_type and effect.multiplier and context.target.type == effect.enemy_type then
        return (damage or 0) * effect.multiplier
    end
    return damage
end)

-- [REVISION 1.1.0 - Addressed: Point 4 - Set Bonus Application & Point 2 - Diverse Effects]
-- Example for a defensive effect (could also be a set bonus type)
uniqueItemSystem:registerEffectHandler("elemental_resistance", function(incomingDamage, effect, context)
    -- Assumes context.eventType is "CHARACTER_TAKES_DAMAGE"
    -- and context.damageType matches effect.element
    if context.damageType and effect.element and context.damageType == effect.element then
        return (incomingDamage or 0) * (1 - (effect.value or 0)) -- effect.value is 0.5 for 50% resistance
    end
    return incomingDamage
end)

-- Additional handlers for other effect types...
```

## 3. Integration Points in Existing Code

### A. Combat System Integration

Modify `playerActionFunctions.lua` (and potentially enemy AI and incoming damage calculations) to incorporate unique item effects.

```lua
-- Current code in playerActionFunctions.lua (outgoing damage example)
damage, isCritical = skillSystem:calculateDamage(
    self.selectedSkill,
    currentChar,
    self.selectedTarget,
    currentChar.skills[self.selectedSkill.name].level
)

-- Modified code with unique item effects
local skillInstance = deepcopy(self.selectedSkill) -- Create a mutable copy for this calculation
local baseDamage, isCritical = skillSystem:calculateDamage(
    skillInstance,
    currentChar,
    self.selectedTarget,
    currentChar.skills[skillInstance.name].level -- Use original skill name for level lookup
)

-- Apply unique item effects that modify outgoing damage
local damageProcessingContext = {
    eventType = "CALCULATE_OUTGOING_DAMAGE",
    character = currentChar,
    target = self.selectedTarget,
    skill = skillInstance, -- Pass the mutable copy
    value = baseDamage,
    is_critical = isCritical,
    -- Potentially add originalDamage = baseDamage if handlers need it
}
local modifiedDamage = uniqueItemSystem:processEffects(damageProcessingContext)
-- The skillInstance.element might have been changed by an effect

-- Further processing with modifiedDamage and potentially modified skillInstance properties...
```
**[REVISION 1.1.0 - Addressed: Point 4 - Set Bonus Integration (Incoming Damage)]**
Similarly, when a character takes damage, an integration point is needed:
```lua
-- Example in a hypothetical takeDamage function for a character
function Character:takeDamage(amount, type, source)
    local damageTakingContext = {
        eventType = "CHARACTER_TAKES_DAMAGE",
        character = self, -- The character taking damage
        source = source,  -- The entity dealing damage
        value = amount,   -- The initial damage amount
        damageType = type
    }
    local finalDamage = uniqueItemSystem:processEffects(damageTakingContext) 
    -- This call will also process set bonuses of type "elemental_resistance" etc.
    -- (assuming set bonus effects are registered with uniqueItemSystem or handled by a similar merged system)

    -- Apply finalDamage...
end
```

### B. Character System Enhancement

**[REVISION 1.1.0 - Addressed: Point 7 - `character:getUniqueItemEffects` Signature & Point 3 - Passive Effects]**
The existing `character:getUniqueItemEffects` function is useful for querying specific passive effects that aren't processed via the main event loop (e.g., for UI display or certain game logic checks).
Its signature should be:
```lua
-- Add to character.lua (or a character utility module)
-- Note: 'Character' as the table name if it's a module, or ensure 'self' is correctly the character instance.
function Character:getActiveEffectsOfType(effectType) -- Renamed for clarity
    local effects = {}
    if not self.equipment then return effects end
    
    for slot, item in pairs(self.equipment) do
        if item and item.unique and item.uniqueEffects then
            for _, effectInstance in ipairs(item.uniqueEffects) do
                if effectInstance.type == effectType then
                    -- For passive effects, conditions might be checked here or assumed always true if no condition field.
                    -- For simplicity, this example assumes it's just collecting potential effects.
                    -- The caller would be responsible for interpreting/applying them.
                    table.insert(effects, effectInstance)
                end
            end
        end
    end
    
    -- This could also be extended to include active set bonuses of the given type.
    -- local setEffects = uniqueItemSystem:getEquippedSetBonuses(self) -- (from section 6.B)
    -- for _, setEffect in ipairs(setEffects) do
    --     if setEffect.type == effectType then table.insert(effects, setEffect) end
    -- end

    return effects
end
```

## 4. Special Skills Granted by Unique Items

**[REVISION 1.1.0 - Addressed: Point 3 - Handling `grant_skill`]**
Implement unique items that grant skills. These are treated as passive effects. The `grant_skill` effect itself doesn't modify a value in `processEffects`. Instead, the skill system or UI would query for these granted skills.

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
            id = "CelestialOrbGrantMeteor",
            type = "grant_skill",
            -- No condition means always active when equipped
            effect = {
                skillId = "MeteorShower" -- ID of the skill to grant
            }
        }
    }
}

-- No specific 'grant_skill' handler needed in the main uniqueItemSystem:processEffects loop for combat.
-- Instead, the character's skill availability logic or UI would use Character:getActiveEffectsOfType("grant_skill").
-- Example:
-- function Character:getAvailableSkills()
--     local allSkills = deepcopy(self.jobSkills) -- Start with job skills
--     local grantedSkillEffects = self:getActiveEffectsOfType("grant_skill")
--     for _, effect in ipairs(grantedSkillEffects) do
--         if effect.effect and effect.effect.skillId then
--             if not table_contains(allSkills, effect.effect.skillId) then -- Psuedo function
--                 table.insert(allSkills, globalSkillDatabase[effect.effect.skillId])
--             end
--         end
--     end
--     return allSkills
-- end
```
The `uniqueItemSystem` does not need a `grant_skill` handler that modifies a value. The presence of this effect type is informational, to be queried by other systems.

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

**[REVISION 1.1.0 - Addressed: Point 4 - Set Bonus Application & Integration with Unique System]**
Set bonuses will be processed by leveraging the same `uniqueItemSystem` and its effect handlers. When a set bonus becomes active, it's treated as another effect source.

```lua
-- Modify uniqueItemSystem.lua
function uniqueItemSystem:getEquippedSetBonuses(character)
    local setsPieces = {}
    local activeBonuses = {} -- This will now collect effect-like structures
    
    if not character or not character.equipment then return activeBonuses end

    -- Count equipped set pieces
    for slot, item in pairs(character.equipment) do
        if item and item.setItem and item.setName then
            setsPieces[item.setName] = (setsPieces[item.setName] or 0) + 1
        end
    end
    
    -- Check which set bonuses are active
    for setName, count in pairs(setsPieces) do
        if setItemBonuses[setName] then -- setItemBonuses defined as in original plan
            for pieceCountStr, bonusData in pairs(setItemBonuses[setName]) do
                local pieceCount = tonumber(pieceCountStr)
                if count >= pieceCount then
                    -- Add the bonus in a structure similar to uniqueEffects
                    table.insert(activeBonuses, {
                        id = setName .. "_SetBonus_" .. pieceCount, -- e.g., Firewalker_SetBonus_2
                        type = bonusData.type, -- e.g., "elemental_resistance"
                        condition = bonusData.condition, -- Set bonuses can also have conditions
                        effect = bonusData -- Pass the whole bonusData as the effect payload
                                           -- (e.g., { element = "fire", value = 0.5 })
                    })
                end
            end
        end
    end
    
    return activeBonuses
end

-- Modify uniqueItemSystem:processEffects(context) to include set bonuses
function uniqueItemSystem:processEffects(context) -- Extended version
    local character = context.character
    local modifiedValue = context.value

    if not character then return modifiedValue end -- Guard clause

    -- 1. Process unique item effects from equipped gear
    if character.equipment then
        for slot, item in pairs(character.equipment) do
            if item and item.unique and item.uniqueEffects then
                for _, effectInstance in ipairs(item.uniqueEffects) do
                    local handler = self.effectHandlers[effectInstance.type]
                    if handler and self:checkEffectConditions(effectInstance.condition, context) then
                        modifiedValue = handler(modifiedValue, effectInstance.effect, context)
                    end
                end
            end
        end
    end
    
    -- 2. Process active set bonuses
    local activeSetEffects = self:getEquippedSetBonuses(character)
    for _, setEffectInstance in ipairs(activeSetEffects) do
        local handler = self.effectHandlers[setEffectInstance.type]
        -- Set bonuses can also have conditions, processed the same way
        if handler and self:checkEffectConditions(setEffectInstance.condition, context) then
            modifiedValue = handler(modifiedValue, setEffectInstance.effect, context)
        end
    end
    
    return modifiedValue
end
```
This integrates set bonuses smoothly into the existing effect processing pipeline, assuming their `type` corresponds to a registered handler (e.g., "elemental_resistance", "damage_modifier").

**[REVISION 1.1.0 - Addressed: Point 6 - Order of Effect Application]**
### C. Order of Effect Application
The current implementation in `processEffects` applies unique item effects first (iterating through equipment slots) and then active set bonuses. Within unique items, the order depends on equipment slot iteration and the order of effects within an item's `uniqueEffects` array.

**Considerations & Actionable Items:**
1.  **Document Current Order:** Clearly document this default application order.
2.  **Review Stacking Rules:** For common effects (e.g., multiple `damage_multiplier` instances), define how they stack (additively, multiplicatively, diminishing returns). This logic will need to be built into the respective handlers or the `processEffects` function. For example, multiplicative stacking is often default for multipliers.
3.  **Priority System (Future Enhancement):** For more complex interactions, a future enhancement could involve adding an optional `priority` field to effect definitions. `processEffects` could then sort all applicable effects (from items and sets) by priority before applying them. This is not essential for the initial implementation but should be kept in mind for future complexity.

## 7. UI and Player Feedback [REVISION 1.1.0 - Addressed: Point 9]

Effective communication of unique and set item properties to the player is crucial.

**Actionable Items:**
1.  **Item Tooltips:**
    *   Clearly display that an item is "Unique" or part of a "Set."
    *   List all unique effects. For effects with simple conditions (e.g., "Applies to Fire skills"), display them. For complex conditions, a more generic description might be needed (e.g., "Activates under certain combat conditions").
    *   For set items, display the set name, pieces equipped/total (e.g., "Firewalker Set (2/3)"), and list bonuses for each tier (2-piece, 3-piece), highlighting active ones.
2.  **Character Sheet:**
    *   Potentially have a section summarizing active set bonuses and significant persistent unique effects (e.g., granted skills).
3.  **Dynamic Feedback:**
    *   Consider visual or log feedback when a significant unique effect or set bonus triggers in combat, if appropriate for game feel.

## 8. Development Aids: Error Handling and Validation [REVISION 1.1.0 - Addressed: Point 10]

To streamline development and content creation:

**Actionable Items:**
1.  **Handler Registration Check:** When `uniqueItemSystem:registerEffectHandler` is called, log a warning or error if an attempt is made to overwrite an existing handler for the same `effectType` without an explicit "override" flag.
2.  **Effect Validation:** Upon loading item definitions (`unique_items.lua`, `set_item_bonuses.lua`):
    *   Validate that each `effect.type` has a registered handler in `uniqueItemSystem.effectHandlers`. Log errors for unhandled effect types.
    *   Validate the structure of `effect.condition` and `effect.effect` payloads against expected formats for each `effectType`. This can be basic schema validation.
3.  **Runtime Checks:** In `uniqueItemSystem:processEffects`, if a handler is not found for an effect type, log a warning.
4.  **Debug Logging:** Implement verbosity levels for logging within the `uniqueItemSystem` to trace effect application and condition evaluation during testing.

## Implementation Process

The proposed implementation will follow this sequence:

1.  Define core data structures (item definitions, effect structures, condition structures). [REVISION 1.1.0 - Expanded]
2.  Create the `uniqueItemSystem.lua` module with handler registration, effect processing, and condition checking logic. [REVISION 1.1.0 - Enhanced condition logic]
3.  Implement initial effect handlers for common scenarios (e.g., damage modification, attribute boosts).
4.  Add unique item data structures to `data/items/unique_items.lua` (or chosen path). [REVISION 1.1.0 - Specified path]
5.  Integrate `uniqueItemSystem:processEffects` calls at key points in the game logic (e.g., combat calculations, character stat calculations, loot generation). [REVISION 1.1.0 - Emphasized diverse integration points]
6.  Implement the `Character:getActiveEffectsOfType` (or similar) for querying passive effects like granted skills. [REVISION 1.1.0 - Clarified]
7.  Implement UI enhancements to display unique properties and set bonuses. [REVISION 1.1.0 - Detailed]
8.  Add set item data structures and integrate set bonus acquisition into `uniqueItemSystem`. [REVISION 1.1.0 - Streamlined integration]
9.  Implement development aids (error handling, validation). [REVISION 1.1.0 - Added section]
10. Test thoroughly with debug commands and a variety of item/effect combinations.

## Conclusion

This implementation plan (Version 1.1.0) provides a flexible, modular, and more robust approach to unique and set items, building upon the initial proposal by incorporating detailed review feedback. The design emphasizes:

- Clear separation between standard item properties and unique effects.
- An extensible effect handler system for easy addition of new behaviors.
- A significantly more flexible conditional activation system for effects, supporting complex logic. [REVISION 1.1.0]
- Clearer mechanisms for handling diverse effect types, including passive and on-equip effects. [REVISION 1.1.0]
- Integrated support for set bonuses leveraging the same core system.
- Detailed considerations for UI, player feedback, and developer aids. [REVISION 1.1.0]
- Easy testing through debug console commands.

By following this enhanced plan, we can implement a rich unique and set item system that supports complex behaviors while maintaining code quality, minimizing refactoring risks, and facilitating future expansion.

## [REVISION 1.1.0] Revision History

**Version 1.1.0 (Current Version) - Comprehensive Review and Enhancements**
*   **Overall:** Incorporated feedback from a detailed review to enhance clarity, robustness, extensibility, and address potential issues.
*   **Section 1 (Data Structure):** Clarified storage and loading of unique item definitions (`data/items/unique_items.lua`). (Addresses Review Point 1)
*   **Section 2 (Unique Item Handling):**
    *   Detailed the `context` object for `processEffects`, emphasizing `eventType` and flexibility for diverse effects beyond combat. (Addresses Review Point 2)
    *   Significantly enhanced `checkEffectConditions` to support complex logical operators (AND/OR), nested conditions, and new check types like character health/status. (Addresses Review Point 5, and user request for specific checks)
    *   Added best practices for effect handlers regarding state modification. (Addresses Review Point 8)
    *   Included examples for defensive effect handlers and discussed integration points for various game systems. (Addresses Review Point 2 & 4)
*   **Section 3 (Integration Points & Character System):**
    *   Corrected signature and clarified purpose of `Character:getActiveEffectsOfType` (formerly `getUniqueItemEffects`). (Addresses Review Point 7)
    *   Provided examples of integration for outgoing and incoming damage, and how `context.skill` should be handled (mutable copy).
*   **Section 4 (Special Skills):** Clarified that `grant_skill` is a passive effect queried by other systems, not actively processed in the main combat loop. (Addresses Review Point 3)
*   **Section 6 (Set Items):**
    *   Streamlined set bonus processing to fully integrate with the `uniqueItemSystem` and its handlers. Set bonuses are now treated as effect instances. (Addresses Review Point 4)
    *   Added subsection "Order of Effect Application" to discuss current behavior and future considerations like a priority system. (Addresses Review Point 6)
*   **Section 7 (New - UI and Player Feedback):** Added a dedicated section outlining requirements for item tooltips, character sheet, and dynamic feedback. (Addresses Review Point 9)
*   **Section 8 (New - Development Aids):** Added a dedicated section for error handling, validation, and debug logging to improve development workflow. (Addresses Review Point 10)
*   **Implementation Process & Conclusion:** Updated to reflect the enhancements and new sections.

**Version 1.0.0 - Initial Document**
*   Initial draft of the implementation plan for unique and set items. 