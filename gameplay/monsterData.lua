-- gameplay/monsterData.lua
local monsterData = {}

monsterData.monsters = {
    -- Basic Monsters
    ["monster_rat"] = {
        id = "monster_rat",
        name = "Giant Rat",
        stats = { level = 1, hp = 10, attack = 3, defense = 1, speed = 8 },
        color = {0.5, 0.5, 0.5}
    },
    ["monster_goblin"] = {
        id = "monster_goblin",
        name = "Goblin",
        stats = { level = 2, hp = 20, attack = 5, defense = 2, speed = 10 },
        color = {0.2, 0.8, 0.2}
    },
    ["monster_skeleton"] = {
        id = "monster_skeleton",
        name = "Skeleton",
        stats = { level = 3, hp = 25, attack = 6, defense = 4, speed = 9 },
        color = {0.9, 0.9, 0.9}
    },
    ["monster_orc"] = {
        id = "monster_orc",
        name = "Orc",
        stats = { level = 4, hp = 40, attack = 8, defense = 5, speed = 7 },
        color = {0.1, 0.6, 0.1}
    },
    
    -- Bosses
    ["boss_troll"] = {
        id = "boss_troll",
        name = "Cave Troll",
        stats = { level = 5, hp = 120, attack = 18, defense = 10, speed = 6 }, -- Higher stats
        color = {0.4, 0.6, 0.4},
        isBoss = true
    }
    -- Add more monsters and bosses here...
}

-- ID mapping for quest system (numeric IDs to string IDs)
monsterData.idMapping = {
    [1] = "monster_rat",
    [2] = "monster_goblin", 
    [3] = "monster_skeleton",
    [4] = "monster_orc",
    [5] = "boss_troll"
}

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
        return "monster_rat" -- Fallback
    end
end

return monsterData 