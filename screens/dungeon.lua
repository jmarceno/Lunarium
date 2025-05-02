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

local dungeon = screenManager:createScreen("Dungeon")

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
    self.inventoryPanelVisible = false
    self.questLogPanelVisible = false
    self.selectedInventoryItemIndex = nil
    self.statusBarVisible = true -- Initially visible
    self.statusBarTimer = 10 -- 10 seconds timer
    self.transitionStarted = false
    self.loot = {}
    self.currentMonster = nil
    
    -- UI elements (Initialize the table first!)
    self.elements = {}
    
    -- Confirmation Dialog
    self.elements.confirmDialog = {
        visible = false,
        message = "",
        confirmCallback = nil,
        cancelCallback = nil,
        x = GAME.width / 2 - 175,
        y = GAME.height / 2 - 75,
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
            screenManager:drawPanel(nil, self.x, self.y, self.width, self.height)
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1,1,1)
            love.graphics.printf(self.message, self.x + 10, self.y + 20, self.width - 20, "center")
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
    
    -- Inventory Button (Bottom Right)
    self.elements.inventoryButton = screenManager.UI.Button(
        GAME.width - 110, GAME.height - 110, 100, 30, "Inventory (I)",
        function() self:openInventory() end
    )
    
    -- Quest Log Button (Bottom Right, above Inventory)
    self.elements.questLogButton = screenManager.UI.Button(
        GAME.width - 110, GAME.height - 150, 100, 30, "Quests (J)",
        function() self:toggleQuestLogPanel() end
    )
    
    -- Status Button (Bottom Right, left of Inventory)
    self.elements.statusButton = screenManager.UI.Button(
        GAME.width - 220, GAME.height - 110, 100, 30, "Status (K)",
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
                            if x == entityX and y == entityY and entity.type ~= "objective" then
                                love.graphics.setColor(entity.color or {1, 0, 0})
                                love.graphics.circle("fill", 
                                    self.x + entity.x * cellSize, 
                                    self.y + entity.y * cellSize, 
                                    cellSize/2)
                            end
                        end
                    end
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
    
    -- Party Panel to display character info
    self.elements.partyPanel = {
        x = 10,
        y = GAME.height - 70,
        width = GAME.width - 20,
        height = 60,
        
        draw = function(self)
            if not GAME.party then return end
            
            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            love.graphics.setColor(0.3, 0.3, 0.5)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw party member info
            local memberWidth = self.width / #GAME.party
            for i, character in ipairs(GAME.party) do
                local portraitX = self.x + (i-1) * memberWidth + 10
                local portraitY = self.y + 10
                
                -- Draw character name
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(character.name, portraitX, portraitY)
                
                -- Draw HP/MP bars
                if character.currentHP and character.maxHP then
                    -- HP bar
                    local hpWidth = (memberWidth - 20) * (character.currentHP / character.maxHP)
                    love.graphics.setColor(0.5, 0, 0)
                    love.graphics.rectangle("fill", portraitX, portraitY + 20, memberWidth - 20, 10)
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.rectangle("fill", portraitX, portraitY + 20, hpWidth, 10)
                    
                    -- HP text
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(character.currentHP .. "/" .. character.maxHP, portraitX + 5, portraitY + 19)
                    
                    -- MP bar if character has MP
                    if character.currentMP and character.maxMP then
                        local manaWidth = (memberWidth - 20) * (character.currentMP / character.maxMP)
                        love.graphics.setColor(0, 0, 0.5)
                        love.graphics.rectangle("fill", portraitX, portraitY + 35, memberWidth - 20, 10)
                        love.graphics.setColor(0, 0, 1)
                        love.graphics.rectangle("fill", portraitX, portraitY + 35, manaWidth, 10)
                        
                        -- MP text
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.print(character.currentMP .. "/" .. character.maxMP, portraitX + 5, portraitY + 34)
                    end
                end
            end
        end
    }
    
    -- Quest Log Panel (Hidden Initially)
    self.elements.questLogPanel = {
        visible = false,
        x = GAME.width / 2 - 250,
        y = GAME.height / 2 - 150,
        width = 500,
        height = 300,
        closeButton = nil,
        
        init = function(self)
            self.closeButton = screenManager.UI.Button(
                self.x + self.width / 2 - 60, self.y + self.height - 60,
                120, 40, "Close (ESC)",
                function() dungeon:toggleQuestLogPanel() end
            )
        end,
        
        draw = function(self)
            if not self.visible then return end
            if not self.closeButton then self:init() end
            
            -- Placeholder draw function
            love.graphics.setColor(0.15, 0.1, 0.1, 0.95)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.printf("Quest Log", self.x, self.y + 10, self.width, "center")
            
            -- Display Current Quest
            if GAME.debug then
                print("Drawing Quest Log Panel. dungeon.currentQuest is:", dungeon.currentQuest)
                if dungeon.currentQuest then
                    print("  Quest Name:", dungeon.currentQuest.name)
                    print("  Quest Desc:", dungeon.currentQuest.description)
                end
            end
            
            love.graphics.setFont(screenManager.fonts.medium)
            if dungeon.currentQuest then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("Current Quest:", self.x + 20, self.y + 60)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(dungeon.currentQuest.name, self.x + 40, self.y + 90)
                
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.9, 0.9, 0.9)
                -- Simple word wrapping for description
                local description = dungeon.currentQuest.description or "No description available."
                local wrappedText = {}
                local maxWidth = self.width - 60
                local font = screenManager.fonts.small
                local lines = {}
                for line in string.gmatch(description, "([^\\n]*)\\n?") do
                    local currentLine = ""
                    for word in string.gmatch(line .. " ", "(%S+)%s*") do
                        local testLine = currentLine .. word .. " "
                        if font:getWidth(testLine) <= maxWidth then
                            currentLine = testLine
                        else
                            table.insert(lines, currentLine)
                            currentLine = word .. " "
                        end
                    end
                    table.insert(lines, currentLine)
                end
                
                local textY = self.y + 120
                for _, line in ipairs(lines) do
                    love.graphics.print(line, self.x + 40, textY)
                    textY = textY + font:getHeight() + 2
                end
            else
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.printf("No active quest.", self.x, self.y + 100, self.width, "center")
            end
            
            -- Draw Close button
            self.closeButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            if self.closeButton:clicked(x, y, button) then return true end
            
            return false -- Click was inside but not on the button
        end
    }
