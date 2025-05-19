local screenManager -- Forward declaration
local statusBarPanel = {}

statusBarPanel.defaultConfig = {
    x = 10,
    y = 10,
    widthOffset = -240, -- Offset from game width
    height = 60,
    visible = true
}

function statusBarPanel:new(config)
    local instance = {}
    setmetatable(instance, self)
    self.__index = self

    if not screenManager then screenManager = require("screens/screenManager") end

    instance.x = config and config.x or statusBarPanel.defaultConfig.x
    instance.y = config and config.y or statusBarPanel.defaultConfig.y
    instance.widthOffset = config and config.widthOffset or statusBarPanel.defaultConfig.widthOffset -- Store for resize
    instance.width = (config and config.width) or (GAME.width + instance.widthOffset)
    instance.height = config and config.height or statusBarPanel.defaultConfig.height
    instance.visible = config and config.visible ~= nil and config.visible or statusBarPanel.defaultConfig.visible
    
    return instance
end

function statusBarPanel:draw(dungeonScreen) -- Pass dungeon screen for quest info
    if not self.visible then return end
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
    
    if dungeonScreen.currentQuest then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(screenManager.fonts.small)
        love.graphics.print("Current Quest: " .. dungeonScreen.currentQuest.name, self.x + 10, self.y + 10)
        
        local objectiveText = ""
        local objectiveColor = {1, 0.8, 0}
        local quest = dungeonScreen.currentQuest
        local objectiveData = dungeonScreen.objective -- Assuming this is dungeonScreen.objective for EXPLORE type
        
        if quest.type == "EXPLORE" then
            if objectiveData and objectiveData.reached then -- Added nil check for objectiveData
                objectiveText = "Return to entrance"
                objectiveColor = {0, 1, 0}
            else
                objectiveText = "Find the target location"
            end
        elseif quest.type == "KILL" then
            local current = quest.objective.current or 0
            local count = quest.objective.count or 0
            objectiveText = "Defeat " .. current .. "/" .. count .. " " .. quest.objective.targetName
            if current >= count then objectiveColor = {0, 1, 0} end
        elseif quest.type == "COLLECT" then
            local current = quest.objective.current or 0
            local count = quest.objective.count or 0
            objectiveText = "Collect " .. current .. "/" .. count .. " " .. quest.objective.itemName
            if current >= count then objectiveColor = {0, 1, 0} end
        end
        
        love.graphics.setColor(objectiveColor)
        love.graphics.print("Objective: " .. objectiveText, self.x + 10, self.y + 30)
    end
end

function statusBarPanel:setVisible(isVisible)
    self.visible = isVisible
end

function statusBarPanel:isVisible()
    return self.visible
end

function statusBarPanel:updatePosition(screenWidth, screenHeight)
    self.width = screenWidth + self.widthOffset
end

return statusBarPanel 