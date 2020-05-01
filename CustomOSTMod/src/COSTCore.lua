-- Load all mod files
local source_dir_path = ModPath .. "src/"

if file.DirectoryExists(source_dir_path) then
    local source_files = file.GetFiles(source_dir_path)

    for _, file in pairs(source_files) do
        if file ~= "COSTCore.lua" and file ~= "COSTLateHooks.lua" then
            dofile(source_dir_path .. file)
        end
    end
else
    log("[CustomOST] [Error] : Cannot find the source directory, please reinstall this mod")
end

-- Verify and start the x audio
if not XAudio then
    COSTLogger:log_err("You need XAudio to make this mod work")
    return
end

blt.xaudio.setup()

-- Load all custom tracks
local tracks_dir_path = "mods/CustomOSTTracks/"

if file.DirectoryExists(tracks_dir_path) then
    local tracks_dir = file.GetDirectories(tracks_dir_path)
    local tracks_files = file.GetFiles(tracks_dir_path)

    -- Load all the track folders
    for _, dir in pairs(tracks_dir) do

        dir = dir .. "/"

        -- Get the json OR THE FALSE TXT JSON FILE
        local track_json_file = nil
        local track_xml_file = nil
        if file:FileExists(tracks_dir_path .. dir .. "track.txt") then
            track_json_file = tracks_dir_path .. dir .. "track.txt"
        end
        if file:FileExists(tracks_dir_path .. dir .. "track.json") then
            track_json_file = tracks_dir_path .. dir .. "track.json"
        end
        if file:FileExists(tracks_dir_path .. dir .. "main.xml") then
            track_xml_file = tracks_dir_path .. dir .. "main.xml"
        end

        if track_json_file then
            COSTTrackManager:create_from_json_file(track_json_file, tracks_dir_path .. dir)
        end
        if track_xml_file then
            COSTTrackManager:create_from_xml_file(track_xml_file, tracks_dir_path .. dir)
        end
        
    end

    -- Load all the simple music files
    for _, file in pairs(tracks_files) do
        local splited_file_name = split_string(file, ".")
        local file_extension = splited_file_name[#splited_file_name]
        if file_extension == "ogg" or file_extension == "OGG" then
            COSTTrackManager:create_simple_track(file, tracks_dir_path)
        end
    end
else
    COSTLogger:dev_log("Tracks directory was not found... The mod has created one")
    file:MakeDir(tracks_dir_path)
end

-- If you want to load the hooks in the game menu (essential for the mod working)
local do_hook = true

if do_hook then

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

-- Tell the developer if the core ended with success
COSTLogger:dev_log("Core ended correctly !")