local aiplayer = include('sim/aiplayer')
local simquery = include('sim/simquery')

local function createGuard(originalFunction, self, sim,unitType)
    local unit = originalFunction(self, sim, unitType)

	local hasItems = false
	for i,child in ipairs(unit:getChildren()) do
		if not child:getTraits().anarchySpecialItem and child:hasAbility( "carryable" ) then
			hasItems = true
			break
		end
	end

	if simquery.calculateCashOnHand( sim, unit ) <= 0 and simquery.calculatePWROnHand( sim, unit ) <= 0 and not hasItems then 
		unit:getTraits().searched = true
	end

    return unit
end

local patches = {
    { package = aiplayer,   name = 'createGuard',   f = createGuard },

}

return monkeyPatch(patches)
