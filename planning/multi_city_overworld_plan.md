# Multi-City Overworld Feature Implementation Plan

## Original Prompt

Right now the game has a city (overworld.lua) where the player acquire missions from various locations and them go to explore the dungeon, we will change this game loop a little.
What will have now is a proper overworld screen, representing something like a continent or country, they player will start in one of those cities (Kalzor, the one we have as the overworld today), and after reaching a certain amount of reputation, the player will them be able to go to the next city and continue its jorney.
As we will rename the overworld and now the player will go back to the last city it was instead of always going back to the overworld, we will need to save this last city at the save game, and we will need to change all the functions that call the overworld, to call the screen of this last city, we can only store the name of the city as the screen can be acessed at cities_definitions.lua by the field `screen`

We have our cities defined at @cities_definitions.lua, and the screens, will be stored at @screens\cities folder
Our current overworld screen, will now be `Delzor`, so we will need to rename it to delzor.lua and move it to @screens\cities.lua, we will them need to create a new overworld screen, that will have buttons leading to `delzor.lua` screen and to the new `kael.lua` screen. This last one will be the new city that we will create in addition to the one that we have. kael.lua will be very similar to delzor.lua but will use different images for smith, shop, inn, tavern and guild, and will have diffent quests available for the take. This quest filtering by location is something that will need to be added at each of of the screens where we can take quests (inn.lua, guild.lua, tavern.lua).

Quests at, @quest_definitions.lua, will change to have a new field, called `location`, this will be name of the city where the quest will be available. All the current that have levels from 1-5 will have `Delzor` as location, all the other ones will receive `kael` as location

Smithrecipes will need to change too, as they will have a location associated with them, this field will need to allow to a list of locations, so we can have a recipe in more than one location
Items will need to change too, as they will need a location field, where we can make an item be sold in one city, but not in others, this field will need to allow to a list of locations

## Changelog

- **2025-06-01** Initial plan creation. (Prompt: User request to plan multi-city overworld)

## Plan

### **Techincal Guidelines**
  * These guidelines have priority above anything else and should always be respected:
    * Follow the DRY principle as much as possible try to not repeat code
    * Do not change layout for any screens that you were not explicit asked too
    * Buttons are defined at screenManager.lua, use them
    * Fonts are defined at screenManager.lua, use them
    * Before using a function, validate if it in fact exist where you are calling it
    * Before require any file/module, validate its existance in the project
    * Do not run the game by yourself to test anything, I will run it later

### Phase 1: Core Structure and Data Definition Changes

1.  **Directory and File Structure Setup:**
    *   Create directory `screens/cities/`.
    *   Rename `screens/overworld.lua` to `screens/cities/delzor.lua`.
    *   Create a new placeholder file `screens/cities/kael.lua`. (This can initially be a copy of `delzor.lua` or a very basic screen structure).
    *   Create a new placeholder file `screens/overworld.lua` for the new continent/country map.

2.  **Update `data/cities_definitions.lua`:**
    *   Modify the entry for "Town of Delzor":
        *   Update `screen` to `"screens/cities/delzor.lua"`.
    *   Add a new entry for "Town of Kael":
        *   `name = "Town of Kael"`
        *   `description = "A prosperous city, known for its trade and industry."` (or similar)
        *   `image = "assets/cities/kael.png"` (placeholder, actual asset needed)
        *   `reputationNeeded = 100` (or as specified)
        *   `screen = "screens/cities/kael.lua"`
        *   `smithShop = "assets/KaelSmithScreen.png"` (placeholder, actual asset needed)
        *   `generalShop = "assets/KaelGeneralScreen.png"` (placeholder, actual asset needed)
        *   `inn = "assets/KaelInnScreen.png"` (placeholder, actual asset needed)
        *   `guild = "assets/KaelGuildScreen.png"` (placeholder, actual asset needed)
        *   `tavern = "assets/KaelTavernScreen.png"` (placeholder, actual asset needed)


