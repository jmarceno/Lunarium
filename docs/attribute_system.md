# Attribute System Documentation

## Overview

The attribute system in DC Lua Vibe defines the core characteristics of player characters and influences nearly every aspect of gameplay. Each character has seven primary attributes that determine their capabilities in combat, social interactions, and other game mechanics.

## Core Attributes

### STR (Strength)
**Primary Focus**: Physical combat effectiveness

**Influences**:
- **Physical Damage**: Direct scaling for all physical attacks and skills
- **Melee Hit Chance**: +0.5% hit chance per point (base formula: 70 + STR*0.5 + DEX*0.2)
- **Attack Power**: Core component of physical damage calculations
- **Equipment Requirements**: Many weapons and heavy armor require minimum STR

**Formula Examples**:
- Physical skill damage: `(basePower / 100) * (STR * 2 - target_defense)`
- Basic attack damage: `attackPower - (enemyDefense / 2)`

### DEX (Dexterity) 
**Primary Focus**: Precision, agility, and speed

**Influences**:
- **Dodge Chance**: +0.3% dodge chance per point (base: 2%)
- **Ranged Hit Chance**: +0.5% hit chance per point for bow/crossbow attacks
- **Critical Hit Bonus**: +0.5% critical chance per point for precision skills (useDexForCrit = true)
- **Speed**: +1 speed per 20 DEX points (affects turn order in active turn system)
- **Steal Success**: +1% success rate per point for stealing attempts

**Formula Examples**:
- Dodge chance: `min(50, 2 + DEX * 0.3)`
- Speed calculation: `baseSpeed + floor(DEX / 20)`
- Ranged hit chance: `70 + DEX * 0.5 + STR * 0.2`

### CON (Constitution)
**Primary Focus**: Health and endurance

**Influences**:
- **Hit Points**: Primary determinant of maximum HP
- **Physical Defense**: Used in defense calculations when no explicit defense stat exists

**Formula Examples**:
- HP calculation: `50 + CON * 5` (simplified, actual formula includes level scaling)
- Fallback defense: `CON / 2` when target has no explicit defense value

### INT (Intelligence)
**Primary Focus**: Magical power and mana capacity

**Influences**:
- **Magic Power**: Core component for magical damage calculations
- **Mana Points**: Primary component of MP calculation alongside WIL and WIS
- **Magical Skill Damage**: Direct scaling for all magical attacks

**Formula Examples**:
- Magic damage: `(basePower / 100) * (INT * 2.5 - target_magicDefense)`
- MP calculation: `20 + INT * 3 + WIS * 2` (simplified)

### WIS (Wisdom)
**Primary Focus**: Healing effectiveness and magical insight

**Influences**:
- **Healing Power**: Enhanced scaling for healing spells and abilities
- **Mana Points**: Secondary component of MP calculation
- **Magic Defense**: Used in magical defense calculations

**Formula Examples**:
- Healing formula: `(basePower / 100) * (WIS * 3) * wisdomMultiplier`
- Wisdom multiplier: `1.0 + ((WIS - 10) * 0.05)` (5% bonus per point above 10)
- Magic defense: `floor((WIL + WIS) / 4)` + equipment bonuses

### WIL (Willpower)
**Primary Focus**: Magical resistance and mana capacity

**Influences**:
- **Mana Points**: Primary component of MP calculation alongside INT and WIS
- **Magic Defense**: Core component of magical damage resistance
- **Mental Status Resistance**: Resistance to mind-affecting abilities

**Formula Examples**:
- Magic defense: `floor((WIL + WIS) / 4)` + equipment bonuses
- MP calculation: Includes WIL as major component

### CHA (Charisma)
**Primary Focus**: Social interactions and commerce

**Influences**:
- **Shop Prices**: Up to 15% discount on all purchases (1% per CHA point)
- **Quest Rewards**: Enhanced rewards from certain quests (planned)
- **Haggle Success**: Improved success rates in negotiation scenarios (existing feature)

**Formula Examples**:
- Price discount: `min(0.15, CHA * 0.01)` (maximum 15% discount)
- Final price: `ceil(basePrice * (1.0 - discount))`

