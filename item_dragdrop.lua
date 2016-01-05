local upgradeScreen = include ( 'states/state-upgrade-screen' )
local mui_defs = include("mui/mui_defs")
local mui_dragzone = include( "mui/widgets/mui_dragzone" )
local mui_image = include( "mui/widgets/mui_image" )
local mui_button = include( "mui/widgets/mui_button" )
local util = include( "modules/util" )
local guiex = include( "client/guiex" )
local cdefs = include( "client_defs" )

local function updateButton(screen, widget, item, encumbered)
    if item then
        guiex.updateButtonFromItem( screen, nil, widget, item, nil, encumbered )
    else
        guiex.updateButtonEmptySlot( widget, encumbered )
    end
end

local function onDragDrop( self, item, upgrade )
  repl:log("onDragDrop index == ", self.screen._lastDragIndex, " upgrade == ", upgrade)
  return true
end

local function onDragOver( screen, idx )
    if screen._lastDragIndex == idx then return true end

    screen._lastDragIndex = idx

    local dragItem = screen:getDragDrop()
    repl:log("onDragEnter to " .. idx .. " with " .. tostring(dragItem))

    local inventory = {}

    for i, widget in screen.binder:forEach( "inv_" ) do
        -- repl:log("widget " .. i .. " is ", widget._item)
        if widget._item and widget._item ~= dragItem and widget:getAlias() then -- getAlias ensures item still exists
            table.insert(inventory, widget._item)
        end
    end

    idx = math.min(#inventory + 1, idx) -- clamp to last empty slot
    table.insert(inventory, idx, dragItem)

    for i=1,8 do
        local item = inventory[i]
        local widget = screen:findWidget( "inv_" .. i)

        local encumbered = widget.binder.encumbered._cont._isVisible
        updateButton(screen, widget, item, encumbered)
        if item and i == idx then
            widget.binder.btn:setColor(0.9, 0.75, 0.37, 1)
        end
    end

    return true
end

local function handleMouseOverDuringDrag( self, ev )
  if ev.screen:getDragDrop() and ev.eventType == mui_defs.EVENT_MouseMove
      and ev.screen:getInputLock() == self and self._prop:inside( ev.x, ev.y ) then
    local xmin, ymin, zmin, xmax, ymax, zmax = self._prop:getWorldBounds()

    local idx = math.floor((ev.x - xmin) / ((xmax - xmin) / 4)) + 1

    if ev.y < ymin + ((ymax - ymin) / 2) then
      idx = idx + 4
    end

    return onDragOver(ev.screen, idx)
  else
    return mui_button.handleInputEvent( self, ev )
  end
end

function upgradeScreen:onDragEnter( dragWidget )
  dragWidget._button.handleInputEvent = handleMouseOverDuringDrag
  return true
end

local function saveInventory( screen )
  local inv = {}

  for i, widget in screen.binder:forEach( "inv_" ) do
    local item = { encumbered = widget.binder.encumbered._cont._isVisible }
    if widget:getAlias() then
      item.item = widget._item
    end

    table.insert(inv, item)
  end

  return inv
end

local function restoreInventory( screen, inv )
  for i, tbl in ipairs(inv) do
    local widget = screen:findWidget( "inv_" .. i)
    -- widget.binder.btn:setColor(0.95, 1, 0.47, 1)
    updateButton( screen, widget, tbl.item, tbl.encumbered )
  end
end

function upgradeScreen:onDragInventory( upgrade, item, _ )
  self.screen._lastDragIndex = nil
  local widget = self.screen:startDragDrop( item, "DragItem" )
  widget.binder.img:setImage( item:getUnitData().profile_icon )

  self._saved_inventory = saveInventory( self.screen )
  self.screen:findWidget( "drag" ).onDragDrop = function(item) onDragDrop(self, item, upgrade) end
  self.screen:findWidget( "storageDragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
  self.screen:findWidget( "dragAugment" ).onDragDrop = function() util.coDelegate( self.onDragToAugments, self, upgrade, item ) end

  return true
end

function upgradeScreen:onDragLeave( dragWidget )
  repl:log( "onDragLeave, restoring inventory" )
  restoreInventory( self.screen, self._saved_inventory )
  dragWidget._button.handleInputEvent = mui_button.handleInputEvent
  return true
end


if not upgradeScreen.oldRefreshInventory then
    upgradeScreen.oldRefreshInventory = upgradeScreen.refreshInventory
end

function upgradeScreen:refreshInventory( unitDef, index )
    self:oldRefreshInventory( unitDef, index )

    self._saved_inventory = {}
    local dragWidget = self.screen:findWidget( "drag" )
    dragWidget.onDragEnter = util.makeDelegate( self, 'onDragEnter', dragWidget )
    dragWidget.onDragLeave = util.makeDelegate( self, 'onDragLeave', dragWidget )
end

function reload()
  package.loaded[ 'workshop-581951281/item_dragdrop' ] = nil
  return mod_manager:mountContentMod('workshop-581951281')
end

log:write("loaded")