end

function dungeon:enter(params)
    -- Check if we're returning from inventory
    if params and params.from == "inventory" and self.map then
        -- We're coming back from inventory, keep the existing dungeon state
        -- Just update the camera
        raycaster:setCamera(self.playerPos.x, self.playerPos.y, self.playerPos.angle)
        return
    end
    
    -- Otherwise initialize a new dungeon
    self.state = STATES.EXPLORING
    self.objective.completed = false
    self.objective.reached = false
    
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
        
        -- Set player starting position
        self.playerPos = {
            x = self.map.start.x + 0.5,
            y = self.map.start.y + 0.5,
            angle = 0
        }
        
        -- Adjust the player's position to be away from the entrance
        -- Calculate direction toward dungeon center
        local centerX = self.map.width / 2
        local centerY = self.map.height / 2
        
        -- Calculate direction vector from start to center
        local dirX = centerX - self.map.start.x
        local dirY = centerY - self.map.start.y
        
        -- Normalize the direction vector
        local length = math.sqrt(dirX*dirX + dirY*dirY)
        if length > 0 then
            dirX = dirX / length
            dirY = dirY / length
            
            -- Move player 1.5 units in this direction (enough to not touch entrance)
            self.playerPos.x = self.map.start.x + 0.5 + (dirX * 1.5)
            self.playerPos.y = self.map.start.y + 0.5 + (dirY * 1.5)
            
            -- Set player's angle to face away from entrance (toward dungeon center)
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
        
        -- Set player starting position
        self.playerPos = {
            x = self.map.start.x + 0.5,
            y = self.map.start.y + 0.5,
            angle = 0
        }
        
        -- Adjust the player's position to be away from the entrance
        -- Calculate direction toward dungeon center
        local centerX = self.map.width / 2
        local centerY = self.map.height / 2
        
        -- Calculate direction vector from start to center
        local dirX = centerX - self.map.start.x
        local dirY = centerY - self.map.start.y
        
        -- Normalize the direction vector
        local length = math.sqrt(dirX*dirX + dirY*dirY)
        if length > 0 then
            dirX = dirX / length
            dirY = dirY / length
            
            -- Move player 1.5 units in this direction (enough to not touch entrance)
            self.playerPos.x = self.map.start.x + 0.5 + (dirX * 1.5)
            self.playerPos.y = self.map.start.y + 0.5 + (dirY * 1.5)
            
            -- Set player's angle to face away from entrance (toward dungeon center)
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
                    stats = fetchedMonsterData.stats
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
            stats = fetchedBossData.stats -- Make sure boss stats are defined
        })
         -- Optionally add filler monsters/items, avoiding the end room
        self:addFillerEntities(difficulty, 5, true) 

    elseif questType == "ESCORT" then
        -- TODO: Add NPC entity to follow player
        print("ESCORT quest population not fully implemented.")
        self:addFillerEntities(difficulty, 5)
        
    elseif questType == "EXPLORE" then
        -- No specific entities needed, objective is reaching the end
        -- Add filler monsters/items
        self:addFillerEntities(difficulty, 5)
        
    else 
        -- Fallback for unknown quest types
        self:addFillerEntities(difficulty, 5)
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
    local monsterCount = math.floor(count / 2)
    local itemCount = count - monsterCount
    
    local usedMonsterData = require("gameplay/monsterData") -- Require inside helper

    -- Add filler monsters
    for i = 1, monsterCount do
        local x, y = self:findValidSpawnPosition(avoidEnd)
        if x then
            -- Choose a random non-quest monster type
            local randomMonsterId = usedMonsterData:getRandomMonsterId(difficulty) 
            local fetchedMonsterData = usedMonsterData:getMonsterData(randomMonsterId) 
            if fetchedMonsterData then
                table.insert(self.entities, {
                    x = x + 0.5,
                    y = y + 0.5,
                    type = "monster",
                    id = randomMonsterId,
                    name = fetchedMonsterData.name, 
                    color = fetchedMonsterData.color,
                    stats = fetchedMonsterData.stats
                })
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
            -- Add random loot to chest
            item.contents = itemSystem:generateRandomLoot(difficulty, math.random(1,2)) -- Use itemSystem
            table.insert(self.entities, item)
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

    -- Update based on current state
    if self.state == STATES.EXPLORING then
        -- If quest log panel is open, don't update exploration logic (movement, etc.)
        if self.elements.questLogPanel.visible then
            return -- Stop further updates for this frame
        end
        
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
        
        if love.keyboard.isDown("w") then
            raycaster:moveCamera(moveSpeed, self.map)
            playerMoved = true
        end
        
        if love.keyboard.isDown("s") then
            raycaster:moveCamera(-moveSpeed, self.map)
            playerMoved = true
        end
        
        if love.keyboard.isDown("a") then
            raycaster:rotateCamera(-turnSpeed)
            playerMoved = true
        end
        
        if love.keyboard.isDown("d") then
            raycaster:rotateCamera(turnSpeed)
            playerMoved = true
        end
        
        if love.keyboard.isDown("q") then
            raycaster:strafeCamera(-moveSpeed, self.map)
            playerMoved = true
        end
        
        if love.keyboard.isDown("e") then
            raycaster:strafeCamera(moveSpeed, self.map)
            playerMoved = true
        end
        
        -- Update player position from raycaster
        self.playerPos.x = raycaster.camera.x
        self.playerPos.y = raycaster.camera.y
        self.playerPos.angle = raycaster.camera.angle
        
        -- Update fog of war if player moved
        if playerMoved and (self.playerPos.x ~= oldX or self.playerPos.y ~= oldY) then
            self.map:revealArea(self.playerPos.x, self.playerPos.y, self.fogOfWarRadius)
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
                self.combat = combatSystem:createCombat(GAME.party, entity)
                break
            elseif entity.type == "chest" then
                -- Open chest/collect item
                self.state = STATES.LOOT
                print("Opening chest...") -- Debug
                self.currentLoot = entity
                
                -- For now, automatically collect loot
                if GAME.inventory and entity.contents then
                    for _, item in ipairs(entity.contents) do
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
                            table.insert(GAME.inventory, item)
                            print("Collected Item: " .. item.name) -- Debug
                            -- Notify quest system if it's a regular item pickup (might be relevant for some quests)
                        end
                    end
                end
                
                -- Play pickup sound
                assetManager:playSound("pickup")
                
                -- Remove chest from entities
                for i = #self.entities, 1, -1 do
                    if self.entities[i] == entity then
                        table.remove(self.entities, i)
                        break
                    end
                end
                
                -- Return to exploring state
                self.state = STATES.EXPLORING
                self.currentLoot = nil
                -- No break here, check other interactions too
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
                print("Interacting with entrance...")
                
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

    -- Draw based on current state
    if self.state == STATES.EXPLORING then
        -- Draw 3D view only if not in inventory or quest log
        if not (self.elements.questLogPanel.visible) then
            self:drawExploringState()
        end

        -- Draw UI elements that should appear in exploring state
        self.elements.minimap:draw()
        
        -- Display party members with basic stats (bottom of screen)
        self.elements.partyPanel:draw()
    elseif self.state == STATES.COMBAT then
        -- Draw combat UI
        if self.combat then
            self.combat:draw()
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
        self.elements.completeButton:draw()
    end
    
    -- Draw UI buttons (except in combat)
    if self.state ~= STATES.COMBAT then
        self.elements.inventoryButton:draw()
        self.elements.questLogButton:draw()
        self.elements.statusButton:draw()
    end
    
    -- Draw any panels that should appear on top
    if self.elements.questLogPanel.visible then
        self.elements.questLogPanel:draw()
    end
    
    -- Draw confirmation dialog last (if visible)
    if self.elements.confirmDialog.visible then
        self.elements.confirmDialog:draw()
    end
