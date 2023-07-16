if not _G[aura_env.id] then
    _G[aura_env.id] = C_Timer.NewTicker(0.1, function()
            WeakAuras.ScanEvents("SIM_NAG_UPDATE")
    end)
end

aura_env.Update = function(auras, rotation)
    local timeNow = GetTime()
    local gcdStart, gcdDuration = GetSpellCooldown(aura_env.Spells.GCD)
    aura_env.nextTime = math.max(timeNow + 0.3, gcdStart + gcdDuration)
    aura_env.NextSpell = 10730
    aura_env.SecondarySpells = {}

    rotation()

    local show = UnitCanAttack("player", "target")

    auras[0] = {
        show = show,
        changed = true,
        primary = true,
        icon = GetSpellTexture(aura_env.NextSpell)
    }

    for i=1,5 do
        auras[i] = {
            show = show and aura_env.SecondarySpells[i],
            changed = true,
            primary = false,
            icon = GetSpellTexture(aura_env.SecondarySpells[i])
        }
    end
end

aura_env.AuraIsActive = function(spellId)
    local spellName = GetSpellInfo(spellId)
    return spellName and AuraUtil.FindAuraByName(spellName, "player")
end

aura_env.AuraRemainingTime = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 999
    end
    local _,_,_,_,_,expires = AuraUtil.FindAuraByName(spellName, "player")
    
    if not expires then
        return 999
    end

    return expires - aura_env.nextTime
end

aura_env.DotIsActive = function(spellId)
    local spellName = GetSpellInfo(spellId)
    return spellName and AuraUtil.FindAuraByName(spellName, "target", "PLAYER|HARMFUL")
end

aura_env.DotRemainingTime = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 999
    end
    local _,_,_,_,_,expires = AuraUtil.FindAuraByName(spellName, "target", "PLAYER|HARMFUL")
    
    if not expires then
        return 999
    end

    return expires - aura_env.nextTime
end

aura_env.IsReady = function(spellId)
    local start, duration = GetSpellCooldown(spellId)
    return start + duration <= aura_env.nextTime
end

aura_env.CanCast = function(spellId)
    local usable,nomana = IsUsableSpell(spellId)
    if nomana then
        return false
    end

    -- Rune Strike has no cooldown, it becomes usable after a dodge or parry
    if spellId == aura_env.Spells.RuneStrike then
        if not usable or IsCurrentSpell(aura_env.Spells.RuneStrike) then
            return false
        end
    end

    return aura_env.IsReady(spellId)
end

aura_env.TimeToReady = function(spellId)
    local start, duration = GetSpellCooldown(spellId)

    if start == 0 then
        return 0
    end

    return start + duration - aura_env.nextTime
end

aura_env.Cast = function(spellId)
    if aura_env.CanCast(spellId) then
        if aura_env.IsMajorCooldown(spellId) then
            aura_env.AddSecondarySpell(spellId)
            return false
        else
            aura_env.NextSpell = spellId
            return true
        end
    end
    
    return false
end

aura_env.RunicPower = function()
    return UnitPower("player", 6)
end

aura_env.RuneType = {
    Blood = 1,
    Unholy = 2,
    Frost = 3,
    Death = 4
}

aura_env.NumNonDeathRunes = function(runeType)
    local total = 0
    for i=1,6 do
        if GetRuneType(i) == runeType then
            total = total + 1
        end
    end
    return total
end

aura_env.NumRunes = function(runeType)
    local total = 0
    for i=1,6 do
        local rt = GetRuneType(i)
        if rt == runeType or rt == aura_env.RuneType.Death then
            total = total + 1
        end
    end
    return total
end

aura_env.ResetSequences = function()
    aura_env.SequencePosition = {}
    aura_env.SequenceSpells = {}
end

aura_env.ResetSequences()

aura_env.ResetSequence = function(name)
    aura_env.SequencePosition[name] = nil
    aura_env.SequenceSpells[name] = nil
end

aura_env.Sequence = function(name, ...)
    local index = aura_env.SequencePosition[name] or 1

    if select('#',...) < index then
        return false
    end

    if not aura_env.SequenceSpells[name] then
        aura_env.SequenceSpells[name] = {...}
    end
    
    aura_env.SequencePosition[name] = index
    local item = aura_env.SequenceSpells[name][index]
    return aura_env.Cast(item)
end

aura_env.SpellCastSucceeded = function(spellId)
    for name, spells in pairs(aura_env.SequenceSpells) do
        local nextSpell = spells[aura_env.SequencePosition[name]]
        if spellId == nextSpell then
            aura_env.SequencePosition[name] = aura_env.SequencePosition[name] + 1
            if #spells < aura_env.SequencePosition[name] then
                print("Sequence " .. name .. " completed")
            else
                print("Advanced to next spell in sequence: " .. name .. " " .. GetSpellInfo(nextSpell) .. " -> " .. GetSpellInfo(spells[aura_env.SequencePosition[name]]))
            end
        end
    end
end

aura_env.AddSecondarySpell = function(spellId)
    for i=1,#aura_env.SecondarySpells do
        if aura_env.SecondarySpells[i] == spellId then
           return
        end
    end
    table.insert(aura_env.SecondarySpells, spellId)
end

aura_env.Spells = {
    BloodTap = 45529,
    RaiseDead = 46584,
    EmpowerRuneWeapon = 47568,
    UnbreakableArmor = 51271,
    HornOfWinter = 57623,
    GCD = 61304,
    
    FrostFever = 55095,
    BloodPlague = 55264,
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
    SummonGargoyle = 61777,
    GhoulFrenzy = 63560,
    ScourgeStrike = 71488,

    RuneStrike = 56815,
    DeathStrike = 49998,
    DeathCoil = 47541,

    FrostPresence = 48263,
    UnholyPresence = 48265,
    BloodPresence = 48266,
}

aura_env.IsMajorCooldown = function(spellId)
    return spellId == aura_env.Spells.RaiseDead or
        spellId == aura_env.Spells.EmpowerRuneWeapon or
        spellId == aura_env.Spells.UnbreakableArmor or
        spellId == aura_env.Spells.BloodTap or
        spellId == aura_env.Spells.ArmyOfTheDead or
        spellId == aura_env.Spells.Gloves or
        spellId == aura_env.Spells.SaroniteBomb or
        spellId == aura_env.Spells.Sapper or
        spellId == aura_env.Spells.PotionOfSpeed or
        spellId == aura_env.Spells.IndestructiblePotion
end