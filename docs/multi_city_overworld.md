# Multi-City Overworld System Documentation

This document outlines the implementation of the multi-city overworld system in the game. This system allows the player to travel between multiple cities, each with its own unique content, quests, and shop inventories.

## Core Concepts

1.  **Cities (`data/cities_definitions.lua`):**
    *   Each city is defined in `data/cities_definitions.lua`.
    *   Key properties for each city include:
        *   `name`: The display name of the city (e.g., "Town of Delzor").
        *   `description`: A brief description of the city.
        *   `image`: Path to the image asset used to represent the city on the overworld map.
        *   `reputationNeeded`: The total reputation (Guild + Tavern) required for the player to unlock and travel to this city.
        *   `screen`: The Lua script file that handles the city's main screen (e.g., `"screens/cities/delzor.lua"`).
        *   `smithShop`, `generalShop`, `inn`, `guild`, `tavern`: Paths to background image assets for the respective building interiors within that city.
        *   `screenBackgroundImage`: Path to the background image for the city's main screen.

2.  **Overworld Map (`screens/overworld.lua`):**
    *   This is a new screen that displays a map of the game world (continent/country).
    *   Buttons or markers on this map represent the available cities.
    *   Cities are unlocked based on player reputation.
    *   Clicking an unlocked city transitions the player to that city's main screen.
    *   The player's total reputation (Guild + Tavern) is displayed on this screen.

3.  **City Screens (e.g., `screens/cities/delzor.lua`, `screens/cities/kael.lua`):**
    *   These are the individual screens for each city. The original `screens/overworld.lua` was renamed to `screens/cities/delzor.lua` to become the first city.
    *   Each city screen is responsible for:
        *   Displaying the city's name and background image (defined in `cities_definitions.lua`).
        *   Providing clickable areas to navigate to different locations within the city (Smith, Shop, Inn, Guild, Tavern, Dungeon).
        *   Handling navigation back to the new Overworld Map screen.
    *   When entering a city screen, `GAME.lastCity` and `GAME.currentCityData` are updated.

4.  **Game State (`GAME` global table in `main.lua`):**
    *   `GAME.lastCity` (string): Stores the name of the last city the player visited. This is saved and loaded with the game.
    *   `GAME.currentCityData` (table): Stores the complete definition (from `cities_definitions.lua`) of the city the player is currently in. This is used by various screens to access city-specific information like asset paths and names.

5.  **Save/Load System (`utils/saveLoad.lua`):**
    *   The `lastCity` is now saved as part of the player's profile data.
    *   When a game is loaded:
        *   `GAME.lastCity` is restored.
        *   `GAME.currentCityData` is populated based on the loaded `GAME.lastCity`.
        *   If `lastCity` is missing from an old save file, it defaults to "Delzor".
    *   New profiles default `lastCity` to "Delzor".

## Content Filtering

Content such as quests, shop items, and smithing recipes are now filtered based on the player's current city:

1.  **Quests (`data/quest_definitions.lua`):**
    *   Each quest definition now has a `location` field (string), specifying the name of the city where the quest is available (e.g., `"Delzor"` or `"Kael"`).
    *   Quest-giving screens (e.g., `screens/guild.lua`, `screens/tavern.lua`) filter their quest lists to only show quests matching `GAME.currentCityData.name`.

2.  **Smithing Recipes (`data/smithRecipes_definitions.lua`):**
    *   Each smithing recipe definition now has a `locations` field (table of strings), specifying the names of the cities where the recipe is available (e.g., `{"Delzor", "Kael"}`).
    *   The smithing screen (`screens/smith.lua`) will filter recipes, showing only those where `GAME.currentCityData.name` is present in the recipe's `locations` list.

3.  **Items (`data/item_definitions.lua`):**
    *   Item definitions (for items sold in shops or potentially found as loot) now have a `locations` field (table of strings).
    *   Shop screens (`screens/shop.lua`) will filter items for sale, showing only those where `GAME.currentCityData.name` is present in the item's `locations` list.

## Navigation Flow Changes

*   **Main Menu:**
    *   Starting a new game or loading a game now transitions the player to the new Overworld Map screen (if `GAME.lastCity` implies the player was on the map) or directly to the `GAME.lastCity` screen.
*   **Exiting a City:**
    *   The "Exit to Main Menu" button in city screens (like Delzor or Kael) has been changed to "Exit to World Map", navigating to `screens/overworld.lua`.
    *   Pressing "Escape" in a city screen also navigates to the World Map.
*   **Returning from Dungeon/Other States:**
    *   When returning from states like the Dungeon, Inventory, or Character Info, the game now returns the player to the screen of the city they were in (`GAME.currentCityData.screen`) instead of a generic "overworld". This is managed by passing `fromScreen = gameState:getCurrentScreenName()` when changing to those states and using it to return.

## Asset Management

*   City-specific assets (backgrounds for city screens, building interiors) are defined in `data/cities_definitions.lua`.
*   The new Overworld Map uses `assets/temp_continent.jpg` as a placeholder background.
*   New assets for the city of Kael (e.g., `assets/KaelSmithScreen.png`, `assets/cities/kael.png`) need to be created and correctly referenced.

## Key File Modifications Summary

*   **`main.lua`**:
    *   Added `GAME.lastCity` and `GAME.currentCityData` to the global `GAME` table.
*   **`utils/saveLoad.lua`**:
    *   Modified `createProfile`, `saveGame`, and `applyLoadedData` to handle `lastCity` and initialize `currentCityData`.
*   **`data/cities_definitions.lua`**:
    *   Updated "Town of Delzor" entry.
    *   Added new entry for "Town of Kael" with its specific properties and asset paths.
    *   Added `screenBackgroundImage` field for city screen backgrounds.
*   **`data/quest_definitions.lua`**:
    *   Added `location` field to all quest definitions.
*   **`data/smithRecipes_definitions.lua`**:
    *   Added `locations` field (table of strings) to all smithing recipes.
*   **`data/item_definitions.lua`**:
    *   Added `locations` field (table of strings) to all item definitions.
*   **`screens/overworld.lua` (New File)**:
    *   Implements the new continent/country map screen.
    *   Displays cities from `cities_definitions.lua`.
    *   Handles city unlocking based on reputation (`GAME.reputation.GUILD + GAME.reputation.TAVERN`).
    *   Navigates to selected city screens.
*   **`screens/cities/delzor.lua` (Renamed from `screens/overworld.lua`)**:
    *   Modified to function as a specific city screen.
    *   Loads its data and background based on `self.cityData` (passed via `enter` or loaded from `citiesDefs`).
    *   Updates `GAME.lastCity` and `GAME.currentCityData`.
    *   "Exit" button now goes to the new Overworld Map.
*   **`screens/cities/kael.lua` (New File)**:
    *   A new city screen, similar in structure to `delzor.lua` but intended for Kael-specific assets and content.
    *   Loads its data and background based on `self.cityData`.
*   **`screens/guild.lua`, `screens/tavern.lua`**:
    *   Modified to filter quests based on `GAME.currentCityData.name` using the new `location` field in quests.
*   **`screens/inn.lua`**:
    *   Quest-related functionality has been removed as per user correction. Inns do not offer quests in this system.
*   **Other screens (e.g., `shop.lua`, `smith.lua`)**:
    *   These will require modification to filter their respective content (items, recipes) based on `GAME.currentCityData.name` and the new `locations` field in their data definitions. (This was part of the plan but specific implementation details for these screens are not covered in this summary of *already completed* changes). 