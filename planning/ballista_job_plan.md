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
  - **NEW:** Artificer is now focused on a unique dungeon interaction: throwing traps at visible enemies while exploring the dungeon (not in combat). Artificer has no direct combat skills, but can use 3+ different trap types in the dungeon. These "skills" are dungeon actions, their effects are defined for pre-combat scenarios.
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
  - Artificer has no other direct combat skills. Its abilities revolve around preparing and throwing these dungeon traps.
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
  - **Dungeon Trap Throw (x3+ types):** (These are dungeon actions, not combat skills. Their definitions in `skill_definitions.lua` will specify pre-combat effects. `job_definitions.lua` will list them for player information.)
    - Net Trap: Chance to immobilize or slow enemy at start of combat
    - Poison Trap: Chance to apply poison DoT at start of combat
    - Stun Trap: Chance to make enemy lose first turn
    - (More trap types can be added)
  - **No direct combat skills for Artificer.**
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
- **Tier 2 (Artificer):** Focus on dungeon trap-throwing, gadgets, and basic minion support awareness (no direct minion command skills).
- **Tier 3 (Ballista Master):** Unlocks Ballista, advanced minion support, and battlefield control.

### 1.9. Ballista Reload Mechanism (Game Design)
- **Skill Name:** "Reload Ballista" (usable by Ballista Master).
- **Action Type:** Standard combat action, consumes the character's turn.
- **Effect:** Targets a single friendly Ballista minion that has `needsReload = true` or ammo < maxAmmo. Restores the target Ballista's ammo to its `maxAmmo` value.
- **Resource Cost:** Initially, no special resource cost beyond the action point/turn. Can be revisited for balance (e.g., requiring "Scrap Parts" consumable).
- **Cooldown:** Initially, no cooldown. Can be revisited for balance.
- **Player Feedback:**
    - Clear UI indication on the Ballista minion when it requires reloading (e.g., "Needs Reload" status, ammo displayed as 0/X).
    - Visual/audio feedback when the Reload Ballista skill is successfully used.
    - The Ballista should be able to act normally on its next turn after being reloaded.

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
- **Update job progression logic to allow Rogue → Artificer (dungeon trap specialist with no direct combat skills) → Ballista Master (combat engineer with Ballista minions).**
- **Ensure job selection UI and level up screens support new jobs and requirements, correctly displaying Artificer's non-combat trap abilities and Ballista Master's combat skills.**

### 2.4. Testing and Balancing
- **Test Ballista minion logic (summon, attack, ammo, reload, repair, destruction)**
- **Test trap deployment and triggering in combat**
- **Test all new skills and interactions (buffs, debuffs, status effects)**
- **Balance Ballista stats, skills, and progression for fairness and fun**
- **Test trap-throwing in dungeon (targeting, hit chance, effect application)**
- **Test combat start with pre-applied status effects/turn loss**
- **Balance trap effects, hit chances, and Artificer progression**
- **Test Ballista reload skill functionality and its impact on combat flow**

### 2.5. Documentation
- **File Creation:** Create `docs/artificer_ballista_mechanics.md`.
- **Content - Artificer (Dungeon Trap-Throwing):**
    - Detailed explanation of how players activate trap-throwing mode (e.g., hotkey 'T').
    - Description of the UI: trap selector population (based on learned Artificer skills/trap types), enemy targeting via mouse click in 3D view.
    - Breakdown of trap success calculation (`trapSystem:checkThrownTrapSuccess`), mentioning dependency on Artificer level vs. enemy level.
    - List of initial trap types (Net, Poison, Stun) and their effects (linking to `skill_effect_id` in `skill_definitions.lua`). Emphasis on these being pre-combat effects.
    - Mention key files: `dungeon.lua` (core logic, UI), `raycaster.lua` (targeting), `trapSystem.lua` (trap data, success check), `job_definitions.lua` (Artificer skill list), `skill_definitions.lua` (trap effect definitions), `combatSystem.lua` (applying effects).
