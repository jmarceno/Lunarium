# Skill Effects Implementation Status

This document reviews each skill defined in `gameplay/skill_definitions.lua`, lists its effects, and assesses whether its effects are fully supported by the current combat system implementation `gameplay/combatSystem.lua`. Any missing or unimplemented functionality is noted.

---

## Legend
- **Supported**: Effect is implemented and handled in combat.
- **Partial**: Some effect logic is present, but not fully implemented or may not work as intended.
- **Missing**: No implementation for this effect in combat.

---

## Skills Review

### Base Skills
- **Attack**
  - Effect: Physical damage (formula)
  - Status: **Supported**

- **Defend**
  - Effect: `defense_multiplier` buff (stat, value, duration)
  - Status: **Partial** (Handled as a special case in `executeDefend`, but not as a general status effect. Not shown in status icons.)

---

### Fighter Skills
- **Power Strike**
  - Effect: Physical damage (formula)
  - Status: **Supported**

- **Double Slash**
  - Effect: Physical damage, 2 hits
  - Status: **Partial** (Multiple hits not natively supported; only one hit is processed.)

- **Taunt**
  - Effect: `taunt` status (stat, value, duration)
  - Status: **Missing** (No taunt logic in combat/AI targeting)

- **Shield Bash**
  - Effect: Physical damage, chance to `stun` (type, chance, duration, strength)
  - Status: **Missing**
  - Implementation Note: Needs to add chance-based application of stun in `executeSkill` function. Current `applySkillEffect` doesn't handle effect.type with chance rolls.

---

### Mage Skills
- **Fire Bolt**
  - Effect: Magical damage, chance to `burn` (type, chance, duration, strength)
  - Status: **Missing**
  - Implementation Note: Needs to add chance-based application of burn in `executeSkill` function, similar to other status effects like stun.

- **Ice Shard**
  - Effect: Magical damage, chance to apply `speed_multiplier` (stat, value, chance, duration)
  - Status: **Partial** 
  - Implementation Note: Currently applies speed_multiplier directly without chance rolls. Should be handled as a proper status effect in statusEffects.lua.

- **Thunder Bolt**
  - Effect: Magical damage, increased crit chance
  - Status: **Supported**

- **Mana Shield**
  - Effect: `barrier` (stat, formula, duration)
  - Status: **Missing** (No barrier logic in combat; stat is set but not used to absorb damage)

---

### Cleric Skills
- **Heal**
  - Effect: Healing (formula)
  - Status: **Supported**

- **Divine Favor**
  - Effect: Buffs `attack_multiplier` and `defense_multiplier` (stats, duration)
  - Status: **Partial** (Multipliers are set as status, but not all are used in damage/defense calculations)

- **Purify**
  - Effect: Removes negative status effects, healing (function)
  - Status: **Partial** (Negative status removal is supported; custom healing function is not used)

- **Smite**
  - Effect: Magical damage (formula)
  - Status: **Supported**

---

### Rogue Skills
- **Precise Strike**
  - Effect: Physical damage, increased crit chance
  - Status: **Supported**

- **Steal**
  - Effect: Attempt to steal item (stealChance)
  - Status: **Supported**

---

### Advanced Job Skills
- **Shield Wall**
  - Effect: `defense_multiplier` (stat, value, duration)
  - Status: **Partial** (See Defend)

- **Rage**
  - Effect: Buffs `attack_multiplier`, debuffs `defense_multiplier` (stats, duration)
  - Status: **Partial** (Multipliers are set, but not all are used in calculations)

- **Fireball**
  - Effect: Magical damage to all enemies
  - Status: **Supported**

- **Group Heal**
  - Effect: Healing to all allies
  - Status: **Supported**

---

### Master Job Skills
- **Divine Blade**
  - Effect: Physical damage (formula)
  - Status: **Supported**

- **Arcane Mastery**
  - Effect: `magic_multiplier` (stat, value, duration)
  - Status: **Partial** (Multiplier is set, but not used in all spell calculations)

- **Shadow Merge**
  - Effect: `untargetable` (stat, value, duration)
  - Status: **Missing** (No logic for untargetable in combat/AI)

---

### Dark Mage Skills
- **Shadow Bolt**
  - Effect: Magical damage (formula)
  - Status: **Supported**

- **Drain Life**
  - Effect: Magical damage, lifeDrain (drainPercent)
  - Status: **Missing** (No life drain logic implemented)

- **Curse of Weakness**
  - Effect: Debuff `attack_multiplier` (stat, value, duration)
  - Status: **Partial** (Multiplier is set, but not used in all calculations)

---

