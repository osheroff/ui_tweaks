local simquery = include ( "sim/simquery" )
local simquery = include ( "sim/simquery" )
local simactions = include ( "sim/simactions" )
local moveBody = include ( "sim/abilities/moveBody" )

local canModifyExit = function( oldFunction, ... )
    local canModify, reason = oldFunction(unpack(arg))

    if canModify == false and reason == STRINGS.UI.DOORS.DROP_BODY then
        return true
    else
        return canModify, reason
    end
end

local doUseDoorAction = function ( oldFunction, sim, exitOp, unitID, x0, y0, facing )
    local unit = sim:getUnit( unitID )
    local body = unit:getTraits().movingBody

    if body then
        -- drop body
        moveBody:executeAbility( sim, unit, unit, body:getID() )
    end

    -- open door
    local retVal = oldFunction(sim, exitOp, unitID, x0, y0, facing)

    if body then
        -- pick up again
        moveBody:executeAbility( sim, unit, unit, body:getID() )
    end

    return retVal
end

local patches = {
    { package = simquery,   name = 'canModifyExit',  f = canModifyExit },
    { package = simactions, name = 'useDoorAction', f = doUseDoorAction }
}

return monkeyPatch(patches)
