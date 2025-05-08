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
    
    -- Create UI elements
    self:createUI()
end

function inventory:createUI()
    -- Define column widths and positions
    self.columnWidths = {
        characters = 250,  -- Width of character list column
        details = 280,     -- Width of character details column
        inventory = 500,   -- Width of inventory panel
    }
    
    -- Calculate X positions for columns
    self.columnX = {
        characters = 20,   -- Left margin
        details = 290,     -- Left margin + characters width + padding
        inventory = GAME.width - self.columnWidths.inventory - 20, -- Right aligned with margin
    }
    
    -- Create category buttons at the top of inventory column
    self.elements.categoryButtons = {}
    
    for i, category in ipairs(self.categories) do
        local buttonWidth = 75
        local totalWidth = #self.categories * buttonWidth
        local startX = self.columnX.inventory + (self.columnWidths.inventory - totalWidth) / 2
        
        self.elements.categoryButtons[i] = screenManager.UI.Button(
            startX + (i-1) * buttonWidth, 50, 
            buttonWidth - 5, 30, category, 
            function() self:selectCategory(category) end
        )
        self.elements.categoryButtons[i].visible = true
    end
    
    -- Create sort buttons below categories
    self.elements.sortButtons = {
        screenManager.UI.Button(
            self.columnX.inventory, 90, 
            150, 25, "Sort by Type", 
            function() self:setSortMethod("type") end
        ),
        screenManager.UI.Button(
            self.columnX.inventory + 160, 90, 
            150, 25, "Sort by Name", 
            function() self:setSortMethod("name") end
        ),
        screenManager.UI.Button(
            self.columnX.inventory + 320, 90, 
            150, 25, "Sort by Value", 
            function() self:setSortMethod("value") end
        )
    }
    
    -- Set visibility for sort buttons
    for _, button in ipairs(self.elements.sortButtons) do
        button.visible = true
    end

    -- Create character list panel (similar to characterInfo screen)
    self.elements.characterList = {
        x = self.columnX.characters,
        y = 90,
        width = self.columnWidths.characters,
        height = 500, -- Taller to fit stacked characters
        
        draw = function(self)
            if not GAME.party or #GAME.party == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.printf("No characters in party", self.x, self.y + 30, self.width, "center")
                return
            end
            
            -- Draw character slots stacked vertically
            local charHeight = 120 -- Height per character slot
            local padding = 10 -- Padding between character slots
            
            for i, character in ipairs(GAME.party) do
                local y = self.y + (i-1) * (charHeight + padding)
                
                -- Draw selection background if selected
                if character == inventory.selectedCharacter then
                    love.graphics.setColor(0.3, 0.3, 0.6)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle("fill", self.x, y, self.width, charHeight, 5, 5)
                
                -- Set up portrait area
                local portraitScale = 0.5
                local portraitX = self.x + 15
                local portraitY = y + 15
                local textX = portraitX + 100 -- Start text after portrait
                local barWidth = self.width - 130 -- Bar width adjusted for left column
                
                -- Draw character portrait
                love.graphics.setColor(1, 1, 1)
                if character.portraitId and assetManager.images.portraits[character.portraitId] then
                    love.graphics.draw(
                        assetManager.images.portraits[character.portraitId],
                        portraitX, portraitY,
                        0, portraitScale, portraitScale
                    )
                elseif assetManager.images.profiles[character.profileIndex] then
                    love.graphics.draw(
                        assetManager.images.profiles[character.profileIndex],
                        portraitX, portraitY,
                        0, portraitScale, portraitScale
                    )
                end
                
                -- Draw character name
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                
                local nameWidth = screenManager.fonts.small:getWidth(character.name)
                if nameWidth > barWidth then
                    -- Truncate name if too long
                    local truncName = ""
                    local j = 1
                    while screenManager.fonts.small:getWidth(truncName .. "...") < barWidth and j <= #character.name do
                        truncName = truncName .. character.name:sub(j, j)
                        j = j + 1
                    end
                    love.graphics.print(truncName .. "...", textX, y + 20)
                else
                    love.graphics.print(character.name, textX, y + 20)
                end
                
                -- Draw character job and level
                love.graphics.setColor(0.8, 0.8, 1)
                local jobText = character.job .. " Lv." .. (character.jobLevels[character.job] or 1)
                love.graphics.print(jobText, textX, y + 40)
                
                -- Draw HP/MP bars with spacing
                -- HP bar
                local healthWidth = barWidth * (character.currentHP / character.maxHP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", textX, y + 73, barWidth, 10)
                love.graphics.setColor(0.8, 0.2, 0.2)
                love.graphics.rectangle("fill", textX, y + 73, healthWidth, 10)
                
                -- HP values
                love.graphics.setColor(1, 0.7, 0.7)
                love.graphics.print(
                    character.currentHP .. "/" .. character.maxHP,
                    textX + barWidth - 60, y + 73 - 14
                )
                
                -- MP bar
                local manaWidth = barWidth * (character.currentMP / character.maxMP)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", textX, y + 95, barWidth, 10)
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", textX, y + 95, manaWidth, 10)
                
                -- MP values
                love.graphics.setColor(0.7, 0.7, 1)
                love.graphics.print(
                    character.currentMP .. "/" .. character.maxMP,
                    textX + barWidth - 60, y + 95 - 14
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            if not GAME.party or #GAME.party == 0 then return false end
            
            -- Check if click is within list
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Find which character was clicked
                local charHeight = 120
                local padding = 10
                
                for i, character in ipairs(GAME.party) do
                    local charY = self.y + (i-1) * (charHeight + padding)
                    
                    if y >= charY and y <= charY + charHeight then
                        inventory:selectCharacter(character)
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create character panel (middle column, top)
    self.elements.characterPanel = {
        x = self.columnX.details,
        y = 90,
        width = self.columnWidths.details,
        height = 250,
        
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
                
                -- Calculate character level as sum of job levels
                local totalLevel = 0
                if char.jobLevels then
                    for _, level in pairs(char.jobLevels) do
                        totalLevel = totalLevel + level
                    end
                end
                
                love.graphics.print(
                    "Level " .. totalLevel .. " " .. char.job,
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
                
                -- Draw accessory 1 slot
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print(
                    "Amulet:",
                    self.x + 30, self.y + 185
                )
                
                if char.equipment.amulet then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        char.equipment.amulet.name,
                        self.x + 110, self.y + 185
                    )
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print(
                        "None",
                        self.x + 110, self.y + 185
                    )
                end
                
                -- Draw accessory 2 slot
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print(
                    "Ring:",
                    self.x + 30, self.y + 205
                )
                
                if char.equipment.ring then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(
                        char.equipment.ring.name,
                        self.x + 110, self.y + 205
                    )
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print(
                        "None",
                        self.x + 110, self.y + 205
                    )
                end
            end
        end
    }
    
    -- Create item details panel (middle column, bottom)
    self.elements.itemDetailsPanel = {
        x = self.columnX.details,
        y = 350, -- Just below character panel
        width = self.columnWidths.details,
        height = 280,
        
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
                    item.name or "Unknown Item",
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
                    love.graphics.print("Value: " .. item.value .. " gold", self.x + 20, self.y + self.height - 20)
                end
                
                -- Draw requirements if the item is equipment
                if item.type == "weapon" or item.type == "armor" or item.type == "accessory" then
                    -- Draw a separator line
                    love.graphics.setColor(0.4, 0.4, 0.5)
                    love.graphics.line(
                        self.x + 20, self.y + 190, 
                        self.x + self.width - 20, self.y + 190
                    )
                    
                    -- Left column - Requirements
                    if item.requirements then
                        local reqX = self.x + 20
                        local reqY = self.y + 200
                        
                        love.graphics.setColor(1, 0.8, 0.2)
                        love.graphics.print("Requirements:", reqX, reqY)
                        reqY = reqY + 20
                        
                        -- List each requirement
                        love.graphics.setColor(0.9, 0.9, 0.9)
                        for attr, value in pairs(item.requirements) do
                            love.graphics.print(attr .. ": " .. value, reqX + 10, reqY)
                            reqY = reqY + 15
                        end
                    end
                    
                    -- Right column - Jobs
                    if item.jobs and #item.jobs > 0 then
                        local jobsX = self.x + (self.width / 2)
                        local jobsY = self.y + 200
                        
                        love.graphics.setColor(0.2, 0.8, 0.5)
                        love.graphics.print("Usable by:", jobsX, jobsY)
                        jobsY = jobsY + 20
                        
                        -- Format jobs list with more space
                        local jobsList = table.concat(item.jobs, ", ")
                        -- Allow for more text due to wider panel
                        if #jobsList > 40 then
                            jobsList = string.sub(jobsList, 1, 40) .. "..."
                        end
                        
                        love.graphics.setColor(0.8, 1, 0.8)
                        love.graphics.printf(jobsList, jobsX, jobsY, self.width/2 - 30, "left")
                        jobsY = jobsY + 25
                        
                        -- If inventory.selectedCharacter exists, indicate if they can use it
                        if inventory.selectedCharacter then
                            local canEquip = false
                            for _, job in ipairs(item.jobs) do
                                if job == inventory.selectedCharacter.job then
                                    canEquip = true
                                    break
                                end
                            end
                            
                            if canEquip then
                                love.graphics.setColor(0.2, 1, 0.2)
                                love.graphics.print("Can equip", jobsX, jobsY)
                            else
                                love.graphics.setColor(1, 0.2, 0.2)
                                love.graphics.print("Cannot equip", jobsX, jobsY)
                            end
                        end
                    end
                end
            end
        end
    }
    
    -- Create action buttons (keep these at the same position)
    self.elements.actionButtons = {
        useButton = screenManager.UI.Button(
            GAME.width - 280, GAME.height - 60, 
            80, 40, "Use", 
            function() inventory:useItem() end
        ),
        
        equipButton = screenManager.UI.Button(
            GAME.width - 280, GAME.height - 60, 
            80, 40, "Equip", 
            function() inventory:equipItem() end
        ),
        
        sellButton = screenManager.UI.Button(
            GAME.width - 190, GAME.height - 60, 
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
    
    -- Create context menu (keep as is)
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
    
    -- Create confirmation dialog (keep as is)
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
    
    -- Create quantity selector dialog (keep as is)
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
                love.graphics.printf(
                    self.item.name or "Unknown Item", 
                    self.x + 20, self.y + 20, 
                    self.width - 40, "center"
                )
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
                    self.x + 20, self.y + 170, self.width - 40, "center"
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
    
    -- Create hand selection dialog for dual-wield (keep as is)
    self.elements.handSelector = {
        x = GAME.width / 2 - 150,
        y = GAME.height / 2 - 100,
        width = 300,
        height = 180,
        message = "",
        item = nil,
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
            
            -- Draw item name and message
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            if self.item then
                love.graphics.printf(
                    self.item.name or "Unknown Item", 
                    self.x + 20, self.y + 20, 
                    self.width - 40, "center"
                )
            end
            
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.printf(self.message, self.x + 20, self.y + 50, self.width - 40, "center")
            
            -- Draw main hand button
            love.graphics.setColor(0.3, 0.6, 0.3)
            love.graphics.rectangle("fill", self.x + 40, self.y + 80, 100, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.printf("Main Hand", self.x + 40, self.y + 92, 100, "center")
            
            -- Draw off-hand button
            love.graphics.setColor(0.6, 0.3, 0.3)
            love.graphics.rectangle("fill", self.x + self.width - 140, self.y + 80, 100, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Off Hand", self.x + self.width - 140, self.y + 92, 100, "center")
            
            -- Draw cancel button
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("fill", self.x + self.width/2 - 50, self.y + self.height - 50, 100, 30, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Cancel", self.x + self.width/2 - 50, self.y + self.height - 42, 100, "center")
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Main hand button
            if x >= self.x + 40 and x <= self.x + 140 and
               y >= self.y + 80 and y <= self.y + 120 then
                if self.confirmCallback then
                    self.confirmCallback("weapon")
                end
                self.visible = false
                assetManager:playSound("click")
                return true
            end
            
            -- Off-hand button
            if x >= self.x + self.width - 140 and x <= self.x + self.width - 40 and
               y >= self.y + 80 and y <= self.y + 120 then
                if self.confirmCallback then
                    self.confirmCallback("offhand")
                end
                self.visible = false
                assetManager:playSound("click")
                return true
            end
            
            -- Cancel button
            if x >= self.x + self.width/2 - 50 and x <= self.x + self.width/2 + 50 and
               y >= self.y + self.height - 50 and y <= self.y + self.height - 20 then
                if self.cancelCallback then
                    self.cancelCallback()
                end
                self.visible = false
                assetManager:playSound("click")
                return true
            end
            
            return true
        end,
        
        show = function(self, item, message, callback, cancelCallback)
            self.item = item
            self.message = message or "Select hand to equip:"
            self.confirmCallback = callback
            self.cancelCallback = cancelCallback
            self.visible = true
        end
    }
    
    -- Create item list panel (right column)
    self.elements.itemListPanel = {
        x = self.columnX.inventory,
        y = 130,
        width = self.columnWidths.inventory,
        height = GAME.height - 210, -- Make taller, leaving space for buttons
        
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
                        -- Check if types exist, default to empty string if nil
                        local aType = a.type or ""
                        local bType = b.type or ""
                        
                        if aType == bType then
                            -- Check if names exist, default to empty string if nil
                            local aName = a.name or ""
                            local bName = b.name or ""
                            return aName < bName
                        else
                            return inventory:getTypeOrder(aType) < inventory:getTypeOrder(bType)
                        end
                    end)
                elseif inventory.sortBy == "name" then
                    table.sort(displayedItems, function(a, b)
                        -- Check if names exist, default to empty string if nil
                        local aName = a.name or ""
                        local bName = b.name or ""
                        return aName < bName
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
                        item.name or "Unknown Item",
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
                            -- Check if types exist, default to empty string if nil
                            local aType = a.type or ""
                            local bType = b.type or ""
                            
                            if aType == bType then
                                -- Check if names exist, default to empty string if nil
                                local aName = a.name or ""
                                local bName = b.name or ""
                                return aName < bName
                            else
                                return inventory:getTypeOrder(aType) < inventory:getTypeOrder(bType)
                            end
                        end)
                    elseif inventory.sortBy == "name" then
                        table.sort(displayedItems, function(a, b)
                            -- Check if names exist, default to empty string if nil
                            local aName = a.name or ""
                            local bName = b.name or ""
                            return aName < bName
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
end

function inventory:enter(params)
    -- Initialize state
    self.state = "main"
    self.selectedItem = nil
    self.pageOffset = 0
    
    -- Track which state opened the inventory
    local gameState = require("states/gameState")
    self.openedFrom = params and params.from or gameState:getCurrentStateName()
    
    -- Select first character if available
    if GAME.party and #GAME.party > 0 then
        self.selectedCharacter = GAME.party[1]
    else
        self.selectedCharacter = nil
    end
    
    -- Verify inventory items have necessary fields
    if GAME.inventory then
        for i, item in ipairs(GAME.inventory) do
            -- Ensure all items have at least basic properties
            if not item.name then item.name = "Unknown Item" end
            if not item.type then item.type = "material" end
            if not item.uniqueId then 
                item.uniqueId = itemSystem:generateUniqueId()
            end
            
            -- Clean up any non-equippable items that might have equippedBy or equippedSlot properties
            if item.type == "monster_part" or item.type == "material" or item.type == "consumable" then
                if item.equippedBy or item.equippedSlot then
                    -- Remove incorrect equipped properties
                    item.equippedBy = nil
                    item.equippedSlot = nil
                    
                    if GAME.debug then
                        print("Cleaned up incorrectly marked equipped status on " .. item.name)
                    end
                end
            end
        end
    end
    
    -- Adjust UI layout
    self:adjustLayout()
    
    -- Enter the screen
    enter = function(self, params)
        -- Store where we came from
        self.openedFrom = params and params.from or nil
        
        -- Load character data from GAME state
        if GAME and GAME.party then
            -- Create character tabs
            self.elements.charTabs = {}
            
            for i, character in ipairs(GAME.party) do
                local tab = self:createCharacterTab(character, i)
                table.insert(self.elements.charTabs, tab)
            end
            
            -- Set first character as selected if none is already selected
            if not self.selectedCharacter and #GAME.party > 0 then
                self.selectedCharacter = GAME.party[1].name
                self.elements.charTabs[1].active = true
            end
        end
        
        -- Update inventory list
        self:updateInventoryList()
    end
end

-- Adjust UI panel sizes and positions
function inventory:adjustLayout()
    -- Calculate column positions based on screen size
    self.columnWidths = {
        characters = 250,  -- Width of character list column
        details = 280,     -- Width of character details column
        inventory = 500,   -- Width of inventory panel
    }
    
    -- Calculate X positions for columns
    self.columnX = {
        characters = 20,   -- Left margin
        details = 290,     -- Left margin + characters width + padding
        inventory = GAME.width - self.columnWidths.inventory - 20, -- Right aligned with margin
    }
    
    -- Update panel positions
    if self.elements then
        -- Character list (left column)
        if self.elements.characterList then
            self.elements.characterList.x = self.columnX.characters
            self.elements.characterList.width = self.columnWidths.characters
        end
        
        -- Character panel (middle column, top)
        if self.elements.characterPanel then
            self.elements.characterPanel.x = self.columnX.details
            self.elements.characterPanel.width = self.columnWidths.details
        end
        
        -- Item details panel (middle column, bottom)
        if self.elements.itemDetailsPanel then
            self.elements.itemDetailsPanel.x = self.columnX.details
            self.elements.itemDetailsPanel.width = self.columnWidths.details
        end
        
        -- Inventory panel (right column)
        if self.elements.itemListPanel then
            self.elements.itemListPanel.x = self.columnX.inventory
            self.elements.itemListPanel.width = self.columnWidths.inventory
            self.elements.itemListPanel.height = GAME.height - 210 -- Taller panel
        end
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
    
    -- Draw main panels
    self.elements.characterList:draw()     -- Left column
    self.elements.characterPanel:draw()    -- Middle column, top
    self.elements.itemDetailsPanel:draw()  -- Middle column, bottom
    self.elements.itemListPanel:draw()     -- Right column
    
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
    
    -- Draw hand selector if visible
    if self.elements.handSelector.visible then
        self.elements.handSelector:draw()
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
    
    -- Check if hand selector is visible first
    if self.elements.handSelector.visible then
        self.elements.handSelector:clicked(x, y, button)
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
        -- Check if click is within item list panel
        if x >= self.elements.itemListPanel.x and 
           x <= self.elements.itemListPanel.x + self.elements.itemListPanel.width and
           y >= self.elements.itemListPanel.y and 
           y <= self.elements.itemListPanel.y + self.elements.itemListPanel.height then
            
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
                        -- Check if types exist, default to empty string if nil
                        local aType = a.type or ""
                        local bType = b.type or ""
                        
                        if aType == bType then
                            -- Check if names exist, default to empty string if nil
                            local aName = a.name or ""
                            local bName = b.name or ""
                            return aName < bName
                        else
                            return self:getTypeOrder(aType) < self:getTypeOrder(bType)
                        end
                    end)
                elseif self.sortBy == "name" then
                    table.sort(displayedItems, function(a, b)
                        -- Check if names exist, default to empty string if nil
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
                
                -- Apply pagination
                local startIndex = self.pageOffset + 1
                local endIndex = math.min(startIndex + self.itemsPerPage - 1, #displayedItems)
                
                for i = startIndex, endIndex do
                    local itemY = self.elements.itemListPanel.y + 50 + (i - startIndex) * 30
                    
                    if y >= itemY and y <= itemY + 25 then
                        -- Select item and show context menu
                        self:selectItem(displayedItems[i])
                        self:showContextMenu(x, y)
                        return true
                    end
                end
            end
        end
        
        return false
    end
    
    -- Flag to track if click was handled
    local clickHandled = false
    
    -- Pass to character list
    if self.elements.characterList:clicked(x, y, button) then
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
            -- Fix: Check if name exists before using it in print
            local itemName = self.selectedItem.name or "Unknown Item"
            print("Checking action buttons. Selected item: " .. itemName)
            if self.selectedCharacter then
                local charName = self.selectedCharacter.name or "Unknown Character"
                print("Selected character: " .. charName)
            else
                print("No character selected")
            end
        end
        
        -- Check use button for consumables
        if self.selectedItem.type == "consumable" and
           self.elements.actionButtons.useButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
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
            self:equipItem()
            clickHandled = true
        -- Check sell button - only available if opened from overworld
        elseif self.openedFrom == "overworld" and
               self.elements.actionButtons.sellButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
            self:sellItem()
            clickHandled = true
        -- Check drop button
        elseif self.elements.actionButtons.dropButton:clicked(x, y, button) then
            -- Play click sound
            assetManager:playSound("click")
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
end

function inventory:getTypeOrder(type)
    if not type then
        return 99  -- Place items with nil type at the end
    elseif type == "weapon" then
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
        local charName = character and character.name or "Unknown Character"
        print("Selecting character: " .. charName)
    end
    
    -- Select character
    self.selectedCharacter = character
    
    -- Play sound
    assetManager:playSound("click")
    
    -- Show feedback
    local charName = character and character.name or "Unknown Character"
    self:showFloatingMessage(charName .. " selected", {0.3, 0.7, 1, 1})
end

function inventory:selectItem(item)
    -- Select item
    self.selectedItem = item
    self.elements.contextMenu.visible = false
end

function inventory:isItemEquipped(item, character)
    -- Immediately return false for non-equippable item types
    if item and (item.type == "monster_part" or item.type == "material" or item.type == "consumable") then
        return false
    end
    
    -- Quick check if item has the equipped properties
    if item and item.equippedBy and item.equippedSlot and character then
        -- Check if this item is equipped by this character
        if item.equippedBy == character.name then
            return true
        end
    end

    -- Check if item is equipped by character
    if not character or not character.equipment then
        return false
    end
    
    -- Debug output
    if GAME.debug then
        local itemName = item and item.name or "Unknown Item"
        local itemId = item and item.uniqueId or "No ID"
        local charName = character and character.name or "Unknown Character"
        print("Checking if item " .. itemName .. " (ID: " .. itemId .. ") is equipped by " .. charName)
        
        -- Print character's equipment
        for slot, equippedItem in pairs(character.equipment) do
            if equippedItem then
                local equippedId = equippedItem.uniqueId or "No ID"
                print("Slot " .. slot .. ": " .. (equippedItem.name or "unknown") .. " (ID: " .. equippedId .. ")")
            end
        end
    end
    
    -- Check each equipment slot
    for slot, equippedItem in pairs(character.equipment) do
        -- Compare by uniqueId if available, otherwise fallback to reference comparison
        if equippedItem and item and 
           ((equippedItem.uniqueId and item.uniqueId and equippedItem.uniqueId == item.uniqueId) or
            equippedItem == item) then
            if GAME.debug then
                print("Item is equipped in slot: " .. slot)
            end
            return true
        end
    end
    
    -- Special check for amulet and ring slots since they're new
    if character.equipment.amulet and item and
       ((character.equipment.amulet.uniqueId and item.uniqueId and character.equipment.amulet.uniqueId == item.uniqueId) or
        character.equipment.amulet == item) then
        return true
    end
    
    if character.equipment.ring and item and
       ((character.equipment.ring.uniqueId and item.uniqueId and character.equipment.ring.uniqueId == item.uniqueId) or
        character.equipment.ring == item) then
        return true
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
    
    -- Check if item is already equipped by the selected character
    if self:isItemEquipped(self.selectedItem, self.selectedCharacter) then
        self:showFloatingMessage("This item is already equipped!", {1, 0.5, 0.5, 1})
        assetManager:playSound("hit")
        return
    end
    
    -- Check if item is equipped by another character
    for _, character in ipairs(GAME.party) do
        if character ~= self.selectedCharacter and self:isItemEquipped(self.selectedItem, character) then
            self:showFloatingMessage("This item is equipped by " .. character.name .. "!", {1, 0.5, 0.5, 1})
            assetManager:playSound("hit")
            return
        end
    end
    
    -- Debug output
    if GAME.debug then
        local itemName = self.selectedItem.name or "Unknown Item"
        local charName = self.selectedCharacter.name or "Unknown Character"
        print("Equipping " .. itemName .. " to " .. charName)
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
        -- Make sure character has attributes table
        if not self.selectedCharacter.attributes then
            self.selectedCharacter.attributes = {}
        end
        
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
    
    -- Special case for weapons - if character can dual-wield, show hand selection
    local characterSystem = require("gameplay/character")
    if self.selectedItem.type == "weapon" and characterSystem:canDualWield(self.selectedCharacter) then
        -- Show hand selector dialog
        self.elements.handSelector:show(
            self.selectedItem,
            "Choose which hand to equip this weapon:",
            function(slot)
                self:completeEquip(slot)
            end,
            function()
                -- Cancel callback
            end
        )
    else
        -- For other item types or characters that can't dual-wield,
        -- determine equipment slot automatically
        local slot = nil
        
        if self.selectedItem.type == "weapon" then
            slot = "weapon"
        elseif self.selectedItem.type == "armor" then
            slot = "body"
        elseif self.selectedItem.type == "accessory" then
            -- Find first empty accessory slot or use the first one
            if self.selectedItem.slot == "amulet" then
                slot = "amulet"
            elseif self.selectedItem.slot == "ring" then
                slot = "ring"
            elseif self.selectedItem.slot == "offhand" then
                slot = "offhand"
            else
                -- Legacy accessory items with no specific slot
                if not self.selectedCharacter.equipment.amulet then
                    slot = "amulet"
                elseif not self.selectedCharacter.equipment.ring then
                    slot = "ring"
                else
                    slot = "amulet" -- Replace the amulet if both are filled
                end
            end
        end
        
        if slot then
            self:completeEquip(slot)
        end
    end
end

-- Helper function to complete equipping an item after slot selection
function inventory:completeEquip(slot)
    if not self.selectedItem or not self.selectedCharacter then
        return
    end
    
    -- Initialize equipment if not exists
    if not self.selectedCharacter.equipment then
        self.selectedCharacter.equipment = {}
    end
    
    -- Make sure character has attributes table
    if not self.selectedCharacter.attributes then
        self.selectedCharacter.attributes = {}
    end
    
    -- Unequip previous item if exists
    local prevItem = self.selectedCharacter.equipment[slot]
    
    -- Remove stat bonuses from previous item if it exists
    if prevItem then
        -- Remove attack/defense bonuses
        if prevItem.attack then
            -- Initialize attack stat if it doesn't exist
            if self.selectedCharacter.attack == nil then
                self.selectedCharacter.attack = prevItem.attack  -- Set to exactly the bonus amount so subtraction will result in 0
            end
            self.selectedCharacter.attack = self.selectedCharacter.attack - prevItem.attack
        end
        if prevItem.magicAttack then
            -- Initialize magicAttack stat if it doesn't exist
            if self.selectedCharacter.magicAttack == nil then
                self.selectedCharacter.magicAttack = prevItem.magicAttack
            end
            self.selectedCharacter.magicAttack = self.selectedCharacter.magicAttack - prevItem.magicAttack
        end
        if prevItem.defense then
            -- Initialize defense stat if it doesn't exist
            if self.selectedCharacter.defense == nil then
                self.selectedCharacter.defense = prevItem.defense
            end
            self.selectedCharacter.defense = self.selectedCharacter.defense - prevItem.defense
        end
        if prevItem.magicDefense then
            -- Initialize magicDefense stat if it doesn't exist
            if self.selectedCharacter.magicDefense == nil then
                self.selectedCharacter.magicDefense = prevItem.magicDefense
            end
            self.selectedCharacter.magicDefense = self.selectedCharacter.magicDefense - prevItem.magicDefense
        end
        
        -- Remove attribute bonuses if any
        if prevItem.attributes then
            for attr, bonus in pairs(prevItem.attributes) do
                if self.selectedCharacter.attributes then
                    if self.selectedCharacter.attributes[attr] == nil then
                        self.selectedCharacter.attributes[attr] = bonus
                    end
                    self.selectedCharacter.attributes[attr] = self.selectedCharacter.attributes[attr] - bonus
                end
            end
        end
    end
    
    -- Equip new item
    self.selectedCharacter.equipment[slot] = self.selectedItem
    
    -- Ensure the item's slot property matches where it's equipped
    if slot == "amulet" or slot == "ring" then
        self.selectedItem.slot = slot
    end
    
    -- Add stat bonuses from new item
    if self.selectedItem.attack then
        -- Initialize attack stat if it doesn't exist
        if self.selectedCharacter.attack == nil then
            self.selectedCharacter.attack = 0
        end
        self.selectedCharacter.attack = self.selectedCharacter.attack + self.selectedItem.attack
    end
    if self.selectedItem.magicAttack then
        -- Initialize magicAttack stat if it doesn't exist
        if self.selectedCharacter.magicAttack == nil then
            self.selectedCharacter.magicAttack = 0
        end
        self.selectedCharacter.magicAttack = self.selectedCharacter.magicAttack + self.selectedItem.magicAttack
    end
    if self.selectedItem.defense then
        -- Initialize defense stat if it doesn't exist
        if self.selectedCharacter.defense == nil then
            self.selectedCharacter.defense = 0
        end
        self.selectedCharacter.defense = self.selectedCharacter.defense + self.selectedItem.defense
    end
    if self.selectedItem.magicDefense then
        -- Initialize magicDefense stat if it doesn't exist
        if self.selectedCharacter.magicDefense == nil then
            self.selectedCharacter.magicDefense = 0
        end
        self.selectedCharacter.magicDefense = self.selectedCharacter.magicDefense + self.selectedItem.magicDefense
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
    local itemName = self.selectedItem.name or "Unknown Item"
    self:showFloatingMessage(itemName .. " equipped!", {0.2, 1, 0.2, 1})
    
    -- Mark the item as equipped but do NOT remove it from inventory
    -- This is important for rings and amulets to be visible in the inventory
    -- and to properly track equipped status
    self.selectedItem.equippedBy = self.selectedCharacter.name
    self.selectedItem.equippedSlot = slot
    
    -- Add unequipped item to inventory if exists
    if prevItem then
        -- Clear equipped status on the previous item
        prevItem.equippedBy = nil
        prevItem.equippedSlot = nil
        
        -- If the previous item isn't already in inventory, add it
        local prevItemInInventory = false
        for _, invItem in ipairs(GAME.inventory) do
            if prevItem.uniqueId and invItem.uniqueId and prevItem.uniqueId == invItem.uniqueId then
                prevItemInInventory = true
                break
            end
        end
        
        if not prevItemInInventory then
            table.insert(GAME.inventory, prevItem)
        end
    end
    
    -- Refresh selected item
    self.selectedItem = nil
end

function inventory:dropItem()
    if not self.selectedItem then
        return
    end
    
    -- Check if item is equipped - only needed for equippable items
    if self.selectedItem.type == "weapon" or self.selectedItem.type == "armor" or self.selectedItem.type == "accessory" then
        for _, character in ipairs(GAME.party) do
            if self:isItemEquipped(self.selectedItem, character) then
                -- Show error message and play error sound
                self:showFloatingMessage("Cannot drop equipped items!", {1, 0.3, 0.3, 1})
                assetManager:playSound("hit")
                return
            end
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
    local itemName = self.selectedItem.name or "Unknown Item"
    dialog.message = "Are you sure you want to drop " .. itemName .. "?\nThis item will be permanently destroyed."
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
    
    -- Check if item is equipped by any character (only for equippable items)
    if self.selectedItem.type == "weapon" or self.selectedItem.type == "armor" or self.selectedItem.type == "accessory" then
        for _, character in ipairs(GAME.party) do
            if self:isItemEquipped(self.selectedItem, character) then
                self:showFloatingMessage("You can't sell equipped items!", {1, 0.3, 0.3, 1})
                return
            end
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
        local itemName = self.selectedItem.name or "Unknown Item"
        self.elements.confirmDialog.message = "Sell " .. itemName .. " to the " .. sellLocation .. " for " .. sellPrice .. " gold?"
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
    local itemName = self.selectedItem.name or "Unknown Item"
    self:showFloatingMessage("Sold " .. quantity .. " " .. itemName .. " for " .. totalGold .. " gold!", {1, 1, 0, 1})
    
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
        elseif self.elements.handSelector.visible then
            self.elements.handSelector.visible = false
            if self.elements.handSelector.cancelCallback then
                self.elements.handSelector.cancelCallback()
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
