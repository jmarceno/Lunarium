-- Smith Screen
-- Where players can craft items from monster parts
local screenManager = require("screens/screenManager")
local assetManager = require("assets/assetManager")
local itemSystem = require("gameplay/item")
local partyPanel = require("screens/ui_slices/partyPanel")
local smithRecipes = require("gameplay/smithRecipes_definitions")

local smith = screenManager:createScreen("Smith")

function smith:init()
    -- Initialize state
    self.state = "main" -- main, recipe_details, craft_result
    self.recipes = {}
    self.selectedRecipe = nil
    self.craftedItem = nil
    self.selectedCategory = "All"
    self.pageOffset = 0
    self.recipesPerPage = 5
    
    -- Categories
    self.categories = {
        "All",
        "Weapons",
        "Armor",
        "Accessories"
    }
    
    -- Create recipes
    self:createRecipes()
    
    -- Create UI elements
    self:createUI()
end

function smith:createRecipes()
    -- Use recipes from the imported file
    self.recipes = smithRecipes
    
    -- Sort recipes by category then by gold cost
    table.sort(self.recipes, function(a, b)
        if a.category == b.category then
            return a.goldCost < b.goldCost
        else
            return self:getCategoryOrder(a.category) < self:getCategoryOrder(b.category)
        end
    end)
end

