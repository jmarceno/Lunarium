-- Player Action Functions
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local assetManager = require("assets/assetManager")
local uniqueItemSystem = require("gameplay/uniqueItemSystem")
local damageTypes = require("gameplay/damageTypes")
local statusEffects = require("gameplay/statusEffects")

-- Execute player's selected action
local function executePlayerAction(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar then return end
    
    -- Execute attack
    if self.selectedAction == "attack" then
        -- Ensure character has attack power
        if not currentChar.attackPower or type(currentChar.attackPower) ~= "number" then
            -- Force set character attack power if missing
            currentChar.attackPower = currentChar.attributes and currentChar.attributes.STR or 10
            if GAME.debug then
                print("Fixed missing character attack power, set to: " .. currentChar.attackPower)
            end
        end
        
        -- Get the target enemy (for backward compatibility, default to self.enemy if no specific target)
        local targetEnemy = self.selectedTarget or self.enemy
        
        -- Ensure enemy has defense
        if not targetEnemy.defense or type(targetEnemy.defense) ~= "number" then
            targetEnemy.defense = 0
            if GAME.debug then
                print("Fixed missing enemy defense, set to: " .. targetEnemy.defense)
            end
        end
        
        -- Calculate damage using explicit values
        local attackPower = currentChar.attackPower or 10  -- Default if missing
        local enemyDefense = targetEnemy.defense or 0       -- Default if missing
        
        -- Debug attack values
        if GAME.debug then
            print("Player attack calculation:")
            print("  Character: " .. currentChar.name)
            print("  Attack power: " .. attackPower)
            print("  Enemy defense: " .. enemyDefense)
        end
        
        -- Basic damage calculation with explicit values
        local damage = math.floor(attackPower - (enemyDefense / 2))
        
        -- Ensure minimum damage
        if damage < 1 then 
            damage = 1
            if GAME.debug then
                print("  Adjusted to minimum damage: " .. damage)
            end
        end
        
        -- Apply damage to enemy
        if not targetEnemy.currentHP or type(targetEnemy.currentHP) ~= "number" then
            targetEnemy.currentHP = targetEnemy.maxHP or 20
        end
        
        -- Apply damage and ensure we don't go below 0
        targetEnemy.currentHP = targetEnemy.currentHP - damage
        if targetEnemy.currentHP < 0 then targetEnemy.currentHP = 0 end
        
        if GAME.debug then
            print("  Enemy HP after attack: " .. targetEnemy.currentHP)
        end
        
        -- Add animation delay
        self.animationDelay = 0.5
        
        -- Play attack sound
        assetManager:playSound("attack")
        
        -- Add to combat log
        self:addLog(currentChar.name .. " attacks " .. targetEnemy.name .. " for " .. damage .. " damage!")
        
        -- Check for enemy defeat
        if targetEnemy.currentHP <= 0 then
            -- Make sure to mark as inactive
            targetEnemy.active = false
            
            if GAME.debug then
                print("  Enemy defeated in executePlayerAction: " .. targetEnemy.name)
            end
            
            self:enemyDefeated(targetEnemy)
        end
    end
    
    -- Ensure action buttons will be visible for next player's turn
    self:showActionButtons()
    
    -- End turn after a short delay
    self.turnEndDelay = 0.7
end

-- Execute skill use
local function executeSkill(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar or not self.selectedSkill then 
        if GAME.debug then
            print("executeSkill failed: ", currentChar and "Character OK" or "No character", 
                  self.selectedSkill and "Skill OK" or "No skill")
        end
        return 
    end
    
    -- Log skill execution for debugging
    if GAME.debug then
        print("Executing skill: " .. self.selectedSkill.name)
        print("  Target type: " .. (self.selectedSkill.target or "unknown"))
        print("  Selected target: " .. (self.selectedTarget and self.selectedTarget.name or "none/all"))
    end
    
    -- Check target for single-enemy skills
    if self.selectedSkill.target == "single_enemy" and not self.selectedTarget then
        self:addLog("No valid target for skill.", {1, 0.5, 0})
        if GAME.debug then print("Missing target for skill " .. self.selectedSkill.name) end
        return
    end
    
    -- Check MP cost
    if currentChar.currentMP < self.selectedSkill.mpCost then
        self:addLog("Not enough MP!")
        return
    end
    
    -- Deduct MP
    currentChar.currentMP = currentChar.currentMP - self.selectedSkill.mpCost
    
    -- Add animation delay
    self.animationDelay = 0.5
    
    -- Handle summon skills specifically
    if self.selectedSkill.type == "summon" then
        -- Play summon sound
        assetManager:playSound("spell")
        
        -- Process the summon
        local success = self:processSummonSkill(currentChar, self.selectedSkill)
        
        if success then
            -- Recalculate turn order to include new minion
            self:determineTurnOrder()
        end
        
        -- End turn after a short delay
        self.turnEndDelay = 0.7
        return
    end
    
    -- Special case for Steal skill
    if self.selectedSkill.name == "Steal" then
        self:executeStealSkill(currentChar)
        return
    end
    
    -- Handle different skill targets
    if self.selectedSkill.target == "single_enemy" then
        -- Apply damage to the selected enemy
        local damage, isCritical = 0, false
        
        -- Make sure character has this skill before calculating damage
        if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
            -- Create a mutable copy of the skill for this calculation
            local skillCopy = {}
            for k, v in pairs(self.selectedSkill) do
                skillCopy[k] = v
            end
            
            damage, isCritical = skillSystem:calculateDamage(
                skillCopy,
                currentChar,
                self.selectedTarget,
                currentChar.skills[self.selectedSkill.name].level
            )
            
            -- Apply damage type modifier if skill has a damage type
            if skillCopy.damageType then
                local damageMultiplier = damageTypes:calculateModifier(skillCopy.damageType, self.selectedTarget)
                damage = math.floor(damage * damageMultiplier)
                
                -- Log damage type effectiveness
                local resistText, resistColor = damageTypes:getDisplayText(damageMultiplier)
                if resistText then
                    self:addLog(self.selectedTarget.name .. " " .. resistText .. " to " .. skillCopy.damageType .. "!", resistColor)
                end
            end
            
            -- Apply unique item effects to the damage
            local damageContext = {
                eventType = "CALCULATE_OUTGOING_DAMAGE",
                character = currentChar,
                target = self.selectedTarget,
                skill = skillCopy, -- Pass the mutable copy
                value = damage,
                is_critical = isCritical,
                damageType = skillCopy.damageType or "physical" -- Add damage type to context
            }
            damage = uniqueItemSystem:processEffects(damageContext)
            
            -- Update isCritical if needed
            isCritical = damageContext.is_critical
        else
            -- Fallback if skill level is not found
            -- Create a mutable copy of the skill for this calculation
            local skillCopy = {}
            for k, v in pairs(self.selectedSkill) do
                skillCopy[k] = v
            end
            
            damage, isCritical = skillSystem:calculateDamage(
                skillCopy,
                currentChar,
                self.selectedTarget,
                1
            )
            
            -- Apply unique item effects to the damage
            local damageContext = {
                eventType = "CALCULATE_OUTGOING_DAMAGE",
                character = currentChar,
                target = self.selectedTarget,
                skill = skillCopy, -- Pass the mutable copy
                value = damage,
                is_critical = isCritical
            }
            damage = uniqueItemSystem:processEffects(damageContext)
            
            -- Update isCritical if needed
            isCritical = damageContext.is_critical
        end
        
        -- Apply damage
        self.selectedTarget.currentHP = math.max(0, self.selectedTarget.currentHP - damage)
        
        -- Play appropriate sound
        if self.selectedSkill.type == "magical" then
            assetManager:playSound("spell")
        else
            assetManager:playSound("attack")
        end
        
        -- Add to combat log
        local logText = currentChar.name .. " uses " .. self.selectedSkill.name
        logText = logText .. " on " .. self.selectedTarget.name
        logText = logText .. " for " .. damage .. " damage!"
        
        if isCritical then
            logText = logText .. " Critical hit!"
        end
        
        self:addLog(logText)
        
        -- Apply skill effects
        if self.selectedSkill.effect then
            self:applySkillEffect(self.selectedSkill, currentChar, self.selectedTarget)
        end
        
        -- Check for enemy defeat
        if self.selectedTarget.currentHP <= 0 then
            self:enemyDefeated(self.selectedTarget)
        end
        
        -- Add status effect if skill has effect property
        if self.selectedSkill.effect and self.selectedTarget.active then
            local effect = self.selectedSkill.effect
            local effectType = effect.type
            local chance = effect.chance or 1.0
            local duration = effect.duration or 3
            local strength = effect.strength or 1
            
            -- Roll for effect chance
            if math.random() <= chance then
                local applied = statusEffects:apply(effectType, self.selectedTarget, duration, strength)
                if applied then
                    self:addLog(self.selectedTarget.name .. " is afflicted with " .. statusEffects.effects[effectType].name .. "!", {0.8, 0.6, 0.8})
                end
            end
        end
    elseif self.selectedSkill.target == "all_enemies" then
        -- Apply to all enemies
        local totalDamage = 0
        local defeatedCount = 0
        
        for _, enemy in ipairs(self.enemies) do
            if enemy.active then
                local damage, isCritical = 0, false
                
                -- Create a mutable copy of the skill for this calculation
                local skillCopy = {}
                for k, v in pairs(self.selectedSkill) do
                    skillCopy[k] = v
                end
                
                -- Calculate damage for each enemy
                if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                    damage, isCritical = skillSystem:calculateDamage(
                        skillCopy,
                        currentChar,
                        enemy,
                        currentChar.skills[self.selectedSkill.name].level
                    )
                else
                    damage, isCritical = skillSystem:calculateDamage(
                        skillCopy,
                        currentChar,
                        enemy,
                        1
                    )
                end
                
                -- Apply unique item effects to the damage
                local damageContext = {
                    eventType = "CALCULATE_OUTGOING_DAMAGE",
                    character = currentChar,
                    target = enemy,
                    skill = skillCopy, -- Pass the mutable copy
                    value = damage,
                    is_critical = isCritical
                }
                damage = uniqueItemSystem:processEffects(damageContext)
                
                -- Update isCritical if needed
                isCritical = damageContext.is_critical
                
                -- Apply damage with AOE reduction
                local aoeReduction = 0.8 -- Reduce damage for AOE attacks
                damage = math.floor(damage * aoeReduction)
                enemy.currentHP = math.max(0, enemy.currentHP - damage)
                totalDamage = totalDamage + damage
                
                -- Apply skill effects
                if self.selectedSkill.effect then
                    self:applySkillEffect(self.selectedSkill, currentChar, enemy)
                end
                
                -- Check for enemy defeat
                if enemy.currentHP <= 0 and enemy.active then
                    enemy.active = false
                    defeatedCount = defeatedCount + 1
                end
            end
        end
        
        -- Play appropriate sound
        if self.selectedSkill.type == "magical" then
            assetManager:playSound("spell")
        else
            assetManager:playSound("attack")
        end
        
        -- Add to combat log
        local logText = currentChar.name .. " uses " .. self.selectedSkill.name
        logText = logText .. " on all enemies for " .. totalDamage .. " total damage!"
        self:addLog(logText)
        
        -- Log defeated enemies if any
        if defeatedCount > 0 then
            self:addLog(defeatedCount .. " enemies were defeated!", {0, 1, 0})
            
            -- Check if all enemies are defeated
            self:checkAllEnemiesDefeated()
        end
    elseif self.selectedSkill.target == "single_ally" or 
           self.selectedSkill.target == "self" then
        -- Handle healing
        if self.selectedSkill.formula == "healing" then
            local healing = 0
            -- Make sure character has this skill
            if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                healing = skillSystem:calculateDamage(
                    self.selectedSkill,
                    currentChar,
                    self.selectedTarget,
                    currentChar.skills[self.selectedSkill.name].level
                )
            else
                healing = skillSystem:calculateDamage(
                    self.selectedSkill,
                    currentChar,
                    self.selectedTarget,
                    1
                )
            end
            
            self.selectedTarget.currentHP = math.min(
                self.selectedTarget.maxHP,
                self.selectedTarget.currentHP + healing
            )
            
            -- Play heal sound
            assetManager:playSound("spell")
            
            -- Add to combat log
            if self.selectedTarget == currentChar then
                self:addLog(
                    currentChar.name .. " uses " .. self.selectedSkill.name .. 
                    " and heals self for " .. healing .. " HP!",
                    {0.2, 0.8, 0.2}
                )
            else
                self:addLog(
                    currentChar.name .. " uses " .. self.selectedSkill.name .. 
                    " and heals " .. self.selectedTarget.name .. " for " .. healing .. " HP!",
                    {0.2, 0.8, 0.2}
                )
            end
        end
        
        -- Apply skill effects
        if self.selectedSkill.effect then
            self:applySkillEffect(self.selectedSkill, currentChar, self.selectedTarget)
        end
    elseif self.selectedSkill.target == "all_allies" then
        -- Apply to all party members
        for _, ally in ipairs(self.party) do
            if ally.active then
                -- Handle healing
                if self.selectedSkill.formula == "healing" then
                    local healing = 0
                    -- Make sure character has this skill
                    if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                        healing = skillSystem:calculateDamage(
                            self.selectedSkill,
                            currentChar,
                            ally,
                            currentChar.skills[self.selectedSkill.name].level
                        )
                    else
                        healing = skillSystem:calculateDamage(
                            self.selectedSkill,
                            currentChar,
                            ally,
                            1
                        )
                    end
                    
                    ally.currentHP = math.min(
                        ally.maxHP,
                        ally.currentHP + healing
                    )
                end
                
                -- Apply skill effects
                if self.selectedSkill.effect then
                    self:applySkillEffect(self.selectedSkill, currentChar, ally)
                end
            end
        end
        
        -- Play heal sound
        assetManager:playSound("spell")
        
        -- Add to combat log
        self:addLog(
            currentChar.name .. " uses " .. self.selectedSkill.name .. 
            " on the entire party!",
            {0.2, 0.8, 0.2}
        )
    elseif self.selectedSkill.target == "none" then
        -- Handle target-less skills (like some summons)
        -- Play appropriate sound
        assetManager:playSound("spell")
        
        -- Add to combat log
        self:addLog(
            currentChar.name .. " uses " .. self.selectedSkill.name .. "!",
            {0.5, 0.5, 1}
        )
    end
    
    -- Make sure action buttons will be visible for next turn
    self:showActionButtons()
    
    -- End turn after a short delay
    self.turnEndDelay = 0.7
end

-- Execute steal skill
local function executeStealSkill(self, character)
    -- Play effect sound
    assetManager:playSound("spell")
    
    -- Calculate steal chance based on character level and enemy level
    local effect = nil
    if character.skills and character.skills.Steal then
        effect = skillSystem:calculateSkillEffect(
            self.selectedSkill, 
            character, 
            self.enemy, 
            character.skills.Steal.level
        )
    else
        effect = skillSystem:calculateSkillEffect(
            self.selectedSkill, 
            character, 
            self.enemy, 
            1
        )
    end
    
    local stealChance = effect.stealChance or 0.3
    
    -- Add character DEX bonus
    if character.attributes and character.attributes.DEX then
        stealChance = stealChance + (character.attributes.DEX / 100)
    end
    
    -- Subtract enemy level penalty
    if self.enemy.stats and self.enemy.stats.level then
        stealChance = stealChance - (self.enemy.stats.level * 0.02)
    end
    
    -- Clamp steal chance
    stealChance = math.max(0.1, math.min(0.8, stealChance))
    
    -- Try to steal
    if math.random() < stealChance then
        -- Success! Generate a random item
        local stolenItem = itemSystem:generateRandomItem(self.enemy.stats.level or 1)
        
        -- Add item to inventory
        itemSystem:addToInventory(stolenItem)
        
        -- Add to combat log
        self:addLog(
            character.name .. " successfully steals " .. stolenItem.name .. "!",
            {0.2, 0.8, 0.8}
        )
    else
        -- Failed to steal
        self:addLog(
            character.name .. " fails to steal anything!",
            {0.8, 0.5, 0.2}
        )
    end
    
    -- Make sure buttons are visible
    self:showActionButtons()
    
    -- End turn after a short delay
    self.turnEndDelay = 0.7
end

-- Apply skill effect to target
local function applySkillEffect(self, skill, caster, target)
    if not skill.effect then return end
    
    local skillLevel = 1
    -- Safely get the skill level if it exists
    if caster.skills and caster.skills[skill.name] and caster.skills[skill.name].level then
        skillLevel = caster.skills[skill.name].level
    end
    
    local effect = skillSystem:calculateSkillEffect(
        skill,
        caster,
        target,
        skillLevel
    )
    
    -- Apply status effects
    if effect.stat then
        -- Single stat effect
        target.status[effect.stat] = {
            value = effect.value,
            duration = effect.duration
        }
        
        -- Add to combat log
        self:addLog(
            target.name .. " is affected by " .. effect.stat .. "!",
            {0.8, 0.8, 0.2}
        )
    elseif effect.stats then
        -- Multiple stat effects
        for stat, value in pairs(effect.stats) do
            target.status[stat] = {
                value = value,
                duration = effect.duration
            }
        end
        
        -- Add to combat log
        self:addLog(
            target.name .. " is affected by multiple status effects!",
            {0.8, 0.8, 0.2}
        )
    end
    
    -- Handle special effects
    if effect.removeStatus then
        -- Remove status effects
        if effect.removeStatus == "negative" then
            -- List of negative status effects
            local negativeEffects = {
                "poison", "sleep", "paralysis", "silence", "blind"
            }
            
            for _, status in ipairs(negativeEffects) do
                if target.status[status] then
                    target.status[status] = nil
                end
            end
            
            -- Add to combat log
            self:addLog(
                target.name .. "'s negative status effects are removed!",
                {0.2, 0.8, 0.2}
            )
        else
            -- Remove specific status
            if target.status[effect.removeStatus] then
                target.status[effect.removeStatus] = nil
                
                -- Add to combat log
                self:addLog(
                    target.name .. "'s " .. effect.removeStatus .. " is removed!",
                    {0.2, 0.8, 0.2}
                )
            end
        end
    end
end

-- Execute item use
local function executeItemUse(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar or not self.selectedItem then return end
    
    -- Make sure we have a valid target
    if not self.selectedTarget then
        self:addLog("No target selected for item use.", {1, 0.5, 0})
        return
    end
    
    -- Use item on target
    local success = itemSystem:useItem(self.selectedItem, self.selectedTarget)
    
    if success then
        -- Play pickup sound
        assetManager:playSound("pickup")
        
        -- Add to combat log
        if self.selectedTarget == currentChar then
            self:addLog(
                currentChar.name .. " uses " .. self.selectedItem.name .. " on self!",
                {0.2, 0.8, 0.8}
            )
        else
            self:addLog(
                currentChar.name .. " uses " .. self.selectedItem.name .. " on " .. self.selectedTarget.name .. "!",
                {0.2, 0.8, 0.8}
            )
        end
        
        -- Remove item from inventory
        if GAME.inventory then
            for i, item in ipairs(GAME.inventory) do
                if item.name == self.selectedItem.name then
                    if item.count and item.count > 1 then
                        item.count = item.count - 1
                    else
                        table.remove(GAME.inventory, i)
                    end
                    break
                end
            end
        end
        
        -- End turn after a short delay
        self.turnEndDelay = 0.7
    else
        -- Item use failed
        self:addLog("Item use failed!")
    end
end

-- Execute defend action
local function executeDefend(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar then return end
    
    -- Apply defense buff
    currentChar.status.defending = {
        value = 2.0,  -- Double defense
        duration = 1  -- Until next turn
    }
    
    -- Add to combat log
    self:addLog(currentChar.name .. " takes a defensive stance!")
    
    -- End turn after a short delay (like other actions)
    self.turnEndDelay = 0.5 -- Use a short delay consistent with others or adjust as needed
end

-- Confirm selected action
local function confirmAction(self)
    if self.selectedAction == "skill" then
        -- Find selected skill
        local selectedSkill = nil
        for _, skill in ipairs(self.elements.skillList.skills) do
            if skill.selected then
                selectedSkill = skill
                break
            end
        end
        
        if selectedSkill then
            -- Set selected skill
            self.selectedSkill = selectedSkill.skill
            
            -- Determine target based on skill target type
            if selectedSkill.skill.target == "single_enemy" then
                if #self.enemies > 1 then
                    -- Show enemy selection UI
                    self:showEnemySelectionUI("skill")
                    return -- Wait for enemy selection
                else
                    -- If only one enemy, target it directly
                    self.selectedTarget = self.enemy
                    self:executeSkill()
                end
            elseif selectedSkill.skill.target == "all_enemies" then
                -- Target all enemies (handled in execution)
                self.selectedTarget = nil -- Special case for all enemies
                self:executeSkill()
            elseif selectedSkill.skill.target == "single_ally" then
                -- Show party selection UI instead of auto-targeting
                self:showPartySelectionUI("skill")
                return -- Wait for party selection
            elseif selectedSkill.skill.target == "all_allies" then
                -- Target all allies (handled in execution)
                self.selectedTarget = self.party
                -- Execute skill immediately
                self:executeSkill()
            elseif selectedSkill.skill.target == "self" then
                self.selectedTarget = self.party[self.currentCharacter]
                -- Execute skill immediately
                self:executeSkill()
            else
                -- Default case for any other target types
                self.selectedTarget = self.party[self.currentCharacter]
                self:executeSkill()
            end
        else
            -- No skill selected, do nothing
            self:addLog("No skill selected.", {1, 0.5, 0})
            return
        end
    elseif self.selectedAction == "item" then
        -- Find selected item
        local selectedItem = nil
        for _, item in ipairs(self.elements.itemList.items) do
            if item.selected then
                selectedItem = item
                break
            end
        end
        
        if selectedItem then
            -- Set selected item
            self.selectedItem = selectedItem.item
            
            -- Check if item targets a single ally
            if selectedItem.item.target == "single_ally" then
                -- Show party selection UI
                self:showPartySelectionUI("item")
                return -- Wait for party selection
            else
                -- For other item types, target self for now
                self.selectedTarget = self.party[self.currentCharacter]
                -- Execute item use immediately
                self:executeItemUse()
            end
        else
            -- No item selected, do nothing
            self:addLog("No item selected.", {1, 0.5, 0})
            return
        end
    end
    
    -- Hide lists
    self:hideSelectionLists()
end

return {
    executePlayerAction = executePlayerAction,
    executeSkill = executeSkill,
    executeStealSkill = executeStealSkill,
    applySkillEffect = applySkillEffect,
    executeItemUse = executeItemUse,
    executeDefend = executeDefend,
    confirmAction = confirmAction
}