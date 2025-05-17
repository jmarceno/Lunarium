-- Dungeon Screen
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local raycaster = require("engine/raycaster")
local dungeonGenerator = require("gameplay/dungeonGenerator")
local combatSystem = require("gameplay/combatSystem")
local questSystem = require("gameplay/questSystem")
local itemSystem = require("gameplay/item")
local monsterDataModule = require("gameplay/monsterData")
local layoutHelper = screenManager.layoutHelper
local characterSystem = require("gameplay/character")
local gameState = require("states/gameState")
local minionManager = require("gameplay/minionManager")
local interactables = require("gameplay/interactables")
local trapSystem = require("gameplay/trapSystem")
local dungeon = screenManager:createScreen("Dungeon")
local partyPanel = require("screens/ui_slices/partyPanel")

-- Dungeon states
local STATES = {
    EXPLORING = 1,
    COMBAT = 2,
    LOOT = 3,
    DIALOGUE = 4,
    COMPLETED = 5
}

function dungeon:init()
    -- Initialize raycaster with game dimensions
    raycaster:init(GAME.width, GAME.height)
    
    -- Initialize dungeon state
    self.state = STATES.EXPLORING
    self.map = nil
    self.playerPos = {x = 1.5, y = 1.5, angle = 0}
    self.entities = {}
    self.combat = nil
    self.currentQuest = nil
    self.seed = 0
    self.baseMoveSpeed = 0.05
    self.moveSpeed = self.baseMoveSpeed
    self.turnSpeed = 0.03
    self.objective = {x = 0, y = 0, completed = false, reached = false}
    self.selectedInventoryItemIndex = nil
    self.statusBarVisible = true -- Initially visible
    self.statusBarTimer = 10 -- 10 seconds timer
    self.transitionStarted = false
    self.loot = {}
    self.currentMonster = nil
    
    -- Footstep sound variables
    self.footstepTimer = 0
    self.footstepInterval = 0.5 -- Time between footstep sounds in seconds
    self.isMoving = false
    
    -- Texture settings
    self.textureSettings = {
        wallTexturesEnabled = true,
        floorTexturesEnabled = true
    }
    
    -- Entrance entity tracking for dialog
    self.activeEntranceEntity = nil
    
    -- Active chest tracking for trap detection/dialog
    self.activeChestEntity = nil
    
    -- UI elements (Initialize the table first!)
    self.elements = {}
    
    -- Confirmation Dialog
    self.elements.confirmDialog = {
        visible = false,
        message = "",
        confirmCallback = nil,
        cancelCallback = nil,
        x = 20,
        y = GAME.height - 280,
        width = 350,
        height = 150,
        yesButton = nil,
        noButton = nil,

        init = function(self)
            self.yesButton = screenManager.UI.Button(
                self.x + self.width - 110, self.y + self.height - 55,
                100, 40, "Yes", 
                function() 
                    self.visible = false 
                    if self.confirmCallback then self.confirmCallback() end 
                end
            )
            self.noButton = screenManager.UI.Button(
                self.x + 10, self.y + self.height - 55, 
                100, 40, "No", 
                function() 
                    self.visible = false 
                    if self.cancelCallback then self.cancelCallback() end 
                end
            )
        end,

        show = function(self, message, onConfirm, onCancel)
            if not self.yesButton then self:init() end
            self.message = message
            self.confirmCallback = onConfirm
            self.cancelCallback = onCancel
            self.visible = true
        end,

        draw = function(self)
            if not self.visible then return end
            -- Draw a semi-transparent panel
            love.graphics.setColor(0, 0, 0, 0.7) -- Black background with 70% opacity
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            love.graphics.setColor(0.5, 0.5, 0.8, 0.7) -- Border with 70% opacity
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw text with slight transparency
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.printf(self.message, self.x + 10, self.y + 20, self.width - 20, "center")
            
            -- Draw buttons
            self.yesButton:draw()
            self.noButton:draw()
        end,

        clicked = function(self, x, y, button)
            if not self.visible then return false end
            if self.yesButton:clicked(x, y, button) then return true end
            if self.noButton:clicked(x, y, button) then return true end
            -- Consume clicks inside the panel
            if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
               return true
            end
            return false
        end
    }
    
    -- Add other UI elements
    self.elements.completeButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height - 80, 
        200, 50, "Return to Town", 
        function() self:completeQuest() end
    )
    
    -- Character Info Button (Bottom Right, above Inventory)
    self.elements.characterInfoButton = screenManager.UI.Button(
        GAME.width - 170, GAME.height - 233, 150, 30, "Party Info (C)",
        function() self:openCharacterInfo() end
    )
    
    -- Inventory Button (Bottom Right, above Status and Quest Status)
    self.elements.inventoryButton = screenManager.UI.Button(
        GAME.width - 170, GAME.height - 193, 150, 30, "Inventory (I)",
        function() self:openInventory() end
    )
    -- Status Button (Bottom Right, Bellow Inventory)
    self.elements.statusButton = screenManager.UI.Button(
        GAME.width - 170, GAME.height - 153, 150, 30, "Quest Status (J)",
        function() self:toggleStatusBar() end
    )
    
    -- Initialize minimap
    self.elements.minimap = {
        x = GAME.width - 220,
        y = 10, -- Move down to avoid overlap with status bar
        width = 200,
        height = 200,
        scale = 10,
        visible = true,
        
        draw = function(self)
            if not dungeon.map then return end
            
            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw border
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            
            -- Calculate minimap scale
            local cellSize = math.min(self.width / dungeon.map.width, self.height / dungeon.map.height)
            
            -- Draw map cells
            for y = 0, dungeon.map.height - 1 do
                for x = 0, dungeon.map.width - 1 do
                    -- Only draw cells that have been revealed (fog of war)
                    if dungeon.map:isCellVisible(x, y) then
                        local cellType = dungeon.map:getCell(x, y)
                        
                        if cellType > 0 then
                            -- Wall
                            love.graphics.setColor(0.7, 0.7, 0.7)
                            love.graphics.rectangle("fill", 
                                self.x + x * cellSize, 
                                self.y + y * cellSize, 
                                cellSize, cellSize)
                        else
                            -- Floor
                            love.graphics.setColor(0.3, 0.3, 0.3)
                            love.graphics.rectangle("fill", 
                                self.x + x * cellSize, 
                                self.y + y * cellSize, 
                                cellSize, cellSize)
                        end
                        
                        -- Draw entities only in revealed areas
                        for _, entity in ipairs(dungeon.entities) do
                            local entityX = math.floor(entity.x)
                            local entityY = math.floor(entity.y)
                            -- Only draw the entity if it's not hidden, or if debug mode is on and it's hidden
                            if x == entityX and y == entityY and entity.type ~= "objective" and 
                               (not entity.hidden or (entity.hidden and GAME.debug)) then
                                -- Use a different color for hidden monsters in debug mode
                                if entity.hidden and GAME.debug then
                                    love.graphics.setColor(1, 0, 1) -- Magenta color for hidden monsters in debug mode
                                else
                                    love.graphics.setColor(entity.color or {1, 0, 0})
                                end
                                love.graphics.circle("fill", 
                                    self.x + entity.x * cellSize, 
                                    self.y + entity.y * cellSize, 
                                    cellSize/2)
                            end
                        end
                    end
                end
            end
            
            -- Draw traps in debug mode
            if GAME.debug and dungeon.map.activeTraps then
                for _, trap in ipairs(dungeon.map.activeTraps) do
                    -- Draw all traps on minimap with cyan color
                    love.graphics.setColor(0, 1, 1) -- Cyan color for traps in debug mode
                    love.graphics.rectangle("fill", 
                        self.x + trap.x * cellSize + cellSize/4, 
                        self.y + trap.y * cellSize + cellSize/4, 
                        cellSize/2, cellSize/2)
                    
                    -- Draw X for disarmed traps
                    if trap.isTrapDisarmed then
                        love.graphics.setColor(0.8, 0, 0) -- Red color for X
                        -- Draw an X by using two lines
                        love.graphics.line(
                            self.x + trap.x * cellSize + cellSize/4,
                            self.y + trap.y * cellSize + cellSize/4,
                            self.x + trap.x * cellSize + cellSize*3/4,
                            self.y + trap.y * cellSize + cellSize*3/4
                        )
                        love.graphics.line(
                            self.x + trap.x * cellSize + cellSize*3/4,
                            self.y + trap.y * cellSize + cellSize/4,
                            self.x + trap.x * cellSize + cellSize/4,
                            self.y + trap.y * cellSize + cellSize*3/4
                        )
                    end
                end
            end
            
            -- Draw secret passages in debug mode
            if GAME.debug and dungeon.map.secretPassages then
                for _, passage in ipairs(dungeon.map.secretPassages) do
                    -- Use a special color for secret passages
                    if passage.secretPassageRevealed then
                        -- Green for revealed passages
                        love.graphics.setColor(0, 0.8, 0.2)
                    else
                        -- Magenta for hidden passages
                        love.graphics.setColor(1, 0, 1)
                    end
                    
                    -- Draw a diamond shape for secret passages
                    local centerX = self.x + passage.x * cellSize + cellSize/2
                    local centerY = self.y + passage.y * cellSize + cellSize/2
                    local size = cellSize/2
                    
                    love.graphics.polygon("fill", 
                        centerX, centerY - size/2,  -- Top point
                        centerX + size/2, centerY,  -- Right point
                        centerX, centerY + size/2,  -- Bottom point
                        centerX - size/2, centerY   -- Left point
                    )
                end
            end
            
            -- Draw interactable walls in debug mode
            if GAME.debug and dungeon.map.interactableWalls then
                for _, wall in ipairs(dungeon.map.interactableWalls) do
                    -- Use orange for interactable walls
                    love.graphics.setColor(1, 0.5, 0)
                    
                    -- Draw a smaller square for interactable walls
                    love.graphics.rectangle("fill", 
                        self.x + wall.x * cellSize + cellSize/3, 
                        self.y + wall.y * cellSize + cellSize/3, 
                        cellSize/3, cellSize/3)
                end
            end
            
            -- Draw objective if revealed
            local objX = math.floor(dungeon.objective.x)
            local objY = math.floor(dungeon.objective.y)
            if not dungeon.objective.reached and dungeon.map:isCellVisible(objX, objY) then
                love.graphics.setColor(0, 1, 0)
                love.graphics.circle("fill", 
                    self.x + dungeon.objective.x * cellSize + cellSize/2, 
                    self.y + dungeon.objective.y * cellSize + cellSize/2, 
                    cellSize/2)
            end
            
            -- Player is always visible
            love.graphics.setColor(0, 0, 1)
            love.graphics.circle("fill", 
                self.x + dungeon.playerPos.x * cellSize, 
                self.y + dungeon.playerPos.y * cellSize, 
                cellSize/2)
            
            -- Draw player direction
            local dirX = math.cos(dungeon.playerPos.angle) * cellSize
            local dirY = math.sin(dungeon.playerPos.angle) * cellSize
            
            love.graphics.setColor(1, 1, 0)
            love.graphics.line(
                self.x + dungeon.playerPos.x * cellSize,
                self.y + dungeon.playerPos.y * cellSize,
                self.x + dungeon.playerPos.x * cellSize + dirX,
                self.y + dungeon.playerPos.y * cellSize + dirY
            )
        end
    }
    
    -- Status bar
    self.elements.statusBar = {
        x = 10,
        y = 10,
        width = GAME.width - 240, -- Make room for buttons on the right
        height = 60,
        visible = true,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw status bar background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            love.graphics.setColor(0.3, 0.3, 0.5)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw quest info
            if dungeon.currentQuest then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.print("Current Quest: " .. dungeon.currentQuest.name, self.x + 10, self.y + 10)
                
                -- Draw objective status based on quest type
                local objectiveText = ""
                local objectiveColor = {1, 0.8, 0}
                
                if dungeon.currentQuest.type == "EXPLORE" then
                    if dungeon.objective.reached then
                        objectiveText = "Return to entrance"
                        objectiveColor = {0, 1, 0}
                    else
                        objectiveText = "Find the target location"
                    end
                elseif dungeon.currentQuest.type == "KILL" then
                    local current = dungeon.currentQuest.objective.current or 0
                    local count = dungeon.currentQuest.objective.count or 0
                    objectiveText = "Defeat " .. current .. "/" .. count .. " " .. dungeon.currentQuest.objective.targetName
                    
                    -- Set color to green if objective is complete
                    if current >= count then
                        objectiveColor = {0, 1, 0}
                    end
                elseif dungeon.currentQuest.type == "COLLECT" then
                    local current = dungeon.currentQuest.objective.current or 0
                    local count = dungeon.currentQuest.objective.count or 0
                    objectiveText = "Collect " .. current .. "/" .. count .. " " .. dungeon.currentQuest.objective.itemName
                    
                    -- Set color to green if objective is complete
                    if current >= count then
                        objectiveColor = {0, 1, 0}
                    end
                end
                
                love.graphics.setColor(objectiveColor)
                love.graphics.print("Objective: " .. objectiveText, self.x + 10, self.y + 30)
            end
        end
    }

     -- Initialize party panel
     self.elements.partyPanel = partyPanel

     -- Initialize the minion manager
    minionManager:init()
    
    return self
