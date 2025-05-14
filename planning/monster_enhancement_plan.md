# Monster Enhancement Plan

## Original Prompt:
Let's create a plan to enhance monsters

Currently the monsters only have base stats as can be seen at @monster_definitions.lua, this makes them all the same and not interesting
To change that we will make some additions to them

1. Monster Abilities: Monsters will have specific abilities just as character jobs have. Low level monsters will only have a basic attack, and higher the level of the monster, more varied those abilities will be, causing status effects or hitting more than one enemy. A small number of low level enemies could have abilities that cause status effects too.

2. Damage Type: Each monster will cause a damage of a different type, and be vulnerable to a different damage type. Some enemies could continue to have no vulnerabilities or cause no different damage types to add variety. Some attacks/skills could cause more than one damage type

3. Status Effects: Right now monsters and minions do not suffer from status effects, we will do that in a future change, so plan accordainly to minize the work in the future

We need to change the UI to proper communicate those changes, like showing above or below the enemy/character the effect that is being applied and show on the combat log the skill name, effect and damage types it caused

This is big change that will require to be wired on all combat system and proper damage calculations, so analyze very carefully before suggesting these changes

## Changelog

-   **2024-07-27 (User Feedback Incorporation):**
    -   Added analysis of `skill_definitions.lua` impact: player skills need `damageType` and updated calculation logic.
    -   Specified initial 0 resistances and no immunities for characters and minions.
    -   Revised equipment impact: items get a `resistances` table for specific damage type mods; character `defense` primarily for physical.
    -   Elevated `gameplay/monsterAbilities.lua` to be the central definition point for monster abilities; `monster_definitions.lua` will use ability IDs.
    -   Added requirement to define minion abilities in a new `gameplay/minionAbilities.lua` with full structure, and update summon skills to reference these.
    -   Integrated actionable tasks for all new considerations.
-   **2024-07-26:**
    -   Clarified that monster abilities are pre-defined. `monsterAbilities.lua` serves as a library of ability definitions.
    -   Added `stats.magicAttack` to monster definitions.
    -   Removed redundant root `damageType` from monster definitions.
    -   Proposed new module `gameplay/monsterAttackSystem.lua`.
    -   Standardized `onTurnStart` return value in `statusEffects.lua`.
    -   Added note on `require` statement placement.
    -   Added actionable task for asset manager and icon loading.
-   **Initial version:** Created plan based on requirements.

## Analysis of Current State

Currently, monster definitions include:
- Basic stats (level, hp, attack, defense, speed)
- Visual attributes (color, sprite)
- Category/type information

The combat system calculates damage based on simple formulas:
- Enemy attacking player: `attackPower - (defense / 2)`
- Player skills (from `skill_definitions.lua`) have damage formulas like "physical" or "magical" but lack explicit `damageType` for resistance calculations.
- Status effects can be applied to players but not yet fully to monsters/minions. Monsters and minions will have a `status` table prepared.

## Planned Changes

### 1. Monster Abilities

#### Data Structure Changes
**Actionable Task:** Update structure in `monster_definitions.lua` and define abilities in `gameplay/monsterAbilities.lua`.
```lua
-- In monster_definitions.lua
["monster_id"] = {
    -- existing fields...
    stats = { 
        level = 1, hp = 15, attack = 4, defense = 2, speed = 7, 
        magicAttack = 5 -- New: Stat for magical abilities
    },
    abilities = { -- List of ability IDs and specific configurations for this monster
        { id = "basic_physical_attack", chanceToUse = 0.7 },
        { id = "toxic_spores_v1", chanceToUse = 0.3, unlockLevel = 3 }
        -- More ability IDs referencing gameplay/monsterAbilities.lua
    }
}

-- In gameplay/monsterAbilities.lua (Central Ability Definitions)
local monsterAbilities = {}
monsterAbilities.definitions = {
    basic_physical_attack = {
        name = "Claw",
        type = "physical",
        basePower = 100,
        target = "single_enemy",
        damageType = "slashing",
        description = "A swift claw attack."
    },
    toxic_spores_v1 = {
        name = "Toxic Spores",
        type = "magical",
        basePower = 80,
        target = "all_enemies",
        damageType = "poison",
        effect = {
            type = "poison", -- from statusEffects.lua
            chance = 0.5,    -- 50% chance to apply
            duration = 3,    -- turns
            strength = 1     -- Potency of the status effect
        },
        description = "Releases a cloud of toxic spores."
    }
    -- All other monster abilities defined here
}
return monsterAbilities
```

