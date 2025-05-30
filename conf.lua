function love.conf(t)
    t.identity = "Lunarium"           -- The name of the save directory
    t.appendidentity = true                  -- Search files in source directory before save directory
    t.version = "11.4"                       -- The LÖVE version this game was made for
    t.console = true                         -- Attach a console (Windows only)
    
    t.window.title = "Lunarium"       -- The window title
    t.window.icon = nil                      -- Filepath to an image to use as the window's icon
    t.window.width = 1280                    -- The window width
    t.window.height = 720                    -- The window height
    t.window.borderless = false              -- Remove all border visuals from the window
    t.window.resizable = true                -- Let the window be user-resizable
    t.window.minwidth = 640                  -- Minimum window width if the window is resizable
    t.window.minheight = 360                 -- Minimum window height if the window is resizable
    t.window.fullscreen = false              -- Enable fullscreen
    t.window.fullscreentype = "desktop"      -- Standard fullscreen or desktop fullscreen mode
    t.window.vsync = 1                       -- Vertical sync mode (0 = off, 1 = on, 2 = adaptive)
    t.window.msaa = 0                        -- The number of samples to use with multi-sampled antialiasing
    t.window.depth = nil                     -- The number of bits per sample in the depth buffer
    t.window.stencil = nil                   -- The number of bits per sample in the stencil buffer
    
    t.modules.audio = true                   -- Enable the audio module
    t.modules.data = true                    -- Enable the data module
    t.modules.event = true                   -- Enable the event module
    t.modules.font = true                    -- Enable the font module
    t.modules.graphics = true                -- Enable the graphics module
    t.modules.image = true                   -- Enable the image module
    t.modules.joystick = true                -- Enable the joystick module
    t.modules.keyboard = true                -- Enable the keyboard module
    t.modules.math = true                    -- Enable the math module
    t.modules.mouse = true                   -- Enable the mouse module
    t.modules.physics = false                -- Enable the physics module
    t.modules.sound = true                   -- Enable the sound module
    t.modules.system = true                  -- Enable the system module
    t.modules.thread = true                  -- Enable the thread module
    t.modules.timer = true                   -- Enable the timer module
    t.modules.touch = true                   -- Enable the touch module
    t.modules.video = false                  -- Enable the video module
    t.modules.window = true                  -- Enable the window module
end
