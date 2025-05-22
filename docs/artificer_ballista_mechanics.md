# Artificer and Ballista Master Mechanics

This document explains the unique mechanics for the Artificer and Ballista Master jobs.

## Artificer (Dungeon Trap-Throwing)

The Artificer is a Tier 2 job that specializes in throwing traps at enemies while exploring the dungeon. Unlike most jobs, Artificer has no direct combat skills. Instead, their abilities affect enemies before combat even begins.

### Activating Trap-Throwing Mode

- Press 'T' key while exploring the dungeon to enter trap-throwing mode
- A trap selector UI will appear at the bottom of the screen showing available trap types
- Select a trap using the mouse, then click on a visible enemy in the 3D view to throw the trap

### Trap Success Calculation

Trap success is determined by `trapSystem:checkThrownTrapSuccess()` which considers:
- Artificer's job level
- Enemy's level
- Trap type (different traps have different base success rates)

The formula generally follows:
```
baseChance + (artificerLevel - enemyLevel) * modifier
```

Where:
- `baseChance` varies by trap type (0.5 to 0.7)
- `modifier` is typically 0.05 per level difference

### Trap Types

1. **Net Trap** (`DungeonTrapper:Net`)
   - Effect: Applies SLOW status in combat
   - Duration: 2 turns
   - Base Success: 70%

2. **Poison Trap** (`DungeonTrapper:Poison`)
   - Effect: Applies POISON status in combat
   - Duration: 3 turns
   - Base Damage: 5 per turn
   - Base Success: 60%

3. **Stun Trap** (`DungeonTrapper:Stun`)
   - Effect: Applies STUN status in combat 
   - Duration: 1 turn
   - Special: Enemy loses its first turn in combat
   - Base Success: 50%

### Key Files

- `dungeon.lua`: Core trap-throwing UI, targeting and mechanics
- `trapSystem.lua`: Trap success calculation, trap type definitions
- `skill_definitions.lua`: Pre-combat trap effect definitions using `DUNGEON_*_TRAP_EFFECT` skills
- `combatSystem.lua`: Applies trap effects at combat start

## Ballista Master (Ballista Minion)

The Ballista Master is a Tier 3 job (advanced from Artificer) that focuses on deploying and managing ballista contraptions in combat.

### Summoning a Ballista

- Use the "Summon Ballista" skill in combat
- Ballista is created as a special type of minion with 3 ammo
- Ballista acts on its own turn in the combat order
- Ballista persists until destroyed or the dungeon is exited

### Ballista Properties

- **Type**: `minion.TYPES.BALLISTA`
- **HP**: 80 (base) + scaling with level and owner stats
- **Ammo System**: 
  - Starts with 3 ammo (`maxAmmo = 3`)
  - Consumes 1 ammo per attack
  - Once out of ammo (`ammo = 0`), the `needsReload` flag is set
  - Cannot attack when `needsReload` is true

### Reloading the Ballista

- Use the "Reload Ballista" skill to restore ammo
- This is a targeted skill that only works on ballista-type minions
- Resets `ammo` to `maxAmmo` and clears the `needsReload` flag
- Consumes the Ballista Master's turn

### Modifying Ballista Attacks

Several skills change the Ballista's attack properties:

1. **Ballista Overcharge**
   - Greatly increases damage for next shot
   - Temporarily replaces ability with `ballista_overcharge_shot`
   
2. **Ballista Elemental Mods**
   - Fire Mod: Adds burn effect to shots
   - Ice Mod: Adds slow effect to shots
   
3. **Ballista Poison Mod**
   - Adds poison DoT effect to shots
   
4. **Ballista Net Shot**
   - Adds immobilize effect to shots

### Key Files

- `minion.lua`: Defines the BALLISTA minion type and ammo properties
- `minionManager.lua`: Contains reload and attack modification methods
- `minionFunctions.lua`: Handles turn logic including ammo checks
- `minionAbilities.lua`: Defines ballista attack types
- `skill_definitions.lua`: Defines Ballista Master skills

## Implementation Notes

This implementation reuses much of the existing minion and trap systems, with specific extensions for:

1. Artificer trap-throwing (pre-combat interactions)
2. Ballista ammo system (in-combat resource management)

The decision to make Artificer's abilities work in the dungeon phase (rather than in combat) creates a unique gameplay mechanic that encourages preparation and tactics before entering battle. 