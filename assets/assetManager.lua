-- Asset Manager
-- Handles loading and management of game assets (images, sounds, etc.)
local assetManager = {
    images = {},
    sounds = {},
    music = {}
}

function assetManager:init()
    -- Load character portraits
    self:loadPortraits()
    
    -- Create placeholder images for future textures
    self:createPlaceholders()
    
    -- Attempt to load sounds
    self:loadSounds()
    
    -- Attempt to load music
    self:loadMusic()
end

-- Load character portraits from Sprites/Portraits directory
function assetManager:loadPortraits()
    self.images.portraits = {}
    self.images.profiles = {}
    
    -- Check if portraits directory exists
    local info = love.filesystem.getInfo("assets/Sprites/Portraits")
    if not info or info.type ~= "directory" then
        print("Warning: Portraits directory not found")
        return
    end
    
    -- Get list of portraits
    local files = love.filesystem.getDirectoryItems("assets/Sprites/Portraits")
    for _, file in ipairs(files) do
        -- Skip non-PNG files
        if file:match("%.png$") then
            local id = file:gsub("_DD%.png$", "")
            local path = "assets/Sprites/Portraits/" .. file
            
            -- Load image
            local success, portrait = pcall(function()
                return love.graphics.newImage(path)
            end)
            
            if success and portrait then
                -- Store portrait indexed by filename (without extension)
                self.images.portraits[id] = portrait
            end
        end
    end
    
    -- For backwards compatibility, map first 8 portraits to profiles array
    local count = 0
    for id, portrait in pairs(self.images.portraits) do
        count = count + 1
        if count <= 8 then
            self.images.profiles[count] = portrait
        end
    end
    
    print("Loaded " .. count .. " portraits")
end

function assetManager:createPlaceholders()
    -- Character profile placeholders if no portraits were loaded
    if not self.images.profiles[1] then
        self.images.profiles = {}
        for i = 1, 8 do
            local placeholder = self:createProfilePlaceholder(i)
            self.images.profiles[i] = placeholder
        end
    end
    
    -- Wall textures placeholders
    self.images.walls = {}
    for i = 1, 10 do
        local placeholder = self:createWallPlaceholder(i)
        self.images.walls[i] = placeholder
    end
    
    -- Item placeholders
    self.images.items = {}
    for i = 1, 20 do
        local placeholder = self:createItemPlaceholder(i)
        self.images.items[i] = placeholder
    end
    
    -- Monster placeholders
    self.images.monsters = {}
    for i = 1, 15 do
        local placeholder = self:createMonsterPlaceholder(i)
        self.images.monsters[i] = placeholder
    end
end

-- Create a placeholder profile image with a solid color and number
function assetManager:createProfilePlaceholder(index)
    local size = 64
    local canvas = love.graphics.newCanvas(size, size)
    
    -- Generate a color based on index
    local r = 0.3 + (index % 3) * 0.2
    local g = 0.3 + (math.floor(index / 3) % 3) * 0.2
    local b = 0.3 + (math.floor(index / 9) % 3) * 0.2
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    
    -- Draw background
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, size, size)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", 0, 0, size, size)
    
    -- Draw number
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(index, (size - love.graphics.getFont():getWidth(index)) / 2, 
                       (size - love.graphics.getFont():getHeight()) / 2)
    
    love.graphics.setCanvas()
    
    return canvas
end

-- Create a placeholder wall texture with a solid color and pattern
function assetManager:createWallPlaceholder(index)
    local width, height = 64, 64
    local canvas = love.graphics.newCanvas(width, height)
    
    -- Generate a color based on index
    local r = 0.2 + (index % 3) * 0.2
    local g = 0.2 + (math.floor(index / 3) % 3) * 0.2
    local b = 0.2 + (math.floor(index / 9) % 3) * 0.2
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    
    -- Draw background
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Draw pattern based on index
    love.graphics.setColor(r * 1.4, g * 1.4, b * 1.4)
    
    if index % 4 == 0 then
        -- Grid pattern
        for i = 0, width, 16 do
            love.graphics.line(i, 0, i, height)
            love.graphics.line(0, i, width, i)
        end
    elseif index % 4 == 1 then
        -- Diagonal lines
        for i = -height, width, 16 do
            love.graphics.line(i, 0, i + height, height)
        end
    elseif index % 4 == 2 then
        -- Circles
        for x = 0, width, 16 do
            for y = 0, height, 16 do
                love.graphics.circle("line", x, y, 8)
            end
        end
    else
        -- Rectangles
        for x = 0, width, 16 do
            for y = 0, height, 16 do
                love.graphics.rectangle("line", x, y, 8, 8)
            end
        end
    end
    
    -- Draw border
    love.graphics.setColor(0.8, 0.8, 0.8, 0.5)
    love.graphics.rectangle("line", 0, 0, width, height)
    
    love.graphics.setCanvas()
    
    return canvas
