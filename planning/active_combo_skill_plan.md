# Plan for Implementing Active Combo Skills

## Original Prompt

<user_query>
We will add a new type of skill to the game. This will be a complex type and may lead to many problems if not properly done, so lets create a detailed plan of how to do it.
The plan should state that we documentation about the system should be created at the docs folder after implementation.

New type of skills - activeCombo
Those new skills will have the flag "isActiveCombo"
Those new skills will have a new property "comboEntry" - This property is a list, each entry has id, name, type, sprite
Those new skills will have a new property "comboResult" - This property is a list, each entry has the name id and name of other skills
If this flag is true, after the skill is selected a new prompt will be show to players asking to input the combo, while the combo is being input user can see the values that were inputed and can correct those values if it want to. The allowed input values will be at comboEntry and they will be mapped to Q, W, R, A, S, D if all 6 values exist, if less we just map the keys respectively, leaving the last ones unused
User can confirm the combo with Enter or Space
User can delete the last selection if backspace
After the user confirm the entries, we check comboResult property and trigger the skill there - comboResult is a list with names of existing skills, so after the combo is entered we select the skill that corresponds to the value entered and trigger it normally, as any normal skill
To determinate the result, we concatenate the comboEntry names that the user inputed, there is an example below, just validate if Lua accepts the proposed syntax, if not, make adjusments, so we can get the desired result
If we do not find a correct combination, the cast fail


At no point, the user will be presented with the values of comboResult

The UI implementation will be tricky and prony to fail, be very carefull and try to reuse function that already exist as much as possible to minimize risks.
Try to have as little as possible UI code outside of the dedicated ui modules like uiFunctions.lua and uiHelpers.lua

Example activeCombo skill:

    RunicConjuration = {
        name = "Combine the power of runes to create powerfull magical effects",
        description = "A powerfull explosion",
        type = "magical",
		isActiveCombo = true        
        mpCost = 6,       
        castingTime = 0, 
        maxLevel = 5,
		comboEntry = { "nor", "ox", "elgard"},
		comboResult = {
			nor = "Firebolt",
			ox = "IceShard",
			elgard = "Thuderbolt",			
			norox = "ManaShield",
			norelgard = "Heal"			
			oxelgard = "DivineFavor"
			oxnor = "Fireball"			
			elgardnor = "Smite",
			elgardox = "Purify"			
		},
		
        levelModifier = function(level) return 1 + (level * 0.1) end
    },
	
Now, create the datailed implementation plan
</user_query>

## Changelog

- **YYYY-MM-DD:** Initial plan creation.

## Implementation Plan

This plan outlines the steps to implement the "activeCombo" skill type in the game.

### 1. Data Structure Definition (Skill Definitions)

File: `data/skill_definitions.lua` (or relevant skill definition file)

-   **Modify Skill Structure:**
    -   Add a new boolean flag `isActiveCombo` to the skill definition.
    -   Add a new property `comboEntry` (table/list). Each element in this list will be a table with `id` (string, for internal use, e.g., "nor"), `name` (string, display name, e.g., "Nor Rune"), `type` (string, e.g., "rune_fire", for potential visual/gameplay differentiation), and `sprite` (string, path to the sprite for the combo entry).
    -   Add a new property `comboResult` (table/map).
        -   The keys of this table will be concatenated `id`s from `comboEntry` (e.g., "norox", "elgardnorox").
        -   The values will be the `id` (string) of an existing skill (e.g., "Fireball", "ManaShield").
        -   **Lua Syntax for `comboResult`:** The example provided (`nor = "Firebolt"`) is valid Lua syntax for defining table entries where the key is a string. Concatenated IDs like `norox` are also valid string keys.

-   **Example Skill:** Implement the provided `RunicConjuration` example skill in the definitions file to serve as a test case.

