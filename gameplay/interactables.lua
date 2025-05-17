-- Interactables Module
-- Handles secret passages, wall interactables, and puzzles
local assetManager = require("assets/assetManager")

local interactables = {}

-- Initialize the interactable wall properties in the map
function interactables:initializeMap(map)
    -- Add interactable walls property to the map
    map.interactableWalls = {}
    
    -- Add secretPassages properties to the map
    map.secretPassages = {}
    
    -- Add puzzles property to the map
    map.puzzles = {}
    
    -- Add methods to the map
    
    -- Method to check if a wall is interactable
    map.isWallInteractable = function(self, x, y)
        for _, wall in ipairs(self.interactableWalls) do
            if wall.x == x and wall.y == y then
                return true
            end
        end
        return false
    end
    
    -- Method to get an interactable wall
    map.getInteractableWall = function(self, x, y)
        for _, wall in ipairs(self.interactableWalls) do
            if wall.x == x and wall.y == y then
                return wall
            end
        end
        return nil
    end
    
    -- Method to check if a wall is a secret passage
    map.isSecretPassage = function(self, x, y)
        for _, passage in ipairs(self.secretPassages) do
            if passage.x == x and passage.y == y then
                return true
            end
        end
        return false
    end
    
    -- Method to get a secret passage
    map.getSecretPassage = function(self, x, y)
        for _, passage in ipairs(self.secretPassages) do
            if passage.x == x and passage.y == y then
                return passage
            end
        end
        return nil
    end
    
    -- Method to get hint factor for walls
    map.getHintFactor = function(self, x, y, elementType)
        if elementType == "wall" then
            local wall = self:getInteractableWall(x, y)
            if wall then
                return wall.hintFactor or 0.0
            end
            
            local passage = self:getSecretPassage(x, y)
            if passage then
                return passage.hintFactor or 0.0
            end
        elseif elementType == "floor" then
            -- For future trap implementation
            return 0.0
        end
        return 0.0
    end
    
    -- Method to check if a wall is related to a trap (for debug mode)
    map.isWallTrapRelated = function(self, x, y)
        local wall = self:getInteractableWall(x, y)
        if wall then
            return true
        end
        
        local passage = self:getSecretPassage(x, y)
        if passage then
            return true
        end
        
        return false
    end
    
    return map
end

-- Add an interactable wall to the map
function interactables:addInteractableWall(map, x, y, props)
    local wall = {
        x = x,
        y = y,
        isInteractableWall = true,
        interactableId = props.interactableId or ("interactable_" .. x .. "_" .. y),
        interactionPrompt = props.interactionPrompt or "Inspect wall",
        revealsPassageAt = props.revealsPassageAt,
        triggersPuzzleEvent = props.triggersPuzzleEvent,
        requiresItemId = props.requiresItemId,
        textureVariant = props.textureVariant,
        activatedTextureVariant = props.activatedTextureVariant,
        isActivated = props.isActivated or false,
        hintFactor = props.hintFactor or 0.0
    }
    
    -- Set the wall texture if a variant is provided
    if wall.textureVariant and not wall.isActivated then
        map:setWallTexture(x, y, wall.textureVariant)
    elseif wall.activatedTextureVariant and wall.isActivated then
        map:setWallTexture(x, y, wall.activatedTextureVariant)
    end
    
    table.insert(map.interactableWalls, wall)
    return wall
end

-- Add a secret passage to the map
function interactables:addSecretPassage(map, x, y, props)
    local passage = {
        x = x,
        y = y,
        isSecretPassage = true,
        secretPassageRevealed = props.secretPassageRevealed or false,
        secretPassageType = props.secretPassageType or "slide",
        textureVariant = props.textureVariant,
        hintFactor = props.hintFactor or 0.0
    }
    
    -- Set the wall texture if a variant is provided
    if passage.textureVariant then
        map:setWallTexture(x, y, passage.textureVariant)
    end
    
    table.insert(map.secretPassages, passage)
    return passage
end

-- Add a multi-step puzzle to the map
function interactables:addPuzzle(map, puzzleId, requiredSteps, revealsPassageAt)
    map.puzzles[puzzleId] = {
        requiredSteps = requiredSteps or {},
        currentSteps = {},
        revealsPassageAt = revealsPassageAt,
        isSolved = false
    }
    return map.puzzles[puzzleId]
end

