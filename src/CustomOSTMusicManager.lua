CustomOSTMusicManager = {}

CustomOSTMusicManager.event_x_sources = {
    setup = nil,
    control = nil,
    buildup = nil,
    assault = nil
}

CustomOSTMusicManager.current_track = nil
CustomOSTMusicManager.current_event = nil

CustomOSTMusicManager.events_table = {
    music_heist_setup = "setup",
    music_heist_control = "control",
    music_heist_anticipation = "buildup",
    music_heist_assault = "assault"
}

CustomOSTMusicManager.volume_factor = 1

-- Function to handle the music preview in the loadout menu
function CustomOSTMusicManager:track_listen_start (event, track)
    if track and Global._custom_ost_tracks_map[track] then
        Global.music_manager.source:stop()
        if track ~= CustomOSTMusicManager.current_track then
            CustomOSTMusicManager.stop_custom(false)
            CustomOSTMusicManager:play_custom(event, track, false, false)
        end
    else
        CustomOSTMusicManager:stop_custom(false)
    end
end

-- Function to handle stop music preview in the loadout menu
function CustomOSTMusicManager:track_listen_stop ()
    if Global._custom_ost_tracks_map[Global.music_manager.loadout_selection] then
        CustomOSTMusicManager:stop_custom(true, 1)
    end
end

-- Fuction to handle event changing in the heist
function CustomOSTMusicManager:post_event (event)
    local current_track_id = Global.music_manager.loadout_selection
    if Global._custom_ost_tracks_map[current_track_id] then

        if CustomOSTMusicManager.current_event == CustomOSTMusicManager.events_table[event] and CustomOSTMusicManager.current_track == current_track_id then
            return
        end

        local custom_track = Global._custom_ost_tracks_map[current_track_id]

        if custom_track.fade_transition then
            CustomOSTMusicManager:stop_custom(true, 0.5)
            CustomOSTMusicManager:play_custom(event, current_track_id, true, true, 0.5)
        else
            CustomOSTMusicManager:stop_custom()
            CustomOSTMusicManager:play_custom(event, current_track_id, true, false)
        end
    end
end

-- Function to play a custom track in the wanted event
function CustomOSTMusicManager:play_custom (event, track, play_start, fade, fade_duration)
    if CustomOSTMusicManager.events_table[event] then

        -- Traduct the event for custom OST
        local trad_event = CustomOSTMusicManager.events_table[event]
        local custom_track = Global._custom_ost_tracks_map[track]

        -- Test if the track is correct
        if not custom_track or custom_track._meta ~= "CustomOSTTrack" then
            CustomOSTLogger:log_err("Track " .. track .. " could not be loaded")
            return
        end

        -- Save the current event and the current track
        CustomOSTMusicManager.current_event = trad_event
        CustomOSTMusicManager.current_track = custom_track.id

        -- Choose between simple playing and start playing
        if play_start and custom_track.events[trad_event].start_source_buffer and custom_track.events[trad_event].start_source_file then

            CustomOSTMusicManager.event_x_sources[trad_event] = CustomOSTXSource:create_source(custom_track.events[trad_event].start_source_buffer, trad_event)
            CustomOSTMusicManager.event_x_sources[trad_event]:set_looping(false)
            Hooks:PostHook(CustomOSTMusicManager.event_x_sources[trad_event], "close", "CustomOSTStart" .. event .. "TrackClose", function ()
                CustomOSTMusicManager:play_after_start(event)
            end)

        else

            CustomOSTMusicManager.event_x_sources[trad_event] = CustomOSTXSource:create_source(custom_track.events[trad_event].source_buffer, trad_event)
            CustomOSTMusicManager.event_x_sources[trad_event]:set_looping(true)

        end

        -- Set the common track settings
        CustomOSTMusicManager.event_x_sources[trad_event]:set_type(CustomOSTXSource.MUSIC)
        CustomOSTMusicManager.event_x_sources[trad_event]:set_relative(true)
        
        if fade then
            fade_duration = fade_duration or 1
            CustomOSTXSource:fade_in(CustomOSTMusicManager.event_x_sources[trad_event], custom_track.volume * CustomOSTMusicManager.volume_factor, fade_duration)
        else
            CustomOSTMusicManager.event_x_sources[trad_event]:set_volume(custom_track.volume * CustomOSTMusicManager.volume_factor)
        end

        CustomOSTLogger:dev_log("Playing " .. custom_track.id .. " - " .. trad_event)

    else

        CustomOSTLogger:dev_log("Event " .. event .. " is not handle")

    end
end

-- A function to play the track loop after the start source were played
function CustomOSTMusicManager:play_after_start (event)
    -- Remove the hook to avoid recursiv calling
    Hooks:RemovePostHook("CustomOSTStart" .. event .. "TrackClose")

    -- If the track is in the same event, play the main track part
    if CustomOSTMusicManager.events_table[event] then
        local trad_event = CustomOSTMusicManager.events_table[event]

        if trad_event == CustomOSTMusicManager.current_event then
            local custom_track = Global._custom_ost_tracks_map[CustomOSTMusicManager.current_track]

            CustomOSTXSource:close_source(CustomOSTMusicManager.event_x_sources[trad_event])
            CustomOSTMusicManager.event_x_sources[trad_event] = CustomOSTXSource:create_source(custom_track.events[trad_event].source_buffer, trad_event)
            CustomOSTMusicManager.event_x_sources[trad_event]:set_looping(true)
            CustomOSTMusicManager.event_x_sources[trad_event]:set_relative(true)
            CustomOSTMusicManager.event_x_sources[trad_event]:set_type(CustomOSTXSource.MUSIC)
            CustomOSTMusicManager.event_x_sources[trad_event]:set_volume(custom_track.volume * CustomOSTMusicManager.volume_factor)
        end
    else
        CustomOSTLogger:dev_log("Event " .. event .. " is not handle by CustomOST")
    end
end

-- Function to stop all custom tracks playing
function CustomOSTMusicManager:stop_custom (fade, fade_duration)
    -- For each source, if it is active, stop it
    for event, source in pairs(CustomOSTMusicManager.event_x_sources) do
        if source and source:is_active() then

            if fade then
                fade_duration = fade_duration or 1
                CustomOSTXSource:fade_out(source, fade_duration)
            else
                CustomOSTXSource:close_source(source)
            end
            CustomOSTMusicManager.event_x_sources[event] = nil
            CustomOSTMusicManager.current_track = nil
            CustomOSTMusicManager.current_event = nil

            CustomOSTLogger:dev_log("Stop custom track")

        end
    end
end

-- Function to set the volume of all event relatively to the track volume
function CustomOSTMusicManager:set_volume_factor (factor)
    if factor >= 0 then
        CustomOSTMusicManager.volume_factor = factor
        if CustomOSTMusicManager.current_track then
            local custom_track = Global._custom_ost_tracks_map[CustomOSTMusicManager.current_track]

            for event, source in pairs(CustomOSTMusicManager.event_x_sources) do
                if source then
                    if source:is_active() then
                        source:set_volume(custom_track.volume * CustomOSTMusicManager.volume_factor)
                    end
                end
            end
        end
    end
end