function smith:createUI()
    if not screenManager.UI then
        screenManager:init()  -- Ensure UI is initialized
    end

    -- Create category buttons
    self.elements.categoryButtons = {}
    
    for i, category in ipairs(self.categories) do
        self.elements.categoryButtons[i] = screenManager.UI.Button(
            50 + (i-1) * 180, 70, 
            160, 30, category, 
            function() self:selectCategory(category) end
        )
        self.elements.categoryButtons[i].visible = true
    end
    
    -- Create recipe list panel
    self.elements.recipeListPanel = {
        x = 100,
        y = 50,
        width = GAME.width - 200,
        height = GAME.height - 200,
        
        draw = function(self)
            -- Draw panel background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw screen title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("Blacksmith", self.x, self.y + 20, self.width, "center")
            
            -- Draw current gold
            if GAME.gold then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Gold: " .. GAME.gold,
                    self.x + 50, self.y + 70
                )
            end
            
            -- Draw category buttons
            local categoryY = self.y + 100
            local btnWidth = 160
            local spacing = 10
            local totalWidth = btnWidth * #smith.categories + spacing * (#smith.categories - 1)
            local startX = self.x + (self.width - totalWidth) / 2
            
            for i, category in ipairs(smith.categories) do
                local btnX = startX + (i-1) * (btnWidth + spacing)
                
                -- Draw button background
                if category == smith.selectedCategory then
                    love.graphics.setColor(0.3, 0.4, 0.6)
                else
                    love.graphics.setColor(0.2, 0.3, 0.4)
                end
                
                love.graphics.rectangle("fill", btnX, categoryY, btnWidth, 30, 5, 5)
                
                -- Draw button text
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(category, btnX, categoryY + 7, btnWidth, "center")
            end
            
            -- Draw "Available Recipes" section label
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.printf("Available Recipes", self.x, self.y + 140, self.width, "center")
            
            -- Draw divider line
            love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
            love.graphics.line(
                self.x + 50, self.y + 170, 
                self.x + self.width - 55, self.y + 170
            )
            
            -- Draw recipes
            local recipeCount = 0
            local displayedRecipes = {}
            
            -- Filter recipes by category
            for _, recipe in ipairs(smith.recipes) do
                if smith.selectedCategory == "All" or recipe.category == smith.selectedCategory then
                    table.insert(displayedRecipes, recipe)
                end
            end
            
            -- Apply pagination
            local startIndex = smith.pageOffset + 1
            local endIndex = math.min(startIndex + smith.recipesPerPage - 1, #displayedRecipes)
            
            -- Draw visible recipes
            for i = startIndex, endIndex do
                local recipe = displayedRecipes[i]
                local recipeY = self.y + 180 + (i - startIndex) * 60
                
                -- Draw recipe entry background
                if recipe == smith.selectedRecipe then
                    love.graphics.setColor(0.3, 0.3, 0.5)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3)
                end
                
                love.graphics.rectangle(
                    "fill",
                    self.x + 20, recipeY, 
                    self.width - 45, 55,
                    5, 5
                )
                
                -- Draw recipe name
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 1)
                
                love.graphics.print(
                    recipe.name,
                    self.x + 40, recipeY + 7
                )
                
                -- Draw recipe category
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.7, 0.7, 1)
                
                love.graphics.print(
                    recipe.category,
                    self.x + 40, recipeY + 35
                )
                
                -- Draw recipe gold cost
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    recipe.goldCost .. " gold",
                    self.x + self.width - 150, recipeY + 7
                )
                
                -- Check if player has enough materials
                local hasIngredients = true
                
                if GAME.inventory then
                    local inventoryMaterials = {}
                    
                    -- Count materials in inventory
                    for _, item in ipairs(GAME.inventory) do
                        if item.type == "material" or item.type == "monster_part" then
                            inventoryMaterials[item.name] = (inventoryMaterials[item.name] or 0) + (item.count or 1)
                        end
                    end
                    
                    -- Check each required material
                    for material, count in pairs(recipe.materials) do
                        if not inventoryMaterials[material] or inventoryMaterials[material] < count then
                            hasIngredients = false
                            break
                        end
                    end
                else
                    hasIngredients = false
                end
                
                -- Draw availability indicator
                if not hasIngredients then
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.8, 0.2, 0.2)
                    
                    love.graphics.print(
                        "Missing materials",
                        self.x + self.width - 180, recipeY + 35
                    )
                else
                    love.graphics.setFont(screenManager.fonts.small)
                    love.graphics.setColor(0.2, 0.8, 0.2)
                    
                    love.graphics.print(
                        "Available",
                        self.x + self.width - 180, recipeY + 35
                    )
                end
            end
            
            -- Draw pagination info
            love.graphics.setFont(screenManager.fonts.small)
            love.graphics.setColor(0.7, 0.7, 0.7)
            
            local totalPages = math.ceil(#displayedRecipes / smith.recipesPerPage)
            local currentPage = math.floor(smith.pageOffset / smith.recipesPerPage) + 1
            
            love.graphics.print(
                "Page " .. currentPage .. " of " .. totalPages,
                self.x + self.width / 2 - 40, self.y + self.height - 29
            )
            
            -- Draw pagination buttons
            if currentPage > 1 then
                -- Draw prev button
                love.graphics.setColor(0.3, 0.3, 0.5)
                love.graphics.rectangle(
                    "fill",
                    self.x + 20, self.y + self.height - 44, 
                    100, 25,
                    5, 5
                )
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "Previous",
                    self.x + 40, self.y + self.height - 41
                )
            end
            
            if currentPage < totalPages then
                -- Draw next button
                love.graphics.setColor(0.3, 0.3, 0.5)
                love.graphics.rectangle(
                    "fill",
                    self.x + self.width - 120, self.y + self.height - 44, 
                    100, 25,
                    5, 5
                )
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "Next",
                    self.x + self.width - 100, self.y + self.height - 41
                )
            end
            
            -- Draw message if no recipes
            if #displayedRecipes == 0 then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(0.7, 0.7, 0.7)
                
                love.graphics.printf(
                    "No recipes available in this category.",
                    self.x + 40, self.y + 250,
                    self.width - 85, "center"
                )
            end
        end,
        
        clicked = function(self, x, y, button)
            if button ~= 1 then return false end
            
            -- Check if click is within panel
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                
                -- Check category buttons
                local categoryY = self.y + 100
                local btnWidth = 160
                local spacing = 10
                local totalWidth = btnWidth * #smith.categories + spacing * (#smith.categories - 1)
                local startX = self.x + (self.width - totalWidth) / 2
                
                for i, category in ipairs(smith.categories) do
                    local btnX = startX + (i-1) * (btnWidth + spacing)
                    
                    if x >= btnX and x <= btnX + btnWidth and
                       y >= categoryY and y <= categoryY + 30 then
                        smith:selectCategory(category)
                        return true
                    end
                end
                
                -- Check pagination buttons
                if y >= self.y + self.height - 44 and y <= self.y + self.height - 19 then
                    -- Filter recipes by category
                    local displayedRecipes = {}
                    for _, recipe in ipairs(smith.recipes) do
                        if smith.selectedCategory == "All" or recipe.category == smith.selectedCategory then
                            table.insert(displayedRecipes, recipe)
                        end
                    end
                    
                    local totalPages = math.ceil(#displayedRecipes / smith.recipesPerPage)
                    local currentPage = math.floor(smith.pageOffset / smith.recipesPerPage) + 1
                    
                    -- Prev button
                    if x >= self.x + 20 and x <= self.x + 120 and currentPage > 1 then
                        smith.pageOffset = smith.pageOffset - smith.recipesPerPage
                        return true
                    end
                    
                    -- Next button
                    if x >= self.x + self.width - 120 and x <= self.x + self.width - 20 and currentPage < totalPages then
                        smith.pageOffset = smith.pageOffset + smith.recipesPerPage
                        return true
                    end
                end
                
                -- Check recipe entries
                local displayedRecipes = {}
                
                -- Filter recipes by category
                for _, recipe in ipairs(smith.recipes) do
                    if smith.selectedCategory == "All" or recipe.category == smith.selectedCategory then
                        table.insert(displayedRecipes, recipe)
                    end
                end
                
                -- Apply pagination
                local startIndex = smith.pageOffset + 1
                local endIndex = math.min(startIndex + smith.recipesPerPage - 1, #displayedRecipes)
                
                for i = startIndex, endIndex do
                    local recipeY = self.y + 180 + (i - startIndex) * 60
                    
                    if y >= recipeY and y <= recipeY + 55 then
                        smith:selectRecipe(displayedRecipes[i])
                        return true
                    end
                end
                
                return true
            end
            
            return false
        end
    }
    
    -- Create recipe details panel
    self.elements.recipeDetailsPanel = {
        x = 100,
        y = 50,
        width = GAME.width - 200,
        height = GAME.height - 200,
        visible = false,
        
        draw = function(self)
            if not self.visible or not smith.selectedRecipe then
                return
            end
            
            local recipe = smith.selectedRecipe
            
            -- Draw panel background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
            
            -- Draw screen title
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 0.9, 0.7)
            love.graphics.printf("Blacksmith", self.x, self.y + 20, self.width, "center")
            
            -- Draw current gold
            if GAME.gold then
                love.graphics.setFont(screenManager.fonts.medium)
                love.graphics.setColor(1, 1, 0)
                
                love.graphics.print(
                    "Gold: " .. GAME.gold,
                    self.x + 50, self.y + 70
                )
            end
            
            -- Draw "Recipe Details" section label
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.printf("Recipe Details", self.x, self.y + 100, self.width, "center")
            
            -- Draw divider line
            love.graphics.setColor(0.5, 0.5, 0.7, 0.7)
            love.graphics.line(
                self.x + 50, self.y + 130, 
                self.x + self.width - 50, self.y + 130
            )
            
            -- Draw recipe name
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                recipe.name,
                self.x + 20, self.y + 150,
                self.width - 40, "center"
            )
            
            -- Draw recipe description
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 0.9)
            
            love.graphics.printf(
                recipe.description,
                self.x + 50, self.y + 190,
                self.width - 100, "center"
            )
            
            -- Draw required materials
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.print(
                "Required Materials:",
                self.x + 50, self.y + 240
            )
            
            -- Count materials in inventory
            local inventoryMaterials = {}
            
            if GAME.inventory then
                for _, item in ipairs(GAME.inventory) do
                    if item.type == "material" or item.type == "monster_part" then
                        inventoryMaterials[item.name] = (inventoryMaterials[item.name] or 0) + (item.count or 1)
                    end
                end
            end
            
            -- Draw material list
            love.graphics.setFont(screenManager.fonts.medium)
            
            local materialY = self.y + 270
            for material, count in pairs(recipe.materials) do
                -- Check if player has enough
                local playerCount = inventoryMaterials[material] or 0
                local hasEnough = playerCount >= count
                
                -- Draw material name and count
                if hasEnough then
                    love.graphics.setColor(0.2, 0.8, 0.2)
                else
                    love.graphics.setColor(0.8, 0.2, 0.2)
                end
                
                love.graphics.print(
                    material .. " x" .. count .. " (" .. playerCount .. " available)",
                    self.x + 70, materialY
                )
                
                materialY = materialY + 30
            end
            
            -- Draw gold cost
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(1, 1, 0)
            
            love.graphics.print(
                "Gold Cost: " .. recipe.goldCost,
                self.x + 50, self.y + 370
            )
            
            -- Check if player has enough gold
            if not GAME.gold or GAME.gold < recipe.goldCost then
                love.graphics.setFont(screenManager.fonts.small)
                love.graphics.setColor(0.8, 0.2, 0.2)
                
                love.graphics.print(
                    "Not enough gold!",
                    self.x + 220, self.y + 370
                )
            end
            
            -- Draw buttons
            self.craftButton:draw()
            self.backButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check button clicks
            if self.craftButton:clicked(x, y, button) then
                return true
            end
            
            if self.backButton:clicked(x, y, button) then
                return true
            end
            
            return false
        end,
        
        init = function(self)
            -- Create buttons
            self.craftButton = screenManager.UI.Button(
                self.x + self.width / 2 - 110, self.y + self.height - 70, 
                100, 40, "Craft", 
                function() smith:craftItem() end
            )
            
            self.backButton = screenManager.UI.Button(
                self.x + self.width / 2 + 10, self.y + self.height - 70, 
                100, 40, "Back", 
                function() smith:showMainScreen() end
            )
        end
    }
    
    -- Create craft result panel
    self.elements.craftResultPanel = {
        x = 150,
        y = 150,
        width = 500,
        height = 300,
        visible = false,
        
        draw = function(self)
            if not self.visible or not smith.craftedItem then
                return
            end
            
            -- Draw panel background
            screenManager:drawPanel("Item Crafted!", self.x, self.y, self.width, self.height)
            
            -- Draw crafted item name
            love.graphics.setFont(screenManager.fonts.large)
            love.graphics.setColor(1, 1, 1)
            
            love.graphics.printf(
                smith.craftedItem.name,
                self.x + 20, self.y + 50,
                self.width - 40, "center"
            )
            
            -- Draw crafted item description
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.9, 0.9, 0.9)
            
            love.graphics.printf(
                smith.craftedItem.description or "No description available.",
                self.x + 30, self.y + 100,
                self.width - 60, "center"
            )
            
            -- Draw success message
            love.graphics.setFont(screenManager.fonts.medium)
            love.graphics.setColor(0.2, 0.8, 0.2)
            
            love.graphics.printf(
                "The item has been added to your inventory!",
                self.x + 30, self.y + 170,
                self.width - 60, "center"
            )
            
            -- Draw button
            self.closeButton:draw()
        end,
        
        clicked = function(self, x, y, button)
            if not self.visible then return false end
            
            -- Check button click
            if self.closeButton:clicked(x, y, button) then
                return true
            end
            
            return false
        end,
        
        init = function(self)
            -- Create button
            self.closeButton = screenManager.UI.Button(
                self.x + self.width / 2 - 50, self.y + self.height - 70, 
                100, 40, "Close", 
                function() smith:showMainScreen() end
            )
        end
    }
    
    -- Initialize panels
    self.elements.recipeDetailsPanel:init()
    self.elements.craftResultPanel:init()
    
    -- Create back button
    self.elements.backToTownButton = screenManager.UI.Button(
        GAME.width - 200, 20, 
        150, 40, "Back to Town", 
        function() self:returnToTown() end
    )
    self.elements.backToTownButton.visible = true
    
    -- Set initial visibility
    self:updateElementVisibility()
    
    -- Initialize party panel
    self.elements.partyPanel = partyPanel
    self.elements.partyPanel.visible = true
