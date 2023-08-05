function()
    local spells = aura_env.Spells
    
    aura_env.Prepull[-10] = spells.UnholyPresence
    aura_env.Prepull[-8] = spells.GhoulFrenzy
    aura_env.Potion = spells.PotionOfSpeed
end
