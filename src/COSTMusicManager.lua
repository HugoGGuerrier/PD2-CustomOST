COSTMusicManager = {}

COSTMusicManager.current_track = nil
COSTMusicManager.current_event = nil

COSTMusicManager.events_table = {
    music_heist_setup = "setup",
    music_heist_control = "control",
    music_heist_anticipation = "buildup",
    music_heist_assault = "assault"
}
COSTMusicManager.events_rtable = {
    setup = "music_heist_setup",
    control = "music_heist_control",
    buildup = "music_heist_anticipation",
    assault = "music_heist_assault"
}

COSTMusicManager.volume_factor = 1

-- Function to handle the music preview in the loadout menu
function COSTMusicManager:track_listen_start (event, track)
    -- Only if track exists, else do nothing
    if track then

        -- Test if the track is a custom track
        local custom_track_id = COSTTracks.custom_tracks_map[track].id
        local trad_event = COSTMusicManager.events_table[event]

        if custom_track_id and trad_event then

            COSTMusicManager.current_event = trad_event
            COSTMusicManager.current_track = custom_track_id

            COSTLogger:dev_log("Custom track listen start " .. custom_track_id .. " - " .. trad_event .. " !")
            -- TODO : Play the current custom music
        else
            COSTLogger:dev_log("Other track listen start !")
            -- TODO : Stop the current custom music
        end

    end
end

-- Function to handle stop music preview in the loadout menu
function COSTMusicManager:track_listen_stop ()
    if COSTTracks.custom_tracks_map[Global.music_manager.loadout_selection] then
        COSTLogger:dev_log("Track listen stop !")
        -- TODO : Stop the current music
    end
end

-- Fuction to handle event changing in the heist
function COSTMusicManager:post_event (event)
    -- Verify thge current track selection
    local loadout_selection = Global.music_manager.loadout_selection
    if COSTTracks.custom_tracks_map[loadout_selection] and COSTMusicManager.current_track ~= loadout_selection then
        COSTMusicManager.current_track = loadout_selection
    end

    -- Make the event changing
    if COSTMusicManager.events_table[event] then
        local trad_event = COSTMusicManager.events_table[event]

        if COSTMusicManager.current_event ~= trad_event then
            COSTMusicManager.current_event = trad_event

            COSTLogger:dev_log(trad_event .. " posted !")
            -- TODO : Handle the music change
        end
    else
        COSTLogger:dev_log("Event " .. event .. " is not handle")
    end
end

-- Function to play a custom track in the wanted event
function COSTMusicManager:play_custom (play_start, fade_in, fade_duration)
    -- TODO : Play the current custom track
end

-- Function to stop all custom tracks playing
function COSTMusicManager:stop_custom (fade, fade_duration)
    -- TODO : Stop the current music playing
end

-- Function to set the volume of all event relatively to the track volume
function COSTMusicManager:set_volume_factor (factor)
    if factor >= 0 and factor <= 1 then
        COSTLogger:dev_log("Volume factor set to " .. factor .. " !")
    end
end