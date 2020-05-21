------ The base of all music managers ------


COSTMusicManager = COSTMusicManager or class()


-- Custructor to make general behaviors
function COSTMusicManager:init ()
    self.cost_type = "CustomOSTMusicManager"

    self._current_track = nil
    self._current_event = nil
    self._x_source = nil
    self._old_source = nil

    self._handled_events_table = {
        music_heist_setup = "setup",
        music_stealth_setup = "setup",
        suspense_1 = "setup",

        music_heist_control = "control",
        music_stealth_control = "control",
        suspense_2 = "control",

        music_heist_anticipation = "buildup",
        music_stealth_buildup = "buildup",
        suspense_3 = "buildup",
        suspense_4 = "buildup",

        music_heist_assault = "assault",
        music_stealth_assault = "assault",
        suspense_5 = "assault"
    }

    self._volume_alterators = {
        hit = 0,
        feedback = 0,
        speak = 0,
        event = 0
    }
    self._timers = {
        hit = nil,
        feedback = nil,
        bleedout = nil,
        flashbang = nil
    }
end


------ Getters and setters ------


-- Function to get the current track
function COSTMusicManager:get_current_track ()
    return self._current_track
end

-- Function to set the current track
function COSTMusicManager:set_current_track (track)
    self._current_track = track
end


-- Function to get the current event
function COSTMusicManager:get_current_event ()
    return self._current_event
end

-- Function to set the current event
function COSTMusicManager:set_current_event (event)
    self._current_event = event
end


-- Function to get the volume modificator
function COSTMusicManager:get_volume_changer ()
    -- Get the decline factor for the bleedout state
    local decline_factor = 1
    if self._timers.bleedout ~= nil then
        decline_factor = math.max(0, self._timers.bleedout:get_remain_prop())
    end

    -- Get the flash factor for the flashbanged state
    local flash_factor = 1
    if self._timers.flashbang ~= nil then
        flash_factor = math.max(0, self._timers.flashbang:get_passed_prop())
    end

    local volume_factor = math.max(0.15, (1 - (self._volume_alterators.hit + self._volume_alterators.feedback + self._volume_alterators.speak + self._volume_alterators.event))) * decline_factor * flash_factor
    local do_inertia = flash_factor == 1

    return {volume_factor = volume_factor, do_inertia = do_inertia}
end


------ Default Music manager bindings ------


-- Function when a track preview start
function COSTMusicManager:track_listen_start (event, track)
    -- If there is a track
    if track and event then

        local custom_track = CustomOST.track_manager:get_track(track)

        if custom_track then
            if self._current_track ~= track or self._current_event ~= event then
                -- Update the current state
                self._current_track = track
                self._current_event = event

                -- Stop all other music
                Global.music_manager.source:stop()
                self:stop_custom(false, 0)

                -- Play the custom music
                self:play_custom(false, 0, {forced = "main"})
                COSTLogger:log_dev("Custom track listen start " .. custom_track:get_id() .. " - " .. event)
            end
        else
            -- Stop the custom track
            self._current_track = nil
            self._current_event = nil
            self:stop_custom(false, 0)
            COSTLogger:log_dev("Build-in track listen start")
        end

    elseif event and event == "stop_all_music" then

        -- Stop the current track
        if self._current_track and self._current_event then
            self._current_track = nil
            self._current_event = nil
            self:stop_custom(false, 0)
        end

    end
end


-- Function when a track preview stop
function COSTMusicManager:track_listen_stop ()
    if self._current_track and self._current_event then
        self._current_track = nil
        self._current_event = nil
        self:stop_custom(true, 1)
        COSTLogger:log_dev("Custom track listen stop")
    end
end