end

function dungeon:partyHasRogue()
    if GAME.party then
        for _, member in ipairs(GAME.party) do
            if member.class == "Rogue" then
                return true
            end
        end
    end
    return false
end

function dungeon:enter(params)
    -- Debug output to track flow
    print("Entering dungeon screen with params:", params and table.concat({"from_levelup="..(params.from_levelup and "true" or "false"), "from="..(params.from or "nil")}, ", ") or "nil")
    
    -- Set footstep sound volume to a lower level
    assetManager:setSoundVolume("footstep_gravel_walk_01", 0.05) -- Set to 30% of normal volume
    
    -- Check if we're returning from inventory or level up screen
    if (params and params.from == "inventory" and self.map) or 
       (params and params.from == "characterInfo" and self.map) or
       (params and params.from_levelup and self.map) then
        print("Preserving existing dungeon state")
        -- We're coming back from inventory or level up, keep the existing dungeon state
        -- Just update the camera
        if not self.playerPos then
            print("WARNING: playerPos is nil! Recreating default position.")
            self.playerPos = {x = 1.5, y = 1.5, angle = 0}
        end
        
        -- Make sure raycaster is initialized
        if not raycaster.initialized then
            print("Reinitializing raycaster")
            raycaster:init(GAME.width, GAME.height)
        end
        
        -- Restore texture settings
        raycaster.texturesEnabled = self.textureSettings.wallTexturesEnabled
        raycaster.floorTexturesEnabled = self.textureSettings.floorTexturesEnabled
        
        print("Setting camera to:", self.playerPos.x, self.playerPos.y, self.playerPos.angle)
        raycaster:setCamera(self.playerPos.x, self.playerPos.y, self.playerPos.angle)
        
        -- Reset combat-related state
        self.state = STATES.EXPLORING
        self.combat = nil
        
        -- Reset kill quest notification when returning from levelup
        if params.from_levelup then
            self.killQuestNotificationShown = false
        end
        
        -- Refresh character stats to ensure equipment changes are reflected in future combats
        if params.from == "inventory" then
            self:refreshCharacterStats()
        end
        
        return
    end
    
    -- Otherwise initialize a new dungeon
    print("Initializing new dungeon")
    self.state = STATES.EXPLORING
    self.objective.completed = false
    self.objective.reached = false
    
    -- Set up texture settings for raycaster
    raycaster.texturesEnabled = self.textureSettings.wallTexturesEnabled
    raycaster.floorTexturesEnabled = self.textureSettings.floorTexturesEnabled
    
    -- Calculate fog of war radius based on dungeon size and difficulty
    local baseFogRadius = 5 -- Base visibility radius
    if params and params.quest and params.quest.difficulty then
        -- Scale fog radius with difficulty, but not as aggressively as dungeon size
        self.fogOfWarRadius = baseFogRadius + math.floor(params.quest.difficulty * 1.5)
    else
        self.fogOfWarRadius = baseFogRadius -- Default for non-quest dungeons
    end
    
    self.killQuestNotificationShown = false -- Reset notification flag for kill quests
    
    -- Start playing dungeon music
    assetManager:playMusic("dungeon")
    
    -- Load or generate dungeon
    if params and params.quest then
        self.currentQuest = params.quest
        
        -- Generate dungeon from quest seed or create a new one
        local seed = params.quest.seed or os.time()
        self.seed = seed
        
        -- Calculate dungeon size based on difficulty
        local difficulty = params.quest.difficulty or 1
        local baseSize = 20 -- Minimum size 
        local dungeonSize = baseSize * (2 ^ (difficulty - 1)) -- Scale by 2^(difficulty-1)
        
        -- Cap size to prevent performance issues (optional)
        dungeonSize = math.min(dungeonSize, 160) -- Cap at 160x160
        
        self.map = dungeonGenerator:generate(dungeonSize, dungeonSize, seed)
        
        -- Scale movement speed based on dungeon size
        -- Increase movement speed for larger dungeons to reduce travel time
        local speedMultiplier = 1.0 + (math.min(difficulty, 5) * 0.2) -- Cap at 2x speed at difficulty 5
        self.moveSpeed = self.baseMoveSpeed * speedMultiplier
        
        -- Get the first room which is the starting room
        local startRoom = self.map.rooms[1]
        
        -- Place player in the center of the starting room
        self.playerPos = {
            x = math.floor(startRoom.x + startRoom.width / 2) + 0.5,
            y = math.floor(startRoom.y + startRoom.height / 2) + 0.5,
            angle = 0
        }
        
        -- Set player's angle to face away from entrance (toward dungeon center)
        local dirX = self.playerPos.x - self.map.start.x
        local dirY = self.playerPos.y - self.map.start.y
        
        -- Normalize the direction vector
        local length = math.sqrt(dirX*dirX + dirY*dirY)
        if length > 0 then
            -- Set player's angle to face away from entrance
            self.playerPos.angle = math.atan2(dirY, dirX)
        end
        
        -- Set objective position
        self.objective = {
            x = self.map.end_.x,
            y = self.map.end_.y,
            completed = false,
            reached = false
        }
        
        -- Populate dungeon with monsters and items
        self:populateDungeon(params.quest.difficulty or 1)
    else
        -- Create a default dungeon if no quest is provided
        -- Use the minimum size (40x40) for default dungeons
        self.map = dungeonGenerator:generate(40, 40, os.time())
        
        -- Use base movement speed for default dungeons
        self.moveSpeed = self.baseMoveSpeed
        
        -- Get the first room which is the starting room
        local startRoom = self.map.rooms[1]
        
        -- Place player in the center of the starting room
        self.playerPos = {
            x = math.floor(startRoom.x + startRoom.width / 2) + 0.5,
            y = math.floor(startRoom.y + startRoom.height / 2) + 0.5,
            angle = 0
        }
        
        -- Set player's angle to face away from entrance (toward dungeon center)
        local dirX = self.playerPos.x - self.map.start.x
        local dirY = self.playerPos.y - self.map.start.y
        
        -- Normalize the direction vector
        local length = math.sqrt(dirX*dirX + dirY*dirY)
        if length > 0 then
            -- Set player's angle to face away from entrance
            self.playerPos.angle = math.atan2(dirY, dirX)
        end
        
        -- Set objective position
        self.objective = {
            x = self.map.end_.x,
            y = self.map.end_.y,
            completed = false,
            reached = false
        }
        
        -- Populate dungeon with default monsters and items
        self:populateDungeon(1)
    end
    
    -- Add Entrance marker entity at the start
    table.insert(self.entities, { 
        x = self.map.start.x + 0.5,
        y = self.map.start.y + 0.5,
        type = "entrance",
        name = "Dungeon Entrance",
        color = {0.2, 0.8, 1.0} -- Light blue
    })
    
    -- Add Objective marker entity ONLY if it's an Explore quest or similar
    -- (Boss quests place the boss here, Kill/Collect quests might not need an end marker)
    if self.currentQuest and self.currentQuest.type == "EXPLORE" then
        table.insert(self.entities, {
            x = self.objective.x,
            y = self.objective.y,
            type = "objective",
            name = "Quest Objective",
            color = {0, 1, 0},
            isObjective = true
        })
    end
    
    -- Update raycaster camera with the final player position
    raycaster:setCamera(self.playerPos.x, self.playerPos.y, self.playerPos.angle)
    
    -- Reveal the area around the starting position
    self.map:revealArea(self.playerPos.x, self.playerPos.y, self.fogOfWarRadius)
