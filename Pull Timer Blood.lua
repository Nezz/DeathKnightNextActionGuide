function()
    local spells = aura_env.Spells
    
    aura_env.Prepull[-20] = spells.UnholyPresence
    aura_env.Prepull[-10] = spells.ArmyOfTheDead
    aura_env.Prepull[-6] = spells.BloodPresence
    aura_env.Prepull[-1] = spells.PotionOfSpeed
    aura_env.Prepull[0] = spells.UnholyFrenzy
end
