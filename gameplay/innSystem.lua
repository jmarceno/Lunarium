-- Inn System
-- Handles player rest, recovery, and special inn services
local reputationSystem = require("gameplay/reputationSystem")

local innSystem = {
    roomTypes = {
        {
            id = "basic",
            name = "Basic Room",
            description = "A simple room with a bed and basic amenities.",
            cost = 10,
            hpRecovery = 0.5, -- 50% HP recovery
            mpRecovery = 0.3, -- 30% MP recovery
            statusEffectRemoval = false,
            tempBuffs = {}
        },
        {
            id = "standard",
            name = "Standard Room",
            description = "A comfortable room with a proper bed and desk.",
            cost = 25,
            hpRecovery = 0.75, -- 75% HP recovery
            mpRecovery = 0.5, -- 50% MP recovery
            statusEffectRemoval = true,
            tempBuffs = {
                { stat = "CON", amount = 1, duration = 600 } -- 10 minutes game time
            }
        },
        {
            id = "luxury",
            name = "Luxury Suite",
            description = "A spacious suite with high-quality furnishings and services.",
            cost = 50,
            hpRecovery = 1.0, -- 100% HP recovery
            mpRecovery = 1.0, -- 100% MP recovery
            statusEffectRemoval = true,
            tempBuffs = {
                { stat = "CON", amount = 2, duration = 1200 }, -- 20 minutes game time
                { stat = "WIL", amount = 1, duration = 1200 }  -- 20 minutes game time
            }
        },
        {
            id = "royal",
            name = "Royal Chamber",
            description = "The finest accommodations, reserved for distinguished guests.",
            cost = 100,
            hpRecovery = 1.0, -- 100% HP recovery + bonus
            mpRecovery = 1.0, -- 100% MP recovery + bonus
            hpBonus = 10,     -- Bonus HP recovery
            mpBonus = 10,     -- Bonus MP recovery
            statusEffectRemoval = true,
            tempBuffs = {
                { stat = "CON", amount = 3, duration = 1800 }, -- 30 minutes game time
                { stat = "WIL", amount = 2, duration = 1800 }, -- 30 minutes game time
                { stat = "STR", amount = 1, duration = 1800 }  -- 30 minutes game time
            }
        }
    },
    
    foodItems = {
        {
            id = "simple_meal",
            name = "Simple Meal",
            description = "A basic but filling meal.",
            cost = 5,
            effects = {
                { type = "heal", amount = 10 },
                { type = "buff", stat = "CON", amount = 1, duration = 300 } -- 5 minutes
            }
        },
        {
            id = "hearty_stew",
            name = "Hearty Stew",
            description = "A thick, nutritious stew that warms the body.",
            cost = 15,
            effects = {
                { type = "heal", amount = 25 },
                { type = "buff", stat = "CON", amount = 2, duration = 600 } -- 10 minutes
            }
        },
        {
            id = "feast",
            name = "Adventurer's Feast",
            description = "A large, varied meal fit for heroes.",
            cost = 30,
            effects = {
                { type = "heal", amount = 40 },
                { type = "buff", stat = "CON", amount = 3, duration = 900 }, -- 15 minutes
                { type = "buff", stat = "STR", amount = 1, duration = 900 }  -- 15 minutes
            }
        }
    },
    
    drinkItems = {
        {
            id = "ale",
            name = "Mug of Ale",
            description = "A refreshing local brew.",
            cost = 3,
            effects = {
                { type = "restore_mp", amount = 5 },
                { type = "buff", stat = "CHA", amount = 1, duration = 300 } -- 5 minutes
            }
        },
        {
            id = "wine",
            name = "Glass of Fine Wine",
            description = "An elegant wine with subtle flavors.",
            cost = 10,
            effects = {
                { type = "restore_mp", amount = 15 },
                { type = "buff", stat = "CHA", amount = 2, duration = 600 } -- 10 minutes
            }
        },
        {
            id = "spirit",
            name = "Rare Spirit",
            description = "A potent spirit with magical properties.",
            cost = 25,
            effects = {
                { type = "restore_mp", amount = 30 },
                { type = "buff", stat = "CHA", amount = 3, duration = 900 }, -- 15 minutes
                { type = "buff", stat = "INT", amount = 1, duration = 900 }  -- 15 minutes
            }
        }
    },
    
    specialEvents = {
        {
            id = "city_invasion",
            name = "City Invasion",
            description = "The city is under attack by monsters! Help defend the inn or flee.",
            choices = {
                {
                    text = "Help defend the inn",
                    outcome = "combat",
                    reputationChange = 20
                },
                {
                    text = "Stay inside and barricade",
                    outcome = "safe",
                    reputationChange = 0
                },
                {
                    text = "Flee the city",
                    outcome = "flee",
                    reputationChange = -10
                }
            },
            chance = 0.05 -- 5% chance of occurring during rest
        },
        {
            id = "mysterious_stranger",
            name = "Mysterious Stranger",
            description = "A hooded figure approaches you in the inn with information to sell.",
            choices = {
                {
                    text = "Buy information (20 gold)",
                    outcome = "info",
                    cost = 20,
                    reputationChange = 0
                },
                {
                    text = "Decline politely",
                    outcome = "decline",
                    reputationChange = 0
                },
                {
                    text = "Threaten the stranger",
                    outcome = "threaten",
                    reputationChange = -5
                }
            },
            chance = 0.1 -- 10% chance of occurring during rest
        },
        {
            id = "drinking_contest",
            name = "Drinking Contest",
            description = "The inn is hosting a drinking contest with a prize for the winner.",
            choices = {
                {
                    text = "Join the contest (10 gold entry)",
                    outcome = "join",
                    cost = 10,
                    reputationChange = 5
                },
                {
                    text = "Watch the contest",
                    outcome = "watch",
                    reputationChange = 0
                },
                {
                    text = "Go to your room",
                    outcome = "ignore",
                    reputationChange = 0
                }
            },
            chance = 0.15 -- 15% chance of occurring during rest
        }
    }
}

