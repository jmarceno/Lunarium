# Status Effects Implementation Plan

## Context
This plan is based on the findings in `skill_effects_implementation_status.md`, which identified several issues with the current implementation of skill effects in the combat system. The main issues identified are:

1. Status effects with chance components (stun, burn) lack proper implementation
2. Stat modifiers are not implemented consistently as standard status effects
3. Several status effect types are missing (barrier, untargetable, etc.)
4. Multiple hit support is not implemented
5. Stat multipliers are not consistently used in calculations
6. Special effects like life drain, taunt need implementation
7. Buffs/debuffs need proper visual representation
8. Skill definitions are not standardized for new effect structure
9. No explicit migration or backward compatibility plan for effect structure changes

## Original Prompt
> Update status effects implementation based on the findings in skill_effects_implementation_status.md to ensure correct functionality of all skills and their effects.

## Changelog
| Date       | Change                                   | Reason                                            |
|------------|------------------------------------------|---------------------------------------------------|
| 2023-MM-DD | Initial plan created                     | Address issues in skill_effects_implementation_status.md |
| 2024-06-XX | Major revision: unified effect logic, clarified effect structure, added missing effects, improved AI/logic details | Addressed review feedback for clarity, completeness, and actionability |
| 2024-06-XX | Added explicit UI/visual steps, migration, documentation, edge case testing, field name standardization, and backward compatibility notes | Improved completeness, clarity, and developer guidance |

## Implementation Steps

### 1. Fix Status Effect Application with Chance Rolls

#### 1.1 Unify Status Effect Application Logic
- **Target file**: `gameplay/combat/playerActionFunctions.lua`
- **Description**: Refactor skill effect application so all status effects (including stat modifiers) use a unified structure and logic.
- **Changes needed**:
  - Standardize skill definitions to use an `effects` array (or table) for multiple effects, each with `type`, `chance`, `duration`, `value` (for flat), `multiplier` (for multiplicative), etc.
  - In `executeSkill`, iterate over all effects and apply each using `statusEffects:apply()` with chance rolls as needed.
  - Remove separate handling for `stat` and `type` fields; always use `type`.
  - Example effect structure:
    ```lua
    effects = {
      { type = "stun", chance = 0.5, duration = 2 },
      { type = "attack_multiplier", multiplier = 1.2, duration = 3 },
      { type = "damage", value = 50 },
    }
    ```
  - Update all relevant code and skill definitions to match this structure.

#### 1.1a Migrate Existing Skill Definitions
- **Target file**: `gameplay/skill_definitions.lua`
- **Description**: Migrate all existing skills to the new `effects` array structure, ensuring all fields use the new naming convention (`value`, `multiplier`, `duration`, `chance`).
- **Note**: Add a migration script or manual checklist as needed.

#### 1.2 Add Status Effect Helper Functions
- **Target file**: `gameplay/statusEffects.lua`
- **Description**: Add helper functions for status effect access and management.
- **Changes needed**:
  - Implement `statusEffects:has(entity, effectType)`, `statusEffects:getValue(entity, effectType)`, `statusEffects:getMultiplier(entity, effectType)`, `statusEffects:getDuration(entity, effectType)`.
  - Refactor all direct `entity.status[effectType]` access to use these helpers.

#### 1.3 Clarify Barrier Stacking/Removal
- **Target file**: `gameplay/statusEffects.lua`, `playerActionFunctions.lua`
- **Description**: Define and document barrier stacking/refreshing/removal logic.
- **Changes needed**:
  - Specify: When a barrier is reapplied, does it stack, refresh, or take the max value? (Recommend: refresh to new value and duration.)
  - When barrier health reaches 0, immediately remove the effect using `statusEffects:remove()`.
  - **Visual**: Barrier HP should be visually distinct from normal HP in the UI (e.g., overlay bar or icon).

#### 1.4 Clarify Multi-Hit Status Effect Application
- **Target file**: `gameplay/combat/playerActionFunctions.lua`
- **Description**: Define whether status effects are applied per hit or once per skill use.
- **Changes needed**:
  - Document and implement: By default, status effects are applied once per skill use (not per hit), unless a skill explicitly specifies otherwise.
  - For skills that should apply effects per hit, add a `perHit = true` property to the effect definition.

#### 1.5 Standardize Stat Multiplier Access
- **Target file**: `gameplay/skill.lua`, `statusEffects.lua`
- **Description**: Ensure all stat multipliers are accessed via helper functions and use consistent field names (`multiplier`).
- **Changes needed**:
  - Refactor all code to use `statusEffects:getMultiplier(entity, effectType)` for multipliers.
  - Ensure all effect applications use `multiplier` as the field for multiplicative effects.

#### 1.6 Clarify Life Drain Calculation
- **Target file**: `playerActionFunctions.lua`
- **Description**: Specify that life drain is based on actual damage dealt to HP (after mitigation, barrier, etc.).
- **Changes needed**:
  - In multi-hit skills, sum all damage dealt before applying life drain.