-- Function when a event is posted, used to dispatch and choose the right behavior
function COSTMusicManager:post_event (event)
    -- Get the current track
    local current_track_id = Global.music_manager.current_track or Global.music_manager.current_music_ext
    local current_track = CustomOST.track_manager:get_track(current_track_id)

    -- If the current track is a custom track
    if current_track then

        -- Set the current track
        if self._current_track ~= current_track:get_id() then
            self._current_track = current_track:get_id()
        end

        -- If the event is handled by Custom OST
        if self._handled_events_table[event] then

            -- Handle the event changing for each type of track
            if self._current_event ~= event then
                COSTLogger:log_dev("Event posted : " .. event)
                if current_track.cost_type == "CustomOSTSimpleTrack" then
                    self:post_event_simple(event)
                elseif current_track.cost_type == "CustomOSTTrack" then
                    self:post_event_standard(event)
                else
                    COSTLogger:log_err("Unknow track type : " .. current_track.cost_type .. " - " .. current_track:get_id())
                end
            end

        elseif event ~= nil then

            -- Stop the current custom track
            self._current_track = nil
            self._current_event = nil
            self:stop_custom(true, 0)

        end

    else
        -- Stop the custom track playing
        self._current_track = nil
        self._current_event = nil
        self:stop_custom(true, 1)
    end
end


function COSTMusicManager:post_event_simple (event)
    -- Set the event volume modificator
    if event == "music_heist_setup" then
        self._volume_alterators.event = 0.5
    elseif event == "music_heist_control" then
        self._volume_alterators.event = 0.35
    elseif event == "music_heist_anticipation" then
        self._volume_alterators.event = 0.1
    elseif event == "music_heist_assault" then
        self._volume_alterators.event = 0
    end

    -- Change the current event
    self._current_event = event

    -- Play the custom track
    if not self._x_source then
        self:play_custom(false, 0)
    elseif self._x_source._cost_buffer.track ~= self._current_track then
        self:stop_custom(false, 0)
        self:play_custom(false, 0)
    end
end


function COSTMusicManager:post_event_standard (event)
    -- Reset the event volume modificator
    self._volume_alterators.event = 0

    -- Change the current event
    local old_event = self._handled_events_table[self._current_event]
    self._current_event = event
    local trad_event = self._handled_events_table[self._current_event]

    local custom_track = CustomOST.track_manager:get_track(self._current_track)

    if old_event then
        self:stop_custom(custom_track:get_event_params(old_event).fade_out ~= 0, custom_track:get_event_params(old_event).fade_out)
    end
    self:play_custom(custom_track:get_event_params(trad_event).fade_in ~= 0, custom_track:get_event_params(trad_event).fade_in, {play_start = true})
end


------ Custom Music manager functions ------


-- Function to start a custom music
function COSTMusicManager:play_custom (fade_in, fade_duration, flags)
    -- Ensure the flag is not nil
    flags = flags or {}

    if not COSTMusicManager.x_source or COSTMusicManager.x_source:is_closed() then
        local custom_track = CustomOST.track_manager:get_track(self._current_track)
        local trad_event = self._handled_events_table[self._current_event]

        -- Verify the current track and event
        if custom_track and trad_event then
            local cost_buffer = custom_track:get_cost_buffer(trad_event, flags.play_start == true, flags.forced)
            if not cost_buffer.error then
                -- Show the warnings
                if #cost_buffer.warnings > 0 then
                    local msg = "Track " .. custom_track:get_name() .. " raise warnings :\n"
                    for _, warn in pairs(cost_buffer.warnings) do
                        msg = msg .. "- " .. warn .. "\n"
                    end
                    COSTLogger:show_warn(msg)
                end

                -- Set the cost buffer event
                cost_buffer.event = self._current_event

                -- Start the buffer
                self._x_source = COSTXSource:new(cost_buffer)
                if fade_in then
                    self._x_source:fade_in(fade_duration)
                end

                local precisions = " "
                if cost_buffer.is_start then precisions = precisions .. "(start) " end
                if cost_buffer.alt then precisions = precisions .. "(alt) " end

                COSTLogger:log_dev("Custom buffer started : " .. cost_buffer.track .. precisions .. "- " .. cost_buffer.event)
            else
                COSTLogger:show_err(cost_buffer.error)
            end
        else
            COSTLogger:log_err("Trying to play a custom track with values current_event=" .. (self._current_event or "nil") .. " current_track=" .. (self._current_track or "nil"))
        end
    end
