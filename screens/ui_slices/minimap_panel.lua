local minimapPanel = {}

minimapPanel.defaultConfig = {
    x = GAME.width - 220,
    y = 10,
    width = 200,
    height = 200,
    visible = true
}

function minimapPanel:new(config)
    local instance = {}
    setmetatable(instance, self)
    self.__index = self

    instance.x = config and config.x or minimapPanel.defaultConfig.x
    instance.y = config and config.y or minimapPanel.defaultConfig.y
    instance.width = config and config.width or minimapPanel.defaultConfig.width
    instance.height = config and config.height or minimapPanel.defaultConfig.height
    instance.visible = config and config.visible ~= nil and config.visible or minimapPanel.defaultConfig.visible
    
    return instance
end

function minimapPanel:draw(dungeonScreen) -- Pass the dungeon screen instance
    if not self.visible or not dungeonScreen.map then return end
            
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    local map = dungeonScreen.map
    local playerPos = dungeonScreen.playerPos
    local objective = dungeonScreen.objective
    local entities = dungeonScreen.entities

    local cellSize = math.min(self.width / map.width, self.height / map.height)
    
    for y_coord = 0, map.height - 1 do
        for x_coord = 0, map.width - 1 do
            if map:isCellVisible(x_coord, y_coord) then
                local cellType = map:getCell(x_coord, y_coord)
                
                if cellType > 0 then
                    love.graphics.setColor(0.7, 0.7, 0.7)
                else
                    love.graphics.setColor(0.3, 0.3, 0.3)
                end
                love.graphics.rectangle("fill", self.x + x_coord * cellSize, self.y + y_coord * cellSize, cellSize, cellSize)
                
                for _, entity in ipairs(entities) do
                    local entityX = math.floor(entity.x)
                    local entityY = math.floor(entity.y)
                    if x_coord == entityX and y_coord == entityY and entity.type ~= "objective" and 
                       (not entity.hidden or (entity.hidden and GAME.debug)) then
                        if entity.hidden and GAME.debug then
                            love.graphics.setColor(1, 0, 1)
                        else
                            love.graphics.setColor(entity.color or {1, 0, 0})
                        end
                        love.graphics.circle("fill", self.x + entity.x * cellSize, self.y + entity.y * cellSize, cellSize/2)
                    end
                end
            end
        end
    end
    
    if GAME.debug and map.activeTraps then
        for _, trap in ipairs(map.activeTraps) do
            if trap.isTrapActive then love.graphics.setColor(0, 1, 1) else love.graphics.setColor(0.5, 0.5, 0.5) end
            love.graphics.rectangle("fill", self.x + trap.x * cellSize + cellSize/4, self.y + trap.y * cellSize + cellSize/4, cellSize/2, cellSize/2)
            if trap.isTrapDisarmed then
                love.graphics.setColor(0.8, 0, 0)
                love.graphics.line(self.x + trap.x * cellSize + cellSize/4, self.y + trap.y * cellSize + cellSize/4, self.x + trap.x * cellSize + cellSize*3/4, self.y + trap.y * cellSize + cellSize*3/4)
                love.graphics.line(self.x + trap.x * cellSize + cellSize*3/4, self.y + trap.y * cellSize + cellSize/4, self.x + trap.x * cellSize + cellSize/4, self.y + trap.y * cellSize + cellSize*3/4)
            end
            if not trap.isTrapActive and not trap.isTrapDisarmed then
                love.graphics.setColor(1, 0.6, 0)
                love.graphics.line(self.x + trap.x * cellSize + cellSize/4, self.y + trap.y * cellSize + cellSize/3, self.x + trap.x * cellSize + cellSize*3/4, self.y + trap.y * cellSize + cellSize/3)
                love.graphics.line(self.x + trap.x * cellSize + cellSize/2, self.y + trap.y * cellSize + cellSize/3, self.x + trap.x * cellSize + cellSize/2, self.y + trap.y * cellSize + cellSize*3/4)
            end
        end
    end
    
    if GAME.debug and map.secretPassages then
        for _, passage in ipairs(map.secretPassages) do
            if passage.secretPassageRevealed then love.graphics.setColor(0, 0.8, 0.2) else love.graphics.setColor(1, 0, 1) end
            local centerX = self.x + passage.x * cellSize + cellSize/2
            local centerY = self.y + passage.y * cellSize + cellSize/2
            local size = cellSize/2
            love.graphics.polygon("fill", centerX, centerY - size/2, centerX + size/2, centerY, centerX, centerY + size/2, centerX - size/2, centerY)
        end
    end
    
    if GAME.debug and map.interactableWalls then
        for _, wall in ipairs(map.interactableWalls) do
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.rectangle("fill", self.x + wall.x * cellSize + cellSize/3, self.y + wall.y * cellSize + cellSize/3, cellSize/3, cellSize/3)
        end
    end
    
    local objX = math.floor(objective.x)
    local objY = math.floor(objective.y)
    if objective and not objective.reached and map:isCellVisible(objX, objY) then -- Added nil check for objective
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", self.x + objective.x * cellSize + cellSize/2, self.y + objective.y * cellSize + cellSize/2, cellSize/2)
    end
    
    if playerPos then -- Added nil check for playerPos
        love.graphics.setColor(0, 0, 1)
        love.graphics.circle("fill", self.x + playerPos.x * cellSize, self.y + playerPos.y * cellSize, cellSize/2)
    
        local dirX = math.cos(playerPos.angle) * cellSize
        local dirY = math.sin(playerPos.angle) * cellSize
        love.graphics.setColor(1, 1, 0)
        love.graphics.line(self.x + playerPos.x * cellSize, self.y + playerPos.y * cellSize, self.x + playerPos.x * cellSize + dirX, self.y + playerPos.y * cellSize + dirY)
    end
end

function minimapPanel:toggleVisibility()
    self.visible = not self.visible
end

function minimapPanel:updatePosition(screenWidth, screenHeight)
    self.x = screenWidth - (self.width + 20) -- Use configured width + offset
end

return minimapPanel 