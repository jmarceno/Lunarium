-- Reputation System
-- Tracks player standing with different factions

local reputationSystem = {
    factions = {
        GUILD = "Guild",
        TAVERN = "Tavern"
    },
    levels = {
        HOSTILE = -2,
        UNFRIENDLY = -1,
        NEUTRAL = 0,
        FRIENDLY = 1,
        HONORED = 2,
        REVERED = 3,
        EXALTED = 4
    },
    thresholds = {
        [-2] = -1000,  -- HOSTILE
        [-1] = -500,   -- UNFRIENDLY
        [0] = 0,       -- NEUTRAL
        [1] = 500,     -- FRIENDLY
        [2] = 1500,    -- HONORED
        [3] = 3000,    -- REVERED
        [4] = 5000     -- EXALTED
    },
    levelNames = {
        [-2] = "Hostile",
        [-1] = "Unfriendly",
        [0] = "Neutral",
        [1] = "Friendly", 
        [2] = "Honored",
        [3] = "Revered",
        [4] = "Exalted"
    }
}

-- Initialize player's reputation with all factions
function reputationSystem:init()
    if not GAME.reputation then
        GAME.reputation = {}
        for _, faction in pairs(self.factions) do
            GAME.reputation[faction] = 0 -- Start at neutral
        end
    end
    
    -- Initialize notification queue if not exists
    if not GAME.reputationNotifications then
        GAME.reputationNotifications = {}
    end
end

-- Get player's current reputation with a faction
function reputationSystem:getReputation(faction)
    self:init() -- Ensure reputation system is initialized
    return GAME.reputation[faction] or 0
end

-- Get player's reputation level with a faction
function reputationSystem:getReputationLevel(faction)
    local rep = self:getReputation(faction)
    local level = 0
    
    for l, threshold in pairs(self.thresholds) do
        if rep >= threshold then
            level = l
        else
            break
        end
    end
    
    return level
end

-- Get reputation level name
function reputationSystem:getReputationLevelName(level)
    return self.levelNames[level] or "Unknown"
end

-- Change player's reputation with a faction
function reputationSystem:changeReputation(faction, amount)
    self:init() -- Ensure reputation system is initialized
    
    -- Get current values
    local oldRep = GAME.reputation[faction] or 0
    local oldLevel = self:getReputationLevel(faction)
    
    -- Update reputation
    GAME.reputation[faction] = oldRep + amount
    
    -- Check for level change
    local newLevel = self:getReputationLevel(faction)
    
    -- Add notification if level changed
    if newLevel ~= oldLevel then
        table.insert(GAME.reputationNotifications, {
            faction = faction,
            oldLevel = oldLevel,
            newLevel = newLevel,
            timestamp = os.time()
        })
        
        -- Return true if level changed
        return true, newLevel
    end
    
    -- Return false if level didn't change
    return false, newLevel
end

-- Check if player has at least a specific reputation level with a faction
function reputationSystem:hasReputationLevel(faction, level)
    local currentLevel = self:getReputationLevel(faction)
    return currentLevel >= level
end

