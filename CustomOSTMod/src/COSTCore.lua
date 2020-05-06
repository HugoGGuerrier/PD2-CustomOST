Global.custom_ost_indicators = Global.custom_ost_indicators or {}


------ Load the mod ------


local misc_dir_path = ModPath .. "src/misc/"
local bases_dir_path = ModPath .. "src/bases/"
local classes_dir_path = ModPath .. "src/classes/"
local managers_dir_path = ModPath .. "src/managers/"

-- Load the misc sources
if file.DirectoryExists(misc_dir_path) then
    local misc_source_files = file.GetFiles(misc_dir_path)

    for _, file in pairs(misc_source_files) do
        dofile(misc_dir_path .. file)
    end
else
    log("[CustomOST] [Error] : Cannot find the misc source directory, please reinstall this mod !")
    return nil
end

-- Load the mod config
COSTConfig:load_config()

-- Load the bases sources
if file.DirectoryExists(bases_dir_path) then
    local bases_source_files = file.GetFiles(bases_dir_path)

    for _, file in pairs(bases_source_files) do
        dofile(bases_dir_path .. file)
    end
else
    COSTLogger:log_err("[CustomOST] [Error] : Cannot find the bases source directory, please reinstall this mod !")
    return nil
end

-- Load the classes sources
if file.DirectoryExists(classes_dir_path) then
    local classes_source_files = file.GetFiles(classes_dir_path)

    for _, file in pairs(classes_source_files) do
        dofile(classes_dir_path .. file)
    end
else
    COSTLogger:log_err("[CustomOST] [Error] : Cannot find the classes source directory, please reinstall this mod !")
    return nil
end

-- Load the managers sources
if file.DirectoryExists(managers_dir_path) then
    local managers_source_files = file.GetFiles(managers_dir_path)

    for _, file in pairs(managers_source_files) do
        dofile(managers_dir_path .. file)
    end
else
    COSTLogger:log_err("[CustomOST] [Error] : Cannot find the managers source directory, please reinstall this mod !")
    return nil
end


------ Verify and initialize the XAudio API ------


if not XAudio then
    COSTLogger:log_err("You need XAudio to make this mod work")
    return nil
end

blt.xaudio.setup()


------ Load all the custom tracks ------


local tracks_dir_path = "mods/CustomOSTTracks/"

