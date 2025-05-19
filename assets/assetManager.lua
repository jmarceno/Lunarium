-- Asset Manager
-- Handles loading and management of game assets (images, sounds, etc.)
local assetManager = {
    images = {},
    sounds = {},
    music = {},
    texArrays = {}, -- Texture arrays for hardware-accelerated rendering
    textureIds = {}, -- Maps texture names to indices in texture arrays
    
    -- Normal maps storage
    normalMaps = {
        walls = {},
        floors = {},
        ceilings = {},
        monsterSprites = {}
    },
    
    -- Centralized audio settings
    audioSettings = {
        masterVolume = 1.0,
        musicVolume = 0.2, -- Default music volume
        soundVolume = 0.2  -- Default sound volume
    },

    wallNormalMapStrength = 1.0,
    floorNormalMapStrength = 1.5,
    monsterNormalMapStrength = 0.1,
}

function assetManager:init()
    -- Load character portraits
    self:loadPortraits()
    
    -- Load wall and floor textures
    self:loadWallAndFloorTextures()
    
    -- Load monster sprites
    self:loadMonsterSprites()
    
    -- Create placeholder images for future textures
    self:createPlaceholders()
    
    -- Create texture arrays for hardware-accelerated rendering
    self:createTextureArrays()
    
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

-- Load wall and floor textures from the assets/Walls and assets/Floor directories
function assetManager:loadWallAndFloorTextures()
    self.images.walls = {}
    self.images.floors = {}
    self.normalMaps.walls = {}
    self.normalMaps.floors = {}
    
    -- Load town map
    if love.filesystem.getInfo("assets/TownMap.png") then
        self.images.townMap = love.graphics.newImage("assets/TownMap.png")
        print("  - Loaded town map image")
    else
        print("  - Warning: assets/TownMap.png not found")
    end
    
    -- Load wall textures
    local wallInfo = love.filesystem.getInfo("assets/Walls")
    if wallInfo and wallInfo.type == "directory" then
        local files = love.filesystem.getDirectoryItems("assets/Walls")
        print("Loading wall textures from assets/Walls directory")
        
        for _, file in ipairs(files) do
            if file:match("%.png$") then
                local path = "assets/Walls/" .. file
                
                -- First load the image data for normal map generation
                local success, imgData = pcall(function()
                    return love.image.newImageData(path)
                end)
                
                if success and imgData then
                    local textureName = file:gsub("%.png$", "")
                    
                    -- Create the texture from the image data
                    local texture = love.graphics.newImage(imgData)
                    texture:setFilter("nearest", "nearest")
                    self.images.walls[textureName] = texture
                    
                    -- Generate normal map
                    local normalData = self:calculateNormalMap(imgData, assetManager.wallNormalMapStrength)
                    self.normalMaps.walls[textureName] = love.graphics.newImage(normalData)
                    
                    print("  - Loaded wall texture: " .. textureName)
                else
                    print("  - Failed to load wall texture: " .. file)
                end
            end
        end
        
        print("Loaded " .. self:countTableElements(self.images.walls) .. " wall textures")
    else
        print("Warning: assets/Walls directory not found")
    end
    
    -- Load floor textures
    local floorInfo = love.filesystem.getInfo("assets/Floor")
    if floorInfo and floorInfo.type == "directory" then
        local files = love.filesystem.getDirectoryItems("assets/Floor")
        print("Loading floor textures from assets/Floor directory")
        
        for _, file in ipairs(files) do
            if file:match("%.png$") then
                local path = "assets/Floor/" .. file
                
                -- First load the image data for normal map generation
                local success, imgData = pcall(function()
                    return love.image.newImageData(path)
                end)
                
                if success and imgData then
                    local textureName = file:gsub("%.png$", "")
                    
                    -- Create the texture from the image data
                    local texture = love.graphics.newImage(imgData)
                    texture:setFilter("nearest", "nearest")
                    self.images.floors[textureName] = texture
                    
                    -- Generate normal map
                    local normalData = self:calculateNormalMap(imgData, assetManager.floorNormalMapStrength)
                    self.normalMaps.floors[textureName] = love.graphics.newImage(normalData)
                    
                    -- Also use for ceiling normals since we're sharing textures
                    self.normalMaps.ceilings[textureName] = love.graphics.newImage(normalData)
                    
                    print("  - Loaded floor texture: " .. textureName)
                else
                    print("  - Failed to load floor texture: " .. file)
                end
            end
        end
        
        print("Loaded " .. self:countTableElements(self.images.floors) .. " floor textures")
    else
        print("Warning: assets/Floor directory not found")
    end
