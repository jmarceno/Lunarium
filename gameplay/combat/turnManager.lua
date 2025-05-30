-- Turn Manager
-- Handles the new action meter based turn system
local statusEffects = require("gameplay/statusEffects")

local turnManager = {}

-- Constants for the action meter system
turnManager.MAX_ACTION_METER_TICKS = 20 -- Used for calculation, but meters now progress smoothly
turnManager.TICK_INTERVAL = 0.5 -- 500ms - used for target time calculation
turnManager.INITIAL_RANDOM_RANGE = {1, 5} -- Random ticks to add at start

-- Combat state constants (to avoid circular dependency)
local COMBAT_STATE = {
    INIT = 1,
    PLAYER_TURN = 2,
    ENEMY_TURN = 3,
    MINION_TURN = 4,
    VICTORY = 5,
    DEFEAT = 6
}

-- Initialize the turn manager for a combat
function turnManager:init(combat)
    self.combat = combat
    self.turnQueue = {}
    self.isPlayerTurnActive = false
    self.recentlyActedEntities = {} -- Track entities that recently acted to prevent consecutive turns
    self.lastActorId = nil -- Track the last entity that took a turn
    self.pendingLastActorClear = false -- Flag to clear last actor when animation delay completes
    
    -- Initialize action meters for all entities
    self:initializeActionMeters()
end

-- Generate unique ID for an entity to track them
function turnManager:getEntityId(entity, entityType, index, minionIndex)
    if entityType == "minion" then
        return entityType .. "_" .. (index or "0") .. "_" .. (minionIndex or "0")
    else
        return entityType .. "_" .. (index or "0")
    end
end

-- Check if an entity can be added to turn queue (not recently acted)
function turnManager:canEntityAct(entity, entityType, index, minionIndex)
    local entityId = self:getEntityId(entity, entityType, index, minionIndex)
    
    -- If this entity was the last actor, prevent consecutive turns
    if self.lastActorId == entityId then
        if GAME and GAME.debug then
            print("Preventing consecutive turn for " .. (entity.name or "Unknown") .. " (ID: " .. entityId .. ")")
        end
        return false
    end
    
    return true
end

-- Mark an entity as having recently acted
function turnManager:markEntityActed(entity, entityType, index, minionIndex)
    local entityId = self:getEntityId(entity, entityType, index, minionIndex)
    self.lastActorId = entityId
    
    if GAME and GAME.debug then
        print("Marked entity as acted: " .. (entity.name or "Unknown") .. " (ID: " .. entityId .. ")")
    end
    
    -- Clear the last actor after some time to allow the entity to act again later
    -- This will be cleared when any other entity acts
end

-- Clear the recently acted status when any entity takes a turn
function turnManager:clearLastActor()
    if GAME and GAME.debug and self.lastActorId then
        print("Clearing last actor: " .. self.lastActorId)
    end
    self.lastActorId = nil
end

-- Initialize action meters for all entities
function turnManager:initializeActionMeters()
    -- Initialize party members
    for i, character in ipairs(self.combat.party) do
        if character.active then
            character.actionMeter = character.actionMeter or 0
            character.speed = character.speed or character.attributes.DEX or 10
            
            -- Set initial action meter value based on ambush status
            -- Convert from old tick-based system to time-based system
            if self.combat.isAmbush then
                character.actionMeter = 0 -- Start at 0 if ambushed
            else
                -- Normal start with random initial value
                local randomTicks = math.random(self.INITIAL_RANDOM_RANGE[1], self.INITIAL_RANDOM_RANGE[2])
                -- Convert ticks to time: (speed + randomTicks) * TICK_INTERVAL
                character.actionMeter = (character.speed + randomTicks) * self.TICK_INTERVAL
            end
        end
    end
    
    -- Initialize enemies
    for i, enemy in ipairs(self.combat.enemies) do
        if enemy.active then
            enemy.actionMeter = enemy.actionMeter or 0
            enemy.speed = enemy.speed or enemy.stats.speed or 10
            
            -- Enemies always get normal random start (even in ambush they get first turn)
            local randomTicks = math.random(self.INITIAL_RANDOM_RANGE[1], self.INITIAL_RANDOM_RANGE[2])
            -- Convert ticks to time: (speed + randomTicks) * TICK_INTERVAL
            enemy.actionMeter = (enemy.speed + randomTicks) * self.TICK_INTERVAL
        end
    end
    
    -- Initialize minions
    if self.combat.minions then
        for ownerIndex, minionList in pairs(self.combat.minions) do
            for minionIndex, minion in pairs(minionList) do
                if minion.active and minion.takesActions then
                    minion.actionMeter = minion.actionMeter or 0
                    minion.speed = minion.speed or 8
                    
                    -- Minions follow same rules as their owner for ambush
                    if self.combat.isAmbush then
                        minion.actionMeter = 0
                    else
                        local randomTicks = math.random(self.INITIAL_RANDOM_RANGE[1], self.INITIAL_RANDOM_RANGE[2])
                        -- Convert ticks to time: (speed + randomTicks) * TICK_INTERVAL
                        minion.actionMeter = (minion.speed + randomTicks) * self.TICK_INTERVAL
                    end
                end
            end
        end
    end
