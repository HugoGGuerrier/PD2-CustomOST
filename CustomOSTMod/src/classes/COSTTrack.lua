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
            alt_start_source_file = nil,
            source_file = nil,
            alt_source_file = nil
        },
        control = {
            start_source_file = nil,
            alt_start_source_file = nil,
            source_file = nil,
            alt_source_file = nil
        },
        buildup = {
            start_source_file = nil,
            alt_start_source_file = nil,
            source_file = nil,
            alt_source_file = nil
        },
        assault = {
            start_source_file = nil,
            alt_start_source_file = nil,
            source_file = nil,
            alt_source_file = nil
        }
    }
    self._events_params = {
        setup = {
            volume = 1,
            fade_in = nil,
            fade_out = nil,
            alt_chance = nil
        },
        control = {
            volume = 1,
            fade_in = nil,
            fade_out = nil,
            alt_chance = nil
        },
        buildup = {
            volume = 1,
            fade_in = nil,
            fade_out = nil,
            alt_chance = nil
        },
        assault = {
            volume = 1,
            fade_in = nil,
            fade_out = nil,
            alt_chance = nil
        }
    }
    self._events_buffers = {
        setup = {
            start_source_buffer = nil,
            alt_start_source_buffer = nil,
            source_buffer = nil,
            alt_source_buffer = nil
        },
        control = {
            start_source_buffer = nil,
            alt_start_source_buffer = nil,
            source_buffer = nil,
            alt_source_buffer = nil
        },
        buildup = {
            start_source_buffer = nil,
            alt_start_source_buffer = nil,
            source_buffer = nil,
            alt_source_buffer = nil
        },
        assault = {
            start_source_buffer = nil,
            alt_start_source_buffer = nil,
            source_buffer = nil,
            alt_source_buffer = nil
        }
    }
end


-- Function to get an event files
function COSTTrack:get_event_files (event)
    return self._events_files[event]
end

-- Function to set an event file
function COSTTrack:set_event_file (event, file)
    if self._events_files[event] then
        self._events_files[event].source_file = file
    end
end

-- Function to set an event alt file
function COSTTrack:set_event_alt_file (event, file)
    if self._events_files[event] then
        self._events_files[event].alt_source_file = file
    end
end

-- Function to set an event start file
function COSTTrack:set_event_start_file (event, start_file)
    if self._events_files[event] then
        self._events_files[event].start_source_file = start_file
    end
end

-- Function to set an event alt start file
function COSTTrack:set_event_alt_start_file (event, start_file)
    if self._events_files[event] then
        self._events_files[event].alt_start_source_file = start_file
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

-- Function to set the alt chance
function COSTTrack:set_event_alt_chance (event, chance)
    if self._events_params[event] then
        self._events_params[event].alt_chance = chance
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
        local start_source_path = files.start_source_file and self._dir .. files.start_source_file
        local alt_start_source_path = files.alt_start_source_file and self._dir .. files.alt_start_source_file
        local source_path = files.source_file and self._dir .. files.source_file
        local alt_source_path = files.alt_source_file and self._dir .. files.alt_source_file

        -- Verify the start source file
        if start_source_path then
            if not file.FileExists(start_source_path) then
                self:add_warning("Start file " .. start_source_path .. " is missing or unreadable")
                self._events_files[event].start_source_file = nil
            end
        end

        -- Verify the alt start source file
        if alt_start_source_path then
            if not file.FileExists(alt_start_source_path) then
                self:add_warning("Alt start file " .. alt_start_source_path .. " is missing or unreadable")
                self._events_files[event].alt_start_source_file = nil
            end
        end

        -- Verify the source file
        if source_path then
            if not file.FileExists(source_path) then
                self:set_error("File " .. source_path .. " is missing or unreadable")
            end
        else
            self:set_error("Track " .. self._name .. " does not have source file for event " .. event .. ", you need at least one source file for each event")
        end

        -- Verify the alt source file
        if alt_source_path then
            if not file.FileExists(alt_source_path) then
                self:add_warning("Alt file " .. alt_source_path .. " is missing or unreadable")
                self._events_files[event].alt_source_file = nil
            end
        end
    end

    -- Return that the track can be displayed
    return true
