# Ballista Job (Contraption Master) Implementation Plan

## Original Prompt
<user_query>
I want to add a job that will summon ballistas, thow traps use some other knds of contraptions during combat.
Ballistas will be mechanically similar to minions (they have turns an act by independently, so internally we will just have a minion type that will be a ballista), but with the difference that they will always be able to perform just 3 attacks, after that they will need to be recharged. The job will have a skill that will reload the ballista.
Ballistas will be targetable by enemies and can be killed, just like minions
The job will have a skill to repair the ballista and some other skills to buff and alter the effect of the ballista. Some of those skill include, adding poison dot damage to the balista shots, changing the ballista damage to fire, changing ballista to shoot a net that slow or lock enemies and other similar effects

Help me create a detailed plan for the game design aspect and the technical one
Some details that we have to decide is how will this job progression be, will it come from rogue? Will it be a tier 2 or tier 3? it is a tier 3, what will be the tier 2?
What weapons will this class be able to equip? Will it have any other damaging sikill, or just hte ballista?
</user_query>

## Changelog
- 2024-07-27: Initial plan creation.
- 2024-07-28: Updated Artificer design to focus on dungeon trap-throwing interactions (see below for details).
- 2024-07-28: Added technical viability analysis and implementation details after reviewing existing systems.

---

## 1. Game Design Plan

### 1.1. Job Name and Theme
- **Name:** Artificer (Tier 2) → Ballista Master (Tier 3)
- **Theme:** A tactical engineer who deploys mechanical ballistas and contraptions in battle. Focuses on battlefield control, indirect damage, and support via mechanical minions.

### 1.2. Job Progression (Updated)
- **Tier 1 Prerequisite:** Rogue (primary), possibly allow Fighter as a secondary path.
- **Tier 2:** Artificer (new job)
  - Requirements: Rogue Lv. 10 (and/or Fighter Lv. 5)
  - Description: "A cunning inventor skilled in traps, gadgets, and mechanical minions."
  - **NEW:** Artificer is now focused on a unique dungeon interaction: throwing traps at visible enemies while exploring the dungeon (not in combat). Artificer has no direct combat skills, but can use 3+ different trap types in the dungeon.
- **Tier 3:** Ballista Master
  - Requirements: Artificer Lv. 15
  - Description: "A master of battlefield engineering, able to deploy powerful ballistas and advanced contraptions."

### 1.3. Attribute Focus
- **Primary:** DEX (for mechanical precision), INT (for invention), CON (for durability)
- **Secondary:** WIS (for tactical skills)

### 1.4. Weapons and Equipment
- **Weapons:** Crossbows, light hammers, daggers, possibly unique "tool" weapons (e.g., Wrench, Gadget Staff)
- **Armor:** Light to medium armor (leather, reinforced leather, special "engineer" gear)
- **Offhand:** Toolkits, mechanical offhands, or small shields

### 1.5. Core Mechanics (Updated)
- **Artificer Dungeon Trap-Throwing:**
  - While exploring the dungeon (first-person view), if the party has an Artificer, the player can throw traps at visible enemies (those seen in the 3D view).
  - When a trap is thrown at an enemy, there is a chance (based on Artificer and enemy level) that the trap will hinder the enemy:
    - Enemy may lose its first turn in combat
    - Enemy may start combat with a status effect (e.g., stunned, slowed, poisoned, etc.)
  - Artificer has no other skills by itself (no combat skills), but can use at least 3 different trap types (e.g., net trap, poison trap, stun trap) while in the dungeon.
  - Trap types can be expanded in the future.
  - This mechanic is unique to the Artificer and does not overlap with existing combat or minion mechanics.

- **Ballista Summon:**
  - Summons a Ballista minion (mechanically a minion type, but with unique rules)
  - Ballista acts independently, has its own turn, can be targeted and destroyed
  - Ballista can attack 3 times before requiring a reload (tracked as ammo or charges)
  - Ballista can be reloaded by the Artificer/Ballista Master (skill action)
  - Ballista can be repaired if damaged (skill action)
  - Ballista can be buffed or have its attack type changed (via skills)
  
