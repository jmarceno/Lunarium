-- Combat Core Functions
-- Core combat flow and state management
local minionManager = require("gameplay/minionManager")
local itemSystem = require("gameplay/item")
local screenManager = require("screens/screenManager")
local partyPanel = require("screens/ui_slices/partyPanel")
local statusEffects = require("gameplay/statusEffects")
local trapSystem = require("gameplay/trapSystem")
local assetManager = require("assets/assetManager")
local characterSystem = require("gameplay/character")
local turnManager = require("gameplay/combat/turnManager")

local combatSystem = {}  -- Forward declaration to reference STATE values

-- Setup combatants with combat stats
local function setupCombatants(self)
    -- Ensure party is setup
    if not self.party then
        error("No party defined for combat")
        return false
    end
    
    -- Ensure enemies are setup
    if not self.enemies or #self.enemies == 0 then
        error("No enemies defined for combat")
        return false
    end
    
    -- Initialize HP and active status for all enemies
    for _, enemyInstance in ipairs(self.enemies) do
        if enemyInstance then
            if enemyInstance.maxHP == nil then
                -- Fallback if maxHP is somehow not defined (should come from monster data)
                enemyInstance.maxHP = 100 -- Default or log error
                if GAME.debug then
                    print("Warning: Enemy " .. (enemyInstance.name or "Unknown") .. " missing maxHP, defaulted to 100.")
                end
            end
            enemyInstance.currentHP = enemyInstance.maxHP
            enemyInstance.active = true -- Ensure enemy is active at the start
            
            -- Initialize status effects table if it doesn't exist
            if not enemyInstance.status then
                enemyInstance.status = {}
            end
        else
            if GAME.debug then
                print("Warning: Found a nil entry in self.enemies during setupCombatants.")
            end
        end
    end
    
    -- Initialize minions
    self.minions = {}
    self.minionsTurnTaken = {}
    
    -- Import any existing minions
    self:importExistingMinions()
    
    -- Initialize turn tracking
    for i, character in ipairs(self.party) do
        -- Set all characters as active initially
        character.active = true
        
        -- Initialize spellQueue for party members
        character.spellQueue = {}
    end
    
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
    
    -- Initialize the new turn manager
    self.turnManager = turnManager
    self.turnManager:init(self)
    
    -- Add initial combat log entry
    if self.isAmbush then
        self:addLog("You've been ambushed! Enemies get the first turn!", {1, 0.5, 0.5})
    else
        local enemiesText = #self.enemies > 1 and "enemies" or "enemy"
        self:addLog("Combat begins against " .. #self.enemies .. " " .. enemiesText .. "!", {1, 1, 0.7})
    end
    
    return true
end

-- Determine turn order (now handled by turn manager)
local function determineTurnOrder(self)
    -- This function is now handled by the turn manager
    -- Keep it for compatibility but it does nothing
    if GAME.debug then
        print("Turn order is now managed by the turn manager")
    end
end

-- Update combat state
local function update(self, dt)
    -- Handle victory waiting for input
    if self.victoryDelayed then
        -- Check for any key press to proceed to victory
        local keyPressed = love.keyboard.isDown("space") or love.keyboard.isDown("return") or 
                         love.keyboard.isDown("z") or love.keyboard.isDown("x")
        
        if keyPressed then
            self.victoryDelayed = false
            self.showVictoryPrompt = false
            self:victory()
            return
        end
        return
    end
    
    -- Skip other updates if in victory or defeat state - only handle drawing
    if self.state == combatSystem.STATE.VICTORY or self.state == combatSystem.STATE.DEFEAT then
        return
    end
    
    -- Always update completed spells (for visual effects)
    self:executeCompletedSpells(dt)

    -- Handle animation delay
    if self.animationDelay and self.animationDelay > 0 then
        self.animationDelay = self.animationDelay - dt
        return
    end
    
    -- Handle turn end delay
    if self.turnEndDelay and self.turnEndDelay > 0 then
        self.turnEndDelay = self.turnEndDelay - dt
        if self.turnEndDelay <= 0 then
            -- Check if we have a pending victory (from minion killing last enemy)
            if self.pendingVictory then
                self:victory()
                return
            end
            
            -- If this was a player turn that just ended, notify the turn manager
            if self.state == combatSystem.STATE.PLAYER_TURN and self.turnManager then
                self.turnManager:playerTurnCompleted()
            end
            
            -- The turn manager will handle turn progression
            self.turnEndDelay = nil
        end
        return
    end
    
    -- Update the turn manager (this handles action meter ticking and turn queue processing)
    if self.turnManager then
        self.turnManager:update(dt)
    end
    
    -- Update spell queue progression with new time-based system
    self:updateSpellQueueTime(dt)
end

-- New function to update spell queue based on time instead of turns
local function updateSpellQueueTime(self, dt)
    -- Don't progress spell queue if player turn is active (everything pauses)
    if self.turnManager and self.turnManager.isPlayerTurnActive then
        return
    end
    
    for i = #self.spellQueue, 1, -1 do
        local spell = self.spellQueue[i]
        if spell.caster.active and not spell.completionStarted then
            -- Decrease remaining cast time in seconds (spell queue now uses seconds instead of turns)
            spell.castingTimeRemaining = spell.castingTimeRemaining - dt
            
            -- Update progress for display
            spell.progress = spell.totalCastingTime - spell.castingTimeRemaining
            
            -- Check if the spell is complete
            if spell.castingTimeRemaining <= 0 then
                spell.isComplete = true
                spell.completionStarted = true
                spell.completionTimer = 0.5  -- Visual effect duration after cast
                spell.flashTimer = 0
                spell.flashState = true
                
                -- Check if target is still valid
                local isValidTarget = true
                if spell.skill.target == "single_enemy" or spell.skill.target == "single_ally" then
                    if not spell.target or not spell.target.active then
                        isValidTarget = false
                        self:addLog(spell.skill.name .. " failed: target is no longer available", {1, 0.5, 0.5})
                    end
                end
                
                -- Execute the spell immediately if target is valid
                if isValidTarget then
                    self:executeSkill(spell.caster, spell.skill, spell.target, true)
                    self:addLog(spell.caster.name .. " finishes casting " .. spell.skill.name .. "!", {0.2, 1, 0.2})
                end
                
                -- Clear casting flag on caster
                spell.caster.isCasting = false
            end
        elseif not spell.caster.active then
            -- Caster is inactive (dead or incapacitated), remove the spell
            self:cancelSpell(spell.caster, i)
        end
    end
end

-- Add to spell queue
local function addToSpellQueue(self, caster, skill, target)
    -- Create a new spell queue entry
    local entry = {
        caster = caster,
        skill = skill,
        target = target,
        progress = 0,
        totalCastingTime = skill.castingTime,
        castingTimeRemaining = skill.castingTime, -- Now in seconds instead of turns
        isCasting = true  -- Flag to indicate entity is currently casting
    }
    
    -- Add to the queue
    table.insert(self.spellQueue, entry)
    
    -- Mark caster as casting
    caster.isCasting = true
    
    -- Add log entry for spell casting
    local targetName = (target and target.name) or "area"
    self:addLog(caster.name .. " begins casting " .. skill.name .. " on " .. targetName .. " (" .. skill.castingTime .. " seconds)", {0.5, 0.8, 1})
    
    return entry
end

-- Track spells that are in the completion animation
local spellCompletionEffects = {}

-- Handle visual effects for completed spells
local function executeCompletedSpells(self)
    -- Update completion effects for visual feedback
    for i = #self.spellQueue, 1, -1 do
        local spell = self.spellQueue[i]
        
        if spell.completionStarted then
            -- Update flash timer for visual effect
            spell.flashTimer = (spell.flashTimer or 0) + 0.1
            if spell.flashTimer >= 0.1 then
                spell.flashTimer = 0
                spell.flashState = not spell.flashState
            end
            
            -- Decrease the completion timer - use larger decrement to ensure it finishes
            spell.completionTimer = spell.completionTimer - 0.05  -- Use larger value for faster removal
            
            -- Remove spell from queue after visual effect completes
            if spell.completionTimer <= 0 then
                -- Ensure we remove it from the queue
                table.remove(self.spellQueue, i)
            end
        end
    end
end

-- Reset spell queue when combat ends
local function resetSpellQueue(self)
    -- Clear all casting flags
    for _, spell in ipairs(self.spellQueue) do
        if spell.caster and spell.caster.isCasting then
            spell.caster.isCasting = false
        end
    end
    
    -- Clear the queue
    self.spellQueue = {}
end

-- Modify spell cast time for a specific spell in the queue
local function modifySpellCastTime(self, caster, skillName, modificationAmount)
    for i, spell in ipairs(self.spellQueue) do
        -- Find the matching spell by caster and skill name
        if spell.caster == caster and spell.skill.name == skillName then
            -- Apply modification
            spell.castingTimeRemaining = math.max(1, spell.castingTimeRemaining + modificationAmount)
            
            -- Add log entry
            if modificationAmount < 0 then
                self:addLog(caster.name .. "'s casting of " .. skillName .. " is accelerated!", {0.2, 1, 0.2})
            else
                self:addLog(caster.name .. "'s casting of " .. skillName .. " is slowed!", {1, 0.5, 0.5})
            end
            
            return true
        end
    end
    
    return false
end

-- Cancel a spell in the queue
local function cancelSpell(self, caster, spellIndex)
    if self.spellQueue[spellIndex] and self.spellQueue[spellIndex].caster == caster then
        -- Add log entry
        self:addLog(caster.name .. "'s casting of " .. self.spellQueue[spellIndex].skill.name .. " was interrupted!", {1, 0.5, 0.5})
        
        -- Clear casting flag
        caster.isCasting = false
        
        -- Remove from queue
        table.remove(self.spellQueue, spellIndex)
        return true
    end
    
    return false
end

-- Check if an entity is currently casting a spell
local function isEntityCasting(self, entity)
    for _, spell in ipairs(self.spellQueue) do
        if spell.caster == entity and spell.isCasting then
            return true, spell
        end
    end
    
    return false, nil
end

local function nextTurn(self)
    -- Process status effects for the current character/entity at the end of their turn
    local statusEffects = require("gameplay/statusEffects")
    
    -- Progress the spell queue at the end of each turn
    self:progressSpellQueue()
    
    -- Execute any completed spells
    self:executeCompletedSpells()

    -- Process status effects for the current player if applicable
    if self.state == combatSystem.STATE.PLAYER_TURN and 
       self.currentCharacter >= 1 and 
       self.currentCharacter <= #self.party then
        local character = self.party[self.currentCharacter]
        local expired = statusEffects:processTurnEnd(character)
        
        -- Display messages about expired effects
        for _, effect in ipairs(expired) do
            self:addLog(effect.message, effect.color)
        end
        
        -- Check for status effect spreading after player turn
        if character.active and character.status then
            -- Collect active party members for possible spread
            local partyMembers = {}
            for _, member in ipairs(self.party) do
                if member.active then
                    table.insert(partyMembers, member)
                end
            end
            
            statusEffects:processEffectSpreading(partyMembers, "party", self)
        end
    end
    
    -- Process status effects for the current minion if applicable
    if self.state == combatSystem.STATE.MINION_TURN and self.activeMinion then
        local charIndex = self.activeMinion.charIndex
        local minionIndex = self.activeMinion.minionIndex
        local minion = self.minions[charIndex][minionIndex]
        
        local expired = statusEffects:processTurnEnd(minion)
        
        -- Display messages about expired effects
        for _, effect in ipairs(expired) do
            self:addLog(effect.message, effect.color)
        end
        
        -- Check for status effect spreading after minion turn
        if minion.active and minion.status then
            -- Collect active minions for possible spread
            local activeMinions = {}
            for _, minionGroup in pairs(self.minions) do
                for _, m in pairs(minionGroup) do
                    if m.active then
                        table.insert(activeMinions, m)
                    end
                end
            end
            
            statusEffects:processEffectSpreading(activeMinions, "minion", self)
        end
    end

    -- When transitioning from enemy state to player state, process all enemy status effects
    if self.state == combatSystem.STATE.ENEMY_TURN then
        for i, enemy in ipairs(self.enemies) do
            if enemy.active then
                local expired = statusEffects:processTurnEnd(enemy)
                -- Display messages about expired effects
                for _, effect in ipairs(expired) do
                    self:addLog(effect.message, effect.color)
                end
                
                -- Check if this is the active enemy that just took its turn
                if i == self.activeEnemyIndex then
                    -- Check for status effect spreading after enemy turn
                    if enemy.status then
                        -- Collect active enemies for possible spread
                        local activeEnemies = {}
                        for _, e in ipairs(self.enemies) do
                            if e.active then
                                table.insert(activeEnemies, e)
                            end
                        end
                        
                        statusEffects:processEffectSpreading(activeEnemies, "enemy", self)
                    end
                end
            end
        end
    end
    
    -- Mark the current character's turn as taken if applicable
    if self.state == combatSystem.STATE.PLAYER_TURN and 
       self.currentCharacter >= 1 and 
       self.currentCharacter <= #self.party then
        self.charactersTurnTaken[self.currentCharacter] = true
    end
    
    -- If we're in minion turn, mark the current minion's turn as taken
    if self.state == combatSystem.STATE.MINION_TURN and self.activeMinion then
        local charIndex = self.activeMinion.charIndex
        local minionIndex = self.activeMinion.minionIndex
        
        if not self.minionsTurnTaken[charIndex] then
            self.minionsTurnTaken[charIndex] = {}
        end
        
        self.minionsTurnTaken[charIndex][minionIndex] = true
    end
    
    -- Track which state we're transitioning from
    local previousState = self.state
    
    -- Debug output
    if GAME.debug then
        print("Current state: " .. self:getStateName(previousState))
        print("Transition progression: " .. self:getStateProgressionInfo())
    end
    
    -- Simple state machine approach - force progression through states in order
    if previousState == combatSystem.STATE.PLAYER_TURN then
        -- If we're coming from player turn, check if any players have untaken turns
        local foundNextPlayer = false
        for i = 1, #self.party do
            local idx = (self.currentCharacter + i - 1) % #self.party + 1
            
            -- Skip player's turn if they are casting a spell
            local isCasting, castingSpell = self:isEntityCasting(self.party[idx])
            if isCasting then
                self:addLog(self.party[idx].name .. " continues casting " .. castingSpell.skill.name .. "...", {0.5, 0.8, 1})
                -- Skip this player
                if GAME.debug then
                    print("Skipping player turn for " .. self.party[idx].name .. " due to casting")
                end
            else
                if self.party[idx].active and not self.charactersTurnTaken[idx] then
                    -- Found an active player with an untaken turn
                    self.currentCharacter = idx
                    foundNextPlayer = true
                    
                    -- Stay in player turn state
                    self.state = combatSystem.STATE.PLAYER_TURN
                    
                    -- Update the party panel to highlight the active character
                    partyPanel:setActiveCharacter(self.currentCharacter)
                    
                    -- Reset selection state
                    self:resetSelectionUI()
                    
                    -- Make sure action buttons are visible for the new turn
                    self:showActionButtons()
                    
                    -- Log new character turn
                    self:addLog(self.party[self.currentCharacter].name .. "'s turn begins", {0.5, 0.5, 1})
                    
                    break
                end
            end
        end
        
        -- If no more players have untaken turns, check for minions
        if not foundNextPlayer then
            -- Check if any active minions with untaken turns exist
            local activeMinion = self:findActiveUntakenMinion()
            
            if activeMinion then
                -- Found an active minion with an untaken turn
                self.activeMinion = activeMinion
                self.state = combatSystem.STATE.MINION_TURN
                
                -- Clear party panel highlight
                partyPanel:setActiveCharacter(nil)
                
                -- Initialize minion turn delay
                self.minionTurnDelay = 0.8
                
                -- Log minion turn
                local minion = self.minions[activeMinion.charIndex][activeMinion.minionIndex]
                self:addLog(minion.name .. "'s turn begins", {0.5, 0.7, 1})
            else
                -- No more players or minions, move to enemy turn
                self:transitionToEnemyTurn()
            end
        end
    elseif previousState == combatSystem.STATE.MINION_TURN then
        -- Check if any more minions have untaken turns
        local activeMinion = self:findActiveUntakenMinion()
        
        if activeMinion then
            -- Found another active minion with an untaken turn
            self.activeMinion = activeMinion
            self.state = combatSystem.STATE.MINION_TURN
            
            -- Initialize minion turn delay
            self.minionTurnDelay = 0.8
            
            -- Log minion turn
            local minion = self.minions[activeMinion.charIndex][activeMinion.minionIndex]
            self:addLog(minion.name .. "'s turn begins", {0.5, 0.7, 1})
        else
            -- No more minions, move to enemy turn
            self:transitionToEnemyTurn()
        end
    elseif previousState == combatSystem.STATE.ENEMY_TURN then
        -- Coming from enemy turn - start a new round
        
        -- Reset player turns for the next round
        for i = 1, #self.party do
            self.charactersTurnTaken[i] = false
        end
        
        -- Reset minion turns for the next round
        self.minionsTurnTaken = {}
        
        -- Start with first active character
        local foundNextPlayer = false
        for i = 1, #self.party do
            if self.party[i].active then
                self.currentCharacter = i
                foundNextPlayer = true
                
                -- Update the party panel to highlight the active character
                partyPanel:setActiveCharacter(self.currentCharacter)
                
                -- Switch to player turn state
                self.state = combatSystem.STATE.PLAYER_TURN
                
                -- Reset selection state
                self:resetSelectionUI()
                
                -- Make sure action buttons are visible for the new turn
                self:showActionButtons()
                
                -- Log new round
                self:addLog("Round " .. self.currentTurn .. " begins", {1, 1, 0.5})
                self.currentTurn = self.currentTurn + 1
                
                -- Log new character turn
                self:addLog(self.party[self.currentCharacter].name .. "'s turn begins", {0.5, 0.5, 1})
                
                break
            end
        end
        
        -- If no active players, it's game over
        if not foundNextPlayer then
            self:partyDefeated()
        end
    end
    
    -- Debug state transition
    if GAME.debug then
        print("State changed: " .. self:getStateName(previousState) .. " -> " .. self:getStateName(self.state))
    end
end

-- Handle party defeat
local function partyDefeated(self)
    self:addLog("The party has been defeated!", {1, 0, 0})
    
    -- Set defeat state
    self.state = combatSystem.STATE.DEFEAT
    
    -- Reset the combat flag
    GAME.inCombat = false
    
    -- Reset party panel
    partyPanel:setCombatMode(false, nil)
    partyPanel:setActiveCharacter(nil)
    
    -- Create continue button
    self.elements.continueButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 + 100,
        200, 40, "Continue",
        function() return true end
    )
    self.elements.continueButton.visible = true
    
    -- Hide combat UI elements
    self:hideAllUI()
