local monsterAbilities = {}

-- Central definitions for all monster abilities
monsterAbilities.definitions = {
    -- Basic physical attacks
    basic_physical_attack = {
        name = "Attack",
        type = "physical",
        basePower = 100,
        target = "single_enemy",
        damageType = "physical",
        castingTime = 0, -- Instant cast
        description = "A basic physical attack."
    },
    strong_physical_attack = {
        name = "Strong Attack",
        type = "physical",
        basePower = 130,
        target = "single_enemy",
        damageType = "physical",
        description = "A powerful physical attack."
    },
    claw_attack = {
        name = "Claw",
        type = "physical",
        basePower = 110,
        target = "single_enemy",
        damageType = "slashing",
        description = "A sharp claw attack."
    },
    bite_attack = {
        name = "Bite",
        type = "physical",
        basePower = 120,
        target = "single_enemy",
        damageType = "piercing",
        description = "A powerful bite attack."
    },
    slam_attack = {
        name = "Slam",
        type = "physical",
        basePower = 130,
        target = "single_enemy",
        damageType = "bludgeoning",
        description = "A heavy slam attack."
    },
    
    -- Multi-target physical attacks
    sweep_attack = {
        name = "Sweep",
        type = "physical",
        basePower = 80,
        target = "all_enemies",
        damageType = "slashing",
        castingTime = 1, -- Short casting time for AoE physical attack
        description = "Attacks all enemies with a sweeping motion."
    },
    
    -- Status effect physical attacks
    infected_bite = {
        name = "Infected Bite",
        type = "physical",
        basePower = 90,
        target = "single_enemy",
        damageType = "piercing",
        effect = {
            type = "poison",
            chance = 0.7,
            duration = 3,
            strength = 1
        },
        description = "A bite that may cause poison."
    },
    bleeding_slash = {
        name = "Bleeding Slash",
        type = "physical",
        basePower = 90,
        target = "single_enemy",
        damageType = "slashing",
        effect = {
            type = "bleed",
            chance = 0.6,
            duration = 3,
            strength = 1
        },
        description = "A slash that causes bleeding."
    },
    concussive_blow = {
        name = "Concussive Blow",
        type = "physical",
        basePower = 80,
        target = "single_enemy",
        damageType = "bludgeoning",
        effect = {
            type = "stun",
            chance = 0.4,
            duration = 1,
            strength = 1
        },
        description = "A blow that may stun the target."
    },
    
    -- New animal abilities
    pounce_attack = {
        name = "Pounce",
        type = "physical",
        basePower = 110,
        target = "single_enemy",
        damageType = "slashing",
        effect = {
            type = "stun",
            chance = 0.3,
            duration = 1,
            strength = 1
        },
        description = "Leaps at the target with a chance to stun."
    },
    frenzy_attack = {
        name = "Frenzy",
        type = "physical",
        basePower = 100,
        target = "all_enemies",
        damageType = "slashing",
        hits = 3, -- Multiple hits
        description = "A wild series of attacks that hit randomly."
    },
    
    -- New troll abilities
    crushing_blow = {
        name = "Crushing Blow",
        type = "physical",
        basePower = 140,
        target = "single_enemy",
        damageType = "bludgeoning",
        effect = {
            type = "weakness",
            chance = 0.5,
            duration = 2,
            strength = 1
        },
        description = "A powerful blow that can weaken the target."
    },
    ground_slam = {
        name = "Ground Slam",
        type = "physical",
        basePower = 110,
        target = "all_enemies",
        damageType = "bludgeoning",
        effect = {
            type = "stun",
            chance = 0.3,
            duration = 1,
            strength = 1
        },
        description = "Slams the ground, creating a shockwave that can stun enemies."
    },
    
    -- New slime abilities
    acid_splash = {
        name = "Acid Splash",
        type = "physical",
        basePower = 80,
        target = "all_enemies",
        damageType = "acid",
        effect = {
            type = "defense_down",
            chance = 0.5,
            duration = 2,
            strength = 1
        },
        description = "Splashes acid that reduces defense."
    },
    absorb = {
        name = "Absorb",
        type = "physical",
        basePower = 100,
        target = "single_enemy",
        damageType = "acid",
        healing = 0.5, -- Heals for 50% of damage dealt
        description = "Absorbs the target's life force, healing the user."
    },
    
    -- Magical attacks
    fireball = {
        name = "Fireball",
        type = "magical",
        basePower = 130,
        target = "single_enemy",
        castingTime = 2, -- Medium casting time for powerful spell,
        damageType = "fire",
        description = "A ball of fire."
    },
    
    -- Multi-target magical attacks
    fire_breath = {
        name = "Fire Breath",
        type = "magical",
        basePower = 100,
        target = "all_enemies",
        damageType = "fire",
        description = "Breathes fire on all enemies."
    },
    
    -- New undead magic attacks
    arcane_bolt = {
        name = "Arcane Bolt",
        type = "magical",
        basePower = 125,
        target = "single_enemy",
        damageType = "arcane",
        effect = {
            type = "magic_vulnerability",
            chance = 0.4,
            duration = 2,
            strength = 1
        },
        description = "A bolt of arcane energy that increases magic damage taken."
    },
    lightning_bolt = {
        name = "Lightning Bolt",
        type = "magical",
        basePower = 130,
        target = "single_enemy",
        damageType = "lightning",
        effect = {
            type = "paralysis",
            chance = 0.3,
            duration = 1,
            strength = 1
        },
        description = "A bolt of lightning that can paralyze the target."
    },
    ice_bolt = {
        name = "Ice Bolt",
        type = "magical",
        basePower = 120,
        target = "single_enemy",
        damageType = "ice",
        effect = {
            type = "slow",
            chance = 0.4,
            duration = 2,
            strength = 1
        },
        description = "A bolt of ice that can slow the target."
    },
    necrotic_blast = {
        name = "Necrotic Blast",
        type = "magical",
        basePower = 140,
        target = "single_enemy",
        damageType = "necrotic",
        effect = {
            type = "weaken",
            chance = 0.5,
            duration = 2,
            strength = 1
        },
        description = "A blast of necrotic energy that weakens the target."
    },
    raise_dead = {
        name = "Raise Dead",
        type = "magical",
        basePower = 0,
        target = "self",
        effect = {
            type = "summon_ally",
            chance = 1.0,
            summonType = "zombie"
        },
        description = "Raises a dead ally to fight."
    },
    
    -- New demonic abilities
    hellfire = {
        name = "Hellfire",
        type = "magical",
        basePower = 150,
        target = "single_enemy",
        damageType = "fire",
        effect = {
            type = "burn",
            chance = 0.7,
            duration = 3,
            strength = 2
        },
        description = "Infernal flames that cause severe burning."
    },
    demonic_fury = {
        name = "Demonic Fury",
        type = "physical",
        basePower = 90,
        target = "all_enemies",
        damageType = "slashing",
        hits = 2,
        description = "A fury of slashes that hit all enemies multiple times."
    },
    seduce = {
        name = "Seduce",
        type = "magical",
        basePower = 50,
        target = "single_enemy",
        damageType = "psychic",
        effect = {
            type = "charm",
            chance = 0.4,
            duration = 1,
            strength = 1
        },
        description = "Seduces the target with a chance to charm them."
    },
    
    -- Status effect magical attacks
    flames_of_agony = {
        name = "Flames of Agony",
        type = "magical",
        basePower = 100,
        target = "single_enemy",
        damageType = "fire",
        effect = {
            type = "burn",
            chance = 0.8,
            duration = 3,
            strength = 1
        },
        description = "Flames that continue to burn."
    },
    toxic_spores = {
        name = "Toxic Spores",
        type = "magical",
        basePower = 90,
        target = "all_enemies",
        damageType = "poison",
        effect = {
            type = "poison",
            chance = 0.6,
            duration = 3,
            strength = 1
        },
        description = "Releases toxic spores that poison enemies."
    },
    
    -- Special abilities for bosses
    death_touch = {
        name = "Death Touch",
        type = "magical",
        basePower = 150,
        target = "single_enemy",
        damageType = "necrotic",
        effect = {
            type = "vulnerable",
            chance = 0.9,
            duration = 2,
            strength = 1
        },
        description = "A touch that brings death and vulnerability."
    },
    necrotic_touch = {
        name = "Necrotic Touch",
        type = "magical",
        basePower = 120,
        target = "single_enemy",
        damageType = "necrotic",
        effect = {
            type = "weaken",
            chance = 0.7,
            duration = 2,
            strength = 1
        },
        description = "A touch that drains life force and weakens the target."
    },
    arcane_explosion = {
        name = "Arcane Explosion",
        type = "magical",
        basePower = 160,
        target = "all_enemies",
        damageType = "arcane",
        description = "A massive explosion of arcane energy."
    },
    summon_minions = {
        name = "Summon Minions",
        type = "magical",
        basePower = 0,
        target = "self",
        effect = {
            type = "summon_ally",
            chance = 1.0,
            count = 2
        },
        description = "Summons minions to aid in battle."
    },
    split = {
        name = "Split",
        type = "support",
        basePower = 0,
        target = "self",
        effect = {
            type = "summon_ally",
            chance = 1.0,
            summonType = "slime_small",
            count = 2
        },
        description = "Splits into smaller slimes."
    },
    web_shot = {
        name = "Web Shot",
        type = "physical",
        basePower = 70,
        target = "single_enemy",
        damageType = "physical",
        effect = {
            type = "immobilize",
            chance = 0.8,
            duration = 2,
            strength = 1
        },
        description = "Shoots a web that can immobilize the target."
    },
    venom_spray = {
        name = "Venom Spray",
        type = "physical",
        basePower = 90,
        target = "all_enemies",
        damageType = "poison",
        effect = {
            type = "poison",
            chance = 0.7,
            duration = 4,
            strength = 2
        },
        description = "Sprays deadly venom that causes severe poisoning."
    },
    
    -- Buffing abilities
    strengthen_allies = {
        name = "Strengthen Allies",
        type = "support",
        basePower = 0,
        target = "all_allies",
        effect = {
            type = "strengthen",
            chance = 1.0,
            duration = 3,
            strength = 1
        },
        description = "Strengthens all allies, increasing their damage."
    },
    protective_aura = {
        name = "Protective Aura",
        type = "support",
        basePower = 0,
        target = "all_allies",
        effect = {
            type = "defense_up",
            chance = 1.0,
            duration = 3,
            strength = 1
        },
        description = "Creates an aura that increases allies' defense."
    },
    regeneration = {
        name = "Regeneration",
        type = "support",
        basePower = 0,
        target = "self",
        effect = {
            type = "heal_over_time",
            chance = 1.0,
            duration = 3,
            strength = 2
        },
        description = "Regenerates health over time."
    },
    rage = {
        name = "Rage",
        type = "support",
        basePower = 0,
        target = "self",
        effect = {
            type = "attack_up",
            chance = 1.0,
            duration = 3,
            strength = 2
        },
        description = "Increases attack power significantly."
    },
    silence_spell = {
        name = "Silence Spell",
        type = "magical",
        basePower = 70,
        target = "single_enemy",
        damageType = "arcane",
        effect = {
            type = "silence",
            chance = 0.7,
            duration = 2,
            strength = 1
        },
        description = "A spell that silences the target, preventing magical abilities."
    }
}

