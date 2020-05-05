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
local config_file = ModPath .. "config.txt"
COSTConfig:load_config(config_file)

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

    -- Launch the track file loading
    COSTTrackManager:load_tracks_files()
else
    COSTLogger:dev_log("Tracks directory was not found... The mod has created one")
    file.MakeDir(tracks_dir_path)
end

-- Set the game init indicators
Global.custom_ost_indicators.game_init = true


------ Create the hooks to insert custom tracks in the game ------


if COSTConfig.do_hook then

    -- Create the hook to insert the custom tracks in the jukebox menu and the playlist menu
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

    Hooks:PostHook(MusicManager, "stop", "CustomOSTStop", function()
        COSTMusicManager:stop_custom(false, 1)
    end)

    Hooks:PostHook(MusicManager, "post_event", "CustomOSTPostEvent", function(_, name)
        COSTMusicManager:post_event(name)
    end)

end


------ End of the core ------


COSTLogger:dev_log("Core ended correctly !")