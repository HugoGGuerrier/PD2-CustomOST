-- This class helps in the source manipulation
CustomOSTXSource = {}
local C = CustomOSTXSource

-- Get the XAudio constants
C.MUSIC = XAudio.Source.MUSIC
C.SOUND_EFFECT = XAudio.Source.SOUND_EFFECT

-- Get an XAudio source with the wanted hook to handle actions
function C:create_source (buffer, event)
    res = XAudio.Source:new(buffer)

    res._cost_meta = "CustomOSTXSourceInstance"
    res._cost_fade_in_cursor = nil
    res._cost_fade_in_duration = nil
    res._cost_fade_out_cursor = nil
    res._cost_fade_out_duration = nil

    res._cost_fade_start_volume = nil
    res._cost_fade_target_volume = nil

    res._cost_event = event
    
    -- Create the hook to make custom update
    Hooks:PostHook(res, "update", "CustomOSTXAudio" .. res._cost_event .. "Update", function (self, t, dt)
        C:custom_update(self, t, dt)
    end)
    
    return res
end

-- Close a source and delete the hook
function C:close_source (src)
    if src._cost_meta == "CustomOSTXSourceInstance" then
        Hooks:RemovePostHook("CustomOSTXAudio" .. src._cost_event .. "Update")
        src:close()
    end
end

-- Custom function to make a fade in of a track
function C:fade_in (src, target_vol, duration)
    src:set_volume(0)
    src._cost_fade_in_cursor = 0
    src._cost_fade_target_volume = target_vol
    src._cost_fade_in_duration = duration
end

-- Custom function to make a fade out of a track
function C:fade_out (src, duration)
    src._cost_fade_out_cursor = 0
    src._cost_fade_start_volume = src:get_volume()
    src._cost_fade_out_duration = duration
end

-- Update the XAudio source
function C:custom_update (self, t, dt)
    -- Fade out handling
    if self._cost_fade_out_cursor ~= nil then
        self._cost_fade_out_cursor = self._cost_fade_out_cursor + dt
        local fade_out_dif = self._cost_fade_out_duration - self._cost_fade_out_cursor

        if fade_out_dif >= 0 then
            local fade_out_factor = fade_out_dif / self._cost_fade_out_duration
            self:set_volume(self._cost_fade_start_volume * fade_out_factor)
        else
            self._cost_fade_out_cursor = nil
            self._cost_fade_out_duration = nil
            self._cost_fade_start_volume = nil
            C:close_source(self)
        end
    end

    -- Fade in handling
    if self._cost_fade_in_cursor ~= nil then
        self._cost_fade_in_cursor = self._cost_fade_in_cursor + dt
        local fade_in_dif = self._cost_fade_in_duration - self._cost_fade_in_cursor

        if fade_in_dif >= 0 then
            local fade_in_factor = (self._cost_fade_in_duration - fade_in_dif) / self._cost_fade_in_duration
            self:set_volume(self._cost_fade_target_volume * fade_in_factor)
        else
            self._cost_fade_in_cursor = nil
            self._cost_fade_in_duration = nil
            self:set_volume(self._cost_fade_target_volume)
            self._cost_fade_target_volume = nil
        end
    end
end