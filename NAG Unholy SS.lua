function(auras)
    local spells = aura_env.Spells
    aura_env.Update(auras, function()
        return (aura_env.DotRemainingTime(spells.FrostFever) < 3 and aura_env.Cast(spells.IcyTouch))
        or (aura_env.DotRemainingTime(spells.BloodPlague) < 3 and aura_env.Cast(spells.PlagueStrike))
        or (not aura_env.AuraIsActive(spells.Desolation) and aura_env.Cast(spells.BloodStrike))
        or ((aura_env.AuraIsActive(spells.SummonGargoyle) or aura_env.TimeToReady(spells.SummonGargoyle) > 50) and aura_env.Cast(spells.Gloves))
        or (aura_env.AuraIsActive(spells.SummonGargoyle) and aura_env.Cast(spells.EmpowerRuneWeapon))
        or (aura_env.AuraIsActive(spells.SummonGargoyle) and aura_env.Cast(spells.ArmyOfTheDead))
        or aura_env.Cast(spells.DeathAndDecay)
        or (aura_env.TimeToReady(spells.DeathAndDecay) > 6 and (aura_env.Cast(spells.BloodStrike) and aura_env.Cast(spells.ScourgeStrike)))
        or (aura_env.TimeToReady(spells.DeathAndDecay) > 6 and aura_env.AuraRemainingTime(spells.Desolation) < 10 and aura_env.Cast(spells.BloodStrike))
        or (aura_env.TimeToReady(spells.DeathAndDecay) > 6 and aura_env.Cast(spells.BloodBoil))
        or aura_env.Cast(spells.SummonGargoyle)
        or (not aura_env.IsReady(spells.SummonGargoyle) and aura_env.Cast(spells.DeathCoil))
        or (not aura_env.Cast(spells.BloodTap) and aura_env.Cast(spells.GhoulFrenzy))
        or (aura_env.AuraIsActive(spells.UnholyPresence) and not aura_env.Isready(spells.SummonGargoyle) and not aura_env.AuraIsActive(spells.SummonGargoyle) and aura_env.Cast(spells.BloodPresence))
    end)
    return true
end

