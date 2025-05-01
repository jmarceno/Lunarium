-- Dungeon Generator
-- Procedurally generates dungeon maps
local dungeonGenerator = {}

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
        end_ = {x = 0, y = 0}
    }
    
    -- Initialize map with all walls
    for y = 0, height - 1 do
        map.data[y] = {}
        for x = 0, width - 1 do
            map.data[y][x] = 1  -- 1 means wall
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

function Map:isCellWalkable(x, y)
    return self:getCell(x, y) == 0  -- 0 means floor
end

-- Dungeon generator functions
function dungeonGenerator:generate(width, height, seed)
    -- Set random seed
    math.randomseed(seed or os.time())
    
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
    
    return map
end

function dungeonGenerator:generateRooms(map)
    local roomCount = math.floor(map.width * map.height / 100) + math.random(6, 10)
    local attempts = 0
    local maxAttempts = 100
    
    while #map.rooms < roomCount and attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Random room dimensions
        local roomWidth = math.random(3, 8)
        local roomHeight = math.random(3, 8)
        
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
                height = roomHeight
            }
            
            -- Carve room into map
            for y = roomY, roomY + roomHeight - 1 do
                for x = roomX, roomX + roomWidth - 1 do
                    map:setCell(x, y, 0)  -- 0 means floor
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
    -- Connect all rooms with corridors
    for i = 1, #map.rooms - 1 do
        local roomA = map.rooms[i]
        local roomB = map.rooms[i + 1]
        
        -- Get center points of rooms
        local centerAX = math.floor(roomA.x + roomA.width / 2)
        local centerAY = math.floor(roomA.y + roomA.height / 2)
        local centerBX = math.floor(roomB.x + roomB.width / 2)
        local centerBY = math.floor(roomB.y + roomB.height / 2)
        
        -- Randomly decide if we go horizontal or vertical first
        if math.random() < 0.5 then
            -- Horizontal then vertical
            self:createHorizontalCorridor(map, centerAX, centerBX, centerAY)
            self:createVerticalCorridor(map, centerAY, centerBY, centerBX)
        else
            -- Vertical then horizontal
            self:createVerticalCorridor(map, centerAY, centerBY, centerAX)
            self:createHorizontalCorridor(map, centerAX, centerBX, centerBY)
        end
    end
    
    -- Add some random additional connections for loops
    local additionalConnections = math.random(1, 3)
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
        
        -- Randomly decide if we go horizontal or vertical first
        if math.random() < 0.5 then
            -- Horizontal then vertical
            self:createHorizontalCorridor(map, centerAX, centerBX, centerAY)
            self:createVerticalCorridor(map, centerAY, centerBY, centerBX)
        else
            -- Vertical then horizontal
            self:createVerticalCorridor(map, centerAY, centerBY, centerAX)
            self:createHorizontalCorridor(map, centerAX, centerBX, centerBY)
        end
        
        ::continue::
    end
end

function dungeonGenerator:createHorizontalCorridor(map, x1, x2, y)
    local start = math.min(x1, x2)
    local ending = math.max(x1, x2)
    
    for x = start, ending do
        map:setCell(x, y, 0)  -- 0 means floor
    end
end

function dungeonGenerator:createVerticalCorridor(map, y1, y2, x)
    local start = math.min(y1, y2)
    local ending = math.max(y1, y2)
    
    for y = start, ending do
        map:setCell(x, y, 0)  -- 0 means floor
    end
end

function dungeonGenerator:placeStartAndEnd(map)
    -- Select two rooms for start and end
    local startRoom = map.rooms[1]
    local endRoom = map.rooms[#map.rooms]
    
    -- Place start and end in the middle of these rooms
    map.start = {
        x = math.floor(startRoom.x + startRoom.width / 2),
        y = math.floor(startRoom.y + startRoom.height / 2)
    }
    
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

return dungeonGenerator