end

-- Helper function to count elements in a table (including non-numeric indices)
function assetManager:countTableElements(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
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
    
    -- Wall textures placeholders - only create if none were loaded
    if self:countTableElements(self.images.walls) == 0 then
        for i = 1, 10 do
            local placeholder = self:createWallPlaceholder(i)
            self.images.walls[tostring(i)] = placeholder
        end
    end
    
    -- Floor textures placeholders - only create if none were loaded
    if self:countTableElements(self.images.floors) == 0 then
        self.images.floors = {}
        for i = 1, 5 do
            local placeholder = self:createFloorPlaceholder(i)
            self.images.floors[tostring(i)] = placeholder
        end
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
    
    -- Also create a normal map for the placeholder
    local canvasData = canvas:newImageData()
    local normalData = self:calculateNormalMap(canvasData, assetManager.wallNormalMapStrength)
    self.normalMaps.walls[tostring(index)] = love.graphics.newImage(normalData)
    
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

-- Create a placeholder floor texture with a solid color and pattern
function assetManager:createFloorPlaceholder(index)
    local width, height = 64, 64
    local canvas = love.graphics.newCanvas(width, height)
    
    -- Generate a color based on index
    local r = 0.15 + (index % 3) * 0.1
    local g = 0.15 + (math.floor(index / 3) % 3) * 0.1
    local b = 0.15 + (math.floor(index / 9) % 3) * 0.1
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    
    -- Draw background
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Draw pattern based on index
    love.graphics.setColor(r * 1.3, g * 1.3, b * 1.3)
    
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
        -- Dots
        for x = 0, width, 8 do
            for y = 0, height, 8 do
                love.graphics.points(x, y)
            end
        end
    else
        -- Small squares
        for x = 0, width, 16 do
            for y = 0, height, 16 do
                love.graphics.rectangle("fill", x + 4, y + 4, 4, 4)
            end
        end
    end
    
    love.graphics.setCanvas()
    
    -- Also create a normal map for the placeholder
    local canvasData = canvas:newImageData()
    local normalData = self:calculateNormalMap(canvasData, assetManager.floorNormalMapStrength)
    self.normalMaps.floors[tostring(index)] = love.graphics.newImage(normalData)
    self.normalMaps.ceilings[tostring(index)] = love.graphics.newImage(normalData)
    
    return canvas
end

function assetManager:loadSounds()
    self.sounds = {}
    
    -- Check for sounds directory
    local soundsDirectory = "assets/Sounds"
    local info = love.filesystem.getInfo(soundsDirectory)
    if not info or info.type ~= "directory" then
        print("Warning: Sounds directory not found")
        return
    end
    
    -- Load standard UI sounds
    local uiSounds = {
        "click",
        "hover",
        "pickup",
        "drop",
        "attack",
        "hit",
        "spell",
        "footstep_gravel_walk_01",  -- Add our footstep sound
        "trap_arrow_fire", -- sound for fire arrow trap
        "trap_disarm_start", -- sound for disarm attempt
        "trap_disarm_success", -- sound for disarm success
        "trap_disarm_fail", -- sound for disarm fail
        "trap_spike_trigger", -- sound for spike trap
        "chest_trap_trigger_generic", -- sound for chest trap
        "trap_gas_trigger", -- sound for gas trap
        "trap_detected", -- sound for trap detected
        "missing_item", -- sound for missing item
        "secret_passage_switch_click", -- sound for secret passage switch click
        "secret_passage_open" -- sound for secret passage open
    }
    
    -- Try to load UI sounds
    for _, soundName in ipairs(uiSounds) do
        -- Try both .wav and .ogg formats
        local extensions = {".wav", ".ogg"}
        local loaded = false
        
        for _, ext in ipairs(extensions) do
            local path = soundsDirectory .. "/" .. soundName .. ext
            if love.filesystem.getInfo(path) then
                local success, sound = pcall(function()
                    return love.audio.newSource(path, "static")
                end)
                
                if success and sound then
                    self.sounds[soundName] = sound
                    print("  - Loaded sound: " .. soundName)
                    loaded = true
                    break  -- Stop trying other extensions if one worked
                else
                    print("  - Failed to load sound: " .. path)
                end
            end
        end
        
        if not loaded then
            print("  - Could not find sound: " .. soundName .. " in any supported format")
        end
    end
    
    -- Also check for any other sound files in the directory
    local files = love.filesystem.getDirectoryItems(soundsDirectory)
    for _, file in ipairs(files) do
        -- Check if file has a valid audio extension
        local ext = file:match("%.(%w+)$")
        if ext and (ext == "wav" or ext == "ogg" or ext == "mp3") then
            -- Extract sound name without extension
            local soundName = file:gsub("%." .. ext .. "$", "")
            
            -- Skip if we already loaded this sound
            if not self.sounds[soundName] then
                local path = soundsDirectory .. "/" .. file
                local success, sound = pcall(function()
                    return love.audio.newSource(path, "static")
                end)
                
                if success and sound then
                    self.sounds[soundName] = sound
                    print("  - Loaded additional sound: " .. soundName)
                else
                    print("  - Failed to load additional sound: " .. path)
                end
            end
        end
    end
    
    print("Loaded " .. self:countTableElements(self.sounds) .. " sounds")
end

function assetManager:loadMusic()
    -- Prepare music table with placeholders
    self.music = {
        menu = nil,
        dungeon = nil,
        combat = nil,
        combatAlt = nil,  -- Alternative battle music
        bossCombat = nil, -- Boss battle music
        victory = nil,
        town = nil,
        currentTrack = nil -- Track which music is currently playing
    }
    
    -- Try to load music, but don't crash if it doesn't exist
    local function tryLoadMusic(name, path)
        if love.filesystem.getInfo(path) then
            local success, result = pcall(function() return love.audio.newSource(path, "stream") end)
            if success then
                self.music[name] = result
                result:setLooping(true)
                result:setVolume(self.audioSettings.musicVolume)
                print("  - Loaded music: " .. name .. " from " .. path)
                return true
            else
                print("  - Failed to load music: " .. path)
            end
        else
            print("  - Music file not found: " .. path)
        end
        return false
    end
    
    -- Try to load all music
    tryLoadMusic("menu", "assets/music/menu.ogg")
    
    -- Try to load town music from either standard or custom location
    if not tryLoadMusic("town", "assets/music/town.ogg") then
        tryLoadMusic("town", "assets/Sounds/Music/CityMusic01.mp3")
    end
    
    -- Try to load dungeon music from either standard or custom location
    if not tryLoadMusic("dungeon", "assets/music/dungeon.ogg") then
        tryLoadMusic("dungeon", "assets/Sounds/Music/DungeonMusic01.mp3")
    end
    
    -- Try to load combat music from either standard or custom location
    if not tryLoadMusic("combat", "assets/music/combat.ogg") then
        tryLoadMusic("combat", "assets/Sounds/Music/BattleMusic01.mp3")
    end
    
    -- Load alternative battle music
    tryLoadMusic("combatAlt", "assets/Sounds/Music/BattleMusic02.mp3")
    
    -- Load boss battle music
    tryLoadMusic("bossCombat", "assets/Sounds/Music/BattleMusicBoss01.mp3")
    
    tryLoadMusic("victory", "assets/music/victory.ogg")
    
    print("Loaded " .. self:countTableElements(self.music) - 1 .. " music tracks") -- -1 for currentTrack
end

-- Play a sound if it's loaded
function assetManager:playSound(name, pitch)
    if self.sounds[name] then
        -- Clone the source to allow overlapping sounds
        local clone = self.sounds[name]:clone()
        
        -- Apply volume based on settings
        clone:setVolume(self.audioSettings.soundVolume)
        
        -- Apply pitch if specified
        if pitch then
            clone:setPitch(pitch)
        end
        
        clone:play()
    end
end

-- Set volume for a specific sound
function assetManager:setSoundVolume(name, volume)
    if self.sounds[name] then
        self.sounds[name]:setVolume(volume * self.audioSettings.soundVolume)
    end
end

-- Set volume for all button sounds
function assetManager:setButtonSoundVolume(volume)
    if self.sounds.button_hover then
        self.sounds.button_hover:setVolume(volume * self.audioSettings.soundVolume)
    end
    if self.sounds.button_click then
        self.sounds.button_click:setVolume(volume * self.audioSettings.soundVolume)
    end
end

-- Replace button sounds with new ones
function assetManager:setButtonSounds(hoverSoundPath, clickSoundPath)
    if hoverSoundPath then
        local success, result = pcall(function() return love.audio.newSource(hoverSoundPath, "static") end)
        if success then
            self.sounds.button_hover = result
        end
    end
    
    if clickSoundPath then
        local success, result = pcall(function() return love.audio.newSource(clickSoundPath, "static") end)
        if success then
            self.sounds.button_click = result
        end
    end
end

-- Set music volume (affects all music tracks)
function assetManager:setMusicVolume(volume)
    self.audioSettings.musicVolume = volume
    
    -- Apply to currently playing music
    for key, music in pairs(self.music) do
        if type(music) == "userdata" then
            music:setVolume(volume)
        end
    end
end

-- Set master volume (affects both music and sound)
function assetManager:setMasterVolume(volume)
    self.audioSettings.masterVolume = volume
    
    -- Update music volume
    self:setMusicVolume(self.audioSettings.musicVolume * volume)
    
    -- Update sound volume (will apply to next sounds played)
    self.audioSettings.soundVolume = self.audioSettings.soundVolume * volume
end

-- Play music if it's loaded
function assetManager:playMusic(name)
    -- Skip if already playing this track
    if self.music.currentTrack == name and self.music[name] and self.music[name]:isPlaying() then
        return
    end
    
    -- Stop any currently playing music
    for key, music in pairs(self.music) do
        if type(music) == "userdata" and music:isPlaying() then
            music:stop()
        end
    end
    
    -- Play the requested music if it exists
    if self.music[name] then
        self.music[name]:setVolume(self.audioSettings.musicVolume)
        self.music[name]:play()
        self.music.currentTrack = name
    end
end

-- Create texture arrays for hardware-accelerated rendering
function assetManager:createTextureArrays()
    -- Initialize texture ID maps
    self.textureIds = {
        walls = {},
        floors = {},
        ceilings = {},
        wallNormals = {},
        floorNormals = {},
        ceilingNormals = {}
    }
    
    -- Helper function to convert an Image to ImageData
    local function convertToImageData(image, defaultSize)
        if not image then return nil end
        
        -- Create a canvas to draw the image to
        local width, height = image:getDimensions()
        width = width or defaultSize
        height = height or defaultSize
        
        local canvas = love.graphics.newCanvas(width, height)
        
        -- Draw the image to the canvas
        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, 0, 0)
        love.graphics.setCanvas()
        
        -- Get the image data from the canvas
        return canvas:newImageData()
    end
    
    -- Create wall texture array
    local wallTextures = {}
    local wallCount = 0
    for name, texture in pairs(self.images.walls) do
        wallCount = wallCount + 1
        local imgData = convertToImageData(texture, 64)
        if imgData then
            table.insert(wallTextures, imgData)
            self.textureIds.walls[name] = wallCount - 1  -- 0-based index for shader
        end
    end
    
    if wallCount > 0 then
        pcall(function()
            self.texArrays.walls = love.graphics.newArrayImage(wallTextures)
        end)
        if self.texArrays.walls then
            print("Created wall texture array with " .. wallCount .. " textures")
        else
            print("Failed to create wall texture array")
        end
    else
        print("Warning: No wall textures found for array creation")
        -- Create a dummy texture array with at least one texture
        local dummyTexture = self:createWallPlaceholder(1)
        local dummyData = convertToImageData(dummyTexture, 64)
        self.texArrays.walls = love.graphics.newArrayImage({dummyData})
        self.textureIds.walls["default"] = 0
    end
    
    -- Create floor texture array
    local floorTextures = {}
    local floorCount = 0
    for name, texture in pairs(self.images.floors) do
        floorCount = floorCount + 1
        local imgData = convertToImageData(texture, 64)
        if imgData then
            table.insert(floorTextures, imgData)
            self.textureIds.floors[name] = floorCount - 1  -- 0-based index for shader
        end
    end
    
    if floorCount > 0 then
        pcall(function()
            self.texArrays.floors = love.graphics.newArrayImage(floorTextures)
        end)
        if self.texArrays.floors then
            print("Created floor texture array with " .. floorCount .. " textures")
        else
            print("Failed to create floor texture array")
        end
    else
        print("Warning: No floor textures found for array creation")
        -- Create a dummy texture array with at least one texture
        local dummyTexture = self:createFloorPlaceholder(1)
        local dummyData = convertToImageData(dummyTexture, 64)
        self.texArrays.floors = love.graphics.newArrayImage({dummyData})
        self.textureIds.floors["default"] = 0
    end
    
    -- Create ceiling texture array (copy of floor textures if none specified)
    local ceilingTextures = {}
    local ceilingCount = 0
    
    -- For now, we'll use the floor textures for ceilings
    -- In the future, you might want to add dedicated ceiling textures
    for name, texture in pairs(self.images.floors) do
        ceilingCount = ceilingCount + 1
        local imgData = convertToImageData(texture, 64)
        if imgData then
            table.insert(ceilingTextures, imgData)
            self.textureIds.ceilings[name] = ceilingCount - 1  -- 0-based index for shader
        end
    end
    
    if ceilingCount > 0 then
        pcall(function()
            self.texArrays.ceilings = love.graphics.newArrayImage(ceilingTextures)
        end)
        if self.texArrays.ceilings then
            print("Created ceiling texture array with " .. ceilingCount .. " textures")
        else
            print("Failed to create ceiling texture array")
        end
    else
        print("Warning: No ceiling textures found for array creation")
        -- Create a dummy texture array with at least one texture
        local dummyTexture = self:createFloorPlaceholder(1)
        local dummyData = convertToImageData(dummyTexture, 64)
        self.texArrays.ceilings = love.graphics.newArrayImage({dummyData})
        self.textureIds.ceilings["default"] = 0
    end
    
    -- Create wall normal map texture array
    local wallNormalTextures = {}
    local wallNormalCount = 0
    for name, texture in pairs(self.normalMaps.walls) do
        wallNormalCount = wallNormalCount + 1
        local imgData = convertToImageData(texture, 64)
        if imgData then
            table.insert(wallNormalTextures, imgData)
            self.textureIds.wallNormals[name] = wallNormalCount - 1  -- 0-based index for shader
        end
    end
    
    if wallNormalCount > 0 then
        pcall(function()
            self.texArrays.wallNormals = love.graphics.newArrayImage(wallNormalTextures)
        end)
        if self.texArrays.wallNormals then
            print("Created wall normal texture array with " .. wallNormalCount .. " textures")
        else
            print("Failed to create wall normal texture array")
        end
    end
    
    -- Create floor normal map texture array
    local floorNormalTextures = {}
    local floorNormalCount = 0
    for name, texture in pairs(self.normalMaps.floors) do
        floorNormalCount = floorNormalCount + 1
        local imgData = convertToImageData(texture, 64)
        if imgData then
            table.insert(floorNormalTextures, imgData)
            self.textureIds.floorNormals[name] = floorNormalCount - 1  -- 0-based index for shader
        end
    end
    
    if floorNormalCount > 0 then
        pcall(function()
            self.texArrays.floorNormals = love.graphics.newArrayImage(floorNormalTextures)
        end)
        if self.texArrays.floorNormals then
            print("Created floor normal texture array with " .. floorNormalCount .. " textures")
        else
            print("Failed to create floor normal texture array")
        end
    end
    
    -- Create ceiling normal map texture array
    local ceilingNormalTextures = {}
    local ceilingNormalCount = 0
    for name, texture in pairs(self.normalMaps.ceilings) do
        ceilingNormalCount = ceilingNormalCount + 1
        local imgData = convertToImageData(texture, 64)
        if imgData then
            table.insert(ceilingNormalTextures, imgData)
            self.textureIds.ceilingNormals[name] = ceilingNormalCount - 1  -- 0-based index for shader
        end
    end
    
    if ceilingNormalCount > 0 then
        pcall(function()
            self.texArrays.ceilingNormals = love.graphics.newArrayImage(ceilingNormalTextures)
        end)
        if self.texArrays.ceilingNormals then
            print("Created ceiling normal texture array with " .. ceilingNormalCount .. " textures")
        else
            print("Failed to create ceiling normal texture array")
        end
    end
    
    -- Free the temporary imagedata objects
    for _, imgData in ipairs(wallTextures) do
        imgData:release()
    end
    for _, imgData in ipairs(floorTextures) do
        imgData:release()
    end
    for _, imgData in ipairs(ceilingTextures) do
        imgData:release()
    end
    for _, imgData in ipairs(wallNormalTextures) do
        imgData:release()
    end
    for _, imgData in ipairs(floorNormalTextures) do
        imgData:release()
    end
    for _, imgData in ipairs(ceilingNormalTextures) do
        imgData:release()
    end
    
    -- Initialize entities texture array
    self.images.entities = {}
    self.texArrays.entities = nil  -- Will be created when needed
