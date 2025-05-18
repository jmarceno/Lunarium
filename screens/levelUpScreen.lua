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
    self:createUI()
    
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
end

function levelUpScreen:createUI()
    -- Main Panel
    self.elements.mainPanel = {
        x = 50,
        y = 50,
        width = GAME.width - 100,
        height = GAME.height - 100
    }

    -- Option Buttons Panel (with scrolling)
    self.elements.optionsPanel = {
        x = self.elements.mainPanel.x + 20,
        y = self.elements.mainPanel.y + 150,
        width = self.elements.mainPanel.width / 2 - 60,
        height = 300
    }

    -- Option Buttons (will be created dynamically)
    self.elements.optionButtons = {}

    -- Scroll buttons for job options
    self.elements.scrollUpButton = screenManager.UI.Button(
        self.elements.optionsPanel.x + self.elements.optionsPanel.width - 30,
        self.elements.optionsPanel.y,
        30, 30, "▲",
        function() self:scrollJobOptions(-1) end
    )
    
    self.elements.scrollDownButton = screenManager.UI.Button(
        self.elements.optionsPanel.x + self.elements.optionsPanel.width - 30,
        self.elements.optionsPanel.y + self.elements.optionsPanel.height - 30,
        30, 30, "▼",
        function() self:scrollJobOptions(1) end
    )

    -- Gains Display Area (with more details)
    self.elements.gainsPanel = {
        x = self.elements.mainPanel.x + self.elements.mainPanel.width / 2 - 20,
        y = self.elements.mainPanel.y + 150,
        width = self.elements.mainPanel.width / 2,
        height = self.elements.mainPanel.height - 250
    }

    -- Job Description Panel
    self.elements.jobDescPanel = {
        x = self.elements.optionsPanel.x,
        y = self.elements.optionsPanel.y + self.elements.optionsPanel.height + 20,
        width = self.elements.optionsPanel.width,
        height = 120
    }

    -- Confirmation Button
    self.elements.confirmButton = screenManager.UI.Button(
        self.elements.mainPanel.x + self.elements.mainPanel.width - 170,
        self.elements.mainPanel.y + self.elements.mainPanel.height - 70,
        150, 50, "Confirm",
        function() self:confirmLevelUp() end
    )
    self.elements.confirmButton.visible = false -- Initially hidden

    -- Back/Change Button (for confirmation state)
    self.elements.backButton = screenManager.UI.Button(
        self.elements.mainPanel.x + 20,
        self.elements.mainPanel.y + self.elements.mainPanel.height - 70,
        150, 50, "Change Choice",
        function() self:changeChoice() end
    )
    self.elements.backButton.visible = false -- Initially hidden

     -- Finish Button (for when all chars are leveled)
    self.elements.finishButton = screenManager.UI.Button(
        GAME.width / 2 - 75,
        GAME.height / 2 + 100,
        150, 50, "Continue",
        function() self:close() end
    )
    self.elements.finishButton.visible = false
end