- **Buff/Alter Ballista:**
  - Add poison to shots (DoT)
  - Change damage type (fire, ice, etc.)
  - Shoot net (inflicts slow or immobilize)
  - Overcharge (next attack deals double damage or AoE)
- **Other Skills:**  
  - Defensive skills
    -  "Deploy Cover" for party

### 1.6. Example Skill List (Updated)
- **Artificer (Tier 2):**
  - **Dungeon Trap Throw (x3+ types):**
    - Net Trap: Chance to immobilize or slow enemy at start of combat
    - Poison Trap: Chance to apply poison DoT at start of combat
    - Stun Trap: Chance to make enemy lose first turn
    - (More trap types can be added)
  - **No direct combat skills**
- **Ballista Master (Tier 3):**
  - Summon Ballista (minion, 3 attacks before reload)
  - Reload Ballista (restore all ammo to a Ballista)
  - Ballista Overcharge (next Ballista attack is AoE or double damage)
  - Ballista Elemental Mod (change Ballista's damage type for 2 turns)
  - Ballista Poison Mod (add poison DoT to Ballista attacks)
  - Ballista Net Shot (next Ballista attack inflicts slow/immobilize)
  - Advanced Repair (restore Ballista to full HP)

### 1.7. Ballista Minion Details
- **Acts on its own turn (like other minions)**
- **Ammo/Charge System:** 3 attacks, then must be reloaded
- **Targetable by enemies, can be destroyed**
- **Can be repaired or buffed**
- **Can be affected by status effects (e.g., stunned, burned)**
- **Can have its attack type/status changed by Artificer/Ballista Master skills**

### 1.8. Progression and Unlocks
- **Tier 2 (Artificer):** Focus on traps, gadgets, and basic minion support
- **Tier 3 (Ballista Master):** Unlocks Ballista, advanced minion support, and battlefield control

---

## 2. Technical Implementation Plan (Updated)

### 2.1. Data Structure Changes
- **job_definitions.lua:**
  - Artificer job definition updated: remove combat skills, add trap-throwing ability for dungeon exploration.
- **minion.lua/minionManager.lua:**
  - Add Ballista as a new minion type (or as a special case of existing minion)
  - Add ammo/charge tracking to minion data structure (e.g., `minion.ammo = 3`)
  - Add logic for Ballista to skip its turn if out of ammo (until reloaded)
  - Add logic for Ballista to be reloaded by a skill (restore ammo to max)
  - Add logic for Ballista to be repaired by a skill (restore HP)
  - Add logic for Ballista to be buffed/altered (status effects, damage type, etc.)
- **minionAbilities.lua:**
  - Add Ballista attack abilities (normal shot, poison shot, fire shot, net shot, overcharge shot, etc.)
  - Ensure minion abilities can be swapped/modified by skills
- **skill_definitions.lua:**
  - Add all new Artificer and Ballista Master skills
  - Ensure skills can target minions (for repair, reload, buff, etc.)
  - Add trap deployment skills (may require new trap/contraption system or integration with existing trapSystem)
- **trapSystem.lua:**
  - Allow player skills to deploy traps in combat (if not already supported)
  - Ensure traps can be triggered by enemies and have effects (damage, status, etc.)
  - Add new trap types usable by Artificer in the dungeon (not just for dungeon tiles, but as thrown projectiles at visible enemies).
- **combatSystem/combat/minionFunctions.lua:**
  - Ensure minion turn logic supports ammo/charge system for Ballista
  - Ensure minion status effects and buffs are supported
- **UI:**
  - Show Ballista ammo/charges in minion display
  - Show Ballista status (buffs, debuffs, repair needed, etc.)
  - Show trap deployment options and trap status in combat
- **dungeon.lua:**
  - Add logic to allow the player to throw traps at visible enemies if the party has an Artificer.
  - Implement UI/controls for selecting and throwing traps at enemies in the 3D view.
  - When a trap is thrown, determine if it hits and what effect it applies (based on Artificer/enemy level and trap type).
  - Store pre-combat status effects or turn loss for affected enemies.
- **raycaster.lua:**
  - Add support for targeting visible enemies in the 3D view (e.g., raycast to select enemy sprite/entity).
  - Visual feedback for trap-throwing (e.g., highlight target, show trap animation).
- **combatSystem.lua:**
  - On combat start, check if the enemy was hit by a trap in the dungeon and apply the appropriate status effect or turn loss.
  - Ensure status effects from traps are applied only for the first round/turn as appropriate.

### 2.2. New/Modified Mechanics
- **Ballista Ammo System:**
  - Track ammo/charges for Ballista minions
  - Prevent Ballista from acting if out of ammo
  - Allow reload skill to restore ammo
- **Ballista Buff/Mod System:**
  - Allow skills to change Ballista's attack type/status for a duration
  - Allow skills to apply buffs/debuffs to Ballista
- **Trap Deployment:**
  - Allow player to deploy traps in combat (as skills)
  - Traps act as battlefield hazards (triggered by enemy movement or as targeted skills)
- **Repair System:**
  - Allow skills to restore Ballista HP (and possibly other minions/contraptions)
- **Dungeon Trap-Throwing System:**
  - Allow player to select and throw traps at visible enemies in the dungeon if Artificer is in the party.
  - Track which enemies have been hit and what effects should be applied at combat start.
  - Ensure thrown traps are limited in number or have a cooldown (optional, for balance).
- **Combat Pre-Status System:**
  - On combat start, check for pre-applied status effects or turn loss from traps.
  - Remove/expire these effects after the first turn/round as needed.

### 2.3. Job Progression Logic
- **Update job progression logic to allow Rogue → Artificer (dungeon trap specialist) → Ballista Master**
- **Ensure job selection UI and level up screens support new jobs and requirements**

### 2.4. Testing and Balancing
- **Test Ballista minion logic (summon, attack, ammo, reload, repair, destruction)**
- **Test trap deployment and triggering in combat**
- **Test all new skills and interactions (buffs, debuffs, status effects)**
- **Balance Ballista stats, skills, and progression for fairness and fun**
- **Test trap-throwing in dungeon (targeting, hit chance, effect application)**
- **Test combat start with pre-applied status effects/turn loss**
- **Balance trap effects, hit chances, and Artificer progression**

---

## 3. Open Design Questions (for further iteration)
- Should Ballista be the only minion, or can Artificer also summon other contraptions (e.g., turrets, drones)?
- Should Ballista Master have access to unique weapons or armor?
- Should Ballista attacks be single-target, AoE, or both (via skills)?
- Should traps persist between battles or only last for one combat?
- Should Ballista be able to act immediately on summon, or have a "setup" turn?
- Should Ballista skills consume resources (e.g., special ammo, components)?
- Should thrown traps be limited by inventory, cooldown, or per-dungeon use?
- Should enemies be able to resist or avoid traps (e.g., based on their stats)?
- Should trap effects stack if multiple traps are thrown at the same enemy?
- Should Artificer be able to craft or recover traps between dungeons?

---

## 4. Actionable Steps for LLM (Updated)
1. Update Artificer job in `job_definitions.lua` to focus on dungeon trap-throwing (remove combat skills).
2. Implement dungeon trap-throwing system in `dungeon.lua` (UI, targeting, trap logic, effect storage).
3. Update `raycaster.lua` to support targeting visible enemies and visual feedback for trap throws.
4. Update `combatSystem.lua` to apply pre-combat trap effects/statuses at combat start.
5. Add new trap types and logic to `trapSystem.lua` for thrown traps.
6. Update UI for trap selection, targeting, and feedback.
7. Playtest and balance the new Artificer mechanics and progression.
8. Update job progression logic and UI for new jobs.

---

## 5. Technical Viability Analysis

After examining the existing systems, here's an analysis of the technical viability of implementing the Artificer and Ballista Master jobs:

### 5.1. Existing Systems That Can Be Reused

#### Trap System
- **trapSystem.lua** already has support for:
  - Creating traps with various effects (spike, gas, dart, etc.)
  - Trap detection and disarming
  - Visualization of traps in the dungeon
  - Damage calculation and effect application

#### Minion System
- **minionManager.lua** and **minion.lua** provide:
  - Minion creation and persistence
  - Three minion types (UNDEAD, ELEMENTAL, SPIRIT)
  - Stat scaling with summoner's attributes
  - Ability to update durations and handle lifecycle events
  - Support for abilities and passive buffs

#### Raycaster Engine
- **raycaster.lua** already supports:
  - Rendering entities in 3D space
  - Entity targeting for interactions
  - Visual effects for entities (can be extended for highlighting targets)

#### Combat System
- **combatSystem.lua** has:
  - Predefined states for different combat phases
  - Support for status effects
  - Support for minion turns
  - "isAmbush" flag that can be repurposed for pre-combat effects

### 5.2. Necessary Modifications

#### For Artificer (Dungeon Trap-Throwing)
1. **dungeon.lua**:
   - Add trap selection UI/controls during exploration (similar to existing item/skill UI)
   - Implement trap throwing mechanics (using raycaster for targeting)
   - Store pre-combat effects for enemies hit by traps
   - Add check for Artificer presence in party

2. **raycaster.lua**:
   - Extend entity targeting to support aiming at enemies
   - Add visual feedback for selected targets
   - Add animation for thrown traps

3. **combatSystem.lua**:
   - Extend combat initialization to check for pre-applied trap effects
   - Implement pre-combat status application (can reuse existing status system)

#### For Ballista Master
1. **minionManager.lua/minion.lua**:
   - Add a new "BALLISTA" minion type (or extend existing types)
   - Add ammo/charge tracking
   - Add functions for reloading and modifying ballista properties

2. **minionFunctions.lua**:
   - Extend minion turn execution to handle ammo checks
   - Implement special ballista abilities

---

## 6. Detailed Implementation Plan

### 6.1. Artificer Trap-Throwing Implementation

#### Step 1: Trap Type Definition
```lua
-- Add to trapSystem.lua
trapSystem.THROWN_TRAP_TYPES = {
    NET = {
        name = "Net Trap",
        effect = "immobilize",
        duration = 1, -- turns
        successChance = 0.7, -- base chance, modified by level difference
        texture = "net_trap"
    },
    POISON = {
        name = "Poison Trap",
        effect = "poison",
        damage = 5, -- base damage
        duration = 2, -- turns
        successChance = 0.6,
        texture = "poison_trap"
    },
    STUN = {
        name = "Stun Trap",
        effect = "stun",
        duration = 1, -- turns
        successChance = 0.5,
        texture = "stun_trap"
    }
}

-- Add function to check trap success
function trapSystem:checkThrownTrapSuccess(trapType, artificerLevel, enemyLevel)
    local trap = self.THROWN_TRAP_TYPES[trapType]
    if not trap then return false end
    
    local baseChance = trap.successChance
    local levelDiff = artificerLevel - enemyLevel
    local modifier = levelDiff * 0.05 -- 5% per level difference
    
    local successChance = baseChance + modifier
    successChance = math.max(0.1, math.min(0.9, successChance)) -- Clamp between 10% and 90%
    
    return math.random() < successChance
end
```

#### Step 2: Dungeon UI and Controls
```lua
-- Add to dungeon.lua

-- Check if party has Artificer
function dungeon:partyHasArtificer()
    if GAME.party then
        for _, member in ipairs(GAME.party) do
            if member.job == "Artificer" or member.job == "Ballista Master" then
                return true, member
            end
        end
    end
    return false
end

-- Initialize trap throwing UI
function dungeon:initTrapThrowingUI()
    -- Create UI elements for trap selection
    self.elements.trapSelector = screenManager.UI.Selector(
        20, GAME.height - 120, 150, 100, 
        {"Net Trap", "Poison Trap", "Stun Trap"},
        function(selected) self:selectTrap(selected) end
    )
    self.elements.trapSelector.visible = false
    
    -- Initialize trap throwing state
    self.trapThrowing = {
        active = false,
        selectedTrap = nil,
        targetedEnemy = nil
    }
end

-- Toggle trap throwing mode
function dungeon:toggleTrapThrowing()
    local hasArtificer, artificerMember = self:partyHasArtificer()
    if not hasArtificer then 
        uiFunctions.showFloatingText("No Artificer in party!", GAME.width/2, GAME.height/2, {1,0.5,0.5}, 2.0, self.floatingTexts)
        return 
    end
    
    self.trapThrowing.active = not self.trapThrowing.active
    
    if self.trapThrowing.active then
        -- Enter trap throwing mode
        self.elements.trapSelector.visible = true
        uiFunctions.showFloatingText("Trap throwing mode active. Select a trap.", GAME.width/2, GAME.height/2, {0.5,1,0.5}, 2.0, self.floatingTexts)
    else
        -- Exit trap throwing mode
        self.elements.trapSelector.visible = false
        self.trapThrowing.selectedTrap = nil
        self.trapThrowing.targetedEnemy = nil
    end
end

-- Select trap type
function dungeon:selectTrap(trapName)
    local trapType = nil
    if trapName == "Net Trap" then trapType = "NET"
    elseif trapName == "Poison Trap" then trapType = "POISON"
    elseif trapName == "Stun Trap" then trapType = "STUN"
    end
    
    self.trapThrowing.selectedTrap = trapType
    uiFunctions.showFloatingText("Selected " .. trapName .. ". Click on an enemy to throw.", GAME.width/2, GAME.height/2, {0.5,1,0.5}, 2.0, self.floatingTexts)
end

-- Update function to handle enemy targeting
function dungeon:updateTrapTargeting()
    if not self.trapThrowing.active or not self.trapThrowing.selectedTrap then return end
    
    -- Get mouse position
    local mx, my = love.mouse.getPosition()
    
    -- Use raycaster to find entity under cursor
    local entity = raycaster:getEntityUnderCursor(mx, my, self.entities)
    
    if entity and entity.type == "monster" then
        -- Highlight targeted enemy
        self.trapThrowing.targetedEnemy = entity
        -- Visual feedback handled in raycaster.lua
    else
        self.trapThrowing.targetedEnemy = nil
    end
end

-- Throw trap at targeted enemy
function dungeon:throwTrap()
    if not self.trapThrowing.active or not self.trapThrowing.selectedTrap or not self.trapThrowing.targetedEnemy then
        return false
    end
    
    local hasArtificer, artificerMember = self:partyHasArtificer()
    if not hasArtificer then return false end
    
    local targetEnemy = self.trapThrowing.targetedEnemy
    local trapType = self.trapThrowing.selectedTrap
    
    -- Calculate success based on Artificer level and enemy level
    local artificerLevel = artificerMember.jobLevels[artificerMember.job] or 1
    local enemyLevel = targetEnemy.level or 1
    
    local success = trapSystem:checkThrownTrapSuccess(trapType, artificerLevel, enemyLevel)
    
    if success then
        -- Mark enemy as trapped
        targetEnemy.trapped = true
        targetEnemy.trapType = trapType
        
        -- Show success message
        uiFunctions.showFloatingText("Trap hit! Effect will apply in combat.", GAME.width/2, GAME.height/2, {0.2,1,0.2}, 2.0, self.floatingTexts)
        
        -- Play success sound
        assetManager:playSound("trap_set")
    else
        -- Show failure message
        uiFunctions.showFloatingText("Trap missed!", GAME.width/2, GAME.height/2, {1,0.5,0.5}, 2.0, self.floatingTexts)
        
        -- Play failure sound
        assetManager:playSound("trap_miss")
    end
    
    -- Exit trap throwing mode
    self.trapThrowing.active = false
    self.elements.trapSelector.visible = false
    
    return true
end

-- Add to mousepressed handler
function dungeon:mousepressed(x, y, button)
    -- ... existing code ...
    
    -- Handle trap throwing
    if self.trapThrowing and self.trapThrowing.active and button == 1 then
        if self.trapThrowing.targetedEnemy then
            self:throwTrap()
            return true
        end
    end
    
    -- ... rest of existing code ...
end

-- Add to keypressed handler
function dungeon:keypressed(key)
    -- ... existing code ...
    
    -- Add trap throwing hotkey
    if key == "t" and self.state == STATES.EXPLORING then
        self:toggleTrapThrowing()
        return true
    end
    
    -- ... rest of existing code ...
end
```

#### Step 3: Raycaster Extensions
```lua
-- Add to raycaster.lua

-- Get entity under cursor
function raycaster:getEntityUnderCursor(mouseX, mouseY, entities)
    -- Convert mouse position to normalized camera space
    local normalizedX = mouseX / self.viewWidth
    
    -- Use normalizedX to determine which screen column was clicked
    local screenColumn = math.floor(normalizedX * self.viewWidth)
    
    -- Get the ray direction for this column
    local cameraX = 2 * normalizedX - 1
    local rayDirX = self.camera.dirX + self.camera.planeX * cameraX
    local rayDirY = self.camera.dirY + self.camera.planeY * cameraX
    
    -- Check if there's a wall hit by this ray
    local wallDist = self.zBuffer[screenColumn + 1] or self.maxDistance
    
    -- Check entities along this ray
    for _, entity in ipairs(entities) do
        if entity.type == "monster" then
            -- Calculate entity position relative to camera
            local spriteX = entity.x - self.camera.x
            local spriteY = entity.y - self.camera.y
            
            -- Calculate perpendicular distance
            local perpDist = (spriteX * spriteX + spriteY * spriteY)
            perpDist = math.sqrt(perpDist) * math.cos(math.atan2(spriteY, spriteX) - self.camera.angle)
            
            -- Check if entity is closer than wall
            if perpDist < wallDist then
                -- Check if entity is in the clicked column (with some margin)
                local spriteScreenX = math.floor((self.viewWidth / 2) * (1 + (math.atan2(spriteY, spriteX) - self.camera.angle) / (self.fov/2)))
                if math.abs(spriteScreenX - screenColumn) < 30 then -- 30 pixel margin
                    return entity
                end
            end
        end
    end
    
    return nil
end

-- Draw highlighted entity (for trap targeting)
function raycaster:drawHighlightedEntity(entity)
    if not entity then return end
    
    -- Use existing sprite rendering code with added highlight
    -- This would be implemented within the renderEntities function
    -- by adding a highlight parameter and drawing an outline/glow
}
```

#### Step 4: Combat System Integration
```lua
-- Add to combatSystem.lua - setupCombatants function

function coreFunctions.setupCombatants(self)
    -- ... existing code ...
    
    -- Check for and apply trap effects from Artificer
    for _, enemy in ipairs(self.enemies) do
        if enemy.trapped and enemy.trapType then
            local trapType = enemy.trapType
            local trapEffect = trapSystem.THROWN_TRAP_TYPES[trapType].effect
            local trapDuration = trapSystem.THROWN_TRAP_TYPES[trapType].duration
            
            -- Apply appropriate effect
            if trapEffect == "immobilize" then
                statusEffects:applyEffect(enemy, "immobilize", trapDuration)
                self:addLog(enemy.name .. " is caught in a net trap!", {0.5, 0.7, 1})
            elseif trapEffect == "poison" then
                statusEffects:applyEffect(enemy, "poison", trapDuration)
                local poisonDamage = trapSystem.THROWN_TRAP_TYPES[trapType].damage
                self:addLog(enemy.name .. " is poisoned by a trap!", {0.5, 1, 0.5})
            elseif trapEffect == "stun" then
                statusEffects:applyEffect(enemy, "stun", trapDuration)
                self:addLog(enemy.name .. " is stunned by a trap!", {1, 1, 0.5})
                -- For stun traps, also mark first turn as taken
                if not self.isAmbush then -- Only if not already ambushed
                    enemy.turnTaken = true
                end
            end
            
            -- Clear trap info
            enemy.trapped = false
            enemy.trapType = nil
        end
    end
    
    -- ... rest of existing code ...
end
```

### 6.2. Ballista Master Implementation

#### Step 1: Add New Minion Type
```lua
-- Add to minion.lua
minion.TYPES = {
    UNDEAD = "undead",       
    ELEMENTAL = "elemental", 
    SPIRIT = "spirit",
    BALLISTA = "ballista"    -- New type for Ballista Master
}

-- Special setup for ballista type in createMinion function
if type == minion.TYPES.BALLISTA then
    -- Ballista-specific properties
    newMinion.takesActions = true
    newMinion.persistAcrossBattles = true -- Persists until destroyed
    newMinion.ammo = 3 -- Start with 3 shots
    newMinion.maxAmmo = 3
    newMinion.needsReload = false
end
```

#### Step 2: Add Ballista Functions to minionManager
```lua
-- Add to minionManager.lua

-- Reload a ballista
function minionManager:reloadBallista(ballista)
    if ballista.type ~= minion.TYPES.BALLISTA then return false end
    
    ballista.ammo = ballista.maxAmmo
    ballista.needsReload = false
    return true
end

-- Modify ballista attack type
function minionManager:modifyBallistaAttack(ballista, attackType, duration)
    if ballista.type ~= minion.TYPES.BALLISTA then return false end
    
    ballista.attackType = attackType
    ballista.attackTypeDuration = duration
    return true
end
```

#### Step 3: Update Minion Turn Logic
```lua
-- Modify executeMinionTurn in minionFunctions.lua

local function executeMinionTurn(self)
    -- ... existing code ...
    
    -- Check if minion is a ballista and needs reload
    if minion.type == minion.TYPES.BALLISTA and (minion.ammo <= 0 or minion.needsReload) then
        self:addLog(minion.name .. " needs to be reloaded!", {0.7, 0.7, 0.7})
        
        -- Skip turn
        self.minionsTurnTaken[charIndex][minionIndex] = true
        return
    end
    
    -- ... existing attack code ...
    
    -- If ballista, use ammo
    if minion.type == minion.TYPES.BALLISTA and minion.ammo > 0 then
        minion.ammo = minion.ammo - 1
        if minion.ammo <= 0 then
            minion.needsReload = true
        end
    end
    
    -- ... rest of existing code ...
}
```

---

## 7. Code Reuse Summary

### 7.1. Artificer Trap-Throwing
- **Reuse `trapSystem.lua`** for trap definitions, success checks, and effect calculation
- **Reuse `raycaster.lua`** entity rendering for targeting
- **Reuse `statusEffects.lua`** for applying trap effects in combat
- **Reuse `dungeon.lua`** UI framework for trap selection interface
- **Reuse `combatSystem.lua`** pre-combat setup to apply trap effects

### 7.2. Ballista Master
- **Reuse `minion.lua`** and extend with a new type
- **Reuse `minionManager.lua`** lifecycle management
- **Reuse `minionFunctions.lua`** for turn execution, with added ammo checks
- **Reuse `minionAbilities.lua`** for ballista attacks

### 7.3. Estimated Reuse Percentage
- Artificer: ~70% reuse of existing code, 30% new code (mainly UI and targeting)
- Ballista Master: ~80% reuse of existing code, 20% new code (mainly ammo system and special abilities)

--- 