end

-- Update the action meter system
function turnManager:update(dt)
    -- Don't tick if combat is over
    if self.combat:isOver() then
        return
    end
    
    -- Check if we should clear the last actor after enemy/minion animation delay
    if self.pendingLastActorClear and not self.combat.animationDelay then
        self:clearLastActor()
        self.pendingLastActorClear = false
    end
    
    -- Process action meter updates (now smooth using delta time)
    self:processActionMeterUpdate(dt)
    
    -- Process the turn queue if player turn is not active
    if not self.isPlayerTurnActive then
        self:processTurnQueue()
    end
end

-- Process smooth action meter updates using delta time
function turnManager:processActionMeterUpdate(dt)
    -- Don't update if player turn is active (all meters pause)
    if self.isPlayerTurnActive then
        return
    end
    
    -- Update all entities' action meters smoothly
    self:updateEntityMeters(self.combat.party, "player", dt)
    self:updateEntityMeters(self.combat.enemies, "enemy", dt)
    
    -- Update minion meters
    if self.combat.minions then
        for ownerIndex, minionList in pairs(self.combat.minions) do
            for minionIndex, minion in pairs(minionList) do
                if minion.active and minion.takesActions then
                    self:updateSingleEntityMeter(minion, "minion", ownerIndex, minionIndex, dt)
                end
            end
        end
    end
end

-- Update action meters for a list of entities
function turnManager:updateEntityMeters(entityList, entityType, dt)
    for i, entity in ipairs(entityList) do
        if entity.active then
            self:updateSingleEntityMeter(entity, entityType, i, nil, dt)
        end
    end
end

-- Update a single entity's action meter smoothly
function turnManager:updateSingleEntityMeter(entity, entityType, index, minionIndex, dt)
    -- Initialize actionMeter if it doesn't exist (for newly summoned minions)
    if not entity.actionMeter then
        -- Initialize based on speed for balanced start
        local speed = entity.speed or 10
        entity.actionMeter = math.random(1, 5) + speed
        entity.actionMeter = entity.actionMeter * self.TICK_INTERVAL -- Convert to time units
        
        if GAME and GAME.debug then
            print("Initialized actionMeter for " .. (entity.name or "entity") .. ": " .. entity.actionMeter)
        end
    end
    
    -- Skip if entity is casting an ability with castingTime > 1
    if self:isEntityCasting(entity) then
        return
    end
    
    -- Check for status effects that modify action meter
    local canUpdate = self:canEntityActionMeterTick(entity)
    if not canUpdate then
        return
    end
    
    -- Calculate the update rate based on speed
    local speedMultiplier = statusEffects:getMultiplier(entity, "speed_multiplier")
    local effectiveSpeed = (entity.speed or 10) * speedMultiplier
    
    -- Calculate update rate: faster entities update their meters faster
    -- Base rate: 1 time unit per second, modified by effective speed
    local updateRate = 1.0 + (effectiveSpeed - 10) * 0.1 -- Every 10 speed adds 0.1 to the rate
    updateRate = math.max(0.1, updateRate) -- Ensure minimum progress rate
    
    -- Update action meter smoothly
    entity.actionMeter = entity.actionMeter + (updateRate * dt)
    
    -- Calculate target time needed
    local targetTime = self:getTargetTimeForEntity(entity)
    
    -- Check if entity is ready for a turn
    if entity.actionMeter >= targetTime then
        self:addToTurnQueue(entity, entityType, index, minionIndex)
    end
end

-- Check if an entity's action meter can tick (considering status effects)
function turnManager:canEntityActionMeterTick(entity)
    -- Check for "stop" effects that prevent action meter ticking
    if statusEffects:has(entity, "STUN") then
        return false
    end
    
    -- Add other status effects that might stop action meter ticking
    -- Future status effects can be added here
    
    return true
end

-- Calculate target time needed for an entity (converted from old tick system)
function turnManager:getTargetTimeForEntity(entity)
    local baseSpeed = entity.speed or 10
    
    -- Apply speed modifiers from status effects
    local speedMultiplier = statusEffects:getMultiplier(entity, "speed_multiplier")
    local effectiveSpeed = baseSpeed * speedMultiplier
    
    -- Calculate target time based on old tick system
    -- Old: targetTicks = MAX_ACTION_METER_TICKS - effectiveSpeed, minimum 1 tick
    -- New: targetTime = targetTicks * TICK_INTERVAL
    local targetTicks = math.max(1, self.MAX_ACTION_METER_TICKS - effectiveSpeed)
    local targetTime = targetTicks * self.TICK_INTERVAL
    
    return targetTime
