-- Dungeon Generator
-- Procedurally generates dungeon maps
local dungeonGenerator = {
    -- Texture variety parameters
    maxWallTextureTypes = 1,
    maxFloorTextureTypes = 1,
    maxTextureSets = 1,
    maxRegionCount = 1
}

-- Map class definition
local Map = {}
Map.__index = Map

function Map:new(width, height)
    local map = {
        width = width,
        height = height,
        data = {},
        rooms = {},
        start = {x = 0, y = 0},
        end_ = {x = 0, y = 0},
        fogOfWar = {}, -- Track which cells have been seen
        textures = {
            wall = {},    -- Wall texture for each cell
            floor = {},   -- Floor texture for each cell
            ceiling = {}, -- Ceiling texture for each cell (new)
            roomId = {}   -- Store which room/area each cell belongs to (for consistent texturing)
        }
    }
    
    -- Initialize map with all walls
    for y = 0, height - 1 do
        map.data[y] = {}
        map.fogOfWar[y] = {} -- Initialize fog of war
        map.textures.wall[y] = {}
        map.textures.floor[y] = {}
        map.textures.ceiling[y] = {} -- Initialize ceiling textures
        map.textures.roomId[y] = {}
        for x = 0, width - 1 do
            map.data[y][x] = 1  -- 1 means wall
            map.fogOfWar[y][x] = false -- Initially all cells are hidden
            map.textures.wall[y][x] = nil -- No texture initially
            map.textures.floor[y][x] = nil -- No texture initially
            map.textures.ceiling[y][x] = nil -- No ceiling texture initially
            map.textures.roomId[y][x] = 0 -- Not part of any room initially
        end
    end
    
    return setmetatable(map, Map)
end