- **Content - Ballista Master (Ballista Minion):**
    - How to summon a Ballista (via "Summon Ballista" skill).
    - Ballista stats, its persistence, and how it acts on its own turn.
    - Ammo System: `ammo`, `maxAmmo`, `needsReload` properties in `minion.lua`. How `minionFunctions.lua` checks ammo before acting and sets `needsReload`.
    - "Reload Ballista" skill: How it's used by the Ballista Master, its AP cost, targeting a Ballista, and calling `minionManager:reloadBallista`.
    - `minionManager:reloadBallista` function details: resetting ammo and `needsReload` flag.
    - Other skills: Brief mention of repair, buff/debuff skills and how they might interact with Ballista properties.
    - Mention key files: `minion.lua` (Ballista type, properties), `minionManager.lua` (reload function), `minionFunctions.lua` (turn logic, ammo consumption), `skill_definitions.lua` (Ballista Master skills), `job_definitions.lua` (Ballista Master skill list).
- **UI Changes:** Briefly describe new UI elements (trap selector, Ballista ammo display).

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
1. Update `job_definitions.lua`:
    - For Artificer: Define job, focus on dungeon trap-throwing (no combat skills), add descriptive entries for trap abilities.
    - For Ballista Master: Define job and add all its combat skills.
2. Update `skill_definitions.lua`:
    - For Artificer: Add definitions for the *effects* of dungeon traps (these are not active combat skills).
    - For Ballista Master: Add definitions for all combat skills (including Summon Ballista, Reload Ballista, buffs, etc.).
3. Implement dungeon trap-throwing system in `dungeon.lua` (UI, targeting, trap logic using `trapSystem.lua`, effect storage for `combatSystem.lua`).
4. Update `raycaster.lua` to support targeting visible enemies for trap throws and provide visual feedback.
5. Update `combatSystem.lua` to apply pre-combat trap effects/statuses at combat start, based on effects defined in `skill_definitions.lua`.
6. Add new trap types and associated logic to `trapSystem.lua` for thrown traps, ensuring clarity that these are for Artificer's dungeon use.
7. Implement Ballista minion type (in `minion.lua`), ammo system, reload mechanism (in `minionManager.lua` for the function, `skill_definitions.lua` for the skill), and modification logic in relevant minion files (`minionFunctions.lua` for turn behavior).
8. Update UI elements for:
    - Artificer: Dungeon trap selection, targeting, and feedback.
    - Ballista: Display of ammo, "Needs Reload" status, and other statuses/buffs.
9. Playtest and balance the new Artificer (dungeon trap effectiveness, progression) and Ballista Master (Ballista stats, skill costs, reload impact, overall combat balance) mechanics.
10. Update job progression logic in the game and corresponding UI elements to reflect the new jobs and their unique skill acquisition.
11. Create a new documentation file `docs/artificer_ballista_mechanics.md` detailing the new functionalities as specified in section 2.5.

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
   - Add trap selection UI/controls during exploration (similar to existing item/skill UI) specifically for Artificer.
   - Implement trap throwing mechanics (using raycaster for targeting, `trapSystem.lua` for success/effect definition).
   - Store pre-combat effects for enemies hit by traps.
   - Add check for Artificer presence in party to enable this functionality.

2. **raycaster.lua**:
   - Extend entity targeting to support aiming at enemies
   - Add visual feedback for selected targets
   - Add animation for thrown traps

3. **combatSystem.lua**:
   - Extend combat initialization to check for pre-applied trap effects using data stored by `dungeon.lua`.
   - Implement pre-combat status application (can reuse existing status system, applying effects as defined in `skill_definitions.lua` for the specific trap).

