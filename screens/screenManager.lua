-- Screen Manager
local screenManager = {
    fonts = {},
    colors = {},
    UI = {}
}

function screenManager:init()
    -- Load fonts
    self.fonts = {
        small = love.graphics.newFont(12),
        medium = love.graphics.newFont(18),
        large = love.graphics.newFont(24),
        title = love.graphics.newFont(36)
    }
    
    -- Define colors
    self.colors = {
        background = {0.1, 0.1, 0.2, 1.0},
        title = {1.0, 0.8, 0.2, 1.0},
        text = {0.9, 0.9, 0.9, 1.0},
        button = {0.3, 0.3, 0.5, 1.0},
        buttonHover = {0.4, 0.4, 0.6, 1.0},
        buttonText = {1.0, 1.0, 1.0, 1.0},
        primary = {0.2, 0.4, 0.8, 1.0},
        secondary = {0.8, 0.4, 0.2, 1.0},
        highlight = {1.0, 1.0, 0.0, 1.0},
        floor = {0.6, 0.6, 0.6, 1.0},
        wall = {0.4, 0.4, 0.4, 1.0},
        ceiling = {0.3, 0.3, 0.3, 1.0},
        health = {0.8, 0.2, 0.2, 1.0},
        mana = {0.2, 0.2, 0.8, 1.0},
        success = {0.2, 0.8, 0.2, 1.0},
        warning = {0.8, 0.8, 0.0, 1.0},
        danger = {0.8, 0.2, 0.2, 1.0}
    }
    
    -- Initialize UI elements
    self:initUI()
end