function levelUpScreen:enter(params)
    print("Entering Level Up Screen")
    -- Ensure we reset state properly
    self.state = STATES.SELECT_OPTION
    self.charactersToLevel = {}
    self.currentCharacterIndex = 1
    self.selectedOption = nil
    self.jobOptionsScroll = 0 -- Reset scroll position
    self.potentialGains = { attributes = {}, newSkills = {} }
    self.elements.confirmButton.visible = false
    self.elements.backButton.visible = false
    self.elements.finishButton.visible = false
    self.elements.optionButtons = {} -- Clear old buttons
    self.elements.scrollUpButton.visible = false
    self.elements.scrollDownButton.visible = false

    if params and params.charactersToLevelUp then
        self.charactersToLevel = params.charactersToLevelUp
        print("Characters to level up:", #self.charactersToLevel)
        if #self.charactersToLevel > 0 then
            self:setupCharacter(self.charactersToLevel[self.currentCharacterIndex])
        else
            print("Warning: Entered level up screen with no characters to level.")
            self.state = STATES.FINISHED -- Nothing to do
            self.elements.finishButton.visible = true
        end
    else
        print("Error: Level up screen entered without characters to level.")
        self.state = STATES.FINISHED -- Nothing to do
        self.elements.finishButton.visible = true
    end

    -- Play level up jingle or sound effect
    assetManager:playSound("level_up_start") -- Assuming a sound named 'level_up_start' exists
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
    self.elements.confirmButton.visible = false -- Hide confirm until an option is chosen
    self.elements.backButton.visible = false -- Hide back button initially

    self:generateOptionButtons(character)
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
    self.elements.optionButtons = {}
    local availableOptions = self:getAvailableLevelUpOptions(character)
    local buttonHeight = 40
    local spacing = 10
    
    -- Configure button dimensions
    local buttonWidth = self.elements.optionsPanel.width - 40 -- Account for scroll buttons
    local buttonY = self.elements.optionsPanel.y
    local buttonX = self.elements.optionsPanel.x
    
    -- Show scroll buttons if needed
    local showScrollButtons = #availableOptions > self.maxJobOptionsVisible
    self.elements.scrollUpButton.visible = showScrollButtons
    self.elements.scrollDownButton.visible = showScrollButtons
    
    -- Create a button for each option
    for i, option in ipairs(availableOptions) do
        local btn = screenManager.UI.Button(
            buttonX, 
            buttonY + (i-1) * (buttonHeight + spacing),
            buttonWidth, 
            buttonHeight, 
            option.displayName,
            function() self:selectOption(option) end
        )
        -- Store job data in the button for convenience
        btn.jobData = option.jobData
        table.insert(self.elements.optionButtons, btn)
    end
end

function levelUpScreen:selectOption(option)
    print("Selected option:", option.displayName)
    self.selectedOption = option
    self.potentialGains = self:calculateGains(self.charactersToLevel[self.currentCharacterIndex], option.jobName, option.isNewJob)

    -- Move to confirmation state
    self.state = STATES.CONFIRM
    self.elements.confirmButton.visible = true
    self.elements.backButton.visible = true

    -- Make option buttons inactive visually (or hide them)
    for _, btn in ipairs(self.elements.optionButtons) do
        btn.disabled = true -- Assuming Button class handles disabled state visually
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

function levelUpScreen:changeChoice()
    self.state = STATES.SELECT_OPTION
    self.selectedOption = nil
    self.potentialGains = { attributes = {}, newSkills = {} }
    self.elements.confirmButton.visible = false
    self.elements.backButton.visible = false

    -- Re-enable option buttons
    for _, btn in ipairs(self.elements.optionButtons) do
        btn.disabled = false
    end
     assetManager:playSound("cancel") -- Or a different sound
end

function levelUpScreen:confirmLevelUp()
    if not self.selectedOption then return end
    local character = self.charactersToLevel[self.currentCharacterIndex]
    local chosenJobName = self.selectedOption.jobName
    local isNewJob = self.selectedOption.isNewJob

    print("Confirming level up for", character.name, "as", chosenJobName)

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
            self:nextCharacter() -- Move to next character
            return
        end
    end

    -- Apply attribute gains, recalculate stats
    characterSystem:applyLevelUpChanges(character, self.selectedOption.jobData)

    -- Play confirmation sound
    assetManager:playSound("confirm") -- Or 'level_up_complete'

    -- Move to the next character
    self:nextCharacter()
end

function levelUpScreen:nextCharacter()
    self.currentCharacterIndex = self.currentCharacterIndex + 1
    if self.currentCharacterIndex > #self.charactersToLevel then
        self.state = STATES.FINISHED
        self.elements.confirmButton.visible = false
        self.elements.backButton.visible = false
        self.elements.finishButton.visible = true
         for _, btn in ipairs(self.elements.optionButtons) do btn.visible = false end -- Hide old buttons
    else
        self:setupCharacter(self.charactersToLevel[self.currentCharacterIndex])
    end
end

function levelUpScreen:update(dt)
    -- Not much needed here unless adding animations
end

function levelUpScreen:draw()
    -- Dim background (draw semi-transparent overlay)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)

    -- Draw Main Panel Background
    screenManager:drawPanel("Level Up! - Choose a Path", self.elements.mainPanel.x, self.elements.mainPanel.y, self.elements.mainPanel.width, self.elements.mainPanel.height)

    if self.state == STATES.FINISHED then
        -- Draw Finished Message
        love.graphics.setFont(screenManager.fonts.large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Level Up Complete!", 0, GAME.height / 2 - 50, GAME.width, "center")
        self.elements.finishButton:draw()
        return -- Don't draw anything else
    end

    -- Get current character
    local character = self.charactersToLevel[self.currentCharacterIndex]
    if not character then return end -- Should not happen if logic is correct

    -- Draw Character Info (Portrait, Name, Level)
    local portraitX = self.elements.mainPanel.x + 20
    local portraitY = self.elements.mainPanel.y + 40
    love.graphics.setColor(1, 1, 1)
    if character.portraitId and assetManager.images.portraits[character.portraitId] then
        love.graphics.draw(assetManager.images.portraits[character.portraitId], portraitX, portraitY, 0, 0.5, 0.5)
    elseif assetManager.images.profiles[character.profileIndex] then
        love.graphics.draw(assetManager.images.profiles[character.profileIndex], portraitX, portraitY, 0, 0.5, 0.5)
    end

    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(character.name, portraitX + 100, portraitY + 10)

    -- Display current and new job level
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(0.9, 0.9, 1)
    
    -- Show job level progression based on selected option
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
    
    -- Show job information
    love.graphics.print(displayedJobName .. " Lv. " .. currentJobLevel .. " -> " .. newJobLevel, portraitX + 100, portraitY + 50)
    
    -- Show total level information
    local totalLevel = characterSystem:_calculateTotalLevel(character)
    local newTotalLevel = totalLevel + 1  -- One level up will increase total level by 1
    love.graphics.print("Total Level: " .. totalLevel .. " -> " .. newTotalLevel, portraitX + 100, portraitY + 80)

    -- Draw Options Panel
    love.graphics.setColor(0.2, 0.25, 0.3)
    love.graphics.rectangle("fill", self.elements.optionsPanel.x, self.elements.optionsPanel.y, 
        self.elements.optionsPanel.width, self.elements.optionsPanel.height, 5, 5)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.rectangle("line", self.elements.optionsPanel.x, self.elements.optionsPanel.y, 
        self.elements.optionsPanel.width, self.elements.optionsPanel.height, 5, 5)

    -- -- Draw Options Area Title
    -- love.graphics.setFont(screenManager.fonts.medium)
    -- love.graphics.setColor(1, 1, 0)
    -- love.graphics.print("Choose Level Up Path:", self.elements.optionsPanel.x, self.elements.optionsPanel.y - 30)

    -- Draw Option Buttons with scrolling
    local visibleStart = self.jobOptionsScroll + 1
    local visibleEnd = math.min(#self.elements.optionButtons, visibleStart + self.maxJobOptionsVisible - 1)
    
    -- Clip to options panel area (prevents buttons from drawing outside the panel)
    love.graphics.setScissor(
        self.elements.optionsPanel.x, 
        self.elements.optionsPanel.y, 
        self.elements.optionsPanel.width, 
        self.elements.optionsPanel.height
    )
    
    -- Draw visible buttons
    for i = visibleStart, visibleEnd do
        local btn = self.elements.optionButtons[i]
        if btn then
            -- Adjust button position for scrolling
            local originalY = btn.y
            btn.y = self.elements.optionsPanel.y + (i - visibleStart) * (btn.height + 10)
            btn:draw()
            btn.y = originalY -- Restore original position for hit detection
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw scroll buttons if more options than we can display
    if #self.elements.optionButtons > self.maxJobOptionsVisible then
        self.elements.scrollUpButton:draw()
        self.elements.scrollDownButton:draw()
    end
    
    -- Draw Job Description Panel
    love.graphics.setColor(0.2, 0.25, 0.3) 
    love.graphics.rectangle("fill", self.elements.jobDescPanel.x, self.elements.jobDescPanel.y, 
        self.elements.jobDescPanel.width, self.elements.jobDescPanel.height, 5, 5)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.rectangle("line", self.elements.jobDescPanel.x, self.elements.jobDescPanel.y, 
        self.elements.jobDescPanel.width, self.elements.jobDescPanel.height, 5, 5)
    
    -- Show job description if option is selected
    if self.selectedOption and self.selectedOption.jobData then
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Job: " .. self.selectedOption.jobData.name .. " (Tier " .. self.selectedOption.jobData.tier .. ")\n" ..
            (self.selectedOption.jobData.description or "No description available"),
            self.elements.jobDescPanel.x + 10, 
            self.elements.jobDescPanel.y + 10,
            self.elements.jobDescPanel.width - 20,
            "left"
        )
    end

    -- Draw Gains Preview Area
    local gainsX = self.elements.gainsPanel.x
    local gainsY = self.elements.gainsPanel.y
    local gainsW = self.elements.gainsPanel.width
    local gainsH = self.elements.gainsPanel.height

    love.graphics.setColor(0.2, 0.25, 0.3)
    love.graphics.rectangle("fill", gainsX, gainsY, gainsW, gainsH, 5, 5)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.rectangle("line", gainsX, gainsY, gainsW, gainsH, 5, 5)

    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 1, 0)
    love.graphics.printf("Potential Gains", gainsX, gainsY + 10, gainsW, "center")

    if self.selectedOption then
        local gainTextY = gainsY + 50
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(1, 1, 1)

        -- Attributes
        love.graphics.print("Attribute Increases:", gainsX + 20, gainTextY)
        gainTextY = gainTextY + 25
        local hasAttrGains = false
        for attr, mod in pairs(self.potentialGains.attributes) do
             if mod > 0 then
                 love.graphics.setColor(0, 1, 0) -- Green for gains
                 
                 -- Print attribute name and value
                 local attrText = attr .. ": +" .. mod
                 love.graphics.print(attrText, gainsX + 30, gainTextY)
                 
                 -- Print attribute description with wrapping
                 if self.attributeDescriptions[attr] then
                     love.graphics.setColor(0.9, 0.9, 0.9) -- Light gray for description text
                     love.graphics.printf(
                         self.attributeDescriptions[attr], 
                         gainsX + 150, 
                         gainTextY,
                         gainsW - 180, -- Width for wrapping
                         "left"
                     )
                 end
                 
                 -- Calculate text height with wrapping for proper spacing
                 local _, textLines = screenManager.fonts.small:getWrap(
                     self.attributeDescriptions[attr] or "", 
                     gainsW - 180
                 )
                 local textHeight = #textLines * screenManager.fonts.small:getHeight()
                 
                 -- Add extra space for multi-line descriptions (min 30 pixels)
                 gainTextY = gainTextY + math.max(30, textHeight + 10)
                 hasAttrGains = true
             end
        end
        if not hasAttrGains then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("  (None)", gainsX + 30, gainTextY)
            gainTextY = gainTextY + 20
        end

        -- New Skills
        gainTextY = gainTextY + 15
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("New Skills Learned:", gainsX + 20, gainTextY)
        gainTextY = gainTextY + 25
        if #self.potentialGains.newSkills > 0 then
            for _, skill in ipairs(self.potentialGains.newSkills) do
                love.graphics.setColor(0.8, 0.8, 1) -- Light blue for skills
                
                -- Print skill name
                love.graphics.print("• " .. skill.name .. " (" .. (skill.type or "Unknown") .. ")", gainsX + 30, gainTextY)
                                
                -- Print skill type and description with wrapping
                love.graphics.setColor(0.9, 0.9, 0.9) -- Light gray for description text
                local skillDesc = "\n" .. (skill.description or "No description available")
                
                love.graphics.printf(
                    skillDesc, 
                    gainsX + 45, 
                    gainTextY,
                    gainsW - 75, -- Width for wrapping
                    "left"
                )
                
                -- Calculate text height with wrapping for proper spacing
                local _, textLines = screenManager.fonts.small:getWrap(skillDesc, gainsW - 75)
                local textHeight = #textLines * screenManager.fonts.small:getHeight()
                
                -- Add space after description
                gainTextY = gainTextY + textHeight + 15
            end
        else
             love.graphics.setColor(0.7, 0.7, 0.7)
             love.graphics.print("  (None)", gainsX + 30, gainTextY)
             gainTextY = gainTextY + 20
        end

        -- Skill Point Info
        gainTextY = gainTextY + 15
        love.graphics.setColor(1, 1, 1)
        -- Show next skill to be gained if this is an odd level after 1
        local character = self.charactersToLevel[self.currentCharacterIndex]
        local jobData = self.selectedOption.jobData
        local newJobLevel = character.jobLevels[jobData.name] or 1
        if not self.selectedOption.isNewJob then
            newJobLevel = newJobLevel + 1 -- Account for pending level up
        end
        
        if newJobLevel > 1 and newJobLevel % 2 == 1 and jobData.availableSkills then
            gainTextY = gainTextY + 15
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Next Level Skill:", gainsX + 20, gainTextY)
            gainTextY = gainTextY + 25
            
            -- Find next unlearned skill
            local nextSkill = nil
            for _, skillName in ipairs(jobData.availableSkills) do
                if not character.skills[skillName] then
                    nextSkill = skillName
                    break
                end
            end
            
            if nextSkill then
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.print("  - " .. nextSkill, gainsX + 30, gainTextY)
                gainTextY = gainTextY + 20
            end
        end
    else
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("(Select a path to see gains)", gainsX, gainsY + gainsH / 2 - 10, gainsW, "center")
    end

    -- Draw Confirmation/Back Buttons
    if self.state == STATES.CONFIRM then
        self.elements.confirmButton:draw()
        self.elements.backButton:draw()
    end
