# Attribute Influence Implementation Plan

## Overview
This document outlines specific tasks to improve how attributes influence gameplay mechanics. Each task includes implementation details, file locations, and cross-references to the dev dashboard.

---

## 🎯 High Priority Tasks

### Task 1: Implement Dodge Chance System
**Goal**: Add DEX-based dodge mechanics to combat

**Files to Modify**:
- `gameplay/character.lua`
- `gameplay/combat/playerActionFunctions.lua`  
- `gameplay/monsterAttackSystem.lua`
- `dev/balance_analyzer.py` (for balance analysis)

**Implementation Steps**:

1. **Add Dodge Calculation Function** (`gameplay/character.lua`)
   ```lua
   -- Add after calculateMagicDefense function (around line 570)
   function character:calculateDodgeChance(char)
       local baseDodge = 2  -- Base 2% dodge chance
       local dexBonus = char.attributes.DEX * 0.3  -- 0.3% per DEX point
       
       return math.min(50, baseDodge + dexBonus)  -- Cap at 50%
   end
   ```

2. **Add Dodge Check to Combat** (`gameplay/combat/playerActionFunctions.lua`)
   ```lua
   -- Add dodge check before damage application (around line 75 in attack function)
   -- Before: enemy.currentHP = math.max(0, enemy.currentHP - damage)
   
   local dodgeChance = character:calculateDodgeChance(targetEnemy)
   if math.random(1, 100) <= dodgeChance then
       self:addLog(targetEnemy.name .. " dodges the attack!", {0.8, 0.8, 0.2})
       return  -- Skip damage application
   end
   ```

3. **Add Player Dodge vs Monster Attacks** (`gameplay/monsterAttackSystem.lua`)
   ```lua
   -- Add before damage application in calculateDamage function (around line 50)
   local characterSystem = require("gameplay/character")
   local dodgeChance = characterSystem:calculateDodgeChance(target)
   if math.random(1, 100) <= dodgeChance then
       return 0, 1.0, ability.damageType or "physical"  -- Dodged, no damage
   end
   ```

4. **Update Balance Dashboard** (`dev/balance_analyzer.py`)
   ```python
   # Add to calculate_character_power function (around line 320)
   # Calculate dodge chance (DEX-based)
   dodge_chance = min(50, 5 + (attributes.get('DEX', 10) * 0.3))
   
   # Add dodge to the returned metrics
   return {
       'attack_power': attack_power,
       'magic_power': magic_power,
       'defense': defense,
       'magic_defense': magic_defense,
       'hp': hp,
       'mp': mp,
       'dodge_chance': dodge_chance,  # New field
       'survivability': survivability
   }
   ```

---

### Task 2: Implement Hit/Miss System in Combat
**Goal**: Make hit chance calculations actually work in combat

**Files to Modify**:
- `gameplay/combat/playerActionFunctions.lua`
- `gameplay/skill.lua`
- `dev/templates/edit.html` (for skill hit chance display)

**Implementation Steps**:

1. **Add Hit Chance Check to Player Attacks** (`gameplay/combat/playerActionFunctions.lua`)
   ```lua
   -- Add after attack power calculation (around line 60)
   local hitChance = 70  -- Base hit chance
   
   -- Determine if this is a ranged attack based on weapon type
   local isRangedAttack = false
   if currentChar.equipment and currentChar.equipment.weapon then
       local weapon = currentChar.equipment.weapon
       if weapon.category == "bow" or weapon.category == "crossbow" or 
          weapon.subtype == "throwing" or weapon.name:lower():find("bow") then
           isRangedAttack = true
       end
   end
   
   if isRangedAttack then
       hitChance = character:calculateRangedHitChance(
           currentChar.attributes.DEX, 
           currentChar.attributes.STR
       )
   else
       hitChance = character:calculateMeleeHitChance(
           currentChar.attributes.STR, 
           currentChar.attributes.DEX
       )
   end
   
   -- Check if attack hits
   if math.random(1, 100) > hitChance then
       self:addLog(currentChar.name .. " misses!", {0.8, 0.4, 0.4})
       return  -- Skip damage
   end
   ```

2. **Add Hit Chance to Skill Calculations** (`gameplay/skill.lua`)
   ```lua
   -- Add new function after calculateDamage (around line 260)
   function skillSystem:calculateHitChance(skill, user, target)
       local baseHitChance = skill.baseHitChance or 85
       
       -- Apply accuracy multiplier from status effects
       local accuracyMultiplier = statusEffects:getMultiplier(user, "accuracy_multiplier")
       
       -- DEX bonus for precision
       local dexBonus = 0
       if user.attributes and user.attributes.DEX then
           dexBonus = user.attributes.DEX * 0.2
       end
       
       return math.min(95, baseHitChance + dexBonus) * accuracyMultiplier
   end
   ```