#### For Ballista Master
1. **minionManager.lua/minion.lua**:
   - Add a new "BALLISTA" minion type.
   - Add `ammo`, `maxAmmo`, and `needsReload` properties to minion structure (specifically for Ballista, or generalized if other minions might use ammo).
   - Add `reloadBallista(ballista)` function to `minionManager.lua` to reset ammo and `needsReload` status.
   - Add functions for modifying ballista properties (attack type, etc.).

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
        skill_effect_id = "DUNGEON_NET_TRAP_EFFECT", -- Links to skill_definitions.lua
        successChanceFormula = function(artificerLevel, enemyLevel) -- Example, can be more complex
            local baseChance = 0.7
            local levelDiff = artificerLevel - enemyLevel
            local modifier = levelDiff * 0.05
            return math.max(0.1, math.min(0.9, baseChance + modifier))
        end,
        texture = "net_trap_projectile" -- Texture for the thrown projectile
    },
    POISON = {
        name = "Poison Trap",
        skill_effect_id = "DUNGEON_POISON_TRAP_EFFECT",
        successChanceFormula = function(artificerLevel, enemyLevel)
            local baseChance = 0.6
            local levelDiff = artificerLevel - enemyLevel
            local modifier = levelDiff * 0.05
            return math.max(0.1, math.min(0.9, baseChance + modifier))
        end,
        texture = "poison_trap_projectile"
    },
    STUN = {
        name = "Stun Trap",
        skill_effect_id = "DUNGEON_STUN_TRAP_EFFECT",
        successChanceFormula = function(artificerLevel, enemyLevel)
            local baseChance = 0.5
            local levelDiff = artificerLevel - enemyLevel
            local modifier = levelDiff * 0.05
            return math.max(0.1, math.min(0.9, baseChance + modifier))
        end,
        texture = "stun_trap_projectile"
    }
}

-- Updated function to check trap success
function trapSystem:checkThrownTrapSuccess(trapIdentifier, artificerLevel, enemyLevel)
    local trapProps = self.THROWN_TRAP_TYPES[trapIdentifier]
    if not trapProps or not trapProps.successChanceFormula then return false end
    
    local successChance = trapProps.successChanceFormula(artificerLevel, enemyLevel)
    return math.random() < successChance
end

-- Function to get trap effect details (referenced by combatSystem)
function trapSystem:getThrownTrapEffectID(trapIdentifier)
    local trapProps = self.THROWN_TRAP_TYPES[trapIdentifier]
    return trapProps and trapProps.skill_effect_id
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
        {}, -- Trap options will be populated dynamically
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
        uiFunctions.showFloatingText("No Artificer in party to throw traps!", GAME.width/2, GAME.height/2, {1,0.5,0.5}, 2.0, self.floatingTexts)
        return 
    end
    
    self.trapThrowing.active = not self.trapThrowing.active
    
    if self.trapThrowing.active then
        -- Populate trap selector based on Artificer's known traps
        local availableTraps = self:getArtificerAvailableTraps(artificerMember)
        if #availableTraps == 0 then
            uiFunctions.showFloatingText("Artificer knows no traps yet!", GAME.width/2, GAME.height/2, {1,0.5,0.5}, 2.0, self.floatingTexts)
            self.trapThrowing.active = false
            return
        end
        self.elements.trapSelector:setOptions(availableTraps)
        self.elements.trapSelector.visible = true
        uiFunctions.showFloatingText("Trap throwing: Select a trap and click an enemy.", GAME.width/2, GAME.height/2, {0.5,1,0.5}, 2.0, self.floatingTexts)
    else
        -- Exit trap throwing mode
        self.elements.trapSelector.visible = false
        self.trapThrowing.selectedTrap = nil
        self.trapThrowing.targetedEnemy = nil
    end
end

-- Get available traps for the Artificer (based on job_definitions.lua)
function dungeon:getArtificerAvailableTraps(artificerMember)
    local knownTrapNames = {}
    local jobData = JOBS[artificerMember.job]
    if jobData and jobData.skills_by_level then
        local currentLevel = artificerMember.jobLevels[artificerMember.job] or 0
        for level, skills in pairs(jobData.skills_by_level) do
            if currentLevel >= level then
                for _, skillInfo in ipairs(skills) do
                    -- Assuming display_name matches keys in trapSystem.THROWN_TRAP_TYPES or a mapping exists
                    if skillInfo.display_name == "Dungeon Trapper: Net" then table.insert(knownTrapNames, "NET") end
                    if skillInfo.display_name == "Dungeon Trapper: Poison" then table.insert(knownTrapNames, "POISON") end
                    if skillInfo.display_name == "Dungeon Trapper: Stun" then table.insert(knownTrapNames, "STUN") end
                    -- This needs robust mapping if names differ significantly
                end
            end
        end
    end
    -- Convert keys to display names for the selector
    local displayNames = {}
    for _, trapKey in ipairs(knownTrapNames) do
        if trapSystem.THROWN_TRAP_TYPES[trapKey] then
            table.insert(displayNames, trapSystem.THROWN_TRAP_TYPES[trapKey].name) -- e.g., "Net Trap"
        end
    end
    return displayNames
