------ The class of the standard Custom OST track ------


COSTTrack = COSTTrack or class(COSTTrackBase)


-- Constructor
function COSTTrack:init ()
    -- Super init
    COSTTrackBase.init(self)

    self.cost_type = "CustomOSTTrack"

    -- Init specific attributes
    self._events_files = {
        setup = {
            start_source_file = nil,
            source_file = nil,
        },
        control = {
            start_source_file = nil,
            source_file = nil,
        },
        buildup = {
            start_source_file = nil,
            source_file = nil,
        },
        assault = {
            start_source_file = nil,
            source_file = nil,
        }
    }
    self._events_params = {
        setup = {
            volume = 1,
            fade_in = nil,
            fade_out = nil
        },
        control = {
            volume = 1,
            fade_in = nil,
            fade_out = nil
        },
        buildup = {
            volume = 1,
            fade_in = nil,
            fade_out = nil
        },
        assault = {
            volume = 1,
            fade_in = nil,
            fade_out = nil
        }
    }
    self._events_buffers = {
        setup = {
            start_source_buffer = nil,
            source_buffer = nil
        },
        control = {
            start_source_buffer = nil,
            source_buffer = nil
        },
        buildup = {
            start_source_buffer = nil,
            source_buffer = nil
        },
        assault = {
            start_source_buffer = nil,
            source_buffer = nil
        }
    }
end


-- Function to get an event files
function COSTTrack:get_event_files (event)
    return self._events_files[event]
end

-- Function to set an event file
function COSTTrack:set_event_file (event, file)
    if self._events_files [event] then
        self._events_files[event].source_file = file
    end
end

-- Function to set an event start file
function COSTTrack:set_event_start_file (event, start_file)
    if self._events_files [event] then
        self._events_files[event].start_source_file = start_file
    end
end


-- Function to get an event params
function COSTTrack:get_event_params (event)
    return self._events_params[event]
end

-- Function to set event volume
function COSTTrack:set_event_volume (event, volume)
    if self._events_params[event] then
        self._events_params[event].volume = volume
    end
end

-- Function to set event fade in
function COSTTrack:set_event_fade_in (event, fade_in)
    if self._events_params[event] then
        self._events_params[event].fade_in = fade_in
    end
end

-- Function to set event fade out
function COSTTrack:set_event_fade_out (event, fade_out)
    if self._events_params[event] then
        self._events_params[event].fade_out = fade_out
    end
end


-- Function to get event buffers
function COSTTrack:get_event_buffers (event)
    return self._events_buffers[event]
end


-- (Override) Function to test the source files
function COSTTrack:is_valid ()
    -- Verify the id
    if not self._id then
        return false
    end

    -- Verify the track name
    if not self._name then
        return false
    end

    -- Verify all the music files and return true because we want to display error messages
    for event, files in pairs(self._events_files) do
        local source_path = files.source_file and self._dir .. files.source_file

        if source_path then
            if not file.FileExists(source_path) then
                self:set_error("File " .. source_path .. " is missing or unreadable")
                return true
            end
        else
            self:set_error("Track " .. self._name .. " does not have source file for event " .. event .. ", you need at least one source file for each event")
            return true
        end
    end

    -- Return that the track can be displayed
    return true
end

-- (Override) Function to get the cost buffer of an event
function COSTTrack:get_cost_buffer (event, play_start)
    -- Init the result
    local res = {}
    res.cost_type = "CustomOSTBuffer"
    res.event = event
    res.track = self._id
    res.volume = self._volume * self._events_params[event].volume

    if play_start and self._events_files[event].start_source_file then

        if not self._events_buffers[event].start_source_buffer then
            if not self._error then

                if COSTConfig.dynamic_load then
                    self:load_files()
                else
                    local start_source_path = self._dir .. self._events_files[event].start_source_file
                    local valid, buffer = pcall(function () return XAudio.Buffer:new(start_source_path) end)
                    if valid then
                        self._events_buffers[event].start_source_buffer = buffer
                    else
                        self:set_error("Cannot load the file " .. start_source_path .. ", please verify the file integrity")
                    end
                end
                
            end
        end
        res.buffer = self._events_buffers[event].start_source_buffer
        res.is_looping = false
        res.is_start = true

    else

        if not self._events_buffers[event].source_buffer then
            if not self._error then

                if COSTConfig.dynamic_load then
                    self:load_files()
                else
                    local source_path = self._dir .. self._events_files[event].source_file
                    local valid, buffer = pcall(function () return XAudio.Buffer:new(source_path) end)
                    if valid then
                        self._events_buffers[event].source_buffer = buffer
                    else
                        self:set_error("Cannot load the file " .. source_path .. ", please verify the file integrity")
                    end
                end

            end
        end
        res.buffer = self._events_buffers[event].source_buffer
        res.is_looping = true
        res.is_start = false

    end

    res.error = self._error
    return res
end

-- (Override) Function to load the files into the buffers
function COSTTrack:load_files ()
    for event, files in pairs(self._events_files) do
        local start_source_path = files.start_source_file and self._dir .. files.start_source_file
        local source_path = files.source_file and self._dir .. files.source_file

        -- Load the start source file
        if start_source_path then
            if file.FileExists(start_source_path) then
                local valid, buffer = pcall(function () return XAudio.Buffer:new(start_source_path) end)
                if valid then
                    self._events_buffers[event].start_source_buffer = buffer
                    COSTLogger:dev_log("Load " .. self._id .. " - " .. event .. " (start)")
                else
                    COSTLogger:log_warn("File " .. start_source_path .. " cannot be loaded into a buffer")
                end
            else
                COSTLogger:log_warn("File " .. start_source_path .. " is missing or unreadable")
            end
        end

        -- Load the source file
        if source_path then
            if file.FileExists(source_path) then
                local valid, buffer = pcall(function () return XAudio.Buffer:new(source_path) end)
                if valid then
                    self._events_buffers[event].source_buffer = buffer
                    COSTLogger:dev_log("Load " .. self._id .. " - " .. event)
                else
                    self:set_error("Cannot load the file " .. source_path .. ", please verify the file integrity")
                end
            end
        end
    end

    -- Log the loading success
    COSTLogger:dev_log(self._id .. " loaded !")
end