end

-- Create a placeholder item image
function assetManager:createItemPlaceholder(index)
    local size = 32
    local canvas = love.graphics.newCanvas(size, size)
    
    -- Generate a color based on index
    local r = 0.4 + (index % 3) * 0.2
    local g = 0.4 + (math.floor(index / 3) % 3) * 0.2
    local b = 0.4 + (math.floor(index / 9) % 3) * 0.2
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Draw item shape based on type
    love.graphics.setColor(r, g, b)
    
    local itemType = index % 5
    if itemType == 0 then  -- Sword
        love.graphics.polygon("fill", 
            size/2, 4,
            size/2 - 3, size/3,
            size/2, size - 4,
            size/2 + 3, size/3
        )
        love.graphics.polygon("fill",
            size/3, size/3,
            size*2/3, size/3,
            size*2/3, size/3 + 3,
            size/3, size/3 + 3
        )
    elseif itemType == 1 then  -- Shield
        love.graphics.polygon("fill",
            size/2, 4,
            size - 4, size/3,
            size - 8, size - 4,
            size/2, size - 8,
            4, size - 4,
            4, size/3
        )
    elseif itemType == 2 then  -- Potion
        love.graphics.circle("fill", size/2, size/5, size/5)
        love.graphics.rectangle("fill", 
            size/2 - size/5, size/5,
            size/2.5, size*3/5
        )
        love.graphics.polygon("fill",
            size/2 - size/5, size*4/5,
            size/2 + size/5, size*4/5,
            size/2, size - 4
        )
    elseif itemType == 3 then  -- Staff
        love.graphics.rectangle("fill",
            size/2 - 2, 4,
            4, size - 8
        )
        love.graphics.circle("fill", size/2, 8, size/5)
    else  -- Book
        love.graphics.rectangle("fill",
            size/4, size/4,
            size/2, size/2
        )
        love.graphics.setColor(0.8, 0.8, 0.8, 0.5)
        love.graphics.rectangle("line",
            size/4 + 2, size/4 + 2,
            size/2 - 4, size/2 - 4
        )
    end
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", 0, 0, size, size)
    
    love.graphics.setCanvas()
    
    return canvas
end