3.  **Update `data/quest_definitions.lua`:**
    *   Add a new field `location` (string) to each quest definition.
    *   For existing quests:
        *   Assign `location = "Delzor"` for quests with levels 1-5.
        *   Assign `location = "Kael"` for all other quests.
    *   **Action:** Systematically go through all quests and add this field.

4.  **Update Smithing Recipes (`data/smithRecipes_definitions.lua`):**
    *   Add a new field `locations` (table/list of strings) to each smithing recipe definition.
    *   Example: `locations = {"Delzor", "Kael"}` or `locations = {"Delzor"}`.
    *   **Action:** Determine which recipes are available in which city and update accordingly. If the file doesn't exist, define its structure.


5.  **Update Item Definitions (`data/items_definitions.lua`):**
    *   Add a new field `locations` (table/list of strings) to each item definition (for items sold in shops).
    *   Example: `locations = {"Delzor"}` if an item is only sold in Delzor.
    *   **Action:** Determine which items are sold in which city shops and update accordingly.
    *   **Clarification:** Based on `shop.lua`, `data/items_definitions.lua` stores all items in the game, not just shop items. The shop system uses `itemSystem:getItemsByType()` to filter items by type (weapons, armor, accessories, consumables) and then filters out master tier items (tier 3). The shop's inventory is populated through the `shop:loadInventory()` function which calls these item system methods. Therefore, we should add the `locations` field to all item definitions, not just shop items.

### Phase 2: Save/Load System and Game State Management

1.  **Update `utils/saveLoad.lua`:**
    *   In `saveLoad:createProfile()`:
        *   Add `lastCity = "Delzor"` to the new profile data.
    *   In `saveLoad:saveGame()`:
        *   Ensure `gameData.lastCity = GAME.lastCity` (or similar global variable holding the current city name) is saved.
    *   In `saveLoad:applyLoadedData()`:
        *   Load `GAME.lastCity = gameData.lastCity or "Delzor"`. The fallback to "Delzor" handles older save files.
        *   Add `GAME.currentCityData` (table) to store the full definition of the current city from `cities_definitions.lua`. This should be populated after loading `GAME.lastCity` or when changing cities.

2.  **Global Game State (`main.lua` or a dedicated game state module):**
    *   Add `GAME.lastCity` (string) to store the name of the last visited city (e.g., "Delzor").
    *   Add `GAME.currentCityData` (table) to hold the full definition of the city the player is currently in (loaded from `cities_definitions.lua` based on `GAME.lastCity`). This will make accessing city-specific screen paths, names, and asset paths easier.
    *   When the game starts or a save is loaded, populate `GAME.currentCityData` based on `GAME.lastCity`.

### Phase 3: New Overworld Screen Implementation

1.  **Create `screens/overworld.lua` (New Continent Map):**
    *   **Dependencies:** `screenManager`, `assetManager`, `gameState`, `cities_definitions.lua` (or a way to access city data).
    *   **`init()` function:**
        *   Load background image for the continent map.
        *   Define UI elements (buttons) for each city defined in `cities_definitions.lua`.
            *   Button text should be the city name (e.g., "Town of Delzor").
            *   Store city data (name, screen path, `reputationNeeded`) with each button.
    *   **`update(dt)` function:**
        *   Handle button hover effects.
        *   Check player reputation (`GAME.reputation[reputationSystem.factions.GUILD]` or other specified reputation) against `city.reputationNeeded`. Disable/grey out buttons for cities the player cannot access yet. The reputation value to progress is the sum of all reputation values ( `GAME.reputation.GUILD` + `GAME.reputation.TAVERN`)
    *   **`draw()` function:**
        *   Draw background map.
        *   Draw city buttons. Visually indicate locked/unlocked cities.
        *   Display city names and perhaps a small icon or marker on the map.
        *   Display player's current relevant reputation score.
    *   **`mousepressed(x, y, button)` function:**
        *   If an unlocked city button is clicked:
            *   Update `GAME.lastCity` to the selected city's name.
            *   Update `GAME.currentCityData` with the selected city's data from `cities_definitions.lua`.
            *   Call `gameState:changeState(selectedCity.screen, { cityData = GAME.currentCityData })`, passing the city data to the city screen.
    *   **Navigation:**
        *   How does the player get TO this new overworld screen?
            *   From Main Menu -> New Game / Load Game -> Character Creation (if new) -> New Overworld (instead of directly to Delzor).
            *   From a city screen, there might be an "Exit to World Map" button.