end

-- Calculate target ticks needed for an entity (for backwards compatibility)
function turnManager:getTargetTicksForEntity(entity)
    local targetTime = self:getTargetTimeForEntity(entity)
    return targetTime / self.TICK_INTERVAL
end

-- Check if an entity is casting (for abilities with castingTime > 1)
function turnManager:isEntityCasting(entity)
    -- Check if entity has any spells in the casting queue
    if self.combat.spellQueue then
        for _, spell in ipairs(self.combat.spellQueue) do
            if spell.caster == entity and not spell.isComplete then
                return true
            end
        end
    end
    
    return false
end

-- Add an entity to the turn queue
function turnManager:addToTurnQueue(entity, entityType, index, minionIndex)
    -- Don't add if already in queue
    for _, queueEntry in ipairs(self.turnQueue) do
        if queueEntry.entity == entity then
            return
        end
    end
    
    -- Check if entity can act (prevent consecutive turns)
    if not self:canEntityAct(entity, entityType, index, minionIndex) then
        return
    end
    
    -- Create queue entry
    local queueEntry = {
        entity = entity,
        entityType = entityType,
        index = index,
        minionIndex = minionIndex,
        speed = entity.speed or 10
    }
    
    -- Insert in queue based on priority: higher speed first, then player > minion > enemy
    local insertIndex = #self.turnQueue + 1
    for i, existingEntry in ipairs(self.turnQueue) do
        if self:shouldInsertBefore(queueEntry, existingEntry) then
            insertIndex = i
            break
        end
    end
    
    table.insert(self.turnQueue, insertIndex, queueEntry)
end

-- Determine if a queue entry should be inserted before another
function turnManager:shouldInsertBefore(newEntry, existingEntry)
    -- Higher speed goes first
    if newEntry.speed > existingEntry.speed then
        return true
    elseif newEntry.speed < existingEntry.speed then
        return false
    end
    
    -- Same speed: player > minion > enemy
    local priority = {player = 3, minion = 2, enemy = 1}
    local newPriority = priority[newEntry.entityType] or 0
    local existingPriority = priority[existingEntry.entityType] or 0
    
    return newPriority > existingPriority
end

-- Process the turn queue
function turnManager:processTurnQueue()
    if #self.turnQueue == 0 then
        return
    end
    
    -- Special case: if all entities in queue are blocked by consecutive turn prevention,
    -- we need to clear the last actor to prevent deadlock
    local allBlocked = true
    for _, entry in ipairs(self.turnQueue) do
        if self:canEntityAct(entry.entity, entry.entityType, entry.index, entry.minionIndex) then
            allBlocked = false
            break
        end
    end
    
    if allBlocked and #self.turnQueue > 0 then
        if GAME and GAME.debug then
            print("All entities in turn queue are blocked by consecutive turn prevention - clearing last actor to prevent deadlock")
        end
        -- Clear the last actor to allow progress
        self:clearLastActor()
    end
    
    -- Get the next entity to act
    local nextEntry = self.turnQueue[1]
    
    -- Check if this entity can act (after potential clearing above)
    if not self:canEntityAct(nextEntry.entity, nextEntry.entityType, nextEntry.index, nextEntry.minionIndex) then
        -- Remove from queue and try the next one
        table.remove(self.turnQueue, 1)
        return
    end
    
    -- Remove from queue
    table.remove(self.turnQueue, 1)
    
    -- Execute the turn based on entity type
    if nextEntry.entityType == "player" then
        self:executePlayerTurn(nextEntry)
    elseif nextEntry.entityType == "enemy" then
        self:executeEnemyTurn(nextEntry)
    elseif nextEntry.entityType == "minion" then
        self:executeMinionTurn(nextEntry)
    end
end

-- Execute a player turn
function turnManager:executePlayerTurn(entry)
    -- Mark this entity as having acted to prevent consecutive turns
    self:markEntityActed(entry.entity, entry.entityType, entry.index, entry.minionIndex)
    
    -- Set player turn active flag (pauses all action meters)
    self.isPlayerTurnActive = true
    
    -- Set up combat state for player turn
    self.combat.state = COMBAT_STATE.PLAYER_TURN
    self.combat.currentCharacter = entry.index
    
    -- Reset any lingering UI state from previous turns
    self.combat.selectedAction = nil
    self.combat.selectedTarget = nil
    self.combat.selectedSkill = nil
    self.combat.selectedItem = nil
    
    -- Reset action in progress flag to prevent exploitation
    self.combat.actionInProgress = false
    
    -- Hide any selection lists that might be visible
    self.combat:hideSelectionLists()
    
    -- Show action buttons and UI
    self.combat:showActionButtons()
    
    -- Update party panel
    local partyPanel = require("screens/ui_slices/partyPanel")
    partyPanel:setActiveCharacter(entry.index)
    
    -- Add log message
    self.combat:addLog(entry.entity.name .. "'s turn begins", {0.5, 0.5, 1})
