-- Quest System
-- Manages quest generation, tracking, and completion
local itemSystem = require("gameplay/item")

local questSystem = {
    quests = {},
    questTypes = {}
}

-- Quest difficulty levels
questSystem.DIFFICULTY = {
    EASY = 1,
    MEDIUM = 2,
    HARD = 3,
    VERY_HARD = 4,
    LEGENDARY = 5
}

-- Quest status
questSystem.STATUS = {
    AVAILABLE = "available",
    ACTIVE = "active",
    COMPLETED = "completed",
    FAILED = "failed"
}

-- Quest types
questSystem.questTypes = {
    -- Kill quest
    KILL = {
        name = "Hunt",
        description = "Defeat specific monsters in the dungeon.",
        generateDescription = function(params)
            return "Defeat " .. params.count .. " " .. params.targetName .. " in the dungeon."
        end,
        generateObjective = function(params)
            return {
                type = "kill",
                targetId = params.targetId,
                targetName = params.targetName,
                count = params.count,
                current = 0
            }
        end,
        checkCompletion = function(objective, event, data)
            if event == "kill" and data.monsterId == objective.targetId then
                objective.current = objective.current + 1
                return objective.current >= objective.count
            end
            return false
        end,
        generateRewards = function(difficulty, level)
            return {
                gold = 50 * difficulty * level,
                items = {}
            }
        end
    },
    
    -- Collect quest
    COLLECT = {
        name = "Collect",
        description = "Collect specific items from the dungeon.",
        generateDescription = function(params)
            return "Collect " .. params.count .. " " .. params.itemName .. " from the dungeon."
        end,
        generateObjective = function(params)
            return {
                type = "collect",
                itemId = params.itemId,
                itemName = params.itemName,
                count = params.count,
                current = 0
            }
        end,
        checkCompletion = function(objective, event, data)
            if event == "item_pickup" and data.itemId == objective.itemId then
                objective.current = objective.current + data.count or 1
                return objective.current >= objective.count
            end
            return false
        end,
        generateRewards = function(difficulty, level)
            return {
                gold = 40 * difficulty * level,
                items = {}
            }
        end
    },
    
    -- Explore quest
    EXPLORE = {
        name = "Explore",
        description = "Explore a specific dungeon area.",
        generateDescription = function(params)
            return "Explore the " .. params.locationName .. " dungeon."
        end,
        generateObjective = function(params)
            return {
                type = "explore",
                locationId = params.locationId,
                locationName = params.locationName,
                completed = false
            }
        end,
        checkCompletion = function(objective, event, data)
            if event == "explore" and data.locationId == objective.locationId then
                objective.completed = true
                return true
            end
            return false
        end,
        generateRewards = function(difficulty, level)
            return {
                gold = 30 * difficulty * level,
                items = {}
            }
        end
    },
    
    -- Escort quest
    ESCORT = {
        name = "Escort",
        description = "Escort an NPC safely through the dungeon.",
        generateDescription = function(params)
            return "Escort " .. params.npcName .. " safely through the " .. params.locationName .. "."
        end,
        generateObjective = function(params)
            return {
                type = "escort",
                npcId = params.npcId,
                npcName = params.npcName,
                locationId = params.locationId,
                locationName = params.locationName,
                completed = false,
                failed = false
            }
        end,
        checkCompletion = function(objective, event, data)
            if event == "escort_complete" and data.npcId == objective.npcId then
                objective.completed = true
                return true
            elseif event == "escort_failed" and data.npcId == objective.npcId then
                objective.failed = true
                return false
            end
            return false
        end,
        generateRewards = function(difficulty, level)
            return {
                gold = 70 * difficulty * level,
                items = {}
            }
        end
    },
    
    -- Boss quest
    BOSS = {
        name = "Boss",
        description = "Defeat a powerful boss in the dungeon.",
        generateDescription = function(params)
            return "Defeat the boss " .. params.bossName .. " in the " .. params.locationName .. "."
        end,
        generateObjective = function(params)
            return {
                type = "boss",
                bossId = params.bossId,
                bossName = params.bossName,
                locationId = params.locationId,
                locationName = params.locationName,
                completed = false
            }
        end,
        checkCompletion = function(objective, event, data)
            if event == "boss_kill" and data.bossId == objective.bossId then
                objective.completed = true
                return true
            end
            return false
        end,
        generateRewards = function(difficulty, level)
            -- Boss quests have better rewards
            local rewards = {
                gold = 100 * difficulty * level,
                items = {}
            }
            
            -- Add rare item reward
            table.insert(rewards.items, itemSystem:getRandomItem("consumable", difficulty * level))
            
            return rewards
        end
    }
}

