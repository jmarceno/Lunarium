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
    self.itemsPerPage = 12 -- Increased from 9 to fill taller panel
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
    
    -- LUIS layer name
    self.luisLayer = "inventoryScreen"
    
    -- Create UI elements
    self:createUI()
end

function inventory:createUI()
    -- Main container using flexbox layout
    self.mainContainer = luis.newFlexContainer(1, 1, 62, 38)
    self.mainContainer:setDirection("row")
    self.mainContainer:setJustifyContent("space-between")
    self.mainContainer:setAlignItems("stretch")
    self.mainContainer:setPadding(1, 1, 1, 1)
    
    -- Left column - Character list
    self.leftColumn = luis.newFlexContainer(0, 0, 18, 38)
    self.leftColumn:setDirection("column")
    self.leftColumn:setJustifyContent("flex-start")
    self.leftColumn:setAlignItems("stretch")
    self.leftColumn:setPadding(1, 1, 1, 1)
    
    -- Character list container
    self.characterListContainer = luis.newFlexContainer(0, 0, 18, 28)
    self.characterListContainer:setDirection("column")
    self.characterListContainer:setJustifyContent("flex-start")
    self.characterListContainer:setAlignItems("stretch")
    
    -- Character details panel
    self.characterDetailsPanel = luis.newFlexContainer(0, 0, 18, 10)
    self.characterDetailsPanel:setDirection("column")
    self.characterDetailsPanel:setJustifyContent("flex-start")
    self.characterDetailsPanel:setAlignItems("stretch")
    self.characterDetailsPanel:setPadding(1, 1, 1, 1)
    
    self.characterNameLabel = luis.newLabel(0, 0, 16, 2, "Select a character")
    self.characterJobLabel = luis.newLabel(0, 0, 16, 2, "")
    self.characterEquipmentLabel = luis.newLabel(0, 0, 16, 6, "Equipment will appear here")
    
    self.characterDetailsPanel:addChild(self.characterNameLabel)
    self.characterDetailsPanel:addChild(self.characterJobLabel)
    self.characterDetailsPanel:addChild(self.characterEquipmentLabel)
    
    self.leftColumn:addChild(self.characterListContainer)
    self.leftColumn:addChild(self.characterDetailsPanel)
    
    -- Middle column - Item details
    self.middleColumn = luis.newFlexContainer(0, 0, 18, 38)
    self.middleColumn:setDirection("column")
    self.middleColumn:setJustifyContent("flex-start")
    self.middleColumn:setAlignItems("stretch")
    self.middleColumn:setPadding(1, 1, 1, 1)
    
    -- Item details container
    self.itemDetailsContainer = luis.newFlexContainer(0, 0, 18, 36)
    self.itemDetailsContainer:setDirection("column")
    self.itemDetailsContainer:setJustifyContent("flex-start")
    self.itemDetailsContainer:setAlignItems("stretch")
    self.itemDetailsContainer:setPadding(1, 1, 1, 1)
    
    self.itemNameLabel = luis.newLabel(0, 0, 16, 2, "Select an item")
    self.itemDescriptionLabel = luis.newLabel(0, 0, 16, 10, "Item details will appear here")
    
    self.itemDetailsContainer:addChild(self.itemNameLabel)
    self.itemDetailsContainer:addChild(self.itemDescriptionLabel)
    
    self.middleColumn:addChild(self.itemDetailsContainer)
    
    -- Right column - Inventory grid
    self.rightColumn = luis.newFlexContainer(0, 0, 24, 38)
    self.rightColumn:setDirection("column")
    self.rightColumn:setJustifyContent("flex-start")
    self.rightColumn:setAlignItems("stretch")
    self.rightColumn:setPadding(1, 1, 1, 1)
    
    -- Category buttons container
    self.categoryContainer = luis.newFlexContainer(0, 0, 24, 3)
    self.categoryContainer:setDirection("row")
    self.categoryContainer:setJustifyContent("space-around")
    self.categoryContainer:setAlignItems("center")
    
    -- Create category buttons
    self.categoryButtons = {}
    for i, category in ipairs(self.categories) do
        local btn = luis.newButton(0, 0, 3, 2, category, function()
            self:selectCategory(category)
        end)
        self.categoryContainer:addChild(btn)
        self.categoryButtons[category] = btn
    end
    
    -- Sort buttons container
    self.sortContainer = luis.newFlexContainer(0, 0, 24, 2)
    self.sortContainer:setDirection("row")
    self.sortContainer:setJustifyContent("space-around")
    self.sortContainer:setAlignItems("center")
    
    self.sortByTypeButton = luis.newButton(0, 0, 7, 2, "By Type", function()
        self:setSortMethod("type")
    end)
    
    self.sortByNameButton = luis.newButton(0, 0, 7, 2, "By Name", function()
        self:setSortMethod("name")
    end)
    
    self.sortByValueButton = luis.newButton(0, 0, 7, 2, "By Value", function()
        self:setSortMethod("value")
    end)
    
    self.sortContainer:addChild(self.sortByTypeButton)
    self.sortContainer:addChild(self.sortByNameButton)
    self.sortContainer:addChild(self.sortByValueButton)
    
    -- Item list container
    self.itemListContainer = luis.newFlexContainer(0, 0, 24, 28)
    self.itemListContainer:setDirection("column")
    self.itemListContainer:setJustifyContent("flex-start")
    self.itemListContainer:setAlignItems("stretch")
    self.itemListContainer:setPadding(1, 1, 1, 1)
    
    -- Pagination container
    self.paginationContainer = luis.newFlexContainer(0, 0, 24, 2)
    self.paginationContainer:setDirection("row")
    self.paginationContainer:setJustifyContent("space-between")
    self.paginationContainer:setAlignItems("center")
    
    self.prevPageButton = luis.newButton(0, 0, 6, 2, "Previous", function()
        self:previousPage()
    end)
    
    self.pageInfoLabel = luis.newLabel(0, 0, 10, 2, "Page 1 of 1")
    
    self.nextPageButton = luis.newButton(0, 0, 6, 2, "Next", function()
        self:nextPage()
    end)
    
    self.paginationContainer:addChild(self.prevPageButton)
    self.paginationContainer:addChild(self.pageInfoLabel)
    self.paginationContainer:addChild(self.nextPageButton)
    
    -- Action buttons container
    self.actionContainer = luis.newFlexContainer(0, 0, 24, 3)
    self.actionContainer:setDirection("row")
    self.actionContainer:setJustifyContent("space-around")
    self.actionContainer:setAlignItems("center")
    
    self.useButton = luis.newButton(0, 0, 5, 2, "Use", function()
        self:useItem()
    end)
    
    self.equipButton = luis.newButton(0, 0, 5, 2, "Equip", function()
        self:equipItem()
    end)
    
    self.sellButton = luis.newButton(0, 0, 5, 2, "Sell", function()
        self:sellItem()
    end)
    
    self.dropButton = luis.newButton(0, 0, 5, 2, "Drop", function()
        self:dropItem()
    end)
    
    self.actionContainer:addChild(self.useButton)
    self.actionContainer:addChild(self.equipButton)
    self.actionContainer:addChild(self.sellButton)
    self.actionContainer:addChild(self.dropButton)
    
    self.rightColumn:addChild(self.categoryContainer)
    self.rightColumn:addChild(self.sortContainer)
    self.rightColumn:addChild(self.itemListContainer)
    self.rightColumn:addChild(self.paginationContainer)
    self.rightColumn:addChild(self.actionContainer)
    
    -- Bottom container - Back button
    self.bottomContainer = luis.newFlexContainer(1, 37, 62, 2)
    self.bottomContainer:setDirection("row")
    self.bottomContainer:setJustifyContent("flex-start")
    self.bottomContainer:setAlignItems("center")
    
    self.backButton = luis.newButton(0, 0, 8, 2, "Back", function()
        self:close()
    end)
    
    self.bottomContainer:addChild(self.backButton)
    
    -- Add all columns to main container
    self.mainContainer:addChild(self.leftColumn)
    self.mainContainer:addChild(self.middleColumn)
    self.mainContainer:addChild(self.rightColumn)
    
    -- Store item buttons for cleanup
    self.itemButtons = {}
    self.characterButtons = {}
