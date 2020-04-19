CustomOSTTrack = {}
local C = CustomOSTTrack

function C:_init (track_obj)
    track_obj.id = nil
    track_obj._meta = "CustomOSTTrack"
    track_obj.volume = 1
    track_obj.fade_transition = false
    track_obj.name = "Default track name"
    track_obj.dir = nil
    track_obj.events = {
        setup = {
            start_source_file = nil,
            start_source_buffer = nil,
            source_file = nil,
            source_buffer = nil
        },
        control = {
            start_source_file = nil,
            start_source_buffer = nil,
            source_file = nil,
            source_buffer = nil
        },
        buildup = {
            start_source_file = nil,
            start_source_buffer = nil,
            source_file = nil,
            source_buffer = nil
        },
        assault = {
            start_source_file = nil,
            start_source_buffer = nil,
            source_file = nil,
            source_buffer = nil
        }
    }
end

-- Create a new track from a json file and the directory of this file
function C:create_from_file (track_file, dir)
    -- Init the result
    local res = {}
    C:_init(res)

    -- Check the track file existence
    if not file:FileExists(track_file) then
        CustomOSTLogger:log_err("Cannot load track from folder " .. dir .. " track.json file is missing")
        return nil
    end

    -- Load the track config
    local f = io.open(track_file, "r")
    local track_json = f:read("*all")
    local track_obj = json.decode(track_json)
    f:close()

    res.name = track_obj.name
    res.id = track_obj.id
    res.volume = track_obj.volume or 1
    res.fade_transition = track_obj.fade_transition or false
    res.dir = dir
    
    if not res.id or not res.name then
        CustomOSTLogger:log_err("Cannot load track from folder " .. dir .. " track.json file is malformed, you need at leat a 'name' and an 'id'")
        return nil
    end

    for event, sources_path in pairs(track_obj.events) do
        res.events[event].start_source_file = track_obj.events[event].start_source
        res.events[event].source_file = track_obj.events[event].source
    end
    
    if C:load_music_files(res) then
        CustomOSTLogger:dev_log(res.name .. " loaded !")
        return res
    end

    return nil
end

-- Load all the track files of the track object
function C:load_music_files (track_obj)
    for event, sources in pairs(track_obj.events) do
        -- Get the source paths
        local start_source_path = track_obj.events[event].start_source_file and track_obj.dir .. track_obj.events[event].start_source_file or nil
        local source_path = track_obj.events[event].source_file and track_obj.dir .. track_obj.events[event].source_file or nil

        -- Load the start source file in a buffer if it exists
        if start_source_path then
            if file:FileExists(start_source_path) then
                local success, start_source_buffer = pcall(function () return XAudio.Buffer:new(start_source_path) end)
                if success then
                    track_obj.events[event].start_source_buffer = start_source_buffer
                    CustomOSTLogger:dev_log("Load " .. track_obj.id .. " - " .. event .. "(start)")
                else
                    CustomOSTLogger:log_warn("File " .. start_source_path .. " is unreadable")
                end
            else
                CustomOSTLogger:log_warn("File " .. start_source_path .. " is missing")
            end
        end

        -- Try to load the main source file in a buffer
        if source_path then
            if file:FileExists(source_path) then
                local success, source_buffer = pcall(function () return XAudio.Buffer:new(source_path) end)
                if success then
                    track_obj.events[event].source_buffer = source_buffer
                    CustomOSTLogger:dev_log("Load " .. track_obj.id .. " - " .. event)
                else
                    CustomOSTLogger:log_err("File " .. source_path .. " is unreadable")
                    return false
                end
            else
                CustomOSTLogger:log_err("File " .. source_path .. " is missing")
                return false
            end
        else
            CustomOSTLogger:log_err("Track " .. track_obj.name .. " does not have source file for event " .. event .. ", you need at least one source file for each event")
            return false
        end
    end

    -- If all the sources were loaded
    return true
end