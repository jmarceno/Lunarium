-- Enemy Functions - Handling AI and enemy turns
local assetManager = require("assets/assetManager")
local uniqueItemSystem = require("gameplay/uniqueItemSystem")
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
    
    -- Log that this enemy is taking its turn
    self:addLog(enemy.name .. " prepares to attack!", {1, 0.6, 0.6})
    
    -- Check for valid targets (party members and minions)
    local validTargets = {}
    
    -- Add active party members to valid targets
    for i, character in ipairs(self.party) do
        if character.active then
            table.insert(validTargets, { type = "player", index = i })
        end
    end
    
    -- Add active minions to valid targets
    for charIndex, minions in pairs(self.minions) do
        for minionIndex, minion in pairs(minions) do
            if minion.active then
                table.insert(validTargets, { 
                    type = "minion", 
                    charIndex = charIndex, 
                    minionIndex = minionIndex 
                })
            end
        end
    end
    
    -- Debug information about targets
    if GAME.debug then
        print("Found " .. #validTargets .. " valid targets")
    end
    
    -- If no valid targets, party must be defeated
    if #validTargets == 0 then
        self:partyDefeated()
        return
    end
    
    -- Select a random target from valid targets
    local targetInfo = validTargets[math.random(#validTargets)]
    local targetName = ""
    local damage = 0
    
    if targetInfo.type == "player" then
        -- Target is a player character
        local target = self.party[targetInfo.index]
        targetName = target.name
        
        -- Calculate damage
        local attackPower = enemy.attackPower or enemy.stats.attack or 10
        local defense = target.defense or 5
        
        -- Basic damage calculation
        damage = math.floor(attackPower - (defense / 2))
        damage = math.max(1, damage) -- Ensure minimum damage
        
        -- Process unique item effects that modify incoming damage
        local damageContext = {
            eventType = "CHARACTER_TAKES_DAMAGE",
            character = target,
            source = enemy,
            value = damage,
            damageType = enemy.element or "physical" -- Use enemy's element or default to physical
        }
        damage = uniqueItemSystem:processEffects(damageContext)
        
        -- Apply damage to character
        target.currentHP = math.max(0, target.currentHP - damage)
        
        -- Check if character is defeated
        if target.currentHP <= 0 then
            target.currentHP = 0
            target.active = false
            
            -- Add to combat log
            self:addLog(target.name .. " is defeated!", {1, 0, 0})
            
            -- Check if all party members are defeated
            local allDefeated = true
            for _, char in ipairs(self.party) do
                if char.active then
                    allDefeated = false
                    break
                end
            end
            
            if allDefeated then
                self:partyDefeated()
                return
            end
        end
    elseif targetInfo.type == "minion" then
        -- Target is a minion
        local minion = self.minions[targetInfo.charIndex][targetInfo.minionIndex]
        targetName = minion.name
        
        -- Calculate damage
        local attackPower = enemy.attackPower or enemy.stats.attack or 10
        local defense = minion.defense or 5
        
        -- Basic damage calculation
        damage = math.floor(attackPower - (defense / 2))
        damage = math.max(1, damage) -- Ensure minimum damage
        
        -- Apply damage to minion
        minion.currentHP = math.max(0, minion.currentHP - damage)
        
        -- Check if minion is defeated
        if minion.currentHP <= 0 then
            minion.currentHP = 0
            minion.active = false
            
            -- Add to combat log
            self:addLog(minion.name .. " is defeated!", {1, 0.3, 0.3})
        end
    end
    
    -- Add to combat log
    self:addLog(enemy.name .. " attacks " .. targetName .. " for " .. damage .. " damage!", {1, 0.5, 0.5})
    
    -- Play attack sound
    assetManager:playSound("attack")
    
    -- Increment to next enemy - only increment here
    self.activeEnemyIndex = self.activeEnemyIndex + 1
end

combatSystem.STATE = {INIT = 1, PLAYER_TURN = 2, ENEMY_TURN = 3, MINION_TURN = 4, VICTORY = 5, DEFEAT = 6}

return {
    executeEnemyTurn = executeEnemyTurn
}