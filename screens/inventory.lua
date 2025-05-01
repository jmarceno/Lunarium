-- Inventory Screen
-- Where players can manage items and equipment
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local itemSystem = require("gameplay/item")

local inventory = screenManager:createScreen("Inventory")

function inventory:init()
    -- Initialize state
    self.state = "main" -- main, item_details, equip
    self.selectedItem = nil
    self.selectedCharacter = nil
    self.selectedCategory = "All"
    self.pageOffset = 0
    self.itemsPerPage = 12
    self.sortBy = "type" -- type, name, value
    self.contextMenuVisible = false
    self.confirmDialogVisible = false
    self.openedFrom = nil -- Track which state opened the inventory
    
    -- Categories
    self.categories = {
        "All",
        "Weapons",
        "Armor",
        "Accessories",
        "Consumables",
        "Materials"
    }
    
    -- Create UI elements
    self:createUI()
end

function inventory:createUI()
    -- Create category buttons
    self.elements.categoryButtons = {}
    
    for i, category in ipairs(self.categories) do
        self.elements.categoryButtons[i] = screenManager.UI.Button(
            20 + (i-1) * 125, 50, 
            115, 30, category, 
            function() self:selectCategory(category) end
        )
        self.elements.categoryButtons[i].visible = true
    end
    
    -- Create sort buttons
    self.elements.sortButtons = {
        screenManager.UI.Button(
            20, 90, 
            115, 25, "Sort by Type", 
            function() self:setSortMethod("type") end
        ),
        screenManager.UI.Button(
            145, 90, 
            115, 25, "Sort by Name", 
            function() self:setSortMethod("name") end
        ),
        screenManager.UI.Button(
            270, 90, 
            115, 25, "Sort by Value", 
            function() self:setSortMethod("value") end
        )
    }
    
    -- Set visibility for sort buttons
    for _, button in ipairs(self.elements.sortButtons) do
        button.visible = true
    end
    
    -- Create character selection tabs
    self.elements.characterTabs = {
        x = GAME.width - 300,
        y = 50,
        width = 280,
        height = 30,
        
        draw = function(self)
            -- Draw background
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            
            -- Draw character tabs
            if GAME.party then
                local tabWidth = self.width / #GAME.party
                
                for i, character in ipairs(GAME.party) do
                    local x = self.x + (i-1) * tabWidth
                    
                    -- Draw tab background
                    if inventory.selectedCharacter == character then
                        love.graphics.setColor(0.3, 0.5, 0.8)
                    else
                        love.graphics.setColor(0.3, 0.3, 0.5)
                    end
                    
                    love.graphics.rectangle("fill", x, self.y, tabWidth - 2, self.height, 5, 5)
                    
                    -- Draw character name
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    local nameWidth = screenManager.fonts.small:getWidth(character.name)
                    love.graphics.print(
                        character.name,
                        x + (tabWidth - nameWidth) / 2,
                        self.y + 5
                    )
                end
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within tabs
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check character tabs
                if GAME.party then
                    local tabWidth = self.width / #GAME.party
                    
                    for i, character in ipairs(GAME.party) do
                        local tabX = self.x + (i-1) * tabWidth
                        
                        if x >= tabX and x <= tabX + tabWidth - 2 then
                            -- Debug output
                            if GAME.debug then
                                print("Character tab clicked: " .. character.name)
                            end
                            
                            inventory:selectCharacter(character)
                            return true
                        end
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create item list panel
    self.elements.itemListPanel = {
        x = 20,
        y = 130,
        width = 500,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Inventory", self.x, self.y, self.width, self.height)
            
            -- Draw items
            local itemCount = 0
            local displayedItems = {}
            
            if GAME.inventory then
                -- Filter items by category
                for _, item in ipairs(GAME.inventory) do
                    if inventory.selectedCategory == "All" or
                       (inventory.selectedCategory == "Weapons" and item.type == "weapon") or
                       (inventory.selectedCategory == "Armor" and item.type == "armor") or
                       (inventory.selectedCategory == "Accessories" and item.type == "accessory") or
                       (inventory.selectedCategory == "Consumables" and item.type == "consumable") or
                       (inventory.selectedCategory == "Materials" and (item.type == "material" or item.type == "monster_part")) then
                        
                        table.insert(displayedItems, item)
                    end
                end
                
                -- Sort items
                if inventory.sortBy == "type" then
                    table.sort(displayedItems, function(a, b)
                        if a.type == b.type then
                            return a.name < b.name
                        else
                            return inventory:getTypeOrder(a.type) < inventory:getTypeOrder(b.type)
                        end
                    end)
                elseif inventory.sortBy == "name" then
                    table.sort(displayedItems, function(a, b)
                        return a.name < b.name
                    end)
                elseif inventory.sortBy == "value" then
                    table.sort(displayedItems, function(a, b)
                        local aValue = a.value or 0
                        local bValue = b.value or 0
                        return aValue > bValue
                    end)
                end
                
                -- Apply pagination
                local startIndex = inventory.pageOffset + 1
                local endIndex = math.min(startIndex + inventory.itemsPerPage - 1, #displayedItems)
                
                -- Draw visible items
                for i = startIndex, endIndex do
                    local item = displayedItems[i]
                    local itemY = self.y + 50 + (i - startIndex) * 30
                    
                    -- Draw item entry background
                    if item == inventory.selectedItem then
                        love.graphics.setColor(0.3, 0.3, 0.5)
                    else
                        love.graphics.setColor(0.2, 0.2, 0.3)
                    end
                    
                    love.graphics.rectangle(
                        "fill",
                        self.x + 10, itemY, 
                        self.width - 20, 25,
                        5, 5
                    )
                    
                    -- Draw item name
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(1, 1, 1)
                    
                    love.graphics.print(
                        item.name,
                        self.x + 20, itemY + 5
                    )
                    
                    -- Draw item count if stackable
                    if item.count and item.count > 1 then
                        love.graphics.print(
                            "x" .. item.count,
                            self.x + self.width - 80, itemY + 5
                        )
                    end
                    
                    -- Draw equipped indicator
                    if inventory.selectedCharacter and inventory:isItemEquipped(item, inventory.selectedCharacter) then
                        love.graphics.setColor(0.2, 0.8, 0.2)
                        love.graphics.print(
                            "Equipped",
                            self.x + self.width - 180, itemY + 5
                        )
                    end
                end
                
                -- Draw pagination info
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                local totalPages = math.ceil(#displayedItems / inventory.itemsPerPage)
                local currentPage = math.floor(inventory.pageOffset / inventory.itemsPerPage) + 1
                
                love.graphics.print(
                    "Page " .. currentPage .. " of " .. (totalPages > 0 and totalPages or 1),
                    self.x + self.width / 2 - 40, self.y + self.height - 30
                )
                
                -- Draw pagination buttons
                if currentPage > 1 then
                    -- Draw prev button
                    love.graphics.setColor(0.3, 0.3, 0.5)
                    love.graphics.rectangle(
                        "fill",
                        self.x + 20, self.y + self.height - 35, 
                        100, 25,
                        5, 5
                    )
                    
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        "Previous",
                        self.x + 40, self.y + self.height - 33
                    )
                end
                
                if currentPage < totalPages then
                    -- Draw next button
                    love.graphics.setColor(0.3, 0.3, 0.5)
                    love.graphics.rectangle(
                        "fill",
                        self.x + self.width - 120, self.y + self.height - 35, 
                        100, 25,
                        5, 5
                    )
                    
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        "Next",
                        self.x + self.width - 100, self.y + self.height - 33
                    )
                end
            end
            
            -- Draw message if no items
            if #displayedItems == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                love.graphics.printf(
                    "No items in this category.",
                    self.x + 20, self.y + 150,
                    self.width - 40, "center"
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check pagination buttons
                if y >= self.y + self.height - 35 and y <= self.y + self.height - 10 then
                    local displayedItems = {}
                    
                    if GAME.inventory then
                        -- Filter items by category
                        for _, item in ipairs(GAME.inventory) do
                            if inventory.selectedCategory == "All" or
                               (inventory.selectedCategory == "Weapons" and item.type == "weapon") or
                               (inventory.selectedCategory == "Armor" and item.type == "armor") or
                               (inventory.selectedCategory == "Accessories" and item.type == "accessory") or
                               (inventory.selectedCategory == "Consumables" and item.type == "consumable") or
                               (inventory.selectedCategory == "Materials" and (item.type == "material" or item.type == "monster_part")) then
                                
                                table.insert(displayedItems, item)
                            end
                        end
                    end
                    
                    local totalPages = math.ceil(#displayedItems / inventory.itemsPerPage)
                    local currentPage = math.floor(inventory.pageOffset / inventory.itemsPerPage) + 1
                    
                    -- Prev button
                    if x >= self.x + 20 and x <= self.x + 120 and currentPage > 1 then
                        inventory.pageOffset = inventory.pageOffset - inventory.itemsPerPage
                        return true
                    end
                    
                    -- Next button
                    if x >= self.x + self.width - 120 and x <= self.x + self.width - 20 and currentPage < totalPages then
                        inventory.pageOffset = inventory.pageOffset + inventory.itemsPerPage
                        return true
                    end
                end
                
                -- Check item entries
                if GAME.inventory then
                    local displayedItems = {}
                    
                    -- Filter items by category
                    for _, item in ipairs(GAME.inventory) do
                        if inventory.selectedCategory == "All" or
                           (inventory.selectedCategory == "Weapons" and item.type == "weapon") or
                           (inventory.selectedCategory == "Armor" and item.type == "armor") or
                           (inventory.selectedCategory == "Accessories" and item.type == "accessory") or
                           (inventory.selectedCategory == "Consumables" and item.type == "consumable") or
                           (inventory.selectedCategory == "Materials" and (item.type == "material" or item.type == "monster_part")) then
                            
                            table.insert(displayedItems, item)
                        end
                    end
                    
                    -- Sort items
                    if inventory.sortBy == "type" then
                        table.sort(displayedItems, function(a, b)
                            if a.type == b.type then
                                return a.name < b.name
                            else
                                return inventory:getTypeOrder(a.type) < inventory:getTypeOrder(b.type)
                            end
                        end)
                    elseif inventory.sortBy == "name" then
                        table.sort(displayedItems, function(a, b)
                            return a.name < b.name
                        end)
                    elseif inventory.sortBy == "value" then
                        table.sort(displayedItems, function(a, b)
                            local aValue = a.value or 0
                            local bValue = b.value or 0
                            return aValue > bValue
                        end)
                    end
                    
                    -- Apply pagination
                    local startIndex = inventory.pageOffset + 1
                    local endIndex = math.min(startIndex + inventory.itemsPerPage - 1, #displayedItems)
                    
                    for i = startIndex, endIndex do
                        local itemY = self.y + 50 + (i - startIndex) * 30
                        
                        if y >= itemY and y <= itemY + 25 then
                            inventory:selectItem(displayedItems[i])
                            return true
                        end
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create character panel
    self.elements.characterPanel = {
        x = GAME.width - 300,
        y = 90,
        width = 280,
        height = 200,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Character", self.x, self.y, self.width, self.height)
            
            -- Draw character info
            if inventory.selectedCharacter then
                local char = inventory.selectedCharacter
                
                -- Draw character name and job
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    char.name,
                    self.x + 20, self.y + 50
                )
                
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.8, 1)
                
                love.graphics.print(
                    "Level " .. char.level .. " " .. char.job,
                    self.x + 20, self.y + 75
                )
                
                -- Draw equipped items
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    "Equipment",
                    self.x + 20, self.y + 100
                )
                
                love.graphics.setFont(screenManager.fonts.small)
                
                -- Draw weapon slot
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print(
                    "Weapon:",
                    self.x + 30, self.y + 125
                )
                
                if char.equipment.weapon then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        char.equipment.weapon.name,
                        self.x + 90, self.y + 125
                    )
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print(
                        "None",
                        self.x + 90, self.y + 125
                    )
                end
                
                -- Draw armor slot
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print(
                    "Armor:",
                    self.x + 30, self.y + 145
                )
                
                if char.equipment.body then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        char.equipment.body.name,
                        self.x + 90, self.y + 145
                    )
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print(
                        "None",
                        self.x + 90, self.y + 145
                    )
                end
                
                -- Draw offhand slot
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print(
                    "Offhand:",
                    self.x + 30, self.y + 165
                )
                
                if char.equipment.offhand then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        char.equipment.offhand.name,
                        self.x + 90, self.y + 165
                    )
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print(
                        "None",
                        self.x + 90, self.y + 165
                    )
                end
            end
        end
    }
    
    -- Create item details panel
    self.elements.itemDetailsPanel = {
        x = GAME.width - 300,
        y = 300,
        width = 280,
        height = 230,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Item Details", self.x, self.y, self.width, self.height)
            
            -- Draw item details
            if inventory.selectedItem then
                local item = inventory.selectedItem
                
                -- Draw item name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.printf(
                    item.name,
                    self.x + 20, self.y + 50,
                    self.width - 40, "left"
                )
                
                -- Draw item description
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.9, 0.9, 0.9)
                
                love.graphics.printf(
                    item.description or "No description available.",
                    self.x + 20, self.y + 80,
                    self.width - 40, "left"
                )
                
                -- Draw item stats based on type
                love.graphics.setFont(screenManager.fonts.small)
                
                -- Different stats based on item type
                if item.type == "weapon" then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("Type: Weapon", self.x + 20, self.y + 130)
                    
                    if item.attack then
                        love.graphics.print("Attack: " .. item.attack, self.x + 20, self.y + 150)
                    end
                    
                    if item.magicAttack then
                        love.graphics.print("Magic Attack: " .. item.magicAttack, self.x + 20, self.y + 170)
                    end
                elseif item.type == "armor" then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("Type: Armor", self.x + 20, self.y + 130)
                    
                    if item.defense then
                        love.graphics.print("Defense: " .. item.defense, self.x + 20, self.y + 150)
                    end
                    
                    if item.magicDefense then
                        love.graphics.print("Magic Defense: " .. item.magicDefense, self.x + 20, self.y + 170)
                    end
                elseif item.type == "accessory" then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("Type: Accessory", self.x + 20, self.y + 130)
                    
                    -- Print various possible accessory stats
                    local statY = self.y + 150
                    if item.defense then
                        love.graphics.print("Defense: " .. item.defense, self.x + 20, statY)
                        statY = statY + 20
                    end
                    
                    if item.magicDefense then
                        love.graphics.print("Magic Defense: " .. item.magicDefense, self.x + 20, statY)
                        statY = statY + 20
                    end
                    
                    if item.attack then
                        love.graphics.print("Attack: " .. item.attack, self.x + 20, statY)
                        statY = statY + 20
                    end
                    
                    if item.magicAttack then
                        love.graphics.print("Magic Attack: " .. item.magicAttack, self.x + 20, statY)
                    end
                elseif item.type == "consumable" then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("Type: Consumable", self.x + 20, self.y + 130)
                    
                    -- Print effect if available
                    if item.effect then
                        if item.effect.type == "heal" then
                            love.graphics.print("Restores " .. item.effect.amount .. " HP", self.x + 20, self.y + 150)
                        elseif item.effect.type == "restore_mp" then
                            love.graphics.print("Restores " .. item.effect.amount .. " MP", self.x + 20, self.y + 150)
                        elseif item.effect.type == "cure_status" then
                            love.graphics.print("Cures " .. item.effect.status .. " status", self.x + 20, self.y + 150)
                        elseif item.effect.type == "full_restore" then
                            love.graphics.print("Fully restores HP and MP", self.x + 20, self.y + 150)
                        end
                    end
                elseif item.type == "material" or item.type == "monster_part" then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("Type: Material", self.x + 20, self.y + 130)
                    love.graphics.print("Used for crafting", self.x + 20, self.y + 150)
                end
                
                -- Draw value
                if item.value then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.print("Value: " .. item.value .. " gold", self.x + 20, self.y + 200)
                end
            end
        end
    }
    
    -- Create action buttons
    self.elements.actionButtons = {
        useButton = screenManager.UI.Button(
            GAME.width - 280, GAME.height - 60, 
            80, 40, "Use", 
            function() inventory:useItem() end
        ),
        
        equipButton = screenManager.UI.Button(
            GAME.width - 190, GAME.height - 60, 
            80, 40, "Equip", 
            function() inventory:equipItem() end
        ),
        
        sellButton = screenManager.UI.Button(
            GAME.width - 190, GAME.height - 110, 
            80, 40, "Sell", 
            function() inventory:sellItem() end
        ),
        
        dropButton = screenManager.UI.Button(
            GAME.width - 100, GAME.height - 60, 
            80, 40, "Drop", 
            function() inventory:dropItem() end
        )
    }
    
    -- Set visibility for action buttons
    self.elements.actionButtons.useButton.visible = true
    self.elements.actionButtons.equipButton.visible = true
    self.elements.actionButtons.sellButton.visible = true
    self.elements.actionButtons.dropButton.visible = true
    
    -- Create back button
    self.elements.backButton = screenManager.UI.Button(
        20, GAME.height - 60, 
        100, 40, "Back", 
        function() self:close() end
    )
    self.elements.backButton.visible = true
    
    -- Create context menu
    self.elements.contextMenu = {
        x = 0,
        y = 0,
        width = 150,
        height = 0,
        options = {},
        visible = false,
        
        setPosition = function(self, x, y)
            -- Ensure menu stays on screen
            self.x = math.min(x, GAME.width - self.width)
            self.y = math.min(y, GAME.height - self.height)
        end,
        
        setOptions = function(self, options)
            self.options = options
            self.height = #options * 30 + 10
        end,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Draw background
            love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
            
            -- Draw options
            love.graphics.setFont(screenManager.fonts.small)
            for i, option in ipairs(self.options) do
                -- Hover effect
                if option.hover then
                    love.graphics.setColor(0.4, 0.4, 0.6)
                    love.graphics.rectangle("fill", self.x + 5, self.y + (i-1) * 30 + 5, self.width - 10, 25, 3, 3)
                end
                
                -- Option text
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(option.text, self.x + 15, self.y + (i-1) * 30 + 10)
            end
        end,
        
        update = function(self, x, y)
            if not self.visible then return end
            
            -- Update hover states
            for i, option in ipairs(self.options) do
                local optionY = self.y + (i-1) * 30 + 5
                option.hover = x >= self.x + 5 and x <= self.x + self.width - 5 and
                               y >= optionY and y <= optionY + 25
            end
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            for i, option in ipairs(self.options) do
                local optionY = self.y + (i-1) * 30 + 5
                if x >= self.x + 5 and x <= self.x + self.width - 5 and
                   y >= optionY and y <= optionY + 25 then
                    -- Execute callback
                    if option.callback then
                        option.callback()
                    end
                    
                    -- Hide menu after clicking an option
                    self.visible = false
                    return true
                end
            end
            
            -- Check if click is outside menu (to close it)
            if x < self.x or x > self.x + self.width or
               y < self.y or y > self.y + self.height then
                self.visible = false
                return true
            end
            
            return true
        end
    }
    
    -- Create confirmation dialog
    self.elements.confirmDialog = {
        x = GAME.width / 2 - 150,
        y = GAME.height / 2 - 100,
        width = 300,
        height = 200,
        message = "",
        confirmCallback = nil,
        cancelCallback = nil,
        visible = false,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Dim background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
            
            -- Draw panel
            love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 8, 8)
            
            -- Draw message
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(self.message, self.x + 20, self.y + 40, self.width - 40, "center")
            
            -- Draw buttons
            -- Yes button
            love.graphics.setColor(0.2, 0.5, 0.2)
            love.graphics.rectangle("fill", self.x + self.width - 110, self.y + self.height - 60, 90, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Yes", self.x + self.width - 85, self.y + self.height - 50)
            
            -- No button
            love.graphics.setColor(0.5, 0.2, 0.2)
            love.graphics.rectangle("fill", self.x + 20, self.y + self.height - 60, 90, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("No", self.x + 50, self.y + self.height - 50)
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Yes button
            if x >= self.x + self.width - 110 and x <= self.x + self.width - 20 and
               y >= self.y + self.height - 60 and y <= self.y + self.height - 20 then
                if self.confirmCallback then
                    self.confirmCallback()
                end
                self.visible = false
                return true
            end
            
            -- No button
            if x >= self.x + 20 and x <= self.x + 110 and
               y >= self.y + self.height - 60 and y <= self.y + self.height - 20 then
                if self.cancelCallback then
                    self.cancelCallback()
                end
                self.visible = false
                return true
            end
            
            return true
        end
    }
    
    -- Create quantity selector dialog
    self.elements.quantitySelector = {
        x = GAME.width / 2 - 150,
        y = GAME.height / 2 - 120,
        width = 300,
        height = 240,
        message = "",
        quantity = 1,
        maxQuantity = 1,
        confirmCallback = nil,
        cancelCallback = nil,
        visible = false,
        item = nil,
        
        draw = function(self)
            if not self.visible then return end
            
            -- Dim background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
            
            -- Draw panel
            love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 8, 8)
            
            -- Draw item name and message
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            if self.item then
                love.graphics.printf(self.item.name, self.x + 20, self.y + 20, self.width - 40, "center")
            end
            
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.printf(self.message, self.x + 20, self.y + 50, self.width - 40, "center")
            
            -- Draw quantity selector
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", self.x + 60, self.y + 90, self.width - 120, 40, 5, 5)
            
            -- Draw quantity value
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(tostring(self.quantity), self.x + 60, self.y + 95, self.width - 120, "center")
            
            -- Draw decrement button
            love.graphics.setColor(0.7, 0.3, 0.3)
            love.graphics.rectangle("fill", self.x + 20, self.y + 90, 30, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.print("-", self.x + 28, self.y + 95)
            
            -- Draw increment button
            love.graphics.setColor(0.3, 0.7, 0.3)
            love.graphics.rectangle("fill", self.x + self.width - 50, self.y + 90, 30, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("+", self.x + self.width - 42, self.y + 95)
            
            -- Draw slider
            local sliderWidth = self.width - 40
            local sliderX = self.x + 20
            local sliderY = self.y + 140
            
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, 10, 3, 3)
            
            local handlePos = sliderX + (self.quantity - 1) / (self.maxQuantity - 1) * sliderWidth
            if self.maxQuantity == 1 then
                handlePos = sliderX + sliderWidth / 2
            end
            
            love.graphics.setColor(0.7, 0.7, 0.8)
            love.graphics.rectangle("fill", handlePos - 5, sliderY - 5, 10, 20, 3, 3)
            
            -- Draw value if selling
            if self.value then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.printf(
                    "Value: " .. (self.value * self.quantity) .. " gold",
                    self.x + 20, self.y + 160, self.width - 40, "center"
                )
            end
            
            -- Draw buttons
            -- Confirm button
            love.graphics.setColor(0.2, 0.5, 0.2)
            love.graphics.rectangle("fill", self.x + self.width - 110, self.y + self.height - 60, 90, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.print("Confirm", self.x + self.width - 100, self.y + self.height - 45)
            
            -- Cancel button
            love.graphics.setColor(0.5, 0.2, 0.2)
            love.graphics.rectangle("fill", self.x + 20, self.y + self.height - 60, 90, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Cancel", self.x + 35, self.y + self.height - 45)
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Decrement button
            if x >= self.x + 20 and x <= self.x + 50 and
               y >= self.y + 90 and y <= self.y + 130 then
                self.quantity = math.max(1, self.quantity - 1)
                assetManager:playSound("click")
                return true
            end
            
            -- Increment button
            if x >= self.x + self.width - 50 and x <= self.x + self.width - 20 and
               y >= self.y + 90 and y <= self.y + 130 then
                self.quantity = math.min(self.maxQuantity, self.quantity + 1)
                assetManager:playSound("click")
                return true
            end
            
            -- Slider
            local sliderWidth = self.width - 40
            local sliderX = self.x + 20
            local sliderY = self.y + 140
            
            if x >= sliderX and x <= sliderX + sliderWidth and
               y >= sliderY - 10 and y <= sliderY + 20 then
                local percentage = (x - sliderX) / sliderWidth
                self.quantity = math.max(1, math.min(self.maxQuantity, math.floor(percentage * self.maxQuantity + 0.5)))
                return true
            end
            
            -- Confirm button
            if x >= self.x + self.width - 110 and x <= self.x + self.width - 20 and
               y >= self.y + self.height - 60 and y <= self.y + self.height - 20 then
                if self.confirmCallback then
                    self.confirmCallback(self.quantity)
                end
                self.visible = false
                assetManager:playSound("click")
                return true
            end
            
            -- Cancel button
            if x >= self.x + 20 and x <= self.x + 110 and
               y >= self.y + self.height - 60 and y <= self.y + self.height - 20 then
                if self.cancelCallback then
                    self.cancelCallback()
                end
                self.visible = false
                assetManager:playSound("click")
                return true
            end
            
            return true
        end,
        
        show = function(self, item, message, maxQuantity, callback, cancelCallback, value)
            self.item = item
            self.message = message or "Select quantity:"
            self.maxQuantity = maxQuantity or 1
            self.quantity = 1
            self.confirmCallback = callback
            self.cancelCallback = cancelCallback
            self.visible = true
            self.value = value
        end
    }
end

function inventory:enter(params)
    -- Initialize state
    self.state = "main"
    self.selectedItem = nil
    self.pageOffset = 0
    
    -- Track which state opened the inventory
    local gameState = require("states/gameState")
    self.openedFrom = params and params.from or gameState:getCurrentStateName()
    
    if GAME.debug then
        print("Inventory opened from state: " .. (self.openedFrom or "unknown"))
    end
    
    -- Select first character if available
    if GAME.party and #GAME.party > 0 then
        self.selectedCharacter = GAME.party[1]
    else
        self.selectedCharacter = nil
    end
end

function inventory:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(screenManager.colors.title)
    love.graphics.print("Inventory", 20, 10)
    
    -- Draw category buttons
    for _, button in ipairs(self.elements.categoryButtons) do
        button:draw()
    end
    
    -- Draw sort buttons
    for _, button in ipairs(self.elements.sortButtons) do
        button:draw()
    end
    
    -- Draw character tabs
    self.elements.characterTabs:draw()
    
    -- Draw main panels
    self.elements.itemListPanel:draw()
    self.elements.characterPanel:draw()
    self.elements.itemDetailsPanel:draw()
    
    -- Draw context menu if visible
    if self.elements.contextMenu.visible then
        self.elements.contextMenu:draw()
    end
    
    -- Draw confirmation dialog if visible
    if self.elements.confirmDialog.visible then
        self.elements.confirmDialog:draw()
    end
    
    -- Draw quantity selector if visible
    if self.elements.quantitySelector.visible then
        self.elements.quantitySelector:draw()
    end
    
    -- Draw floating message if exists
    if self.floatingMessage and self.floatingMessage.timeRemaining > 0 then
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.setColor(self.floatingMessage.color)
        
        -- Add shadow for better visibility
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.printf(self.floatingMessage.text, 
            self.floatingMessage.x - 198, self.floatingMessage.y + 2, 
            400, "center")
        
        -- Draw actual text
        love.graphics.setColor(self.floatingMessage.color)
        love.graphics.printf(self.floatingMessage.text, 
            self.floatingMessage.x - 200, self.floatingMessage.y, 
            400, "center")
    end
    
    -- Draw action buttons
    -- Only show appropriate buttons based on selected item
    if self.selectedItem then
        if self.selectedItem.type == "consumable" then
            self.elements.actionButtons.useButton:draw()
        end
        
        if (self.selectedItem.type == "weapon" or 
            self.selectedItem.type == "armor" or 
            self.selectedItem.type == "accessory") and
           self.selectedCharacter then
            self.elements.actionButtons.equipButton:draw()
        end
        
        -- Show sell button only if opened from overworld and item is not equipped
        if self.openedFrom == "overworld" then
            local isEquipped = false
            if self.selectedCharacter then
                isEquipped = self:isItemEquipped(self.selectedItem, self.selectedCharacter)
            end
            
            if not isEquipped then
                self.elements.actionButtons.sellButton:draw()
            end
        end
        
        self.elements.actionButtons.dropButton:draw()
    end
    
    -- Draw back button
    self.elements.backButton:draw()
end

function inventory:mousepressed(x, y, button, istouch, presses)
    -- Check if quantity selector is visible first
    if self.elements.quantitySelector.visible then
        self.elements.quantitySelector:clicked(x, y, button)
        return true
    end
    
    -- Check if confirmation dialog is visible first
    if self.elements.confirmDialog.visible then
        self.elements.confirmDialog:clicked(x, y, button)
        return true
    end
    
    -- Check if context menu is visible first
    if self.elements.contextMenu.visible then
        if self.elements.contextMenu:clicked(x, y, button) then
            return true
        end
    end
    
    -- Right-click to open context menu for items
    if button == 2 then
        -- Pass to item list panel to show context menu
        local itemClicked = false
        local displayedItems = {}
        
        if GAME.inventory then
            -- Filter items by category
            for _, item in ipairs(GAME.inventory) do
                if self.selectedCategory == "All" or
                   (self.selectedCategory == "Weapons" and item.type == "weapon") or
                   (self.selectedCategory == "Armor" and item.type == "armor") or
                   (self.selectedCategory == "Accessories" and item.type == "accessory") or
                   (self.selectedCategory == "Consumables" and item.type == "consumable") or
                   (self.selectedCategory == "Materials" and (item.type == "material" or item.type == "monster_part")) then
                    
                    table.insert(displayedItems, item)
                end
            end
            
            -- Sort items
            if self.sortBy == "type" then
                table.sort(displayedItems, function(a, b)
                    if a.type == b.type then
                        return a.name < b.name
                    else
                        return self:getTypeOrder(a.type) < self:getTypeOrder(b.type)
                    end
                end)
            elseif self.sortBy == "name" then
                table.sort(displayedItems, function(a, b)
                    return a.name < b.name
                end)
            elseif self.sortBy == "value" then
                table.sort(displayedItems, function(a, b)
                    local aValue = a.value or 0
                    local bValue = b.value or 0
                    return aValue > bValue
                end)
            end
            
            -- Apply pagination
            local startIndex = self.pageOffset + 1
            local endIndex = math.min(startIndex + self.itemsPerPage - 1, #displayedItems)
            
            for i = startIndex, endIndex do
                local itemY = self.elements.itemListPanel.y + 50 + (i - startIndex) * 30
                
                if x >= self.elements.itemListPanel.x + 10 and x <= self.elements.itemListPanel.x + self.elements.itemListPanel.width - 10 and
                   y >= itemY and y <= itemY + 25 then
                    -- Select item and show context menu
                    self:selectItem(displayedItems[i])
                    self:showContextMenu(x, y)
                    itemClicked = true
                    break
                end
            end
        end
        
        if itemClicked then
            return true
        end
    end
    
    -- Flag to track if click was handled
    local clickHandled = false
    
    -- Pass to character tabs first
    if self.elements.characterTabs:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        clickHandled = true
    end
    
    -- Pass to item list panel if not yet handled
    if not clickHandled and self.elements.itemListPanel:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        clickHandled = true
    end
    
    -- Pass to category buttons if not yet handled
    if not clickHandled then
        for i, btn in ipairs(self.elements.categoryButtons) do
            if btn:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Category button clicked: " .. self.categories[i])
                end
                
                clickHandled = true
                break
            end
        end
    end
    
    -- Pass to sort buttons if not yet handled
    if not clickHandled then
        for i, btn in ipairs(self.elements.sortButtons) do
            if btn:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Sort button clicked: " .. i)
                end
                
                clickHandled = true
                break
            end
        end
    end
    
    -- Pass to action buttons if not yet handled
    if not clickHandled and self.selectedItem then
        if GAME.debug then
            print("Checking action buttons. Selected item: " .. self.selectedItem.name)
            if self.selectedCharacter then
                print("Selected character: " .. self.selectedCharacter.name)
            else
                print("No character selected")
            end
        end
        
        -- Check use button for consumables
        if self.selectedItem.type == "consumable" and
           self.elements.actionButtons.useButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            if GAME.debug then print("Use button clicked") end
            self:useItem()
            clickHandled = true
        -- Check equip button for appropriate item types
        elseif (self.selectedItem.type == "weapon" or 
               self.selectedItem.type == "armor" or 
               self.selectedItem.type == "accessory") and
               self.selectedCharacter and
               self.elements.actionButtons.equipButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            if GAME.debug then print("Equip button clicked") end
            self:equipItem()
            clickHandled = true
        -- Check sell button - only available if opened from overworld
        elseif self.openedFrom == "overworld" and
               self.elements.actionButtons.sellButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            if GAME.debug then print("Sell button clicked") end
            self:sellItem()
            clickHandled = true
        -- Check drop button
        elseif self.elements.actionButtons.dropButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            if GAME.debug then print("Drop button clicked") end
            self:confirmDropItem()
            clickHandled = true
        end
    end
    
    -- Pass to back button if not yet handled
    if not clickHandled and self.elements.backButton:clicked(x, y, button) then
        -- Play click sound
        assetManager:playSound("click")
        clickHandled = true
    end
    
    return clickHandled
end

function inventory:mousereleased(x, y, button, istouch, presses)
    -- Handle button releases to trigger callbacks
    
    -- Handle category buttons
    for _, btn in ipairs(self.elements.categoryButtons) do
        if btn.released then
            btn:released(x, y, button)
        end
    end
    
    -- Handle sort buttons
    for _, btn in ipairs(self.elements.sortButtons) do
        if btn.released then
            btn:released(x, y, button)
        end
    end
    
    -- Handle action buttons if item is selected
    if self.selectedItem then
        if self.selectedItem.type == "consumable" and
           self.elements.actionButtons.useButton.released then
            self.elements.actionButtons.useButton:released(x, y, button)
        end
        
        if (self.selectedItem.type == "weapon" or 
            self.selectedItem.type == "armor" or 
            self.selectedItem.type == "accessory") and
           self.selectedCharacter and
           self.elements.actionButtons.equipButton.released then
            self.elements.actionButtons.equipButton:released(x, y, button)
        end
        
        -- Handle sell button release
        if self.openedFrom == "overworld" and
           self.elements.actionButtons.sellButton.released then
            self.elements.actionButtons.sellButton:released(x, y, button)
        end
        
        if self.elements.actionButtons.dropButton.released then
            self.elements.actionButtons.dropButton:released(x, y, button)
        end
    end
    
    -- Handle back button
    if self.elements.backButton and self.elements.backButton.released then
        self.elements.backButton:released(x, y, button)
    end
    
    if GAME.debug then
        print("Inventory mouse released at: " .. x .. "," .. y)
    end
end

function inventory:getTypeOrder(type)
    if type == "weapon" then
        return 1
    elseif type == "armor" then
        return 2
    elseif type == "accessory" then
        return 3
    elseif type == "consumable" then
        return 4
    elseif type == "material" or type == "monster_part" then
        return 5
    else
        return 6
    end
end

function inventory:selectCategory(category)
    -- Select category
    self.selectedCategory = category
    
    -- Reset pagination
    self.pageOffset = 0
end

function inventory:setSortMethod(method)
    -- Set sort method
    self.sortBy = method
end

function inventory:selectCharacter(character)
    -- Debug output
    if GAME.debug then
        print("Selecting character: " .. character.name)
    end
    
    -- Select character
    self.selectedCharacter = character
    
    -- Play sound
    assetManager:playSound("click")
    
    -- Show feedback
    self:showFloatingMessage(character.name .. " selected", {0.3, 0.7, 1, 1})
end

function inventory:selectItem(item)
    -- Select item
    self.selectedItem = item
    self.elements.contextMenu.visible = false
end

function inventory:isItemEquipped(item, character)
    -- Check if item is equipped by character
    if not character or not character.equipment then
        return false
    end
    
    -- Debug output
    if GAME.debug then
        print("Checking if item " .. item.name .. " is equipped by " .. character.name)
        
        -- Print character's equipment
        for slot, equippedItem in pairs(character.equipment) do
            if equippedItem then
                print("Slot " .. slot .. ": " .. (equippedItem.name or "unknown"))
            end
        end
    end
    
    -- Check each equipment slot
    for slot, equippedItem in pairs(character.equipment) do
        if equippedItem and equippedItem.name == item.name then
            if GAME.debug then
                print("Item is equipped in slot: " .. slot)
            end
            return true
        end
    end
    
    if GAME.debug then
        print("Item is not equipped")
    end
    
    return false
end

function inventory:useItem()
    if not self.selectedItem or not self.selectedCharacter then
        return
    end
    
    -- Check if item is usable
    if self.selectedItem.type ~= "consumable" then
        return
    end
    
    -- Use item
    local success, message = itemSystem:useItem(self.selectedItem, self.selectedCharacter)
    
    if success then
        -- Play use sound
        assetManager:playSound("pickup")
        
        -- Show effect message
        if message then
            -- Create a temporary floating text for feedback
            self:showFloatingMessage(message, {0, 1, 0, 1})
        end
        
        -- Remove item from inventory
        for i, item in ipairs(GAME.inventory) do
            if item == self.selectedItem then
                if item.count and item.count > 1 then
                    item.count = item.count - 1
                else
                    table.remove(GAME.inventory, i)
                    self.selectedItem = nil
                end
                break
            end
        end
    else
        -- Play error sound
        assetManager:playSound("hit")
        
        -- Show error message
        if message then
            -- Create a temporary floating text for feedback
            self:showFloatingMessage(message, {1, 0.5, 0.5, 1})
        end
    end
end

-- Helper function to show floating message
function inventory:showFloatingMessage(message, color)
    -- Store the message for temporary display
    self.floatingMessage = {
        text = message,
        color = color or {1, 1, 1, 1},
        x = GAME.width / 2,
        y = GAME.height / 2 - 100,
        lifetime = 2.0, -- Show for 2 seconds
        timeRemaining = 2.0
    }
end

function inventory:equipItem()
    if not self.selectedItem or not self.selectedCharacter then
        self:showFloatingMessage("Select a character and an item first!", {1, 0.5, 0.5, 1})
        return
    end
    
    -- Check if item is equippable
    if self.selectedItem.type ~= "weapon" and 
       self.selectedItem.type ~= "armor" and 
       self.selectedItem.type ~= "accessory" then
        self:showFloatingMessage("This item cannot be equipped!", {1, 0.5, 0.5, 1})
        return
    end
    
    -- Debug output
    if GAME.debug then
        print("Equipping " .. self.selectedItem.name .. " to " .. self.selectedCharacter.name)
    end
    
    -- Check if character can equip this item
    if self.selectedItem.jobs then
        local canEquip = false
        for _, job in ipairs(self.selectedItem.jobs) do
            if job == self.selectedCharacter.job then
                canEquip = true
                break
            end
        end
        
        if not canEquip then
            -- Play error sound
            assetManager:playSound("hit")
            self:showFloatingMessage(self.selectedCharacter.name .. " cannot equip this item!", {1, 0.5, 0.5, 1})
            return
        end
    end
    
    -- Check requirements
    if self.selectedItem.requirements then
        for attr, req in pairs(self.selectedItem.requirements) do
            if not self.selectedCharacter.attributes[attr] or 
               self.selectedCharacter.attributes[attr] < req then
                -- Play error sound
                assetManager:playSound("hit")
                self:showFloatingMessage("Requirements not met: " .. attr .. " " .. req .. " required", {1, 0.5, 0.5, 1})
                return
            end
        end
    end
    
    -- Initialize equipment if not exists
    if not self.selectedCharacter.equipment then
        self.selectedCharacter.equipment = {}
    end
    
    -- Determine equipment slot
    local slot = self.selectedItem.slot or "weapon"
    
    -- Unequip previous item if exists
    local prevItem = self.selectedCharacter.equipment[slot]
    
    -- Remove stat bonuses from previous item if it exists
    if prevItem then
        -- Remove attack/defense bonuses
        if prevItem.attack then
            self.selectedCharacter.attack = self.selectedCharacter.attack - prevItem.attack
        end
        if prevItem.magicAttack then
            self.selectedCharacter.magicAttack = self.selectedCharacter.magicAttack - prevItem.magicAttack
        end
        if prevItem.defense then
            self.selectedCharacter.defense = self.selectedCharacter.defense - prevItem.defense
        end
        if prevItem.magicDefense then
            self.selectedCharacter.magicDefense = self.selectedCharacter.magicDefense - prevItem.magicDefense
        end
        
        -- Remove attribute bonuses if any
        if prevItem.attributes then
            for attr, bonus in pairs(prevItem.attributes) do
                if self.selectedCharacter.attributes[attr] then
                    self.selectedCharacter.attributes[attr] = self.selectedCharacter.attributes[attr] - bonus
                end
            end
        end
    end
    
    -- Equip new item
    self.selectedCharacter.equipment[slot] = self.selectedItem
    
    -- Add stat bonuses from new item
    if self.selectedItem.attack then
        self.selectedCharacter.attack = (self.selectedCharacter.attack or 0) + self.selectedItem.attack
    end
    if self.selectedItem.magicAttack then
        self.selectedCharacter.magicAttack = (self.selectedCharacter.magicAttack or 0) + self.selectedItem.magicAttack
    end
    if self.selectedItem.defense then
        self.selectedCharacter.defense = (self.selectedCharacter.defense or 0) + self.selectedItem.defense
    end
    if self.selectedItem.magicDefense then
        self.selectedCharacter.magicDefense = (self.selectedCharacter.magicDefense or 0) + self.selectedItem.magicDefense
    end
    
    -- Add attribute bonuses if any
    if self.selectedItem.attributes then
        for attr, bonus in pairs(self.selectedItem.attributes) do
            if self.selectedCharacter.attributes[attr] then
                self.selectedCharacter.attributes[attr] = self.selectedCharacter.attributes[attr] + bonus
            end
        end
    end
    
    -- Play equip sound
    assetManager:playSound("pickup")
    
    -- Show floating message
    self:showFloatingMessage(self.selectedItem.name .. " equipped!", {0.2, 1, 0.2, 1})
    
    -- Remove equipped item from inventory
    for i, item in ipairs(GAME.inventory) do
        if item == self.selectedItem then
            table.remove(GAME.inventory, i)
            break
        end
    end
    
    -- Add unequipped item to inventory if exists
    if prevItem then
        table.insert(GAME.inventory, prevItem)
    end
    
    -- Refresh selected item
    self.selectedItem = nil
end

function inventory:dropItem()
    if not self.selectedItem then
        return
    end
    
    -- Check if item is equipped
    for _, character in ipairs(GAME.party) do
        if self:isItemEquipped(self.selectedItem, character) then
            -- Play error sound
            assetManager:playSound("hit")
            return
        end
    end
    
    -- Remove item from inventory
    for i, item in ipairs(GAME.inventory) do
        if item == self.selectedItem then
            if item.count and item.count > 1 then
                item.count = item.count - 1
            else
                table.remove(GAME.inventory, i)
            end
            
            self.selectedItem = nil
            break
        end
    end
    
    -- Play drop sound
    assetManager:playSound("hit")
end

function inventory:close()
    -- Return to previous state with appropriate parameters
    local gameState = require("states/gameState")
    
    -- If we came from the dungeon, return with "from=inventory" parameter
    if self.openedFrom == "dungeon" then
        gameState:changeState("dungeon", { from = "inventory" })
    else
        -- Otherwise, just return to previous state
        gameState:returnToPreviousState()
    end
end

function inventory:showContextMenu(x, y)
    if not self.selectedItem then return end
    
    local contextMenu = self.elements.contextMenu
    local options = {}
    
    -- Add options based on item type
    if self.selectedItem.type == "weapon" or 
       self.selectedItem.type == "armor" or 
       self.selectedItem.type == "accessory" then
        -- Only show equip if character is selected
        if self.selectedCharacter then
            table.insert(options, {
                text = "Equip",
                callback = function() self:equipItem() end,
                hover = false
            })
        end
    end
    
    if self.selectedItem.type == "consumable" and self.selectedCharacter then
        table.insert(options, {
            text = "Use",
            callback = function() self:useItem() end,
            hover = false
        })
    end
    
    -- Examine option for all items
    table.insert(options, {
        text = "Examine",
        callback = function() 
            -- Just select the item to see details
            -- Already done by right-clicking
        end,
        hover = false
    })
    
    -- Sell option - only available if opened from town (overworld)
    if self.openedFrom == "overworld" then
        table.insert(options, {
            text = "Sell",
            callback = function() self:sellItem() end,
            hover = false
        })
    end
    
    -- Drop option for all items
    table.insert(options, {
        text = "Drop",
        callback = function()
            self:confirmDropItem()
        end,
        hover = false
    })
    
    -- Set options and position
    contextMenu:setOptions(options)
    contextMenu:setPosition(x, y)
    contextMenu.visible = true
end

function inventory:confirmDropItem()
    if not self.selectedItem then return end
    
    -- Check if item is equipped
    local isEquipped = false
    for _, character in ipairs(GAME.party) do
        if self:isItemEquipped(self.selectedItem, character) then
            isEquipped = true
            break
        end
    end
    
    if isEquipped then
        -- Cannot drop equipped items
        assetManager:playSound("hit")
        return
    end
    
    local dialog = self.elements.confirmDialog
    dialog.message = "Are you sure you want to drop " .. self.selectedItem.name .. "?\nThis item will be permanently destroyed."
    dialog.confirmCallback = function() self:dropItem() end
    dialog.cancelCallback = function() end
    dialog.visible = true
end

function inventory:update(dt)
    if self.elements.contextMenu.visible then
        local mx, my = love.mouse.getPosition()
        self.elements.contextMenu:update(mx, my)
    end
    
    -- Update floating message
    if self.floatingMessage then
        self.floatingMessage.timeRemaining = self.floatingMessage.timeRemaining - dt
        if self.floatingMessage.timeRemaining <= 0 then
            self.floatingMessage = nil
        end
    end
end

function inventory:sellItem()
    if not self.selectedItem then return end
    
    -- Check if inventory was opened from overworld
    if self.openedFrom ~= "overworld" then
        self:showFloatingMessage("You can only sell items in town!", {1, 0.3, 0.3, 1})
        return
    end
    
    -- Check if item is equipped by any character
    for _, character in ipairs(GAME.party) do
        if self:isItemEquipped(self.selectedItem, character) then
            self:showFloatingMessage("You can't sell equipped items!", {1, 0.3, 0.3, 1})
            return
        end
    end
    
    -- Determine if we should sell at guild or smith based on item type
    local sellLocation = "smith"
    if self.selectedItem.type == "monster_part" then
        sellLocation = "guild"
    end
    
    -- Calculate sell price (typically 50% of buy value)
    local sellPrice = math.floor((self.selectedItem.value or 1) * 0.5)
    
    -- For stacked items, ask how many to sell
    if self.selectedItem.count and self.selectedItem.count > 1 then
        self.elements.quantitySelector:show(
            self.selectedItem,
            "How many would you like to sell to the " .. sellLocation .. "?",
            self.selectedItem.count,
            function(quantity)
                self:completeSale(quantity, sellPrice, sellLocation)
            end,
            function()
                -- Cancel callback
            end,
            sellPrice
        )
    else
        -- Single item, confirm sale
        self.elements.confirmDialog.message = "Sell " .. self.selectedItem.name .. " to the " .. sellLocation .. " for " .. sellPrice .. " gold?"
        self.elements.confirmDialog.confirmCallback = function()
            self:completeSale(1, sellPrice, sellLocation)
        end
        self.elements.confirmDialog.visible = true
    end
end

function inventory:completeSale(quantity, price, location)
    if not self.selectedItem then return end
    
    -- Calculate total gold from sale
    local totalGold = price * quantity
    
    -- Add gold to player
    GAME.gold = (GAME.gold or 0) + totalGold
    
    -- Show feedback message
    self:showFloatingMessage("Sold " .. quantity .. " " .. self.selectedItem.name .. " for " .. totalGold .. " gold!", {1, 1, 0, 1})
    
    -- Remove sold items from inventory
    for i, item in ipairs(GAME.inventory) do
        if item == self.selectedItem then
            if item.count and item.count > quantity then
                item.count = item.count - quantity
            else
                table.remove(GAME.inventory, i)
                self.selectedItem = nil
            end
            break
        end
    end
    
    -- Play coin sound
    assetManager:playSound("pickup")
end

-- Add wheel scrolling function
function inventory:wheelmoved(x, y)
    -- Handle scrolling the item list using the mouse wheel
    if y ~= 0 and not self.elements.quantitySelector.visible and not self.elements.confirmDialog.visible then
        local displayedItems = {}
        
        if GAME.inventory then
            -- Filter items by category
            for _, item in ipairs(GAME.inventory) do
                if self.selectedCategory == "All" or
                   (self.selectedCategory == "Weapons" and item.type == "weapon") or
                   (self.selectedCategory == "Armor" and item.type == "armor") or
                   (self.selectedCategory == "Accessories" and item.type == "accessory") or
                   (self.selectedCategory == "Consumables" and item.type == "consumable") or
                   (self.selectedCategory == "Materials" and (item.type == "material" or item.type == "monster_part")) then
                    
                    table.insert(displayedItems, item)
                end
            end
        end
        
        local totalPages = math.ceil(#displayedItems / self.itemsPerPage)
        
        if y > 0 then
            -- Scroll up
            self.pageOffset = math.max(0, self.pageOffset - math.floor(self.itemsPerPage / 2))
            return true
        elseif y < 0 then
            -- Scroll down
            local maxOffset = math.max(0, #displayedItems - self.itemsPerPage)
            self.pageOffset = math.min(maxOffset, self.pageOffset + math.floor(self.itemsPerPage / 2))
            return true
        end
    end
    
    return false
end

-- Handle keyboard input
function inventory:keypressed(key, scancode, isrepeat)
    -- Handle ESC key to close the inventory
    if key == "escape" then
        -- If a dialog is open, close it first
        if self.elements.confirmDialog.visible then
            self.elements.confirmDialog.visible = false
            if self.elements.confirmDialog.cancelCallback then
                self.elements.confirmDialog.cancelCallback()
            end
            return true
        elseif self.elements.quantitySelector.visible then
            self.elements.quantitySelector.visible = false
            if self.elements.quantitySelector.cancelCallback then
                self.elements.quantitySelector.cancelCallback()
            end
            return true
        elseif self.elements.contextMenu.visible then
            self.elements.contextMenu.visible = false
            return true
        else
            -- Otherwise close the inventory
            self:close()
            return true
        end
    end
    
    return false
end

return inventory
