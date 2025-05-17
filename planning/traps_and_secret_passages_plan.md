# Plan: Implementing Traps and Secret Passages

**Original Prompt:**
<user_query>
How could we implement traps and secret passages?
Those would be detactable by certain classes or by players that are paying attention to the environment. Certain classes would have a much easier time disabling those traps without taking damage.

We would need to find a way to only give a small hint about those traps and passages. Would be possible to do that with our raycaster?

I would like to have different types of traps, like gas, spikes or other things that we can think about. Trapdoor I do not think would be a good ideia, as we do no have support for holes and vertical movement.

Suggest what we could do from a creative and technical standpoint
</user_query>

## Changelog
- 2024-07-27: Initial plan creation.
- 2024-07-27: Added requirements for optional assets with fallbacks and debug mode trap visualization.
- 2024-07-27: Simplified secret passage activation; removed pressure plate puzzles; clarified rendering of wall interactables.
- 2024-07-27: Added trapped chests with player-prompted opening mechanism.

## 1. Creative Concepts

### 1.1. Secret Passages
    - **Activation Methods:**
        - Interactable Wall Elements: A slightly different colored brick, a loose stone, a specific carving on a wall that the player can "use" or click on. These are visually part of the wall surface (e.g., different texture).
        - Hidden Switches/Levers (Wall Surface Based): These are represented as distinct textures on a wall segment (e.g., a carved lever that changes texture when "pulled").
        - Item-Based: Requiring a specific key or item to be used on a particular wall section (which itself is an interactable wall element).
        - Multi-step Wall Puzzles: Sequences of interactions with different wall elements (e.g., "activating" several specific wall symbols in a certain order, or placing items into "slots" represented by distinct wall textures).
    - **Visual & Auditory Cues for Detection (Subtle Hints):**
        - Faint Outlines/Symbols: Certain classes (e.g., a "Rogue" or "Loremaster") might passively see a faint glow or symbol on a wall that hides a secret.
        - Texture Variation: A very slight difference in texture brightness, color, or a subtle crack.
        - Drafts/Sounds: Faint sound of wind or a distant echo when near a secret passage.
        - Scuff Marks/Dust: Marks on the floor near a wall suggesting it moves.
    - **Revelation Mechanics:**
        - Wall segment slides into the floor/ceiling/side.
        - Wall segment rotates.
        - Wall becomes illusory, allowing the player to walk through.

### 1.2. Traps
    - **General Mechanics:**
        - **Detection:**
            - Passive (Class-based): Rogues might get an automatic "sense danger" notification or see subtle visual cues more clearly.
            - Active (Player Skill): A "Search" or "Inspect" action to reveal traps in the vicinity.
            - Environmental Cues: Disturbed floor tiles, small holes in walls/floors, faint smells, subtle clicking sounds.
            - **Debug Mode Visibility:** If `GAME.debug` is active, all traps are clearly visible on screen (e.g., with a distinct color overlay like bright magenta) and should be marked on any existing or future mini-map system.
        - **Disarming:**
            - Class-based Advantage: Rogues higher chance/unique options; Warriors "smash" simple traps (risk involved); Mages use spells.
            - Tool-based: Requiring a "Trap Disarm Kit" item.
            - Skill Check: Dice roll against difficulty, modified by class/stats/items. Failure might trigger the trap.
    - **Trap Types (Excluding Trapdoors):**
        - **Spike Traps:**
            - Cue: Small holes in floor tiles, slightly raised/uneven tiles.
            - Trigger: Pressure plate or stepping on specific tile(s).
            - Effect: Instant damage.
            - Disarm: Jamming the mechanism.
        - **Gas Traps:**
            - Cue: Faint haze near vents, nozzles on walls; slight hissing sound.
            - Trigger: Area entry, pressure plate.
            - Effect: Damage over time, blurred vision (post-processing effect).
            - Disarm: Plugging vents, item to neutralize gas, wind spell.
        - **Arrow/Dart Traps:**
            - Cue: Tiny, dark holes in walls.
            - Trigger: Invisible tripwire, pressure plate.
            - Effect: Fast-moving projectile (sprite) deals damage.
            - Disarm: Blocking holes, cutting tripwire, disabling pressure plate.
        - **Trapped Chests:**
            - **Cue:** Initially none for basic implementation. Future: Subtle visual differences in chest texture, or a text hint for characters with high perception/trap detection skill (e.g., "This chest looks slightly off...").
            - **Trigger:** Player chooses "Yes" when prompted to open the chest.
            - **Effect:** Various effects like direct damage (poison needle, magical burst), small Area of Effect (gas cloud), or status ailments. Effects depend on `trapType`.
            - **Disarm (Future):** Could involve a skill check (e.g., Thievery) or a specific item (Trap Disarm Kit). If successful, trap is bypassed. If failed, trap triggers.

