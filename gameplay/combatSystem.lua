-- Combat System
-- Handles turn-based combat mechanics
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local assetManager = require("assets/assetManager")
local screenManager = require("screens/screenManager")

local combatSystem = {
    STATE = {
        INIT = 1,
        PLAYER_TURN = 2,
        ENEMY_TURN = 3,
        VICTORY = 4,
        DEFEAT = 5
    }
}

-- Create a new combat instance
function combatSystem:createCombat(party, enemy)
    local combat = {
        party = party,
        enemy = enemy,
        state = self.STATE.INIT,
        currentTurn = 1,
        currentCharacter = 1,
        log = {},
        selectedAction = nil,
        selectedTarget = nil,
        turnOrder = {},
        effects = {},
        
        -- Combat UI elements
        elements = {},
        
        -- Initialize combat
        init = function(self)
            -- Setup characters and enemy stats
            self:setupCombatants()
            
            -- Determine turn order
            self:determineTurnOrder()
            
            -- Create UI elements
            self:createUI()
            
            -- Initialize timing variables
            self.animationDelay = 0
            self.turnEndDelay = 0
            self.enemyTurnDelay = nil  -- Set to nil to force initialization
            
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
            
            -- Print debug message with current character and active status
            if GAME.debug then
                local status = {}
                for i=1, #self.party do
                    if self.party[i].active then
                        status[i] = "active"
                    else
                        status[i] = "inactive"
                    end
                end
                
                print("Combat initialized with " .. #self.party .. " characters")
                for i=1, #self.party do
                    print("Character " .. i .. ": " .. self.party[i].name .. " - " .. status[i])
                end
                print("Starting with character " .. self.currentCharacter .. ": " .. self.party[self.currentCharacter].name)
            end
            
            -- Add combat start message
            self:addLog("Combat started!")
            self:addLog(self.enemy.name .. " appeared!")
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
            
            -- Setup enemy
            if not self.enemy.name then
                self.enemy.name = "Monster #" .. self.enemy.id
            end
            
            if not self.enemy.maxHP then
                self.enemy.maxHP = self.enemy.stats.hp
                self.enemy.currentHP = self.enemy.maxHP
            end
            
            if not self.enemy.attackPower then
                self.enemy.attackPower = self.enemy.stats.attack
                self.enemy.defense = self.enemy.stats.defense
            end
            
            -- Setup enemy status effects
            self.enemy.status = {}
            
            -- Set enemy as active
            self.enemy.active = true
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
                end
            end
            
            -- Add enemy to turn order
            table.insert(self.turnOrder, {
                type = "enemy",
                index = 1,
                speed = self.enemy.stats.speed or 10
            })
            
            -- Sort by speed
            table.sort(self.turnOrder, function(a, b)
                return a.speed > b.speed
            end)
        end,
        
        -- Create UI elements
        createUI = function(self)
            -- Action buttons
            self.elements.attackButton = screenManager.UI.Button(
                50, GAME.height - 150, 
                150, 40, "Attack", 
                function() self:selectAction("attack") end
            )
            self.elements.attackButton.visible = true
            
            self.elements.skillButton = screenManager.UI.Button(
                210, GAME.height - 150, 
                150, 40, "Skills", 
                function() self:selectAction("skill") end
            )
            self.elements.skillButton.visible = true
            
            self.elements.itemButton = screenManager.UI.Button(
                370, GAME.height - 150, 
                150, 40, "Items", 
                function() self:selectAction("item") end
            )
            self.elements.itemButton.visible = true
            
            self.elements.defendButton = screenManager.UI.Button(
                530, GAME.height - 150, 
                150, 40, "Defend", 
                function() self:selectAction("defend") end
            )
            self.elements.defendButton.visible = true
            
            -- Skill list (hidden initially)
            self.elements.skillList = {
                visible = false,
                skills = {},
                x = 100,
                y = GAME.height - 250,
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
                x = 100,
                y = GAME.height - 250,
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
            
            -- Confirm button (for skills/items)
            self.elements.confirmButton = screenManager.UI.Button(
                360, GAME.height - 200, 
                120, 40, "Confirm", 
                function() self:confirmAction() end
            )
            self.elements.confirmButton.visible = false
            
            -- Back button (for skills/items)
            self.elements.backButton = screenManager.UI.Button(
                360, GAME.height - 150, 
                120, 40, "Back", 
                function() self:cancelSelection() end
            )
            self.elements.backButton.visible = false
        end,
        
        -- Update combat state
        update = function(self, dt)
            if GAME.debug then
                print("Update Start: State=", self.state, "Char=", self.currentCharacter, "TurnTaken=", self.charactersTurnTaken, "TurnDelay=", self.turnEndDelay, "EnemyDelay=", self.enemyTurnDelay)
            end
            
            -- Update UI elements
            for _, element in pairs(self.elements) do
                if element.update then
                    element:update(dt)
                end
            end
            
            -- Handle animation delay
            if self.animationDelay and self.animationDelay > 0 then
                self.animationDelay = self.animationDelay - dt
            end
            
            -- Handle turn end delay (used after player AND enemy actions)
            if self.turnEndDelay and self.turnEndDelay > 0 then
                self.turnEndDelay = self.turnEndDelay - dt
                return -- Wait for delay to complete
            elseif self.turnEndDelay and self.turnEndDelay <= 0 then
                self.turnEndDelay = nil
                if GAME.debug then print("Turn end delay finished, calling nextTurn from update") end
                self:nextTurn() -- Proceed to the actual next turn logic
                return -- <<<< ADDED RETURN: Stop processing after nextTurn call
            end
            
            -- Handle state-specific updates (only if turnEndDelay is not active)
            if self.state == combatSystem.STATE.PLAYER_TURN then
                -- Check if the designated current character is inactive
                local currentChar = self.party[self.currentCharacter]
                if not currentChar or not currentChar.active then
                    if GAME.debug then print("Character " .. self.currentCharacter .. " is inactive at start of their turn check, calling nextTurn") end
                    self:nextTurn() -- Skip their turn
                    return -- <<<< ADDED RETURN: Stop processing after nextTurn call
                end
                
                -- No actual turn logic here; actions are triggered by UI clicks which set turnEndDelay
                
            elseif self.state == combatSystem.STATE.ENEMY_TURN then
                -- Enemy turn logic
                if self.enemyTurnDelay == nil then
                    -- Initialize delay if not set
                    self.enemyTurnDelay = 1.0  -- 1 second delay
                    if GAME.debug then print("Enemy turn delay initialized to 1.0") end
                    return -- Wait for next update cycle
                end
                
                -- Update delay timer
                if self.enemyTurnDelay > 0 then
                    self.enemyTurnDelay = self.enemyTurnDelay - dt
                    
                    if self.enemyTurnDelay <= 0 then
                        -- Delay finished, execute enemy action
                        if GAME.debug then print("Enemy turn delay complete, executing enemy turn") end
                        self:executeEnemyTurn() -- This function SHOULD set self.turnEndDelay
                        self.enemyTurnDelay = nil -- Clear enemy specific delay, now wait for general turnEndDelay
                        -- No return here, let the frame finish. turnEndDelay handles the next step.
                    end
                end
            end
            
            if GAME.debug then print("Update End: State=", self.state, "Char=", self.currentCharacter) end
        end,
        
        -- Draw combat UI
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
            
            -- Draw based on current state
            if self.state == combatSystem.STATE.VICTORY then
                self:drawVictoryUI()
                
                -- Draw continue button if it exists
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
            end
            
            -- Always draw combat log
            self:drawCombatLog()
        end,
        
        -- Draw enemy information
        drawEnemy = function(self)
            -- Draw enemy name
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.print(self.enemy.name, GAME.width / 2 - 100, 50)
            
            -- Draw enemy health bar
            local healthWidth = 200 * (self.enemy.currentHP / self.enemy.maxHP)
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", GAME.width / 2 - 100, 90, 200, 20)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", GAME.width / 2 - 100, 90, healthWidth, 20)
            
            -- Draw HP text
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(
                self.enemy.currentHP .. " / " .. self.enemy.maxHP,
                GAME.width / 2 - 30, 92
            )
            
            -- Draw status effects
            local statusX = GAME.width / 2 - 100
            local statusY = 115
            
            for status, info in pairs(self.enemy.status) do
                love.graphics.setColor(0.8, 0.8, 0.2)
                love.graphics.print(status, statusX, statusY)
                statusY = statusY + 15
            end
        end,
        
        -- Draw party information
        drawParty = function(self)
            for i, character in ipairs(self.party) do
                local x = 20 + (i - 1) * 180
                local y = GAME.height - 350
                
                -- Highlight current character's turn
                if self.state == combatSystem.STATE.PLAYER_TURN and i == self.currentCharacter then
                    love.graphics.setColor(0.3, 0.3, 0.7, 0.5)
                    love.graphics.rectangle("fill", x - 5, y - 5, 170, 140)
                end
                
                -- Draw character name
                love.graphics.setFont(screenManager.fonts.medium)
                if character.active then
                    love.graphics.setColor(1, 1, 1)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                end
                love.graphics.print(character.name, x, y)
                
                -- Draw job
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 1)
                love.graphics.print(character.job, x, y + 25)
                
                -- Draw HP bar
                local healthWidth = 150 * (character.currentHP / character.maxHP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", x, y + 50, 150, 15)
                love.graphics.setColor(0.8, 0.2, 0.2)
                love.graphics.rectangle("fill", x, y + 50, healthWidth, 15)
                
                -- Draw HP text
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    character.currentHP .. " / " .. character.maxHP,
                    x + 50, y + 50
                )
                
                -- Draw MP bar
                local manaWidth = 150 * (character.currentMP / character.maxMP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", x, y + 70, 150, 15)
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", x, y + 70, manaWidth, 15)
                
                -- Draw MP text
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    character.currentMP .. " / " .. character.maxMP,
                    x + 50, y + 70
                )
                
                -- Draw status effects
                local statusX = x
                local statusY = y + 90
                
                for status, info in pairs(character.status) do
                    love.graphics.setColor(0.8, 0.8, 0.2)
                    love.graphics.print(status, statusX, statusY)
                    statusY = statusY + 15
                end
            end
        end,
        
        -- Draw combat log
        drawCombatLog = function(self)
            -- Draw log background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", GAME.width - 280, 50, 260, 300)
            
            -- Draw log title
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Combat Log", GAME.width - 270, 55)
            
            -- Draw log entries
            love.graphics.setFont(screenManager.fonts.small)
            
            local startIndex = math.max(1, #self.log - 15)
            for i = startIndex, #self.log do
                local entry = self.log[i]
                local y = 85 + (i - startIndex) * 18
                
                love.graphics.setColor(entry.color or {1, 1, 1})
                love.graphics.print(entry.text, GAME.width - 270, y)
            end
        end,
        
        -- Draw UI for player turn
        drawPlayerTurnUI = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar then return end
            
            -- Draw turn info
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(
                currentChar.name .. "'s Turn",
                50, GAME.height - 190
            )
            
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
                
                -- Draw confirm and back buttons for skill/item selection
                if self.elements.skillList.visible or self.elements.itemList.visible then
                    self.elements.confirmButton.visible = true
                    self.elements.backButton.visible = true
                    self.elements.confirmButton:draw()
                    self.elements.backButton:draw()
                end
            end
        end,
        
        -- Draw UI for enemy turn state
        drawEnemyTurnUI = function(self)
            -- Draw "Enemy Turn" text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.print(
                "Enemy Turn",
                50, GAME.height - 190
            )
            
            -- Show a "Waiting..." message
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.print(
                "Waiting for enemy action...",
                50, GAME.height - 160
            )
        end,
        
        -- Draw UI for victory state
        drawVictoryUI = function(self)
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
            love.graphics.printf(
                "You defeated " .. self.enemy.name,
                GAME.width / 2 - 200, GAME.height / 3 - 50,
                400, "center"
            )
            
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
                
                love.graphics.setFont(screenManager.fonts.small)
                for i, item in ipairs(self.rewards.loot) do
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
            end
            
            -- Draw "Press Enter to continue" text
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1, 0.7 + math.sin(love.timer.getTime() * 4) * 0.3)
            love.graphics.printf(
                "Press Enter to continue",
                GAME.width / 2 - 200, GAME.height / 3 + 200,
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
                -- Select enemy as target for attack
                self.selectedTarget = self.enemy
                self:executePlayerAction()
            elseif action == "skill" then
                -- Show skill list
                self:showSkillList()
            elseif action == "item" then
                -- Show item list
                self:showItemList()
            elseif action == "defend" then
                -- Execute defend action
                self:executeDefend()
            end
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
                    if selectedSkill.skill.target == "single_enemy" or
                       selectedSkill.skill.target == "all_enemies" then
                        self.selectedTarget = self.enemy
                    elseif selectedSkill.skill.target == "single_ally" then
                        -- For simplicity, target self for now
                        self.selectedTarget = self.party[self.currentCharacter]
                    elseif selectedSkill.skill.target == "all_allies" then
                        -- Target all allies (handled in execution)
                        self.selectedTarget = self.party
                    elseif selectedSkill.skill.target == "self" then
                        self.selectedTarget = self.party[self.currentCharacter]
                    end
                    
                    -- Execute skill
                    self:executeSkill()
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
                    
                    -- For simplicity, target self for now
                    self.selectedTarget = self.party[self.currentCharacter]
                    
                    -- Execute item use
                    self:executeItemUse()
                else
                    -- No item selected, do nothing
                    self:addLog("No item selected.", {1, 0.5, 0})
                    return
                end
            end
            
            -- Hide lists
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
        end,
        
        -- Cancel current selection
        cancelSelection = function(self)
            -- Reset selection
            self.selectedAction = nil
            self.selectedTarget = nil
            self.selectedSkill = nil
            self.selectedItem = nil
            
            -- Hide lists
            self.elements.skillList.visible = false
            self.elements.itemList.visible = false
            
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
                
                -- Ensure enemy has defense
                if not self.enemy.defense or type(self.enemy.defense) ~= "number" then
                    self.enemy.defense = 0
                    if GAME.debug then
                        print("Fixed missing enemy defense, set to: " .. self.enemy.defense)
                    end
                end
                
                -- Calculate damage using explicit values
                local attackPower = currentChar.attackPower or 10  -- Default if missing
                local enemyDefense = self.enemy.defense or 0       -- Default if missing
                
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
                if not self.enemy.currentHP or type(self.enemy.currentHP) ~= "number" then
                    self.enemy.currentHP = self.enemy.maxHP or 20
                end
                
                -- Apply damage and ensure we don't go below 0
                self.enemy.currentHP = self.enemy.currentHP - damage
                if self.enemy.currentHP < 0 then self.enemy.currentHP = 0 end
                
                if GAME.debug then
                    print("  Enemy HP after attack: " .. self.enemy.currentHP)
                end
                
                -- Add animation delay
                self.animationDelay = 0.5
                
                -- Play attack sound
                assetManager:playSound("attack")
                
                -- Add to combat log
                self:addLog(currentChar.name .. " attacks for " .. damage .. " damage!")
                
                -- Check for enemy defeat
                if self.enemy.currentHP <= 0 then
                    self:enemyDefeated()
                    return
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
            if not currentChar or not self.selectedSkill then return end
            
            -- Check MP cost
            if currentChar.currentMP < self.selectedSkill.mpCost then
                self:addLog("Not enough MP!")
                return
            end
            
            -- Deduct MP
            currentChar.currentMP = currentChar.currentMP - self.selectedSkill.mpCost
            
            -- Add animation delay
            self.animationDelay = 0.5
            
            -- Special case for Steal skill
            if self.selectedSkill.name == "Steal" then
                self:executeStealSkill(currentChar)
                return
            end
            
            -- Handle different skill targets
            if self.selectedSkill.target == "single_enemy" or 
               self.selectedSkill.target == "all_enemies" then
                -- Apply damage to enemy
                local damage, isCritical = 0, false
                
                -- Make sure character has this skill before calculating damage
                if currentChar.skills and currentChar.skills[self.selectedSkill.name] then
                    damage, isCritical = skillSystem:calculateDamage(
                        self.selectedSkill,
                        currentChar,
                        self.enemy,
                        currentChar.skills[self.selectedSkill.name].level
                    )
                else
                    -- Fallback if skill level is not found
                    damage, isCritical = skillSystem:calculateDamage(
                        self.selectedSkill,
                        currentChar,
                        self.enemy,
                        1
                    )
                end
                
                self.enemy.currentHP = math.max(0, self.enemy.currentHP - damage)
                
                -- Play appropriate sound
                if self.selectedSkill.type == "magical" then
                    assetManager:playSound("spell")
                else
                    assetManager:playSound("attack")
                end
                
                -- Add to combat log
                local logText = currentChar.name .. " uses " .. self.selectedSkill.name
                logText = logText .. " for " .. damage .. " damage!"
                
                if isCritical then
                    logText = logText .. " Critical hit!"
                end
                
                self:addLog(logText)
                
                -- Apply skill effects
                if self.selectedSkill.effect then
                    self:applySkillEffect(self.selectedSkill, currentChar, self.enemy)
                end
                
                -- Check for enemy defeat
                if self.enemy.currentHP <= 0 then
                    self:enemyDefeated()
                    return
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
                    self:addLog(
                        currentChar.name .. " uses " .. self.selectedSkill.name .. 
                        " and heals " .. self.selectedTarget.name .. " for " .. healing .. " HP!",
                        {0.2, 0.8, 0.2}
                    )
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
                if GAME.inventory and stolenItem then
                    table.insert(GAME.inventory, stolenItem)
                    
                    -- Add to combat log
                    self:addLog(
                        character.name .. " successfully steals " .. stolenItem.name .. "!",
                        {0.2, 0.8, 0.8}
                    )
                else
                    -- Add to combat log
                    self:addLog(
                        character.name .. " successfully steals an item!",
                        {0.2, 0.8, 0.8}
                    )
                end
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
            
            -- Use item on target
            local success = itemSystem:useItem(self.selectedItem, self.selectedTarget)
            
            if success then
                -- Play pickup sound
                assetManager:playSound("pickup")
                
                -- Add to combat log
                self:addLog(
                    currentChar.name .. " uses " .. self.selectedItem.name .. "!",
                    {0.2, 0.8, 0.8}
                )
                
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
                
                -- End turn
                self:nextTurn()
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
        
        -- Move to next turn
        nextTurn = function(self)
            if GAME.debug then print("--- nextTurn called (Current Char: " .. self.currentCharacter .. ", State: " .. self.state .. ") ---") end
            
            -- Reset selection
            self.selectedAction = nil
            self.selectedTarget = nil
            self.selectedSkill = nil
            self.selectedItem = nil
            
            -- Update status effect durations
            self:updateStatusEffects()
            
            -- Mark current character's turn as taken, only if it was a valid player turn
            if self.state == combatSystem.STATE.PLAYER_TURN and self.currentCharacter >= 1 and self.currentCharacter <= #self.party then
                if GAME.debug then print("Marking turn taken for character: " .. self.currentCharacter .. " Name: " .. self.party[self.currentCharacter].name) end
                self.charactersTurnTaken[self.currentCharacter] = true
            else
                 if GAME.debug then print("Not marking turn taken (State was Enemy or invalid Char Index)") end
            end
            
            -- Find the next character whose turn hasn't been taken
            local nextCharacterIndex = -1
            -- Start checking from the character *after* the current one. Handle case where currentCharacter might be 0 initially or invalid.
            local currentValidChar = self.currentCharacter
            if currentValidChar < 1 or currentValidChar > #self.party then 
                currentValidChar = #self.party -- Wrap around if invalid, effectively starting check from 1
            end
            local checkIndex = (currentValidChar % #self.party) + 1 
            
            if GAME.debug then 
                print("Starting check for next char. Current was: " .. self.currentCharacter .. ". Starting check index: " .. checkIndex)
                -- Use a temporary table for readable print
                local takenStatus = {}
                for k, v in pairs(self.charactersTurnTaken) do table.insert(takenStatus, k .. ":" .. tostring(v)) end
                print("Current turn taken status: {" .. table.concat(takenStatus, ", ") .. "}")
            end
            
            -- Loop exactly #self.party times to check everyone once
            for i = 1, #self.party do 
                if GAME.debug then print("  Checking index: " .. checkIndex) end
                
                -- Check if this character is valid, active, and hasn't taken their turn
                if self.party[checkIndex] and self.party[checkIndex].active and not self.charactersTurnTaken[checkIndex] then
                    if GAME.debug then print("    Found next character: " .. checkIndex .. " Name: " .. self.party[checkIndex].name) end
                    nextCharacterIndex = checkIndex
                    break -- Found the next character
                else
                    if GAME.debug then 
                        local reason = ""
                        if not self.party[checkIndex] then reason = "invalid index" 
                        elseif not self.party[checkIndex].active then reason = "inactive" 
                        elseif self.charactersTurnTaken[checkIndex] then reason = "turn already taken" end
                        print("    Skipping index " .. checkIndex .. " (" .. reason .. ")")
                    end
                end
                
                -- Move to the next index, wrapping around
                checkIndex = (checkIndex % #self.party) + 1
            end
            
            -- If no next character was found, it means all active characters have taken their turn
            if nextCharacterIndex == -1 then
                if GAME.debug then print("No valid next character found. Transitioning to Enemy Turn.") end
                
                -- Reset turn tracking for the next round
                if GAME.debug then print("Resetting charactersTurnTaken for next round.") end
                for j = 1, #self.party do
                    self.charactersTurnTaken[j] = false
                end
                
                -- Start enemy turn
                self.state = combatSystem.STATE.ENEMY_TURN
                self.enemyTurnDelay = nil -- Reset delay for enemy turn
                self:addLog("Enemy's turn", {1, 0.5, 0.5})
            else
                -- Found the next character, switch to their turn
                if GAME.debug then print("Switching to player turn for character: " .. nextCharacterIndex) end
                self.currentCharacter = nextCharacterIndex
                self.state = combatSystem.STATE.PLAYER_TURN
                
                -- Ensure action buttons are visible for the new turn
                self.elements.attackButton.visible = true
                self.elements.skillButton.visible = true
                self.elements.itemButton.visible = true
                self.elements.defendButton.visible = true
                
                -- Add log message
                local currentChar = self.party[self.currentCharacter]
                if currentChar then
                    self:addLog(currentChar.name .. "'s turn begins", {0.5, 0.5, 1})
                else
                    -- This case should ideally not happen if logic is correct
                    if GAME.debug then print("Error: Current character at index " .. self.currentCharacter .. " is nil after assignment!") end
                    -- As a fallback, maybe try finding the *first* available character again?
                    -- Or transition to enemy turn? For now, just log the error.
                end
            end
            
            if GAME.debug then print("--- nextTurn finished (New Char: " .. self.currentCharacter .. ", New State: " .. self.state .. ") ---") end
        end,
        
        -- Update status effect durations
        updateStatusEffects = function(self)
            -- Update party status effects
            for _, character in ipairs(self.party) do
                for status, info in pairs(character.status) do
                    if info.duration then
                        info.duration = info.duration - 1
                        
                        if info.duration <= 0 then
                            character.status[status] = nil
                            self:addLog(
                                character.name .. "'s " .. status .. " effect wore off!",
                                {0.8, 0.8, 0.2}
                            )
                        end
                    end
                end
            end
            
            -- Update enemy status effects
            for status, info in pairs(self.enemy.status) do
                if info.duration then
                    info.duration = info.duration - 1
                    
                    if info.duration <= 0 then
                        self.enemy.status[status] = nil
                        self:addLog(
                            self.enemy.name .. "'s " .. status .. " effect wore off!",
                            {0.8, 0.8, 0.2}
                        )
                    end
                end
            end
        end,
        
        -- Execute enemy turn
        executeEnemyTurn = function(self)
            -- Explicit state check
            if self.state ~= combatSystem.STATE.ENEMY_TURN then
                if GAME.debug then print("Error: executeEnemyTurn called while not in ENEMY_TURN state!") end
                return
            end

            -- Check if enemy is stunned
            if self.enemy.status.stun then
                self:addLog(self.enemy.name .. " is stunned and cannot act!")
                -- Need to end the enemy's turn properly
                self.turnEndDelay = 0.5 
                return
            end
            
            -- Add a combat log entry to show the enemy's turn is starting
            self:addLog(self.enemy.name .. " is taking its turn...", {1, 0.5, 0.5})
            
            -- Debug enemy stats
            if GAME.debug then
                print("Enemy stats:")
                print("  Name: " .. self.enemy.name)
                print("  Attack Power: " .. tostring(self.enemy.attackPower))
                print("  HP: " .. tostring(self.enemy.currentHP) .. "/" .. tostring(self.enemy.maxHP))
            end
            
            -- Choose a random active party member to attack
            local targets = {}
            for i, character in ipairs(self.party) do
                if character.active then
                    table.insert(targets, i)
                end
            end
            
            if #targets > 0 then
                -- Select a random target
                local targetIndex = targets[math.random(1, #targets)]
                local target = self.party[targetIndex]
                
                if GAME.debug then
                    print("Enemy targeting " .. target.name)
                    print("Enemy attack power: " .. tostring(self.enemy.attackPower or "nil"))
                    print("Target defense: " .. tostring(target.defense or "nil"))
                end
                
                -- Ensure enemy has attack power
                if not self.enemy.attackPower or type(self.enemy.attackPower) ~= "number" then
                    -- Force set enemy attack power if missing
                    self.enemy.attackPower = 10
                    if GAME.debug then
                        print("Fixed missing enemy attack power, set to: " .. self.enemy.attackPower)
                    end
                end
                
                -- Calculate enemy damage - using direct number values to avoid conversion issues
                local baseDamage = self.enemy.attackPower or 10  -- Default if missing
                if type(baseDamage) ~= "number" then baseDamage = 10 end
                
                local targetDefense = 0
                if target.defense and type(target.defense) == "number" then
                    targetDefense = target.defense
                end
                
                -- Basic damage calculation with explicit values
                local damage = math.floor(baseDamage - (targetDefense / 2))
                
                -- Debug damage calculation
                if GAME.debug then
                    print("Damage calculation:")
                    print("  Base damage: " .. baseDamage)
                    print("  Target defense: " .. targetDefense)
                    print("  Initial damage: " .. damage)
                end
                
                -- Ensure minimum damage
                if damage < 1 then 
                    damage = 1
                    if GAME.debug then
                        print("  Adjusted to minimum damage: " .. damage)
                    end
                end
                
                -- Apply defending status
                if target.status and target.status.defending then
                    local defenseMultiplier = target.status.defending.value or 2.0
                    damage = math.floor(damage / defenseMultiplier)
                    
                    if GAME.debug then
                        print("  Target is defending, reducing damage by " .. defenseMultiplier .. "x")
                        print("  Damage after defense: " .. damage)
                    end
                end
                
                -- Final minimum damage check
                damage = math.max(1, damage)
                
                if GAME.debug then
                    print("  Final damage: " .. damage)
                    print("  Target HP before: " .. target.currentHP)
                end
                
                -- Apply damage to target - ensure current HP is properly calculated
                if not target.currentHP or type(target.currentHP) ~= "number" then
                    target.currentHP = target.maxHP or 20
                end
                
                -- Force damage to be at least 1
                if damage < 1 then damage = 1 end
                
                -- Apply damage and ensure we don't go below 0
                target.currentHP = target.currentHP - damage
                if target.currentHP < 0 then target.currentHP = 0 end
                
                if GAME.debug then
                    print("  Target HP after: " .. target.currentHP)
                end
                
                -- Play hit sound
                assetManager:playSound("hit")
                
                -- Add to combat log
                self:addLog(
                    self.enemy.name .. " attacks " .. target.name .. 
                    " for " .. damage .. " damage!",
                    {1, 0.5, 0.5}
                )
                
                -- Check if target is defeated
                if target.currentHP <= 0 then
                    target.active = false
                    self:addLog(target.name .. " is defeated!", {1, 0, 0})
                    
                    -- Check if all party members are defeated
                    local allDefeated = true
                    for _, character in ipairs(self.party) do
                        if character.active then
                            allDefeated = false
                            break
                        end
                    end
                    
                    if allDefeated then
                        self:partyDefeated()
                        return
                    end
                end
            else
                -- No valid targets, enemy does nothing
                self:addLog(self.enemy.name .. " has no valid target!", {1, 0.5, 0.5})
            end
            
            -- Add a short delay before moving to the next turn
            self.turnEndDelay = 0.5
        end,
        
        -- Handle enemy defeat
        enemyDefeated = function(self)
            self:addLog(self.enemy.name .. " is defeated!", {0, 1, 0})
            
            -- Notify quest system about the kill
            local questSystem = require("gameplay/questSystem")
            -- Pass relevant data: monster ID and potentially boss flag
            local eventData = { 
                monsterId = self.enemy.id or "unknown", -- Pass the actual monster ID
                isBoss = self.enemy.isBoss or false -- Check for the boss flag
            }
            -- If it's a boss, trigger the boss kill event specifically
            local eventName = eventData.isBoss and "boss_kill" or "kill"
            questSystem:updateProgress(eventName, eventData) 
            -- TODO: Check return value from updateProgress if needed for immediate completion logic
            
            -- Calculate rewards
            self.rewards = {
                exp = self.enemy.stats.level * 10,
                loot = itemSystem:generateRandomLoot(self.enemy.stats.level)
            }
            
            -- Grant experience to party members
            for _, character in ipairs(self.party) do
                if character.active then
                    local charSystem = require("gameplay/character")
                    charSystem:addExperience(character, self.rewards.exp)
                end
            end
            
            -- Set victory state
            self.state = combatSystem.STATE.VICTORY
            
            -- Create continue button
            self.elements.continueButton = screenManager.UI.Button(
                GAME.width / 2 - 100, GAME.height / 3 + 250,
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
        
        -- Handle keypresses
        keypressed = function(self, key)
            if self:isOver() then
                -- In victory or defeat, pressing space/enter will exit combat
                if key == "return" or key == "space" then
                    return true
                end
            end
            return false
        end,
        
        -- Handle mouse clicks
        mousepressed = function(self, x, y, button)
            -- Check if combat is over FIRST
            if self:isOver() then
                if button == 1 and self.elements.continueButton and 
                   self.elements.continueButton.visible and 
                   self.elements.continueButton:clicked(x, y, button) then
                    -- If the continue button is clicked in victory/defeat state,
                    -- execute its callback and return the result (which should be true).
                    if self.elements.continueButton.callback then
                        return self.elements.continueButton.callback() -- This callback returns true
                    else
                        return true -- Default to true if no callback
                    end
                end
                -- If combat is over but click wasn't on continue button, do nothing more
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
                    -- Click was handled by the list, but combat is not over
                    return false 
                end
                
                -- Check item list clicks
                if self.elements.itemList and self.elements.itemList.visible and self.elements.itemList:clicked(x, y) then
                    -- Click was handled by the list, but combat is not over
                    return false 
                end
                
                -- Check other button clicks (Attack, Skill, Item, Defend, Confirm, Back)
                for name, element in pairs(self.elements) do
                    -- Exclude lists and the continue button (handled above)
                    if element.clicked and element ~= self.elements.skillList and 
                       element ~= self.elements.itemList and 
                       element ~= self.elements.continueButton then
                        
                        if element.visible ~= false and element:clicked(x, y, button) then
                            -- Button callback was executed, click handled, but combat continues.
                            return false -- Return FALSE here!
                        end
                    end
                end
            end
            
            -- Click was not on any relevant UI element during player turn
            return false
        end
    }
    
    -- Initialize combat
    combat:init()
    
    return combat
end

return combatSystem
