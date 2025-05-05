-- Combat System
-- Handles turn-based combat mechanics
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local assetManager = require("assets/assetManager")
local screenManager = require("screens/screenManager")
local minionManager = require("gameplay/minionManager") -- Add minion manager

local combatSystem = {
    STATE = {
        INIT = 1,
        PLAYER_TURN = 2,
        ENEMY_TURN = 3,
        MINION_TURN = 4, -- New state for minion turns
        VICTORY = 5,     -- Fixed: was 4
        DEFEAT = 6       -- Fixed: was 5
    }
}

-- Create a new combat instance
function combatSystem:createCombat(party, enemy)
    local combat = {
        party = party,
        enemies = {}, -- Array to hold multiple enemies
        activeEnemyIndex = 1, -- Current enemy in turn
        state = self.STATE.INIT,
        currentTurn = 1,
        currentCharacter = 1,
        activeMinion = nil, -- Current minion in turn
        log = {},
        selectedAction = nil,
        selectedTarget = nil,
        turnOrder = {},
        effects = {},
        rewardsCalculated = false, -- New flag to track reward calculation
        
        -- Active minions in combat
        minions = {},
        
        -- Combat UI elements
        elements = {},
        
        -- Settings
        settings = {
            autoConfirmSelection = true -- Enable auto-confirm by default
        },
        
        -- Initialize combat
        init = function(self)
            -- Handle backward compatibility - convert single enemy to enemies array
            if enemy then
                if type(enemy) == "table" and enemy[1] then
                    -- Already an array of enemies
                    self.enemies = enemy
                else
                    -- Single enemy, add to array
                    table.insert(self.enemies, enemy)
                end
            end
            
            -- Create enemy property for backward compatibility
            -- Points to the first enemy in the array
            self.enemy = self.enemies[1]
            
            -- Setup characters and enemy stats
            self:setupCombatants()
            
            -- Initialize minions tracking
            self.minions = {}
            
            -- Initialize minion turn tracking
            self.minionsTurnTaken = {}
            
            -- Import any existing minions from minionManager
            self:importExistingMinions()
            
            -- Determine turn order
            self:determineTurnOrder()
            
            -- Create UI elements
            self:createUI()
            
            -- Initialize timing variables
            self.animationDelay = 0
            self.turnEndDelay = 0
            self.enemyTurnDelay = nil  -- Set to nil to force initialization on first enemy turn
            self.activeEnemyIndex = 1  -- Start with the first enemy
            
            -- Set initial state and find the first active character
            self.state = combatSystem.STATE.PLAYER_TURN
            
            -- Track which characters have had their turn this round
            self.charactersTurnTaken = {}
            for i=1, #self.party do
                self.charactersTurnTaken[i] = false
            end
            
            -- Find the first active character
            self.currentCharacter = 0  -- Start with 0 so we can find the first active character
            local found = false
            
            -- Loop through all characters to find the first active one
            for i=1, #self.party do
                if self.party[i].active then
                    self.currentCharacter = i
                    found = true
                    -- Ensure their turn is not marked as taken
                    self.charactersTurnTaken[i] = false
                    break
                end
            end
            
            -- If no active characters found (should not happen), handle gracefully
            if not found and #self.party > 0 then
                self.currentCharacter = 1
                self.party[1].active = true
                self.charactersTurnTaken[1] = false  -- Ensure first character gets a turn
            end
            
            -- Add combat start message
            self:addLog("Combat started!")
            -- Show enemies that appeared
            if #self.enemies > 1 then
                local enemyNames = ""
                for i, enemy in ipairs(self.enemies) do
                    if i > 1 then
                        if i == #self.enemies then
                            enemyNames = enemyNames .. " and "
                        else
                            enemyNames = enemyNames .. ", "
                        end
                    end
                    enemyNames = enemyNames .. enemy.name
                end
                self:addLog(enemyNames .. " appeared!")
            else
                self:addLog(self.enemy.name .. " appeared!")
            end
            self:addLog(self.party[self.currentCharacter].name .. "'s turn begins", {0.5, 0.5, 1})
            
            -- Make sure action buttons are visible for first player turn
            self.elements.attackButton.visible = true
            self.elements.skillButton.visible = true
            self.elements.itemButton.visible = true
            self.elements.defendButton.visible = true
        end,
        
        -- Setup combatants with combat stats
        setupCombatants = function(self)
            -- Setup party
            for i, character in ipairs(self.party) do
                -- Calculate derived stats if they don't exist
                if not character.attackPower then
                    local charSystem = require("gameplay/character")
                    character.attackPower = charSystem:calculateAttackPower(character)
                    character.magicPower = charSystem:calculateMagicPower(character)
                    character.defense = charSystem:calculateDefense(character)
                    character.magicDefense = charSystem:calculateMagicDefense(character)
                end
                
                -- Setup status effects table
                character.status = {}
                
                -- Set active flag
                character.active = character.currentHP > 0
            end
            
            -- Setup all enemies
            for i, enemy in ipairs(self.enemies) do
                if not enemy.name then
                    enemy.name = "Monster #" .. enemy.id
                end
                
                if not enemy.maxHP then
                    enemy.maxHP = enemy.stats.hp
                    enemy.currentHP = enemy.maxHP
                end
                
                if not enemy.attackPower then
                    enemy.attackPower = enemy.stats.attack
                    enemy.defense = enemy.stats.defense
                end
                
                -- Setup enemy status effects
                enemy.status = {}
                
                -- Set enemy as active
                enemy.active = true
            end
        end,
        
        -- Determine turn order
        determineTurnOrder = function(self)
            self.turnOrder = {}
            
            -- Add party members to turn order
            for i, character in ipairs(self.party) do
                if character.active then
                    table.insert(self.turnOrder, {
                        type = "player",
                        index = i,
                        speed = character.attributes.DEX or 10
                    })
                    
                    -- Add active minions for this character
                    local charMinions = minionManager:getActiveMinions(character)
                    if charMinions and #charMinions > 0 then
                        if GAME.debug then
                            print("Found " .. #charMinions .. " active minions for " .. character.name)
                        end
                        
                        for j, minion in ipairs(charMinions) do
                            -- Only add minions that take actions (not passive spirits)
                            if minion.takesActions then
                                table.insert(self.turnOrder, {
                                    type = "minion",
                                    owner = i, -- Reference to the owner's index in party
                                    index = j, -- Index in character's minion array
                                    speed = minion.speed or 8
                                })
                                
                                -- Store minion reference in combat.minions
                                if not self.minions[i] then 
                                    self.minions[i] = {}
                                end
                                self.minions[i][j] = minion
                                
                                if GAME.debug then
                                    print("Added minion to turn order: " .. minion.name)
                                end
                            end
                        end
                    end
                    
                    -- Also check the local combat minions list for this character
                    if self.minions[i] then
                        for j, minion in pairs(self.minions[i]) do
                            -- Skip if already processed from minionManager
                            if not minion.processed then
                                if minion.takesActions and minion.active then
                                    table.insert(self.turnOrder, {
                                        type = "minion",
                                        owner = i, -- Reference to the owner's index in party
                                        index = j, -- Index in combat's minion array
                                        speed = minion.speed or 8
                                    })
                                    
                                    if GAME.debug then
                                        print("Added combat-local minion to turn order: " .. minion.name)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Add all enemies to turn order
            for i, enemy in ipairs(self.enemies) do
                table.insert(self.turnOrder, {
                    type = "enemy",
                    index = i,
                    speed = enemy.stats.speed or 10
                })
            end
            
            -- Sort by speed
            table.sort(self.turnOrder, function(a, b)
                return a.speed > b.speed
            end)
            
            if GAME.debug then
                print("Turn order determined with " .. #self.turnOrder .. " entries")
            end
        end,
        
        -- Create UI elements
        createUI = function(self)
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
            
            -- Skill list (hidden initially)
            self.elements.skillList = {
                visible = false,
                skills = {},
                x = 20, -- Move to left side of screen
                y = GAME.height - partyHeight - 250, -- Position above the party UI
                width = 250,
                height = 200,
                
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
                    
                    -- Draw skill list
                    love.graphics.setFont(screenManager.fonts.small)
                    for i, skill in ipairs(self.skills) do
                        local y = self.y + 30 + (i - 1) * 25
                        
                        -- Highlight selected skill
                        if skill.selected then
                            love.graphics.setColor(0.3, 0.3, 0.7)
                            love.graphics.rectangle("fill", self.x + 5, y - 2, self.width - 10, 22)
                        end
                        
                        -- Draw skill name
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print(skill.name, self.x + 10, y)
                        
                        -- Draw MP cost
                        love.graphics.setColor(0.5, 0.5, 1)
                        love.graphics.print("MP: " .. skill.mpCost, self.x + 180, y)
                    end
                end,
                
                clicked = function(self, x, y)
                    if not self.visible then return false end
                    
                    -- Check if click is within bounds
                    if x >= self.x and x <= self.x + self.width and
                       y >= self.y and y <= self.y + self.height then
                       
                        -- Check skill selection
                        for i, skill in ipairs(self.skills) do
                            local skillY = self.y + 30 + (i - 1) * 25
                            
                            if y >= skillY - 2 and y <= skillY + 20 then
                                -- Deselect all skills
                                for _, s in ipairs(self.skills) do
                                    s.selected = false
                                end
                                
                                -- Select this skill
                                skill.selected = true
                                return true
                            end
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
                x = 20, -- Move to left side of screen
                y = GAME.height - partyHeight - 250, -- Position above the party UI
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
                x = 20, -- Move to left side of screen
                y = GAME.height - partyHeight - 250, -- Position above the party UI
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
            
            -- Confirm button (for skills/items) - stacked vertically
            self.elements.confirmButton = screenManager.UI.Button(
                280, GAME.height - partyHeight - 200, 
                120, 40, "Confirm", 
                function() self:confirmAction() end
            )
            self.elements.confirmButton.visible = false
            
            -- Back button (for skills/items) - stacked vertically
            self.elements.backButton = screenManager.UI.Button(
                280, GAME.height - partyHeight - 150, 
                120, 40, "Back", 
                function() self:cancelSelection() end
            )
            self.elements.backButton.visible = true
        end,
        
        -- Update combat state
        update = function(self, dt)
            -- Skip all updates if in victory or defeat state - only handle drawing
            if self.state == combatSystem.STATE.VICTORY or self.state == combatSystem.STATE.DEFEAT then
                return
            end

            -- Handle animation delay
            if self.animationDelay > 0 then
                self.animationDelay = self.animationDelay - dt
                return
            end
            
            -- Handle turn end delay
            if self.turnEndDelay > 0 then
                self.turnEndDelay = self.turnEndDelay - dt
                if self.turnEndDelay <= 0 then
                    -- Check if we have a pending victory (from minion killing last enemy)
                    if self.pendingVictory then
                        self:victory()
                        return
                    end
                    
                    -- Normal turn progression
                    self:nextTurn()
                end
                return
            end
            
            -- Check for inactive character on their turn
            if self.state == combatSystem.STATE.PLAYER_TURN and 
               (self.currentCharacter < 1 or 
                self.currentCharacter > #self.party or 
                not self.party[self.currentCharacter].active) then
                self:nextTurn()
                return
            end
            
            -- Enemy turn processing
            if self.state == combatSystem.STATE.ENEMY_TURN then
                if self.enemyTurnDelay == nil then
                    -- Initialize enemy turns - set the active enemy index to the first enemy
                    self.activeEnemyIndex = 1
                    self.enemyTurnDelay = 1.0  -- Initial delay before first enemy acts
                end
                
                self.enemyTurnDelay = self.enemyTurnDelay - dt
                
                if self.enemyTurnDelay <= 0 then
                    -- Execute current enemy's turn
                    self:executeEnemyTurn()
                    
                    -- Check if we need to move to the next enemy
                    if self.activeEnemyIndex >= #self.enemies then
                        -- We've completed a full cycle of enemies
                        self.enemyTurnDelay = nil
                        self:nextTurn() -- Go to player turn
                    else
                        -- More enemies to process, set a delay before next enemy acts
                        self.enemyTurnDelay = 0.7 -- Delay between enemy actions
                    end
                end
            end
            
            -- Add new minion turn handling
            if self.state == combatSystem.STATE.MINION_TURN then
                if self.minionTurnDelay == nil then
                    -- Initialize minion turns
                    self.minionTurnDelay = 0.8
                end
                
                self.minionTurnDelay = self.minionTurnDelay - dt
                
                if self.minionTurnDelay <= 0 then
                    -- Execute current minion's turn
                    self:executeMinionTurn()
                    
                    -- Check for pending victory (minion might have killed last enemy)
                    if self.pendingVictory then
                        return
                    end
                    
                    -- Move to next turn
                    self.minionTurnDelay = nil
                    self:nextTurn()
                end
            end
        end,
        
        -- Draw combat UI
        draw = function(self)
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
                if self.elements.skillList then
                    self.elements.skillList:draw()
                end
                
                if self.elements.itemList then
                    self.elements.itemList:draw()
                end
                
                if self.elements.partySelectList then
                    self.elements.partySelectList:draw()
                end
                
                if self.elements.enemySelectList then
                    self.elements.enemySelectList:draw()
                end
            end
            
            -- Draw minions
            if self.state ~= combatSystem.STATE.VICTORY and self.state ~= combatSystem.STATE.DEFEAT then
                self:drawMinions()
            end
            
            -- Always draw combat log
            self:drawCombatLog()
        end,
        
        -- Draw enemy information
        drawEnemy = function(self)
            -- For multiple enemies, arrange them in a grid
            if #self.enemies > 1 then
                self:drawMultipleEnemies()
            else
                -- Original single enemy display
                self:drawSingleEnemy(self.enemy, GAME.width / 2 - 100, 50)
            end
        end,
        
        -- Draw multiple enemies in a grid layout
        drawMultipleEnemies = function(self)
            -- Calculate grid layout based on number of enemies
            local columns = math.min(3, #self.enemies)  -- Max 3 enemies per row
            local rows = math.ceil(#self.enemies / columns)
            
            -- Calculate dimensions for each enemy display area
            local enemyWidth = GAME.width / columns
            local enemyHeight = 300  -- Fixed height for enemy section
            
            -- Draw each enemy in grid
            for i, enemy in ipairs(self.enemies) do
                -- Calculate position in grid
                local col = (i - 1) % columns
                local row = math.floor((i - 1) / columns)
                local x = col * enemyWidth + (enemyWidth / 2) - 100  -- Center in column
                local y = 30 + row * enemyHeight * 0.7  -- Reduce vertical spacing to fit all rows
                
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
        end,
        
        -- Draw a single enemy at specified position
        drawSingleEnemy = function(self, enemy, x, y)
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
            
            -- Draw HP text
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(
                enemy.currentHP .. " / " .. enemy.maxHP,
                x + 70, y + 42
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
            
            -- Draw status effects
            local statusX = x
            local statusY = y + 200 -- Move status effects below the sprite
            
            for status, info in pairs(enemy.status) do
                love.graphics.setColor(0.8, 0.8, 0.2)
                love.graphics.print(status, statusX, statusY)
                statusY = statusY + 15
            end
        end,
        
        -- Draw party information
        drawParty = function(self)
            -- Create a background panel at the bottom of the screen
            local panelHeight = 110 -- Increased from 90
            local panelY = GAME.height - panelHeight
            
            -- Draw panel background
            love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
            love.graphics.rectangle("fill", 0, panelY, GAME.width, panelHeight)
            
            -- Draw panel border
            love.graphics.setColor(0.3, 0.3, 0.5)
            love.graphics.rectangle("line", 0, panelY, GAME.width, panelHeight)
            
            -- Calculate width available for each character
            local characterWidth = GAME.width / #self.party
            
            for i, character in ipairs(self.party) do
                local x = (i - 1) * characterWidth + 20
                local y = panelY + 10
                
                -- Draw character container
                if self.state == combatSystem.STATE.PLAYER_TURN and i == self.currentCharacter then
                    -- Highlight current character
                    love.graphics.setColor(0.3, 0.3, 0.7, 0.5)
                    love.graphics.rectangle("fill", x - 10, y - 5, characterWidth - 20, panelHeight - 10, 5, 5)
                end
                
                -- Draw character name
                love.graphics.setFont(screenManager.fonts.medium)
                if character.active then
                    love.graphics.setColor(1, 1, 1)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                end
                love.graphics.print(character.name, x, y)
                
                -- Draw HP/MP bars side by side
                local barWidth = characterWidth - 100 -- Leave space for portrait
                local barHeight = 15
                
                -- Draw HP bar
                local healthWidth = barWidth * (character.currentHP / character.maxHP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", x, y + 30, barWidth, barHeight)
                love.graphics.setColor(0.8, 0.2, 0.2)
                love.graphics.rectangle("fill", x, y + 30, healthWidth, barHeight)
                
                -- Draw HP text
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "HP: " .. character.currentHP .. "/" .. character.maxHP,
                    x + 5, y + 30
                )
                
                -- Draw MP bar
                local mpWidth = barWidth * (character.currentMP / character.maxMP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", x, y + 50, barWidth, barHeight)
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", x, y + 50, mpWidth, barHeight)
                
                -- Draw MP text
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "MP: " .. character.currentMP .. "/" .. character.maxMP,
                    x + 5, y + 50
                )
                
                -- Draw character portrait
                local portraitSize = 60
                local portraitX = x + barWidth + 20
                local portraitY = y + 15
                
                -- Try to load and draw character portrait
                local portrait = nil
                if character.portraitId then
                    portrait = assetManager:getImage("portrait", character.portraitId)
                end
                
                if portrait then
                    -- Draw portrait with fixed size
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.draw(
                        portrait,
                        portraitX,
                        portraitY,
                        0, -- rotation
                        portraitSize / portrait:getWidth(), -- scale x
                        portraitSize / portrait:getHeight() -- scale y
                    )
                else
                    -- Draw placeholder if portrait not found
                    love.graphics.setColor(0.5, 0.5, 0.6)
                    love.graphics.rectangle("fill", portraitX, portraitY, portraitSize, portraitSize)
                    
                    -- Draw first letter of character name in placeholder
                    love.graphics.setColor(0.9, 0.9, 1)
                    love.graphics.setFont(screenManager.fonts.large)
                    love.graphics.printf(
                        string.sub(character.name, 1, 1),
                        portraitX,
                        portraitY + portraitSize/4,
                        portraitSize,
                        "center"
                    )
                end
                
                -- Draw any status effects as small icons or text
                if next(character.status) then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.8, 0.8, 0.2)
                    
                    local statusX = x
                    local statusY = y + 70
                    local statusText = "Status: "
                    
                    for status, _ in pairs(character.status) do
                        statusText = statusText .. status .. " "
                    end
                    
                    -- Truncate if too long
                    if love.graphics.getFont():getWidth(statusText) > barWidth then
                        statusText = string.sub(statusText, 1, 20) .. "..."
                    end
                    
                    love.graphics.print(statusText, statusX, statusY)
                end
            end
        end,
        
        -- Draw combat log
        drawCombatLog = function(self)
            -- Position in bottom right corner, above the party panel
            local panelHeight = 110 -- Should match party panel height (increased from 90)
            local logWidth = 260
            local logHeight = 180
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
            
            -- Calculate how many entries can fit
            local entriesVisible = math.floor((logHeight - 30) / 18) -- 30px for header, 18px per entry
            local startIndex = math.max(1, #self.log - entriesVisible + 1)
            
            for i = startIndex, #self.log do
                local entry = self.log[i]
                local y = logY + 30 + (i - startIndex) * 18
                
                love.graphics.setColor(entry.color or {1, 1, 1})
                love.graphics.print(entry.text, logX + 10, y)
            end
        end,
        
        -- Draw UI for player turn
        drawPlayerTurnUI = function(self)
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
                self.elements.attackButton.visible = true
                self.elements.skillButton.visible = true
                self.elements.itemButton.visible = true
                self.elements.defendButton.visible = true
                
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
                self.elements.attackButton.visible = false
                self.elements.skillButton.visible = false
                self.elements.itemButton.visible = false
                self.elements.defendButton.visible = false
                
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
                if self.elements.skillList.visible or 
                   self.elements.itemList.visible then
                    -- Only show confirm/back buttons for skill and item selection
                    self.elements.confirmButton.visible = true
                    self.elements.backButton.visible = true
                    self.elements.confirmButton:draw()
                    self.elements.backButton:draw()
                elseif (self.elements.enemySelectList and self.elements.enemySelectList.visible) or
                        self.elements.partySelectList.visible then
                    -- For target selection (enemy or party), show only back button
                    self.elements.confirmButton.visible = false
                    self.elements.backButton.visible = true
                    self.elements.backButton:draw()
                end
            end
        end,
        
        -- Draw UI for enemy turn state
        drawEnemyTurnUI = function(self)
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
        end,
        
        -- Draw UI for victory state
        drawVictoryUI = function(self)
            -- Ensure rewards are initialized (safety check)
            if not self.rewards then
                -- Initialize default empty rewards if missing
                self.rewards = {
                    exp = 0,
                    loot = {}
                }
                
                if GAME.debug then
                    print("Warning: Victory UI rendered before rewards were initialized")
                end
            end

            -- Darken background for readability
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
            
            -- Draw victory message
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.printf(
                "Victory!",
                GAME.width / 2 - 200, GAME.height / 3 - 100,
                400, "center"
            )
            
            -- Draw battle summary
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            -- Different text based on number of enemies
            if #self.enemies > 1 then
                love.graphics.printf(
                    "You defeated " .. #self.enemies .. " enemies!",
                    GAME.width / 2 - 200, GAME.height / 3 - 50,
                    400, "center"
                )
            else
                love.graphics.printf(
                    "You defeated " .. self.enemy.name,
                    GAME.width / 2 - 200, GAME.height / 3 - 50,
                    400, "center"
                )
            end
            
            -- Draw reward info
            love.graphics.setColor(1, 1, 0.5)
            love.graphics.printf(
                "Experience gained: " .. self.rewards.exp,
                GAME.width / 2 - 200, GAME.height / 3,
                400, "center"
            )
            
            -- Draw loot info
            if self.rewards.loot and #self.rewards.loot > 0 then
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.printf(
                    "Items obtained:",
                    GAME.width / 2 - 200, GAME.height / 3 + 50,
                    400, "center"
                )
                
                -- First, consolidate identical items
                local consolidatedLoot = {}
                for _, item in ipairs(self.rewards.loot) do
                    local found = false
                    for i, existingItem in ipairs(consolidatedLoot) do
                        if existingItem.name == item.name then
                            -- Increment count for existing item
                            existingItem.count = (existingItem.count or 1) + (item.count or 1)
                            found = true
                            break
                        end
                    end
                    if not found then
                        -- Add new item to consolidated list
                        local newEntry = {}
                        for k, v in pairs(item) do
                            newEntry[k] = v
                        end
                        -- Ensure count exists
                        newEntry.count = item.count or 1
                        table.insert(consolidatedLoot, newEntry)
                    end
                end
                
                -- Draw consolidated loot
                love.graphics.setFont(screenManager.fonts.small)
                local maxItemsToShow = 8 -- Limit displayed items if many
                local shownItems = math.min(#consolidatedLoot, maxItemsToShow)
                
                for i = 1, shownItems do
                    local item = consolidatedLoot[i]
                    -- Ensure item and item.name exist before trying to print
                    local itemName = (item and item.name) or "Unknown Item"
                    local text = itemName
                    
                    if item and item.count and item.count > 1 then
                        text = text .. " x" .. item.count
                    end
                    
                    love.graphics.printf(
                        text,
                        GAME.width / 2 - 200, GAME.height / 3 + 80 + (i - 1) * 20,
                        400, "center"
                    )
                end
                
                -- If there are more items than we can show
                if #consolidatedLoot > maxItemsToShow then
                    love.graphics.printf(
                        "... and " .. (#consolidatedLoot - maxItemsToShow) .. " more items",
                        GAME.width / 2 - 200, GAME.height / 3 + 80 + shownItems * 20,
                        400, "center"
                    )
                end
            end
            
            -- Ensure the continue button exists
            if not self.elements.continueButton then
                self.elements.continueButton = screenManager.UI.Button(
                    GAME.width / 2 - 125, GAME.height / 3 + 250,
                    250, 50, "Continue",
                    function() return true end
                )
            end
            
            -- Make sure it's visible
            self.elements.continueButton.visible = true
            self.elements.continueButton.color = {0.3, 0.7, 0.3}
            self.elements.continueButton.hoverColor = {0.4, 0.8, 0.4}
            
            -- Draw the continue button explicitly
            self.elements.continueButton:draw()
            
            -- Draw "Click Continue to exit" text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1, 0.7 + math.sin(love.timer.getTime() * 4) * 0.3)
            love.graphics.printf(
                "Click Continue to exit",
                GAME.width / 2 - 200, GAME.height / 2 + 50,
                400, "center"
            )
        end,
        
        -- Draw UI for defeat state
        drawDefeatUI = function(self)
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
        end,
        
        -- Add an entry to the combat log
        addLog = function(self, text, color)
            table.insert(self.log, {
                text = text,
                color = color or {1, 1, 1}
            })
        end,
        
        -- Handle player selecting an action
        selectAction = function(self, action)
            self.selectedAction = action
            
            -- Hide all lists
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            
            if action == "attack" then
                if #self.enemies > 1 then
                    -- For multiple enemies, show enemy selection UI
                    self:showEnemySelectionUI("attack")
                else
                    -- For single enemy, select it directly
                    self.selectedTarget = self.enemy
                    self:executePlayerAction()
                end
            elseif action == "skill" then
                -- Show skill list
                self:showSkillList()
            elseif action == "item" then
                -- Show item list
                self:showItemList()
            elseif action == "defend" then
                -- Execute defend action
                self:executeDefend()
            elseif action == "minion" then
                self:selectMinionCommand()
            end
        end,
        
        -- Show enemy selection UI for targeting
        showEnemySelectionUI = function(self, actionType)
            -- Create enemy selection UI if it doesn't exist
            if not self.elements.enemySelectList then
                self.elements.enemySelectList = {
                    visible = false,
                    x = GAME.width - 300, -- Position on right side of screen
                    y = 100, -- Higher on screen
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
                                
                                -- Draw HP info
                                love.graphics.setColor(0.8, 0.3, 0.3)
                                love.graphics.print("HP: " .. enemy.currentHP .. "/" .. enemy.maxHP, self.x + 120, y)
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
                                        print("Selected enemy: " .. enemies[i].name .. " (index: " .. i .. ")")
                                        
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
            self.elements.backButton.visible = true
        end,
        
        -- Confirm enemy selection
        confirmEnemySelection = function(self)
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
        end,
        
        -- Show skill list for current character
        showSkillList = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar then return end
            
            -- Prepare skill list
            self.elements.skillList.skills = {}
            
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
            
            -- Show skill list
            self.elements.skillList.visible = true
            
            -- Update confirm button callback to standard confirmation
            self.elements.confirmButton.callback = function()
                self:confirmAction()
            end
            
            -- Make sure buttons are visible
            self.elements.confirmButton.visible = true
            self.elements.backButton.visible = true
        end,
        
        -- Show item list
        showItemList = function(self)
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
        end,
        
        -- Confirm selected action
        confirmAction = function(self)
            if self.selectedAction == "skill" then
                -- Find selected skill
                local selectedSkill = nil
                for _, skill in ipairs(self.elements.skillList.skills) do
                    if skill.selected then
                        selectedSkill = skill
                        break
                    end
                end
                
                if selectedSkill then
                    -- Set selected skill
                    self.selectedSkill = selectedSkill.skill
                    
                    -- Determine target based on skill target type
                    if selectedSkill.skill.target == "single_enemy" then
                        if #self.enemies > 1 then
                            -- Show enemy selection UI
                            self:showEnemySelectionUI("skill")
                            return -- Wait for enemy selection
                        else
                            -- If only one enemy, target it directly
                            self.selectedTarget = self.enemy
                            self:executeSkill()
                        end
                    elseif selectedSkill.skill.target == "all_enemies" then
                        -- Target all enemies (handled in execution)
                        self.selectedTarget = nil -- Special case for all enemies
                        self:executeSkill()
                    elseif selectedSkill.skill.target == "single_ally" then
                        -- Show party selection UI instead of auto-targeting
                        self:showPartySelectionUI("skill")
                        return -- Wait for party selection
                    elseif selectedSkill.skill.target == "all_allies" then
                        -- Target all allies (handled in execution)
                        self.selectedTarget = self.party
                        -- Execute skill immediately
                        self:executeSkill()
                    elseif selectedSkill.skill.target == "self" then
                        self.selectedTarget = self.party[self.currentCharacter]
                        -- Execute skill immediately
                        self:executeSkill()
                    else
                        -- Default case for any other target types
                        self.selectedTarget = self.party[self.currentCharacter]
                        self:executeSkill()
                    end
                else
                    -- No skill selected, do nothing
                    self:addLog("No skill selected.", {1, 0.5, 0})
                    return
                end
            elseif self.selectedAction == "item" then
                -- Find selected item
                local selectedItem = nil
                for _, item in ipairs(self.elements.itemList.items) do
                    if item.selected then
                        selectedItem = item
                        break
                    end
                end
                
                if selectedItem then
                    -- Set selected item
                    self.selectedItem = selectedItem.item
                    
                    -- Check if item targets a single ally
                    if selectedItem.item.target == "single_ally" then
                        -- Show party selection UI
                        self:showPartySelectionUI("item")
                        return -- Wait for party selection
                    else
                        -- For other item types, target self for now
                        self.selectedTarget = self.party[self.currentCharacter]
                        -- Execute item use immediately
                        self:executeItemUse()
                    end
                else
                    -- No item selected, do nothing
                    self:addLog("No item selected.", {1, 0.5, 0})
                    return
                end
            end
            
            -- Hide lists
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            self.elements.partySelectList.visible = false
            if self.elements.enemySelectList then
                self.elements.enemySelectList.visible = false
            end
        end,
        
        -- Show party selection UI
        showPartySelectionUI = function(self, actionType)
            -- Hide other selection lists
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            
            -- Reset selection
            self.elements.partySelectList.selectedIndex = nil
            
            -- Show party selection list
            self.elements.partySelectList.visible = true
            
            -- Store the action type for later reference
            self.partySelectionActionType = actionType
            
            -- Since we're using auto-confirm, we only need the back button
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = true
        end,
        
        -- Confirm party member selection
        confirmPartySelection = function(self)
            -- Make sure party selection list exists and has a selectedIndex
            if not self.elements.partySelectList then
                print("Warning: Party selection list is missing")
                return
            end
            
            local selectedIndex = self.elements.partySelectList.selectedIndex
            
            -- Check if a party member was selected
            if not selectedIndex then
                self:addLog("No target selected.", {1, 0.5, 0})
                return
            end
            
            -- Set the selected party member as the target
            self.selectedTarget = self.party[selectedIndex]
            
            -- Hide party selection UI
            self.elements.partySelectList.visible = false
            
            -- Execute the action based on type
            if self.partySelectionActionType == "skill" then
                self:executeSkill()
            elseif self.partySelectionActionType == "item" then
                self:executeItemUse()
            end
            
            -- Reset party selection tracking
            self.partySelectionActionType = nil
        end,
        
        -- Cancel current selection
        cancelSelection = function(self)
            -- Reset selection
            self.selectedAction = nil
            self.selectedTarget = nil
            self.selectedSkill = nil
            self.selectedItem = nil
            self.partySelectionActionType = nil
            self.enemySelectionActionType = nil
            
            -- Hide lists
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            self.elements.partySelectList.visible = false
            if self.elements.enemySelectList then
                self.elements.enemySelectList.visible = false
            end
            
            -- Make sure action buttons are visible again
            self.elements.attackButton.visible = true
            self.elements.skillButton.visible = true
            self.elements.itemButton.visible = true
            self.elements.defendButton.visible = true
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = false
        end,
        
        -- Execute player's selected action
        executePlayerAction = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar then return end
            
            -- Execute attack
            if self.selectedAction == "attack" then
                -- Ensure character has attack power
                if not currentChar.attackPower or type(currentChar.attackPower) ~= "number" then
                    -- Force set character attack power if missing
                    currentChar.attackPower = currentChar.attributes and currentChar.attributes.STR or 10
                    if GAME.debug then
                        print("Fixed missing character attack power, set to: " .. currentChar.attackPower)
                    end
                end
                
                -- Get the target enemy (for backward compatibility, default to self.enemy if no specific target)
                local targetEnemy = self.selectedTarget or self.enemy
                
                -- Ensure enemy has defense
                if not targetEnemy.defense or type(targetEnemy.defense) ~= "number" then
                    targetEnemy.defense = 0
                    if GAME.debug then
                        print("Fixed missing enemy defense, set to: " .. targetEnemy.defense)
                    end
                end
                
                -- Calculate damage using explicit values
                local attackPower = currentChar.attackPower or 10  -- Default if missing
                local enemyDefense = targetEnemy.defense or 0       -- Default if missing
                
                -- Debug attack values
                if GAME.debug then
                    print("Player attack calculation:")
                    print("  Character: " .. currentChar.name)
                    print("  Attack power: " .. attackPower)
                    print("  Enemy defense: " .. enemyDefense)
                end
                
                -- Basic damage calculation with explicit values
                local damage = math.floor(attackPower - (enemyDefense / 2))
                
                -- Ensure minimum damage
                if damage < 1 then 
                    damage = 1
                    if GAME.debug then
                        print("  Adjusted to minimum damage: " .. damage)
                    end
                end
                
                -- Apply damage to enemy
                if not targetEnemy.currentHP or type(targetEnemy.currentHP) ~= "number" then
                    targetEnemy.currentHP = targetEnemy.maxHP or 20
                end
                
                -- Apply damage and ensure we don't go below 0
                targetEnemy.currentHP = targetEnemy.currentHP - damage
                if targetEnemy.currentHP < 0 then targetEnemy.currentHP = 0 end
                
                if GAME.debug then
                    print("  Enemy HP after attack: " .. targetEnemy.currentHP)
                end
                
                -- Add animation delay
                self.animationDelay = 0.5
                
                -- Play attack sound
                assetManager:playSound("attack")
                
                -- Add to combat log
                self:addLog(currentChar.name .. " attacks " .. targetEnemy.name .. " for " .. damage .. " damage!")
                
                -- Check for enemy defeat
                if targetEnemy.currentHP <= 0 then
                    -- Make sure to mark as inactive
                    targetEnemy.active = false
                    
                    if GAME.debug then
                        print("  Enemy defeated in executePlayerAction: " .. targetEnemy.name)
                    end
                    
                    self:enemyDefeated(targetEnemy)
                end
            end
            
            -- Ensure action buttons will be visible for next player's turn
            self.elements.attackButton.visible = true
            self.elements.skillButton.visible = true
            self.elements.itemButton.visible = true
            self.elements.defendButton.visible = true
            
            -- End turn after a short delay
            self.turnEndDelay = 0.7
        end,
        
        -- Execute skill use
        executeSkill = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar or not self.selectedSkill then 
                if GAME.debug then
                    print("executeSkill failed: ", currentChar and "Character OK" or "No character", 
                          self.selectedSkill and "Skill OK" or "No skill")
                end
                return 
            end
            
            -- Log skill execution for debugging
            if GAME.debug then
                print("Executing skill: " .. self.selectedSkill.name)
                print("  Target type: " .. (self.selectedSkill.target or "unknown"))
                print("  Selected target: " .. (self.selectedTarget and self.selectedTarget.name or "none/all"))
            end
            
            -- Check target for single-enemy skills
            if self.selectedSkill.target == "single_enemy" and not self.selectedTarget then
                self:addLog("No valid target for skill.", {1, 0.5, 0})
                if GAME.debug then print("Missing target for skill " .. self.selectedSkill.name) end
                return
            end
            
            -- Check MP cost
            if currentChar.currentMP < self.selectedSkill.mpCost then
                self:addLog("Not enough MP!")
                return
            end
            
            -- Deduct MP
            currentChar.currentMP = currentChar.currentMP - self.selectedSkill.mpCost
            
            -- Add animation delay
            self.animationDelay = 0.5
            
            -- Handle summon skills specifically
            if self.selectedSkill.type == "summon" then
                -- Play summon sound
                assetManager:playSound("spell")
                
                -- Process the summon
                local success = self:processSummonSkill(currentChar, self.selectedSkill)
                
                if success then
                    -- Recalculate turn order to include new minion
                    self:determineTurnOrder()
                end
                
                -- End turn after a short delay
                self.turnEndDelay = 0.7
                return
            end
            
            -- Special case for Steal skill
            if self.selectedSkill.name == "Steal" then
                self:executeStealSkill(currentChar)
                return
            end
            
            -- Handle different skill targets
            if self.selectedSkill.target == "single_enemy" then
                -- Apply damage to the selected enemy
                local damage, isCritical = 0, false
                
                -- Make sure character has this skill before calculating damage
                if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                    damage, isCritical = skillSystem:calculateDamage(
                        self.selectedSkill,
                        currentChar,
                        self.selectedTarget,
                        currentChar.skills[self.selectedSkill.name].level
                    )
                else
                    -- Fallback if skill level is not found
                    damage, isCritical = skillSystem:calculateDamage(
                        self.selectedSkill,
                        currentChar,
                        self.selectedTarget,
                        1
                    )
                end
                
                self.selectedTarget.currentHP = math.max(0, self.selectedTarget.currentHP - damage)
                
                -- Play appropriate sound
                if self.selectedSkill.type == "magical" then
                    assetManager:playSound("spell")
                else
                    assetManager:playSound("attack")
                end
                
                -- Add to combat log
                local logText = currentChar.name .. " uses " .. self.selectedSkill.name
                logText = logText .. " on " .. self.selectedTarget.name
                logText = logText .. " for " .. damage .. " damage!"
                
                if isCritical then
                    logText = logText .. " Critical hit!"
                end
                
                self:addLog(logText)
                
                -- Apply skill effects
                if self.selectedSkill.effect then
                    self:applySkillEffect(self.selectedSkill, currentChar, self.selectedTarget)
                end
                
                -- Check for enemy defeat
                if self.selectedTarget.currentHP <= 0 then
                    self:enemyDefeated(self.selectedTarget)
                end
            elseif self.selectedSkill.target == "all_enemies" then
                -- Apply to all enemies
                local totalDamage = 0
                local defeatedCount = 0
                
                for _, enemy in ipairs(self.enemies) do
                    if enemy.active then
                        local damage, isCritical = 0, false
                        
                        -- Calculate damage for each enemy
                        if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                            damage, isCritical = skillSystem:calculateDamage(
                                self.selectedSkill,
                                currentChar,
                                enemy,
                                currentChar.skills[self.selectedSkill.name].level
                            )
                        else
                            damage, isCritical = skillSystem:calculateDamage(
                                self.selectedSkill,
                                currentChar,
                                enemy,
                                1
                            )
                        end
                        
                        -- Apply damage with AOE reduction
                        local aoeReduction = 0.8 -- Reduce damage for AOE attacks
                        damage = math.floor(damage * aoeReduction)
                        enemy.currentHP = math.max(0, enemy.currentHP - damage)
                        totalDamage = totalDamage + damage
                        
                        -- Apply skill effects
                        if self.selectedSkill.effect then
                            self:applySkillEffect(self.selectedSkill, currentChar, enemy)
                        end
                        
                        -- Check for enemy defeat
                        if enemy.currentHP <= 0 and enemy.active then
                            enemy.active = false
                            defeatedCount = defeatedCount + 1
                        end
                    end
                end
                
                -- Play appropriate sound
                if self.selectedSkill.type == "magical" then
                    assetManager:playSound("spell")
                else
                    assetManager:playSound("attack")
                end
                
                -- Add to combat log
                local logText = currentChar.name .. " uses " .. self.selectedSkill.name
                logText = logText .. " on all enemies for " .. totalDamage .. " total damage!"
                self:addLog(logText)
                
                -- Log defeated enemies if any
                if defeatedCount > 0 then
                    self:addLog(defeatedCount .. " enemies were defeated!", {0, 1, 0})
                    
                    -- Check if all enemies are defeated
                    self:checkAllEnemiesDefeated()
                end
            elseif self.selectedSkill.target == "single_ally" or 
                   self.selectedSkill.target == "self" then
                -- Handle healing
                if self.selectedSkill.formula == "healing" then
                    local healing = 0
                    -- Make sure character has this skill
                    if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                        healing = skillSystem:calculateDamage(
                            self.selectedSkill,
                            currentChar,
                            self.selectedTarget,
                            currentChar.skills[self.selectedSkill.name].level
                        )
                    else
                        healing = skillSystem:calculateDamage(
                            self.selectedSkill,
                            currentChar,
                            self.selectedTarget,
                            1
                        )
                    end
                    
                    self.selectedTarget.currentHP = math.min(
                        self.selectedTarget.maxHP,
                        self.selectedTarget.currentHP + healing
                    )
                    
                    -- Play heal sound
                    assetManager:playSound("spell")
                    
                    -- Add to combat log
                    if self.selectedTarget == currentChar then
                        self:addLog(
                            currentChar.name .. " uses " .. self.selectedSkill.name .. 
                            " and heals self for " .. healing .. " HP!",
                            {0.2, 0.8, 0.2}
                        )
                    else
                        self:addLog(
                            currentChar.name .. " uses " .. self.selectedSkill.name .. 
                            " and heals " .. self.selectedTarget.name .. " for " .. healing .. " HP!",
                            {0.2, 0.8, 0.2}
                        )
                    end
                end
                
                -- Apply skill effects
                if self.selectedSkill.effect then
                    self:applySkillEffect(self.selectedSkill, currentChar, self.selectedTarget)
                end
            elseif self.selectedSkill.target == "all_allies" then
                -- Apply to all party members
                for _, ally in ipairs(self.party) do
                    if ally.active then
                        -- Handle healing
                        if self.selectedSkill.formula == "healing" then
                            local healing = 0
                            -- Make sure character has this skill
                            if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                                healing = skillSystem:calculateDamage(
                                    self.selectedSkill,
                                    currentChar,
                                    ally,
                                    currentChar.skills[self.selectedSkill.name].level
                                )
                            else
                                healing = skillSystem:calculateDamage(
                                    self.selectedSkill,
                                    currentChar,
                                    ally,
                                    1
                                )
                            end
                            
                            ally.currentHP = math.min(
                                ally.maxHP,
                                ally.currentHP + healing
                            )
                        end
                        
                        -- Apply skill effects
                        if self.selectedSkill.effect then
                            self:applySkillEffect(self.selectedSkill, currentChar, ally)
                        end
                    end
                end
                
                -- Play heal sound
                assetManager:playSound("spell")
                
                -- Add to combat log
                self:addLog(
                    currentChar.name .. " uses " .. self.selectedSkill.name .. 
                    " on the entire party!",
                    {0.2, 0.8, 0.2}
                )
            elseif self.selectedSkill.target == "none" then
                -- Handle target-less skills (like some summons)
                -- Play appropriate sound
                assetManager:playSound("spell")
                
                -- Add to combat log
                self:addLog(
                    currentChar.name .. " uses " .. self.selectedSkill.name .. "!",
                    {0.5, 0.5, 1}
                )
            end
            
            -- Make sure action buttons will be visible for next turn
            self.elements.attackButton.visible = true
            self.elements.skillButton.visible = true
            self.elements.itemButton.visible = true
            self.elements.defendButton.visible = true
            
            -- End turn after a short delay
            self.turnEndDelay = 0.7
        end,
        
        -- Execute steal skill
        executeStealSkill = function(self, character)
            -- Play effect sound
            assetManager:playSound("spell")
            
            -- Calculate steal chance based on character level and enemy level
            local effect = nil
            if character.skills and character.skills.Steal then
                effect = skillSystem:calculateSkillEffect(
                    self.selectedSkill, 
                    character, 
                    self.enemy, 
                    character.skills.Steal.level
                )
            else
                effect = skillSystem:calculateSkillEffect(
                    self.selectedSkill, 
                    character, 
                    self.enemy, 
                    1
                )
            end
            
            local stealChance = effect.stealChance or 0.3
            
            -- Add character DEX bonus
            if character.attributes and character.attributes.DEX then
                stealChance = stealChance + (character.attributes.DEX / 100)
            end
            
            -- Subtract enemy level penalty
            if self.enemy.stats and self.enemy.stats.level then
                stealChance = stealChance - (self.enemy.stats.level * 0.02)
            end
            
            -- Clamp steal chance
            stealChance = math.max(0.1, math.min(0.8, stealChance))
            
            -- Try to steal
            if math.random() < stealChance then
                -- Success! Generate a random item
                local stolenItem = itemSystem:generateRandomItem(self.enemy.stats.level or 1)
                
                -- Add item to inventory
                itemSystem:addToInventory(stolenItem)
                
                -- Add to combat log
                self:addLog(
                    character.name .. " successfully steals " .. stolenItem.name .. "!",
                    {0.2, 0.8, 0.8}
                )
            else
                -- Failed to steal
                self:addLog(
                    character.name .. " fails to steal anything!",
                    {0.8, 0.5, 0.2}
                )
            end
            
            -- Make sure buttons are visible
            self.elements.attackButton.visible = true
            self.elements.skillButton.visible = true
            self.elements.itemButton.visible = true
            self.elements.defendButton.visible = true
            
            -- End turn after a short delay
            self.turnEndDelay = 0.7
        end,
        
        -- Apply skill effect to target
        applySkillEffect = function(self, skill, caster, target)
            if not skill.effect then return end
            
            local skillLevel = 1
            -- Safely get the skill level if it exists
            if caster.skills and caster.skills[skill.name] and caster.skills[skill.name].level then
                skillLevel = caster.skills[skill.name].level
            end
            
            local effect = skillSystem:calculateSkillEffect(
                skill,
                caster,
                target,
                skillLevel
            )
            
            -- Apply status effects
            if effect.stat then
                -- Single stat effect
                target.status[effect.stat] = {
                    value = effect.value,
                    duration = effect.duration
                }
                
                -- Add to combat log
                self:addLog(
                    target.name .. " is affected by " .. effect.stat .. "!",
                    {0.8, 0.8, 0.2}
                )
            elseif effect.stats then
                -- Multiple stat effects
                for stat, value in pairs(effect.stats) do
                    target.status[stat] = {
                        value = value,
                        duration = effect.duration
                    }
                end
                
                -- Add to combat log
                self:addLog(
                    target.name .. " is affected by multiple status effects!",
                    {0.8, 0.8, 0.2}
                )
            end
            
            -- Handle special effects
            if effect.removeStatus then
                -- Remove status effects
                if effect.removeStatus == "negative" then
                    -- List of negative status effects
                    local negativeEffects = {
                        "poison", "sleep", "paralysis", "silence", "blind"
                    }
                    
                    for _, status in ipairs(negativeEffects) do
                        if target.status[status] then
                            target.status[status] = nil
                        end
                    end
                    
                    -- Add to combat log
                    self:addLog(
                        target.name .. "'s negative status effects are removed!",
                        {0.2, 0.8, 0.2}
                    )
                else
                    -- Remove specific status
                    if target.status[effect.removeStatus] then
                        target.status[effect.removeStatus] = nil
                        
                        -- Add to combat log
                        self:addLog(
                            target.name .. "'s " .. effect.removeStatus .. " is removed!",
                            {0.2, 0.8, 0.2}
                        )
                    end
                end
            end
        end,
        
        -- Execute item use
        executeItemUse = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar or not self.selectedItem then return end
            
            -- Make sure we have a valid target
            if not self.selectedTarget then
                self:addLog("No target selected for item use.", {1, 0.5, 0})
                return
            end
            
            -- Use item on target
            local success = itemSystem:useItem(self.selectedItem, self.selectedTarget)
            
            if success then
                -- Play pickup sound
                assetManager:playSound("pickup")
                
                -- Add to combat log
                if self.selectedTarget == currentChar then
                    self:addLog(
                        currentChar.name .. " uses " .. self.selectedItem.name .. " on self!",
                        {0.2, 0.8, 0.8}
                    )
                else
                    self:addLog(
                        currentChar.name .. " uses " .. self.selectedItem.name .. " on " .. self.selectedTarget.name .. "!",
                        {0.2, 0.8, 0.8}
                    )
                end
                
                -- Remove item from inventory
                if GAME.inventory then
                    for i, item in ipairs(GAME.inventory) do
                        if item.name == self.selectedItem.name then
                            if item.count and item.count > 1 then
                                item.count = item.count - 1
                            else
                                table.remove(GAME.inventory, i)
                            end
                            break
                        end
                    end
                end
                
                -- End turn after a short delay
                self.turnEndDelay = 0.7
            else
                -- Item use failed
                self:addLog("Item use failed!")
            end
        end,
        
        -- Execute defend action
        executeDefend = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar then return end
            
            -- Apply defense buff
            currentChar.status.defending = {
                value = 2.0,  -- Double defense
                duration = 1  -- Until next turn
            }
            
            -- Add to combat log
            self:addLog(currentChar.name .. " takes a defensive stance!")
            
            -- End turn after a short delay (like other actions)
            self.turnEndDelay = 0.5 -- Use a short delay consistent with others or adjust as needed
        end,
        
        -- Move to next character's turn
        nextTurn = function(self)
            -- Mark the current character's turn as taken
            if self.state == combatSystem.STATE.PLAYER_TURN and 
               self.currentCharacter >= 1 and 
               self.currentCharacter <= #self.party then
                self.charactersTurnTaken[self.currentCharacter] = true
            end
            
            -- If we're in minion turn, mark the current minion's turn as taken
            if self.state == combatSystem.STATE.MINION_TURN and self.activeMinion then
                local charIndex = self.activeMinion.charIndex
                local minionIndex = self.activeMinion.minionIndex
                
                if not self.minionsTurnTaken[charIndex] then
                    self.minionsTurnTaken[charIndex] = {}
                end
                
                self.minionsTurnTaken[charIndex][minionIndex] = true
            end
            
            -- Find next character with an untaken turn
            local foundCharacter = false
            for i = 1, #self.party do
                local idx = (self.currentCharacter + i - 1) % #self.party + 1 -- Cycle through characters starting from current+1
                if self.party[idx].active and not self.charactersTurnTaken[idx] then
                    self.currentCharacter = idx
                    foundCharacter = true
                    self.state = combatSystem.STATE.PLAYER_TURN
                    
                    -- Reset selection state for new character turn
                    self.selectedAction = nil
                    self.selectedTarget = nil
                    self.selectedSkill = nil
                    self.selectedItem = nil
                    
                    -- Hide any selection lists
                    self.elements.skillList.visible = false
                    self.elements.itemList.visible = false
                    self.elements.partySelectList.visible = false
                    if self.elements.enemySelectList then
                        self.elements.enemySelectList.visible = false
                    end
                    
                    -- Show action buttons for the new turn
                    self.elements.attackButton.visible = true
                    self.elements.skillButton.visible = true
                    self.elements.itemButton.visible = true
                    self.elements.defendButton.visible = true
                    self.elements.confirmButton.visible = false
                    self.elements.backButton.visible = false
                    
                    -- Log new character turn
                    self:addLog(self.party[self.currentCharacter].name .. "'s turn begins", {0.5, 0.5, 1})
                    
                    break
                end
            end
            
            -- If no characters have untaken turns, check for minions with untaken turns
            if not foundCharacter then
                local foundMinion = false
                
                -- Check for any active minions with untaken turns
                for charIndex, minions in pairs(self.minions) do
                    if self.party[charIndex] and self.party[charIndex].active then -- Only consider minions of active characters
                        for minionIndex, minion in pairs(minions) do
                            -- Check if minion is active, takes actions, and hasn't had its turn yet
                            if minion.active and minion.takesActions and 
                              (not self.minionsTurnTaken[charIndex] or not self.minionsTurnTaken[charIndex][minionIndex]) then
                                
                                -- Set active minion
                                self.activeMinion = {
                                    charIndex = charIndex,
                                    minionIndex = minionIndex
                                }
                                
                                foundMinion = true
                                self.state = combatSystem.STATE.MINION_TURN
                                
                                -- Initialize minion turn delay
                                self.minionTurnDelay = 0.8
                                
                                -- Add log entry
                                self:addLog(minion.name .. "'s turn begins", {0.5, 0.7, 1})
                                
                                break
                            end
                        end
                        if foundMinion then break end
                    end
                end
                
                -- If all characters and minions have taken turns, move to enemy turn
                if not foundMinion then
                    -- Check if all party members are inactive
                    local allInactive = true
                    for _, character in ipairs(self.party) do
                        if character.active then
                            allInactive = false
                            break
                        end
                    end
                    
                    if allInactive then
                        -- All party members are defeated
                        self:partyDefeated()
                        return
                    end
                    
                    -- No minions to act, proceed to enemy turn
                    self.state = combatSystem.STATE.ENEMY_TURN
                    
                    -- Reset enemy turn delay to force initialization
                    self.enemyTurnDelay = nil
                    
                    -- Reset player turns for the next round
                    for i = 1, #self.party do
                        self.charactersTurnTaken[i] = false
                    end
                    
                    -- Reset minion turns for the next round
                    for charIndex, turnData in pairs(self.minionsTurnTaken) do
                        for minionIndex, _ in pairs(turnData) do
                            self.minionsTurnTaken[charIndex][minionIndex] = false
                        end
                    end
                end
            end
            
            -- Move to the next enemy's turn (if we're in enemy state)
            if self.state == combatSystem.STATE.ENEMY_TURN then
                self.activeEnemyIndex = 1  -- Start with the first enemy
            end
        end,
        
        -- Handle party defeat
        partyDefeated = function(self)
            self:addLog("The party has been defeated!", {1, 0, 0})
            
            -- Set defeat state
            self.state = combatSystem.STATE.DEFEAT
            
            -- Create continue button
            self.elements.continueButton = screenManager.UI.Button(
                GAME.width / 2 - 100, GAME.height / 2 + 100,
                200, 40, "Continue",
                function() return true end
            )
            self.elements.continueButton.visible = true
            
            -- Hide combat UI elements
            self.elements.attackButton.visible = false
            self.elements.skillButton.visible = false
            self.elements.itemButton.visible = false
            self.elements.defendButton.visible = false
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = false
        end,
        
        -- Check if combat is over
        isOver = function(self)
            return self.state == combatSystem.STATE.VICTORY or 
                   self.state == combatSystem.STATE.DEFEAT
        end,
        
        -- Check if combat ended in victory
        isVictory = function(self)
            return self.state == combatSystem.STATE.VICTORY
        end,
        
        -- Get combat rewards
        getLoot = function(self)
            if self.state == combatSystem.STATE.VICTORY and self.rewards then
                return self.rewards.loot
            end
            return nil
        end,
        
        -- Handle enemy being defeated
        enemyDefeated = function(self, enemy)
            -- Make sure enemy is marked as inactive
            enemy.active = false
            
            -- Add to combat log
            self:addLog(enemy.name .. " was defeated!", {0, 1, 0})
            
            -- Check if all enemies are defeated
            self:checkAllEnemiesDefeated()
        end,
        
        -- Check if all enemies are defeated
        checkAllEnemiesDefeated = function(self)
            local allDefeated = true
            
            -- Check all enemies
            for _, enemy in ipairs(self.enemies) do
                if enemy.active then
                    allDefeated = false
                    break
                end
            end
            
            -- If all enemies are defeated, trigger victory
            if allDefeated then
                self:victory()
            end
        end,
        
        -- Handle keypresses
        keypressed = function(self, key)
            if self:isOver() then
                -- Remove keyboard shortcut for exiting combat
                return false
            end
            return false
        end,
        
        -- Handle mouse clicks
        mousepressed = function(self, x, y, button)
            -- Check if combat is over
            if self:isOver() then
                if button == 1 and self.elements.continueButton then
                    -- Check continue button explicitly
                    if self.elements.continueButton:clicked(x, y, button) then
                        if GAME.debug then
                            print("Continue button clicked, returning true to exit combat")
                        end
                        return true
                    end
                    
                    -- Also check if coordinates are within the button bounds
                    if x >= self.elements.continueButton.x and
                       x <= self.elements.continueButton.x + self.elements.continueButton.width and
                       y >= self.elements.continueButton.y and
                       y <= self.elements.continueButton.y + self.elements.continueButton.height then
                        if GAME.debug then
                            print("Clicked in continue button bounds, returning true to exit combat")
                        end
                        return true
                    end
                end
                
                -- TEMPORARY FIX: Exit combat on any click in victory state
                if self.state == combatSystem.STATE.VICTORY and button == 1 then
                    if GAME.debug then
                        print("TEMPORARY FIX: Exiting combat on any click during victory state")
                    end
                    return true
                end
                
                -- In victory/defeat state, any click should do nothing else
                return false
            end

            -- If combat is NOT over, proceed with player turn logic
            if self.state ~= combatSystem.STATE.PLAYER_TURN then
                return false
            end
            
            -- Check UI element clicks during player turn
            if button == 1 then
                -- Check skill list clicks
                if self.elements.skillList and self.elements.skillList.visible and self.elements.skillList:clicked(x, y) then
                    return false 
                end
                
                -- Check item list clicks
                if self.elements.itemList and self.elements.itemList.visible and self.elements.itemList:clicked(x, y) then
                    return false 
                end
                
                -- Check party selection list clicks
                if self.elements.partySelectList and self.elements.partySelectList.visible and self.elements.partySelectList:clicked(x, y) then
                    return false
                end
                
                -- Check enemy selection list clicks
                if self.elements.enemySelectList and self.elements.enemySelectList.visible and self.elements.enemySelectList:clicked(x, y) then
                    return false
                end
                
                -- Check other button clicks (Attack, Skill, Item, Defend, Confirm, Back)
                for name, element in pairs(self.elements) do
                    -- Exclude lists and the continue button (handled above)
                    if element.clicked and element ~= self.elements.skillList and 
                       element ~= self.elements.itemList and 
                       element ~= self.elements.partySelectList and
                       element ~= self.elements.enemySelectList and
                       element ~= self.elements.continueButton then
                        
                        if element.visible ~= false and element:clicked(x, y, button) then
                            return false
                        end
                    end
                end
            end
            
            return false
        end,
        
        -- UI handler for clicks on the UI
        handleUIClick = function(self)
            -- Selection UI for actions that need targets
            if self.selectedAction then
                if self.selectedAction == "skill" then
                    -- Show skill selection UI if needed
                    if not self.selectedSkill then
                        self.elements.skillList.visible = true
                        self.elements.attackButton.visible = false
                        self.elements.skillButton.visible = false
                        self.elements.itemButton.visible = false
                        self.elements.defendButton.visible = false
                    end
                elseif self.selectedAction == "item" then
                    -- Show item selection UI if needed
                    if not self.selectedItem then
                        self.elements.itemList.visible = true
                        self.elements.attackButton.visible = false
                        self.elements.skillButton.visible = false
                        self.elements.itemButton.visible = false
                        self.elements.defendButton.visible = false
                    end
                end
            end
        end,
        
        -- Draw minions UI
        drawMinions = function(self)
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
        end,

        -- Process summon skill
        processSummonSkill = function(self, character, skillData)
            -- Get skill level
            local skillLevel = 1
            if character.skills[skillData.name] then
                skillLevel = character.skills[skillData.name].level
            end
            
            -- Get stat modifier if defined in skill level modifier
            local statModifier = 1
            local duration = skillData.duration or 0
            
            if skillData.levelModifier then
                local modData = skillData.levelModifier(skillLevel)
                
                if type(modData) == "table" then
                    statModifier = modData.statModifier or 1
                    
                    if modData.duration then
                        duration = modData.duration
                    end
                    
                    -- Scale passive buffs for spirits
                    if modData.passiveBuffs and skillData.summonType == "spirit" then
                        for stat, value in pairs(modData.passiveBuffs) do
                            skillData.summonStats.passiveBuffs[stat] = value
                        end
                    end
                else
                    statModifier = modData
                end
            end
            
            -- Apply stat modifier to summon stats
            local summonStats = {}
            for k, v in pairs(skillData.summonStats) do
                if type(v) == "number" and k ~= "color" then
                    summonStats[k] = v * statModifier
                else
                    summonStats[k] = v
                end
            end
            
            -- Add required additional properties for battle
            summonStats.active = true
            summonStats.takesActions = true  -- Most summons take actions in battle
            summonStats.type = skillData.summonType  -- Ensure type is set for UI rendering
            summonStats.element = skillData.element   -- Set element if applicable
            
            -- Make sure currentHP is set to maxHP initially
            summonStats.currentHP = summonStats.maxHP
            
            -- Ensure abilities array exists
            if not summonStats.abilities then
                summonStats.abilities = {}
            end
            
            -- Set owner info
            summonStats.owner = {
                name = character.name,
                index = self.currentCharacter  -- Store the character index for reference
            }
            
            -- Create the minion
            local minion = minionManager:summonMinion(
                character,
                skillData.summonType,
                skillData.summonStats.name,
                summonStats,
                duration
            )
            
            if GAME.debug then
                print("Summoned minion: " .. minion.name)
                print("  Type: " .. (minion.type or "none"))
                print("  takesActions: " .. tostring(minion.takesActions))
                print("  HP: " .. minion.currentHP .. "/" .. minion.maxHP)
                if minion.abilities and #minion.abilities > 0 then
                    print("  Abilities: " .. table.concat(minion.abilities, ", "))
                end
            end
            
            -- Add log message
            self:addLog(character.name .. " summoned " .. minion.name .. "!", {0.5, 0.8, 1})
            
            -- Update the current combat's minion list
            if not self.minions[self.currentCharacter] then
                self.minions[self.currentCharacter] = {}
            end
            
            -- Add to minions list for this combat
            table.insert(self.minions[self.currentCharacter], minion)
            local newMinionIndex = #self.minions[self.currentCharacter]
            
            -- Initialize turn tracking for this minion
            if not self.minionsTurnTaken then
                self.minionsTurnTaken = {}
            end
            
            if not self.minionsTurnTaken[self.currentCharacter] then
                self.minionsTurnTaken[self.currentCharacter] = {}
            end
            
            -- Mark that the minion hasn't taken a turn yet
            self.minionsTurnTaken[self.currentCharacter][newMinionIndex] = false
            
            -- Recalculate turn order to include the new minion
            self:determineTurnOrder()
            
            -- Return success
            return true
        end,
        
        -- Execute minion turn
        executeMinionTurn = function(self)
            if not self.activeMinion then
                if GAME.debug then
                    print("No active minion for turn execution")
                end
                return
            end
            
            local charIndex = self.activeMinion.charIndex
            local minionIndex = self.activeMinion.minionIndex
            
            if not self.party[charIndex] or 
               not self.minions[charIndex] or 
               not self.minions[charIndex][minionIndex] then
                -- Invalid minion, skip turn
                if GAME.debug then
                    print("Invalid minion references, skipping turn")
                end
                return
            end
            
            local minion = self.minions[charIndex][minionIndex]
            
            -- Add log entry
            self:addLog(minion.name .. " takes its turn!", {0.5, 0.7, 1})
            
            -- Process minion turn if active
            if minion.active and #self.enemies > 0 then
                -- Find active enemies
                local activeEnemies = {}
                for i, enemy in ipairs(self.enemies) do
                    if enemy.active then
                        table.insert(activeEnemies, i)
                    end
                end
                
                if #activeEnemies > 0 then
                    -- Choose random active enemy
                    local targetIndex = activeEnemies[math.random(#activeEnemies)]
                    local target = self.enemies[targetIndex]
                    
                    -- Determine if using ability or basic attack
                    local usingAbility = false
                    local abilityName = nil
                    local damage = 0
                    
                    if minion.abilities and #minion.abilities > 0 and math.random() > 0.4 then
                        -- Use random ability
                        abilityName = minion.abilities[math.random(#minion.abilities)]
                        local abilityData = skillSystem:getSkill(abilityName)
                        
                        if abilityData then
                            usingAbility = true
                            
                            -- Calculate damage based on ability type
                            if abilityData.type == "physical" then
                                damage = (minion.attackPower or 10) * (abilityData.basePower / 100)
                            elseif abilityData.type == "magical" then
                                damage = (minion.magicPower or 10) * (abilityData.basePower / 100)
                            else
                                damage = minion.attackPower or 10 -- Default to attack power for other types
                            end
                            
                            -- Ensure reasonable damage
                            damage = math.max(1, math.floor(damage))
                        end
                    end
                    
                    if usingAbility then
                        -- Execute ability
                        self:addLog(minion.name .. " uses " .. abilityName .. " on " .. target.name .. "!", {0.6, 0.6, 1})
                        
                        -- Apply damage
                        target.currentHP = math.max(0, target.currentHP - damage)
                        
                        -- Log damage
                        self:addLog(target.name .. " takes " .. damage .. " damage!", {1, 0.6, 0.6})
                        
                        -- Play appropriate sound
                        assetManager:playSound("spell")
                    else
                        -- Execute basic attack
                        self:addLog(minion.name .. " attacks " .. target.name .. "!", {0.7, 0.7, 0.7})
                        
                        -- Calculate basic attack damage
                        damage = minion.attackPower or 10
                        if target.defense then
                            damage = math.max(1, damage - (target.defense / 3))
                        end
                        damage = math.floor(damage)
                        
                        -- Apply damage
                        target.currentHP = math.max(0, target.currentHP - damage)
                        
                        -- Log damage
                        self:addLog(target.name .. " takes " .. damage .. " damage!", {1, 0.6, 0.6})
                        
                        -- Play attack sound
                        assetManager:playSound("attack")
                    end
                    
                    -- Check if enemy was defeated
                    if target.currentHP <= 0 then
                        target.currentHP = 0
                        target.active = false
                        self:addLog(target.name .. " was defeated!", {0, 1, 0})
                        
                        -- Check if all enemies are defeated
                        local allDefeated = true
                        for _, enemy in ipairs(self.enemies) do
                            if enemy.active then
                                allDefeated = false
                                break
                            end
                        end
                        
                        if allDefeated then
                            -- Add delay before triggering victory to show final messages
                            self:addLog("All enemies have been defeated!", {0, 1, 0.2})
                            self:addLog(minion.name .. " has dealt the final blow!", {0.3, 1, 0.7})
                            
                            -- Calculate rewards BEFORE setting victory state
                            self:calculateVictoryRewards()
                            
                            -- Set state directly to victory instead of continuing turn processing
                            self.state = combatSystem.STATE.VICTORY
                            
                            -- Use a longer delay before showing victory screen when minion delivers final blow
                            self.animationDelay = 2.0  -- Increased from 1.0
                            
                            -- Trigger victory directly with a delay
                            self.turnEndDelay = 1.5  -- Increased from 0.2
                            
                            -- We'll need a custom function to handle this delayed victory
                            self.pendingVictory = true
                            
                            -- Important: Return immediately to prevent further turn processing
                            return
                        end
                    end
                else
                    -- No active enemies
                    self:addLog(minion.name .. " has no targets.", {0.7, 0.7, 0.7})
                end
            else
                -- Minion can't act
                if not minion.active then
                    self:addLog(minion.name .. " is inactive and can't take a turn.", {0.5, 0.5, 0.5})
                elseif #self.enemies == 0 then
                    self:addLog(minion.name .. " has no enemies to target.", {0.5, 0.5, 0.5})
                end
            end
            
            -- Add delay before next turn
            self.turnEndDelay = 0.7
        end,

        -- Handle victory state
        victory = function(self)
            -- Set victory state immediately to block any other processing
            self.state = combatSystem.STATE.VICTORY
            
            -- Calculate rewards (safe to call multiple times due to the rewardsCalculated check)
            self:calculateVictoryRewards()
            
            self:addLog("All enemies defeated!", {0, 1, 0})
            
            -- Grant experience to party members
            for _, character in ipairs(self.party) do
                if character.active then
                    local charSystem = require("gameplay/character")
                    charSystem:addExperience(character, self.rewards.exp)
                end
            end
            
            -- Handle minion persistence after battle
            minionManager:clearNonPersistentMinions()
            
            -- Create continue button
            self.elements.continueButton = screenManager.UI.Button(
                GAME.width / 2 - 125, GAME.height / 3 + 250,
                250, 50, "Continue",
                function() return true end
            )
            self.elements.continueButton.visible = true
            self.elements.continueButton.color = {0.3, 0.7, 0.3}
            self.elements.continueButton.hoverColor = {0.4, 0.8, 0.4}
            
            -- Hide combat UI elements
            self.elements.attackButton.visible = false
            self.elements.skillButton.visible = false
            self.elements.itemButton.visible = false
            self.elements.defendButton.visible = false
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            self.elements.confirmButton.visible = false
            self.elements.backButton.visible = false
            if self.elements.enemySelectList then
                self.elements.enemySelectList.visible = false
            end
        end,
        
        -- Execute current enemy's turn
        executeEnemyTurn = function(self)
            -- Get the current active enemy
            local enemy = self.enemies[self.activeEnemyIndex]
            if not enemy or not enemy.active then
                -- Skip the turn if the enemy is inactive
                if self.activeEnemyIndex < #self.enemies then
                    -- Try the next enemy
                    self.activeEnemyIndex = self.activeEnemyIndex + 1
                    return
                else
                    -- No more enemies to act
                    self:nextTurn()
                    return
                end
            end
            
            -- Check for valid targets (party members and minions)
            local validTargets = {}
            
            -- Add active party members to valid targets
            for i, character in ipairs(self.party) do
                if character.active then
                    table.insert(validTargets, { type = "player", index = i })
                end
            end
            
            -- Add active minions to valid targets
            for charIndex, minions in pairs(self.minions) do
                for minionIndex, minion in pairs(minions) do
                    if minion.active then
                        table.insert(validTargets, { 
                            type = "minion", 
                            charIndex = charIndex, 
                            minionIndex = minionIndex 
                        })
                    end
                end
            end
            
            -- If no valid targets, party must be defeated
            if #validTargets == 0 then
                self:partyDefeated()
                return
            end
            
            -- Select a random target from valid targets
            local targetInfo = validTargets[math.random(#validTargets)]
            local targetName = ""
            local damage = 0
            
            if targetInfo.type == "player" then
                -- Target is a player character
                local target = self.party[targetInfo.index]
                targetName = target.name
                
                -- Calculate damage
                local attackPower = enemy.attackPower or enemy.stats.attack or 10
                local defense = target.defense or 5
                
                -- Basic damage calculation
                damage = math.floor(attackPower - (defense / 2))
                damage = math.max(1, damage) -- Ensure minimum damage
                
                -- Apply damage to character
                target.currentHP = math.max(0, target.currentHP - damage)
                
                -- Check if character is defeated
                if target.currentHP <= 0 then
                    target.currentHP = 0
                    target.active = false
                    
                    -- Add to combat log
                    self:addLog(target.name .. " is defeated!", {1, 0, 0})
                    
                    -- Check if all party members are defeated
                    local allDefeated = true
                    for _, char in ipairs(self.party) do
                        if char.active then
                            allDefeated = false
                            break
                        end
                    end
                    
                    if allDefeated then
                        self:partyDefeated()
                        return
                    end
                end
            elseif targetInfo.type == "minion" then
                -- Target is a minion
                local minion = self.minions[targetInfo.charIndex][targetInfo.minionIndex]
                targetName = minion.name
                
                -- Calculate damage
                local attackPower = enemy.attackPower or enemy.stats.attack or 10
                local defense = minion.defense or 5
                
                -- Basic damage calculation
                damage = math.floor(attackPower - (defense / 2))
                damage = math.max(1, damage) -- Ensure minimum damage
                
                -- Apply damage to minion
                minion.currentHP = math.max(0, minion.currentHP - damage)
                
                -- Check if minion is defeated
                if minion.currentHP <= 0 then
                    minion.currentHP = 0
                    minion.active = false
                    
                    -- Add to combat log
                    self:addLog(minion.name .. " is defeated!", {1, 0.3, 0.3})
                end
            end
            
            -- Add to combat log
            self:addLog(enemy.name .. " attacks " .. targetName .. " for " .. damage .. " damage!", {1, 0.5, 0.5})
            
            -- Play attack sound
            assetManager:playSound("attack")
            
            -- Increment to next enemy or move to next turn
            self.activeEnemyIndex = self.activeEnemyIndex + 1
            if self.activeEnemyIndex > #self.enemies then
                -- All enemies have acted, move to next turn
                self.enemyTurnDelay = 0.5
            else
                -- More enemies to act, set delay for the next enemy
                self.enemyTurnDelay = 0.7
            end
        end,
        
        -- Handle enemy being defeated
        enemyDefeated = function(self, enemy)
            -- Make sure enemy is marked as inactive
            enemy.active = false
            
            -- Add to combat log
            self:addLog(enemy.name .. " was defeated!", {0, 1, 0})
            
            -- Check if all enemies are defeated
            self:checkAllEnemiesDefeated()
        end,
        
        -- Check if all enemies are defeated
        checkAllEnemiesDefeated = function(self)
            local allDefeated = true
            
            -- Check all enemies
            for _, enemy in ipairs(self.enemies) do
                if enemy.active then
                    allDefeated = false
                    break
                end
            end
            
            -- If all enemies are defeated, trigger victory
            if allDefeated then
                self:victory()
            end
        end,
        
        -- Import existing minions from minionManager
        importExistingMinions = function(self)
            for i, character in ipairs(self.party) do
                -- Get minions from minionManager
                local charMinions = minionManager:getActiveMinions(character)
                
                if charMinions and #charMinions > 0 then
                    if GAME.debug then
                        print("Importing " .. #charMinions .. " existing minions for " .. character.name)
                    end
                    
                    -- Initialize this character's minion tracking
                    self.minions[i] = {}
                    self.minionsTurnTaken[i] = {}
                    
                    -- Add each minion
                    for j, minion in ipairs(charMinions) do
                        -- Ensure minion has required combat properties
                        minion.active = true
                        minion.takesActions = (minion.takesActions ~= false) -- Default to true unless explicitly false
                        
                        if minion.currentHP == nil then
                            minion.currentHP = minion.maxHP
                        end
                        
                        -- Store minion reference
                        self.minions[i][j] = minion
                        self.minionsTurnTaken[i][j] = false
                        
                        if GAME.debug then
                            print("Imported minion: " .. minion.name)
                            print("  HP: " .. minion.currentHP .. "/" .. minion.maxHP)
                            print("  Takes actions: " .. tostring(minion.takesActions))
                        end
                    end
                end
            end
        end,
        
        -- Calculate victory rewards
        calculateVictoryRewards = function(self)
            -- Skip if rewards were already calculated
            if self.rewardsCalculated then
                if GAME.debug then
                    print("Rewards already calculated, skipping")
                end
                return
            end
            
            -- Mark that rewards have been calculated
            self.rewardsCalculated = true
            
            -- Initialize rewards structure
            self.rewards = {
                exp = 0,
                loot = {}
            }
            
            -- Sum up experience and generate loot from all enemies
            for _, enemy in ipairs(self.enemies) do
                -- Add experience
                self.rewards.exp = self.rewards.exp + (enemy.stats.level * 100)
                
                -- Generate loot for each enemy and add to the total
                local enemyLoot = itemSystem:generateRandomLoot(enemy.stats.level)
                for _, item in ipairs(enemyLoot) do
                    table.insert(self.rewards.loot, item)
                end
            end
            
            if GAME.debug then
                print("Victory rewards calculated:")
                print("  Experience: " .. self.rewards.exp)
                print("  Loot items: " .. #self.rewards.loot)
            end
        end,
    }
    
    -- Initialize combat
    combat:init()
    
    return combat
end

return combatSystem