end

function levelUpScreen:mousepressed(x, y, button, istouch, presses)
    if self.state == STATES.FINISHED then
        if self.elements.finishButton:clicked(x,y,button) then return true end
        return false -- Consume clicks on finished screen
    end

    -- Check scroll buttons
    if self.elements.scrollUpButton.visible and self.elements.scrollUpButton:clicked(x, y, button) then
        return true
    end
    
    if self.elements.scrollDownButton.visible and self.elements.scrollDownButton:clicked(x, y, button) then
        return true
    end

    if self.state == STATES.SELECT_OPTION then
        -- Check option buttons
        for i, btn in ipairs(self.elements.optionButtons) do
            -- Only check visible buttons
            if i >= self.jobOptionsScroll + 1 and i <= self.jobOptionsScroll + self.maxJobOptionsVisible then
                -- Adjust position for scrolling
                local originalY = btn.y
                btn.y = self.elements.optionsPanel.y + (i - self.jobOptionsScroll - 1) * (btn.height + 10)
                local clicked = btn:clicked(x, y, button)
                btn.y = originalY -- Restore original position
                
                if clicked then return true end
            end
        end
    elseif self.state == STATES.CONFIRM then
        -- Check confirm button
        if self.elements.confirmButton:clicked(x, y, button) then
            return true
        end
        
        -- Check back button
        if self.elements.backButton:clicked(x, y, button) then return true end
    end
    
    -- Consume clicks within the main panel area even if not on a button
    if x >= self.elements.mainPanel.x and x <= self.elements.mainPanel.x + self.elements.mainPanel.width and
       y >= self.elements.mainPanel.y and y <= self.elements.mainPanel.y + self.elements.mainPanel.height then
       return true
    end

    return false -- Click was outside the panel