end

-- (Override) Function to get the cost buffer of an event
function COSTTrack:get_cost_buffer (event, play_start, forced)
    -- Init the result
    local res = {}
    res.cost_type = "CustomOSTBuffer"
    res.event = event
    res.track = self._id
    res.volume = self._volume * self._events_params[event].volume

    -- Load the files if they were not loaded before
    if not self._loaded then
        self:load_files()
    end

    -- Get a random to choose the alt or the main and prepare the default buffer settings
    local alt_rand = math.random()

    local buffer_to_return = "source_buffer"
    res.alt = nil
    res.is_looping = true
    res.is_start = false

    if self._events_buffers[event].alt_source_buffer then
        if forced ~= "main" and (alt_rand <= self._events_params[event].alt_chance or forced == "alt") then
            buffer_to_return = "alt_source_buffer"
        end
    end

    if play_start then

        if self._events_buffers[event].start_source_buffer then
            buffer_to_return = "start_source_buffer"

            res.is_looping = false
            res.is_start = true
        end

        if self._events_buffers[event].alt_start_source_buffer then
            if forced ~= "main" and (alt_rand <= self._events_params[event].alt_chance or forced == "alt") then
                buffer_to_return = "alt_start_source_buffer"

                res.alt = true
                res.is_looping = false
                res.is_start = true
            else
                res.alt = false
            end
        end

    end

    res.buffer = self._events_buffers[event][buffer_to_return]
    res.warnings = self._warnings
    res.error = self._error
    return res
end

-- (Override) Function to load the files into the buffers
function COSTTrack:load_files ()
    if not self._error then

        for event, files in pairs(self._events_files) do
            local start_source_path = files.start_source_file and self._dir .. files.start_source_file
            local alt_start_source_path = files.alt_start_source_file and self._dir .. files.alt_start_source_file
            local source_path = files.source_file and self._dir .. files.source_file
            local alt_source_path = files.alt_source_file and self._dir .. files.alt_source_file

            -- Load the start source file
            if start_source_path then
                if file.FileExists(start_source_path) then
                    local valid, buffer = pcall(function () return XAudio.Buffer:new(start_source_path) end)
                    if valid then
                        self._events_buffers[event].start_source_buffer = buffer
                        COSTLogger:log_dev("Load " .. self._id .. " - " .. event .. " (start)")
                    else
                        self:add_warning("File " .. start_source_path .. " cannot be loaded into a buffer")
                    end
                end
            end

            -- Load the alt start source file
            if alt_start_source_path then
                if file.FileExists(alt_start_source_path) then
                    local valid, buffer = pcall(function () return XAudio.Buffer:new(alt_start_source_path) end)
                    if valid then
                        self._events_buffers[event].alt_start_source_buffer = buffer
                        COSTLogger:log_dev("Load " .. self._id .. " - " .. event .. " (alt start)")
                    else
                        self:add_warning("File " .. alt_start_source_path .. " cannot be loaded into a buffer")
                    end
                end
            end

            -- Load the source file
            if source_path then
                if file.FileExists(source_path) then
                    local valid, buffer = pcall(function () return XAudio.Buffer:new(source_path) end)
                    if valid then
                        self._events_buffers[event].source_buffer = buffer
                        COSTLogger:log_dev("Load " .. self._id .. " - " .. event)
                    else
                        self:set_error("Cannot load the file " .. source_path .. ", please verify the file integrity")
                    end
                end
            end

            -- Load the alt source file
            if alt_source_path then
                if file.FileExists(alt_source_path) then
                    local valid, buffer = pcall(function () return XAudio.Buffer:new(alt_source_path) end)
                    if valid then
                        self._events_buffers[event].alt_source_buffer = buffer
                        COSTLogger:log_dev("Load " .. self._id .. " - " .. event .. " (alt)")
                    else
                        self:add_warning("File " .. alt_source_path .. " cannot be loaded into a buffer")
                    end
                end
            end
        end

    end

    -- Log the loading success
    self._loaded = true
    COSTLogger:log_dev(self._id .. " loaded !")
end