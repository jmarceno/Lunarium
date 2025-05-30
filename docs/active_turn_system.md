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
- For players: Speed defaults to DEX attribute (typically 10)
- For enemies: Speed is defined in monster stats (typically 10)
- For minions: Speed defaults to 8

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

- **Player Characters**: 8-15 (based on DEX)
- **Fast Enemies**: 12-18
- **Normal Enemies**: 8-12  
- **Slow Enemies**: 5-8
- **Minions**: 6-10

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