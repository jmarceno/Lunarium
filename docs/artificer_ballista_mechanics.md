# Artificer and Ballista Master Mechanics

This document outlines the implementation details for the Artificer and Ballista Master jobs, focusing on their unique mechanics: dungeon trap-throwing for the Artificer, and the Ballista minion system for the Ballista Master.

## 1. Artificer: Dungeon Trap-Throwing

The Artificer is a Tier 2 job specializing in tactical preparation. Instead of direct combat skills, the Artificer can throw various traps at visible enemies during dungeon exploration. These traps can apply pre-combat debuffs or hinder enemies.

### 1.1. Activation and UI
- **Activation:** While exploring the dungeon, if an Artificer is in the party, the player can press a hotkey (default: 'T') to enter "Trap Throwing Mode."
- **Trap Selector UI:**
    - Upon entering trap throwing mode, a UI element appears, allowing the player to select which trap to throw.
    - This selector is populated based on the traps the Artificer has learned (defined in `job_definitions.lua` and linked to `trapSystem.THROWN_TRAP_TYPES`).
    - Example UI initialization in `dungeon.lua`:
      ```lua
      function dungeon:initTrapThrowingUI()
          self.elements.trapSelector = screenManager.UI.Selector(
              20, GAME.height - 120, 150, 100, 
              {}, -- Trap options will be populated dynamically
              function(selected) self:selectTrap(selected) end
          )
          self.elements.trapSelector.visible = false
          self.trapThrowing = { active = false, selectedTrap = nil, targetedEnemy = nil }
      end
      ```
- **Targeting:**
    - After selecting a trap, the player can click on a visible enemy in the 3D dungeon view.
    - The `raycaster.lua` module is used to determine which enemy is being targeted.
      ```lua
      -- In dungeon.lua, during updateTrapTargeting:
      local entity = raycaster:getEntityUnderCursor(mx, my, self.entities)
      if entity and entity.type == "monster" then
          self.trapThrowing.targetedEnemy = entity
      end
      ```
    - Visual feedback (e.g., highlighting the targeted enemy) should be handled by `raycaster.lua` or `dungeon.lua`'s rendering functions.

### 1.2. Trap Success and Effects
- **Success Calculation:**
    - When a trap is thrown, its success is determined by `trapSystem:checkThrownTrapSuccess(trapIdentifier, artificerLevel, enemyLevel)`.
    - This function typically considers the Artificer's level versus the enemy's level, along with a base chance defined for each trap type.
    - Example structure in `trapSystem.lua`:
      ```lua
      trapSystem.THROWN_TRAP_TYPES = {
          NET = {
              name = "Net Trap",
              skill_effect_id = "DUNGEON_NET_TRAP_EFFECT", -- Links to skill_definitions.lua
              successChanceFormula = function(artificerLevel, enemyLevel)
                  local baseChance = 0.7
                  local levelDiff = artificerLevel - enemyLevel
                  local modifier = levelDiff * 0.05
                  return math.max(0.1, math.min(0.9, baseChance + modifier))
              end,
              texture = "net_trap_projectile"
          },
          -- Other traps (POISON, STUN) follow a similar structure
      }

      function trapSystem:checkThrownTrapSuccess(trapIdentifier, artificerLevel, enemyLevel)
          local trapProps = self.THROWN_TRAP_TYPES[trapIdentifier]
          if not trapProps or not trapProps.successChanceFormula then return false end
          local successChance = trapProps.successChanceFormula(artificerLevel, enemyLevel)
          return math.random() < successChance
      end
      ```
