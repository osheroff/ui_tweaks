local upgradeScreen = include ( 'states/state-upgrade-screen' )
local mui_defs = include("mui/mui_defs")
local mui_button = include( "mui/widgets/mui_button" )
local util = include( "modules/util" )
local guiex = include( "client/guiex" )
local cdefs = include( "client_defs" )
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )

local function updateButton(screen, widget, item, encumbered)
    if item then
        guiex.updateButtonFromItem( screen, nil, widget, item, nil, encumbered )
    else
        guiex.updateButtonEmptySlot( widget, encumbered )
    end
end

local function getInventory( unitDef )
    local unit = simfactory.createUnit( unitdefs.createUnitData( unitDef ), nil )
    local inventory = {}

    for i,item in ipairs(unitDef.upgrades) do
        local itemDef, upgradeParams
        if type(unitDef.upgrades[i]) == "string" then
            itemDef = unitdefs.lookupTemplate( unitDef.upgrades[i] )
        else
            upgradeParams = unitDef.upgrades[i].upgradeParams
            itemDef = unitdefs.lookupTemplate( unitDef.upgrades[i].upgradeName )
        end

        if itemDef then
            local itemUnit = simfactory.createUnit( util.extend( itemDef )( upgradeParams and util.tcopy( upgradeParams )), nil )
            if itemUnit:getTraits().augment and itemUnit:getTraits().installed then
            else
                table.insert(inventory,{item=itemUnit,upgrade=unitDef.upgrades[i],index = i })
            end
        end
    end
    return inventory
end

local function onDragDrop( self, item, upgrade, unit, unitDef, itemIndex, fromStorage )
    repl:log("got drag-drop into ", self.screen._lastDragIndex, " itemIndex is ", itemIndex)

    local inventory = getInventory( unitDef )
    local upgradeIndex = inventory[self.screen._lastDragIndex].index

    if fromStorage then
        table.insert( unitDef.upgrades, upgradeIndex, upgrade )
        table.remove( self._agency.upgrades, itemIndex )
    else
        table.remove( unitDef.upgrades, itemIndex )
        table.insert( unitDef.upgrades, upgradeIndex, upgrade )
    end

    self:refreshInventory(unitDef, self._selectedIndex)

    repl:log("returning")
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


local function onDragCommon( self, upgrade, item )

    local widget = self.screen:startDragDrop( item, "DragItem" )
    widget.binder.img:setImage( item:getUnitData().profile_icon )

    self.screen._lastDragIndex = nil
    self._saved_inventory = saveInventory( self.screen )

    self.screen:findWidget( "dragAugment" ).onDragDrop = function() util.coDelegate( self.onDragToAugments, self, upgrade, item ) end

end

function upgradeScreen:onDragInventory( upgrade, item, oldOnDragDrop )
    onDragCommon( self, upgrade, item )

    local unit, unitDef, itemIndex = oldOnDragDrop[2], oldOnDragDrop[3], oldOnDragDrop[6]

    self.screen:findWidget( "drag" ).onDragDrop = function(item) return onDragDrop(self, item, upgrade, unit, unitDef, itemIndex, false) end
    self.screen:findWidget( "storageDrag" ).onDragDrop = function() util.coDelegate( oldOnDragDrop ) end
    self.screen:findWidget( "storageDragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    return true
end

function upgradeScreen:onDragStorage( upgrade, item, oldOnDragDrop )
    onDragCommon( self, upgrade, item )

    local unit, unitDef, itemIndex = oldOnDragDrop[2], oldOnDragDrop[3], oldOnDragDrop[6]

    self.screen:findWidget( "drag" ).onDragDrop = function(item) return onDragDrop(self, item, upgrade, unit, unitDef, itemIndex, true) end
    self.screen:findWidget( "dragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
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