end

function dungeon:populateDungeon(difficulty)
    self.entities = {}
    
    -- Check if we have a quest, otherwise populate randomly
    local hasQuest = self.currentQuest and self.currentQuest.objective
    if not hasQuest then
        print("Warning: Populating dungeon without a valid quest! Using random population.")
        self:addFillerEntities(difficulty, 10, false) -- Add more filler if no quest
        return
    end

    local questType = self.currentQuest.type
    local objective = self.currentQuest.objective

    -- Add quest-specific entities
    if questType == "KILL" then
        local fetchedMonsterData = monsterDataModule:getMonsterData(objective.targetId)
        if not fetchedMonsterData then print("Error: Cannot find monster data for KILL quest target: " .. objective.targetId); return end
        for i = 1, objective.count do
            local x, y = self:findValidSpawnPosition()
            if x then 
                table.insert(self.entities, {
                    x = x + 0.5,
                    y = y + 0.5,
                    type = "monster",
                    id = objective.targetId,
                    name = fetchedMonsterData.name, 
                    color = fetchedMonsterData.color,
                    stats = fetchedMonsterData.stats,
                    sprite = fetchedMonsterData.sprite, -- Add sprite path
                    category = fetchedMonsterData.category -- Add category
                })
            end
        end
        -- Optionally add some unrelated filler monsters/items
        self:addFillerEntities(difficulty, 3, false) -- Add 3 filler monsters/items

    elseif questType == "COLLECT" then
        local fetchedItemData = itemSystem:getItemData(objective.itemId)
        -- Handle case where item might not be in main item list (e.g., pure quest item)
        if not fetchedItemData then 
             print("Warning: Item data not found for COLLECT quest target: " .. objective.itemId .. ". Using generic quest item.")
             fetchedItemData = { name = objective.itemName or objective.itemId, type = "quest_item", questItemId = objective.itemId, color = {1, 1, 0} }
        end
        for i = 1, objective.count do
            local x, y = self:findValidSpawnPosition()
             if x then 
                table.insert(self.entities, {
                    x = x + 0.5,
                    y = y + 0.5,
                    type = "quest_item", -- Special type for quest items
                    questItemId = objective.itemId,
                    name = fetchedItemData.name,
                    color = fetchedItemData.color or {1,1,0}
                })
            end
        end
         -- Optionally add filler monsters/items
        self:addFillerEntities(difficulty, 5, false) -- avoidEnd is false here

    elseif questType == "BOSS" then
        -- Place boss at the end location
        local fetchedBossData = monsterDataModule:getMonsterData(objective.bossId)
        if not fetchedBossData then print("Error: Cannot find monster data for BOSS quest target: " .. objective.bossId); return end
        table.insert(self.entities, {
            x = self.map.end_.x + 0.5,
            y = self.map.end_.y + 0.5,
            type = "monster", -- Treat boss as a monster
            isBoss = true, -- Add a flag
            id = objective.bossId,
            name = fetchedBossData.name,
            color = fetchedBossData.color,
            stats = fetchedBossData.stats, -- Make sure boss stats are defined
            sprite = fetchedBossData.sprite, -- Add sprite path
            category = fetchedBossData.category -- Add category
        })
         -- Optionally add filler monsters/items, avoiding the end room
        self:addFillerEntities(difficulty, 5, true) 

    elseif questType == "ESCORT" then
        -- TODO: Add NPC entity to follow player
        print("ESCORT quest population not fully implemented.")
        -- Scale monster count based on difficulty
        local monsterCount = 5 + (difficulty * 3) -- 8 for medium, 11 for hard, 14 for very hard
        
        -- For ESCORT quests, place some monsters near the entrance and exit
        -- This ensures the player encounters monsters at critical points
        local entranceX, entranceY = self.map.start.x, self.map.start.y
        local exitX, exitY = self.map.end_.x, self.map.end_.y
        
        -- Place monsters near entrance (but not too close)
        for i = 1, math.min(3, difficulty) do
            local x = entranceX + math.random(-5, 5)
            local y = entranceY + math.random(-5, 5)
            
            -- Ensure position is valid
            if x > 1 and y > 1 and x < self.map.width and y < self.map.height and
               self.map:getCell(x, y) == 0 and
               (math.abs(x - entranceX) > 2 or math.abs(y - entranceY) > 2) then
                
                -- Get a slightly tougher monster for escorts
                local scaledDifficulty = math.min(5, difficulty + 1) -- Scale up difficulty by 1
                local randomMonsterId = monsterDataModule:getRandomMonsterId(scaledDifficulty)
                local fetchedMonsterData = monsterDataModule:getMonsterData(randomMonsterId)
                
                if fetchedMonsterData then
                    table.insert(self.entities, {
                        x = x + 0.5,
                        y = y + 0.5,
                        type = "monster",
                        id = randomMonsterId,
                        name = fetchedMonsterData.name,
                        color = fetchedMonsterData.color,
                        stats = fetchedMonsterData.stats,
                        sprite = fetchedMonsterData.sprite,
                        category = fetchedMonsterData.category
                    })
                end
            end
        end
        
        -- Place monsters near exit (but not too close)
        for i = 1, math.min(3, difficulty) do
            local x = exitX + math.random(-5, 5)
            local y = exitY + math.random(-5, 5)
            
            -- Ensure position is valid
            if x > 1 and y > 1 and x < self.map.width and y < self.map.height and
               self.map:getCell(x, y) == 0 and
               (math.abs(x - exitX) > 2 or math.abs(y - exitY) > 2) then
                
                -- Get a tougher monster for exit area
                local scaledDifficulty = math.min(5, difficulty + 2) -- Scale up difficulty by 2
                local randomMonsterId = monsterDataModule:getRandomMonsterId(scaledDifficulty)
                local fetchedMonsterData = monsterDataModule:getMonsterData(randomMonsterId)
                
                if fetchedMonsterData then
                    table.insert(self.entities, {
                        x = x + 0.5,
                        y = y + 0.5,
                        type = "monster",
                        id = randomMonsterId,
                        name = fetchedMonsterData.name,
                        color = fetchedMonsterData.color,
                        stats = fetchedMonsterData.stats,
                        sprite = fetchedMonsterData.sprite,
                        category = fetchedMonsterData.category
                    })
                end
            end
        end
        
        -- Add random monsters throughout the dungeon
        self:addFillerEntities(difficulty, monsterCount)
        
    elseif questType == "EXPLORE" then
        -- No specific entities needed, objective is reaching the end
        -- Add filler monsters/items
        local monsterCount = 5 + (difficulty * 3)
        self:addFillerEntities(difficulty, monsterCount)
        
    else 
        -- Fallback for unknown quest types
        local monsterCount = 5 + (difficulty * 3)
        self:addFillerEntities(difficulty, monsterCount)
    end

end

-- Helper to find a valid spawn position away from start/end
function dungeon:findValidSpawnPosition(avoidEnd)
    local attempts = 0
    local maxAttempts = 50
    while attempts < maxAttempts do
        attempts = attempts + 1
        local x = math.random(1, self.map.width - 2)
        local y = math.random(1, self.map.height - 2)
        local isEndPos = (x == self.map.end_.x and y == self.map.end_.y)
        
        if self.map:getCell(x, y) == 0 and
           (math.abs(x - self.map.start.x) > 2 or math.abs(y - self.map.start.y) > 2) and
           (not avoidEnd or not isEndPos) then
             -- Check proximity to other entities to avoid stacking
            local tooClose = false
            for _, entity in ipairs(self.entities) do
                if math.abs(x - entity.x) < 1 and math.abs(y - entity.y) < 1 then
                    tooClose = true
                    break
                end
            end
            if not tooClose then
                return x, y
            end
        end
    end
    print("Warning: Could not find valid spawn position after " .. maxAttempts .. " attempts.")
    return nil, nil -- Indicate failure
end