end

-- Load monster sprites from the assets/Sprites/Enemies directory and subdirectories
function assetManager:loadMonsterSprites()
    if self.images.monsterSprites then
        return self.images.monsterSprites
    end
    
    self.images.monsterSprites = {}
    self.normalMaps.monsterSprites = {}
    
    -- Check if enemies directory exists
    local info = love.filesystem.getInfo("assets/Sprites/Enemies")
    if not info or info.type ~= "directory" then
        print("Warning: Enemies directory not found")
        return self.images.monsterSprites
    end
    
    -- Get list of enemy type subdirectories
    local subDirs = love.filesystem.getDirectoryItems("assets/Sprites/Enemies")
    local totalLoaded = 0
    
    for _, subDir in ipairs(subDirs) do
        local subDirPath = "assets/Sprites/Enemies/" .. subDir
        local subDirInfo = love.filesystem.getInfo(subDirPath)
        
        if subDirInfo and subDirInfo.type == "directory" then
            print("Loading monster sprites from " .. subDirPath)
            
            -- Get sprite files from each category subdirectory
            local files = love.filesystem.getDirectoryItems(subDirPath)
            for _, file in ipairs(files) do
                if file:match("%.png$") then
                    local path = subDirPath .. "/" .. file
                    local id_from_filename = file:gsub("%.png$", "") -- Raw name from file, e.g., "Giant_Rat" or "Enraged_Panther_BOSS"
                    
                    local targetKey

                    if id_from_filename:match("_BOSS$") then
                        local nameStr = id_from_filename:gsub("_BOSS$", "") -- e.g., "Giant_Rat", "Enraged_Panther"
                        local parts = {}
                        for part in nameStr:gmatch("([^_]+)") do
                            -- Capitalize first letter of part, rest of part as is from file
                            table.insert(parts, part:sub(1,1):upper() .. part:sub(2))
                        end
                        targetKey = table.concat(parts, "") .. "_BOSS" -- e.g., "GiantRat_BOSS", "EnragedPanther_BOSS"
                    else
                        local parts = {}
                        for part in id_from_filename:gmatch("([^_]+)") do
                            table.insert(parts, part:sub(1,1):upper() .. part:sub(2))
                        end
                        targetKey = table.concat(parts, "") -- e.g., "GiantRat"
                    end
                    
                    -- First load the image data for normal map generation
                    local success, imgData = pcall(function()
                        return love.image.newImageData(path)
                    end)
                    
                    if success and imgData then
                        -- Create the sprite texture
                        local sprite = love.graphics.newImage(imgData)
                        sprite:setFilter("nearest", "nearest")
                        
                        -- Generate and store normal map
                        local normalData = self:calculateNormalMap(imgData, assetManager.monsterNormalMapStrength)
                        local normalMap = love.graphics.newImage(normalData)
                        
                        -- Store sprite with the targetKey
                        self.images.monsterSprites[targetKey] = sprite
                        self.normalMaps.monsterSprites[targetKey] = normalMap
                        
                        totalLoaded = totalLoaded + 1
                        print(string.format("  - Loaded monster sprite: %s (from file %s, as key %s)", targetKey, file, targetKey))
                    else
                        print("  - Failed to load monster sprite: " .. file)
                    end
                end
            end
        end
    end
    
    print("Successfully loaded " .. totalLoaded .. " monster sprites")
    return self.images.monsterSprites