3. **Update Skill Edit Template** (`dev/templates/edit.html`)
   ```html
   <!-- Add after basePower field (around line 850) -->
   <div class="col-md-6 mb-3">
       <label for="baseHitChance" class="form-label">Base Hit Chance (%)</label>
       <input type="number" class="form-control" name="baseHitChance" 
              value="{{ skill_data.baseHitChance if skill_data.baseHitChance else 85 }}"
              min="0" max="100" placeholder="85">
       <small class="text-muted">Base accuracy percentage (default: 85%)</small>
   </div>
   ```

---

### Task 3: Enhanced DEX Critical Hit System
**Goal**: Make DEX contribute to critical hit chance for appropriate skills

**Files to Modify**:
- `gameplay/skill.lua`
- `data/skill_definitions.lua`
- `dev/balance_analyzer.py`

**Implementation Steps**:

1. **Modify Critical Hit Calculation** (`gameplay/skill.lua`)
   ```lua
   -- Replace existing crit calculation (around line 220) with:
   local isCritical = false
   if skill.critChance then
       local critChance = skill.critChance
       
       -- DEX bonus for precision skills
       if skill.useDexForCrit and user.attributes and user.attributes.DEX then
           local dexBonus = user.attributes.DEX * 0.005  -- 0.5% per DEX point
           critChance = critChance + dexBonus
       end
       
       -- Apply accuracy multiplier from status effects
       critChance = critChance * statusEffects:getMultiplier(user, "accuracy_multiplier")
       
       if math.random() < critChance then
           damage = damage * (skill.critModifier or 1.5)
           isCritical = true
       end
   end
   ```

2. **Update Rogue Skills** (`data/skill_definitions.lua`)
   ```lua
   -- Update PreciseStrike (around line 280)
   PreciseStrike = {
       name = "Precise Strike",
       description = "A precise attack with increased critical hit chance.",
       type = "physical",
       target = "single_enemy",
       mpCost = 5,
       basePower = 90,
       formula = "physical",
       critModifier = 2.5,
       critChance = 0.25,
       useDexForCrit = true,  -- New field
       maxLevel = 5,
       levelModifier = function(level) 
           return {
               power = 1 + (level * 0.06),
               critChance = 0.25 + (level * 0.05)
           }
       end
   },
   
   -- Add to other precision skills: Backstab, AssassinStrike, etc.
   ```

---

## 🎯 Medium Priority Tasks

### Task 4: Expand CHA Influence
**Goal**: Make Charisma affect more game systems

**Files to Modify**:
- `screens/shop.lua`
- `gameplay/questSystem.lua` 
- `gameplay/reputationSystem.lua`
- `dev/templates/manage.html`

**Implementation Steps**:

1. **Add Shop Price Discounts** (`screens/shop.lua`)
   ```lua
   -- Add function after existing shop functions
   function shop:calculatePriceDiscount(character)
       if not character or not character.attributes then
           return 1.0  -- No discount
       end
       
       local charisma = character.attributes.CHA or 5
       local discount = math.min(0.15, charisma * 0.01)  -- Max 15% discount, 1% per CHA
       return 1.0 - discount
   end
   
   -- Modify item price display to use discount
   ```

2. **Enhanced Quest Rewards** (`gameplay/questSystem.lua`)
   ```lua
   -- Add after haggle function (around line 890)
   function questSystem:calculateCharismaBonus(character)
       local charisma = character.attributes.CHA or 5
       local bonus = 1.0 + (charisma * 0.02)  -- 2% bonus per CHA point
       return math.min(1.5, bonus)  -- Max 50% bonus
   end
   ```

3. **Update Management Dashboard** (`dev/templates/manage.html`)
   ```html
   <!-- Add CHA influence info panel -->
   <div class="info-panel">
       <h6>Charisma Influences</h6>
       <ul>
           <li>Shop Prices: -1% per point (max -15%)</li>
           <li>Quest Rewards: +2% per point (max +50%)</li>
           <li>Haggle Success: +3% per point</li>
       </ul>
   </div>
   ```

---

### Task 5: Enhanced Wisdom Healing
**Goal**: Make WIS provide enhanced healing effectiveness

**Files to Modify**:
- `gameplay/skill.lua`
- `dev/balance_analyzer.py`

**Implementation Steps**:

1. **Enhance Healing Skills** (`gameplay/skill.lua`)
   ```lua
   -- Modify healing formula (around line 160)
   elseif skill.formula == "healing" then
       local wisdom = 10
       if user.attributes and user.attributes.WIS then
           wisdom = user.attributes.WIS
       end
       
       -- Enhanced scaling for high wisdom
       local wisdomMultiplier = 1.0 + ((wisdom - 10) * 0.05)  -- 5% bonus per point above 10
       wisdom = tonumber(wisdom) or 10
       
       damage = (power / 100) * (wisdom * 3) * wisdomMultiplier
       damage = math.max(1, damage)
   end
   ```

