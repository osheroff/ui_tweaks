local precise_ap = { enabled = false }

local flagui = include('hud/flag_ui')
local panel = include('hud/home_panel').panel
local game = include( "modules/game" )


local function roundToPointFive( ap )
	ap = math.max(0, ap)
	return 0.5 * math.floor(ap / 0.5)
end

local function shiftWidgetRight( w, px )
	local x, y = w:getPosition()
	w:setPosition( x + px, nil )
end

function panel:adjustAgentAPWidgets()
	for i=1, 10 do
		local widget = self._panel.binder:tryBind( "agent" .. i )
		if widget and not widget.preciseAPAdjusted then
			shiftWidgetRight(widget.binder.apNum, 5)
			shiftWidgetRight(widget.binder.apTxt, 5)
			widget.preciseAPAdjusted = true
		end
	end
end

panel.oldRefreshAgent = panel.refreshAgent
function panel:refreshAgent( unit )
	self:oldRefreshAgent( unit )

	if not precise_ap.enabled then return end

	self:adjustAgentAPWidgets()

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

flagui.oldRefreshFlag = flagui.refreshFlag
function flagui:refreshFlag( unit, isSelected )
	unit = unit or self._rig:getUnit()
	local ret = self:oldRefreshFlag( unit, isSelected )
	if not precise_ap.enabled then return end

	local sim = self._rig._boardRig:getSim()

	if not(unit:getPlayerOwner():isNPC() or unit:isKO() or unit:getTraits().takenDrone) then
		if sim:getCurrentPlayer() == unit:getPlayerOwner() then
			local ap = roundToPointFive ( unit:getMP() - (self._moveCost or 0) )
			self._widget.binder.meters.binder.APnum:setText( ap )
		end
	end
end

return precise_ap

