-- Item System
-- Defines items, equipment, and consumables

-- Import item definitions from external file
local itemDefs = require("gameplay/item_definitions")

local itemSystem = {
    items = itemDefs.items,
    monsterParts = itemDefs.monsterParts,
    nextItemId = 1  -- Initialize ID counter
}

-- Track the next available unique ID for items
itemSystem.nextItemId = 1

-- Item types
itemSystem.ITEM_TYPE = {
    WEAPON = "weapon",
    ARMOR = "armor",
    ACCESSORY = "accessory",
    CONSUMABLE = "consumable",
    MATERIAL = "material",
    MONSTER_PART = "monster_part",
    KEY_ITEM = "key_item"
}

-- Equipment slots
itemSystem.EQUIP_SLOT = {
    WEAPON = "weapon",
    OFFHAND = "offhand",
    HEAD = "head",
    BODY = "body",
    AMULET = "amulet",
    RING = "ring"
}

-- Weapon types
itemSystem.WEAPON_TYPE = {
    SWORD = "sword",
    AXE = "axe",
    DAGGER = "dagger",
    MACE = "mace",
    STAFF = "staff",
    BOW = "bow",
    WAND = "wand"
}

-- Get an item by name
function itemSystem:getItem(name)
    return self.items[name]
end

-- Get a monster part by name
function itemSystem:getMonsterPart(name)
    return self.monsterParts[name]
end

-- Get all items of a specific type
function itemSystem:getItemsByType(itemType)
    local items = {}
    
    for name, item in pairs(self.items) do
        if item.type == itemType then
            table.insert(items, item)
        end
    end
    
    return items
end

-- Get all items usable by a specific job
function itemSystem:getItemsByJob(jobName)
    local items = {}
    
    for name, item in pairs(self.items) do
        if item.jobs then
            for _, job in ipairs(item.jobs) do
                if job == jobName then
                    table.insert(items, item)
                    break
                end
            end
        end
    end
    
    return items
end

-- Generate random loot based on difficulty level
function itemSystem:generateRandomLoot(difficulty, count)
    local loot = {}
    count = count or math.random(1, 3)
    
    -- Check if a COLLECT quest is active for a specific item
    local collectQuestItem = nil
    if GAME.activeQuests and #GAME.activeQuests > 0 then
        local quest = GAME.activeQuests[1] -- Assuming first quest
        if quest.type == "COLLECT" and quest.objective then
            collectQuestItem = quest.objective.itemId
        end
    end
    
    for i = 1, count do
        local roll = math.random(1, 100)
        
        -- Higher chance to drop quest item if needed
        if collectQuestItem and roll <= 30 then -- 30% chance if quest active
            local itemData = self:getItemData(collectQuestItem)
            if itemData then
                table.insert(loot, { 
                    name = itemData.name, 
                    type = itemData.type, 
                    questItemId = collectQuestItem, -- Add quest ID flag
                    value = itemData.value or 0 
                })
            else
                table.insert(loot, self:getRandomMonsterPart(difficulty)) -- Fallback
            end
        elseif roll <= 5 + (difficulty * 2) then
            -- Regular rare item drop (consumable for now)
            table.insert(loot, self:getRandomItem("consumable", difficulty)) 
        else
            -- Monster part drop
            table.insert(loot, self:getRandomMonsterPart(difficulty))
        end
    end
    
    -- Chance for gold (based on difficulty)
    if math.random(1, 100) <= 20 then
        local goldAmount = math.random(5, 15) * difficulty
        table.insert(loot, {
            type = "gold",
            amount = goldAmount
        })
    end
    
    return loot
end

