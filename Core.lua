-- Load all mod files
local source_dir_path = ModPath .. "src/"

if file.DirectoryExists( source_dir_path ) then
    local source_files = file.GetFiles( source_dir_path )

    for _, file in pairs(source_files) do
        dofile( source_dir_path .. file )
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
local tracks_dir_path = "mods/CustomTracks/"

if file.DirectoryExists( tracks_dir_path ) then
    local tracks_dir = file.GetDirectories(tracks_dir_path)

    for _, dir in pairs(tracks_dir) do

        dir = dir .. "/"
        local track_json_file = tracks_dir_path .. dir .. "track.json"
        COSTTracks:create_from_file(track_json_file, tracks_dir_path .. dir)
        
    end
else
    COSTLogger:log_err("Tracks directory does not exists, please create the directory 'CustomOST/tracks/'")
end

-- Create all game hooks to make this mod works
-- If you just want to test music loading, set this value to "false"
local do_hooks = true

if do_hooks then

    -- Create the hook to insert the custom tracks in the jukebox menu
    Hooks:Add("LocalizationManagerPostInit", "CustomOSTTracksLocalization", function()
        COSTTracks:load_tracks_loc()
    end)

    Hooks:PostHook(MusicManager, "init", "CustomOSTTracksTweak", function()
        COSTTracks:add_tracks_tweak()
    end)

    -- Create hooks to make the custom music play
    Hooks:PostHook(MusicManager, "track_listen_start", "CustomOSTTrackListerStart", function(_, event, track)
        COSTMusicManager:track_listen_start(event, track)
    end)

    Hooks:PostHook(MusicManager, "track_listen_stop", "CustomOSTTrackListenStop", function()
        COSTMusicManager:track_listen_stop()
    end)

    Hooks:PostHook(MusicManager, "stop", "CustomOSTStop", function()
        COSTMusicManager:stop_custom(false)
    end)

    Hooks:PostHook(MusicManager, "post_event", "CustomOSTPostEvent", function(_, name)
        COSTMusicManager:post_event(name)
    end)

    -- Create the hooks to make the dynamic music integration
    Hooks:PostHook(DialogManager, "_play_dialog", "CustomOSTStartDialog", function ()
        COSTMusicManager:speek_mission()
    end)

    Hooks:PostHook(DialogManager, "_stop_dialog", "CustomOSTStopDialog", function ()
        COSTMusicManager:stop_speek()
    end)

    Hooks:PostHook(VoiceBriefingManager, "post_event", "CustomOSTVoiceBriefingTalk", function ()
        COSTMusicManager:speek_planning()
    end)

    Hooks:PostHook(VoiceBriefingManager, "post_event_simple", "CustomOSTVoiceBriefingTalk2", function ()
        COSTMusicManager:speek_planning()
    end)

    Hooks:PostHook(VoiceBriefingManager, "stop_event", "CustomOSTVoiceBriefingStop", function ()
        COSTMusicManager:stop_speek()
    end)

    Hooks:PostHook(VoiceBriefingManager, "_clear_event", "CustomOSTVoiceBriefingStop2", function ()
        COSTMusicManager:stop_speek()
    end)

end

-- Tell the developer if the core ended with success
COSTLogger:dev_log("Core ended correctly")