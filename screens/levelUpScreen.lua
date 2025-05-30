-- Level Up Screen
-- Handles the character level up process after gaining sufficient experience

local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local characterSystem = require("gameplay/character")
local jobSystem = require("gameplay/job")
local skillSystem = require("gameplay/skill")

local levelUpScreen = screenManager:createScreen("LevelUp")

-- Screen States
local STATES = {
    SELECT_OPTION = 1,
    CONFIRM = 2,
    FINISHED = 3
}

function levelUpScreen:init()
    self.state = STATES.SELECT_OPTION
    self.charactersToLevel = {}
    self.currentCharacterIndex = 1
    self.selectedOption = nil -- { jobName = "...", isNewJob = false }
    self.potentialGains = {
        attributes = {},
        newSkills = {}
    }
    
    -- Scroll position for job options
    self.jobOptionsScroll = 0
    self.maxJobOptionsVisible = 6 -- Max number of job options visible at once

    self.elements = {}
    
    -- Attribute descriptions
    self.attributeDescriptions = {
        STR = "Strength: Increases physical damage and hit chance. Essential for melee fighters.",
        INT = "Intelligence: Boosts magic power and maximum mana. Critical for spellcasters.",
        CON = "Constitution: Enhances health points and physical resilience. Important for tanks.",
        WIL = "Will: Improves magic resistance and mental fortitude. Useful against magical attacks.",
        CHA = "Charisma: Affects NPC interactions and certain persuasion skills. Helps in social situations.",
        DEX = "Dexterity: Improves ranged attacks, dodge chance, and action speed. Key for rogues.",
        WIS = "Wisdom: Enhances healing power, skill effectiveness, and mana regeneration. Important for healers."
    }
    
    -- Create LUIS layer for level up screen
    self.luisLayer = "levelUpScreen"
    self:createUI()
end