-- Get available faction rewards based on reputation level
function reputationSystem:getAvailableRewards(faction)
    local level = self:getReputationLevel(faction)
    local rewards = {}
    
    -- Guild rewards
    if faction == self.factions.GUILD then
        if level >= self.levels.FRIENDLY then
            table.insert(rewards, {
                type = "discount",
                name = "Equipment Discount",
                description = "10% discount on all equipment purchases",
                value = 0.1
            })
        end
        
        if level >= self.levels.HONORED then
            table.insert(rewards, {
                type = "item",
                name = "Guild Badge",
                description = "Grants access to special guild quests",
                itemId = "item_guild_badge"
            })
            
            table.insert(rewards, {
                type = "discount",
                name = "Greater Equipment Discount",
                description = "15% discount on all equipment purchases",
                value = 0.15
            })
        end
        
        if level >= self.levels.REVERED then
            table.insert(rewards, {
                type = "item",
                name = "Guild Armor",
                description = "Special armor with guild insignia",
                itemId = "item_guild_armor"
            })
            
            table.insert(rewards, {
                type = "discount",
                name = "Superior Equipment Discount",
                description = "20% discount on all equipment purchases",
                value = 0.2
            })
        end
        
        if level >= self.levels.EXALTED then
            table.insert(rewards, {
                type = "item",
                name = "Guild Master's Seal",
                description = "Valuable item that marks you as an honorary guild master",
                itemId = "item_guild_seal"
            })
            
            table.insert(rewards, {
                type = "discount",
                name = "Master Equipment Discount",
                description = "25% discount on all equipment purchases",
                value = 0.25
            })
        end
    end
    
    -- Tavern rewards
    if faction == self.factions.TAVERN then
        if level >= self.levels.FRIENDLY then
            table.insert(rewards, {
                type = "discount",
                name = "Drink Discount",
                description = "10% discount on all tavern drinks",
                value = 0.1
            })
        end
        
        if level >= self.levels.HONORED then
            table.insert(rewards, {
                type = "item",
                name = "Tavern Mug",
                description = "Special mug that gives bonus from tavern drinks",
                itemId = "item_tavern_mug"
            })
            
            table.insert(rewards, {
                type = "discount",
                name = "Greater Drink Discount",
                description = "15% discount on all tavern drinks",
                value = 0.15
            })
        end
        
        if level >= self.levels.REVERED then
            table.insert(rewards, {
                type = "item",
                name = "Smuggler's Map",
                description = "Shows special merchant locations",
                itemId = "item_smuggler_map"
            })
            
            table.insert(rewards, {
                type = "discount",
                name = "Room Discount",
                description = "20% discount on inn rooms",
                value = 0.2
            })
        end
        
        if level >= self.levels.EXALTED then
            table.insert(rewards, {
                type = "item",
                name = "Barkeep's Key",
                description = "Grants access to special tavern storage",
                itemId = "item_tavern_key"
            })
            
            table.insert(rewards, {
                type = "discount",
                name = "Master Tavern Discount",
                description = "25% discount on all tavern services",
                value = 0.25
            })
        end
    end
    
    return rewards
end

-- Get faction-specific shop items based on reputation level
function reputationSystem:getSpecialShopItems(faction)
    local level = self:getReputationLevel(faction)
    local items = {}
    
    -- Guild special items
    if faction == self.factions.GUILD then
        if level >= self.levels.FRIENDLY then
            table.insert(items, {
                id = "guild_healing_potion",
                name = "Guild Healing Potion",
                description = "A superior healing potion",
                type = "consumable",
                price = 150,
                effect = {type = "heal", amount = 50}
            })
        end
        
        if level >= self.levels.HONORED then
            table.insert(items, {
                id = "guild_shield",
                name = "Guild Shield",
                description = "A sturdy shield with the guild emblem",
                type = "armor",
                slot = "offhand",
                price = 300,
                stats = {DEF = 15}
            })
        end
        
        if level >= self.levels.REVERED then
            table.insert(items, {
                id = "guild_sword",
                name = "Guild Sword",
                description = "A finely crafted sword with the guild emblem",
                type = "weapon",
                slot = "weapon",
                price = 500,
                stats = {ATK = 25}
            })
        end
        
        if level >= self.levels.EXALTED then
            table.insert(items, {
                id = "guild_armor_set",
                name = "Complete Guild Armor Set",
                description = "A full set of armor with the guild insignia",
                type = "armor",
                slot = "body",
                price = 1000,
                stats = {DEF = 30}
            })
        end
    end
    
    -- Tavern special items
    if faction == self.factions.TAVERN then
        if level >= self.levels.FRIENDLY then
            table.insert(items, {
                id = "tavern_special_ale",
                name = "Special Ale",
                description = "A special brew that temporarily increases STR",
                type = "consumable",
                price = 100,
                effect = {type = "buff", stat = "STR", amount = 2, duration = 300}
            })
        end
        
        if level >= self.levels.HONORED then
            table.insert(items, {
                id = "tavern_smuggled_dagger",
                name = "Smuggled Dagger",
                description = "A unique dagger with a hidden poison compartment",
                type = "weapon",
                slot = "weapon",
                price = 350,
                stats = {ATK = 12, DEX = 5}
            })
        end
        
        if level >= self.levels.REVERED then
            table.insert(items, {
                id = "tavern_invisibility_cloak",
                name = "Smuggler's Cloak",
                description = "A cloak that provides temporary invisibility",
                type = "armor",
                slot = "body",
                price = 600,
                stats = {DEF = 8, DEX = 10}
            })
        end
        
        if level >= self.levels.EXALTED then
            table.insert(items, {
                id = "tavern_master_rogue_kit",
                name = "Master Rogue's Kit",
                description = "A collection of specialized tools for a master thief",
                type = "accessory",
                slot = "amulet",
                price = 800,
                stats = {DEX = 15, CHA = 10}
            })
        end
    end
    
    return items
end

return reputationSystem 