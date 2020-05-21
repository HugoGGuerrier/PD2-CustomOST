------ This class contains all the mod configuration ------


COSTConfig = COSTConfig or {}

COSTConfig.config_file = SavePath .. "custom_ost.txt"

COSTConfig.fade_duration_trad = {
    0,
    0.5,
    1,
    1.5,
    2,
    2.5,
    3
}

COSTConfig.load_timeout_trad = {
    -1,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10
}

COSTConfig.dev = false
COSTConfig.do_hook = true
COSTConfig.load_timeout = 4
COSTConfig.dynamic_load = false
COSTConfig.default_fade_duration = 1
COSTConfig.dynamic_volume = true


-- Function to load the mod config from a config file
function COSTConfig:load_config ()
    if file.FileExists(COSTConfig.config_file) then
        local f = io.open(COSTConfig.config_file, "r")
        local config_json_string = f:read("*all")
        f:close()
        local valid, config_json_table = pcall(function () return json.decode(config_json_string) end)
        if valid then
            COSTConfig.dev = config_json_table.dev
            COSTConfig.do_hook = config_json_table.do_hook
            COSTConfig.load_timeout = config_json_table.load_timeout
            COSTConfig.dynamic_load = config_json_table.dynamic_load
            COSTConfig.default_fade_duration = config_json_table.default_fade_duration
            COSTConfig.dynamic_volume = config_json_table.dynamic_volume
        end
    else
        self:save_config()
    end
end


-- Function to save the current configuration
function COSTConfig:save_config ()
    local config_json_table = {
        dev = COSTConfig.dev,
        do_hook = COSTConfig.do_hook,
        load_timeout = COSTConfig.load_timeout,
        dynamic_load = COSTConfig.dynamic_load,
        default_fade_duration = COSTConfig.default_fade_duration,
        dynamic_volume = COSTConfig.dynamic_volume
    }

    local f = io.open(COSTConfig.config_file, "w")
    f:write(json.encode(config_json_table))
    f:close()
end


-- Function to get the object to set the menu elements state
function COSTConfig:get_menu_params ()
    local res = {}
    res.dev = COSTConfig.dev
    res.do_hook = COSTConfig.do_hook

    local _, load_timeout = pcall(function () for i, timeout in pairs(COSTConfig.load_timeout_trad) do if timeout == COSTConfig.load_timeout then return i end end return nil end)
    res.load_timeout = load_timeout

    res.dynamic_load = COSTConfig.dynamic_load

    local _, default_fade_duration = pcall(function () for i, duration in pairs(COSTConfig.fade_duration_trad) do if duration == COSTConfig.default_fade_duration then return i end end return nil end)
    res.default_fade_duration = default_fade_duration

    res.dynamic_volume = COSTConfig.dynamic_volume

    return res
end