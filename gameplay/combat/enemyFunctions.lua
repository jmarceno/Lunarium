-- Enemy Functions - Handling AI and enemy turns
local assetManager = require("assets/assetManager")
local uniqueItemSystem = require("gameplay/uniqueItemSystem")
local statusEffects = require("gameplay/statusEffects")
local monsterAttackSystem = require("gameplay/monsterAttackSystem")
local combatSystem = {}  -- Forward declaration

-- Execute current enemy's turn
local function executeEnemyTurn(self)
    -- Get the current active enemy
    local enemy = self.enemies[self.activeEnemyIndex]
    
    -- Debug information
    if GAME.debug then
        print("Executing turn for enemy at index " .. self.activeEnemyIndex)
        if enemy then
            print("Enemy: " .. enemy.name .. " (active: " .. tostring(enemy.active) .. ")")
        else
            print("No enemy found at this index")
        end
    end
    
    -- Ensure enemy exists
    if not enemy then
        self.activeEnemyIndex = self.activeEnemyIndex + 1
        return
    end
    
    -- Check if enemy is currently casting a spell
    local isCasting, castingSpell = self:isEntityCasting(enemy)
    if isCasting then
        -- Skip this enemy's turn as they're currently casting
        self:addLog(enemy.name .. " continues casting " .. castingSpell.skill.name .. "...", {0.5, 0.8, 1})
        self.activeEnemyIndex = self.activeEnemyIndex + 1
        return
    end
    
    -- Ensure active is a boolean (fix it if nil)
    if enemy.active == nil then
        enemy.active = (enemy.currentHP or 0) > 0
        if GAME.debug then
            print("WARNING: Fixed nil enemy.active for " .. enemy.name .. " - now set to " .. tostring(enemy.active))
        end
    end
    
    -- Skip the turn if the enemy is inactive
    if not enemy.active then
        self.activeEnemyIndex = self.activeEnemyIndex + 1
        return
    end
    
    -- Process status effects at turn start
    local statusUpdates = statusEffects:processTurnStart(enemy)
    
    -- Log status effect messages
    for _, update in ipairs(statusUpdates) do
        self:addLog(update.message, update.color)
        
        -- If enemy was defeated by a status effect, skip its turn
        if update.message:find(enemy.name .. " is defeated") then
            self.activeEnemyIndex = self.activeEnemyIndex + 1
            return
        end
    end
    
    -- Check for stun status effect
    if enemy.status and enemy.status["stun"] then
        self:addLog(enemy.name .. " is stunned and cannot act!", {0.8, 0.8, 0.2})
        self.activeEnemyIndex = self.activeEnemyIndex + 1
        
        -- Process status effects at turn end
        local expiredEffects = statusEffects:processTurnEnd(enemy)
        for _, expired in ipairs(expiredEffects) do
            self:addLog(expired.message, expired.color)
        end
        
        return
    end
    
    -- Log that this enemy is taking its turn
    self:addLog(enemy.name .. " prepares to attack!", {1, 0.6, 0.6})
    
    -- Check for valid targets (party members and minions)
    local validTargets = {}
    local tauntingTargets = {} -- Track targets with taunt effect
    
    -- Add active party members to valid targets
    for i, character in ipairs(self.party) do
        if character.active then
            -- Check if character has taunt effect
            if statusEffects:has(character, "taunt") then
                table.insert(tauntingTargets, { type = "player", index = i, entity = character })
            -- Check if character is untargetable or stealthed
            elseif not statusEffects:has(character, "untargetable") and not statusEffects:has(character, "stealth") and not statusEffects:has(character, "invisible") then
                table.insert(validTargets, { type = "player", index = i, entity = character })
            end
        end
    end
    
    -- Add active minions to valid targets
    for charIndex, minions in pairs(self.minions) do
        for minionIndex, minion in pairs(minions) do
            if minion.active then
                -- Check if minion has taunt effect
                if statusEffects:has(minion, "taunt") then
                    table.insert(tauntingTargets, { 
                        type = "minion", 
                        charIndex = charIndex, 
                        minionIndex = minionIndex,
                        entity = minion
                    })
                -- Check if minion is untargetable or stealthed
                elseif not statusEffects:has(minion, "untargetable") and not statusEffects:has(minion, "stealth") and not statusEffects:has(minion, "invisible") then
                    table.insert(validTargets, { 
                        type = "minion", 
                        charIndex = charIndex, 
                        minionIndex = minionIndex,
                        entity = minion
                    })
                end
            end
        end
    end
    
    -- Debug information about targets
    if GAME.debug then
        print("Found " .. #validTargets .. " valid targets")
        print("Found " .. #tauntingTargets .. " taunting targets")
    end
    
    -- If no valid targets, party must be defeated
    if #validTargets == 0 and #tauntingTargets == 0 then
        -- Case: All potential targets are untargetable
        if self.allTargetsUntargetable then
            self:addLog(enemy.name .. " couldn't find a valid target and skips its turn!", {0.7, 0.7, 0.9})
            self.activeEnemyIndex = self.activeEnemyIndex + 1
            return
        else
            self.allTargetsUntargetable = true
            self:partyDefeated()
            return
        end
    end
    
    -- Reset the untargetable flag if we found valid targets
    self.allTargetsUntargetable = false
    
    -- Prioritize taunting targets over regular targets
    local targetInfo
    if #tauntingTargets > 0 then
        -- If there are taunting targets, choose randomly among them
        targetInfo = tauntingTargets[math.random(#tauntingTargets)]
        
        if GAME.debug then
            print("Targeting taunting " .. targetInfo.entity.name)
        end
    else
        -- Otherwise choose randomly among valid targets
        targetInfo = validTargets[math.random(#validTargets)]
        
        if GAME.debug then
            print("Targeting " .. targetInfo.entity.name)
        end
    end
    
    -- Select ability to use
    local abilityId = monsterAttackSystem:selectAbility(enemy)
    
    -- Process target selection based on ability target type
    local targets = {}
    if targetInfo.type == "player" then
        -- Target is a player character
        local target = self.party[targetInfo.index]
        targets = {target}
    elseif targetInfo.type == "minion" then
        -- Target is a minion
        local minion = self.minions[targetInfo.charIndex][targetInfo.minionIndex]
        targets = {minion}
    end
    
    -- Resolve the ability
    local logEntries = monsterAttackSystem:resolveAbility(abilityId, enemy, targets, self)
    
    -- Add log entries to combat log
    for _, entry in ipairs(logEntries) do
        self:addLog(entry.message, entry.color or {1, 0.5, 0.5})
    end
    
    -- Play attack sound
    assetManager:playSound("attack")
    
    -- Process status effects at turn end
    local expiredEffects = statusEffects:processTurnEnd(enemy)
    for _, expired in ipairs(expiredEffects) do
        self:addLog(expired.message, expired.color)
    end
    
    -- Increment to next enemy
    self.activeEnemyIndex = self.activeEnemyIndex + 1
end

combatSystem.STATE = {INIT = 1, PLAYER_TURN = 2, ENEMY_TURN = 3, MINION_TURN = 4, VICTORY = 5, DEFEAT = 6}

return {
    executeEnemyTurn = executeEnemyTurn
}