### Phase 4: City Screen Modifications (Delzor & Kael)

1.  **Modify `screens/cities/delzor.lua` (formerly `screens/overworld.lua`):**
    *   **`enter(params)` function:**
        *   Receive `params.cityData`. If not provided (e.g., direct load into Delzor), load Delzor's data from `cities_definitions.lua`. Store this as `self.cityData`.
        *   Update `GAME.lastCity = self.cityData.name`.
        *   Update `GAME.currentCityData = self.cityData`.
    *   **`draw()` function:**
        *   Dynamically display the city name using `self.cityData.name` instead of the hardcoded "Town of Delzor". (e.g., `love.graphics.print(self.cityData.name, 20, 20)`).
    *   **Asset Loading:**
        *   Ensure building images (Smith, Shop, etc.) are loaded based on paths from `self.cityData` (e.g., `self.cityData.smithShop`). This might already be flexible if `assetManager` is used with keys.
    *   **Navigation:**
        *   The "Dungeon" button should still lead to the dungeon state.
        *   Change any "Return to Overworld" or similar logic to navigate back to the current city
        *   Calls like `gameState:changeState("overworld")` when exiting other states (e.g. inventory, character info from within a city) should now return to the current city screen. This means those states need to know where they were called *from*. A common pattern is `gameState:changeState("inventory", { from = gameState:getCurrentStateName() })`. The inventory screen's back button would then use this `from` parameter.

2.  **Implement `screens/cities/kael.lua`:**
    *   Start by copying `screens/cities/delzor.lua`.
    *   **`enter(params)` function:**
        *   Similar to `delzor.lua`, receive `params.cityData` for Kael.
        *   Update `GAME.lastCity = self.cityData.name`.
        *   Update `GAME.currentCityData = self.cityData`.
    *   **Asset Paths:**
        *   Ensure it uses Kael-specific image paths from `self.cityData` (e.g., `self.cityData.smithShop` which should point to `assets/KaelSmithScreen.png`). This requires the assets to be created and correctly referenced in `cities_definitions.lua`.
    *   **Quest Givers, Shops, Smithy:** These locations within Kael will need to be configured to show Kael-specific quests, items, and recipes (covered in Phase 5).
    *   **`draw()` function:**
        *   Display "Town of Kael" using `self.cityData.name`.

### Phase 5: Content Filtering in City Locations (Quests, Shops, Smithy)

1.  **Identify Quest-Giving Screens:**
    *   Likely candidates: `screens/guild.lua`, `screens/tavern.lua`.
    *   **Action:** Confirm these file paths.

2.  **Modify Quest-Giving Screens (e.g., `screens/guild.lua`):**
    *   **`enter(params)` or `init()`:**
        *   Needs access to the current city's name (e.g., from `GAME.currentCityData.name`).
    *   **Quest Loading/Display Logic:**
        *   When fetching or displaying available quests, filter them from `quest_definitions.lua` where `quest.location == GAME.currentCityData.name`.
    *   **Quest Loading Analysis:**
        *   **Tavern Quests:**
            *   Quests are loaded in `tavern:createUI()` and stored in `tavern.questList`
            *   Each quest is displayed in a panel with name, difficulty, level, and rewards
            *   Quests can be selected, viewed in detail, and accepted
            *   **Required Change:** Filter `tavern.questList` based on `GAME.currentCityData.name` when loading quests
        *   **Guild Quests:**
            *   Similar structure to tavern with `guild.questList`
            *   Uses a quest list panel and details panel
            *   **Required Change:** Filter `guild.questList` based on `GAME.currentCityData.name` when loading quests
        *   **Implementation Approach:**
            *   Add a `location` field to quest definitions in `quest_definitions.lua`
            *   When loading quests in both tavern and guild, filter using:
                ```lua
                for _, quest in pairs(allQuests) do
                    if quest.location == GAME.currentCityData.name then
                        table.insert(self.questList, quest)
                    end
                end
                ```

