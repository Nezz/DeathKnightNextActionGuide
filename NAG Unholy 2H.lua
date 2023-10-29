function(auras)
    local spells = aura_env.Spells
    aura_env.Update(auras, function()
        return (aura_env.DotRemainingTime(spells.FrostFever) <= aura_env.NextRuneCooldown(aura_env.RuneType.Frost) and aura_env.Cast(spells.IcyTouch))
        or (aura_env.DotRemainingTime(spells.BloodPlague) <= aura_env.NextRuneCooldown(aura_env.RuneType.Unholy) and aura_env.Cast(spells.PlagueStrike))
        or (not aura_env.AuraIsActive(spells.Desolation) and aura_env.Cast(spells.BloodStrike))
        or ((aura_env.AuraIsActive(spells.SummonGargoyle) or aura_env.TimeToReady(spells.SummonGargoyle) > 50) and aura_env.Cast(spells.Gloves))
        or (aura_env.AuraIsActive(spells.SummonGargoyle) and aura_env.Cast(spells.PotionOfSpeed))
        or (aura_env.AuraIsActive(spells.SummonGargoyle) and aura_env.Cast(spells.ArmyOfTheDead))
        or (aura_env.IsReady(spells.BloodTap) and aura_env.IsReady(spells.GhoulFrenzy) and (aura_env.Cast(spells.BloodTap) or aura_env.Cast(spells.GhoulFrenzy)))
        or aura_env.Cast(spells.ScourgeStrike)
        or (aura_env.AuraIsActive(spells.UnholyPresence) and not aura_env.IsReady(spells.SummonGargoyle) and not aura_env.AuraIsActive(spells.SummonGargoyle)
            and aura_env.Cast(spells.BloodPresence)) -- Increased in priority to avoid being stuck in Unholy
        or aura_env.Cast(spells.BloodStrike)
        or (aura_env.AuraIsActive(spells.SummonGargoyle) and aura_env.Cast(spells.EmpowerRuneWeapon))
        or aura_env.Cast(spells.SummonGargoyle)
        or (not aura_env.IsReady(spells.SummonGargoyle) and aura_env.Cast(spells.DeathCoil))
        or aura_env.Cast(spells.HornOfWinter)
    end)
    return true
end

