-- Minion Functions - Handling minion creation, turns, and management
local skillSystem = require("gameplay/skill")
local assetManager = require("assets/assetManager")
local minionManager = require("gameplay/minionManager")
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
    
    -- Add log entry
    self:addLog(minion.name .. " takes its turn!", {0.5, 0.7, 1})
    
    -- Process minion turn if active
    if minion.active and #self.enemies > 0 then
        -- Find active enemies
        local activeEnemies = {}
        for i, enemy in ipairs(self.enemies) do
            if enemy.active then
                table.insert(activeEnemies, i)
            end
        end
        
        if #activeEnemies > 0 then
            -- Choose random active enemy
            local targetIndex = activeEnemies[math.random(#activeEnemies)]
            local target = self.enemies[targetIndex]
            
            -- Determine if using ability or basic attack
            local usingAbility = false
            local abilityName = nil
            local damage = 0
            
            if minion.abilities and #minion.abilities > 0 and math.random() > 0.4 then
                -- Use random ability
                abilityName = minion.abilities[math.random(#minion.abilities)]
                local abilityData = skillSystem:getSkill(abilityName)
                
                if abilityData then
                    usingAbility = true
                    
                    -- Calculate damage based on ability type
                    if abilityData.type == "physical" then
                        damage = (minion.attackPower or 10) * (abilityData.basePower / 100)
                    elseif abilityData.type == "magical" then
                        damage = (minion.magicPower or 10) * (abilityData.basePower / 100)
                    else
                        damage = minion.attackPower or 10 -- Default to attack power for other types
                    end
                    
                    -- Ensure reasonable damage
                    damage = math.max(1, math.floor(damage))
                end
            end
            
            if usingAbility then
                -- Execute ability
                self:addLog(minion.name .. " uses " .. abilityName .. " on " .. target.name .. "!", {0.6, 0.6, 1})
                
                -- Apply damage
                target.currentHP = math.max(0, target.currentHP - damage)
                
                -- Log damage
                self:addLog(target.name .. " takes " .. damage .. " damage!", {1, 0.6, 0.6})
                
                -- Play appropriate sound
                assetManager:playSound("spell")
            else
                -- Execute basic attack
                self:addLog(minion.name .. " attacks " .. target.name .. "!", {0.7, 0.7, 0.7})
                
                -- Calculate basic attack damage
                damage = minion.attackPower or 10
                if target.defense then
                    damage = math.max(1, damage - (target.defense / 3))
                end
                damage = math.floor(damage)
                
                -- Apply damage
                target.currentHP = math.max(0, target.currentHP - damage)
                
                -- Log damage
                self:addLog(target.name .. " takes " .. damage .. " damage!", {1, 0.6, 0.6})
                
                -- Play attack sound
                assetManager:playSound("attack")
            end
            
            -- Check if enemy was defeated
            if target.currentHP <= 0 then
                target.currentHP = 0
                target.active = false
                self:addLog(target.name .. " was defeated!", {0, 1, 0})
                
                -- Check if all enemies are defeated
                local allDefeated = true
                for _, enemy in ipairs(self.enemies) do
                    if enemy.active then
                        allDefeated = false
                        break
                    end
                end
                
                if allDefeated then
                    -- Add delay before triggering victory to show final messages
                    self:addLog("All enemies have been defeated!", {0, 1, 0.2})
                    self:addLog(minion.name .. " has dealt the final blow!", {0.3, 1, 0.7})
                    
                    -- Calculate rewards BEFORE setting victory state
                    self:calculateVictoryRewards()
                    
                    -- Set state directly to victory instead of continuing turn processing
                    self.state = combatSystem.STATE.VICTORY
                    
                    -- Use a longer delay before showing victory screen when minion delivers final blow
                    self.animationDelay = 2.0  -- Increased from 1.0
                    
                    -- Trigger victory directly with a delay
                    self.turnEndDelay = 1.5  -- Increased from 0.2
                    
                    -- We'll need a custom function to handle this delayed victory
                    self.pendingVictory = true
                    
                    -- Important: Return immediately to prevent further turn processing
                    return
                end
            end
        else
            -- No active enemies
            self:addLog(minion.name .. " has no targets.", {0.7, 0.7, 0.7})
        end
    else
        -- Minion can't act
        if not minion.active then
            self:addLog(minion.name .. " is inactive and can't take a turn.", {0.5, 0.5, 0.5})
        elseif #self.enemies == 0 then
            self:addLog(minion.name .. " has no enemies to target.", {0.5, 0.5, 0.5})
        end
    end
    
    -- Debug enemy states after minion action
    if GAME.debug then
        print("Enemy states after minion turn:")
        for i, enemy in ipairs(self.enemies) do
            print("  Enemy " .. i .. ": " .. enemy.name .. " (active: " .. tostring(enemy.active) .. ")")
        end
    end
    
    -- Add delay before next turn
    self.turnEndDelay = 0.7
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