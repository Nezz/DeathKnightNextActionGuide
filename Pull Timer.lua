local pullTimerRegistration = C_ChatInfo.IsAddonMessagePrefixRegistered("D5WC")
if not pullTimerRegistration then C_ChatInfo.RegisterAddonMessagePrefix("D5WC") end

aura_env.Prepull = {}

aura_env.ShowWithCombat = function(auras, pullTimerDuration, timeUntilCombat)
    for time,spellId in pairs(aura_env.Prepull) do
        local duration = pullTimerDuration + time
        auras[time] = {
            show = pullTimerDuration ~= 0 and pullTimerDuration > -time,
            changed = true,
            progressType = "timed",
            duration = duration,
            expirationTime = GetTime() + duration,
            autoHide = true,
            index = time,
            icon = GetSpellTexture(spellId)
        }
    end

    if aura_env.Potion then
        local time = timeUntilCombat - pullTimerDuration - 1
        local duration = pullTimerDuration + time
        auras[99] = {
            show = pullTimerDuration ~= 0 and pullTimerDuration > -time,
            changed = true,
            progressType = "timed",
            duration = duration,
            expirationTime = GetTime() + duration,
            autoHide = true,
            index = time,
            icon = GetSpellTexture(aura_env.Potion)
        }
    end
end

aura_env.Show = function(auras, pullTimerDuration)
    aura_env.ShowWithCombat(auras, pullTimerDuration, pullTimerDuration)
end

aura_env.Spells = {
    BloodTap = 45529,
    RaiseDead = 46584,
    EmpowerRuneWeapon = 47568,
    UnbreakableArmor = 51271,
    HornOfWinter = 57623,
    GCD = 61304,
    
    FrostFever = 55095,
    BloodPlague = 55078,
    KillingMachine = 51124,
    FreezingFog = 59052,
    
    IcyTouch = 49909,
    FrostStrike = 55268,
    PlagueStrike = 49921,
    Obliterate = 51425,
    HowlingBlast = 51411,
    Pestilence = 50842,
    BloodStrike = 49930,
    BloodBoil = 49941,
    
    PotionOfSpeed = 53908,
    IndestructiblePotion = 53762,
    Berserking = 26297,
    Strangulate = 47476,
    Gloves = 54758,
    SaroniteBomb = 56350,
    Sapper = 56488,
    
    DeathAndDecay = 49938,
    ArmyOfTheDead = 42650,
    Desolation = 66803,
    SummonGargoyle = 49206,
    GhoulFrenzy = 63560,
    ScourgeStrike = 55271,
    
    RuneStrike = 56815,
    DeathStrike = 49998,
    DeathCoil = 47541,
    UnholyFrenzy = 49016,
    
    FrostPresence = 48263,
    UnholyPresence = 48265,
    BloodPresence = 48266,
}