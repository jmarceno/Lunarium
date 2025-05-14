local minionAbilities = {}

-- Central definitions for all minion abilities
minionAbilities.definitions = {
    -- Basic minion physical attacks
    minion_basic_attack = {
        name = "Attack",
        type = "physical",
        basePower = 90,
        target = "single_enemy",
        damageType = "physical",
        description = "A basic physical attack by a minion."
    },
    minion_claw_attack = {
        name = "Claw",
        type = "physical",
        basePower = 100,
        target = "single_enemy",
        damageType = "slashing",
        description = "A minion's claw attack."
    },
    minion_bite_attack = {
        name = "Bite",
        type = "physical",
        basePower = 110,
        target = "single_enemy",
        damageType = "piercing",
        description = "A minion's bite attack."
    },
    minion_slam_attack = {
        name = "Slam",
        type = "physical",
        basePower = 120,
        target = "single_enemy",
        damageType = "bludgeoning",
        description = "A heavy slam attack by a minion."
    },
    
    -- Undead minion abilities
    skeleton_bone_strike = {
        name = "Bone Strike",
        type = "physical",
        basePower = 110,
        target = "single_enemy",
        damageType = "bludgeoning",
        description = "A strike with a skeletal limb."
    },
    zombie_infected_bite = {
        name = "Infected Bite",
        type = "physical",
        basePower = 100,
        target = "single_enemy",
        damageType = "piercing",
        effect = {
            type = "poison",
            chance = 0.5,
            duration = 2,
            strength = 1
        },
        description = "A bite that may cause infection."
    },
    ghost_haunting_touch = {
        name = "Haunting Touch",
        type = "magical",
        basePower = 110,
        target = "single_enemy",
        damageType = "necrotic",
        description = "A ghostly touch that causes necrotic damage."
    },
    
    -- Elemental minion abilities
    fire_elemental_flame = {
        name = "Elemental Flame",
        type = "magical",
        basePower = 120,
        target = "single_enemy",
        damageType = "fire",
        effect = {
            type = "burn",
            chance = 0.6,
            duration = 2,
            strength = 1
        },
        description = "Elemental flames that burn the target."
    },
    ice_elemental_frost = {
        name = "Elemental Frost",
        type = "magical",
        basePower = 115,
        target = "single_enemy",
        damageType = "ice",
        description = "Elemental frost that chills the target."
    },
    lightning_elemental_shock = {
        name = "Elemental Shock",
        type = "magical",
        basePower = 125,
        target = "single_enemy",
        damageType = "lightning",
        description = "Elemental lightning that shocks the target."
    },
    
    -- Beast minion abilities
    wolf_rend = {
        name = "Rend",
        type = "physical",
        basePower = 110,
        target = "single_enemy",
        damageType = "slashing",
        effect = {
            type = "bleed",
            chance = 0.6,
            duration = 3,
            strength = 1
        },
        description = "A rending attack that causes bleeding."
    },
    bear_maul = {
        name = "Maul",
        type = "physical",
        basePower = 130,
        target = "single_enemy",
        damageType = "slashing",
        description = "A devastating maul attack."
    },
    snake_venomous_bite = {
        name = "Venomous Bite",
        type = "physical",
        basePower = 100,
        target = "single_enemy",
        damageType = "piercing",
        effect = {
            type = "poison",
            chance = 0.7,
            duration = 3,
            strength = 1
        },
        description = "A bite that injects venom."
    },
    
    -- Construct minion abilities
    golem_crush = {
        name = "Crush",
        type = "physical",
        basePower = 140,
        target = "single_enemy",
        damageType = "bludgeoning",
        description = "A powerful crushing attack."
    },
    automaton_crossbow = {
        name = "Crossbow Shot",
        type = "physical",
        basePower = 120,
        target = "single_enemy",
        damageType = "piercing",
        description = "A precise crossbow shot."
    },
    
    -- Demonic minion abilities
    imp_firebolt = {
        name = "Firebolt",
        type = "magical",
        basePower = 110,
        target = "single_enemy",
        damageType = "fire",
        description = "A bolt of hellfire."
    },
    demon_shadowbolt = {
        name = "Shadowbolt",
        type = "magical",
        basePower = 130,
        target = "single_enemy",
        damageType = "necrotic",
        description = "A bolt of shadow energy."
    }
}

-- Helper function to get ability by ID
function minionAbilities:getAbility(abilityId)
    return self.definitions[abilityId]
end

return minionAbilities 