-- Assign abilities to specific monster types (can be accessed through the ID)
monsterAbilities.monsterTypes = {
    -- Animals
    animal = {
        low = {"bite_attack", "claw_attack"},
        medium = {"bite_attack", "claw_attack", "pounce_attack"},
        high = {"pounce_attack", "frenzy_attack", "bleeding_slash"}
    },
    
    -- Cultists
    cultist = {
        low = {"basic_physical_attack", "fireball"},
        medium = {"fireball", "flames_of_agony", "silence_spell"},
        high = {"fire_breath", "flames_of_agony", "strengthen_allies", "silence_spell"}
    },
    
    -- Demons
    demon = {
        low = {"claw_attack", "fireball"},
        medium = {"fireball", "hellfire", "demonic_fury"},
        high = {"hellfire", "demonic_fury", "seduce", "fire_breath"}
    },
    
    -- Goblins
    goblin = {
        low = {"basic_physical_attack", "bleeding_slash"},
        medium = {"fireball", "toxic_spores", "bleeding_slash"},
        high = {"fire_breath", "toxic_spores", "strengthen_allies"}
    },
    
    -- Insectoids
    insectoid = {
        low = {"bite_attack", "infected_bite"},
        medium = {"bite_attack", "infected_bite", "web_shot"},
        high = {"infected_bite", "web_shot", "venom_spray"}
    },
    
    -- Slime
    slime = {
        low = {"basic_physical_attack", "acid_splash"},
        medium = {"acid_splash", "absorb"},
        high = {"acid_splash", "absorb", "toxic_spores"}
    },
    
    -- Troll
    troll = {
        low = {"slam_attack", "crushing_blow"},
        medium = {"slam_attack", "crushing_blow", "ground_slam"},
        high = {"crushing_blow", "ground_slam", "frenzy_attack"}
    },
    
    -- Undead
    undead = {
        low = {"bite_attack", "claw_attack"},
        medium = {"bite_attack", "necrotic_blast", "ice_bolt"},
        high = {"necrotic_blast", "death_touch", "raise_dead"}
    },
    
    -- Bosses
    boss = {
        low = {"slam_attack", "sweep_attack", "protective_aura"},
        medium = {"slam_attack", "sweep_attack", "fire_breath", "strengthen_allies", "summon_minions"},
        high = {"arcane_explosion", "death_touch", "strengthen_allies", "protective_aura", "summon_minions", "venom_spray"}
    }
}

