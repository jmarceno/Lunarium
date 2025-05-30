-- Character Creator Screen (LUIS)
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local saveLoad = require("utils/saveLoad")
local characterSystem = require("gameplay/character")
local jobSystem = require("gameplay/job")

-- Get LUIS instance
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

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
    self.portraitId = nil
    
    -- Initialize base attributes
    for _, attr in ipairs(characterSystem.attributes) do
        self.baseAttributes[attr] = 5 -- Starting value
        self.tempAttributes[attr] = 5
    end
    
    -- Create LUIS layers for different steps
    luis.newLayer("characterCreatorLayer")
    luis.newLayer("jobSelectionLayer")
    luis.newLayer("attributeLayer")
    luis.newLayer("nameInputLayer")
    luis.newLayer("previewLayer")
    
    -- Create UI elements
    self:createUI()
    
    -- Start with job selection
    self:showJobSelection()
end

function characterCreator:createUI()
    -- Create main character creator container
    local mainContainer = luis.createElement("characterCreatorLayer", "FlexContainer", 35, 18, 2, 3, nil, "CharCreatorMain")
    
    -- Character slots panel (right side)
    local slotsContainer = luis.newFlexContainer(8, 16, 1, 1, nil, "CharacterSlots")
    
    -- Create character slot buttons
    self.characterSlots = {}
    for i = 1, 4 do
        local slotButton = luis.newButton("Empty Slot", 7, 3, 
            function() self:selectCharacterSlot(i) end, nil, 1, 1)
        slotsContainer:addChild(slotButton)
        self.characterSlots[i] = slotButton
    end
    
    mainContainer:addChild(slotsContainer)
    
    -- Navigation buttons
    local navContainer = luis.newFlexContainer(35, 3, 1, 1, nil, "Navigation")
    
    self.prevButton = luis.newButton("Previous", 6, 2, function() self:previousStep() end, nil, 1, 1)
    self.nextButton = luis.newButton("Next", 6, 2, function() self:nextStep() end, nil, 1, 1)
    self.finishButton = luis.newButton("Finish", 6, 2, function() self:finishCharacterCreation() end, nil, 1, 1)
    self.backButton = luis.newButton("Back to Menu", 8, 2, function() self:backToMainMenu() end, nil, 1, 1)
    
    navContainer:addChild(self.prevButton)
    navContainer:addChild(self.nextButton)
    navContainer:addChild(self.finishButton)
    navContainer:addChild(self.backButton)
    
    mainContainer:addChild(navContainer)
    
    -- Job Selection UI
    self:createJobSelectionUI()
    
    -- Attribute Selection UI
    self:createAttributeUI()
    
    -- Name Input UI
    self:createNameInputUI()
    
    -- Preview UI
    self:createPreviewUI()
end

function characterCreator:createJobSelectionUI()
    local jobContainer = luis.createElement("jobSelectionLayer", "FlexContainer", 30, 16, 2, 3, nil, "JobSelection")
    
    -- Job title
    local jobTitle = luis.newLabel("Choose Job", 25, 2, 1, 1, "center")
    jobContainer:addChild(jobTitle)
    
    -- Job buttons container (grid layout)
    local jobGrid = luis.newFlexContainer(28, 12, 1, 1, nil, "JobGrid")
    
    -- Get available jobs and create buttons
    local jobs = jobSystem:getBaseJobs()
    self.jobButtons = {}
    
    for _, job in ipairs(jobs) do
        local jobButton = luis.newButton(job.name, 8, 3, 
            function() self:selectJob(job.name) end, nil, 1, 1)
        jobGrid:addChild(jobButton)
        self.jobButtons[job.name] = jobButton
    end
    
    jobContainer:addChild(jobGrid)
    
    -- Job description area
    self.jobDescription = luis.newLabel("Select a job to see description", 28, 3, 1, 1, "left")
    jobContainer:addChild(self.jobDescription)
end

