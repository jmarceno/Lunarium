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
        description = "A basic physical attack."
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
    
    -- Magical attacks
    fireball = {
        name = "Fireball",
        type = "magical",
        basePower = 130,
        target = "single_enemy",
        damageType = "fire",
        description = "A ball of fire."
    },
    ice_spike = {
        name = "Ice Spike",
        type = "magical",
        basePower = 120,
        target = "single_enemy",
        damageType = "ice",
        description = "A sharp spike of ice."
    },
    lightning_bolt = {
        name = "Lightning Bolt",
        type = "magical",
        basePower = 140,
        target = "single_enemy",
        damageType = "lightning",
        description = "A bolt of lightning."
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
    frost_nova = {
        name = "Frost Nova",
        type = "magical",
        basePower = 90,
        target = "all_enemies",
        damageType = "ice",
        description = "A burst of freezing energy."
    },
    chain_lightning = {
        name = "Chain Lightning",
        type = "magical",
        basePower = 110,
        target = "all_enemies",
        damageType = "lightning",
        description = "Lightning that chains between targets."
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
    arcane_explosion = {
        name = "Arcane Explosion",
        type = "magical",
        basePower = 160,
        target = "all_enemies",
        damageType = "arcane",
        description = "A massive explosion of arcane energy."
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
        target = "self",
        effect = {
            type = "protect",
            chance = 1.0,
            duration = 3,
            strength = 1
        },
        description = "Surrounds self with a protective aura, reducing damage taken."
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
    -- Bloomers (Fungal monsters)
    fungal = {
        low = {"basic_physical_attack", "infected_bite"},
        medium = {"basic_physical_attack", "infected_bite", "toxic_spores"},
        high = {"infected_bite", "toxic_spores", "strengthen_allies"}
    },
    
    -- Cultists
    cultist = {
        low = {"basic_physical_attack", "fireball"},
        medium = {"fireball", "flames_of_agony", "protective_aura"},
        high = {"fire_breath", "flames_of_agony", "strengthen_allies", "silence_spell"}
    },
    
    -- Undead
    undead = {
        low = {"bite_attack", "claw_attack"},
        medium = {"bite_attack", "infected_bite", "bleeding_slash"},
        high = {"infected_bite", "death_touch", "strengthen_allies"}
    },
    
    -- Insects
    insect = {
        low = {"bite_attack", "infected_bite"},
        medium = {"bite_attack", "infected_bite", "toxic_spores"},
        high = {"infected_bite", "toxic_spores", "concussive_blow"}
    },
    
    -- Bosses
    boss = {
        low = {"slam_attack", "sweep_attack", "protective_aura"},
        medium = {"slam_attack", "sweep_attack", "fire_breath", "strengthen_allies"},
        high = {"arcane_explosion", "death_touch", "strengthen_allies", "protective_aura", "silence_spell"}
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
    if monsterCategory:find("bloomer") then
        abilityType = "fungal"
    elseif monsterCategory:find("cultist") then
        abilityType = "cultist"
    elseif monsterCategory:find("undead") then
        abilityType = "undead"
    elseif monsterCategory:find("insect") then
        abilityType = "insect"
    else
        -- Default to basic abilities
        abilityType = "fungal"
    end
    
    -- Use boss abilities if monster is a boss
    if level >= 6 and (monsterCategory:find("boss") or level >= 8) then
        abilityType = "boss"
    end
    
    return self.monsterTypes[abilityType][tier] or {"basic_physical_attack"}
end

return monsterAbilities 