#### Monster Ability Distribution Pattern
- Level 1-2 monsters: 1-2 abilities.
- Level 3-5 monsters: 2-3 abilities.
- Level 6+ monsters: 3-4 abilities.
- Bosses: 4-6 abilities.
- Abilities are centrally defined in `gameplay/monsterAbilities.lua` and referenced by ID in `monster_definitions.lua`.

### 2. Damage Types

#### Damage Type Definition
**Actionable Task:** Create/Update `gameplay/damageTypes.lua`.
(Content as previously defined: `damageTypes.types` table with name, color for UI; `calculateModifier` and `getDisplayText` functions).

#### Vulnerability & Resistance System
**Actionable Task:** Update `monster_definitions.lua` for each monster with `resistances` and `immunities`.
```lua
-- Add to monster definition structure in monster_definitions.lua
["monster_id"] = {
    -- existing fields...
    resistances = { -- Values are percentages. Positive = vulnerable, Negative = resistant.
        ["ice"] = -50, -- takes 50% less damage from ice
        ["fire"] = 50,  -- takes 50% more damage from fire
    },
    immunities = { -- List of damage types the monster is immune to (e.g., takes 0 damage)
        "necrotic"
    }
}
```

### 3. Status Effects System
**Actionable Task:** Create/Update `gameplay/statusEffects.lua`.
(Content for `statusEffects.effects` with `onTurnStart` returning `{ message, value, color }`, `icon`, `apply`, `processTurnStart`, `processTurnEnd` functions as previously detailed).

## Implementation Plan

### Phase 1: Data Structure Updates & Core Systems

1.  **Update `monster_definitions.lua`:**
    *   **Actionable Task:** Add `stats.magicAttack` to all monsters.
    *   **Actionable Task:** Change `abilities` to be a list of `{id = "ability_id", chanceToUse = X, unlockLevel = Y}`.
    *   **Actionable Task:** Add `resistances` and `immunities` tables to each monster.
2.  **Create `gameplay/monsterAbilities.lua`:**
    *   **Actionable Task:** Define all monster abilities centrally with full structure (name, type, basePower, damageType, effect, description etc.).
3.  **Create `gameplay/damageTypes.lua`:** (Implement as planned).
4.  **Create `gameplay/statusEffects.lua`:** (Implement as planned).
5.  **Create `gameplay/monsterAttackSystem.lua`:** (Implement as planned, ensuring it fetches ability details from `gameplay/monsterAbilities.lua` using the ID).
6.  **Character & Minion Initial Resistances:**
    *   **Actionable Task:** Initialize player character data structures (e.g., in `gameplay/character.lua` or save files) to include `resistances = {}` (all types defaulting to 0) and `immunities = {}`.
    *   **Actionable Task:** Ensure minion data structures (upon creation/definition, likely in files like `gameplay/minionManager.lua` or player summon skill definitions in `skill_definitions.lua`) are initialized with `resistances = {}` and `immunities = {}`.
7.  **Equipment-Based Resistances:**
    *   **Actionable Task:** Update `item_definitions.lua`: Add a `resistances = { fire = 10, ice = -5 }` table field to relevant armor, shields, and accessories. (Character `defense` stat will primarily mitigate direct physical damage).
    *   **Actionable Task:** Modify character stat calculation functions (e.g., in `gameplay/character.lua`) to aggregate these `resistances` from all equipped items. This aggregated value is what `damageTypes:calculateModifier` will use for the player character.
8.  **Defining Minion Abilities:**
    *   **Actionable Task:** Create `gameplay/minionAbilities.lua`. Define minion-specific abilities here with the same full structure as monster abilities (name, type, basePower, target, damageType, effect, etc.).
    *   **Actionable Task:** Update player summon skills in `skill_definitions.lua`: The `summonStats.abilities` array should now list ability IDs that reference definitions in `gameplay/minionAbilities.lua` (e.g., `abilities = { {id = "minion_claw_v1"}, ...}`).