```lua
-- Example in skill_definitions.lua
SKILL_DEFINITIONS = {
    -- ... other skills ...
    RunicConjuration = {
        name = "Runic Conjuration", -- Changed for clarity
        description = "Combine the power of runes to create powerful magical effects.", -- Corrected typo
        type = "magical",
        isActiveCombo = true,
        mpCost = 6,        
        target = "none", -- Assuming combo skills might not always have a direct target initially, or the target is determined by the resulting skill. This needs clarification.
        maxLevel = 5,
        comboEntry = {
            { id = "nor", name = "Nor Rune", type = "fire_rune", sprite = "sprites/runes/nor.png" },
            { id = "ox", name = "Ox Rune", type = "ice_rune", sprite = "sprites/runes/ox.png" },
            { id = "elgard", name = "Elgard Rune", type = "lightning_rune", sprite = "sprites/runes/elgard.png" }
            -- Potentially more entries
        },
        comboResult = {
            nor = "Firebolt",
            ox = "IceShard",
            elgard = "Thunderbolt",
            norox = "ManaShield",
            norelgard = "Heal",
            oxelgard = "DivineFavor",
            oxnor = "Fireball", -- Note: Order matters for concatenated keys if "norox" and "oxnor" lead to different skills.
            elgardnor = "Smite",
            elgardox = "Purify"
            -- Add more combinations as needed, e.g., three-rune combos:
            -- norelgardox = "UltimateBlast" 
        },
        levelModifier = function(level) return 1 + (level * 0.1) end,
        -- Standard skill properties like effect, icon, etc. might need to be defined or inherited if the combo itself has an initial representation.
        icon = "icons/skills/runic_conjuration.png" 
    },
    Firebolt = { -- Example resulting skill
        name = "Firebolt",
        description = "A bolt of fire.",
        type = "magical",
        mpCost = 3,
        target = "single_enemy",
        -- ... other properties ...
    },
    -- ... other resulting skills like IceShard, ManaShield, etc.
}
```

### 2. Core Combat Logic (`gameplay/combat/coreFunctions.lua` or similar)

-   **Modify `selectAction` (or equivalent function where skills are chosen):**
    -   When a skill is selected, check if `skill.isActiveCombo` is `true`.
    -   If true, instead of proceeding to target selection or execution, transition to a new combat state or phase: `AWAITING_COMBO_INPUT`.
    -   Store the selected `activeCombo` skill details (e.g., `self.currentComboSkill = skill`).

-   **New State/Phase: `AWAITING_COMBO_INPUT`:**
    -   In this state, the game should wait for player input for the combo.
    -   The UI will handle displaying the combo input prompt (see Section 3).

-   **Modify `handlePlayerAction` / `executeSkill` (or equivalent):**
    -   This part will be triggered *after* the combo is successfully entered and a `comboResult` skill is identified.
    -   A new function, say `processComboInput(comboSequence)`, will be responsible for:
        1.  Taking the sequence of entered combo entry `id`s (e.g., `{"nor", "ox"}`).
        2.  Concatenating them to form a key (e.g., `"norox"`).
        3.  Looking up this key in `self.currentComboSkill.comboResult`.
        4.  If a resulting skill ID is found:
            -   Retrieve the full skill definition for this resulting skill (e.g., `skillSystem:getSkill(resultingSkillId)`).
            -   Proceed with the execution of this resulting skill as if it were selected normally (i.e., handle its targeting, MP cost deduction, casting time, effects, etc.). The MP cost of the *original* `activeCombo` skill should be the one deducted, not the resulting skill's MP cost, unless specified otherwise. This needs clarification. For now, assume the original `activeCombo` skill's MP cost is used.
            -   Add a log entry: `"[Character] performs [ActiveComboSkillName] successfully, unleashing [ResultingSkillName]!"`
        5.  If no resulting skill ID is found for the entered combo:
            -   The cast fails.
            -   Add a log entry: `"[Character]'s [ActiveComboSkillName] fizzles..."` or `"[Character] failed to form a valid rune sequence."`
            -   The player's turn might end, or they might be returned to the action selection. This needs clarification. Assume turn ends on failure for now.
    -   Ensure that when the resulting skill is triggered, it correctly identifies targets if needed (e.g., if "Fireball" (AoE) is a result, it should target all enemies, if "Heal" (single ally) is a result, it should prompt for ally target selection *after* the combo is confirmed). This implies the combo input UI might need to hide, then potentially show a target selection UI.

