function(auras, event, text, content, channel)
    if event == "CHAT_MSG_ADDON" and text == "D5WC" then
        local _, _, dbmPrefix, arg1 = strsplit("\t", content) 
        if dbmPrefix == "PT" then
            local pullTimerDuration = tonumber(arg1)

            local instanceName,_,_,difficultyName,_,_,_,instanceMapId = GetInstanceInfo()
            local instanceId = nil

            if instanceMapId == 649 then
                for i=1, GetNumSavedInstances() do
                    local savedInstanceName,_,_,_,_,_,_,_,_,savedDifficultyName = GetSavedInstanceInfo(i)
                    
                    if savedInstanceName == instanceName and savedDifficultyName == difficultyName then
                        instanceId = i
                        break
                    end
                end
            
                if instanceId then
                    local numEncounters = select(11,GetSavedInstanceInfo(instanceId))
            
                    for i = 1, numEncounters do
                        local bossName,_,isKilled = GetSavedInstanceEncounterInfo(instanceId, i)

                        if not isKilled and (i == 1 or i == 2) then
                            return false
                        end          
                    end
                end
            end

            aura_env.Show(auras, pullTimerDuration)
            return true
        end
    elseif event == "CHAT_MSG_MONSTER_YELL" and text then
        if string.find(text, "Welcome, champions!") then
            aura_env.ShowWithCombat(auras, 48, 37)
        elseif string.find(text, "Hailing from the deepest, darkest caverns of the Storm Peaks, Gormok the Impaler") then
            aura_env.ShowWithCombat(auras, 22.5, 10)
        --elseif string.find(text, "Steel yourselves, heroes, for the twin terrors, Acidmaw and Dreadscale") then
            --aura_env.Show(auras, 14.5)
        --elseif string.find(text, "The air itself freezes with the introduction of our next combatant, Icehowl") then
            --aura_env.Show(auras, 10.5)
        elseif string.find(text, "Grand Warlock Wilfred Fizzlebang will summon forth your next challenge") then
            aura_env.Show(auras, 88)
        end
        return true
    end
end

