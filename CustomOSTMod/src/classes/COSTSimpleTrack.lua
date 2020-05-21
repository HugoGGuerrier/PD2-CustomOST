------ The class of simple Custom OST track that are made from only one file ------


COSTSimpleTrack = COSTSimpleTrack or class(COSTTrackBase)


-- Constructor
function COSTSimpleTrack:init ()
    -- Super init
    COSTTrackBase.init(self)

    self.cost_type = "CustomOSTSimpleTrack"

    -- Init specific attributes
    self._file = nil
    self._buffer = nil
end


-- Function to get the track file
function COSTSimpleTrack:get_file ()
    return self._file
end

-- Function to set the file
function COSTSimpleTrack:set_file (file)
    self._file = file
end


-- Function to get the track buffer
function COSTSimpleTrack:get_buffer ()
    return self._buffer
end


-- (Override) Function to test the track file
function COSTSimpleTrack:is_valid ()
    -- Verify the id
    if not self._id then
        return false
    end

    -- Verify the track name
    if not self._name then
        return false
    end

    -- Verify the music file and return true to display error messages
    if self._file and self._dir then
        local source_path = self._dir .. self._file
        if not file.FileExists(source_path) then
            self:set_error("File " .. source_path .. " is missing or unreadable")
        end
    else
        self:set_error(self._name .. " source file or directory does not exists")
    end

    -- Return that the track is valid
    return true
end

-- (Override) Function to get the cost buffer
function COSTSimpleTrack:get_cost_buffer (event, _, _)
    -- Prepare the result
    local res = {}
    res.cost_type = "CustomOSTBuffer"
    res.track = self._id
    res.volume = self._volume
    res.is_looping = true
    res.is_start = false
    res.alt = false

    if not self._loaded then
        self:load_files()
    end
    res.buffer = self._buffer

    res.warnings = self._warnings
    res.error = self._error
    return res
end

-- (Override) Function to load the file
function COSTSimpleTrack:load_files ()
    if self._file then
        local source_path = self._dir .. self._file
        if file.FileExists(source_path) then
            local valid, buffer = pcall(function () return XAudio.Buffer:new(source_path) end)
            if valid then
                self._buffer = buffer
                COSTLogger:log_dev("Load " .. self._id .. " (simple track)")
            else
                self:set_error("Cannot load the file " .. source_path .. ", please verify the file integrity")
            end
        end
    end

    -- Log the loading success
    self._loaded = true
    COSTLogger:log_dev(self._id .. " loaded ! (simple track)")
end