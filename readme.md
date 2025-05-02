# First Person Dungeon Crawler Game

A turn-based first-person dungeon crawler game built with LÖVE (Love2D).

## Features

- First-person raycaster rendering
- Turn-based combat system
- Job system inspired by Final Fantasy Tactics
- Character creation and progression
- Procedurally generated dungeons
- Quest system with rewards
- Item crafting from monster parts
- Shop for buying and selling items

## Requirements

- [LÖVE](https://love2d.org/) version 11.4 or newer

## Setup

1. Install LÖVE from https://love2d.org/
2. Clone or download this repository
3. Create the following folder structure:

```
my-game/
├── main.lua
├── conf.lua
├── assets/
├── engine/
├── gameplay/
├── lib/
│   └── bitser.lua
├── screens/
├── states/
└── utils/
```

4. Download the [bitser](https://github.com/gvx/bitser) library and place it in the `lib/` folder.
5. Copy all the Lua files from this project into their respective folders.

## Running the Game

### Windows
Drag the game folder onto `love.exe` or run:
```
"C:\Program Files\LOVE\love.exe" path\to\my-game
```

### macOS
```
/Applications/love.app/Contents/MacOS/love path/to/my-game
```

### Linux
```
love path/to/my-game
```

## Controls

- **W, A, S, D**: Move forward/backward and turn left/right in dungeon
- **Q, E**: Strafe left/right in dungeon
- **Space**: Attack/interact
- **Tab**: Open menu
- **Mouse**: Navigate UI, select options

## Game Screens

### Main Menu
- Start a new game
- Load saved games
- Options
- About

### Character Creator
- Create a party of up to 4 characters
- Choose jobs, allocate attributes, and name characters

### Overworld
- Navigate between town locations:
  - Tavern: Find quests with negotiable rewards
  - Guild: Find reliable quests with fixed rewards
  - Shop: Buy items and equipment
  - Smith: Craft equipment from monster parts
  - Dungeon: Complete quests and find loot

### Dungeon
- First-person exploration
- Turn-based combat
- Find treasure chests and monster parts
- Complete quest objectives

## Game Systems

### Character System
- Job-based progression
- Level up to improve attributes
- Learn skills based on job

### Job System
- Base jobs: Fighter, Mage, Rogue, Cleric
- Advanced jobs: Knight, Berserker, Black Mage, White Mage, etc.
- Master jobs: Holy Knight, Archmage, Shadowblade, etc.

### Combat System
- Turn-based with multiple actions
- Physical and magical attacks
- Skills with various effects
- Item usage

### Quest System
- Different quest types: kill, collect, explore, escort, boss
- Rewards include gold and items
- Haggle for better rewards in the tavern

### Crafting System
- Collect monster parts from defeated enemies
- Use parts to craft weapons, armor, and accessories at the smith

## Extending the Game

### Adding New Jobs
Add new job definitions to `gameplay/job.lua` following the existing format.

### Adding New Skills
Add new skill definitions to `gameplay/skill.lua` following the existing format.

### Adding New Items
Add new item definitions to `gameplay/item.lua` following the existing format.

### Adding New Quests
Add new quest templates to `gameplay/questSystem.lua` following the existing format.

### Adding Textures
Replace placeholder solid colors with actual textures by adding image files to an `assets/images/` folder and updating the `assetManager.lua` file.

### Adding Sound Effects and Music
Add sound files to an `assets/sounds/` and `assets/music/` folders and update the `assetManager.lua` file.

## UI Sound Effects

The game includes a sound effect system for UI buttons. By default, all buttons play hover and click sounds.

### Customizing Button Sounds

You can customize the sounds globally:

```lua
local assets = require("assets/assetManager")

-- Set volume for all button sounds
assets:setButtonSoundVolume(0.5) -- Set to a value between 0 and 1

-- Replace button sounds with new ones
assets:setButtonSounds("path/to/new_hover.wav", "path/to/new_click.wav")
```

For individual buttons, you can customize or disable sounds:

```lua
-- Create a button with custom sounds
local myButton = screenManager.UI.Button(x, y, width, height, "Text", callback)
    :setSounds("custom_hover", "custom_click") -- Use sound names from assetManager.sounds
    
-- Or disable sounds for a specific button
local silentButton = screenManager.UI.Button(x, y, width, height, "Silent", callback)
    :enableSounds(false)
```

### Sound Files

The default button sounds are located in:
- `assets/Sounds/button_hover.wav` - Played when hovering over a button
- `assets/Sounds/button_click.wav` - Played when clicking a button

Replace these files to change the default sounds for all buttons.

## License

This game is provided as-is for educational purposes.
