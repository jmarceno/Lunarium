-- Combat System
-- Handles turn-based combat mechanics
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local assetManager = require("assets/assetManager")
local screenManager = require("screens/screenManager")
local minionManager = require("gameplay/minionManager")

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
        rewardsCalculated = false, -- Flag to track reward calculation
        
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
        self:showActionButtons()
    end
    
    -- Initialize combat
    combat:init()
    
    return combat
end

return combatSystem