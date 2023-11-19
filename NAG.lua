aura_env.DEBUG = true

if not _G[aura_env.id] then
    _G[aura_env.id] = C_Timer.NewTicker(0.1, function()
            WeakAuras.ScanEvents("SIM_NAG_UPDATE")
            WeakAuras.ScanEvents("SIM_NAG_THROTTLER")
    end)
end

aura_env.Update = function(auras, rotation)
    local timeNow = GetTime()
    local gcdStart, gcdDuration = GetSpellCooldown(aura_env.Spells.GCD)
    aura_env.nextTime = math.max(timeNow + 0.3, gcdStart + gcdDuration)
    aura_env.NextSpell = aura_env.Spells.Pacify
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

-- =========================================================================
-- Aura values
aura_env.AuraIsActive = function(spellId)
    if spellId == aura_env.Spells.SummonGargoyle then
        -- The sim assumes that Gary is an aura but it's not
        return aura_env.TimeToReady(aura_env.Spells.SummonGargoyle) >= 150
    end
    
    local spellName = GetSpellInfo(spellId)
    return spellName and aura_env.FindAuraByName(spellName, "player")
end
aura_env.AuraActive = aura_env.AuraIsActive

aura_env.AuraIsActivePet = function(spellId)
    local spellName = GetSpellInfo(spellId)
    return spellName and aura_env.FindAuraByName(spellName, "pet")
end
aura_env.AuraActivePet = aura_env.AuraIsActivePet

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

aura_env.AuraShouldRefresh = function(spellId, overlap)
    if aura_env.AuraRemainingTime(spellId) < overlap then
        return true
    end
    return false
end
aura_env.ShouldRefreshAura = aura_env.AuraShouldRefresh

aura_env.AuraNumStacks = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 0
    end
    local _,_,count = aura_env.FindAuraByName(spellName, "player")
    if not count then
        return 0
    end
    return count
end
aura_env.AuraStacks = aura_env.AuraNumStacks

-- =========================================================================
-- DOT values
aura_env.DotIsActive = function(spellId)
    local spellName = GetSpellInfo(spellId)
    return spellName and aura_env.FindAuraByName(spellName, "target")
end
aura_env.DotActive = aura_env.DotIsActive

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

aura_env.DotNumStacks = function(spellId)
    local spellName = GetSpellInfo(spellId)
    if not spellName then
        return 0
    end
    local _,_,count = aura_env.FindAuraByName(spellName, "target")    
    if not count then
        return 0
    end
    return count
end
aura_env.DotStacks = aura_env.DotNumStacks

aura_env.DotShouldRefresh = function(spellId, overlap)
    if aura_env.DotRemainingTime(spellId) < overlap then
        return true
    end
    return false
end
aura_env.ShouldRefreshDot = aura_env.DotShouldRefresh

-- =========================================================================
-- Spell values
aura_env.IsReady = function(spellId)
    if not spellId then return false end
    local start, duration = GetSpellCooldown(spellId)
    return start + duration <= aura_env.nextTime
end
aura_env.SpellIsReady = aura_env.IsReady

aura_env.CanCast = function(spellId)
    if not spellId then return false end
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
aura_env.SpellCanCast = aura_env.CanCast

aura_env.TimeToReady = function(spellId)
    local start, duration = GetSpellCooldown(spellId)
    
    if start == 0 then
        return 0
    end
    
    return start + duration - aura_env.nextTime
end
aura_env.SpellTimeToReady = aura_env.TimeToReady

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
aura_env.SpellCast = aura_env.Cast

aura_env.SpellCastTime = function(spellId)
    if not spellId then return 0 end
    local _,_,_,castTime = GetSpellInfo(spellId)    
    return castTime
end
aura_env.CastTime = aura_env.SpellCastTime

aura_env.SpellIsQueued = function(spellId)
    if aura_env.nextSpell == spellId then
        return true
    end    
    for i=1,#aura_env.SecondarySpells do
        if aura_env.SecondarySpells[i] == spellId then
            return true
        end
    end    
    return false
end
aura_env.IsQueued = aura_env.SpellIsQueued

--TODO: Not sure this is obtainable until spell is cast, so would only work after cast?
aura_env.SpellChannelTime = function() 
    local _,_,_,_,endTimeMS = UnitChannelInfo("player")
    local finish = endTimeMS/1000 - GetTime()
    return finish
end
--Returns if a specific spell is being channel, does it need to be just any spell being channeled?
aura_env.SpellIsChanneling = function(spellId) 
    local spell,_,_,_,_,_,_,_,Id = UnitCastingInfo("player")
    if spell == "CHANNELING" then
        if spellId == Id then
            return true
        end
    end
    return false