### 3. UI Implementation (`gameplay/combat/uiFunctions.lua` and potentially `screens/ui_slices/`)

This is the most complex part and requires careful integration.

-   **New UI Element: Combo Input Prompt/Panel:**
    -   This panel should become visible when `self.state == AWAITING_COMBO_INPUT` (or a similar flag is set after an `activeCombo` skill is chosen).
    -   It should temporarily hide or overlay parts of the standard combat UI (action buttons, skill lists, etc.).
    -   **Display:**
        -   A title like "Enter Rune Sequence for [ActiveComboSkillName]".
        -   A display area showing the currently entered combo entries (e.g., their sprites or names).
        -   Visual cues for the available `comboEntry` options and their key mappings (Q, W, E, A, S, D).
            -   Example: "Q: Nor Rune [Sprite]", "W: Ox Rune [Sprite]", etc.
            -   Only display mappings for the available `comboEntry` items.
    -   **Properties:**
        -   `visible`: boolean
        -   `x, y, width, height`: for positioning.
        -   `currentComboSequence`: a list to store the `id`s of entered combo parts.
        -   `activeComboSkill`: reference to the skill being performed.
        -   `keyMappings`: a table mapping keys ('q', 'w', etc.) to `comboEntry` items.

-   **Create `comboInputPanel` in `createUI` (inside `uiFunctions.lua`):**
    -   Define its structure, drawing logic, and input handling.
    -   `comboInputPanel.draw()`:
        -   Draws the panel background, title.
        -   Iterates through `self.activeComboSkill.comboEntry` to display available inputs and their key mappings.
        -   Iterates through `self.currentComboSequence` to display the sequence entered so far (e.g., showing sprites of selected runes in order).
    -   `comboInputPanel.keypressed(key)`:
        -   Handles Q, W, E, A, S, D inputs:
            -   If the key is mapped to a `comboEntry`, add the `comboEntry.id` to `self.currentComboSequence`.
            -   Limit the length of `currentComboSequence` (e.g., to a max of 3-5, or determined by the `comboResult` structure).
        -   Handles `Backspace`: Remove the last entry from `self.currentComboSequence`.
        -   Handles `Enter` or `Space`:
            -   Call a combat system function to process the combo (e.g., `combatSystem:confirmComboInput(self.currentComboSequence)`).
            -   Hide the `comboInputPanel`.
        -   Handles `Escape` (or a dedicated "Cancel" button on the panel):
            -   Clear `self.currentComboSequence`.
            -   Hide the `comboInputPanel`.
            -   Return the player to the skill selection or action selection phase (cancel the `activeCombo` skill attempt). `combatSystem:cancelSelection()` might be reusable here.

-   **Integration with `combatSystem.draw()` in `uiFunctions.lua`:**
    -   Add a call to `self.elements.comboInputPanel:draw()` if it's visible.

-   **Integration with `combatSystem.keypressed()` in `main.lua` (or wherever combat key input is handled):**
    -   If `comboInputPanel` is visible, pass the key press to `self.elements.comboInputPanel:keypressed(key)`. Ensure this takes precedence over other combat key presses.

-   **Helper functions in `uiFunctions.lua` (reuse/adapt if possible):**
    -   `drawListContainer`: Could be adapted for the main combo panel background/border.
    -   Consider a function to draw individual combo entries with their sprites and key hints.

-   **Key Mapping Logic:**
    -   The mapping (Q, W, E, A, S, D) should be generated dynamically based on the number of `comboEntry` items.
    -   `local keys = {"q", "w", "e", "a", "s", "d"}`
    -   Iterate `i` from 1 to `math.min(#skill.comboEntry, #keys)` and map `keys[i]` to `skill.comboEntry[i]`.

### 4. Skill System (`gameplay/skill.lua`)

-   **`getSkill(skillName)`:** Ensure this function correctly loads all new properties (`isActiveCombo`, `comboEntry`, `comboResult`) for `activeCombo` skills.
-   No major changes expected here beyond correctly parsing the new skill definition format.

### 5. Game Flow and Callbacks (`main.lua` or state manager)