end

-- Transition to enemy turn
local function transitionToEnemyTurn(self)
    -- Check if all party members are inactive (defeated)
    local allInactive = true
    for _, character in ipairs(self.party) do
        if character.active then
            allInactive = false
            break
        end
    end
    
    if allInactive then
        -- All party members are defeated
        self:partyDefeated()
        return
    end
    
    -- Check if any enemies are active
    local anyActiveEnemies = false
    for _, enemy in ipairs(self.enemies) do
        -- Force repair any nil active flags
        if enemy.active == nil then
            enemy.active = (enemy.currentHP or 0) > 0
        end
        
        if enemy.active then
            anyActiveEnemies = true
            break
        end
    end
    
    if not anyActiveEnemies then
        -- No active enemies, trigger victory
        self:victory()
        return
    end
    
    -- Set enemy turn state
    self.state = combatSystem.STATE.ENEMY_TURN
    
    -- Reset enemy turn delay to force initialization
    self.enemyTurnDelay = nil
    
    -- Log start of enemy turns
    self:addLog("Enemy turn begins", {1, 0.5, 0.5})
end

-- Calculate victory rewards
local function calculateVictoryRewards(self)
    -- Skip if rewards were already calculated
    if self.rewardsCalculated then
        if GAME.debug then
            print("Rewards already calculated, skipping")
        end
        return
    end
    
    -- Mark that rewards have been calculated
    self.rewardsCalculated = true
    
    -- Initialize rewards structure
    self.rewards = {
        exp = 0,
        loot = {}
    }
    
    -- Sum up experience and generate loot from all enemies
    for _, enemy in ipairs(self.enemies) do
        -- Add experience
        self.rewards.exp = self.rewards.exp + (enemy.stats.level * 100)
        
        -- Generate loot for each enemy and add to the total
        local enemyLoot = itemSystem:generateRandomLoot(enemy.stats.level)
        for _, item in ipairs(enemyLoot) do
            table.insert(self.rewards.loot, item)
        end
    end
    
    if GAME.debug then
        print("Victory rewards calculated:")
        print("  Experience: " .. self.rewards.exp)
        print("  Loot items: " .. #self.rewards.loot)
    end
end

-- Get state name for debugging
local function getStateName(self, stateValue)
    for name, value in pairs(combatSystem.STATE) do
        if value == stateValue then
            return name
        end
    end
    return "UNKNOWN_STATE"
end

-- Get progression info for debugging
local function getStateProgressionInfo(self)
    -- Player stats
    local activePlayers = 0
    local playersTaken = 0
    for i=1, #self.party do
        if self.party[i].active then
            activePlayers = activePlayers + 1
            if self.charactersTurnTaken[i] then
                playersTaken = playersTaken + 1
            end
        end
    end
    
    -- Minion stats
    local activeMinions = 0
    local minionsTaken = 0
    for charIndex, minions in pairs(self.minions) do
        for minionIndex, minion in pairs(minions) do
            if minion.active and minion.takesActions then
                activeMinions = activeMinions + 1
                if self.minionsTurnTaken[charIndex] and self.minionsTurnTaken[charIndex][minionIndex] then
                    minionsTaken = minionsTaken + 1
                end
            end
        end
    end
    
    -- Enemy stats
    local activeEnemies = 0
    for _, enemy in ipairs(self.enemies) do
        if enemy.active then
            activeEnemies = activeEnemies + 1
        end
    end
    
    return "Players: " .. playersTaken .. "/" .. activePlayers .. 
           " | Minions: " .. minionsTaken .. "/" .. activeMinions .. 
           " | Active enemies: " .. activeEnemies
end

-- Check if combat is over
local function isOver(self)
    return self.state == combatSystem.STATE.VICTORY or 
           self.state == combatSystem.STATE.DEFEAT
end

-- Check if combat ended in victory
local function isVictory(self)
    return self.state == combatSystem.STATE.VICTORY
end

-- Get combat rewards
local function getLoot(self)
    if self.state == combatSystem.STATE.VICTORY and self.rewards then
        return self.rewards.loot
    end
    return nil
end

combatSystem.STATE = {INIT = 1, PLAYER_TURN = 2, ENEMY_TURN = 3, MINION_TURN = 4, VICTORY = 5, DEFEAT = 6}

return {
    setupCombatants = setupCombatants,
    determineTurnOrder = determineTurnOrder,
    update = update,
    updateSpellQueueTime = updateSpellQueueTime,
    nextTurn = nextTurn,
    partyDefeated = partyDefeated,
    transitionToEnemyTurn = transitionToEnemyTurn,
    calculateVictoryRewards = calculateVictoryRewards,
    getStateName = getStateName,
    getStateProgressionInfo = getStateProgressionInfo,
    isOver = isOver,
    isVictory = isVictory,
    getLoot = getLoot,
    
    -- Spell queue management functions
    addToSpellQueue = addToSpellQueue,
    progressSpellQueue = progressSpellQueue,
    executeCompletedSpells = executeCompletedSpells,
    resetSpellQueue = resetSpellQueue,
    modifySpellCastTime = modifySpellCastTime,
    cancelSpell = cancelSpell,
    isEntityCasting = isEntityCasting
}