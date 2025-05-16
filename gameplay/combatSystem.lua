-- Combat System
-- Handles turn-based combat mechanics
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local assetManager = require("assets/assetManager")
local screenManager = require("screens/screenManager")
local minionManager = require("gameplay/minionManager")
local partyPanel = require("screens/ui_slices/partyPanel")

-- Import modules from gameplay/combat directory
local uiHelpers = require("gameplay/combat/uiHelpers")
local combatFunctions = require("gameplay/combat/combatFunctions")
local coreFunctions = require("gameplay/combat/coreFunctions") 
local uiFunctions = require("gameplay/combat/uiFunctions")
local playerActionFunctions = require("gameplay/combat/playerActionFunctions")
local enemyFunctions = require("gameplay/combat/enemyFunctions")
local minionFunctions = require("gameplay/combat/minionFunctions")
local eventHandlerFunctions = require("gameplay/combat/eventHandlerFunctions")

local combatSystem = {
    STATE = {
        INIT = 1,
        PLAYER_TURN = 2,
        ENEMY_TURN = 3,
        MINION_TURN = 4,
        VICTORY = 5,
        DEFEAT = 6
    }
}

-- Create a new combat instance
function combatSystem:createCombat(party, enemy, isAmbush)
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
        rewardsCalculated = false, -- Flag to track reward calculation
        isAmbush = isAmbush or false, -- Flag to indicate if the player was ambushed
        
        -- Active minions in combat
        minions = {},
        
        -- Combat UI elements
        elements = {},
        
        -- Settings
        settings = {
            autoConfirmSelection = true -- Enable auto-confirm by default
        }
    }
    
    -- Add UI helper functions
    combat.showActionButtons = uiHelpers.showActionButtons
    combat.hideActionButtons = uiHelpers.hideActionButtons
    combat.hideSelectionLists = uiHelpers.hideSelectionLists
    combat.showConfirmBackButtons = uiHelpers.showConfirmBackButtons
    combat.hideAllUI = uiHelpers.hideAllUI
    
    -- Add combat core functions
    combat.setupCombatants = coreFunctions.setupCombatants
    combat.determineTurnOrder = coreFunctions.determineTurnOrder
    combat.update = coreFunctions.update
    combat.nextTurn = coreFunctions.nextTurn
    combat.partyDefeated = coreFunctions.partyDefeated
    combat.transitionToEnemyTurn = coreFunctions.transitionToEnemyTurn
    combat.calculateVictoryRewards = coreFunctions.calculateVictoryRewards
    combat.getStateName = coreFunctions.getStateName
    combat.getStateProgressionInfo = coreFunctions.getStateProgressionInfo
    combat.isOver = coreFunctions.isOver
    combat.isVictory = coreFunctions.isVictory
    combat.getLoot = coreFunctions.getLoot
    
    -- Add UI functions
    combat.createUI = uiFunctions.createUI
    combat.draw = uiFunctions.draw
    combat.drawEnemy = uiFunctions.drawEnemy
    combat.drawMultipleEnemies = uiFunctions.drawMultipleEnemies
    combat.drawSingleEnemy = uiFunctions.drawSingleEnemy
    combat.drawParty = uiFunctions.drawParty
    combat.drawCombatLog = uiFunctions.drawCombatLog
    combat.drawPlayerTurnUI = uiFunctions.drawPlayerTurnUI
    combat.drawEnemyTurnUI = uiFunctions.drawEnemyTurnUI
    combat.drawDefeatUI = uiFunctions.drawDefeatUI
    combat.showEnemySelectionUI = uiFunctions.showEnemySelectionUI
    combat.confirmEnemySelection = uiFunctions.confirmEnemySelection
    combat.showSkillList = uiFunctions.showSkillList
    combat.showItemList = uiFunctions.showItemList
    combat.showPartySelectionUI = uiFunctions.showPartySelectionUI
    combat.handleUIClick = uiFunctions.handleUIClick
    combat.drawMinions = uiFunctions.drawMinions
    combat.drawStatusEffectTooltips = uiFunctions.drawStatusEffectTooltips
    
    -- Add player action functions
    combat.executePlayerAction = playerActionFunctions.executePlayerAction
    combat.executeSkill = playerActionFunctions.executeSkill
    combat.executeStealSkill = playerActionFunctions.executeStealSkill
    combat.applySkillEffect = playerActionFunctions.applySkillEffect
    combat.executeItemUse = playerActionFunctions.executeItemUse
    combat.executeDefend = playerActionFunctions.executeDefend
    combat.confirmAction = playerActionFunctions.confirmAction
    
    -- Add minion functions
    combat.importExistingMinions = minionFunctions.importExistingMinions
    combat.processSummonSkill = minionFunctions.processSummonSkill
    combat.executeMinionTurn = minionFunctions.executeMinionTurn
    combat.findActiveUntakenMinion = minionFunctions.findActiveUntakenMinion
    
    -- Add enemy functions
    combat.executeEnemyTurn = enemyFunctions.executeEnemyTurn
    
    -- Add event handler functions
    combat.keypressed = eventHandlerFunctions.keypressed
    combat.mousepressed = eventHandlerFunctions.mousepressed
    combat.wheelmoved = eventHandlerFunctions.wheelmoved
    
    -- Add extracted combat functions
    combat.enemyDefeated = combatFunctions.enemyDefeated
    combat.checkAllEnemiesDefeated = combatFunctions.checkAllEnemiesDefeated
    combat.selectAction = combatFunctions.selectAction
    combat.resetSelectionUI = combatFunctions.resetSelectionUI
    combat.cancelSelection = combatFunctions.cancelSelection
    combat.confirmPartySelection = combatFunctions.confirmPartySelection
    combat.drawVictoryUI = combatFunctions.drawVictoryUI
    combat.victory = combatFunctions.victory
    
    -- Basic log function that all modules need
    combat.addLog = function(self, text, color)
        table.insert(self.log, {
            text = text,
            color = color or {1, 1, 1}
        })
    end
    
    -- Add item validation function to ensure proper items
    combat.validateItem = function(self, item)
        if not item then
            error("Null item reference found in combat")
            return false
        end
        if not item.name then
            error("Item without name found in combat")
            return false
        end
        if not item.type then
            error("Item without type found in combat: " .. item.name)
            return false
        end
        if not item.uniqueId then 
            error("Item without uniqueId found in combat: " .. item.name)
            return false
        end
        return true
    end
    
    -- Override getLoot to validate items before adding them to inventory
    combat.getLoot = function(self)
        if not self.loot then
            self.loot = {}
        end
        
        -- Validate all loot items before returning
        local validLoot = {}
        for i, item in ipairs(self.loot) do
            -- Only add valid items to loot
            if self:validateItem(item) then
                table.insert(validLoot, item)
            else
                print("ERROR: Invalid item removed from loot")
            end
        end
        
        return validLoot
    end
    
    -- Override showItemList to filter invalid items
    combat.showItemList = function(self)
        if not GAME.inventory or #GAME.inventory == 0 then
            self:addLog("No items available!", {1, 0.5, 0.5})
            self.selectedAction = nil -- Reset selected action
            self:showActionButtons() -- Show action buttons again
            self:showConfirmBackButtons(false, false) -- Hide confirm/back buttons
            return
        end
        
        -- Filter to only consumable items
        local consumables = {}
        for _, item in ipairs(GAME.inventory) do
            -- Validate each item before adding to consumables list
            if item.type == "consumable" and self:validateItem(item) then
                table.insert(consumables, item)
            end
        end
        
        if #consumables == 0 then
            self:addLog("No consumables available!", {1, 0.5, 0.5})
            self.selectedAction = nil -- Reset selected action
            self:showActionButtons() -- Show action buttons again
            self:showConfirmBackButtons(false, false) -- Hide confirm/back buttons
            return
        end
        
        -- Show item list
        self.selectedAction = "item"
        self.elements.itemList.visible = true
        self.elements.itemList.items = consumables
        
        -- Hide other UI elements
        self:hideActionButtons()
        self:showConfirmBackButtons()
    end
    
    -- Override executeItemUse to ensure item is valid
    combat.executeItemUse = function(self, item, target)
        -- Validate the item
        if not self:validateItem(item) then
            self:addLog("Invalid item! Cannot use.", {1, 0, 0})
            return false
        end
        
        -- Check if item is consumable
        if item.type ~= "consumable" then
            self:addLog("Only consumable items can be used in combat!", {1, 0.5, 0.5})
            return false
        end
        
        -- Use item
        local success, message = itemSystem:useItem(item, target)
        
        if success then
            -- Play sound effect
            assetManager:playSound("pickup")
            
            -- Add log message
            self:addLog(target.name .. " used " .. item.name, {0.5, 1, 0.5})
            
            -- Display effect message if available
            if message then
                self:addLog(message, {0.5, 1, 0.5})
            end
            
            -- Remove item from inventory
            for i, invItem in ipairs(GAME.inventory) do
                if invItem.uniqueId == item.uniqueId then
                    if invItem.count and invItem.count > 1 then
                        invItem.count = invItem.count - 1
                    else
                        table.remove(GAME.inventory, i)
                    end
                    break
                end
            end
            
            return true
        else
            -- Play error sound
            assetManager:playSound("hit")
            
            -- Add log message
            self:addLog("Failed to use " .. item.name, {1, 0.5, 0.5})
            
            -- Display error message if available
            if message then
                self:addLog(message, {1, 0.5, 0.5})
            end
            
            return false
        end
    end
    
    -- Initialize combat
    combat.init = function(self)
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
        self.minionTurnDelay = nil -- Set to nil to force initialization on first minion turn
        self.activeEnemyIndex = 1  -- Start with the first enemy
        
        -- Set initial state based on whether this is an ambush
        if self.isAmbush then
            -- If ambushed, enemies go first
            self.state = combatSystem.STATE.ENEMY_TURN
        else
            -- Normal combat, players go first
            self.state = combatSystem.STATE.PLAYER_TURN
        end
        
        -- Track which characters have had their turn this round
        self.charactersTurnTaken = {}
        for i=1, #self.party do
            -- If ambushed, mark all party members as having already taken their turn in the first round
            self.charactersTurnTaken[i] = self.isAmbush
        end
        
        -- Find the first active character
        self.currentCharacter = 0  -- Start with 0 so we can find the first active character
        local found = false
        
        -- Loop through all characters to find the first active one
        for i=1, #self.party do
            if self.party[i].active then
                self.currentCharacter = i
                found = true
                -- Ensure their turn is not marked as taken (unless ambushed)
                if not self.isAmbush then
                    self.charactersTurnTaken[i] = false
                end
                break
            end
        end
        
        -- If no active characters found (should not happen), handle gracefully
        if not found and #self.party > 0 then
            self.currentCharacter = 1
            self.party[1].active = true
            self.charactersTurnTaken[1] = self.isAmbush  -- Mark taken if ambushed
        end
        
        -- Initialize party panel for combat mode
        partyPanel:setCombatMode(true, self.party)
        if self.state == combatSystem.STATE.PLAYER_TURN then
            partyPanel:setActiveCharacter(self.currentCharacter)
        else
            partyPanel:setActiveCharacter(nil)
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
        
        -- Add ambush message if applicable
        if self.isAmbush then
            self:addLog("You've been AMBUSHED! Your party loses their first turn!", {1, 0, 0})
            self:addLog("The enemies attack first!", {1, 0.3, 0.3})
        else
            self:addLog(self.party[self.currentCharacter].name .. "'s turn begins", {0.5, 0.5, 1})
            
            -- Make sure action buttons are visible for first player turn
            self:showActionButtons()
        end
    end
    
    -- Initialize combat
    combat:init()
    
    return combat
end

return combatSystem