end
aura_env.IsChanneling = aura_env.SpellIsChanneling

-- =========================================================================
-- Resource values
aura_env.RunicPower = function()
    return UnitPower("player", 6)
end

aura_env.executePhaseThreshold = { E20 = 1, E25 = 2, E35 = 3 }
aura_env.RuneType = { Blood = 1, Unholy = 2, Frost = 3, Death = 4 }
aura_env.runeType = aura_env.RuneType

aura_env.runeSlot = { LeftBlood = 1, RightBlood = 2, LeftFrost = 3, 
    RightFrost = 4, LeftUnholy = 5, RightUnholy = 6 ,
    BloodLeft = 1, BloodRight = 2, FrostLeft = 3, 
FrostRight = 4, UnholyLeft = 5, UnholyRight = 6 }
aura_env.RuneSlot = aura_env.runeSlot

aura_env.CurrentHealth = function()
    return UnitHealth("player")
end
aura_env.Health = aura_env.CurrentHealth

aura_env.CurrentHealthPercent = function()
    local healthPerc = (UnitHealth("player")/UnitHealthMax("player"))*100
    return healthPerc
end
aura_env.HealthPercent = aura_env.CurrentHealthPercent

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
aura_env.RuneIsReady = aura_env.RuneReady

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
aura_env.RuneCooldown = aura_env.NextRuneCooldown

aura_env.CurrentRuneCount = function(runeType)
    local total = 0
    for i=1,6 do
        local rt = GetRuneType(i)
        if (rt == runeType or rt == aura_env.RuneType.Death) and aura_env.CurrentRuneActive(i) then
            total = total + 1
        end
    end
    return total
end
aura_env.RuneCount = aura_env.CurrentRuneCount

aura_env.CurrentRuneDeath = function(runeSlot)
    return (GetRuneType(runeSlot) == "Death")
end
aura_env.RuneDeath = aura_env.CurrentRuneDeath
aura_env.RuneIsDeath = aura_env.CurrentRuneDeath

aura_env.CurrentRuneActive = function(runeSlot)
    local _,_,active = GetRuneCooldown(runeSlot)
    return active
end
aura_env.RuneActive = aura_env.CurrentRuneActive
aura_env.RuneIsActive = aura_env.CurrentRuneActive

aura_env.RuneSlotCooldown = function(runeSlot)
    local runeOnCD = GetRuneCooldown(runeSlot)
    return runeOnCD
end
aura_env.RuneSlotCD = aura_env.RuneSlotCooldown

--[[ --Not sure this logic is correct, so leaving it out for now?  
aura_env.RuneGrace = function(runeType) -- TODO
    
    local grace = 2.5
    for i=1,6 do
        local rt = GetRuneType(i)
        if rt == runeType or rt == aura_env.RuneType.Death then
            local start, duration, runeReady = GetRuneCooldown(i)
            --print(aura_env.runeType[i], start, duration, runeReady)
            if not runeReady and duration-(aura_env.nextTime-start) < 2.5 then 
                grace = math.min(grace, duration - (aura_env.nextTime-start) )
                
            end
        end
    end
    
    return math.max(grace, 0)
end
aura_env.RuneGracePeriod = aura_env.RuneGrace

aura_env.RuneSlotGrace = function(runeSlot) -- TODO 

    local grace = 2.5
    local start, duration, runeReady = GetRuneCooldown(runeSlot)
    --        print(aura_env.runeType[i], start, duration, runeReady)
    if not runeReady and duration-(aura_env.nextTime-start) < 2.5 then 
        grace = math.min(grace, duration - (aura_env.nextTime-start) )       
    end
    return math.max(grace, 0)   
end
--]]

-- =========================================================================
-- Sequence values
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

-- =========================================================================
-- Encounter Values
aura_env.CurrentTime = function()
    local combatTime = aura_env.startTime and aura_env.nextTime - aura_env.startTime or 0
    return combatTime
end
--aura_env.CurrentTimePercent = function() -- TODO
aura_env.RemainingTime = function() 
    return aura_env.TTD or 8888
end
-- aura_env.RemainingTimePercent = function() --TODO
aura_env.IsExecutePhase = function(threshold)
    local healthPerc = (UnitHealth("target")/UnitHealthMax("target"))*100
    return (healthPerc <= threshold)
end
aura_env.IsExecute = aura_env.IsExecutePhase

aura_env.NumberTargets = function()
    return aura_env.mobCount or 0
end

