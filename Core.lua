-- Define config
local source_dir_path = ModPath .. "src/"
local tracks_dir_path = ModPath .. "tracks/"
local do_hooks = false

-- Load all mod files
if file.DirectoryExists( source_dir_path ) then
    local source_files = file.GetFiles( source_dir_path )

    for _, file in pairs(source_files) do
        dofile( source_dir_path .. file )
    end
else
    log("[ CustomOST ] [ Error ] : Cannot find the source directory, please reinstall this mod")
end

-- Verify and start the x audio
if not XAudio then
    CustomOSTLogger:log_err("You need XAudio to make this mod work")
    return nil
end

blt.xaudio.setup()

-- Load all custom tracks
local custom_tracks_map = {}
local custom_tracks_ordered = {}

if file.DirectoryExists( tracks_dir_path ) then
    local tracks_dir = file.GetDirectories(tracks_dir_path)

    for _, dir in pairs(tracks_dir) do

        dir = dir .. "/"
        local track_json_file = tracks_dir_path .. dir .. "track.json"
        local new_track = CustomOSTTrack:create_from_file(track_json_file, tracks_dir_path .. dir)

        if new_track ~= nil then
            custom_tracks_map[new_track.id] = new_track
            table.insert(custom_tracks_ordered, new_track)
        end
        
    end
else
    CustomOSTLogger:log_err( "Tracks directory does not exists, please create the directory 'CustomOST/tracks/'" )
end

-- Export all tracks in the globals
Global._custom_ost_tracks_map = custom_tracks_map
Global._custom_ost_tracks_ordered = custom_tracks_ordered

if do_hooks then

    -- Create the hook to insert the custom tracks in the wanted menu
    Hooks:Add("LocalizationManagerPostInit", "CustomOSTTracksLocalization", function()
        load_tracks_loc()
    end)

    Hooks:PostHook(MusicManager, "init", "CustomOSTTracksTweak", function()
        add_tracks_tweak()
    end)

    -- Create hooks to make the custom music play
    Hooks:PostHook(MusicManager, "track_listen_start", "CustomOSTTrackListerStart", function(_, event, track)
        log("track listen start")
        CustomOSTMusicManager:track_listen_start(event, track)
    end)

    Hooks:PostHook(MusicManager, "track_listen_stop", "CustomOSTTrackListenStop", function()
        log("track listen stop")
        CustomOSTMusicManager:track_listen_stop()
    end)

    Hooks:PostHook(MusicManager, "stop", "CustomOSTStop", function()
        log("stop")
        CustomOSTMusicManager:stop_custom(false)
    end)

    Hooks:PostHook(MusicManager, "post_event", "CustomOSTPostEvent", function(_, name)
        log("post event")
        CustomOSTMusicManager:post_event(name)
    end)

    -- Create the hooks to make the music integration
    Hooks:PostHook(DialogManager, "_play_dialog", "CustomOSTStartDialog", function ()
        CustomOSTMusicManager:set_volume_factor(0.45)
    end)

    Hooks:PostHook(DialogManager, "_stop_dialog", "CustomOSTStopDialog", function ()
        CustomOSTMusicManager:set_volume_factor(1)
    end)

    Hooks:PostHook(VoiceBriefingManager, "post_event", "CustomOSTVoiceBriefingTalk", function ()
        CustomOSTMusicManager:set_volume_factor(0.4)
    end)

    Hooks:PostHook(VoiceBriefingManager, "post_event_simple", "CustomOSTVoiceBriefingTalk2", function ()
        CustomOSTMusicManager:set_volume_factor(0.4)
    end)

    Hooks:PostHook(VoiceBriefingManager, "stop_event", "CustomOSTVoiceBriefingStop", function ()
        CustomOSTMusicManager:set_volume_factor(1)
    end)

    Hooks:PostHook(VoiceBriefingManager, "_clear_event", "CustomOSTVoiceBriefingStop2", function ()
        CustomOSTMusicManager:set_volume_factor(1)
    end)

end

-- Tell the developer if the core ended with success
CustomOSTLogger:dev_log("Core ended correctly")