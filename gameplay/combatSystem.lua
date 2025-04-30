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
            
            -- Set initial state
            self.state = combatSystem.STATE.PLAYER_TURN
            
            -- Add combat start message
            self:addLog("Combat started!")
            self:addLog(self.enemy.name .. " appeared!")
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
            
            self.elements.skillButton = screenManager.UI.Button(
                210, GAME.height - 150, 
                150, 40, "Skills", 
                function() self:selectAction("skill") end
            )
            
            self.elements.itemButton = screenManager.UI.Button(
                370, GAME.height - 150, 
                150, 40, "Items", 
                function() self:selectAction("item") end
            )
            
            self.elements.defendButton = screenManager.UI.Button(
                530, GAME.height - 150, 
                150, 40, "Defend", 
                function() self:selectAction("defend") end
            )
            
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
            
            -- Back button (for skills/items)
            self.elements.backButton = screenManager.UI.Button(
                360, GAME.height - 150, 
                120, 40, "Back", 
                function() self:cancelSelection() end
            )
        end,
        
        -- Update combat state
        update = function(self, dt)
            -- Update UI elements
            for _, element in pairs(self.elements) do
                if element.update then
                    element:update(dt)
                end
            end
            
            -- Handle state-specific updates
            if self.state == combatSystem.STATE.PLAYER_TURN then
                -- Check if current character is active
                local currentChar = self.party[self.currentCharacter]
                if not currentChar or not currentChar.active then
                    self:nextTurn()
                end
            elseif self.state == combatSystem.STATE.ENEMY_TURN then
                -- If no delay, execute enemy turn immediately
                if not self.enemyTurnDelay then
                    self.enemyTurnDelay = 1.0  -- 1 second delay
                end
                
                -- Update delay timer
                if self.enemyTurnDelay > 0 then
                    self.enemyTurnDelay = self.enemyTurnDelay - dt
                    
                    if self.enemyTurnDelay <= 0 then
                        self:executeEnemyTurn()
                        self.enemyTurnDelay = nil
                    end
                end
            end
        end,
        
        -- Draw combat UI
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 0, GAME.height - 200, GAME.width, 200)
            
            -- Draw enemy info
            self:drawEnemy()
            
            -- Draw party info
            self:drawParty()
            
            -- Draw combat log
            self:drawCombatLog()
            
            -- Draw UI based on current state
            if self.state == combatSystem.STATE.PLAYER_TURN then
                self:drawPlayerTurnUI()
            elseif self.state == combatSystem.STATE.VICTORY then
                self:drawVictoryUI()
            elseif self.state == combatSystem.STATE.DEFEAT then
                self:drawDefeatUI()
            end
            
            -- Draw skill list if visible
            self.elements.skillList:draw()
            
            -- Draw item list if visible
            self.elements.itemList:draw()
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
            
            -- Draw action buttons
            if not self.selectedAction then
                self.elements.attackButton:draw()
                self.elements.skillButton:draw()
                self.elements.itemButton:draw()
                self.elements.defendButton:draw()
            else
                -- Draw confirm and back buttons for skill/item selection
                if self.elements.skillList.visible or self.elements.itemList.visible then
                    self.elements.confirmButton:draw()
                    self.elements.backButton:draw()
                end
            end
        end,
        
        -- Draw UI for victory state
        drawVictoryUI = function(self)
            -- Draw victory message
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.printf(
                "Victory!",
                GAME.width / 2 - 200, GAME.height / 2 - 100,
                400, "center"
            )
            
            -- Draw reward info
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(
                "Experience gained: " .. self.rewards.exp,
                GAME.width / 2 - 200, GAME.height / 2 - 50,
                400, "center"
            )
            
            -- Draw loot info
            if self.rewards.loot and #self.rewards.loot > 0 then
                love.graphics.printf(
                    "Items obtained:",
                    GAME.width / 2 - 200, GAME.height / 2,
                    400, "center"
                )
                
                love.graphics.setFont(screenManager.fonts.small)
                for i, item in ipairs(self.rewards.loot) do
                    local text = item.name
                    if item.count and item.count > 1 then
                        text = text .. " x" .. item.count
                    end
                    
                    love.graphics.printf(
                        text,
                        GAME.width / 2 - 200, GAME.height / 2 + 30 + (i - 1) * 20,
                        400, "center"
                    )
                end
            end
        end,
        
        -- Draw UI for defeat state
        drawDefeatUI = function(self)
            -- Draw defeat message
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.printf(
                "Defeat!",
                GAME.width / 2 - 200, GAME.height / 2 - 50,
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
                    self:addLog("No skill selected.")
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
                    self:addLog("No item selected.")
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
        end,
        
        -- Execute player's selected action
        executePlayerAction = function(self)
            local currentChar = self.party[self.currentCharacter]
            if not currentChar then return end
            
            -- Execute attack
            if self.selectedAction == "attack" then
                -- Calculate damage
                local damage = math.floor(currentChar.attackPower - self.enemy.defense / 2)
                damage = math.max(1, damage)
                
                -- Apply damage to enemy
                self.enemy.currentHP = math.max(0, self.enemy.currentHP - damage)
                
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
            
            -- End turn
            self:nextTurn()
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
            
            -- Handle different skill targets
            if self.selectedSkill.target == "single_enemy" or 
               self.selectedSkill.target == "all_enemies" then
                -- Apply damage to enemy
                local damage, isCritical = skillSystem:calculateDamage(
                    self.selectedSkill,
                    currentChar,
                    self.enemy,
                    currentChar.skills[self.selectedSkill.name].level
                )
                
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
                    local healing = skillSystem:calculateDamage(
                        self.selectedSkill,
                        currentChar,
                        self.selectedTarget,
                        currentChar.skills[self.selectedSkill.name].level
                    )
                    
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
                            local healing = skillSystem:calculateDamage(
                                self.selectedSkill,
                                currentChar,
                                ally,
                                currentChar.skills[self.selectedSkill.name].level
                            )
                            
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
            
            -- End turn
            self:nextTurn()
        end,
        
        -- Apply skill effect to target
        applySkillEffect = function(self, skill, caster, target)
            if not skill.effect then return end
            
            local effect = skillSystem:calculateSkillEffect(
                skill,
                caster,
                target,
                caster.skills[skill.name].level
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
            
            -- End turn
            self:nextTurn()
        end,
        
        -- Move to next turn
        nextTurn = function(self)
            -- Reset selection
            self.selectedAction = nil
            self.selectedTarget = nil
            self.selectedSkill = nil
            self.selectedItem = nil
            
            -- Update status effect durations
            self:updateStatusEffects()
            
            -- Move to next character or enemy turn
            self.currentCharacter = self.currentCharacter + 1
            
            -- Check if all party members have acted
            if self.currentCharacter > #self.party then
                -- Start enemy turn
                self.currentCharacter = 1
                self.state = combatSystem.STATE.ENEMY_TURN
            else
                -- Check if current character is active
                local currentChar = self.party[self.currentCharacter]
                if not currentChar or not currentChar.active then
                    -- Skip this character
                    self:nextTurn()
                end
            end
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
            -- Check if enemy is stunned
            if self.enemy.status.stun then
                self:addLog(self.enemy.name .. " is stunned and cannot act!")
            else
                -- Choose a random action
                -- For now, just a basic attack on a random party member
                
                -- Choose a random active party member
                local targets = {}
                for i, character in ipairs(self.party) do
                    if character.active then
                        table.insert(targets, i)
                    end
                end
                
                if #targets > 0 then
                    local targetIndex = targets[math.random(1, #targets)]
                    local target = self.party[targetIndex]
                    
                    -- Calculate enemy damage
                    local damage = math.floor(self.enemy.attackPower - target.defense / 2)
                    
                    -- Apply defending status
                    if target.status.defending then
                        damage = math.floor(damage / target.status.defending.value)
                    end
                    
                    damage = math.max(1, damage)
                    
                    -- Apply damage to target
                    target.currentHP = math.max(0, target.currentHP - damage)
                    
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
                end
            end
            
            -- Start next player turn
            self.state = combatSystem.STATE.PLAYER_TURN
        end,
        
        -- Handle enemy defeat
        enemyDefeated = function(self)
            self:addLog(self.enemy.name .. " is defeated!", {0, 1, 0})
            
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
        end,
        
        -- Handle party defeat
        partyDefeated = function(self)
            self:addLog("The party has been defeated!", {1, 0, 0})
            
            -- Set defeat state
            self.state = combatSystem.STATE.DEFEAT
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
            if key == "return" and self.isOver() then
                return true
            end
            return false
        end,
        
        -- Handle mouse clicks
        mousepressed = function(self, x, y, button)
            -- Check UI element clicks
            if button == 1 then
                -- Check skill list clicks
                if self.elements.skillList:clicked(x, y) then
                    return true
                end
                
                -- Check item list clicks
                if self.elements.itemList:clicked(x, y) then
                    return true
                end
                
                -- Check button clicks
                for name, element in pairs(self.elements) do
                    if element.clicked and element ~= self.elements.skillList and
                       element ~= self.elements.itemList then
                        if element:clicked(x, y, button) then
                            return true
                        end
                    end
                end
            end
            
            return false
        end
    }
    
    -- Initialize combat
    combat:init()
    
    return combat
end

return combatSystem
