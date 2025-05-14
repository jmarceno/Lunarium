-- Minion Functions - Handling minion creation, turns, and management
local skillSystem = require("gameplay/skill")
local assetManager = require("assets/assetManager")
local minionManager = require("gameplay/minionManager")
local monsterAttackSystem = require("gameplay/monsterAttackSystem")
local minionAbilities = require("gameplay/minionAbilities")
local statusEffects = require("gameplay/statusEffects")
local combatSystem = {}  -- Forward declaration

-- Import existing minions from minionManager
local function importExistingMinions(self)
    for i, character in ipairs(self.party) do
        -- Get minions from minionManager
        local charMinions = minionManager:getActiveMinions(character)
        
        if charMinions and #charMinions > 0 then
            if GAME.debug then
                print("Importing " .. #charMinions .. " existing minions for " .. character.name)
            end
            
            -- Initialize this character's minion tracking
            self.minions[i] = {}
            self.minionsTurnTaken[i] = {}
            
            -- Add each minion
            for j, minion in ipairs(charMinions) do
                -- Ensure minion has required combat properties
                minion.active = true
                minion.takesActions = (minion.takesActions ~= false) -- Default to true unless explicitly false
                
                if minion.currentHP == nil then
                    minion.currentHP = minion.maxHP
                end
                
                -- Store minion reference
                self.minions[i][j] = minion
                self.minionsTurnTaken[i][j] = false
                
                if GAME.debug then
                    print("Imported minion: " .. minion.name)
                    print("  HP: " .. minion.currentHP .. "/" .. minion.maxHP)
                    print("  Takes actions: " .. tostring(minion.takesActions))
                end
            end
        end
    end
end

-- Process summon skill
local function processSummonSkill(self, character, skillData)
    -- Get skill level
    local skillLevel = 1
    if character.skills[skillData.name] then
        skillLevel = character.skills[skillData.name].level
    end
    
    -- Get stat modifier if defined in skill level modifier
    local statModifier = 1
    local duration = skillData.duration or 0
    
    if skillData.levelModifier then
        local modData = skillData.levelModifier(skillLevel)
        
        if type(modData) == "table" then
            statModifier = modData.statModifier or 1
            
            if modData.duration then
                duration = modData.duration
            end
            
            -- Scale passive buffs for spirits
            if modData.passiveBuffs and skillData.summonType == "spirit" then
                for stat, value in pairs(modData.passiveBuffs) do
                    skillData.summonStats.passiveBuffs[stat] = value
                end
            end
        else
            statModifier = modData
        end
    end
    
    -- Apply stat modifier to summon stats
    local summonStats = {}
    for k, v in pairs(skillData.summonStats) do
        if type(v) == "number" and k ~= "color" then
            summonStats[k] = v * statModifier
        else
            summonStats[k] = v
        end
    end
    
    -- Add required additional properties for battle
    summonStats.active = true
    summonStats.takesActions = true  -- Most summons take actions in battle
    summonStats.type = skillData.summonType  -- Ensure type is set for UI rendering
    summonStats.element = skillData.element   -- Set element if applicable
    
    -- Make sure currentHP is set to maxHP initially
    summonStats.currentHP = summonStats.maxHP
    
    -- Ensure abilities array exists
    if not summonStats.abilities then
        summonStats.abilities = {}
    end
    
    -- Set owner info
    summonStats.owner = {
        name = character.name,
        index = self.currentCharacter  -- Store the character index for reference
    }
    
    -- Create the minion
    local minion = minionManager:summonMinion(
        character,
        skillData.summonType,
        skillData.summonStats.name,
        summonStats,
        duration
    )
    
    if GAME.debug then
        print("Summoned minion: " .. minion.name)
        print("  Type: " .. (minion.type or "none"))
        print("  takesActions: " .. tostring(minion.takesActions))
        print("  HP: " .. minion.currentHP .. "/" .. minion.maxHP)
        if minion.abilities and #minion.abilities > 0 then
            print("  Abilities: " .. table.concat(minion.abilities, ", "))
        end
    end
    
    -- Add log message
    self:addLog(character.name .. " summoned " .. minion.name .. "!", {0.5, 0.8, 1})
    
    -- Update the current combat's minion list
    if not self.minions[self.currentCharacter] then
        self.minions[self.currentCharacter] = {}
    end
    
    -- Add to minions list for this combat
    table.insert(self.minions[self.currentCharacter], minion)
    local newMinionIndex = #self.minions[self.currentCharacter]
    
    -- Initialize turn tracking for this minion
    if not self.minionsTurnTaken then
        self.minionsTurnTaken = {}
    end
    
    if not self.minionsTurnTaken[self.currentCharacter] then
        self.minionsTurnTaken[self.currentCharacter] = {}
    end
    
    -- Mark that the minion hasn't taken a turn yet
    self.minionsTurnTaken[self.currentCharacter][newMinionIndex] = false
    
    -- Recalculate turn order to include the new minion
    self:determineTurnOrder()
    
    -- Return success
    return true
end

-- Execute minion turn
local function executeMinionTurn(self)
    if not self.activeMinion then
        if GAME.debug then
            print("No active minion for turn execution")
        end
        return
    end
    
    local charIndex = self.activeMinion.charIndex
    local minionIndex = self.activeMinion.minionIndex
    
    if not self.party[charIndex] or 
       not self.minions[charIndex] or 
       not self.minions[charIndex][minionIndex] then
        -- Invalid minion, skip turn
        if GAME.debug then
            print("Invalid minion references, skipping turn")
        end
        return
    end
    
    local minion = self.minions[charIndex][minionIndex]
    
    -- Debug minion turn
    if GAME.debug then
        print("Executing turn for minion: " .. minion.name)
        print("  Owner: " .. self.party[charIndex].name)
        print("  Minion HP: " .. minion.currentHP .. "/" .. minion.maxHP)
        
        -- Debug enemy states
        print("Checking enemy states during minion turn:")
        for i, enemy in ipairs(self.enemies) do
            print("  Enemy " .. i .. ": " .. enemy.name .. " (active: " .. tostring(enemy.active) .. ")")
        end
    end
    
    -- Process status effects at turn start
    local statusUpdates = statusEffects:processTurnStart(minion)
    
    -- Log status effect messages
    for _, update in ipairs(statusUpdates) do
        self:addLog(update.message, update.color)
        
        -- If minion was defeated by a status effect, skip its turn
        if update.message:find(minion.name .. " is defeated") then
            -- Mark turn as taken
            self.minionsTurnTaken[charIndex][minionIndex] = true
            return
        end
    end
    
    -- Check for stun status effect
    if minion.status and minion.status["stun"] then
        self:addLog(minion.name .. " is stunned and cannot act!", {0.8, 0.8, 0.2})
        
        -- Process status effects at turn end
        local expiredEffects = statusEffects:processTurnEnd(minion)
        for _, expired in ipairs(expiredEffects) do
            self:addLog(expired.message, expired.color)
        end
        
        -- Mark turn as taken
        self.minionsTurnTaken[charIndex][minionIndex] = true
        return
    end
    
    -- Add log entry
    self:addLog(minion.name .. " takes its turn!", {0.5, 0.7, 1})
    
    -- Process minion turn if active
    if minion.active and #self.enemies > 0 then
        -- Find a valid target - Select a random active enemy
        local validTargets = {}
        for i, enemy in ipairs(self.enemies) do
            if enemy.active then
                table.insert(validTargets, enemy)
            end
        end
        
        if #validTargets > 0 then
            local targetEnemy = validTargets[math.random(#validTargets)]
            
            -- Select an ability to use
            local abilityId = "minion_basic_attack" -- Default ability
            
            -- If minion has specific abilities defined, select from them
            if minion.abilities and #minion.abilities > 0 then
                abilityId = minion.abilities[math.random(#minion.abilities)]
            end
            
            -- Get the ability definition
            local abilityDef = minionAbilities:getAbility(abilityId)
            
            -- Resolve the ability
            local logEntries = monsterAttackSystem:resolveAbility(abilityDef or abilityId, minion, {targetEnemy}, self)
            
            -- Add log entries to combat log
            for _, entry in ipairs(logEntries) do
                self:addLog(entry.message, entry.color or {1, 0.7, 0.7})
            end
            
            -- Play attack sound
            assetManager:playSound("attack")
        else
            -- No valid targets, which means all enemies are defeated
            self:addLog("No valid targets for " .. minion.name, {0.7, 0.7, 0.7})
        end
    end
    
    -- Process status effects at turn end
    local expiredEffects = statusEffects:processTurnEnd(minion)
    for _, expired in ipairs(expiredEffects) do
        self:addLog(expired.message, expired.color)
    end
    
    -- Mark minion's turn as taken
    self.minionsTurnTaken[charIndex][minionIndex] = true
    
    -- Add animation delay
    self.animationDelay = 0.5
end

-- Find an active minion with an untaken turn
local function findActiveUntakenMinion(self)
    for charIndex, minions in pairs(self.minions) do
        if self.party[charIndex] and self.party[charIndex].active then -- Only consider minions of active characters
            for minionIndex, minion in pairs(minions) do
                -- Check if minion is active, takes actions, and hasn't had its turn yet
                if minion.active and minion.takesActions and 
                  (not self.minionsTurnTaken[charIndex] or not self.minionsTurnTaken[charIndex][minionIndex]) then
                    -- Return reference to this minion
                    return {
                        charIndex = charIndex,
                        minionIndex = minionIndex
                    }
                end
            end
        end
    end
    
    -- No active untaken minion found
    return nil
end

combatSystem.STATE = {INIT = 1, PLAYER_TURN = 2, ENEMY_TURN = 3, MINION_TURN = 4, VICTORY = 5, DEFEAT = 6}

return {
    importExistingMinions = importExistingMinions,
    processSummonSkill = processSummonSkill,
    executeMinionTurn = executeMinionTurn,
    findActiveUntakenMinion = findActiveUntakenMinion
}