end

-- Get an image by type and id
-- Types: "portrait", "monster", "item", "wall", "floor", "townMap"
-- Returns the image if found, nil otherwise
function assetManager:getImage(type, id)
    if type == "portrait" then
        -- Check in portraits collection
        if self.images.portraits and self.images.portraits[id] then
            return self.images.portraits[id]
        end
        
        -- If not found in portraits, check in profiles by index (legacy support)
        if self.images.profiles and tonumber(id) and self.images.profiles[tonumber(id)] then
            return self.images.profiles[tonumber(id)]
        end
    elseif type == "monster" then
        -- Check in monster sprites collection
        if self.images.monsterSprites and self.images.monsterSprites[id] then
            return self.images.monsterSprites[id]
        end
        
        -- If not found by ID, try to use a placeholder monster sprite
        if self.images.monsters and tonumber(id) and self.images.monsters[tonumber(id)] then
            return self.images.monsters[tonumber(id)]
        elseif self.images.monsters and self.images.monsters[1] then
            -- Return the first monster placeholder as fallback
            return self.images.monsters[1]
        end
    elseif type == "item" then
        -- Check in items collection
        if self.images.items and tonumber(id) and self.images.items[tonumber(id)] then
            return self.images.items[tonumber(id)]
        end
    elseif type == "wall" then
        -- Check in walls collection
        if self.images.walls and self.images.walls[id] then
            return self.images.walls[id]
        end
    elseif type == "floor" then
        -- Check in floors collection
        if self.images.floors and self.images.floors[id] then
            return self.images.floors[id]
        end
    elseif type == "townMap" then
        -- Return town map image
        return self.images.townMap
    end
    
    -- Image not found
    return nil