-- Create a placeholder monster image
function assetManager:createMonsterPlaceholder(index)
    local size = 96
    local canvas = love.graphics.newCanvas(size, size)
    
    -- Generate a color based on index
    local r = 0.2 + (index % 3) * 0.25
    local g = 0.2 + (math.floor(index / 3) % 3) * 0.25
    local b = 0.2 + (math.floor(index / 9) % 3) * 0.25
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Draw monster shape based on type
    love.graphics.setColor(r, g, b)
    
    local monsterType = index % 5
    if monsterType == 0 then  -- Slime
        love.graphics.circle("fill", size/2, size*2/3, size/3)
        love.graphics.ellipse("fill", size/2, size*2/3, size/2, size/4)
        
        -- Eyes
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", size/3, size/2, size/10)
        love.graphics.circle("fill", size*2/3, size/2, size/10)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", size/3, size/2, size/20)
        love.graphics.circle("fill", size*2/3, size/2, size/20)
    elseif monsterType == 1 then  -- Humanoid
        -- Body
        love.graphics.rectangle("fill", size/3, size/3, size/3, size/2)
        
        -- Head
        love.graphics.circle("fill", size/2, size/4, size/6)
        
        -- Arms
        love.graphics.rectangle("fill", size/5, size/3, size/6, size/3)
        love.graphics.rectangle("fill", size*3/5, size/3, size/6, size/3)
        
        -- Legs
        love.graphics.rectangle("fill", size/3, size*5/6, size/8, size/6)
        love.graphics.rectangle("fill", size/2, size*5/6, size/8, size/6)
        
        -- Eyes
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", size*2/5, size/5, size/20)
        love.graphics.circle("fill", size*3/5, size/5, size/20)
    elseif monsterType == 2 then  -- Spider
        -- Body
        love.graphics.circle("fill", size/2, size/2, size/6)
        
        -- Legs
        for i = 0, 7 do
            local angle = i * math.pi / 4
            local x1 = size/2 + math.cos(angle) * size/6
            local y1 = size/2 + math.sin(angle) * size/6
            local x2 = size/2 + math.cos(angle) * size/2
            local y2 = size/2 + math.sin(angle) * size/2
            
            love.graphics.line(x1, y1, x2, y2)
        end
        
        -- Eyes
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", size*2/5, size*2/5, size/30)
        love.graphics.circle("fill", size*3/5, size*2/5, size/30)
    elseif monsterType == 3 then  -- Ghost
        -- Body
        love.graphics.rectangle("fill", size/3, size/3, size/3, size/3)
        love.graphics.arc("fill", size/2, size/3, size/3, 0, math.pi)
        
        -- Bottom
        love.graphics.polygon("fill",
            size/3, size*2/3,
            size*2/3, size*2/3,
            size*2/3, size*5/6,
            size/2, size*3/4,
            size/3, size*5/6
        )
        
        -- Eyes
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", size*2/5, size/3, size/20)
        love.graphics.circle("fill", size*3/5, size/3, size/20)
    else  -- Dragon
        -- Body
        love.graphics.ellipse("fill", size/2, size/2, size/4, size/6)
        
        -- Head
        love.graphics.ellipse("fill", size/4, size/2, size/8, size/10)
        
        -- Tail
        love.graphics.polygon("fill",
            size*3/4, size/2,
            size*7/8, size/3,
            size - 4, size/2,
            size*7/8, size*2/3
        )
        
        -- Wings
        love.graphics.polygon("fill",
            size/2, size/2 - 2,
            size*3/4, size/4,
            size/2, size/3
        )
        
        -- Eyes
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", size/5, size*9/20, size/30)
    end
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", 0, 0, size, size)
    
    love.graphics.setCanvas()
    
    return canvas
end

function assetManager:loadSounds()
    -- Prepare sound table with placeholders
    self.sounds = {
        click = nil,
        footstep = nil,
        attack = nil,
        spell = nil,
        hit = nil,
        door = nil,
        pickup = nil,
        levelup = nil
    }
    
    -- Try to load sounds, but don't crash if they don't exist
    local function tryLoadSound(name, path)
        local success, result = pcall(function() return love.audio.newSource(path, "static") end)
        if success then
            self.sounds[name] = result
        end
    end
    
    -- Try to load all sounds
    tryLoadSound("click", "assets/sounds/click.wav")
    tryLoadSound("footstep", "assets/sounds/footstep.wav")
    tryLoadSound("attack", "assets/sounds/attack.wav")
    tryLoadSound("spell", "assets/sounds/spell.wav")
    tryLoadSound("hit", "assets/sounds/hit.wav")
    tryLoadSound("door", "assets/sounds/door.wav")
    tryLoadSound("pickup", "assets/sounds/pickup.wav")
    tryLoadSound("levelup", "assets/sounds/levelup.wav")
end

function assetManager:loadMusic()
    -- Prepare music table with placeholders
    self.music = {
        menu = nil,
        dungeon = nil,
        combat = nil,
        victory = nil,
        town = nil
    }
    
    -- Try to load music, but don't crash if it doesn't exist
    local function tryLoadMusic(name, path)
        local success, result = pcall(function() return love.audio.newSource(path, "stream") end)
        if success then
            self.music[name] = result
            result:setLooping(true)
        end
    end
    
    -- Try to load all music
    tryLoadMusic("menu", "assets/music/menu.ogg")
    tryLoadMusic("dungeon", "assets/music/dungeon.ogg")
    tryLoadMusic("combat", "assets/music/combat.ogg")
    tryLoadMusic("victory", "assets/music/victory.ogg")
    tryLoadMusic("town", "assets/music/town.ogg")
end

-- Play a sound if it's loaded
function assetManager:playSound(name)
    if self.sounds[name] then
        -- Clone the source to allow overlapping sounds
        local clone = self.sounds[name]:clone()
        clone:play()
    end
end

-- Play music if it's loaded
function assetManager:playMusic(name)
    -- Stop any currently playing music
    for _, music in pairs(self.music) do
        if music and music:isPlaying() then
            music:stop()
        end
    end
    
    -- Play the requested music if it exists
    if self.music[name] then
        self.music[name]:play()
    end
end

return assetManager
