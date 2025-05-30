# Turn System Rework Implementation Plan

## Original Prompt:

We will change how the turn system works
Every time I use the word entity here, I'm refering to enemies, minions and player characters (party members)
Today every entity takes its turn in sequence, independent of their speed or other stats, we will change that to a more dinamic approach, similar to games like final fantasy 7.

How the new system will work:
- Every entity will have a `actionMeter` that will tick every 500ms (half a second)
- Once this meter has ticked 20 times (ten seconds) minus the entity speed, the entity will be ready to take its turn
	- This means that entities with high speed will go first
	- speed will be able to go negative, in this case it will be summed into the ticks, delaiyng the turn
- Once the meter is full (has ticked the proper amount of times based on entity speed), the entity is added to the turn queue to take its action
- If party member (player character) is taking turn, all actionMeters stop ticking
- Minions and Enemies just execute their actions normally when their meter is full and other meters do not stop ticking in this case
- Once an entity takes its action, its meter start to tick again
- Abilities with casting time superior to 1 are exceptions, as they when the ability is on the cast queue, the actionMeter for the entity casting the skill do not tick

This new system, means that we need to change how our casting time for abilities work, as today they tick every turn, now the cast time will change to represent seconds. So our spell queue will need to change to reflect that.

Status effects will be able to interfere in the actionMeter, like stoping, reducing and speeding up its total tick time needed

We will need to add progress bars to communicate this those action meters, lets add them to the same place we have our spell queue and reutilize part of the code if we can

Now, review these instructions and create an implementation plan, so we can try to preemptly fix any concerns

## Implementation Plan:

### Phase 1: Core `actionMeter` Logic

1.  **Modify Entity Data Structures:**
    *   Add `actionMeter` (number, initialized to 0) to all entity types (player characters, enemies, minions).
    *   Add `speed` (number, can be positive or negative) to all entity types.
    *   Define a constant for `MAX_ACTION_METER_TICKS` (e.g., 20).
2.  **Implement `actionMeter` Ticking Mechanism:**
    *   Create a global timer or integrate with an existing game loop update function that fires every 500ms.
    *   In this timer/update function:
        *   Iterate through all active entities.
        *   If an entity is a player character whose turn it is, skip ticking for all entities.
        *   If an entity is casting an ability with `castingTime > 1` (seconds), skip ticking for that entity.
        *   Increment the `actionMeter` for eligible entities.
3.  **Implement Turn Readiness and Queue:**
    *   Create a `turnQueue` (list/table) to hold entities ready to take their turn.
    *   When an entity's `actionMeter` >= (`MAX_ACTION_METER_TICKS` - `entity.speed`):
        *   Add the entity to the `turnQueue`.
        *   Do not reset `actionMeter` yet (it will reset after the action).
4.  **Modify Turn Execution Logic:**
    *   The game should now pull the next entity from the `turnQueue` to take its turn.
    *   If the `turnQueue` is empty, the game waits/continues ticking `actionMeter`s.
    *   After an entity takes its action:
        *   Reset its `actionMeter` to 0.
5.  **Handle Player Character Turn:**
    *   When a player character is selected from the `turnQueue` to take their turn:
        *   Set a global flag (e.g., `isPlayerTurnActive = true`).
        *   The `actionMeter` ticking mechanism (from step 2) should check this flag and pause all ticking.
    *   After the player character confirms their action and the action is resolved:
        *   Set `isPlayerTurnActive = false`.
        *   Reset the player character's `actionMeter` to 0.

### Phase 2: Ability Casting Time Rework

1.  **Update Ability Data:**
    *   Change `castingTime` for all abilities to represent seconds instead of turns.
        *   A `castingTime` of 0 means instant.
        *   A `castingTime` of 1 means it takes 1 second to cast.
2.  **Modify Spell Queue (`castQueue`) Logic:**
    *   The `castQueue` will now track the remaining `castTimeInSeconds` for each ability.
    *   Create a new timer or integrate with the 500ms `actionMeter` tick:
        *   For each spell in the `castQueue`:
            *   If `isPlayerTurnActive` is true, pause casting time countdowns. (Or decide if enemy/minion casts should also pause).
            *   Player turn pauses enemy/minion casting
            *   Decrement `remainingCastTimeInSeconds` by 0.5 every 500ms tick.
        *   When `remainingCastTimeInSeconds` <= 0, the ability resolves.
        *   The entity that was casting becomes eligible for its `actionMeter` to start ticking again (as per Phase 1, step 2).

### Phase 3: Status Effects on `actionMeter`