end

-- Calculate normal map from a texture
function assetManager:calculateNormalMap(imageData, strength)
    -- Default strength if not provided
    strength = strength or 2.0
    
    local width, height = imageData:getDimensions()
    local normalData = love.image.newImageData(width, height)
    
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            -- Get heights at surrounding pixels (with edge handling)
            local xMinus = x > 0 and x - 1 or x
            local xPlus = x < width - 1 and x + 1 or x
            local yMinus = y > 0 and y - 1 or y
            local yPlus = y < height - 1 and y + 1 or y
            
            -- Sample pixel colors and calculate grayscale height values
            local _, _, _, a00 = imageData:getPixel(xMinus, yMinus)
            local r01, g01, b01, a01 = imageData:getPixel(x, yMinus)
            local _, _, _, a02 = imageData:getPixel(xPlus, yMinus)
            local r10, g10, b10, a10 = imageData:getPixel(xMinus, y)
            local r11, g11, b11, a11 = imageData:getPixel(x, y)
            local r12, g12, b12, a12 = imageData:getPixel(xPlus, y)
            local _, _, _, a20 = imageData:getPixel(xMinus, yPlus)
            local r21, g21, b21, a21 = imageData:getPixel(x, yPlus)
            local _, _, _, a22 = imageData:getPixel(xPlus, yPlus)
            
            -- Skip calculation for fully transparent pixels
            if a11 < 0.01 then
                normalData:setPixel(x, y, 0.5, 0.5, 1.0, 0.0)
            else
                -- Calculate height values using luminance
                local h00 = (a00 > 0.01) and 0.299 * r10 + 0.587 * g10 + 0.114 * b10 or 0
                local h01 = (a01 > 0.01) and 0.299 * r01 + 0.587 * g01 + 0.114 * b01 or 0
                local h02 = (a02 > 0.01) and 0.299 * r12 + 0.587 * g12 + 0.114 * b12 or 0
                local h10 = (a10 > 0.01) and 0.299 * r10 + 0.587 * g10 + 0.114 * b10 or 0
                local h11 = 0.299 * r11 + 0.587 * g11 + 0.114 * b11
                local h12 = (a12 > 0.01) and 0.299 * r12 + 0.587 * g12 + 0.114 * b12 or 0
                local h20 = (a20 > 0.01) and 0.299 * r21 + 0.587 * g21 + 0.114 * b21 or 0
                local h21 = (a21 > 0.01) and 0.299 * r21 + 0.587 * g21 + 0.114 * b21 or 0
                local h22 = (a22 > 0.01) and 0.299 * r12 + 0.587 * g12 + 0.114 * b12 or 0
                
                -- Sobel operator to get gradients
                local xGradient = 
                    (h00 + 2 * h10 + h20) - 
                    (h02 + 2 * h12 + h22)
                
                local yGradient = 
                    (h00 + 2 * h01 + h02) - 
                    (h20 + 2 * h21 + h22)
                
                -- Normalize and apply strength
                xGradient = xGradient * strength
                yGradient = yGradient * strength
                
                -- Construct normal vector (x, y, z)
                local length = math.sqrt(xGradient * xGradient + yGradient * yGradient + 1)
                local nx = -xGradient / length
                local ny = -yGradient / length
                local nz = 1.0 / length
                
                -- Convert from [-1, 1] to [0, 1] range for storage
                nx = nx * 0.5 + 0.5
                ny = ny * 0.5 + 0.5
                
                -- Store normal in RGB format
                normalData:setPixel(x, y, nx, ny, nz, a11)
            end
        end
    end
    
    return normalData
end

-- Add helper function to get normal map for a specific texture
function assetManager:getNormalMap(type, id)
    if type == "wall" then
        return self.normalMaps.walls[id]
    elseif type == "floor" then
        return self.normalMaps.floors[id]
    elseif type == "ceiling" then
        return self.normalMaps.ceilings[id]
    elseif type == "monster" then
        return self.normalMaps.monsterSprites[id]
    end
    return nil
end

return assetManager
