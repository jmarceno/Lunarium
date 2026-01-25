
-- Mock love environment
love = {
    graphics = {
        newImage = function(path)
            print("Loading image: " .. path)
            return { path = path }
        end,
        newFont = function() return {} end,
        newCanvas = function() return { newImageData = function() end } end,
        newArrayImage = function() return {} end,
        clear = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        printf = function() end,
        line = function() end,
        draw = function() end,
        setFont = function() end,
        getFont = function() return { getWidth = function() return 10 end, getHeight = function() return 10 end } end
    },
    filesystem = {
        getInfo = function() return { type = "directory" } end,
        getDirectoryItems = function() return {} end
    },
    audio = {
        newSource = function() return {} end
    },
    mouse = {
        getPosition = function() return 0,0 end
    },
    image = {
        newImageData = function() return { getDimensions = function() return 10, 10 end, getPixel = function() return 0,0,0,0 end, setPixel = function() end } end
    }
}

-- Mock global GAME object
GAME = {
    width = 800,
    height = 600,
    debug = false
}

-- Load dependencies
local screenManager = require("screens/screenManager")
screenManager:init() -- Init screen manager

-- Load shop
local shop = require("screens/shop")

print("--- Shop Loaded ---")

print("Calling shop:init()...")
shop:init()
print("shop.backgroundImage is: ", shop.backgroundImage)

print("Calling shop:enter()...")
shop:enter()
print("shop.backgroundImage is: ", shop.backgroundImage)