-- Initialize inn system
function innSystem:init()
    -- Nothing to initialize yet
end

-- Get available room types
function innSystem:getAvailableRoomTypes()
    -- Apply reputation-based discounts
    local discountedRooms = {}
    local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
    local discount = 0
    
    -- Calculate discount based on reputation level
    if tavernRepLevel >= reputationSystem.levels.FRIENDLY then
        discount = 0.1 -- 10% discount
    end
    if tavernRepLevel >= reputationSystem.levels.HONORED then
        discount = 0.15 -- 15% discount
    end
    if tavernRepLevel >= reputationSystem.levels.REVERED then
        discount = 0.2 -- 20% discount
    end
    if tavernRepLevel >= reputationSystem.levels.EXALTED then
        discount = 0.25 -- 25% discount
    end
    
    -- Apply discounts to room costs
    for i, room in ipairs(self.roomTypes) do
        local discountedRoom = {}
        for k, v in pairs(room) do
            discountedRoom[k] = v
        end
        
        -- Apply discount to cost
        if discount > 0 then
            discountedRoom.cost = math.floor(discountedRoom.cost * (1 - discount))
            discountedRoom.discounted = true
        end
        
        table.insert(discountedRooms, discountedRoom)
    end
    
    -- Unlock royal chamber only for high reputation
    if tavernRepLevel < reputationSystem.levels.HONORED then
        table.remove(discountedRooms) -- Remove royal chamber (last item)
    end
    
    return discountedRooms
end

-- Rest at the inn with selected room type
function innSystem:rest(character, roomTypeId)
    -- Find selected room type
    local roomType = nil
    local availableRooms = self:getAvailableRoomTypes()
    
    for _, room in ipairs(availableRooms) do
        if room.id == roomTypeId then
            roomType = room
            break
        end
    end
    
    if not roomType then
        return false, "Room type not available"
    end
    
    -- Check if player has enough gold
    if GAME.gold < roomType.cost then
        return false, "Not enough gold"
    end
    
    -- Deduct cost
    GAME.gold = GAME.gold - roomType.cost
    
    -- Apply recovery
    if roomType.hpRecovery > 0 then
        local recoveryAmount = math.floor(character.maxHP * roomType.hpRecovery)
        if roomType.hpBonus then
            recoveryAmount = recoveryAmount + roomType.hpBonus
        end
        character.currentHP = math.min(character.maxHP, character.currentHP + recoveryAmount)
    end
    
    if roomType.mpRecovery > 0 then
        local recoveryAmount = math.floor(character.maxMP * roomType.mpRecovery)
        if roomType.mpBonus then
            recoveryAmount = recoveryAmount + roomType.mpBonus
        end
        character.currentMP = math.min(character.maxMP, character.currentMP + recoveryAmount)
    end
    
    -- Remove status effects if room provides it
    if roomType.statusEffectRemoval and character.statusEffects then
        character.statusEffects = {}
    end
    
    -- Apply temporary buffs
    if roomType.tempBuffs and #roomType.tempBuffs > 0 then
        if not character.temporaryBuffs then
            character.temporaryBuffs = {}
        end
        
        for _, buff in ipairs(roomType.tempBuffs) do
            table.insert(character.temporaryBuffs, {
                stat = buff.stat,
                amount = buff.amount,
                duration = buff.duration,
                startTime = GAME.gameTime or 0
            })
        end
    end
    
    -- Roll for special event
    local eventOccurred = self:checkForSpecialEvent()
    
    -- Add time passage (8 hours)
    if GAME.gameTime then
        GAME.gameTime = GAME.gameTime + 8 * 60 -- 8 hours in minutes
    end
    
    return true, "You rested well at the inn.", eventOccurred
