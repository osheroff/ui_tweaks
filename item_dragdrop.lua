local upgradeScreen = include ( 'states/state-upgrade-screen' )
local mui_defs = include("mui/mui_defs")
local mui_dragzone = include( "mui/widgets/mui_dragzone" )
local mui_image = include( "mui/widgets/mui_image" )
local util = include( "modules/util" )
local guiex = include( "client/guiex" )
local cdefs = include( "client_defs" )

function upgradeScreen:onDragInventory( upgrade, item, onDragDrop )
  local widget = self.screen:startDragDrop( item, "DragItem" )
  widget.binder.img:setImage( item:getUnitData().profile_icon )
  self.screen:findWidget( "storageDragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
  self.screen:findWidget( "dragAugment" ).onDragDrop = function() util.coDelegate( self.onDragToAugments, self, upgrade, item ) end

  self._preserved_inventory = {}
  for i, widget in self.screen.binder:forEach( "inv_" ) do
      table.insert(self._preserved_inventory, widget._item)
  end

  return true
end

local function updateButton(screen, widget, item)
    if item then
        guiex.updateButtonFromItem( screen, nil, widget, item, nil, false )
    else
        guiex.updateButtonEmptySlot( widget )
    end
end

function upgradeScreen:onDragEnter( screen, idx )
    local dragItem = screen:getDragDrop()
    repl:log("onDragEnter to " .. idx .. " with " .. tostring(dragItem))

    local inventory = {}

    for i, widget in screen.binder:forEach( "inv_" ) do
        repl:log("widget " .. i .. " is " .. tostring(widget._item))
        if widget._item and widget._item ~= dragItem then
            table.insert(inventory, widget._item)
        end
    end

    idx = math.min(#inventory + 1, idx) -- clamp to last empty slot
    table.insert(inventory, idx, dragItem)

    for i=1,8 do
        local item = inventory[i]
        local widget = screen:findWidget( "inv_" .. i)

        updateButton(screen, widget, item)
        if item and i == idx then
            widget.binder.btn:setColor(0.9, 0.75, 0.37, 1)
        end
    end

    return true
end


function upgradeScreen:onDragLeave( unitDef, agentIndex, dragIdx)
    repl:log("onDragLeave from " .. dragIdx)
    for i, item in ipairs(self._preserved_inventory) do
        local widget = self.screen:findWidget( "inv_" .. i)
        repl:log("resetting " .. i .. " to " .. tostring(item))
        updateButton(self.screen, widget, item)
        widget.binder.btn:setColor(0.95, 1, 0.47, 1)
    end
    return true
end

if not upgradeScreen.oldRefreshInventory then
    upgradeScreen.oldRefreshInventory = upgradeScreen.refreshInventory
end

function upgradeScreen:refreshInventory( unitDef, index )
    self:oldRefreshInventory( unitDef, index )

    self._preserved_inventory = {}

    gUnitDef = unitDef
    local oldDragWidget = self.screen:findWidget( "drag" )

 --   if oldDragWidget then
--        self.screen:removeWidget(oldDragWidget)
--    end

    for i, widget in self.screen.binder:forEach( "inv_" ) do
        local agentPnl = self.screen:findWidget( "agentPnl" )

        local x = widget._cont._x
        local y = widget._cont._y
        local w = 58.5 / 1280
        local h = 63

        -- if i == 1 then
          -- x = x + 4
          -- w = w - 4
        -- elseif i == 4 then
          -- x = x - 4
          -- w = w - 4
        -- end

        if not self.screen:findWidget( "drag_" .. i ) then
            local dragzone_widget = mui_dragzone(self.screen, {
                name = "drag_" .. i,
                isVisible = true,
                noInput = true,
                x = x,
                y = y,
                w = w,
                h = h,
                xpx = true,
                ypx = true,
                wpx = false,
                hpx = true,
                sx = 1,
                sy = 1,
            })
            dragzone_widget.onDragEnter = util.makeDelegate( self, 'onDragEnter', self.screen, i)
            dragzone_widget.onDragLeave = util.makeDelegate( self, 'onDragLeave', unitDef, index, i)

            agentPnl:addChild(dragzone_widget)
            local img = mui_image(self.screen, {
                name = "bg_" .. i,
                noInput = true,
                x = x,
                y = y,
                w = w,
                h = h,
                xpx = true,
                ypx = true,
                wpx = false,
                hpx = true,
                sx = 1,
                sy = 1,
                color =
                {
                    math.random(), math.random(), math.random(), 0.5,
                },
                images =
                {
                    {
                        file = [[white.png]],
                        name = [[]],
                        color =
                        {
                            1,
                            1,
                            1,
                            0.5,
                        },
                    },
                }
            })
            agentPnl:addChild(img)
        end
    end
end

function reload()
  package.loaded[ 'workshop-581951281/item_dragdrop' ] = nil
  return mod_manager:mountContentMod('workshop-581951281')
end

log:write("loaded")
