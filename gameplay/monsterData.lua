-- gameplay/monsterData.lua
local monsterData = {}
local assets = require("assets/assetManager")

-- Import monster definitions
local monsterDefinitions = require("gameplay/monster_definitions")
monsterData.monsters = monsterDefinitions.monsters
monsterData.idMapping = monsterDefinitions.idMapping

-- Get monster data by ID
function monsterData:getMonsterData(id)
    -- If ID is numeric, translate it using the mapping
    if type(id) == "number" then
        id = self.idMapping[id]
    end
    return self.monsters[id]
end

-- Get a random monster ID suitable for a given difficulty/level
function monsterData:getRandomMonsterId(difficulty)
    local possible = {}
    local maxLevel = difficulty * 2 -- Simple heuristic
    for id, data in pairs(self.monsters) do
        if not data.isBoss and data.stats.level <= maxLevel then
            table.insert(possible, id)
        end
    end
    if #possible > 0 then
        return possible[math.random(1, #possible)]
    else
        return "fungal_fighter" -- Fallback to lowest level monster
    end
end

-- Get a random boss ID suitable for a given difficulty/level
function monsterData:getRandomBossId(difficulty)
    local possible = {}
    local minLevel = math.max(1, difficulty - 2)
    local maxLevel = difficulty + 3
    
    for id, data in pairs(self.monsters) do
        if data.isBoss and data.stats.level >= minLevel and data.stats.level <= maxLevel then
            table.insert(possible, id)
        end
    end
    
    if #possible > 0 then
        return possible[math.random(1, #possible)]
    else
        return "spore_witch_boss" -- Fallback to lowest level boss
    end
end

-- Get a list of monsters by category
function monsterData:getMonstersByCategory(category, includeBosses)
    local result = {}
    includeBosses = includeBosses or false
    
    for id, data in pairs(self.monsters) do
        if data.category == category then
            if includeBosses or not data.isBoss then
                table.insert(result, id)
            end
        end
    end
    
    return result
end

-- Load monster sprites
function monsterData:loadSprites()
    if not self.sprites then
        self.sprites = {}
        for id, data in pairs(self.monsters) do
            if data.sprite then
                local success, image = pcall(function()
                    return love.graphics.newImage(data.sprite)
                end)
                
                if success and image then
                    self.sprites[id] = image
                else
                    print("Failed to load sprite for: " .. id)
                end
            end
        end
        print("Loaded " .. self:countTableElements(self.sprites) .. " monster sprites")
    end
    return self.sprites
end

-- Helper function to count elements in a table
function monsterData:countTableElements(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Get a random monster of a specific category 
function monsterData:getRandomMonsterByCategory(category, difficulty)
    local monsters = self:getMonstersByCategory(category, false)
    local validMonsters = {}
    
    -- Filter by difficulty/level
    local maxLevel = difficulty * 2 -- Simple heuristic
    for _, id in ipairs(monsters) do
        local monster = self.monsters[id]
        if monster.stats.level <= maxLevel then
            table.insert(validMonsters, id)
        end
    end
    
    -- Return a random valid monster
    if #validMonsters > 0 then
        return validMonsters[math.random(1, #validMonsters)]
    end
    
    -- Fallback to first monster in the category regardless of level
    if #monsters > 0 then
        return monsters[1]
    end
    
    -- Ultimate fallback
    return "fungal_fighter"
end

-- Generate a group of monsters of the same category based on difficulty
function monsterData:generateMonsterGroup(difficulty)
    -- Print debug info about the difficulty
    print("Generating monster group for difficulty level: " .. tostring(difficulty))
    
    -- Load quest system difficulty constants if needed
    local questSystem = require("gameplay/questSystem")
    local DIFFICULTY = questSystem.DIFFICULTY
    
    -- Determine number of monsters based on difficulty
    local monsterCount
    
    -- Check against enum values if possible
    if DIFFICULTY then
        if difficulty == DIFFICULTY.EASY then
            monsterCount = 1 -- Easy - 1 monster
        elseif difficulty == DIFFICULTY.MEDIUM then
            monsterCount = math.random(1, 3) -- Medium - 1-3 monsters
        elseif difficulty == DIFFICULTY.HARD then
            monsterCount = math.random(2, 4) -- Hard - 2-4 monsters
        elseif difficulty >= DIFFICULTY.VERY_HARD then
            monsterCount = math.random(3, 5) -- Very hard/legendary - 3-5 monsters
        else
            -- Numeric fallback if difficulty doesn't match enum
            if difficulty <= 1 then
                monsterCount = 1
            elseif difficulty <= 3 then
                monsterCount = math.random(1, 3)
            elseif difficulty <= 5 then
                monsterCount = math.random(2, 4)
            else
                monsterCount = math.random(3, 5)
            end
        end
    else
        -- Direct numeric fallback (original logic)
        if difficulty <= 1 then
            monsterCount = 1
        elseif difficulty <= 3 then
            monsterCount = math.random(1, 3)
        elseif difficulty <= 5 then
            monsterCount = math.random(2, 4)
        else
            monsterCount = math.random(3, 5)
        end
    end
    
    print("Will generate " .. monsterCount .. " monsters")
    
    -- Choose a random category from available monsters
    local categories = {}
    for _, data in pairs(self.monsters) do
        if not data.isBoss and not self:contains(categories, data.category) then
            table.insert(categories, data.category)
        end
    end
    
    -- Randomly select a category
    local selectedCategory = categories[math.random(1, #categories)]
    print("Selected monster category: " .. tostring(selectedCategory))
    
    -- Generate the monster group
    local monsters = {}
    for i = 1, monsterCount do
        local monsterId = self:getRandomMonsterByCategory(selectedCategory, difficulty)
        local monsterData = self:getMonsterData(monsterId)
        
        if monsterData then
            -- Clone monster data to avoid reference issues
            local monster = {
                id = monsterData.id,
                name = monsterData.name,
                stats = table.copy(monsterData.stats),
                color = monsterData.color,
                sprite = monsterData.sprite,
                category = monsterData.category
            }
            
            table.insert(monsters, monster)
            print("Added monster: " .. monster.name)
        else
            print("Warning: Failed to get monster data for ID: " .. tostring(monsterId))
        end
    end
    
    -- Ensure we return at least one monster
    if #monsters == 0 then
        local fallbackMonster = self:getMonsterData("fungal_fighter")
        table.insert(monsters, {
            id = fallbackMonster.id,
            name = fallbackMonster.name,
            stats = table.copy(fallbackMonster.stats),
            color = fallbackMonster.color,
            sprite = fallbackMonster.sprite,
            category = fallbackMonster.category
        })
        print("Warning: Monster group generation failed, using fallback monster")
    end
    
    print("Final monster group size: " .. #monsters)
    return monsters
end

-- Helper function to check if a table contains a value (moved to a method for scope safety)
function monsterData:contains(tbl, value)
    if not tbl or type(tbl) ~= "table" then return false end
    
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Helper function to copy a table
function table.copy(t)
    local u = {}
    for k, v in pairs(t) do
        u[k] = v
    end
    return u
end

return monsterData 