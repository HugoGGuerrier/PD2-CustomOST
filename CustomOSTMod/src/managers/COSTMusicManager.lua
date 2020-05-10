------ The manager which handle all music events ------


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
    speak = 0,
    event = 0
}

COSTMusicManager.timers = {
    hit = nil,
    feedback = nil,
    bleedout = nil,
    flashbang = nil
}


-- Function to handle the music preview in the loadout menu
function COSTMusicManager:track_listen_start (event, track)
    -- Only if track exists
    if track then
        -- Test if the track is a custom track
        local custom_track = COSTTrackManager.custom_tracks_map[track]
        local trad_event = COSTMusicManager.events_table[event]

        if custom_track and trad_event then
            if custom_track:get_id() ~= COSTMusicManager.current_track or trad_event ~= COSTMusicManager.current_event then

                -- Update current state
                COSTMusicManager.current_event = trad_event
                COSTMusicManager.current_track = custom_track:get_id()

                -- Stop all other music
                Global.music_manager.source:stop()
                COSTMusicManager:stop_custom(false, 1)

                -- Play the custom music
                COSTLogger:log_dev("Custom track listen start " .. custom_track:get_id() .. " - " .. trad_event .. " !")
                COSTMusicManager:play_custom(false, 1, {forced = "main"})

            end
        else
            COSTMusicManager:stop_and_clean(false, 0)
            COSTLogger:log_dev("Other track listen start !")
        end

    end

    -- Handle music stopping in the menu
    if event and event == "stop_all_music" then
        if COSTMusicManager.current_track then
            COSTMusicManager:stop_and_clean(false, 0)
        end
    end

end


-- Function to handle stop music preview in the loadout menu
function COSTMusicManager:track_listen_stop ()
    if COSTMusicManager.current_track then
        COSTMusicManager:stop_and_clean(true, 1)
        COSTLogger:log_dev("Track listen stop !")
    end
end


-- Fuction to handle event changing in the heist
function COSTMusicManager:post_event (event)
    -- Get the current track even without excplicit selection
    local current_track = Global.music_manager.current_track

    -- Verify that the event post should be handled
    if COSTTrackManager.custom_tracks_map[current_track] then
        -- Update the current track
        if COSTMusicManager.current_track ~= current_track then
            COSTMusicManager.current_track = current_track
        end

        -- Make the event changing
        if COSTMusicManager.events_table[event] then
            local trad_event = COSTMusicManager.events_table[event]

            if COSTMusicManager.current_event ~= trad_event then
                -- Save and update the event
                local old_event = COSTMusicManager.current_event
                COSTMusicManager.current_event = trad_event

                -- Get the current track
                local custom_track = COSTTrackManager.custom_tracks_map[COSTMusicManager.current_track]

                COSTLogger:log_dev(trad_event .. " posted !")

                if custom_track.cost_type == "CustomOSTTrack" then

                    COSTMusicManager.volume_alterators.event = 0

                    if old_event then
                        COSTMusicManager:stop_custom(custom_track:get_event_params(old_event).fade_out ~= 0, custom_track:get_event_params(old_event).fade_out)
                    end
                    COSTMusicManager:play_custom(custom_track:get_event_params(trad_event).fade_in ~= 0, custom_track:get_event_params(trad_event).fade_in, {play_start = true})

                elseif custom_track.cost_type == "CustomOSTSimpleTrack" then

                    if COSTMusicManager.current_event == "setup" then
                        COSTMusicManager.volume_alterators.event = 0.5
                    elseif COSTMusicManager.current_event == "control" then
                        COSTMusicManager.volume_alterators.event = 0.35
                    elseif COSTMusicManager.current_event == "buildup" then
                        COSTMusicManager.volume_alterators.event = 0
                    elseif COSTMusicManager.current_event == "assault" then
                        COSTMusicManager.volume_alterators.event = 0
                    end

                    if not COSTMusicManager.x_source or not COSTMusicManager.x_source._cost_buffer then
                        COSTMusicManager:play_custom(false, 0)
                    else
                        if COSTMusicManager.x_source._cost_buffer.track ~= COSTMusicManager.current_track then
                            COSTMusicManager:stop_custom(false, 0)
                            COSTMusicManager:play_custom(false, 0)
                        end
                    end

                end
            end
        else
            COSTMusicManager:stop_and_clean(true, 1)
        end
    else
        COSTMusicManager:stop_and_clean(true, 1)
    end
end


-- Function to clean track selection and stop
function COSTMusicManager:stop_and_clean (fade, fade_duration)
    if COSTMusicManager.current_track ~= nil then
        COSTMusicManager.current_event = nil
        COSTMusicManager.current_track = nil
        COSTMusicManager:stop_custom(fade, fade_duration)
    end
end


