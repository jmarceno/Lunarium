-- UI Functions
-- Functions for creating and managing the combat UI
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local minionManager = require("gameplay/minionManager")
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local partyPanel = require("screens/ui_slices/partyPanel")

local combatSystem = {}  -- Forward declaration

-- Helper function to safely get fonts with fallbacks
local function safeGetFont(fontName)
    if screenManager.fonts and screenManager.fonts[fontName] then
        return screenManager.fonts[fontName]
    elseif screenManager.fonts and screenManager.fonts.small then
        return screenManager.fonts.small
    else
        return love.graphics.getFont()
    end
end

-- Helper functions for UI Refactoring
local function drawListContainer(listElement, title, borderColor)
    if not listElement.visible then return end

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", listElement.x, listElement.y, listElement.width, listElement.height)

    -- Draw border
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3])
    love.graphics.rectangle("line", listElement.x, listElement.y, listElement.width, listElement.height)

    -- Draw title
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, listElement.x + 10, listElement.y + 5)
end

local function isClickInsideList(listElement, x, y)
    if not listElement.visible then return false end
    return x >= listElement.x and x <= listElement.x + listElement.width and
           y >= listElement.y and y <= listElement.y + listElement.height
end

local function drawTooltipContent(tooltipX, tooltipY, tooltipWidth, tooltipHeight, effectInfo, effect)
    -- Draw tooltip background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)

    -- Draw tooltip border
    if effectInfo.statusType == "positive" then
        love.graphics.setColor(0.2, 0.7, 0.3, 0.7)
    elseif effectInfo.statusType == "negative" then
        love.graphics.setColor(0.7, 0.3, 0.2, 0.7)
    else
        love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
    end
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)

    -- Draw effect name
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(effectInfo.name, tooltipX + 10, tooltipY + 10)

    -- Draw effect description
    love.graphics.setFont(safeGetFont("small"))
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf(effectInfo.description, tooltipX + 10, tooltipY + 35, tooltipWidth - 20, "left")

    -- Draw effect duration
    love.graphics.setColor(0.7, 0.7, 1)
    love.graphics.print(
        "Duration: " .. effect.duration .. " turns",
        tooltipX + 10, tooltipY + tooltipHeight - 20
    )
end

