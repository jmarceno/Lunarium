-- Dungeon Screen
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local raycaster = require("engine/raycaster")
local dungeonGenerator = require("gameplay/dungeonGenerator")
local combatSystem = require("gameplay/combatSystem")

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
    -- Initialize raycaster
    raycaster:init(800, 600)
    
    -- Initialize dungeon state
    self.state = STATES.EXPLORING
    self.map = nil
    self.playerPos = {x = 0, y = 0, angle = 0}
    self.entities = {}
    self.combat = nil
    self.currentQuest = nil
    self.seed = 0
    self.moveSpeed = 0.05
    self.turnSpeed = 0.03
    self.objective = {x = 0, y = 0, completed = false}
    
    -- UI elements
    self.elements = {}
    
    self.elements.completeButton = screenManager.UI.Button(
        GAME.width / 2 - 100, GAME.height - 80, 
        200, 50, "Return to Town", 
        function() self:completeQuest() end
    )
    
    self.elements.minimap = {
        x = GAME.width - 220,
        y = 20,
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
                end
            end
            
            -- Draw objective
            love.graphics.setColor(0, 1, 0)
            love.graphics.circle("fill", 
                self.x + dungeon.objective.x * cellSize + cellSize/2, 
                self.y + dungeon.objective.y * cellSize + cellSize/2, 
                cellSize/2)
            
            -- Draw entities
            for _, entity in ipairs(dungeon.entities) do
                love.graphics.setColor(entity.color or {1, 0, 0})
                love.graphics.circle("fill", 
                    self.x + entity.x * cellSize, 
                    self.y + entity.y * cellSize, 
                    cellSize/2)
            end
            
            -- Draw player position
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
    
    -- Initialize status bar
    self.elements.statusBar = {
        draw = function(self)
            -- Draw status bar background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, GAME.height - 50, GAME.width, 50)
            
            -- Draw party health and mana
            if GAME.party then
                for i, character in ipairs(GAME.party) do
                    -- Character portrait
                    local portraitX = 10 + (i-1) * 200
                    love.graphics.setColor(1, 1, 1)
                    
                    -- Draw character name
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.print(character.name, portraitX + 50, GAME.height - 45)
                    
                    -- Draw health bar
                    local healthWidth = 140 * (character.currentHP / character.maxHP)
                    love.graphics.setColor(0.2, 0.2, 0.2)
                    love.graphics.rectangle("fill", portraitX + 50, GAME.height - 30, 140, 10)
                    love.graphics.setColor(0.8, 0.2, 0.2)
                    love.graphics.rectangle("fill", portraitX + 50, GAME.height - 30, healthWidth, 10)
                    
                    -- Draw mana bar
                    local manaWidth = 140 * (character.currentMP / character.maxMP)
                    love.graphics.setColor(0.2, 0.2, 0.2)
                    love.graphics.rectangle("fill", portraitX + 50, GAME.height - 15, 140, 10)
                    love.graphics.setColor(0.2, 0.2, 0.8)
                    love.graphics.rectangle("fill", portraitX + 50, GAME.height - 15, manaWidth, 10)
                end
            end
        end
    }
end

function dungeon:enter(params)
    self.state = STATES.EXPLORING
    self.objective.completed = false
    
    -- Start playing dungeon music
    assetManager:playMusic("dungeon")
    
    -- Load or generate dungeon
    if params and params.quest then
        self.currentQuest = params.quest
        
        -- Generate dungeon from quest seed or create a new one
        local seed = params.quest.seed or os.time()
        self.seed = seed
        self.map = dungeonGenerator:generate(20, 20, seed)
        
        -- Set player starting position
        self.playerPos = {
            x = self.map.start.x + 0.5,
            y = self.map.start.y + 0.5,
            angle = 0
        }
        
        -- Set objective position
        self.objective = {
            x = self.map.end_.x,
            y = self.map.end_.y,
            completed = false
        }
        
        -- Populate dungeon with monsters and items
        self:populateDungeon(params.quest.difficulty or 1)
    else
        -- Create a default dungeon if no quest is provided
        self.map = dungeonGenerator:generate(20, 20, os.time())
        
        -- Set player starting position
        self.playerPos = {
            x = self.map.start.x + 0.5,
            y = self.map.start.y + 0.5,
            angle = 0
        }
        
        -- Set objective position
        self.objective = {
            x = self.map.end_.x,
            y = self.map.end_.y,
            completed = false
        }
        
        -- Populate dungeon with default monsters and items
        self:populateDungeon(1)
    end
    
    -- Update raycaster camera
    raycaster:setCamera(self.playerPos.x, self.playerPos.y, self.playerPos.angle)