if file.DirectoryExists(tracks_dir_path) then
    -- Load all the track folders
    local tracks_dirs = file.GetDirectories(tracks_dir_path)

    for _, dir in pairs(tracks_dirs) do

        dir = dir .. "/"

        -- Get the json or the xml file
        local track_json_file = nil
        local track_xml_file = nil

        if file.FileExists(tracks_dir_path .. dir .. "track.txt") then
            track_json_file = tracks_dir_path .. dir .. "track.txt"
        end
        if file.FileExists(tracks_dir_path .. dir .. "track.json") then
            track_json_file = tracks_dir_path .. dir .. "track.json"
        end
        if file.FileExists(tracks_dir_path .. dir .. "main.xml") then
            track_xml_file = tracks_dir_path .. dir .. "main.xml"
        end

        if track_json_file then
            COSTTrackManager:create_track_from_json(track_json_file, tracks_dir_path .. dir)
        elseif track_xml_file then
            COSTTrackManager:create_track_from_xml(track_xml_file, tracks_dir_path .. dir)
        else
            COSTLogger:log_warn("Cannot load the track mod " .. dir .. " track definition file does not exists")
        end
        
    end

    -- Load all the simple music files
    local tracks_files = file.GetFiles(tracks_dir_path)

    for _, file in pairs(tracks_files) do
        local splited_file_name = split_string(file, ".")
        local file_extension = splited_file_name[#splited_file_name]
        if file_extension == "ogg" or file_extension == "OGG" then
            COSTTrackManager:create_track_from_ogg(file, tracks_dir_path)
        end
    end

    -- Launch the track file loading if the dynamic loading is not active
    if not COSTConfig.dynamic_load then
        COSTTrackManager:load_tracks_files()
    end
else
    COSTLogger:dev_log("Tracks directory was not found... The mod has created one")
    file.MakeDir(tracks_dir_path)
end

-- Set the game init indicators
Global.custom_ost_indicators.game_init = true


------ Create the and function to make the mod menu ------


-- Load the menu localization
local loc_file = ModPath .. "loc/en.txt"

Hooks:Add("LocalizationManagerPostInit", "CustomOSTMenuLocalization", function ()
    if file.FileExists(loc_file) then
        local loc_f = io.open(loc_file, "r")
        local loc_json_string = loc_f:read("*all")
        loc_f:close()

        local valid, loc_json_table = pcall(function () return json.decode(loc_json_string) end)
        if valid then
            LocalizationManager:add_localized_strings(loc_json_table, false)
        else
            COSTLogger:log_err("Error during the menu localization file parsing : " .. loc_file)
        end
    else
        COSTLogger:log_err(loc_file .. " is missing or unreadable")
    end
end)

-- Create the menu callback functions
MenuCallbackHandler.costn_save = function ()
    COSTConfig:save_config()
end

MenuCallbackHandler.costn_default_fade_duration_choice = function (_, v)
    COSTConfig.default_fade_duration = COSTConfig.fade_duration_trad[v._current_index]
end

MenuCallbackHandler.costn_dynamic_load_toogle = function (_, v)
    local _, timeout_choice = pcall(function () for _, item in pairs(MenuHelper:GetMenu("costn_menu")._items) do if item._parameters.name == "costn_load_timeout_choice" then return item end end return nil end)
    if v.selected == 1 then
        COSTConfig.dynamic_load = true
        timeout_choice._enabled = false
    else
        COSTConfig.dynamic_load = false
        timeout_choice._enabled = true
    end
    timeout_choice:dirty_callback()
end

MenuCallbackHandler.costn_load_timeout_choice = function (_, v)
    COSTConfig.load_timeout = COSTConfig.load_timeout_trad[v._current_index]
end

MenuCallbackHandler.costn_dev_toogle = function (_, v)
    COSTConfig.dev = v.selected == 1
end

MenuCallbackHandler.costn_hook_toogle = function (_, v)
    COSTConfig.do_hook = v.selected == 1
end


-- Add the mod menu
local menu_id = "costn_menu"
local menu_file = ModPath .. "res/mod_menu.json"

Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenus_Example", function(_, _)
    MenuHelper:NewMenu(menu_id)
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_Example", function(_, _)
    MenuHelper:LoadFromJsonFile(menu_file, {}, COSTConfig:get_menu_params())
end)

------ Create the hooks to insert custom tracks in the game ------


if COSTConfig.do_hook then

    -- Create hooks to insert the custom tracks in the jukebox menu and the playlist menu
    Hooks:Add("LocalizationManagerPostInit", "CustomOSTTracksLocalization", function()
        COSTTrackManager:load_tracks_loc()
    end)

    Hooks:PostHook(MusicManager, "init", "CustomOSTTracksTweak", function()
        COSTTrackManager:add_tracks_tweak()
    end)

    -- Create hooks to make the custom music play
    Hooks:PostHook(MusicManager, "track_listen_start", "CustomOSTTrackListerStart", function(_, event, track)
        COSTMusicManager:track_listen_start(event, track)
    end)

    Hooks:PostHook(MusicManager, "track_listen_stop", "CustomOSTTrackListenStop", function()
        COSTMusicManager:track_listen_stop()
    end)

    Hooks:PostHook(MusicManager, "on_mission_end", "CustomOSTMissionEnd", function ()
        COSTMusicManager:stop_and_clean(true, 1)
    end)

    Hooks:PostHook(MusicManager, "stop", "CustomOSTStop", function()
        COSTMusicManager:stop_and_clean(false, 0)
    end)

    Hooks:PostHook(MusicManager, "post_event", "CustomOSTPostEvent", function(_, name)
        COSTMusicManager:post_event(name)
    end)

    -- Compatibility with Music Control
    if Music then
        Hooks:PreHook(Music, "Call", "CustomOSTMusicControlCompats", function (_, _, song, event, _)
            Global.music_manager.current_track = song
        end)
    end

end


------ End of the core ------


COSTLogger:dev_log("Core ended correctly !")