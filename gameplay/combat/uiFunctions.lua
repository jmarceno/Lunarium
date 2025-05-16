-- UI Functions
-- Functions for creating and managing the combat UI
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local minionManager = require("gameplay/minionManager")
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local partyPanel = require("screens/ui_slices/partyPanel")

local combatSystem = {}  -- Forward declaration

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
            
            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw border
            love.graphics.setColor(0.5, 0.5, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Skills", self.x + 10, self.y + 5)
            
            -- Calculate visible range based on scroll
            local startIdx = self.scroll + 1
            local endIdx = math.min(startIdx + self.maxSkillsVisible - 1, #self.skills)
            
            -- Draw skill list
            love.graphics.setFont(screenManager.fonts.small)
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
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
               
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
                
                -- Deselect all skills
                for _, s in ipairs(self.skills) do
                    s.selected = false
                end
                
                -- Select the new skill
                self.skills[newIndex].selected = true
                self.selectedIndex = newIndex
                
                -- Adjust scroll if necessary
                if newIndex <= self.scroll then
                    self.scroll = math.max(0, newIndex - 1)
                elseif newIndex > self.scroll + self.maxSkillsVisible then
                    self.scroll = newIndex - self.maxSkillsVisible
                end
                
                return true
            elseif key == "s" or key == "down" then
                -- Move selection down
                local newIndex = self.selectedIndex + 1
                if newIndex > #self.skills then newIndex = 1 end
                
                -- Deselect all skills
                for _, s in ipairs(self.skills) do
                    s.selected = false
                end
                
                -- Select the new skill
                self.skills[newIndex].selected = true
                self.selectedIndex = newIndex
                
                -- Adjust scroll if necessary
                if newIndex <= self.scroll then
                    self.scroll = math.max(0, newIndex - 1)
                elseif newIndex > self.scroll + self.maxSkillsVisible then
                    self.scroll = newIndex - self.maxSkillsVisible
                end
                
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
            
            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw border
            love.graphics.setColor(0.5, 0.8, 0.5)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Items", self.x + 10, self.y + 5)
            
            -- Draw item list
            love.graphics.setFont(screenManager.fonts.small)
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
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
               
                -- Check item selection
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
            
            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw border
            love.graphics.setColor(0.5, 0.7, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            
            -- Draw title
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Select Target", self.x + 10, self.y + 5)
            
            -- Draw party member list
            love.graphics.setFont(screenManager.fonts.small)
            
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
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
               
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
        function() self:cancelSelection() end
    )
    self.elements.itemBackButton.visible = false
end

-- Draw combat UI
local function draw(self)
    -- Draw background
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
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
    
        -- Draw enemy
        self:drawEnemy()
        
        -- Draw party
        self:drawParty()
        
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
    end
    
    -- Draw minions
    if self.state ~= combatSystem.STATE.VICTORY and self.state ~= combatSystem.STATE.DEFEAT then
        self:drawMinions()
    end
end

-- Draw enemy information
local function drawEnemy(self)
    -- For multiple enemies, arrange them in a grid
    if #self.enemies > 1 then
        self:drawMultipleEnemies()
    else
        -- Original single enemy display
        self:drawSingleEnemy(self.enemy, GAME.width / 2 - 100, 50)
    end
end

-- Draw multiple enemies in a grid layout
local function drawMultipleEnemies(self)
    -- Calculate grid layout based on number of enemies
    local maxRows = 2 -- Maximum number of rows
    local maxEnemiesFirstRow = 3 -- Max 3 enemies in the first row
    
    local firstRowCount = math.min(maxEnemiesFirstRow, #self.enemies)
    local secondRowCount = math.min(#self.enemies - firstRowCount, 2) -- Max 2 enemies in second row
    
    -- Calculate dimensions for each enemy display area
    local enemyWidth = 240 -- Increased from 200 to add more space between enemies
    local enemyHeight = 300 -- Fixed height for enemy section
    
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
        
        -- Draw individual enemy
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
            local y = 200 -- Second row position (below first row)
            
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
            
            -- Draw individual enemy
            self:drawSingleEnemy(enemy, x, y)
        end
    end
end

-- Draw a single enemy at specified position
local function drawSingleEnemy(self, enemy, x, y)
    -- Draw enemy name
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.print(enemy.name, x, y)
    
    -- Draw enemy health bar
    local healthWidth = 200 * (enemy.currentHP / enemy.maxHP)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y + 40, 200, 20)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y + 40, healthWidth, 20)
    
    -- Draw HP text - moved 20px to the right
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
        enemy.currentHP .. " / " .. enemy.maxHP,
        x + 90, y + 42 -- Moved from x + 70 to x + 90
    )
    
    -- Draw enemy sprite below the health bar
    love.graphics.setColor(1, 1, 1)
    
    -- Try to load and draw the enemy sprite
    local sprite = nil
    if enemy.id then
        -- Use enemy ID to get sprite
        sprite = assetManager:getImage("monster", enemy.id)
    end
    
    if sprite then
        -- Calculate size for sprite (max 150px width/height for multiple enemies)
        local maxSize = #self.enemies > 1 and 120 or 200
        local width = sprite:getWidth()
        local height = sprite:getHeight()
        local scale = math.min(maxSize / width, maxSize / height)
        
        -- Draw centered below the health bar
        love.graphics.draw(
            sprite, 
            x + 100 - (width * scale / 2), 
            y + 70, -- Position below the health bar
            0, -- rotation
            scale, -- scale x
            scale  -- scale y
        )
    else
        -- Draw placeholder if sprite not found
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("fill", x + 40, y + 70, 120, 120)
        love.graphics.setColor(0.8, 0.4, 0.4)
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.printf(enemy.name or "Monster", x + 40, y + 120, 120, "center")
    end
    
    -- Draw status effects using the helper function
    if enemy.status and next(enemy.status) then
        local uiHelpers = require("gameplay/combat/uiHelpers")
        uiHelpers.drawStatusEffects(enemy, x, y + 195, 28, 5)
    end
    
    -- Draw resistances/vulnerabilities if this is the selected target
    if self.selectedTarget == enemy and enemy.resistances then
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.setColor(1, 1, 1, 0.8)
        
        local resistY = y + 230
        love.graphics.print("Resistances:", x, resistY)
        resistY = resistY + 20
        
        -- Get notable resistances/vulnerabilities (those with significant values)
        for damageType, value in pairs(enemy.resistances) do
            if math.abs(value) >= 20 then -- Only show significant resistances/vulnerabilities
                if value < 0 then
                    love.graphics.setColor(0.4, 0.8, 0.4) -- Green for resistance
                    love.graphics.print(damageType .. " " .. value .. "%", x + 10, resistY)
                else
                    love.graphics.setColor(0.8, 0.4, 0.4) -- Red for vulnerability
                    love.graphics.print(damageType .. " +" .. value .. "%", x + 10, resistY)
                end
                resistY = resistY + 15
            end
        end
        
        -- Show immunities if any
        if enemy.immunities and #enemy.immunities > 0 then
            resistY = resistY + 5
            love.graphics.setColor(0.8, 0.8, 0.2)
            love.graphics.print("Immune to:", x, resistY)
            resistY = resistY + 15
            
            for _, immunity in ipairs(enemy.immunities) do
                love.graphics.print("- " .. immunity, x + 10, resistY)
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
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Combat Log", logX + 10, logY + 5)
    
    -- Draw log entries
    love.graphics.setFont(screenManager.fonts.small)
    
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
    love.graphics.setFont(screenManager.fonts.medium)
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
    
    -- Draw action buttons - always draw them if it's player's turn
    if not self.selectedAction then
        -- Make sure action buttons are visible
        self:showActionButtons()
        
        -- Draw the buttons
        self.elements.attackButton:draw()
        self.elements.skillButton:draw()
        self.elements.itemButton:draw()
        self.elements.defendButton:draw()
        
        -- Hide confirm and back buttons
        self.elements.confirmButton.visible = false
        self.elements.backButton.visible = false
    else
        -- Hide action buttons during selection
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
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = false
            
            -- Show item-specific buttons
            self.elements.itemConfirmButton.visible = true
            self.elements.itemBackButton.visible = true
            
            -- Draw the item-specific buttons
            self.elements.itemConfirmButton:draw()
            self.elements.itemBackButton:draw()
        elseif (self.elements.enemySelectList and self.elements.enemySelectList.visible) or
                self.elements.partySelectList.visible then
            -- For target selection (enemy or party), show only back button
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = true
            
            -- Update back button position for target selection
            if self.elements.enemySelectList and self.elements.enemySelectList.visible then
                self.elements.backButton.x = self.elements.enemySelectList.x - self.elements.backButton.width - 10
                self.elements.backButton.y = self.elements.enemySelectList.y
            elseif self.elements.partySelectList.visible then
                self.elements.backButton.x = self.elements.partySelectList.x - self.elements.backButton.width - 10
                self.elements.backButton.y = self.elements.partySelectList.y
            end
            
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
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 0.5, 0.5)
    
    local turnText = "Enemy Turn"
    local textWidth = love.graphics.getFont():getWidth(turnText)
    local textX = GAME.width / 2 - textWidth / 2
    
    love.graphics.print(turnText, textX, turnTextY)
    
    -- Show a "Waiting..." message below it
    love.graphics.setFont(screenManager.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.7)
    
    local waitText = "Waiting for enemy action..."
    local waitWidth = love.graphics.getFont():getWidth(waitText)
    local waitX = GAME.width / 2 - waitWidth / 2
    
    love.graphics.print(waitText, waitX, turnTextY + 25)
