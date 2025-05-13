#TODOs
- Level up screen has some overlap with the fonts asking the player to choose the path and the job list
- Reorganize the character creator screen to make it less tiresome (adding attributes is a pain)
- Check Message - ESCORT quest population not fully implemented. This is a console message that is being displayed
- Add full keyboard navigation to the combat UI
- Add "Decals" textures over walls and floor textures to make them look older or broken
- Add Textures for chests and other ground loot (maybe just a small bag)
- Add Traps - Check claude chat for the ideas
- Add more quests
- Add Unique items - They should have skills or powers that are unique to them - Ex. a mace that gives you detection power of a rogue
    - Prompt:
            We now need to implement unique items. They are magic items (only equipable items) that can have special behavior. This special behavior can trigger a different code path to change how a specific game rule works. Some examples are below. Keep in mind that they are just a limited set of examples and much more complex ones will be designed later. The idea is for those items to work the
            way that unique items work in Path of Exile, Last Epoch and Diablo 2 and the way that Legendary items work on Diablo 3 and Diablo 4

            Examples of behaviors a unique item can have:
                - Change damage type
                - Cause an enemy type to take increased damage (of all types or specific type)
                - Cause a character/party member/all party members to take less damage (of all types or specific type)
                - Cause a character/party member/all party members to take more damage (of all types or specific type)
                - Give a character a skill that it not at in any jobs' skill list
                - Make it easier to find loot that is rarer
                - Apply a specific status to an enemy or party member
                - Make the character minions stronger
                - Make the character minions be more/less likely to be choosen as target by the enemies 

            Now, with all these potential rules in memory, go throught the project code part responsible for combat, items, skills, monsters and characters, carefully analyze it and plan the best way to implement this system with the following priorities
            1. Data and new code paths for these special items should be very well separated and organized to make it easy to add and remove them
            2. Least amount of refactoring necessary. Big refactors cause all types of bugs and unpredictable behavior. We should keep changes to a minimum of
            3. Easy of testing. We should have a way to quickly add these items to the party (during development only) so we can test the items.
            4. As a bonus, try to plan a way to implement the system to support Set Items, those would work like how set items work in Diablo 2, Diablo 3, Last Epoch and Grim Dawn

            You should not implement any change for now, just carefuly create a plan that you can execute later after my review and changes


- Add a place to revive characters - This is problematic as we will need some kind o church on overworld map (need to be redraw)


#Bugs


#Ideias and Experimentation
- Change bitser for a text based save? Pros and Cons? Viability?

#Ideias for future features
- Crafting:
    - A job skill (or a skill that all jobs can get) that can learn to craft items instead of asking for the smith.
the crafting would be a reflex mini-game or something like that require a little skill but no luck. Maybe add a small luck component ?