COSTXSource = class(XAudio.Source)

-- Init the source object with a custom buffer
function COSTXSource:init (cost_buffer)
    -- Init the parent class
    XAudio.Source.init(self, cost_buffer.buffer)

    -- Set the custom attibutes
    self._cost_buffer = cost_buffer
    self._fade_in_cursor = nil
    self._fade_in_duration = nil
    self._fade_in_target = nil

    self._fade_out_cursor = nil
    self._fade_out_duration = nil
    self._fade_out_start = nil


    -- Set the parameters value
    self:set_looping(self._cost_buffer.is_looping)
    self:set_volume(self._cost_buffer.volume * COSTMusicManager.volume_factor)
    self:set_relative(true)
    self:set_single_sound(true)
    self:set_type(XAudio.Source.MUSIC)
end

function COSTXSource:track_volume ()
    return self._cost_buffer.volume
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
    self._fade_in_cursor = 0
    self._fade_in_duration = duration
    self._fade_in_target = self._cost_buffer.volume
end

function COSTXSource:fade_out (duration)
    self._fade_out_cursor = 0
    self._fade_out_start = self:get_volume()
    self._fade_out_duration = duration
end

-- Function to update the source every tick
function COSTXSource:update (t, dt, paused)
    XAudio.Source.update(self, t, dt, paused)

    -- Make the fade
    if self._fade_out_cursor then
        self._fade_out_cursor = self._fade_out_cursor + dt

        if self._fade_out_cursor < self._fade_out_duration then
            local fade_out_factor = (self._fade_out_duration - self._fade_out_cursor) / self._fade_out_duration
            self:set_volume(self._fade_out_start * fade_out_factor)
        else
            self._fade_out_cursor = nil
            self._fade_out_duration = nil
            self._fade_out_start = nil
            self:close()
        end
    else
        if self._fade_in_cursor then
            self._fade_in_cursor = self._fade_in_cursor + dt

            if self._fade_in_cursor < self._fade_in_duration then
                local fade_in_factor = self._fade_in_cursor / self._fade_in_duration
                self:set_volume(self._fade_in_target * fade_in_factor)
            else
                self:set_volume(self._fade_in_target)
                self._fade_in_cursor = nil
                self._fade_in_duration = nil
                self._fade_in_target = nil
            end
        end
    end
end