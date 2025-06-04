### TODOs
- Review if attributes are influencing the parts of the game they are supposed to be influencing:
    "STR", -- Strength - affects physical damage and hit chance
    "INT", -- Intelligence - affects magic power and mana
    "CON", -- Constitution - affects health points
    "WIL", -- Will - affects magic resistance and mana
    "CHA", -- Charisma - affects NPC interactions and certain skills
    "DEX", -- Dexterity - affects ranged attacks and dodge chance
    "WIS"  -- Wisdom - affects skill effectiveness and mana
    Maybe we need to add a governingAttribute field to skills (skill_definitions.lua) ? Or could we find a better/cleaner way of doing it?

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