- **Applying Effects:**
    - If the trap hits, the targeted enemy is marked (e.g., `targetEnemy.trapped_by_artificer = true`, `targetEnemy.artificer_trap_effect_id = ...`).
    - The actual effect (e.g., stun, poison) is defined in `skill_definitions.lua` and linked via the `skill_effect_id`.
    - When combat starts, `combatSystem.lua` (specifically in `coreFunctions.setupCombatants`) checks for these marked enemies and applies the corresponding effects.
      ```lua
      -- In combatSystem.lua (coreFunctions.setupCombatants)
      for _, enemy in ipairs(self.enemies) do
          if enemy.trapped_by_artificer and enemy.artificer_trap_effect_id then
              local effectId = enemy.artificer_trap_effect_id
              local trapEffectDef = SKILL_DEFINITIONS[effectId]
              if trapEffectDef then
                  self:addLog(enemy.name .. " is affected by a pre-combat " .. trapSystem.THROWN_TRAP_TYPES[enemy.artificer_trap_type].name .. "!", {0.8, 0.8, 0.2})
                  if trapEffectDef.effects then
                      for _, effectData in ipairs(trapEffectDef.effects) do
                          if effectData.type == "APPLY_STATUS" then
                              statusEffects:applyEffect(enemy, effectData.status_effect, effectData.duration, {base_damage = effectData.base_damage, chance = effectData.chance})
                              if effectData.status_effect == "STUN" and not self.isAmbush then
                                  enemy.turnTaken = true -- Skip first turn
                              end
                          end
                      end
                  end
              end
              -- Clear trap flags
              enemy.trapped_by_artificer = false 
              enemy.artificer_trap_type = nil
              enemy.artificer_trap_effect_id = nil
          end
      end
      ```
- **Initial Trap Types:**
    - **Net Trap:** `skill_effect_id = "DUNGEON_NET_TRAP_EFFECT"` (e.g., applies SLOW or IMMOBILIZE).
    - **Poison Trap:** `skill_effect_id = "DUNGEON_POISON_TRAP_EFFECT"` (e.g., applies POISON status).
    - **Stun Trap:** `skill_effect_id = "DUNGEON_STUN_TRAP_EFFECT"` (e.g., applies STUN, potentially making the enemy lose its first turn).
    These effects are defined as pre-combat effects that typically last for a very short duration (e.g., 1 turn) or modify the enemy's initial combat state.

### 1.3. Key Files
- **`dungeon.lua`:** Handles the core logic for trap-throwing mode, UI interaction (trap selection), initiating the throw, and storing trap effects on enemies.
- **`raycaster.lua`:** Provides functionality for targeting enemies in the 3D view (`getEntityUnderCursor`).
- **`trapSystem.lua`:** Defines throwable trap types, their properties (name, success chance formula, linked skill effect ID), and the success calculation logic (`checkThrownTrapSuccess`, `getThrownTrapEffectID`).
- **`job_definitions.lua`:** Lists the trap-throwing "skills" for the Artificer. These entries inform the UI about what traps the Artificer knows (e.g., "Dungeon Trapper: Net").
- **`skill_definitions.lua`:** Defines the actual pre-combat *effects* of the traps (e.g., applying STUN status for 1 turn). These are referenced by `skill_effect_id`.
- **`gameplay/combat/coreFunctions.lua` (via `combatSystem.lua`):** The `setupCombatants` function checks for and applies the stored pre-combat effects from traps when a battle begins.
- **`statusEffects.lua`:** Used by `combatSystem.lua` to apply the status conditions defined by the traps.

## 2. Ballista Master: Ballista Minion

The Ballista Master is a Tier 3 job that excels at deploying and managing powerful Ballista minions in combat.

### 2.1. Summoning and Basic Properties
- **Summoning:** The Ballista Master uses the "Summon Ballista" skill (defined in `skill_definitions.lua`) to bring a Ballista into combat.
- **Minion Type:** A new minion type, `minion.TYPES.BALLISTA`, is added in `minion.lua`.
  ```lua
  -- In minion.lua
  minion.TYPES = {
      UNDEAD = "undead",       
      ELEMENTAL = "elemental", 
      SPIRIT = "spirit",
      BALLISTA = "ballista"    -- New type
  }
  ```
- **Stats and Persistence:**
    - Ballistas are persistent minions ( `persistAcrossBattles = true` if not destroyed).
    - They have their own stats, take actions on their turn, and can be targeted/destroyed by enemies.
    - Initial properties are set in `minion.createMinion` in `minion.lua`:
      ```lua
      -- In minion.lua, inside createMinion
      if type == minion.TYPES.BALLISTA then
          newMinion.takesActions = true
          newMinion.persistAcrossBattles = true 
          newMinion.ammo = 3 
          newMinion.maxAmmo = 3
          newMinion.needsReload = false
      end
      ```