end

function levelUpScreen:keypressed(key, scancode, isrepeat)
    if self.state == STATES.FINISHED and (key == "return" or key == "space" or key == "escape") then
        self:close()
        return true
    end

    if self.state == STATES.CONFIRM and key == "escape" then
        self:changeChoice()
        return true
    end
    
    -- Scrolling with keyboard
    if key == "up" then
        self:scrollJobOptions(-1)
        return true
    elseif key == "down" then
        self:scrollJobOptions(1)
        return true
    end
    
    -- Number keys for quick selection (1-9)
    local num = tonumber(key)
    if num and num >= 1 and num <= 9 then
        local index = num + self.jobOptionsScroll
        if index <= #self.elements.optionButtons then
            local option = self.elements.optionButtons[index]
            if option and option.jobData then
                -- Create a proper option object
                local fullOption = {
                    jobName = option.jobData.name,
                    displayName = option.text,
                    isNewJob = option.jobData.name ~= self.charactersToLevel[self.currentCharacterIndex].job,
                    jobData = option.jobData
                }
                self:selectOption(fullOption)
                return true
            end
        end
    end
    
    -- Confirm with enter/return
    if self.state == STATES.CONFIRM and (key == "return" or key == "space") then
        self:confirmLevelUp()
        return true
    end

    return false