-   **`love.keypressed(key)` in Combat State:**
    -   If the `comboInputPanel` is active, route input to it.
    -   If Enter/Space is pressed and the combo panel is active, trigger combo confirmation.
    -   If Backspace is pressed and the combo panel is active, trigger combo entry deletion.

-   **Callbacks from UI to Core Logic:**
    -   When the skill button for an `activeCombo` skill is clicked: `combatSystem:selectAction("skill", skillId)` which then leads to showing the combo panel.
    -   When the combo is confirmed in the UI: `combatSystem:confirmComboInput(enteredSequence)`.
    -   This will then call the `processComboInput` function mentioned in Section 2.

### 6. Targeting for Resulting Skills

This is a crucial detail.
-   **Scenario 1: Resulting skill is self-target or no target (e.g., "ManaShield" on self, an AoE buff).**
    -   After combo confirmation, the resulting skill executes immediately.
-   **Scenario 2: Resulting skill is single_enemy, all_enemies, single_ally, all_allies.**
    -   After combo confirmation and identification of the resulting skill:
        1.  The combo input panel hides.
        2.  The `combatSystem` needs to store the `pendingResultingSkill`.
        3.  The UI system then needs to show the appropriate targeting UI (enemy selection list, party selection list) based on `pendingResultingSkill.target`.
        4.  Once the target is selected (or implicitly determined for "all" types), the `pendingResultingSkill` is executed.
    -   This means `confirmAction` or a similar function needs to be aware of this intermediate state.
    -   `uiFunctions.lua` will need to be updated to show targeting UIs based on `combatSystem.pendingResultingSkill` instead of just `combatSystem.selectedSkill` if a combo is in progress.

### 7. Asset Management (`assets/assetManager.lua`)

-   Ensure sprites for `comboEntry` items (e.g., runes) can be loaded.
-   The `sprite` path in `comboEntry` should be relative to the asset manager's lookup paths.

### 8. Edge Cases & Considerations

-   **Maximum combo length:** Should there be one? Or is it determined by the longest key in `comboResult`? For simplicity, a fixed max (e.g., 3 or 4 entries) might be easier initially. The example implies up to 3.
-   **MP Cost:**
    - Deduct MP only upon successful execution of a `comboResult` skill. This avoids penalizing players for typos or cancellations. The MP cost should be that of the original `activeCombo` skill.
-   **Casting Time:**
    -   Casting time is equal to the amount of entries used in the combo. In the example above, a combo with 2 runes would have a cast time of 2.    
-   **UI Responsiveness:** Ensure the combo input UI is clear, responsive, and provides good feedback.
-   **AI Usage:** AI will not use `activeCombo` skills initially, simplifying implementation.

### 9. Testing Plan

-   Test selecting an `activeCombo` skill.
-   Test entering valid combo sequences and verify the correct `comboResult` skill is triggered.
    -   Test with resulting skills that have different targeting types (self, single enemy, all enemies, single ally, all allies).
-   Test entering invalid combo sequences and verify the cast fails gracefully.
-   Test canceling combo input (e.g., with Escape or a back button).
-   Test the Backspace functionality during combo input.
-   Test key mappings for Q, W, E, A, S, D with varying numbers of `comboEntry` items.
-   Test MP cost deduction (when and how much).
-   Test interaction with casting times, if applicable.
-   Verify combat log messages are accurate.
-   Verify UI elements (combo panel, current sequence display) work as expected.

### 10. Documentation (Post-Implementation)

-   Create a new file in the `docs/` folder (e.g., `docs/active_combo_skills.md`).
-   **Contents:**
    -   Explanation of the `activeCombo` skill type.
    -   How to define an `activeCombo` skill in `skill_definitions.lua`, detailing `isActiveCombo`, `comboEntry` (and its sub-fields `id`, `name`, `type`, `sprite`), and `comboResult`.
    -   Explanation of the combo input UI and its controls.
    -   How `comboResult` keys are formed (concatenation of `id`s).
    -   Notes on MP cost and casting time interactions.
    -   Example `activeCombo` skill definition.

This detailed plan should provide a solid foundation for implementing the `activeCombo` skill feature. 