### Phase 2: Combat Logic Updates

1.  **Update `combat/enemyFunctions.lua` (e.g., `executeEnemyTurn`):**
    *   **Actionable Task:** Modify enemy AI to select an ability ID from its `abilities` list.
    *   **Actionable Task:** Fetch the full ability definition from `gameplay/monsterAbilities.lua` using the ID.
    *   **Actionable Task:** Call `monsterAttackSystem:resolveAbility(fullAbilityDef, currentEnemy, selectedTarget, self)`.
2.  **Update `combat/coreFunctions.lua`:** (Integrate status effect processing as planned, ensuring `setupCombatants` initializes `status` tables for all combatant types).
3.  **Impact on Player Skills (`skill_definitions.lua`):**
    *   **Actionable Task:** Add a `damageType` field to all damaging skills in `skill_definitions.lua` (e.g., `FireBolt` gets `damageType = "fire"`).
    *   **Actionable Task:** Update player skill damage calculation logic (e.g., `skillSystem:calculateDamage` or equivalent in `gameplay/skill.lua` or `combat/playerActionFunctions.lua`) to:
        *   Fetch the skill's `damageType`.
        *   Call `damageTypes:calculateModifier(skillDamageType, targetMonster)`.
        *   Apply the resulting multiplier to the calculated damage.
4.  **Update `combat/playerActionFunctions.lua` & `combat/minionFunctions.lua`:**
    *   (Player skill updates covered by point 3).
    *   **Actionable Task:** For minion attacks: Modify minion action logic (likely in `combat/minionFunctions.lua`) to:
        *   Fetch the full minion ability definition from `gameplay/minionAbilities.lua` using the ID from the minion's `abilities` list (which itself comes from the player's summon skill definition in `skill_definitions.lua`).
        *   Utilize `monsterAttackSystem:resolveAbility` (or a similar/adapted function if minion abilities need distinct handling) for executing the minion's ability. This ensures minion attacks respect target resistances and apply effects correctly using the new systems.

### Phase 3: UI Updates

1.  **Update `combat/uiFunctions.lua`:**
    *   **Actionable Task:** Display active status effects (icons + duration) for all combatants. Use the `drawStatusEffects` helper. **Note:** Integrate these icons into the existing enemy and party member display areas, preserving the current layout as much as possible (e.g., above/below health bars or alongside names, without shifting core elements like sprites or health bars themselves).
    *   **Actionable Task:** When an attack occurs, display the damage type icon and effectiveness text. Use `drawDamageTypeIcon` helper. **Note:** This information should ideally appear momentarily near the damage numbers or target, without permanently altering the static UI layout.
    *   **Actionable Task (Optional):** During target selection, potentially show monster vulnerabilities/resistances.
2.  **Update `combat/uiHelpers.lua`:**
    *   **Actionable Task:** Implement `drawStatusEffects` and `drawDamageTypeIcon` helpers.
3.  **Update Combat Log:**
    *   **Actionable Task:** Enhance log messages to include ability names, damage types, resistance info, status effects applied/triggered.
4.  **Asset Management:**
    *   **Actionable Task:** Ensure `assetManager` can load icons and verify icon paths.

## Detailed Implementation Tasks

### 1. Coding Standards and Best Practices
*   **Guideline:** All `require()` statements for Lua modules should be at the top of the file.

### 2. `gameplay/monsterAbilities.lua` (Central Monster Ability Definitions)
(Content structure as shown in "Planned Changes -> 1. Monster Abilities" - this file will contain a table, e.g., `monsterAbilities.definitions`, mapping ability IDs to full ability objects).

