-- Character Creator Screen
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")
local characterSystem = require("gameplay/character")
local jobSystem = require("gameplay/job")

local characterCreator = screenManager:createScreen("Character Creator")

function characterCreator:init()
    -- Initialize state variables
    self.state = "main" -- main, job, attributes, name, preview
    self.currentStep = 1 -- 1-4 (job, attributes, name, preview)
    self.currentCharacter = 1 -- 1-4 (party members)
    self.newGame = true
    self.characters = {}
    self.tempChar = nil
    self.selectedJob = nil
    self.attributePoints = 20
    self.baseAttributes = {}
    self.tempAttributes = {}
    self.charName = ""
    self.profileIndex = 1
    
    -- Initialize base attributes
    for _, attr in ipairs(characterSystem.attributes) do
        self.baseAttributes[attr] = 5 -- Starting value
        self.tempAttributes[attr] = 5
    end
    
    -- Create UI elements
    self:createUI()
end

function characterCreator:createUI()
    -- Step indicators
    self.elements.steps = {
        x = 50,
        y = 100,
        width = GAME.width - 100,
        height = 30,
        
        draw = function(self)
            local steps = {"Choose Job", "Assign Attributes", "Name Character", "Preview"}
            local stepWidth = self.width / #steps
            
            -- Draw steps
            for i, stepName in ipairs(steps) do
                local x = self.x + (i - 1) * stepWidth
                local isActive = characterCreator.currentStep == i
                
                -- Draw background
                love.graphics.setColor(isActive and {0.3, 0.5, 0.8} or {0.2, 0.2, 0.3})
                love.graphics.rectangle("fill", x, self.y, stepWidth - 10, self.height, 5, 5)
                
                -- Draw step name
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                
                local textWidth = screenManager.fonts.small:getWidth(stepName)
                love.graphics.print(
                    stepName,
                    x + (stepWidth - 10 - textWidth) / 2,
                    self.y + (self.height - screenManager.fonts.small:getHeight()) / 2
                )
            end
        end
    }
    
    -- Character slots
    self.elements.charSlots = {
        x = GAME.width - 250,
        y = 150,
        width = 200,
        height = 200,
        
        draw = function(self)
            -- Draw character slots
            for i = 1, 4 do
                local x = self.x
                local y = self.y + (i - 1) * 50
                local isActive = characterCreator.currentCharacter == i
                
                -- Draw background
                if characterCreator.characters[i] then
                    love.graphics.setColor(isActive and {0.3, 0.5, 0.8} or {0.2, 0.3, 0.4})
                else
                    love.graphics.setColor(isActive and {0.3, 0.3, 0.5} or {0.2, 0.2, 0.3})
                end
                love.graphics.rectangle("fill", x, y, self.width, 40, 5, 5)
                
                -- Draw character info if exists
                if characterCreator.characters[i] then
                    local char = characterCreator.characters[i]
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(char.name, x + 10, y + 5)
                    
                    love.graphics.setColor(0.8, 0.8, 1)
                    love.graphics.print(char.job, x + 10, y + 22)
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    love.graphics.print("Empty Slot", x + 10, y + 12)
                end
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if within bounds
            if x >= self.x and x <= self.x + self.width then
                for i = 1, 4 do
                    local slotY = self.y + (i - 1) * 50
                    
                    if y >= slotY and y <= slotY + 40 then
                        characterCreator:selectCharacterSlot(i)
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Job selection grid
    self.elements.jobGrid = {
        x = 50,
        y = 150,
        width = GAME.width - 350,
        height = 300,
        jobs = {},
        visible = true,
        
        init = function(self)
            -- Load base jobs
            self.jobs = jobSystem:getBaseJobs()
        end,
        
        draw = function(self)
            -- Skip if not visible
            if self.visible == false then return end
            
            -- Draw jobs in a grid
            local jobWidth = 150
            local jobHeight = 120
            local cols = math.floor(self.width / jobWidth)
            
            for i, job in ipairs(self.jobs) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                
                local x = self.x + col * jobWidth
                local y = self.y + row * jobHeight
                
                -- Draw job background
                local isSelected = characterCreator.selectedJob == job.name
                
                if isSelected then
                    love.graphics.setColor(0.3, 0.5, 0.8)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle("fill", x + 5, y + 5, jobWidth - 10, jobHeight - 10, 5, 5)
                
                -- Draw job name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                local nameWidth = screenManager.fonts.medium:getWidth(job.name)
                love.graphics.print(
                    job.name,
                    x + 5 + (jobWidth - 10 - nameWidth) / 2,
                    y + 15
                )
                
                -- Draw job description
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 0.8)
                
                love.graphics.printf(
                    job.description,
                    x + 10, y + 45,
                    jobWidth - 20, "center"
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            -- Skip if not visible
            if self.visible == false then return false end
            
            if button ~= 1 then return false end
            
            -- Check if within bounds
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Determine which job was clicked
                local jobWidth = 150
                local jobHeight = 120
                local cols = math.floor(self.width / jobWidth)
                
                for i, job in ipairs(self.jobs) do
                    local col = (i - 1) % cols
                    local row = math.floor((i - 1) / cols)
                    
                    local jobX = self.x + col * jobWidth
                    local jobY = self.y + row * jobHeight
                    
                    if x >= jobX + 5 and x <= jobX + jobWidth - 5 and
                       y >= jobY + 5 and y <= jobY + jobHeight - 5 then
                        characterCreator:selectJob(job.name)
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Attribute allocation
    self.elements.attributes = {
        x = 50,
        y = 150,
        width = GAME.width - 350,
        height = 300,
        visible = true,
        
        draw = function(self)
            -- Skip if not visible
            if self.visible == false then return end
            
            -- Draw points remaining
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(
                "Points Remaining: " .. characterCreator.attributePoints,
                self.x, self.y - 30
            )
            
            -- Draw attributes
            for i, attr in ipairs(characterSystem.attributes) do
                local y = self.y + (i - 1) * 40
                
                -- Draw attribute name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(attr, self.x, y)
                
                -- Draw attribute value
                local value = characterCreator.tempAttributes[attr]
                local valueWidth = screenManager.fonts.medium:getWidth(tostring(value))
                
                love.graphics.print(
                    tostring(value),
                    self.x + 150 - valueWidth / 2,
                    y
                )
                
                -- Draw decrease button
                local canDecrease = value > characterCreator.baseAttributes[attr]
                love.graphics.setColor(canDecrease and {0.8, 0.2, 0.2} or {0.4, 0.1, 0.1})
                love.graphics.rectangle("fill", self.x + 180, y, 30, 30, 5, 5)
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.print("-", self.x + 190, y + 5)
                
                -- Draw increase button
                local canIncrease = characterCreator.attributePoints > 0 and value < characterSystem.BASE_ATTRIBUTE_CAP
                love.graphics.setColor(canIncrease and {0.2, 0.8, 0.2} or {0.1, 0.4, 0.1})
                love.graphics.rectangle("fill", self.x + 220, y, 30, 30, 5, 5)
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("+", self.x + 230, y + 5)
            end
        end,
        
        clicked = function(self, x, y, button)
            -- Skip if not visible
            if self.visible == false then return false end
            
            if button ~= 1 then return false end
            
            -- Check if within bounds of attribute buttons
            for i, attr in ipairs(characterSystem.attributes) do
                local attrY = self.y + (i - 1) * 40
                
                -- Check decrease button
                if x >= self.x + 180 and x <= self.x + 210 and
                   y >= attrY and y <= attrY + 30 then
                    characterCreator:decreaseAttribute(attr)
                    return true
                end
                
                -- Check increase button
                if x >= self.x + 220 and x <= self.x + 250 and
                   y >= attrY and y <= attrY + 30 then
                    characterCreator:increaseAttribute(attr)
                    return true
                end
            end
            
            return false
        end
    }
    
    -- Name input
    self.elements.nameInput = screenManager.UI.InputField(
        50, 200, 300, 40, "Enter character name", 20
    )
    
    -- Profile selection
    self.elements.profileSelection = {
        x = 50,
        y = 280,
        width = 300,
        height = 150,
        
        draw = function(self)
            -- Draw label
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Select Character Portrait", self.x, self.y - 30)
            
            -- Draw profile selection grid
            local profileSize = 64
            local spacing = 10
            local cols = 4
            
            for i = 1, 8 do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                
                local x = self.x + col * (profileSize + spacing)
                local y = self.y + row * (profileSize + spacing)
                
                -- Draw selection highlight
                if i == characterCreator.profileIndex then
                    love.graphics.setColor(0.3, 0.5, 0.8)
                    love.graphics.rectangle(
                        "fill", 
                        x - 3, y - 3, 
                        profileSize + 6, profileSize + 6
                    )
                end
                
                -- Draw profile image
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(assetManager.images.profiles[i], x, y)
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if within bounds
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Determine which profile was clicked
                local profileSize = 64
                local spacing = 10
                local cols = 4
                
                for i = 1, 8 do
                    local col = (i - 1) % cols
                    local row = math.floor((i - 1) / cols)
                    
                    local profileX = self.x + col * (profileSize + spacing)
                    local profileY = self.y + row * (profileSize + spacing)
                    
                    if x >= profileX and x <= profileX + profileSize and
                       y >= profileY and y <= profileY + profileSize then
                        characterCreator.profileIndex = i
                        return true
                    end
                end
            end
            
            return false
        end
    }
    
    -- Character preview
    self.elements.characterPreview = {
        x = 50,
        y = 150,
        width = GAME.width - 350,
        height = 300,
        
        draw = function(self)
            if not characterCreator.tempChar then return end
            
            local char = characterCreator.tempChar
            
            -- Draw character profile
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                assetManager.images.profiles[char.profileIndex],
                self.x, self.y
            )
            
            -- Draw character details
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(char.name, self.x + 80, self.y)
            
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.print("Level " .. char.level .. " " .. char.job, self.x + 80, self.y + 25)
            
            -- Draw attributes
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(1, 1, 1)
            
            local attrY = self.y + 70
            for _, attr in ipairs(characterSystem.attributes) do
                love.graphics.print(attr .. ": " .. char.attributes[attr], self.x + 80, attrY)
                attrY = attrY + 20
            end
            
            -- Draw derived stats
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Stats", self.x, self.y + 220)
            
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.print("HP: " .. char.maxHP, self.x, self.y + 250)
            love.graphics.print("MP: " .. char.maxMP, self.x + 100, self.y + 250)
            
            local meleeHit = characterSystem:calculateMeleeHitChance(
                char.attributes.STR, char.attributes.DEX
            )
            local rangedHit = characterSystem:calculateRangedHitChance(
                char.attributes.DEX, char.attributes.STR
            )
            
            love.graphics.print("Melee Hit: " .. math.floor(meleeHit) .. "%", self.x, self.y + 270)
            love.graphics.print("Ranged Hit: " .. math.floor(rangedHit) .. "%", self.x + 100, self.y + 270)
            
            -- Draw skills
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Starting Skills", self.x + 250, self.y)
            
            love.graphics.setFont(screenManager.fonts.small)
            local skillY = self.y + 30
            for skillName, skillInfo in pairs(char.skills) do
                love.graphics.print(skillName, self.x + 250, skillY)
                skillY = skillY + 20
            end
        end
    }
    
    -- Navigation buttons
    self.elements.prevButton = screenManager.UI.Button(
        50, GAME.height - 80, 150, 40, "Previous", 
        function() self:prevStep() end
    )
    self.elements.prevButton.visible = true

    self.elements.nextButton = screenManager.UI.Button(
        GAME.width - 200, GAME.height - 80, 150, 40, "Next", 
        function() self:nextStep() end
    )
    self.elements.nextButton.visible = true

    -- Finish button (for last step)
    self.elements.finishButton = screenManager.UI.Button(
        GAME.width - 200, GAME.height - 80, 150, 40, "Create", 
        function() self:finishCharacter() end
    )
    self.elements.finishButton.visible = false  -- Initially hidden, shown in step 4
    
    -- Initialize job grid
    self.elements.jobGrid:init()
end

function characterCreator:enter(params)
    -- Reset state
    self.state = "main"
    self.currentStep = 1
    self.newGame = params and params.newGame or false
    
    -- If new game, initialize party
    if self.newGame then
        self.characters = {}
        self.currentCharacter = 1
    else
        -- Load existing party if available
        self.characters = GAME.party or {}
        self.currentCharacter = math.min(#self.characters + 1, 4)
    end
    
    -- Reset temp variables
    self:resetTempChar()
end

function characterCreator:update(dt)
    -- Update input fields
    self.elements.nameInput:update(dt)
end

function characterCreator:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(screenManager.colors.title)
    love.graphics.print("Character Creator", 50, 50)
    
    -- Draw step indicators
    self.elements.steps:draw()
    
    -- Draw character slots
    self.elements.charSlots:draw()
    
    -- Update button visibility based on current step
    self:updateElementVisibility()
    
    -- Draw current step content
    if self.currentStep == 1 then
        -- Job selection
        self.elements.jobGrid:draw()
    elseif self.currentStep == 2 then
        -- Attribute allocation
        self.elements.attributes:draw()
    elseif self.currentStep == 3 then
        -- Character naming and profile selection
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Character Name", 50, 170)
        
        self.elements.nameInput:draw()
        self.elements.profileSelection:draw()
    elseif self.currentStep == 4 then
        -- Character preview
        self.elements.characterPreview:draw()
    end
    
    -- Always draw navigation buttons separately from updateElementVisibility
    if self.currentStep > 1 then
        self.elements.prevButton:draw()
        if GAME.debug then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("Previous Button: " .. (self.elements.prevButton.visible and "visible" or "hidden"), 10, GAME.height - 110)
        end
    end
    
    if self.currentStep < 4 then
        self.elements.nextButton:draw()
        if GAME.debug then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("Next Button: " .. (self.elements.nextButton.visible and "visible" or "hidden"), GAME.width - 200, GAME.height - 110)
        end
    else
        self.elements.finishButton:draw()
        if GAME.debug then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("Create Button: " .. (self.elements.finishButton.visible and "visible" or "hidden"), GAME.width - 200, GAME.height - 110)
        end
    end
end

function characterCreator:updateElementVisibility()
    -- Navigation buttons visibility based on current step
    if self.currentStep > 1 then
        self.elements.prevButton.visible = true
    else
        self.elements.prevButton.visible = false
    end
    
    if self.currentStep < 4 then
        self.elements.nextButton.visible = true
        self.elements.finishButton.visible = false
    else
        self.elements.nextButton.visible = false
        self.elements.finishButton.visible = true
    end
    
    if GAME.debug then
        print("Button visibility updated - Step: " .. self.currentStep)
        print("  Previous: " .. (self.elements.prevButton.visible and "visible" or "hidden"))
        print("  Next: " .. (self.elements.nextButton.visible and "visible" or "hidden"))
        print("  Create: " .. (self.elements.finishButton.visible and "visible" or "hidden"))
    end
    
    -- Job grid visibility
    if self.elements.jobGrid then
        self.elements.jobGrid.visible = (self.currentStep == 1)
    end
    
    -- Attributes visibility
    if self.elements.attributes then
        self.elements.attributes.visible = (self.currentStep == 2)
    end
    
    -- Name input and profile selection visibility
    if self.elements.nameInput then
        self.elements.nameInput.visible = (self.currentStep == 3)
    end
    
    if self.elements.profileSelection then
        self.elements.profileSelection.visible = (self.currentStep == 3)
    end
    
    -- Character preview visibility
    if self.elements.characterPreview then
        self.elements.characterPreview.visible = (self.currentStep == 4)
    end
end

function characterCreator:keypressed(key, scancode, isrepeat)
    -- Pass to input fields
    self.elements.nameInput:keyPressed(key)
end

function characterCreator:textinput(text)
    -- Pass to input fields
    self.elements.nameInput:textInput(text)
end

function characterCreator:mousepressed(x, y, button, istouch, presses)
    -- Pass to UI elements that are visible for the current step
    local clickHandled = false
    
    for name, element in pairs(self.elements) do
        -- Only process visible elements
        if element.visible ~= false then
            if element.clicked then
                if element:clicked(x, y, button) then
                    -- Play click sound
                    assetManager:playSound("click")
                    
                    if GAME.debug then
                        print("Button clicked: " .. name)
                    end
                    
                    clickHandled = true
                    -- Don't break to allow hover effects on other elements
                end
            end
        end
    end
    
    return clickHandled
end

function characterCreator:mousereleased(x, y, button, istouch, presses)
    -- Pass to UI elements
    for _, element in pairs(self.elements) do
        if element.released then
            element:released(x, y)
        end
    end
end

function characterCreator:selectCharacterSlot(index)
    -- Select character slot
    self.currentCharacter = index
    
    -- If character exists, load it for editing
    if self.characters[index] then
        -- TODO: Implement character editing
        -- For now, just create a new character
        self:resetTempChar()
    else
        -- Reset temporary character
        self:resetTempChar()
    end
end

function characterCreator:printDebugInfo(message)
    if not GAME.debug then return end
    
    print("=== Character Creator Debug ===")
    if message then
        print(message)
    end
    print("Current Step: " .. self.currentStep)
    print("Selected Job: " .. (self.selectedJob or "None"))
    print("Points Remaining: " .. self.attributePoints)
    print("Character Name: " .. (self.charName or ""))
    print("Profile Index: " .. self.profileIndex)
    print("Button Visibility:")
    print("  Previous: " .. (self.elements.prevButton.visible and "visible" or "hidden"))
    print("  Next: " .. (self.elements.nextButton.visible and "visible" or "hidden"))
    print("  Create: " .. (self.elements.finishButton.visible and "visible" or "hidden"))
    print("Element Visibility:")
    print("  jobGrid: " .. (self.elements.jobGrid.visible and "visible" or "hidden"))
    print("  attributes: " .. (self.elements.attributes.visible and "visible" or "hidden"))
end

function characterCreator:selectJob(jobName)
    -- Select job
    self.selectedJob = jobName
    
    if GAME.debug then
        print("Selected job: " .. jobName)
    end
    
    -- Update base attributes based on job
    local job = jobSystem:getJob(jobName)
    if job and job.attributeModifiers then
        for attr, _ in pairs(self.baseAttributes) do
            self.baseAttributes[attr] = 5 -- Reset to default
        end
        
        for attr, mod in pairs(job.attributeModifiers) do
            self.baseAttributes[attr] = self.baseAttributes[attr] + mod
        end
        
        -- Reset temp attributes to match base attributes
        for attr, value in pairs(self.baseAttributes) do
            self.tempAttributes[attr] = value
        end
        
        -- Reset attribute points
        self.attributePoints = 20
    end
    
    -- Print debug info
    self:printDebugInfo("Job selected: " .. jobName)
end

function characterCreator:increaseAttribute(attr)
    -- Check if points available and not at cap
    if self.attributePoints > 0 and self.tempAttributes[attr] < characterSystem.BASE_ATTRIBUTE_CAP then
        -- Increase attribute
        self.tempAttributes[attr] = self.tempAttributes[attr] + 1
        
        -- Decrease points
        self.attributePoints = self.attributePoints - 1
    end
end

function characterCreator:decreaseAttribute(attr)
    -- Check if above base value
    if self.tempAttributes[attr] > self.baseAttributes[attr] then
        -- Decrease attribute
        self.tempAttributes[attr] = self.tempAttributes[attr] - 1
        
        -- Increase points
        self.attributePoints = self.attributePoints + 1
    end
end

function characterCreator:resetTempChar()
    -- Reset selected job
    self.selectedJob = nil
    
    -- Reset attributes
    for attr, _ in pairs(self.baseAttributes) do
        self.baseAttributes[attr] = 5 -- Default
        self.tempAttributes[attr] = 5
    end
    
    -- Reset attribute points
    self.attributePoints = 20
    
    -- Reset name
    self.charName = ""
    self.elements.nameInput:setValue("")
    
    -- Reset profile index
    self.profileIndex = 1
    
    -- Reset temp character
    self.tempChar = nil
end

function characterCreator:prevStep()
    -- Go to previous step
    if self.currentStep > 1 then
        self.currentStep = self.currentStep - 1
        
        -- Update element visibility
        self:updateElementVisibility()
        
        -- Print debug info
        self:printDebugInfo("Moved to previous step")
    end
end

function characterCreator:nextStep()
    -- Check if current step is complete
    if not self:isStepComplete() then
        return
    end
    
    -- Go to next step
    if self.currentStep < 4 then
        self.currentStep = self.currentStep + 1
        
        -- If going to preview step, create temporary character
        if self.currentStep == 4 then
            self:createTempChar()
        end
        
        -- Update element visibility
        self:updateElementVisibility()
        
        -- Print debug info
        self:printDebugInfo("Moved to next step")
    end
end

function characterCreator:isStepComplete()
    if self.currentStep == 1 then
        -- Job selection
        return self.selectedJob ~= nil
    elseif self.currentStep == 2 then
        -- Attribute allocation
        return true -- Always complete, as points can remain unallocated
    elseif self.currentStep == 3 then
        -- Character naming
        return self.elements.nameInput:getValue() ~= ""
    end
    
    return true
end

function characterCreator:createTempChar()
    -- Get character name
    self.charName = self.elements.nameInput:getValue()
    
    -- Create temporary character
    self.tempChar = characterSystem:new(
        self.charName,
        self.selectedJob,
        self.tempAttributes,
        self.profileIndex
    )
end

function characterCreator:finishCharacter()
    -- Create final character
    self:createTempChar()
    
    -- Add character to party
    self.characters[self.currentCharacter] = self.tempChar
    
    -- If party is not full, go to next character
    if #self.characters < 4 then
        -- Move to next empty slot
        local nextSlot = 0
        for i = 1, 4 do
            if not self.characters[i] then
                nextSlot = i
                break
            end
        end
        
        if nextSlot > 0 then
            -- Select next slot and start over
            self.currentCharacter = nextSlot
            self.currentStep = 1
            self:resetTempChar()
            return
        end
    end
    
    -- Party complete or selected slot filled, move to next step
    self:finishParty()
end

function characterCreator:finishParty()
    -- Save party to game state
    GAME.party = self.characters
    
    -- Initialize inventory if needed
    if not GAME.inventory then
        GAME.inventory = {}
    end
    
    -- Initialize gold if needed
    if not GAME.gold then
        GAME.gold = 100
    end
    
    -- If new game, create a save file
    if self.newGame then
        -- Create profile using first character's name
        local profileName = self.characters[1].name .. "s_Party"
        
        -- Create and save profile
        local profile = saveLoad:createProfile(profileName)
        
        if not profile then
            -- Save failed, show an error but continue to overworld
            print("WARNING: Failed to create save profile!")
            -- Could add a popup message here
        else
            -- Set profile data
            profile.party = self.characters
            profile.inventory = GAME.inventory
            profile.gold = GAME.gold
            
            -- Save profile
            if not saveLoad:saveGame(profile) then
                print("WARNING: Failed to save game data!")
                -- Could add a popup message here
            end
        end
    end
    
    -- Move to overworld
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

return characterCreator