end


-- Function to stop a custom music
function COSTMusicManager:stop_custom (fade_out, fade_duration)
    if self._x_source then
        if fade_out then
            self._x_source:fade_out(fade_duration)
        else
            self._x_source:close()
        end
        self._x_source = nil
    end
end


-- Function to signal the end of a start track
function COSTMusicManager:start_finish (event)
    if event == self._current_event then
        local s_forced = nil
        if self._x_source._cost_buffer.alt == true then
            s_forced = "alt"
        elseif self._x_source._cost_buffer.alt == false then
            s_forced = "main"
        end
        self:play_custom(false, 0, {forced = s_forced})
    end
end


------ Dynamic music integration system ------


-- Function to update the timers
function COSTMusicManager:custom_update (dt, paused)
    if not paused then

        -- Update all timers
        for name, timer in pairs(self._timers) do
            if timer ~= nil then
                timer:update(dt)
            end

            if timer:is_finish() then
                self._timers[name] = nil
            end
        end

    end
end


-- Function to call when someone talk in the preplanning
function COSTMusicManager:speak_planning ()
    self._volume_alterators.speak = 0.6
end


-- Function to call when the operator talk during the event
function COSTMusicManager:speak_mission ()
    if self._current_track and self._current_event then
        if self._current_event == "music_heist_setup" or self._current_event == "suspense_1" or self._current_event == "suspense_2" or self._current_event == "suspense_3" or self._current_event == "suspense_4" or self._current_event == "suspense_5" then
            self._volume_alterators.speak = 0.7
        elseif self._current_event == "music_heist_control" then
            self._volume_alterators.speak = 0.65
        elseif self._current_event == "music_heist_anticipation" then
            self._volume_alterators.speak = 0.53
        elseif self._current_event == "music_heist_assault" then
            self._volume_alterators.speak = 0.49
        end
    end
end


-- Function to call when someone stop to talk
function COSTMusicManager:stop_speak ()
    self._volume_alterators.speak = 0
end


-- Function to call when there is a feedback stinger
function COSTMusicManager:feedback_sound ()
    if self._current_track then
        self._timers.feedback = COSTTimer:new(2.5)
        self._timers.feedback:set_callback(function () self._volume_alterators.feedback = 0 end)
        self._volume_alterators.feedback = 0.75
    end
end


-- Function to call when a new objective is added
function COSTMusicManager:objective_sound ()
    if self._current_track then
        self._timers.feedback = COSTTimer:new(2.9)
        self._timers.feedback:set_callback(function () self._volume_alterators.feedback = 0 end)
        self._volume_alterators.feedback = 0.75
    end
end


-- Function to call when the player is hit
function COSTMusicManager:hit_sound ()
    if self._current_track then
        self._timers.hit = COSTTimer:new(0.6)
        self._timers.hit:set_callback(function () self._volume_alterators.hit = 0 end)
        self._volume_alterators.hit = 0.34
    end
end


-- Function to call when the player is flashed
function COSTMusicManager:flash_grenade (flash_factor)
    if self._current_track then
        self._timers.flashbang = COSTTimer:new(10)
        self._timers.flashbang:set_cursor(5.5 - (10 * flash_factor))
    end
end


-- Function to call when the player enter in bleedout state
function COSTMusicManager:bleedout_enter ()
    if self._current_track then
        self._timers.bleedout = COSTTimer:new(27)
        self._timers.bleedout:set_delay(10)
    end
end


-- Function to call when the player enter in the standard state
function COSTMusicManager:standard_enter ()
    if self._current_track then
        self._timers.bleedout = nil
    end
end