end

function levelUpScreen:wheelmoved(x, y)
    -- Mouse wheel scrolling for job options
    if y ~= 0 and #self.elements.optionButtons > self.maxJobOptionsVisible then
        self:scrollJobOptions(-math.floor(y)) -- Scrolling up (y > 0) should move list up (jobOptionsScroll down)
        return true
    end
    return false
end

function levelUpScreen:close()
    print("Closing Level Up Screen.")
    
    -- Make sure ALL characters in the party have their level up flags cleared
    -- This prevents the level-up screen from reappearing immediately
    if GAME.party then
        print("Clearing level up flags for all party members")
        for _, char in ipairs(GAME.party) do
            if char.needsLevelUpScreen then
                print("Clearing level up flag for " .. char.name)
                char.needsLevelUpScreen = nil
            end
        end
    end
    
    local gameState = require("states/gameState")
    -- Important: Return to the *previous* state, which should be the dungeon
    -- screen (or potentially Overworld if leveling happened outside dungeon?)
    gameState:returnToPreviousState({ from_levelup = true })
end

function levelUpScreen:finishCharacterLevelUp()
    local currentChar = self.charactersToLevel[self.currentCharacterIndex]
    
    -- Check if currentChar is valid
    if not currentChar then
        print("Error: No character found at index " .. self.currentCharacterIndex)
        self:close()
        return
    end
    
    -- Apply the level up changes based on selected job
    if self.selectedOption and self.selectedOption.jobName then
        local chosenJobName = self.selectedOption.jobName
        local isNewJob = self.selectedOption.isNewJob
        
        -- Check if continuing existing job or changing to a new/different job
        if isNewJob then
            -- Change job (which also handles adding it to jobLevels if new)
            local actualJobKey = self.selectedOption.jobData.name
            local jobChanged = characterSystem:changeJob(currentChar, actualJobKey)
            if not jobChanged then
                print("Error: Failed to change job for", currentChar.name, "to", actualJobKey)
                -- Might need to revert level up? Complex state. For now, proceed.
            end
        else
            -- Level up the current job
            if not characterSystem:levelUp(currentChar) then
                print("Error: Failed to level up job for", currentChar.name)
                self:nextCharacter() -- Move to next character
                return
            end
        end
        
        -- Apply attribute gains, recalculate stats
        characterSystem:applyLevelUpChanges(currentChar, self.selectedOption.jobData)
        
        -- Clear the level up flag now that it's been processed
        currentChar.needsLevelUpScreen = nil
        
        -- Move to the next character or finish
        self.currentCharacterIndex = self.currentCharacterIndex + 1
        if self.currentCharacterIndex <= #self.charactersToLevel then
            -- Reset for next character
            self.state = STATES.SELECT_OPTION
            self.selectedOption = nil
            self.potentialGains = {
                attributes = {},
                newSkills = {}
            }
            self:setupCharacter(self.charactersToLevel[self.currentCharacterIndex])
        else
            -- All characters are done, transition back to dungeon
            self:close()
        end
    end
end

function levelUpScreen:scrollJobOptions(direction)
    local totalOptions = #self.elements.optionButtons
    local maxScroll = math.max(0, totalOptions - self.maxJobOptionsVisible)
    
    self.jobOptionsScroll = self.jobOptionsScroll + direction
    if self.jobOptionsScroll < 0 then self.jobOptionsScroll = 0 end
    if self.jobOptionsScroll > maxScroll then self.jobOptionsScroll = maxScroll end
    
    assetManager:playSound("click")
end

return levelUpScreen 