aura_env.MobsAround = function()
    local count = 0
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitCanAttack("player", unit)
        and WeakAuras.CheckRange(unit, 8, "<=")
        then
            count = count + 1
        end
    end
    return count
end


-- =========================================================================
-- Autoattack values
aura_env.AutoTimeToNext = function() 
    local start,duration = GetSpellCooldown(aura_env.Spells.AutoAttack)
    return (start + duration - aura_env.nextTime)
end
aura_env.TimeToNextAuto = aura_env.AutoTimeToNext

-- =========================================================================
-- GCD values
aura_env.GCDIsReady = function()
    if aura_env.SpellCanCast(aura_env.Spells.GCD) then
        return true
    end
    return false
end
aura_env.GCDTimeToReady = function()
    local start,duration = GetSpellCooldown(aura_env.Spells.GCD)
    return (start + duration - aura_env.nextTime)
end

aura_env.CancelAura = function(auraId) --TODO: not needed? unless we can maybe show the aura icon with an X through it w/overlay?
    return true
end

-- ==========================================================
-- Autobuild Spells from spellbook, need to add procs/buffs/etc that aren't listed in the specs spellbook
aura_env.Spells = {}
aura_env.SpellsById = {}

aura_env.BuildSpellBook = function()
    aura_env.Spells = {}
    local i = 1
    while true do        
        local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        if not spellName then
            do break end
        end
        -- can add more to clean up the Spells table if it matters
        if ( spellName~="Axe Specialization" and  spellName~="Basic Campfire" and  spellName~="Cold Weather Flying"
            and spellName ~= "Cooking" and spellName ~= "Dual Wield" and  spellName ~= "Engineering" 
            and spellName ~= "Find Fish" and spellName ~= "First Aid" and  spellName ~= "Fishing" 
            and spellName ~= "Goblin Engineer" and spellName ~= "Jewelcrafting" and  spellName ~= "Tailoring" 
            and spellName ~= "Mining" and spellName ~= "Prospecting" and  spellName ~= "Shoot"
            and spellName ~= "Stance Mastery" and spellName ~= "Throw" and spellName ~= "Hardiness"
            and spellName ~= "Command" and spellName ~= "Rampage" and spellName ~= "Parry" and spellName ~= "Dodge"
        and spellName ~= "Block" and spellName ~= "Enchanting" and spellName ~= "Disenchant") then
            
            local _, spellId = GetSpellBookItemInfo(spellName)
            spellName = string.gsub(spellName, "%s+", "") -- remove spaces. may need to add other if other special characters need to be removed
            if not aura_env.Spells[spellName] then    
                aura_env.Spells[spellName] = spellId
            end
            
        end
        i = i + 1
    end
    
    -- Add auras/potions/items here
    --Common   
    aura_env.Spells["AutoAttack"] = 6603
    aura_env.Spells["PotionOfSpeed"] = 40211
    aura_env.Spells["Speed"] = 53908       --the aura from PotionOfSpeed to trigger off haste pot usage
    aura_env.Spells["GCD"] = 61304
    aura_env.Spells["Pacify"] = 10730
    aura_env.Spells["IndestructiblePotion"] = 40093
    aura_env.Spells["Indestructible"] = 53762  --the aura from IndestructiblePotion to trigger off indestructible pot usage
    aura_env.Spells["Berserking"] = 26297
    aura_env.Spells["Gloves"] = 54758
    aura_env.Spells["SaroniteBomb"] = 56350
    aura_env.Spells["Sapper"] = 56488
    aura_env.Spells["HyperspeedAcceleration"] = 54758
    aura_env.Spells["DancingRuneWeapon"] = 49028
    
    --DK
    aura_env.Spells["Desolation"] = 66803
    aura_env.Spells["KillingMachine"] = 51124
    aura_env.Spells["FreezingFog"] = 59052
    aura_env.Spells["UnholyForce"] = 67383
    aura_env.Spells["UnholyMight"] = 67117
    aura_env.Spells["UnholyFrenzy"] = 49016
    aura_env.Spells["Indomitable"] = 71227
    
    --Tier 10 2p/4p aura id's
    aura_env.Spells["DeathKnightT10Melee2P"] = 70655
    aura_env.Spells["DeathKnightT10Melee4P"] = 70656
    aura_env.Spells["DeathKnightT10Tank2P"] = 70650
    aura_env.Spells["DeathKnightT10Tank4P"] = 70652
    
    aura_env.SpellsByID = {}
    
    for name, id in pairs(aura_env.Spells) do
        --create reverse lookup table of aura_env.Spells
        if aura_env.SpellsById[name] then
            table.insert(aura_env.SpellsById[name], id)
        else
            aura_env.SpellsById[id] = name
        end
        if DLAPI and aura_env.DEBUG then DLAPI.DebugLog("Spells", name .. ": " .. id) end
        
    end