function characterCreator:createAttributeUI()
    local attrContainer = luis.createElement("attributeLayer", "FlexContainer", 30, 16, 2, 3, nil, "AttributeSelection")
    
    -- Attribute title
    local attrTitle = luis.newLabel("Assign Attributes", 25, 2, 1, 1, "center")
    attrContainer:addChild(attrTitle)
    
    -- Points remaining label
    self.pointsLabel = luis.newLabel("Points Remaining: " .. self.attributePoints, 25, 1, 1, 1, "center")
    attrContainer:addChild(self.pointsLabel)
    
    -- Attribute controls container
    local attrGrid = luis.newFlexContainer(28, 10, 1, 1, nil, "AttributeGrid")
    
    self.attributeControls = {}
    for _, attr in ipairs(characterSystem.attributes) do
        local attrRow = luis.newFlexContainer(26, 2, 1, 1, nil, "Attr" .. attr)
        
        -- Attribute name
        local nameLabel = luis.newLabel(attr, 8, 1, 1, 1, "left")
        attrRow:addChild(nameLabel)
        
        -- Decrease button
        local decreaseBtn = luis.newButton("-", 2, 1, 
            function() self:adjustAttribute(attr, -1) end, nil, 1, 1)
        attrRow:addChild(decreaseBtn)
        
        -- Value label
        local valueLabel = luis.newLabel(tostring(self.tempAttributes[attr]), 3, 1, 1, 1, "center")
        attrRow:addChild(valueLabel)
        
        -- Increase button
        local increaseBtn = luis.newButton("+", 2, 1, 
            function() self:adjustAttribute(attr, 1) end, nil, 1, 1)
        attrRow:addChild(increaseBtn)
        
        attrGrid:addChild(attrRow)
        
        self.attributeControls[attr] = {
            decrease = decreaseBtn,
            value = valueLabel,
            increase = increaseBtn
        }
    end
    
    attrContainer:addChild(attrGrid)
end

function characterCreator:createNameInputUI()
    local nameContainer = luis.createElement("nameInputLayer", "FlexContainer", 30, 16, 2, 3, nil, "NameInput")
    
    -- Name title
    local nameTitle = luis.newLabel("Name Your Character", 25, 2, 1, 1, "center")
    nameContainer:addChild(nameTitle)
    
    -- Name input field
    self.nameInput = luis.newTextInput("Enter name here...", 20, 2, 
        function(text) self.charName = text end, 1, 1)
    nameContainer:addChild(self.nameInput)
    
    -- Portrait selection (simplified)
    local portraitLabel = luis.newLabel("Portrait Selection (placeholder)", 25, 2, 1, 1, "center")
    nameContainer:addChild(portraitLabel)
end

function characterCreator:createPreviewUI()
    local previewContainer = luis.createElement("previewLayer", "FlexContainer", 30, 16, 2, 3, nil, "Preview")
    
    -- Preview title
    local previewTitle = luis.newLabel("Character Preview", 25, 2, 1, 1, "center")
    previewContainer:addChild(previewTitle)
    
    -- Character summary
    self.previewSummary = luis.newLabel("Character details will appear here", 25, 10, 1, 1, "left")
    previewContainer:addChild(self.previewSummary)
end

function characterCreator:enter(options)
    -- Handle enter parameters
    if options and options.newGame then
        self.newGame = true
        self.characters = {}
        self.currentCharacter = 1
    end
    
    -- Start with job selection
    self:showJobSelection()
    self:updateCharacterSlots()
end

function characterCreator:showJobSelection()
    self.currentStep = 1
    luis.disableLayer("attributeLayer")
    luis.disableLayer("nameInputLayer")
    luis.disableLayer("previewLayer")
    luis.enableLayer("characterCreatorLayer")
    luis.enableLayer("jobSelectionLayer")
    self:updateNavigationButtons()
end

function characterCreator:showAttributeSelection()
    self.currentStep = 2
    luis.disableLayer("jobSelectionLayer")
    luis.disableLayer("nameInputLayer")
    luis.disableLayer("previewLayer")
    luis.enableLayer("characterCreatorLayer")
    luis.enableLayer("attributeLayer")
    self:updateNavigationButtons()
    self:updateAttributeControls()
end

function characterCreator:showNameInput()
    self.currentStep = 3
    luis.disableLayer("jobSelectionLayer")
    luis.disableLayer("attributeLayer")
    luis.disableLayer("previewLayer")
    luis.enableLayer("characterCreatorLayer")
    luis.enableLayer("nameInputLayer")
    self:updateNavigationButtons()
end

function characterCreator:showPreview()
    self.currentStep = 4
    luis.disableLayer("jobSelectionLayer")
    luis.disableLayer("attributeLayer")
    luis.disableLayer("nameInputLayer")
    luis.enableLayer("characterCreatorLayer")
    luis.enableLayer("previewLayer")
    self:updateNavigationButtons()
    self:updatePreview()
end

function characterCreator:update(dt)
    -- LUIS handles all UI updates automatically
end

function characterCreator:draw()
    -- Draw background
    love.graphics.clear(0.1, 0.1, 0.15)
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.title)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Character Creator"
    local titleWidth = screenManager.fonts.title:getWidth(titleText)
    love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 20)
    
    -- Draw current character indicator
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(0.8, 0.8, 1)
    local charText = "Character " .. self.currentCharacter .. " of 4"
    love.graphics.print(charText, 20, 80)
    
    -- LUIS handles all UI rendering automatically via main.lua