end

function smith:updateElementVisibility()
    -- Update element visibility based on current state
    if self.state == "main" then
        if self.elements.recipeDetailsPanel then
            self.elements.recipeDetailsPanel.visible = false
        end
        if self.elements.craftResultPanel then
            self.elements.craftResultPanel.visible = false
        end
    elseif self.state == "recipe_details" then
        if self.elements.recipeDetailsPanel then
            self.elements.recipeDetailsPanel.visible = true
        end
        if self.elements.craftResultPanel then
            self.elements.craftResultPanel.visible = false
        end
    elseif self.state == "craft_result" then
        if self.elements.recipeDetailsPanel then
            self.elements.recipeDetailsPanel.visible = false
        end
        if self.elements.craftResultPanel then
            self.elements.craftResultPanel.visible = true
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
        print("Smith UI visibility updated - State: " .. self.state)
    end
end

function smith:enter()
    -- Start playing smith music
    -- assetManager:playMusic("town") -- Use town music for now
    
    -- Initialize state
    self.state = "main"
    self.selectedRecipe = nil
    self.craftedItem = nil
    self.elements.recipeDetailsPanel.visible = false
    self.elements.craftResultPanel.visible = false
    self.selectedCategory = "All"
    self.pageOffset = 0
    
    -- Update element visibility
    self:updateElementVisibility()
