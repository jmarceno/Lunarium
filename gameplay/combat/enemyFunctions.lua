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
    if statusEffects:has(enemy, "stun") then
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
    
    -- Find valid targets - first collect all potential targets
    local allTargets = {
        party = {},    -- Regular party members
        minions = {},  -- Summoned minions
        taunters = {}  -- Entities with taunt status
    }
    
    -- Add active party members to potential targets
    for i, character in ipairs(self.party) do
        if character.active then
            -- Check if the character has untargetable effect
            if not statusEffects:has(character, "untargetable") then
                -- Check if the character has taunt effect
                if statusEffects:has(character, "taunt") then
                    table.insert(allTargets.taunters, { type = "player", index = i })
                else
                    table.insert(allTargets.party, { type = "player", index = i })
                end
            elseif GAME.debug then
                print(character.name .. " is untargetable and skipped in targeting")
            end
        end
    end
    
    -- Add active minions to potential targets
    for charIndex, minions in pairs(self.minions) do
        for minionIndex, minion in pairs(minions) do
            if minion.active then
                -- Check if the minion has untargetable effect
                if not statusEffects:has(minion, "untargetable") then
                    -- Check if the minion has taunt effect
                    if statusEffects:has(minion, "taunt") then
                        table.insert(allTargets.taunters, { 
                            type = "minion", 
                            charIndex = charIndex, 
                            minionIndex = minionIndex 
                        })
                    else
                        table.insert(allTargets.minions, { 
                            type = "minion", 
                            charIndex = charIndex, 
                            minionIndex = minionIndex 
                        })
                    end
                elseif GAME.debug then
                    print("Minion " .. minion.name .. " is untargetable and skipped in targeting")
                end
            end
        end
    end
    
    -- Debug information about targets
    if GAME.debug then
        print("Found " .. #allTargets.party .. " targetable party members")
        print("Found " .. #allTargets.minions .. " targetable minions")
        print("Found " .. #allTargets.taunters .. " taunters")
    end
    
    -- Select a target based on priority rules
    local targetInfo = nil
    
    -- Priority 1: If there are taunters, randomly select one of them
    if #allTargets.taunters > 0 then
        targetInfo = allTargets.taunters[math.random(#allTargets.taunters)]
        if GAME.debug then
            print("Selected a taunter as target")
        end
    -- Priority 2: Combine party members and minions, and randomly select one
    elseif #allTargets.party > 0 or #allTargets.minions > 0 then
        -- Combine all non-taunting, targetable entities
        local combinedTargets = {}
        for _, target in ipairs(allTargets.party) do
            table.insert(combinedTargets, target)
        end
        for _, target in ipairs(allTargets.minions) do
            table.insert(combinedTargets, target)
        end
        
        targetInfo = combinedTargets[math.random(#combinedTargets)]
        if GAME.debug then
            print("Selected a random target from " .. #combinedTargets .. " possibilities")
        end
    end
    
    -- If no valid targets, all targets must be untargetable or defeated
    if not targetInfo then
        -- Special case: all targets are untargetable, enemy skips turn
        self:addLog(enemy.name .. " can't find a valid target and skips its turn!", {0.7, 0.7, 0.7})
        self.activeEnemyIndex = self.activeEnemyIndex + 1
        
        if GAME.debug then
            print("All potential targets are untargetable or defeated")
        end
        
        return
    end
    
    -- Extract the actual target entity from target info
    local targets = {}
    
    if targetInfo.type == "player" then
        -- Target is a player character
        local target = self.party[targetInfo.index]
        targets = {target}
        
        if GAME.debug then 
            print("Targeting party member: " .. target.name)
        end
    elseif targetInfo.type == "minion" then
        -- Target is a minion
        local minion = self.minions[targetInfo.charIndex][targetInfo.minionIndex]
        targets = {minion}
        
        if GAME.debug then 
            print("Targeting minion: " .. minion.name)
        end
    end
    
    -- Select ability to use
    local abilityId = monsterAttackSystem:selectAbility(enemy)
    
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