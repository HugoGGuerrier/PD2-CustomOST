------ Class which inherits from the XAudio source to make custom music playing ------


COSTXSource = class(XAudio.Source)

-- Init the source object with a custom buffer
function COSTXSource:init (cost_buffer)
    -- Init the parent class
    XAudio.Source.init(self, cost_buffer.buffer)

    -- Set the custom attibutes
    self._cost_buffer = cost_buffer

    self._fade_in_timer = nil
    self._fade_in_target = nil

    self._fade_out_timer = nil
    self._fade_out_start = nil

    self._volume_inertia = 0.6

    -- Set the parameters value
    self:set_looping(self._cost_buffer.is_looping)
    self:set_volume(self._cost_buffer.volume * COSTMusicManager:get_volume_changer().volume_factor)
    self:set_relative(true)
    self:set_single_sound(true)
    self:set_type(XAudio.Source.MUSIC)
end

-- Function to close the source
function COSTXSource:close ()
    XAudio.Source.close(self)

    -- Check is the buffer is a start
    if self._cost_buffer.is_start then
        COSTMusicManager:start_finish(self._cost_buffer.event)
    end
end

-- Make a fade in with the music
function COSTXSource:fade_in (duration)
    self:set_volume(0)
    self._fade_in_timer = COSTTimer:new(duration)
    self._fade_in_target = self._cost_buffer.volume
end

function COSTXSource:fade_out (duration)
    self._fade_out_timer = COSTTimer:new(duration)
    self._fade_out_start = self:get_volume()
end

-- Function to update the source every tick
function COSTXSource:update (t, dt, paused)
    XAudio.Source.update(self, t, dt, paused)

    -- Call the music manager update
    COSTMusicManager:custom_update(dt, paused)

    -- Process the fades
    if self._fade_out_timer then

        self._fade_out_timer:update(dt)

        if not self._fade_out_timer:is_finish() then
            self:set_volume((self._fade_out_start * self._fade_out_timer:get_remain_prop()) * COSTMusicManager:get_volume_changer().volume_factor)
        else
            self._fade_out_timer = nil
            self._fade_out_start = nil
            self:close()
        end

    elseif self._fade_in_timer then

        self._fade_in_timer:update(dt)

        if not self._fade_in_timer:is_finish() then
            self:set_volume((self._fade_in_target * self._fade_in_timer:get_passed_prop()) * COSTMusicManager:get_volume_changer().volume_factor)
        else
            self:set_volume(self._fade_in_target * COSTMusicManager:get_volume_changer().volume_factor)
            self._fade_in_timer = nil
            self._fade_in_target = nil
        end

    else

        -- Make the sound dynamic volume changing
        local volume_changer = COSTMusicManager:get_volume_changer()
        local target_volume = self._cost_buffer.volume * volume_changer.volume_factor
        local current_volume = self:get_volume()

        if target_volume ~= current_volume then

            if volume_changer.do_inertia then

                -- Make the inertia effect
                local volume_to_add = (dt / self._volume_inertia) * self._cost_buffer.volume
                if target_volume > current_volume then
                    if target_volume <= (current_volume + volume_to_add) then
                        self:set_volume(target_volume)
                    else
                        self:set_volume(current_volume + volume_to_add)
                    end
                else
                    if target_volume >= (current_volume - volume_to_add) then
                        self:set_volume(target_volume)
                    else
                        self:set_volume(current_volume - volume_to_add)
                    end
                end

            else

                -- Avoid the inertia for flashbang
                self:set_volume(target_volume)

            end

        end
        
    end
end