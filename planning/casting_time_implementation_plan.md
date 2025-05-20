# Casting Time Implementation Plan

## Original Prompt
We will now make a big change to how spells work in the game. Because of that, you should be extra careful and thoughtful when making the changes.

Today spells are instantly cast, but we will change it to make spells have a casting time, where they will "charge" a progress bar. At the end of this casting time, the spell will be cast just as it is today.

This casting time will use the following rules:
1. It will be expressed in turns, and will progress every time a player, a minion or an enemy take a turn
2. Effects will trigger at the end of that turn. For example: A player uses a spell with a cast time of 3, at the end of its turn it will progress one step, the next player takes its turn and the progress gains one more stage, then an enemy takes its turn, completing the third turn. At the end of this enemy turn the spell then activates and creates its effect
3. We will have a progress bar for each entity (players, enemies, minions) to show this progress. This will show above the combat log and will have the progress value, the name of the caster and the name of the spell.
4. This queue will reset every time a battle ends and will never carry over
5. A character casting a spell cannot take another turn until the spell is cast (may skip turns)
6. The casting time should be modifiable after the spell is queued (for party buffs that affect cast speed)

## Current System Overview

Currently, the spell casting system works as follows:
- A player selects a skill during their turn
- The skill effect is immediately applied
- The turn ends and moves to the next entity

The key files involved are:
- `gameplay/combatSystem.lua`: Main combat system state and management
- `gameplay/combat/coreFunctions.lua`: Core combat functionality
- `gameplay/combat/playerActionFunctions.lua`: Handles player action execution
- `gameplay/skill_definitions.lua`: Defines player skills
- `gameplay/monsterAbilities.lua`: Defines monster abilities
- `gameplay/combat/uiFunctions.lua`: Handles UI rendering

## Implementation Plan

### 1. Data Structure Changes

#### A. Add casting time to skill definitions in `skill_definitions.lua`
Each skill definition will need a new property:
```lua
castingTime = N, -- where N is the number of turns required to cast the spell
```

#### B. Add a spell queue to `combatSystem.lua`
```lua
spellQueue = {
    -- Example structure
    {
        caster = reference_to_entity,
        skill = reference_to_skill,
        target = reference_to_target,
        progress = 0,
        totalCastingTime = N,
        castingTimeRemaining = N,
        isCasting = true -- flag to indicate if entity is currently casting
    },
    -- More queued spells...
}
```

### 2. Logic Changes

#### A. Modify `playerActionFunctions.executeSkill` (`gameplay/combat/playerActionFunctions.lua`)
- Check if the skill has a casting time
- If it does, add it to the spell queue instead of executing immediately
- If it doesn't, execute immediately as before
- Set isCasting flag on the caster

#### B. Add spell queue processing in `coreFunctions.nextTurn` (`gameplay/combat/coreFunctions.lua`)
- At the end of each entity's turn, progress all spells in the queue
- Check if any spells are complete (progress == totalCastingTime)
- Execute completed spells
- Remove completed spells from the queue
- Clear isCasting flag when spell completes

#### C. Add spell queue reset in `coreFunctions.isOver` or related function
- When combat ends, clear the spell queue

#### D. Modify monster ability execution to use the same system
- Update `enemyFunctions.executeEnemyTurn` to handle casting time for monster abilities

#### E. Modify minion ability execution similarly
- Update `minionFunctions.executeMinionTurn` to use the casting system

#### F. Add turn skipping logic
- In the turn determination logic, check if an entity is casting
- If an entity is casting, they skip their turn (but their queued spell still progresses)

#### G. Add dynamic cast time modification
- Add function to modify cast time for spells in the queue
- Ensure this is accessible to buffs/skills that affect casting speed

### 3. UI Changes

#### A. Add a new UI element to `uiFunctions.createUI`
- Create a progress bar container in the top right corner
- Design element to show spell name, caster, and progress

