CustomOSTMusicManager = {}
local C = CustomOSTMusicManager

C.event_x_sources = {
    setup = nil,
    control = nil,
    buildup = nil,
    assault = nil
}

C.current_track = nil
C.current_event = nil

C.events_table = {
    music_heist_setup = "setup",
    music_heist_control = "control",
    music_heist_anticipation = "buildup",
    music_heist_assault = "assault"
}

C.volume_factor = 1

-- Function to handle the music preview in the loadout menu
function C:track_listen_start (event, track)
    if track and Global._custom_ost_tracks_map[track] then
        Global.music_manager.source:stop()
        if track ~= C.current_track then
            C.stop_custom(false)
            C:play_custom(event, track, false, false)
        end
    else
        C:stop_custom(false)
    end
end

-- Function to handle stop music preview in the loadout menu
function C:track_listen_stop ()
    if Global._custom_ost_tracks_map[Global.music_manager.loadout_selection] then
        C:stop_custom(true, 1)
    end
end

-- Fuction to handle event changing in the heist
function C:post_event (event)
    local current_track_id = Global.music_manager.loadout_selection
    if Global._custom_ost_tracks_map[current_track_id] then

        if C.current_event == C.events_table[event] and C.current_track == current_track_id then
            return
        end

        local custom_track = Global._custom_ost_tracks_map[current_track_id]

        if custom_track.fade_transition then
            C:stop_custom(true, 0.5)
            C:play_custom(event, current_track_id, true, true, 0.5)
        else
            C:stop_custom()
            C:play_custom(event, current_track_id, true, false)
        end
    end
end

-- Function to play a custom track in the wanted event
function C:play_custom (event, track, play_start, fade, fade_duration)
    if C.events_table[event] then

        -- Traduct the event for custom OST
        local trad_event = C.events_table[event]
        local custom_track = Global._custom_ost_tracks_map[track]

        -- Test if the track is correct
        if not custom_track or custom_track._meta ~= "CustomOSTTrack" then
            CustomOSTLogger:log_err("Track " .. track .. " could not be loaded")
            return
        end

        -- Save the current event and the current track
        C.current_event = trad_event
        C.current_track = custom_track.id

        -- Choose between simple playing and start playing
        if play_start and custom_track.events[trad_event].start_source_buffer and custom_track.events[trad_event].start_source_file then

            C.event_x_sources[trad_event] = CustomOSTXSource:create_source(custom_track.events[trad_event].start_source_buffer, trad_event)
            C.event_x_sources[trad_event]:set_looping(false)
            Hooks:PostHook(C.event_x_sources[trad_event], "close", "CustomOSTStart" .. event .. "TrackClose", function ()
                C:play_after_start(event)
            end)

        else

            C.event_x_sources[trad_event] = CustomOSTXSource:create_source(custom_track.events[trad_event].source_buffer, trad_event)
            C.event_x_sources[trad_event]:set_looping(true)

        end

        -- Set the common track settings
        C.event_x_sources[trad_event]:set_type(CustomOSTXSource.MUSIC)
        C.event_x_sources[trad_event]:set_relative(true)
        
        if fade then
            fade_duration = fade_duration or 1
            CustomOSTXSource:fade_in(C.event_x_sources[trad_event], custom_track.volume * C.volume_factor, fade_duration)
        else
            C.event_x_sources[trad_event]:set_volume(custom_track.volume * C.volume_factor)
        end

        CustomOSTLogger:dev_log("Playing " .. custom_track.id .. " - " .. trad_event)

    else

        CustomOSTLogger:dev_log("Event " .. event .. " is not handle")

    end
end

-- A function to play the track loop after the start source were played
function C:play_after_start (event)
    -- Remove the hook to avoid recursiv calling
    Hooks:RemovePostHook("CustomOSTStart" .. event .. "TrackClose")

    -- If the track is in the same event, play the main track part
    if C.events_table[event] then
        local trad_event = C.events_table[event]

        if trad_event == C.current_event then
            local custom_track = Global._custom_ost_tracks_map[C.current_track]

            CustomOSTXSource:close_source(C.event_x_sources[trad_event])
            C.event_x_sources[trad_event] = CustomOSTXSource:create_source(custom_track.events[trad_event].source_buffer, trad_event)
            C.event_x_sources[trad_event]:set_looping(true)
            C.event_x_sources[trad_event]:set_relative(true)
            C.event_x_sources[trad_event]:set_type(CustomOSTXSource.MUSIC)
            C.event_x_sources[trad_event]:set_volume(custom_track.volume * C.volume_factor)
        end
    else
        CustomOSTLogger:dev_log("Event " .. event .. " is not handle by CustomOST")
    end
end

-- Function to stop all custom tracks playing
function C:stop_custom (fade, fade_duration)
    -- For each source, if it is active, stop it
    for event, source in pairs(C.event_x_sources) do
        if source and source:is_active() then

            if fade then
                fade_duration = fade_duration or 1
                CustomOSTXSource:fade_out(source, fade_duration)
            else
                CustomOSTXSource:close_source(source)
            end
            C.event_x_sources[event] = nil
            C.current_track = nil
            C.current_event = nil

            CustomOSTLogger:dev_log("Stop custom track")

        end
    end
end

-- Function to set the volume of all event relatively to the track volume
function C:set_volume_factor (factor)
    if factor >= 0 then
        C.volume_factor = factor
        if C.current_track then
            local custom_track = Global._custom_ost_tracks_map[C.current_track]

            for event, source in pairs(C.event_x_sources) do
                if source then
                    if source:is_active() then
                        source:set_volume(custom_track.volume * C.volume_factor)
                    end
                end
            end
        end
    end
end