end

function inventory:enter(params)
    -- Store where we came from
    self.openedFrom = params and params.from or "unknown"
    
    -- Create and show LUIS layer
    luis.setCurrentLayer(self.luisLayer)
    luis.insertElement(self.luisLayer, self.mainContainer)
    luis.insertElement(self.luisLayer, self.bottomContainer)
    
    -- Select first character by default
    if GAME.party and #GAME.party > 0 then
        self:selectCharacter(GAME.party[1])
    end
    
    -- Refresh UI
    self:refreshCharacterList()
    self:refreshItemList()
end

function inventory:exit()
    -- Clean up LUIS layer
    if luis.getLayer(self.luisLayer) then
        luis.clearLayer(self.luisLayer)
    end
    
    -- Clear selections
    self.selectedCharacter = nil
    self.selectedItem = nil
end

function inventory:refreshCharacterList()
    -- Clear existing character buttons
    for _, button in ipairs(self.characterButtons) do
        self.characterListContainer:removeChild(button)
    end
    self.characterButtons = {}
    
    -- Create character buttons
    if GAME.party and #GAME.party > 0 then
        for i, character in ipairs(GAME.party) do
            local charText = character.name .. "\n" .. character.job .. " Lv." .. (character.jobLevels[character.job] or 1)
            local btn = luis.newButton(0, 0, 16, 6, charText, function()
                self:selectCharacter(character)
            end)
            
            -- Highlight selected character
            if character == self.selectedCharacter then
                -- We'll need to implement highlighting through LUIS theming
            end
            
            self.characterListContainer:addChild(btn)
            table.insert(self.characterButtons, btn)
        end
    end
