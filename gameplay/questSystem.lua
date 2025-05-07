-- Quest System
-- Manages quest generation, tracking, and completion
local itemSystem = require("gameplay/item")
local reputationSystem = require("gameplay/reputationSystem")
local questDefinitions = require("gameplay/quest_definitions")

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
        generateRewards = function(difficulty, level, giver)
            local rewards = {
                gold = 0,
                items = {},
                reputation = 0
            }
            
            -- Different reward structures based on quest giver
            if giver == "Guild" then
                -- Guild quests have higher gold rewards
                rewards.gold = 70 * difficulty * level
                rewards.reputation = 10 * difficulty
            else -- Tavern
                -- Tavern quests have lower gold but better item rewards
                rewards.gold = 40 * difficulty * level
                rewards.reputation = 15 * difficulty
                
                -- Add a random item with higher quality for tavern quests
                local itemLevel = level + math.floor(difficulty * 0.5)
                table.insert(rewards.items, itemSystem:getRandomItem("consumable", itemLevel))
            end
            
            return rewards
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
        generateRewards = function(difficulty, level, giver)
            local rewards = {
                gold = 0,
                items = {},
                reputation = 0
            }
            
            if giver == "Guild" then
                -- Guild quests have higher gold rewards
                rewards.gold = 60 * difficulty * level
                rewards.reputation = 15 * difficulty
            else -- Tavern
                -- Tavern quests have lower gold but better item rewards
                rewards.gold = 35 * difficulty * level
                rewards.reputation = 20 * difficulty
                
                -- Add a random weapon or armor for tavern collect quests
                local itemType = math.random() < 0.5 and "weapon" or "armor"
                local itemLevel = level + math.floor(difficulty * 0.5)
                table.insert(rewards.items, itemSystem:getRandomItem(itemType, itemLevel))
            end
            
            return rewards
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
        generateRewards = function(difficulty, level, giver)
            local rewards = {
                gold = 0,
                items = {},
                reputation = 0
            }
            
            if giver == "Guild" then
                -- Guild exploration quests have map rewards
                rewards.gold = 50 * difficulty * level
                rewards.reputation = 15 * difficulty
                
                -- Add map item for high difficulty guild quests
                if difficulty >= questSystem.DIFFICULTY.HARD then
                    table.insert(rewards.items, {
                        type = "consumable",
                        name = "Detailed Map",
                        description = "Reveals more of the dungeon map"
                    })
                end
            else -- Tavern
                -- Tavern exploration has treasure rewards
                rewards.gold = 25 * difficulty * level
                rewards.reputation = 25 * difficulty
                
                -- Always add a random item for tavern explore quests
                local itemTypes = {"weapon", "armor", "accessory", "consumable"}
                local itemType = itemTypes[math.random(1, #itemTypes)]
                local itemLevel = level + difficulty
                table.insert(rewards.items, itemSystem:getRandomItem(itemType, itemLevel))
            end
            
            return rewards
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
        generateRewards = function(difficulty, level, giver)
            local rewards = {
                gold = 0,
                items = {},
                reputation = 0
            }
            
            if giver == "Guild" then
                -- Guild escort missions are formal and have good gold
                rewards.gold = 100 * difficulty * level
                rewards.reputation = 30 * difficulty
                
                -- Add faction-specific equipment for guild escort
                if difficulty >= questSystem.DIFFICULTY.MEDIUM then
                    table.insert(rewards.items, {
                        type = "accessory",
                        name = "Guild Insignia",
                        description = "Marks you as a trusted guild escort"
                    })
                end
            else -- Tavern
                -- Tavern escort missions are risky but rewarding
                rewards.gold = 60 * difficulty * level
                rewards.reputation = 40 * difficulty
                
                -- Add multiple random items for tavern escort quests
                for i = 1, math.min(difficulty, 3) do
                    local itemTypes = {"weapon", "armor", "accessory"}
                    local itemType = itemTypes[math.random(1, #itemTypes)]
                    local itemLevel = level + difficulty
                    table.insert(rewards.items, itemSystem:getRandomItem(itemType, itemLevel))
                end
            end
            
            return rewards
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
        generateRewards = function(difficulty, level, giver)
            local rewards = {
                gold = 0,
                items = {},
                reputation = 0
            }
            
            if giver == "Guild" then
                -- Guild boss quests have excellent gold and reputation
                rewards.gold = 150 * difficulty * level
                rewards.reputation = 50 * difficulty
                
                -- Add high-quality guild equipment
                table.insert(rewards.items, itemSystem:getRandomItem("weapon", level + difficulty))
                
                -- Add guild-specific reward for high difficulty
                if difficulty >= questSystem.DIFFICULTY.HARD then
                    table.insert(rewards.items, {
                        type = "accessory",
                        name = "Guild Champion Badge",
                        description = "Marks you as a guild champion who has defeated powerful foes"
                    })
                end
            else -- Tavern
                -- Tavern boss quests have moderate gold but excellent items
                rewards.gold = 80 * difficulty * level
                rewards.reputation = 75 * difficulty
                
                -- Add multiple high-quality items
                table.insert(rewards.items, itemSystem:getRandomItem("weapon", level + difficulty + 1))
                table.insert(rewards.items, itemSystem:getRandomItem("armor", level + difficulty + 1))
                
                -- Add rare unique item for tavern boss quests
                if difficulty >= questSystem.DIFFICULTY.MEDIUM then
                    table.insert(rewards.items, {
                        type = "accessory",
                        name = "Trophy: " .. objective.bossName,
                        description = "A trophy from your defeat of " .. objective.bossName
                    })
                end
            end
            
            return rewards
        end
    }
}

-- Load quest data from external file
questSystem.quests = questDefinitions

-- Get available quests for a specific location
function questSystem:getAvailableQuests(location, level)
    local available = {}
    
    for _, quest in ipairs(self.quests) do
        if quest.giver == location and quest.status == self.STATUS.AVAILABLE then
            -- Check if the quest is in the completed quests list
            local isCompleted = false
            if GAME.completedQuests then
                for _, completedQuest in ipairs(GAME.completedQuests) do
                    if completedQuest.id == quest.id then
                        isCompleted = true
                        break
                    end
                end
            end
            
            -- Only add if not completed and level appropriate (within 3 levels)
            if not isCompleted and (not level or math.abs(quest.level - level) <= 3) then
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
        -- Monster targets based on level and categories
        local monsterCategories = {
            { -- Level 1-2
                {id = "fungal_fighter", name = "Fungal Fighter"},
                {id = "shroomling", name = "Shroomling"},
                {id = "zombie_farmer", name = "Zombie Farmer"},
                {id = "horned_beetle", name = "Horned Beetle"}
            },
            { -- Level 3-4
                {id = "walking_mushroom", name = "Walking Mushroom"},
                {id = "toxic_sporeling", name = "Toxic Sporeling"},
                {id = "cultists_initiate", name = "Cultist Initiate"},
                {id = "hooded_cultist", name = "Hooded Cultist"},
                {id = "zombie_biter", name = "Zombie Biter"},
                {id = "skeletal_hound", name = "Skeletal Hound"},
                {id = "buzzer", name = "Buzzer"},
                {id = "armored_ant", name = "Armored Ant"}
            },
            { -- Level 5-7
                {id = "fungal_zombie", name = "Fungal Zombie"},
                {id = "cult_warlock", name = "Cult Warlock"},
                {id = "cultist_pyromancer", name = "Cultist Pyromancer"},
                {id = "plague_cultist", name = "Plague Cultist"},
                {id = "skeleton_warrior", name = "Skeleton Warrior"},
                {id = "ghoul_stalker", name = "Ghoul Stalker"},
                {id = "tormented_ghoul", name = "Tormented Ghoul"},
                {id = "mantis_warrior", name = "Mantis Warrior"},
                {id = "wasp_demon", name = "Wasp Demon"}
            }
        }
        
        -- Select appropriate category based on level
        local categoryIndex = math.min(math.ceil(level / 2), #monsterCategories)
        local category = monsterCategories[categoryIndex]
        
        -- Select random monster from appropriate category
        local monster = category[math.random(1, #category)]
        
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
            { -- Level 5-7
                {id = "spore_witch_boss", name = "Spore Witch"},
                {id = "chanting_fanatic_boss", name = "Chanting Fanatic"}
            },
            { -- Level 8-9
                {id = "spore_lord_boss", name = "Spore Lord"},
                {id = "skeleton_general_boss", name = "Skeleton General"},
                {id = "matron_zirrk_boss", name = "Matron Zirrk"}
            },
            { -- Level 10+
                {id = "demonic_leader_boss", name = "Demonic Leader"},
                {id = "lich_king_boss", name = "Lich King"},
                {id = "killerpede_boss", name = "Killerpede"}
            }
        }
        
        -- Locations
        local locations = {
            {id = 1, name = "Fungal Grove"},
            {id = 2, name = "Cultist Altar"},
            {id = 3, name = "Ancient Crypt"},
            {id = 4, name = "Dragon's Lair"},
            {id = 5, name = "Insect Hive"},
            {id = 6, name = "Corrupted Temple"}
        }
        
        -- Select boss based on level
        local categoryIndex = math.min(math.ceil((level - 4) / 2), #bosses)
        categoryIndex = math.max(1, categoryIndex) -- Ensure minimum index is 1
        local bossCategory = bosses[categoryIndex]
        local boss = bossCategory[math.random(1, #bossCategory)]
        
        -- Select random location
        local location = locations[math.random(1, #locations)]
        
        params = {
            bossId = boss.id,
            bossName = boss.name,
            locationId = location.id,
            locationName = location.name
        }
    end
    
    -- Generate quest objective and description
    local objective = questTemplate.generateObjective(params)
    local description = questTemplate.generateDescription(params)
    
    -- Generate rewards
    local rewards = questTemplate.generateRewards(difficulty, level, giver)
    
    -- Add time limit for Guild quests
    local timeLimit = nil
    if giver == "Guild" then
        -- Guild quests have time limits based on difficulty
        timeLimit = {
            days = math.max(1, 5 - difficulty), -- Harder quests have shorter deadlines
            inGameTime = true -- Uses in-game time rather than real time
        }
    end
    
    -- Add hidden objectives for Tavern quests
    local hiddenObjectives = nil
    if giver == "Tavern" and math.random() < 0.3 then
        hiddenObjectives = {
            {
                description = "Find a secret item in the dungeon",
                type = "item_find",
                itemId = "hidden_item_" .. math.random(1, 5),
                completed = false
            }
        }
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
        seed = seed,
        timeLimit = timeLimit, -- Only set for Guild quests
        hiddenObjectives = hiddenObjectives, -- Only set for some Tavern quests
        -- Additional fields for quest differentiation
        isReliable = giver == "Guild", -- Guild info is reliable, Tavern info may not be
        hasPenalty = giver == "Guild", -- Guild quests have reputation penalties for failure
        canHaggle = giver == "Tavern", -- Only Tavern quests can be haggled
        haggleAttempts = 0 -- Track haggle attempts for Tavern quests
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
                
                -- Add to completed quests if not already there
                if not GAME.completedQuests then
                    GAME.completedQuests = {quest}
                else
                    -- Check if already in completed quests
                    local alreadyExists = false
                    for _, completedQuest in ipairs(GAME.completedQuests) do
                        if completedQuest.id == questId then
                            alreadyExists = true
                            break
                        end
                    end
                    
                    -- Only add if not already in the list
                    if not alreadyExists then
                        table.insert(GAME.completedQuests, quest)
                    end
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
                itemSystem:addToInventory(item)
            end
        end
        
        -- Add reputation reward
        if completedQuest.rewards.reputation and completedQuest.rewards.reputation > 0 then
            -- Initialize reputation system
            reputationSystem:init()
            
            -- Add reputation with the quest giver faction
            reputationSystem:changeReputation(completedQuest.giver, completedQuest.rewards.reputation)
        end
        
        return completedQuest
    end
    
    return nil
end

-- Fail a quest
function questSystem:failQuest(questId)
    -- Find quest
    local failedQuest = nil
    
    if GAME.activeQuests then
        for i, quest in ipairs(GAME.activeQuests) do
            if quest.id == questId and quest.status == self.STATUS.ACTIVE then
                quest.status = self.STATUS.FAILED
                failedQuest = quest
                
                -- Remove from active quests
                table.remove(GAME.activeQuests, i)
                
                -- Add to failed quests if tracking
                if GAME.failedQuests then
                    table.insert(GAME.failedQuests, quest)
                else
                    GAME.failedQuests = {quest}
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
    
    -- Apply reputation penalty for Guild quests
    if failedQuest and failedQuest.hasPenalty then
        -- Initialize reputation system
        reputationSystem:init()
        
        -- Reduce reputation with the Guild (penalty is scaled by difficulty)
        local repPenalty = -10 * failedQuest.difficulty
        reputationSystem:changeReputation(failedQuest.giver, repPenalty)
    end
    
    return failedQuest
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
    -- Reset status to available for all quests not active or completed
    for _, quest in ipairs(self.quests) do
        -- Skip active quests
        if quest.status ~= self.STATUS.ACTIVE then
            -- Check if the quest is in the completed quests list
            local isCompleted = false
            if GAME.completedQuests then
                for _, completedQuest in ipairs(GAME.completedQuests) do
                    if completedQuest.id == quest.id then
                        isCompleted = true
                        break
                    end
                end
            end
            
            -- Only reset to available if not completed
            if not isCompleted then
                quest.status = self.STATUS.AVAILABLE
            end
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

-- Attempt to haggle for a Tavern quest
function questSystem:haggle(questId, character)
    -- Find quest
    local quest = nil
    
    for _, q in ipairs(self.quests) do
        if q.id == questId then
            quest = q
            break
        end
    end
    
    if not quest or not quest.canHaggle then
        return false, "This quest cannot be haggled"
    end
    
    -- Check if quest is from Tavern
    if quest.giver ~= "Tavern" then
        return false, "You can only haggle with tavern questgivers"
    end
    
    -- Check if haggle attempts exceeded
    if quest.haggleAttempts >= 3 then
        return false, "The questgiver refuses to haggle further"
    end
    
    -- Calculate success chance based on character's CHA attribute
    local charisma = character.attributes.CHA or 5
    local baseChance = 30 + charisma * 3
    
    -- Reduce chance based on previous attempts
    local successChance = baseChance - (quest.haggleAttempts * 15)
    successChance = math.max(5, math.min(95, successChance)) -- Clamp between 5% and 95%
    
    -- Roll for haggle result
    local roll = math.random(1, 100)
    local result = ""
    local repChange = 0
    
    -- Increment haggle attempts
    quest.haggleAttempts = quest.haggleAttempts + 1
    
    -- Process haggle result
    if roll <= successChance / 3 then
        -- Great success - increase gold by 25-40%
        local goldIncrease = math.random(25, 40) / 100
        quest.rewards.gold = math.floor(quest.rewards.gold * (1 + goldIncrease))
        
        -- Maybe add an extra item
        if math.random() < 0.3 then
            local itemLevel = quest.level + quest.difficulty
            table.insert(quest.rewards.items, itemSystem:getRandomItem("consumable", itemLevel))
        end
        
        result = "Great success! Gold reward increased by " .. math.floor(goldIncrease * 100) .. "%"
        repChange = 5
    elseif roll <= successChance then
        -- Success - increase gold by 10-20%
        local goldIncrease = math.random(10, 20) / 100
        quest.rewards.gold = math.floor(quest.rewards.gold * (1 + goldIncrease))
        result = "Success! Gold reward increased by " .. math.floor(goldIncrease * 100) .. "%"
        repChange = 2
    elseif roll <= successChance + 20 then
        -- Partial success - small increase
        local goldIncrease = math.random(5, 10) / 100
        quest.rewards.gold = math.floor(quest.rewards.gold * (1 + goldIncrease))
        result = "Partial success. Gold reward increased slightly"
        repChange = 0
    else
        -- Failure - chance to decrease reward
        if math.random() < 0.4 then  -- 40% chance to decrease reward
            local goldDecrease = math.random(10, 20) / 100
            quest.rewards.gold = math.floor(quest.rewards.gold * (1 - goldDecrease))
            result = "Haggle failed badly! The questgiver reduced the reward by " .. math.floor(goldDecrease * 100) .. "%"
        else
            result = "Haggle failed. The questgiver seems annoyed"
        end
        
        repChange = -5
    end
    
    -- Apply reputation change
    if repChange ~= 0 then
        reputationSystem:init()
        reputationSystem:changeReputation("Tavern", repChange)
    end
    
    return true, result, successChance
end

return questSystem
