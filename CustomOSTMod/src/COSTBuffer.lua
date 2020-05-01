COSTBuffer = COSTBuffer or {}


-- Create a custom buffer with the needed informations
function COSTBuffer:create_buffer (cost_track, event, play_start)
    -- Prepare the result
    local res = {}
    res.cost_type = "CustomOSTBuffer"
    res.event = event
    res.track = cost_track.id
    
    if cost_track.cost_type == "CustomOSTTrack" then

        res.volume = cost_track.volume * cost_track.events_params[event].volume
        if play_start and cost_track.events_buffers[event].start_source_buffer then
            res.buffer = cost_track.events_buffers[event].start_source_buffer
            res.is_looping = false
            res.is_start = true
        else
            res.buffer = cost_track.events_buffers[event].source_buffer
            res.is_looping = true
            res.is_start = false
        end
        
    elseif cost_track.cost_type == "CustomOSTSimpleTrack" then

        res.volume = cost_track.volume
        res.buffer = cost_track.buffer
        res.is_looping = true
        res.is_start = false

    end

    return res
end