-- Activate an interactable wall
function interactables:activateWall(map, x, y, player)
    local wall = map:getInteractableWall(x, y)
    if not wall then return false end
    
    -- Check if the interactable requires an item
    if wall.requiresItemId then
        local hasItem = false
        -- This should check the player's inventory
        -- For now, assume they have the item (to be implemented later)
        hasItem = true
        
        if not hasItem then
            -- Play a sound for missing item
            if assetManager.sounds.missing_item then
                assetManager.sounds.missing_item:play()
            end
            return false
        end
    end
    
    -- Play activation sound
    if assetManager.sounds.secret_passage_switch_click then
        assetManager.sounds.secret_passage_switch_click:play()
    end
    
    -- Mark the wall as activated
    wall.isActivated = true
    
    -- If it has an activated texture, set it
    if wall.activatedTextureVariant then
        map:setWallTexture(wall.x, wall.y, wall.activatedTextureVariant)
    end
    
    -- If this wall reveals a passage directly
    if wall.revealsPassageAt then
        self:revealSecretPassage(map, wall.revealsPassageAt.x, wall.revealsPassageAt.y)
    end
    
    -- If this wall triggers a puzzle event
    if wall.triggersPuzzleEvent then
        self:triggerPuzzleEvent(map, wall.triggersPuzzleEvent, player)
    end
    
    return true
end

-- Reveal a secret passage
function interactables:revealSecretPassage(map, x, y)
    local passage = map:getSecretPassage(x, y)
    if not passage then return false end
    
    -- Mark the passage as revealed
    passage.secretPassageRevealed = true
    
    -- Set the cell to walkable (0)
    map:setCell(x, y, 0)
    
    -- Play sound
    if assetManager.sounds.secret_passage_open then
        assetManager.sounds.secret_passage_open:play()
    end
    
    return true
end

-- Trigger a puzzle event
function interactables:triggerPuzzleEvent(map, eventId, player)
    -- Find which puzzle this event belongs to
    for puzzleId, puzzle in pairs(map.puzzles) do
        for _, step in ipairs(puzzle.requiredSteps) do
            if step == eventId then
                -- Add the step to the current steps if not already there
                local stepFound = false
                for _, currentStep in ipairs(puzzle.currentSteps) do
                    if currentStep == eventId then
                        stepFound = true
                        break
                    end
                end
                
                if not stepFound then
                    table.insert(puzzle.currentSteps, eventId)
                    
                    -- Check if the puzzle is solved
                    self:checkPuzzleSolution(map, puzzleId)
                end
                
                return true
            end
        end
    end
    
    return false
end

-- Check if a puzzle is solved
function interactables:checkPuzzleSolution(map, puzzleId)
    local puzzle = map.puzzles[puzzleId]
    if not puzzle or puzzle.isSolved then return false end
    
    -- Check if all required steps are completed
    local allStepsCompleted = true
    for _, requiredStep in ipairs(puzzle.requiredSteps) do
        local stepCompleted = false
        for _, currentStep in ipairs(puzzle.currentSteps) do
            if currentStep == requiredStep then
                stepCompleted = true
                break
            end
        end
        
        if not stepCompleted then
            allStepsCompleted = false
            break
        end
    end
    
    -- If all steps are completed, solve the puzzle
    if allStepsCompleted and puzzle.revealsPassageAt then
        puzzle.isSolved = true
        self:revealSecretPassage(map, puzzle.revealsPassageAt.x, puzzle.revealsPassageAt.y)
        return true
    end
    
    return false
end

-- Update hint factors based on player position and class
function interactables:updateHintFactors(map, playerX, playerY)
    local detectionRange = 3.0  -- Base detection range (e.g. Warrior or default)
    local hintMultiplier = 1.0  -- Base hint multiplier
    -- local bestClassType = "Default" -- For logging if needed

    if GAME.party and #GAME.party > 0 then
        local hasRogue, hasMage = false, false
        for _, member in ipairs(GAME.party) do
            if member.class == "Rogue" then hasRogue = true; break end -- Rogue is highest priority
            if member.class == "Mage" then hasMage = true end
        end

        if hasRogue then
            detectionRange = 7.0
            hintMultiplier = 1.5
            -- bestClassType = "Rogue"
        elseif hasMage then
            detectionRange = 5.0
            hintMultiplier = 1.2
            -- bestClassType = "Mage"
        end
    end
    
    -- Update interactable walls
    for _, wall in ipairs(map.interactableWalls) do
        local distance = math.sqrt((wall.x - playerX)^2 + (wall.y - playerY)^2)
        if distance <= detectionRange then
            -- Calculate hint factor based on distance and multiplier
            local baseFactor = (1.0 - (distance / detectionRange)) * hintMultiplier
            wall.hintFactor = math.min(0.8, baseFactor)  -- Cap at 0.8 for subtlety
        else
            wall.hintFactor = 0.0
        end
    end
    
    -- Update secret passages
    for _, passage in ipairs(map.secretPassages) do
        if not passage.secretPassageRevealed then
            local distance = math.sqrt((passage.x - playerX)^2 + (passage.y - playerY)^2)
            if distance <= detectionRange then
                -- Calculate hint factor based on distance and multiplier
                local baseFactor = (1.0 - (distance / detectionRange)) * hintMultiplier
                passage.hintFactor = math.min(0.8, baseFactor)  -- Cap at 0.8 for subtlety
            else
                passage.hintFactor = 0.0
            end
        else
            passage.hintFactor = 0.0  -- No hint for revealed passages
        end
    end
end

return interactables 