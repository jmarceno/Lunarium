-- Combat System
-- Handles turn-based combat mechanics
local skillSystem = require("gameplay/skill")
local itemSystem = require("gameplay/item")
local assetManager = require("assets/assetManager")
local screenManager = require("screens/screenManager")
local minionManager = require("gameplay/minionManager")
local partyPanel = require("screens/ui_slices/partyPanel")
local raycaster = require("engine/raycaster") -- Add raycaster directly

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

-- Create a small combat room map
function combatSystem:createCombatRoom(theme)
    -- Default theme if none provided
    theme = theme or "dungeon"
    
    -- Define texture sets based on themes
    local textures = {
        dungeon = {
            wall = "brickwall",
            floor = "stone_floor",
            ceiling = "stone_ceiling"
        },
        cave = {
            wall = "cave_wall",
            floor = "cave_floor",
            ceiling = "cave_ceiling"
        },
        crypt = {
            wall = "crypt_wall",
            floor = "crypt_floor",
            ceiling = "crypt_ceiling"
        },
        forest = {
            wall = "wooden_wall",
            floor = "grass_floor",
            ceiling = "tree_ceiling"
        }
    }
    
    -- Define decorative entities based on themes
    local decorations = {
        dungeon = {
            {type = "decoration", x = 3.5, y = 8.5, sprite = "torch", name = "Torch", animated = true},
            {type = "decoration", x = 6.5, y = 8.5, sprite = "torch", name = "Torch", animated = true},
            {type = "decoration", x = 5.0, y = 8.8, sprite = "chains", name = "Chains"}
        },
        cave = {
            {type = "decoration", x = 3.0, y = 8.5, sprite = "stalagmite", name = "Stalagmite"},
            {type = "decoration", x = 7.0, y = 8.5, sprite = "stalagmite", name = "Stalagmite"},
            {type = "decoration", x = 5.0, y = 8.8, sprite = "crystal", name = "Crystal", color = {0.5, 0.8, 1.0}}
        },
        crypt = {
            {type = "decoration", x = 3.5, y = 8.5, sprite = "coffin", name = "Coffin"},
            {type = "decoration", x = 6.5, y = 8.5, sprite = "coffin", name = "Coffin"},
            {type = "decoration", x = 5.0, y = 8.8, sprite = "skull_pile", name = "Skull Pile"}
        },
        forest = {
            {type = "decoration", x = 3.5, y = 8.5, sprite = "tree_stump", name = "Tree Stump"},
            {type = "decoration", x = 6.5, y = 8.5, sprite = "tree_stump", name = "Tree Stump"},
            {type = "decoration", x = 5.0, y = 8.8, sprite = "mushrooms", name = "Mushrooms", color = {0.8, 0.2, 0.2}}
        }
    }
    
    -- Fallback to dungeon theme if specified theme doesn't exist
    if not textures[theme] then
        theme = "dungeon"
    end
    
    -- Get texture set for the theme
    local textureSet = textures[theme]
    
    -- Create a simple square room (10x10)
    local roomSize = 10
    local room = {
        width = roomSize,
        height = roomSize,
        rooms = {{x = 1, y = 1, width = roomSize-2, height = roomSize-2}},
        start = {x = 1, y = 1},
        end_ = {x = roomSize-2, y = roomSize-2},
        decorations = decorations[theme] or decorations.dungeon -- Add theme-specific decorations
    }
    
    -- Initialize the grid with walls
    room.grid = {}
    for y = 1, roomSize do
        room.grid[y] = {}
        for x = 1, roomSize do
            -- 1 for walls (outer border only)
            if x == 1 or y == 1 or x == roomSize or y == roomSize then
                room.grid[y][x] = 1
            else
                room.grid[y][x] = 0 -- 0 for empty space
            end
        end
    end
    
    -- Add map functions needed by raycaster
    room.getCell = function(self, x, y)
        if x < 1 or y < 1 or x > self.width or y > self.height then
            return 1 -- Wall for out of bounds
        end
        return self.grid[y][x]
    end
    
    room.isCellWalkable = function(self, x, y)
        if x < 1 or y < 1 or x > self.width or y > self.height then
            return false
        end
        return self.grid[y][x] == 0
    end
    
    -- Add texture functions using the selected theme
    room.getWallTexture = function(self, x, y)
        return textureSet.wall
    end
    
    room.getFloorTexture = function(self, x, y)
        return textureSet.floor
    end
    
    room.getCeilingTexture = function(self, x, y)
        return textureSet.ceiling
    end
    
    -- Add fog of war function (empty implementation)
    room.revealArea = function(self, x, y, radius)
        -- Combat room is always fully visible
    end
    
    -- Add hint factor function (empty implementation)
    room.getHintFactor = function(self, x, y, type)
        return 0
    end
    
    -- Create the physical layout texture needed by raycaster
    local physicalLayoutData = love.image.newImageData(roomSize, roomSize)
    for y = 0, roomSize-1 do
        for x = 0, roomSize-1 do
            -- Use 1.0 for walls (white), 0.0 for open spaces (black)
            local value = 0.0
            if room:getCell(x+1, y+1) > 0 then
                value = 1.0
            end
            physicalLayoutData:setPixel(x, y, value, value, value, 1.0)
        end
    end
    room.physicalLayoutTexture = love.graphics.newImage(physicalLayoutData)
    
    -- Set dimensions for shader use
    room.dimensions = {roomSize, roomSize}
    
    return room