## Combat Mechanics

### Hit/Miss System
All attacks and skills use hit chance calculations based on relevant attributes:

- **Melee Attacks**: 70 + STR*0.5 + DEX*0.2
- **Ranged Attacks**: 70 + DEX*0.5 + STR*0.2  
- **Skills**: Base skill hit chance + DEX*0.2 (if applicable)

### Dodge System
Characters can avoid incoming damage through dexterity-based dodging:
- **Base Dodge**: 2% for all characters
- **DEX Bonus**: +0.3% per DEX point
- **Cap**: Maximum 50% dodge chance
- **Application**: Checked for all physical attacks and damaging skills

### Critical Hit System
Certain skills can critically hit for increased damage:
- **Base Critical**: Defined per skill (e.g., 25% for Precise Strike)
- **DEX Bonus**: +0.5% per DEX point for skills with `useDexForCrit = true`
- **Status Effects**: Modified by accuracy_multiplier status effects
- **Damage Multiplier**: Typically 1.5x to 2.5x base damage

### Speed and Turn Order
The active turn system uses speed to determine action frequency:
- **Base Speed**: Default 10, varies by character/class
- **DEX Contribution**: +1 speed per 20 DEX points
- **Turn System**: Higher speed = more frequent actions
- **Calculation**: Characters act when their speed accumulator reaches threshold

## Status Effect Integration

Attributes work seamlessly with the status effect system:

- **Multipliers**: Status effects can modify attribute effectiveness
- **Accuracy Effects**: Affect hit chances and critical chances
- **Defense Effects**: Modify damage reduction calculations
- **Temporary Boosts**: Can temporarily increase effective attribute values

## Equipment Synergy

Attributes determine equipment usability and effectiveness:

- **Requirements**: Weapons and armor have minimum attribute requirements
- **Bonuses**: Equipment can provide attribute bonuses
- **Scaling**: Some equipment effects scale with character attributes
- **Unique Items**: May have special attribute-based effects

## Balance Considerations

### Attribute Caps
- **Base Cap**: 50 points per attribute (defined in character.lua)
- **Equipment**: Can potentially exceed caps through bonuses
- **Progression**: Balanced growth through job advancement

### Scaling Curves
- **Linear Growth**: Most attribute benefits scale linearly
- **Diminishing Returns**: Some mechanics have caps (dodge at 50%, price discount at 15%)
- **Breakpoints**: DEX speed bonus at every 20 points creates meaningful thresholds

### Multi-Attribute Dependencies
- **HP**: Primarily CON, but level also matters
- **MP**: Combination of INT, WIL, and WIS
- **Defense**: Multiple attributes contribute to different defense types
- **Hit Chances**: Usually combine two attributes for balanced gameplay

## Implementation Files

### Core System Files
- `gameplay/character.lua`: Attribute calculations and character stat management
- `gameplay/skill.lua`: Skill damage, hit chance, and critical hit calculations
- `gameplay/combat/playerActionFunctions.lua`: Combat resolution and attribute application
- `gameplay/monsterAttackSystem.lua`: Monster vs player combat with dodge checks

### Data Files
- `data/skill_definitions.lua`: Skill definitions with attribute dependencies
- `data/job_definitions.lua`: Job attribute growth patterns

### UI/Shop Integration
- `screens/shop.lua`: Charisma-based price discounts
- `dev/balance_analyzer.py`: Attribute impact analysis and balance testing

### Documentation
- `docs/active_turn_system.md`: Turn order and speed mechanics
- `planning/attribute_influence_implementation_plan.md`: Development roadmap

## Future Enhancements

Potential areas for expansion:
- **Environmental Interactions**: Attributes affecting exploration options
- **Crafting Integration**: Attributes influencing crafting success and quality
- **Social System**: Expanded charisma effects in dialogue and reputation
- **Advanced Combat**: Attribute-based special abilities and combos

---

This documentation reflects the current implementation as of the attribute system overhaul. For technical implementation details, refer to the specific source files mentioned above. 