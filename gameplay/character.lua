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
-- Level caps
character.JOB_LEVEL_CAP = 50 -- Maximum level for a single job
character.TOTAL_LEVEL_CAP = 100 -- Maximum sum of all job levels

-- Helper function to calculate total level
function character:_calculateTotalLevel(char)
    local total = 0
    if char.jobLevels then
        for _, jobLevel in pairs(char.jobLevels) do
            total = total + jobLevel
        end
    end
    return total
end

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
    
    -- Initialize job levels
    local jobLevels = {}
    jobLevels[job.name] = 1 -- Start the chosen job at level 1
    
    -- Calculate initial derived stats using calculated total level
    local totalLevel = 1 -- Initial total level (should equal 1 since only one job at level 1)
    local maxHP = self:calculateHP(attrs.CON, totalLevel)
    local maxMP = self:calculateMP(attrs.INT, attrs.WIL, attrs.WIS, totalLevel)
    
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
    
    -- Calculate initial experience needed (based on job level 1)
    local experienceToNext = self:calculateExperienceForLevel(1) 

    -- Create character table with new structure - NOTE: don't directly store level
    local char = {
        name = name,
        job = job.name, -- Current active job
        jobLevels = jobLevels, -- Table storing levels for each job
        experience = 0,
        experienceToNext = experienceToNext,
        attributes = attrs,
        maxHP = maxHP,
        currentHP = maxHP,
        maxMP = maxMP,
        currentMP = maxMP,
        skillPoints = 0, -- Still grant based on total level for now
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
        local item = itemSystem:cloneItemWithId(itemName)
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
function character:calculateHP(constitution, totalLevel)
    return math.floor(constitution * 5 + totalLevel * 2)
end

-- Calculate maximum MP based on intelligence, will, wisdom and level
function character:calculateMP(intelligence, will, wisdom, totalLevel)
    return math.floor(((intelligence + will + wisdom) / 3) * 2 + totalLevel)
end

-- Calculate hit chance with melee attacks
function character:calculateMeleeHitChance(strength, dexterity)
    return 70 + (strength * 0.5) + (dexterity * 0.2)
end

-- Calculate hit chance with ranged attacks
function character:calculateRangedHitChance(dexterity, strength)
    return 70 + (dexterity * 0.5) + (strength * 0.2)
end

-- Calculate experience required for the next level of a specific JOB
function character:calculateExperienceForLevel(jobLevel)
    -- Base experience on the job level, not total level
    return math.floor(100 * jobLevel * (1 + jobLevel * 0.1))
end

-- Level up a character (job level up)
function character:levelUp(char)
    local currentJobName = char.job
    local currentJobLevel = char.jobLevels[currentJobName] or 0
    local totalLevel = self:_calculateTotalLevel(char)
    
    -- Check caps: current job level and total level
    if currentJobLevel >= self.JOB_LEVEL_CAP or totalLevel >= self.TOTAL_LEVEL_CAP then
        print(char.name .. " cannot level up further (Job Level: " .. currentJobLevel .. "/" .. self.JOB_LEVEL_CAP .. ", Total Level: " .. totalLevel .. "/" .. self.TOTAL_LEVEL_CAP .. ")")
        -- Reset XP needed if capped
        char.experienceToNext = 0 
        char.experience = 0
        return false
    end
    
    -- Increase current job level
    char.jobLevels[currentJobName] = currentJobLevel + 1
    
    -- Grant skill points (based on total level increase - might reconsider later)
    char.skillPoints = char.skillPoints + 1
    
    -- Adjust experience (as before)
    if char.experience >= char.experienceToNext then
        char.experience = char.experience - char.experienceToNext
    else
        char.experience = 0 
    end
    
    -- Calculate next level experience threshold (based on NEW job level)
    local nextJobLevel = char.jobLevels[currentJobName]
    local newTotalLevel = self:_calculateTotalLevel(char)
    
    if nextJobLevel < self.JOB_LEVEL_CAP and newTotalLevel < self.TOTAL_LEVEL_CAP then
        char.experienceToNext = self:calculateExperienceForLevel(nextJobLevel)
    else
        -- Reached cap after this level up
        char.experience = 0
        char.experienceToNext = 0
    end

    print(char.name .. " leveled up job " .. currentJobName .. " to level " .. nextJobLevel .. "! Total Level: " .. newTotalLevel)
    
    -- Stat recalculation/healing are handled separately by applyLevelUpChanges
    return true
end

-- Add experience to a character
function character:addExperience(char, amount)
    local currentJobName = char.job
    local currentJobLevel = char.jobLevels[currentJobName] or 0
    local totalLevel = self:_calculateTotalLevel(char)

    -- Don't add experience if job or total level is capped
    if currentJobLevel >= self.JOB_LEVEL_CAP or totalLevel >= self.TOTAL_LEVEL_CAP then
        print(char.name .. " cannot gain experience (level capped).")
        return
    end

    print("Adding " .. amount .. " experience to " .. char.name)
    print("  Current XP: " .. char.experience .. "/" .. char.experienceToNext .. " (Job: " .. currentJobName .. " Lv." .. currentJobLevel .. ", Total Lv." .. totalLevel .. ")")

    char.experience = char.experience + amount
    
    -- Check if character has enough XP to level up (based on current job's next threshold)
    -- Ensure experienceToNext is not zero before checking
    if char.experienceToNext > 0 and char.experience >= char.experienceToNext then
        print("  " .. char.name .. " has gained enough XP to level up job " .. currentJobName .. "! (" .. char.experience .. " >= " .. char.experienceToNext .. ")")
        
        -- Set level-up flag (as before)
        if not char.needsLevelUpScreen then
            print("  Setting needsLevelUpScreen flag for " .. char.name)
            char.needsLevelUpScreen = true
        else
            print("  Level-up flag already set for " .. char.name)
        end
        -- Leveling up happens via the level-up screen process
    end
    
    print("  Final XP: " .. char.experience .. "/" .. char.experienceToNext)
end

-- Change a character's job
function character:changeJob(char, newJobName)
    local newJob = jobSystem:getJob(newJobName)
    if not newJob then return false end
    
    local currentJob = jobSystem:getJob(char.job)
    if not currentJob or not self:canChangeJob(char, currentJob, newJob) then return false end
    
    -- Set new job as current
    char.job = newJob.name
    print(char.name .. " changed job to " .. newJob.name)

    -- Add to jobLevels if it's a new job for this character
    if not char.jobLevels[newJob.name] then
        print("  Learned new job: " .. newJob.name)
        char.jobLevels[newJob.name] = 1
        
        -- Add new job starting skills ONLY if it's a brand new job
        for _, skillName in ipairs(newJob.startingSkills) do
            if not char.skills[skillName] then
                local skill = skillSystem:getSkill(skillName)
                if skill then
                    char.skills[skillName] = { level = 1, uses = 0 }
                    print("    Learned starting skill: " .. skillName)
                end
            end
        end
    else
        print("  Switched back to job: " .. newJob.name .. " (Level " .. char.jobLevels[newJob.name] .. ")")
    end

    -- Recalculate XP needed for the *new current* job's level
    local newCurrentJobLevel = char.jobLevels[char.job]
    local totalLevel = self:_calculateTotalLevel(char)
    
    if newCurrentJobLevel < self.JOB_LEVEL_CAP and totalLevel < self.TOTAL_LEVEL_CAP then
        char.experienceToNext = self:calculateExperienceForLevel(newCurrentJobLevel)
    else
        char.experienceToNext = 0 -- Capped
    end
    char.experience = 0 -- Reset progress towards next level on job change
    
    return true
end

-- Check if a character can change to a new job based on job level requirements
function character:canChangeJob(char, currentJob, newJob)
    if newJob.requirements then
        for reqJob, reqLevel in pairs(newJob.requirements) do
            -- Check if the required job exists in jobLevels and meets the level
            if not char.jobLevels[reqJob] or char.jobLevels[reqJob] < reqLevel then
                print("Job change failed: Requires " .. reqJob .. " Lv." .. reqLevel .. ", " .. char.name .. " has Lv." .. (char.jobLevels[reqJob] or 0))
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

-- Check if a character can dual-wield weapons
function character:canDualWield(char)
    if not char or not char.job then
        return false
    end
    
    -- Jobs that can dual-wield weapons
    local dualWieldJobs = {
        ["Rogue"] = true,
        ["Assassin"] = true,
        ["Ninja"] = true,
        ["DualBlader"] = true,
        ["Shadowblade"] = true
    }
    
    -- Check if current job allows dual-wielding
    return dualWieldJobs[char.job] == true
end

-- Calculate attack power
function character:calculateAttackPower(char)
    local basePower = char.attributes.STR

    -- Add main weapon power
    if char.equipment.weapon and char.equipment.weapon.attack then
        basePower = basePower + char.equipment.weapon.attack
    end
    
    -- Add off-hand weapon power if a weapon is equipped there
    if char.equipment.offhand and char.equipment.offhand.type == "weapon" and char.equipment.offhand.attack then
        -- Only add a portion of the off-hand weapon's power (dual-wield balance)
        local offhandMultiplier = 0.5 -- 50% effectiveness for off-hand weapons
        
        -- Rogues get better dual-wield efficiency
        if char.job == "Rogue" then
            offhandMultiplier = 0.7 -- 70% effectiveness for rogues
        end
        
        -- Special jobs get even better dual-wield efficiency
        if char.job == "Ninja" or char.job == "DualBlader" then
            offhandMultiplier = 0.8 -- 80% effectiveness for advanced dual-wielders
        end
        
        -- Apply the multiplier to the off-hand weapon's attack value
        basePower = basePower + math.floor(char.equipment.offhand.attack * offhandMultiplier)
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
    local job = jobSystem:getJob(chosenJobName) -- chosenJobName is the job that JUST leveled up
    if not job then
        print("Error applying level up changes: Job '" .. chosenJobName .. "' not found.")
        return
    end

    -- Apply attribute modifiers ONLY from the job that leveled up
    if job.attributeModifiers then
        print("Applying attribute modifiers for leveling up " .. chosenJobName .. " on " .. char.name)
        for attr, mod in pairs(job.attributeModifiers) do
            local currentVal = char.attributes[attr] or 0
            char.attributes[attr] = math.min(self.BASE_ATTRIBUTE_CAP, currentVal + mod)
             print("  " .. attr .. ": " .. currentVal .. " + " .. mod .. " -> " .. char.attributes[attr])
        end
    end

    -- Calculate the total level
    local totalLevel = self:_calculateTotalLevel(char)
    
    -- Recalculate stats based on new total level and potentially new attributes
    char.maxHP = self:calculateHP(char.attributes.CON, totalLevel)
    char.maxMP = self:calculateMP(char.attributes.INT, char.attributes.WIL, char.attributes.WIS, totalLevel)

    -- Heal character to full after level up
    char.currentHP = char.maxHP
    char.currentMP = char.maxMP

    print(char.name .. " level up changes applied. New Max HP: " .. char.maxHP .. ", New Max MP: " .. char.maxMP)
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
