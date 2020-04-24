-- Add the function FileExists to the blt file class
function file:FileExists (file_to_test)
    local f = io.open(file_to_test, "r")

    if f~=nil then 
        io.close(f)
        return true
    else 
        return false
    end
end

-- Print any var simply!
function smart_print (val, indent)
    indent = indent or 0
    if val ~= nil then

        if type(val) == "table" then
            log(string.rep("  ", indent) .. "{")

            for k, v in pairs(val) do
                if type(v) == "table" then
                    log(string.rep("  ", indent) .. "\"" .. tostring(k) .. "\"" .. " : ")
                    smart_print(v, indent + 1)
                else
                    log(string.rep("  ", indent) .. "\"" .. tostring(k) .. "\"" .. " : " .. tostring(v))
                end
            end

            log(string.rep("  ", indent) .. "}")
        else
            log(string.rep("  ", indent) .. tostring(val))
        end

    else
        log(string.rep("  ", indent) .. "nil")
    end
end
