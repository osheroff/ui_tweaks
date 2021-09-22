
local items_panel = include( "hud/items_panel" )
local modalDialog = include( "states/state-modal-dialog" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

-- ======================
-- client/hud/items_panel
-- ======================

local function lootPanelInit( originalFunction, self, ... )
	originalFunction( self, ... )
	self._uit_firstRefresh = true
end

local function lootPanelRefresh( originalFunction, self, ... )
	if self._uit_firstRefresh then
		self._uit_firstRefresh = nil

		-- Upon first displaying the loot panel, check for any loot.
		local screen = self._screen
		local lootWidget = screen:findWidget( "inventory" )
		local hasItem = false
		for i, widget in lootWidget.binder:forEach( "item" ) do
			if self:refreshItem( widget, i, "item" ) then
				hasItem = true
			end
		end

		if not hasItem then
			-- Instead notify the user that there was no loot.
			MOAIFmodDesigner.playSound( simdefs.SOUND_HUD_INCIDENT_NEGATIVE.path )
			local game = self._hud._game
			self:destroy()
			modalDialog.show(
			  util.sformat( STRINGS.MOD_UI_TWEAKS.UI.DIALOGS.NO_LOOT_BODY, self._unit:getName() ),
			  STRINGS.MOD_UI_TWEAKS.UI.DIALOGS.NO_LOOT_TITLE
		    )
			return
		end
	end

	originalFunction( self, ... )
end

-- ============
-- sim/simquery
-- ============

-- Searching the target will either produce lootable goods or new information on its absence.
local function searchIsValuable( sim, unit, targetUnit )
	if simquery.isAgent( targetUnit ) or targetUnit:getTraits().iscorpse then
		-- Player expects the target to potentially have an inventory.
		-- Has target never been searched?
		if not targetUnit:getTraits().searched then
			return true
		end
		-- Has target never been expertly searched?
		if unit:getTraits().anarchyItemBonus and not targetUnit:getTraits().searchedAnarchy5 then
			return true
		end
	end

	-- Does target have something we can steal?
	-- (UIT: vanilla check from canLoot starts here)
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
	return (simquery.calculateCashOnHand( sim, targetUnit ) > 0
			or simquery.calculatePWROnHand( sim, targetUnit ) > 0
			or inventoryCount > 0)
end

-- Modified copy of vanilla simquery.canLoot
-- Changes at 'UIT:'
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

	-- UIT: Extracted method. Considers additional factors valuable to search.
	if not searchIsValuable( sim, unit, targetUnit ) then
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
	{ package = items_panel.loot, name = 'init', f = lootPanelInit },
	{ package = items_panel.loot, name = 'refresh', f = lootPanelRefresh },
	{ package = simquery, name = 'canLoot', f = canLoot },
}

return monkeyPatch(patches)
