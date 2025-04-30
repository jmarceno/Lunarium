# First Person Dungeon Crawler Game Guide

## Installation and Setup

### Requirements
- LÖVE (Love2D) framework version 11.4 or newer
- Recommended: at least 1GB of free RAM and a dedicated graphics card

### Steps to Install
1. Download and install LÖVE from https://love2d.org/
2. Download or clone this repository
3. Create the folder structure as shown in the README.md file
4. Make sure the bitser.lua library is in the lib folder

### Running the Game
- Windows: Drag the game folder onto love.exe or create a shortcut with the command:
  ```
  "C:\Program Files\LOVE\love.exe" path\to\game-folder
  ```
- macOS: Use the terminal command:
  ```
  /Applications/love.app/Contents/MacOS/love path/to/game-folder
  ```
- Linux: Use the command:
  ```
  love path/to/game-folder
  ```

## Game Overview

This is a first-person turn-based dungeon crawler RPG with the following features:
- First-person exploration using a raycaster engine
- Turn-based combat system
- Character progression with jobs, skills, and equipment
- Procedurally generated dungeons
- Quest system with rewards
- Item crafting from monster parts

## Controls

### General Controls
- **Mouse**: Navigate UI, select options
- **ESC**: Open menu/back
- **F1**: Toggle debug mode

### Dungeon Controls
- **W**: Move forward
- **S**: Move backward
- **A**: Turn left
- **D**: Turn right
- **Q**: Strafe left
- **E**: Strafe right
- **M**: Toggle minimap
- **SPACE**: Interact/attack
- **R**: Use item
- **TAB**: Open inventory

## Game Flow

1. **Main Menu**: Start a new game or load a saved game
2. **Character Creation**: Create a party of up to 4 characters
3. **Town (Overworld)**: Visit different locations:
   - **Tavern**: Find quests with negotiable rewards
   - **Guild**: Find reliable quests with fixed rewards
   - **Shop**: Buy items and equipment
   - **Smith**: Craft equipment from monster parts
   - **Dungeon**: Complete quests and find loot
4. **Dungeon**: Complete quests, defeat monsters, and find treasures
5. **Return to Town**: Turn in completed quests for rewards

## Character System

### Creating Characters
When starting a new game, you'll create a party of up to 4 characters. For each character, you'll:
1. Choose a starting job
2. Allocate attribute points
3. Name your character
4. Choose a profile image

### Attributes
- **STR (Strength)**: Affects physical damage and melee hit chance
- **INT (Intelligence)**: Affects magic power and mana
- **CON (Constitution)**: Affects health points
- **WIL (Will)**: Affects magic resistance and mana
- **CHA (Charisma)**: Affects NPC interactions and certain skills
- **DEX (Dexterity)**: Affects ranged attacks and dodge chance
- **WIS (Wisdom)**: Affects skill effectiveness and mana

### Job System
The game features a job system inspired by Final Fantasy Tactics:

#### Tier 1 (Basic Jobs)
- **Fighter**: Strong physical combatant with high HP and defense
- **Mage**: Elemental magic specialist with high MP
- **Rogue**: Fast attacker with high evasion and critical hits
- **Cleric**: Healing and support specialist

#### Tier 2 (Advanced Jobs)
- **Knight**: Heavy defensive fighter (requires Fighter)
- **Berserker**: Powerful offensive fighter (requires Fighter)
- **Black Mage**: Offensive magic specialist (requires Mage)
- **White Mage**: Healing magic specialist (requires Mage and Cleric)
- **Assassin**: Stealth and critical hit specialist (requires Rogue)
- **Ranger**: Ranged combat specialist (requires Rogue and Fighter)
- **Paladin**: Holy knight with healing abilities (requires Fighter and Cleric)

#### Tier 3 (Master Jobs)
- **Holy Knight**: Ultimate holy warrior (requires Paladin and Knight)
- **Archmage**: Ultimate magic user (requires Black Mage and White Mage)
- **Shadowblade**: Ultimate stealth assassin (requires Assassin and Black Mage)

### Skills
Each job has unique skills that characters can learn and use in combat. Skills include:
- Physical attacks
- Magical spells
- Healing abilities
- Support buffs
- Utility actions

Characters gain skill points when leveling up, which can be used to learn new skills or improve existing ones.

## Combat System

Combat is turn-based and occurs when encountering monsters in the dungeon:

1. **Turn Order**: Determined by character/enemy DEX (speed)
2. **Actions**:
   - **Attack**: Basic physical attack
   - **Skill**: Use a special ability (costs MP)
   - **Item**: Use a consumable item
   - **Defend**: Reduce damage until next turn
3. **Victory**: Gain experience, gold, and monster parts
4. **Defeat**: Return to town (lose some gold)

## Dungeon System

Dungeons are procedurally generated and feature:
- Multiple rooms and corridors
- Monsters to battle
- Treasure chests with loot
- Quest objectives to complete

The first-person view is rendered using a raycaster engine, providing a retro-style 3D experience similar to classic games like Doom and Wolfenstein 3D.

## Quest System

Quests can be obtained from the Guild and Tavern:
- **Guild Quests**: Reliable, fixed rewards
- **Tavern Quests**: Can haggle for better rewards but may be more difficult

Quest types include:
- **Kill**: Defeat specific monsters
- **Collect**: Gather specific items
- **Explore**: Reach a specific location
- **Escort**: Protect an NPC
- **Boss**: Defeat a powerful boss monster

## Item System

Items are categorized as:
- **Weapons**: Increase attack power
- **Armor**: Increase defense
- **Accessories**: Provide various stat bonuses
- **Consumables**: One-time use items with effects
- **Materials**: Used for crafting (including monster parts)

### Crafting
At the Smith, you can craft equipment using monster parts obtained from defeating enemies. Better quality parts create more powerful items.

## Tips for New Players

1. **Balanced Party**: Create a party with diverse jobs to handle different situations
2. **Resource Management**: Manage your HP, MP, and items carefully
3. **Upgrade Equipment**: Regularly upgrade your equipment at the Smith
4. **Quest Selection**: Choose quests appropriate for your party's level
5. **Save Often**: Save your game frequently to avoid losing progress

## Known Issues and Workarounds

- If the game freezes during dungeon generation, restart the game and try a different quest
- If sound effects don't play, verify that your system's audio is properly configured
- For performance issues, try disabling textures in the options menu

## Troubleshooting

If you encounter issues:
1. Verify that you have the latest version of LÖVE installed
2. Check that all files are in the correct directory structure
3. Look for error messages in the console output
4. Try restarting the game
5. If all else fails, check the LÖVE forums or submit an issue on the repository

## Extending the Game

See the README.md for information on how to extend the game with:
- New jobs
- New skills
- New items
- New quests
- Custom textures and sounds

## Credits

This game was created using LÖVE (Love2D) and the following libraries:
- Bitser: for serialization

Enjoy your adventure!
