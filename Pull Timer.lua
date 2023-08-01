function(auras, event, prefix, content, channel)
    if prefix == "D5WC" then
        local _, _, dbmPrefix, arg1 = strsplit("\t", content) 
        if dbmPrefix == "PT" then
            local pullTimerDuration = tonumber(arg1)
            
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
            return true
        end
    end
end

