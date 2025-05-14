local damageTypes = {}

-- Define all damage types with their display properties
damageTypes.types = {
    ["physical"] = { name = "Physical", color = {0.8, 0.8, 0.8}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 }, -- Placeholder icon
    ["slashing"] = { name = "Slashing", color = {0.9, 0.7, 0.7}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["bludgeoning"] = { name = "Bludgeoning", color = {0.7, 0.7, 0.9}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["piercing"] = { name = "Piercing", color = {0.8, 0.8, 0.9}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["fire"] = { name = "Fire", color = {0.9, 0.5, 0.1}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["ice"] = { name = "Ice", color = {0.5, 0.8, 0.9}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["lightning"] = { name = "Lightning", color = {0.9, 0.9, 0.3}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["poison"] = { name = "Poison", color = {0.4, 0.8, 0.4}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["necrotic"] = { name = "Necrotic", color = {0.5, 0.2, 0.5}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 },
    ["arcane"] = { name = "Arcane", color = {0.8, 0.4, 0.8}, icon = "assets/Icons/StatusEffects/poison.png", iconSize = 24 }
}

-- Calculate damage modifier based on resistances and immunities
-- @param damageType: string - The type of damage
-- @param target: table - The target with resistances and immunities
-- @return multiplier: number - The damage multiplier (0 = immune, <1 = resistant, 1 = normal, >1 = vulnerable)
function damageTypes:calculateModifier(damageType, target)
    -- If the target has no resistances or they're not relevant to this damage type
    if not target or not damageType then
        return 1.0 -- Normal damage
    end
    
    -- Check for immunity
    if target.immunities then
        for _, immune in ipairs(target.immunities) do
            if immune == damageType then
                return 0.0 -- No damage
            end
        end
    end
    
    -- Check for resistance/vulnerability
    if target.resistances and target.resistances[damageType] then
        local resistValue = target.resistances[damageType]
        return 1.0 + (resistValue / 100) -- Convert percentage to multiplier
    end
    
    -- Default: no special resistance or vulnerability
    return 1.0
end

-- Get the display text for a damage type's effectiveness
-- @param multiplier: number - The damage multiplier
-- @return text: string - The display text (e.g., "Resisted", "Weak", "Immune")
-- @return color: table - The color for the text
function damageTypes:getDisplayText(multiplier)
    if multiplier == 0 then
        return "Immune", {0.7, 0.7, 0.7}
    elseif multiplier < 1 then
        return "Resisted", {0.4, 0.8, 0.4}
    elseif multiplier > 1 then
        return "Weakness", {0.9, 0.4, 0.4}
    else
        return nil, nil -- No special text for normal damage
    end
end

return damageTypes 