#### 1.7 Refine Taunt/Untargetable AI Logic
- **Target file**: `gameplay/combat/enemyFunctions.lua`
- **Description**: Update AI targeting to prioritize taunt, then untargetable, and handle multiple taunters.
- **Changes needed**:
  - If any party members have taunt, randomly select among them (excluding untargetable ones).
  - If no taunters, select randomly among non-untargetable targets.
  - If all targets are untargetable, AI should skip turn or use a non-targeted action (document this behavior).
  - Document this priority and edge cases in the plan.

### 2. Add Missing Effects and Logic

#### 2.1 Purify Skill: Custom Healing
- **Target file**: `playerActionFunctions.lua`
- **Description**: Ensure Purify uses its custom healing logic after removing negative effects.

#### 2.2 Elemental Burst: Random Element
- **Target file**: `skill_definitions.lua`, `playerActionFunctions.lua`, `skill.lua`
- **Description**: Implement logic for Elemental Burst to randomly select an element for each use.

#### 2.3 Elemental Affinity: Elemental Resist/Power
- **Target file**: `statusEffects.lua`, `skill.lua`
- **Description**: Add `elementalResist` and `elementalPower` as status effects and use them in damage calculations.

#### 2.4 Spirit Sight: Reveal Weakness
- **Target file**: `playerActionFunctions.lua`, `uiFunctions.lua`
- **Description**: Implement logic to reveal enemy weaknesses in combat and display them in the UI.

#### 2.5 Ancestral Guidance: Accuracy Multiplier
- **Target file**: `statusEffects.lua`, `skill.lua`
- **Description**: Add `accuracy_multiplier` as a status effect and use it in hit calculations.

#### 2.6 Minion Buffs: Stat Usage
- **Target file**: `statusEffects.lua`, `skill.lua`, minion logic files
- **Description**: Ensure all minion stat buffs are used in relevant calculations.

### 2.7 Visual Representation of Status Effects
- **Target file**: `uiFunctions.lua`, UI assets
- **Description**: Add or update UI elements to visually represent all status effects, including new ones (barrier, taunt, untargetable, elemental buffs, etc.).
- **Changes needed**:
  - Add icons/tooltips for each status effect.
  - Show barrier HP as a distinct overlay or bar.
  - Ensure buffs/debuffs are clearly visible and distinguishable.

### 2.8 Update Developer Documentation
- **Target file**: `README.md`, in-code comments
- **Description**: Update documentation to describe the new unified effect structure, helper functions, and migration steps.

### 2.9 Backward Compatibility
- **Target file**: Save/load logic, migration scripts
- **Description**: Ensure that changes to the effect structure do not break existing saves or add a migration step for old save data.

### 3. Update Testing Plan
- Expand unit and integration tests to cover all new and clarified effects, including Purify, Elemental Burst, Elemental Affinity, Spirit Sight, Ancestral Guidance, and minion buffs.
- **Edge Cases to Test:**
  - Barrier stacking/refreshing/removal
  - Multi-hit skills with per-hit and per-use effects
  - Taunt/untargetable AI targeting, including all targets untargetable
  - Stat multiplier stacking and expiration
  - Visual representation of all new effects
  - Migration of old skill definitions and save data

### 4. Update Implementation Schedule
- Add new steps for the missing effects above, and clarify the order for unified effect logic and helper function refactors.
- Include migration, documentation, and UI steps in the schedule.

## Testing Plan

### Unit Tests
1. Test each status effect type individually
2. Verify chance-based applications work correctly
3. Test multiple hits functionality
4. Test stat multipliers in damage calculations
5. Test barrier stacking, refreshing, and removal
6. Test taunt/untargetable AI targeting logic
7. Test migration of skill definitions and save data

### Integration Tests
1. Test complete skills in combat scenarios
2. Verify visual representation of status effects (icons, tooltips, barrier HP)
3. Test enemy AI with taunt and untargetable effects, including edge cases
4. Test UI for all new and updated status effects

## Implementation Schedule

1. **Phase 1**: Fix status effect application with chance rolls (1.1-1.3)
2. **Phase 2**: Standardize stat modifiers as status effects and migrate skill definitions (1.1a, 2.1-2.2)
3. **Phase 3**: Add missing status effect types and logic (2.3-2.6)
4. **Phase 4**: Implement multiple hit support (1.4)
5. **Phase 5**: Update damage calculations with stat multipliers (1.5)
6. **Phase 6**: Implement special effect logic (1.6-1.7)
7. **Phase 7**: Enhance visual representation (2.7)
8. **Phase 8**: Update documentation and ensure backward compatibility (2.8-2.9)
9. **Phase 9**: Expand and run tests (3)

## Metrics for Success
- All skills work as described in their definitions
- Status effects apply correctly with proper chance rolls
- Multiple hit skills deal the correct number of hits
- Stat multipliers correctly affect combat calculations
- All status effects have visual representation (icons, tooltips, barrier HP)
- Special effects like barrier, taunt, and life drain function properly
- Old skill definitions and save data are migrated or handled without errors
- Documentation is up to date and clear for future developers 