function screenManager:initUI()
    -- Button UI element
    self.UI.Button = function(x, y, width, height, text, callback)
        local button = {
            x = x,
            y = y,
            width = width,
            height = height,
            text = text,
            callback = callback,
            hover = false,
            isPressed = false,
            visible = true, -- Set visible by default
            
            update = function(self, dt)
                local mx, my = love.mouse.getPosition()
                self.hover = mx >= self.x and mx <= self.x + self.width and
                              my >= self.y and my <= self.y + self.height
            end,
            
            draw = function(self)
                -- Only draw if visible
                if self.visible == false then return end
                
                -- Draw button background
                if self.isPressed then
                    love.graphics.setColor(0.2, 0.2, 0.4) -- Darker when pressed
                elseif self.hover then
                    love.graphics.setColor(0.4, 0.4, 0.6) -- Lighter when hovering
                else
                    love.graphics.setColor(0.3, 0.3, 0.5) -- Normal
                end
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
                
                -- Draw button outline
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
                
                -- Draw button text
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(screenManager.fonts.medium)
                local textWidth = love.graphics.getFont():getWidth(self.text)
                local textHeight = love.graphics.getFont():getHeight()
                love.graphics.print(self.text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)
            end,
            
            clicked = function(self, x, y, button)
                -- Only clickable if visible
                if self.visible == false then return false end
                
                if button == 1 and x >= self.x and x <= self.x + self.width and
                   y >= self.y and y <= self.y + self.height then
                    self.isPressed = true
                    return true
                end
                return false
            end,
            
            released = function(self, x, y)
                -- Only process release if visible
                if self.visible == false then return false end
                
                if self.isPressed then
                    self.isPressed = false
                    -- Only trigger callback if released over button
                    if x >= self.x and x <= self.x + self.width and
                       y >= self.y and y <= self.y + self.height then
                        if self.callback then self.callback() end
                    end
                    return true
                end
                return false
            end
        }
        
        return button
    end
    
    -- Label UI element
    self.UI.Label = function(x, y, text, font, color)
        local label = {
            x = x,
            y = y,
            text = text,
            font = font or screenManager.fonts.medium,
            color = color or screenManager.colors.text,
            
            draw = function(self)
                love.graphics.setFont(self.font)
                love.graphics.setColor(self.color)
                love.graphics.print(self.text, self.x, self.y)
            end
        }
        
        return label
    end
    
    -- Input field UI element
    self.UI.InputField = function(x, y, width, height, placeholder, maxLength)
        local inputField = {
            x = x,
            y = y,
            width = width,
            height = height,
            placeholder = placeholder or "",
            text = "",
            maxLength = maxLength or 20,
            active = false,
            cursor = 0,
            cursorBlinkTimer = 0,
            showCursor = true,
            visible = true, -- Set visible by default
            
            update = function(self, dt)
                if self.active then
                    self.cursorBlinkTimer = self.cursorBlinkTimer + dt
                    if self.cursorBlinkTimer > 0.5 then
                        self.showCursor = not self.showCursor
                        self.cursorBlinkTimer = 0
                    end
                end
            end,
            
            draw = function(self)
                -- Only draw if visible
                if self.visible == false then return end
                
                -- Draw input background
                love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
                
                -- Draw input outline
                love.graphics.setColor(self.active and screenManager.colors.highlight or {1, 1, 1, 0.5})
                love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
                
                -- Draw input text or placeholder
                love.graphics.setFont(screenManager.fonts.medium)
                if self.text ~= "" then
                    love.graphics.setColor(screenManager.colors.text)
                    love.graphics.print(self.text, self.x + 10, self.y + (self.height - love.graphics.getFont():getHeight()) / 2)
                    
                    -- Draw cursor
                    if self.active and self.showCursor then
                        local textWidth = love.graphics.getFont():getWidth(self.text:sub(1, self.cursor))
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.rectangle("fill", self.x + 10 + textWidth, self.y + 5, 2, self.height - 10)
                    end
                else
                    love.graphics.setColor(0.6, 0.6, 0.6, 1.0)
                    love.graphics.print(self.placeholder, self.x + 10, self.y + (self.height - love.graphics.getFont():getHeight()) / 2)
                end
            end,
            
            clicked = function(self, x, y)
                -- Only clickable if visible
                if self.visible == false then return false end
                
                self.active = x >= self.x and x <= self.x + self.width and
                              y >= self.y and y <= self.y + self.height
                
                if self.active then
                    -- Calculate cursor position based on click
                    local font = screenManager.fonts.medium
                    love.graphics.setFont(font)
                    
                    local clickX = x - self.x - 10
                    local closestDist = math.huge
                    local closestPos = 0
                    
                    for i = 0, #self.text do
                        local textWidth = font:getWidth(self.text:sub(1, i))
                        local dist = math.abs(clickX - textWidth)
                        
                        if dist < closestDist then
                            closestDist = dist
                            closestPos = i
                        end
                    end
                    
                    self.cursor = closestPos
                end
                
                return self.active
            end,
            
            textInput = function(self, text)
                if self.active then
                    if #self.text < self.maxLength then
                        self.text = self.text:sub(1, self.cursor) .. text .. self.text:sub(self.cursor + 1)
                        self.cursor = self.cursor + #text
                    end
                end
            end,
            
            keyPressed = function(self, key)
                if self.active then
                    if key == "backspace" then
                        if self.cursor > 0 then
                            self.text = self.text:sub(1, self.cursor - 1) .. self.text:sub(self.cursor + 1)
                            self.cursor = self.cursor - 1
                        end
                    elseif key == "delete" then
                        if self.cursor < #self.text then
                            self.text = self.text:sub(1, self.cursor) .. self.text:sub(self.cursor + 2)
                        end
                    elseif key == "left" then
                        self.cursor = math.max(0, self.cursor - 1)
                    elseif key == "right" then
                        self.cursor = math.min(#self.text, self.cursor + 1)
                    elseif key == "home" then
                        self.cursor = 0
                    elseif key == "end" then
                        self.cursor = #self.text
                    end
                end
            end,
            
            getValue = function(self)
                return self.text
            end,
            
            setValue = function(self, text)
                self.text = text
                self.cursor = #text
            end
        }
        
        return inputField
    end
    
    -- Slider UI element
    self.UI.Slider = function(x, y, width, min, max, value, callback)
        local slider = {
            x = x,
            y = y,
            width = width,
            height = 20,
            min = min or 0,
            max = max or 100,
            value = value or 50,
            callback = callback,
            dragging = false,
            visible = true, -- Set visible by default
            
            update = function(self, dt)
                if self.dragging then
                    local mx = love.mouse.getX()
                    local percentage = math.max(0, math.min(1, (mx - self.x) / self.width))
                    self.value = self.min + percentage * (self.max - self.min)
                    
                    if self.callback then
                        self.callback(self.value)
                    end
                end
            end,
            
            draw = function(self)
                -- Only draw if visible
                if self.visible == false then return end
                
                -- Draw slider background
                love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
                love.graphics.rectangle("fill", self.x, self.y + (self.height - 8) / 2, self.width, 8, 4, 4)
                
                -- Draw slider position
                local handleX = self.x + (self.value - self.min) / (self.max - self.min) * self.width
                
                love.graphics.setColor(0.4, 0.4, 0.8, 1.0)
                love.graphics.rectangle("fill", self.x, self.y + (self.height - 8) / 2, handleX - self.x, 8, 4, 4)
                
                -- Draw slider handle
                love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
                love.graphics.circle("fill", handleX, self.y + self.height / 2, 10)
                
                -- Draw value
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(screenManager.colors.text)
                local valueText = math.floor(self.value)
                local textWidth = love.graphics.getFont():getWidth(valueText)
                love.graphics.print(valueText, handleX - textWidth / 2, self.y + self.height + 5)
            end,
            
            pressed = function(self, x, y)
                -- Only clickable if visible
                if self.visible == false then return false end
                
                if y >= self.y and y <= self.y + self.height then
                    local handleX = self.x + (self.value - self.min) / (self.max - self.min) * self.width
                    
                    if math.abs(x - handleX) <= 10 then
                        self.dragging = true
                        return true
                    end
                    
                    if x >= self.x and x <= self.x + self.width then
                        local percentage = (x - self.x) / self.width
                        self.value = self.min + percentage * (self.max - self.min)
                        
                        if self.callback then
                            self.callback(self.value)
                        end
                        
                        self.dragging = true
                        return true
                    end
                end
                
                return false
            end,
            
            released = function(self, x, y)
                -- Only process release if visible
                if self.visible == false then return false end
                
                self.dragging = false
                return false
            end,
            
            getValue = function(self)
                return self.value
            end,
            
            setValue = function(self, value)
                self.value = math.max(self.min, math.min(self.max, value))
                
                if self.callback then
                    self.callback(self.value)
                end
            end
        }
        
        return slider
    end
end

-- Draw panel with title
function screenManager:drawPanel(title, x, y, width, height)
    -- Draw panel background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", x, y, width, height, 10, 10)
    
    -- Draw panel border
    love.graphics.setColor(0.4, 0.4, 0.6, 1.0)
    love.graphics.rectangle("line", x, y, width, height, 10, 10)
    
    -- Draw panel title if provided
    if title then
        -- Title background
        love.graphics.setColor(0.3, 0.3, 0.5, 1.0)
        love.graphics.rectangle("fill", x, y, width, 40, 10, 10)
        love.graphics.rectangle("fill", x, y + 30, width, 10)
        
        -- Title text
        love.graphics.setFont(self.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        local titleWidth = self.fonts.large:getWidth(title)
        love.graphics.print(title, x + (width - titleWidth) / 2, y + 5)
    end
end

-- Create a default screen template
function screenManager:createScreen(name)
    local screen = {
        name = name,
        elements = {},
        
        init = function(self)
            -- Initialize screen-specific elements
        end,
        
        enter = function(self, params)
            -- Called when entering this screen
        end,
        
        exit = function(self)
            -- Called when exiting this screen
        end,
        
        update = function(self, dt)
            -- Update UI elements
            for _, element in pairs(self.elements) do
                if element.update then
                    element:update(dt)
                end
            end
        end,
        
        draw = function(self)
            -- Clear screen
            love.graphics.clear(screenManager.colors.background)
            
            -- Draw screen title
            love.graphics.setFont(screenManager.fonts.title)
            love.graphics.setColor(screenManager.colors.title)
            local titleText = self.name
            local titleWidth = screenManager.fonts.title:getWidth(titleText)
            love.graphics.print(titleText, (GAME.width - titleWidth) / 2, 20)
            
            -- Draw UI elements
            for _, element in pairs(self.elements) do
                if element.draw then
                    element:draw()
                end
            end
        end,
        
        keypressed = function(self, key, scancode, isrepeat)
            -- Handle key presses for UI elements
            for _, element in pairs(self.elements) do
                if element.keyPressed then
                    element:keyPressed(key)
                end
            end
        end,
        
        textinput = function(self, text)
            -- Handle text input for UI elements
            for _, element in pairs(self.elements) do
                if element.textInput then
                    element:textInput(text)
                end
            end
        end,
        
        mousepressed = function(self, x, y, button, istouch, presses)
            -- Handle mouse presses for UI elements
            local clickHandled = false
            
            for _, element in pairs(self.elements) do
                if element.visible ~= false then  -- Skip invisible elements
                    if element.clicked then
                        if element:clicked(x, y, button) then
                            clickHandled = true
                            -- Don't break to allow hover effects to work properly
                        end
                    elseif element.pressed then
                        if element:pressed(x, y) then
                            clickHandled = true
                            -- Don't break to allow hover effects to work properly
                        end
                    end
                end
            end
            
            return clickHandled
        end,
        
        mousereleased = function(self, x, y, button, istouch, presses)
            -- Handle mouse releases for UI elements
            for _, element in pairs(self.elements) do
                if element.released then
                    element:released(x, y, button)
                end
            end
        end,
        
        addElement = function(self, id, element)
            self.elements[id] = element
            return element
        end,
        
        getElement = function(self, id)
            return self.elements[id]
        end
    }
    
    return screen
end

return screenManager
