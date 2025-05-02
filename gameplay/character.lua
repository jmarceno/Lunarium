-- Character System
-- Handles character creation, leveling, and stats
local jobSystem = require("gameplay/job")
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")

local character = {}

-- Attribute definitions
character.attributes = {
    "STR", -- Strength - affects physical damage and hit chance
    "INT", -- Intelligence - affects magic power and mana
    "CON", -- Constitution - affects health points
    "WIL", -- Will - affects magic resistance and mana
    "CHA", -- Charisma - affects NPC interactions and certain skills
    "DEX", -- Dexterity - affects ranged attacks and dodge chance
    "WIS"  -- Wisdom - affects skill effectiveness and mana
}

-- Base attribute cap
character.BASE_ATTRIBUTE_CAP = 50
character.LEVEL_CAP = 100

-- Create a new character
function character:new(name, jobName, attributes, profileIndex, portraitId)
    -- Validate name
    if not name or name == "" then
        name = "Character_" .. os.time()
    end
    
    -- Get job definition
    local job = jobSystem:getJob(jobName)
    if not job then
        job = jobSystem:getJob("Fighter") -- Default job
    end
    
    -- Create attributes table
    local attrs = {}
    for _, attr in ipairs(self.attributes) do
        attrs[attr] = 5 -- Default base value
    end
    
    -- Apply provided attribute values if valid
    if attributes then
        for attr, value in pairs(attributes) do
            if value <= self.BASE_ATTRIBUTE_CAP then
                attrs[attr] = value
            end
        end
    end
    
    -- Apply job attribute modifiers
    if job.attributeModifiers then
        for attr, mod in pairs(job.attributeModifiers) do
            attrs[attr] = attrs[attr] + mod
        end
    end
    
    -- Calculate derived stats
    local maxHP = self:calculateHP(attrs.CON, 1)
    local maxMP = self:calculateMP(attrs.INT, attrs.WIL, attrs.WIS, 1)
    
    -- Handle portrait selection
    local finalPortraitId = portraitId
    
    -- If no portrait ID provided, use profile index for backwards compatibility
    if not finalPortraitId and profileIndex then
        -- Use numeric profile index (legacy)
        finalPortraitId = "profile" .. profileIndex
    end
    
    -- If still no portrait, select a random one based on job
    if not finalPortraitId then
        -- Select a random portrait based on job type
        finalPortraitId = self:selectRandomPortrait(job.name)
    end
    
    -- Create character table
    local char = {
        name = name,
        job = job.name,
        jobHistory = {job.name},
        level = 1,
        experience = 0,
        experienceToNext = 100,
        attributes = attrs,
        maxHP = maxHP,
        currentHP = maxHP,
        maxMP = maxMP,
        currentMP = maxMP,
        skillPoints = 0,
        skills = {},
        equipment = {
            weapon = nil,
            offhand = nil,
            head = nil,
            body = nil,
            accessory1 = nil,
            accessory2 = nil
        },
        inventory = {},
        portraitId = finalPortraitId,
        -- Keep profileIndex for backwards compatibility
        profileIndex = profileIndex or math.random(1, 8)
    }
    
    -- Add starting skills from job
    for _, skillName in ipairs(job.startingSkills) do
        local skill = skillSystem:getSkill(skillName)
        if skill then
            char.skills[skillName] = {
                level = 1,
                uses = 0
            }
        end
    end
    
    -- Add starting equipment from job
    for slot, itemName in pairs(job.startingEquipment) do
        local item = itemSystem:getItem(itemName)
        if item then
            char.equipment[slot] = item
        end
    end
    
    return char
end

