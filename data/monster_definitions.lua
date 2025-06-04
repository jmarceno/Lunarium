-- Monster Definitions
-- Contains all monster definitions and ID mappings

local monsterDefinitions = {}

-- Monster definitions
monsterDefinitions.monsters = {
    -- Animals
    ["giant_rat"] = {
        id = "giant_rat",
        name = "Giant Rat",
        stats = { 
            level = 1, 
            hp = 12, 
            attack = 3, 
            defense = 1, 
            speed = 10,
            magicAttack = 0
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.7 },
            { id = "claw_attack", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -10,
            ["fire"] = 20
        },
        immunities = {},
        color = {0.6, 0.5, 0.4},
        sprite = "GiantRat",  -- File: GiantRat.png
        category = "Animals"
    },
    ["giant_plague_rat"] = {
        id = "giant_plague_rat",
        name = "Giant Plague Rat",
        stats = { 
            level = 3, 
            hp = 18, 
            attack = 4, 
            defense = 2, 
            speed = 9,
            magicAttack = 2
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.5 }
        },
        resistances = {
            ["poison"] = -40,
            ["fire"] = 30
        },
        immunities = {"poison"},
        color = {0.4, 0.5, 0.3},
        sprite = "GiantPlagueRat",  -- File: GiantPlagueRat.png
        category = "Animals"
    },
    ["mutant_rat"] = {
        id = "mutant_rat",
        name = "Mutant Rat",
        stats = { 
            level = 4, 
            hp = 25, 
            attack = 6, 
            defense = 3, 
            speed = 8,
            magicAttack = 4
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.4 },
            { id = "claw_attack", chanceToUse = 0.3 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -20,
            ["necrotic"] = -10,
            ["fire"] = 15
        },
        immunities = {},
        color = {0.6, 0.4, 0.6},
        sprite = "MutantRat",  -- File: MutantRat.png
        category = "Animals"
    },
    ["cave_panther"] = {
        id = "cave_panther",
        name = "Cave Panther",
        stats = { 
            level = 5, 
            hp = 35, 
            attack = 9, 
            defense = 4, 
            speed = 12,
            magicAttack = 0
        },
        abilities = {
            { id = "claw_attack", chanceToUse = 0.5 },
            { id = "bite_attack", chanceToUse = 0.3 },
            { id = "pounce_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -20,
            ["fire"] = 10
        },
        immunities = {},
        color = {0.2, 0.2, 0.3},
        sprite = "CavePanther",  -- File: CavePanther.png
        category = "Animals"
    },
    ["enraged_panther_boss"] = {
        id = "enraged_panther_boss",
        name = "Enraged Panther",
        stats = { 
            level = 7, 
            hp = 120, 
            attack = 14, 
            defense = 6, 
            speed = 15,
            magicAttack = 0
        },
        abilities = {
            { id = "claw_attack", chanceToUse = 0.3 },
            { id = "bite_attack", chanceToUse = 0.2 },
            { id = "pounce_attack", chanceToUse = 0.2 },
            { id = "frenzy_attack", chanceToUse = 0.2 },
            { id = "bleeding_slash", chanceToUse = 0.1 }
        },
        resistances = {
            ["physical"] = -40,
            ["fire"] = 20,
            ["arcane"] = 10
        },
        immunities = {},
        color = {0.7, 0.2, 0.2},
        sprite = "EnragedPanther_BOSS",  -- File: EnragedPanther.png
        category = "Animals",
        isBoss = true
    },
    
    -- Cultists
    ["cultist"] = {
        id = "cultist",
        name = "Cultist",
        stats = { 
            level = 2, 
            hp = 20, 
            attack = 5, 
            defense = 3, 
            speed = 7,
            magicAttack = 6
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "fireball", chanceToUse = 0.4 }
        },
        resistances = {
            ["fire"] = -20,
            ["arcane"] = -15,
            ["physical"] = 10
        },
        immunities = {},
        color = {0.4, 0.1, 0.4},
        sprite = "Cultist",  -- File: Cultist.png
        category = "Cultists"
    },
    ["cultist_rogue"] = {
        id = "cultist_rogue",
        name = "Cultist Rogue",
        stats = { 
            level = 3, 
            hp = 22, 
            attack = 7, 
            defense = 2, 
            speed = 9,
            magicAttack = 3
        },
        abilities = {
            { id = "bleeding_slash", chanceToUse = 0.5 },
            { id = "basic_physical_attack", chanceToUse = 0.3 },
            { id = "silence_spell", chanceToUse = 0.2 }
        },
        resistances = {
            ["arcane"] = -10,
            ["physical"] = 5
        },
        immunities = {},
        color = {0.5, 0.2, 0.5},
        sprite = "CultistRogue",  -- File: CultistRogue.png
        category = "Cultists"
    },
    
    -- Demons
    ["barbarian_demon"] = {
        id = "barbarian_demon",
        name = "Barbarian Demon",
        stats = { 
            level = 5, 
            hp = 45, 
            attack = 12, 
            defense = 8, 
            speed = 7,
            magicAttack = 2
        },
        abilities = {
            { id = "slam_attack", chanceToUse = 0.6 },
            { id = "demonic_fury", chanceToUse = 0.4 }
        },
        resistances = {
            ["fire"] = -40,
            ["ice"] = 20,
            ["arcane"] = 10
        },
        immunities = {},
        color = {0.7, 0.3, 0.3},
        sprite = "BarbarianDemon",  -- File: BarbarianDemon.png
        category = "Demons"
    },
    ["berserker_demon"] = {
        id = "berserker_demon",
        name = "Berserker Demon",
        stats = { 
            level = 6, 
            hp = 55, 
            attack = 14, 
            defense = 6, 
            speed = 9,
            magicAttack = 0
        },
        abilities = {
            { id = "frenzy_attack", chanceToUse = 0.4 },
            { id = "sweep_attack", chanceToUse = 0.3 },
            { id = "crushing_blow", chanceToUse = 0.3 }
        },
        resistances = {
            ["fire"] = -50,
            ["physical"] = -20,
            ["ice"] = 30
        },
        immunities = {"fire"},
        color = {0.8, 0.2, 0.2},
        sprite = "BerserkerDemon",  -- File: BerserkerDemon.png
        category = "Demons"
    },
    ["deformed_bat_abomination"] = {
        id = "deformed_bat_abomination",
        name = "Deformed Bat Abomination",
        stats = { 
            level = 4, 
            hp = 30, 
            attack = 9, 
            defense = 3, 
            speed = 12,
            magicAttack = 5
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.5 },
            { id = "toxic_spores", chanceToUse = 0.3 },
            { id = "necrotic_blast", chanceToUse = 0.2 }
        },
        resistances = {
            ["necrotic"] = -30,
            ["physical"] = 10
        },
        immunities = {},
        color = {0.3, 0.3, 0.4},
        sprite = "DeformedBatAbomination",  -- File: DeformedBatAbomination.png
        category = "Demons"
    },
    ["fire_invoker"] = {
        id = "fire_invoker",
        name = "Fire Invoker",
        stats = { 
            level = 5, 
            hp = 30, 
            attack = 5, 
            defense = 4, 
            speed = 7,
            magicAttack = 14
        },
        abilities = {
            { id = "fireball", chanceToUse = 0.4 },
            { id = "hellfire", chanceToUse = 0.3 },
            { id = "fire_breath", chanceToUse = 0.2 },
            { id = "flames_of_agony", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -80,
            ["ice"] = 50,
            ["arcane"] = -20
        },
        immunities = {"fire", "burn"},
        color = {0.9, 0.4, 0.1},
        sprite = "FireInvoker",  -- File: FireInvoker.png
        category = "Demons"
    },
    ["succubus"] = {
        id = "succubus",
        name = "Succubus",
        stats = { 
            level = 4, 
            hp = 25, 
            attack = 6, 
            defense = 3, 
            speed = 10,
            magicAttack = 12
        },
        abilities = {
            { id = "seduce", chanceToUse = 0.4 },
            { id = "fireball", chanceToUse = 0.3 },
            { id = "basic_physical_attack", chanceToUse = 0.3 }
        },
        resistances = {
            ["fire"] = -30,
            ["psychic"] = -20,
            ["holy"] = 40
        },
        immunities = {"charm"},
        color = {0.7, 0.2, 0.5},
        sprite = "Succubus",  -- File: Succubus.png
        category = "Demons"
    },
    ["succubus_infiltrator"] = {
        id = "succubus_infiltrator",
        name = "Succubus Infiltrator",
        stats = { 
            level = 5, 
            hp = 30, 
            attack = 8, 
            defense = 4, 
            speed = 11,
            magicAttack = 14
        },
        abilities = {
            { id = "seduce", chanceToUse = 0.3 },
            { id = "silence_spell", chanceToUse = 0.3 },
            { id = "flames_of_agony", chanceToUse = 0.2 },
            { id = "bleeding_slash", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -30,
            ["psychic"] = -30,
            ["holy"] = 50
        },
        immunities = {"charm"},
        color = {0.8, 0.1, 0.4},
        sprite = "SuccubusInfiltrator",  -- File: SuccubusInfiltrator.png
        category = "Demons"
    },
    ["royal_demon_boss"] = {
        id = "royal_demon_boss",
        name = "Royal Demon",
        stats = { 
            level = 8, 
            hp = 180, 
            attack = 15, 
            defense = 12, 
            speed = 8,
            magicAttack = 20
        },
        abilities = {
            { id = "hellfire", chanceToUse = 0.2 },
            { id = "fire_breath", chanceToUse = 0.2 },
            { id = "demonic_fury", chanceToUse = 0.2 },
            { id = "summon_minions", chanceToUse = 0.2 },
            { id = "strengthen_allies", chanceToUse = 0.1 },
            { id = "arcane_explosion", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -80,
            ["necrotic"] = -50,
            ["physical"] = -30,
            ["arcane"] = -20,
            ["ice"] = 40,
            ["holy"] = 60
        },
        immunities = {"fire", "burn", "charm"},
        color = {0.9, 0.1, 0.1},
        sprite = "RoyalDemon_BOSS",  -- File: RoyalDemon.png
        category = "Demons",
        isBoss = true
    },
    ["succubus_dominatrix_boss"] = {
        id = "succubus_dominatrix_boss",
        name = "Succubus Dominatrix",
        stats = { 
            level = 7, 
            hp = 140, 
            attack = 12, 
            defense = 8, 
            speed = 13,
            magicAttack = 18
        },
        abilities = {
            { id = "seduce", chanceToUse = 0.3 },
            { id = "hellfire", chanceToUse = 0.2 },
            { id = "fire_breath", chanceToUse = 0.2 },
            { id = "silence_spell", chanceToUse = 0.2 },
            { id = "summon_minions", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -60,
            ["psychic"] = -50,
            ["necrotic"] = -30,
            ["holy"] = 70
        },
        immunities = {"fire", "charm", "burn"},
        color = {0.9, 0.2, 0.6},
        sprite = "SuccubusDominatrix_BOSS",  -- File: SuccubusDominatrix.png
        category = "Demons",
        isBoss = true
    },
    ["succubus_doctrinator"] = {
        id = "succubus_doctrinator",
        name = "Succubus Doctrinator",
        stats = { 
            level = 6, 
            hp = 90, 
            attack = 10, 
            defense = 6, 
            speed = 11,
            magicAttack = 15
        },
        abilities = {
            { id = "seduce", chanceToUse = 0.3 },
            { id = "hellfire", chanceToUse = 0.3 },
            { id = "flames_of_agony", chanceToUse = 0.2 },
            { id = "silence_spell", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -50,
            ["psychic"] = -40,
            ["necrotic"] = -20,
            ["holy"] = 60
        },
        immunities = {"fire", "charm"},
        color = {0.85, 0.25, 0.55},
        sprite = "SuccbusDoutrinator",
        category = "Demons"
    },
    ["beserker_demon"] = {
        id = "beserker_demon",
        name = "Beserker Demon",
        stats = { 
            level = 7, 
            hp = 70, 
            attack = 16, 
            defense = 7, 
            speed = 10,
            magicAttack = 2
        },
        abilities = {
            { id = "frenzy_attack", chanceToUse = 0.5 },
            { id = "demonic_fury", chanceToUse = 0.3 },
            { id = "rage", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -60,
            ["physical"] = -30,
            ["ice"] = 35
        },
        immunities = {"fire", "burn"},
        color = {0.85, 0.15, 0.15},
        sprite = "BeserkerDemon",
        category = "Demons"
    },
    
    -- Goblins
    ["goblin"] = {
        id = "goblin",
        name = "Goblin",
        stats = { 
            level = 1, 
            hp = 10, 
            attack = 3, 
            defense = 1, 
            speed = 8,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.8 },
            { id = "bleeding_slash", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -10
        },
        immunities = {},
        color = {0.2, 0.7, 0.3},
        sprite = "Goblin",  -- File: Goblin.png
        category = "Goblins"
    },
    ["goblin_archer"] = {
        id = "goblin_archer",
        name = "Goblin Archer",
        stats = { 
            level = 2, 
            hp = 12, 
            attack = 5, 
            defense = 1, 
            speed = 9,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "bleeding_slash", chanceToUse = 0.4 }
        },
        resistances = {
            ["poison"] = -10
        },
        immunities = {},
        color = {0.3, 0.6, 0.3},
        sprite = "GoblinArcher",  -- File: GoblinArcher.png
        category = "Goblins"
    },
    ["goblin_fire_shaman"] = {
        id = "goblin_fire_shaman",
        name = "Goblin Fire Shaman",
        stats = { 
            level = 3, 
            hp = 15, 
            attack = 2, 
            defense = 2, 
            speed = 7,
            magicAttack = 8
        },
        abilities = {
            { id = "fireball", chanceToUse = 0.5 },
            { id = "flames_of_agony", chanceToUse = 0.3 },
            { id = "basic_physical_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["fire"] = -30,
            ["poison"] = -10,
            ["ice"] = 20
        },
        immunities = {},
        color = {0.6, 0.4, 0.2},
        sprite = "GoblinFireShaman",  -- File: GoblinFireShaman.png
        category = "Goblins"
    },
    ["goblin_ice_shaman"] = {
        id = "goblin_ice_shaman",
        name = "Goblin Ice Shaman",
        stats = { 
            level = 3, 
            hp = 14, 
            attack = 2, 
            defense = 3, 
            speed = 6,
            magicAttack = 9
        },
        abilities = {
            { id = "ice_bolt", chanceToUse = 0.6 },
            { id = "basic_physical_attack", chanceToUse = 0.3 },
            { id = "silence_spell", chanceToUse = 0.1 }
        },
        resistances = {
            ["ice"] = -30,
            ["poison"] = -10,
            ["fire"] = 20
        },
        immunities = {},
        color = {0.2, 0.6, 0.8},
        sprite = "GoblinIceShaman",  -- File: GoblinIceShaman.png
        category = "Goblins"
    },
    ["goblin_plague_shaman"] = {
        id = "goblin_plague_shaman",
        name = "Goblin Plague Shaman",
        stats = { 
            level = 4, 
            hp = 18, 
            attack = 3, 
            defense = 2, 
            speed = 7,
            magicAttack = 10
        },
        abilities = {
            { id = "toxic_spores", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "basic_physical_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -40,
            ["necrotic"] = -20
        },
        immunities = {"poison"},
        color = {0.4, 0.7, 0.2},
        sprite = "GoblinPlagueShaman",  -- File: GoblinPlagueShaman.png
        category = "Goblins"
    },
    ["goblin_rogue"] = {
        id = "goblin_rogue",
        name = "Goblin Rogue",
        stats = { 
            level = 2, 
            hp = 13, 
            attack = 6, 
            defense = 1, 
            speed = 10,
            magicAttack = 0
        },
        abilities = {
            { id = "bleeding_slash", chanceToUse = 0.6 },
            { id = "basic_physical_attack", chanceToUse = 0.4 }
        },
        resistances = {
            ["poison"] = -10
        },
        immunities = {},
        color = {0.3, 0.5, 0.3},
        sprite = "GoblinRogue",  -- File: GoblinRogue.png
        category = "Goblins"
    },
    ["goblin_shaman_boss"] = {
        id = "goblin_shaman_boss",
        name = "Goblin Shaman",
        stats = { 
            level = 6, 
            hp = 80, 
            attack = 6, 
            defense = 5, 
            speed = 8,
            magicAttack = 16
        },
        abilities = {
            { id = "fireball", chanceToUse = 0.2 },
            { id = "toxic_spores", chanceToUse = 0.2 },
            { id = "ice_bolt", chanceToUse = 0.2 },
            { id = "summon_minions", chanceToUse = 0.2 },
            { id = "strengthen_allies", chanceToUse = 0.1 },
            { id = "protective_aura", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -20,
            ["ice"] = -20,
            ["poison"] = -30,
            ["arcane"] = -10
        },
        immunities = {"poison"},
        color = {0.5, 0.8, 0.3},
        sprite = "GoblinShaman_BOSS",  -- File: GoblinShaman.png
        category = "Goblins",
        isBoss = true
    },
    ["mutated_goblin_archer"] = {
        id = "mutated_goblin_archer",
        name = "Mutated Goblin Archer",
        stats = { 
            level = 5, 
            hp = 28, 
            attack = 10, 
            defense = 3, 
            speed = 9,
            magicAttack = 0
        },
        abilities = {
            { id = "bleeding_slash", chanceToUse = 0.4 },
            { id = "infected_bite", chanceToUse = 0.4 },
            { id = "basic_physical_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -30,
            ["necrotic"] = -10
        },
        immunities = {"poison"},
        color = {0.5, 0.6, 0.2},
        sprite = "MutatedGoblinArcher",  -- File: MutatedGoblinArcher.png
        category = "Goblins"
    },
    
    -- Insectoids
    ["cave_spider"] = {
        id = "cave_spider",
        name = "Cave Spider",
        stats = { 
            level = 1, 
            hp = 10, 
            attack = 4, 
            defense = 1, 
            speed = 10,
            magicAttack = 0
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.8 },
            { id = "infected_bite", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -40
        },
        immunities = {},
        color = {0.2, 0.2, 0.2},
        sprite = "CaveSpider",  -- File: CaveSpider.png
        category = "Insectoids"
    },
    ["death_mosquito"] = {
        id = "death_mosquito",
        name = "Death Mosquito",
        stats = { 
            level = 3, 
            hp = 15, 
            attack = 6, 
            defense = 1, 
            speed = 12,
            magicAttack = 0
        },
        abilities = {
            { id = "infected_bite", chanceToUse = 0.7 },
            { id = "basic_physical_attack", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -50
        },
        immunities = {"poison"},
        color = {0.7, 0.1, 0.1},
        sprite = "DeathMosquito",  -- File: DeathMosquito.png
        category = "Insectoids"
    },
    ["death_spider"] = {
        id = "death_spider",
        name = "Death Spider",
        stats = { 
            level = 4, 
            hp = 25, 
            attack = 8, 
            defense = 3, 
            speed = 9,
            magicAttack = 0
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "web_shot", chanceToUse = 0.2 }
        },
        resistances = {
            ["poison"] = -40,
            ["necrotic"] = -20
        },
        immunities = {"poison"},
        color = {0.1, 0.1, 0.1},
        sprite = "DeathSpider",  -- File: DeathSpider.png
        category = "Insectoids"
    },
    ["toxic_spider"] = {
        id = "toxic_spider",
        name = "Toxic Spider",
        stats = { 
            level = 5, 
            hp = 30, 
            attack = 7, 
            defense = 4, 
            speed = 8,
            magicAttack = 6
        },
        abilities = {
            { id = "infected_bite", chanceToUse = 0.4 },
            { id = "web_shot", chanceToUse = 0.3 },
            { id = "toxic_spores", chanceToUse = 0.3 }
        },
        resistances = {
            ["poison"] = -60,
            ["necrotic"] = -20
        },
        immunities = {"poison"},
        color = {0.1, 0.6, 0.1},
        sprite = "ToxicSpider",  -- File: ToxicSpider.png
        category = "Insectoids"
    },
    ["broodmother_boss"] = {
        id = "broodmother_boss",
        name = "Broodmother",
        stats = { 
            level = 7, 
            hp = 150, 
            attack = 12, 
            defense = 8, 
            speed = 7,
            magicAttack = 10
        },
        abilities = {
            { id = "web_shot", chanceToUse = 0.2 },
            { id = "venom_spray", chanceToUse = 0.2 },
            { id = "infected_bite", chanceToUse = 0.2 },
            { id = "summon_minions", chanceToUse = 0.2 },
            { id = "toxic_spores", chanceToUse = 0.1 },
            { id = "strengthen_allies", chanceToUse = 0.1 }
        },
        resistances = {
            ["poison"] = -80,
            ["necrotic"] = -30,
            ["physical"] = -20,
            ["fire"] = 40
        },
        immunities = {"poison"},
        color = {0.3, 0.7, 0.3},
        sprite = "Broodmother",  -- File: Broodmother.png
        category = "Insectoids",
        isBoss = true
    },
    
    -- Slimes

    ["slime"] = {
        id = "slime",
        name = "Slime",
        stats = { 
            level = 1, 
            hp = 15, 
            attack = 3, 
            defense = 2, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.7 },
            { id = "acid_splash", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -10,
            ["acid"] = -30,
            ["fire"] = 20
        },
        immunities = {"poison"},
        color = {0.2, 0.6, 0.2},
        sprite = "Slime",
        category = "Slimes"
    },
    ["death_slime"] = {
        id = "death_slime",
        name = "Death Slime",
        stats = { 
            level = 3, 
            hp = 25, 
            attack = 5, 
            defense = 3, 
            speed = 3,
            magicAttack = 6
        },
        abilities = {
            { id = "acid_splash", chanceToUse = 0.4 },
            { id = "absorb", chanceToUse = 0.3 },
            { id = "necrotic_touch", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -15,
            ["acid"] = -40,
            ["necrotic"] = -30,
            ["fire"] = 15
        },
        immunities = {"poison"},
        color = {0.4, 0.2, 0.4},
        sprite = "DeathSlime",
        category = "Slimes"
    },
    ["slime_amalgamation"] = {
        id = "slime_amalgamation",
        name = "Slime Amalgamation",
        stats = { 
            level = 4, 
            hp = 40, 
            attack = 7, 
            defense = 5, 
            speed = 2,
            magicAttack = 4
        },
        abilities = {
            { id = "acid_splash", chanceToUse = 0.5 },
            { id = "absorb", chanceToUse = 0.3 },
            { id = "split", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -20,
            ["acid"] = -40,
            ["fire"] = 10
        },
        immunities = {"poison"},
        color = {0.3, 0.5, 0.3},
        sprite = "SlimeAmalgamation",
        category = "Slimes"
    },
    ["evoluted_acid_slime"] = {
        id = "evoluted_acid_slime",
        name = "Evoluted Acid Slime",
        stats = { 
            level = 5, 
            hp = 35, 
            attack = 8, 
            defense = 4, 
            speed = 5,
            magicAttack = 5
        },
        abilities = {
            { id = "acid_splash", chanceToUse = 0.6 },
            { id = "absorb", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -15,
            ["acid"] = -60,
            ["fire"] = 25
        },
        immunities = {"poison", "acid"},
        color = {0.1, 0.7, 0.3},
        sprite = "EvolutedAcidSlime",
        category = "Slimes"
    },
    ["mutated_death_slime"] = {
        id = "mutated_death_slime",
        name = "Mutated Death Slime",
        stats = { 
            level = 6, 
            hp = 45, 
            attack = 9, 
            defense = 5, 
            speed = 4,
            magicAttack = 10
        },
        abilities = {
            { id = "acid_splash", chanceToUse = 0.3 },
            { id = "necrotic_blast", chanceToUse = 0.4 },
            { id = "absorb", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -20,
            ["acid"] = -50,
            ["necrotic"] = -40,
            ["fire"] = 15
        },
        immunities = {"poison", "necrotic"},
        color = {0.5, 0.1, 0.5},
        sprite = "MutatedDeathSlime",
        category = "Slimes"
    },
    ["king_slime_boss"] = {
        id = "king_slime_boss",
        name = "King Slime",
        stats = { 
            level = 7, 
            hp = 150, 
            attack = 12, 
            defense = 10, 
            speed = 3,
            magicAttack = 12
        },
        abilities = {
            { id = "acid_splash", chanceToUse = 0.3 },
            { id = "absorb", chanceToUse = 0.2 },
            { id = "split", chanceToUse = 0.2 },
            { id = "ground_slam", chanceToUse = 0.2 },
            { id = "summon_minions", chanceToUse = 0.1 }
        },
        resistances = {
            ["physical"] = -30,
            ["acid"] = -70,
            ["fire"] = 30
        },
        immunities = {"poison", "acid"},
        color = {0.2, 0.8, 0.4},
        sprite = "KingSlime_BOSS",
        category = "Slimes",
        isBoss = true
    },
    ["royal_slime_boss"] = {
        id = "royal_slime_boss",
        name = "Royal Slime",
        stats = { 
            level = 6, 
            hp = 120, 
            attack = 8, 
            defense = 10, 
            speed = 6,
            magicAttack = 14
        },
        abilities = {
            { id = "acid_splash", chanceToUse = 0.2 },
            { id = "lightning_bolt", chanceToUse = 0.2 },
            { id = "ice_bolt", chanceToUse = 0.2 },
            { id = "fireball", chanceToUse = 0.2 },
            { id = "summon_minions", chanceToUse = 0.1 },
            { id = "split", chanceToUse = 0.1 }
        },
        resistances = {
            ["fire"] = -30,
            ["ice"] = -30,
            ["lightning"] = -30,
            ["acid"] = -30,
            ["physical"] = -40
        },
        immunities = {"poison", "burn", "freeze", "paralysis"},
        color = {0.7, 0.3, 0.9},
        sprite = "RoyalSlime",  -- File: RoyalSlime.png
        category = "Slimes",
        isBoss = true
    },

    
    -- Trolls
    ["cave_troll"] = {
        id = "cave_troll",
        name = "Cave Troll",
        stats = { 
            level = 5, 
            hp = 75, 
            attack = 12, 
            defense = 8, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -40,
            ["acid"] = -20,
            ["fire"] = 20
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "CaveTroll",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["armored_cave_troll"] = {
        id = "armored_cave_troll",
        name = "Armored Cave Troll",
        stats = { 
            level = 7, 
            hp = 75, 
            attack = 16, 
            defense = 10, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.1 }
        },
        resistances = {
            ["physical"] = -60,
            ["acid"] = -20,
            ["fire"] = 10
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "ArmoredCaveTroll",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["cave_troll_brute"] = {
        id = "cave_troll_brute",
        name = "Cave Troll Brute",
        stats = { 
            level = 9, 
            hp = 90, 
            attack = 20, 
            defense = 12, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -60,
            ["acid"] = -20,
            ["fire"] = 10
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "CaveTrollBrute",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["troll_archer"] = {
        id = "troll_archer",
        name = "Troll Archer",
        stats = { 
            level = 3, 
            hp = 50, 
            attack = 20, 
            defense = 7, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -60,
            ["acid"] = -20,
            ["fire"] = 10
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "TrollArcher",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["troll_fire_mage"] = {
        id = "troll_fire_mage",
        name = "Troll Fire Mage",
        stats = { 
            level = 8, 
            hp = 50, 
            attack = 30, 
            defense = 7, 
            speed = 4,
            magicAttack = 5
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -30,
            ["acid"] = -10,
            ["fire"] = -5
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "TrollFireMage",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["troll"] = {
        id = "troll",
        name = "Troll",
        stats = { 
            level = 4, 
            hp = 30, 
            attack = 20, 
            defense = 4, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -30,
            ["acid"] = -10,
            ["fire"] = -5
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "Troll",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["troll_brute"] = {
        id = "troll_brute",
        name = "Troll Brute",
        stats = { 
            level = 4, 
            hp = 45, 
            attack = 35, 
            defense = 4, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -30,
            ["acid"] = -10,
            ["fire"] = -5
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "TrollBrute",  -- File: CaveTroll.png
        category = "Trolls"
    },
    ["troll_mage"] = {
        id = "troll_mage",
        name = "Troll Mage",
        stats = { 
            level = 4, 
            hp = 45, 
            attack = 35, 
            defense = 4, 
            speed = 4,
            magicAttack = 4
        },
        abilities = {
            { id = "strong_physical_attack", chanceToUse = 0.8 },
            { id = "regeneration", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -30,
            ["acid"] = -10,
            ["fire"] = -5
        },
        immunities = {},
        color = {0.4, 0.4, 0.4},
        sprite = "TrollMage",  -- File: CaveTroll.png
        category = "Trolls"
    },
    
    ["troll_shaman_boss"] = {
        id = "troll_shaman_boss",
        name = "Troll Shaman",
        stats = { 
            level = 8, 
            hp = 200, 
            attack = 18, 
            defense = 12, 
            speed = 5,
            magicAttack = 8
        },
        abilities = {            
            { id = "regeneration", chanceToUse = 0.2 },
            { id = "toxic_spores", chanceToUse = 0.5 },
            { id = "ground_slam", chanceToUse = 0.2 },
            { id = "rage", chanceToUse = 0.1 }
        },
        resistances = {
            ["physical"] = -60,
            ["poison"] = -40,
            ["acid"] = -30,
            ["arcane"] = 20,
            ["holy"] = 20
        },
        immunities = {"poison"},
        color = {0.6, 0.2, 0.2},
        sprite = "TrollShaman_BOSS",  -- File: TrollAbomination.png
        category = "Trolls",
        isBoss = true
    },
    
    -- Undead
    ["skeleton"] = {
        id = "skeleton",
        name = "Skeleton",
        stats = { 
            level = 1, 
            hp = 15, 
            attack = 4, 
            defense = 2, 
            speed = 6,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 1.0 }
        },
        resistances = {
            ["physical"] = -10,
            ["necrotic"] = -40,
            ["holy"] = 40,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.8, 0.8, 0.8},
        sprite = "Skeleton",  -- File: Skeleton.png
        category = "Undead"
    },
    ["skeleton_archer"] = {
        id = "skeleton_archer",
        name = "Skeleton Archer",
        stats = { 
            level = 2, 
            hp = 12, 
            attack = 6, 
            defense = 1, 
            speed = 7,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 1.0 }
        },
        resistances = {
            ["physical"] = -10,
            ["necrotic"] = -40,
            ["holy"] = 40,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.8, 0.8, 0.7},
        sprite = "SkeletonArcher",  -- File: SkeletonArcher.png
        category = "Undead"
    },
    ["skeleton_mage"] = {
        id = "skeleton_mage",
        name = "Skeleton Mage",
        stats = { 
            level = 3, 
            hp = 10, 
            attack = 2, 
            defense = 1, 
            speed = 5,
            magicAttack = 8
        },
        abilities = {
            { id = "arcane_bolt", chanceToUse = 0.6 },
            { id = "necrotic_touch", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -10,
            ["necrotic"] = -60,
            ["arcane"] = -30,
            ["holy"] = 60,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.6, 0.6, 0.9},
        sprite = "SkeletonMage",  -- File: SkeletonMage.png
        category = "Undead"
    },
    ["zombie"] = {
        id = "zombie",
        name = "Zombie",
        stats = { 
            level = 2, 
            hp = 25, 
            attack = 5, 
            defense = 3, 
            speed = 3,
            magicAttack = 0
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.7 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -50,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.3, 0.5, 0.3},
        sprite = "Deceased",  -- File: Deceased.png
        category = "Undead"
    },
    ["plague_zombie"] = {
        id = "plague_zombie",
        name = "Plague Zombie",
        stats = { 
            level = 4, 
            hp = 30, 
            attack = 6, 
            defense = 3, 
            speed = 3,
            magicAttack = 5
        },
        abilities = {
            { id = "infected_bite", chanceToUse = 0.6 },
            { id = "toxic_spores", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -50,
            ["poison"] = -30,
            ["holy"] = 50
        },
        immunities = {"poison"},
        color = {0.2, 0.7, 0.2},
        sprite = "PlagueZombie",
        category = "Undead"
    },
    ["skeleton_cold_mage"] = {
        id = "skeleton_cold_mage",
        name = "Skeleton Cold Mage",
        stats = { 
            level = 4, 
            hp = 15, 
            attack = 3, 
            defense = 2, 
            speed = 5,
            magicAttack = 10
        },
        abilities = {
            { id = "ice_bolt", chanceToUse = 0.7 },
            { id = "basic_physical_attack", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -10,
            ["necrotic"] = -40,
            ["ice"] = -60,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison", "freeze"},
        color = {0.5, 0.7, 0.9},
        sprite = "SkeletonColdMage",
        category = "Undead"
    },
    ["skeleton_defender"] = {
        id = "skeleton_defender",
        name = "Skeleton Defender",
        stats = { 
            level = 3, 
            hp = 22, 
            attack = 5, 
            defense = 7, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.7 },
            { id = "protective_aura", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -30,
            ["necrotic"] = -40,
            ["holy"] = 40,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.7, 0.7, 0.7},
        sprite = "SkeletonDefender",
        category = "Undead"
    },
    ["skeleton_champion"] = {
        id = "skeleton_champion",
        name = "Skeleton Champion",
        stats = { 
            level = 5, 
            hp = 30, 
            attack = 8, 
            defense = 5, 
            speed = 6,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "crushing_blow", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -25,
            ["necrotic"] = -40,
            ["holy"] = 45,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.8, 0.7, 0.6},
        sprite = "SkeletonChampion",
        category = "Undead"
    },
    ["skeleton_warrior"] = {
        id = "skeleton_warrior",
        name = "Skeleton Warrior",
        stats = { 
            level = 2, 
            hp = 18, 
            attack = 5, 
            defense = 3, 
            speed = 5,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.8 },
            { id = "bleeding_slash", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -15,
            ["necrotic"] = -40,
            ["holy"] = 40,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.75, 0.75, 0.75},
        sprite = "SkeletonWarrior",
        category = "Undead"
    },
    ["skeleton_warrior_elite_boss"] = {
        id = "skeleton_warrior_elite_boss",
        name = "Skeleton Warrior Elite",
        stats = { 
            level = 7, 
            hp = 120, 
            attack = 14, 
            defense = 10, 
            speed = 7,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.3 },
            { id = "bleeding_slash", chanceToUse = 0.3 },
            { id = "strengthen_allies", chanceToUse = 0.2 },
            { id = "raise_dead", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -30,
            ["necrotic"] = -50,
            ["holy"] = 60,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.9, 0.8, 0.7},
        sprite = "SkeletonWarriorElite_BOSS",
        category = "Undead",
        isBoss = true
    },
    ["skeleton_arch_mage_boss"] = {
        id = "skeleton_arch_mage_boss",
        name = "Skeleton Arch Mage",
        stats = { 
            level = 8, 
            hp = 100, 
            attack = 5, 
            defense = 6, 
            speed = 6,
            magicAttack = 18
        },
        abilities = {
            { id = "arcane_bolt", chanceToUse = 0.3 },
            { id = "ice_bolt", chanceToUse = 0.2 },
            { id = "necrotic_blast", chanceToUse = 0.2 },
            { id = "arcane_explosion", chanceToUse = 0.1 },
            { id = "raise_dead", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -15,
            ["necrotic"] = -70,
            ["arcane"] = -50,
            ["ice"] = -30,
            ["holy"] = 70,
            ["poison"] = 100
        },
        immunities = {"poison", "silence"},
        color = {0.6, 0.4, 0.9},
        sprite = "SkeletonArchMage_BOSS",
        category = "Undead",
        isBoss = true
    },
    ["undead_troll"] = {
        id = "undead_troll",
        name = "Undead Troll",
        stats = { 
            level = 6, 
            hp = 65, 
            attack = 12, 
            defense = 7, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "slam_attack", chanceToUse = 0.6 },
            { id = "crushing_blow", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -30,
            ["necrotic"] = -40,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.5, 0.6, 0.4},
        sprite = "UndeadTroll",
        category = "Undead"
    },
    ["undead_troll_mage"] = {
        id = "undead_troll_mage",
        name = "Undead Troll Mage",
        stats = { 
            level = 7, 
            hp = 60, 
            attack = 9, 
            defense = 6, 
            speed = 4,
            magicAttack = 14
        },
        abilities = {
            { id = "necrotic_blast", chanceToUse = 0.5 },
            { id = "slam_attack", chanceToUse = 0.3 },
            { id = "raise_dead", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -25,
            ["necrotic"] = -60,
            ["arcane"] = -30,
            ["holy"] = 55,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.4, 0.6, 0.5},
        sprite = "UndeadTrollMage",
        category = "Undead"
    },
    ["armored_undead_troll"] = {
        id = "armored_undead_troll",
        name = "Armored Undead Troll",
        stats = { 
            level = 8, 
            hp = 75, 
            attack = 14, 
            defense = 11, 
            speed = 3,
            magicAttack = 0
        },
        abilities = {
            { id = "slam_attack", chanceToUse = 0.5 },
            { id = "crushing_blow", chanceToUse = 0.3 },
            { id = "ground_slam", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -40,
            ["necrotic"] = -40,
            ["holy"] = 60,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.5, 0.5, 0.5},
        sprite = "ArmoredUndeadTroll",
        category = "Undead"
    },
    ["vampire"] = {
        id = "vampire",
        name = "Vampire",
        stats = { 
            level = 6, 
            hp = 45, 
            attack = 9, 
            defense = 5, 
            speed = 9,
            magicAttack = 10
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.4 },
            { id = "necrotic_blast", chanceToUse = 0.3 },
            { id = "absorb", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -30,
            ["necrotic"] = -60,
            ["holy"] = 70,
            ["poison"] = 100
        },
        immunities = {"poison", "bleed"},
        color = {0.7, 0.2, 0.2},
        sprite = "Vampire",
        category = "Undead"
    },
    ["wraith"] = {
        id = "wraith",
        name = "Wraith",
        stats = { 
            level = 5, 
            hp = 35, 
            attack = 7, 
            defense = 4, 
            speed = 8,
            magicAttack = 12
        },
        abilities = {
            { id = "necrotic_touch", chanceToUse = 0.6 },
            { id = "necrotic_blast", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = 50,
            ["necrotic"] = -80,
            ["holy"] = 80,
            ["poison"] = 100
        },
        immunities = {"poison", "physical"},
        color = {0.3, 0.3, 0.7},
        sprite = "Wraith",
        category = "Undead"
    },
    ["zombie_crawler"] = {
        id = "zombie_crawler",
        name = "Zombie Crawler",
        stats = { 
            level = 1, 
            hp = 18, 
            attack = 4, 
            defense = 2, 
            speed = 3,
            magicAttack = 0
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.8 },
            { id = "infected_bite", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -15,
            ["necrotic"] = -40,
            ["holy"] = 45,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.4, 0.5, 0.4},
        sprite = "ZombieCrawler",
        category = "Undead"
    },
    ["zombie_walker"] = {
        id = "zombie_walker",
        name = "Zombie Walker",
        stats = { 
            level = 2, 
            hp = 22, 
            attack = 5, 
            defense = 3, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.7 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -45,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.35, 0.5, 0.35},
        sprite = "ZombieWalker",
        category = "Undead"
    },
    ["plague_zombie_brute"] = {
        id = "plague_zombie_brute",
        name = "Plague Zombie Brute",
        stats = { 
            level = 5, 
            hp = 45, 
            attack = 9, 
            defense = 5, 
            speed = 3,
            magicAttack = 7
        },
        abilities = {
            { id = "slam_attack", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "toxic_spores", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -25,
            ["necrotic"] = -50,
            ["poison"] = -40,
            ["holy"] = 60
        },
        immunities = {"poison"},
        color = {0.25, 0.7, 0.3},
        sprite = "PlagueZombieBrute",
        category = "Undead"
    },
    ["putrified_zombie"] = {
        id = "putrified_zombie",
        name = "Putrified Zombie",
        stats = { 
            level = 4, 
            hp = 32, 
            attack = 7, 
            defense = 3, 
            speed = 4,
            magicAttack = 6
        },
        abilities = {
            { id = "infected_bite", chanceToUse = 0.5 },
            { id = "toxic_spores", chanceToUse = 0.5 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -50,
            ["poison"] = -40,
            ["holy"] = 55
        },
        immunities = {"poison"},
        color = {0.3, 0.6, 0.3},
        sprite = "PutrifiedZombie",
        category = "Undead"
    },
    ["rotting_one"] = {
        id = "rotting_one",
        name = "Rotting One",
        stats = { 
            level = 3, 
            hp = 28, 
            attack = 6, 
            defense = 2, 
            speed = 4,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "infected_bite", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -45,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.4, 0.55, 0.4},
        sprite = "RottingOne",
        category = "Undead"
    },
    ["runner_zombie"] = {
        id = "runner_zombie",
        name = "Runner Zombie",
        stats = { 
            level = 3, 
            hp = 24, 
            attack = 5, 
            defense = 2, 
            speed = 8,
            magicAttack = 0
        },
        abilities = {
            { id = "bite_attack", chanceToUse = 0.7 },
            { id = "infected_bite", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -45,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.35, 0.5, 0.35},
        sprite = "RunnerZombie",
        category = "Undead"
    },
    ["screamer"] = {
        id = "screamer",
        name = "Screamer",
        stats = { 
            level = 4, 
            hp = 25, 
            attack = 6, 
            defense = 2, 
            speed = 6,
            magicAttack = 8
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.5 },
            { id = "silence_spell", chanceToUse = 0.5 }
        },
        resistances = {
            ["physical"] = -20,
            ["necrotic"] = -45,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison", "silence"},
        color = {0.6, 0.4, 0.4},
        sprite = "Screamer",
        category = "Undead"
    },
    ["deceased_screamer"] = {
        id = "deceased_screamer",
        name = "Deceased Screamer",
        stats = { 
            level = 5, 
            hp = 30, 
            attack = 7, 
            defense = 3, 
            speed = 7,
            magicAttack = 10
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.4 },
            { id = "silence_spell", chanceToUse = 0.4 },
            { id = "necrotic_blast", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -25,
            ["necrotic"] = -50,
            ["holy"] = 55,
            ["poison"] = 100
        },
        immunities = {"poison", "silence"},
        color = {0.65, 0.35, 0.35},
        sprite = "DeceasedScreamer",
        category = "Undead"
    },
    ["penitent"] = {
        id = "penitent",
        name = "Penitent",
        stats = { 
            level = 4, 
            hp = 35, 
            attack = 8, 
            defense = 3, 
            speed = 5,
            magicAttack = 0
        },
        abilities = {
            { id = "basic_physical_attack", chanceToUse = 0.6 },
            { id = "bleeding_slash", chanceToUse = 0.4 }
        },
        resistances = {
            ["physical"] = -25,
            ["necrotic"] = -40,
            ["holy"] = 50,
            ["poison"] = 100
        },
        immunities = {"poison"},
        color = {0.5, 0.4, 0.4},
        sprite = "Penitent",
        category = "Undead"
    },
    ["phantom"] = {
        id = "phantom",
        name = "Phantom",
        stats = { 
            level = 6, 
            hp = 40, 
            attack = 6, 
            defense = 5, 
            speed = 7,
            magicAttack = 12
        },
        abilities = {
            { id = "necrotic_touch", chanceToUse = 0.5 },
            { id = "necrotic_blast", chanceToUse = 0.3 },
            { id = "silence_spell", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = 40,
            ["necrotic"] = -70,
            ["holy"] = 70,
            ["poison"] = 100
        },
        immunities = {"poison", "physical", "bleed"},
        color = {0.5, 0.5, 0.8},
        sprite = "Phantom",
        category = "Undead"
    },
    ["crawling_abomination"] = {
        id = "crawling_abomination",
        name = "Crawling Abomination",
        stats = { 
            level = 5, 
            hp = 40, 
            attack = 10, 
            defense = 4, 
            speed = 4,
            magicAttack = 6
        },
        abilities = {
            { id = "toxic_spores", chanceToUse = 0.5 },
            { id = "infected_bite", chanceToUse = 0.3 },
            { id = "basic_physical_attack", chanceToUse = 0.2 }
        },
        resistances = {
            ["physical"] = -25,
            ["necrotic"] = -50,
            ["poison"] = -40,
            ["holy"] = 55
        },
        immunities = {"poison"},
        color = {0.3, 0.6, 0.4},
        sprite = "CrawlingAbomination",
        category = "Undead"
    },
    ["death_knight"] = {
        id = "death_knight",
        name = "Death Knight",
        stats = { 
            level = 7, 
            hp = 60, 
            attack = 12, 
            defense = 8, 
            speed = 5,
            magicAttack = 10
        },
        abilities = {
            { id = "bleeding_slash", chanceToUse = 0.4 },
            { id = "necrotic_blast", chanceToUse = 0.3 },
            { id = "basic_physical_attack", chanceToUse = 0.3 }
        },
        resistances = {
            ["physical"] = -30,
            ["necrotic"] = -60,
            ["holy"] = 65,
            ["poison"] = 100
        },
        immunities = {"poison", "bleed"},
        color = {0.6, 0.3, 0.5},
        sprite = "DeathKnight",
        category = "Undead"
    }
}

-- Empty cache for lookup by ID
monsterDefinitions.monstersByID = {}

-- Populate the lookup cache
for id, monster in pairs(monsterDefinitions.monsters) do
    monsterDefinitions.monstersByID[id] = monster
end

return monsterDefinitions 