function levelUpScreen:createUI()
    -- Main container using flexbox layout
    self.mainContainer = luis.newFlexContainer(2, 2, 58, 36)
    self.mainContainer:setDirection("column")
    self.mainContainer:setJustifyContent("flex-start")
    self.mainContainer:setAlignItems("stretch")
    self.mainContainer:setPadding(2, 2, 2, 2)
    
    -- Character info container
    self.characterInfoContainer = luis.newFlexContainer(0, 0, 58, 8)
    self.characterInfoContainer:setDirection("row")
    self.characterInfoContainer:setJustifyContent("flex-start")
    self.characterInfoContainer:setAlignItems("center")
    self.characterInfoContainer:setPadding(2, 2, 2, 2)
    
    -- Character portrait (placeholder for now since LUIS doesn't have image widget)
    self.characterPortrait = luis.newLabel(0, 0, 8, 6, "Portrait")
    self.characterInfoContainer:addChild(self.characterPortrait)
    
    -- Character details container
    self.characterDetailsContainer = luis.newFlexContainer(0, 0, 40, 6)
    self.characterDetailsContainer:setDirection("column")
    self.characterDetailsContainer:setJustifyContent("flex-start")
    self.characterDetailsContainer:setAlignItems("flex-start")
    
    self.characterNameLabel = luis.newLabel(0, 0, 40, 2, "Character Name")
    self.characterJobLabel = luis.newLabel(0, 0, 40, 2, "Job Info")
    self.characterLevelLabel = luis.newLabel(0, 0, 40, 2, "Level Info")
    
    self.characterDetailsContainer:addChild(self.characterNameLabel)
    self.characterDetailsContainer:addChild(self.characterJobLabel)
    self.characterDetailsContainer:addChild(self.characterLevelLabel)
    
    self.characterInfoContainer:addChild(self.characterDetailsContainer)
    self.mainContainer:addChild(self.characterInfoContainer)
    
    -- Content container (job options + gains preview)
    self.contentContainer = luis.newFlexContainer(0, 0, 58, 22)
    self.contentContainer:setDirection("row")
    self.contentContainer:setJustifyContent("space-between")
    self.contentContainer:setAlignItems("stretch")
    self.contentContainer:setPadding(1, 1, 1, 1)
    
    -- Left side - job options and description
    self.leftContainer = luis.newFlexContainer(0, 0, 28, 22)
    self.leftContainer:setDirection("column")
    self.leftContainer:setJustifyContent("flex-start")
    self.leftContainer:setAlignItems("stretch")
    
    -- Job options container
    self.jobOptionsContainer = luis.newFlexContainer(0, 0, 28, 15)
    self.jobOptionsContainer:setDirection("column")
    self.jobOptionsContainer:setJustifyContent("flex-start")
    self.jobOptionsContainer:setAlignItems("stretch")
    self.jobOptionsContainer:setPadding(1, 1, 1, 1)
    
    -- Job description container
    self.jobDescContainer = luis.newFlexContainer(0, 0, 28, 7)
    self.jobDescContainer:setDirection("column")
    self.jobDescContainer:setJustifyContent("flex-start")
    self.jobDescContainer:setAlignItems("stretch")
    self.jobDescContainer:setPadding(1, 1, 1, 1)
    
    self.jobDescLabel = luis.newLabel(0, 0, 26, 5, "Select a job option to see details")
    self.jobDescContainer:addChild(self.jobDescLabel)
    
    self.leftContainer:addChild(self.jobOptionsContainer)
    self.leftContainer:addChild(self.jobDescContainer)
    
    -- Right side - gains preview
    self.gainsContainer = luis.newFlexContainer(0, 0, 28, 22)
    self.gainsContainer:setDirection("column")
    self.gainsContainer:setJustifyContent("flex-start")
    self.gainsContainer:setAlignItems("stretch")
    self.gainsContainer:setPadding(1, 1, 1, 1)
    
    self.gainsTitle = luis.newLabel(0, 0, 26, 2, "Potential Gains")
    self.gainsContent = luis.newLabel(0, 0, 26, 18, "Select an option to see gains")
    
    self.gainsContainer:addChild(self.gainsTitle)
    self.gainsContainer:addChild(self.gainsContent)
    
    self.contentContainer:addChild(self.leftContainer)
    self.contentContainer:addChild(self.gainsContainer)
    self.mainContainer:addChild(self.contentContainer)
    
    -- Bottom buttons container
    self.buttonsContainer = luis.newFlexContainer(0, 0, 58, 4)
    self.buttonsContainer:setDirection("row")
    self.buttonsContainer:setJustifyContent("space-between")
    self.buttonsContainer:setAlignItems("center")
    self.buttonsContainer:setPadding(2, 2, 2, 2)
    
    -- Change choice button (initially hidden)
    self.changeChoiceButton = luis.newButton(0, 0, 12, 3, "Change Choice", function()
        self:changeChoice()
    end)
    
    -- Confirm button (initially hidden)
    self.confirmButton = luis.newButton(0, 0, 12, 3, "Confirm", function()
        self:confirmLevelUp()
    end)
    
    -- Finish button (initially hidden)
    self.finishButton = luis.newButton(0, 0, 12, 3, "Continue", function()
        self:close()
    end)
    
    self.buttonsContainer:addChild(self.changeChoiceButton)
    self.buttonsContainer:addChild(self.confirmButton)
    self.buttonsContainer:addChild(self.finishButton)
    
    self.mainContainer:addChild(self.buttonsContainer)
    
    -- Store job option buttons for cleanup
    self.jobOptionButtons = {}
end

function levelUpScreen:enter(params)
    print("Entering Level Up Screen")
    
    -- Create and show LUIS layer
    luis.setCurrentLayer(self.luisLayer)
    luis.insertElement(self.luisLayer, self.mainContainer)
    
    -- Ensure we reset state properly
    self.state = STATES.SELECT_OPTION
    self.charactersToLevel = {}
    self.currentCharacterIndex = 1
    self.selectedOption = nil
    self.jobOptionsScroll = 0 -- Reset scroll position
    self.potentialGains = { attributes = {}, newSkills = {} }
    
    -- Hide all buttons initially
    self.confirmButton:setVisible(false)
    self.changeChoiceButton:setVisible(false)
    self.finishButton:setVisible(false)

    if params and params.charactersToLevelUp then
        self.charactersToLevel = params.charactersToLevelUp
        print("Characters to level up:", #self.charactersToLevel)
        if #self.charactersToLevel > 0 then
            self:setupCharacter(self.charactersToLevel[self.currentCharacterIndex])
        else
            print("Warning: Entered level up screen with no characters to level.")
            self.state = STATES.FINISHED -- Nothing to do
            self.finishButton:setVisible(true)
        end
    else
        print("Error: Level up screen entered without characters to level.")
        self.state = STATES.FINISHED -- Nothing to do
        self.finishButton:setVisible(true)
    end

    -- Play level up jingle or sound effect
    assetManager:playSound("level_up_start") -- Assuming a sound named 'level_up_start' exists
end

function levelUpScreen:exit()
    -- Clean up LUIS layer
    if luis.getLayer(self.luisLayer) then
        luis.clearLayer(self.luisLayer)
    end
end

function levelUpScreen:setupCharacter(character)
    print("Setting up level up for:", character.name)
    
    -- Ensure character has required fields
    if not character.jobLevels then
        print("Warning: Initializing jobLevels for", character.name)
        character.jobLevels = {}
    end
    
    if not character.jobHistory then
        print("Warning: Initializing jobHistory for", character.name)
        character.jobHistory = {character.job} -- Assume current job is in history
    end
    
    -- Ensure character's current job is in jobLevels
    if not character.jobLevels[character.job] then
        print("Warning: Initializing job level for current job", character.job)
        character.jobLevels[character.job] = 1 -- Assume at least level 1
    end
    
    self.state = STATES.SELECT_OPTION
    self.selectedOption = nil
    self.potentialGains = { attributes = {}, newSkills = {} }
    
    -- Update character display
    self:updateCharacterDisplay(character)
    
    -- Hide confirm buttons until an option is chosen
    self.confirmButton:setVisible(false)
    self.changeChoiceButton:setVisible(false)

    self:generateOptionButtons(character)
end

function levelUpScreen:updateCharacterDisplay(character)
    -- Update character name
    self.characterNameLabel:setText(character.name)
    
    -- Update job info based on selected option
    local currentJobName = character.job
    local displayedJobName = currentJobName
    local currentJobLevel = character.jobLevels[currentJobName] or 0
    local newJobLevel = currentJobLevel + 1
    
    -- If changing jobs, use the new job name and level
    if self.selectedOption and self.selectedOption.isNewJob then
        displayedJobName = self.selectedOption.jobName
        -- If it's a brand new job, start at level 1
        if not character.jobLevels[displayedJobName] then
            currentJobLevel = 0
            newJobLevel = 1
        else
            -- Otherwise use the existing level
            currentJobLevel = character.jobLevels[displayedJobName] or 0
            newJobLevel = currentJobLevel + 1
        end
    end
    
    -- Update job label
    self.characterJobLabel:setText(displayedJobName .. " Lv. " .. currentJobLevel .. " -> " .. newJobLevel)
    
    -- Update total level
    local totalLevel = characterSystem:_calculateTotalLevel(character)
    local newTotalLevel = totalLevel + 1
    self.characterLevelLabel:setText("Total Level: " .. totalLevel .. " -> " .. newTotalLevel)
end

function levelUpScreen:getAvailableLevelUpOptions(character)
    local options = {}
    local currentJob = jobSystem:getJob(character.job)
    
    if not currentJob then
        print("Error: Could not find job definition for " .. (character.job or "nil"))
        return options -- Return empty options list
    end

    -- Option 1: Continue current job
    table.insert(options, {
        jobName = character.job,
        displayName = "Continue as " .. character.job,
        isNewJob = false,
        jobData = currentJob -- Pass jobData here too
    })

    -- Option 2+: Change job (if possible)
    local availableJobs = jobSystem:getAvailableJobs(character) or {}
    print("Available jobs from jobSystem for", character.name, ":")
    for i, job in ipairs(availableJobs) do
        print("  - ", job.name, "(Tier", job.tier, ")")
        -- Add any available job that isn't the character's current job as an option
        if job.name ~= character.job then
            print("    Adding as option:", job.name)
            table.insert(options, {
                jobName = job.name,
                displayName = "Change to " .. job.name .. " (Tier " .. job.tier .. ")",
                isNewJob = true,
                jobData = job -- Pass the full job data
            })
        end
    end

    return options
end

function levelUpScreen:generateOptionButtons(character)
    -- Clear existing option buttons
    for _, button in ipairs(self.jobOptionButtons) do
        self.jobOptionsContainer:removeChild(button)
    end
    self.jobOptionButtons = {}
    
    local availableOptions = self:getAvailableLevelUpOptions(character)
    
    -- Create LUIS button for each option
    for i, option in ipairs(availableOptions) do
        local btn = luis.newButton(0, 0, 26, 2, option.displayName, function()
            self:selectOption(option)
        end)
        
        -- Store job data in the button for convenience
        btn.jobData = option.jobData
        
        self.jobOptionsContainer:addChild(btn)
        table.insert(self.jobOptionButtons, btn)
    end
end

function levelUpScreen:selectOption(option)
    print("Selected option:", option.displayName)
    self.selectedOption = option
    self.potentialGains = self:calculateGains(self.charactersToLevel[self.currentCharacterIndex], option.jobName, option.isNewJob)

    -- Update character display with new selection
    self:updateCharacterDisplay(self.charactersToLevel[self.currentCharacterIndex])
    
    -- Update job description
    if option.jobData then
        local descText = "Job: " .. option.jobData.name .. " (Tier " .. option.jobData.tier .. ")\n" .. 
                        (option.jobData.description or "No description available")
        self.jobDescLabel:setText(descText)
    end
    
    -- Update gains display
    self:updateGainsDisplay()

    -- Move to confirmation state
    self.state = STATES.CONFIRM
    self.confirmButton:setVisible(true)
    self.changeChoiceButton:setVisible(true)

    -- Make option buttons inactive visually
    for _, btn in ipairs(self.jobOptionButtons) do
        btn:setEnabled(false)
    end
    
    assetManager:playSound("click")
end

function levelUpScreen:calculateGains(character, chosenJobName, isNewJob)
    local gains = { attributes = {}, newSkills = {} }
    
    -- Directly use the jobData passed in the selectedOption
    local job = self.selectedOption and self.selectedOption.jobData

--[[     -- Debugging Print - Check if we got the jobData directly
    print("[LevelUpScreen] Calculating gains for job:", (job and job.name or chosenJobName), "IsNewJob:", isNewJob)
    if job then
        if job.attributeModifiers then
           local count = 0
           for _ in pairs(job.attributeModifiers) do count = count + 1 end
        end        
    else
        print("  Error: Could not get jobData from self.selectedOption for", chosenJobName)
        -- This should not happen if selectOption worked correctly
        return gains
    end
    -- End Debugging Print ]]

    -- Attribute gains
    if job.attributeModifiers then
        for attr, mod in pairs(job.attributeModifiers) do
            local currentVal = character.attributes[attr] or 0
            local newVal = math.min(characterSystem.BASE_ATTRIBUTE_CAP, currentVal + mod)
            if newVal > currentVal then
                gains.attributes[attr] = (gains.attributes[attr] or 0) + mod
            end
        end
    end

    -- New skills (only if changing to a new job)
    if isNewJob and job.startingSkills then
        for _, skillName in ipairs(job.startingSkills) do
            -- Check if character already knows the skill (from a previous job perhaps)
            -- Ensure character.skills exists before accessing it
            if not (character.skills and character.skills[skillName]) then
                local skill = skillSystem:getSkill(skillName)
                if skill then
                    table.insert(gains.newSkills, skill)
                else 
                    print("Warning: Could not find skill data for starting skill:", skillName, "in job:", job.name)
                end
            end
        end
    end

    return gains
end

function levelUpScreen:updateGainsDisplay()
    local gainsText = "Attribute Increases:\n"
    local hasAttrGains = false
    
    for attr, mod in pairs(self.potentialGains.attributes) do
        if mod > 0 then
            gainsText = gainsText .. attr .. ": +" .. mod .. "\n"
            if self.attributeDescriptions[attr] then
                gainsText = gainsText .. "  " .. self.attributeDescriptions[attr] .. "\n\n"
            end
            hasAttrGains = true
        end
    end
    
    if not hasAttrGains then
        gainsText = gainsText .. "  (None)\n\n"
    end
    
    gainsText = gainsText .. "New Skills Learned:\n"
    if #self.potentialGains.newSkills > 0 then
        for _, skill in ipairs(self.potentialGains.newSkills) do
            gainsText = gainsText .. "• " .. skill.name .. "\n"
            if skill.description then
                gainsText = gainsText .. "  " .. skill.description .. "\n"
            end
        end
    else
        gainsText = gainsText .. "  (None)"
    end
    
    self.gainsContent:setText(gainsText)
end

function levelUpScreen:changeChoice()
    self.state = STATES.SELECT_OPTION
    self.selectedOption = nil
    self.potentialGains = { attributes = {}, newSkills = {} }
    
    -- Update character display back to default
    self:updateCharacterDisplay(self.charactersToLevel[self.currentCharacterIndex])
    
    -- Reset job description
    self.jobDescLabel:setText("Select a job option to see details")
    
    -- Reset gains display
    self.gainsContent:setText("Select an option to see gains")
    
    -- Hide confirmation buttons
    self.confirmButton:setVisible(false)
    self.changeChoiceButton:setVisible(false)
    
    -- Re-enable option buttons
    for _, btn in ipairs(self.jobOptionButtons) do
        btn:setEnabled(true)
    end
    
    assetManager:playSound("click")
end

function levelUpScreen:confirmLevelUp()
    if not self.selectedOption then
        print("Error: No option selected for level up")
        return
    end

    local character = self.charactersToLevel[self.currentCharacterIndex]
    print("Confirming level up for:", character.name, "with option:", self.selectedOption.displayName)
    
    -- Apply the level up
    self:applyLevelUp(character, self.selectedOption.jobName, self.selectedOption.isNewJob)
    
    -- Move to next character or finish
    self.currentCharacterIndex = self.currentCharacterIndex + 1
    
    if self.currentCharacterIndex <= #self.charactersToLevel then
        -- Set up next character
        self:setupCharacter(self.charactersToLevel[self.currentCharacterIndex])
    else
        -- All characters leveled up
        self.state = STATES.FINISHED
        -- Hide all other UI elements
        self.mainContainer:setVisible(false)
        -- Show finish button
        self.finishButton:setVisible(true)
    end
    
    assetManager:playSound("level_up_confirm")
end

function levelUpScreen:close()
    self.selectedOption = nil
    self.charactersToLevel = {}
    self.currentCharacterIndex = 1
    self:exit()
    screenManager:popToScreen("Dungeon")
end

function levelUpScreen:update(dt)
    -- LUIS handles all UI updates now
end

function levelUpScreen:draw()
    -- LUIS handles all drawing now
end

function levelUpScreen:mousepressed(x, y, button, istouch, presses)
    -- LUIS handles all mouse input now
    return false
end

function levelUpScreen:keypressed(key)
    -- Handle any keyboard shortcuts if needed
    if key == "escape" then
        if self.state == STATES.CONFIRM then
            self:changeChoice()
        else
            self:close()
        end
        return true
    end
    
    return false
end

function levelUpScreen:wheelmoved(x, y)
    -- Mouse wheel scrolling is handled by LUIS flexbox layout automatically
    return false
end

function levelUpScreen:applyLevelUp(character, chosenJobName, isNewJob)
    print("Applying level up for", character.name, "as", chosenJobName)

    -- Check if continuing existing job or changing to a new/different job
    if isNewJob then
        -- Change job (which also handles adding it to jobLevels if new)
        local actualJobKey = self.selectedOption.jobData.name
        actualJobKey = actualJobKey:gsub("%s+", "")
        local jobChanged = characterSystem:changeJob(character, actualJobKey)
        if not jobChanged then
            print("Error: Failed to change job for", character.name, "to", actualJobKey)
            -- Might need to revert level up? Complex state. For now, proceed.
        end
    else
        -- Level up the current job
        if not characterSystem:levelUp(character) then
            print("Error: Failed to level up job for", character.name)
            return
        end
    end

    -- Apply attribute gains, recalculate stats
    characterSystem:applyLevelUpChanges(character, self.selectedOption.jobData)
    
    -- Clear the level up flag now that it's been processed
    character.needsLevelUpScreen = nil
end

return levelUpScreen 