-- Debug Console
-- Implements a developer console for in-game debugging and commands

local screenManager = require("screens/screenManager")
local layoutHelper = require("utils/layoutHelper")

local debugConsole = {
    visible = false,
    history = {},
    commandBuffer = {},
    bufferPosition = 0,
    lastCommandIndex = 0,
    maxHistoryEntries = 100,
    inputText = "",
    cursorPosition = 0,
    cursorBlinkTimer = 0,
    showCursor = true,
    scrollOffset = 0,
    
    -- Command registry
    commands = {},
    
    -- UI elements
    elements = {},
    
    -- Console dimensions and styling
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    padding = 10,
    prompt = "> ",
    backgroundColor = {0.1, 0.1, 0.2, 0.9},
    borderColor = {0.6, 0.6, 0.8, 0.8},
    textColor = {1, 1, 1, 1},
    resultColor = {0.7, 0.7, 1, 1},
    errorColor = {1, 0.4, 0.4, 1},
    historyColor = {0.8, 0.8, 0.8, 0.8},
    promptColor = {0.6, 0.8, 0.3, 1}
}

-- Initialize the console
function debugConsole:init()
    -- Set console dimensions
    self:updateDimensions()
    
    -- Register built-in commands
    self:registerBuiltInCommands()
    
    -- Initialize input field
    self.inputField = {
        x = self.x + self.padding + self.prompt:len() * 10, -- Adjust position based on prompt
        y = self.y + self.height - 35,
        width = self.width - self.padding * 2 - self.prompt:len() * 10,
        height = 25,
        text = "",
        active = true,
        
        update = function(self, dt)
            -- No special behavior needed for update
        end,
        
        draw = function(self)
            -- The input field drawing is handled by the console's draw method
        end,
        
        textInput = function(self, text)
            debugConsole.inputText = debugConsole.inputText:sub(1, debugConsole.cursorPosition) .. 
                                    text .. 
                                    debugConsole.inputText:sub(debugConsole.cursorPosition + 1)
            debugConsole.cursorPosition = debugConsole.cursorPosition + text:len()
        end,
        
        keyPressed = function(self, key)
            if key == "backspace" then
                if debugConsole.cursorPosition > 0 then
                    debugConsole.inputText = debugConsole.inputText:sub(1, debugConsole.cursorPosition - 1) .. 
                                           debugConsole.inputText:sub(debugConsole.cursorPosition + 1)
                    debugConsole.cursorPosition = debugConsole.cursorPosition - 1
                end
            elseif key == "delete" then
                debugConsole.inputText = debugConsole.inputText:sub(1, debugConsole.cursorPosition) .. 
                                       debugConsole.inputText:sub(debugConsole.cursorPosition + 2)
            elseif key == "left" then
                debugConsole.cursorPosition = math.max(0, debugConsole.cursorPosition - 1)
            elseif key == "right" then
                debugConsole.cursorPosition = math.min(debugConsole.inputText:len(), debugConsole.cursorPosition + 1)
            elseif key == "home" then
                debugConsole.cursorPosition = 0
            elseif key == "end" then
                debugConsole.cursorPosition = debugConsole.inputText:len()
            elseif key == "up" then
                debugConsole:navigateHistory(1)
            elseif key == "down" then
                debugConsole:navigateHistory(-1)
            elseif key == "return" or key == "kpenter" then
                debugConsole:executeCommand(debugConsole.inputText)
            elseif key == "escape" then
                debugConsole:toggle()
            elseif key == "tab" then
                debugConsole:autoComplete()
            elseif key == "pageup" then
                debugConsole:scroll(10)
            elseif key == "pagedown" then
                debugConsole:scroll(-10)
            end
        end
    }
    
    -- Add command for easier access to help
    self:addCommand("help", function(args)
        if #args == 0 then
            local cmdList = {}
            for cmd, _ in pairs(self.commands) do
                table.insert(cmdList, cmd)
            end
            table.sort(cmdList)
            return "Available commands: " .. table.concat(cmdList, ", ")
        else
            local cmd = args[1]
            if self.commands[cmd] and self.commands[cmd].help then
                return cmd .. ": " .. self.commands[cmd].help
            else
                return "No help available for command: " .. cmd
            end
        end
    end, "Display help for commands. Usage: help [command]")
    
    -- Add welcome message with tip about quotes
    self:addToHistory("Debug Console v1.0 - Type 'help' for available commands", "result")
    self:addToHistory("TIP: Use quotes for arguments with spaces: player additem \"healing potion\" 5", "result")
    
    return self