### Elemental Mage Skills
- **Elemental Burst**
  - Effect: Magical damage (random element)
  - Status: **Partial** (Random element not handled; always uses defined element)

- **Elemental Affinity**
  - Effect: Buffs `elementalResist`, `elementalPower` (custom stats, duration)
  - Status: **Missing** (No logic for these stats in combat)

---

### Spirit Speaker Skills
- **Spirit Sight**
  - Effect: `revealWeakness` (reveal enemy weaknesses)
  - Status: **Missing** (No logic for revealing weaknesses in combat)

- **Ancestral Guidance**
  - Effect: Buff `accuracy_multiplier` (stat, value, duration)
  - Status: **Missing** (No logic for accuracy_multiplier in hit calculations)

---

### Necromancer/Conjurer/Shaman Summons
- **All Summon Skills**
  - Effect: Summon minion with stats, abilities, duration
  - Status: **Supported** (Summons are handled and minions act in combat)

- **Dark Command, Death Pact, Elemental Mastery, etc.**
  - Effect: Buffs to minions (various stats)
  - Status: **Partial/Missing** (Buffs are set, but not all stats are used in calculations)

---

### Other Effects
- **barrier**: Not implemented (see Mana Shield)
- **untargetable**: Not implemented (see Shadow Merge)
- **elementalResist/elementalPower**: Not implemented
- **accuracy_multiplier**: Not implemented
- **revealWeakness**: Not implemented
- **lifeDrain**: Not implemented
- **Multiple hits**: Only first hit is processed
- **Stat multipliers**: Only some are used in calculations (attack_multiplier, defense_multiplier, etc.)

---

## Summary Table

| Skill Name         | Effect(s)                        | Status     | Notes |
|--------------------|----------------------------------|------------|-------|
| Attack             | Physical damage                  | Supported  |       |
| Defend             | defense_multiplier               | Partial    | Not a status effect, not shown in icons |
| Power Strike       | Physical damage                  | Supported  |       |
| Double Slash       | 2x physical damage               | Partial    | Only one hit processed |
| Taunt              | taunt                            | Missing    | No AI targeting logic |
| Shield Bash        | Stun                             | Missing    | No chance-based stun application |
| Fire Bolt          | Burn                             | Missing    | No chance-based burn application |
| Ice Shard          | speed_multiplier                 | Partial    | Applies without chance rolls |
| Thunder Bolt       | Crit chance                      | Supported  |       |
| Mana Shield        | barrier                          | Missing    | No barrier logic |
| Heal               | Healing                          | Supported  |       |
| Divine Favor       | attack/defense_multiplier        | Partial    | Not all used |
| Purify             | Remove negative status           | Partial    | Custom healing not used |
| Smite              | Magical damage                   | Supported  |       |
| Precise Strike     | Crit chance                      | Supported  |       |
| Steal              | Steal item                       | Supported  |       |
| Shield Wall        | defense_multiplier               | Partial    | See Defend |
| Rage               | attack/defense_multiplier        | Partial    | Not all used |
| Fireball           | AOE magical damage               | Supported  |       |
| Group Heal         | AOE healing                      | Supported  |       |
| Divine Blade       | Physical damage                  | Supported  |       |
| Arcane Mastery     | magic_multiplier                 | Partial    | Not all used |
| Shadow Merge       | untargetable                     | Missing    | No logic |
| Shadow Bolt        | Magical damage                   | Supported  |       |
| Drain Life         | lifeDrain                        | Missing    | No logic |
| Curse of Weakness  | attack_multiplier                | Partial    | Not all used |
| Elemental Burst    | random element                   | Partial    | Not handled |
| Elemental Affinity | elementalResist/elementalPower   | Missing    | No logic |
| Spirit Sight       | revealWeakness                   | Missing    | No logic |
| Ancestral Guidance | accuracy_multiplier              | Missing    | No logic |
| Summons            | Summon minion                    | Supported  |       |
| Minion Buffs       | Buff minion stats                | Partial    | Not all stats used |

---

## Recommendations
- Implement missing status effect application with chance rolls in `playerActionFunctions.executeSkill`:
  - Add proper stun application for Shield Bash
  - Add proper burn application for Fire Bolt
  - Convert speed_multiplier to a standard status effect
- Standardize all stat modifiers as proper status effects in statusEffects.lua
- Add new status effect types for: barrier, untargetable, elementalResist, accuracy_multiplier
- Implement support for multiple hits in skills
- Ensure all stat multipliers are correctly used in damage/defense calculations
- Add logic for life drain, taunt, and revealWeakness
- Consider making all buffs/debuffs visible as status effects with proper icons 