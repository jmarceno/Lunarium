-- Event Handler Functions - For input and interaction events
local combatSystem = {}  -- Forward declaration to reference STATE values

-- Handle keypresses
local function keypressed(self, key)
    if self:isOver() then
        -- Remove keyboard shortcut for exiting combat
        return false
    end
    
    -- Check if the skill list should handle the keypress
    if self.state == combatSystem.STATE.PLAYER_TURN and 
       self.elements.skillList and 
       self.elements.skillList.visible and
       self.elements.skillList:keypressed(key) then
        return false
    end
    
    return false
end

-- Handle mouse clicks
local function mousepressed(self, x, y, button)
    -- Check if combat is over
    if self:isOver() then
        if button == 1 and self.elements.continueButton then
            -- Check continue button explicitly
            if self.elements.continueButton:clicked(x, y, button) then
                if GAME.debug then
                    print("Continue button clicked, returning true to exit combat")
                end
                return true
            end
            
            -- Also check if coordinates are within the button bounds
            if x >= self.elements.continueButton.x and
               x <= self.elements.continueButton.x + self.elements.continueButton.width and
               y >= self.elements.continueButton.y and
               y <= self.elements.continueButton.y + self.elements.continueButton.height then
                if GAME.debug then
                    print("Clicked in continue button bounds, returning true to exit combat")
                end
                return true
            end
        end
        
        -- TEMPORARY FIX: Exit combat on any click in victory state
        if self.state == combatSystem.STATE.VICTORY and button == 1 then
            if GAME.debug then
                print("TEMPORARY FIX: Exiting combat on any click during victory state")
            end
            return true
        end
        
        -- In victory/defeat state, any click should do nothing else
        return false
    end

    -- If combat is NOT over, proceed with player turn logic
    if self.state ~= combatSystem.STATE.PLAYER_TURN then
        return false
    end
    
    -- Check UI element clicks during player turn
    if button == 1 then
        -- Check skill list clicks
        if self.elements.skillList and self.elements.skillList.visible and self.elements.skillList:clicked(x, y) then
            return false 
        end
        
        -- Check item list clicks
        if self.elements.itemList and self.elements.itemList.visible and self.elements.itemList:clicked(x, y) then
            return false 
        end
        
        -- Check party selection list clicks
        if self.elements.partySelectList and self.elements.partySelectList.visible and self.elements.partySelectList:clicked(x, y) then
            return false
        end
        
        -- Check enemy selection list clicks
        if self.elements.enemySelectList and self.elements.enemySelectList.visible and self.elements.enemySelectList:clicked(x, y) then
            return false
        end
        
        -- Check other button clicks (Attack, Skill, Item, Defend, Confirm, Back)
        for name, element in pairs(self.elements) do
            -- Exclude lists and the continue button (handled above)
            if element.clicked and element ~= self.elements.skillList and 
               element ~= self.elements.itemList and 
               element ~= self.elements.partySelectList and
               element ~= self.elements.enemySelectList and
               element ~= self.elements.continueButton then
                
                if element.visible ~= false and element:clicked(x, y, button) then
                    return false
                end
            end
        end
    end
    
    return false
end

-- Handle mouse wheel scrolling
local function wheelmoved(self, x, y)
    -- Check if we need to forward to skill list
    if self.state == combatSystem.STATE.PLAYER_TURN and 
       self.elements.skillList and 
       self.elements.skillList.visible and 
       self.elements.skillList:wheel(love.mouse.getX(), love.mouse.getY(), x, y) then
        return false
    end
    
    return false
end

combatSystem.STATE = {INIT = 1, PLAYER_TURN = 2, ENEMY_TURN = 3, MINION_TURN = 4, VICTORY = 5, DEFEAT = 6}

return {
    keypressed = keypressed,
    mousepressed = mousepressed,
    wheelmoved = wheelmoved
}