
local simdefs = include( "sim/simdefs" )
local astar_handlers = include( "sim/astar_handlers" )

local function handleNode( originalFunction, self, to_cell, from_node, goal_cell, ... )
	local n = originalFunction( self, to_cell, from_node, goal_cell, ... )

	if n and self._unit:isPC() then
		local simquery = self._sim:getQuery()
		local watchState = simquery.isCellWatched( self._sim, self._unit:getPlayerOwner(), to_cell.x, to_cell.y )

		-- Penalize paths for moving through watched and noticed tiles.
		-- Penalty is less than difference between paths with different real mp costs for reasonable path lengths.
		if watchState == simdefs.CELL_WATCHED then
			n.mCost = n.mCost + 0.001
			n.score = n.score + 0.001
		elseif watchState == simdefs.CELL_NOTICED then
			n.mCost = n.mCost + 0.00001
			n.score = n.score + 0.00001
		end
	end

	return n
end


local patches = {
    { package = astar_handlers.handler, name = '_handleNode',   f = handleNode },
}

return monkeyPatch(patches)
