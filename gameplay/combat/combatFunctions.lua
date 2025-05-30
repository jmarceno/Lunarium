-- Combat Functions - Core combat functionality
local screenManager = require("screens/screenManager")
local minionManager = require("gameplay/minionManager")
local partyPanel = require("screens/ui_slices/partyPanel")

local combatSystem = {}  -- Forward declaration

-- Handle enemy being defeated
local function enemyDefeated(self, enemy)
    -- Make sure enemy is marked as inactive
    enemy.active = false
    
    -- Add to combat log
    self:addLog(enemy.name .. " was defeated!", {0, 1, 0})
    
    -- Check if all enemies are defeated
    self:checkAllEnemiesDefeated()
end

-- Check if all enemies are defeated
local function checkAllEnemiesDefeated(self)
    -- Check if there are any active enemies
    for _, enemy in ipairs(self.enemies) do
        if enemy and enemy.active then
            return false
        end
    end
    
    -- No active enemies found
    if not self.victoryDelayed then
        self.victoryDelayed = true
        self.showVictoryPrompt = true
        return false
    end
    
    return true
end

-- Handle player selecting an action
local function selectAction(self, action)
    -- Prevent multiple actions by immediately hiding buttons
    self:hideActionButtons()
    
    -- Set selected action
    self.selectedAction = action
    
    -- Hide all lists
    self:hideSelectionLists()
    
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
end

-- Reset selection UI elements
local function resetSelectionUI(self)
    -- Reset selection state for new character turn
    self.selectedAction = nil
    self.selectedTarget = nil
    self.selectedSkill = nil
    self.selectedItem = nil
    
    -- Hide any selection lists
    self:hideSelectionLists()
    
    -- Show action buttons for the new turn
    self:showActionButtons()
    self:showConfirmBackButtons(false, false)
end

-- Cancel current selection
local function cancelSelection(self)
    -- Reset selection
    self.selectedAction = nil
    self.selectedTarget = nil
    self.selectedSkill = nil
    self.selectedItem = nil
    self.partySelectionActionType = nil
    self.enemySelectionActionType = nil
    
    -- Hide lists
    self:hideSelectionLists()
    
    -- Make sure action buttons are visible again
    self:showActionButtons()
    self:showConfirmBackButtons(false, false)
end

-- Confirm party member selection
local function confirmPartySelection(self)
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
    
    -- Hide all UI elements and clear state
    self:hideSelectionLists()
    
    -- Execute the action based on type
    if self.partySelectionActionType == "skill" then
        self:executeSkill()
    elseif self.partySelectionActionType == "item" then
        self:executeItemUse()
    end
    
    -- Reset party selection tracking
    self.partySelectionActionType = nil
end

-- Draw UI for victory state
local function drawVictoryUI(self)
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
end

-- Handle victory state
local function victory(self)
    local assetManager = require("assets/assetManager")
    
    -- Play victory sound
    assetManager:playSound("victory")
    
    -- Set state to victory
    self.state = combatSystem.STATE.VICTORY
    
    -- Reset the spell queue
    self:resetSpellQueue()
    
    -- Reset the combat flag
    GAME.inCombat = false
    
    -- Calculate rewards if not already done
    if not self.rewardsCalculated then
        self:calculateVictoryRewards()
    end
    
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
    
    -- Reset party panel
    partyPanel:setCombatMode(false, nil)
    partyPanel:setActiveCharacter(nil)
    
    -- Hide combat UI
    self:hideAllUI()
    
    -- Create continue button
    self.elements.continueButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height / 2 + 100,
        200, 40, "Continue",
        function() return true end
    )
    self.elements.continueButton.visible = true
end

-- Define the combat system states for reference
combatSystem.STATE = {
    INIT = 1,
    PLAYER_TURN = 2,
    ENEMY_TURN = 3,
    MINION_TURN = 4,
    VICTORY = 5,
    DEFEAT = 6
}

return {
    enemyDefeated = enemyDefeated,
    checkAllEnemiesDefeated = checkAllEnemiesDefeated,
    selectAction = selectAction,
    resetSelectionUI = resetSelectionUI,
    cancelSelection = cancelSelection,
    confirmPartySelection = confirmPartySelection,
    drawVictoryUI = drawVictoryUI,
    victory = victory
}