local function drawSingleMinionDisplay(minion, slotX, yPos, slotWidth, slotHeight, isCurrentTurnMinion, showCombatStats)
    -- Draw background based on minion type
    if minion.type == "undead" then
        love.graphics.setColor(0.3, 0.1, 0.3, 0.8) -- Dark purple
    elseif minion.type == "elemental" then
        if minion.element == "fire" then
            love.graphics.setColor(0.8, 0.2, 0.1, 0.8) -- Red
        elseif minion.element == "water" then
            love.graphics.setColor(0.1, 0.3, 0.8, 0.8) -- Blue
        elseif minion.element == "earth" then
            love.graphics.setColor(0.5, 0.3, 0.1, 0.8) -- Brown
        elseif minion.element == "air" then
            love.graphics.setColor(0.7, 0.7, 0.9, 0.8) -- Light blue
        else
            love.graphics.setColor(0.2, 0.4, 0.8, 0.8) -- Default blue
        end
    elseif minion.type == "spirit" then
        love.graphics.setColor(0.5, 0.8, 0.5, 0.8) -- Green
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8) -- Gray default
    end
    love.graphics.rectangle("fill", slotX, yPos, slotWidth, slotHeight, 5, 5)

    if isCurrentTurnMinion then
        love.graphics.setColor(1, 1, 0.5, 0.4)
        love.graphics.rectangle("fill", slotX - 2, yPos - 2, slotWidth + 4, slotHeight + 4, 5, 5)
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", slotX, yPos, slotWidth, slotHeight, 5, 5)

    love.graphics.setFont(safeGetFont("small"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(minion.name, slotX + 5, yPos + 5)

    local hpBarWidth = slotWidth - 10
    local hpBarHeight = 8
    local hpPercent = minion.currentHP / minion.maxHP

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", slotX + 5, yPos + 22, hpBarWidth, hpBarHeight)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", slotX + 5, yPos + 22, hpBarWidth * hpPercent, hpBarHeight)
    
    local textY = yPos + 33 -- Starting Y for text below HP bar
    love.graphics.setFont(safeGetFont("small"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. math.floor(minion.currentHP) .. "/" .. math.floor(minion.maxHP), slotX + 5, textY)
    textY = textY + 12

    if showCombatStats then
        if minion.attackPower then
            love.graphics.print("ATK: " .. math.floor(minion.attackPower), slotX + 5, textY)
            textY = textY + 12
        elseif minion.magicPower then
            love.graphics.print("MAG: " .. math.floor(minion.magicPower), slotX + 5, textY)
            textY = textY + 12
        end
    end

    love.graphics.setColor(1, 1, 1)
    if minion.takesActions then
        love.graphics.print("Combat", slotX + 5, textY)
    else
        love.graphics.print("Passive", slotX + 5, textY)
    end
end

local function updateSkillSelectionAndScroll(skillList, newIndex)
    -- Deselect all skills
    for _, s in ipairs(skillList.skills) do
        s.selected = false
    end

    -- Select the new skill
    if skillList.skills[newIndex] then -- Ensure the newIndex is valid
        skillList.skills[newIndex].selected = true
        skillList.selectedIndex = newIndex

        -- Adjust scroll if necessary
        if newIndex <= skillList.scroll then
            skillList.scroll = math.max(0, newIndex - 1)
        elseif newIndex > skillList.scroll + skillList.maxSkillsVisible -1 --Ensure -1 is applied
        then
            skillList.scroll = math.max(0, newIndex - skillList.maxSkillsVisible)
        end
    end
end

-- Create UI elements
local function createUI(self)
    -- Calculate button positions relative to the bottom of the screen
    local partyHeight = 110 -- Height of the party display section (increased from 90)
    local buttonY = GAME.height - partyHeight - 50 -- Move buttons up by 50px from party UI
    local buttonSpacing = 10 -- Space between buttons
    local buttonWidth = 150
    local buttonHeight = 40
    
    -- Calculate starting X position to center the buttons
    local totalButtonWidth = (buttonWidth * 4) + (buttonSpacing * 3)
    local startX = (GAME.width - totalButtonWidth) / 2
    
    -- Action buttons
    self.elements.attackButton = screenManager.UI.Button(
        startX, buttonY, 
        buttonWidth, buttonHeight, "Attack", 
        function() self:selectAction("attack") end
    )
    self.elements.attackButton.visible = true
    
    self.elements.skillButton = screenManager.UI.Button(
        startX + buttonWidth + buttonSpacing, buttonY, 
        buttonWidth, buttonHeight, "Skills", 
        function() self:selectAction("skill") end
    )
    self.elements.skillButton.visible = true
    
    self.elements.itemButton = screenManager.UI.Button(
        startX + (buttonWidth + buttonSpacing) * 2, buttonY, 
        buttonWidth, buttonHeight, "Items", 
        function() self:selectAction("item") end
    )
    self.elements.itemButton.visible = true
    
    self.elements.defendButton = screenManager.UI.Button(
        startX + (buttonWidth + buttonSpacing) * 3, buttonY, 
        buttonWidth, buttonHeight, "Defend", 
        function() self:selectAction("defend") end
    )
    self.elements.defendButton.visible = true
    
    -- Skill list (hidden initially) - Position just above skills button
    self.elements.skillList = {
        visible = false,
        skills = {},
        x = startX + buttonWidth + buttonSpacing, -- Position above skill button
        y = buttonY - 210, -- Position directly above the skill button
        width = 250,
        height = 200,
        selectedIndex = 1, -- Track the selected index
        scroll = 0, -- Current scroll position
        maxSkillsVisible = 7, -- Max number of skills visible at once
        
        draw = function(self)
            if not self.visible then return end
            
            drawListContainer(self, "Skills", {0.5, 0.5, 0.8})
            
            -- Calculate visible range based on scroll
            local startIdx = self.scroll + 1
            local endIdx = math.min(startIdx + self.maxSkillsVisible - 1, #self.skills)
            
            -- Draw skill list
            love.graphics.setFont(safeGetFont("small"))
            for i = startIdx, endIdx do
                local skill = self.skills[i]
                local displayIndex = i - startIdx
                local y = self.y + 30 + displayIndex * 25
                
                -- Highlight selected skill
                if skill.selected then
                    love.graphics.setColor(0.3, 0.3, 0.7)
                    love.graphics.rectangle("fill", self.x + 5, y - 2, self.width - 25, 22) -- Width reduced to make room for scrollbar
                end
                
                -- Draw skill name
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(skill.name, self.x + 10, y)
                
                -- Draw MP cost
                love.graphics.setColor(0.5, 0.5, 1)
                love.graphics.print("MP: " .. skill.mpCost, self.x + 180, y)
            end
            
            -- Draw scrollbar if needed
            if #self.skills > self.maxSkillsVisible then
                -- Draw scrollbar background
                love.graphics.setColor(0.2, 0.2, 0.3)
                love.graphics.rectangle("fill", self.x + self.width - 15, self.y + 30, 10, self.height - 35)
                
                -- Calculate scrollbar size and position
                local scrollBarHeight = math.max(20, (self.maxSkillsVisible / #self.skills) * (self.height - 35))
                local scrollBarY = self.y + 30 + (self.scroll / math.max(1, #self.skills - self.maxSkillsVisible)) * (self.height - 35 - scrollBarHeight)
                
                -- Draw scrollbar handle
                love.graphics.setColor(0.5, 0.5, 0.8)
                love.graphics.rectangle("fill", self.x + self.width - 15, scrollBarY, 10, scrollBarHeight, 3, 3)
            end
        end,
        
        clicked = function(self, x, y)
            if not self.visible then return false end
            
            -- Check if click is within bounds
            if isClickInsideList(self, x, y) then
               
                -- Check if click is on the scrollbar
                if x >= self.x + self.width - 15 and #self.skills > self.maxSkillsVisible then
                    -- Clicked on scrollbar - calculate new scroll position
                    local scrollAreaHeight = self.height - 35
                    local scrollBarHeight = math.max(20, (self.maxSkillsVisible / #self.skills) * scrollAreaHeight)
                    local clickY = y - (self.y + 30)
                    
                    if clickY < 0 then clickY = 0 end
                    if clickY > scrollAreaHeight then clickY = scrollAreaHeight end
                    
                    -- Calculate new scroll position
                    local maxScroll = math.max(0, #self.skills - self.maxSkillsVisible)
                    self.scroll = math.floor((clickY / scrollAreaHeight) * maxScroll)
                    
                    -- Ensure scroll is within bounds
                    if self.scroll < 0 then self.scroll = 0 end
                    if self.scroll > maxScroll then self.scroll = maxScroll end
                    
                    return true
                end
                
                -- Check skill selection
                local startIdx = self.scroll + 1
                local endIdx = math.min(startIdx + self.maxSkillsVisible - 1, #self.skills)
                
                for i = startIdx, endIdx do
                    local displayIndex = i - startIdx
                    local skillY = self.y + 30 + displayIndex * 25
                    
                    if y >= skillY - 2 and y <= skillY + 20 then
                        -- Deselect all skills
                        for _, s in ipairs(self.skills) do
                            s.selected = false
                        end
                        
                        -- Select this skill
                        self.skills[i].selected = true
                        self.selectedIndex = i
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end,
        
        -- Handle wheel scrolling
        wheel = function(self, mouseX, mouseY, x, y)
            if not self.visible then return false end
            
            -- Check if mouse is within bounds
            if mouseX >= self.x and mouseX <= self.x + self.width and
               mouseY >= self.y and mouseY <= self.y + self.height then
               
                -- Scroll up or down based on wheel direction
                local maxScroll = math.max(0, #self.skills - self.maxSkillsVisible)
                if y > 0 then
                    -- Scroll up
                    self.scroll = math.max(0, self.scroll - 1)
                else
                    -- Scroll down
                    self.scroll = math.min(maxScroll, self.scroll + 1)
                end
                
                return true
            end
            
            return false
        end,
        
        -- Handle WASD navigation
        keypressed = function(self, key)
            if not self.visible or #self.skills == 0 then return false end
            
            if key == "w" or key == "up" then
                -- Move selection up
                local newIndex = self.selectedIndex - 1
                if newIndex < 1 then newIndex = #self.skills end
                updateSkillSelectionAndScroll(self, newIndex)
                return true
            elseif key == "s" or key == "down" then
                -- Move selection down
                local newIndex = self.selectedIndex + 1
                if newIndex > #self.skills then newIndex = 1 end
                updateSkillSelectionAndScroll(self, newIndex)
                return true
            end
            
            return false
        end
    }
    
    -- Item list (hidden initially)
    self.elements.itemList = {
        visible = false,
        items = {},
        x = startX + (buttonWidth + buttonSpacing) * 2, -- Position above items button
        y = buttonY - 210, -- Position directly above the items button
        width = 250,
        height = 200,
        
        draw = function(self)
            if not self.visible then return end
            
            drawListContainer(self, "Items", {0.5, 0.8, 0.5})
            
            -- Draw item list
            love.graphics.setFont(safeGetFont("small"))
            for i, item in ipairs(self.items) do
                local y = self.y + 30 + (i - 1) * 25
                
                -- Highlight selected item
                if item.selected then
                    love.graphics.setColor(0.3, 0.7, 0.3)
                    love.graphics.rectangle("fill", self.x + 5, y - 2, self.width - 10, 22)
                end
                
                -- Draw item name
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(item.name, self.x + 10, y)
                
                -- Draw count if available
                if item.count and item.count > 1 then
                    love.graphics.print("x" .. item.count, self.x + 180, y)
                end
            end
        end,
        
        clicked = function(self, x, y)
            if not self.visible then return false end
            
            -- Check if click is within bounds
            if isClickInsideList(self, x, y) then
               
                -- Check if click is within bounds
                for i, item in ipairs(self.items) do
                    local itemY = self.y + 30 + (i - 1) * 25
                    
                    if y >= itemY - 2 and y <= itemY + 20 then
                        -- Deselect all items
                        for _, s in ipairs(self.items) do
                            s.selected = false
                        end
                        
                        -- Select this item
                        item.selected = true
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Party member selection list (for single_ally targeted skills/items)
    self.elements.partySelectList = {
        visible = false,
        x = startX, -- Position above attack button
        y = buttonY - 210, -- Position directly above the attack button
        width = 250,
        height = 200,
        selectedIndex = nil,
        combatRef = self, -- Store reference to the combat instance
        
        draw = function(self)
            if not self.visible then return end
            
            drawListContainer(self, "Select Target", {0.5, 0.7, 0.8})
            
            -- Draw party member list
            love.graphics.setFont(safeGetFont("small"))
            
            -- Use the stored combat reference
            local party = self.combatRef.party
            
            -- Draw each party member that is active
            for i, character in ipairs(party) do
                if character.active then
                    local y = self.y + 30 + (i - 1) * 25
                    
                    -- Highlight selected character
                    if self.selectedIndex == i then
                        love.graphics.setColor(0.3, 0.5, 0.7)
                        love.graphics.rectangle("fill", self.x + 5, y - 2, self.width - 10, 22)
                    end
                    
                    -- Draw character name
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(character.name, self.x + 10, y)
                    
                    -- Draw HP info
                    love.graphics.setColor(0.8, 0.3, 0.3)
                    love.graphics.print("HP: " .. character.currentHP .. "/" .. character.maxHP, self.x + 120, y)
                end
            end
        end,
        
        clicked = function(self, x, y)
            if not self.visible then return false end
            
            -- Check if click is within bounds
            if isClickInsideList(self, x, y) then
               
                -- Use the stored combat reference
                local party = self.combatRef.party
                local activeIndex = 0
                
                for i, character in ipairs(party) do
                    if character.active then
                        activeIndex = activeIndex + 1
                        local memberY = self.y + 30 + (i - 1) * 25
                        
                        if y >= memberY - 2 and y <= memberY + 20 then
                            -- Select this party member
                            self.selectedIndex = i
                            print("Selected party member: " .. party[i].name .. " (index: " .. i .. ")")
                            
                            -- Auto-confirm the selection if needed
                            if self.combatRef.settings and self.combatRef.settings.autoConfirmSelection then
                                -- Auto-confirm after a short delay
                                self.combatRef:confirmPartySelection()
                            end
                            
                            return true
                        end
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Confirm button (for skills/items)
    self.elements.confirmButton = screenManager.UI.Button(
        self.elements.skillList.x + self.elements.skillList.width + 10, 
        self.elements.skillList.y, 
        120, 40, "Confirm", 
        function() self:confirmAction() end
    )
    self.elements.confirmButton.visible = false
    
    -- Back button (for skills/items)
    self.elements.backButton = screenManager.UI.Button(
        self.elements.skillList.x + self.elements.skillList.width + 10, 
        self.elements.skillList.y + 50, -- Keep this position
        120, 40, "Back", 
        function() self:cancelSelection() end
    )
    self.elements.backButton.visible = true
    
    -- Store original positions of confirm and back buttons for item panel
    self.elements.itemConfirmButton = screenManager.UI.Button(
        self.elements.itemList.x - 130, -- Position to the left of item list
        self.elements.itemList.y, -- Same y as item list
        120, 40, "Confirm", 
        function() self:confirmAction() end
    )
    self.elements.itemConfirmButton.visible = false
    
    self.elements.itemBackButton = screenManager.UI.Button(
        self.elements.itemList.x - 130, -- Position to the left of item list
        self.elements.itemList.y + 50, -- 50px below confirm button
        120, 40, "Back", 
        function() 
            -- DIRECT FORCED CLEANUP: Hide all item UI elements directly
            self.elements.itemList.visible = false
            self.elements.itemConfirmButton.visible = false
            self.elements.itemBackButton.visible = false
            
            -- Reset selection state
            self.selectedAction = nil
            self.selectedItem = nil
            
            -- Show action buttons again
            self:showActionButtons()
        end
    )
    self.elements.itemBackButton.visible = false
end

-- Draw action meter progress bars for all entities
local function drawActionMeterBars(self)
    -- Only draw if we have a turn manager
    if not self.turnManager then return end
    
    -- Get all entity status from turn manager
    local entityStatus = self.turnManager:getAllEntityStatus()
    if #entityStatus == 0 then return end
    
    -- Position above the spell queue - reduced width by 25%
    local queueX = GAME.width - 230  -- Reduced from 300 to 230
    local queueY = 20
    local queueWidth = 210  -- Reduced from 280 to 210 (25% reduction)
    local itemHeight = 35
    local spacing = 3
    
    -- Calculate total height
    local totalHeight = (itemHeight + spacing) * #entityStatus + 20
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", queueX, queueY, queueWidth, totalHeight, 5, 5)
    
    -- Draw border
    love.graphics.setColor(0.6, 0.4, 0.8, 0.7)
    love.graphics.rectangle("line", queueX, queueY, queueWidth, totalHeight, 5, 5)
    
    -- Check if any entity is paused to add to title
    local anyPaused = false
    for _, status in ipairs(entityStatus) do
        if status.isPaused then
            anyPaused = true
            break
        end
    end
    
    -- Draw title with font safety check, include PAUSED if needed
    local titleFont = safeGetFont("medium") or safeGetFont("small") or love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Action Meters"
    if anyPaused then
        titleText = "Action Meters"
    end
    love.graphics.print(titleText, queueX + 10, queueY + 5)
    
    -- Draw each entity's action meter
    for i, status in ipairs(entityStatus) do
        local itemY = queueY + 25 + (i-1) * (itemHeight + spacing)
        
        -- Choose color based on entity type
        local nameColor = {1, 1, 1}
        if status.type == "player" then
            nameColor = {0.5, 0.8, 1}
        elseif status.type == "enemy" then
            nameColor = {1, 0.5, 0.5}
        elseif status.type == "minion" then
            nameColor = {0.8, 1, 0.5}
        end
        
        -- Draw entity name with font safety check
        local nameFont = safeGetFont("small") or love.graphics.getFont()
        love.graphics.setFont(nameFont)
        love.graphics.setColor(nameColor[1], nameColor[2], nameColor[3])
        love.graphics.print(status.entity.name, queueX + 10, itemY)
        
        -- Draw progress bar background
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", queueX + 10, itemY + 15, queueWidth - 20, 10)
        
        -- Draw progress bar fill
        local fillColor = {0.2, 0.6, 0.8} -- Default blue
        if status.isReady then
            fillColor = {0.2, 1, 0.2} -- Green when ready
        elseif status.isPaused then
            fillColor = {0.8, 0.8, 0.2} -- Yellow when paused
        end
        
        love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3])
        love.graphics.rectangle("fill", queueX + 10, itemY + 15, (queueWidth - 20) * status.progress, 10)
        
        -- Draw status text with font safety check - no more individual PAUSED text
        love.graphics.setColor(1, 1, 1)
        local statusFont = safeGetFont("tiny") or safeGetFont("small") or love.graphics.getFont()
        love.graphics.setFont(statusFont)
        local statusText = ""
        if status.isReady then
            statusText = "READY"
        else
            statusText = string.format("%.1f%%", status.progress * 100)
        end
        love.graphics.print(statusText, queueX + queueWidth - 50, itemY)
    end
end

-- Draw spell queue progress bars
local function drawSpellQueue(self)
    if #self.spellQueue == 0 then return end
    
    -- Position below action meters (if they exist) - updated to match new action meter width
    local queueX = GAME.width - 230  -- Changed from 300 to 230 to match action meters
    local baseY = 20
    
    -- Adjust position if action meters are being drawn
    if self.turnManager then
        local entityStatus = self.turnManager:getAllEntityStatus()
        if #entityStatus > 0 then
            local actionMeterHeight = (#entityStatus * 38) + 20  -- 35 + 3 spacing, plus padding
            baseY = baseY + actionMeterHeight + 10 -- 10px gap between action meters and spell queue
        end
    end
    
    local queueY = baseY
    local queueWidth = 210  -- Changed from 280 to 210 to match action meters
    local itemHeight = 40
    local spacing = 5
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", queueX, queueY, queueWidth, (itemHeight + spacing) * #self.spellQueue + 10, 5, 5)
    
    -- Draw border
    love.graphics.setColor(0.4, 0.6, 0.8, 0.7)
    love.graphics.rectangle("line", queueX, queueY, queueWidth, (itemHeight + spacing) * #self.spellQueue + 10, 5, 5)
    
    -- Draw title with font safety check
    local titleFont = safeGetFont("medium") or safeGetFont("small") or love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Spell Queue", queueX + 10, queueY + 5)
    
    -- Draw each spell in the queue
    for i, spell in ipairs(self.spellQueue) do
        local itemY = queueY + 30 + (i-1) * (itemHeight + spacing)
        
        -- Draw spell name and caster with font safety check
        local spellFont = safeGetFont("small") or love.graphics.getFont()
        love.graphics.setFont(spellFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(spell.caster.name .. " - " .. spell.skill.name, queueX + 10, itemY)
        
        -- Calculate progress percentage for new time-based system
        local progressPercent = 0
        if spell.totalCastingTime > 0 then
            progressPercent = (spell.totalCastingTime - spell.castingTimeRemaining) / spell.totalCastingTime
        end
        
        -- Draw progress bar background
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", queueX + 10, itemY + 20, queueWidth - 20, 12)
        
        -- Draw progress bar fill
        if spell.completionStarted then
            -- Flash between yellow and green when complete
            if spell.flashState then
                love.graphics.setColor(1, 1, 0.2, 0.8) -- Yellow
            else
                love.graphics.setColor(0.2, 1, 0.2, 0.8) -- Green
            end
        else
            love.graphics.setColor(0.2, 0.8, 0.6) -- Normal teal
        end
        love.graphics.rectangle("fill", queueX + 10, itemY + 20, (queueWidth - 20) * progressPercent, 12)
        
        -- Draw progress text
        love.graphics.setColor(1, 1, 1)
        if spell.completionStarted then
            -- Show CASTING... during the visual effect phase
            love.graphics.print("CASTING...", queueX + 10, itemY + 19)
        else
            -- Show remaining time in seconds
            love.graphics.print(string.format("%.1fs", spell.castingTimeRemaining), 
                            queueX + queueWidth - 40, itemY + 19)
        end
    end
end

-- Draw victory prompt in the center of the screen
local function drawVictoryPrompt(self)
    if not self.showVictoryPrompt then return end
    
    -- Draw semi-transparent overlay for the prompt
    love.graphics.setColor(0, 0, 0, 0.6)
    local promptWidth = 500
    local promptHeight = 80
    local promptX = (GAME.width - promptWidth) / 2
    local promptY = 150 -- Above the character turn display
    love.graphics.rectangle("fill", promptX, promptY, promptWidth, promptHeight, 10, 10)
    
    -- Draw victory message with font safety check
    local victoryFont = safeGetFont("medium") or safeGetFont("small") or love.graphics.getFont()
    love.graphics.setFont(victoryFont)
    
    -- Draw with a glow effect
    local time = love.timer.getTime()
    local brightness = 0.7 + 0.3 * math.sin(time * 3) -- Pulsing brightness
    love.graphics.setColor(1 * brightness, 1 * brightness, 0.2 * brightness)
    
    local text = "All enemies defeated! Press any key to continue..."
    local textWidth = victoryFont:getWidth(text)
    love.graphics.print(text, promptX + (promptWidth - textWidth) / 2, promptY + 30)
 end

local function draw(self)
    -- We no longer draw the background here as it's handled by the raycaster in combatSystem
    -- DO NOT draw: love.graphics.setColor(0.2, 0.2, 0.3); love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw based on current state
    if self.state == combatSystem.STATE.VICTORY then
        self:drawVictoryUI()
        
        -- Draw continue button - no need to check if it exists since drawVictoryUI ensures it
        if self.elements.continueButton then
            self.elements.continueButton:draw()
        end
    elseif self.state == combatSystem.STATE.DEFEAT then
        self:drawDefeatUI()
        
        -- Draw continue button if it exists
        if self.elements.continueButton then
            self.elements.continueButton:draw()
        end
    else
        -- Draw regular combat UI
    
        -- Draw UI elements for enemy info (health bars, status, etc.)
        -- Note: Actual enemy sprites are now rendered by the raycaster
        self:drawEnemy()
        
        -- Draw party
        self:drawParty()
        
        -- Draw victory prompt if all enemies defeated
        if self.showVictoryPrompt then
            self:drawVictoryPrompt()
        end
        
        -- Draw UI based on current turn state
        if self.state == combatSystem.STATE.PLAYER_TURN then
            self:drawPlayerTurnUI()
        elseif self.state == combatSystem.STATE.ENEMY_TURN then
            self:drawEnemyTurnUI()
        end
        
        -- Draw select lists if visible
        for _, element in pairs(self.elements) do
            if element.visible then
                element:draw()
            end
        end
        
        -- Draw status effect tooltips for any hovered effect icons
        self:drawStatusEffectTooltips()
        
        -- Draw combat log
        self:drawCombatLog()
        
        -- Draw action meter bars
        drawActionMeterBars(self)
        
        -- Draw spell queue
        drawSpellQueue(self)
        
        -- Draw floating combat text
        if self.floatingTexts then
            for i = #self.floatingTexts, 1, -1 do
                local floatingText = self.floatingTexts[i]
                floatingText:draw()
            end
        end
    end
    
    -- Draw minions
    if self.state ~= combatSystem.STATE.VICTORY and self.state ~= combatSystem.STATE.DEFEAT then
        self:drawMinions()
    end
end

-- Draw enemy information (health bars, status effects, etc.)
local function drawEnemy(self)
    -- For multiple enemies, arrange them in a grid
    if #self.enemies > 1 then
        self:drawMultipleEnemies()
    else
        -- Original single enemy display
        self:drawSingleEnemy(self.enemies[1], GAME.width / 2 - 100, 50)
    end
end

-- Draw multiple enemies' UI elements (not the sprites)
local function drawMultipleEnemies(self)
    -- Calculate grid layout based on number of enemies
    local maxRows = 2 -- Maximum number of rows
    local maxEnemiesFirstRow = 3 -- Max 3 enemies in the first row
    
    local firstRowCount = math.min(maxEnemiesFirstRow, #self.enemies)
    local secondRowCount = math.min(#self.enemies - firstRowCount, 2) -- Max 2 enemies in second row
    
    -- Calculate dimensions for each enemy display area
    local enemyWidth = 240 -- Increased from 200 to add more space between enemies
    local enemyHeight = 150 -- Reduced from 300 to save space, we don't draw the sprites
    
    -- Draw enemies in first row (up to 3)
    for i = 1, firstRowCount do
        local enemy = self.enemies[i]
        -- Center the enemies in first row
        local rowWidth = firstRowCount * enemyWidth
        local startX = (GAME.width - rowWidth) / 2
        local x = startX + (i-1) * enemyWidth + (enemyWidth/2) - 100 -- Center in space
        local y = 30 -- Top row position
        
        -- Highlight currently active enemy 
        if self.state == combatSystem.STATE.ENEMY_TURN and i == self.activeEnemyIndex then
            love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
            love.graphics.rectangle("fill", x - 10, y - 10, 220, enemyHeight - 20, 5, 5)
        end
        
        -- Highlight selected enemy for targeting
        if self.selectedTarget == enemy then
            love.graphics.setColor(0.1, 0.5, 0.1, 0.3)
            love.graphics.rectangle("fill", x - 10, y - 10, 220, enemyHeight - 20, 5, 5)
        end
        
        -- Draw individual enemy UI
        self:drawSingleEnemy(enemy, x, y)
    end
    
    -- Draw enemies in second row (up to 2) - centered
    if secondRowCount > 0 then
        local rowWidth = secondRowCount * enemyWidth
        local startX = (GAME.width - rowWidth) / 2
        
        for i = 1, secondRowCount do
            local enemyIndex = firstRowCount + i
            local enemy = self.enemies[enemyIndex]
            
            local x = startX + (i-1) * enemyWidth + (enemyWidth/2) - 100 -- Center in space
            local y = 110 -- Second row position (adjusted from 200 to be closer to first row)
            
            -- Highlight currently active enemy 
            if self.state == combatSystem.STATE.ENEMY_TURN and enemyIndex == self.activeEnemyIndex then
                love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
                love.graphics.rectangle("fill", x - 10, y - 10, 220, enemyHeight - 20, 5, 5)
            end
            
            -- Highlight selected enemy for targeting
            if self.selectedTarget == enemy then
                love.graphics.setColor(0.1, 0.5, 0.1, 0.3)
                love.graphics.rectangle("fill", x - 10, y - 10, 220, enemyHeight - 20, 5, 5)
            end
            
            -- Draw individual enemy UI
            self:drawSingleEnemy(enemy, x, y)
        end
    end
end

-- Draw a single enemy's UI elements (health bar, status, etc.)
local function drawSingleEnemy(self, enemy, x, y)
    -- Draw background for enemy info for better readability
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x - 5, y - 5, 210, 100, 5, 5)
    
    -- Draw enemy name
    love.graphics.setFont(safeGetFont("medium")) -- Changed from large to medium
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.print(enemy.name, x, y)
    
    -- Draw enemy health bar
    local healthWidth = 200 * (enemy.currentHP / enemy.maxHP)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y + 30, 200, 20) -- Moved up from y+40
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y + 30, healthWidth, 20) -- Moved up from y+40
    
    -- Draw HP text
    love.graphics.setFont(safeGetFont("small"))
    love.graphics.setColor(1, 1, 1)
    
    -- Display HP values directly - should never be nil
    love.graphics.print(
        enemy.currentHP .. " / " .. enemy.maxHP,
        x + 90, y + 32 -- Adjusted from y+42
    )
    
    -- Draw small target indicator if selected
    if self.selectedTarget == enemy then
        love.graphics.setColor(0.1, 0.8, 0.1, 0.7)
        love.graphics.circle("fill", x + 100, y + 65, 10)
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.circle("line", x + 100, y + 65, 10)
    end
    
    -- Draw status effects using the helper function
    if enemy and enemy.status and next(enemy.status) then
        local uiHelpers = require("gameplay/combat/uiHelpers")
        uiHelpers.drawStatusEffects(enemy, x, y + 65, 22, 5) -- Moved up from y+195
    end
    
    -- Draw resistances/vulnerabilities if this is the selected target
    if enemy and self.selectedTarget == enemy and enemy.resistances then
        -- Create a small panel for resistances to make them readable
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x + 210, y, 120, 100, 5, 5)
        
        love.graphics.setFont(safeGetFont("small"))
        love.graphics.setColor(1, 1, 1, 0.8)
        
        local resistY = y + 5 -- Start at top of resistance panel
        love.graphics.print("Resistances:", x + 215, resistY)
        resistY = resistY + 15
        
        -- Get notable resistances/vulnerabilities (those with significant values)
        local count = 0
        for damageType, value in pairs(enemy.resistances) do
            if math.abs(value) >= 20 and count < 4 then -- Only show significant resistances/vulnerabilities, limit to 4
                count = count + 1
                if value < 0 then
                    love.graphics.setColor(0.4, 0.8, 0.4) -- Green for resistance
                    love.graphics.print(damageType .. " " .. value .. "%", x + 215, resistY)
                else
                    love.graphics.setColor(0.8, 0.4, 0.4) -- Red for vulnerability
                    love.graphics.print(damageType .. " +" .. value .. "%", x + 215, resistY)
                end
                resistY = resistY + 15
            end
        end
        
        -- Show immunities if any
        if enemy.immunities and #enemy.immunities > 0 then
            resistY = resistY + 5
            love.graphics.setColor(0.8, 0.8, 0.2)
            love.graphics.print("Immune:", x + 215, resistY)
            resistY = resistY + 15
            
            for i = 1, math.min(2, #enemy.immunities) do -- Limit to 2 immunities
                love.graphics.print("- " .. enemy.immunities[i], x + 215, resistY)
                resistY = resistY + 15
            end
        end
    end
end

-- Draw party information
local function drawParty(self)
    -- Configure party panel for combat
    partyPanel:setCombatMode(true, self.party)
    
    -- Set the active character based on current state
    if self.state == combatSystem.STATE.PLAYER_TURN then
        partyPanel:setActiveCharacter(self.currentCharacter)
    else
        partyPanel:setActiveCharacter(nil)
    end
    
    -- Draw the party panel
    partyPanel:draw()
end

-- Draw combat log
local function drawCombatLog(self)
    -- Position in bottom right corner, above the party panel
    local panelHeight = partyPanel.height
    local logWidth = 260
    local logHeight = 230
    local logX = GAME.width - logWidth - 20 -- 20px margin from right edge
    local logY = GAME.height - panelHeight - logHeight - 20 -- Above party panel with 20px gap
    
    -- Draw log background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", logX, logY, logWidth, logHeight, 5, 5) -- Added rounded corners
    
    -- Draw log border
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("line", logX, logY, logWidth, logHeight, 5, 5)
    
    -- Draw log title
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Combat Log", logX + 10, logY + 5)
    
    -- Draw log entries
    love.graphics.setFont(safeGetFont("small"))
    
    -- Calculate line height - double the font height to prevent overlap completely
    local fontHeight = love.graphics.getFont():getHeight()
    local lineHeight = fontHeight * 2 -- Double the line height
    
    -- Calculate how many entries can fit
    local entriesVisible = math.floor((logHeight - 30) / lineHeight) -- 30px for header
    local startIndex = math.max(1, #self.log - entriesVisible + 1)
    
    for i = startIndex, #self.log do
        local entry = self.log[i]
        local y = logY + 30 + (i - startIndex) * lineHeight
        
        love.graphics.setColor(entry.color or {1, 1, 1})
        
        -- Add text wrapping - max width is logWidth - 20 (for margins)
        local textWidth = logWidth - 20
        love.graphics.printf(entry.text, logX + 10, y, textWidth, "left")
    end
end

-- Draw UI for player turn
local function drawPlayerTurnUI(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar then return end
    
    -- Draw turn info - centered above the buttons
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 1)
    
    -- Position turn text higher to avoid overlap
    local buttonY = self.elements.attackButton.y
    local turnTextY = buttonY - 60 -- Increased from 40 to 60
    
    -- Create a background panel for the turn text for better visibility
    local turnText = currentChar.name .. "'s Turn"
    local textWidth = love.graphics.getFont():getWidth(turnText)
    local textX = GAME.width / 2 - textWidth / 2
    
    -- Draw text background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", textX - 10, turnTextY - 5, textWidth + 20, 30, 5, 5)
    
    -- Draw text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(turnText, textX, turnTextY)
    
    -- Draw UI based on whether an action is selected
    if not self.selectedAction then
        -- No action selected - show action buttons
        -- Make sure action buttons are visible
        self:showActionButtons()
        
        -- Draw the buttons
        self.elements.attackButton:draw()
        self.elements.skillButton:draw()
        self.elements.itemButton:draw()
        self.elements.defendButton:draw()
        
        -- Hide confirm and back buttons since no action is selected
        self.elements.confirmButton.visible = false
        self.elements.backButton.visible = false
    else
        -- Action is selected - hide action buttons and show selection UI
        self:hideActionButtons()
        
        -- Debug: Show the current state
        if GAME.debug then
            print("Selection UI state:")
            print("  Selected action: " .. self.selectedAction)
            print("  Skill list visible: " .. tostring(self.elements.skillList.visible))
            print("  Item list visible: " .. tostring(self.elements.itemList.visible))
            print("  Party list visible: " .. tostring(self.elements.partySelectList.visible))
            if self.elements.enemySelectList then
                print("  Enemy list visible: " .. tostring(self.elements.enemySelectList.visible))
            end
        end
        
        -- Draw confirm and back buttons for skill/item selection only
        if self.elements.skillList.visible then
            -- For skill selection, use the regular positions
            self.elements.confirmButton.visible = true
            self.elements.backButton.visible = true
            
            -- Make sure the back button is in its original position
            self.elements.backButton.x = self.elements.skillList.x + self.elements.skillList.width + 10
            self.elements.backButton.y = self.elements.skillList.y + 50
            
            self.elements.confirmButton:draw()
            self.elements.backButton:draw()
            
            -- Hide item-specific buttons
            self.elements.itemConfirmButton.visible = false
            self.elements.itemBackButton.visible = false
        elseif self.elements.itemList.visible then
            -- For item selection, use the item-specific buttons
            if self.elements.itemConfirmButton then
                self.elements.itemConfirmButton.visible = true
                self.elements.itemConfirmButton:draw()
            end
            
            if self.elements.itemBackButton then
                self.elements.itemBackButton.visible = true
                self.elements.itemBackButton:draw()
            end
            
            -- Hide regular confirm/back buttons
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = false
        elseif self.elements.partySelectList.visible then
            -- For party selection, use the regular back button only (auto-confirm enabled)
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = true
            self.elements.backButton:draw()
            
            -- Hide item-specific buttons
            self.elements.itemConfirmButton.visible = false
            self.elements.itemBackButton.visible = false
        elseif self.elements.enemySelectList and self.elements.enemySelectList.visible then
            -- For enemy selection, use the regular back button only (auto-confirm enabled)
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = true
            self.elements.backButton:draw()
            
            -- Hide item-specific buttons
            self.elements.itemConfirmButton.visible = false
            self.elements.itemBackButton.visible = false
        end
    end
end

-- Draw UI for enemy turn state
local function drawEnemyTurnUI(self)
    -- Get where the action buttons would be
    local partyHeight = 90 -- Height of the party display section
    local buttonY = GAME.height - partyHeight - 50 -- Same as in createUI
    local turnTextY = buttonY - 40
    
    -- Draw "Enemy Turn" text centered
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 0.5, 0.5)
    
    local turnText = "Enemy Turn"
    local textWidth = love.graphics.getFont():getWidth(turnText)
    local textX = GAME.width / 2 - textWidth / 2
    
    love.graphics.print(turnText, textX, turnTextY)
    
    -- Show a "Waiting..." message below it
    love.graphics.setFont(safeGetFont("small"))
    love.graphics.setColor(1, 1, 1, 0.7)
    
    local waitText = "Waiting for enemy action..."
    local waitWidth = love.graphics.getFont():getWidth(waitText)
    local waitX = GAME.width / 2 - waitWidth / 2
    
    love.graphics.print(waitText, waitX, turnTextY + 25)
end

-- Draw UI for victory state
local function drawVictoryUI(self)
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw victory message
    love.graphics.setFont(safeGetFont("large"))
    love.graphics.setColor(1, 1, 1)
    local text = "VICTORY!"
    local textWidth = safeGetFont("large"):getWidth(text)
    love.graphics.print(text, (love.graphics.getWidth() - textWidth) / 2, love.graphics.getHeight() / 3)
    
    -- Draw rewards summary
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 0.5)
    local rewardsText = "You defeated all enemies!"
    local rewardsWidth = safeGetFont("medium"):getWidth(rewardsText)
    love.graphics.print(rewardsText, (love.graphics.getWidth() - rewardsWidth) / 2, love.graphics.getHeight() / 2)
    
    -- Draw continue prompt with blinking effect
    local time = love.timer.getTime()
    local alpha = 0.5 + 0.5 * math.sin(time * 3)  -- Blinking effect
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 1, alpha)
    local prompt = "Press SPACE, ENTER, Z, or X to continue..."
    local promptWidth = safeGetFont("medium"):getWidth(prompt)
    love.graphics.print(prompt, (love.graphics.getWidth() - promptWidth) / 2, love.graphics.getHeight() * 2/3)
end

-- Draw UI for defeat state
local function drawDefeatUI(self)
    -- Darken background for readability
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw defeat message
    love.graphics.setFont(safeGetFont("large"))
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.printf(
        "Defeat!",
        GAME.width / 2 - 200, GAME.height / 2 - 50,
        400, "center"
    )
    
    -- Draw "Press Enter to continue" text
    love.graphics.setFont(safeGetFont("medium"))
    love.graphics.setColor(1, 1, 1, 0.7 + math.sin(love.timer.getTime() * 4) * 0.3)
    love.graphics.printf(
        "Press Enter to continue",
        GAME.width / 2 - 200, GAME.height / 2 + 50,
        400, "center"
    )

    -- Ensure continue button is created for defeat state too (if not already)
    if not self.elements.continueButton then
        self.elements.continueButton = screenManager.UI.Button(
            GAME.width / 2 - 60, GAME.height / 2 + 100, 
            120, 40, "Continue", 
            function() self:endCombat(false) end -- false for defeat
        )
    end
    self.elements.continueButton.visible = true -- Make sure it's visible
end

-- Show enemy selection UI for targeting
local function showEnemySelectionUI(self, actionType)
    -- Create enemy selection UI if it doesn't exist
    if not self.elements.enemySelectList then
        self.elements.enemySelectList = {
            visible = false,
            x = self.elements.attackButton.x, -- Position above attack button
            y = self.elements.attackButton.y - 210, -- Position directly above the attack button
            width = 250,
            height = 200,
            selectedIndex = nil,
            combatRef = self, -- Store reference to the combat instance
            
            draw = function(self)
                if not self.visible then return end
                
                drawListContainer(self, "Select Target", {0.8, 0.5, 0.5})
                
                -- Draw enemy list
                love.graphics.setFont(safeGetFont("small"))
                
                -- Use the stored combat reference
                local enemies = self.combatRef.enemies
                
                -- Draw each active enemy
                for i, enemy in ipairs(enemies) do
                    if enemy.active then
                        local y = self.y + 30 + (i - 1) * 25
                        
                        -- Highlight selected enemy
                        if self.selectedIndex == i then
                            love.graphics.setColor(0.7, 0.3, 0.3)
                            love.graphics.rectangle("fill", self.x + 5, y - 2, self.width - 10, 22)
                        end
                        
                        -- Draw enemy name
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print(enemy.name, self.x + 10, y)
                        
                        -- Draw HP info - moved more to the right
                        love.graphics.setColor(0.8, 0.3, 0.3)
                        love.graphics.print("HP: " .. enemy.currentHP .. "/" .. enemy.maxHP, self.x + 140, y) -- Moved from 120 to 140
                    end
                end
            end,
            
            clicked = function(self, x, y)
                if not self.visible then return false end
                
                -- Check if click is within bounds
                if isClickInsideList(self, x, y) then
                   
                    -- Use the stored combat reference
                    local enemies = self.combatRef.enemies
                    
                    for i, enemy in ipairs(enemies) do
                        if enemy.active then
                            local enemyY = self.y + 30 + (i - 1) * 25
                            
                            if y >= enemyY - 2 and y <= enemyY + 20 then
                                -- Select this enemy
                                self.selectedIndex = i
                                if GAME.debug then
                                    print("Selected enemy: " .. enemies[i].name .. " (index: " .. i .. ")")
                                end
                                
                                -- Auto-confirm the selection if needed
                                if self.combatRef.settings and self.combatRef.settings.autoConfirmSelection then
                                    -- Auto-confirm after a short delay
                                    self.combatRef:confirmEnemySelection()
                                end
                                
                                return true
                            end
                        end
                    end
                    
                    return true
                end
                
                return false
            end
        }
    end
    
    -- Reset selection
    self.elements.enemySelectList.selectedIndex = nil
    
    -- Show enemy selection list
    self.elements.enemySelectList.visible = true
    
    -- Store the action type for later reference
    self.enemySelectionActionType = actionType
    
    -- Since we're using auto-confirm, we only need the back button
    self.elements.confirmButton.visible = false
    
    -- Position the back button to the left of the enemy selection list
    self.elements.backButton.x = self.elements.enemySelectList.x - self.elements.backButton.width - 10
    self.elements.backButton.y = self.elements.enemySelectList.y
    self.elements.backButton.visible = true
end

-- Confirm enemy selection
local function confirmEnemySelection(self)
    -- Make sure enemy selection list exists and has a selectedIndex
    if not self.elements.enemySelectList then
        print("Warning: Enemy selection list is missing")
        return
    end
    
    local selectedIndex = self.elements.enemySelectList.selectedIndex
    
    -- Check if an enemy was selected
    if not selectedIndex then
        self:addLog("No target selected.", {1, 0.5, 0})
        return
    end
    
    -- Set the selected enemy as the target
    self.selectedTarget = self.enemies[selectedIndex]
    
    -- Hide all UI elements and clear state
    self:hideSelectionLists()
    
    -- Execute the action based on type
    if self.enemySelectionActionType == "attack" then
        self:executePlayerAction()
    elseif self.enemySelectionActionType == "skill" then
        self:executeSkill()
    end
    
    -- Reset enemy selection tracking
    self.enemySelectionActionType = nil
end

-- Show skill list for current character
local function showSkillList(self)
    local currentChar = self.party[self.currentCharacter]
    if not currentChar then return end
    
    -- Prepare skill list
    self.elements.skillList.skills = {}
    
    -- Reset scroll and selection
    self.elements.skillList.scroll = 0
    self.elements.skillList.selectedIndex = 1
    
    -- Add skills from character
    for skillName, skillInfo in pairs(currentChar.skills) do
        local skill = skillSystem:getSkill(skillName)
        if skill then
            -- Check if enough MP
            local usable = currentChar.currentMP >= skill.mpCost
            
            table.insert(self.elements.skillList.skills, {
                name = skill.name,
                mpCost = skill.mpCost,
                skill = skill,
                usable = usable,
                selected = false
            })
        end
    end
    
    -- Sort by name
    table.sort(self.elements.skillList.skills, function(a, b)
        return a.name < b.name
    end)
    
    -- Select the first skill if available
    if #self.elements.skillList.skills > 0 then
        self.elements.skillList.skills[1].selected = true
    end
    
    -- Show skill list
    self.elements.skillList.visible = true
    
    -- Update confirm button callback to standard confirmation
    self.elements.confirmButton.callback = function()
        self:confirmAction()
    end
    
    -- Make sure buttons are visible
    self.elements.confirmButton.visible = true
    self.elements.backButton.visible = true
end

-- Show item list
local function showItemList(self)
    -- First hide all selection UIs and buttons to ensure a clean state
    self:hideSelectionLists()
    
    -- Hide standard buttons to avoid conflicts
    self.elements.confirmButton.visible = false
    self.elements.backButton.visible = false
    
    -- Prepare item list
    self.elements.itemList.items = {}
    
    -- Get consumable items from inventory
    if GAME.inventory then
        for _, item in ipairs(GAME.inventory) do
            if item.type == "consumable" then
                table.insert(self.elements.itemList.items, {
                    name = item.name,
                    item = item,
                    count = item.count or 1,
                    selected = false
                })
            end
        end
    end
    
    -- Sort by name
    table.sort(self.elements.itemList.items, function(a, b)
        return a.name < b.name
    end)
    
    -- Show item list
    self.elements.itemList.visible = true
    
    -- Show item-specific buttons only
    if self.elements.itemConfirmButton then
        self.elements.itemConfirmButton.visible = true
        self.elements.itemConfirmButton.callback = function()
            self:confirmAction()
        end
    end
    
    if self.elements.itemBackButton then
        self.elements.itemBackButton.visible = true
        self.elements.itemBackButton.callback = function()
            -- Clear selected items
            for _, item in ipairs(self.elements.itemList.items) do
                item.selected = false
            end
            
            -- Hide all item UI
            self.elements.itemList.visible = false
            self.elements.itemConfirmButton.visible = false
            self.elements.itemBackButton.visible = false
            
            -- Show action buttons
            self:showActionButtons()
        end
    end
end

-- Show party selection UI
local function showPartySelectionUI(self, actionType)
    -- Hide other selection lists
    self:hideSelectionLists()
    
    -- Reset selection
    self.elements.partySelectList.selectedIndex = nil
    
    -- Show party selection list
    self.elements.partySelectList.visible = true
    
    -- Store the action type for later reference
    self.partySelectionActionType = actionType
    
    -- Since we're using auto-confirm, we only need the back button
    self.elements.confirmButton.visible = false
    self.elements.backButton.visible = true
end

-- UI handler for clicks on the UI
local function handleUIClick(self, x, y)
    -- Check for item-specific buttons first if visible
    if self.elements.itemConfirmButton and self.elements.itemConfirmButton.visible then
        if self.elements.itemConfirmButton:clicked(x, y) then
            return true
        end
    end
    
    if self.elements.itemBackButton and self.elements.itemBackButton.visible then
        if self.elements.itemBackButton:clicked(x, y) then
            -- DIRECT FIX: Forcibly hide ALL item UI elements when Back is clicked
            self.elements.itemList.visible = false
            self.elements.itemConfirmButton.visible = false
            self.elements.itemBackButton.visible = false
            
            -- Clear any selected items
            for _, item in ipairs(self.elements.itemList.items) do
                item.selected = false
            end
            
            -- Reset selection state
            self.selectedAction = nil
            self.selectedItem = nil
            
            -- Ensure action buttons are shown
            self:showActionButtons()
            
            return true
        end
    end
    
    -- Selection UI for actions that need targets
    if self.selectedAction then
        if self.selectedAction == "skill" then
            -- Show skill selection UI if needed
            if not self.selectedSkill then
                self.elements.skillList.visible = true
                self:hideActionButtons()
            end
        elseif self.selectedAction == "item" then
            -- Show item selection UI if needed
            if not self.selectedItem then
                self.elements.itemList.visible = true
                self:hideActionButtons()
            end
        end
    end
end

-- Draw minions UI
local function drawMinions(self)
    -- Draw minion slots on the left side of the screen
    local slotWidth = 90
    local slotHeight = 70
    local slotX = 20
    local slotY = 150
    local slotSpacing = 10
    
    -- Track how many minions we've drawn
    local minionsDrawn = 0
    
    -- Draw each minion slot
    for i, character in ipairs(self.party) do
        if character.active then
            -- Check for minions in the local combat minions list
            if self.minions[i] then
                for j, minion in pairs(self.minions[i]) do
                    if minion.active then
                        minionsDrawn = minionsDrawn + 1
                        local yPos = slotY + ((minionsDrawn - 1) * (slotHeight + slotSpacing))
                        
                        local isCurrentTurnMinion = self.state == combatSystem.STATE.MINION_TURN and 
                                                   self.activeMinion and 
                                                   self.activeMinion.charIndex == i and 
                                                   self.activeMinion.minionIndex == j
                        
                        drawSingleMinionDisplay(minion, slotX, yPos, slotWidth, slotHeight, isCurrentTurnMinion, true)
                    end
                end
            end
            
            -- Also check minions from the minionManager
            local charMinions = minionManager:getActiveMinions(character)
            if charMinions and #charMinions > 0 then
                for j, minion in ipairs(charMinions) do
                    -- Don't draw if already drawn from combat minions
                    if not self.minions[i] or not self.minions[i][j] then
                        if minion.active then
                            minionsDrawn = minionsDrawn + 1
                            local yPos = slotY + ((minionsDrawn - 1) * (slotHeight + slotSpacing))
                            
                            -- For minions from minionManager, we don't highlight for current turn or show detailed combat stats in this context
                            drawSingleMinionDisplay(minion, slotX, yPos, slotWidth, slotHeight, false, false)
                        end
                    end
                end
            end
        end
    end
    
    -- If there are no minions, draw a message
    if minionsDrawn == 0 and GAME.debug then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
        love.graphics.setFont(safeGetFont("small"))
        love.graphics.print("No active minions", slotX, slotY)
    end
end

-- Cancel selection and return to action buttons
local function cancelSelection(self)
    -- Hide all selection UIs
    if self.elements.skillList then
        self.elements.skillList.visible = false
        
        -- Deselect all skills
        for _, skill in ipairs(self.elements.skillList.skills) do
            skill.selected = false
        end
    end
    
    if self.elements.itemList then
        self.elements.itemList.visible = false
        
        -- Deselect all items
        for _, item in ipairs(self.elements.itemList.items) do
            item.selected = false
        end
    end
    
    if self.elements.partySelectList then
        self.elements.partySelectList.visible = false
    end
    
    if self.elements.enemySelectList then
        self.elements.enemySelectList.visible = false
    end
    
    -- Hide confirm/back buttons for skills
    if self.elements.confirmButton then
        self.elements.confirmButton.visible = false
    end
    
    if self.elements.backButton then
        self.elements.backButton.visible = false
    end
    
    -- Hide item-specific buttons
    if self.elements.itemConfirmButton then
        self.elements.itemConfirmButton.visible = false
    end
    
    if self.elements.itemBackButton then
        self.elements.itemBackButton.visible = false
    end
    
    -- Reset selected action and skill
    self.selectedAction = nil
    self.selectedSkill = nil
    self.selectedItem = nil
    
    -- Show action buttons
    self:showActionButtons()
end

-- Draw status effect tooltips when hovering over icons
local function drawStatusEffectTooltips(self)
    local mouseX, mouseY = love.mouse.getPosition()
    local statusEffects = require("gameplay/statusEffects")
    local tooltipShown = false
    
    -- Use party panel dimensions
    local partyPanelX = partyPanel.x
    local partyPanelY = partyPanel.y
    local partyPanelWidth = partyPanel.width
    local partyPanelHeight = partyPanel.height
    
    -- Check if mouse is over any character status effect icons
    for _, character in ipairs(self.party or {}) do
        if character.status then
            local characterIdx = nil
            for i, partyMember in ipairs(self.party) do
                if partyMember == character then
                    characterIdx = i
                    break
                end
            end
            
            if characterIdx then
                local x = partyPanelX + 10 + (characterIdx-1) * ((partyPanelWidth - 20) / 4)
                local width = (partyPanelWidth - 20) / 4 - 10
                local portraitSpace = 80
                local textStartX = x + portraitSpace
                
                -- Calculate status effect icon layout
                local statusIconSize = 16
                local statusIconSpacing = 2
                local maxIconsPerRow = 5
                local iconStartX = textStartX
                local iconStartY = partyPanelY + 60
                local iconIndex = 0
                
                for effectType, effect in pairs(character.status) do
                    if statusEffects.effects[effectType] then
                        local effectInfo = statusEffects.effects[effectType]
                        local row = math.floor(iconIndex / maxIconsPerRow)
                        local col = iconIndex % maxIconsPerRow
                        
                        local iconX = iconStartX + col * (statusIconSize + statusIconSpacing)
                        local iconY = iconStartY + row * (statusIconSize + statusIconSpacing)
                        
                        -- Check if mouse is over this status effect icon
                        if mouseX >= iconX and mouseX <= iconX + statusIconSize and
                           mouseY >= iconY and mouseY <= iconY + statusIconSize then
                            
                            -- Draw tooltip
                            local tooltipWidth = 200
                            local tooltipHeight = 100
                            local tooltipX = mouseX + 10
                            local tooltipY = mouseY - tooltipHeight - 10
                            
                            -- Adjust tooltip position if it would go off-screen
                            if tooltipX + tooltipWidth > GAME.width then
                                tooltipX = GAME.width - tooltipWidth - 10
                            end
                            if tooltipY < 0 then
                                tooltipY = mouseY + 20
                            end
                            
                            drawTooltipContent(tooltipX, tooltipY, tooltipWidth, tooltipHeight, effectInfo, effect)
                            
                            tooltipShown = true
                            break
                        end
                        
                        iconIndex = iconIndex + 1
                    end
                end
                
                if tooltipShown then
                    break
                end
            end
        end
    end
    
    -- Also check enemy status effects if not already showing a tooltip
    if not tooltipShown and self.enemies then
        for _, enemy in ipairs(self.enemies) do
            if enemy.status and enemy.active then
                -- Calculate enemy status icon positions
                -- This depends on how they are displayed in the drawEnemy function
                local enemyX = GAME.width / 2 - 50
                local enemyY = 150
                
                local statusIconSize = 18
                local statusIconSpacing = 3
                local maxIconsPerRow = 5
                local iconStartX = enemyX + 100
                local iconStartY = enemyY - 30
                local iconIndex = 0
                
                for effectType, effect in pairs(enemy.status) do
                    if statusEffects.effects[effectType] then
                        local effectInfo = statusEffects.effects[effectType]
                        local row = math.floor(iconIndex / maxIconsPerRow)
                        local col = iconIndex % maxIconsPerRow
                        
                        local iconX = iconStartX + col * (statusIconSize + statusIconSpacing)
                        local iconY = iconStartY + row * (statusIconSize + statusIconSpacing)
                        
                        -- Check if mouse is over this icon
                        if mouseX >= iconX and mouseX <= iconX + statusIconSize and
                           mouseY >= iconY and mouseY <= iconY + statusIconSize then
                            
                            -- Draw tooltip
                            local tooltipWidth = 200
                            local tooltipHeight = 100
                            local tooltipX = mouseX + 10
                            local tooltipY = mouseY - tooltipHeight - 10
                            
                            -- Adjust tooltip position if it would go off-screen
                            if tooltipX + tooltipWidth > GAME.width then
                                tooltipX = GAME.width - tooltipWidth - 10
                            end
                            if tooltipY < 0 then
                                tooltipY = mouseY + 20
                            end
                            
                            drawTooltipContent(tooltipX, tooltipY, tooltipWidth, tooltipHeight, effectInfo, effect)
                            
                            break
                        end
                        
                        iconIndex = iconIndex + 1
                    end
                end
            end
        end
    end
end

-- Show floating text on screen
local function showFloatingText(text, x, y, color, duration, floatingTexts)
    -- Default values
    x = x or GAME.width / 2
    y = y or GAME.height / 2
    color = color or {1, 1, 1, 1}
    duration = duration or 3.0
    
    -- Create floating text object
    local floatingText = {
        text = text,
        x = x,
        y = y,
        color = color,
        timeLeft = duration
    }
    
    -- Add to floating texts table
    table.insert(floatingTexts, floatingText)
    
    -- Print to console as well for debugging
    print("Floating text: " .. text)
end

combatSystem.STATE = {
    INIT = 1,
    PLAYER_TURN = 2,
    ENEMY_TURN = 3,
    MINION_TURN = 4,
    VICTORY = 5,
    DEFEAT = 6
}

return {
    createUI = createUI,
    draw = draw,
    drawCombatLog = drawCombatLog,
    drawEnemy = drawEnemy,
    drawSingleEnemy = drawSingleEnemy,
    drawMultipleEnemies = drawMultipleEnemies,
    drawParty = drawParty,
    drawMinions = drawMinions,
    drawEnemyTurnUI = drawEnemyTurnUI,
    drawVictoryUI = drawVictoryUI,
    drawDefeatUI = drawDefeatUI,
    drawVictoryPrompt = drawVictoryPrompt,
    drawPlayerTurnUI = drawPlayerTurnUI,
    handleUIClick = handleUIClick,
    showSkillList = showSkillList,
    showItemList = showItemList,
    showEnemySelectionUI = showEnemySelectionUI,
    showPartySelectionUI = showPartySelectionUI,
    confirmEnemySelection = confirmEnemySelection,
    confirmPartySelection = confirmPartySelection,
    hideSelectionLists = hideSelectionLists,
    selectAction = selectAction,
    cancelSelection = cancelSelection,
    handleMouseScroll = handleMouseScroll,
    drawStatusEffectTooltips = drawStatusEffectTooltips,
    showFloatingText = showFloatingText
}