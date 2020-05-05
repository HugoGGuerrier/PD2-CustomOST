------ This class contains all the mod configuration ------


COSTConfig = COSTConfig or {}

COSTConfig.dev = false
COSTConfig.do_hook = true
COSTConfig.load_timeout = -1
COSTConfig.default_fade_duration = 1


-- Function to load the mod config from a config file
function COSTConfig:load_config (config_file)
    if file.FileExists(config_file) then
        local f = io.open(config_file, "r")
        local config_json_string = f:read("*all")
        local valid, config_json_table = pcall(function () return json.decode(config_json_string) end)
        if valid then
            COSTConfig.dev = config_json_table.dev
            COSTConfig.do_hook = config_json_table.do_hook
            COSTConfig.load_timeout = config_json_table.load_timeout
            COSTConfig.default_fade_duration = config_json_table.default_fade_duration
        end
    end
end