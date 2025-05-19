local screenManager -- Forward declaration
local confirmDialogPanel = {}

confirmDialogPanel.defaultConfig = {
    x = 20,
    yOffset = -280, -- Offset from bottom of screen
    width = 350,
    height = 150
}

function confirmDialogPanel:new(config)
    local instance = {}
    setmetatable(instance, self)
    self.__index = self

    if not screenManager then screenManager = require("screens/screenManager") end

    instance.x = config and config.x or confirmDialogPanel.defaultConfig.x
    -- Store yOffset for resize, calculate initial y
    instance.yOffset = config and config.yOffset or confirmDialogPanel.defaultConfig.yOffset
    instance.y = (config and config.y) or (GAME.height + instance.yOffset)
    
    instance.width = config and config.width or confirmDialogPanel.defaultConfig.width
    instance.height = config and config.height or confirmDialogPanel.defaultConfig.height
    
    instance.visible = false
    instance.message = ""
    instance.confirmCallback = nil
    instance.cancelCallback = nil
    
    instance.yesButton = screenManager.UI.Button(
        instance.x + instance.width - 110, instance.y + instance.height - 55,
        100, 40, "Yes", 
        function() 
            instance.visible = false 
            if instance.confirmCallback then instance.confirmCallback() end 
        end
    )
    instance.noButton = screenManager.UI.Button(
        instance.x + 10, instance.y + instance.height - 55, 
        100, 40, "No", 
        function() 
            instance.visible = false 
            if instance.cancelCallback then instance.cancelCallback() end 
        end
    )
    return instance
end

function confirmDialogPanel:show(message, onConfirm, onCancel)
    self.message = message
    self.confirmCallback = onConfirm
    self.cancelCallback = onCancel
    self.visible = true
end

function confirmDialogPanel:draw()
    if not self.visible then return end
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    love.graphics.setColor(0.5, 0.5, 0.8, 0.7)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
    
    love.graphics.setFont(screenManager.fonts.medium)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(self.message, self.x + 10, self.y + 20, self.width - 20, "center")
    
    self.yesButton:draw()
    self.noButton:draw()
end

function confirmDialogPanel:clicked(x, y, button)
    if not self.visible then return false end
    if self.yesButton:clicked(x, y, button) then return true end
    if self.noButton:clicked(x, y, button) then return true end
    if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
       return true
    end
    return false
end

function confirmDialogPanel:updatePosition(screenWidth, screenHeight)
    self.y = screenHeight + self.yOffset 
    
    self.yesButton.x = self.x + self.width - 110
    self.yesButton.y = self.y + self.height - 55
    self.noButton.x = self.x + 10
    self.noButton.y = self.y + self.height - 55
end

return confirmDialogPanel 