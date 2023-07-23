function(auras)
    local spells = aura_env.Spells
    aura_env.Update(auras, function()
        return aura_env.Sequence("Opener",
        spells.IcyTouch,
        spells.PlagueStrike,
        spells.BloodStrike,
        spells.UnbreakableArmor,
        spells.BloodTap,
        spells.Gloves,
        spells.DeathAndDecay,
        spells.EmpowerRuneWeapon,
        spells.ArmyOfTheDead)
    or (not aura_env.DotIsActive(spells.FrostFever) and aura_env.Cast(spells.IcyTouch))
    or (not aura_env.DotIsActive(spells.BloodPlague) and aura_env.Cast(spells.PlagueStrike))
    or (aura_env.CanCast(spells.UnbreakableArmor) and aura_env.Cast(spells.Gloves))
    or (aura_env.CanCast(spells.UnbreakableArmor) and aura_env.Cast(spells.PotionOfSpeed))
    or (aura_env.Cast(spells.UnbreakableArmor) and aura_env.Cast(spells.BloodTap))
    or (aura_env.RunicPower() >= 110 and aura_env.Cast(spells.FrostStrike))
    or (aura_env.AuraIsActive(spells.KillingMachine) and aura_env.Cast(spells.FrostStrike))
    or aura_env.Cast(spells.PlagueStrike)
    or (not aura_env.AuraIsActive(spells.KillingMachine) and aura_env.Cast(spells.IcyTouch))
    or aura_env.Cast(spells.BloodStrike)
    or aura_env.Cast(spells.HornOfWinter)
    end)
    return true
end