3.  **Identify Smithing Screen:**
    *   Likely `screens/smith.lua` or similar.
    *   **Action:** Confirm file path.

4.  **Modify Smithing Screen:**
    *   **`enter(params)` or `init()`:**
        *   Needs access to the current city's name (e.g., from `GAME.currentCityData.name`).
    *   **Recipe Loading/Display Logic:**
        *   When fetching or displaying available recipes from `smith_recipes_definitions.lua`, filter them. A recipe is available if `GAME.currentCityData.name` is present in the recipe's `locations` list.
        *   (e.g., `for _, recipe in pairs(all_recipes) do if table_contains(recipe.locations, GAME.currentCityData.name) then -- display recipe end end`)

5.  **Identify Shop Screen(s):**
    *   Likely `screens/shop.lua` or `screens/generalShop.lua`.
    *   **Action:** Confirm file path(s).

6.  **Modify Shop Screen(s):**
    *   **`enter(params)` or `init()`:**
        *   Needs access to the current city's name (e.g., from `GAME.currentCityData.name`).
    *   **Item Loading/Display Logic:**
        *   When fetching or displaying items for sale from `items_definitions.lua`, filter them. An item is available if `GAME.currentCityData.name` is present in the item's `locations` list.

### Phase 6: Updating Game Flow and Navigation

1.  **Review `gameState:changeState` calls:**
    *   Search codebase for all instances of `gameState:changeState("overworld", ...)`.
    *   These should be changed to navigate to the *last visited city screen*.
        *   This might involve `gameState:changeState(GAME.currentCityData.screen, { cityData = GAME.currentCityData })` or similar, assuming `GAME.currentCityData` holds the correct city information.
    *   Example: Exiting the dungeon. Instead of going to "overworld", it should go to the screen of the city from which the player entered the dungeon (which should be `GAME.lastCity` or `GAME.currentCityData.screen`). The dungeon state might need to be launched with `params.returnScreen = GAME.currentCityData.screen`.

2.  **Main Menu Flow:**
    *   `mainMenu.lua`'s `startNewGame()`:
        *   Should transition to the new `screens/overworld.lua` (continent map) after character creation (if applicable), or directly if no character creation.
        *   Alternatively, a new game could always start the player in "Delzor". In this case, after character creation:
            *   Set `GAME.lastCity = "Delzor"`.
            *   Load Delzor's data into `GAME.currentCityData`.
            *   `gameState:changeState(GAME.currentCityData.screen, { cityData = GAME.currentCityData })`.
    *   `mainMenu.lua`'s `loadSelectedGame()`:
        *   After loading game data (which now includes `lastCity`), use `GAME.lastCity` to determine which city screen to transition to.
            *   Load the correct city data into `GAME.currentCityData`.
            *   `gameState:changeState(GAME.currentCityData.screen, { cityData = GAME.currentCityData })`.

3.  **"Return to Title" / "Exit Game" from Cities/Overworld:**
    *   Ensure these functions correctly save game state if needed (including `lastCity`).

### Phase 7: Asset Creation and Integration

1.  **Create Kael-specific Assets:**
    *   Background image for Kael city screen (if different from Delzor's map).
    *   Images for Kael's Smith, General Shop, Inn, Guild, Tavern (as defined in `cities_definitions.lua`).
    *   Image for the "Town of Kael" marker/button on the new overworld map (`assets/cities/kael.png`).
    *   Background image for the new continent overworld screen. (use `assets/temp_continent.jpg` for now)

2.  **Integrate Assets:**
    *   Ensure all new assets are correctly referenced in `assetManager.lua` if it's used for preloading or managing assets by keys.
    *   Verify paths in `cities_definitions.lua` match actual asset locations.
