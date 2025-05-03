-- gameplay/monsterData.lua
local monsterData = {}
local assets = require("assets/assetManager")

monsterData.monsters = {
    -- Bloomers (Fungal monsters)
    ["fungal_fighter"] = {
        id = "fungal_fighter",
        name = "Fungal Fighter",
        stats = { level = 1, hp = 15, attack = 4, defense = 2, speed = 7 },
        color = {0.5, 0.8, 0.5},
        sprite = "assets/Sprites/Enemies/Bloomers/fungal_fighter.png",
        category = "Bloomers"
    },
    ["shroomling"] = {
        id = "shroomling",
        name = "Shroomling",
        stats = { level = 1, hp = 12, attack = 3, defense = 1, speed = 9 },
        color = {0.6, 0.7, 0.4},
        sprite = "assets/Sprites/Enemies/Bloomers/shroomling.png",
        category = "Bloomers"
    },
    ["walking_mushroom"] = {
        id = "walking_mushroom",
        name = "Walking Mushroom",
        stats = { level = 2, hp = 20, attack = 5, defense = 3, speed = 6 },
        color = {0.7, 0.5, 0.6},
        sprite = "assets/Sprites/Enemies/Bloomers/walking_mushroom.png",
        category = "Bloomers"
    },
    ["toxic_sporeling"] = {
        id = "toxic_sporeling",
        name = "Toxic Sporeling",
        stats = { level = 3, hp = 25, attack = 7, defense = 4, speed = 8 },
        color = {0.3, 0.7, 0.3},
        sprite = "assets/Sprites/Enemies/Bloomers/toxic_sporeling.png",
        category = "Bloomers"
    },
    ["fungal_rat"] = {
        id = "fungal_rat",
        name = "Fungal Rat",
        stats = { level = 2, hp = 18, attack = 6, defense = 2, speed = 10 },
        color = {0.5, 0.6, 0.5},
        sprite = "assets/Sprites/Enemies/Bloomers/fungal_rat.png",
        category = "Bloomers"
    },
    ["fungal_zombie"] = {
        id = "fungal_zombie",
        name = "Fungal Zombie",
        stats = { level = 4, hp = 35, attack = 9, defense = 5, speed = 5 },
        color = {0.4, 0.6, 0.4},
        sprite = "assets/Sprites/Enemies/Bloomers/fungal_zombie.png",
        category = "Bloomers"
    },
    
    -- Cultists
    ["cultists_initiate"] = {
        id = "cultists_initiate",
        name = "Cultist Initiate",
        stats = { level = 2, hp = 22, attack = 6, defense = 3, speed = 8 },
        color = {0.7, 0.2, 0.2},
        sprite = "assets/Sprites/Enemies/Cultists/cultists_initiate.png",
        category = "Cultists"
    },
    ["hooded_cultist"] = {
        id = "hooded_cultist",
        name = "Hooded Cultist",
        stats = { level = 3, hp = 28, attack = 7, defense = 4, speed = 7 },
        color = {0.6, 0.3, 0.3},
        sprite = "assets/Sprites/Enemies/Cultists/hooded_cultist.png",
        category = "Cultists"
    },
    ["cult_warlock"] = {
        id = "cult_warlock",
        name = "Cult Warlock",
        stats = { level = 5, hp = 40, attack = 10, defense = 6, speed = 9 },
        color = {0.5, 0.1, 0.5},
        sprite = "assets/Sprites/Enemies/Cultists/cult_warlock.png",
        category = "Cultists"
    },
    ["cultist_pyromancer"] = {
        id = "cultist_pyromancer",
        name = "Cultist Pyromancer",
        stats = { level = 6, hp = 45, attack = 12, defense = 5, speed = 8 },
        color = {0.8, 0.4, 0.1},
        sprite = "assets/Sprites/Enemies/Cultists/cultist_pyromancer.png",
        category = "Cultists"
    },
    ["plague_cultist"] = {
        id = "plague_cultist",
        name = "Plague Cultist",
        stats = { level = 4, hp = 32, attack = 9, defense = 5, speed = 7 },
        color = {0.3, 0.6, 0.3},
        sprite = "assets/Sprites/Enemies/Cultists/plague_cultist.png",
        category = "Cultists"
    },
    
    -- Undead
    ["zombie_farmer"] = {
        id = "zombie_farmer",
        name = "Zombie Farmer",
        stats = { level = 1, hp = 18, attack = 5, defense = 2, speed = 4 },
        color = {0.5, 0.5, 0.3},
        sprite = "assets/Sprites/Enemies/Undead/zombie_farmer.png",
        category = "Undead"
    },
    ["zombie_biter"] = {
        id = "zombie_biter",
        name = "Zombie Biter",
        stats = { level = 2, hp = 25, attack = 7, defense = 3, speed = 6 },
        color = {0.4, 0.4, 0.4},
        sprite = "assets/Sprites/Enemies/Undead/zombie_biter.png",
        category = "Undead"
    },
    ["skeletal_hound"] = {
        id = "skeletal_hound",
        name = "Skeletal Hound",
        stats = { level = 3, hp = 22, attack = 8, defense = 3, speed = 11 },
        color = {0.8, 0.8, 0.8},
        sprite = "assets/Sprites/Enemies/Undead/skeletal_hound.png",
        category = "Undead"
    },
    ["skeleton_warrior"] = {
        id = "skeleton_warrior",
        name = "Skeleton Warrior",
        stats = { level = 3, hp = 30, attack = 9, defense = 6, speed = 7 },
        color = {0.9, 0.9, 0.7},
        sprite = "assets/Sprites/Enemies/Undead/skeleton_warrior.png",
        category = "Undead"
    },
    ["ghoul_stalker"] = {
        id = "ghoul_stalker",
        name = "Ghoul Stalker",
        stats = { level = 4, hp = 35, attack = 10, defense = 5, speed = 9 },
        color = {0.5, 0.5, 0.6},
        sprite = "assets/Sprites/Enemies/Undead/ghoul_stalker.png",
        category = "Undead"
    },
    ["tormented_ghoul"] = {
        id = "tormented_ghoul",
        name = "Tormented Ghoul",
        stats = { level = 5, hp = 45, attack = 12, defense = 7, speed = 8 },
        color = {0.6, 0.5, 0.7},
        sprite = "assets/Sprites/Enemies/Undead/tormented_ghoul.png",
        category = "Undead"
    },
    
    -- Insects
    ["horned_beetle"] = {
        id = "horned_beetle",
        name = "Horned Beetle",
        stats = { level = 1, hp = 20, attack = 6, defense = 7, speed = 6 },
        color = {0.5, 0.3, 0.1},
        sprite = "assets/Sprites/Enemies/Insects/horned_beetle.png",
        category = "Insects"
    },
    ["buzzer"] = {
        id = "buzzer",
        name = "Buzzer",
        stats = { level = 2, hp = 15, attack = 5, defense = 3, speed = 12 },
        color = {0.7, 0.7, 0.2},
        sprite = "assets/Sprites/Enemies/Insects/buzzer.png",
        category = "Insects"
    },
    ["armored_ant"] = {
        id = "armored_ant",
        name = "Armored Ant",
        stats = { level = 3, hp = 28, attack = 7, defense = 9, speed = 7 },
        color = {0.4, 0.3, 0.2},
        sprite = "assets/Sprites/Enemies/Insects/armored_ant.png",
        category = "Insects"
    },
    ["mantis_warrior"] = {
        id = "mantis_warrior",
        name = "Mantis Warrior",
        stats = { level = 4, hp = 35, attack = 12, defense = 6, speed = 10 },
        color = {0.2, 0.7, 0.3},
        sprite = "assets/Sprites/Enemies/Insects/mantis_warrior.png",
        category = "Insects"
    },
    ["wasp_demon"] = {
        id = "wasp_demon",
        name = "Wasp Demon",
        stats = { level = 5, hp = 40, attack = 13, defense = 5, speed = 13 },
        color = {0.8, 0.5, 0.1},
        sprite = "assets/Sprites/Enemies/Insects/wasp_demon.png",
        category = "Insects"
    },
    
    -- Bosses
    ["spore_witch_boss"] = {
        id = "spore_witch_boss",
        name = "Spore Witch",
        stats = { level = 6, hp = 150, attack = 15, defense = 10, speed = 9 },
        color = {0.3, 0.7, 0.2},
        sprite = "assets/Sprites/Enemies/Bloomers/spore_witch_BOSS.png",
        category = "Bloomers",
        isBoss = true
    },
    ["spore_lord_boss"] = {
        id = "spore_lord_boss",
        name = "Spore Lord",
        stats = { level = 8, hp = 200, attack = 18, defense = 14, speed = 7 },
        color = {0.2, 0.6, 0.3},
        sprite = "assets/Sprites/Enemies/Bloomers/spore_lord_BOSS.png",
        category = "Bloomers",
        isBoss = true
    },
    ["chanting_fanatic_boss"] = {
        id = "chanting_fanatic_boss",
        name = "Chanting Fanatic",
        stats = { level = 7, hp = 180, attack = 17, defense = 12, speed = 10 },
        color = {0.7, 0.2, 0.4},
        sprite = "assets/Sprites/Enemies/Cultists/chanting_fanatic_BOSS.png",
        category = "Cultists",
        isBoss = true
    },
    ["demonic_leader_boss"] = {
        id = "demonic_leader_boss",
        name = "Demonic Leader",
        stats = { level = 10, hp = 250, attack = 22, defense = 16, speed = 11 },
        color = {0.8, 0.1, 0.1},
        sprite = "assets/Sprites/Enemies/Cultists/demonic_leader_BOSS.png",
        category = "Cultists",
        isBoss = true
    },
    ["skeleton_general_boss"] = {
        id = "skeleton_general_boss",
        name = "Skeleton General",
        stats = { level = 8, hp = 190, attack = 19, defense = 15, speed = 9 },
        color = {0.7, 0.7, 0.5},
        sprite = "assets/Sprites/Enemies/Undead/skeleton_general_BOSS.png",
        category = "Undead",
        isBoss = true
    },
    ["lich_king_boss"] = {
        id = "lich_king_boss",
        name = "Lich King",
        stats = { level = 12, hp = 300, attack = 25, defense = 18, speed = 8 },
        color = {0.3, 0.3, 0.8},
        sprite = "assets/Sprites/Enemies/Undead/lich_king_BOSS.png",
        category = "Undead",
        isBoss = true
    },
    ["matron_zirrk_boss"] = {
        id = "matron_zirrk_boss",
        name = "Matron Zirrk",
        stats = { level = 9, hp = 220, attack = 20, defense = 16, speed = 12 },
        color = {0.4, 0.7, 0.2},
        sprite = "assets/Sprites/Enemies/Insects/matron_zirrk_BOSS.png",
        category = "Insects",
        isBoss = true
    },
    ["killerpede_boss"] = {
        id = "killerpede_boss",
        name = "Killerpede",
        stats = { level = 11, hp = 270, attack = 23, defense = 17, speed = 14 },
        color = {0.7, 0.4, 0.1},
        sprite = "assets/Sprites/Enemies/Insects/killerpede_BOSS.png",
        category = "Insects",
        isBoss = true
    }
}