---

### Task 6: DEX Speed Contribution
**Goal**: Make DEX contribute to speed for turn order in the active turn system

**Files to Modify**:
- `gameplay/character.lua`
- `gameplay/combat/turnManager.lua` (if speed calculation needs updating)
- `dev/balance_analyzer.py`

**Implementation Steps**:

1. **Add Speed Calculation Enhancement** (`gameplay/character.lua`)
   ```lua
   -- Add after existing calculation functions
   function character:calculateSpeed(char)
       local baseSpeed = char.speed or 10  -- Default speed
       local dexBonus = math.floor(char.attributes.DEX / 20)  -- +1 speed per 20 DEX
       
       return baseSpeed + dexBonus
   end
   ```

2. **Update Character Speed on Attribute Changes** (`gameplay/character.lua`)
   ```lua
   -- Add to attribute modification functions or level up
   -- Update speed whenever DEX changes
   char.speed = character:calculateSpeed(char)
   ```

---

## 🎯 Low Priority Tasks

### Task 7: Attribute Documentation
**Goal**: Create comprehensive documentation for the attribute system

**Files to Create**:
- `docs/attribute_system.md`

**Implementation Steps**:

1. **Create Attribute System Documentation** (`docs/attribute_system.md`)
   - Document how each attribute influences gameplay
   - Explain calculation formulas and caps
   - Provide examples and use cases
   - Cross-reference with existing systems (combat, skills, etc.)
   - Include balance guidelines and recommendations

---

## 📊 Dev Dashboard Updates Needed

### Balance Analyzer Updates (`dev/balance_analyzer.py`)

1. **Add New Metrics** (around line 320 in `calculate_character_power`):
   ```python
   # Add these calculations
   dodge_chance = min(50, 2 + (attributes.get('DEX', 10) * 0.3))
   speed_bonus = math.floor(attributes.get('DEX', 10) / 20)  # +1 speed per 20 DEX
   shop_discount = min(15, attributes.get('CHA', 10) * 1)  # Percentage
   ```

2. **Update Return Dictionary**:
   ```python
   return {
       'attack_power': attack_power,
       'magic_power': magic_power,
       'defense': defense,
       'magic_defense': magic_defense,
       'hp': hp,
       'mp': mp,
       'dodge_chance': dodge_chance,
       'speed_bonus': speed_bonus,
       'shop_discount': shop_discount,
       'survivability': survivability
   }
   ```

### Management Dashboard Updates (`dev/templates/manage.html`)

1. **Add Attribute Influence Panel**:
   ```html
   <div class="card mb-4">
       <div class="card-header">
           <h5>Attribute Influences</h5>
       </div>
       <div class="card-body">
           <div class="row">
               <div class="col-md-6">
                   <h6>STR (Strength)</h6>
                   <ul>
                       <li>Physical damage: Direct scaling</li>
                       <li>Melee hit chance: +0.5% per point</li>
                       <li>Attack power calculation</li>
                   </ul>
               </div>
               <div class="col-md-6">
                   <h6>DEX (Dexterity)</h6>
                   <ul>
                       <li>Dodge chance: +0.3% per point</li>
                       <li>Ranged hit chance: +0.5% per point</li>
                       <li>Critical hit bonus: +0.5% per point (precision skills)</li>
                       <li>Steal success: +1% per point</li>
                       <li>Speed bonus: +1 per 20 points</li>
                   </ul>
               </div>
           </div>
           <!-- Add similar blocks for other attributes -->
       </div>
   </div>
   ```

---

## 🧪 Testing Checklist

After implementing each task:

1. **Test combat mechanics**:
   - Verify dodge chances work correctly
   - Check hit/miss system functions
   - Validate critical hit bonuses

2. **Test attribute scaling**:
   - Create characters with different attribute distributions
   - Verify calculations match expected values

3. **Test dashboard accuracy**:
   - Compare in-game calculations with dashboard predictions
   - Update balance analyzer if discrepancies found

4. **Test edge cases**:
   - Very high/low attribute values
   - Missing attribute data
   - Nil value handling

---

## 📋 Implementation Order

1. **Week 1**: Tasks 1-2 (Dodge & Hit/Miss systems)
2. **Week 2**: Task 3 (DEX Critical Hit system)
3. **Week 3**: Tasks 4-5 (CHA & WIS enhancements)
4. **Week 4**: Task 6 (DEX Speed contribution)
5. **Week 5**: Task 7 (Documentation) + Dashboard updates and testing

Each task is designed to be implementable independently, allowing for incremental testing and validation. 