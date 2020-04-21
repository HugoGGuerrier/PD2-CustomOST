-- This class that handle the sound source to make it more simple to manage
COSTSourceManager = {}

COSTSourceManager.x_source = nil
COSTSourceManager.buffer_queue = {}
COSTSourceManager.current_buffer = nil

-- Get the XAudio constants
COSTSourceManager.MUSIC = XAudio.Source.MUSIC
COSTSourceManager.SOUND_EFFECT = XAudio.Source.SOUND_EFFECT

-- Start an XAudio source with the wanted buffer
function COSTSourceManager:play_buffer (buffer)
    if buffer.cost_type == "CustomOSTBuffer" then

        -- TODO : Add the buffer to the buffer queue

    end
end

-- Close the current playing source
function COSTSourceManager:close ()
    COSTSourceManager:close_source(COSTSourceManager.x_source)
    COSTSourceManager.x_source = nil
    COSTSourceManager.buffer_queue = {}
end

-- Close a specified source
function COSTSourceManager:close_source (src)
    Hooks:RemovePostHook("CustomOSTXAudio" .. src._cost_event .. "Update")
    src:close()
end

-- Set the current source volume
function COSTSourceManager:set_volume (vol)
    if COSTSourceManager.x_source and COSTSourceManager.x_source:is_active() then
        COSTSourceManager.x_source:set_volume(vol)
    end
end

-- Custom function to make a fade in of a track
function COSTSourceManager:fade_in (target_vol, duration)
    if COSTSourceManager.x_source then
        COSTSourceManager:set_volume(0)
        COSTSourceManager.x_source._cost_fade_in_cursor = 0
        COSTSourceManager.x_source._cost_fade_target_volume = target_vol
        COSTSourceManager.x_source._cost_fade_in_duration = duration
    end
end

-- Custom function to make a fade out of a track
function COSTSourceManager:fade_out (duration)
    if COSTSourceManager.x_source then
        COSTSourceManager.x_source._cost_fade_out_cursor = 0
        COSTSourceManager.x_source._cost_fade_start_volume = COSTSourceManager.x_source:get_volume()
        COSTSourceManager.x_source._cost_fade_out_duration = duration
    end
end

-- Update the XAudio source
function COSTSourceManager:custom_update (src, t, dt)
    -- Fade out handling
    if src._cost_fade_out_cursor ~= nil then
        src._cost_fade_out_cursor = src._cost_fade_out_cursor + dt
        local fade_out_dif = src._cost_fade_out_duration - src._cost_fade_out_cursor

        if fade_out_dif >= 0 then
            local fade_out_factor = fade_out_dif / src._cost_fade_out_duration
            src:set_volume(src._cost_fade_start_volume * fade_out_factor)
        else
            src._cost_fade_out_cursor = nil
            src._cost_fade_out_duration = nil
            src._cost_fade_start_volume = nil
            COSTSourceManager:close_source(src)
        end
    end

    -- Fade in handling
    if src._cost_fade_in_cursor ~= nil then
        src._cost_fade_in_cursor = src._cost_fade_in_cursor + dt
        local fade_in_dif = src._cost_fade_in_duration - src._cost_fade_in_cursor

        if fade_in_dif >= 0 then
            local fade_in_factor = (src._cost_fade_in_duration - fade_in_dif) / src._cost_fade_in_duration
            src:set_volume(src._cost_fade_target_volume * fade_in_factor)
        else
            src:set_volume(src._cost_fade_target_volume)
            src._cost_fade_in_cursor = nil
            src._cost_fade_in_duration = nil
            src._cost_fade_target_volume = nil
        end
    end
end