end

-- Draw UI for defeat state
local function drawDefeatUI(self)
    -- Darken background for readability
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw defeat message
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.printf(
        "Defeat!",
        GAME.width / 2 - 200, GAME.height / 2 - 50,
        400, "center"
    )
    
    -- Draw "Press Enter to continue" text
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 1, 1, 0.7 + math.sin(love.timer.getTime() * 4) * 0.3)
    love.graphics.printf(
        "Press Enter to continue",
        GAME.width / 2 - 200, GAME.height / 2 + 50,
        400, "center"
    )
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
                
                -- Draw background
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
                
                -- Draw border
                love.graphics.setColor(0.8, 0.5, 0.5)
                love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
                
                -- Draw title
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Select Target", self.x + 10, self.y + 5)
                
                -- Draw enemy list
                love.graphics.setFont(screenManager.fonts.small)
                
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
                if x >= self.x and x <= self.x + self.width and
                   y >= self.y and y <= self.y + self.height then
                   
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
    
    -- Hide enemy selection UI
    self.elements.enemySelectList.visible = false
    
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
    
    -- Update confirm button callback to standard confirmation
    self.elements.confirmButton.callback = function()
        self:confirmAction()
    end
    
    -- Make sure buttons are visible
    self.elements.confirmButton.visible = true
    self.elements.backButton.visible = true
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
                        
                        -- Draw slot background
                        love.graphics.rectangle("fill", slotX, yPos, slotWidth, slotHeight, 5, 5)
                        
                        -- Highlight active minion if it's their turn
                        if self.state == combatSystem.STATE.MINION_TURN and 
                           self.activeMinion and 
                           self.activeMinion.charIndex == i and 
                           self.activeMinion.minionIndex == j then
                            love.graphics.setColor(1, 1, 0.5, 0.4)
                            love.graphics.rectangle("fill", slotX - 2, yPos - 2, slotWidth + 4, slotHeight + 4, 5, 5)
                        end
                        
                        -- Draw border
                        love.graphics.setColor(0.7, 0.7, 0.7)
                        love.graphics.rectangle("line", slotX, yPos, slotWidth, slotHeight, 5, 5)
                        
                        -- Draw name
                        love.graphics.setFont(screenManager.fonts.small)
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print(minion.name, slotX + 5, yPos + 5)
                        
                        -- Draw HP bar
                        local hpBarWidth = slotWidth - 10
                        local hpBarHeight = 8
                        local hpPercent = minion.currentHP / minion.maxHP
                        
                        -- HP bar background
                        love.graphics.setColor(0.2, 0.2, 0.2)
                        love.graphics.rectangle("fill", slotX + 5, yPos + 22, hpBarWidth, hpBarHeight)
                        
                        -- HP bar fill
                        love.graphics.setColor(0.2, 0.8, 0.2)
                        love.graphics.rectangle("fill", slotX + 5, yPos + 22, hpBarWidth * hpPercent, hpBarHeight)
                        
                        -- Draw stats - use small font instead of tiny
                        love.graphics.setFont(screenManager.fonts.small)
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print("HP: " .. math.floor(minion.currentHP) .. "/" .. math.floor(minion.maxHP), 
                            slotX + 5, yPos + 33)
                            
                        -- Draw attack power or other relevant stat
                        if minion.attackPower then
                            love.graphics.print("ATK: " .. math.floor(minion.attackPower), 
                                slotX + 5, yPos + 45)
                        elseif minion.magicPower then
                            love.graphics.print("MAG: " .. math.floor(minion.magicPower), 
                                slotX + 5, yPos + 45)
                        end

                        -- Draw status (active/inactive/buff)
                        love.graphics.setColor(1, 1, 1)
                        if minion.takesActions then
                            love.graphics.print("Combat", slotX + 5, yPos + 57)
                        else
                            love.graphics.print("Passive", slotX + 5, yPos + 57)
                        end
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
                            
                            -- Draw background based on minion type
                            if minion.type == "undead" then
                                love.graphics.setColor(0.3, 0.1, 0.3, 0.8) -- Dark purple
                            elseif minion.type == "elemental" then
                                love.graphics.setColor(0.2, 0.4, 0.8, 0.8) -- Blue
                            elseif minion.type == "spirit" then
                                love.graphics.setColor(0.5, 0.8, 0.5, 0.8) -- Green
                            else
                                love.graphics.setColor(0.3, 0.3, 0.3, 0.8) -- Gray default
                            end
                            
                            -- Draw slot background
                            love.graphics.rectangle("fill", slotX, yPos, slotWidth, slotHeight, 5, 5)
                            
                            -- Draw border
                            love.graphics.setColor(0.7, 0.7, 0.7)
                            love.graphics.rectangle("line", slotX, yPos, slotWidth, slotHeight, 5, 5)
                            
                            -- Draw name
                            love.graphics.setFont(screenManager.fonts.small)
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print(minion.name, slotX + 5, yPos + 5)
                            
                            -- Draw HP bar
                            local hpBarWidth = slotWidth - 10
                            local hpBarHeight = 8
                            local hpPercent = minion.currentHP / minion.maxHP
                            
                            -- HP bar background
                            love.graphics.setColor(0.2, 0.2, 0.2)
                            love.graphics.rectangle("fill", slotX + 5, yPos + 22, hpBarWidth, hpBarHeight)
                            
                            -- HP bar fill
                            love.graphics.setColor(0.2, 0.8, 0.2)
                            love.graphics.rectangle("fill", slotX + 5, yPos + 22, hpBarWidth * hpPercent, hpBarHeight)
                            
                            -- Draw stats - use small font instead of tiny
                            love.graphics.setFont(screenManager.fonts.small)
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print("HP: " .. math.floor(minion.currentHP) .. "/" .. math.floor(minion.maxHP), 
                                slotX + 5, yPos + 33)
                                
                            -- Draw status (active/inactive/buff)
                            love.graphics.setColor(1, 1, 1)
                            if minion.takesActions then
                                love.graphics.print("Combat", slotX + 5, yPos + 45)
                            else
                                love.graphics.print("Passive", slotX + 5, yPos + 45)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- If there are no minions, draw a message
    if minionsDrawn == 0 and GAME.debug then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.print("No active minions", slotX, slotY)
    end