end

-- Select trap type (trapName is the display name like "Net Trap")
function dungeon:selectTrap(trapName)
    local trapIdentifier = nil
    -- Find the key (e.g., "NET") from the display name
    for key, trapDetails in pairs(trapSystem.THROWN_TRAP_TYPES) do
        if trapDetails.name == trapName then
            trapIdentifier = key
            break
        end
    end
    
    if trapIdentifier then
        self.trapThrowing.selectedTrap = trapIdentifier -- Store "NET", "POISON", etc.
        uiFunctions.showFloatingText("Selected " .. trapName .. ". Click on an enemy.", GAME.width/2, GAME.height/2, {0.5,1,0.5}, 2.0, self.floatingTexts)
    else
        self.trapThrowing.selectedTrap = nil -- Clear if not found
    end
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
    local trapTypeKey = self.trapThrowing.selectedTrap -- This is now "NET", "POISON", etc.
    
    -- Calculate success based on Artificer level and enemy level
    local artificerLevel = artificerMember.jobLevels[artificerMember.job] or 1
    local enemyLevel = targetEnemy.level or 1
    
    local success = trapSystem:checkThrownTrapSuccess(trapTypeKey, artificerLevel, enemyLevel)
    
    if success then
        -- Mark enemy as trapped
        targetEnemy.trapped_by_artificer = true -- More specific flag
        targetEnemy.artificer_trap_type = trapTypeKey -- Store "NET", "POISON", etc.
        targetEnemy.artificer_trap_effect_id = trapSystem:getThrownTrapEffectID(trapTypeKey) -- Store the skill_effect_id

        local trapDisplayName = trapSystem.THROWN_TRAP_TYPES[trapTypeKey].name
        uiFunctions.showFloatingText(trapDisplayName .. " hit! Effect in combat.", GAME.width/2, GAME.height/2, {0.2,1,0.2}, 2.0, self.floatingTexts)
        
        -- Play success sound
        assetManager:playSound("trap_set")
    else
        -- Show failure message
        local trapDisplayName = trapSystem.THROWN_TRAP_TYPES[trapTypeKey].name
        uiFunctions.showFloatingText(trapDisplayName .. " missed!", GAME.width/2, GAME.height/2, {1,0.5,0.5}, 2.0, self.floatingTexts)
        
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
        if enemy.trapped_by_artificer and enemy.artificer_trap_effect_id then
            local effectId = enemy.artificer_trap_effect_id
            local trapEffectDef = SKILL_DEFINITIONS[effectId]
            
            if trapEffectDef then
                self:addLog(enemy.name .. " is affected by a pre-combat " .. trapSystem.THROWN_TRAP_TYPES[enemy.artificer_trap_type].name .. "!", {0.8, 0.8, 0.2})
                -- Apply effects defined in skill_definitions.lua
                if trapEffectDef.effects then
                    for _, effectData in ipairs(trapEffectDef.effects) do
                        if effectData.type == "APPLY_STATUS" then
                            -- Assuming statusEffects:applyEffect can take a definition object or separate params
                            statusEffects:applyEffect(enemy, effectData.status_effect, effectData.duration, {base_damage = effectData.base_damage, chance = effectData.chance})
                            self:addLog("... " .. enemy.name .. " gets " .. effectData.status_effect .. "!", {0.8,0.8,0.2})

                            -- Special handling for STUN (e.g., make enemy lose first turn)
                            if effectData.status_effect == "STUN" and not self.isAmbush then
                                enemy.turnTaken = true -- Or a more direct way to skip first turn
                                self:addLog("... " .. enemy.name .. " will miss its first action!", {1,1,0.5})
                            end
                        end
                        -- Extend for other effect types if PRE_COMBAT_TRAP can do more
                    end
                end
            end
            
            -- Clear trap info after applying
            enemy.trapped_by_artificer = false
            enemy.artificer_trap_type = nil
            enemy.artificer_trap_effect_id = nil
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