end

-- Check for special events during rest
function innSystem:checkForSpecialEvent()
    -- Roll chance for each possible event
    for _, event in ipairs(self.specialEvents) do
        if math.random() < event.chance then
            return event
        end
    end
    
    return nil -- No event occurred
end

-- Handle event outcome
function innSystem:handleEventOutcome(eventId, choiceIndex, character)
    -- Find the event
    local event = nil
    for _, e in ipairs(self.specialEvents) do
        if e.id == eventId then
            event = e
            break
        end
    end
    
    if not event then
        return false, "Event not found"
    end
    
    -- Get selected choice
    local choice = event.choices[choiceIndex]
    if not choice then
        return false, "Invalid choice"
    end
    
    -- Handle cost
    if choice.cost and choice.cost > 0 then
        if GAME.gold < choice.cost then
            return false, "Not enough gold"
        end
        
        GAME.gold = GAME.gold - choice.cost
    end
    
    -- Apply reputation change
    if choice.reputationChange and choice.reputationChange ~= 0 then
        reputationSystem:changeReputation(reputationSystem.factions.TAVERN, choice.reputationChange)
    end
    
    -- Process outcome based on event and choice
    local result = "Your choice had consequences."
    local rewards = {}
    
    if event.id == "city_invasion" then
        if choice.outcome == "combat" then
            -- TODO: Trigger combat encounter
            result = "You bravely fought off the invaders. The innkeeper is grateful."
            rewards = {
                reputation = 20,
                gold = 50,
                items = { { type = "consumable", name = "Health Potion", count = 2 } }
            }
        elseif choice.outcome == "safe" then
            result = "You stayed inside. The danger has passed."
        elseif choice.outcome == "flee" then
            result = "You fled the city. The innkeeper seems disappointed."
        end
    elseif event.id == "mysterious_stranger" then
        if choice.outcome == "info" then
            -- Reveal a random dungeon location or quest hint
            result = "The stranger gives you valuable information about a hidden treasure."
            rewards = {
                quest = { type = "hidden", location = "Ancient Ruins", difficulty = 3 }
            }
        elseif choice.outcome == "decline" then
            result = "The stranger nods and leaves you alone."
        elseif choice.outcome == "threaten" then
            result = "The stranger quickly disappears. Other patrons look at you with disapproval."
        end
    elseif event.id == "drinking_contest" then
        if choice.outcome == "join" then
            -- Test character's CON attribute
            local conCheck = character.attributes.CON or 10
            local roll = math.random(1, 20)
            
            if roll + conCheck > 15 then
                result = "You win the drinking contest! Everyone cheers your name."
                rewards = {
                    reputation = 10,
                    gold = 30,
                    items = { { type = "consumable", name = "Special Brew", count = 1 } }
                }
            else
                result = "You didn't win, but had a good time. Your head hurts a bit."
                character.currentHP = math.max(1, character.currentHP - 5) -- Minor health loss
            end
        elseif choice.outcome == "watch" then
            result = "You enjoyed watching the contest. It was quite entertaining."
        elseif choice.outcome == "ignore" then
            result = "You went to your room, ignoring the noise downstairs."
        end
    end
    
    -- Give rewards
    if rewards.gold and rewards.gold > 0 then
        GAME.gold = GAME.gold + rewards.gold
    end
    
    if rewards.items and #rewards.items > 0 then
        for _, item in ipairs(rewards.items) do
            -- Add to inventory (assuming itemSystem has this function)
            local itemSystem = require("gameplay/item")
            itemSystem:addToInventory(item)
        end
    end
    
    return true, result, rewards
