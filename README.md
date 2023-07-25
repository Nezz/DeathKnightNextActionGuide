# Death Knight Next Action Guide

This repository contains the source code for the experimental [Death Knight Next Action Guide](https://wago.io/Pl9Fk7Ktw).

# How to create your own rotation

You can create your own rotation with minimal LUA knowledge.
After importing the [NAG](https://wago.io/Pl9Fk7Ktw) you can find the individual rotations under "Next action group":
![WA Trigger](https://github.com/Nezz/DeathKnightNextActionGuide/assets/431167/582e832c-f544-4141-b6d2-67172d054dad)

Inside it you can expand "Trigger 1", where you find the [code for the rotation](https://github.com/Nezz/DeathKnightNextActionGuide/blob/2a22a8e55ee3d23e8fa4c22c650c07ddb73943d7/NAG%20Frost%20sub-blood.lua#L4-L30), which is usually around 20-30 lines. This is a direct translation of the wowsims APL rotation that you can modify. Here are some examples:
![Example](https://github.com/Nezz/DeathKnightNextActionGuide/assets/431167/3b928a78-5947-4c2d-81fb-b0e747a9411d)

The rotation is a single logical condition that keeps executing until it finds a spell that can be cast.
If a major cooldown is found then it is suggested on the left side of the WeakAura, but the logical condition keeps running until a regular spell is found that can be cast.
The example above in code looks like this:
```lua
return (not aura_env.DotIsActive(spells.FrostFever) and aura_env.Cast(spells.IcyTouch))
    or (not aura_env.DotIsActive(spells.BloodPlague) and aura_env.Cast(spells.PlagueStrike))
    or (aura_env.DotRemainingTime(spells.FrostFever) < 1.5 and aura_env.DotIsActive(spells.FrostFever) and aura_env.Cast(spells.Pestilence))
```
