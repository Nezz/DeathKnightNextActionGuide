function(auras)
    local spells = aura_env.Spells
    aura_env.Update(auras, function()
        return (not aura_env.AuraIsActive(spells.FrostPresence) and aura_env.Cast(spells.FrostPresence))
        or (aura_env.Cast(spells.UnholyFrenzy))
        or (aura_env.RunicPower() >= 40 and aura_env.Cast(spells.RuneStrike))
        or (not aura_env.DotIsActive(spells.FrostFever) and aura_env.Cast(spells.IcyTouch))
        or (not aura_env.DotIsActive(spells.BloodPlague) and aura_env.Cast(spells.PlagueStrike))
        or (aura_env.DotRemainingTime(spells.BloodPlague) < 3 and aura_env.DotIsActive(spells.BloodPlague) and aura_env.Cast(spells.Pestilence))
        or (aura_env.NumNonDeathRunes(aura_env.RuneType.Frost) > 0 and aura_env.NumNonDeathRunes(aura_env.RuneType.Unholy) > 0 and aura_env.Cast(spells.DeathStrike))
        or (aura_env.NumRunes(aura_env.RuneType.Death) > 0 and aura_env.Cast(spells.IcyTouch))
        or (aura_env.NumNonDeathRunes(aura_env.RuneType.Blood) > 1 and aura_env.CanCast(spells.EmpowerRuneWeapon) and aura_env.Cast(spells.BloodStrike))
        or (aura_env.Cast(spells.RaiseDead))
        or (aura_env.Cast(spells.EmpowerRuneWeapon))
        or (aura_env.RunicPower() >= 80 and aura_env.Cast(spells.DeathCoil))
    end)
    return true
end