end

function inventory:refreshItemList()
    -- Clear existing item buttons
    for _, button in ipairs(self.itemButtons) do
        self.itemListContainer:removeChild(button)
    end
    self.itemButtons = {}
    
    -- Get filtered and sorted items
    local displayedItems = self:getDisplayedItems()
    
    -- Apply pagination
    local startIndex = self.pageOffset + 1
    local endIndex = math.min(startIndex + self.itemsPerPage - 1, #displayedItems)
    
    -- Create item buttons for current page
    for i = startIndex, endIndex do
        if displayedItems[i] then
            local item = displayedItems[i]
            local itemText = item.name
            
            -- Add count if stackable
            if item.count and item.count > 1 then
                itemText = itemText .. " x" .. item.count
            end
            
            -- Add equipped indicator
            if self.selectedCharacter and self:isItemEquipped(item, self.selectedCharacter) then
                itemText = itemText .. " [E]"
            end
            
            local btn = luis.newButton(0, 0, 22, 2, itemText, function()
                self:selectItem(item)
            end)
            
            self.itemListContainer:addChild(btn)
            table.insert(self.itemButtons, btn)
        end
    end
    
    -- Update pagination info
    local totalPages = math.ceil(#displayedItems / self.itemsPerPage)
    local currentPage = math.floor(self.pageOffset / self.itemsPerPage) + 1
    self.pageInfoLabel:setText("Page " .. currentPage .. " of " .. (totalPages > 0 and totalPages or 1))
    
    -- Update pagination button states
    self.prevPageButton:setEnabled(currentPage > 1)
    self.nextPageButton:setEnabled(currentPage < totalPages)
end

function inventory:getDisplayedItems()
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
                local aType = a.type or ""
                local bType = b.type or ""
                
                if aType == bType then
                    local aName = a.name or ""
                    local bName = b.name or ""
                    return aName < bName
                else
                    return self:getTypeOrder(aType) < self:getTypeOrder(bType)
                end
            end)
        elseif self.sortBy == "name" then
            table.sort(displayedItems, function(a, b)
                local aName = a.name or ""
                local bName = b.name or ""
                return aName < bName
            end)
        elseif self.sortBy == "value" then
            table.sort(displayedItems, function(a, b)
                local aValue = a.value or 0
                local bValue = b.value or 0
                return aValue > bValue
            end)
        end
    end
    
    return displayedItems
end

function inventory:selectCharacter(character)
    self.selectedCharacter = character
    
    -- Update character display
    if character then
        self.characterNameLabel:setText(character.name)
        
        -- Calculate total level
        local totalLevel = 0
        if character.jobLevels then
            for _, level in pairs(character.jobLevels) do
                totalLevel = totalLevel + level
            end
        end
        
        self.characterJobLabel:setText("Level " .. totalLevel .. " " .. character.job)
        
        -- Update equipment display
        local equipText = "Equipment:\n"
        equipText = equipText .. "Weapon: " .. (character.equipment.weapon and character.equipment.weapon.name or "None") .. "\n"
        equipText = equipText .. "Armor: " .. (character.equipment.body and character.equipment.body.name or "None") .. "\n"
        equipText = equipText .. "Offhand: " .. (character.equipment.offhand and character.equipment.offhand.name or "None") .. "\n"
        equipText = equipText .. "Amulet: " .. (character.equipment.amulet and character.equipment.amulet.name or "None") .. "\n"
        equipText = equipText .. "Ring: " .. (character.equipment.ring and character.equipment.ring.name or "None")
        
        self.characterEquipmentLabel:setText(equipText)
    end
    
    -- Refresh character and item lists to update highlighting
    self:refreshCharacterList()
    self:refreshItemList()
    
    assetManager:playSound("click")
end

function inventory:selectItem(item)
    self.selectedItem = item
    
    if item then
        self.itemNameLabel:setText(item.name)
        
        -- Build detailed item description
        local descText = (item.description or "No description available.") .. "\n\n"
        
        -- Add type-specific stats
        if item.type == "weapon" then
            descText = descText .. "Type: Weapon\n"
            if item.attack then
                descText = descText .. "Attack: " .. item.attack .. "\n"
            end
            if item.magicAttack then
                descText = descText .. "Magic Attack: " .. item.magicAttack .. "\n"
            end
        elseif item.type == "armor" then
            descText = descText .. "Type: Armor\n"
            if item.defense then
                descText = descText .. "Defense: " .. item.defense .. "\n"
            end
            if item.magicDefense then
                descText = descText .. "Magic Defense: " .. item.magicDefense .. "\n"
            end
        elseif item.type == "accessory" then
            descText = descText .. "Type: Accessory\n"
            if item.defense then
                descText = descText .. "Defense: " .. item.defense .. "\n"
            end
            if item.magicDefense then
                descText = descText .. "Magic Defense: " .. item.magicDefense .. "\n"
            end
            if item.attack then
                descText = descText .. "Attack: " .. item.attack .. "\n"
            end
            if item.magicAttack then
                descText = descText .. "Magic Attack: " .. item.magicAttack .. "\n"
            end
        elseif item.type == "consumable" then
            descText = descText .. "Type: Consumable\n"
            if item.effect then
                if item.effect.type == "heal" then
                    descText = descText .. "Restores " .. item.effect.amount .. " HP\n"
                elseif item.effect.type == "restore_mp" then
                    descText = descText .. "Restores " .. item.effect.amount .. " MP\n"
                elseif item.effect.type == "cure_status" then
                    descText = descText .. "Cures " .. item.effect.status .. " status\n"
                elseif item.effect.type == "full_restore" then
                    descText = descText .. "Fully restores HP and MP\n"
                end
            end
        elseif item.type == "material" or item.type == "monster_part" then
            descText = descText .. "Type: Material\nUsed for crafting\n"
        end
        
        -- Add value
        if item.value then
            descText = descText .. "\nValue: " .. item.value .. " gold"
        end
        
        -- Add requirements and job restrictions for equipment
        if item.type == "weapon" or item.type == "armor" or item.type == "accessory" then
            if item.requirements then
                descText = descText .. "\n\nRequirements:\n"
                for attr, value in pairs(item.requirements) do
                    descText = descText .. attr .. ": " .. value .. "\n"
                end
            end
            
            if item.jobs and #item.jobs > 0 then
                descText = descText .. "\nUsable by: " .. table.concat(item.jobs, ", ") .. "\n"
                
                if self.selectedCharacter then
                    local canEquip = false
                    for _, job in ipairs(item.jobs) do
                        if job == self.selectedCharacter.job then
                            canEquip = true
                            break
                        end
                    end
                    
                    if canEquip then
                        descText = descText .. "\nCan equip: Yes"
                    else
                        descText = descText .. "\nCan equip: No"
                    end
                end
            end
        end
        
        self.itemDescriptionLabel:setText(descText)
    end
    
    assetManager:playSound("click")
end

function inventory:selectCategory(category)
    self.selectedCategory = category
    self.pageOffset = 0 -- Reset to first page
    self:refreshItemList()
    assetManager:playSound("click")
end

function inventory:setSortMethod(method)
    self.sortBy = method
    self.pageOffset = 0 -- Reset to first page
    self:refreshItemList()
    assetManager:playSound("click")
end

function inventory:previousPage()
    if self.pageOffset > 0 then
        self.pageOffset = self.pageOffset - self.itemsPerPage
        self:refreshItemList()
        assetManager:playSound("click")
    end
end

function inventory:nextPage()
    local displayedItems = self:getDisplayedItems()
    local totalPages = math.ceil(#displayedItems / self.itemsPerPage)
    local currentPage = math.floor(self.pageOffset / self.itemsPerPage) + 1
    
    if currentPage < totalPages then
        self.pageOffset = self.pageOffset + self.itemsPerPage
        self:refreshItemList()
        assetManager:playSound("click")
    end
end

function inventory:draw()
    -- LUIS handles all drawing
end

function inventory:mousepressed(x, y, button, istouch, presses)
    -- LUIS handles all mouse input
    return false
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
end

function inventory:getTypeOrder(itemType)
    local order = {
        weapon = 1,
        armor = 2,
        accessory = 3,
        consumable = 4,
        material = 5,
        monster_part = 6
    }
    return order[itemType] or 999
end

function inventory:useItem()
    if not self.selectedItem then return end
    
    -- Only consumables can be used
    if self.selectedItem.type ~= "consumable" then
        return
    end
    
    -- Must have a character selected
    if not self.selectedCharacter then
        return
    end
    
    -- Use the item
    local success = itemSystem:useItem(self.selectedItem, self.selectedCharacter)
    
    if success then
        assetManager:playSound("pickup")
        
        -- Remove item from inventory or reduce count
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
        
        -- Refresh UI
        self:refreshItemList()
    else
        assetManager:playSound("hit")
    end
end

function inventory:equipItem()
    if not self.selectedItem then return end
    if not self.selectedCharacter then return end
    
    -- Only equipment can be equipped
    if self.selectedItem.type ~= "weapon" and 
       self.selectedItem.type ~= "armor" and 
       self.selectedItem.type ~= "accessory" then
        return
    end
    
    -- Try to equip the item
    local success = itemSystem:equipItem(self.selectedItem, self.selectedCharacter)
    
    if success then
        assetManager:playSound("pickup")
        
        -- Refresh UI to show equipment changes
        self:selectCharacter(self.selectedCharacter)
        self:refreshItemList()
    else
        assetManager:playSound("hit")
    end
end

function inventory:sellItem()
    if not self.selectedItem then return end
    
    -- Check if inventory was opened from overworld
    if self.openedFrom ~= "overworld" then
        return
    end
    
    -- Check if item is equipped by any character (only for equippable items)
    if self.selectedItem.type == "weapon" or self.selectedItem.type == "armor" or self.selectedItem.type == "accessory" then
        for _, character in ipairs(GAME.party) do
            if self:isItemEquipped(self.selectedItem, character) then
                return
            end
        end
    end
    
    -- Calculate sell price (typically 50% of buy value)
    local sellPrice = math.floor((self.selectedItem.value or 1) * 0.5)
    
    -- For stacked items, sell all for simplicity in LUIS version
    local quantity = self.selectedItem.count or 1
    local totalGold = sellPrice * quantity
    
    -- Add gold to player
    GAME.gold = (GAME.gold or 0) + totalGold
    
    -- Remove sold items from inventory
    for i, item in ipairs(GAME.inventory) do
        if item == self.selectedItem then
            table.remove(GAME.inventory, i)
            self.selectedItem = nil
            break
        end
    end
    
    -- Play coin sound
    assetManager:playSound("pickup")
    
    -- Refresh UI
    self:refreshItemList()
end

function inventory:dropItem()
    if not self.selectedItem then return end
    
    -- Check if item is equipped - only for equippable items
    local isEquipped = false
    if self.selectedItem.type == "weapon" or self.selectedItem.type == "armor" or self.selectedItem.type == "accessory" then
        for _, character in ipairs(GAME.party) do
            if self:isItemEquipped(self.selectedItem, character) then
                isEquipped = true
                break
            end
        end
    end
    
    if isEquipped then
        -- Cannot drop equipped items
        return
    end
    
    -- Remove item from inventory
    for i, item in ipairs(GAME.inventory) do
        if item == self.selectedItem then
            table.remove(GAME.inventory, i)
            self.selectedItem = nil
            break
        end
    end
    
    -- Play drop sound
    assetManager:playSound("hit")
    
    -- Refresh UI
    self:refreshItemList()
end

function inventory:close()
    self:exit()
    screenManager:popToScreen(self.openedFrom or "Overworld")
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
            -- For weapons and dual-wield characters, we'll show different equip options
            local characterSystem = require("gameplay/character")
            if self.selectedItem.type == "weapon" and characterSystem:canDualWield(self.selectedCharacter) then
                table.insert(options, {
                    text = "Equip...",
                    callback = function() self:equipItem() end,
                    hover = false
                })
            else
                table.insert(options, {
                    text = "Equip",
                    callback = function() self:equipItem() end,
                    hover = false
                })
            end
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
    
    -- Verify item has required properties
    if not self.selectedItem.name then
        error("Attempted to drop item without a name")
    end
    
    -- Check if item is equipped - only for equippable items
    local isEquipped = false
    if self.selectedItem.type == "weapon" or self.selectedItem.type == "armor" or self.selectedItem.type == "accessory" then
        for _, character in ipairs(GAME.party) do
            if self:isItemEquipped(self.selectedItem, character) then
                isEquipped = true
                break
            end
        end
    end
    
    if isEquipped then
        -- Cannot drop equipped items
        self:showFloatingMessage("Cannot drop equipped items!", {1, 0.3, 0.3, 1})
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
    -- LUIS handles most updates, but we may need some custom logic
end

function inventory:isItemEquipped(item, character)
    -- Immediately return false for non-equippable item types
    if item and (item.type == "monster_part" or item.type == "material" or item.type == "consumable") then
        return false
    end
    
    -- Check if item is equipped by character
    if not character or not character.equipment then
        return false
    end
    
    -- Check each equipment slot
    for slot, equippedItem in pairs(character.equipment) do
        -- Compare by uniqueId if available, otherwise fallback to reference comparison
        if equippedItem and item and 
           ((equippedItem.uniqueId and item.uniqueId and equippedItem.uniqueId == item.uniqueId) or
            equippedItem == item) then
            return true
        end
    end
    
    return false
end

return inventory
