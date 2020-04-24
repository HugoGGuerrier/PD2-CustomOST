COSTMusicManager = {}

COSTMusicManager.current_track = nil
COSTMusicManager.current_event = nil
COSTMusicManager.x_source = nil

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
        local custom_track = COSTTracks.custom_tracks_map[track]
        local trad_event = COSTMusicManager.events_table[event]

        if custom_track and trad_event then
            if custom_track.id ~= COSTMusicManager.current_track or trad_event ~= COSTMusicManager.current_event then

                -- Update current state
                COSTMusicManager.current_event = trad_event
                COSTMusicManager.current_track = custom_track.id

                -- Stop all other music
                Global.music_manager.source:stop()
                COSTMusicManager:stop_custom(false, 1)

                -- Play the custom music
                COSTLogger:dev_log("Custom track listen start " .. custom_track.id .. " - " .. trad_event .. " !")
                COSTMusicManager:play_custom(false, false, 1)

            end
        else
            -- Remove the current state
            COSTMusicManager.current_event = nil
            COSTMusicManager.current_track = nil

            -- Stop the custom music
            COSTLogger:dev_log("Other track listen start !")
            COSTMusicManager:stop_custom(false, 1)
        end

    end
end

-- Function to handle stop music preview in the loadout menu
function COSTMusicManager:track_listen_stop ()
    if COSTTracks.custom_tracks_map[Global.music_manager.loadout_selection] then
        COSTMusicManager.current_event = nil
        COSTLogger:dev_log("Track listen stop !")
        COSTMusicManager:stop_custom(true, 1)
    end
end

-- Fuction to handle event changing in the heist
function COSTMusicManager:post_event (event)
    -- Verify the current track selection
    local current_track_id = COSTMusicManager.current_track or Global.music_manager.loadout_selection
    if COSTTracks.custom_tracks_map[current_track_id] then
        -- Update the curren track
        if current_track_id ~= COSTMusicManager.current_track then
            COSTMusicManager.current_track = current_track_id
        end

        -- Make the event changing
        if COSTMusicManager.events_table[event] then
            local trad_event = COSTMusicManager.events_table[event]

            if COSTMusicManager.current_event ~= trad_event then
                COSTMusicManager.current_event = trad_event
                local is_track_fade = COSTTracks.custom_tracks_map[COSTMusicManager.current_track].fade_transition
                local fade_duration = COSTTracks.custom_tracks_map[COSTMusicManager.current_track].fade_duration

                COSTLogger:dev_log(trad_event .. " posted !")

                COSTMusicManager:stop_custom(is_track_fade, fade_duration)
                COSTMusicManager:play_custom(true, is_track_fade, fade_duration)
            end
        else
            if event == "resultscreen_win" or event == "resultscreen_lose" then
                if COSTMusicManager.current_track then
                    self:stop_custom(true, 1)
                end
            else
                COSTLogger:dev_log("Event " .. event .. " is not handle")
            end
        end
    end
end

-- Function to play a custom track in the wanted event
function COSTMusicManager:play_custom (play_start, fade_in, fade_duration)
    if not COSTMusicManager.x_source or COSTMusicManager.x_source:is_closed() then
        local custom_track = COSTTracks.custom_tracks_map[COSTMusicManager.current_track]

        if custom_track and COSTMusicManager.current_event then
            local cost_buffer = COSTBuffer:create_buffer(custom_track, COSTMusicManager.current_event, play_start)
            COSTMusicManager.x_source = COSTXSource:new(cost_buffer)
            if fade_in then
                COSTMusicManager.x_source:fade_in(fade_duration)
            end
        else
            COSTLogger:log_err("Try to start a custom track with values current_event=" .. (COSTMusicManager.current_event or "nil") .. " current_track=" .. (COSTMusicManager.current_track or "nil"))
        end
    end
end

-- Function to stop all custom tracks playing
function COSTMusicManager:stop_custom (fade_out, fade_duration)
    if COSTMusicManager.x_source then
        if fade_out then
            COSTMusicManager.x_source:fade_out(fade_duration)
        else
            COSTMusicManager.x_source:close()
        end
        COSTMusicManager.x_source = nil
    end
end

-- Function to signal a start track end
function COSTMusicManager:start_finish (event)
    COSTLogger:dev_log("End of the " .. event .. " start source")
    if event == COSTMusicManager.current_event then
        self:play_custom(false, false, 1)
    end
end

-- Set the volume factor
function COSTMusicManager:set_volume_factor (factor)
    if factor <= 1 and factor >= 0 then
        COSTMusicManager.volume_factor = factor
        if COSTMusicManager.x_source then
            COSTMusicManager.x_source:set_volume(COSTMusicManager.volume_factor * COSTMusicManager.x_source:track_volume())
        end
    end
end

-- Function to call when someone talk in the preplanning 
function COSTMusicManager:speak_planning ()
    if COSTMusicManager.current_track then
        log("speek planning")
        self:set_volume_factor(0.4)
    end
end

-- Function to call when someone talk during the mission
function COSTMusicManager:speak_mission ()
    if COSTMusicManager.current_track then
        if COSTMusicManager.current_event then
            log("speak mission")
            if COSTMusicManager.current_event == "setup" then
                self:set_volume_factor(0.35)
            end
            if COSTMusicManager.current_event == "control" then
                self:set_volume_factor(0.43)
            end
            if COSTMusicManager.current_event == "buildup" then
                self:set_volume_factor(0.5)
            end
            if COSTMusicManager.current_event == "assault" then
                self:set_volume_factor(0.6)
            end
        end
    end
end

function COSTMusicManager:stop_speak ()
    log("stop speak")
    self:set_volume_factor(1)
end

-- Function to call when there is a loot sound
function COSTMusicManager:loot_sound ()
    -- TODO : Lower the music volume
end