end

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
        victoryDelayed = false, -- Flag to track if victory is delayed for effects
        victoryDelay = nil, -- Timer for victory delay
        showVictoryPrompt = false, -- Flag to show the victory prompt in the center
        
        -- Active minions in combat
        minions = {},
        
        -- Combat UI elements
        elements = {},
        
        -- Spell queue for casting time system
        spellQueue = {},
        
        -- Settings
        settings = {
            autoConfirmSelection = true -- Enable auto-confirm by default
        },
        
        -- 3D room rendering
        combatRoom = nil,
        savedRaycasterState = nil,
        enemyEntities = {}
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
    
    -- Add spell queue management functions
    combat.addToSpellQueue = coreFunctions.addToSpellQueue
    combat.progressSpellQueue = coreFunctions.progressSpellQueue
    combat.executeCompletedSpells = coreFunctions.executeCompletedSpells
    combat.resetSpellQueue = coreFunctions.resetSpellQueue
    combat.modifySpellCastTime = coreFunctions.modifySpellCastTime
    combat.cancelSpell = coreFunctions.cancelSpell
    combat.isEntityCasting = coreFunctions.isEntityCasting
    combat.updateSpellQueueTime = coreFunctions.updateSpellQueueTime
    
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
    combat.drawSpeechBubble = uiFunctions.drawSpeechBubble
    combat.drawActorStatus = uiFunctions.drawActorStatus
    combat.drawDefeatUI = uiFunctions.drawDefeatUI
    combat.drawVictoryPrompt = uiFunctions.drawVictoryPrompt
    combat.showEnemySelectionUI = uiFunctions.showEnemySelectionUI
    combat.processClick = uiFunctions.processClick
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
    
    -- Add raycaster combat room functions
    combat.setupCombatRoom = function(self)
        self.savedRaycasterState = {
            camera = {x = raycaster.camera.x, y = raycaster.camera.y, angle = raycaster.camera.angle},
            texturesEnabled = raycaster.texturesEnabled,
            floorTexturesEnabled = raycaster.floorTexturesEnabled
        }
        
        local theme = (GAME.currentQuest and GAME.currentQuest.dungeonTheme) or "dungeon"
        if not GAME.currentQuest or not GAME.currentQuest.dungeonTheme then -- Fallback theme detection
            if GAME.currentQuest and GAME.currentQuest.location then
                local loc = GAME.currentQuest.location:lower()
                if loc:find("cave") or loc:find("cavern") then theme = "cave"
                elseif loc:find("crypt") or loc:find("tomb") or loc:find("catacomb") then theme = "crypt"
                elseif loc:find("forest") or loc:find("wood") then theme = "forest"
                end
            end
        end
        
        if GAME.debug then print("Combat room theme: " .. theme) end
        self.combatRoom = combatSystem:createCombatRoom(theme)
        raycaster.texturesEnabled = true
        raycaster.floorTexturesEnabled = true
        -- Centered X, close to south wall (low Y), looking North (positive Y direction)
        raycaster:setCamera(self.combatRoom.width / 2 + 0.5, 2.5, math.pi / 2) 
        self:setupEnemyEntities()
    end
    
    -- Create enemy entities for raycaster
    combat.setupEnemyEntities = function(self)
        self.enemyEntities = {}
        
        -- Add decorative items from the combat room
        if self.combatRoom and self.combatRoom.decorations then
            for _, decoration in ipairs(self.combatRoom.decorations) do
                table.insert(self.enemyEntities, decoration)
            end
        end
        
        -- Calculate positions based on number of enemies
        local numEnemies = #self.enemies
        local centerX = 5.5 -- Center of the 10-wide room's floor (2-9)
        local frontZ = 7.5 -- Distance from camera (closer to player)
        local backZ = 8.5  -- Distance from camera for back row (further from player)
        local spreadX = 2.0 -- Horizontal spread between enemies

        -- Special layout for single enemy - position in center
        if numEnemies == 1 then
            local enemy = self.enemies[1]
            local monsterDataModule = require("gameplay/monsterData")
            local monsterData = monsterDataModule:getMonsterData(enemy.id)
            local isBoss = enemy.isBoss or (monsterData and monsterData.isBoss)
            local posZ = 7.5
            if isBoss then
                posZ = 6.5 -- Bosses slightly closer
            end
            
            local spriteKey = (monsterData and monsterData.sprite) or enemy.sprite
            
            table.insert(self.enemyEntities, {
                x = centerX, y = posZ, type = "monster", id = enemy.id,
                sprite = spriteKey, color = enemy.color or {1,0,0}, name = enemy.name,
                isCombatEntity = true, enemyIndex = 1, isBoss = isBoss
            })
        else
            -- Multiple enemies - arrange in formation
            local useDoubleRow = numEnemies >= 4
            local frontRowCount = numEnemies
            local backRowCount = 0
            if useDoubleRow then
                frontRowCount = math.ceil(numEnemies / 2)
                backRowCount = math.floor(numEnemies / 2)
            end
            
            -- Place front row enemies
            for i = 1, frontRowCount do
                local enemy = self.enemies[i]
                local posX = centerX
                if frontRowCount > 1 then
                    local totalWidth = (frontRowCount - 1) * spreadX
                    local startX = centerX - (totalWidth / 2)
                    posX = startX + (i - 1) * spreadX
                end
                local monsterDataModule = require("gameplay/monsterData")
                local monsterData = monsterDataModule:getMonsterData(enemy.id)
                local spriteKey = (monsterData and monsterData.sprite) or enemy.sprite
                table.insert(self.enemyEntities, {
                    x = posX, y = frontZ, type = "monster", id = enemy.id,
                    sprite = spriteKey, color = enemy.color or {1,0,0}, name = enemy.name,
                    isCombatEntity = true, enemyIndex = i
                })
            end
            
            -- Place back row enemies
            for i = 1, backRowCount do
                local enemyIndex = frontRowCount + i
                local enemy = self.enemies[enemyIndex]
                local posX = centerX
                if backRowCount > 1 then
                     local totalWidth = (backRowCount - 1) * spreadX
                     local startX = centerX - (totalWidth / 2)
                     posX = startX + (i-1) * spreadX
                     -- Stagger back row slightly if not perfectly symmetrical with front
                     if backRowCount < frontRowCount and backRowCount > 1 then
                        posX = posX + (spreadX / (2 * (backRowCount -1 ))) -- More centered stagger
                     elseif backRowCount == 1 then -- Single enemy in back row centered
                        posX = centerX
                     end
                end

                local monsterDataModule = require("gameplay/monsterData")
                local monsterData = monsterDataModule:getMonsterData(enemy.id)
                local spriteKey = (monsterData and monsterData.sprite) or enemy.sprite
                table.insert(self.enemyEntities, {
                    x = posX, y = backZ, type = "monster", id = enemy.id,
                    sprite = spriteKey, color = enemy.color or {1,0,0}, name = enemy.name,
                    isCombatEntity = true, enemyIndex = enemyIndex
                })
            end
        end
        
        if GAME.debug then
            print("Setting up " .. #self.enemies .. " enemies for combat scene:")
            for _, entity in ipairs(self.enemyEntities) do
                if entity.type == "monster" then
                    print(string.format("  Enemy %d: %s at [%.1f, %.1f], Sprite: %s", 
                        entity.enemyIndex or 0, entity.name, entity.x, entity.y, entity.sprite or "N/A"))
                end
            end
        end
    end
    
    -- Restore raycaster state after combat
    combat.restoreRaycasterState = function(self)
        if self.savedRaycasterState then
            raycaster:setCamera(
                self.savedRaycasterState.camera.x,
                self.savedRaycasterState.camera.y,
                self.savedRaycasterState.camera.angle
            )
            raycaster.texturesEnabled = self.savedRaycasterState.texturesEnabled
            raycaster.floorTexturesEnabled = self.savedRaycasterState.floorTexturesEnabled
        end
    end
    
    -- Render the 3D combat background
    combat.renderCombatBackground = function(self)
        if self.combatRoom then
            love.graphics.setColor(1, 1, 1)
            -- Centered X, close to south wall (low Y), looking North (positive Y direction)
            raycaster:setCamera(self.combatRoom.width / 2 + 0.5, 2.5, math.pi / 2) 
            raycaster:render(self.combatRoom, self.enemyEntities)
        else
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
        end
    end
    
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
    
    -- Override draw function to use 3D background
    combat.draw = function(self)
        -- Use raycaster to render 3D background (unscaled)
        local scaling = require("utils/scaling")
        
        -- The 3D background needs to be rendered WITHOUT scaling
        love.graphics.setColor(1, 1, 1)
        self:renderCombatBackground()
        
        -- Draw UI elements and combat status WITH scaling
        scaling:push()
        
        local state = self.state
        
        if state == combatSystem.STATE.PLAYER_TURN then
            self:drawPlayerTurnUI()
        elseif state == combatSystem.STATE.ENEMY_TURN then
            self:drawEnemyTurnUI()
        elseif state == combatSystem.STATE.VICTORY then
            self:drawVictoryUI()
        elseif state == combatSystem.STATE.DEFEAT then
            self:drawDefeatUI()
        end
        
        -- Draw enemy info UI (health bars, status, etc.) - only UI elements, NOT the sprites
        self:drawEnemy()
        
        -- Draw party
        self:drawParty()
        
        -- Draw minions
        if self.state ~= combatSystem.STATE.VICTORY and self.state ~= combatSystem.STATE.DEFEAT then
            self:drawMinions()
        end
        
        -- Draw select lists if visible
        for _, element in pairs(self.elements) do
            if element.visible and element.draw then
                element:draw()
            end
        end
        
        -- Draw status effect tooltips for any hovered effect icons
        self:drawStatusEffectTooltips()
        
        -- Draw combat log
        self:drawCombatLog()
        
        -- Draw action meter bars
        if self.drawActionMeterBars then
            self:drawActionMeterBars()
        end
        
        -- Draw spell queue
        if self.drawSpellQueue then
            self:drawSpellQueue()
        end
        
        -- Draw floating combat text
        if self.floatingTexts then
            for i = #self.floatingTexts, 1, -1 do
                local floatingText = self.floatingTexts[i]
                floatingText:draw()
            end
        end
        
        -- Draw victory prompt if needed
        if self.showVictoryPrompt then
            self:drawVictoryPrompt()
        end
        
        scaling:pop()
    end
    
    -- Initialize combat
    combat.init = function(self)
        -- Set the combat flag to inform other systems
        GAME.inCombat = true
        
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
        
        -- Set up 3D combat room
        self:setupCombatRoom()
        
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
    
    -- Override victory function to restore raycaster state
    combat.victory = function(self)
        -- First calculate rewards if not already done
        if not self.rewardsCalculated then
            self:calculateVictoryRewards()
            self.rewardsCalculated = true
        end
        
        -- Show victory prompt
        self.showVictoryPrompt = true
        
        -- Change state to VICTORY
        self.state = combatSystem.STATE.VICTORY
        
        -- Restore raycaster state
        self:restoreRaycasterState()
        
        return true
    end
    
    -- Override the isOver function to restore raycaster state
    combat.isOver = function(self)
        local over = self.state == combatSystem.STATE.VICTORY or self.state == combatSystem.STATE.DEFEAT
        
        -- If combat is over, make sure we've restored the raycaster state
        if over then
            self:restoreRaycasterState()
        end
        
        return over
    end
    
    -- Add a helper function to safely get fonts with fallbacks
    local function safeGetFont(fontName)
        if screenManager.fonts and screenManager.fonts[fontName] then
            return screenManager.fonts[fontName]
        elseif screenManager.fonts and screenManager.fonts.small then
            return screenManager.fonts.small
        else
            return love.graphics.getFont()
        end
    end

    -- Add action meter bars function
    combat.drawActionMeterBars = function(self)
        -- Only draw if we have a turn manager
        if not self.turnManager then return end
        
        -- Get all entity status from turn manager
        local entityStatus = self.turnManager:getAllEntityStatus()
        if #entityStatus == 0 then return end
        
        -- Position above the spell queue
        local queueX = GAME.width - 230
        local queueY = 20
        local queueWidth = 210
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
        
        -- Draw title
        local titleFont = safeGetFont("medium")
        love.graphics.setFont(titleFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Action Meters", queueX + 10, queueY + 5)
        
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
            
            -- Draw entity name
            local nameFont = safeGetFont("small")
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
            
            -- Draw status text
            love.graphics.setColor(1, 1, 1)
            local statusFont = safeGetFont("tiny") or safeGetFont("small")
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
    
    -- Add spell queue function
    combat.drawSpellQueue = function(self)
        if #self.spellQueue == 0 then return end
        
        -- Position below action meters (if they exist)
        local queueX = GAME.width - 230
        local baseY = 20
        
        -- Adjust position if action meters are being drawn
        if self.turnManager then
            local entityStatus = self.turnManager:getAllEntityStatus()
            if #entityStatus > 0 then
                local actionMeterHeight = (#entityStatus * 38) + 20
                baseY = baseY + actionMeterHeight + 10 -- 10px gap between action meters and spell queue
            end
        end
        
        local queueY = baseY
        local queueWidth = 210
        local itemHeight = 40
        local spacing = 5
        
        -- Draw background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", queueX, queueY, queueWidth, (itemHeight + spacing) * #self.spellQueue + 10, 5, 5)
        
        -- Draw border
        love.graphics.setColor(0.4, 0.6, 0.8, 0.7)
        love.graphics.rectangle("line", queueX, queueY, queueWidth, (itemHeight + spacing) * #self.spellQueue + 10, 5, 5)
        
        -- Draw title
        local titleFont = safeGetFont("medium")
        love.graphics.setFont(titleFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Spell Queue", queueX + 10, queueY + 5)
        
        -- Draw each spell in the queue
        for i, spell in ipairs(self.spellQueue) do
            local itemY = queueY + 30 + (i-1) * (itemHeight + spacing)
            
            -- Draw spell name and caster
            local spellFont = safeGetFont("small")
            love.graphics.setFont(spellFont)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(spell.caster.name .. " - " .. spell.skill.name, queueX + 10, itemY)
            
            -- Calculate progress percentage
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
    
    -- Initialize combat
    combat:init()
    
    return combat
end

return combatSystem