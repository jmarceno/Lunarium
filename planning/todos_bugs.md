### TODOs
- Add Textures for chests and other ground loot (maybe just a small bag)
- Add quests and other things tied to the lore documents
- How to deal with damage out of combat in the dungeon?
  - Deaths

- Add pain sounds - male and female

- Check if Walls and interactables detection is properly working

### Portraits
  - Not working on battle screen
  - Too Small on level up screen
  
- Check music on E:\Game Development\Sons\IDA_Music_Pack\Wavs\
- Check textures from F:\Backup\Game Development\Textures

- Check Message - ESCORT quest population not fully implemented. This is a console message that is being displayed
- Add full keyboard navigation to the combat UI
- Add "Decals" textures over walls and floor textures to make them look older or broken
- Add a place to revive characters - This is problematic as we will need some kind o church on overworld map (need to be redraw)
- Internacionalization
- Add more quests
- Quests:
  - Quest were someone was cursed and is haunting the dungeon (given on tavern as a more personal request)
  - Quest were someones wife/husbasd died and became an undead (given on tavern as a more personal request)
  - Final Job Progression Hidden Quests:
    - Some jobs could have final progressions that are hidden and only trigger after a certain condition
      - Example: After reaching level 20 as Necromancer a hidden quest can appear on the Inn, that once completed will allow the character to progress to from Necromancer to Lich


### Bugs


### Ideias and Experimentation
- Change bitser for a text based save? Pros and Cons? Viability?

### Ideias for future features
# Crafting:
    A job skill (or a skill that all jobs can get) that can learn to craft items instead of asking for the smith. the crafting would be a reflex mini-game or something like that require a little skill but no luck. Maybe add a small luck component ?


Right now the game has a city (overworld.lua) where the player acquire missions from various locations and them go to explore the dungeon, we will change this game loop a little.
What will have now is a proper overworld screen, representing something like a continent or country, they player will start in one of those cities (Kalzor, the one we have as the overworld today), and after reaching a certain amount of reputation, the player will them be able to go to the next city and continue its jorney.
As we will rename the overworld and now the player will go back to the last city it was instead of always going back to the overworld, we will need to save this last city at the save game, and we will need to change all the functions that call the overworld, to call the screen of this last city, we can only store the name of the city as the screen can be acessed at cities_definitions.lua by the field `screen`

We have our cities defined at @cities_definitions.lua, and the screens, will be stored at @screens\cities folder
Our current overworld screen, will now be `Delzor`, so we will need to rename it to delzor.lua and move it to @screens\cities.lua, we will them need to create a new overworld screen, that will have buttons leading to `delzor.lua` screen and to the new `kael.lua` screen. This last one will be the new city that we will create in addition to the one that we have. kael.lua will be very similar to delzor.lua but will use different images for smith, shop, inn, tavern and guild, and will have diffent quests available for the take. This quest filtering by location is something that will need to be added at each of of the screens where we can take quests (inn.lua, guild.lua, tavern.lua).

Quests at, @quest_definitions.lua, will change to have a new field, called `location`, this will be name of the city where the quest will be available. All the current that have levels from 1-5 will have `Delzor` as location, all the other ones will receive `kael` as location

Smithrecipes will need to change too, as they will have a location associated with them, this field will need to allow to a list of locations, so we can have a recipe in more than one location
Items will need to change too, as they will need a location field, where we can make an item be sold in one city, but not in others, this field will need to allow to a list of locations