-- Helper function to add some random filler monsters and chests
function dungeon:addFillerEntities(difficulty, count, avoidEnd)
    -- Calculate monster count - increase monster ratio for higher difficulties
    local monsterRatio = 0.5 + (difficulty * 0.1) -- 50% for easy, 60% for medium, 70% for hard, etc.
    monsterRatio = math.min(monsterRatio, 0.9) -- Cap at 90% monsters
    local monsterCount = math.floor(count * monsterRatio)
    local itemCount = count - monsterCount
    
    local usedMonsterData = require("gameplay/monsterData") -- Require inside helper

    -- Calculate how many hidden monsters to add (10% of total monsters with minimum of 1)
    local hiddenMonsterCount = math.max(1, math.floor(monsterCount * 0.1))
    -- Increase total monster count by 10% to account for hidden monsters
    monsterCount = monsterCount + hiddenMonsterCount
    
    print("Adding " .. monsterCount .. " monsters (" .. hiddenMonsterCount .. " hidden)")
    
    -- Keep track of monsters added and hidden monsters added
    local monstersAdded = 0
    local hiddenMonstersAdded = 0

    -- Add filler monsters
    for i = 1, monsterCount do
        local x, y = self:findValidSpawnPosition(avoidEnd)
        if x then
            -- Choose a random non-quest monster type
            local randomMonsterId = usedMonsterData:getRandomMonsterId(difficulty) 
            local fetchedMonsterData = usedMonsterData:getMonsterData(randomMonsterId) 
            if fetchedMonsterData then
                -- Determine if this monster should be hidden
                -- Ensure we add the minimum number of hidden monsters
                local isHidden = false
                if hiddenMonstersAdded < hiddenMonsterCount and 
                   (monstersAdded >= (monsterCount - hiddenMonsterCount) or math.random() < 0.1) then
                    isHidden = true
                    hiddenMonstersAdded = hiddenMonstersAdded + 1
                end
                
                table.insert(self.entities, {
                    x = x + 0.5,
                    y = y + 0.5,
                    type = "monster",
                    id = randomMonsterId,
                    name = fetchedMonsterData.name, 
                    color = fetchedMonsterData.color,
                    stats = fetchedMonsterData.stats,
                    sprite = fetchedMonsterData.sprite, -- Add sprite path
                    category = fetchedMonsterData.category, -- Add category
                    hidden = isHidden -- Flag to mark hidden monsters for ambushes
                })
                monstersAdded = monstersAdded + 1
            else
                print("Warning: Could not get data for random filler monster ID: " .. tostring(randomMonsterId))
            end
        end
    end

    -- Add filler chests
    for i = 1, itemCount do
        local x, y = self:findValidSpawnPosition(avoidEnd)
        if x then
            local item = {
                x = x + 0.5,
                y = y + 0.5,
                type = "chest",
                color = {1, 0.8, 0},
                contents = {}
            }
            
            -- Determine if chest is trapped (25% chance + higher chance with higher difficulty)
            local trapChance = 0.25 + (difficulty * 0.05)
            if math.random() < trapChance then
                item.isTrapped = true
                
                -- Determine trap type
                local trapTypes = {"poison_needle", "gas_cloud", "magic_blast"}
                item.trapType = trapTypes[math.random(1, #trapTypes)]
                
                -- Optional: Set a different texture for trapped chests
                -- item.texture = "chest_trapped_subtle"
                
                print("Added trapped chest with " .. item.trapType .. " trap")
            end
            
            -- Add random loot to chest
            item.contents = itemSystem:generateRandomLoot(difficulty, math.random(1,2))
            
            -- Add chest to entities
            table.insert(self.entities, item)
        end
    end
    
    -- Add traps and secret passages
    self:addTrapsAndSecretPassages(difficulty)
end

-- Add traps and secret passages to the dungeon
function dungeon:addTrapsAndSecretPassages(difficulty)
    -- Initialize interactables and trap systems for the map
    self.map = interactables:initializeMap(self.map)
    self.map = trapSystem:initializeMap(self.map)
    
    -- Calculate number of traps and secret passages based on difficulty
    local numTraps = math.floor(3 + (difficulty * 2))
    local numSecretPassages = math.floor(1 + (difficulty * 0.5))
    
    print("Adding " .. numTraps .. " traps and " .. numSecretPassages .. " secret passages")
    
    -- Add floor traps
    for i = 1, numTraps do
        local x, y = self:findValidSpawnPosition(false)
        if x then
            -- Select a random trap type
            local trapTypes = {"spike", "gas", "dart"}
            local trapType = trapTypes[math.random(1, #trapTypes)]
            
            -- Add trap to the map
            trapSystem:addTrap(self.map, x, y, {
                trapType = trapType,
                hintFactor = 0 -- Initially not visible
            })
            
            print("Added " .. trapType .. " trap at " .. x .. "," .. y)
        end
    end
    
    -- Create some interactable walls that reveal secret passages
    for i = 1, numSecretPassages do
        -- Find a wall tile that isn't on the edge of the map
        local attempts = 0
        local maxAttempts = 50
        local wallX, wallY, passageX, passageY
        
        while attempts < maxAttempts do
            attempts = attempts + 1
            
            -- Get a random wall tile
            wallX = math.random(2, self.map.width - 3)
            wallY = math.random(2, self.map.height - 3)
            
            -- Only use wall tiles
            if self.map:getCell(wallX, wallY) > 0 then
                -- Look for an adjacent wall to turn into a passage
                -- Try all 4 directions
                local dirs = {{1,0}, {0,1}, {-1,0}, {0,-1}}
                local shuffled = {}
                for j, dir in ipairs(dirs) do shuffled[j] = dir end
                
                -- Shuffle directions
                for j = #shuffled, 2, -1 do
                    local k = math.random(1, j)
                    shuffled[j], shuffled[k] = shuffled[k], shuffled[j]
                end
                
                -- Check each direction
                for _, dir in ipairs(shuffled) do
                    passageX = wallX + dir[1]
                    passageY = wallY + dir[2]
                    
                    -- Make sure the passage is a wall
                    if self.map:getCell(passageX, passageY) > 0 then
                        -- Check if there's open space beyond the passage
                        local beyondX = passageX + dir[1]
                        local beyondY = passageY + dir[2]
                        
                        if beyondX > 0 and beyondX < self.map.width and
                           beyondY > 0 and beyondY < self.map.height and
                           self.map:getCell(beyondX, beyondY) == 0 then
                            -- We found a suitable place for a secret passage
                            
                            -- Create an interactable wall
                            interactables:addInteractableWall(self.map, wallX, wallY, {
                                interactionPrompt = "Examine Wall [E]",
                                revealsPassageAt = {x = passageX, y = passageY}
                            })
                            
                            -- Create a secret passage
                            interactables:addSecretPassage(self.map, passageX, passageY, {
                                secretPassageType = "slide"
                            })
                            
                            print("Added secret passage at " .. passageX .. "," .. passageY .. " revealed by wall at " .. wallX .. "," .. wallY)
                            
                            -- Add some treasure beyond the passage
                            local treasureItem = {
                                x = beyondX + 0.5,
                                y = beyondY + 0.5,
                                type = "chest",
                                color = {1, 0.8, 0},
                                contents = {}
                            }
                            
                            -- Make the secret chest loot more valuable
                            treasureItem.contents = itemSystem:generateRandomLoot(difficulty + 1, math.random(2, 3))
                            
                            -- Add chest to entities
                            table.insert(self.entities, treasureItem)
                            
                            -- Break out of both loops
                            attempts = maxAttempts
                            break
                        end
                    end
                end
            end
        end
    end
end

function dungeon:update(dt)
    -- Update status bar timer
    if self.statusBarVisible and self.statusBarTimer > 0 then
        self.statusBarTimer = self.statusBarTimer - dt
        if self.statusBarTimer <= 0 then
            self.statusBarVisible = false
            self.elements.statusBar.visible = false
        end
    end

    -- Update minion durations
    minionManager:updateDurations(dt)

    -- Update traps and interactables for all states
    self:updateTrapsAndInteractables(dt)
    
    -- Update based on current state
    if self.state == STATES.EXPLORING then
        -- Check wall interactions (needs to be in exploring state)
        self:checkWallInteraction()
        
        -- Check if a kill quest was just completed
        if self.currentQuest and self.currentQuest.type == "KILL" and 
           self.currentQuest.objective.current >= self.currentQuest.objective.count and
           not self.killQuestNotificationShown then
            
            -- Show completion notification
            self.elements.confirmDialog:show(
                "You've defeated all the " .. self.currentQuest.objective.targetName .. "s! Would you like to return to town now?",
                function() -- onConfirm (Yes - Return to town)
                    print("Returning to town after completing kill quest.")
                    -- Complete quest and return to town
                    self:completeQuest()
                end,
                function() -- onCancel (No - Continue exploring)
                    print("Continuing to explore after completing kill quest.")
                    -- Just close the dialog and continue
                    self.killQuestNotificationShown = true
                end
            )
        end
        
        -- Track if player moved this frame
        local playerMoved = false
        local baseSpeed = 2 -- base speed units per second
        local baseTurnSpeed = 2 -- base turning speed radians per second
        
        -- Calculate speed based on deltaTime
        local moveSpeed = baseSpeed * dt
        local turnSpeed = baseTurnSpeed * dt
        
        -- Store old position
        local oldX, oldY = self.playerPos.x, self.playerPos.y
        
        -- Reset isMoving flag before checking movements
        self.isMoving = false
        
        if love.keyboard.isDown("w") then
            raycaster:moveCamera(moveSpeed, self.map)
            playerMoved = true
            self.isMoving = true
        end
        
        if love.keyboard.isDown("s") then
            raycaster:moveCamera(-moveSpeed, self.map)
            playerMoved = true
            self.isMoving = true
        end
        
        if love.keyboard.isDown("a") then
            raycaster:rotateCamera(-turnSpeed)
            playerMoved = true
            -- Not setting isMoving true for rotation, only for actual movement
        end
        
        if love.keyboard.isDown("d") then
            raycaster:rotateCamera(turnSpeed)
            playerMoved = true
            -- Not setting isMoving true for rotation, only for actual movement
        end
        
        if love.keyboard.isDown("q") then
            raycaster:strafeCamera(-moveSpeed, self.map)
            playerMoved = true
            self.isMoving = true
        end
        
        if love.keyboard.isDown("e") then
            raycaster:strafeCamera(moveSpeed, self.map)
            playerMoved = true
            self.isMoving = true
        end
        
        -- Play footstep sound when moving
        if self.isMoving then
            -- Update footstep timer
            self.footstepTimer = self.footstepTimer - dt
            if self.footstepTimer <= 0 then
                -- Play footstep sound with random pitch variation
                local randomPitch = 0.85 + math.random() * 0.3 -- Random pitch between 0.85 and 1.15
                assetManager:playSound("footstep_gravel_walk_01", randomPitch)
                -- Reset timer
                self.footstepTimer = self.footstepInterval
            end
        else
            -- Reset timer when not moving
            self.footstepTimer = 0
        end
        
        -- Update player position from raycaster
        self.playerPos.x = raycaster.camera.x
        self.playerPos.y = raycaster.camera.y
        self.playerPos.angle = raycaster.camera.angle
        
        -- Update fog of war if player moved
        if playerMoved and (self.playerPos.x ~= oldX or self.playerPos.y ~= oldY) then
            self.map:revealArea(self.playerPos.x, self.playerPos.y, self.fogOfWarRadius)
        end
        
        -- Check if the entrance dialog should be hidden (player moved away from entrance)
        if self.elements.confirmDialog.visible and self.activeEntranceEntity then
            local distToEntrance = math.sqrt(
                (self.playerPos.x - self.activeEntranceEntity.x)^2 + 
                (self.playerPos.y - self.activeEntranceEntity.y)^2
            )
            
            -- If player moved away from entrance, hide the dialog
            if distToEntrance > 1.0 then
                self.elements.confirmDialog.visible = false
                self.activeEntranceEntity = nil
                print("Dialog closed: player moved away from entrance")
            end
        end
        
        -- Check for entity interaction
        self:checkEntityInteraction()
        
        -- Update entities
        for i, entity in ipairs(self.entities) do
            if entity.update then
                entity:update(dt, self.map, self.playerPos)
            end
        end
    elseif self.state == STATES.COMBAT then
        self:updateCombat(dt)
    elseif self.state == STATES.LOOT then
        self:updateLoot(dt)
    end
    
    -- Check for quest completion if exploring (not in combat/loot)
    if self.state == STATES.EXPLORING and self.currentQuest then
        -- Check if the quest status in the global game state has changed to completed
        -- This relies on questSystem:updateProgress modifying the quest in GAME.activeQuests
        local isActive = false
        if GAME.activeQuests then
            for _, q in ipairs(GAME.activeQuests) do
                if q.id == self.currentQuest.id then
                    isActive = true
                    break
                end
            end
        end
        
        if not isActive and self.currentQuest.status ~= questSystem.STATUS.COMPLETED then 
            -- The quest is no longer in the active list, assume completed
            -- Double check status isn't already completed to prevent loops if returning
            print("Quest " .. self.currentQuest.name .. " detected as completed!")
            self.objective.completed = true -- Mark dungeon objective as met
            self.state = STATES.COMPLETED -- Trigger dungeon completion screen
            -- The actual quest completion rewards are handled by questSystem/overworld
        end
    end
end

function dungeon:updateExploring(dt)
    -- Handle player movement
    if love.keyboard.isDown("w") then
        raycaster:moveCamera(self.moveSpeed, self.map)
        self.playerPos.x = raycaster.camera.x
        self.playerPos.y = raycaster.camera.y
    end
    if love.keyboard.isDown("s") then
        raycaster:moveCamera(-self.moveSpeed, self.map)
        self.playerPos.x = raycaster.camera.x
        self.playerPos.y = raycaster.camera.y
    end
    if love.keyboard.isDown("a") then
        raycaster:rotateCamera(-self.turnSpeed)
        self.playerPos.angle = raycaster.camera.angle
    end
    if love.keyboard.isDown("d") then
        raycaster:rotateCamera(self.turnSpeed)
        self.playerPos.angle = raycaster.camera.angle
    end
    if love.keyboard.isDown("q") then
        raycaster:strafeCamera(-self.moveSpeed, self.map)
        self.playerPos.x = raycaster.camera.x
        self.playerPos.y = raycaster.camera.y
    end
    if love.keyboard.isDown("e") then
        raycaster:strafeCamera(self.moveSpeed, self.map)
        self.playerPos.x = raycaster.camera.x
        self.playerPos.y = raycaster.camera.y
    end
    
    -- Check for entity interaction
    self:checkEntityInteraction()
end

function dungeon:updateCombat(dt)
    if self.combat then
        -- Update the combat system
        self.combat:update(dt)
        
        -- Combat ending logic is now handled directly in keypressed/mousepressed
        -- based on the return value from self.combat input handlers.
    end
end

function dungeon:updateLoot(dt)
    -- Loot interaction is handled via UI
end

function dungeon:checkEntityInteraction()
    -- Check for nearby entities to interact with
    for _, entity in ipairs(self.entities) do
        -- Skip interaction if entity is nil or position is invalid (safety check)
        if not entity or not entity.x or not entity.y then 
            goto continue 
        end

        local distToEntity = math.sqrt(
            (self.playerPos.x - entity.x)^2 + 
            (self.playerPos.y - entity.y)^2
        )
        
        -- If player is near entity
        if distToEntity < 1.0 then
            if entity.type == "monster" then
                -- Start combat
                self.state = STATES.COMBAT
                
                -- Flag to track if this is an ambush (for hidden monsters)
                local isAmbush = entity.hidden
                
                -- For boss monsters, always use single-enemy combat
                if entity.isBoss then
                    self.combat = combatSystem:createCombat(GAME.party, entity, isAmbush)
                    -- Play boss battle music
                    assetManager:playMusic("bossCombat")
                else
                    -- For regular monsters, check mission difficulty
                    local difficulty = self.currentQuest and self.currentQuest.difficulty or 1
                    
                    -- For higher difficulty missions, create multi-enemy combats
                    if difficulty > 1 then
                        -- Save the monster's category
                        local monsterCategory = entity.category
                        
                        -- Debug print to track difficulty value
                        print("Creating monster group with difficulty: " .. tostring(difficulty))
                        
                        -- Generate a monster group of same category (including the encountered monster)
                        local monsterDataModule = require("gameplay/monsterData")
                        local monsters = monsterDataModule:generateMonsterGroup(difficulty)
                        
                        -- Show monster count in debug log
                        print("Generated " .. #monsters .. " monsters for combat")
                        
                        -- Make sure first monster is the one we encountered (optional)
                        if #monsters > 0 then
                            monsters[1] = entity
                        else
                            monsters = {entity} -- Fallback
                        end
                        
                        -- Start combat with multiple enemies, passing the ambush flag
                        self.combat = combatSystem:createCombat(GAME.party, monsters, isAmbush)
                    else
                        -- Easy missions still have single enemies
                        self.combat = combatSystem:createCombat(GAME.party, entity, isAmbush)
                    end
                    
                    -- Play regular battle music (randomly select between two tracks)
                    if math.random() > 0.5 then
                        assetManager:playMusic("combat")
                    else
                        assetManager:playMusic("combatAlt")
                    end
                end
                
                break
            elseif entity.type == "chest" then
                -- If the confirmation dialog is already visible AND it's for this current chest entity,
                -- we've already processed it. Don't re-evaluate message or re-show, to prevent flicker.
                if self.elements.confirmDialog.visible and self.activeChestEntity == entity then
                    break -- Interaction with this chest is already active via its dialog.
                end

                -- Otherwise, (no dialog visible, or dialog is for a different entity),
                -- we proceed to interact with THIS chest.
                self.activeChestEntity = entity -- Mark this chest as the current interaction focus.
                
                -- Construct confirmation message
                local message = "Open this chest?"
                
                -- If player is a Rogue or has high enough perception and chest is trapped, 
                -- show warning message instead of the standard message.
                -- This random check will now effectively run only once when the dialog for this chest is first shown.
                if entity.isTrapped then
                    local partyHasRogue = self:partyHasRogue()
                    if partyHasRogue then
                        message = "This chest seems suspicious. Open it anyway?"
                    elseif math.random() < 0.3 then -- Fallback perception check if no Rogue in party
                        message = "This chest seems suspicious. Open it anyway?"
                    end
                end
                
                -- Show confirmation dialog
                self.elements.confirmDialog:show(
                    message,
                    function() -- onConfirm (Yes - Open the chest)
                        -- If chest is trapped, trigger the trap
                        if entity.isTrapped then
                            self:triggerChestTrap(entity)
                        end
                        
                        -- Collect loot regardless of trap
                        self:collectChestLoot(entity)
                        
                        -- Remove chest from entities
                        for i = #self.entities, 1, -1 do
                            if self.entities[i] == entity then
                                table.remove(self.entities, i)
                                break
                            end
                        end
                        
                        -- Reset active chest (dialog's onConfirm should also ensure visibility = false)
                        self.activeChestEntity = nil 
                    end,
                    function() -- onCancel (No - Leave the chest)
                        -- Reset active chest (dialog's onCancel should also ensure visibility = false)
                        self.activeChestEntity = nil
                    end
                )
                break
            elseif entity.type == "objective" and entity.isObjective then
                -- Mark objective as reached (but don't complete it yet)
                self.objective.reached = true
                
                -- For EXPLORE quests, reaching the objective marks the goal as reached
                if self.currentQuest and self.currentQuest.type == "EXPLORE" then
                    print("Reached EXPLORE quest objective!")
                    -- Show confirmation dialog with options
                    self.elements.confirmDialog:show(
                        "You've reached the objective! Would you like to return to town now?", 
                        function() -- onConfirm (Yes - Return to town)
                            print("Returning to town after reaching objective.")
                            -- Update quest progress
                            local questSystem = require("gameplay/questSystem")
                            questSystem:updateProgress("explore", {locationId = self.currentQuest.objective.locationId})
                            -- Return to town with quest progress saved
                            self:completeQuest()
                        end,
                        function() -- onCancel (No - Continue exploring)
                            print("Continuing to explore after reaching objective.")
                            -- Update quest progress but stay in dungeon
                            local questSystem = require("gameplay/questSystem")
                            questSystem:updateProgress("explore", {locationId = self.currentQuest.objective.locationId})
                            -- Don't immediately complete quest or return to town
                        end
                    )
                    
                    -- Remove the objective marker from the dungeon
                    for i = #self.entities, 1, -1 do
                        if self.entities[i] == entity then
                            table.remove(self.entities, i)
                            print("Objective marker removed from dungeon")
                            break
                        end
                    end
                end
                break
            elseif entity.type == "entrance" then
                -- Store reference to entrance entity for distance checking
                self.activeEntranceEntity = entity
                
                -- Check if this is an EXPLORE quest and the objective was reached
                if self.currentQuest and self.currentQuest.type == "EXPLORE" and self.objective.reached then
                    -- Show different message for completed objective
                    self.elements.confirmDialog:show(
                        "Return to town and complete your quest?", 
                        function() -- onConfirm
                            print("Returning to town with completed quest.")
                            -- Mark objective as fully completed
                            self.objective.completed = true
                            self:completeQuest()
                        end,
                        function() -- onCancel
                            print("Staying in dungeon.")
                        end
                    )
                else
                    -- Standard entrance dialog for non-completed quests
                    self.elements.confirmDialog:show(
                        "Return to town? Quest progress might be lost!", 
                        function() -- onConfirm
                            print("Confirmed returning to town.")
                            -- Make sure to clean up minions when leaving dungeon
                            self:exitDungeon()
                            
                            local gameState = require("states/gameState")
                            gameState:changeState("overworld")
                            -- Optionally fail quest here if needed (e.g., escort)
                            -- if self.currentQuest then questSystem:failQuest(self.currentQuest.id) end
                        end,
                        function() -- onCancel
                            print("Cancelled returning to town.")
                        end
                    )
                end
                break
            end
        end
        ::continue:: -- Label for goto
    end
end

function dungeon:draw()
    -- Clear screen
    love.graphics.clear(0.1, 0.1, 0.1)

    -- Safety checks for critical data
    if self.state == STATES.EXPLORING and not self.map then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.printf("Error: Map data is missing. Please restart the game.", 0, GAME.height/2 - 50, GAME.width, "center")
        
        -- Try to print a restart message
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press ESC to return to main menu", 0, GAME.height/2 + 20, GAME.width, "center")
        return
    end

    -- Draw based on current state
    if self.state == STATES.EXPLORING then
        -- Draw 3D view
        self:drawExploringState()

        -- Draw UI elements that should appear in exploring state
        if self.elements.minimap then
            self.elements.minimap:draw()
        end
        
        -- Display party members with basic stats (bottom of screen)
        if self.elements.partyPanel then
            self.elements.partyPanel:draw()
        end
    elseif self.state == STATES.COMBAT then
        -- Draw combat UI
        if self.combat then
            self.combat:draw()
        else
            -- Handle case where combat system is missing
            love.graphics.setColor(1, 0, 0)
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.printf("Error: Combat system not initialized.", 0, GAME.height/2 - 50, GAME.width, "center")
            
            -- Reset to EXPLORING if combat is nil
            print("ERROR: Combat state active but combat system is nil. Reverting to EXPLORING.")
            self.state = STATES.EXPLORING
        end
    elseif self.state == STATES.COMPLETED then
        -- Draw completion message and button
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
        
        love.graphics.setFont(screenManager.fonts.large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Dungeon Completed!",
            0, GAME.height / 3,
            GAME.width, "center"
        )
        
        if self.currentQuest then
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.printf(
                "Quest: " .. self.currentQuest.name .. " - Complete",
                0, GAME.height / 3 + 50,
                GAME.width, "center"
            )
        end
        
        -- Draw return button
        if self.elements.completeButton then
            self.elements.completeButton:draw()
        end
    end
    
    -- Draw UI buttons (except in combat)
    if self.state ~= STATES.COMBAT then
        if self.elements.characterInfoButton then self.elements.characterInfoButton:draw() end
        if self.elements.inventoryButton then self.elements.inventoryButton:draw() end
        if self.elements.statusButton then self.elements.statusButton:draw() end
    end
    
    -- Draw confirmation dialog last (if visible)
    if self.elements.confirmDialog and self.elements.confirmDialog.visible then
        self.elements.confirmDialog:draw()
    end
    
end

function dungeon:keypressed(key, scancode, isrepeat)

    -- Toggle CRT effect with F5
    if key == "f5" then
        raycaster:keypressed(key)
        return true
    end

    -- Toggle texture rendering for debugging
    if key == 't' and GAME.debug then
        self:toggleWallTextures()
        return true
    elseif key == 'f' and GAME.debug then
        self:toggleFloorTextures()
        return true
    end

    
    -- Process keys based on state
    if self.state == STATES.EXPLORING then
        -- Inventory shortcut
        if key == 'i' then
            self:openInventory()
            return true
        end
        
        -- Character Info shortcut
        if key == 'c' then
            self:openCharacterInfo()
            return true
        end
        
        -- Status bar shortcut
        if key == 'j' then
            self:toggleStatusBar()
            return true
        end
        
        -- Handle key presses for exploring state (like minimap toggle)
        if key == "m" then
            -- Toggle minimap
            self.elements.minimap.visible = not self.elements.minimap.visible
            return true -- Handled
        end
    elseif self.state == STATES.COMBAT and self.combat then
        if self.combat:keypressed(key) then
            -- If combat system signals completion via keypress, handle victory/defeat immediately
            if self.combat:isVictory() then
                -- Get loot and enemy info before potential state change
                local loot = self.combat:getLoot()
                local enemyToRemove = self.combat.enemy

                -- Handle victory rewards (loot, remove enemy)
                if GAME.inventory and loot then
                    for _, item in ipairs(loot) do 
                        itemSystem:addToInventory(item)
                    end
                end
                
                -- Handle multiple enemies if present
                if self.combat.enemies and #self.combat.enemies > 0 then
                    -- Track entities to remove
                    local entitiesToRemove = {}
                    
                    -- Find enemies to remove
                    for _, combatEnemy in ipairs(self.combat.enemies) do
                        for i, entity in ipairs(self.entities) do
                            if entity.type == "monster" and entity.id == combatEnemy.id then
                                table.insert(entitiesToRemove, i)
                                break
                            end
                        end
                    end
                    
                    -- Remove entities and update quest progress
                    table.sort(entitiesToRemove, function(a, b) return a > b end)
                    for _, index in ipairs(entitiesToRemove) do
                        -- Get entity before removing it
                        local entity = self.entities[index]
                        
                        -- Make sure entity exists before accessing its properties
                        if entity then
                            -- Update quest progress for kill quests
                            if entity.type == "monster" and self.currentQuest and self.currentQuest.type == "KILL" then
                                -- Trigger kill event
                                local questSystem = require("gameplay/questSystem")
                                questSystem:updateProgress("kill", {monsterId = entity.id})
                                
                                if GAME.debug then
                                    print("Keypressed: Updated kill quest progress for monster ID: " .. entity.id)
                                end
                            end
                            
                            -- Remove the entity
                            table.remove(self.entities, index)
                        else
                            print("Warning: Tried to access nil entity at index " .. index)
                        end
                    end
                else
                    -- Handle single enemy for backward compatibility
                    local enemyToRemove = self.combat.enemy
                    
                    -- Make sure enemyToRemove exists before proceeding
                    if enemyToRemove then
                        for i = #self.entities, 1, -1 do
                            if self.entities[i] == enemyToRemove then
                                -- Update quest progress for kill quests if applicable
                                if enemyToRemove.type == "monster" and self.currentQuest and self.currentQuest.type == "KILL" then
                                    -- Trigger kill event through quest system
                                    local questSystem = require("gameplay/questSystem")
                                    questSystem:updateProgress("kill", {monsterId = enemyToRemove.id})
                                    
                                    if GAME.debug then
                                        print("Keypressed: Updated kill quest progress for monster ID: " .. enemyToRemove.id)
                                    end
                                end
                                
                                table.remove(self.entities, i)
                                break
                            end
                        end
                    else
                        print("Warning: Tried to handle nil enemyToRemove in single-enemy combat")
                    end
                end

                -- Check for level ups
                local charactersToLevelUp = {}
                if GAME.party then
                    for _, char in ipairs(GAME.party) do
                        -- Check if the character has the flag set from levelUp() function
                        if char.needsLevelUpScreen then
                            table.insert(charactersToLevelUp, char)
                        end
                    end
                end

                -- Transition to Level Up Screen or back to Exploring
                if #charactersToLevelUp > 0 then
                    print("Combat Victory: Triggering level up for", #charactersToLevelUp, "character(s).")
                    self.combat = nil -- Clear combat state
                    gameState:changeState("levelUp", { charactersToLevelUp = charactersToLevelUp })
                     -- Note: Don't reset killQuestNotificationShown here, LevelUp screen will return
                else
                     -- No level ups, return to exploring
                    print("Combat Victory: No level ups, returning to exploring.")
                    self.state = STATES.EXPLORING
                    self.combat = nil
                    -- Reset kill quest notification flag AFTER victory if no level up occurs
                    self.killQuestNotificationShown = false
                    -- Return to dungeon music
                    assetManager:playMusic("dungeon")
                end

            else
                -- Handle defeat                 
                self:failQuest()
            end
            return true -- Indicate keypress was handled and led to state change
        end
    elseif self.state == STATES.COMPLETED then
        if key == "return" or key == "space" then
             self:completeQuest()
             return true -- Handled
        end
    end
    
    -- If not handled above, return false
    return false
end

function dungeon:mousepressed(x, y, button, istouch, presses)
    -- First, check if panels are open and handle their clicks
    if self.elements.confirmDialog.visible then
        return self.elements.confirmDialog:clicked(x, y, button)
    end
    
    -- Handle Inventory/Quest button clicks ONLY if panels are NOT open
    if self.state == STATES.EXPLORING then
        if self.elements.characterInfoButton:clicked(x, y, button) then return true end
        if self.elements.inventoryButton:clicked(x, y, button) then return true end
        if self.elements.statusButton:clicked(x, y, button) then return true end
    end

    -- Pass mouse press to combat system ONLY if in combat state
    if self.state == STATES.COMBAT and self.combat then
        if self.combat:mousepressed(x, y, button) then
            -- If combat system signals completion via mouse click (on Continue button)
            if self.combat:isVictory() then
                -- Get loot before potential state change
                local loot = self.combat:getLoot()
                
                -- Handle victory rewards (loot, remove enemies)
                if GAME.inventory and loot then
                    for _, item in ipairs(loot) do 
                        itemSystem:addToInventory(item)
                    end
                end
                
                -- Remove all defeated enemies from the entities list
                -- With multiple enemies, we need to handle all enemies that were in combat
                if self.combat.enemies and #self.combat.enemies > 0 then
                    -- Create a table to track which entities to remove
                    local entitiesToRemove = {}
                    
                    -- Find all of the combat enemies in the dungeon entities
                    for _, combatEnemy in ipairs(self.combat.enemies) do
                        for i, entity in ipairs(self.entities) do
                            -- Match by ID and position if possible
                            if entity.type == "monster" and entity.id == combatEnemy.id then
                                -- Check if position values exist before calculating distance
                                if combatEnemy.x ~= nil and combatEnemy.y ~= nil and entity.x ~= nil and entity.y ~= nil then
                                    -- If entity positions approximately match the combat enemy
                                    -- (Using a small tolerance for floating point comparison)
                                    local distX = entity.x - combatEnemy.x
                                    local distY = entity.y - combatEnemy.y
                                    local dist = math.sqrt(distX*distX + distY*distY)
                                    
                                    -- Match by position with small tolerance
                                    if dist < 2.0 then
                                        table.insert(entitiesToRemove, i)
                                        break
                                    end
                                else
                                    -- If positions aren't available, match by ID only
                                    table.insert(entitiesToRemove, i)
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Remove the entities in reverse order to avoid index shifting issues
                    table.sort(entitiesToRemove, function(a, b) return a > b end)
                    for _, index in ipairs(entitiesToRemove) do
                        -- Get the entity before removing it
                        local entity = self.entities[index]
                        
                        -- Make sure entity exists before accessing its properties
                        if entity then
                            -- Update quest progress for kill quests if applicable
                            if entity.type == "monster" and self.currentQuest and self.currentQuest.type == "KILL" then
                                -- Trigger kill event through quest system
                                local questSystem = require("gameplay/questSystem")
                                questSystem:updateProgress("kill", {monsterId = entity.id})
                                
                                if GAME.debug then
                                    print("Updated kill quest progress for monster ID: " .. entity.id)
                                end
                            end
                            
                            -- Remove the entity
                            table.remove(self.entities, index)
                        else
                            print("Warning: Tried to access nil entity at index " .. index)
                        end
                    end
                    
                elseif self.combat.enemy then
                    -- Backward compatibility for single enemy combat
                    local enemyToRemove = self.combat.enemy
                    
                    -- Make sure enemyToRemove exists before proceeding
                    if enemyToRemove then
                        for i = #self.entities, 1, -1 do
                            if self.entities[i] == enemyToRemove then
                                -- Update quest progress for kill quests if applicable
                                if enemyToRemove.type == "monster" and self.currentQuest and self.currentQuest.type == "KILL" then
                                    -- Trigger kill event through quest system
                                    local questSystem = require("gameplay/questSystem")
                                    questSystem:updateProgress("kill", {monsterId = enemyToRemove.id})
                                    
                                    if GAME.debug then
                                        print("Updated kill quest progress for monster ID: " .. enemyToRemove.id)
                                    end
                                end
                                
                                table.remove(self.entities, i)
                                break
                            end
                        end
                    else
                        print("Warning: Tried to handle nil enemyToRemove in single-enemy combat")
                    end
                end

                -- Check for level ups
                local charactersToLevelUp = {}
                if GAME.party then
                    for _, char in ipairs(GAME.party) do
                        -- Check if the character has the flag set from levelUp() function
                        if char.needsLevelUpScreen then
                            table.insert(charactersToLevelUp, char)
                        end
                    end
                end

                -- Transition to Level Up Screen or back to Exploring
                if #charactersToLevelUp > 0 then
                    print("Combat Victory: Triggering level up for", #charactersToLevelUp, "character(s).")
                    self.combat = nil -- Clear combat state
                    gameState:changeState("levelUp", { charactersToLevelUp = charactersToLevelUp })
                     -- Note: Don't reset killQuestNotificationShown here, LevelUp screen will return
                else
                     -- No level ups, return to exploring
                    print("Combat Victory: No level ups, returning to exploring.")
                    self.state = STATES.EXPLORING
                    self.combat = nil
                    -- Reset kill quest notification flag AFTER victory if no level up occurs
                    self.killQuestNotificationShown = false
                    -- Return to dungeon music
                    assetManager:playMusic("dungeon")
                end

            else
                -- Handle defeat                 
                self:failQuest()
            end
            return true -- Indicate click was handled and led to state change
        end
    -- Handle mouse press for completed state (Return to Town button)
    elseif self.state == STATES.COMPLETED then
        if self.elements.completeButton and self.elements.completeButton:clicked(x, y, button) then
             self:completeQuest()
             return true -- Handled
        end
    end
    
    -- If not handled by combat or completion screen, return false
    return false
end

function dungeon:completeQuest()
    -- Handle quest completion
    if self.currentQuest then
        -- Add quest to completed quests
        if GAME.completedQuests then
            table.insert(GAME.completedQuests, self.currentQuest)
        end
        
        -- Give quest rewards
        if self.currentQuest.goldReward and GAME.gold then
            GAME.gold = GAME.gold + self.currentQuest.goldReward
        end
        
        if self.currentQuest.itemRewards and GAME.inventory then
            for _, item in ipairs(self.currentQuest.itemRewards) do
                table.insert(GAME.inventory, item)
            end
        end
    end
    
    -- Make sure to clean up minions when leaving dungeon
    self:exitDungeon()
    
    -- Return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

function dungeon:failQuest()
    -- Handle quest failure
    
    -- Make sure to clean up minions when leaving dungeon
    self:exitDungeon()
    
    -- For now, just return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

-- Add this method to handle window resizing
function dungeon:onResize(width, height)
    -- Update raycaster dimensions
    raycaster:init(width, height)
    
    -- Update raycaster camera
    raycaster:setCamera(self.playerPos.x, self.playerPos.y, self.playerPos.angle)
    
    -- Update UI element positions
    self.elements.completeButton.x = width / 2 - 100
    self.elements.completeButton.y = height - 80
    
    -- Update minimap position
    self.elements.minimap.x = width - 220
    
    -- You might need to update other position-dependent elements here
end

-- Open Inventory Screen
function dungeon:openInventory()
    -- Store texture settings before switching screens
    self.textureSettings.wallTexturesEnabled = raycaster.texturesEnabled
    self.textureSettings.floorTexturesEnabled = raycaster.floorTexturesEnabled
    
    local gameState = require("states/gameState")
    gameState:changeState("inventory", { from = "dungeon" })
end

-- Open Character Info Screen
function dungeon:openCharacterInfo()
    -- Store texture settings before switching screens
    self.textureSettings.wallTexturesEnabled = raycaster.texturesEnabled
    self.textureSettings.floorTexturesEnabled = raycaster.floorTexturesEnabled
    
    local gameState = require("states/gameState")
    gameState:changeState("characterInfo", { from = "dungeon" })
end

-- Function to handle drawing the exploring state
function dungeon:drawExploringState()
    -- Safety check for map - if no map, render an error message instead of crashing
    if not self.map then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.printf("Error: Map data is missing. Please restart the game.", 
            0, GAME.height/2 - 50, GAME.width, "center")
        print("ERROR: Attempted to draw dungeon with nil map!")
        return
    end
    
    -- Safety check for raycaster
    if not raycaster or not raycaster.render then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.printf("Error: Raycaster is not properly initialized.", 
            0, GAME.height/2 - 50, GAME.width, "center")
        print("ERROR: Raycaster not properly initialized!")
        return
    end
    
    -- Draw 3D view from raycaster
    love.graphics.setColor(1, 1, 1)
    raycaster:render(self.map, self.entities)
    
    -- Draw status bar if it exists and is visible
    if self.elements.statusBar and self.statusBarVisible then
        self.elements.statusBar:draw()
    end
    
    -- Draw objective reached reminder if applicable
    if self.objective and self.objective.reached and not self.objective.completed and 
       self.currentQuest and self.currentQuest.type == "EXPLORE" then
        -- Display a message indicating the player should return to entrance
        love.graphics.setColor(0, 1, 0, 0.7 + math.sin(love.timer.getTime() * 2) * 0.3) -- Pulsing green
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.printf(
            "Objective reached! Return to the entrance to complete your quest.",
            0, 100, GAME.width, "center"
        )
    end
    
    -- Draw debug info
    if GAME.debug then
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.print("Player Pos: " .. string.format("%.2f, %.2f", self.playerPos.x, self.playerPos.y), 10, 70)
        love.graphics.print("Player Angle: " .. string.format("%.2f", self.playerPos.angle), 10, 90)
        love.graphics.print("Map size: " .. self.map.width .. "x" .. self.map.height, 10, 110)

        if self.map and self.map.getHintFactor then
            local playerCellX = math.floor(self.playerPos.x)
            local playerCellY = math.floor(self.playerPos.y)
            local floorHint = self.map:getHintFactor(playerCellX, playerCellY, "floor")
            love.graphics.print("Floor Hint (Player Tile): " .. string.format("%.2f", floorHint or 0), 10, 130)

            -- For wall hint factor: Cast a short ray to find the wall in front.
            local rayDirX = math.cos(self.playerPos.angle)
            local rayDirY = math.sin(self.playerPos.angle)
            -- Check a short distance in front of the player (e.g., 0.5 units)
            local wallCheckX = self.playerPos.x + rayDirX * 0.5 
            local wallCheckY = self.playerPos.y + rayDirY * 0.5
            local wallCellX = math.floor(wallCheckX)
            local wallCellY = math.floor(wallCheckY)
            local wallHintText = "Wall Hint (Front): N/A"

            -- Check if the cell in front is actually a wall before getting its hint factor
            if self.map:getCell(wallCellX, wallCellY) > 0 then 
                local wallHint = self.map:getHintFactor(wallCellX, wallCellY, "wall")
                wallHintText = "Wall Hint (Front): " .. string.format("%.2f", wallHint or 0)
            end
            love.graphics.print(wallHintText, 10, 150)
        end
        
        -- Draw entity info, starting further down to accommodate new hint prints
        -- local entityStartY = 110 
        -- for i, entity in ipairs(self.entities) do
        --     love.graphics.print("Entity " .. i .. ": " .. string.format("%.2f, %.2f", entity.x, entity.y), 10, entityStartY + (i-1) * 20)
        -- end
    end
end

-- Toggle Status Bar Visibility
function dungeon:toggleStatusBar()
    self.statusBarVisible = not self.statusBarVisible
    self.elements.statusBar.visible = self.statusBarVisible
    if self.statusBarVisible then
        -- Reset timer when manually shown
        self.statusBarTimer = 10
    end
end

-- Add a function to toggle texture rendering (for performance or debug purposes)
function dungeon:toggleWallTextures()
    raycaster.texturesEnabled = not raycaster.texturesEnabled
    self.textureSettings.wallTexturesEnabled = raycaster.texturesEnabled
    print("Wall textures " .. (raycaster.texturesEnabled and "enabled" or "disabled"))
end

function dungeon:toggleFloorTextures()
    raycaster.floorTexturesEnabled = not raycaster.floorTexturesEnabled
    self.textureSettings.floorTexturesEnabled = raycaster.floorTexturesEnabled
    print("Floor textures " .. (raycaster.floorTexturesEnabled and "enabled" or "disabled"))
end

-- When exiting dungeon
function dungeon:exitDungeon()
    -- Clear all minions when exiting dungeon
    minionManager:onDungeonExit()
end

-- Handle mouse wheel scrolling
function dungeon:wheelmoved(x, y)
    -- Forward wheel events to combat system if in combat state
    if self.state == STATES.COMBAT and self.combat then
        if self.combat:wheelmoved(x, y) then
            return true -- If combat handled it, return true
        end
    end
    
    return false -- Not handled
end

-- Add this new function to refresh character stats
function dungeon:refreshCharacterStats()
    if not GAME.party then return end
    
    -- Recalculate derived stats for all party members
    for _, character in ipairs(GAME.party) do
        local charSystem = require("gameplay/character")
        character.attackPower = charSystem:calculateAttackPower(character)
        character.magicPower = charSystem:calculateMagicPower(character)
        character.defense = charSystem:calculateDefense(character)
        character.magicDefense = charSystem:calculateMagicDefense(character)
        
        if GAME.debug then
            print("Refreshed stats for " .. character.name .. ":")
            print("  Attack: " .. character.attackPower)
            print("  Magic: " .. character.magicPower)
            print("  Defense: " .. character.defense)
            print("  Magic Def: " .. character.magicDefense)
        end
    end
    
    print("Character stats refreshed to reflect equipment changes")
end

-- Trigger a chest trap effect (called from confirm dialog)
function dungeon:triggerChestTrap(chestEntity)
    if not chestEntity or not chestEntity.isTrapped or not chestEntity.trapType then
        return false
    end
    
    -- Target is always the lead character
    local target = GAME.party[1]
    
    -- Call the trap system to apply trap effects
    local damage = trapSystem:triggerChestTrap(chestEntity, target)
    
    -- Show floating text for damage
    if damage and damage > 0 then
        self:showFloatingText(
            string.format("-%d", damage), 
            GAME.width / 2, 
            GAME.height / 2 - 50, 
            {1, 0.2, 0.2, 1},
            1.5
        )
    end
    
    return true
end

-- Collect loot from a chest (called after trap check)
function dungeon:collectChestLoot(chestEntity)
    if not chestEntity or not chestEntity.contents then
        return false
    end
    
    -- Add all items to inventory
    for _, item in ipairs(chestEntity.contents) do
        if item.type == "gold" then
            GAME.gold = (GAME.gold or 0) + item.amount
            print("Collected Gold: " .. item.amount) -- Debug
        else
            -- Check if this collected item is a quest item
            if item.questItemId and self.currentQuest and 
               self.currentQuest.type == "COLLECT" and 
               item.questItemId == self.currentQuest.objective.itemId then
                print("Collected QUEST ITEM from chest: " .. item.name)
                questSystem:updateProgress("item_pickup", {itemId = item.questItemId, count = item.count or 1})
            end
            itemSystem:addToInventory(item)
            print("Collected Item: " .. item.name) -- Debug
        end
    end
    
    -- Play pickup sound
    assetManager:playSound("pickup")
    
    return true
end

-- Check if player is looking at an interactable wall and handle interaction
function dungeon:checkWallInteraction()
    -- Skip if a dialog is already visible
    if self.elements.confirmDialog.visible then
        return
    end
    
    -- Define ray parameters
    local maxRayLength = 1.5 -- Maximum interaction distance
    local rayDir = {
        x = math.cos(self.playerPos.angle),
        y = math.sin(self.playerPos.angle)
    }
    
    -- Simple ray cast to check for walls in front of player
    local rayX = self.playerPos.x
    local rayY = self.playerPos.y
    local distTraveled = 0
    local step = 0.05 -- Step size for ray
    
    while distTraveled < maxRayLength do
        -- Move ray forward
        rayX = rayX + rayDir.x * step
        rayY = rayY + rayDir.y * step
        distTraveled = distTraveled + step
        
        -- Get map cell at ray position
        local cellX = math.floor(rayX)
        local cellY = math.floor(rayY)
        
        -- Check if we hit a wall
        if self.map:getCell(cellX, cellY) > 0 then
            -- Check if it's an interactable wall
            if self.map.isWallInteractable and self.map:isWallInteractable(cellX, cellY) then
                -- Show interaction prompt
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1, 0.9)
                
                -- Get the interactable wall for prompt text
                local wall = self.map:getInteractableWall(cellX, cellY)
                local promptText = wall and wall.interactionPrompt or "Interact [E]"
                
                -- Draw prompt in center of screen
                love.graphics.printf(
                    promptText, 
                    GAME.width / 2 - 150, 
                    GAME.height / 2 + 50,
                    300, "center"
                )
                
                -- Check for interaction (E key is pressed)
                if love.keyboard.isDown("e") then
                    -- Interact with the wall
                    if interactables:activateWall(self.map, cellX, cellY, GAME.party[1]) then
                        -- If successful, don't allow interaction for a short time to prevent spam
                        self.wallInteractionCooldown = 0.5
                    end
                end
            end
            
            -- Check if it's a secret passage
            if self.map.isSecretPassage and self.map:isSecretPassage(cellX, cellY) then
                local passage = self.map:getSecretPassage(cellX, cellY)
                
                -- If passage is not yet revealed, show interaction prompt
                if passage and not passage.secretPassageRevealed then
                    love.graphics.setFont(screenManager.fonts.medium)
                    love.graphics.setColor(1, 1, 1, 0.9)
                    
                    -- Draw prompt in center of screen
                    love.graphics.printf(
                        "Examine wall [E]", 
                        GAME.width / 2 - 150, 
                        GAME.height / 2 + 50,
                        300, "center"
                    )
                    
                    -- Check for interaction (E key is pressed)
                    if love.keyboard.isDown("e") then
                        -- Try to reveal the passage
                        if interactables:revealSecretPassage(self.map, cellX, cellY) then
                            -- If successful, don't allow interaction for a short time
                            self.wallInteractionCooldown = 0.5
                        end
                    end
                end
            end
            
            -- Don't need to check further
            break
        end
    end
end

-- Update trap detection and interaction hints based on player position
function dungeon:updateTrapsAndInteractables(dt)
    -- Skip if map is not initialized
    if not self.map then return end
        
    -- Update hint factors for secret passages and traps based on player position and party composition
    interactables:updateHintFactors(self.map, self.playerPos.x, self.playerPos.y)
    trapSystem:updateTrapHintFactors(self.map, self.playerPos.x, self.playerPos.y)
    
    -- Check if player is standing on a trap
    if self.map.getTrap then
        local trapX = math.floor(self.playerPos.x)
        local trapY = math.floor(self.playerPos.y)
        local trap = self.map:getTrap(trapX, trapY)
        
        -- If there's a trap and it's active
        if trap and trap.isTrapActive and not trap.isTrapDisarmed then
            -- Check for trap detection
            local detectResult = false
            if not trap.isTrapDetected then
                detectResult = trapSystem:checkTrapDetection(trap) -- Updated call
                
                -- If trap was just detected, show a notification
                if detectResult then
                    self:showFloatingText("Trap Detected!", 
                         GAME.width / 2, 
                         GAME.height / 2 - 80, 
                         {1, 0.8, 0.2, 1},
                         1.5)
                end
            end
            
            -- If trap is detected and no other dialog is open, show interact prompt
            if trap.isTrapDetected and not self.elements.confirmDialog.visible then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 0.5, 0.5, 0.9)
                
                -- Draw trap warning in center of screen
                love.graphics.printf(
                    "Trap Detected! Disarm [E]", 
                    GAME.width / 2 - 150, 
                    GAME.height / 2 + 80,
                    300, "center"
                )
                
                -- Check for disarm attempt (E key is pressed)
                if love.keyboard.isDown("e") and not self.trapDisarmCooldown then
                    -- Try to disarm the trap
                    local disarmResult = trapSystem:attemptDisarm(trap) -- Updated call
                    
                    if disarmResult then
                        -- Show success message
                        self:showFloatingText("Trap Disarmed!", GAME.width / 2, GAME.height / 2 - 80, {0.2, 1, 0.2, 1}, 1.5)
                    else
                        -- Show failure message
                        self:showFloatingText(
                            "Disarm Failed!", 
                            GAME.width / 2, 
                            GAME.height / 2 - 80, 
                            {1, 0.2, 0.2, 1},
                            1.5
                        )
                    end
                    
                    -- Set cooldown to prevent spam
                    self.trapDisarmCooldown = 1.0
                end
            else
                -- If trap is not detected and not triggered yet, chance to trigger it
                if not trap.isTrapDetected and math.random() < 0.7 and not self.trapTriggerCooldown then
                    -- Trigger the trap
                    trapSystem:activateTrap(trap, GAME.party[1])
                    
                    -- Show damage message
                    self:showFloatingText(
                        "Triggered Trap!", 
                        GAME.width / 2, 
                        GAME.height / 2 - 80, 
                        {1, 0.2, 0.2, 1},
                        1.5
                    )
                    
                    -- Set cooldown
                    self.trapTriggerCooldown = 1.0
                end
            end
        end
    end
    
    -- Update cooldowns
    if self.wallInteractionCooldown then
        self.wallInteractionCooldown = self.wallInteractionCooldown - dt
        if self.wallInteractionCooldown <= 0 then
            self.wallInteractionCooldown = nil
        end
    end
    
    if self.trapDisarmCooldown then
        self.trapDisarmCooldown = self.trapDisarmCooldown - dt
        if self.trapDisarmCooldown <= 0 then
            self.trapDisarmCooldown = nil
        end
    end
    
    if self.trapTriggerCooldown then
        self.trapTriggerCooldown = self.trapTriggerCooldown - dt
        if self.trapTriggerCooldown <= 0 then
            self.trapTriggerCooldown = nil
        end
    end
end

-- Show floating text on screen
function dungeon:showFloatingText(text, x, y, color, duration)
    -- Default values
    x = x or GAME.width / 2
    y = y or GAME.height / 2
    color = color or {1, 1, 1, 1}
    duration = duration or 1.0
    
    -- Create floating text effect
    -- This is just a stub - in a real implementation, this would add the text
    -- to a list of floating texts that would be rendered and updated over time
    print("Floating text: " .. text)
end

return dungeon