function Map:getCell(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return 1  -- Outside bounds is a wall
    end
    
    return self.data[y][x]
end

function Map:setCell(x, y, value)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    self.data[y][x] = value
    return true
end

-- Get wall texture for a specific cell
function Map:getWallTexture(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return nil
    end
    
    return self.textures.wall[y][x]
end

-- Set wall texture for a specific cell
function Map:setWallTexture(x, y, texture)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    self.textures.wall[y][x] = texture
    return true
end

-- Get floor texture for a specific cell
function Map:getFloorTexture(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return nil
    end
    
    return self.textures.floor[y][x]
end

-- Set floor texture for a specific cell
function Map:setFloorTexture(x, y, texture)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    self.textures.floor[y][x] = texture
    return true
end

-- Get ceiling texture for a specific cell
function Map:getCeilingTexture(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return nil
    end
    
    -- If no ceiling texture is set, use the floor texture
    if not self.textures.ceiling[y][x] then
        return self.textures.floor[y][x]
    end
    
    return self.textures.ceiling[y][x]
end

-- Set ceiling texture for a specific cell
function Map:setCeilingTexture(x, y, texture)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    self.textures.ceiling[y][x] = texture
    return true
end

-- Get room ID for a specific cell (used for texture consistency)
function Map:getRoomId(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return 0
    end
    
    return self.textures.roomId[y][x]
end

-- Set room ID for a specific cell
function Map:setRoomId(x, y, roomId)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    self.textures.roomId[y][x] = roomId
    return true
end

function Map:isCellWalkable(x, y)
    return self:getCell(x, y) == 0  -- 0 means floor
end

function Map:isCellVisible(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    return self.fogOfWar[y][x]
end

function Map:revealCell(x, y)
    -- Check bounds
    if x < 0 or y < 0 or x >= self.width or y >= self.height then
        return false
    end
    
    self.fogOfWar[y][x] = true
    return true
end

function Map:revealArea(centerX, centerY, radius)
    -- Reveal a circular area around the given point
    local radiusSquared = radius * radius
    
    for y = math.max(0, math.floor(centerY - radius)), math.min(self.height - 1, math.ceil(centerY + radius)) do
        for x = math.max(0, math.floor(centerX - radius)), math.min(self.width - 1, math.ceil(centerX + radius)) do
            -- Calculate distance squared for efficiency
            local distSquared = (x - centerX)^2 + (y - centerY)^2
            if distSquared <= radiusSquared then
                self:revealCell(x, y)
            end
        end
    end
end

-- Dungeon generator functions
function dungeonGenerator:generate(width, height, seed, options)
    -- Set random seed
    math.randomseed(seed or os.time())
    
    -- Apply options if provided
    options = options or {}
    local textureOptions = options.texture or {}
    local tempWallTypes = self.maxWallTextureTypes
    local tempFloorTypes = self.maxFloorTextureTypes
    local tempTextureSets = self.maxTextureSets
    local tempRegionCount = self.maxRegionCount
    
    -- Override texture parameters if provided
    if textureOptions.maxWallTypes then self.maxWallTextureTypes = textureOptions.maxWallTypes end
    if textureOptions.maxFloorTypes then self.maxFloorTextureTypes = textureOptions.maxFloorTypes end
    if textureOptions.maxSets then self.maxTextureSets = textureOptions.maxSets end
    if textureOptions.maxRegions then self.maxRegionCount = textureOptions.maxRegions end
    
    -- Create new map
    local map = Map:new(width, height)
    
    -- Generate rooms
    self:generateRooms(map)
    
    -- Connect rooms with corridors
    self:connectRooms(map)
    
    -- Place entrance and exit
    self:placeStartAndEnd(map)
    
    -- Add some decoration (different wall types)
    self:decorateMap(map)
    
    -- Add textures to the map
    self:assignTextures(map)
    
    -- Restore original parameters
    self.maxWallTextureTypes = tempWallTypes
    self.maxFloorTextureTypes = tempFloorTypes
    self.maxTextureSets = tempTextureSets
    self.maxRegionCount = tempRegionCount
    
    return map
end

function dungeonGenerator:generateRooms(map)
    -- Scale room count with map size
    local roomCount = math.floor(map.width * map.height / 100) + math.random(6, 10)
    local attempts = 0
    local maxAttempts = 200 -- Increased max attempts for larger maps
    
    -- Scale room size based on map size
    local minRoomSize = 3
    local maxRoomSize = math.min(12, math.max(8, math.floor(map.width / 15)))
    
    while #map.rooms < roomCount and attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Random room dimensions scaled to map size
        local roomWidth = math.random(minRoomSize, maxRoomSize)
        local roomHeight = math.random(minRoomSize, maxRoomSize)
        
        -- Random room position
        local roomX = math.random(1, map.width - roomWidth - 1)
        local roomY = math.random(1, map.height - roomHeight - 1)
        
        -- Check if room overlaps with existing rooms
        local overlaps = false
        for _, room in ipairs(map.rooms) do
            if self:roomsOverlap({x = roomX, y = roomY, width = roomWidth, height = roomHeight}, room) then
                overlaps = true
                break
            end
        end
        
        if not overlaps then
            -- Create room
            local room = {
                x = roomX,
                y = roomY,
                width = roomWidth,
                height = roomHeight,
                id = #map.rooms + 1 -- Assign a unique room ID for texturing
            }
            
            -- Carve room into map
            for y = roomY, roomY + roomHeight - 1 do
                for x = roomX, roomX + roomWidth - 1 do
                    map:setCell(x, y, 0)  -- 0 means floor
                    map:setRoomId(x, y, room.id) -- Assign room ID to each cell
                end
            end
            
            -- Add room to room list
            table.insert(map.rooms, room)
        end
    end
end

function dungeonGenerator:roomsOverlap(room1, room2)
    -- Add 1 tile buffer around rooms
    return not (
        room1.x + room1.width + 1 < room2.x - 1 or
        room1.x - 1 > room2.x + room2.width + 1 or
        room1.y + room1.height + 1 < room2.y - 1 or
        room1.y - 1 > room2.y + room2.height + 1
    )
end

function dungeonGenerator:connectRooms(map)
    -- Assign unique corridor IDs starting after the last room ID
    local nextCorridorId = #map.rooms + 1
    
    -- Connect all rooms with corridors
    for i = 1, #map.rooms - 1 do
        local roomA = map.rooms[i]
        local roomB = map.rooms[i + 1]
        
        -- Get center points of rooms
        local centerAX = math.floor(roomA.x + roomA.width / 2)
        local centerAY = math.floor(roomA.y + roomA.height / 2)
        local centerBX = math.floor(roomB.x + roomB.width / 2)
        local centerBY = math.floor(roomB.y + roomB.height / 2)
        
        local corridorId = nextCorridorId
        nextCorridorId = nextCorridorId + 1
        
        -- Randomly decide if we go horizontal or vertical first
        if math.random() < 0.5 then
            -- Horizontal then vertical
            self:createHorizontalCorridor(map, centerAX, centerBX, centerAY, corridorId)
            self:createVerticalCorridor(map, centerAY, centerBY, centerBX, corridorId)
        else
            -- Vertical then horizontal
            self:createVerticalCorridor(map, centerAY, centerBY, centerAX, corridorId)
            self:createHorizontalCorridor(map, centerAX, centerBX, centerBY, corridorId)
        end
    end
    
    -- Add some random additional connections for loops
    -- Scale the number of connections with map size
    local mapSize = map.width * map.height
    local additionalConnections = math.min(10, math.max(1, math.floor(mapSize / 800)))
    
    for i = 1, additionalConnections do
        local roomA = map.rooms[math.random(1, #map.rooms)]
        local roomB = map.rooms[math.random(1, #map.rooms)]
        
        -- Skip if same room
        if roomA == roomB then goto continue end
        
        -- Get center points of rooms
        local centerAX = math.floor(roomA.x + roomA.width / 2)
        local centerAY = math.floor(roomA.y + roomA.height / 2)
        local centerBX = math.floor(roomB.x + roomB.width / 2)
        local centerBY = math.floor(roomB.y + roomB.height / 2)
        
        local corridorId = nextCorridorId
        nextCorridorId = nextCorridorId + 1
        
        -- Randomly decide if we go horizontal or vertical first
        if math.random() < 0.5 then
            -- Horizontal then vertical
            self:createHorizontalCorridor(map, centerAX, centerBX, centerAY, corridorId)
            self:createVerticalCorridor(map, centerAY, centerBY, centerBX, corridorId)
        else
            -- Vertical then horizontal
            self:createVerticalCorridor(map, centerAY, centerBY, centerAX, corridorId)
            self:createHorizontalCorridor(map, centerAX, centerBX, centerBY, corridorId)
        end
        
        ::continue::
    end
end

function dungeonGenerator:createHorizontalCorridor(map, x1, x2, y, corridorId)
    local start = math.min(x1, x2)
    local ending = math.max(x1, x2)
    
    for x = start, ending do
        map:setCell(x, y, 0)  -- 0 means floor
        map:setRoomId(x, y, corridorId) -- Assign corridor ID
    end
end

function dungeonGenerator:createVerticalCorridor(map, y1, y2, x, corridorId)
    local start = math.min(y1, y2)
    local ending = math.max(y1, y2)
    
    for y = start, ending do
        map:setCell(x, y, 0)  -- 0 means floor
        map:setRoomId(x, y, corridorId) -- Assign corridor ID
    end
end

function dungeonGenerator:placeStartAndEnd(map)
    -- Select two rooms for start and end
    local startRoom = map.rooms[1]
    local endRoom = map.rooms[#map.rooms]
    
    -- Calculate center of the starting room for player position
    local centerX = math.floor(startRoom.x + startRoom.width / 2)
    local centerY = math.floor(startRoom.y + startRoom.height / 2)
    
    -- Find a position for entrance near a wall (but not on a wall)
    local entranceX, entranceY
    
    -- Try to place near the north wall
    if startRoom.y + 1 < centerY - 1 then
        entranceX = centerX
        entranceY = startRoom.y + 1  -- One tile away from north wall
    -- Try to place near the west wall
    elseif startRoom.x + 1 < centerX - 1 then
        entranceX = startRoom.x + 1  -- One tile away from west wall
        entranceY = centerY
    -- Try to place near the south wall
    elseif startRoom.y + startRoom.height - 2 > centerY + 1 then
        entranceX = centerX
        entranceY = startRoom.y + startRoom.height - 2  -- One tile away from south wall
    -- Try to place near the east wall
    elseif startRoom.x + startRoom.width - 2 > centerX + 1 then
        entranceX = startRoom.x + startRoom.width - 2  -- One tile away from east wall
        entranceY = centerY
    -- Fallback: use center but offset slightly to avoid direct overlap
    else
        entranceX = centerX - 1
        entranceY = centerY
    end
    
    -- Ensure entrance and player (center) don't overlap
    if entranceX == centerX and entranceY == centerY then
        -- If they would overlap, shift entrance by 1 tile
        entranceX = entranceX - 1
    end
    
    -- Set the entrance location
    map.start = {
        x = entranceX,
        y = entranceY
    }
    
    -- Place end point in the middle of the end room
    map.end_ = {
        x = math.floor(endRoom.x + endRoom.width / 2),
        y = math.floor(endRoom.y + endRoom.height / 2)
    }
end

function dungeonGenerator:decorateMap(map)
    -- Add different wall types
    for y = 0, map.height - 1 do
        for x = 0, map.width - 1 do
            if map:getCell(x, y) == 1 then  -- If it's a wall
                -- Check if it's a perimeter wall
                if x == 0 or y == 0 or x == map.width - 1 or y == map.height - 1 then
                    map:setCell(x, y, 2)  -- Wall type 2 (perimeter)
                elseif math.random() < 0.2 then
                    -- Randomly add some different wall types
                    map:setCell(x, y, math.random(2, 5))
                end
            end
        end
    end
    
    -- Add some floor decoration (not implemented yet)
end

-- Assign texture sets to rooms and corridors
function dungeonGenerator:assignTextures(map)
    -- First, get a list of all room and corridor IDs
    local areaIds = {}
    local maxAreaId = 0
    
    for y = 0, map.height - 1 do
        for x = 0, map.width - 1 do
            local areaId = map:getRoomId(x, y)
            if areaId > 0 and not areaIds[areaId] then
                areaIds[areaId] = true
                maxAreaId = math.max(maxAreaId, areaId)
            end
        end
    end
    
    -- Load available textures (from assetManager, but we'll simulate it here)
    local assetManager = require("assets/assetManager")
    local wallTextures = {}
    local floorTextures = {}
    
    -- Get all wall texture keys
    for name, _ in pairs(assetManager.images.walls) do
        table.insert(wallTextures, name)
    end
    
    -- Get all floor texture keys
    for name, _ in pairs(assetManager.images.floors) do
        table.insert(floorTextures, name)
    end
    
    -- If no textures are available, use placeholders
    if #wallTextures == 0 then
        for i = 1, 10 do
            table.insert(wallTextures, tostring(i))
        end
    end
    
    if #floorTextures == 0 then
        for i = 1, 5 do
            table.insert(floorTextures, tostring(i))
        end
    end
    
    -- LIMIT TEXTURE VARIETY: Select only a small subset of available textures
    -- Use configurable parameters instead of hardcoded values
    if #wallTextures > self.maxWallTextureTypes then
        local limitedWallTextures = {}
        for i = 1, self.maxWallTextureTypes do
            local index = math.random(1, #wallTextures)
            table.insert(limitedWallTextures, wallTextures[index])
            table.remove(wallTextures, index)
        end
        wallTextures = limitedWallTextures
    end
    
    if #floorTextures > self.maxFloorTextureTypes then
        local limitedFloorTextures = {}
        for i = 1, self.maxFloorTextureTypes do
            local index = math.random(1, #floorTextures)
            table.insert(limitedFloorTextures, floorTextures[index])
            table.remove(floorTextures, index)
        end
        floorTextures = limitedFloorTextures
    end
    
    -- Create texture sets (wall+floor combinations)
    local textureSets = {}
    -- Use configurable parameter for set count
    local setCount = math.min(self.maxTextureSets, math.min(#wallTextures, #floorTextures))
    
    for i = 1, setCount do
        -- Randomly select a wall and floor texture for this set
        local wallIndex = math.random(1, #wallTextures)
        local floorIndex = math.random(1, #floorTextures)
        
        table.insert(textureSets, {
            wall = wallTextures[wallIndex],
            floor = floorTextures[floorIndex]
        })
        
        -- Remove the selected textures from the available pools to ensure variety
        table.remove(wallTextures, wallIndex)
        table.remove(floorTextures, floorIndex)
    end
    
    -- Group rooms and corridors into regions - using configurable parameter
    local regionCount = math.min(self.maxRegionCount, math.ceil(maxAreaId / 10))
    local areaToRegion = {}
    
    for id = 1, maxAreaId do
        local regionId = math.floor((id - 1) / math.ceil(maxAreaId / regionCount)) + 1
        areaToRegion[id] = regionId
    end
    
    -- Assign texture sets to regions
    local regionToTextureSet = {}
    for i = 1, regionCount do
        regionToTextureSet[i] = textureSets[((i - 1) % #textureSets) + 1]
    end
    
    -- Apply textures based on room/corridor ID
    for y = 0, map.height - 1 do
        for x = 0, map.width - 1 do
            local cell = map:getCell(x, y)
            local areaId = map:getRoomId(x, y)
            
            if areaId > 0 then
                local regionId = areaToRegion[areaId]
                local textureSet = regionToTextureSet[regionId]
                
                if cell == 0 then -- Floor
                    map:setFloorTexture(x, y, textureSet.floor)
                end
            end
            
            -- For walls, look at adjacent floor cells to determine which texture to use
            if cell > 0 then -- Wall
                -- Check if this wall is adjacent to a floor
                local adjacentAreaId = 0
                
                -- Check the 4 adjacent cells
                local directions = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
                
                for _, dir in ipairs(directions) do
                    local nx, ny = x + dir[1], y + dir[2]
                    if nx >= 0 and ny >= 0 and nx < map.width and ny < map.height then
                        local neighborAreaId = map:getRoomId(nx, ny)
                        if neighborAreaId > 0 then
                            adjacentAreaId = neighborAreaId
                            break
                        end
                    end
                end
                
                if adjacentAreaId > 0 then
                    local regionId = areaToRegion[adjacentAreaId]
                    local textureSet = regionToTextureSet[regionId]
                    map:setWallTexture(x, y, textureSet.wall)
                else
                    -- If no adjacent floor, use the first texture set as default
                    map:setWallTexture(x, y, textureSets[1].wall)
                end
            end
        end
    end
    
    -- Assign ceiling textures based on room ID
    -- For now, use the same texture as floor
    for y = 0, map.height - 1 do
        for x = 0, map.width - 1 do
            if map:getCell(x, y) == 0 then  -- Only assign ceiling textures to floor cells
                local floorTexture = map:getFloorTexture(x, y)
                map:setCeilingTexture(x, y, floorTexture)
            end
        end
    end
end

return dungeonGenerator