-- ID mapping for quest system (numeric IDs to string IDs)
monsterData.idMapping = {
    -- Regular monsters by category
    -- Bloomers
    [1] = "fungal_fighter",
    [2] = "shroomling", 
    [3] = "walking_mushroom",
    [4] = "toxic_sporeling",
    [5] = "fungal_rat",
    [6] = "fungal_zombie",
    
    -- Cultists
    [11] = "cultists_initiate",
    [12] = "hooded_cultist",
    [13] = "cult_warlock",
    [14] = "cultist_pyromancer",
    [15] = "plague_cultist",
    
    -- Undead
    [21] = "zombie_farmer",
    [22] = "zombie_biter",
    [23] = "skeletal_hound",
    [24] = "skeleton_warrior",
    [25] = "ghoul_stalker",
    [26] = "tormented_ghoul",
    
    -- Insects
    [31] = "horned_beetle",
    [32] = "buzzer",
    [33] = "armored_ant",
    [34] = "mantis_warrior",
    [35] = "wasp_demon",
    
    -- Bosses
    [101] = "spore_witch_boss",
    [102] = "spore_lord_boss",
    [103] = "chanting_fanatic_boss",
    [104] = "demonic_leader_boss",
    [105] = "skeleton_general_boss",
    [106] = "lich_king_boss",
    [107] = "matron_zirrk_boss",
    [108] = "killerpede_boss"
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

return monsterData 