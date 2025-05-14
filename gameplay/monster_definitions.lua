-- Monster Definitions
-- Contains all monster definitions and ID mappings

local monsterDefinitions = {}

-- Monster definitions
monsterDefinitions.monsters = {
    -- Bloomers (Fungal monsters)
    ["fungal_fighter"] = {
        id = "fungal_fighter",
        name = "Fungal Fighter",
        stats = { 
            level = 1, 
            hp = 15, 
            attack = 4, 
            defense = 2, 
            speed = 7,
            magicAttack = 3
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.7 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -30, -- Resistant to poison (takes 30% less damage)
            ["fire"] = 25     -- Vulnerable to fire (takes 25% more damage)
        },
        immunities = {},
        color = {0.5, 0.8, 0.5},
        sprite = "assets/Sprites/Enemies/Bloomers/fungal_fighter.png",
        category = "Bloomers"
    },
    ["shroomling"] = {
        id = "shroomling",
        name = "Shroomling",
        stats = { 
            level = 1, 
            hp = 12, 
            attack = 3, 
            defense = 1, 
            speed = 9,
            magicAttack = 4
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "infected_bite", chanceToUse = 0.4 }
        },
        resistances = {
            ["poison"] = -50, -- Very resistant to poison
            ["fire"] = 30     -- Vulnerable to fire
        },
        immunities = {},
        color = {0.6, 0.7, 0.4},
        sprite = "assets/Sprites/Enemies/Bloomers/shroomling.png",
        category = "Bloomers"
    },
    ["walking_mushroom"] = {
        id = "walking_mushroom",
        name = "Walking Mushroom",
        stats = { 
            level = 2, 
            hp = 20, 
            attack = 5, 
            defense = 3, 
            speed = 6,
            magicAttack = 6
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "toxic_spores", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -40,
            ["fire"] = 35,
            ["ice"] = -10
        },
        immunities = {},
        color = {0.7, 0.5, 0.6},
        sprite = "assets/Sprites/Enemies/Bloomers/walking_mushroom.png",
        category = "Bloomers"
    },
    ["toxic_sporeling"] = {
        id = "toxic_sporeling",
        name = "Toxic Sporeling",
        stats = { 
            level = 3, 
            hp = 25, 
            attack = 7, 
            defense = 4, 
            speed = 8,
            magicAttack = 9
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.3 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "toxic_spores", chanceToUse = 0.4 }
        },
        resistances = {
            ["poison"] = -70,    -- Very resistant to poison
            ["fire"] = 40,       -- Very vulnerable to fire
            ["necrotic"] = -20   -- Somewhat resistant to necrotic
        },
        immunities = {},
        color = {0.3, 0.7, 0.3},
        sprite = "assets/Sprites/Enemies/Bloomers/toxic_sporeling.png",
        category = "Bloomers"
    },
    ["fungal_rat"] = {
        id = "fungal_rat",
        name = "Fungal Rat",
        stats = { 
            level = 2, 
            hp = 18, 
            attack = 6, 
            defense = 2, 
            speed = 10,
            magicAttack = 4
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.7 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -30,
            ["fire"] = 25
        },
        immunities = {},
        color = {0.5, 0.6, 0.5},
        sprite = "assets/Sprites/Enemies/Bloomers/fungal_rat.png",
        category = "Bloomers"
    },
    ["fungal_zombie"] = {
        id = "fungal_zombie",
        name = "Fungal Zombie",
        stats = { 
            level = 4, 
            hp = 35, 
            attack = 9, 
            defense = 5, 
            speed = 5,
            magicAttack = 7
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.3 },
            { id = "infected_bite", chanceToUse = 0.4 },
            { id = "toxic_spores", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -60,
            ["fire"] = 30,
            ["necrotic"] = -40,
            ["physical"] = -20
        },
        immunities = {},
        color = {0.4, 0.6, 0.4},
        sprite = "assets/Sprites/Enemies/Bloomers/fungal_zombie.png",
        category = "Bloomers"
    },
    
    -- Cultists
    ["cultists_initiate"] = {
        id = "cultists_initiate",
        name = "Cultist Initiate",
        stats = { 
            level = 2, 
            hp = 22, 
            attack = 6, 
            defense = 3, 
            speed = 8,
            magicAttack = 7
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "fireball", chanceToUse = 0.4 }
        },
        resistances = {
            ["fire"] = -20,
            ["arcane"] = -10
        },
        immunities = {},
        color = {0.7, 0.2, 0.2},
        sprite = "assets/Sprites/Enemies/Cultists/cultists_initiate.png",
        category = "Cultists"
    },
    ["hooded_cultist"] = {
        id = "hooded_cultist",
        name = "Hooded Cultist",
        stats = { 
            level = 3, 
            hp = 28, 
            attack = 7, 
            defense = 4, 
            speed = 7,
            magicAttack = 9
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.4 },
            { id = "fireball", chanceToUse = 0.4 },
            { id = "flames_of_agony", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -30,
            ["arcane"] = -20,
            ["ice"] = 25
        },
        immunities = {},
        color = {0.6, 0.3, 0.3},
        sprite = "assets/Sprites/Enemies/Cultists/hooded_cultist.png",
        category = "Cultists"
    },
    ["cult_warlock"] = {
        id = "cult_warlock",
        name = "Cult Warlock",
        stats = { 
            level = 5, 
            hp = 40, 
            attack = 10, 
            defense = 6, 
            speed = 9,
            magicAttack = 14
        },
        abilities = {
            { id = "fireball", chanceToUse = 0.3 },
            { id = "flames_of_agony", chanceToUse = 0.3 },
            { id = "fire_breath", chanceToUse = 0.2 },
            { id = "protective_aura", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -50,
            ["arcane"] = -30,
            ["ice"] = 40,
            ["physical"] = 20
        },
        immunities = {},
        color = {0.5, 0.1, 0.5},
        sprite = "assets/Sprites/Enemies/Cultists/cult_warlock.png",
        category = "Cultists"
    },
    ["cultist_pyromancer"] = {
        id = "cultist_pyromancer",
        name = "Cultist Pyromancer",
        stats = { 
            level = 6, 
            hp = 45, 
            attack = 12, 
            defense = 5, 
            speed = 8,
            magicAttack = 17
        },
        abilities = {
            { id = "fireball", chanceToUse = 0.2 },
            { id = "flames_of_agony", chanceToUse = 0.3 },
            { id = "fire_breath", chanceToUse = 0.3 },
            { id = "strengthen_allies", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -70,
            ["arcane"] = -20,
            ["ice"] = 50,
            ["lightning"] = 20
        },
        immunities = {"fire"},
        color = {0.8, 0.4, 0.1},
        sprite = "assets/Sprites/Enemies/Cultists/cultist_pyromancer.png",
        category = "Cultists"
    },
    ["plague_cultist"] = {
        id = "plague_cultist",
        name = "Plague Cultist",
        stats = { 
            level = 4, 
            hp = 32, 
            attack = 9, 
            defense = 5, 
            speed = 7,
            magicAttack = 12
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.3 },
            { id = "toxic_spores", chanceToUse = 0.4 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -60,
            ["necrotic"] = -30,
            ["fire"] = -10,
            ["lightning"] = 25
        },
        immunities = {},
        color = {0.3, 0.6, 0.3},
        sprite = "assets/Sprites/Enemies/Cultists/plague_cultist.png",
        category = "Cultists"
    },
    
    -- Undead
    ["zombie_farmer"] = {
        id = "zombie_farmer",
        name = "Zombie Farmer",
        stats = { 
            level = 1, 
            hp = 18, 
            attack = 5, 
            defense = 2, 
            speed = 4,
            magicAttack = 2
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.8 },
            { id = "bite_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["necrotic"] = -50,
            ["poison"] = -30,
            ["fire"] = 30,
            ["lightning"] = 10
        },
        immunities = {},
        color = {0.5, 0.5, 0.3},
        sprite = "assets/Sprites/Enemies/Undead/zombie_farmer.png",
        category = "Undead"
    },
    ["zombie_biter"] = {
        id = "zombie_biter",
        name = "Zombie Biter",
        stats = { 
            level = 2, 
            hp = 25, 
            attack = 7, 
            defense = 3, 
            speed = 6,
            magicAttack = 3
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.6 },
            { id = "infected_bite", chanceToUse = 0.4 }
        },
        resistances = {
            ["necrotic"] = -60,
            ["poison"] = -40,
            ["fire"] = 40,
            ["lightning"] = 20
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "assets/Sprites/Enemies/Undead/zombie_biter.png",
        category = "Undead"
    },
    ["skeletal_hound"] = {
        id = "skeletal_hound",
        name = "Skeletal Hound",
        stats = { 
            level = 3, 
            hp = 22, 
            attack = 8, 
            defense = 3, 
            speed = 11,
            magicAttack = 5
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.6 },
            { id = "bleeding_slash", chanceToUse = 0.4 }
        },
        resistances = {
            ["necrotic"] = -70,
            ["poison"] = -50,
            ["fire"] = 20,
            ["lightning"] = 10,
            ["piercing"] = 20,
            ["slashing"] = -20
        },
        immunities = {},
        color = {0.8, 0.8, 0.8},
        sprite = "assets/Sprites/Enemies/Undead/skeletal_hound.png",
        category = "Undead"
    },
    ["skeleton_warrior"] = {
        id = "skeleton_warrior",
        name = "Skeleton Warrior",
        stats = { 
            level = 3, 
            hp = 30, 
            attack = 9, 
            defense = 6, 
            speed = 7,
            magicAttack = 4
        },
        abilities = {
            { id = "claw_attack", chanceToUse = 0.3 },
            { id = "bleeding_slash", chanceToUse = 0.5 },
            { id = "slam_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["necrotic"] = -60,
            ["poison"] = -80,
            ["fire"] = 10,
            ["lightning"] = 20,
            ["piercing"] = 30,
            ["slashing"] = -10
        },
        immunities = {"poison"},
        color = {0.9, 0.9, 0.7},
        sprite = "assets/Sprites/Enemies/Undead/skeleton_warrior.png",
        category = "Undead"
    },
    ["ghoul_stalker"] = {
        id = "ghoul_stalker",
        name = "Ghoul Stalker",
        stats = { 
            level = 4, 
            hp = 35, 
            attack = 10, 
            defense = 5, 
            speed = 9,
            magicAttack = 7
        },
        abilities = {
            { id = "claw_attack", chanceToUse = 0.3 },
            { id = "bleeding_slash", chanceToUse = 0.3 },
            { id = "infected_bite", chanceToUse = 0.4 }
        },
        resistances = {
            ["necrotic"] = -70,
            ["poison"] = -40,
            ["fire"] = 35,
            ["lightning"] = 20,
            ["arcane"] = 10
        },
        immunities = {},
        color = {0.5, 0.5, 0.6},
        sprite = "assets/Sprites/Enemies/Undead/ghoul_stalker.png",
        category = "Undead"
    },
    ["tormented_ghoul"] = {
        id = "tormented_ghoul",
        name = "Tormented Ghoul",
        stats = { 
            level = 5, 
            hp = 45, 
            attack = 12, 
            defense = 7, 
            speed = 8,
            magicAttack = 10
        },
        abilities = {
            { id = "claw_attack", chanceToUse = 0.2 },
            { id = "bleeding_slash", chanceToUse = 0.3 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "death_touch", chanceToUse = 0.2 }
        },
        resistances = {
            ["necrotic"] = -80,
            ["poison"] = -50,
            ["fire"] = 40,
            ["lightning"] = 30,
            ["arcane"] = 20
        },
        immunities = {},
        color = {0.6, 0.5, 0.7},
        sprite = "assets/Sprites/Enemies/Undead/tormented_ghoul.png",
        category = "Undead"
    },
    
    -- Insects
    ["horned_beetle"] = {
        id = "horned_beetle",
        name = "Horned Beetle",
        stats = { 
            level = 1, 
            hp = 20, 
            attack = 6, 
            defense = 7, 
            speed = 6,
            magicAttack = 2
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.8 },
            { id = "slam_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["slashing"] = -40,
            ["bludgeoning"] = -20,
            ["piercing"] = 40,
            ["fire"] = 20
        },
        immunities = {},
        color = {0.5, 0.3, 0.1},
        sprite = "assets/Sprites/Enemies/Insects/horned_beetle.png",
        category = "Insects"
    },
    ["buzzer"] = {
        id = "buzzer",
        name = "Buzzer",
        stats = { 
            level = 2, 
            hp = 15, 
            attack = 5, 
            defense = 3, 
            speed = 12,
            magicAttack = 3
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.4 },
            { id = "bite_attack", chanceToUse = 0.4 },
            { id = "infected_bite", chanceToUse = 0.2 }
        },
        resistances = {
            ["piercing"] = -20,
            ["bludgeoning"] = 20,
            ["ice"] = 30
        },
        immunities = {},
        color = {0.7, 0.7, 0.2},
        sprite = "assets/Sprites/Enemies/Insects/buzzer.png",
        category = "Insects"
    },
    ["armored_ant"] = {
        id = "armored_ant",
        name = "Armored Ant",
        stats = { 
            level = 3, 
            hp = 28, 
            attack = 7, 
            defense = 9, 
            speed = 7,
            magicAttack = 4
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "slam_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["slashing"] = -50,
            ["piercing"] = -30,
            ["bludgeoning"] = 20,
            ["fire"] = 30,
            ["poison"] = -10
        },
        immunities = {},
        color = {0.4, 0.3, 0.2},
        sprite = "assets/Sprites/Enemies/Insects/armored_ant.png",
        category = "Insects"
    },
    ["mantis_warrior"] = {
        id = "mantis_warrior",
        name = "Mantis Warrior",
        stats = { 
            level = 4, 
            hp = 35, 
            attack = 12, 
            defense = 6, 
            speed = 10,
            magicAttack = 5
        },
        abilities = {
            { id = "claw_attack", chanceToUse = 0.4 },
            { id = "bleeding_slash", chanceToUse = 0.4 },
            { id = "sweep_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["slashing"] = -20,
            ["bludgeoning"] = 30,
            ["fire"] = 20,
            ["ice"] = 10
        },
        immunities = {},
        color = {0.2, 0.7, 0.3},
        sprite = "assets/Sprites/Enemies/Insects/mantis_warrior.png",
        category = "Insects"
    },
    ["wasp_demon"] = {
        id = "wasp_demon",
        name = "Wasp Demon",
        stats = { 
            level = 5, 
            hp = 40, 
            attack = 13, 
            defense = 5, 
            speed = 13,
            magicAttack = 8
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.3 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "toxic_spores", chanceToUse = 0.2 },
            { id = "concussive_blow", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -40,
            ["piercing"] = -20,
            ["bludgeoning"] = 30,
            ["fire"] = 20
        },
        immunities = {},
        color = {0.8, 0.5, 0.1},
        sprite = "assets/Sprites/Enemies/Insects/wasp_demon.png",
        category = "Insects"
    },
    
    -- Bosses
    ["spore_witch_boss"] = {
        id = "spore_witch_boss",
        name = "Spore Witch",
        stats = { 
            level = 6, 
            hp = 150, 
            attack = 15, 
            defense = 10, 
            speed = 9,
            magicAttack = 18
        },
        abilities = {
            { id = "toxic_spores", chanceToUse = 0.3 },
            { id = "strengthen_allies", chanceToUse = 0.2 },
            { id = "protective_aura", chanceToUse = 0.2 },
            { id = "silence_spell", chanceToUse = 0.2 },
            { id = "slam_attack", chanceToUse = 0.1 }
        },
        resistances = {
            ["poison"] = -80,
            ["necrotic"] = -50,
            ["fire"] = 60,
            ["ice"] = -30,
            ["arcane"] = -20
        },
        immunities = {"poison"},
        color = {0.3, 0.7, 0.2},
        sprite = "assets/Sprites/Enemies/Bloomers/spore_witch_BOSS.png",
        category = "Bloomers",
        isBoss = true
    },
    ["spore_lord_boss"] = {
        id = "spore_lord_boss",
        name = "Spore Lord",
        stats = { 
            level = 8, 
            hp = 200, 
            attack = 18, 
            defense = 14, 
            speed = 7,
            magicAttack = 22
        },
        abilities = {
            { id = "toxic_spores", chanceToUse = 0.2 },
            { id = "death_touch", chanceToUse = 0.2 },
            { id = "strengthen_allies", chanceToUse = 0.2 },
            { id = "protective_aura", chanceToUse = 0.2 },
            { id = "sweep_attack", chanceToUse = 0.1 },
            { id = "arcane_explosion", chanceToUse = 0.1 }
        },
        resistances = {
            ["poison"] = -90,
            ["necrotic"] = -70,
            ["fire"] = 70,
            ["ice"] = -40,
            ["arcane"] = -30,
            ["physical"] = -20
        },
        immunities = {"poison", "necrotic"},
        color = {0.2, 0.6, 0.3},
        sprite = "assets/Sprites/Enemies/Bloomers/spore_lord_BOSS.png",
        category = "Bloomers",
        isBoss = true
    },
    ["chanting_fanatic_boss"] = {
        id = "chanting_fanatic_boss",
        name = "Chanting Fanatic",
        stats = { 
            level = 7, 
            hp = 180, 
            attack = 17, 
            defense = 12, 
            speed = 10,
            magicAttack = 20
        },
        abilities = {
            { id = "fire_breath", chanceToUse = 0.2 },
            { id = "flames_of_agony", chanceToUse = 0.2 },
            { id = "silence_spell", chanceToUse = 0.2 },
            { id = "strengthen_allies", chanceToUse = 0.2 },
            { id = "slam_attack", chanceToUse = 0.1 },
            { id = "arcane_explosion", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -80,
            ["arcane"] = -60,
            ["ice"] = 60,
            ["lightning"] = 40,
            ["necrotic"] = -20,
            ["poison"] = 20
        },
        immunities = {"fire"},
        color = {0.7, 0.2, 0.4},
        sprite = "assets/Sprites/Enemies/Cultists/chanting_fanatic_BOSS.png",
        category = "Cultists",
        isBoss = true
    },
    ["demonic_leader_boss"] = {
        id = "demonic_leader_boss",
        name = "Demonic Leader",
        stats = { 
            level = 10, 
            hp = 250, 
            attack = 22, 
            defense = 16, 
            speed = 11,
            magicAttack = 25
        },
        abilities = {
            { id = "fire_breath", chanceToUse = 0.2 },
            { id = "arcane_explosion", chanceToUse = 0.2 },
            { id = "death_touch", chanceToUse = 0.2 },
            { id = "sweep_attack", chanceToUse = 0.1 },
            { id = "strengthen_allies", chanceToUse = 0.2 },
            { id = "silence_spell", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -80,
            ["arcane"] = -80,
            ["necrotic"] = -60,
            ["ice"] = 70,
            ["lightning"] = 50,
            ["physical"] = -30,
            ["poison"] = -20
        },
        immunities = {"fire", "arcane"},
        color = {0.8, 0.1, 0.1},
        sprite = "assets/Sprites/Enemies/Cultists/demonic_leader_BOSS.png",
        category = "Cultists",
        isBoss = true
    },
    ["skeleton_general_boss"] = {
        id = "skeleton_general_boss",
        name = "Skeleton General",
        stats = { 
            level = 8, 
            hp = 190, 
            attack = 19, 
            defense = 15, 
            speed = 9,
            magicAttack = 14
        },
        abilities = {
            { id = "slam_attack", chanceToUse = 0.2 },
            { id = "sweep_attack", chanceToUse = 0.2 },
            { id = "bleeding_slash", chanceToUse = 0.2 },
            { id = "death_touch", chanceToUse = 0.2 },
            { id = "strengthen_allies", chanceToUse = 0.2 }
        },
        resistances = {
            ["necrotic"] = -80,
            ["poison"] = -90,
            ["fire"] = 30,
            ["lightning"] = 40,
            ["piercing"] = 50,
            ["slashing"] = -20,
            ["bludgeoning"] = 40
        },
        immunities = {"poison", "necrotic"},
        color = {0.7, 0.7, 0.5},
        sprite = "assets/Sprites/Enemies/Undead/skeleton_general_BOSS.png",
        category = "Undead",
        isBoss = true
    },
    ["lich_king_boss"] = {
        id = "lich_king_boss",
        name = "Lich King",
        stats = { 
            level = 12, 
            hp = 300, 
            attack = 25, 
            defense = 18, 
            speed = 8,
            magicAttack = 30
        },
        abilities = {
            { id = "death_touch", chanceToUse = 0.25 },
            { id = "arcane_explosion", chanceToUse = 0.25 },
            { id = "silence_spell", chanceToUse = 0.2 },
            { id = "protective_aura", chanceToUse = 0.15 },
            { id = "strengthen_allies", chanceToUse = 0.15 }
        },
        resistances = {
            ["necrotic"] = -90,
            ["poison"] = -90,
            ["arcane"] = -70,
            ["fire"] = 40,
            ["lightning"] = 40,
            ["ice"] = 40,
            ["physical"] = -50
        },
        immunities = {"poison", "necrotic", "arcane"},
        color = {0.3, 0.3, 0.8},
        sprite = "assets/Sprites/Enemies/Undead/lich_king_BOSS.png",
        category = "Undead",
        isBoss = true
    },
    ["matron_zirrk_boss"] = {
        id = "matron_zirrk_boss",
        name = "Matron Zirrk",
        stats = { 
            level = 9, 
            hp = 220, 
            attack = 20, 
            defense = 16, 
            speed = 12,
            magicAttack = 18
        },
        abilities = {
            { id = "toxic_spores", chanceToUse = 0.2 },
            { id = "infected_bite", chanceToUse = 0.2 },
            { id = "bleeding_slash", chanceToUse = 0.2 },
            { id = "sweep_attack", chanceToUse = 0.2 },
            { id = "concussive_blow", chanceToUse = 0.1 },
            { id = "strengthen_allies", chanceToUse = 0.1 }
        },
        resistances = {
            ["poison"] = -80,
            ["piercing"] = -60,
            ["slashing"] = -40,
            ["bludgeoning"] = 40,
            ["fire"] = 60,
            ["lightning"] = 20
        },
        immunities = {"poison"},
        color = {0.3, 0.6, 0.1},
        sprite = "assets/Sprites/Enemies/Insects/matron_zirrk_BOSS.png",
        category = "Insects",
        isBoss = true
    },
    ["vengeful_spirit_boss"] = {
        id = "vengeful_spirit_boss",
        name = "Vengeful Spirit",
        stats = { 
            level = 11, 
            hp = 270, 
            attack = 23, 
            defense = 17, 
            speed = 11,
            magicAttack = 28
        },
        abilities = {
            { id = "death_touch", chanceToUse = 0.25 },
            { id = "arcane_explosion", chanceToUse = 0.25 },
            { id = "silence_spell", chanceToUse = 0.2 },
            { id = "protective_aura", chanceToUse = 0.15 },
            { id = "concussive_blow", chanceToUse = 0.15 }
        },
        resistances = {
            ["necrotic"] = -90,
            ["arcane"] = -80,
            ["poison"] = -70,
            ["physical"] = 60,
            ["fire"] = 40,
            ["lightning"] = 30,
            ["ice"] = 20
        },
        immunities = {"physical", "necrotic"},
        color = {0.5, 0.5, 0.8},
        sprite = "assets/Sprites/Enemies/Undead/vengeful_spirit_BOSS.png",
        category = "Undead",
        isBoss = true
    }
}

-- Empty cache for lookup by ID
monsterDefinitions.monstersByID = {}

-- Populate the lookup cache
for id, monster in pairs(monsterDefinitions.monsters) do
    monsterDefinitions.monstersByID[id] = monster
end

return monsterDefinitions 