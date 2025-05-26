# LUIS UI Library Migration Plan

## Original Prompt

> We will migrate all our UI code to a new, more powerfull library and you need to elaborate a detailed plan for it.
> This plan need to be divided in small steps that an LLM enginner can them implement with low risk of breaking other parts of the code.
> Besides the visuals, the UI lib takes care of event handling, so take that into consideration, as event handling is critical.
> As a love2d project, currently the events are registered at @main.lua
> Files at @screens are heavy on UI code, so they should be very affected by this change.
> Another heavily impacted system will be @combatSystem.lua , as it handles some very complex UI logic and state during combat, so take care and look closely at everything being imported and used in this file.
> Code that become unused as result of those changes should be removed at every step.
> Ideally we should handle the shared UI componentes and them one screen at a time, but you should analyze the code cascading dependencies and choose the best order for us to do it.
>
> This new library is at @luis , the api documentation for it is at @luis-api-documentation.md and the readme that provides valuable information is at @README.md
>
> The plan should state that documentation about the new implementation should be created at the @docs folder (a single .md file for the whole UI system, but with clear divisions and sections)

## Changelog

- 2024-07-29: Initial plan creation.

## Overall Strategy

The migration will be performed incrementally, focusing on one screen or system at a time to minimize disruption and allow for easier testing and debugging. We will start by integrating LUIS core functionalities, then migrate shared UI components, followed by individual screens, and finally tackle the complex combat UI. Event handling will be transitioned from `main.lua` to LUIS's system as part of each screen's migration. Unused code will be removed at each step. Comprehensive documentation will be created in `docs/ui_system_documentation.md`.

## Phase 1: Core LUIS Integration and Setup

### Step 1.1: Initialize LUIS in `main.lua`
   - **Action:** Add the necessary `require` statement for LUIS (e.g., `local luis = require("luis.init")`) in `main.lua`. Ensure Lua's `package.path` or LÖVE's require mechanism can find the `luis` directory at the project root.
   - **Action:** Initialize LUIS. If LUIS's `init` function requires a path to its widgets directory, this path will now be relative to the `luis` root folder (e.g., `luis.init("widgets")` if the widgets are in `luis/widgets/`). Consult the LUIS documentation for the exact initialization call.
   - **Action:** Add `luis.update(dt)` to the `love.update` function.
   - **Action:** Add `luis.draw()` to the `love.draw` function.
   - **Action:** Forward LÖVE input callbacks (`love.mousepressed`, `love.mousereleased`, `love.wheelmoved`, `love.keypressed`, `love.keyreleased`, `love.textinput`) in `main.lua` to their respective LUIS counterparts (e.g., `luis.mousepressed(x, y, button, istouch, presses)`).
   - **Action:** Initialize LUIS joystick support by calling `luis.initJoysticks()` in `love.load()` and forwarding `love.joystickadded`, `love.joystickremoved`, `love.gamepadpressed`, and `love.gamepadreleased` to LUIS.
   - **Action:** Set up LUIS scaling in `love.load()` and `love.update()` by setting `luis.baseWidth`, `luis.baseHeight`, and calling `luis.updateScale()`.
   - **Action:** Set the LUIS grid size using `luis.setGridSize()`. A default like 32 can be a starting point.
   - **Cleanup:** Review `main.lua` for any input handling logic that is now duplicated by LUIS and remove it, *unless* it's for systems not being migrated yet (e.g., debug console).

### Step 1.2: Create UI Documentation File
   - **Action:** Create a new file `docs/ui_system_documentation.md`.
   - **Action:** Add a basic structure to the file:
     ```markdown
     # UI System Documentation (LUIS)

     This document outlines the UI implementation using the LUIS library.

     ## Core Concepts
     - LUIS Initialization
     - Layer Management
     - Grid System
     - Event Handling
     - Theming

     ## Screens
     (Sections for each screen will be added as they are migrated)

     ## Combat UI
     (Section for combat UI will be added)

     ## Shared Components
     (Section for shared UI components)
     ```
   - **Action:** Add initial documentation about LUIS initialization, core concepts (layers, grid, scaling) based on `luis-api-documentation.md` and the setup in `main.lua`.