### 3. `gameplay/minionAbilities.lua` (Central Minion Ability Definitions)
**Actionable Task:** Create this file and populate it with definitions for all abilities minions can use.
```lua
-- In gameplay/minionAbilities.lua
local minionAbilities = {}
minionAbilities.definitions = {
    minion_basic_strike = {
        name = "Minion Strike",
        type = "physical",
        basePower = 70,
        target = "single_enemy",
        damageType = "bludgeoning",
        description = "A basic attack by the minion."
    },
    bone_strike = { // Example for a Skeleton Warrior's ability
        name = "Bone Strike",
        type = "physical",
        basePower = 90,
        target = "single_enemy",
        damageType = "piercing",
        description = "A sharp strike with a bone."
    },
    infected_bite = { // Example for a Zombie's ability
        name = "Infected Bite",
        type = "physical",
        basePower = 80,
        target = "single_enemy",
        damageType = "piercing",
        effect = { type = "poison", chance = 0.3, duration = 2, strength = 1},
        description = "A bite that may cause infection."
    }
    -- Define all other minion-specific abilities here
}
return minionAbilities
```

### 4. `gameplay/damageTypes.lua`
(Implementation as previously outlined: `damageTypes.types` table, `calculateModifier` function, `getDisplayText` function).

### 5. `gameplay/statusEffects.lua`
(Implementation as previously outlined: `statusEffects.effects` table, `apply`, `processTurnStart`, `processTurnEnd` functions. `onTurnStart` returns `{ message, value, color }`).

### 6. `gameplay/monsterAttackSystem.lua` (New Module)
(Implementation as previously outlined. Key aspects:
    - Fetches monster ability details from `gameplay/monsterAbilities.lua` using an ID.
    - Can be adapted/called for minion abilities, fetching from `gameplay/minionAbilities.lua`.
    - Calculates damage considering attacker stats (including `magicAttack`), ability `basePower`, `damageType`, target `resistances`/`immunities` via `damageTypes:calculateModifier`.
    - Applies status effects via `statusEffects:apply`.
    - Returns structured log data.)

### 7. UI Updates (`combat/uiHelpers.lua`)
(Implementation of `drawStatusEffects` and `drawDamageTypeIcon` as previously outlined. Ensure `assetManager` is correctly referenced for icons, and `require` statements for `damageTypes` and `statusEffects` modules are at the top of `uiHelpers.lua`).

## Migration Strategy

1.  **Backup Project:** Before starting, backup the entire project.
2.  **Phase 1 Implementation (Iterative):**
    *   Create the new Lua files (`damageTypes.lua`, `statusEffects.lua`, `monsterAbilities.lua`, `minionAbilities.lua`, `monsterAttackSystem.lua`).
    *   Modify `monster_definitions.lua` structure for a few representative monsters first.
    *   Add `resistances` to a few sample items in `item_definitions.lua`.
    *   Implement initial character/minion resistance setup.
    *   Define a few monster and minion abilities in their respective new files.
3.  **Phase 2 Integration (Iterative & Focused):**
    *   Focus on one system at a time: e.g., get monster abilities working first, then player skill damage types, then minion abilities.
    *   Update `combat/coreFunctions.lua` for status effect processing and `setupCombatants`.
    *   Modify `combat/enemyFunctions.lua` for one monster type to use the new ability system and `monsterAttackSystem.lua`.
    *   Update a few player skills in `skill_definitions.lua` with `damageType` and test the updated calculation in `playerActionFunctions.lua`.
    *   Update one summon skill and its minion's abilities/attack logic in `minionFunctions.lua`.
4.  **Phase 3 UI Integration:** Implement UI changes incrementally alongside backend logic where possible.
5.  **Content Population & Balancing (Ongoing):**
    *   Gradually define all monster and minion abilities.
    *   Populate `resistances` for all relevant items and all monsters.
    *   Add `damageType` to all relevant player skills.
    *   Extensive playtesting for balance after each major component is integrated.

## Future Considerations for Status Effects on Monsters

(Remains the same as previous version: Groundwork laid. Future AI updates in `enemyFunctions.lua` might be needed for monsters to react intelligently to status effects they suffer from, e.g., a silenced monster not attempting to use a magical ability.)

## Next Steps

1.  Implement Phase 1: Data structure changes and new core system modules.
2.  Implement Phase 2: Integrate new systems into combat logic, focusing on one combatant type (monster, then player, then minion) at a time for applying new mechanics.
3.  Implement Phase 3: Update UI to reflect all new mechanics.
4.  Systematically populate all remaining content (monster/minion abilities, item/monster/character resistances, player skill damage types).
5.  Thoroughly test and balance the game iteratively throughout the process. 