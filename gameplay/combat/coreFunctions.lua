-- Combat Core Functions
-- Core combat flow and state management
local minionManager = require("gameplay/minionManager")
local itemSystem = require("gameplay/item")
local screenManager = require("screens/screenManager")
local partyPanel = require("screens/ui_slices/partyPanel")

local combatSystem = {}  -- Forward declaration to reference STATE values

-- Setup combatants with combat stats
local function setupCombatants(self)
    -- Setup party
    for i, character in ipairs(self.party) do
        -- Calculate derived stats if they don't exist
        if not character.attackPower then
            local charSystem = require("gameplay/character")
            character.attackPower = charSystem:calculateAttackPower(character)
            character.magicPower = charSystem:calculateMagicPower(character)
            character.defense = charSystem:calculateDefense(character)
            character.magicDefense = charSystem:calculateMagicDefense(character)
        end
        
        -- Setup status effects table
        character.status = character.status or {}
        
        -- Initialize resistances table if none exists
        character.resistances = character.resistances or {}
        
        -- Initialize immunities table if none exists
        character.immunities = character.immunities or {}
        
        -- Add resistances from equipped items
        if character.equipment then
            for slot, item in pairs(character.equipment) do
                if item and item.resistances then
                    for damageType, value in pairs(item.resistances) do
                        character.resistances[damageType] = (character.resistances[damageType] or 0) + value
                    end
                end
            end
        end
        
        -- Set active flag
        character.active = character.currentHP > 0
    end
    
    -- Setup all enemies
    for i, enemy in ipairs(self.enemies) do
        if not enemy.name then
            enemy.name = "Monster #" .. enemy.id
        end
        
        if not enemy.maxHP then
            enemy.maxHP = enemy.stats.hp
            enemy.currentHP = enemy.maxHP
        end
        
        if not enemy.attackPower then
            enemy.attackPower = enemy.stats.attack
            enemy.defense = enemy.stats.defense
        end
        
        -- Add magic attack power if defined
        if enemy.stats.magicAttack then
            enemy.magicAttackPower = enemy.stats.magicAttack
        end
        
        -- Setup enemy status effects
        enemy.status = enemy.status or {}
        
        -- Ensure resistances exist
        enemy.resistances = enemy.resistances or {}
        
        -- Ensure immunities exist
        enemy.immunities = enemy.immunities or {}
        
        -- Set enemy as active
        enemy.active = true
    end
    
    -- Setup all minions
    for charIndex, charMinions in pairs(self.minions) do
        for minionIndex, minion in pairs(charMinions) do
            -- Set up base stats if not already present
            if not minion.maxHP then
                minion.maxHP = minion.hp
                minion.currentHP = minion.maxHP
            end
            
            -- Setup minion status effects
            minion.status = minion.status or {}
            
            -- Initialize resistances
            minion.resistances = minion.resistances or {}
            
            -- Initialize immunities
            minion.immunities = minion.immunities or {}
            
            -- Set minion as active
            minion.active = minion.currentHP > 0
        end
    end
end

