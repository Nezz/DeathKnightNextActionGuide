function(auras)
    local spells = aura_env.Spells
    aura_env.Update(auras, function()
        return aura_env.Sequence("Opener",
        spells.IcyTouch,
        spells.PlagueStrike,
        spells.UnbreakableArmor,
        spells.BloodTap,
        spells.Obliterate,
        spells.FrostStrike,
        spells.BloodStrike,
        spells.EmpowerRuneWeapon,
        spells.Obliterate,
        spells.FrostStrike,
        spells.Obliterate,
        spells.Obliterate,
        spells.RaiseDead)
    or (not aura_env.DotIsActive(spells.FrostFever) and aura_env.Cast(spells.IcyTouch))
    or (not aura_env.DotIsActive(spells.BloodPlague) and aura_env.Cast(spells.PlagueStrike))
    or (aura_env.DotRemainingTime(spells.FrostFever) > 0 and aura_env.DotRemainingTime(spells.FrostFever) < 1.5 and aura_env.Cast(spells.Pestilence))
    or (aura_env.CanCast(spells.UnbreakableArmor) and aura_env.Cast(spells.Gloves))
    or (aura_env.CanCast(spells.UnbreakableArmor) and aura_env.Cast(spells.PotionOfSpeed))
    or (aura_env.Cast(spells.UnbreakableArmor) and aura_env.Cast(spells.BloodTap))
    or (aura_env.DotRemainingTime(spells.FrostFever) > 0 and aura_env.DotRemainingTime(spells.FrostFever) < 8.5 and aura_env.Cast(spells.Pestilence))
    or (aura_env.AuraIsActive(spells.FreezingFog) and aura_env.Cast(spells.HowlingBlast))
    or aura_env.Cast(spells.Obliterate)
    or aura_env.Cast(spells.RaiseDead)
    or aura_env.Cast(spells.BloodStrike)
    or aura_env.Cast(spells.FrostStrike)
    or aura_env.Cast(spells.HornOfWinter)
    end)
    return true
end

