# Damage Calculation Formulas

This document outlines the core damage calculation formulas used in the game for player skills and monster abilities.

## 1. Player Skill Damage

Player skill damage is primarily calculated in `gameplay/skillSystem.lua`, within the `skillSystem:calculateDamage` function.

**Core Formula Structure:**

The damage output depends on the skill's `type` (e.g., "physical", "magical") and `basePower`, the character's relevant stats (e.g., `attack`, `magicAttack`, `strength`, `intelligence`), and the target's `defense`.

A common pattern observed for direct damage skills is:

`damage = (skill_basePower / 100) * ( (character_primary_stat * STAT_MULTIPLIER) - target_effective_defense )`

**Key Components:**

*   **`skill_basePower`**: The inherent power value of the skill, defined in `data/skill_definitions.lua`.
*   **`character_primary_stat`**: The character's relevant offensive statistic (e.g., `calculatedAttack` which might include Strength and weapon bonuses, or `calculatedMagicAttack` for Intelligence and magic weapon bonuses).
*   **`STAT_MULTIPLIER`**: Often, the character's primary stat is multiplied (e.g., by 2) to give it more weight in the calculation before defense is applied.
*   **`target_effective_defense`**: The target's defense after considering the damage type. For physical damage, this might be `target_defense / 2`; for magical damage, it could be `target_defense / 3` (implying magic bypasses more raw defense).

**Example (Physical Skill):**
`damage = (skill.basePower / 100) * ( (character.calculatedAttack * 2) - math.floor(target.defense / 2) )`

**Important Notes:**
*   Damage is typically floored (`math.floor`) at various stages.
*   A minimum damage of 1 is usually enforced.
*   The formula can be further modified by:
    *   Character-specific passives or job bonuses.
    *   Active buffs or debuffs (e.g., Strengthen, Weaken).
    *   Target resistances or vulnerabilities to specific `damageType`s (e.g., Fire, Ice), which apply a multiplier.
    *   Critical hits.

## 2. Monster Ability Damage

Monster ability damage is calculated in `gameplay/monsterAttackSystem.lua`, within the `monsterAttackSystem:calculateDamage` function.

**Core Formula Structure (as of latest update):**

`damage = floor( (ability.basePower / 100) * ( (monster_ATK_or_MATK * 2) - effective_player_DEF ) )`

**Key Components:**

*   **`ability.basePower`**: The inherent power of the monster's ability, defined in `data/monsterAbilities.lua`.
*   **`monster_ATK_or_MATK`**: The monster's `attack` stat (for physical abilities) or `magicAttack` stat (for magical abilities) from `data/monster_definitions.lua`.
*   **`monster_ATK_or_MATK * 2`**: The monster's relevant attack stat is doubled to increase its impact, similar to player skill calculations.
*   **`effective_player_DEF`**: The player character's defense after reduction based on the ability's type:
    *   For physical abilities: `effective_player_DEF = floor(player_raw_DEF / 2)`
    *   For magical abilities: `effective_player_DEF = floor(player_raw_DEF / 3)`

**Example (Physical Monster Ability):**
A monster uses a physical ability with `basePower = 130`. The monster has `attack = 16`. The target player has `defense = 10`.

1.  `monster_ATK_scaled = 16 * 2 = 32`
2.  `effective_player_DEF = floor(10 / 2) = 5`
3.  `damage = floor( (130 / 100) * (32 - 5) ) = floor(1.3 * 27) = floor(35.1) = 35`

**Important Notes:**
*   Damage is floored (`math.floor`) and a minimum damage of 1 is enforced.
*   This base damage is then subject to further modifications:
    *   Target resistances/vulnerabilities to the ability's `damageType`.
    *   Status effects on the attacker (e.g., Strengthen) or target (e.g., Vulnerable, Protect).

This revised formula aims to make monster abilities, especially those with high `basePower`, more impactful and scale more aggressively with the monster's offensive stats. 