end

function characterCreator:selectCharacterSlot(slot)
    self.currentCharacter = slot
    self:updateCharacterSlots()
    
    -- If the slot has an existing character, load its data for editing
    if self.characters[slot] then
        local char = self.characters[slot]
        self.selectedJob = char.job
        self.charName = char.name
        self.tempAttributes = {}
        for attr, value in pairs(char.attributes) do
            self.tempAttributes[attr] = value
        end
        self.portraitId = char.portraitId
        
        -- Update UI to reflect the loaded character
        if self.nameInput then
            self.nameInput.text = self.charName
        end
        if self.jobDescription then
            local jobData = jobSystem:getJobByName(self.selectedJob)
            if jobData then
                self.jobDescription.text = jobData.description or "No description available"
            end
        end
    else
        -- Reset for new character
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
    print("Portrait ID: " .. (self.portraitId or "None"))
    print("Button Visibility:")
    print("  Previous: " .. (self.elements.prevButton.visible and "visible" or "hidden"))
    print("  Next: " .. (self.elements.nextButton.visible and "visible" or "hidden"))
    print("  Create: " .. (self.elements.finishButton.visible and "visible" or "hidden"))
    print("Element Visibility:")
    print("  jobGrid: " .. (self.elements.jobGrid.visible and "visible" or "hidden"))
    print("  attributes: " .. (self.elements.attributes.visible and "visible" or "hidden"))
end

function characterCreator:selectJob(jobName)
    self.selectedJob = jobName
    
    -- Update job description
    if self.jobDescription then
        local jobData = jobSystem:getJobByName(jobName)
        if jobData then
            self.jobDescription.text = jobData.description or "No description available"
        end
    end
    
    -- Update job button highlighting
    for name, button in pairs(self.jobButtons) do
        if name == jobName then
            button:setTheme({backgroundColor = {0.3, 0.5, 0.8}})
        else
            button:setTheme({backgroundColor = {0.2, 0.2, 0.3}})
        end
    end
end

function characterCreator:adjustAttribute(attribute, change)
    local currentValue = self.tempAttributes[attribute]
    local newValue = currentValue + change
    
    -- Check constraints
    if change > 0 then
        -- Increasing
        if self.attributePoints > 0 and newValue <= (characterSystem.BASE_ATTRIBUTE_CAP or 20) then
            self.tempAttributes[attribute] = newValue
            self.attributePoints = self.attributePoints - 1
        end
    else
        -- Decreasing
        if newValue >= self.baseAttributes[attribute] then
            self.tempAttributes[attribute] = newValue
            self.attributePoints = self.attributePoints + 1
        end
    end
    
    -- Update UI
    self:updateAttributeControls()
    if self.pointsLabel then
        self.pointsLabel.text = "Points Remaining: " .. self.attributePoints
    end
end

function characterCreator:updateAttributeControls()
    if not self.attributeControls then return end
    
    for attr, controls in pairs(self.attributeControls) do
        local value = self.tempAttributes[attr]
        
        -- Update value display
        controls.value.text = tostring(value)
        
        -- Update button states
        local canDecrease = value > self.baseAttributes[attr]
        local canIncrease = self.attributePoints > 0 and value < (characterSystem.BASE_ATTRIBUTE_CAP or 20)
        
        controls.decrease:setEnabled(canDecrease)
        controls.increase:setEnabled(canIncrease)
    end
end

function characterCreator:updateCharacterSlots()
    if not self.characterSlots then return end
    
    for i, slotButton in ipairs(self.characterSlots) do
        if self.characters[i] then
            local char = self.characters[i]
            slotButton.text = char.name .. "\n" .. char.job
            if i == self.currentCharacter then
                slotButton:setTheme({backgroundColor = {0.3, 0.5, 0.8}})
            else
                slotButton:setTheme({backgroundColor = {0.2, 0.3, 0.4}})
            end
        else
            slotButton.text = "Empty Slot"
            if i == self.currentCharacter then
                slotButton:setTheme({backgroundColor = {0.3, 0.3, 0.5}})
            else
                slotButton:setTheme({backgroundColor = {0.2, 0.2, 0.3}})
            end
        end
    end
end

function characterCreator:updateNavigationButtons()
    if not self.prevButton or not self.nextButton or not self.finishButton then return end
    
    -- Previous button
    self.prevButton:setVisible(self.currentStep > 1)
    
    -- Next/Finish buttons
    if self.currentStep < 4 then
        self.nextButton:setVisible(true)
        self.finishButton:setVisible(false)
    else
        self.nextButton:setVisible(false)
        self.finishButton:setVisible(true)
    end