-- Get a random item of a specific type
function itemSystem:getRandomItem(itemType, level)
    local candidates = {}
    
    -- Gather suitable items
    for name, item in pairs(self.items) do
        if item.type == itemType then
            -- Simple level requirement check (can be more sophisticated)
            if not level or not item.level or item.level <= level then
                table.insert(candidates, name)
            end
        end
    end
    
    -- Select random item from candidates
    if #candidates > 0 then
        local randomName = candidates[math.random(1, #candidates)]
        local baseItem = self.items[randomName]
        
        -- Create a clone with unique ID
        return self:cloneItemWithId(baseItem)
    end
    
    return nil
end

-- Get a random monster part based on difficulty
function itemSystem:getRandomMonsterPart(difficulty)
    local parts = {}
    local maxRarity = math.min(5, math.ceil(difficulty / 2))
    
    -- Filter parts by rarity
    for name, part in pairs(self.monsterParts) do
        if part.rarity <= maxRarity then
            -- Higher chance for lower rarity items
            local count = 6 - part.rarity
            for i = 1, count do
                table.insert(parts, part)
            end
        end
    end
    
    -- Return random part or default if none found
    if #parts > 0 then
        return parts[math.random(1, #parts)]
    else
        return self.monsterParts["SlimeCrystal"]
    end
end

-- Use a consumable item
function itemSystem:useItem(item, target)
    if not item or item.type ~= "consumable" or not item.effect then
        return false
    end
    
    local effect = item.effect
    local success = false
    local effectMessage = ""
    
    if effect.hp then
        -- HP healing item
        if target.currentHP and target.currentHP < target.maxHP then
            local healAmount = effect.hp
            local oldHP = target.currentHP
            target.currentHP = math.min(target.maxHP, target.currentHP + healAmount)
            
            -- Calculate actual heal amount considering max HP cap
            local actualHeal = target.currentHP - oldHP
            
            effectMessage = target.name .. " restored " .. actualHeal .. " HP!"
            success = true
        else
            effectMessage = target.name .. " is already at full HP!"
        end
    elseif effect.mp then
        -- MP restoration item
        if target.currentMP and target.currentMP < target.maxMP then
            local restoreAmount = effect.mp
            local oldMP = target.currentMP
            target.currentMP = math.min(target.maxMP, target.currentMP + restoreAmount)
            
            -- Calculate actual MP restore amount considering max MP cap
            local actualRestore = target.currentMP - oldMP
            
            effectMessage = target.name .. " restored " .. actualRestore .. " MP!"
            success = true
        else
            effectMessage = target.name .. " is already at full MP!"
        end
    elseif effect.type == "heal" then
        -- Legacy healing item
        if target.currentHP and target.currentHP < target.maxHP then
            local healAmount = effect.amount or 20
            local oldHP = target.currentHP
            target.currentHP = math.min(target.maxHP, target.currentHP + healAmount)
            
            effectMessage = target.name .. " restored " .. (target.currentHP - oldHP) .. " HP!"
            success = true
        else
            effectMessage = target.name .. " is already at full HP!"
        end
    elseif effect.type == "restore_mp" then
        -- Legacy MP restoration
        if target.currentMP and target.currentMP < target.maxMP then
            local restoreAmount = effect.amount or 20
            local oldMP = target.currentMP
            target.currentMP = math.min(target.maxMP, target.currentMP + restoreAmount)
            
            effectMessage = target.name .. " restored " .. (target.currentMP - oldMP) .. " MP!"
            success = true
        else
            effectMessage = target.name .. " is already at full MP!"
        end
    elseif effect.type == "cure_status" then
        -- Status healing
        if target.status and target.status[effect.status] then
            target.status[effect.status] = nil
            effectMessage = target.name .. " was cured of " .. effect.status .. "!"
            success = true
        else
            effectMessage = target.name .. " doesn't have that status ailment!"
        end
    elseif effect.type == "full_restore" then
        -- Full restoration
        local needsHealing = false
        
        if target.currentHP and target.currentHP < target.maxHP then
            target.currentHP = target.maxHP
            needsHealing = true
        end
        
        if target.currentMP and target.currentMP < target.maxMP then
            target.currentMP = target.maxMP
            needsHealing = true
        end
        
        if needsHealing then
            effectMessage = target.name .. " was fully restored!"
            success = true
        else
            effectMessage = target.name .. " is already at full health!"
        end
    elseif effect.boost then
        -- Stat boost item
        if effect.boost.stat and effect.boost.amount and target.attributes then
            local statName = effect.boost.stat
            local boostAmount = effect.boost.amount
            local duration = effect.boost.duration or 3  -- Default to 3 turns if not specified
            
            -- Create or update boosted stats
            if not target.boostedStats then target.boostedStats = {} end
            
            if not target.boostedStats[statName] then
                target.boostedStats[statName] = {
                    amount = boostAmount,
                    duration = duration
                }
                
                -- Apply the boost
                target.attributes[statName] = (target.attributes[statName] or 0) + boostAmount
                
                effectMessage = target.name .. "'s " .. statName .. " increased by " .. boostAmount .. "!"
                success = true
            else
                -- If already boosted, refresh the duration instead
                target.boostedStats[statName].duration = duration
                effectMessage = target.name .. "'s " .. statName .. " boost extended!"
                success = true
            end
        end
    end
    
    -- Display effect message if needed
    
    -- Return item use success status and message for UI feedback
    return success, effectMessage
end

-- Craft an item from monster parts
function itemSystem:craftItem(recipe, inventory)
    -- Check if recipe exists
    if not recipe or not recipe.result or not recipe.materials then
        return false
    end
    
    -- Check if materials are available in inventory
    for material, count in pairs(recipe.materials) do
        local available = 0
        
        for _, item in ipairs(inventory) do
            if item.name == material then
                available = available + (item.count or 1)
            end
        end
        
        if available < count then
            return false
        end
    end
    
    -- Remove materials from inventory
    for material, count in pairs(recipe.materials) do
        local remaining = count
        
        for i = #inventory, 1, -1 do
            if inventory[i].name == material then
                local itemCount = inventory[i].count or 1
                
                if itemCount <= remaining then
                    -- Remove entire stack
                    table.remove(inventory, i)
                    remaining = remaining - itemCount
                else
                    -- Remove part of stack
                    inventory[i].count = itemCount - remaining
                    remaining = 0
                end
                
                if remaining <= 0 then
                    break
                end
            end
        end
    end
    
    -- Create result item
    local result = self:getItem(recipe.result)
    
    if not result then
        return false
    end
    
    return result
end

-- Generate a random item for stealing based on enemy level
function itemSystem:generateRandomItem(level)
    level = level or 1
    
    -- Choose item type
    local types = {"weapon", "armor", "accessory", "consumable"}
    local chosenType = types[math.random(1, #types)]
    
    -- Get random item of that type
    local item = self:getRandomItem(chosenType, level)
    
    -- If no item found, fallback to a basic item
    if not item then
        local fallbacks = {
            weapon = "ShortSword",
            armor = "LeatherArmor",
            accessory = "IronRing",
            consumable = "HealthPotion"
        }
        
        local baseItem = self.items[fallbacks[chosenType]]
        if baseItem then
            -- Create a clone with unique ID
            item = self:cloneItemWithId(baseItem)
        end
    end
    
    return item
end

-- Get an item by name (ID)
function itemSystem:getItemData(itemId)
    return self.items[itemId]
end

-- Generate a unique ID for an item
function itemSystem:generateUniqueId()
    local uniqueId = "item_" .. self.nextItemId
    self.nextItemId = self.nextItemId + 1
    return uniqueId
end

-- Clone an item with a unique ID
function itemSystem:cloneItemWithId(itemName)
    local baseItem
    if type(itemName) == "string" then
        baseItem = self:getItem(itemName)
    elseif type(itemName) == "table" then
        baseItem = itemName
    end
    
    if not baseItem then
        return nil
    end
    
    -- Create a deep copy of the item
    local newItem = {}
    for key, value in pairs(baseItem) do
        newItem[key] = value
    end
    
    -- Assign a unique ID
    newItem.uniqueId = self:generateUniqueId()
    
    return newItem
end

-- Add an item to the inventory with unique ID
function itemSystem:addToInventory(item)
    if not item then return false end
    
    -- Ensure the item has a unique ID
    if not item.uniqueId then
        item.uniqueId = self:generateUniqueId()
    end
    
    -- Only stack non-equippable items (consumables, materials, monster parts)
    if item.type == "consumable" or item.type == "material" or item.type == "monster_part" then
        -- Look for existing stack
        for _, invItem in ipairs(GAME.inventory) do
            if invItem.name == item.name and invItem.type == item.type then
                -- Increase count of existing stack
                invItem.count = (invItem.count or 1) + (item.count or 1)
                return true
            end
        end
        
        -- No stack found, set count if needed
        if not item.count then
            item.count = 1
        end
    else
        -- For equippable items (weapons, armor, accessories), always ensure they have unique IDs
        -- and add them as separate entries - never stack them
        -- This ensures each equippable item is distinct and can be tracked individually
        
        -- Set count to 1 if not already set
        item.count = 1
    end
    
    -- Add item to inventory
    table.insert(GAME.inventory, item)
    return true
end

return itemSystem
