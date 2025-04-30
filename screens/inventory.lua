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
        
        dropButton = screenManager.UI.Button(
            GAME.width - 100, GAME.height - 60, 
            80, 40, "Drop", 
            function() inventory:dropItem() end
        )
    }
    
    -- Set visibility for action buttons
    self.elements.actionButtons.useButton.visible = true
    self.elements.actionButtons.equipButton.visible = true
    self.elements.actionButtons.dropButton.visible = true
    
    -- Create back button
    self.elements.backButton = screenManager.UI.Button(
        20, GAME.height - 60, 
        100, 40, "Back", 
        function() self:close() end
    )
    self.elements.backButton.visible = true
end

function inventory:enter(params)
    -- Initialize state
    self.state = "main"
    self.selectedItem = nil
    self.pageOffset = 0
    
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
        
        self.elements.actionButtons.dropButton:draw()
    end
    
    -- Draw back button
    self.elements.backButton:draw()
end

function inventory:mousepressed(x, y, button, istouch, presses)
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
        if self.selectedItem.type == "consumable" and
           self.elements.actionButtons.useButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            clickHandled = true
        elseif (self.selectedItem.type == "weapon" or 
            self.selectedItem.type == "armor" or 
            self.selectedItem.type == "accessory") and
           self.selectedCharacter and
           self.elements.actionButtons.equipButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            clickHandled = true
        elseif self.elements.actionButtons.dropButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
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
    -- Select character
    self.selectedCharacter = character
end

function inventory:selectItem(item)
    -- Select item
    self.selectedItem = item
end

function inventory:isItemEquipped(item, character)
    -- Check if item is equipped by character
    if not character or not character.equipment then
        return false
    end
    
    for slot, equippedItem in pairs(character.equipment) do
        if equippedItem == item then
            return true
        end
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
    local success = itemSystem:useItem(self.selectedItem, self.selectedCharacter)
    
    if success then
        -- Play use sound
        assetManager:playSound("pickup")
        
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
    end
end

function inventory:equipItem()
    if not self.selectedItem or not self.selectedCharacter then
        return
    end
    
    -- Check if item is equippable
    if self.selectedItem.type ~= "weapon" and 
       self.selectedItem.type ~= "armor" and 
       self.selectedItem.type ~= "accessory" then
        return
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
                return
            end
        end
    end
    
    -- Determine equipment slot
    local slot = self.selectedItem.slot or "weapon"
    
    -- Unequip previous item if exists
    local prevItem = self.selectedCharacter.equipment[slot]
    
    -- Equip new item
    self.selectedCharacter.equipment[slot] = self.selectedItem
    
    -- Play equip sound
    assetManager:playSound("pickup")
    
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
    -- Return to previous state
    local gameState = require("states/gameState")
    gameState:returnToPreviousState()
end

return inventory