-- Helper function to get appropriate abilities based on monster level
function monsterAbilities:getAbilitiesForMonster(category, level)
    local tierMap = {
        [1] = "low",
        [2] = "low",
        [3] = "medium",
        [4] = "medium",
        [5] = "medium",
        [6] = "high",
        [7] = "high",
        [8] = "high",
        [9] = "high",
        [10] = "high"
    }
    
    local tier = tierMap[level] or "low"
    local monsterCategory = category:lower()
    
    -- Map category to ability type
    local abilityType
    if monsterCategory:find("animal") then
        abilityType = "animal"
    elseif monsterCategory:find("cultist") then
        abilityType = "cultist"
    elseif monsterCategory:find("demon") then
        abilityType = "demon"
    elseif monsterCategory:find("goblin") then
        abilityType = "goblin"
    elseif monsterCategory:find("insectoid") then
        abilityType = "insectoid"
    elseif monsterCategory:find("slime") then
        abilityType = "slime"
    elseif monsterCategory:find("troll") then
        abilityType = "troll"
    elseif monsterCategory:find("undead") then
        abilityType = "undead"
    else
        -- Default to basic abilities (animals as fallback)
        abilityType = "animal"
    end
    
    -- Use boss abilities if monster is a boss
    if level >= 6 and (monsterCategory:find("boss") or level >= 8) then
        abilityType = "boss"
    end
    
    return self.monsterTypes[abilityType][tier] or {"basic_physical_attack"}
end

return monsterAbilities 