# Active Turn System Documentation

## Overview

The Active Turn System is a dynamic, action meter-based combat system that replaces the traditional sequential turn-based approach. Instead of entities taking turns in a fixed order, the system uses action meters that tick in real-time to determine when entities are ready to act.

## Core Mechanics

### Action Meter System

Every entity (players, enemies, and minions) has an `actionMeter` that ticks every 500ms (half a second). When an entity's action meter reaches a threshold based on their speed, they become ready to take their turn.

#### Key Parameters:
- **Tick Interval**: 500ms (0.5 seconds)
- **Maximum Ticks**: 20 ticks (base requirement)
- **Target Ticks Formula**: `20 - entity.speed`
- **Minimum Ticks**: 1 (ensures no entity can act more than once per 0.5 seconds)

#### Speed System:
- Higher speed values result in fewer ticks needed to act
- Speed can be negative, which increases the ticks required (slower actions)
- **For players**: Base speed 10 + DEX bonus (see Speed Calculation section)
- **For enemies**: Speed is defined in monster stats (typically 8-12)
- **For minions**: Speed defaults to 8
- **Speed cap**: Maximum speed is 15 to prevent extreme turn frequency imbalances

### Turn Queue and Priority

When entities reach their action meter threshold, they are added to a turn queue with the following priority system:

1. **Higher speed goes first** (regardless of entity type)
2. **Same speed priority**: Player > Minion > Enemy
3. **Random tiebreaker** for identical speed and type

### Pausing System

The system has a critical pausing mechanism:
- **Player turns pause everything**: When a player character is taking their turn, all action meters stop ticking
- **Spell casting also pauses**: Entities casting spells with `castingTime > 1` second have their action meters paused
- **Status effects can pause**: Certain status effects (like STUN) prevent action meter ticking

## Speed Calculation System

### Player Character Speed Formula

Player character speed is calculated using a balanced formula to prevent certain classes from dominating combat:

```lua
baseSpeed = 10                              -- All characters start with base speed 10
dexBonus = floor(character.DEX / 30)        -- +1 speed per 30 DEX points
totalSpeed = min(15, baseSpeed + dexBonus) -- Capped at maximum 15 speed
```

### Speed Balance Fix (v1.2)

The speed system was rebalanced to fix issues where high-DEX classes (Rogues, Assassins) were taking excessive turns:

#### Before Fix (Broken):
- Characters could inherit raw DEX values as speed
- Rogues with 15+ DEX would get 15+ speed
- High-level characters could reach 20+ speed
- This created massive turn frequency imbalances

#### After Fix (Balanced):
- All characters start with base speed 10
- DEX provides minimal speed bonus (1 per 30 DEX)
- Speed is capped at 15 maximum
- Turn frequency is much more balanced across classes

### Speed Comparison Table

| Character Type | DEX | Old Speed | New Speed | Action Ticks | Turn Frequency |
|---------------|-----|-----------|-----------|--------------|----------------|
| Fighter       | 6   | 6-7       | 10        | 10 ticks     | Balanced ✅    |
| Rogue         | 8   | 8-9       | 10        | 10 ticks     | Balanced ✅    |
| Assassin      | 12  | 12-13     | 10        | 10 ticks     | Balanced ✅    |
| High-level    | 20+ | 20+       | 10-11     | 9-10 ticks   | Slightly fast  |
| Max possible  | 50  | 50+       | 11        | 9 ticks      | Fast but fair  |

*Note: Lower tick counts = faster turn frequency*

### Class-Based Speed Examples

| Class      | Starting DEX | Level 1 Speed | Level 20 DEX | Level 20 Speed |
|------------|-------------|---------------|--------------|----------------|
| Fighter    | 6           | 10            | ~12          | 10             |
| Mage       | 6           | 10            | ~8           | 10             |
| Rogue      | 8           | 10            | ~18          | 10             |
| Assassin   | 12          | 10            | ~25          | 10             |
| Monk       | 7           | 10            | ~15          | 10             |