-- Determine turn order
local function determineTurnOrder(self)
    self.turnOrder = {}
    
    -- Add party members to turn order
    for i, character in ipairs(self.party) do
        if character.active then
            table.insert(self.turnOrder, {
                type = "player",
                index = i,
                speed = character.attributes.DEX or 10
            })
            
            -- Add active minions for this character
            local charMinions = minionManager:getActiveMinions(character)
            if charMinions and #charMinions > 0 then
                if GAME.debug then
                    print("Found " .. #charMinions .. " active minions for " .. character.name)
                end
                
                for j, minion in ipairs(charMinions) do
                    -- Only add minions that take actions (not passive spirits)
                    if minion.takesActions then
                        table.insert(self.turnOrder, {
                            type = "minion",
                            owner = i, -- Reference to the owner's index in party
                            index = j, -- Index in character's minion array
                            speed = minion.speed or 8
                        })
                        
                        -- Store minion reference in combat.minions
                        if not self.minions[i] then 
                            self.minions[i] = {}
                        end
                        self.minions[i][j] = minion
                        
                        if GAME.debug then
                            print("Added minion to turn order: " .. minion.name)
                        end
                    end
                end
            end
            
            -- Also check the local combat minions list for this character
            if self.minions[i] then
                for j, minion in pairs(self.minions[i]) do
                    -- Skip if already processed from minionManager
                    if not minion.processed then
                        if minion.takesActions and minion.active then
                            table.insert(self.turnOrder, {
                                type = "minion",
                                owner = i, -- Reference to the owner's index in party
                                index = j, -- Index in combat's minion array
                                speed = minion.speed or 8
                            })
                            
                            if GAME.debug then
                                print("Added combat-local minion to turn order: " .. minion.name)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Add all enemies to turn order
    for i, enemy in ipairs(self.enemies) do
        table.insert(self.turnOrder, {
            type = "enemy",
            index = i,
            speed = enemy.stats.speed or 10
        })
    end
    
    -- Sort by speed
    table.sort(self.turnOrder, function(a, b)
        return a.speed > b.speed
    end)
    
    if GAME.debug then
        print("Turn order determined with " .. #self.turnOrder .. " entries")
    end
end

-- Update combat state
local function update(self, dt)
    -- Skip all updates if in victory or defeat state - only handle drawing
    if self.state == combatSystem.STATE.VICTORY or self.state == combatSystem.STATE.DEFEAT then
        return
    end

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
            
            -- Normal turn progression
            self:nextTurn()
        end
        return
    end
    
    -- Check for inactive character on their turn
    if self.state == combatSystem.STATE.PLAYER_TURN and 
       (self.currentCharacter < 1 or 
        self.currentCharacter > #self.party or 
        not self.party[self.currentCharacter].active) then
        self:nextTurn()
        return
    end
    
    -- Enemy turn processing            
    if self.state == combatSystem.STATE.ENEMY_TURN then       
        if self.enemyTurnDelay == nil then
            -- Initialize enemy turns - set the active enemy index to the first enemy
            self.activeEnemyIndex = 1
            self.enemyTurnDelay = 1.0  -- Initial delay before first enemy acts
            
            -- Debug output to check enemy state
            if GAME.debug then
                print("Starting enemy turns with " .. #self.enemies .. " enemies")
                for i, enemy in ipairs(self.enemies) do
                    print("Enemy " .. i .. ": " .. enemy.name .. " (active: " .. tostring(enemy.active) .. ", HP: " .. enemy.currentHP .. "/" .. enemy.maxHP .. ")")
                end
            end
            
            -- Check if ANY enemies are active
            local anyActive = false
            for _, enemy in ipairs(self.enemies) do
                if enemy.active then
                    anyActive = true
                    break
                end
            end
            
            -- If no active enemies at all, go to next turn
            if not anyActive then
                print("No active enemies at start of enemy turn, skipping to next turn")
                self:addLog("No active enemies remaining", {0.7, 0.7, 0.7})
                self.enemyTurnDelay = nil
                self:nextTurn()
                return
            end
            
            -- Find the first active enemy
            while self.activeEnemyIndex <= #self.enemies and not self.enemies[self.activeEnemyIndex].active do
                self.activeEnemyIndex = self.activeEnemyIndex + 1
            end
            
            -- If no active enemies found in sequence, go to next turn
            if self.activeEnemyIndex > #self.enemies then
                print("Reached end of enemy list without finding active enemy")
                self:addLog("No active enemies to take turns", {0.7, 0.7, 0.7})
                self.enemyTurnDelay = nil
                self:nextTurn()
                return
            end
        end
        
        self.enemyTurnDelay = self.enemyTurnDelay - dt
        
        if self.enemyTurnDelay and self.enemyTurnDelay <= 0 then
            -- Debug
            print("Enemy turn timer expired, executing enemy turn for index " .. self.activeEnemyIndex)
            
            -- Execute current enemy's turn
            self:executeEnemyTurn()
            
            -- Find the next active enemy
            local foundNextEnemy = false
            while self.activeEnemyIndex <= #self.enemies do
                if self.enemies[self.activeEnemyIndex].active then
                    foundNextEnemy = true
                    break
                end
                self.activeEnemyIndex = self.activeEnemyIndex + 1
            end
            
            -- Check if we need to move to the next enemy or turn
            if not foundNextEnemy or self.activeEnemyIndex > #self.enemies then
                -- We've completed all enemy turns
                print("All enemies have taken their turns, transitioning to next turn state")
                self.enemyTurnDelay = nil
                self:nextTurn() -- Go to player turn
            else
                -- More enemies to process, set a delay before next enemy acts
                self.enemyTurnDelay = 0.7 -- Delay between enemy actions
                print("Moving to next enemy turn: " .. self.activeEnemyIndex)
            end
        end
    end
    
    -- Add new minion turn handling
    if self.state == combatSystem.STATE.MINION_TURN then
        if self.minionTurnDelay == nil then
            -- Initialize minion turns
            self.minionTurnDelay = 0.8
        end
        
        self.minionTurnDelay = self.minionTurnDelay - dt
        
        if self.minionTurnDelay and self.minionTurnDelay <= 0 then
            -- Execute current minion's turn
            self:executeMinionTurn()
            
            -- If the minion's action resulted in victory or defeat, the state will be set.
            -- The main update loop checks for this at its beginning.
            -- We use self:isOver() here to prevent scheduling another turn if combat ended.
            if self:isOver() then
                 self.minionTurnDelay = nil -- Prevent re-entry if somehow update is called again before state fully processes
                 return -- Combat is over, exit this block
            end
            
            -- If combat is not over, set a short delay then allow nextTurn() to be called
            -- via the turnEndDelay mechanism. This correctly determines the next actor.
            self.turnEndDelay = 0.5 -- Delay before processing nextTurn logic
            self.minionTurnDelay = nil -- Reset for the next potential sequence of minion turns
        end
    end
end

-- Move to next character's turn
local function nextTurn(self)
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
    nextTurn = nextTurn,
    partyDefeated = partyDefeated,
    transitionToEnemyTurn = transitionToEnemyTurn,
    calculateVictoryRewards = calculateVictoryRewards,
    getStateName = getStateName,
    getStateProgressionInfo = getStateProgressionInfo,
    isOver = isOver,
    isVictory = isVictory,
    getLoot = getLoot
}