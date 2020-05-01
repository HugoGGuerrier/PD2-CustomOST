COSTTimer = COSTTimer or class()


-- Init a new timer with the wanted duration
function COSTTimer:init (duration)
    self.cost_type = "CustomOSTTimer"
    self._duration = duration
    self._cursor = 0
    self._delay = 0
    self._clbk = nil
end


-- Function to set the cursor to a wanted value
function COSTTimer:set_cursor (cursor)
    self._cursor = cursor
end


-- Function to add a callback function when the timer is done
function COSTTimer:set_callback (clbk)
    self._clbk = clbk
end


-- Function to set the delay before the timer is concidered as finish
function COSTTimer:set_delay (delay)
    self._delay = delay
end


-- Function to call to update the timer
function COSTTimer:update (dt)
    self._cursor = self._cursor + dt

    if self._clbk ~= nil then
        if self._cursor >= self._duration then
            self._clbk()
        end
    end
end


-- Get if the timer is finish
function COSTTimer:is_finish ()
    return self._cursor >= self._duration + self._delay
end


-- Function to get the proportion of passed time (between 0 and 1)
function COSTTimer:get_passed_prop ()
    return self._cursor / self._duration
end


-- Function to get the proportion of remaining time (between 0 and 1)
function COSTTimer:get_remain_prop ()
    return (self._duration - self._cursor) / self._duration
end