end

-- Execute an enemy turn
function turnManager:executeEnemyTurn(entry)
    -- Mark this entity as having acted to prevent consecutive turns
    self:markEntityActed(entry.entity, entry.entityType, entry.index, entry.minionIndex)
    
    -- Reset action meter after turn
    entry.entity.actionMeter = 0
    
    -- Execute the enemy's action
    self.combat.activeEnemyIndex = entry.index
    self.combat:executeEnemyTurn()
    
    -- Add animation delay to let the action complete before next turn
    self.combat.animationDelay = 1.0
    
    -- Set a flag to clear last actor when animation completes
    self.pendingLastActorClear = true
end

-- Execute a minion turn
function turnManager:executeMinionTurn(entry)
    -- Mark this entity as having acted to prevent consecutive turns
    self:markEntityActed(entry.entity, entry.entityType, entry.index, entry.minionIndex)
    
    -- Reset action meter after turn
    entry.entity.actionMeter = 0
    
    -- Set up minion turn context with proper structure
    self.combat.activeMinion = {
        charIndex = entry.index,
        minionIndex = entry.minionIndex
    }
    self.combat:executeMinionTurn()
    
    -- Add animation delay to let the action complete before next turn
    self.combat.animationDelay = 1.0
    
    -- Set a flag to clear last actor when animation completes
    self.pendingLastActorClear = true
end

-- Called when player confirms their action
function turnManager:playerTurnCompleted()
    -- Reset player action meter
    local currentPlayer = self.combat.party[self.combat.currentCharacter]
    if currentPlayer then
        currentPlayer.actionMeter = 0
    end
    
    -- Clear the last actor so other entities can take consecutive turns if needed
    -- (But the player who just acted still can't act again immediately)
    if #self.turnQueue > 0 then
        -- Only clear if there are other entities ready to act
        self:clearLastActor()
    end
    
    -- Deactivate player turn flag (resumes action meter ticking)
    self.isPlayerTurnActive = false
    
    -- Hide action buttons
    self.combat:hideActionButtons()
    self.combat:hideSelectionLists()
    
    -- Clear party panel active character
    local partyPanel = require("screens/ui_slices/partyPanel")
    partyPanel:setActiveCharacter(nil)
end

-- Get current action meter progress for UI display
function turnManager:getActionMeterProgress(entity)
    if not entity or not entity.actionMeter then
        return 0
    end
    
    local targetTime = self:getTargetTimeForEntity(entity)
    return math.min(entity.actionMeter / targetTime, 1.0)
end

-- Check if an entity is ready to act (in turn queue)
function turnManager:isEntityReady(entity)
    for _, entry in ipairs(self.turnQueue) do
        if entry.entity == entity then
            return true
        end
    end
    return false
end

-- Get all entities with their action meter status for UI
function turnManager:getAllEntityStatus()
    local entityStatus = {}
    
    -- Add party members
    for i, character in ipairs(self.combat.party) do
        if character.active then
            table.insert(entityStatus, {
                entity = character,
                type = "player",
                progress = self:getActionMeterProgress(character),
                isReady = self:isEntityReady(character),
                isPaused = self.isPlayerTurnActive or self:isEntityCasting(character)
            })
        end
    end
    
    -- Add enemies
    for i, enemy in ipairs(self.combat.enemies) do
        if enemy.active then
            table.insert(entityStatus, {
                entity = enemy,
                type = "enemy",
                progress = self:getActionMeterProgress(enemy),
                isReady = self:isEntityReady(enemy),
                isPaused = self.isPlayerTurnActive
            })
        end
    end
    
    -- Add minions
    if self.combat.minions then
        for ownerIndex, minionList in pairs(self.combat.minions) do
            for minionIndex, minion in pairs(minionList) do
                if minion.active and minion.takesActions then
                    table.insert(entityStatus, {
                        entity = minion,
                        type = "minion",
                        progress = self:getActionMeterProgress(minion),
                        isReady = self:isEntityReady(minion),
                        isPaused = self.isPlayerTurnActive or self:isEntityCasting(minion)
                    })
                end
            end
        end
    end
    
    return entityStatus
end

return turnManager 