end

function smith:draw()
    -- Draw background
    love.graphics.clear(screenManager.colors.background)
    
    -- Draw smith interior (placeholder)
    love.graphics.setColor(0.4, 0.2, 0.1)
    love.graphics.rectangle("fill", 0, 0, GAME.width, GAME.height)
    
    
    -- Draw state-specific UI
    if self.state == "main" then
        self.elements.recipeListPanel:draw()
    elseif self.state == "recipe_details" then
        self.elements.recipeDetailsPanel:draw()
    elseif self.state == "craft_result" then
        -- Draw background panels
        self.elements.recipeListPanel:draw()
        self.elements.craftResultPanel:draw()
    end
    
    -- Draw back button
    self.elements.backToTownButton:draw()
    
    -- Draw party panel if visible
    if self.elements.partyPanel and self.elements.partyPanel.visible then
        self.elements.partyPanel:draw()
    end
end

function smith:mousepressed(x, y, button, istouch, presses)
    -- Flag to track if a click was handled
    local clickHandled = false
    
    -- Check craft result panel first if visible
    if self.elements.craftResultPanel.visible then
        clickHandled = self.elements.craftResultPanel:clicked(x, y, button)
        if clickHandled then
            -- Play click sound
            assetManager:playSound("click")
            return true
        end
    end
    
    -- Check recipe details panel if visible
    if self.state == "recipe_details" and self.elements.recipeDetailsPanel.visible and not clickHandled then
        clickHandled = self.elements.recipeDetailsPanel:clicked(x, y, button)
        if clickHandled then
            -- Play click sound
            assetManager:playSound("click")
            return true
        end
    end
    
    -- Check recipe list panel if in main state
    if self.state == "main" and not clickHandled then
        clickHandled = self.elements.recipeListPanel:clicked(x, y, button)
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
    if not clickHandled and self.elements.backToTownButton and 
       self.elements.backToTownButton.visible and
       self.elements.backToTownButton:clicked(x, y, button) then
        
        -- Play click sound
        assetManager:playSound("click")
        
        if GAME.debug then
            print("Back to town button clicked")
        end
        
        clickHandled = true
    end
    
    return clickHandled