1.  **Define Status Effect Properties:**
    *   Status effects with the effect stat `speed_multiplier` that affect the speed, will have an effect on the meter as it changes speed
2.  **Integrate Status Effects into `actionMeter` Ticking:**
    *   When an entity has a "stop" `actionMeter` status effect, its `actionMeter` does not tick.
    *   When calculating the target ticks needed (`MAX_ACTION_METER_TICKS` - `entity.speed`):
        *   If a "slow" effect is active, add `speed_multiplier` to this target speed.
        *   If a "haste" effect is active, subtract `speed_multiplier` from this target (ensure it doesn't go below a minimum, e.g., 1 tick).
    *   Manage the duration of these status effects, removing them when they expire.
    *   Most of those effects already exist, like the slow effect applied by `IceShard` (see skill_definitions.lua line 133-157, and specifically the `effect` section)

### Phase 4: UI - `actionMeter` Progress Bars

1.  **Design Progress Bar Element:**
    *   Determine the visual style and placement. The prompt suggests placing them near the spell queue.
    *   Each active entity (player, enemy, minion) should have a visible action meter progress bar.
2.  **Reutilize Spell Queue UI Code (if possible):**
    *   Analyze existing UI code for the spell queue to identify reusable components or patterns for progress bars.
3.  **Implement Progress Bar Updates:**
    *   The UI needs to read the current `actionMeter` value and the calculated target ticks for each entity.
    *   The progress bar should visually represent `currentActionMeter / targetTicksNeeded`.
    *   Update these progress bars in real-time as `actionMeter`s tick.
    *   Clearly indicate when an entity is in the `turnQueue` (e.g., progress bar full, different color).
    *   Visually indicate if an action meter is paused (e.g., due to player turn or status effect).

### Data Structures and Modules to Review/Create:

*   **Entity System (`gameplay/combat/*.lua` or similar):**
    *   Add `actionMeter`, `speed`.
    *   Modify functions that handle entity state and actions.
*   **Turn Manager (`gameplay/combat/turn_manager.lua` or similar if it exists, otherwise create):**
    *   Manage `turnQueue`.
    *   Centralize `actionMeter` ticking logic.
    *   Handle `isPlayerTurnActive` state.
*   **Ability System (`gameplay/skill.lua` and `gameplay/skill_definitions.lua`):**
    *   Update `castingTime` definition.
    *   Modify how abilities are added to and processed from the `castQueue`.
*   **Status Effect System (`gameplay/statusEffects.lua` or similar):**
    *   Add new properties for `actionMeter` manipulation.
    *   Update logic for applying and removing status effects.
*   **UI System (`screens/dungeon.lua`, `combatSystem.lua` or similar):**
    *   Create or update UI elements for action meter progress bars.
    *   Ensure UI updates correctly based on game state.
*   **Main Game Loop (`dungeon.lua` or game state manager):**
    *   Integrate the 500ms ticker.
    *   Ensure updates to turn manager, entity `actionMeter`s, and `castQueue` are called appropriately.

### Potential Concerns & Questions to Address:

1.  **Performance:** Ticking meters for many entities every 500ms. Ensure the update loop is efficient.
2.  **Simultaneous Turns:** If multiple entities fill their `actionMeter` in the exact same 500ms tick, the priority will be higher speed first, then player > minion > enemy, then random/ID
3.  **Clarity of UI:** How to make sure the player understands why some meters are paused and others are not, especially with multiple enemies and minions.
4.  **Negative Speed:** "speed will be able to go negative, in this case it will be summed into the ticks, delaying the turn". So `targetTicks = MAX_ACTION_METER_TICKS - entity.speed`. If `speed = -5`, then `targetTicks = 20 - (-5) = 25`. This logic is sound.
5.  **Initial `actionMeter` State:** When a battle starts, each `actionMeter` is set to `(speed + random(1,5))` ticks. So the `actionMeter` of an entity with speed 5 that selects a random number 4, will start the combat 4.5 seconds already ticked.
7.  **Interaction between player turn pause and spell casting:** If a player character starts their turn, *all* action meters stop ticking. Spells already in the `castQueue` from enemies/minions pause their countdown too.
    *   The 500ms tick that reduces `remainingCastTimeInSeconds` for abilities in the `castQueue` also pause during a player's turn
    *   *Current interpretation*: Action meters pause.
8. **Ambush:** If the player is ambushed, the `actionMeter` of party members and minions start at 0, enemies will have the normal Initial values calculated as in 7

### Changelog:

*   2025-05-29: Initial plan creation.