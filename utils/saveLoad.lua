-- Save/Load System
local bitser
local success, result = pcall(function() return require("lib/bitser") end)
if success then
    bitser = result
else
    bitser = {
        -- Fallback empty implementation
        loadLoveFile = function() return nil end,
        dumpLoveFile = function() end
    }
    print("Warning: bitser library not found - save/load functionality disabled")
end

local saveLoad = {
    saveDir = "saves/",
    settingsFile = "settings.dat",
    currentProfile = nil
}

function saveLoad:init()
    -- Create save directory if it doesn't exist
    love.filesystem.createDirectory(self.saveDir)
    
    -- Load settings
    self:loadGameSettings()
end

-- Load game settings
function saveLoad:loadGameSettings()
    if love.filesystem.getInfo(self.settingsFile) then
        local success, settings = pcall(function() 
            return bitser.loadLoveFile(self.settingsFile)
        end)
        
        if success and settings then
            -- Apply settings
            GAME.settings = settings
        else
            -- Create default settings
            self:createDefaultSettings()
        end
    else
        -- Create default settings
        self:createDefaultSettings()
    end
end

-- Create default game settings
function saveLoad:createDefaultSettings()
    GAME.settings = {
        sound = {
            musicVolume = 0.5,
            sfxVolume = 0.7,
            masterVolume = 0.8
        },
        graphics = {
            fullscreen = false,
            texturesEnabled = false,
            resolution = "800x600"
        },
        gameplay = {
            difficultyLevel = 2,  -- 1: Easy, 2: Normal, 3: Hard
            autoSave = true
        },
        controls = {
            moveForward = "w",
            moveBackward = "s",
            turnLeft = "a",
            turnRight = "d",
            strafeLeft = "q",
            strafeRight = "e",
            attack = "space",
            useItem = "r",
            openMenu = "tab"
        }
    }
end

-- Save game settings
function saveLoad:saveGameSettings()
    if GAME.settings then
        bitser.dumpLoveFile(self.settingsFile, GAME.settings)
    end
end

-- List all available save profiles
function saveLoad:listSaveProfiles()
    local profiles = {}
    local items = love.filesystem.getDirectoryItems(self.saveDir)
    
    for _, item in ipairs(items) do
        if item:sub(-4) == ".sav" then
            local profile = item:sub(1, -5)  -- Remove .sav extension
            
            -- Get save info
            local infoFile = self.saveDir .. profile .. ".info"
            local info = {
                name = profile,
                date = "Unknown",
                level = 1,
                playtime = 0
            }
            
            if love.filesystem.getInfo(infoFile) then
                local success, savedInfo = pcall(function()
                    return bitser.loadLoveFile(infoFile)
                end)
                
                if success and savedInfo then
                    info = savedInfo
                end
            end
            
            table.insert(profiles, info)
        end
    end
    
    -- Sort by date (most recent first)
    table.sort(profiles, function(a, b)
        return a.date > b.date
    end)
    
    return profiles
end

-- Create a new save profile
function saveLoad:createProfile(name)
    if not name or name == "" then
        name = "Player_" .. os.time()
    end
    
    -- Create profile data
    local profile = {
        name = name,
        party = {},
        inventory = {},
        gold = 100,
        quests = {},
        completedQuests = {},
        dungeonSeeds = {},
        gameTime = 0,
        flags = {}
    }
    
    -- Create info data
    local info = {
        name = name,
        date = os.date("%Y-%m-%d %H:%M:%S"),
        level = 1,
        playtime = 0
    }
    
    -- Save profile
    self.currentProfile = name
    
    -- Ensure save directory exists
    love.filesystem.createDirectory(self.saveDir)
    
    -- Attempt to save files with error handling
    local success1, err1 = pcall(function()
        bitser.dumpLoveFile(self.saveDir .. name .. ".sav", profile)
    end)
    
    local success2, err2 = pcall(function()
        bitser.dumpLoveFile(self.saveDir .. name .. ".info", info)
    end)
    
    if not success1 or not success2 then
        print("Error saving profile: " .. (err1 or "") .. " " .. (err2 or ""))
        return nil
    end
    
    return profile
end

-- Load a save profile
function saveLoad:loadProfile(name)
    local filename = self.saveDir .. name .. ".sav"
    
    if love.filesystem.getInfo(filename) then
        local success, profile = pcall(function()
            return bitser.loadLoveFile(filename)
        end)
        
        if success and profile then
            self.currentProfile = name
            
            -- Update info
            local infoFile = self.saveDir .. name .. ".info"
            local info = {
                name = name,
                date = os.date("%Y-%m-%d %H:%M:%S"),
                level = 1,
                playtime = 0
            }
            
            if love.filesystem.getInfo(infoFile) then
                local success, savedInfo = pcall(function()
                    return bitser.loadLoveFile(infoFile)
                end)
                
                if success and savedInfo then
                    info = savedInfo
                    info.date = os.date("%Y-%m-%d %H:%M:%S")
                end
            end
            
            bitser.dumpLoveFile(infoFile, info)
            
            return profile
        end
    end
    
    return nil
end

-- Save current game data
function saveLoad:saveGame(gameData)
    if not self.currentProfile then
        print("Error: No current profile selected")
        return false
    end
    
    -- Update info
    local infoFile = self.saveDir .. self.currentProfile .. ".info"
    local info = {
        name = self.currentProfile,
        date = os.date("%Y-%m-%d %H:%M:%S"),
        level = 1,
        playtime = gameData.gameTime or 0
    }
    
    -- Update level from party data
    if gameData.party and #gameData.party > 0 then
        local maxLevel = 0
        for _, char in ipairs(gameData.party) do
            if char.level > maxLevel then
                maxLevel = char.level
            end
        end
        info.level = maxLevel
    end
    
    -- Ensure save directory exists
    love.filesystem.createDirectory(self.saveDir)
    
    -- Save files with error handling
    local success1, err1 = pcall(function()
        bitser.dumpLoveFile(self.saveDir .. self.currentProfile .. ".sav", gameData)
    end)
    
    local success2, err2 = pcall(function()
        bitser.dumpLoveFile(infoFile, info)
    end)
    
    if not success1 or not success2 then
        print("Error saving game: " .. (err1 or "") .. " " .. (err2 or ""))
        return false
    end
    
    return true
end

-- Delete a save profile
function saveLoad:deleteProfile(name)
    local saveFile = self.saveDir .. name .. ".sav"
    local infoFile = self.saveDir .. name .. ".info"
    
    if love.filesystem.getInfo(saveFile) then
        love.filesystem.remove(saveFile)
    end
    
    if love.filesystem.getInfo(infoFile) then
        love.filesystem.remove(infoFile)
    end
    
    if self.currentProfile == name then
        self.currentProfile = nil
    end
    
    return true
end

return saveLoad