end

function characterCreator:updatePreview()
    if not self.previewSummary then return end
    
    -- Create temp character for preview
    if self:createTempChar() then
        local char = self.tempChar
        local summary = string.format(
            "Name: %s\nJob: %s\nLevel: %d\n\nAttributes:\n",
            char.name, char.job, (char.level or 1)
        )
        
        for _, attr in ipairs(characterSystem.attributes) do
            summary = summary .. string.format("%s: %d\n", attr, char.attributes[attr])
        end
        
        summary = summary .. string.format(
            "\nHP: %d\nMP: %d",
            char.maxHP or 100, char.maxMP or 50
        )
        
        self.previewSummary.text = summary
    else
        self.previewSummary.text = "Error creating character preview"
    end
end

function characterCreator:previousStep()
    if self.currentStep > 1 then
        self.currentStep = self.currentStep - 1
        self:showCurrentStep()
    end
end

function characterCreator:nextStep()
    if self:isStepComplete() then
        if self.currentStep < 4 then
            self.currentStep = self.currentStep + 1
            self:showCurrentStep()
        end
    end
end

function characterCreator:showCurrentStep()
    if self.currentStep == 1 then
        self:showJobSelection()
    elseif self.currentStep == 2 then
        self:showAttributeSelection()
    elseif self.currentStep == 3 then
        self:showNameInput()
    elseif self.currentStep == 4 then
        self:showPreview()
    end
end

function characterCreator:isStepComplete()
    if self.currentStep == 1 then
        return self.selectedJob ~= nil
    elseif self.currentStep == 2 then
        return self.attributePoints == 0
    elseif self.currentStep == 3 then
        return self.charName ~= "" and self.charName ~= "Enter name here..."
    elseif self.currentStep == 4 then
        return true
    end
    return false
end

function characterCreator:createTempChar()
    if not self.selectedJob or self.charName == "" or self.charName == "Enter name here..." then
        return false
    end
    
    -- Format job name for system lookup
    local formattedJobName = self.selectedJob:gsub("%s+", "")
    
    -- Create character
    self.tempChar = characterSystem:new(
        self.charName,
        formattedJobName,
        self.tempAttributes,
        nil,
        self.portraitId
    )
    
    return self.tempChar ~= nil
end

function characterCreator:finishCharacterCreation()
    if self:createTempChar() then
        -- Add character to party
        self.characters[self.currentCharacter] = self.tempChar
        
        -- Check if we need to create more characters
        local nextSlot = nil
        for i = 1, 4 do
            if not self.characters[i] then
                nextSlot = i
                break
            end
        end
        
        if nextSlot then
            -- Move to next character
            self.currentCharacter = nextSlot
            self:resetTempChar()
            self:showJobSelection()
            self:updateCharacterSlots()
        else
            -- All characters created, finish
            self:finishParty()
        end
    end
end

function characterCreator:finishParty()
    -- Save party to game state
    GAME.party = self.characters
    
    -- Initialize game state for new game
    if self.newGame then
        GAME.inventory = {}
        GAME.gold = 100
        
        -- Initialize other game systems as needed
        local itemSystem = require("gameplay/item")
        for _, character in ipairs(self.characters) do
            if character.equipment then
                for slot, item in pairs(character.equipment) do
                    if item then
                        itemSystem:addToInventory(item)
                    end
                end
            end
        end
    end
    
    -- Move to overworld
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

function characterCreator:backToMainMenu()
    local gameState = require("states/gameState")
    gameState:changeState("mainMenu")
end

function characterCreator:wheelmoved(x, y)
    -- Pass to UI elements
    for _, element in pairs(self.elements) do
        if element.visible ~= false and element.wheelmoved then
            if element:wheelmoved(x, y) then
                return true
            end
        end
    end
    
    return false
end

function characterCreator:resetTempChar()
    self.selectedJob = nil
    self.charName = ""
    self.portraitId = nil
    self.tempChar = nil
    self.attributePoints = 20
    
    -- Reset attributes to base values
    for _, attr in ipairs(characterSystem.attributes) do
        self.baseAttributes[attr] = 5
        self.tempAttributes[attr] = 5
    end
    
    -- Update UI
    if self.nameInput then
        self.nameInput.text = ""
    end
    if self.jobDescription then
        self.jobDescription.text = "Select a job to see description"
    end
    if self.pointsLabel then
        self.pointsLabel.text = "Points Remaining: " .. self.attributePoints
    end
    
    self:updateAttributeControls()
end

return characterCreator