#### B. Add rendering logic to `uiFunctions.draw`
- Render all spells in the queue with their progress bars
- Show the spell name, caster name, and remaining turns

#### C. Update the combat log
- Add log entries when a spell starts casting
- Add log entries when a spell finishes casting
- Add log entries when a spell is interrupted or canceled

### 4. Implementation Sequence

1. **Add the data structures**
   - Add castingTime to skill definitions
   - Add spellQueue to combatSystem

2. **Implement core casting logic**
   - Modify skill execution to use queue for skills with castingTime
   - Add progression logic in nextTurn
   - Add queue reset when combat ends
   - Implement turn skipping for casting entities
   - Add dynamic cast time modification capability

3. **Implement UI**
   - Create progress bar component in top right corner
   - Add rendering logic
   - Update combat log messages

4. **Extend to monsters and minions**
   - Apply the same logic to monster abilities
   - Apply the same logic to minion abilities

5. **Testing**
   - Test with various casting time values
   - Test with different entity types (players, monsters, minions)
   - Test queue reset when combat ends
   - Test turn skipping while casting
   - Test dynamic cast time modifications

### 5. Specific File Changes

#### `gameplay/combatSystem.lua`
- Add spellQueue table to the combat state
- Add helper functions for queue management:
  - addToSpellQueue(caster, skill, target)
  - progressSpellQueue()
  - executeCompletedSpells()
  - resetSpellQueue()
  - modifySpellCastTime(caster, skillName, modificationAmount)
  - cancelSpell(caster, skillIndex)

#### `gameplay/combat/coreFunctions.lua`
- Modify nextTurn() to call progressSpellQueue()
- Check for completed spells after progression
- Execute completed spells
- Reset queue when combat ends
- Add logic to skip turns for casting entities
- Add spell interruption handling for stunned entities

#### `gameplay/combat/playerActionFunctions.lua`
- Modify executeSkill() to check castingTime and use queue when needed
- Create a new beginCastingSpell() function
- Add logic for handling dead targets (cancel single-target spells, keep area spells)

#### `gameplay/skill_definitions.lua` and `gameplay/monsterAbilities.lua`
- Add castingTime property to all applicable skills
- Keep low-level direct damage spells instant (castingTime = 0)
- Add castingTime to all area effect spells

#### `gameplay/combat/uiFunctions.lua`
- Add new UI element for spell queue visualization in top right corner
- Add rendering code for progress bars

### 6. Resolved Challenges and Considerations

1. **Handling interrupted casting**
   - If a caster is stunned, the spell is canceled and removed from the queue
   - If a caster is defeated, the spell is canceled

2. **Targeting issues**
   - If a target dies and the spell is single-target, cancel the spell
   - If a target dies and the spell is area-effect, still cast at the position of the dead enemy

3. **UI space management**
   - Position the spell queue in the top right corner with entries flowing downward
   - No concerns about space limitations

4. **Performance considerations**
   - Not a concern for this simple game
   - Keep data structures straightforward

5. **Balancing considerations**
   - Keep low-level spells like Fire Bolt instant
   - Add casting times to all area effect spells
   - Balance casting times based on spell power

6. **Turn management**
   - Entities that are casting cannot take another turn until their spell completes
   - If casting time is long enough, entities may skip their next turn

7. **Dynamic cast time**
   - Allow modification of casting times for spells already in the queue
   - Implement functions to adjust casting time for party buffs affecting cast speed

## Changelog

### Initial Creation
- Created detailed implementation plan for casting time system
- Outlined data structures, logic changes, and UI requirements
- Identified potential challenges and considerations

### Update 1
- Added solutions for the potential challenges based on user feedback
- Added handling for caster being stunned (cancel spell)
- Added handling for target death (cancel single-target, keep area spells)
- Added UI positioning in top right corner
- Added explicit support for turn skipping while casting
- Added support for dynamic cast time modification 