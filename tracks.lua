local color = include( "modules/color" )
local pathrig = include( "gameplay/pathrig" )
local util = include( "modules/util" )

local PATH_COLORS = {
    color(.5, 1, 0, 1.0),
    color(0, 0.5, 1, 1.0),
    color(1, 1, 0.5, 1.0),
    color(0.8, 0.2, 0, 1.0),
    color(1, 0.5, 0.5, 1.0),
    color(0.5, 1, 0.5, 1.0)
}

local path_color_idx = 0

local function assignColor( pathColors, unitID )
    if not pathColors[ unitID ] then
        pathColors[ unitID ] = PATH_COLORS[ (path_color_idx % #PATH_COLORS) + 1 ]
        path_color_idx = path_color_idx + 1
    end
    return pathColors[ unitID ]
end

local function calculatePathColors( self, unitID, pathPoints )
    local collisions = self._pathCollisions
    local colors = {}
    local unitColor = assignColor ( self._pathColors, unitID )

    for i = 2, #pathPoints do
        local prevPathPoint, pathPoint = pathPoints[i-1], pathPoints[i]
        local prevPointKey  = "" .. prevPathPoint.x .. "." .. prevPathPoint.y
        local pointKey = "" .. pathPoint.x .. "." .. pathPoint.y

        local collided = false

        if not collisions[pointKey] then
            collisions[pointKey] = {}
        end

        collisions[pointKey][unitID] = prevPointKey

        for otherUnitID in pairs( collisions[pointKey] ) do
            if unitID ~= otherUnitID then
                local otherPrevPointKey = collisions[pointKey][otherUnitID]
                repl:log("checking ", pointKey, unitID, prevPointKey, otherUnitID, otherPrevPointKey)
                if otherPrevPointKey == prevPointKey then
                    collided = true
                end
            end
        end

        if collided then
            table.insert(colors, color(1, 1, 1, 1))
        else
            table.insert(colors, unitColor)
        end
            --[[
            collisions[pointKey][unitID] = 1
            local nColors = 0
            local avg = color(0, 0, 0, 0.9)

            for u in pairs( collisions[pointKey] ) do
                local c = self._pathColors[ u ]
                avg.r = avg.r + c.r
                avg.g = avg.g + c.g
                avg.b = avg.b + c.b
                nColors = nColors + 1
            end

            avg.r = avg.r / nColors
            avg.g = avg.g / nColors
            avg.b = avg.b / nColors
            table.insert( colors, avg )
            --]]

    end

    return colors
end

local function refreshPlannedPath( originalFunction, self, unitID )
    originalFunction( self, unitID )

    if self._plannedPaths[ unitID ] then
        local pathCellColors = calculatePathColors( self, unitID, self._plannedPaths[ unitID ] )

        for i, prop in ipairs(self._plannedPathProps[ unitID ]) do
            prop:setColor( pathCellColors[ i ]:unpack() )
        end
    end
end

local function refreshAllTracks( originalFunction, self )
    self._pathCollisions = {}

    if not self._pathColors then
        self._pathColors = {}
    end

    return originalFunction( self )
end

local patches = {
    { package = pathrig.rig, name = 'refreshPlannedPath', f = refreshPlannedPath },
    { package = pathrig.rig, name = 'refreshAllTracks',   f = refreshAllTracks }
}
return monkeyPatch(patches)
