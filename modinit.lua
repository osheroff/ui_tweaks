-- init will be called once
local function init( modApi )
    modApi:addGenerationOption("precise_ap", "this string", "that string" )
end

-- load may be called multiple times with different options enabled
local function load( modApi, options )
    if options["precise_ap"].enabled then
	include( modApi:getScriptPath() .. "/precise_ap" )
    end
end


-- gets called before localization occurs and before content is loaded
local function initStrings( modApi )
end

return {
    init = init,
    load = load,
    initStrings = initStrings,
}