-- Select a random portrait based on job type
function character:selectRandomPortrait(jobName)
    -- Define portrait categories based on race/class
    local portraits = {
        -- Default to these if job not found
        default = {"elf10", "dwarf10", "halfling10"}
    }
    
    -- Map races to portrait categories
    local raceMap = {
        ["Fighter"] = {"dwarf", "halfling"},
        ["Ranger"] = {"elf"},
        ["Mage"] = {"elf"},
        ["Cleric"] = {"dwarf", "halfling"},
        ["Rogue"] = {"halfling"},
        ["Paladin"] = {"dwarf"},
        ["Healer"] = {"elf", "halfling"},
        ["Warrior"] = {"dwarf", "halfling"},
        ["Necromancer"] = {"construct"},
        ["Berserker"] = {"dwarf"}
    }
    
    -- Select a race based on job
    local races = raceMap[jobName] or {"elf", "dwarf", "halfling"}
    local race = races[math.random(1, #races)]
    
    -- Select a number range based on race
    local numRange = {
        elf = {1, 30},
        dwarf = {1, 31},
        halfling = {1, 31},
        construct = {1, 7}
    }
    
    local range = numRange[race] or {1, 10}
    local num = math.random(range[1], range[2])
    
    -- Return the portrait ID
    return race .. num
end

-- Calculate maximum HP based on constitution and level
function character:calculateHP(constitution, level)
    return math.floor(constitution * 5 + level * 2)
end

-- Calculate maximum MP based on intelligence, will, wisdom and level
function character:calculateMP(intelligence, will, wisdom, level)
    return math.floor(((intelligence + will + wisdom) / 3) * 2 + level)
end

-- Calculate hit chance with melee attacks
function character:calculateMeleeHitChance(strength, dexterity)
    return 70 + (strength * 0.5) + (dexterity * 0.2)
end

-- Calculate hit chance with ranged attacks
function character:calculateRangedHitChance(dexterity, strength)
    return 70 + (dexterity * 0.5) + (strength * 0.2)
end

-- Calculate experience required for next level
function character:calculateExperienceForLevel(level)
    return math.floor(100 * level * (1 + level * 0.1))
end

-- Level up a character
function character:levelUp(char)
    if char.level >= self.LEVEL_CAP then
        return false
    end
    
    -- Increase level
    char.level = char.level + 1
    
    -- Grant skill points
    char.skillPoints = char.skillPoints + 1
    
    -- Adjust experience (Ensure experience doesn't become negative)
    if char.experience >= char.experienceToNext then
        char.experience = char.experience - char.experienceToNext
    else
        -- This case shouldn't normally happen if check is done before calling,
        -- but as a safeguard:
        char.experience = 0 
    end
    
    -- Calculate next level experience threshold
    if char.level < self.LEVEL_CAP then
        char.experienceToNext = self:calculateExperienceForLevel(char.level)
    else
        -- Already at cap after level up
        char.experience = 0
        char.experienceToNext = 0
    end
    
    -- Note: Stat recalculation and healing are handled separately after attribute increases.
    return true
end

-- Add experience to a character
function character:addExperience(char, amount)
    -- Print debug info
    print("Adding " .. amount .. " experience to " .. char.name)
    print("  Current XP: " .. char.experience .. "/" .. char.experienceToNext .. " (Level " .. char.level .. ")")

    char.experience = char.experience + amount
    
    -- Check if character has enough XP to level up
    if char.experience >= char.experienceToNext and char.level < self.LEVEL_CAP then
        print("  " .. char.name .. " has gained enough XP to level up! (" .. char.experience .. " >= " .. char.experienceToNext .. ")")
        
        -- Only set the level-up flag if it's not already set
        -- This prevents multiple level-up screens for the same level
        if not char.needsLevelUpScreen then
            print("  Setting needsLevelUpScreen flag for " .. char.name)
            char.needsLevelUpScreen = true
        else
            print("  Level-up flag already set for " .. char.name)
        end
        -- Don't subtract XP or increase level here - that will be done in the level-up screen
    end
    
    -- Cap experience if at max level
    if char.level >= self.LEVEL_CAP then
        char.experience = 0
        char.experienceToNext = 0
    end
    
    print("  Final XP: " .. char.experience .. "/" .. char.experienceToNext)
end

-- Change a character's job
function character:changeJob(char, newJobName)
    local newJob = jobSystem:getJob(newJobName)
    if not newJob then
        return false
    end
    
    -- Check if job change is allowed
    local currentJob = jobSystem:getJob(char.job)
    if not currentJob or not self:canChangeJob(char, currentJob, newJob) then
        return false
    end
    
    -- Add job to history
    table.insert(char.jobHistory, newJob.name)
    
    -- Change current job
    char.job = newJob.name
    
    -- Add new job skills
    for _, skillName in ipairs(newJob.startingSkills) do
        if not char.skills[skillName] then
            local skill = skillSystem:getSkill(skillName)
            if skill then
                char.skills[skillName] = {
                    level = 1,
                    uses = 0
                }
            end
        end
    end
    
    return true
end

-- Check if a character can change to a new job
function character:canChangeJob(char, currentJob, newJob)
    -- Check if current job level meets requirements
    if newJob.requirements then
        for reqJob, reqLevel in pairs(newJob.requirements) do
            local hasJob = false
            local jobLevel = 0
            
            -- Check job history
            for _, job in ipairs(char.jobHistory) do
                if job == reqJob then
                    hasJob = true
                    -- TODO: Track job levels separately
                    jobLevel = char.level
                    break
                end
            end
            
            if not hasJob or jobLevel < reqLevel then
                return false
            end
        end
    end
    
    return true
end

-- Learn a new skill or upgrade existing skill
function character:learnSkill(char, skillName)
    if char.skillPoints <= 0 then
        return false
    end
    
    local skill = skillSystem:getSkill(skillName)
    if not skill then
        return false
    end
    
    -- Check if character already has this skill
    if char.skills[skillName] then
        -- Upgrade skill level
        if char.skills[skillName].level < skill.maxLevel then
            char.skills[skillName].level = char.skills[skillName].level + 1
            char.skillPoints = char.skillPoints - 1
            return true
        end
    else
        -- Check if skill is available for character's job
        local currentJob = jobSystem:getJob(char.job)
        local skillAvailable = false
        
        if currentJob and currentJob.availableSkills then
            for _, jobSkill in ipairs(currentJob.availableSkills) do
                if jobSkill == skillName then
                    skillAvailable = true
                    break
                end
            end
        end
        
        if skillAvailable then
            -- Learn new skill
            char.skills[skillName] = {
                level = 1,
                uses = 0
            }
            char.skillPoints = char.skillPoints - 1
            return true
        end
    end
    
    return false
end

-- Equip an item
function character:equipItem(char, item)
    if not item or not item.type or not item.slot then
        return false
    end
    
    -- Check if character meets requirements
    if item.requirements then
        for attr, req in pairs(item.requirements) do
            if not char.attributes[attr] or char.attributes[attr] < req then
                return false
            end
        end
    end
    
    -- Check if item is equippable by character's job
    if item.jobs and #item.jobs > 0 then
        local canEquip = false
        for _, job in ipairs(item.jobs) do
            if job == char.job then
                canEquip = true
                break
            end
        end
        
        if not canEquip then
            return false
        end
    end
    
    -- Store previous item
    local previousItem = char.equipment[item.slot]
    
    -- Equip new item
    char.equipment[item.slot] = item
    
    -- Return previous item
    return previousItem
end

-- Unequip an item
function character:unequipItem(char, slot)
    if not char.equipment[slot] then
        return nil
    end
    
    local item = char.equipment[slot]
    char.equipment[slot] = nil
    
    return item
end

-- Calculate attack power
function character:calculateAttackPower(char)
    local basePower = char.attributes.STR

    -- Add weapon power
    if char.equipment.weapon and char.equipment.weapon.attack then
        basePower = basePower + char.equipment.weapon.attack
    end
    
    return basePower
end

-- Calculate magic power
function character:calculateMagicPower(char)
    local basePower = char.attributes.INT

    -- Add weapon/item magic power
    if char.equipment.weapon and char.equipment.weapon.magicAttack then
        basePower = basePower + char.equipment.weapon.magicAttack
    end
    
    return basePower
end

-- Calculate defense
function character:calculateDefense(char)
    local baseDefense = math.floor(char.attributes.CON / 2)
    
    -- Add armor defense
    for slot, item in pairs(char.equipment) do
        if item and item.defense then
            baseDefense = baseDefense + item.defense
        end
    end
    
    return baseDefense
end

-- Calculate magic defense
function character:calculateMagicDefense(char)
    local baseMDefense = math.floor((char.attributes.WIL + char.attributes.WIS) / 4)
    
    -- Add armor magic defense
    for slot, item in pairs(char.equipment) do
        if item and item.magicDefense then
            baseMDefense = baseMDefense + item.magicDefense
        end
    end
    
    return baseMDefense
end

-- Apply attribute gains, recalculate stats, and heal after level up or job change
function character:applyLevelUpChanges(char, chosenJobName)
    local job = jobSystem:getJob(chosenJobName)
    if not job then
        print("Error applying level up changes: Job '" .. chosenJobName .. "' not found.")
        return
    end

    -- Apply attribute modifiers from the chosen job for this level
    if job.attributeModifiers then
        --print("Applying attribute modifiers for " .. chosenJobName .. " to " .. char.name)
        for attr, mod in pairs(job.attributeModifiers) do
            local currentVal = char.attributes[attr] or 0
            char.attributes[attr] = math.min(self.BASE_ATTRIBUTE_CAP, currentVal + mod)
             print("  " .. attr .. ": " .. currentVal .. " + " .. mod .. " -> " .. char.attributes[attr])
        end
    end

    -- Recalculate stats based on new level and potentially new attributes
    char.maxHP = self:calculateHP(char.attributes.CON, char.level)
    char.maxMP = self:calculateMP(char.attributes.INT, char.attributes.WIL, char.attributes.WIS, char.level)

    -- Heal character to full after level up
    char.currentHP = char.maxHP
    char.currentMP = char.maxMP

    print(char.name .. " level up applied. New HP: " .. char.maxHP .. ", New MP: " .. char.maxMP)
end

-- Create a character party
function character:createParty(characters)
    local party = {
        members = characters or {},
        maxSize = 4
    }
    
    return party
end

-- Add character to party
function character:addToParty(party, char)
    if #party.members >= party.maxSize then
        return false
    end
    
    table.insert(party.members, char)
    return true
end

-- Remove character from party
function character:removeFromParty(party, index)
    if index < 1 or index > #party.members then
        return nil
    end
    
    local char = party.members[index]
    table.remove(party.members, index)
    
    return char
end

return character