end

function dungeon:keypressed(key, scancode, isrepeat)
    -- Exit to console shortcut (for debugging only)
    if key == '`' and GAME.debug then
        return false -- Let base game handle console
    end

    -- Check if panels are open and escape pressed
    if self.elements.questLogPanel.visible then
        if key == 'escape' then
            self:toggleQuestLogPanel()
            return true
        end
    end
    
    -- Process keys based on state
    if self.state == STATES.EXPLORING then
        -- Inventory shortcut
        if key == 'i' then
            self:openInventory()
            return true
        end
        
        -- Quest log shortcut
        if key == 'j' then
            self:toggleQuestLogPanel()
            return true
        end
        
        -- Status bar shortcut
        if key == 'k' then
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
                -- Handle victory rewards
                local loot = self.combat:getLoot()
                if GAME.inventory and loot then
                    for _, item in ipairs(loot) do table.insert(GAME.inventory, item) end
                end
                -- Find and remove the defeated monster from entities
                local enemyToRemove = self.combat.enemy 
                for i = #self.entities, 1, -1 do
                    if self.entities[i] == enemyToRemove then
                        table.remove(self.entities, i)
                        break
                    end
                end
                -- Return to exploring state
                self.state = STATES.EXPLORING
                self.combat = nil 
                -- Reset kill quest notification flag so we can check if quest is completed
                self.killQuestNotificationShown = false
                if GAME.debug then print("Combat over (Victory - Key), returning to dungeon") end
            else
                -- Handle defeat
                if GAME.debug then print("Combat over (Defeat - Key), returning to town") end
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
    
    if self.elements.questLogPanel.visible then
        if self.elements.questLogPanel:clicked(x, y, button) then
            return true -- Click handled by quest panel
        else
            -- Check if click was *outside* the panel bounds; if so, close it
            local panel = self.elements.questLogPanel
            if not (x >= panel.x and x <= panel.x + panel.width and y >= panel.y and y <= panel.y + panel.height) then
                self:toggleQuestLogPanel()
                return true -- Consumed click outside panel to close it
            end
            return true -- Consume click even if not handled inside panel
        end
    end
    
    -- Handle Inventory/Quest button clicks ONLY if panels are NOT open
    if self.state == STATES.EXPLORING then
        if self.elements.inventoryButton:clicked(x, y, button) then return true end
        if self.elements.questLogButton:clicked(x, y, button) then return true end
        if self.elements.statusButton:clicked(x, y, button) then return true end
    end

    -- Pass mouse press to combat system ONLY if in combat state
    if self.state == STATES.COMBAT and self.combat then
        if self.combat:mousepressed(x, y, button) then
             -- If combat system signals completion via mouse click (on Continue button)
            if self.combat:isVictory() then
                 -- Handle victory rewards
                local loot = self.combat:getLoot()
                if GAME.inventory and loot then
                    for _, item in ipairs(loot) do table.insert(GAME.inventory, item) end
                end
                -- Find and remove the defeated monster from entities
                local enemyToRemove = self.combat.enemy 
                for i = #self.entities, 1, -1 do
                    if self.entities[i] == enemyToRemove then
                        table.remove(self.entities, i)
                        break
                    end
                end
                -- Return to exploring state
                self.state = STATES.EXPLORING
                self.combat = nil 
                -- Reset kill quest notification flag so we can check if quest is completed
                self.killQuestNotificationShown = false
                if GAME.debug then print("Combat over (Victory - Mouse), returning to dungeon") end
            else
                -- Handle defeat
                if GAME.debug then print("Combat over (Defeat - Mouse), returning to town") end
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
    
    -- Return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

