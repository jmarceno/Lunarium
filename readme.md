# Dungeon RPG

A retro-style role-playing game built with LÖVE2D, featuring dungeon exploration, turn-based combat, and character progression.


## Overview

Dungeon RPG is a classic-inspired RPG featuring procedurally generated dungeons, a job-based character system, and quest-driven gameplay. The game combines elements of old-school dungeon crawlers with modern RPG mechanics.

## Features

### Character System
- **Multiple Jobs**: Fighter, Mage, Rogue, Cleric as base classes with advanced progression paths
- **Attribute-Based Stats**: STR, INT, CON, WIL, CHA, DEX, and WIS affecting various abilities
- **Job Progression**: Level up in multiple jobs and unlock advanced options like Knight, Berserker, and Archmage
- **Skills & Abilities**: Learn and upgrade skills specific to each job class
- **Equipment System**: Equip weapons, armor, and accessories with job requirements and stat bonuses

### Dungeon Exploration
- **First-Person Exploration**: Navigate dungeons from a first-person perspective
- **Procedural Generation**: Randomly generated dungeons with different layouts and themes
- **Fog of War**: Areas are revealed as you explore
- **Minimap**: Track your progress with a dynamic minimap
- **Encounter System**: Random and scripted encounters with enemies

### Combat System
- **Turn-Based Combat**: Strategic combat with various actions
- **Skill Usage**: Use job-specific skills in battle
- **Status Effects**: Apply and manage various status effects
- **Item Usage**: Utilize consumable items during battle
- **Rewards**: Gain experience, gold, and items from successful battles

### Quest System
- **Multiple Quest Types**: Kill, Collect, Explore, Escort, and Boss quests
- **Quest Rewards**: Earn experience, gold, and unique items
- **Difficulty Levels**: Quests of varying difficulty for different character levels
- **Quest Tracking**: Track active and completed quests

### Item System
- **Diverse Item Types**: Weapons, armor, accessories, consumables, and crafting materials
- **Unique Properties**: Items with special effects and bonuses
- **Monster Parts**: Collect parts from defeated enemies for crafting
- **Equipment Requirements**: Items with job and attribute requirements

### Town Locations
- **Tavern**: Accept quests and gather information
- **Guild**: Access official quests and services
- **Shop**: Purchase equipment and supplies
- **Smith**: Craft weapons and armor from monster parts

## Installation

1. Download and install [LÖVE2D](https://love2d.org/)
2. Download the game files
3. Run the game by dragging the game folder onto the LÖVE2D executable or use the command:
   ```
   love /path/to/game/folder
   ```

## Controls

- **W/A/S/D**: Move forward/left/backward/right
- **Q/E**: Strafe left/right
- **Mouse Click**: Interact with UI elements
- **I**: Open inventory
- **J**: Open quest log
- **K**: Toggle status bar
- **M**: Toggle minimap

## Development

The game is built with:
- [LÖVE2D](https://love2d.org/) - A framework for making 2D games in Lua
- Custom raycasting engine for dungeon rendering
- Component-based UI system
- Modular gameplay systems for easy expansion

## Credits

Dungeon RPG was created as a demonstration of game development techniques using LÖVE2D. It showcases procedural content generation, RPG systems design, and modular code architecture.