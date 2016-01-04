
-- not the most elegant way to pull this off, but
-- better than monkey-patching the giant "can loot" function.
--
local aiplayer = include('sim/aiplayer')
local simquery = include('sim/simquery')
local i_need_a_dollar = {}

aiplayer.oldCreateGuard = aiplayer.createGuard
function aiplayer:createGuard(sim,unitType)
    local unit = self:oldCreateGuard(sim, unitType)
    if not i_need_a_dollar.enabled then return unit end

    if not unit:getTraits().isDrone and unit:getTraits().cashOnHand == 0 then
	log:write("setting up cash on hand")
	unit:getTraits().cashOnHand = 1
    end
    return unit
end

local oldCalculateCashOnHand = simquery.calculateCashOnHand
function simquery.calculateCashOnHand( sim, unit )
    local value = unit:getTraits().cashOnHand
    if value == 1 then
	return value
    else
	return oldCalculateCashOnHand(sim, unit)
    end
end

return i_need_a_dollar