-- Function to play a custom track in the wanted event
function COSTMusicManager:play_custom (fade_in, fade_duration, flags)
    -- Ensure the flag is not nil
    flags = flags or {}

    if not COSTMusicManager.x_source or COSTMusicManager.x_source:is_closed() then
        local custom_track = COSTTrackManager.custom_tracks_map[COSTMusicManager.current_track]

        if custom_track and COSTMusicManager.current_event then
            -- Get the custom buffer and check the errors
            local cost_buffer = custom_track:get_cost_buffer(COSTMusicManager.current_event, flags.play_start == true, flags.forced)
            if not cost_buffer.error then
                if #cost_buffer.warnings > 0 then
                    local msg = "Track " .. custom_track:get_name() .. " raise warnings :\n"
                    for _, warn in pairs(cost_buffer.warnings) do
                        msg = msg .. "- " .. warn .. "\n"
                    end
                    COSTLogger:show_warn(msg)
                end

                COSTMusicManager.x_source = COSTXSource:new(cost_buffer)
                if fade_in then
                    COSTMusicManager.x_source:fade_in(fade_duration)
                end
            else
                COSTLogger:show_err(cost_buffer.error)
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
    COSTLogger:log_dev("End of the " .. event .. " start source")
    if event == COSTMusicManager.current_event then
        local forced = "main"
        if COSTMusicManager.x_source._cost_buffer.alt then
            forced = "alt"
        end
        COSTMusicManager:play_custom(false, 0, {forced = forced})
    end
end


-- Function to call every tick
function COSTMusicManager:custom_update (dt, paused)
    if not paused then

        -- Update all timers
        for name, timer in pairs(COSTMusicManager.timers) do
            if timer ~= nil then
                timer:update(dt)
            end

            if timer:is_finish() then
                COSTMusicManager.timers[name] = nil
            end
        end

    end
end


-- Get the volumae factor
function COSTMusicManager:get_volume_changer ()
    -- Get the decline factor for the bleedout state
    local decline_factor = 1
    if COSTMusicManager.timers.bleedout ~= nil then
        decline_factor = math.max(0, COSTMusicManager.timers.bleedout:get_remain_prop())
    end

    -- Get the flash factor for the flashbanged state
    local flash_factor = 1
    if COSTMusicManager.timers.flashbang ~= nil then
        flash_factor = math.max(0, COSTMusicManager.timers.flashbang:get_passed_prop())
    end

    local volume_factor = math.max(0.15, (1 - (COSTMusicManager.volume_alterators.feedback + COSTMusicManager.volume_alterators.hit + COSTMusicManager.volume_alterators.speak + COSTMusicManager.volume_alterators.event))) * decline_factor * flash_factor
    local do_inertia = flash_factor == 1
    return {volume_factor = volume_factor, do_inertia = do_inertia}
end


----- All functions above are to integrate music in the game -----


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
            elseif COSTMusicManager.current_event == "control" then
                COSTMusicManager.volume_alterators.speak = 0.65
            elseif COSTMusicManager.current_event == "buildup" then
                COSTMusicManager.volume_alterators.speak = 0.53
            elseif COSTMusicManager.current_event == "assault" then
                COSTMusicManager.volume_alterators.speak = 0.5
            end
        end
    end
end


-- Function to call when someone stop to speak
function COSTMusicManager:stop_speak ()
    COSTMusicManager.volume_alterators.speak = 0
end


-- Function to call when there is a feedback sound (gage, loot, small loot...)
function COSTMusicManager:feedback_sound ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timers.feedback = COSTTimer:new(2.5)
        COSTMusicManager.timers.feedback:set_callback(function () COSTMusicManager.volume_alterators.feedback = 0 end)
        COSTMusicManager.volume_alterators.feedback = 0.75
    end
end


-- Function to call when the player recieve a new objective
function COSTMusicManager:objective_sound ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timers.feedback = COSTTimer:new(2.9)
        COSTMusicManager.timers.feedback:set_callback(function () COSTMusicManager.volume_alterators.feedback = 0 end)
        COSTMusicManager.volume_alterators.feedback = 0.75
    end
end


-- Function to call when the player is hit
function COSTMusicManager:hit_sound ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timers.hit = COSTTimer:new(0.6)
        COSTMusicManager.timers.hit:set_callback(function () COSTMusicManager.volume_alterators.hit = 0 end)
        COSTMusicManager.volume_alterators.hit = 0.37
    end
end


-- Function to enter in the bleedout state
function COSTMusicManager:bleedout_enter ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timers.bleedout = COSTTimer:new(27)
        COSTMusicManager.timers.bleedout:set_delay(30)
    end
end


-- Function to return to the standard state
function COSTMusicManager:standard_enter ()
    if COSTMusicManager.current_track then
        COSTMusicManager.timers.bleedout = nil
    end
end


-- Function to call when the player is flashed
function COSTMusicManager:flash_grenade (sound_factor)
    if COSTMusicManager.current_track then
        COSTMusicManager.timers.flashbang = COSTTimer:new(10)
        COSTMusicManager.timers.flashbang:set_cursor(5.5 - (10 * sound_factor))
    end
end