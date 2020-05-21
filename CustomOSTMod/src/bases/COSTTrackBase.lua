------ Class that is the base of all track type to abstract music playing ------


COSTTrackBase = COSTTrackBase or class()


-- Construcor
function COSTTrackBase:init ()
    self.cost_type = "CustomOSTTrackBase"
    self._id = nil
    self._name = nil
    self._volume = 1
    self._context = nil
    self._dir = nil
    self._error = nil
    self._warnings = {}
    self._loaded = false
end


-- Function to get the id
function COSTTrackBase:get_id ()
    return self._id
end

-- Function to set id
function COSTTrackBase:set_id (id)
    self._id = id
end


-- Function to get name
function COSTTrackBase:get_name ()
    return self._name
end

-- Function to set name
function COSTTrackBase:set_name (name)
    self._name = name
end


-- Function to get volume
function COSTTrackBase:get_volume ()
    return self._volume
end

-- Function to set volume
function COSTTrackBase:set_volume (volume)
    if volume <= 1 and volume >= 0 then
        self._volume = volume
    end
end


-- Function to test a context
function COSTTrackBase:get_context ()
    return self._context
end

-- Function to add a context
function COSTTrackBase:set_context (context)
    if context then
        self._context = context
    end
end


-- Function to get directory
function COSTTrackBase:get_dir ()
    return self._dir
end

-- Function to set directory
function COSTTrackBase:set_dir (dir)
    self._dir = dir
end


--Function to get the warnings
function COSTTrackBase:get_warnings()
    return self._warnings
end

-- Function to add a warning to display
function COSTTrackBase:add_warning (msg)
    table.insert(self._warnings, msg)
end


-- Function to get error
function COSTTrackBase:get_error ()
    return self._error
end

-- Function to set the error
function COSTTrackBase:set_error (msg)
    self._error = self._error or msg
end


-- Function to get if the track was loaded
function COSTTrackBase:is_loaded ()
    return self._loaded
end


-- Function to override
function COSTTrackBase:is_valid ()
    COSTLogger:log_warn("Unoverriden method : COSTTrackBase:is_valid")
end

-- Function to override
function COSTTrackBase:get_cost_buffer (event, play_start, forced)
    COSTLogger:log_warn("Unoverriden method : COSTTrackBase:get_cost_buffer")
end

-- Function to override
function COSTTrackBase:load_files ()
    COSTLogger:log_warn("Unoverriden method : COSTTrackBase:load_files")
end