end

-- Cancel selection and return to action buttons
local function cancelSelection(self)
    -- Hide all selection UIs
    if self.elements.skillList then
        self.elements.skillList.visible = false
    end
    
    if self.elements.itemList then
        self.elements.itemList.visible = false
    end
    
    if self.elements.partySelectList then
        self.elements.partySelectList.visible = false
    end
    
    if self.elements.enemySelectList then
        self.elements.enemySelectList.visible = false
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
                            love.graphics.setFont(screenManager.fonts.medium)
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print(effectInfo.name, tooltipX + 10, tooltipY + 10)
                            
                            -- Draw effect description
                            love.graphics.setFont(screenManager.fonts.small)
                            love.graphics.setColor(0.9, 0.9, 0.9)
                            love.graphics.printf(effectInfo.description, tooltipX + 10, tooltipY + 35, tooltipWidth - 20, "left")
                            
                            -- Draw effect duration
                            love.graphics.setColor(0.7, 0.7, 1)
                            love.graphics.print(
                                "Duration: " .. effect.duration .. " turns", 
                                tooltipX + 10, tooltipY + tooltipHeight - 20
                            )
                            
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
                            love.graphics.setFont(screenManager.fonts.medium)
                            love.graphics.setColor(1, 1, 1)
                            love.graphics.print(effectInfo.name, tooltipX + 10, tooltipY + 10)
                            
                            -- Draw effect description
                            love.graphics.setFont(screenManager.fonts.small)
                            love.graphics.setColor(0.9, 0.9, 0.9)
                            love.graphics.printf(effectInfo.description, tooltipX + 10, tooltipY + 35, tooltipWidth - 20, "left")
                            
                            -- Draw effect duration
                            love.graphics.setColor(0.7, 0.7, 1)
                            love.graphics.print(
                                "Duration: " .. effect.duration .. " turns", 
                                tooltipX + 10, tooltipY + tooltipHeight - 20
                            )
                            
                            break
                        end
                        
                        iconIndex = iconIndex + 1
                    end
                end
            end
        end
    end
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
    drawStatusEffectTooltips = drawStatusEffectTooltips
}