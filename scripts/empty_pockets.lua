
local array = include( "modules/array" )
local simquery = include( "sim/simquery" )

-- Copy of vanilla simquery.canLoot
local function canLoot( originalFunction, sim, unit, targetUnit )
	if unit:getTraits().isDrone then
		return false
	end

	if targetUnit == nil or targetUnit:isGhost() then
		return false
	end

	if not unit:canAct() then
		return false
	end

	if unit:getTraits().movingBody == targetUnit then
		return false
	end

	if not targetUnit:getTraits().iscorpse then
		if simquery.isEnemyTarget( unit:getPlayerOwner(), targetUnit ) then
			if not targetUnit:isKO() and not unit:hasSkill("anarchy", 2) then
				return false
			end

			if not targetUnit:isKO() and sim:canUnitSeeUnit(targetUnit, unit) then
				return false
			end
		else
			if not targetUnit:isKO() then
				return false
			end
		end
	end

	local inventoryCount = targetUnit:getInventoryCount()
	if not unit:getTraits().anarchyItemBonus then
		for i,child in ipairs(targetUnit:getChildren()) do
			if child:getTraits().anarchySpecialItem and child:hasAbility( "carryable" ) then
				inventoryCount = inventoryCount -1
			end
		end
	end


	if not unit:getTraits().largeSafeMapIntel then
		for i,child in ipairs(targetUnit:getChildren()) do
			if child:getTraits().largeSafeMapIntel and child:hasAbility( "carryable" ) then
				inventoryCount = inventoryCount -1
			end
		end
	end
	if simquery.calculateCashOnHand( sim, targetUnit ) <= 0 and simquery.calculatePWROnHand( sim, targetUnit ) <=0 and inventoryCount == 0 then
		return false
	end

	local cell = sim:getCell( unit:getLocation() )
	local found = (cell == sim:getCell( targetUnit:getLocation() ))
	for simdir, exit in pairs( cell.exits ) do
		if simquery.isOpenExit( exit ) then
			found = found or array.find( exit.cell.units, targetUnit ) ~= nil
		end
	end
	if not found then
		return false, STRINGS.UI.REASON.CANT_REACH
	end

	return true
end

local patches = {
	{ package = simquery, name = 'canLoot', f = canLoot },
}

return monkeyPatch(patches)
