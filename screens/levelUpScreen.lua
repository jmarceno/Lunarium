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

    self.elements = {}
    self:createUI()
end

function levelUpScreen:createUI()
    -- Main Panel
    self.elements.mainPanel = {
        x = 50,
        y = 50,
        width = GAME.width - 100,
        height = GAME.height - 100
    }

    -- Option Buttons (will be created dynamically)
    self.elements.optionButtons = {}

    -- Gains Display Area
    self.elements.gainsPanel = {
        x = self.elements.mainPanel.x + self.elements.mainPanel.width / 2 - 20,
        y = self.elements.mainPanel.y + 150,
        width = self.elements.mainPanel.width / 2,
        height = self.elements.mainPanel.height - 250
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
    self.potentialGains = { attributes = {}, newSkills = {} }
    self.elements.confirmButton.visible = false
    self.elements.backButton.visible = false
    self.elements.finishButton.visible = false
    self.elements.optionButtons = {} -- Clear old buttons

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
    -- currentJob = currentJob:gsub("%s+", "")
    
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
    local buttonY = self.elements.mainPanel.y + 150
    local buttonX = self.elements.mainPanel.x + 20
    local buttonWidth = self.elements.mainPanel.width / 2 - 60
    local buttonHeight = 40
    local spacing = 10

    for i, option in ipairs(availableOptions) do
        local btn = screenManager.UI.Button(
            buttonX, buttonY + (i-1) * (buttonHeight + spacing),
            buttonWidth, buttonHeight, option.displayName,
            function() self:selectOption(option) end
        )
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
    screenManager:drawPanel("Level Up!", self.elements.mainPanel.x, self.elements.mainPanel.y, self.elements.mainPanel.width, self.elements.mainPanel.height)

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

    -- Draw Options Area (Left Side)
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Choose Level Up Path:", self.elements.mainPanel.x + 20, self.elements.mainPanel.y + 120)

    -- Draw Option Buttons
    for _, btn in ipairs(self.elements.optionButtons) do
        if btn.visible == nil or btn.visible then -- Check visibility if property exists
             btn:draw()
        end
    end

    -- Draw Gains Preview Area (Right Side)
    local gainsX = self.elements.gainsPanel.x
    local gainsY = self.elements.gainsPanel.y
    local gainsW = self.elements.gainsPanel.width
    local gainsH = self.elements.gainsPanel.height

    love.graphics.setColor(0.2, 0.25, 0.3) -- Slightly different background for gains
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
                 love.graphics.print("  " .. attr .. ": +" .. mod, gainsX + 30, gainTextY)
                 gainTextY = gainTextY + 20
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
            love.graphics.setColor(0.8, 0.8, 1) -- Light blue for skills
            for _, skill in ipairs(self.potentialGains.newSkills) do
                love.graphics.print("  - " .. skill.name, gainsX + 30, gainTextY)
                gainTextY = gainTextY + 20
            end
        else
             love.graphics.setColor(0.7, 0.7, 0.7)
             love.graphics.print("  (None)", gainsX + 30, gainTextY)
             gainTextY = gainTextY + 20
        end

        -- Skill Point
        gainTextY = gainTextY + 15
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Skill Points Gained: +1", gainsX + 20, gainTextY)


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

    if self.state == STATES.SELECT_OPTION then
        -- Check option buttons
        for _, btn in ipairs(self.elements.optionButtons) do
            if btn:clicked(x, y, button) then return true end
        end
    elseif self.state == STATES.CONFIRM then
        -- Check confirm button
        if self.elements.confirmButton:clicked(x, y, button) then
            -- Apply the level up and move to next character
            self:finishCharacterLevelUp()
            return true
        end
        
        -- Check back button
        if self.elements.backButton:clicked(x, y, button) then return true end

        -- Allow clicking options again even in confirm state? No, use Back button.
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

    -- Add shortcuts maybe? e.g., number keys for options, enter to confirm
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

return levelUpScreen 