## Phase 2: Migrating Shared UI Components (if any)

*Analysis Note: The project structure doesn't explicitly show a "shared UI components" directory. We will need to identify if any UI elements are reused across multiple screens. The `screens/ui_slices/partyPanel.lua` is a key shared component.*

### Step 2.1: Identify and Plan for `partyPanel.lua`
   - **Analysis:** `partyPanel.lua` (from `screens/ui_slices/`) is a crucial shared UI element. It is used not only in `combatSystem.lua` but also in `guild.lua`, `shop.lua`, `smith.lua`, `inn.lua`, `tavern.lua`, `dungeon.lua`, and `overworld.lua`.
   - **Analysis:** It functions as a bottom panel displaying party member information and must span the entire screen width. It has distinct visual representations and data for combat and non-combat contexts.
   - **Action:** The LUIS-based `partyPanel` should be refactored as a LUIS FlexContainer. This main container will occupy the full grid width at the bottom of the screen.
     - Inside, it will likely contain sub-FlexContainers, one for each party member.
     - Each party member sub-container will use:
       - `luis.newIcon` or a custom element for portraits.
       - `luis.newLabel` for name, job, level.
       - `luis.newProgressBar` for HP (Note: Barrier HP overlay might require a custom drawing solution on top of the progress bar or layering two progress bars if LUIS doesn't natively support this).
       - `luis.newProgressBar` for MP.
       - `luis.newLabel` for HP/MP text values.
       - A nested `luis.newFlexContainer` holding multiple `luis.newIcon` elements for status effects.
   - **Action:** The design must accommodate both combat (with `activeCharacterIndex` highlighting) and non-combat views. This could involve dynamically changing styles/visibility of LUIS elements within the panel.
   - **Action:** Plan for its persistent nature or how it's instantiated/managed across these various screens via `screenManager.lua` or directly within screen modules.
   - **Action:** Document the planned structure and behavior of the LUIS-based `partyPanel` in `docs/ui_system_documentation.md` under the "Shared Components" section.

### Step 2.2: Implement LUIS-based `partyPanel`
   - **Action:** Create a new Lua module (e.g., `ui_elements/partyPanelLuis.lua`) that uses LUIS to build the party panel according to the plan in Step 2.1.
     - It should provide functions to update its content based on `GAME.party` or `combat.combatParty` data.
     - It must include logic to switch between combat and non-combat displays (e.g., `partyPanelLuis:setCombatMode(isInCombat, partyData)`).
     - It must include logic for highlighting the active character in combat (e.g., `partyPanelLuis:setActiveCharacter(characterIndex)`), perhaps by applying a specific theme or decorator to the character's sub-container.
     - It should provide a function to get the main LUIS element (the root FlexContainer) to be added to a LUIS layer on relevant screens.
   - **Cleanup:** Once the new LUIS-based party panel is functional and thoroughly tested by integrating it into one or two initial screens (e.g., `overworld.lua` or `dungeon.lua` as a first test, then `combatSystem.lua`), the old `screens/ui_slices/partyPanel.lua` can be removed. Ensure all `require` statements for the old panel are updated or removed across all affected files.

## Phase 3: Migrating Screens

*Strategy: We will migrate screens one by one. The order will be chosen based on simplicity and fewer dependencies first, generally starting with menus and then moving to more complex game screens. For each screen, we'll replace existing UI code with LUIS elements and ensure event handling is managed by LUIS.*

### Step 3.1: Migrate `mainMenu.lua`
   - **Analysis:** `mainMenu.lua` likely contains buttons for "New Game", "Load Game", "Settings", "Quit". These can be LUIS Buttons.
   - **Action:** In `mainMenu.lua`:
     - Create a LUIS layer (e.g., "mainMenuLayer").
     - Replace existing button creation code with `luis.newButton` or by creating elements using `luis.createElement("mainMenuLayer", "Button", ...)`.
     - Assign callbacks defined in `mainMenu.lua` to these LUIS buttons.
     - Ensure buttons are positioned using the LUIS grid system.
     - Remove old UI drawing code.
     - Remove old input handling code (mouse clicks for buttons) as LUIS will handle it.
   - **Action:** Update `screenManager.lua` to properly enable/disable the "mainMenuLayer" when switching to/from the main menu. The `setCurrentLayer` and `popLayer` functions from LUIS might be useful here if a stack-based layer management is desired.
   - **Action:** Test main menu functionality thoroughly.
   - **Cleanup:** Remove any unused variables or functions related to the old UI from `mainMenu.lua`.
   - **Documentation:** Add a section for "Main Menu" in `docs/ui_system_documentation.md`, detailing the LUIS layer used and the elements within it.

### Step 3.2: Migrate `characterCreator.lua`
   - **Analysis:** `characterCreator.lua` likely has text inputs for character name, selectors for class/race, buttons for "Create", "Back".
   - **Action:** In `characterCreator.lua`:
     - Create a LUIS layer (e.g., "characterCreatorLayer").
     - Use `luis.newTextInput` for name input.
     - Use `luis.newDropDown` or `luis.newRadioButton` groups for class/race selection.
     - Use `luis.newButton` for "Create" and "Back" buttons.
     - Position elements using the LUIS grid.
     - Wire up LUIS element callbacks to existing logic in `characterCreator.lua`.
     - Remove old UI drawing and input handling.
   - **Action:** Update `screenManager.lua` for "characterCreatorLayer" management.
   - **Action:** Test character creation.
   - **Cleanup:** Remove unused UI code from `characterCreator.lua`.
   - **Documentation:** Add a "Character Creator" section to `docs/ui_system_documentation.md`.

### Step 3.3: Migrate `levelUpScreen.lua`
   - **Analysis:** Similar to character creator, likely involves displaying stats, available points, buttons to allocate points, and a confirmation button.
   - **Action:** In `levelUpScreen.lua`:
     - Create a LUIS layer.
     - Use `luis.newLabel` for stats and points.
     - Use `luis.newButton` for incrementing/decrementing stats and for confirmation.
     - Implement LUIS UI.
     - Update `screenManager.lua`.
   - **Action:** Test level up functionality.
   - **Cleanup:** Remove unused UI code.
   - **Documentation:** Add a "Level Up Screen" section to `docs/ui_system_documentation.md`.

### Step 3.4: Migrate `characterInfo.lua`
    - **Analysis:** Displays character stats, equipment, possibly skills. Likely read-only information with a "Back" button.
    - **Action:** In `characterInfo.lua`:
        - Create a LUIS layer.
        - Use `luis.newLabel` for displaying information.
        - Potentially use `luis.newFlexContainer` if the layout is complex or needs to be dynamic.
        - Use `luis.newButton` for "Back".
        - Implement LUIS UI.
        - Update `screenManager.lua`.
    - **Action:** Test character info display.
    - **Cleanup:** Remove unused UI code.
    - **Documentation:** Add a "Character Info Screen" section to `docs/ui_system_documentation.md`.

### Step 3.5: Migrate `inventory.lua`
   - **Analysis:** Complex screen. Displays inventory items (grid or list), item details, possibly equip/use/drop buttons. May involve drag-and-drop or item selection.
   - **Action:** In `inventory.lua`:
     - Create a LUIS layer.
     - Consider using a `luis.newFlexContainer` for the main inventory grid/list.
     - Each item could be a custom LUIS widget or a small FlexContainer with an icon and label.
     - Use `luis.newLabel` for item details.
     - Use `luis.newButton` for actions.
     - Implement LUIS UI, paying close attention to how item selection and interaction are handled. LUIS focus management might be relevant.
     - Update `screenManager.lua`.
   - **Action:** Test all inventory functionalities.
   - **Cleanup:** Remove unused UI code.
   - **Documentation:** Add an "Inventory Screen" section to `docs/ui_system_documentation.md`.

### Step 3.6: Migrate `questLog.lua`
    - **Analysis:** Displays a list of quests, details for selected quests.
    - **Action:** In `questLog.lua`:
        - Create a LUIS layer.
        - Use `luis.newFlexContainer` or a combination of `luis.newButton` (for quest list) and `luis.newLabel` / `luis.newTextInputMultiLine` (read-only) for quest details.
        - Implement LUIS UI.
        - Update `screenManager.lua`.
    - **Action:** Test quest log.
    - **Cleanup:** Remove unused UI code.
    - **Documentation:** Add a "Quest Log Screen" section to `docs/ui_system_documentation.md`.

### Step 3.7: Migrate `guild.lua`, `shop.lua`, `smith.lua`, `inn.lua`, `tavern.lua`
   - **Analysis:** These are likely menu-driven screens with lists of options/items and interaction buttons. They also display the `partyPanel`.
   - **Action:** For each screen:
     - Create a dedicated LUIS layer.
     - Integrate the LUIS-based `partyPanelLuis.lua` into this layer and ensure it's updated with current party data.
     - Use appropriate LUIS widgets (`luis.newButton`, `luis.newLabel`, `luis.newFlexContainer` for lists) for other UI elements.
     - Replicate existing functionality and connect callbacks.
     - Remove old UI code and input handlers.
     - Update `screenManager.lua` for layer management.
     - Test each screen thoroughly.
   - **Cleanup:** Remove unused UI code from each file.
   - **Documentation:** Add sections for each of these screens in `docs/ui_system_documentation.md`.

### Step 3.8: Migrate `dungeon.lua`
   - **Analysis:** `dungeon.lua` is a core gameplay screen and likely displays various UI elements including the `partyPanel`. It might also have other HUD elements like a minimap, compass, or interaction prompts.
   - **Action:** In `dungeon.lua`:
     - Create a LUIS layer (e.g., "dungeonHudLayer").
     - Integrate the LUIS-based `partyPanelLuis.lua` into this layer.
     - For other HUD elements:
       - Mini-map: Consider a `luis.custom.new` widget for complex drawing, or a `luis.FlexContainer` with `luis.Icon` elements if it's tile-based.
       - Compass: Could be a `luis.custom.new` or a series of `luis.Label` / `luis.Icon` elements.
       - Interaction prompts: `luis.newLabel` or `luis.newButton` (if interactive).
     - Position elements using the LUIS grid.
     - Wire up LUIS element callbacks to existing logic in `dungeon.lua`.
     - Remove old UI drawing and input handling specific to these elements.
   - **Action:** Update `screenManager.lua` for "dungeonHudLayer" management.
   - **Action:** Test all dungeon UI functionality, including party panel updates.
   - **Cleanup:** Remove unused UI code from `dungeon.lua`.
   - **Documentation:** Add a "Dungeon Screen" section to `docs/ui_system_documentation.md`.

### Step 3.9: Migrate `overworld.lua`
    - **Analysis:** The UI elements on the overworld screen might be minimal (e.g., a mini-map, location indicators, character status) and it displays the `partyPanel`.
    - **Action:** In `overworld.lua`:
        - Create a LUIS layer for UI elements (e.g., "overworldHudLayer").
        - Integrate the LUIS-based `partyPanelLuis.lua` into this layer.
        - Use `luis.newIcon` for indicators, `luis.newLabel` for text, or custom LUIS elements if needed for things like a mini-map (potentially a `custom.new` widget).
        - Implement LUIS UI.
        - Update `screenManager.lua`.
    - **Action:** Test overworld UI.
    - **Cleanup:** Remove unused UI code.
    - **Documentation:** Add an "Overworld Screen" section to `docs/ui_system_documentation.md`.

## Phase 4: Migrating `combatSystem.lua`

*Analysis: This is the most complex part. `combatSystem.lua` handles its own UI drawing, state management for UI elements, and interactions. The LUIS API documentation mentions various UI elements like buttons, labels, and potentially progress bars that will be useful. The existing `uiHelpers.lua`, `uiFunctions.lua` in `gameplay/combat/` will need to be heavily refactored or replaced by LUIS equivalents.*

### Step 4.1: Analyze `combatSystem.lua` UI Components and Functions
   - **Action:** Thoroughly review `combatSystem.lua` and its helper modules:
     - `gameplay/combat/uiHelpers.lua`: Functions like `showActionButtons`, `hideActionButtons`, `showConfirmBackButtons`, etc. These will be replaced by LUIS layer/element visibility or by creating/destroying LUIS elements dynamically.
     - `gameplay/combat/uiFunctions.lua`: Functions like `createUI`, `draw`, `drawEnemy`, `drawParty`, `drawCombatLog`, `showSkillList`, `showItemList`, `showPartySelectionUI`, `handleUIClick`. These will be largely replaced by LUIS.
       - `createUI`: Will now involve creating LUIS elements and adding them to a combat LUIS layer.
       - `draw*`: LUIS handles drawing. The logic within these functions that determines *what* to draw (e.g., enemy health, party status) will remain, but will update LUIS elements instead of direct drawing.
       - `show*List/UI`: Will involve creating and showing LUIS FlexContainers or lists of LUIS buttons/labels.
       - `handleUIClick`: LUIS callbacks on elements will replace this.
   - **Action:** Identify all distinct UI panels/elements in combat: action buttons, skill list, item list, target selection indicators, party status, enemy status, combat log, victory/defeat screens.
   - **Action:** Plan how each of these will be represented using LUIS widgets (Buttons, Labels, FlexContainers, ProgressBars).

### Step 4.2: Setup LUIS Layer for Combat
   - **Action:** In `combatSystem.lua`'s `combat:init()` function:
     - Create a main LUIS layer for combat (e.g., "combatLayer").
     - This layer will host all combat UI elements.
   - **Action:** Ensure `screenManager.lua` (or whatever transitions to combat) enables "combatLayer" and disables other game screen layers.

### Step 4.3: Migrate Core Combat UI - Action Buttons, Confirm/Back
   - **Action:** Refactor `uiHelpers.showActionButtons`, `uiHelpers.hideActionButtons`, etc.
     - Instead of direct drawing, these functions will now create/show or hide/remove LUIS buttons (e.g., "Attack", "Skill", "Item", "Defend") on the "combatLayer".
     - The `combat.elements` table in `combatSystem.lua` can be repurposed to store references to these LUIS elements.
     - Example: `combat.elements.attackButton = luis.newButton(...)`, then `combat.elements.attackButton:show()` or `combat.elements.attackButton:hide()`. Or, if using `luis.createElement`, manage visibility through layer or element properties.
   - **Action:** Connect the `onClick` callbacks of these LUIS buttons to the existing `combat:selectAction` or similar logic.
   - **Cleanup:** Remove the old drawing code for these buttons from `uiFunctions.lua`.

### Step 4.4: Migrate Selection Lists (Skills, Items, Targets)
   - **Action:** Refactor `combat.showSkillList` and `combat.showItemList`:
     - These functions should now create a LUIS FlexContainer (or a series of LUIS Buttons) populated with skills/items.
     - Each skill/item button in the list will have an `onClick` callback that sets `combat.selectedSkill` or `combat.selectedItem`.
     - The visibility of these lists will be managed by LUIS.
   - **Action:** Refactor `combat.showPartySelectionUI` and `combat.showEnemySelectionUI`:
     - This might involve highlighting existing LUIS elements representing party members/enemies or creating temporary LUIS selection indicators/buttons over them.
     - Clicks on these LUIS elements (or indicators) will trigger `combat.confirmPartySelection` or `combat.confirmEnemySelection`.
   - **Cleanup:** Remove old drawing code for these lists and selection UIs.

### Step 4.5: Migrate Status Displays (Party, Enemy)
   - **Action:** The LUIS-based `partyPanelLuis.lua` (migrated in Phase 2) will be used for party status. Ensure it's added to the "combatLayer", set to combat mode, and updated correctly with `combat.combatParty` and `combat.activeCharacterIndex`.
   - **Action:** For enemy status display (`uiFunctions.drawEnemy`, `drawMultipleEnemies`, `drawSingleEnemy`):
     - Create LUIS Labels, ProgressBars (for health) for each enemy. These could be grouped in a FlexContainer per enemy.
     - Update these LUIS elements when enemy data changes (e.g., health loss).
     - Remove direct drawing code for enemy status.
   - **Action:** Actor status effects (`uiFunctions.drawActorStatus`, `drawStatusEffectTooltips`):
     - Status effect icons can be LUIS `Icon` elements.
     - Tooltips can be small LUIS Labels or FlexContainers that appear on hover (LUIS doesn't have explicit hover events in the provided API doc, so this might need a custom implementation or be triggered by mouse position checks within an update loop, or a click-to-show-tooltip). Alternatively, display detailed status effect info in a dedicated panel.

### Step 4.6: Migrate Combat Log
   - **Action:** Refactor `combat.drawCombatLog`:
     - Create a LUIS `TextInputMultiLine` (read-only) or a FlexContainer with multiple LUIS Labels for the combat log.
     - The `combat:addLog` function should now append text to this LUIS element.
   - **Cleanup:** Remove old combat log drawing code.

### Step 4.7: Migrate Victory/Defeat UI
   - **Action:** Refactor `combat.drawVictoryUI` and `combat.drawDefeatUI`:
     - Create LUIS Labels and Buttons for these screens (e.g., "Continue", "Return to Main Menu").
     - These could be separate LUIS layers ("victoryLayer", "defeatLayer") or dynamically created FlexContainers on the "combatLayer".
   - **Cleanup:** Remove old drawing code for victory/defeat screens.

### Step 4.8: Refactor Input Handling in Combat
   - **Action:** Remove `combat.handleUIClick` as LUIS element callbacks will manage UI interactions.
   - **Action:** Review `combat.keypressed`, `combat.mousepressed`, `combat.wheelmoved`.
     - UI-related parts (e.g., clicking a button) will be handled by LUIS.
     - Non-UI key presses (e.g., shortcuts for actions, if any) might still need to be handled by these functions, but ensure they don't conflict with LUIS's input processing.
   - **Cleanup:** Remove redundant input handling logic.

### Step 4.9: Final Combat System Cleanup and Testing
   - **Action:** Review all files in `gameplay/combat/` (`uiHelpers.lua`, `combatFunctions.lua`, `coreFunctions.lua`, `uiFunctions.lua`, `playerActionFunctions.lua`, `enemyFunctions.lua`, `minionFunctions.lua`, `eventHandlerFunctions.lua`).
   - **Action:** Remove any functions or code that became obsolete after migrating to LUIS (especially from `uiHelpers.lua` and `uiFunctions.lua`).
   - **Action:** Test all aspects of combat: starting combat, player turns, enemy turns, minion turns, using skills, using items, targeting, status effects, victory, defeat.
   - **Documentation:** Add a detailed "Combat UI" section to `docs/ui_system_documentation.md`, explaining the LUIS layers, key elements, and how interaction flows.

## Phase 5: Final Review, Cleanup, and Documentation Polish

### Step 5.1: Codebase-wide Review for Unused Code
   - **Action:** Systematically go through all modified files and any related files to ensure all old UI code, drawing functions, and event handlers that are now managed by LUIS have been removed.
   - **Action:** Look for any helper functions or variables that are no longer needed.

### Step 5.2: Test All Game Aspects
   - **Action:** Perform a full playthrough or comprehensive test of all game features to catch any UI regressions or issues.
   - **Action:** Test on different resolutions if applicable, to ensure LUIS scaling is working as expected.

### Step 5.3: Finalize UI Documentation
   - **Action:** Review and complete `docs/ui_system_documentation.md`.
   - **Action:** Ensure all migrated screens and the combat system are well-documented.
   - **Action:** Add a section on global LUIS theming if any custom themes were applied or planned.
   - **Action:** Add notes on how to create new UI elements or screens using the established LUIS patterns.

This plan provides a structured approach to the migration. Each step should be implemented and thoroughly tested before moving to the next. Remember that removing code is as important as adding new code to keep the codebase clean. 