end

-- Update console dimensions based on window size
function debugConsole:updateDimensions()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.width = windowWidth - 40
    self.height = windowHeight * 0.4
    self.x = 20
    self.y = 20
    
    -- Update input field position if it exists
    if self.inputField then
        self.inputField.x = self.x + self.padding + self.prompt:len() * 10
        self.inputField.y = self.y + self.height - 35
        self.inputField.width = self.width - self.padding * 2 - self.prompt:len() * 10
    end
end

-- Update the console
function debugConsole:update(dt)
    if not self.visible then return end
    
    -- Update cursor blink
    self.cursorBlinkTimer = self.cursorBlinkTimer + dt
    if self.cursorBlinkTimer > 0.5 then
        self.showCursor = not self.showCursor
        self.cursorBlinkTimer = 0
    end
end

-- Draw the console
function debugConsole:draw()
    if not self.visible then return end
    
    -- Draw console background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    
    -- Draw console border
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
    
    -- Draw console history
    love.graphics.setFont(screenManager.fonts.small)
    local lineHeight = screenManager.fonts.small:getHeight() + 2
    local visibleLines = math.floor((self.height - 40) / lineHeight)
    local startIndex = math.max(1, #self.history - visibleLines + 1 - self.scrollOffset)
    
    for i = startIndex, math.min(#self.history, startIndex + visibleLines - 1) do
        local entry = self.history[i]
        local yPos = self.y + self.padding + (i - startIndex) * lineHeight
        
        -- Set color based on entry type
        if entry.type == "input" then
            love.graphics.setColor(self.promptColor)
            love.graphics.print(self.prompt, self.x + self.padding, yPos)
            love.graphics.setColor(self.textColor)
            love.graphics.print(entry.text, self.x + self.padding + self.prompt:len() * 10, yPos)
        elseif entry.type == "error" then
            love.graphics.setColor(self.errorColor)
            love.graphics.print(entry.text, self.x + self.padding, yPos)
        else
            love.graphics.setColor(self.resultColor)
            love.graphics.print(entry.text, self.x + self.padding, yPos)
        end
    end
    
    -- Draw input line
    love.graphics.setColor(self.promptColor)
    love.graphics.print(self.prompt, self.x + self.padding, self.y + self.height - 35)
    
    -- Draw input text
    love.graphics.setColor(self.textColor)
    love.graphics.print(self.inputText, self.x + self.padding + self.prompt:len() * 10, self.y + self.height - 35)
    
    -- Draw cursor
    if self.showCursor then
        local cursorX = self.x + self.padding + self.prompt:len() * 10 + 
                      screenManager.fonts.small:getWidth(self.inputText:sub(1, self.cursorPosition))
        love.graphics.rectangle("fill", cursorX, self.y + self.height - 35, 2, lineHeight)
    end
end

-- Toggle console visibility
function debugConsole:toggle()
    self.visible = not self.visible
    if self.visible then
        -- Reset cursor position when opening console
        self.cursorPosition = #self.inputText
    end
    return self.visible
end

-- Add a command to the registry
function debugConsole:addCommand(name, func, helpText)
    self.commands[name] = {
        func = func,
        help = helpText or "No help available"
    }
end

-- Execute a command
function debugConsole:executeCommand(commandText)
    -- Add command to history
    self:addToHistory(commandText, "input")
    
    -- Add to command buffer
    table.insert(self.commandBuffer, commandText)
    if #self.commandBuffer > self.maxHistoryEntries then
        table.remove(self.commandBuffer, 1)
    end
    self.lastCommandIndex = #self.commandBuffer + 1
    
    -- Clear input text
    local oldText = self.inputText
    self.inputText = ""
    self.cursorPosition = 0
    
    -- Empty command
    if commandText:gsub("%s+", "") == "" then
        return
    end
    
    -- Parse command and arguments, handling quoted strings
    local parts = {}
    local currentPart = ""
    local inQuote = false
    local quoteChar = nil
    local escaped = false
    
    -- Helper function to add a completed part
    local function addPart()
        if currentPart ~= "" then
            table.insert(parts, currentPart)
            currentPart = ""
        end
    end
    
    -- Parse character by character to handle quotes
    for i = 1, #commandText do
        local char = commandText:sub(i, i)
        
        if escaped then
            -- Handle escaped character
            currentPart = currentPart .. char
            escaped = false
        elseif char == "\\" then
            -- Start escape sequence
            escaped = true
        elseif (char == "\"" or char == "'") and not inQuote then
            -- Start quoted string
            inQuote = true
            quoteChar = char
        elseif char == quoteChar and inQuote then
            -- End quoted string
            inQuote = false
            quoteChar = nil
        elseif char:match("%s") and not inQuote then
            -- Space outside quotes - end current part
            addPart()
        else
            -- Regular character or space inside quotes
            currentPart = currentPart .. char
        end
    end
    
    -- Add final part if there is one
    addPart()
    
    -- Check if we have an unclosed quote
    if inQuote then
        self:addToHistory("Error: Unclosed quote in command", "error")
        return
    end
    
    -- No command parts found
    if #parts == 0 then
        return
    end
    
    local commandName = parts[1]
    table.remove(parts, 1)
    
    -- Execute command if it exists
    if self.commands[commandName] then
        local success, result = pcall(function() 
            return self.commands[commandName].func(parts)
        end)
        
        if success then
            if result then
                self:addToHistory(tostring(result), "result")
            end
        else
            self:addToHistory("Error: " .. tostring(result), "error")
        end
    else
        -- Try to evaluate as Lua expression
        self:evaluateLuaExpression(commandText)
    end
    
    -- Reset scroll
    self.scrollOffset = 0
end

-- Evaluate a Lua expression
function debugConsole:evaluateLuaExpression(expr)
    -- First try as a statement
    local func, err = load("return " .. expr)
    
    -- If it fails, try as a regular statement
    if not func then
        func, err = load(expr)
    end
    
    -- If we have a valid function, execute it
    if func then
        local success, result = pcall(func)
        if success then
            if result ~= nil then
                self:addToHistory(tostring(result), "result")
            end
        else
            self:addToHistory("Error: " .. tostring(result), "error")
        end
    else
        self:addToHistory("Error: " .. tostring(err), "error")
    end
end

-- Add entry to console history
function debugConsole:addToHistory(text, entryType)
    table.insert(self.history, {
        text = text,
        type = entryType or "result"
    })
    
    -- Limit history size
    if #self.history > self.maxHistoryEntries then
        table.remove(self.history, 1)
    end
end

-- Navigate command history
function debugConsole:navigateHistory(direction)
    local newIndex = self.lastCommandIndex + direction
    
    if newIndex >= 1 and newIndex <= #self.commandBuffer + 1 then
        self.lastCommandIndex = newIndex
        
        if newIndex <= #self.commandBuffer then
            self.inputText = self.commandBuffer[newIndex]
        else
            self.inputText = ""
        end
        
        self.cursorPosition = #self.inputText
    end
end

-- Scroll console history
function debugConsole:scroll(amount)
    self.scrollOffset = math.max(0, math.min(#self.history, self.scrollOffset + amount))
end

-- Auto-complete command
function debugConsole:autoComplete()
    local text = self.inputText
    local matches = {}
    
    -- If empty text, show all commands
    if text == "" then
        self:addToHistory("Available commands:", "result")
        local sorted = {}
        for cmd, _ in pairs(self.commands) do
            table.insert(sorted, cmd)
        end
        table.sort(sorted)
        for _, cmd in ipairs(sorted) do
            self:addToHistory("  " .. cmd, "result")
        end
        return
    end
    
    -- Find matching commands
    for cmd, _ in pairs(self.commands) do
        if cmd:sub(1, #text) == text then
            table.insert(matches, cmd)
        end
    end
    
    -- If only one match, auto-complete
    if #matches == 1 then
        self.inputText = matches[1] .. " "
        self.cursorPosition = #self.inputText
    -- If multiple matches, show them
    elseif #matches > 1 then
        self:addToHistory("Matching commands:", "result")
        for _, cmd in ipairs(matches) do
            self:addToHistory("  " .. cmd, "result")
        end
        
        -- Find common prefix
        local commonPrefix = matches[1]
        for i = 2, #matches do
            while not matches[i]:sub(1, #commonPrefix) == commonPrefix and #commonPrefix > 0 do
                commonPrefix = commonPrefix:sub(1, #commonPrefix - 1)
            end
            if #commonPrefix == 0 then break end
        end
        
        -- Set input to common prefix if longer than current
        if #commonPrefix > #text then
            self.inputText = commonPrefix
            self.cursorPosition = #self.inputText
        end
    end
end

-- Register built-in commands
function debugConsole:registerBuiltInCommands()
    -- Clear console
    self:addCommand("clear", function()
        self.history = {}
        return "Console cleared"
    end, "Clear the console history")

    -- Quit game
    self:addCommand("quit", function()
        love.event.quit()
    end, "Exit the game")

    -- Set debug mode
    self:addCommand("debug", function(args)
        if #args > 0 then
            local value = args[1]:lower()
            if value == "on" or value == "true" or value == "1" then
                GAME.debug = true
                return "Debug mode enabled"
            elseif value == "off" or value == "false" or value == "0" then
                GAME.debug = false
                return "Debug mode disabled"
            end
        end
        return "Current debug mode: " .. (GAME.debug and "on" or "off")
    end, "Toggle debug mode. Usage: debug [on|off]")

    -- Get/set game settings
    self:addCommand("set", function(args)
        if #args < 2 then
            return "Usage: set <setting> <value>"
        end
        
        local setting = args[1]
        local value = args[2]
        
        -- Handle known settings
        if setting == "musicVolume" then
            local volume = tonumber(value)
            if volume then
                GAME.settings.sound.musicVolume = volume
                GAME.setVolume(volume)
                return "Music volume set to " .. volume
            end
        elseif setting == "sfxVolume" then
            local volume = tonumber(value)
            if volume then
                GAME.settings.sound.sfxVolume = volume
                GAME.setVolume(nil, volume)
                return "SFX volume set to " .. volume
            end
        elseif setting == "masterVolume" then
            local volume = tonumber(value)
            if volume then
                GAME.settings.sound.masterVolume = volume
                GAME.setVolume(nil, nil, volume)
                return "Master volume set to " .. volume
            end
        elseif setting == "fullscreen" then
            local fs = value == "true" or value == "1" or value == "on"
            GAME.settings.graphics.fullscreen = fs
            love.window.setFullscreen(fs)
            return "Fullscreen set to " .. tostring(fs)
        end
        
        return "Unknown setting: " .. setting
    end, "Change game settings. Usage: set <setting> <value>")

    -- State management
    self:addCommand("state", function(args)
        local gameState = require("states/gameState")
        
        if #args == 0 then
            return "Current state: " .. gameState:getCurrentStateName()
        else
            local stateName = args[1]
            if gameState.states[stateName] then
                gameState:changeState(stateName)
                return "Changed state to " .. stateName
            else
                return "Unknown state: " .. stateName
            end
        end
    end, "Get current state or change state. Usage: state [statename]")
    
    -- List all game states
    self:addCommand("states", function()
        local gameState = require("states/gameState")
        local states = {}
        for name, _ in pairs(gameState.states) do
            table.insert(states, name)
        end
        table.sort(states)
        return "Available states: " .. table.concat(states, ", ")
    end, "List all available game states")
    
    -- Add item command (alias for player additem)
    self:addCommand("additem", function(args)
        if #args < 1 then
            return "Usage: additem \"<item name>\" [amount]"
        end
        
        local itemName = args[1]
        local amount = tonumber(args[2]) or 1
        
        -- Check if inventory exists
        if not GAME.inventory then
            GAME.inventory = {}
        end
        
        -- Get the item system
        local itemSystem = require("gameplay/item")
        if not itemSystem then
            return "Error: Item system not available"
        end
        
        -- Try to find the item by name in all item sources
        local foundItem = nil
        local itemType = nil
        
        -- 1. Look through unique items
        if itemSystem.uniqueItems then
            for id, item in pairs(itemSystem.uniqueItems) do
                if item.name == itemName then
                    foundItem = item
                    itemType = "unique"
                    break
                end
            end
        end
        
        -- 2. Look through set items if not found in uniques
        if not foundItem and itemSystem.setItems then
            for id, item in pairs(itemSystem.setItems) do
                if item.name == itemName then
                    foundItem = item
                    itemType = "set"
                    break
                end
            end
        end
        
        -- 3. Look through regular items if not found in uniques or sets
        if not foundItem and itemSystem.items then
            for id, item in pairs(itemSystem.items) do
                if item.name == itemName then
                    foundItem = item
                    itemType = "regular"
                    break
                end
            end
        end
        
        -- 4. Look through monster parts if not found elsewhere
        if not foundItem and itemSystem.monsterParts then
            for id, item in pairs(itemSystem.monsterParts) do
                if item.name == itemName then
                    foundItem = item
                    itemType = "monsterPart"
                    break
                end
            end
        end
        
        -- If we found an item, add it to inventory
        if foundItem then
            local clonedItem
            if itemSystem.cloneItemWithId then
                clonedItem = itemSystem:cloneItemWithId(foundItem)
            else
                -- Manual clone if function not available
                clonedItem = {}
                for k, v in pairs(foundItem) do
                    clonedItem[k] = v
                end
                clonedItem.uniqueId = os.time() .. "_" .. math.random(1000)
                
                -- Set count for stackable items
                if foundItem.type == "consumable" or foundItem.type == "material" or foundItem.type == "monster_part" then
                    clonedItem.count = amount
                end
            end
            
            if itemSystem.addToInventory then
                itemSystem:addToInventory(clonedItem)
            else
                table.insert(GAME.inventory, clonedItem)
            end
            
            local itemTypeText = ""
            if itemType == "unique" then
                itemTypeText = "unique "
            elseif itemType == "set" then
                itemTypeText = "set "
            end
            
            return "Added " .. itemTypeText .. "item: " .. itemName
        else
            -- No item found with that name in any of the item sources
            return "Error: Item '" .. itemName .. "' does not exist in any item definition table"
        end
    end, "Add items to player inventory. Usage: additem \"<item name>\" [amount]\n" ..
         "For items with spaces in names, use quotes: additem \"healing potion\" 5")
    
    -- Spawn item/entity command (for more flexibility)
    self:addCommand("spawn", function(args)
        if #args < 1 then
            return "Usage: spawn \"<entity/item name>\" [amount/level]"
        end
        
        local name = args[1]
        local param = tonumber(args[2]) or 1
        
        -- Ensure inventory exists
        if not GAME.inventory then
            GAME.inventory = {}
        end
        
        -- Determine if we're spawning an item or entity based on name or context
        if not (GAME.currentState and GAME.currentState.name == "dungeon") then
            -- We're spawning an item outside of dungeon
            local itemSystem = require("gameplay/item")
            if not itemSystem then
                return "Error: Item system not available"
            end
            
            -- Try to find the item by name in all item sources
            local foundItem = nil
            local itemType = nil
            
            -- 1. Look through unique items
            if itemSystem.uniqueItems then
                for id, item in pairs(itemSystem.uniqueItems) do
                    if item.name == name then
                        foundItem = item
                        itemType = "unique"
                        break
                    end
                end
            end
            
            -- 2. Look through set items if not found in uniques
            if not foundItem and itemSystem.setItems then
                for id, item in pairs(itemSystem.setItems) do
                    if item.name == name then
                        foundItem = item
                        itemType = "set"
                        break
                    end
                end
            end
            
            -- 3. Look through regular items if not found in uniques or sets
            if not foundItem and itemSystem.items then
                for id, item in pairs(itemSystem.items) do
                    if item.name == name then
                        foundItem = item
                        itemType = "regular"
                        break
                    end
                end
            end
            
            -- 4. Look through monster parts if not found elsewhere
            if not foundItem and itemSystem.monsterParts then
                for id, item in pairs(itemSystem.monsterParts) do
                    if item.name == name then
                        foundItem = item
                        itemType = "monsterPart"
                        break
                    end
                end
            end
            
            -- If we found an item, add it to inventory
            if foundItem then
                local clonedItem
                if itemSystem.cloneItemWithId then
                    clonedItem = itemSystem:cloneItemWithId(foundItem)
                else
                    -- Manual clone if function not available
                    clonedItem = {}
                    for k, v in pairs(foundItem) do
                        clonedItem[k] = v
                    end
                    clonedItem.uniqueId = os.time() .. "_" .. math.random(1000)
                    
                    -- Set count for stackable items
                    if foundItem.type == "consumable" or foundItem.type == "material" or foundItem.type == "monster_part" then
                        clonedItem.count = param
                    end
                end
                
                if itemSystem.addToInventory then
                    itemSystem:addToInventory(clonedItem)
                else
                    table.insert(GAME.inventory, clonedItem)
                end
                
                local itemTypeText = ""
                if itemType == "unique" then
                    itemTypeText = "unique "
                elseif itemType == "set" then
                    itemTypeText = "set "
                end
                
                return "Added " .. itemTypeText .. "item: " .. name
            else
                -- No item found with that name in any of the item sources
                return "Error: Item '" .. name .. "' does not exist in any item definition table"
            end
        elseif GAME.currentState and GAME.currentState.name == "dungeon" then
            -- In dungeon we're spawning an enemy or object
            if GAME.currentState.spawnEntity then
                local success = GAME.currentState:spawnEntity(name, param)
                if success then
                    return "Spawned " .. name .. " at level " .. param
                else
                    return "Failed to spawn entity: " .. name
                end
            end
            return "Would spawn entity: " .. name .. " (simulation)"
        end
        
        return "Cannot spawn in current game state"
    end, "Spawn an item or entity. Usage: spawn \"<name>\" [amount/level]\n" ..
         "In dungeons spawns monsters, otherwise adds items to inventory.\n" ..
         "Use quotes for names with spaces: spawn \"healing potion\" 5")
    
    -- Player commands
    self:addCommand("player", function(args)
        if #args == 0 then
            return "Usage: player <command> [args]. Try 'help player' for more info."
        end
        
        local subcmd = args[1]
        
        -- Handle player-related commands
        if subcmd == "health" and #args > 1 then
            local health = tonumber(args[2])
            if health and GAME.player then
                GAME.player.health = health
                return "Player health set to " .. health
            end
        elseif subcmd == "gold" and #args > 1 then
            local amount = tonumber(args[2])
            if amount and GAME.player then
                GAME.player.gold = amount
                return "Player gold set to " .. amount
            end
        elseif subcmd == "level" and #args > 1 then
            local level = tonumber(args[2])
            if level and GAME.player then
                GAME.player.level = level
                return "Player level set to " .. level
            end
        elseif subcmd == "info" then
            if GAME.player then
                return "Player: Level " .. GAME.player.level .. 
                       ", Health " .. GAME.player.health .. "/" .. GAME.player.maxHealth ..
                       ", Gold " .. GAME.player.gold
            end
        elseif subcmd == "additem" or subcmd == "add" then
            if #args < 2 then
                return "Usage: player additem \"<item name>\" [amount]"
            end
            
            local itemName = args[2]
            local amount = tonumber(args[3]) or 1
            
            -- Check if inventory exists
            if not GAME.inventory then
                GAME.inventory = {}
            end
            
            -- Get the item system
            local itemSystem = require("gameplay/item")
            if not itemSystem then
                return "Error: Item system not available"
            end
            
            -- Try to find the item by name in all item sources
            local foundItem = nil
            local itemType = nil
            
            -- 1. Look through unique items
            if itemSystem.uniqueItems then
                for id, item in pairs(itemSystem.uniqueItems) do
                    if item.name == itemName then
                        foundItem = item
                        itemType = "unique"
                        break
                    end
                end
            end
            
            -- 2. Look through set items if not found in uniques
            if not foundItem and itemSystem.setItems then
                for id, item in pairs(itemSystem.setItems) do
                    if item.name == itemName then
                        foundItem = item
                        itemType = "set"
                        break
                    end
                end
            end
            
            -- 3. Look through regular items if not found in uniques or sets
            if not foundItem and itemSystem.items then
                for id, item in pairs(itemSystem.items) do
                    if item.name == itemName then
                        foundItem = item
                        itemType = "regular"
                        break
                    end
                end
            end
            
            -- 4. Look through monster parts if not found elsewhere
            if not foundItem and itemSystem.monsterParts then
                for id, item in pairs(itemSystem.monsterParts) do
                    if item.name == itemName then
                        foundItem = item
                        itemType = "monsterPart"
                        break
                    end
                end
            end
            
            -- If we found an item, add it to inventory
            if foundItem then
                local clonedItem
                if itemSystem.cloneItemWithId then
                    clonedItem = itemSystem:cloneItemWithId(foundItem)
                else
                    -- Manual clone if function not available
                    clonedItem = {}
                    for k, v in pairs(foundItem) do
                        clonedItem[k] = v
                    end
                    clonedItem.uniqueId = os.time() .. "_" .. math.random(1000)
                    
                    -- Set count for stackable items
                    if foundItem.type == "consumable" or foundItem.type == "material" or foundItem.type == "monster_part" then
                        clonedItem.count = amount
                    end
                end
                
                if itemSystem.addToInventory then
                    itemSystem:addToInventory(clonedItem)
                else
                    table.insert(GAME.inventory, clonedItem)
                end
                
                local itemTypeText = ""
                if itemType == "unique" then
                    itemTypeText = "unique "
                elseif itemType == "set" then
                    itemTypeText = "set "
                end
                
                return "Added " .. itemTypeText .. "item: " .. itemName
            else
                -- No item found with that name in any of the item sources
                return "Error: Item '" .. itemName .. "' does not exist in any item definition table"
            end
        elseif subcmd == "removeitem" or subcmd == "remove" then
            if #args < 2 then
                return "Usage: player removeitem \"<item name>\" [amount]"
            end
            
            local itemName = args[2]
            local amount = tonumber(args[3]) or 1
            
            -- Check if inventory exists
            if not GAME.inventory or #GAME.inventory == 0 then
                return "Inventory is empty"
            end
            
            -- Search for the item by name
            for i, item in ipairs(GAME.inventory) do
                if item.name == itemName then
                    -- Found the item, handle removal
                    if item.count and item.count > amount then
                        -- Reduce stack
                        item.count = item.count - amount
                        return "Removed " .. amount .. "x " .. itemName .. " from inventory"
                    else
                        -- Remove the item entirely
                        table.remove(GAME.inventory, i)
                        return "Removed " .. itemName .. " from inventory"
                    end
                end
            end
            
            return "Item '" .. itemName .. "' not found in inventory"
        end
        
        return "Unknown player command or no player loaded"
    end, "Player-related commands. Usage: player <subcommand> [args]\n" ..
        "Available subcommands: health, gold, level, info, additem, removeitem\n" ..
        "For items with spaces in names, use quotes: player additem \"healing potion\" 5")
    
    -- FPS commands
    self:addCommand("fps", function(args)
        if #args > 0 then
            local subcmd = args[1]:lower()
            if subcmd == "show" then
                GAME.showFPS = true
                return "FPS display enabled"
            elseif subcmd == "hide" then
                GAME.showFPS = false
                return "FPS display disabled"
            end
        end
        return "Current FPS: " .. love.timer.getFPS()
    end, "FPS commands. Usage: fps [show|hide]")
end

return debugConsole 