function dungeon:failQuest()
    -- Handle quest failure
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

-- Toggle Quest Log Panel Visibility
function dungeon:toggleQuestLogPanel()
    self.elements.questLogPanel.visible = not self.elements.questLogPanel.visible
end

-- Open Inventory Screen
function dungeon:openInventory()
    local gameState = require("states/gameState")
    gameState:changeState("inventory", { from = "dungeon" })
end

-- Function to handle drawing the exploring state
function dungeon:drawExploringState()
    -- Draw 3D view from raycaster
    love.graphics.setColor(1, 1, 1)
    raycaster:render(self.map, self.entities)
    
    -- Draw status bar if it exists and is visible
    if self.elements.statusBar and self.statusBarVisible then
        self.elements.statusBar:draw()
    end
    
    -- Draw objective reached reminder if applicable
    if self.objective.reached and not self.objective.completed and 
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
        love.graphics.print("Player Pos: " .. string.format("%.2f, %.2f", self.playerPos.x, self.playerPos.y), 10, 10)
        love.graphics.print("Player Angle: " .. string.format("%.2f", self.playerPos.angle), 10, 30)
        
        -- Draw entity info
        for i, entity in ipairs(self.entities) do
            love.graphics.print("Entity " .. i .. ": " .. string.format("%.2f, %.2f", entity.x, entity.y), 10, 50 + (i-1) * 20)
        end
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

return dungeon