-- Sample quest data
questSystem.quests = {
    -- Easy quests
    {
        id = "rats_in_cellar",
        name = "Rats in the Cellar",
        description = "The tavern's cellar is infested with giant rats. Clear them out.",
        type = "KILL",
        level = 1,
        difficulty = questSystem.DIFFICULTY.EASY,
        giver = "Tavern",
        objective = {
            type = "kill",
            targetId = "monster_rat",
            targetName = "Giant Rat",
            count = 5,
            current = 0
        },
        rewards = { gold = 50, items = {} },
        status = questSystem.STATUS.AVAILABLE,
        seed = 12345 -- Seed for dungeon generation
    },
    {
        id = "missing_supplies",
        name = "Missing Supplies",
        description = "A shipment of supplies has gone missing. Search the nearby cave.",
        type = "EXPLORE",
        level = 1,
        difficulty = questSystem.DIFFICULTY.EASY,
        giver = "Guild",
        objective = {
            type = "explore",
            locationId = 1,
            locationName = "Foggy Cave",
            completed = false
        },
        rewards = {
            gold = 30,
            items = {}
        },
        status = questSystem.STATUS.AVAILABLE,
        seed = 23456
    },
    
    -- Medium quests
    {
        id = "goblin_raid",
        name = "Goblin Raid",
        description = "A group of goblins has been raiding the town. Take them out.",
        type = "KILL",
        level = 3,
        difficulty = questSystem.DIFFICULTY.MEDIUM,
        giver = "Guild",
        objective = {
            type = "kill",
            targetId = 2, -- Goblin ID
            targetName = "Goblin",
            count = 8,
            current = 0
        },
        rewards = { gold = 150, items = {} },
        status = questSystem.STATUS.AVAILABLE,
        seed = 34567
    },
    {
        id = "herb_collection",
        name = "Medicinal Herbs",
        description = "The town healer needs rare herbs found in the forest.",
        type = "COLLECT",
        level = 2,
        difficulty = questSystem.DIFFICULTY.MEDIUM,
        giver = "Tavern",
        objective = {
            type = "collect",
            itemId = "item_rare_herb",
            itemName = "Rare Healing Herb",
            count = 5,
            current = 0
        },
        rewards = {
            gold = 500,
            items = {
                {
                    type = "weapon",
                    name = "item_troll_crusher",
                    count = 1
                }
            }
        },
        status = questSystem.STATUS.AVAILABLE,
        seed = 45678
    },
    
    -- Hard quests
    {
        id = "escort_merchant",
        name = "Merchant Escort",
        description = "Escort a merchant safely through the dangerous mountain pass.",
        type = "ESCORT",
        level = 5,
        difficulty = questSystem.DIFFICULTY.HARD,
        giver = "Guild",
        objective = {
            type = "escort",
            npcId = 1,
            npcName = "Merchant Thomas",
            locationId = 3,
            locationName = "Mountain Pass",
            completed = false,
            failed = false
        },
        rewards = {
            gold = 350,
            items = {
                {
                    type = "accessory",
                    name = "Lucky Charm",
                    count = 1
                }
            }
        },
        status = questSystem.STATUS.AVAILABLE,
        seed = 56789
    },
    {
        id = "troll_boss",
        name = "The Bridge Troll",
        description = "A massive troll has taken residence under the bridge, blocking trade routes.",
        type = "BOSS",
        level = 6,
        difficulty = questSystem.DIFFICULTY.HARD,
        giver = "Guild",
        objective = {
            type = "boss",
            bossId = 1,
            bossName = "Bridge Troll",
            locationId = 4,
            locationName = "Stone Bridge",
            completed = false
        },
        rewards = {
            gold = 500,
            items = {
                {
                    type = "weapon",
                    name = "Troll Crusher",
                    count = 1
                }
            }
        },
        status = questSystem.STATUS.AVAILABLE,
        seed = 67890
    }
}

