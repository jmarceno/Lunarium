-- Item System
-- Defines items, equipment, and consumables

local itemSystem = {
    items = {},
    monsterParts = {},
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

-- Item definitions
itemSystem.items = {
    -- Basic weapons
    ShortSword = {
        name = "Short Sword",
        description = "A simple but reliable blade.",
        type = "weapon",
        subType = "sword",
        slot = "weapon",
        attack = 10,
        magicAttack = 0,
        value = 100,
        requirements = {
            STR = 5
        },
        jobs = {"Fighter", "Knight", "Paladin", "Rogue"}
    },
    
    Dagger = {
        name = "Dagger",
        description = "Quick and easy to handle.",
        type = "weapon",
        subType = "dagger",
        slot = "weapon",
        attack = 6,
        magicAttack = 0,
        value = 80,
        requirements = {
            DEX = 5
        },
        jobs = {"Rogue", "Assassin"}
    },
    
    ApprenticeStaff = {
        name = "Apprentice Staff",
        description = "A basic staff for novice mages.",
        type = "weapon",
        subType = "staff",
        slot = "weapon",
        attack = 4,
        magicAttack = 12,
        value = 120,
        requirements = {
            INT = 5
        },
        jobs = {"Mage", "BlackMage", "WhiteMage"}
    },
    
    Mace = {
        name = "Mace",
        description = "A blunt weapon favored by clerics.",
        type = "weapon",
        subType = "mace",
        slot = "weapon",
        attack = 8,
        magicAttack = 5,
        value = 110,
        requirements = {
            STR = 4,
            WIS = 4
        },
        jobs = {"Cleric", "Paladin"}
    },
    
    -- Basic armors
    LeatherArmor = {
        name = "Leather Armor",
        description = "Basic protection made of hardened leather.",
        type = "armor",
        slot = "body",
        defense = 6,
        magicDefense = 2,
        value = 90,
        requirements = {},
        jobs = {"Fighter", "Rogue", "Ranger"}
    },
    
    LightLeather = {
        name = "Light Leather",
        description = "Flexible leather gear for agile fighters.",
        type = "armor",
        slot = "body",
        defense = 4,
        magicDefense = 2,
        value = 85,
        requirements = {},
        jobs = {"Rogue", "Assassin", "Ranger"}
    },
    
    ApprenticeRobe = {
        name = "Apprentice Robe",
        description = "A simple robe that aids in channeling magic.",
        type = "armor",
        slot = "body",
        defense = 2,
        magicDefense = 7,
        value = 95,
        requirements = {},
        jobs = {"Mage", "BlackMage", "WhiteMage"}
    },
    
    AcolyteRobe = {
        name = "Acolyte Robe",
        description = "A robe worn by followers of the divine.",
        type = "armor",
        slot = "body",
        defense = 3,
        magicDefense = 6,
        value = 90,
        requirements = {},
        jobs = {"Cleric", "WhiteMage", "Paladin"}
    },
    
    -- Basic shields and offhand items
    WoodenShield = {
        name = "Wooden Shield",
        description = "A basic wooden shield.",
        type = "armor",
        slot = "offhand",
        defense = 5,
        magicDefense = 1,
        value = 70,
        requirements = {
            STR = 4
        },
        jobs = {"Fighter", "Knight", "Paladin"}
    },
    
    HolySymbol = {
        name = "Holy Symbol",
        description = "A symbol of divine power.",
        type = "accessory",
        slot = "offhand",
        defense = 0,
        magicDefense = 4,
        magicAttack = 6,
        value = 85,
        requirements = {
            WIS = 5
        },
        jobs = {"Cleric", "Paladin", "WhiteMage"}
    },
    
    -- Advanced weapons
    Longsword = {
        name = "Longsword",
        description = "A longer blade with better reach.",
        type = "weapon",
        subType = "sword",
        slot = "weapon",
        attack = 16,
        magicAttack = 0,
        value = 220,
        requirements = {
            STR = 8
        },
        jobs = {"Fighter", "Knight", "Paladin"}
    },
    
    BattleAxe = {
        name = "Battle Axe",
        description = "A heavy axe that deals devastating damage.",
        type = "weapon",
        subType = "axe",
        slot = "weapon",
        attack = 20,
        magicAttack = 0,
        value = 250,
        requirements = {
            STR = 12
        },
        jobs = {"Fighter", "Berserker"}
    },
    
    ElementalRod = {
        name = "Elemental Rod",
        description = "A rod infused with elemental power.",
        type = "weapon",
        subType = "wand",
        slot = "weapon",
        attack = 4,
        magicAttack = 18,
        value = 280,
        requirements = {
            INT = 10
        },
        jobs = {"Mage", "BlackMage"}
    },
    
    HealingStaff = {
        name = "Healing Staff",
        description = "A staff that enhances healing magic.",
        type = "weapon",
        subType = "staff",
        slot = "weapon",
        attack = 6,
        magicAttack = 15,
        value = 270,
        requirements = {
            WIS = 10
        },
        jobs = {"Cleric", "WhiteMage"}
    },
    
    AssassinDagger = {
        name = "Assassin Dagger",
        description = "A lethal blade designed for swift kills.",
        type = "weapon",
        subType = "dagger",
        slot = "weapon",
        attack = 14,
        magicAttack = 0,
        critRate = 15,
        value = 260,
        requirements = {
            DEX = 12
        },
        jobs = {"Rogue", "Assassin"}
    },
    
    Bow = {
        name = "Bow",
        description = "A reliable ranged weapon.",
        type = "weapon",
        subType = "bow",
        slot = "weapon",
        attack = 12,
        magicAttack = 0,
        value = 230,
        requirements = {
            DEX = 10
        },
        jobs = {"Ranger"}
    },
    
    -- Advanced armors
    ChainMail = {
        name = "Chain Mail",
        description = "Armor made of interlocking metal rings.",
        type = "armor",
        slot = "body",
        defense = 12,
        magicDefense = 3,
        value = 240,
        requirements = {
            STR = 8
        },
        jobs = {"Fighter", "Knight", "Paladin"}
    },
    
    TribalArmor = {
        name = "Tribal Armor",
        description = "Lightweight armor decorated with tribal symbols.",
        type = "armor",
        slot = "body",
        defense = 8,
        magicDefense = 5,
        value = 220,
        requirements = {},
        jobs = {"Berserker"}
    },
    
    MageRobe = {
        name = "Mage Robe",
        description = "A robe imbued with magical protection.",
        type = "armor",
        slot = "body",
        defense = 5,
        magicDefense = 14,
        value = 250,
        requirements = {
            INT = 10
        },
        jobs = {"Mage", "BlackMage"}
    },
    
    WhiteRobe = {
        name = "White Robe",
        description = "A pristine robe that enhances healing magic.",
        type = "armor",
        slot = "body",
        defense = 6,
        magicDefense = 12,
        value = 240,
        requirements = {
            WIS = 10
        },
        jobs = {"Cleric", "WhiteMage"}
    },
    
    ShadowGarb = {
        name = "Shadow Garb",
        description = "Dark clothing that helps conceal the wearer.",
        type = "armor",
        slot = "body",
        defense = 9,
        magicDefense = 6,
        evasion = 10,
        value = 260,
        requirements = {
            DEX = 12
        },
        jobs = {"Assassin"}
    },
    
    RangerLeathers = {
        name = "Ranger Leathers",
        description = "Treated leather armor favored by rangers.",
        type = "armor",
        slot = "body",
        defense = 10,
        magicDefense = 5,
        value = 235,
        requirements = {
            DEX = 10
        },
        jobs = {"Ranger"}
    },
    
    -- Advanced shields and offhand items
    KiteShield = {
        name = "Kite Shield",
        description = "A large shield that offers excellent protection.",
        type = "armor",
        slot = "offhand",
        defense = 10,
        magicDefense = 3,
        value = 200,
        requirements = {
            STR = 10
        },
        jobs = {"Fighter", "Knight", "Paladin"}
    },
    
    ThrowingKnives = {
        name = "Throwing Knives",
        description = "A set of balanced knives for throwing.",
        type = "weapon",
        subType = "dagger",
        slot = "offhand",
        attack = 8,
        value = 190,
        requirements = {
            DEX = 12
        },
        jobs = {"Rogue", "Assassin"}
    },
    
    QuiverOfArrows = {
        name = "Quiver of Arrows",
        description = "A collection of well-crafted arrows.",
        type = "accessory",
        slot = "offhand",
        attack = 4,
        value = 170,
        requirements = {
            DEX = 10
        },
        jobs = {"Ranger"}
    },
    
    -- Basic amulets and rings
    CopperAmulet = {
        name = "Copper Amulet",
        description = "A simple copper amulet with minor protective properties.",
        type = "accessory",
        slot = "amulet",
        defense = 2,
        magicDefense = 3,
        value = 80,
        requirements = {},
        jobs = {"Fighter", "Knight", "Mage", "Cleric", "Rogue", "Ranger", "BlackMage", "WhiteMage", "Paladin", "Assassin", "Berserker"}
    },
    
    SilverAmulet = {
        name = "Silver Amulet",
        description = "A silver amulet that enhances the wearer's magic abilities.",
        type = "accessory",
        slot = "amulet",
        magicDefense = 5,
        magicAttack = 3,
        value = 150,
        requirements = {},
        jobs = {"Mage", "Cleric", "BlackMage", "WhiteMage", "Paladin"}
    },
    
    AmuletOfProtection = {
        name = "Amulet of Protection",
        description = "An enchanted amulet that provides substantial defense.",
        type = "accessory",
        slot = "amulet",
        defense = 4,
        magicDefense = 6,
        value = 250,
        requirements = {
            WIS = 8
        },
        jobs = {"Fighter", "Knight", "Cleric", "Paladin", "WhiteMage"}
    },
    
    IronRing = {
        name = "Iron Ring",
        description = "A simple iron ring that provides minimal protection.",
        type = "accessory",
        slot = "ring",
        defense = 1,
        value = 50,
        requirements = {},
        jobs = {"Fighter", "Knight", "Mage", "Cleric", "Rogue", "Ranger", "BlackMage", "WhiteMage", "Paladin", "Assassin", "Berserker"}
    },
    
    BandOfStrength = {
        name = "Band of Strength",
        description = "A ring that enhances the wearer's physical power.",
        type = "accessory",
        slot = "ring",
        attack = 3,
        value = 120,
        attributes = {
            STR = 2
        },
        requirements = {
            STR = 6
        },
        jobs = {"Fighter", "Knight", "Paladin", "Berserker"}
    },
    
    MageRing = {
        name = "Mage Ring",
        description = "A ring infused with arcane energy that enhances spellcasting.",
        type = "accessory",
        slot = "ring",
        magicAttack = 5,
        value = 180,
        attributes = {
            INT = 2
        },
        requirements = {
            INT = 6
        },
        jobs = {"Mage", "BlackMage", "WhiteMage", "Cleric"}
    },
    
    RingOfDexterity = {
        name = "Ring of Dexterity",
        description = "A finely crafted ring that improves the wearer's agility.",
        type = "accessory",
        slot = "ring",
        evasion = 5,
        value = 200,
        attributes = {
            DEX = 2
        },
        requirements = {
            DEX = 7
        },
        jobs = {"Rogue", "Ranger", "Assassin"}
    },
    
    -- Master equipment
    SacredBlade = {
        name = "Sacred Blade",
        description = "A legendary sword imbued with holy power.",
        type = "weapon",
        subType = "sword",
        slot = "weapon",
        attack = 30,
        magicAttack = 20,
        element = "holy",
        value = 5000,
        requirements = {
            STR = 18,
            WIS = 15
        },
        jobs = {"Paladin", "HolyKnight"}
    },
    
    ArchmageStaff = {
        name = "Archmage Staff",
        description = "A staff of immense magical power.",
        type = "weapon",
        subType = "staff",
        slot = "weapon",
        attack = 10,
        magicAttack = 35,
        value = 5200,
        requirements = {
            INT = 20,
            WIS = 15
        },
        jobs = {"BlackMage", "WhiteMage", "Archmage"}
    },
    
    ShadowbladeDaggers = {
        name = "Shadowblade Daggers",
        description = "Twin daggers that seem to be made of shadow itself.",
        type = "weapon",
        subType = "dagger",
        slot = "weapon",
        attack = 25,
        magicAttack = 15,
        critRate = 25,
        value = 5100,
        requirements = {
            DEX = 20,
            INT = 12
        },
        jobs = {"Assassin", "Shadowblade"}
    },
    
    DivineAegis = {
        name = "Divine Aegis",
        description = "A shield blessed by the gods.",
        type = "armor",
        slot = "offhand",
        defense = 18,
        magicDefense = 18,
        value = 4800,
        requirements = {
            STR = 15,
            WIS = 15
        },
        jobs = {"Paladin", "HolyKnight"}
    },
    
    HolyCrusaderArmor = {
        name = "Holy Crusader Armor",
        description = "Magnificent armor worn by the most devoted holy knights.",
        type = "armor",
        slot = "body",
        defense = 25,
        magicDefense = 20,
        value = 5500,
        requirements = {
            STR = 18,
            WIS = 15
        },
        jobs = {"Paladin", "HolyKnight"}
    },
    
    ArchmagerobeOfPower = {
        name = "Archmage Robe of Power",
        description = "A masterfully crafted robe that enhances all magical abilities.",
        type = "armor",
        slot = "body",
        defense = 15,
        magicDefense = 30,
        value = 5400,
        requirements = {
            INT = 20,
            WIS = 15
        },
        jobs = {"BlackMage", "WhiteMage", "Archmage"}
    },
    
    ShadowWalkerCloak = {
        name = "Shadow Walker Cloak",
        description = "A mysterious cloak that seems to bend light around the wearer.",
        type = "armor",
        slot = "body",
        defense = 18,
        magicDefense = 18,
        evasion = 20,
        value = 5300,
        requirements = {
            DEX = 20,
            INT = 12
        },
        jobs = {"Assassin", "Shadowblade"}
    },
    
    -- Consumable items
    HealthPotion = {
        name = "Health Potion",
        description = "Restores 50 HP.",
        type = "consumable",
        effect = {
            type = "heal",
            target = "single",
            amount = 50
        },
        value = 30
    },
    
    ManaPotion = {
        name = "Mana Potion",
        description = "Restores 30 MP.",
        type = "consumable",
        effect = {
            type = "restore_mp",
            target = "single",
            amount = 30
        },
        value = 40
    },
    
    Antidote = {
        name = "Antidote",
        description = "Cures poison status.",
        type = "consumable",
        effect = {
            type = "cure_status",
            target = "single",
            status = "poison"
        },
        value = 20
    },
    
    Elixir = {
        name = "Elixir",
        description = "Fully restores HP and MP.",
        type = "consumable",
        effect = {
            type = "full_restore",
            target = "single"
        },
        value = 200
    }
}

-- Monster part definitions
itemSystem.monsterParts = {
    -- Small monster parts
    SlimeCrystal = {
        name = "Slime Crystal",
        description = "A crystallized core of a slime monster.",
        type = "monster_part",
        rarity = 1,
        value = 5
    },
    
    GoblinTooth = {
        name = "Goblin Tooth",
        description = "A sharp tooth from a goblin.",
        type = "monster_part",
        rarity = 1,
        value = 8
    },
    
    BatWing = {
        name = "Bat Wing",
        description = "A wing from a cave bat.",
        type = "monster_part",
        rarity = 1,
        value = 6
    },
    
    SpiderFang = {
        name = "Spider Fang",
        description = "A venomous fang from a large spider.",
        type = "monster_part",
        rarity = 1,
        value = 10
    },
    
    -- Medium monster parts
    OgreHide = {
        name = "Ogre Hide",
        description = "A tough piece of skin from an ogre.",
        type = "monster_part",
        rarity = 2,
        value = 25
    },
    
    WolfPelt = {
        name = "Wolf Pelt",
        description = "The pelt of a fierce wolf.",
        type = "monster_part",
        rarity = 2,
        value = 30
    },
    
    SkeletonBone = {
        name = "Skeleton Bone",
        description = "A bone from a reanimated skeleton.",
        type = "monster_part",
        rarity = 2,
        value = 20
    },
    
    GhostEssence = {
        name = "Ghost Essence",
        description = "The ethereal remnants of a ghost.",
        type = "monster_part",
        rarity = 3,
        value = 45
    },
    
    -- Large monster parts
    DragonScale = {
        name = "Dragon Scale",
        description = "A shimmering scale from a dragon.",
        type = "monster_part",
        rarity = 4,
        value = 100
    },
    
    DemonHorn = {
        name = "Demon Horn",
        description = "A twisted horn from a fearsome demon.",
        type = "monster_part",
        rarity = 4,
        value = 90
    },
    
    PhoenixFeather = {
        name = "Phoenix Feather",
        description = "A brilliant feather that radiates warmth.",
        type = "monster_part",
        rarity = 5,
        value = 150
    },
    
    BehemothHeart = {
        name = "Behemoth Heart",
        description = "The massive heart of a behemoth.",
        type = "monster_part",
        rarity = 5,
        value = 200
    }
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
            if GAME.debug then print("Collect quest active for item: " .. collectQuestItem) end
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
                if GAME.debug then print("Added quest item to loot: " .. itemData.name) end
            else
                 print("Warning: Quest item data not found for " .. collectQuestItem)
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
    if GAME.debug and effectMessage ~= "" then
        print(effectMessage)
    end
    
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
