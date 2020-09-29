dofile_once("mods/ALIEN/scripts/alien_utils.lua")

_collision_trigger = collision_trigger or _collision_trigger

local timesVisitedTemple = 0

function collision_trigger()
    _collision_trigger()

    timesVisitedTemple = timesVisitedTemple + 1
    GamePrint("Times visited temple: " .. timesVisitedTemple)
    if (GetPlayerLevel() < (timesVisitedTemple + 1)) then
        PerformCostlyLevelUp()
    end
end