*All classes now have equal turn frequency until very high DEX values (30+)*

### Balance Design Rationale

The speed calculation rebalance addresses several critical issues:

1. **Early Game Balance**: All classes now have equal turn frequency at level 1-10, preventing any single class from dominating
2. **Meaningful DEX Investment**: Very high DEX (30+) provides a small speed advantage, making DEX investment worthwhile without being overpowered
3. **Class Identity**: High-DEX classes (Rogues, Assassins) still benefit from DEX through dodge chance, critical hit bonus, and other mechanics
4. **Scaling Prevention**: The 30-point requirement for speed bonus prevents exponential scaling issues
5. **Combat Pacing**: Capped speed ensures combat remains tactical rather than being dominated by speed-stacking

### DEX Benefits Beyond Speed

While speed bonus from DEX is now minimal, DEX still provides significant benefits:
- **Dodge Chance**: +0.3% per DEX point (up to 50% cap)
- **Critical Hit Bonus**: +0.5% per DEX point for precision skills
- **Ranged Hit Chance**: +0.5% per DEX point for bow/crossbow attacks
- **Steal Success**: +1% per DEX point for stealing attempts

This ensures DEX remains valuable for DEX-focused builds while preventing speed dominance.

## Spell Casting Integration

### Time-Based Casting

Spell casting now uses real-time seconds instead of turn-based progression:
- `castingTime` values in skill definitions represent seconds
- Casting time counts down in real-time (decremented by delta time)
- Casting pauses during player turns (along with action meters)

### Casting and Action Meters

- Entities casting spells with `castingTime > 1` have their action meters paused
- Once a spell completes, the entity's action meter resumes ticking
- Failed casts (due to interrupted casting or invalid targets) resume action meter ticking immediately

## Combat Flow

### Initialization (Combat Start)

1. **Action Meter Setup**:
   - All entities get initial action meter values
   - Normal combat: `entity.speed + random(1,5)` ticks
   - Ambush combat: Party members start at 0, enemies get normal values

2. **Turn Manager Activation**:
   - Turn manager begins ticking action meters every 500ms
   - Turn queue starts empty
   - No entity is initially paused

### Active Combat Loop

1. **Action Meter Ticking** (every 500ms):
   - Skip if player turn is active
   - Skip individual entities if they're casting or affected by pause effects
   - Increment action meters for eligible entities
   - Check if any entities reach their threshold

2. **Turn Queue Processing**:
   - When entities reach threshold, add to turn queue with proper priority
   - Process highest priority entity from queue
   - Reset that entity's action meter to 0 after their action

3. **Player Turn Handling**:
   - Set global pause flag when player turn starts
   - Show UI and wait for player input
   - Resume action meter ticking when player turn completes

### Combat End

- Turn manager stops when combat ends (victory or defeat)
- All casting queues are cleared
- Action meters are reset for next combat

## Status Effects Integration

### Speed Modifiers

Status effects can modify entity speed through the `speed_multiplier` effect:
- Applied to the entity's base speed before calculating target ticks
- Example: 0.7 multiplier makes entity slower (more ticks needed)
- Example: 1.5 multiplier makes entity faster (fewer ticks needed)

### Action Meter Control

Status effects can directly control action meter behavior:
- **STUN**: Prevents action meter from ticking entirely
- **Future effects**: Can add additional pause conditions

## UI System

### Action Meter Display

Located in the top-right corner of the combat screen, above the spell queue:

- **Progress bars** for each active entity
- **Color coding**:
  - Blue (players)
  - Red (enemies) 
  - Green (minions)
- **Status indicators**:
  - "READY" (green) when entity can act
  - "PAUSED" (yellow) when action meter is paused
  - Percentage complete otherwise

### Visual Feedback

- Progress bars fill from left to right as action meters tick
- Ready entities have full green bars
- Paused entities have yellow bars with "PAUSED" text
- Smooth visual updates every frame

