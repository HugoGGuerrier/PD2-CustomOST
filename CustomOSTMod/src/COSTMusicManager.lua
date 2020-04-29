COSTMusicManager = COSTMusicManager or {}

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

COSTMusicManager.volume_alterators = {
    hit = 0,
    feedback = 0,
    speak = 0
}

COSTMusicManager.timeouts = {
    hit = {
        timer = nil,
        clbk = function () COSTMusicManager.volume_alterators.hit = 0 end
    },
    feedback = {
        timer = nil,
        clbk = function () COSTMusicManager.volume_alterators.feedback = 0 end
    }
}

COSTMusicManager.volume_decline = {
    duration = nil,
    cursor = nil
}

-- Function to handle the music preview in the loadout menu
function COSTMusicManager:track_listen_start (event, track)
    -- Only if track exists
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

    else

        if event and event == "stop_all_music" then
            if COSTMusicManager.current_track then
                -- Remove the current state
                COSTMusicManager.current_event = nil
                COSTMusicManager.current_track = nil

                -- Stop the custom music
                COSTLogger:dev_log("Other choice in the ost menu !")
                COSTMusicManager:stop_custom(false, 1)
            end
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
    local current_track = COSTMusicManager.current_track or Global.music_manager.loadout_selection
    if COSTTracks.custom_tracks_map[current_track] then
        -- Update the curren track
        if current_track ~= COSTMusicManager.current_track then
            COSTMusicManager.current_track = current_track
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
                    COSTMusicManager:stop_custom(true, 1)
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
        COSTMusicManager:play_custom(false, false, 1)
    end
end

-- Function to call every tick
function COSTMusicManager:custom_update (dt)
    -- Update all the timeouts and trigger them if they are good to go
    for _, timeout in pairs(COSTMusicManager.timeouts) do

        if timeout.timer ~= nil then
            timeout.timer = timeout.timer - dt
            if timeout.timer <= 0 then
                timeout.timer = nil
                timeout.clbk()
            end
        end

    end

    -- Update the colume decliner
    if COSTMusicManager.volume_decline.duration ~= nil and COSTMusicManager.volume_decline.cursor ~= nil then
        COSTMusicManager.volume_decline.cursor = COSTMusicManager.volume_decline.cursor + dt
    end
end

-- Get the volumae factor
function COSTMusicManager:get_volume_factor ()
    local decline_factor = 1
    if COSTMusicManager.volume_decline.duration ~= nil and COSTMusicManager.volume_decline.cursor ~= nil then
        decline_factor = (COSTMusicManager.volume_decline.duration - COSTMusicManager.volume_decline.cursor) / COSTMusicManager.volume_decline.duration
        decline_factor = math.max(0, decline_factor)
    end
    return math.max(0.15, (1 - (COSTMusicManager.volume_alterators.feedback + COSTMusicManager.volume_alterators.hit + COSTMusicManager.volume_alterators.speak))) * decline_factor
end

-- Function to call when someone talk in the preplanning 
function COSTMusicManager:speak_planning ()
    COSTMusicManager.volume_alterators.speak = 0.6
end

-- Function to call when someone talk during the mission
function COSTMusicManager:speak_mission ()
    if COSTMusicManager.current_track then
        if COSTMusicManager.current_event then
            if COSTMusicManager.current_event == "setup" then
                COSTMusicManager.volume_alterators.speak = 0.7
            end
            if COSTMusicManager.current_event == "control" then
                COSTMusicManager.volume_alterators.speak = 0.65
            end
            if COSTMusicManager.current_event == "buildup" then
                COSTMusicManager.volume_alterators.speak = 0.5
            end
            if COSTMusicManager.current_event == "assault" then
                COSTMusicManager.volume_alterators.speak = 0.4
            end
        end
    end
end

-- Function to call when nobody speak
function COSTMusicManager:stop_speak ()
    COSTMusicManager.volume_alterators.speak = 0
end

-- Function to call when there is a feedback sound (gage, loot, small loot...)
function COSTMusicManager:feedback_sound ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timeouts.feedback.timer = 2.5
        COSTMusicManager.volume_alterators.feedback = 0.75
    end
end

-- Function to call when the player recieve a new objective
function COSTMusicManager:objective_sound ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timeouts.feedback.timer = 3
        COSTMusicManager.volume_alterators.feedback = 0.75
    end
end

-- Function to call when the player is hit
function COSTMusicManager:hit_sound ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timeouts.hit.timer = 0.7
        COSTMusicManager.volume_alterators.hit = 0.3
    end
end

-- Function to enter in the bleedout state
function COSTMusicManager:bleedout_enter ()
    if COSTMusicManager.current_track then
        COSTMusicManager.volume_decline.duration = 27
        COSTMusicManager.volume_decline.cursor = 0
    end
end

-- Function to return to the standard state
function COSTMusicManager:standard_enter ()
    if COSTMusicManager.current_track then
        COSTMusicManager.volume_decline.duration = nil
        COSTMusicManager.volume_decline.cursor = nil
    end
end