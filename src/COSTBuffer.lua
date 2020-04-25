COSTBuffer = COSTBuffer or {}

-- Create a custom buffer with the needed informations
function COSTBuffer:create_buffer (cost_track, event, play_start)
    local res = {}
    res.cost_type = "CustomOSTBuffer"
    res.event = event
    res.track = cost_track.id
    res.volume = cost_track.volume
    if play_start and cost_track.events_buffers[event].start_source_buffer then
        res.buffer = cost_track.events_buffers[event].start_source_buffer
        res.is_looping = false
        res.is_start = true
    else
        res.buffer = cost_track.events_buffers[event].source_buffer
        res.is_looping = true
        res.is_start = false
    end
    return res
end