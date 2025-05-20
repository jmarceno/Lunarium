-- Trap System
-- Handles trap related logic and effects
local assetManager = require("assets/assetManager")
local characterSystem = require("gameplay/character")
local minionManager = require("gameplay/minionManager")

local trapSystem = {}

-- Constants for trap placement and detection
trapSystem.ACTIVE_TRAP_DISTANCE = 4.0 -- Maximum distance to show trap prompt
trapSystem.BASE_DETECTION_RANGE = 4.0  -- Base detection range
trapSystem.ROGUE_DETECTION_RANGE = 12.0 -- Rogue detection range
trapSystem.MAGE_DETECTION_RANGE = 8.0  -- Mage detection range

-- Calculate minimum distance between traps based on party composition
function trapSystem:calculateMinTrapDistance(party)
    -- Start with base detection range
    local maxDetectionRange = self.BASE_DETECTION_RANGE
    
    -- Check if party has rogues or mages
    if party then
        for _, member in ipairs(party) do
            if member.class == "Rogue" then
                maxDetectionRange = self.ROGUE_DETECTION_RANGE
                break
            elseif member.class == "Mage" and maxDetectionRange < self.MAGE_DETECTION_RANGE then
                maxDetectionRange = self.MAGE_DETECTION_RANGE
            end
        end
    end
    
    -- Calculate minimum distance with 20% buffer
    local minDistance = 1.2 * (maxDetectionRange + self.ACTIVE_TRAP_DISTANCE)
    
    return minDistance
end