end

function smith:mousereleased(x, y, button, istouch, presses)
    -- Handle mouse releases for UI elements
    
    -- Handle craft result panel if visible
    if self.elements.craftResultPanel.visible then
        if self.elements.craftResultPanel.closeButton and self.elements.craftResultPanel.closeButton.released then
            self.elements.craftResultPanel.closeButton:released(x, y, button)
        end
    end
    
    -- Handle recipe details panel button releases
    if self.state == "recipe_details" and self.elements.recipeDetailsPanel.visible then
        if self.elements.recipeDetailsPanel.craftButton and self.elements.recipeDetailsPanel.craftButton.released then
            self.elements.recipeDetailsPanel.craftButton:released(x, y, button)
        end
        
        if self.elements.recipeDetailsPanel.backButton and self.elements.recipeDetailsPanel.backButton.released then
            self.elements.recipeDetailsPanel.backButton:released(x, y, button)
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
        print("Smith mouse released at: " .. x .. "," .. y)
    end
end

function smith:getCategoryOrder(category)
    if category == "Weapons" then
        return 1
    elseif category == "Armor" then
        return 2
    elseif category == "Accessories" then
        return 3
    else
        return 4
    end
end

function smith:selectCategory(category)
    -- Select category
    self.selectedCategory = category
    
    -- Reset pagination
    self.pageOffset = 0