end

aura_env.BuildSpellBook()

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
    spellId == aura_env.Spells.UnholyFrenzy --[[or
    spellId == aura_env.Spells.SummonGargoyle --]]
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

aura_env.last = 0
aura_env.TTD = 180
-- Credit to Aethys https://github.com/herotc/hero-lib
local ttdcache = {}
local ttdunits = {}
local iterableUnits = {"focus", "target", "mouseover"}

if not WeakAuras.IsClassicEra() then
    for i=1,5 do
        iterableUnits[#iterableUnits+1] = "boss"..i
    end
end
for i=1,40 do
    iterableUnits[#iterableUnits+1] = "nameplate"..i
end
function aura_env.TTDRefresh_f()
    local currentTime = GetTime()
    local checkedUnits = {}
    local historyCount = 100
    local historyTime = 10
    
    for _, unit in ipairs(iterableUnits) do
        if UnitExists(unit) then
            local GUID = UnitGUID(unit)
            if not checkedUnits[GUID] then
                checkedUnits[GUID] = true
                local health = UnitHealth(unit)
                local maxHealth = UnitHealthMax(unit)
                local healthPercentage = health ~= -1 and maxHealth ~= -1 and health / maxHealth * 100
                -- Check if it's a valid unit
                if UnitCanAttack("player", unit) and healthPercentage < 100 then
                    local unitTable = ttdunits[GUID]
                    -- Check if we have seen one time this unit, if we don't then initialize it.
                    if not unitTable or healthPercentage > unitTable[1][1][2] then
                        unitTable = { {}, currentTime }
                        ttdunits[GUID] = unitTable
                    end
                    local values = unitTable[1]
                    local time = currentTime - unitTable[2]
                    -- Check if the % HP changed since the last check (or if there were none)
                    if #values == 0 or healthPercentage ~= values[1][2] then
                        local value
                        local lastIndex = #ttdcache
                        -- Check if we can re-use a table from the cache -- Buds: i have doubt on the value of reusing table, with the high cost of tinsert on 1st index
                        if lastIndex == 0 then
                            value = { time, healthPercentage }
                        else
                            value = ttdcache[lastIndex]
                            ttdcache[lastIndex] = nil
                            value[1] = time
                            value[2] = healthPercentage
                        end
                        table.insert(values, 1, value)
                        local n = #values
                        -- Delete values that are no longer valid
                        while (n > historyCount) or (time - values[n][1] > historyTime) do
                            ttdcache[#ttdcache + 1] = values[n]
                            values[n] = nil
                            n = n - 1
                        end
                    end
                end
            end
        end
    end
end
function aura_env.TimeToX_f(guid, percentage, minSamples)
    --if self:IsDummy() then return 6666 end
    --if self:IsAPlayer() and Player:CanAttack(self) then return 25 end
    local seconds = 8888
    local unitTable = ttdunits[guid]
    -- Simple linear regression
    -- ( E(x^2)  E(x) )  ( a )  ( E(xy) )
    -- ( E(x)     n  )  ( b ) = ( E(y)  )
    -- Format of the above: ( 2x2 Matrix ) * ( 2x1 Vector ) = ( 2x1 Vector )
    -- Solve to find a and b, satisfying y = a + bx
    -- Matrix arithmetic has been expanded and solved to make the following operation as fast as possible
    if unitTable then
        local values = unitTable[1]
        local n = #values
        if n > minSamples then
            local a, b = 0, 0
            local Ex2, Ex, Exy, Ey = 0, 0, 0, 0
            
            local value, x, y
            for i = 1, n do
                value = values[i]
                x, y = value[1], value[2]
                
                Ex2 = Ex2 + x * x
                Ex = Ex + x
                Exy = Exy + x * y
                Ey = Ey + y
            end
            -- invariant to find matrix inverse
            local invariant = 1 / (Ex2 * n - Ex * Ex)
            -- Solve for a and b
            a = (-Ex * Exy * invariant) + (Ex2 * Ey * invariant)
            b = (n * Exy * invariant) - (Ex * Ey * invariant)
            if b ~= 0 then
                -- Use best fit line to calculate estimated time to reach target health
                seconds = (percentage - a) / b
                -- Subtract current time to obtain "time remaining"
                seconds = math.min(7777, seconds - (GetTime() - unitTable[2]))
                if seconds < 0 then seconds = 9999 end
            end
        end
    end
    return seconds
end

