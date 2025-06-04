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
    
    -- Prevent duplicate execution
    if self.actionInProgress then
        if GAME.debug then
            print("Action already in progress, ignoring duplicate execution")
        end
        return
    end
    
    -- Mark action as in progress
    self.actionInProgress = true
    
    -- Immediately hide all action buttons to prevent exploitation
    self:hideActionButtons()
    self:hideSelectionLists()
    
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
        
        -- Check for hit/miss
        local characterSystem = require("gameplay/character")
        local hitChance = 70  -- Base hit chance
        
        -- Determine if this is a ranged attack based on weapon type
        local isRangedAttack = false
        if currentChar.equipment and currentChar.equipment.weapon then
            local weapon = currentChar.equipment.weapon
            if weapon.category == "bow" or weapon.category == "crossbow" or 
               weapon.subtype == "throwing" or weapon.name:lower():find("bow") then
                isRangedAttack = true
            end
        end
        
        if isRangedAttack then
            hitChance = characterSystem:calculateRangedHitChance(
                currentChar.attributes.DEX, 
                currentChar.attributes.STR
            )
        else
            hitChance = characterSystem:calculateMeleeHitChance(
                currentChar.attributes.STR, 
                currentChar.attributes.DEX
            )
        end
        
        -- Check if attack hits
        if math.random(1, 100) > hitChance then
            self:addLog(currentChar.name .. " misses!", {0.8, 0.4, 0.4})
            -- Clear selection state and end turn
            self.selectedAction = nil
            self.selectedTarget = nil
            self:hideActionButtons()
            self:hideSelectionLists()
            self.turnEndDelay = 0.7
            return
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
        
        -- Check for enemy dodge
        local characterSystem = require("gameplay/character")
        local dodgeChance = characterSystem:calculateDodgeChance(targetEnemy)
        if math.random(1, 100) <= dodgeChance then
            self:addLog(targetEnemy.name .. " dodges the attack!", {0.8, 0.8, 0.2})
            -- Clear selection state and end turn
            self.selectedAction = nil
            self.selectedTarget = nil
            self:hideActionButtons()
            self:hideSelectionLists()
            self.turnEndDelay = 0.7
            return
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
    
    -- Clear selection state
    self.selectedAction = nil
    self.selectedTarget = nil
    
    -- Hide all UI elements (redundant but safe)
    self:hideActionButtons()
    self:hideSelectionLists()
    if self.elements.confirmButton then self.elements.confirmButton.visible = false end
    if self.elements.backButton then self.elements.backButton.visible = false end
    if self.elements.itemConfirmButton then self.elements.itemConfirmButton.visible = false end
    if self.elements.itemBackButton then self.elements.itemBackButton.visible = false end
    
    -- End turn after a short delay
    self.turnEndDelay = 0.7
end