end

function smith:selectRecipe(recipe)
    -- Select recipe
    self.selectedRecipe = recipe
    
    -- Show recipe details
    self.state = "recipe_details"
    self.elements.recipeDetailsPanel.visible = true
    
    -- Update element visibility
    self:updateElementVisibility()
end

function smith:showMainScreen()
    -- Go back to main screen
    self.state = "main"
    self.selectedRecipe = nil
    self.craftedItem = nil
    self.elements.recipeDetailsPanel.visible = false
    self.elements.craftResultPanel.visible = false
    
    -- Update element visibility
    self:updateElementVisibility()
end

function smith:craftItem()
    if not self.selectedRecipe then
        return
    end
    
    -- Check if player has enough gold
    if not GAME.gold or GAME.gold < self.selectedRecipe.goldCost then
        -- Not enough gold
        assetManager:playSound("hit")
        return
    end
    
    -- Check if player has all required materials
    if not GAME.inventory then
        -- No inventory
        assetManager:playSound("hit")
        return
    end
    
    local inventoryMaterials = {}
    
    -- Count materials in inventory
    for _, item in ipairs(GAME.inventory) do
        if item.type == "material" or item.type == "monster_part" then
            inventoryMaterials[item.name] = (inventoryMaterials[item.name] or 0) + (item.count or 1)
        end
    end
    
    -- Check each required material
    for material, count in pairs(self.selectedRecipe.materials) do
        if not inventoryMaterials[material] or inventoryMaterials[material] < count then
            -- Missing materials
            assetManager:playSound("hit")
            return
        end
    end
    
    -- Deduct gold
    GAME.gold = GAME.gold - self.selectedRecipe.goldCost
    
    -- Remove materials from inventory
    for material, count in pairs(self.selectedRecipe.materials) do
        local remaining = count
        
        for i = #GAME.inventory, 1, -1 do
            local item = GAME.inventory[i]
            
            if (item.type == "material" or item.type == "monster_part") and item.name == material then
                local itemCount = item.count or 1
                
                if itemCount <= remaining then
                    -- Remove entire stack
                    table.remove(GAME.inventory, i)
                    remaining = remaining - itemCount
                else
                    -- Remove part of stack
                    item.count = itemCount - remaining
                    remaining = 0
                end
                
                if remaining <= 0 then
                    break
                end
            end
        end
    end
    
    -- Get crafted item
    local itemTemplate = itemSystem:getItem(self.selectedRecipe.result)
    
    if not itemTemplate then
        -- Item not found
        assetManager:playSound("hit")
        return
    end
    
    self.craftedItem = {}
    
    -- Copy item data
    for key, value in pairs(itemTemplate) do
        self.craftedItem[key] = value
    end
    
    -- Add to inventory
    itemSystem:addToInventory(self.craftedItem)
    
    -- Play success sound
    assetManager:playSound("pickup")
    
    -- Show craft result
    self.state = "craft_result"
    self.elements.craftResultPanel.visible = true
    
    -- Update element visibility
    self:updateElementVisibility()
end

function smith:returnToTown()
    -- Return to town
    local gameState = require("states/gameState")
    gameState:changeState("overworld")
end

return smith