end

-- Purchase food
function innSystem:purchaseFood(foodId, character)
    -- Find the food item
    local foodItem = nil
    for _, food in ipairs(self.foodItems) do
        if food.id == foodId then
            foodItem = food
            break
        end
    end
    
    if not foodItem then
        return false, "Food item not available"
    end
    
    -- Apply tavern reputation discount
    local cost = foodItem.cost
    local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
    
    if tavernRepLevel >= reputationSystem.levels.FRIENDLY then
        cost = math.floor(cost * 0.9) -- 10% discount
    end
    
    -- Check if player has enough gold
    if GAME.gold < cost then
        return false, "Not enough gold"
    end
    
    -- Deduct cost
    GAME.gold = GAME.gold - cost
    
    -- Apply effects
    for _, effect in ipairs(foodItem.effects) do
        if effect.type == "heal" then
            character.currentHP = math.min(character.maxHP, character.currentHP + effect.amount)
        elseif effect.type == "buff" then
            if not character.temporaryBuffs then
                character.temporaryBuffs = {}
            end
            
            table.insert(character.temporaryBuffs, {
                stat = effect.stat,
                amount = effect.amount,
                duration = effect.duration,
                startTime = GAME.gameTime or 0
            })
        end
    end
    
    return true, "You enjoyed the " .. foodItem.name .. "."
end

-- Purchase drink
function innSystem:purchaseDrink(drinkId, character)
    -- Find the drink item
    local drinkItem = nil
    for _, drink in ipairs(self.drinkItems) do
        if drink.id == drinkId then
            drinkItem = drink
            break
        end
    end
    
    if not drinkItem then
        return false, "Drink item not available"
    end
    
    -- Apply tavern reputation discount
    local cost = drinkItem.cost
    local tavernRepLevel = reputationSystem:getReputationLevel(reputationSystem.factions.TAVERN)
    
    if tavernRepLevel >= reputationSystem.levels.FRIENDLY then
        cost = math.floor(cost * 0.9) -- 10% discount
    elseif tavernRepLevel >= reputationSystem.levels.HONORED then
        cost = math.floor(cost * 0.85) -- 15% discount
    end
    
    -- Check if player has enough gold
    if GAME.gold < cost then
        return false, "Not enough gold"
    end
    
    -- Deduct cost
    GAME.gold = GAME.gold - cost
    
    -- Apply effects
    for _, effect in ipairs(drinkItem.effects) do
        if effect.type == "restore_mp" then
            character.currentMP = math.min(character.maxMP, character.currentMP + effect.amount)
        elseif effect.type == "buff" then
            if not character.temporaryBuffs then
                character.temporaryBuffs = {}
            end
            
            table.insert(character.temporaryBuffs, {
                stat = effect.stat,
                amount = effect.amount,
                duration = effect.duration,
                startTime = GAME.gameTime or 0
            })
        end
    end
    
    -- Apply special bonus for tavern mug item if character has it
    local hasTavernMug = false
    if character.inventory then
        for _, item in ipairs(character.inventory) do
            if item.id == "item_tavern_mug" then
                hasTavernMug = true
                break
            end
        end
    end
    
    if hasTavernMug then
        -- Add 50% bonus to all effects
        for _, effect in ipairs(drinkItem.effects) do
            if effect.type == "restore_mp" then
                local bonus = math.floor(effect.amount * 0.5)
                character.currentMP = math.min(character.maxMP, character.currentMP + bonus)
            elseif effect.type == "buff" and effect.amount > 0 then
                -- Find the buff we just added and increase its duration
                for i, buff in ipairs(character.temporaryBuffs) do
                    if buff.stat == effect.stat and buff.startTime == (GAME.gameTime or 0) then
                        -- Increase duration by 50%
                        buff.duration = math.floor(buff.duration * 1.5)
                        break
                    end
                end
            end
        end
        
        return true, "You enjoyed the " .. drinkItem.name .. " from your special tavern mug. The effects were enhanced!"
    end
    
    return true, "You enjoyed the " .. drinkItem.name .. "."
end

return innSystem 