-- Get available quests for a specific location
function questSystem:getAvailableQuests(location, level)
    local available = {}
    
    for _, quest in ipairs(self.quests) do
        if quest.giver == location and quest.status == self.STATUS.AVAILABLE then
            -- Check if level appropriate (within 3 levels)
            if not level or math.abs(quest.level - level) <= 3 then
                table.insert(available, quest)
            end
        end
    end
    
    return available
end

-- Generate a random quest
function questSystem:generateRandomQuest(giver, level, difficulty)
    -- Default values
    level = level or 1
    difficulty = difficulty or self.DIFFICULTY.EASY
    
    -- Choose a random quest type
    local questTypes = {"KILL", "COLLECT", "EXPLORE", "ESCORT", "BOSS"}
    local questType = questTypes[math.random(1, #questTypes)]
    
    -- Set up quest parameters based on type
    local params = {}
    local seed = math.random(10000, 99999)
    local questTemplate = self.questTypes[questType]
    
    if questType == "KILL" then
        -- Monster targets based on level
        local monsters = {
            {id = 1, name = "Giant Rat"},
            {id = 2, name = "Goblin"},
            {id = 3, name = "Skeleton"},
            {id = 4, name = "Orc"},
            {id = 5, name = "Troll"}
        }
        
        -- Select monster based on level
        local monsterIndex = math.min(level, #monsters)
        local monster = monsters[monsterIndex]
        
        params = {
            targetId = monster.id,
            targetName = monster.name,
            count = 3 + difficulty * 2  -- More monsters for higher difficulty
        }
    elseif questType == "COLLECT" then
        -- Item targets
        local items = {
            {id = "item_rare_herb", name = "Rare Healing Herb"},
            {id = "item_magic_crystal", name = "Magic Crystal"},
            {id = "item_ancient_relic", name = "Ancient Relic"},
            {id = "item_dragon_scale", name = "Dragon Scale"},
            {id = "item_enchanted_gem", name = "Enchanted Gem"}
        }
        
        -- Select item based on level
        local itemIndex = math.min(level, #items)
        local item = items[itemIndex]
        
        params = {
            itemId = item.id,
            itemName = item.name,
            count = 2 + difficulty  -- More items for higher difficulty
        }
    elseif questType == "EXPLORE" then
        -- Locations
        local locations = {
            {id = 1, name = "Foggy Cave"},
            {id = 2, name = "Dark Forest"},
            {id = 3, name = "Ancient Ruins"},
            {id = 4, name = "Volcanic Cavern"},
            {id = 5, name = "Frozen Temple"}
        }
        
        -- Select location based on level
        local locationIndex = math.min(level, #locations)
        local location = locations[locationIndex]
        
        params = {
            locationId = location.id,
            locationName = location.name
        }
    elseif questType == "ESCORT" then
        -- NPCs
        local npcs = {
            {id = 1, name = "Merchant Thomas"},
            {id = 2, name = "Scholar Eliza"},
            {id = 3, name = "Ambassador Krell"},
            {id = 4, name = "Priestess Lyra"},
            {id = 5, name = "Prince Aldric"}
        }
        
        -- Locations
        local locations = {
            {id = 1, name = "Trade Route"},
            {id = 2, name = "Mountain Pass"},
            {id = 3, name = "Ancient Road"},
            {id = 4, name = "Swamp Path"},
            {id = 5, name = "Royal Highway"}
        }
        
        -- Select NPC and location based on level
        local npcIndex = math.min(level, #npcs)
        local locationIndex = math.min(level, #locations)
        
        params = {
            npcId = npcs[npcIndex].id,
            npcName = npcs[npcIndex].name,
            locationId = locations[locationIndex].id,
            locationName = locations[locationIndex].name
        }
    elseif questType == "BOSS" then
        -- Bosses
        local bosses = {
            {id = "boss_spider", name = "Giant Spider"},
            {id = "boss_ogre_chief", name = "Ogre Chieftain"},
            {id = "boss_necromancer", name = "Necromancer"},
            {id = "boss_wyvern", name = "Wyvern"},
            {id = "boss_dragon", name = "Ancient Dragon"}
        }
        
        -- Locations
        local locations = {
            {id = 1, name = "Spider's Nest"},
            {id = 2, name = "Ogre Camp"},
            {id = 3, name = "Haunted Crypt"},
            {id = 4, name = "Dragon's Lair"},
            {id = 5, name = "Ancient Throne"}
        }
        
        -- Select boss and location based on level
        local bossIndex = math.min(level, #bosses)
        local locationIndex = math.min(level, #locations)
        
        params = {
            bossId = bosses[bossIndex].id,
            bossName = bosses[bossIndex].name,
            locationId = locations[locationIndex].id,
            locationName = locations[locationIndex].name
        }
    end
    
    -- Generate quest objective and description
    local objective = questTemplate.generateObjective(params)
    local description = questTemplate.generateDescription(params)
    
    -- Generate rewards
    local rewards = questTemplate.generateRewards(difficulty, level)
    
    -- Add special items for higher difficulty
    if difficulty >= self.DIFFICULTY.HARD then
        table.insert(rewards.items, itemSystem:getRandomItem(math.random() < 0.5 and "weapon" or "armor", level))
    end
    
    -- Create quest
    local quest = {
        id = "quest_" .. os.time() .. "_" .. math.random(1000, 9999),
        name = questTemplate.name .. ": " .. params.targetName or params.locationName or params.npcName or params.bossName,
        description = description,
        type = questType,
        level = level,
        difficulty = difficulty,
        giver = giver,
        objective = objective,
        rewards = rewards,
        status = self.STATUS.AVAILABLE,
        seed = seed
    }
    
    return quest
end

-- Accept a quest
function questSystem:acceptQuest(questId)
    -- Find quest
    for _, quest in ipairs(self.quests) do
        if quest.id == questId and quest.status == self.STATUS.AVAILABLE then
            quest.status = self.STATUS.ACTIVE
            
            -- Add to active quests list if exists
            if GAME.activeQuests then
                table.insert(GAME.activeQuests, quest)
            else
                GAME.activeQuests = {quest}
            end
            
            return true
        end
    end
    
    return false
end

-- Complete a quest
function questSystem:completeQuest(questId)
    -- Find quest
    local completedQuest = nil
    
    -- Check active quests
    if GAME.activeQuests then
        for i, quest in ipairs(GAME.activeQuests) do
            if quest.id == questId and quest.status == self.STATUS.ACTIVE then
                quest.status = self.STATUS.COMPLETED
                completedQuest = quest
                
                -- Remove from active quests
                table.remove(GAME.activeQuests, i)
                
                -- Add to completed quests
                if GAME.completedQuests then
                    table.insert(GAME.completedQuests, quest)
                else
                    GAME.completedQuests = {quest}
                end
                
                break
            end
        end
    end
    
    -- Check main quest list
    for _, quest in ipairs(self.quests) do
        if quest.id == questId then
            quest.status = self.STATUS.COMPLETED
            break
        end
    end
    
    if completedQuest then
        -- Give rewards
        GAME.gold = (GAME.gold or 0) + completedQuest.rewards.gold
        
        -- Add item rewards to inventory
        if completedQuest.rewards.items then
            for _, item in ipairs(completedQuest.rewards.items) do
                if not GAME.inventory then
                    GAME.inventory = {}
                end
                
                -- Check if item already exists in inventory
                local found = false
                for _, invItem in ipairs(GAME.inventory) do
                    if invItem.name == item.name then
                        invItem.count = (invItem.count or 1) + (item.count or 1)
                        found = true
                        break
                    end
                end
                
                -- Add new item if not found
                if not found then
                    table.insert(GAME.inventory, item)
                end
            end
        end
        
        return completedQuest
    end
    
    return nil
end

-- Fail a quest
function questSystem:failQuest(questId)
    -- Find quest
    if GAME.activeQuests then
        for i, quest in ipairs(GAME.activeQuests) do
            if quest.id == questId and quest.status == self.STATUS.ACTIVE then
                quest.status = self.STATUS.FAILED
                
                -- Remove from active quests
                table.remove(GAME.activeQuests, i)
                
                -- Add to failed quests if tracking
                if GAME.failedQuests then
                    table.insert(GAME.failedQuests, quest)
                end
                
                break
            end
        end
    end
    
    -- Check main quest list
    for _, quest in ipairs(self.quests) do
        if quest.id == questId then
            quest.status = self.STATUS.FAILED
            break
        end
    end
end

-- Update quest progress
function questSystem:updateProgress(event, data)
    if not GAME.activeQuests then return {} end
    
    local completedQuests = {}
    
    -- Iterate backwards to safely remove completed quests
    for i = #GAME.activeQuests, 1, -1 do
        local quest = GAME.activeQuests[i]
        local questType = self.questTypes[quest.type]
        local objectiveMet = false
        
        if questType and questType.checkCompletion then
            -- Check if event updates this quest's objective
            local objectiveUpdated = questType.checkCompletion(quest.objective, event, data)
            
            if objectiveUpdated then
                -- Objective was updated, now check if it's met
                if quest.type == "KILL" or quest.type == "COLLECT" then
                    objectiveMet = quest.objective.current >= quest.objective.count
                elseif quest.type == "EXPLORE" or quest.type == "BOSS" or quest.type == "ESCORT" then
                    objectiveMet = quest.objective.completed
                end
            end
        end
        
        -- If objective is met, complete the quest
        if objectiveMet then
            if GAME.debug then print("Objective met for quest: " .. quest.id) end
            local completedQuest = self:completeQuest(quest.id) -- completeQuest handles removal from activeQuests
            if completedQuest then
                table.insert(completedQuests, completedQuest)
            end
            -- Since we iterated backwards and removed via completeQuest, the loop index remains valid.
        end
    end
    
    return completedQuests -- Return list of quests completed by this event
end

-- Get available quest count for a location
function questSystem:getAvailableQuestCount(location)
    local count = 0
    
    for _, quest in ipairs(self.quests) do
        if quest.giver == location and quest.status == self.STATUS.AVAILABLE then
            count = count + 1
        end
    end
    
    return count
end

-- Reset available quests
function questSystem:resetAvailableQuests()
    -- Reset status to available for all quests not active
    for _, quest in ipairs(self.quests) do
        if quest.status ~= self.STATUS.ACTIVE then
            quest.status = self.STATUS.AVAILABLE
        end
    end
    
    -- Add some new random quests
    -- TODO: Generate some random quests
end

-- Get active quests
function questSystem:getActiveQuests()
    -- Return the active quests list or empty table if none
    return GAME.activeQuests or {}
end

-- Get completed quests
function questSystem:getCompletedQuests()
    -- Return the completed quests list or empty table if none
    return GAME.completedQuests or {}
end

return questSystem