## 2. Technical Implementation

### 2.1. Map Data Modifications (`map.lua` or similar / Entity Definition)
    - **Per Tile/Cell Data (for Walls):**
        - `isSecretPassage` (boolean) (This tile IS the passage opening itself)
        - `secretPassageRevealed` (boolean, default: false)
        - `secretPassageType` (string, e.g., "slide", "rotate", "illusion")
        - `isInteractableWall` (boolean) (This wall tile IS an interactable element)
        - `interactableId` (string, unique ID if part of a multi-step puzzle or complex interaction)
        - `interactionPrompt` (string, e.g., "Inspect wall", "Pull lever")
        - `revealsPassageAt` (table {x,y}, if this interactable opens a passage elsewhere)
        - `triggersPuzzleEvent` (string, e.g., "rune_puzzle_step_1", if it's part of a larger puzzle)
        - `requiresItemId` (string, ID of item needed to interact)
        - `textureVariant` (string, texture ID for its default state, if different from standard wall)
        - `activatedTextureVariant` (string, texture ID for its activated state)
        - `isActivated` (boolean, for toggle switches or one-time interactables)
        - `hintFactor` (float, 0.0 to 1.0, for shader-based hints)
    - **Per Tile/Cell Data (for Floors - primarily for traps):**
        - `isTrap` (boolean)
        - `trapType` (string, e.g., "spike", "gas_vent")
        - `isTrapActive` (boolean, default: true)
        - `isTrapDetected` (boolean, default: false)
        - `isTrapDisarmed` (boolean, default: false)
        - `hintFactor` (float, 0.0 to 1.0, for shader-based hints)
    - **Map-Level Data (for multi-step wall puzzles):**
        - `map.puzzles = {`
            - `rune_puzzle_1 = {`
                - `requiredSteps = {"rune_slot_A_activated", "rune_slot_B_activated"},`
                - `currentSteps = {},`
                - `revealsPassageAt = {x,y},`
                - `isSolved = false`
            - `}`
        - `}`
    - **Map-Level Lists:**
        - `map.interactableWalls`: List of coordinates for walls that are interactable.
        - `map.activeTraps`: List of active traps.

    - **Entity Data (for Chests - when generated in `dungeon.lua`):**
        - `type = "chest"`
        - `x, y` (coordinates)
        - `color` (visual representation)
        - `contents` (table: result of `itemSystem:generateRandomLoot()`)
        - `isTrapped` (boolean, e.g., 25% chance when generated)
        - `trapType` (string, e.g., "poison_needle", "gas_cloud", "magic_blast", if `isTrapped` is true)
        - `texture` (string, path to texture, potentially `assetManager.images.chest_normal` or `assetManager.images.chest_trapped_subtle`)

### 2.2. Raycaster Engine Modifications (`engine/raycaster.lua`)
    - **Clarification on Rendering Wall Interactables:**
        - Wall interactables are visually represented as standard wall segments that use different textures (defined in `mapData[x][y].textureVariant` or `mapData[x][y].activatedTextureVariant`) or have shader-based visual cues (driven by `hintFactor`).
        - They do **not** require new 3D object rendering capabilities or significant changes to the raycaster's core rendering logic for walls. The existing wall rendering pipeline will correctly display these textured segments. Texture changes for state updates (e.g., a lever moving) are handled by updating the texture ID in `mapData`, which the raycaster then uses in subsequent frames.

    - **`dataBuffer` for Wall Hints (and Debug):**
        - Modify pixel format or add a component if needed to store `hintFactor`.
        - In `renderWalls`, when casting rays:
            `local hintFactor = map:getHintFactor(self.result.x, self.result.y, "wall")`
            `if GAME.debug and map:isWallTrapRelated(self.result.x, self.result.y) then hintFactor = -1.0 end -- Special value for debug`
            `self.dataBuffer:setPixel(x, 0, textureId, wallHeight, self.result.u, shade, hintFactor)`
    - **Floor/Ceiling Hinting (`prepareMapData`, `renderFloorAndCeiling`) (and Debug for floor traps):**
        - When generating `floorImageData` / `ceilingImageData`:
            `local hintFactor = 0.0`
            `if map:isTileTrap(x, y) then hintFactor = map:getHintFactor(x, y, "floor") end`
            `if GAME.debug and map:isTileTrap(x, y) then hintFactor = -1.0 end -- Special value for debug`
            `floorImageData:setPixel(x, y, floorId, hintFactor, 0, 0)`
        - `floorShader` / `ceilingShader` will need to read this and `GAME.debug` (passed as uniform).
    - **Updating Hint Factors:** Game logic updates `mapData[x][y].hintFactor` based on player detection. Raycaster reads this.

### 2.3. Shader Modifications (`engine/shaders/`)

    - **`wallShader.glsl`:**
        - Add `uniform float hintFactor;` (or read from texture as before).
        - Add `uniform bool gameDebugActive;`
        - Fragment shader: 
            `if (gameDebugActive && hintFactor == -1.0) { fragColor.rgb = vec3(1.0, 0.0, 1.0); } // Magenta for debug`
            `else if (hintFactor > 0.0) { fragColor.rgb += hintFactor * vec3(0.2, 0.2, 0.1); }`
    - **`floorShader.glsl` / `ceilingShader.glsl`:**
        - Read `hintFactor` from the appropriate channel/component.
        - Add `uniform bool gameDebugActive;`
        - Fragment shader: 
            `if (gameDebugActive && hintFactor == -1.0) { color.rgb = vec3(1.0, 0.0, 1.0); } // Magenta for debug`
            `else if (hintFactor > 0.0) { color.rgb += hintFactor * vec3(0.2, 0.05, 0.05); }`
    - **New Post-Processing Shader (`gasEffectShader.glsl`):**
        - Input: `uniform sampler2D sceneTexture;`
        - Output: Blurred and/or color-tinted version of the scene.
        - Uniforms: `uniform float gasIntensity;`

### 2.4. Game Logic (`main.lua`, new modules e.g., `systems/traps.lua`, `systems/interactables.lua`, and `screens/dungeon.lua`)

    - **Player State:**
        - Current class, perception stats, detection skills.
    - **Interaction System (`screens/dungeon.lua` - `checkEntityInteraction`):**
        - `love.keypressed` / `love.mousepressed` for interaction (though primary interaction for chests will be proximity-based dialog).
        - Raycast from camera to determine targeted wall interactable.
        - `Game:interactWith(worldX, worldY)` function (for wall interactables).
        - **Chest Interaction Logic (within `checkEntityInteraction` in `dungeon.lua`):**
            - When player is near an entity of `type == "chest"`:
                - Do **not** auto-collect loot.
                - Set `self.activeChestEntity = entity` (new variable in `dungeon.lua`).
                - Construct message for `self.elements.confirmDialog`:
                    - Basic: "Open this chest?"
                    - Future: If `chestEntity.isTrapped` and player has detection skill: "This chest seems suspicious. Open it?"
                - Define `confirmCallback` for the dialog:
                    - Check `self.activeChestEntity.isTrapped`.
                    - If `true`, call `self:triggerChestTrap(self.activeChestEntity)` (new helper function in `dungeon.lua`).
                    - If trap doesn't prevent it (e.g., player survives), or if not trapped, call `self:collectChestLoot(self.activeChestEntity)` (new helper function).
                    - Remove `self.activeChestEntity` from `self.entities`.
                    - Set `self.activeChestEntity = nil`.
                - Define `cancelCallback` for the dialog:
                    - Set `self.activeChestEntity = nil`.
                - Show `self.elements.confirmDialog`.
            - Add logic to `dungeon:update` to hide dialog and clear `self.activeChestEntity` if player moves too far from it.

    - **Chest Helper Functions (in `dungeon.lua`):**
        - `dungeon:triggerChestTrap(chestEntity)`:
            - Takes `chestEntity` as argument.
            - Plays trap sound effect.
            - Applies damage/status effects to `GAME.party[1]` (or AoE) based on `chestEntity.trapType`.
            - Uses `characterSystem:applyDamage`, `characterSystem:applyStatusEffect`.
            - Shows floating text for trap effect.
        - `dungeon:collectChestLoot(chestEntity)`:
            - Takes `chestEntity` as argument.
            - Iterates `chestEntity.contents` and adds items/gold to player's inventory/gold.
            - Plays loot collection sound.

    - **Trap Activation Logic (`screens/dungeon.lua` and `systems/trapEffects.lua` - optional module):**
        - `Interactables.activate(coords)`: (Handles direct revelation)
            - Sets `mapData[coords].secretPassageRevealed = true`.
            - Changes `map:getCell(coords)` to `0` (walkable).
            - Optionally changes texture using `map:setWallTexture(coords, newTextureId)`.
            - Plays sound.
        - `PuzzleManager.triggerEvent(eventId, player)`:
            - Called when an interactable with `triggersPuzzleEvent` is used.
            - Updates the state of the relevant puzzle in `map.puzzles`.
            - If a puzzle is solved, calls `Interactables.activate()` for its target passage.
    - **Modifications to Chest Generation (in `dungeon.lua` - `populateDungeon`, `addFillerEntities`):**
        - When creating chest entities:
            - Randomly determine `isTrapped` (e.g., 20-30% chance).
            - If trapped, assign a `trapType` from a predefined list.
            - Store generated loot in `chestEntity.contents`.
            - **Do not** add loot directly to player inventory at generation time.
            - Assign appropriate texture based on `isTrapped` if distinct trapped chest textures are available.

    - **Trap Effects Module (`systems/trapEffects.lua` - Optional but Recommended):**
        - Create a new module `trapEffects.lua`.
        - `TrapEffects.trigger(trapSource, trapType, primaryTarget, allTargets)`
            - `trapSource` could be "chest", "floor_spike", "wall_dart".
            - Handles applying damage, status effects, sounds, visual effects for various trap types.
            - This would centralize trap effect logic, callable from `dungeon:triggerChestTrap` or other trap triggers.

    - **Detection Logic:**
        - `Player:performSearchAction()`: Checks nearby tiles, updates `hintFactor` in map data based on skill.
        - Passive detection updates `hintFactor` based on class and proximity.
    - **Mini-map Display (Debug Mode):**
        - If a mini-map system exists or is implemented, when `GAME.debug` is true, all trap locations (derived from `mapData` where `isTrap` is true) should be rendered on the mini-map with a distinct icon or color (e.g., cyan).

### 2.5. Asset Management (`assets/assetManager.lua`)
    - **Asset Fallbacks Note:** All listed new assets in this section are considered **optional**. The game **must** implement fallback mechanisms:
        - For **missing textures**: Use a distinct, easily noticeable placeholder color (e.g., bright magenta for debug purposes if a trap-specific texture is missing, or a generic subtle color if a hint overlay is missing, or simply the default wall texture if an interactable's variant is missing). The rendering/asset loading logic must handle this gracefully.
        - For **missing sounds**: The game should simply skip playing the sound without causing an error or warning. Sound playing calls should be wrapped (e.g., `if assetManager.sounds.mySound then assetManager.sounds.mySound:play() end`).

    - **New Textures (Images/Sprites) - Optional:**
        - **Hint Overlays (Optional but good):**
            - `hint_wall_subtle_glow.png` (A faint, semi-transparent texture to blend over walls)
            - `hint_floor_subtle_pattern.png` (A subtle pattern for trapped floor tiles)
            - `hint_interactable_highlight.png` (e.g., a slight shimmer for interactable wall elements)
        - **Secret Passages & Wall Interactables:**
            - `wall_secret_revealed_frame.png` (Texture for the opening of a revealed passage)
            - `wall_interactable_lever_off.png`
            - `wall_interactable_lever_on.png`
            - `wall_interactable_button_up.png`
            - `wall_interactable_button_down.png`
            - `wall_interactable_rune_slot_empty.png`
            - `wall_interactable_rune_slot_filled_A.png` (and B, C etc. for different runes)
        - **Traps & Chests:**
            - `trap_spike_holes.png` (A floor tile variant with small holes, if not achieved by shader)
            - `trap_gas_vent_nozzle_wall.png` (A wall texture variant for where gas emits, if not a separate sprite)
            - `chest_normal.png` (Standard chest texture)
            - `chest_trapped_subtle.png` (Optional: A slightly different texture for trapped chests, for players with high perception or after detection)
        - **UI Elements (if needed):**
            - `icon_search_skill.png`
            - `icon_disarm_kit.png`
    - **New Sound Effects - Optional:**
        - **Secret Passages:**
            - `secret_passage_open.ogg` (Stone grinding, mechanical whirring)
            - `secret_passage_close.ogg` (Optional, if they can close)
            - `secret_passage_hint_draft.ogg` (Faint wind sound when near a hidden passage)
            - `secret_passage_switch_click.ogg` (Sound for interacting with a hidden switch)
        - **Traps - General:**
            - `trap_detected.ogg` (A chime or click when a trap is successfully detected)
            - `trap_disarm_start.ogg` (Sound of starting to disarm, e.g., lockpicking sounds)
            - `trap_disarm_success.ogg` (Positive confirmation sound)
            - `trap_disarm_fail.ogg` (Negative sound, possibly followed by trap trigger)
        - **Spike Traps:**
            - `trap_spike_trigger.ogg` (Quick, sharp sound of spikes extending)
            - `trap_spike_reset.ogg` (Optional, if they reset)
        - **Gas Traps:**
            - `trap_gas_hiss_loop.ogg` (Looping sound for active gas)
            - `trap_gas_trigger.ogg` (Initial burst of gas)
            - `player_cough.ogg` (If player is affected by gas)
        - **Chest Traps:**
            - `chest_open.ogg` (Sound for opening a safe chest)
            - `chest_trap_trigger_generic.ogg` (Generic sound for a chest trap triggering)
            - `chest_trap_poison_needle.ogg` (Specific sound for needle trap)
            - `chest_trap_gas_cloud.ogg` (Sound for gas cloud from chest)
        - **Arrow/Dart Traps:** (Consider removing or simplifying for now if focusing on wall/floor based)
            - `trap_arrow_fire.ogg`
            - `trap_arrow_hit_wall.ogg`
            - `trap_arrow_hit_player.ogg`