## Technical Implementation

### Core Files

- **`gameplay/combat/turnManager.lua`**: Main turn management logic
- **`gameplay/combat/coreFunctions.lua`**: Integration with existing combat system
- **`gameplay/combat/uiFunctions.lua`**: Action meter UI rendering
- **`gameplay/combatSystem.lua`**: System coordination

### Key Functions

- `turnManager:update(dt)`: Main update loop for action meter system
- `turnManager:processActionMeterTick()`: Handles 500ms tick processing
- `turnManager:playerTurnCompleted()`: Called when player action finishes
- `drawActionMeterBars()`: Renders action meter UI

## Configuration and Balancing

### Constants (modifiable in `turnManager.lua`):

```lua
turnManager.MAX_ACTION_METER_TICKS = 20
turnManager.TICK_INTERVAL = 0.5 -- 500ms
turnManager.INITIAL_RANDOM_RANGE = {1, 5}
```

### Speed Balancing Guidelines:

#### Player Characters:
- **Base Speed**: 10 (all classes start equal)
- **DEX Bonus**: +1 speed per 30 DEX points
- **Realistic Range**: 10-11 (most characters)
- **Maximum Possible**: 11 (DEX 30+, capped at 15)

#### Enemies:
- **Fast Enemies**: 12-15 (noticeably faster than players)
- **Normal Enemies**: 8-12 (comparable to players)
- **Slow Enemies**: 5-8 (noticeably slower)
- **Boss Enemies**: 10-15 (varies by encounter design)

#### Minions:
- **Standard Minions**: 6-10 (slightly slower than players)
- **Fast Minions**: 10-12 (equal to players)
- **Slow Minions**: 4-8 (support/tank roles)

#### Action Meter Calculation:
```
requiredTicks = max(1, 20 - speed)
timeToAct = requiredTicks * 0.5 seconds
```

**Examples:**
- Speed 10: 10 ticks = 5.0 seconds
- Speed 12: 8 ticks = 4.0 seconds  
- Speed 15: 5 ticks = 2.5 seconds
- Speed 5: 15 ticks = 7.5 seconds

### Casting Time Guidelines:

- **Instant abilities**: 0 seconds
- **Quick spells**: 1-2 seconds
- **Standard spells**: 2-4 seconds
- **Powerful spells**: 4-8 seconds

## Debugging and Monitoring

### Debug Information

When `GAME.debug` is enabled:
- Action meter values are logged
- Turn queue processing is traced
- Entity state changes are reported

### Performance Considerations

- Action meter ticking is lightweight (simple arithmetic)
- UI updates occur every frame but only recalculate when needed
- Turn queue operations are minimal (typically 1-10 entities)

## Migration Notes

### From Old System

The new system maintains compatibility with existing:
- Skill definitions (casting times now in seconds)
- Status effects (speed modifiers work as before)
- Combat flow (victory/defeat conditions unchanged)

### Breaking Changes

- Turn order is no longer deterministic at combat start
- Casting times changed from turns to seconds
- Some timing-dependent mechanics may need adjustment
- **Speed calculation rebalanced** (v1.2): High-DEX classes no longer dominate turn frequency

### Speed System Migration (v1.2)

Existing characters will have their speed recalculated using the new formula:
- Characters with `speed > 15` will be capped at 15
- Characters without explicit speed values will get proper calculation based on DEX
- Save file compatibility is maintained (speed is recalculated on load)

## Future Enhancements

### Potential Additions

1. **Action Point System**: Multiple actions per turn based on speed
2. **Interrupt Actions**: Fast reactions that don't require full action meter
3. **Speed Boosts**: Temporary action meter acceleration
4. **Formation Effects**: Position-based speed modifiers

### Performance Optimizations

1. **Dirty Flag System**: Only update UI when action meters change
2. **Entity Culling**: Skip inactive entities earlier in processing
3. **Batch Updates**: Group multiple action meter updates 