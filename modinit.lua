-- init will be called once
local function init( modApi )
    modApi:addGenerationOption("precise_ap", STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP, STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP_TIP)
    modApi:addGenerationOption("need_a_dollar", STRINGS.MOD_UI_TWEAKS.OPTIONS.NEED_A_DOLLAR, STRINGS.MOD_UI_TWEAKS.OPTIONS.NEED_A_DOLLAR_TIP)
    include( modApi:getScriptPath() .. "/precise_ap" )
    include( modApi:getScriptPath() .. "/need_a_dollar" )
    include( modApi:getScriptPath() .. "/item_dragdrop" )
end

-- load may be called multiple times with different options enabled
local function load( modApi, options )
    local precise_ap = include( modApi:getScriptPath() .. "/precise_ap" )
    local i_need_a_dollar = include( modApi:getScriptPath() .. "/need_a_dollar" )
    precise_ap.enabled = options["precise_ap"].enabled
    i_need_a_dollar.enabled = options["need_a_dollar"].enabled
end


-- gets called before localization occurs and before content is loaded
local function initStrings( modApi )
    local scriptPath = modApi:getScriptPath()

    local strings = include( scriptPath .. "/strings" )
    modApi:addStrings( modApi:getDataPath(), "MOD_UI_TWEAKS", strings )
end

return {
    init = init,
    load = load,
    initStrings = initStrings,
}