### 2.2. Ammo System
- **Properties:** Ballistas have an ammo system, tracked by `ammo`, `maxAmmo`, and `needsReload` properties within their data structure in `minion.lua`.
- **Attacking:** Each attack consumes one ammo.
- **Out of Ammo:**
    - If a Ballista attempts to act with `ammo <= 0` or `needsReload == true`, it will skip its turn. This logic is handled in `minionFunctions.lua` (specifically `executeMinionTurn`).
      ```lua
      -- In minionFunctions.lua (executeMinionTurn)
      if minion.type == minion.TYPES.BALLISTA and (minion.ammo <= 0 or minion.needsReload) then
          self:addLog(minion.name .. " needs to be reloaded!", {0.7, 0.7, 0.7})
          -- Skip turn logic...
          return
      end
      -- ... (attack logic) ...
      if minion.type == minion.TYPES.BALLISTA and minion.ammo > 0 then
          minion.ammo = minion.ammo - 1
          if minion.ammo <= 0 then
              minion.needsReload = true
          end
      end
      ```

### 2.3. Reloading
- **"Reload Ballista" Skill:** The Ballista Master has a skill (e.g., "Reload Ballista") to replenish a target Ballista's ammo. This skill is defined in `skill_definitions.lua`.
- **Action:** Using the skill costs an action point and targets a friendly Ballista.
- **`minionManager:reloadBallista` Function:** The skill's effect calls `minionManager:reloadBallista(ballistaInstance)` in `minionManager.lua`.
  ```lua
  -- In minionManager.lua
  function minionManager:reloadBallista(ballista)
      if ballista.type ~= minion.TYPES.BALLISTA then return false end
      
      ballista.ammo = ballista.maxAmmo
      ballista.needsReload = false
      -- Potentially add a combat log message here
      return true
  end
  ```
- This function resets the Ballista's `ammo` to `maxAmmo` and clears the `needsReload` flag.

### 2.4. Other Skills
- **Repair:** Skills to restore a Ballista's HP (e.g., "Advanced Repair").
- **Buffs/Debuffs/Modifications:** Skills to alter the Ballista's attack type (e.g., fire damage, net shot), add poison DoT, or provide other enhancements (e.g., "Ballista Overcharge").
    - These skills might temporarily change properties on the Ballista minion object or apply status effects to it.
    - A function like `minionManager:modifyBallistaAttack(ballista, attackType, duration)` can be used to manage temporary attack modifications.
      ```lua
      -- In minionManager.lua
      function minionManager:modifyBallistaAttack(ballista, attackType, duration)
          if ballista.type ~= minion.TYPES.BALLISTA then return false end
          
          ballista.attackType = attackType -- e.g., "FIRE_SHOT", "NET_SHOT"
          ballista.attackTypeDuration = duration -- Number of turns or specific duration
          return true
      end
      ```
    - `minionFunctions.lua` would then need to check `ballista.attackType` when the Ballista performs an attack to apply the modified behavior.

### 2.5. Key Files
- **`minion.lua`:** Defines the `BALLISTA` minion type and its specific properties like `ammo`, `maxAmmo`, `needsReload`.
- **`minionManager.lua`:** Contains functions to manage Ballistas, such as `reloadBallista` and potentially `modifyBallistaAttack`.
- **`gameplay/minionFunctions.lua`:** Handles the Ballista's turn logic, including consuming ammo, checking `needsReload`, and executing attacks (which may be modified).
- **`skill_definitions.lua`:** Defines all Ballista Master skills, including "Summon Ballista," "Reload Ballista," repair skills, and various modification/buff skills.
- **`job_definitions.lua`:** Lists the skills available to the Ballista Master at different levels.
- **UI Files (e.g., `combatUI.lua`, `partyPanel.lua`):** Need updates to display Ballista ammo, "Needs Reload" status, and any other relevant buffs or debuffs on the minion.

## 3. UI Changes

### 3.1. Artificer (Dungeon View)
- **Trap Selector:** A new UI element (likely a list or series of buttons) appears when trap-throwing mode is active, showing available traps.
- **Targeting Feedback:** Visual indication of the currently targeted enemy (e.g., highlight, reticle).
- **Trap Throwing Hotkey:** A hotkey (e.g., 'T') to toggle trap-throwing mode.

### 3.2. Ballista (Combat View)
- **Ammo Display:** The combat UI needs to show the current/max ammo for each Ballista minion (e.g., "Ammo: 2/3").
- **"Needs Reload" Status:** A clear visual indicator (e.g., text, icon) when a Ballista is out of ammo and needs reloading.
- **Buff/Debuff Icons:** Standard display for any active status effects or modifications on the Ballista.

This documentation should provide a solid starting point for understanding and further developing the Artificer and Ballista Master mechanics. 