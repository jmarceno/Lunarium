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

## Content Expansion for New Cities (Updated)

The following cities have been expanded with comprehensive content:

### **Sahriq** (Desert City, reputation needed: 400)
*   **Quests (6 total):**
    *   Desert Bandits (Kill) - Level 4, Medium difficulty
    *   Oasis Protection (Kill) - Level 5, Medium difficulty  
    *   Ancient Relic Hunt (Collect) - Level 6, Medium difficulty
    *   Desert Caravan Escort (Escort) - Level 7, Hard difficulty
    *   The Bound Djinn (Boss) - Level 11, Hard difficulty
    *   The Great Sandworm (Boss) - Level 12, Hard difficulty
*   **Unique Items:** Desert Scimitar, Sand Walker Boots, Desert Robe, Sand Walker's Charm, Desert Remedy, Djinn's Blessing, Sandworm Slayer
*   **Crafting Materials:** Desert Sand (unique to Sahriq)
*   **Smith Recipes:** Desert-themed weapons and armor using desert-specific materials

### **Khulaan** (Steppe City, reputation needed: 600)
*   **Quests (6 total):**
    *   Horse Thieves (Kill) - Level 8, Medium difficulty
    *   Spirit Wolf Pack (Kill) - Level 9, Medium difficulty
    *   Shamanic Ingredients (Collect) - Level 10, Medium difficulty
    *   Tribal Diplomacy (Escort) - Level 11, Hard difficulty
    *   Thunder Horse Taming (Boss) - Level 13, Hard difficulty
    *   Sky Burial Guardian (Boss) - Level 14, Hard difficulty
*   **Unique Items:** Steppe Spear, Nomad Leathers, Wolf Spirit Totem, Shamanic Brew, Storm Rider's Cloak, Ancestral Blade, Peacemaker's Medal
*   **Crafting Materials:** Wolf Pelt and existing materials for steppe-themed crafting
*   **Smith Recipes:** Nomadic weapons and spiritual accessories

### **Vargstad** (Mountain/Coastal City, reputation needed: 800)
*   **Quests (6 total):**
    *   Frost Giant Raids (Kill) - Level 12, Hard difficulty
    *   Mystery of the Northern Lights (Explore) - Level 14, Hard difficulty
    *   Viking Funeral Rites (Escort) - Level 15, Hard difficulty
    *   Sea Serpent Menace (Boss) - Level 16, Hard difficulty
    *   Into the Kraken's Depths (Boss) - Level 18, Hard difficulty
    *   The Dragon King's Awakening (Boss) - Level 20, Hard difficulty
*   **Unique Items:** Frostbite Axe, Viking Chainmail, Seafoam Trident, Aurora Stone, Kraken's Heart, Dragonslayer, Honored Warrior's Axe, Serpent's Bane Harpoon
*   **Crafting Materials:** Ice Crystal, Sea Pearl (unique to Vargstad)
*   **Smith Recipes:** High-tier northern and naval-themed equipment

### **Reputation Progression Balance**
Each city provides sufficient quest rewards to enable progression to the next city:
*   **Delzor → Kael:** 200 reputation needed
*   **Kael → Sahriq:** 400 reputation needed  
*   **Sahriq → Khulaan:** 600 reputation needed
*   **Khulaan → Vargstad:** 800 reputation needed

The quest rewards scale appropriately with city difficulty, ensuring players can accumulate enough reputation through completing available quests in each location. 