-- Execute skill use
local function executeSkill(self, caster, skill, target, fromQueue)
    -- Use parameters if provided (for when called from spell queue), otherwise use selected values
    local currentChar = caster or self.party[self.currentCharacter]
    local selectedSkill = skill or self.selectedSkill
    local selectedTarget = target or self.selectedTarget
    
    if not currentChar or not selectedSkill then 
        if GAME.debug then
            print("executeSkill failed: ", currentChar and "Character OK" or "No character", 
                  selectedSkill and "Skill OK" or "No skill")
        end
        return 
    end
    
    -- Prevent duplicate execution (but only for player-initiated skills, not queue executions)
    if not fromQueue and self.actionInProgress then
        if GAME.debug then
            print("Skill action already in progress, ignoring duplicate execution")
        end
        return
    end
    
    -- Mark action as in progress (but only for player-initiated skills)
    if not fromQueue then
        self.actionInProgress = true
        -- Immediately hide all action buttons to prevent exploitation
        self:hideActionButtons()
        self:hideSelectionLists()
    end
    
    -- Log skill execution for debugging
    if GAME.debug then
        print("Executing skill: " .. selectedSkill.name)
        print("  Target type: " .. (selectedSkill.target or "unknown"))
        print("  Selected target: " .. (selectedTarget and selectedTarget.name or "none/all"))
        print("  From queue: " .. (fromQueue and "true" or "false"))
    end
    
    -- Check target for single-enemy skills
    if selectedSkill.target == "single_enemy" and not selectedTarget then
        self:addLog("No valid target for skill.", {1, 0.5, 0})
        if GAME.debug then print("Missing target for skill " .. selectedSkill.name) end
        return
    end
    
    -- If this is not from the queue and the skill has a casting time, add to queue instead of executing now
    if not fromQueue and selectedSkill.castingTime and selectedSkill.castingTime > 0 then
        -- Add to spell queue and defer execution
        self:addToSpellQueue(currentChar, selectedSkill, selectedTarget)
        
        -- End turn after a short delay
        self.turnEndDelay = 0.7
        return
    end
    
    -- From here on, the skill is actually being executed
    
    -- Check MP cost (only when not from queue, since MP was already deducted when added to queue)
    if not fromQueue and currentChar.currentMP < selectedSkill.mpCost then
        self:addLog("Not enough MP!")
        return
    end
    
    -- Deduct MP (only when not from queue)
    if not fromQueue then
        currentChar.currentMP = currentChar.currentMP - selectedSkill.mpCost
    end
    
    -- Add animation delay
    self.animationDelay = 0.5
    
    -- Handle summon skills specifically
    if selectedSkill.type == "summon" then
        -- Play summon sound
        assetManager:playSound("spell")
        
        -- Process the summon
        local success = self:processSummonSkill(currentChar, selectedSkill)
        
        if success then
            -- Recalculate turn order to include new minion
            self:determineTurnOrder()
        end
        
        -- End turn after a short delay
        self.turnEndDelay = 0.7
        return
    end
    
    -- Special case for Steal skill
    if selectedSkill.name == "Steal" then
        self:executeStealSkill(currentChar)
        return
    end
    
    -- Handle different skill targets
    if selectedSkill.target == "single_enemy" then
        -- Apply damage to the selected enemy
        local damage, isCritical = 0, false
        
        -- Make sure character has this skill before calculating damage
        if currentChar.skills and currentChar.skills[selectedSkill.name] then
            -- Create a mutable copy of the skill for this calculation
            local skillCopy = {}
            for k, v in pairs(selectedSkill) do
                skillCopy[k] = v
            end
            
            damage, isCritical = skillSystem:calculateDamage(
                skillCopy,
                currentChar,
                selectedTarget,
                currentChar.skills[selectedSkill.name].level
            )
            
            -- Apply damage type modifier if skill has a damage type
            if skillCopy.damageType then
                local damageMultiplier = damageTypes:calculateModifier(skillCopy.damageType, selectedTarget)
                damage = math.floor(damage * damageMultiplier)
                
                -- Log damage type effectiveness
                local resistText, resistColor = damageTypes:getDisplayText(damageMultiplier)
                if resistText then
                    self:addLog(selectedTarget.name .. " " .. resistText .. " to " .. skillCopy.damageType .. "!", resistColor)
                end
            end
            
            -- Apply unique item effects to the damage
            local damageContext = {
                eventType = "CALCULATE_OUTGOING_DAMAGE",
                character = currentChar,
                target = selectedTarget,
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
            for k, v in pairs(selectedSkill) do
                skillCopy[k] = v
            end
            
            damage, isCritical = skillSystem:calculateDamage(
                skillCopy,
                currentChar,
                selectedTarget,
                1
            )
            
            -- Apply unique item effects to the damage
            local damageContext = {
                eventType = "CALCULATE_OUTGOING_DAMAGE",
                character = currentChar,
                target = selectedTarget,
                skill = skillCopy, -- Pass the mutable copy
                value = damage,
                is_critical = isCritical
            }
            damage = uniqueItemSystem:processEffects(damageContext)
            
            -- Update isCritical if needed
            isCritical = damageContext.is_critical
        end
        
        -- Check for target dodge (only for damage-dealing skills)
        if damage > 0 then
            local characterSystem = require("gameplay/character")
            local dodgeChance = characterSystem:calculateDodgeChance(selectedTarget)
            if math.random(1, 100) <= dodgeChance then
                self:addLog(selectedTarget.name .. " dodges " .. selectedSkill.name .. "!", {0.8, 0.8, 0.2})
                -- End turn after a short delay
                self.turnEndDelay = 0.7
                return
            end
        end
        
        -- Apply damage
        selectedTarget.currentHP = math.max(0, selectedTarget.currentHP - damage)
        
        -- Play appropriate sound
        if selectedSkill.type == "magical" then
            assetManager:playSound("spell")
        else
            assetManager:playSound("attack")
        end
        
        -- Add to combat log
        local logText = currentChar.name .. " uses " .. selectedSkill.name
        logText = logText .. " on " .. selectedTarget.name
        logText = logText .. " for " .. damage .. " damage!"
        
        if isCritical then
            logText = logText .. " Critical hit!"
        end
        
        self:addLog(logText)
        
        -- Check for enemy defeat
        if selectedTarget.currentHP <= 0 then
            self:enemyDefeated(selectedTarget)
        end
        
        -- Apply skill effects using the new unified structure
        if selectedSkill.effects and selectedTarget.active then
            -- Handle multiple effects
            for _, effect in ipairs(selectedSkill.effects) do
                local effectType = effect.type
                local chance = effect.chance or 1.0
                local duration = effect.duration or 3
                local strength = effect.value or effect.strength or 1
                local extraParams = {}
                
                -- Handle multiplier effects
                if effect.multiplier then
                    extraParams.multiplier = effect.multiplier
                end
                
                -- Handle elemental effects
                if effect.element then
                    extraParams.element = effect.element
                end
                
                -- Check if effect should be applied per hit
                local appliesPerHit = effect.perHit or false
                local hits = 1
                
                if selectedSkill.hits and appliesPerHit then
                    hits = selectedSkill.hits
                end
                
                -- Apply effect for each hit (or just once if not per-hit)
                for i = 1, hits do
                    local success, message = statusEffects:apply(
                        effectType, 
                        selectedTarget, 
                        duration, 
                        strength, 
                        chance, 
                        extraParams
                    )
                    
                    if success and statusEffects.effects[effectType] then
                        self:addLog(selectedTarget.name .. " is afflicted with " .. 
                                     statusEffects.effects[effectType].name .. "!", 
                                     {0.8, 0.6, 0.8})
                    end
                end
            end
        -- Backward compatibility for single effect
        elseif selectedSkill.effect and selectedTarget.active then
            local effect = selectedSkill.effect
            local effectType = effect.type or effect.stat -- Support both formats
            local chance = effect.chance or 1.0
            local duration = effect.duration or 3
            local strength = effect.value or effect.strength or 1
            local extraParams = {}
            
            -- Handle multiplier effects
            if effectType:find("multiplier") and effect.value then
                extraParams.multiplier = effect.value
            end
            
            local success, message = statusEffects:apply(
                effectType, 
                selectedTarget, 
                duration, 
                strength, 
                chance, 
                extraParams
            )
            
            if success and statusEffects.effects[effectType] then
                self:addLog(selectedTarget.name .. " is afflicted with " .. 
                             statusEffects.effects[effectType].name .. "!", 
                             {0.8, 0.6, 0.8})
            end
        end
    elseif selectedSkill.target == "all_enemies" then
        -- Apply to all enemies
        local totalDamage = 0
        local defeatedCount = 0
        
        for _, enemy in ipairs(self.enemies) do
            if enemy.active then
                local damage, isCritical = 0, false
                
                -- Create a mutable copy of the skill for this calculation
                local skillCopy = {}
                for k, v in pairs(selectedSkill) do
                    skillCopy[k] = v
                end
                
                -- Calculate damage for each enemy
                if currentChar.skills and currentChar.skills[selectedSkill.name] then
                    damage, isCritical = skillSystem:calculateDamage(
                        skillCopy,
                        currentChar,
                        enemy,
                        currentChar.skills[selectedSkill.name].level
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
                
                -- Check for enemy dodge
                local characterSystem = require("gameplay/character")
                local dodgeChance = characterSystem:calculateDodgeChance(enemy)
                if math.random(1, 100) <= dodgeChance then
                    self:addLog(enemy.name .. " dodges " .. selectedSkill.name .. "!", {0.8, 0.8, 0.2})
                else
                    enemy.currentHP = math.max(0, enemy.currentHP - damage)
                    totalDamage = totalDamage + damage
                end
                
                -- Apply skill effects
                if selectedSkill.effect then
                    self:applySkillEffect(selectedSkill, currentChar, enemy)
                end
                
                -- Check for enemy defeat
                if enemy.currentHP <= 0 and enemy.active then
                    enemy.active = false
                    defeatedCount = defeatedCount + 1
                end
            end
        end
        
        -- Play appropriate sound
        if selectedSkill.type == "magical" then
            assetManager:playSound("spell")
        else
            assetManager:playSound("attack")
        end
        
        -- Add to combat log
        local logText = currentChar.name .. " uses " .. selectedSkill.name
        logText = logText .. " on all enemies for " .. totalDamage .. " total damage!"
        self:addLog(logText)
        
        -- Log defeated enemies if any
        if defeatedCount > 0 then
            self:addLog(defeatedCount .. " enemies were defeated!", {0, 1, 0})
            
            -- Check if all enemies are defeated
            self:checkAllEnemiesDefeated()
        end
    elseif selectedSkill.target == "single_ally" or 
           selectedSkill.target == "self" then
        -- Handle healing
        if selectedSkill.formula == "healing" then
            local healing = 0
            -- Make sure character has this skill
            if currentChar.skills and currentChar.skills[selectedSkill.name] then
                healing = skillSystem:calculateDamage(
                    selectedSkill,
                    currentChar,
                    selectedTarget,
                    currentChar.skills[selectedSkill.name].level
                )
            else
                healing = skillSystem:calculateDamage(
                    selectedSkill,
                    currentChar,
                    selectedTarget,
                    1
                )
            end
            
            selectedTarget.currentHP = math.min(
                selectedTarget.maxHP,
                selectedTarget.currentHP + healing
            )
            
            -- Play heal sound
            assetManager:playSound("spell")
            
            -- Add to combat log
            if selectedTarget == currentChar then
                self:addLog(
                    currentChar.name .. " uses " .. selectedSkill.name .. 
                    " and heals self for " .. healing .. " HP!",
                    {0.2, 0.8, 0.2}
                )
            else
                self:addLog(
                    currentChar.name .. " uses " .. selectedSkill.name .. 
                    " and heals " .. selectedTarget.name .. " for " .. healing .. " HP!",
                    {0.2, 0.8, 0.2}
                )
            end
        end
        
        -- Apply skill effects
        if selectedSkill.effect then
            self:applySkillEffect(selectedSkill, currentChar, selectedTarget)
        end
    elseif selectedSkill.target == "all_allies" then
        -- Apply to all party members
        for _, ally in ipairs(self.party) do
            if ally.active then
                -- Handle healing
                if selectedSkill.formula == "healing" then
                    local healing = 0
                    -- Make sure character has this skill
                    if currentChar.skills and currentChar.skills[selectedSkill.name] then
                        healing = skillSystem:calculateDamage(
                            selectedSkill,
                            currentChar,
                            ally,
                            currentChar.skills[selectedSkill.name].level
                        )
                    else
                        healing = skillSystem:calculateDamage(
                            selectedSkill,
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
                if selectedSkill.effect then
                    self:applySkillEffect(selectedSkill, currentChar, ally)
                end
            end
        end
        
        -- Play heal sound
        assetManager:playSound("spell")
        
        -- Add to combat log
        self:addLog(
            currentChar.name .. " uses " .. selectedSkill.name .. 
            " on the entire party!",
            {0.2, 0.8, 0.2}
        )
    elseif selectedSkill.target == "none" then
        -- Handle target-less skills (like some summons)
        -- Play appropriate sound
        assetManager:playSound("spell")
        
        -- Add to combat log
        self:addLog(
            currentChar.name .. " uses " .. selectedSkill.name .. "!",
            {0.5, 0.5, 1}
        )
    end
    
    -- Clear selection state
    self.selectedAction = nil
    self.selectedSkill = nil
    self.selectedTarget = nil
    
    -- Hide all UI elements
    self:hideActionButtons()
    self:hideSelectionLists()
    if self.elements.confirmButton then self.elements.confirmButton.visible = false end
    if self.elements.backButton then self.elements.backButton.visible = false end
    if self.elements.itemConfirmButton then self.elements.itemConfirmButton.visible = false end
    if self.elements.itemBackButton then self.elements.itemBackButton.visible = false end
    
    -- End turn after a short delay
    self.turnEndDelay = 0.7
end

-- Execute steal skill
local function executeStealSkill(self, character)
    -- Play effect sound
    assetManager:playSound("spell")
    
    -- Get the Steal skill definition from the skill system
    local stealSkill = skillSystem:getSkill("Steal")
    
    -- Calculate steal chance based on character level and enemy level
    local effect = nil
    if character.skills and character.skills.Steal then
        effect = skillSystem:calculateSkillEffect(
            stealSkill, 
            character, 
            self.enemy, 
            character.skills.Steal.level
        )
    else
        effect = skillSystem:calculateSkillEffect(
            stealSkill, 
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
        if stolenItem and stolenItem.name then
            self:addLog(
                character.name .. " successfully steals " .. stolenItem.name .. "!",
                {0.2, 0.8, 0.8}
            )
        else
            self:addLog(
                character.name .. " successfully steals an item!",
                {0.2, 0.8, 0.8}
            )
        end
    else
        -- Failed to steal
        self:addLog(
            character.name .. " fails to steal anything!",
            {0.8, 0.5, 0.2}
        )
    end
    
    -- Clear selection state
    self.selectedAction = nil
    self.selectedTarget = nil
    
    -- Hide all UI elements
    self:hideActionButtons()
    self:hideSelectionLists()
    if self.elements.confirmButton then self.elements.confirmButton.visible = false end
    if self.elements.backButton then self.elements.backButton.visible = false end
    if self.elements.itemConfirmButton then self.elements.itemConfirmButton.visible = false end
    if self.elements.itemBackButton then self.elements.itemBackButton.visible = false end
    
    -- End turn after a short delay
    self.turnEndDelay = 0.7
end

-- Apply skill effect to target
local function applySkillEffect(self, skill, caster, target)
    if not skill.effect and not skill.effects then return end
    
    local skillLevel = 1
    -- Safely get the skill level if it exists
    if caster.skills and caster.skills[skill.name] and caster.skills[skill.name].level then
        skillLevel = caster.skills[skill.name].level
    end
    
    -- Process unified effects list first
    if skill.effects then
        for _, effect in ipairs(skill.effects) do
            local effectType = effect.type
            local chance = effect.chance or 1.0
            local duration = effect.duration or 3
            local strength = effect.value or effect.strength or 1
            local extraParams = {}
            
            -- Handle multiplier effects
            if effect.multiplier then
                extraParams.multiplier = effect.multiplier
            end
            
            -- Apply level scaling if available
            if skill.levelModifier and type(skill.levelModifier) == "function" then
                local modifier = skill.levelModifier(skillLevel)
                if type(modifier) == "number" then
                    strength = strength * modifier
                elseif type(modifier) == "table" then
                    if modifier.power then
                        strength = strength * modifier.power
                    end
                    if modifier.chance then
                        chance = modifier.chance
                    end
                    if modifier.duration then
                        duration = modifier.duration
                    end
                    if modifier.multiplier then
                        extraParams.multiplier = modifier.multiplier
                    end
                end
            end
            
            -- Apply the status effect
            local success, message = statusEffects:apply(
                effectType,
                target,
                duration,
                strength,
                chance,
                extraParams
            )
            
            if success and statusEffects.effects[effectType] then
                -- Add to combat log
                self:addLog(
                    target.name .. " is affected by " .. statusEffects.effects[effectType].name .. "!",
                    {0.8, 0.8, 0.2}
                )
            end
        end
        return
    end
    
    -- Backward compatibility for old effect format
    if skill.effect then
        local effect = skillSystem:calculateSkillEffect(
            skill,
            caster,
            target,
            skillLevel
        )
        
        -- Apply using the unified structure
        if effect.stat then
            -- Single stat effect
            local effectType = effect.stat
            local value = effect.value or 1
            local duration = effect.duration or 3
            local extraParams = {}
            
            -- Handle multiplier effects
            if effectType:find("multiplier") then
                extraParams.multiplier = value
                value = 1 -- Use value of 1 for multipliers, actual value goes in extraParams
            end
            
            local success, message = statusEffects:apply(
                effectType,
                target,
                duration,
                value,
                1.0, -- No chance in old format, always apply
                extraParams
            )
            
            if success then
                -- Add to combat log
                self:addLog(
                    target.name .. " is affected by " .. (statusEffects.effects[effectType] and 
                                                          statusEffects.effects[effectType].name or 
                                                          effectType) .. "!",
                    {0.8, 0.8, 0.2}
                )
            end
        elseif effect.stats then
            -- Multiple stat effects
            for stat, value in pairs(effect.stats) do
                local effectType = stat
                local duration = effect.duration or 3
                local extraParams = {}
                
                -- Handle multiplier effects
                if effectType:find("multiplier") then
                    extraParams.multiplier = value
                    value = 1 -- Use value of 1 for multipliers, actual value goes in extraParams
                end
                
                local success, message = statusEffects:apply(
                    effectType,
                    target,
                    duration,
                    value,
                    1.0, -- No chance in old format, always apply
                    extraParams
                )
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
                    "poison", "burn", "bleed", "stun", "silence", "vulnerable"
                }
                
                for _, status in ipairs(negativeEffects) do
                    if statusEffects:has(target, status) then
                        statusEffects:remove(target, status)
                    end
                end
                
                -- Add to combat log
                self:addLog(
                    target.name .. "'s negative status effects are removed!",
                    {0.2, 0.8, 0.2}
                )
                
                -- If this is a Purify skill, apply custom healing after removing effects
                if skill.name == "Purify" then
                    local healing = skillSystem:calculateDamage(
                        skill,
                        caster,
                        target,
                        skillLevel
                    )
                    
                    target.currentHP = math.min(
                        target.maxHP,
                        target.currentHP + healing
                    )
                    
                    self:addLog(
                        target.name .. " is healed for " .. healing .. " HP!",
                        {0.2, 0.8, 0.2}
                    )
                end
            else
                -- Remove specific status
                if statusEffects:has(target, effect.removeStatus) then
                    statusEffects:remove(target, effect.removeStatus)
                    
                    -- Add to combat log
                    local statusName = statusEffects.effects[effect.removeStatus] and 
                                       statusEffects.effects[effect.removeStatus].name or
                                       effect.removeStatus
                                       
                    self:addLog(
                        target.name .. "'s " .. statusName .. " is removed!",
                        {0.2, 0.8, 0.2}
                    )
                end
            end
        end
    end
end

-- Execute item use
local function executeItemUse(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar or not self.selectedItem then return end
    
    -- Prevent duplicate execution
    if self.actionInProgress then
        if GAME.debug then
            print("Item action already in progress, ignoring duplicate execution")
        end
        return
    end
    
    -- Mark action as in progress
    self.actionInProgress = true
    
    -- Immediately hide all action buttons to prevent exploitation
    self:hideActionButtons()
    self:hideSelectionLists()
    
    -- Make sure we have a valid target
    if not self.selectedTarget then
        self:addLog("No target selected for item use.", {1, 0.5, 0})
        return
    end
    
    -- Validate the item before using it
    if not self.selectedItem then
        self:addLog("Invalid item! Cannot use.", {1, 0, 0})
        return false
    end
    
    -- Make sure the item is consumable
    if self.selectedItem.type ~= "consumable" then
        self:addLog("Only consumable items can be used in combat!", {1, 0.5, 0.5})
        return false
    end
    
    -- Use the item directly with the itemSystem
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
    
    -- Prevent duplicate execution
    if self.actionInProgress then
        if GAME.debug then
            print("Defend action already in progress, ignoring duplicate execution")
        end
        return
    end
    
    -- Mark action as in progress
    self.actionInProgress = true
    
    -- Immediately hide all action buttons to prevent exploitation
    self:hideActionButtons()
    self:hideSelectionLists()
    
    -- Apply defense buff
    currentChar.status.defending = {
        value = 2.0,  -- Double defense
        duration = 1  -- Until next turn
    }
    
    -- Add to combat log
    self:addLog(currentChar.name .. " takes a defensive stance!")
    
    -- Clear selection state
    self.selectedAction = nil
    self.selectedTarget = nil
    
    -- Hide all UI elements (redundant but safe)
    self:hideActionButtons()
    self:hideSelectionLists()
    
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
            -- Get the skill definition from the UI element
            local skillToUse = selectedSkill.skill
            self.selectedSkill = skillToUse
            
            -- Determine target based on skill target type
            if skillToUse.target == "single_enemy" then
                if #self.enemies > 1 then
                    -- Show enemy selection UI
                    self:showEnemySelectionUI("skill")
                    return -- Wait for enemy selection
                else
                    -- If only one enemy, target it directly
                    selectedTarget = self.enemy
                    self.selectedTarget = selectedTarget
                    self:executeSkill()
                end
            elseif skillToUse.target == "all_enemies" then
                -- Target all enemies (handled in execution)
                selectedTarget = nil -- Special case for all enemies
                self.selectedTarget = selectedTarget
                self:executeSkill()
            elseif skillToUse.target == "single_ally" then
                -- Show party selection UI instead of auto-targeting
                self:showPartySelectionUI("skill")
                return -- Wait for party selection
            elseif skillToUse.target == "all_allies" then
                -- Target all allies (handled in execution)
                selectedTarget = self.party
                self.selectedTarget = selectedTarget
                -- Execute skill immediately
                self:executeSkill()
            elseif skillToUse.target == "self" then
                selectedTarget = self.party[self.currentCharacter]
                self.selectedTarget = selectedTarget
                -- Execute skill immediately
                self:executeSkill()
            else
                -- Default case for any other target types
                selectedTarget = self.party[self.currentCharacter]
                self.selectedTarget = selectedTarget
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
            -- Set selected item - make sure to handle different item structures
            self.selectedItem = selectedItem.item or selectedItem
            
            -- Create a local variable for easier access and add safety checks
            local itemToUse = self.selectedItem
            
            -- Safety check for item target property
            local itemTarget = "self" -- Default target type if not specified
            if itemToUse and itemToUse.target then
                itemTarget = itemToUse.target
            end
            
            -- Check if item targets a single ally
            if itemTarget == "single_ally" then
                -- Show party selection UI
                self:showPartySelectionUI("item")
                return -- Wait for party selection
            else
                -- For other item types, target self for now
                selectedTarget = self.party[self.currentCharacter]
                self.selectedTarget = selectedTarget
                
                -- Make a copy of the selected item before using it (in case it gets cleared during usage)
                local selectedItemCopy = self.selectedItem
                
                -- Reset UI state immediately to avoid UI issues
                -- Hide all selection UIs and item-specific buttons
                self:hideSelectionLists()
                
                if self.elements.itemConfirmButton then
                    self.elements.itemConfirmButton.visible = false
                end
                
                if self.elements.itemBackButton then
                    self.elements.itemBackButton.visible = false
                end
                
                -- Use the item system
                local success = itemSystem:useItem(selectedItemCopy, self.selectedTarget)
                
                if success then
                    -- Play pickup sound
                    assetManager:playSound("pickup")
                    
                    -- Add to combat log with safety checks for names
                    local itemName = selectedItemCopy and selectedItemCopy.name or "item"
                    local targetName = self.selectedTarget and self.selectedTarget.name or "target"
                    
                    self:addLog(
                        "Used " .. itemName .. " on " .. targetName,
                        {0.2, 0.8, 0.8}
                    )
                    
                    -- Remove item from inventory if it was used successfully
                    if GAME.inventory and selectedItemCopy then
                        for i, item in ipairs(GAME.inventory) do
                            if item.name == selectedItemCopy.name then
                                if item.count and item.count > 1 then
                                    item.count = item.count - 1
                                else
                                    table.remove(GAME.inventory, i)
                                end
                                break
                            end
                        end
                    end
                    
                    -- End turn after a short delay - ensure this is properly set
                    self.turnEndDelay = 0.7
                    
                    -- Force end player's turn and proceed to next turn
                    -- Use timer to delay the turn end to allow animations and reading log messages
                    self.pendingAction = function()
                        self:nextTurn()
                    end
                else
                    -- If item use failed, let player select another action
                    self:addLog("Item use failed!", {1, 0.5, 0.5})
                    self:showActionButtons()
                end
                
                -- Clear selection state
                self.selectedAction = nil
                self.selectedItem = nil
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