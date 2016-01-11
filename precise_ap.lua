local flagui = include('hud/flag_ui')
local panel = include('hud/home_panel').panel

local function roundToPointFive( ap )
	ap = math.max(0, ap)
	return 0.5 * math.floor(ap / 0.5)
end

local function shiftWidgetRight( w, px )
	local x, y = w:getPosition()
	w:setPosition( x + px, nil )
end

local function adjustAgentAPWidgets(panel)
	for i=1, 10 do
		local widget = panel.binder:tryBind( "agent" .. i )
		if widget and not widget.preciseAPAdjusted then
			shiftWidgetRight(widget.binder.apNum, 5)
			shiftWidgetRight(widget.binder.apTxt, 5)
			widget.preciseAPAdjusted = true
		end
	end
end

local function refreshAgent( originalFunction, self, unit )
	originalFunction( self, unit )

	adjustAgentAPWidgets(self._panel)

	local widget = self:findAgentWidget( unit:getID() )

	if widget == nil then
		return
	end

	local ap = unit:getMP()
	if self._hud._movePreview and self._hud._movePreview.unitID == unit:getID() and ap > self._hud._movePreview.pathCost then
		ap = ap - self._hud._movePreview.pathCost
	end

	widget.binder.apNum:setText( roundToPointFive(ap) )
end

local function refreshFlag( originalFunction, self, unit, isSelected )
	unit = unit or self._rig:getUnit()
	local ret = originalFunction( self, unit, isSelected )

	local sim = self._rig._boardRig:getSim()

	if not(unit:getPlayerOwner():isNPC() or unit:isKO() or unit:getTraits().takenDrone) then
		if sim:getCurrentPlayer() == unit:getPlayerOwner() then
			local ap = roundToPointFive ( unit:getMP() - (self._moveCost or 0) )
			self._widget.binder.meters.binder.APnum:setText( ap )
		end
	end
end

local patches = {
		{ package = panel,   name = 'refreshAgent', f = refreshAgent },
		{ package = flagui,  name = 'refreshFlag',  f = refreshFlag }
}

return monkeyPatch(patches)