-- Helper function for Line of Sight
local function hasLineOfSight(map, x1, y1, x2, y2)
    if not map or not map.getCell then return false end -- Safety check

    local px1, py1 = math.floor(x1), math.floor(y1)
    local px2, py2 = math.floor(x2), math.floor(y2)

    local dx = math.abs(px2 - px1)
    local dy = -math.abs(py2 - py1)

    local sx = (px1 < px2) and 1 or -1
    local sy = (py1 < py2) and 1 or -1

    local err = dx + dy
    local e2

    local currentX, currentY = px1, py1

    -- Maximum iterations to prevent infinite loops in unexpected scenarios
    local maxIterations = (dx + math.abs(dy)) * 2 -- A generous limit
    local iteration = 0

    while iteration < maxIterations do
        iteration = iteration + 1
        -- Check current cell, but skip the very first cell (player's cell)
        -- and the very last cell (trap's cell) for obstruction.
        -- We only care about cells *between* player and trap.
        if not (currentX == px1 and currentY == py1) and not (currentX == px2 and currentY == py2) then
            if map:getCell(currentX, currentY) > 0 then
                return false -- Wall in the way
            end
        end

        if currentX == px2 and currentY == py2 then
            break -- Reached target
        end

        e2 = 2 * err
        if e2 >= dy then -- Move in x-direction
            if currentX == px2 then break end -- Avoid overshooting if already at target x
            err = err + dy
            currentX = currentX + sx
        end
        if e2 <= dx then -- Move in y-direction
            if currentY == py2 then break end -- Avoid overshooting if already at target y
            err = err + dx
            currentY = currentY + sy
        end
    end
    return true -- No obstruction
end

-- Initialize the trap properties in the map
function trapSystem:initializeMap(map)
    -- Add active traps property to the map
    map.activeTraps = {}
    
    -- Add methods to the map
    
    -- Method to check if a tile is a trap
    map.isTileTrap = function(self, x, y)
        for _, trap in ipairs(self.activeTraps) do
            if trap.x == x and trap.y == y and trap.isTrap then
                return true
            end
        end
        return false
    end
    
    -- Method to get a trap at a specific location
    map.getTrap = function(self, x, y)
        for _, trap in ipairs(self.activeTraps) do
            if trap.x == x and trap.y == y then
                return trap
            end
        end
        return nil
    end
    
    -- Method to get hint factor for traps (for floor visualization)
    map.getHintFactor = function(self, x, y, elementType)
        if elementType == "floor" then
            local trap = self:getTrap(x, y)
            if trap then
                -- Directly return the trap's current hintFactor.
                -- This factor is managed by updateTrapHintFactors based on proximity, detection, and state.
                -- It will be 0.0 if too far, disarmed, or inactive.
                -- It will be > 0 for passive hints or detected traps.
                return trap.hintFactor or 0.0
            end
        end
        return 0.0
    end
    
    return map
end

-- Add a trap to the map
function trapSystem:addTrap(map, x, y, props)
    local trap = {
        x = x,
        y = y,
        isTrap = true,
        trapType = props.trapType or "spike",
        isTrapActive = props.isTrapActive ~= false, -- Default to true
        isTrapDetected = props.isTrapDetected or false,
        isTrapDisarmed = props.isTrapDisarmed or false,
        hintFactor = props.hintFactor or 0.0,
        floorTextureVariant = props.floorTextureVariant,
        -- Store integer cell coordinates for quicker access in LOS checks if needed
        cellX = math.floor(x),
        cellY = math.floor(y)
    }
    
    -- Set the floor texture if a variant is provided
    if trap.floorTextureVariant then
        map:setFloorTexture(x, y, trap.floorTextureVariant)
    end
    
    table.insert(map.activeTraps, trap)
    return trap
end

-- Helper function to activate a trap and apply its effects
function trapSystem:activateTrap(trap, target, allTargets)
    if not trap or not trap.isTrapActive or trap.isTrapDisarmed then
        return false
    end
    
    -- Get the party and minions
    local party = GAME.party or {target}
    local minions = {}
    if minionManager and minionManager.activeMinions then
        minions = minionManager.activeMinions
    end
    
    -- Determine how many party members will be affected (1-4)
    local maxPartyMembers = #party
    local affectedPartyCount = math.random(1, maxPartyMembers)
    
    -- Select which party members will be affected
    local affectedPartyMembers = {}
    if affectedPartyCount == maxPartyMembers then
        -- All party members affected
        affectedPartyMembers = party
    else
        -- Randomly select party members
        local indices = {}
        for i = 1, maxPartyMembers do
            table.insert(indices, i)
        end
        
        -- Shuffle the indices
        for i = #indices, 2, -1 do
            local j = math.random(i)
            indices[i], indices[j] = indices[j], indices[i]
        end
        
        -- Select the first N indices
        for i = 1, affectedPartyCount do
            table.insert(affectedPartyMembers, party[indices[i]])
        end
    end
    
    -- Determine if minions will be affected (50% chance per minion)
    local affectedMinions = {}
    for _, minion in ipairs(minions) do
        if math.random() < 0.5 then
            table.insert(affectedMinions, minion)
        end
    end
    
    local trapEffects = {
        -- Spike trap (direct damage)
        spike = function(targets, trap)
            local baseDamage = 5
            local damageType = "physical"
            local totalDamage = 0
            
            if assetManager.sounds.trap_spike_trigger then
                assetManager.sounds.trap_spike_trigger:play()
            end
            
            -- Apply damage to each affected target
            for _, target in ipairs(targets) do
                totalDamage = totalDamage + characterSystem:applyDamage(target, baseDamage, damageType)
            end
            
            return totalDamage
        end,
        
        -- Gas trap (damage over time)
        gas = function(targets, trap)
            local baseDamage = 2
            local duration = 3
            local damageType = "poison"
            local totalDamage = baseDamage * #targets -- Estimate total damage
            
            if assetManager.sounds.trap_gas_trigger then
                assetManager.sounds.trap_gas_trigger:play()
            end
            
            -- Apply status effect to each affected target
            for _, target in ipairs(targets) do
                characterSystem:applyStatusEffect(target, "poison", {
                    duration = duration,
                    damage = baseDamage,
                    type = damageType
                })
            end
            
            return totalDamage
        end,
        
        -- Dart trap (direct damage, potential status effect)
        dart = function(targets, trap)
            local baseDamage = 3
            local damageType = "physical"
            local totalDamage = 0
            
            if assetManager.sounds.trap_arrow_fire then
                assetManager.sounds.trap_arrow_fire:play()
            end
            
            -- Apply damage and potentially status effect to each affected target
            for _, target in ipairs(targets) do
                totalDamage = totalDamage + characterSystem:applyDamage(target, baseDamage, damageType)
                
                -- 30% chance to apply a poison effect
                if math.random() < 0.3 then
                    characterSystem:applyStatusEffect(target, "poison", {
                        duration = 2,
                        damage = 1,
                        type = "poison"
                    })
                end
            end
            
            return totalDamage
        end
    }
    
    -- Combine party members and minions into a single target list
    local allAffectedTargets = {}
    for _, member in ipairs(affectedPartyMembers) do
        table.insert(allAffectedTargets, member)
    end
    for _, minion in ipairs(affectedMinions) do
        table.insert(allAffectedTargets, minion)
    end
    
    -- Execute the trap effect based on trap type
    if trapEffects[trap.trapType] and #allAffectedTargets > 0 then
        local totalDamage = trapEffects[trap.trapType](allAffectedTargets, trap)
        
        -- Always set the trap to inactive after triggering
        -- Traps are one-shot, regardless of whether they were detected or not
        trap.isTrapActive = false
        
        return totalDamage
    end
    
    return false
end

-- Apply the effects of a chest trap
function trapSystem:triggerChestTrap(entity, target)
    if not entity or not entity.isTrapped or not entity.trapType then
        return false
    end
    
    -- Get the party and minions
    local party = GAME.party or {target}
    local minions = {}
    if minionManager and minionManager.activeMinions then
        minions = minionManager.activeMinions
    end
    
    -- Determine how many party members will be affected (1-4)
    local maxPartyMembers = #party
    local affectedPartyCount = math.random(1, maxPartyMembers)
    
    -- Select which party members will be affected
    local affectedPartyMembers = {}
    if affectedPartyCount == maxPartyMembers then
        -- All party members affected
        affectedPartyMembers = party
    else
        -- Randomly select party members
        local indices = {}
        for i = 1, maxPartyMembers do
            table.insert(indices, i)
        end
        
        -- Shuffle the indices
        for i = #indices, 2, -1 do
            local j = math.random(i)
            indices[i], indices[j] = indices[j], indices[i]
        end
        
        -- Select the first N indices
        for i = 1, affectedPartyCount do
            table.insert(affectedPartyMembers, party[indices[i]])
        end
    end
    
    -- Determine if minions will be affected (50% chance per minion)
    local affectedMinions = {}
    for _, minion in ipairs(minions) do
        if math.random() < 0.5 then
            table.insert(affectedMinions, minion)
        end
    end
    
    -- Play a generic chest trap sound
    if assetManager.sounds.chest_trap_trigger_generic then
        assetManager.sounds.chest_trap_trigger_generic:play()
    end
    
    -- Play a specific trap sound if available
    local specificSound = assetManager.sounds["chest_trap_" .. entity.trapType]
    if specificSound then
        specificSound:play()
    end
    
    -- Define trap effects for chests
    local trapEffects = {
        -- Poison needle (direct damage + poison)
        poison_needle = function(targets)
            local damage = 3
            local totalDamage = 0
            
            for _, target in ipairs(targets) do
                totalDamage = totalDamage + characterSystem:applyDamage(target, damage, "poison")
                characterSystem:applyStatusEffect(target, "poison", {
                    duration = 3,
                    damage = 1,
                    type = "poison"
                })
            end
            
            return totalDamage
        end,
        
        -- Gas cloud (area effect)
        gas_cloud = function(targets)
            local damage = 2
            local totalDamage = damage * #targets
            
            for _, target in ipairs(targets) do
                characterSystem:applyStatusEffect(target, "poison", {
                    duration = 4,
                    damage = 1,
                    type = "poison"
                })
            end
            
            return totalDamage
        end,
        
        -- Magic blast (direct damage)
        magic_blast = function(targets)
            local damage = 6
            local totalDamage = 0
            
            for _, target in ipairs(targets) do
                totalDamage = totalDamage + characterSystem:applyDamage(target, damage, "magic")
            end
            
            return totalDamage
        end
    }
    
    -- Combine party members and minions into a single target list
    local allAffectedTargets = {}
    for _, member in ipairs(affectedPartyMembers) do
        table.insert(allAffectedTargets, member)
    end
    for _, minion in ipairs(affectedMinions) do
        table.insert(allAffectedTargets, minion)
    end
    
    -- Execute the trap effect based on trap type
    if trapEffects[entity.trapType] and #allAffectedTargets > 0 then
        return trapEffects[entity.trapType](allAffectedTargets)
    end
    
    -- Default damage if trap type is invalid
    local totalDamage = 0
    for _, target in ipairs(allAffectedTargets) do
        totalDamage = totalDamage + characterSystem:applyDamage(target, 4, "physical")
    end
    
    return totalDamage
end

-- Check if a player would detect a trap based on their class and skills
function trapSystem:checkTrapDetection(trap, map, playerX, playerY)
    if not trap or not trap.isTrapActive or trap.isTrapDetected then
        return false
    end

    -- Line of Sight Check
    if not hasLineOfSight(map, playerX, playerY, trap.x, trap.y) then
        if GAME.debug then
            print("Trap detection failed for trap at (" .. trap.x .. "," .. trap.y .. "): No line of sight from (" .. playerX .. "," .. playerY .. ")")
        end
        return false -- No line of sight, cannot detect
    end
    
    local detectionChance = 0.15  -- Increased base chance from 10% to 15% (fallback)
    local highestPriorityClass = "None"
    if GAME.party and #GAME.party > 0 then
        local hasRogue, hasMage, hasWarrior = false, false, false
        for _, member in ipairs(GAME.party) do
            if member.class == "Rogue" then hasRogue = true; break end -- Highest priority
            if member.class == "Mage" then hasMage = true end
            if member.class == "Warrior" then hasWarrior = true end
        end
        if hasRogue then
            detectionChance = 0.85  -- Increased from 70% to 85% for rogues
            highestPriorityClass = "Rogue"
        elseif hasMage then
            detectionChance = 0.45  -- Increased from 30% to 45% for mages
            highestPriorityClass = "Mage"
        elseif hasWarrior then
            detectionChance = 0.3   -- Increased from 20% to 30% for warriors
            highestPriorityClass = "Warrior"
        end
    end
    
    -- Calculate distance to player as a bonus factor (closer = higher chance)
    local distance = math.sqrt((trap.x - playerX)^2 + (trap.y - playerY)^2)
    if distance < 3.0 then
        -- Add a proximity bonus (up to 15% extra chance when very close)
        local proximityBonus = 0.15 * (1.0 - (distance / 3.0))
        detectionChance = detectionChance + proximityBonus
    end
    
    -- Check if trap is detected
    if math.random() < detectionChance then
        trap.isTrapDetected = true
        trap.hintFactor = 0.6  -- Make it clearly visible once detected
        
        if GAME.debug then
            print("Trap detected by party (Effective class: " .. highestPriorityClass .. ", Chance: " .. detectionChance .. ")")
        end

        if assetManager.sounds.trap_detected then
            assetManager.sounds.trap_detected:play()
        end
        
        return true
    end
    
    return false
end

-- Attempt to disarm a trap with a player
function trapSystem:attemptDisarm(trap)
    if not trap or not trap.isTrapActive or trap.isTrapDisarmed or not trap.isTrapDetected then
        return false
    end
    
    local disarmChance = 0.2  -- Base 20% chance (fallback)
    local highestPriorityClass = "None"

    if GAME.party and #GAME.party > 0 then
        local hasRogue, hasMage, hasWarrior = false, false, false
        for _, member in ipairs(GAME.party) do
            if member.class == "Rogue" then hasRogue = true; break end -- Highest priority
            if member.class == "Mage" then hasMage = true end
            if member.class == "Warrior" then hasWarrior = true end
        end

        if hasRogue then
            disarmChance = 0.7  -- 70% for rogues
            highestPriorityClass = "Rogue"
        elseif hasMage then
            disarmChance = 0.4  -- 40% for mages with magical means
            highestPriorityClass = "Mage"
        elseif hasWarrior then
            disarmChance = 0.3  -- 30% for warriors brute forcing it
            highestPriorityClass = "Warrior"
        end
    end
    
    -- Play disarm attempt sound
    if assetManager.sounds.trap_disarm_start then
        assetManager.sounds.trap_disarm_start:play()
    end
    
    -- Check if disarm is successful
    if math.random() < disarmChance then
        trap.isTrapDisarmed = true
        if GAME.debug then
            print("Trap disarmed by party (Effective class: " .. highestPriorityClass .. ", Chance: " .. disarmChance .. ")")
        end
        -- Play success sound
        if assetManager.sounds.trap_disarm_success then
            assetManager.sounds.trap_disarm_success:play()
        end
        
        return true
    else
        -- Play failure sound
        if assetManager.sounds.trap_disarm_fail then
            assetManager.sounds.trap_disarm_fail:play()
        end
        if GAME.debug then
             print("Trap disarm failed by party (Effective class: " .. highestPriorityClass .. ", Chance: " .. disarmChance .. ")")
        end
        
        -- Chance to trigger the trap on failure
        if math.random() < 0.5 then
            -- Trigger the trap - activateTrap is already party-aware for damage distribution
            self:activateTrap(trap, GAME.party and GAME.party[1] or nil) 
        end
        
        return false
    end
end

-- Update hint factors for traps based on player position and class
function trapSystem:updateTrapHintFactors(map, playerX, playerY)
    local detectionRange = self.BASE_DETECTION_RANGE  -- Use our constant
    local hintMultiplier = 1.2  -- Increased base hint multiplier (from 1.0 to 1.2)
    -- local bestClassType = "Default" -- For logging if needed

    if GAME.party and #GAME.party > 0 then
        local hasRogue, hasMage = false, false
        for _, member in ipairs(GAME.party) do
            if member.class == "Rogue" then hasRogue = true; break end
            if member.class == "Mage" then hasMage = true end
        end

        if hasRogue then
            detectionRange = self.ROGUE_DETECTION_RANGE  -- Use our constant
            hintMultiplier = 2.5   -- Increased from 2.0 to 2.5
            -- bestClassType = "Rogue"
        elseif hasMage then
            detectionRange = self.MAGE_DETECTION_RANGE  -- Use our constant
            hintMultiplier = 1.8   -- Increased from 1.5 to 1.8
            -- bestClassType = "Mage"
        end
    end
    
    -- Update trap hint factors
    for _, trap in ipairs(map.activeTraps) do
        if trap.isTrapActive and not trap.isTrapDisarmed then
            -- If already detected, maintain a minimum hint level
            if trap.isTrapDetected then
                trap.hintFactor = 0.8  -- Increased from 0.6 to make detected traps more visible
            else
                -- Line of Sight Check before proximity checks
                if not hasLineOfSight(map, playerX, playerY, trap.x, trap.y) then
                    trap.hintFactor = 0.0 -- No line of sight, no hint
                    goto next_trap -- Continue to the next trap in the loop
                end

                local distance = math.sqrt((trap.x - playerX)^2 + (trap.y - playerY)^2)
                if distance <= detectionRange then
                    -- Calculate hint factor based on distance and multiplier
                    local baseFactor = (1.0 - (distance / detectionRange)) * hintMultiplier
                    trap.hintFactor = math.min(0.5, baseFactor)  -- Increased cap from 0.3 to 0.5 for more visible hints
                    
                    -- Increased chance to detect the trap passively 
                    -- Base chance increases as player gets closer to the trap
                    local distanceFactor = 1.0 - (distance / detectionRange)
                    local passiveDetectBaseChance = 0.05 + (distanceFactor * 0.1)  -- 5-15% base chance depending on proximity
                    local rogueBonus = 0
                    
                    if GAME.party then
                        for _, member in ipairs(GAME.party) do
                            if member.class == "Rogue" then
                                rogueBonus = 0.15 + (distanceFactor * 0.1)  -- 15-25% bonus for rogues
                                break
                            elseif member.class == "Mage" then
                                rogueBonus = 0.05 + (distanceFactor * 0.05)  -- 5-10% bonus for mages
                                break
                            end
                        end
                    end
                    
                    -- Check for passive detection with improved chance
                    if math.random() < (passiveDetectBaseChance + rogueBonus) then
                        self:checkTrapDetection(trap, map, playerX, playerY) -- Pass map and player coords
                    end
                else
                    trap.hintFactor = 0.0
                end
            end
        else
            trap.hintFactor = 0.0
        end
        ::next_trap:: -- Label for goto
    end
end

return trapSystem 