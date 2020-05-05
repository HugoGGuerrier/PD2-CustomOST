------ Class that is the base of all track type to abstract music playing ------


COSTTrackBase = COSTTrackBase or class()


-- Construcor
function COSTTrackBase:init ()
    self.cost_type = "CustomOSTTrackBase"
    self._id = nil
    self._name = "Default track name"
    self._volume = 1
    self._dir = nil
    self._error = nil
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


-- Function to get directory
function COSTTrackBase:get_dir ()
    return self._dir
end

-- Function to set directory
function COSTTrackBase:set_dir (dir)
    self._dir = dir
end


-- Function to get error
function COSTTrackBase:get_error ()
    return self._error
end

-- Function to set the error
function COSTTrackBase:set_error (error)
    self._error = self._error or error
end


-- Function to override
function COSTTrackBase:is_valid ()
    COSTLogger:log_warn("Hey dev, you must override the is_valid method !!!")
end

-- Function to override
function COSTTrackBase:get_cost_buffer (event, play_start)
    COSTLogger:log_warn("Hey dev, you must override the get_cost_buffer method !!!")
end

-- Function to override
function COSTTrackBase:load_files ()
    COSTLogger:log_warn("Hey dev, you must override the load_files method !!!")
end