end

function dungeon:populateDungeon(difficulty)
    self.entities = {}
    
    -- Add monsters based on difficulty
    local monsterCount = 5 + difficulty * 2
    
    for i = 1, monsterCount do
        -- Find a valid position for the monster
        local x, y
        repeat
            x = math.random(1, self.map.width - 2)
            y = math.random(1, self.map.height - 2)
        until self.map:getCell(x, y) == 0 and
              (math.abs(x - self.map.start.x) > 3 or math.abs(y - self.map.start.y) > 3) and
              (math.abs(x - self.map.end_.x) > 3 or math.abs(y - self.map.end_.y) > 3)
        
        -- Create monster entity
        local monster = {
            x = x + 0.5,
            y = y + 0.5,
            type = "monster",
            id = math.random(1, 10),  -- Random monster type
            color = {1, 0, 0},
            stats = {
                level = difficulty,
                hp = 10 * difficulty,
                attack = 5 + difficulty,
                defense = 2 + difficulty * 0.5
            }
        }
        
        table.insert(self.entities, monster)
    end
    
    -- Add items and chests
    local itemCount = 2 + math.floor(difficulty / 2)
    
    for i = 1, itemCount do
        -- Find a valid position for the item
        local x, y
        repeat
            x = math.random(1, self.map.width - 2)
            y = math.random(1, self.map.height - 2)
        until self.map:getCell(x, y) == 0 and
              (math.abs(x - self.map.start.x) > 2 or math.abs(y - self.map.start.y) > 2) and
              (math.abs(x - self.map.end_.x) > 2 or math.abs(y - self.map.end_.y) > 2)
        
        -- Create item entity (chest)
        local item = {
            x = x + 0.5,
            y = y + 0.5,
            type = "chest",
            color = {1, 0.8, 0},
            contents = {}
        }
        
        -- Add random loot to chest
        local lootCount = math.random(1, 3)
        for j = 1, lootCount do
            -- Simple random loot generation
            table.insert(item.contents, {
                type = "monster_part",
                id = math.random(1, 20),
                name = "Monster Part",
                value = 10 * difficulty * math.random(5, 15) / 10
            })
        end
        
        -- Add gold to chest with low probability
        if math.random() < 0.2 then
            table.insert(item.contents, {
                type = "gold",
                amount = 10 * difficulty * math.random(5, 20)
            })
        end
        
        table.insert(self.entities, item)
    end
end

function dungeon:update(dt)
    -- Update UI elements
    for _, element in pairs(self.elements) do
        if element.update then
            element:update(dt)
        end
    end
    
    -- Handle different states
    if self.state == STATES.EXPLORING then
        self:updateExploring(dt)
    elseif self.state == STATES.COMBAT then
        self:updateCombat(dt)
    elseif self.state == STATES.LOOT then
        self:updateLoot(dt)
    end
    
    -- Check for objective completion
    if not self.objective.completed then
        local distToObjective = math.sqrt(
            (self.playerPos.x - self.objective.x - 0.5)^2 + 
            (self.playerPos.y - self.objective.y - 0.5)^2
        )
        
        if distToObjective < 1.0 then
            self.objective.completed = true
            assetManager:playSound("victory")
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
        self.combat:update(dt)
        
        -- Check if combat is over
        if self.combat:isOver() then
            if self.combat:isVictory() then
                -- Handle victory rewards
                local loot = self.combat:getLoot()
                
                -- Add loot to inventory
                if GAME.inventory and loot then
                    for _, item in ipairs(loot) do
                        table.insert(GAME.inventory, item)
                    end
                end
                
                -- Remove defeated monster from entities
                for i = #self.entities, 1, -1 do
                    if self.entities[i] == self.combat.enemy then
                        table.remove(self.entities, i)
                        break
                    end
                end
                
                -- Return to exploring state
                self.state = STATES.EXPLORING
                self.combat = nil
            else
                -- Handle defeat
                -- For now, just return to town
                self:failQuest()
            end
        end
    end
