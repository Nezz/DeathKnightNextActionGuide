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
    aura_env.FindAuraByNamePlayerCache = {}
    aura_env.FindAuraByNameTargetCache = {}
    aura_env.FindAuraByNamePetCache = {}

    local show = UnitCanAttack("player", "target")
    if show then
        local foundSpell = rotation()
        while not foundSpell and aura_env.nextTime - timeNow < 10 do
            aura_env.nextTime = aura_env.nextTime + 0.3
            foundSpell = rotation()
        end
    end

    auras[0] = {
        show = show,
        changed = true,
        primary = true,
        icon = GetSpellTexture(aura_env.NextSpell),
        index = 0
    }

    for i=1,5 do
        auras[i] = {
            show = show and aura_env.SecondarySpells[i],
            changed = true,
            primary = false,
            icon = GetSpellTexture(aura_env.SecondarySpells[i]),
            index = i
        }
    end
end

aura_env.AuraIsActive = function(spellId)
    if spellId == aura_env.Spells.SummonGargoyle then
        -- The sim assumes that Gary is an aura but it's not
        return aura_env.TimeToReady(aura_env.Spells.SummonGargoyle) >= 150
    end

    local spellName = GetSpellInfo(spellId)
    return spellName and aura_env.FindAuraByName(spellName, "player")
end

aura_env.AuraIsActivePet = function(spellId)
    local spellName = GetSpellInfo(spellId)
    return spellName and aura_env.FindAuraByName(spellName, "pet")
end

aura_env.AuraRemainingTime = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 0
    end
    local _,_,_,_,_,expires = aura_env.FindAuraByName(spellName, "player")
    
    if not expires then
        return 0
    end

    return expires - aura_env.nextTime
end

aura_env.AuraRemainingICD = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 0
    end
    local _,_,_,_,duration,expires = aura_env.FindAuraByName(spellName, "player")

    local icdReady = 0
    if expires then
        icdReady = expires - duration + aura_env.GetIcd(spellId)
        aura_env.IcdReady[spellId] = icdReady
    else
        icdReady = aura_env.IcdReady[spellId]

        if not icdReady then
            -- We are not aware of this buff being applied in the past, so we assume that it's ready
            return 0
        end
    end

    return icdReady - aura_env.nextTime
end

aura_env.DotIsActive = function(spellId)
    local spellName = GetSpellInfo(spellId)
    return spellName and aura_env.FindAuraByName(spellName, "target")
end

aura_env.DotRemainingTime = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 0
    end
    local _,_,_,_,_,expires = aura_env.FindAuraByName(spellName, "target")
    
    if not expires then
        return 0
    end

    return expires - aura_env.nextTime
end

aura_env.IsReady = function(spellId)
    local start, duration = GetSpellCooldown(spellId)
    return start + duration <= aura_env.nextTime
end

aura_env.CanCast = function(spellId)
    if not aura_env.HasRunicPower(spellId) then
        return false
    end

    -- Rune Strike has no cooldown, it becomes usable after a dodge or parry
    if spellId == aura_env.Spells.RuneStrike then
        local usable = IsUsableSpell(spellId)
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
        if GetRuneType(i) == runeType and aura_env.RuneReady(i) then
            total = total + 1
        end
    end
    return total
end

aura_env.NumRunes = function(runeType)
    local total = 0
    for i=1,6 do
        local rt = GetRuneType(i)
        if (rt == runeType or rt == aura_env.RuneType.Death) and aura_env.RuneReady(i) then
            total = total + 1
        end
    end
    return total
end

aura_env.RuneReady = function(index)
    local start, duration = GetRuneCooldown(index);
    return start + duration <= aura_env.nextTime
end

aura_env.NextRuneCooldown = function(runeType)
    local cooldown = 10
    for i=1,6 do
        local rt = GetRuneType(i)
        if rt == runeType or rt == aura_env.RuneType.Death then
            local start, duration = GetRuneCooldown(i);
            cooldown = math.min(cooldown, start + duration - aura_env.nextTime)
        end
    end

    return math.max(cooldown, 0)
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
                DebugPrint("Sequence " .. name .. " completed")
            else
                DebugPrint("Advanced to next spell in sequence: " .. name .. " " .. GetSpellInfo(nextSpell) .. " -> " .. GetSpellInfo(spells[aura_env.SequencePosition[name]]))
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

aura_env.HasRunicPower = function(spellId)
    local costTable = GetSpellPowerCost(spellId);
	if costTable == nil then
		return 0
	end
	local cost = table.foreach(costTable, function(_, v)
		if v.name == "RUNIC_POWER" then
			return math.max(v.cost, 0); -- Negative runing power is returned for spells that generate runic power
		end
	end)

    return not cost or cost <= UnitPower("player", SPELL_POWER_RUNIC_POWER)
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
    UnholyForce = 67383,
    UnholyMight = 67117,
    
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
        spellId == aura_env.Spells.IndestructiblePotion or
        spellId == aura_env.Spells.FrostPresence or
        spellId == aura_env.Spells.UnholyFrenzy
end

aura_env.IcdReady = {}

aura_env.GetIcd = function(spellId)
    if spellId == aura_env.Spells.UnholyMight then
        return 45
    end
end

-- Caches the result of AuraUtil.FindAuraByName until Update is called
-- Assumes "PLAYER|HARMFUL" filter for target auras
aura_env.FindAuraByName = function(name, unit)
    local cache = nil
    local filter = nil
    if unit == "player" then
        cache = aura_env.FindAuraByNamePlayerCache
    elseif unit == "target" then
        cache = aura_env.FindAuraByNameTargetCache
        filter = "PLAYER|HARMFUL"
    elseif unit == "pet" then
        cache = aura_env.FindAuraByNamePetCache
    end

    local aura = cache[name]
    if not aura then
        aura = { AuraUtil.FindAuraByName(name, unit, filter) }
        cache[name] = aura
    end
    return aura[1], aura[2], aura[3], aura[4], aura[5], aura[6]
end
