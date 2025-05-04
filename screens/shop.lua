-- Shop Screen
-- Where players can buy items and equipment
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local itemSystem = require("gameplay/item")

local shop = screenManager:createScreen("Shop")

function shop:init()
    -- Initialize state
    self.state = "main" -- main, item_details
    self.inventory = {}
    self.selectedItem = nil
    self.selectedCategory = "All"
    self.pageOffset = 0
    self.itemsPerPage = 8
    
    -- Categories
    self.categories = {
        "All",
        "Weapons",
        "Armor",
        "Accessories",
        "Consumables"
    }
    
    -- Create UI elements
    self:createUI()
end

function shop:createUI()
    -- Create category buttons
    self.elements.categoryButtons = {}
    
    for i, category in ipairs(self.categories) do
        self.elements.categoryButtons[i] = screenManager.UI.Button(
            50 + (i-1) * 150, 70, 
            130, 30, category, 
            function() self:selectCategory(category) end
        )
        self.elements.categoryButtons[i].visible = true
    end
    
    -- Create item list panel
    self.elements.itemListPanel = {
        x = 50,
        y = 120,
        width = 700,
        height = 400,
        
        draw = function(self)
            -- Draw panel background
            screenManager:drawPanel("Shop Inventory", self.x, self.y, self.width, self.height)
            
            -- Draw items
            local itemCount = 0
            local displayedItems = {}
            
            -- Filter items by category
            for _, item in ipairs(shop.inventory) do
                if shop.selectedCategory == "All" or
                   (shop.selectedCategory == "Weapons" and item.type == "weapon") or
                   (shop.selectedCategory == "Armor" and item.type == "armor") or
                   (shop.selectedCategory == "Accessories" and item.type == "accessory") or
                   (shop.selectedCategory == "Consumables" and item.type == "consumable") then
                    
                    table.insert(displayedItems, item)
                end
            end
            
            -- Apply pagination
            local startIndex = shop.pageOffset + 1
            local endIndex = math.min(startIndex + shop.itemsPerPage - 1, #displayedItems)
            
            -- Draw visible items
            for i = startIndex, endIndex do
                local item = displayedItems[i]
                local itemY = self.y + 50 + (i - startIndex) * 40
                
                -- Draw item entry background
                if item == shop.selectedItem then
                    love.graphics.setColor(0.3, 0.3, 0.5)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle(
                    "fill",
                    self.x + 10, itemY, 
                    self.width - 20, 35,
                    5, 5
                )
                
                -- Draw item name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    item.name,
                    self.x + 20, itemY + 5
                )
                
                -- Draw item price
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    item.value .. " gold",
                    self.x + self.width - 120, itemY + 5
                )
            end
            
            -- Draw pagination info
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(0.7, 0.7, 0.7)
            
            local totalPages = math.ceil(#displayedItems / shop.itemsPerPage)
            local currentPage = math.floor(shop.pageOffset / shop.itemsPerPage) + 1
            
            love.graphics.print(
                "Page " .. currentPage .. " of " .. totalPages,
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
            
            -- Draw message if no items
            if #displayedItems == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                love.graphics.printf(
                    "No items available in this category.",
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
                    -- Filter items by category
                    local displayedItems = {}
                    for _, item in ipairs(shop.inventory) do
                        if shop.selectedCategory == "All" or
                           (shop.selectedCategory == "Weapons" and item.type == "weapon") or
                           (shop.selectedCategory == "Armor" and item.type == "armor") or
                           (shop.selectedCategory == "Accessories" and item.type == "accessory") or
                           (shop.selectedCategory == "Consumables" and item.type == "consumable") then
                            
                            table.insert(displayedItems, item)
                        end
                    end
                    
                    local totalPages = math.ceil(#displayedItems / shop.itemsPerPage)
                    local currentPage = math.floor(shop.pageOffset / shop.itemsPerPage) + 1
                    
                    -- Prev button
                    if x >= self.x + 20 and x <= self.x + 120 and currentPage > 1 then
                        shop.pageOffset = shop.pageOffset - shop.itemsPerPage
                        return true
                    end
                    
                    -- Next button
                    if x >= self.x + self.width - 120 and x <= self.x + self.width - 20 and currentPage < totalPages then
                        shop.pageOffset = shop.pageOffset + shop.itemsPerPage
                        return true
                    end
                end
                
                -- Check item entries
                local displayedItems = {}
                
                -- Filter items by category
                for _, item in ipairs(shop.inventory) do
                    if shop.selectedCategory == "All" or
                       (shop.selectedCategory == "Weapons" and item.type == "weapon") or
                       (shop.selectedCategory == "Armor" and item.type == "armor") or
                       (shop.selectedCategory == "Accessories" and item.type == "accessory") or
                       (shop.selectedCategory == "Consumables" and item.type == "consumable") then
                        
                        table.insert(displayedItems, item)
                    end
                end
                
                -- Apply pagination
                local startIndex = shop.pageOffset + 1
                local endIndex = math.min(startIndex + shop.itemsPerPage - 1, #displayedItems)
                
                for i = startIndex, endIndex do
                    local itemY = self.y + 50 + (i - startIndex) * 40
                    
                    if y >= itemY and y <= itemY + 35 then
                        shop:selectItem(displayedItems[i])
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create item details panel
    self.elements.itemDetailsPanel = {
        x = 50,
        y = 120,
        width = 700,
        height = 400,
        visible = false,
        
        draw = function(self)
            if not self.visible or not shop.selectedItem then
                return
            end
            
            local item = shop.selectedItem
            
            -- Draw panel background
            screenManager:drawPanel("Item Details", self.x, self.y, self.width, self.height)
            
            -- Draw item name
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                item.name,
                self.x + 20, self.y + 50,
                self.width - 40, "center"
            )
            
            -- Draw item image placeholder
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle(
                "fill",
                self.x + 30, self.y + 100,
                100, 100
            )
            
            -- Draw item description
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 0.9)
            
            love.graphics.printf(
                item.description or "No description available.",
                self.x + 150, self.y + 100,
                self.width - 180, "left"
            )
            
            -- Draw item stats
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            local statsY = self.y + 210
            
            -- Draw stats based on item type
            if item.type == "weapon" then
                love.graphics.print("Attack: " .. (item.attack or 0), self.x + 30, statsY)
                love.graphics.print("Magic Attack: " .. (item.magicAttack or 0), self.x + 30, statsY + 30)
                
                if item.critRate then
                    love.graphics.print("Critical Rate: " .. item.critRate .. "%", self.x + 30, statsY + 60)
                end
                
                if item.subType then
                    love.graphics.print("Type: " .. item.subType, self.x + 30, statsY + 90)
                end
            elseif item.type == "armor" or item.type == "accessory" then
                love.graphics.print("Defense: " .. (item.defense or 0), self.x + 30, statsY)
                love.graphics.print("Magic Defense: " .. (item.magicDefense or 0), self.x + 30, statsY + 30)
                
                if item.evasion then
                    love.graphics.print("Evasion: " .. item.evasion, self.x + 30, statsY + 60)
                end
                
                if item.slot then
                    love.graphics.print("Slot: " .. item.slot, self.x + 30, statsY + 90)
                end
            elseif item.type == "consumable" and item.effect then
                love.graphics.print("Effect: ", self.x + 30, statsY)
                
                if item.effect.type == "heal" then
                    love.graphics.print("Restores " .. item.effect.amount .. " HP", self.x + 50, statsY + 30)
                elseif item.effect.type == "restore_mp" then
                    love.graphics.print("Restores " .. item.effect.amount .. " MP", self.x + 50, statsY + 30)
                elseif item.effect.type == "cure_status" then
                    love.graphics.print("Cures " .. item.effect.status .. " status", self.x + 50, statsY + 30)
                elseif item.effect.type == "full_restore" then
                    love.graphics.print("Fully restores HP and MP", self.x + 50, statsY + 30)
                end
            end
            
            -- Draw requirements if any
            if item.requirements then
                love.graphics.print("Requirements:", self.x + 300, statsY)
                
                local reqY = statsY + 30
                for attr, value in pairs(item.requirements) do
                    love.graphics.print(attr .. ": " .. value, self.x + 320, reqY)
                    reqY = reqY + 25
                end
            end
            
            -- Draw price
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 0)
            
            love.graphics.print(
                "Price: " .. item.value .. " gold",
                self.x + 30, self.y + self.height - 80
            )
            
            -- Draw buttons
            self.buyButton:draw()
            self.backButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check button clicks
            if self.buyButton:clicked(x, y, button) then
                return true
            end
            
            if self.backButton:clicked(x, y, button) then
                return true
            end
            
            return false
        end,
        
        init = function(self)
            -- Create buttons
            self.buyButton = screenManager.UI.Button(
                self.x + self.width / 2 - 110, self.y + self.height - 70, 
                100, 40, "Buy", 
                function() shop:buyItem() end
            )
            
            self.backButton = screenManager.UI.Button(
                self.x + self.width / 2 + 10, self.y + self.height - 70, 
                100, 40, "Back", 
                function() shop:showMainScreen() end
            )
        end
    }
    
    -- Initialize panels
    self.elements.itemDetailsPanel:init()
    
    -- Create back button
    self.elements.backToTownButton = screenManager.UI.Button(
        GAME.width - 170, GAME.height - 70, 
        150, 40, "Back to Town", 
        function() self:returnToTown() end
    )
    self.elements.backToTownButton.visible = true
    
    -- Set initial visibility state
    self:updateElementVisibility()
end

function shop:updateElementVisibility()
    -- Update element visibility based on current state
    if self.state == "main" then
        if self.elements.itemDetailsPanel then
            self.elements.itemDetailsPanel.visible = false
        end
    elseif self.state == "item_details" then
        if self.elements.itemDetailsPanel then
            self.elements.itemDetailsPanel.visible = true
        end
    end
    
    -- Category buttons are always visible
    for _, button in ipairs(self.elements.categoryButtons) do
        button.visible = true
    end
    
    -- Back to town button is always visible
    if self.elements.backToTownButton then
        self.elements.backToTownButton.visible = true
    end
    
    if GAME.debug then
        print("Shop UI visibility updated - State: " .. self.state)
    end
end

function shop:enter()
    -- Start playing shop music
    -- assetManager:playMusic("town") -- Use town music for now
    
    -- Load shop inventory
    self:loadInventory()
    
    -- Initialize state
    self.state = "main"
    self.selectedItem = nil
    self.elements.itemDetailsPanel.visible = false
    self.selectedCategory = "All"
    self.pageOffset = 0
    
    -- Update element visibility
    self:updateElementVisibility()
end

function shop:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw shop interior (placeholder)
    love.graphics.setColor(0.35, 0.35, 0.4)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    -- Draw shop counter
    love.graphics.setColor(0.6, 0.5, 0.4)
    love.graphics.rectangle("fill", 40, 20, 720, 80)
    
    -- Draw shop shelves
    love.graphics.setColor(0.5, 0.4, 0.3)
    love.graphics.rectangle("fill", 40, 110, 720, 420)
    
    -- Draw screen title
    love.graphics.setFont(screenManager.fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("General Store", 50, 30)
    
    -- Draw current gold
    if GAME.gold then
        love.graphics.setFont(screenManager.fonts.medium)
        love.graphics.setColor(1, 1, 0)
        
        love.graphics.print(
            "Gold: " .. GAME.gold,
            600, 30
        )
    end
    
    -- Draw category buttons
    for _, button in ipairs(self.elements.categoryButtons) do
        button:draw()
    end
    
    -- Draw state-specific UI
    if self.state == "main" then
        self.elements.itemListPanel:draw()
    elseif self.state == "item_details" then
        self.elements.itemDetailsPanel:draw()
    end
    
    -- Draw back button
    self.elements.backToTownButton:draw()
end

function shop:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Check item details panel if in that state
    if self.state == "item_details" and self.elements.itemDetailsPanel.visible then
        clickHandled = self.elements.itemDetailsPanel:clicked(x, y, button)
        if clickHandled then
            -- Play click sound
            assetManager:playSound("click")
            return true
        end
    end
    
    -- Check item list panel if in main state
    if self.state == "main" and not clickHandled then
        clickHandled = self.elements.itemListPanel:clicked(x, y, button)
        if clickHandled then
            -- Play click sound
            assetManager:playSound("click")
            return true
        end
    end
    
    -- Check category buttons
    for i, button in ipairs(self.elements.categoryButtons) do
        if button.visible and button:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            
            if GAME.debug then
                print("Category button clicked: " .. self.categories[i])
            end
            
            clickHandled = true
            -- Don't break to allow hover effects
        end
    end
    
    -- Check other UI elements
    for name, element in pairs(self.elements) do
        if element.clicked and element.visible ~= false and 
           element ~= self.elements.itemDetailsPanel and
           element ~= self.elements.itemListPanel and
           not (type(element) == "table" and element[1] and element[1].clicked) then  -- Skip category buttons array
            if element:clicked(x, y, button) then
                -- Play click sound
                assetManager:playSound("click")
                
                if GAME.debug then
                    print("Shop button clicked: " .. name)
                end
                
                clickHandled = true
                -- Don't break to allow hover effects
            end
        end
    end
    
    return clickHandled
end

function shop:mousereleased(x, y, button, istouch, presses)
    -- Handle mouse releases for UI elements
    
    -- Handle item details panel button releases
    if self.state == "item_details" and self.elements.itemDetailsPanel.visible then
        if self.elements.itemDetailsPanel.buyButton and self.elements.itemDetailsPanel.buyButton.released then
            self.elements.itemDetailsPanel.buyButton:released(x, y, button)
        end
        
        if self.elements.itemDetailsPanel.backButton and self.elements.itemDetailsPanel.backButton.released then
            self.elements.itemDetailsPanel.backButton:released(x, y, button)
        end
    end
    
    -- Handle category buttons
    for _, button in ipairs(self.elements.categoryButtons) do
        if button.released then
            button:released(x, y, button)
        end
    end
    
    -- Handle back to town button
    if self.elements.backToTownButton and self.elements.backToTownButton.released then
        self.elements.backToTownButton:released(x, y, button)
    end
    
    if GAME.debug then
        print("Shop mouse released at: " .. x .. "," .. y)
    end
end

function shop:loadInventory()
    -- Clear inventory
    self.inventory = {}
    
    -- Add weapons
    local weapons = itemSystem:getItemsByType("weapon")
    for _, weapon in ipairs(weapons) do
        -- Skip master weapons
        if weapon.tier ~= 3 then
            table.insert(self.inventory, weapon)
        end
    end
    
    -- Add armor
    local armors = itemSystem:getItemsByType("armor")
    for _, armor in ipairs(armors) do
        -- Skip master armor
        if armor.tier ~= 3 then
            table.insert(self.inventory, armor)
        end
    end
    
    -- Add accessories
    local accessories = itemSystem:getItemsByType("accessory")
    for _, accessory in ipairs(accessories) do
        -- Skip master accessories
        if accessory.tier ~= 3 then
            table.insert(self.inventory, accessory)
        end
    end
    
    -- Add consumables
    local consumables = itemSystem:getItemsByType("consumable")
    for _, consumable in ipairs(consumables) do
        table.insert(self.inventory, consumable)
    end
    
    -- Sort inventory by type, then by value
    table.sort(self.inventory, function(a, b)
        if a.type == b.type then
            return a.value < b.value
        else
            return self:getTypeOrder(a.type) < self:getTypeOrder(b.type)
        end
    end)
end

function shop:getTypeOrder(type)
    if type == "weapon" then
        return 1
    elseif type == "armor" then
        return 2
    elseif type == "accessory" then
        return 3
    elseif type == "consumable" then
        return 4
    else
        return 5
    end
end

function shop:selectCategory(category)
    -- Select category
    self.selectedCategory = category
    
    -- Reset pagination
    self.pageOffset = 0
    
    if GAME.debug then
        print("Selected category: " .. category)
    end
end

function shop:selectItem(item)
    -- Select item
    self.selectedItem = item
    
    -- Show item details
    self.state = "item_details"
    
    -- Update element visibility
    self:updateElementVisibility()
    
    if GAME.debug then
        print("Selected item: " .. item.name)
    end
end

function shop:showMainScreen()
    -- Go back to main screen
    self.state = "main"
    
    -- Update element visibility
    self:updateElementVisibility()
end

function shop:buyItem()
    if not self.selectedItem then
        return
    end
    
    -- Check if player has enough gold
    if not GAME.gold or GAME.gold < self.selectedItem.value then
        -- Not enough gold
        assetManager:playSound("hit")
        return
    end
    
    -- Deduct gold
    GAME.gold = GAME.gold - self.selectedItem.value
    
    -- Create a new item with proper unique ID
    local newItem = itemSystem:cloneItemWithId(self.selectedItem)
    
    -- Add item to inventory using the item system's function
    -- which will handle unique IDs and stacking properly
    itemSystem:addToInventory(newItem)
    
    -- Play success sound
    assetManager:playSound("pickup")
    
    -- Return to main screen
    self:showMainScreen()
end

function shop:returnToTown()
    -- Return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

return shop