end

function dungeon:updateLoot(dt)
    -- Loot interaction is handled via UI
end

function dungeon:checkEntityInteraction()
    -- Check for nearby entities to interact with
    for _, entity in ipairs(self.entities) do
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
                self.currentLoot = entity
                
                -- For now, automatically collect loot
                if GAME.inventory and entity.contents then
                    for _, item in ipairs(entity.contents) do
                        if item.type == "gold" then
                            GAME.gold = (GAME.gold or 0) + item.amount
                        else
                            table.insert(GAME.inventory, item)
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
                break
            end
        end
    end
end

function dungeon:draw()
    -- Clear screen
    love.graphics.clear(0, 0, 0)
    
    -- Draw 3D view from raycaster
    love.graphics.setColor(1, 1, 1)
    local renderedView = raycaster:render(self.map, self.entities)
    love.graphics.draw(renderedView)
    
    -- Draw UI elements based on current state
    if self.state == STATES.EXPLORING then
        -- Draw minimap
        self.elements.minimap:draw()
        
        -- Draw status bar
        self.elements.statusBar:draw()
        
        -- Draw objective complete message and button if objective is completed
        if self.objective.completed then
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", GAME.width / 2 - 200, GAME.height / 2 - 100, 400, 200)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.printf("Objective Complete!", GAME.width / 2 - 200, GAME.height / 2 - 80, 400, "center")
            
            -- Draw quest info
            if self.currentQuest then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.printf(self.currentQuest.name, GAME.width / 2 - 180, GAME.height / 2 - 30, 360, "center")
                
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.printf(self.currentQuest.description, GAME.width / 2 - 180, GAME.height / 2, 360, "center")
            end
            
            -- Draw return button
            self.elements.completeButton:draw()
        end
    elseif self.state == STATES.COMBAT then
        -- Draw combat UI
        if self.combat then
            self.combat:draw()
        end
    elseif self.state == STATES.LOOT then
        -- Draw loot UI
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", GAME.width / 2 - 150, GAME.height / 2 - 100, 300, 200)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(screenManager.fonts.large)
        love.graphics.printf("Loot", GAME.width / 2 - 150, GAME.height / 2 - 90, 300, "center")
        
        if self.currentLoot and self.currentLoot.contents then
            love.graphics.setFont(screenManager.fonts.medium)
            for i, item in ipairs(self.currentLoot.contents) do
                local y = GAME.height / 2 - 40 + (i - 1) * 25
                
                if item.type == "gold" then
                    love.graphics.print(item.amount .. " gold", GAME.width / 2 - 130, y)
                else
                    love.graphics.print(item.name, GAME.width / 2 - 130, y)
                end
            end
        end
    end
end

function dungeon:keypressed(key, scancode, isrepeat)
    -- Handle key presses
    if key == "m" then
        -- Toggle minimap
        self.elements.minimap.visible = not self.elements.minimap.visible
    end
    
    -- Pass key press to combat system if in combat
    if self.state == STATES.COMBAT and self.combat then
        self.combat:keypressed(key)
    end
end

function dungeon:mousepressed(x, y, button, istouch, presses)
    -- Handle mouse presses for UI elements
    for _, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false then
            if element:clicked(x, y, button) then
                break
            end
        end
    end
    
    -- Pass mouse press to combat system if in combat
    if self.state == STATES.COMBAT and self.combat then
        self.combat:mousepressed(x, y, button)
    end
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

return dungeon
