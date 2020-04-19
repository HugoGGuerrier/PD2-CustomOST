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

-- Add the track title in the localization
function load_tracks_loc ()
    if Global._custom_ost_tracks_ordered and type(Global._custom_ost_tracks_ordered) == "table" then
        local content = {}
        for _, track in pairs(Global._custom_ost_tracks_ordered) do
            if track._meta == "CustomOSTTrack" then
                local menu_jukebox_id = "menu_jukebox_" .. track.id
                local menu_jukebox_screen_id = "menu_jukebox_screen_" .. track.id
                content[menu_jukebox_id] = track.name
                content[menu_jukebox_screen_id] = track.name
            end
        end
        LocalizationManager:add_localized_strings(content, true)
        CustomOSTLogger:dev_log("Tracks localization loaded !")
    end
end

-- Add the track to the tweaks
function add_tracks_tweak()
    if Global._custom_ost_tracks_ordered and type(Global._custom_ost_tracks_ordered) == "table" then
        for _, track in pairs(Global._custom_ost_tracks_ordered) do
            if track._meta == "CustomOSTTrack" then
                table.insert(tweak_data.music.track_list, {track = track.id})
                CustomOSTLogger:dev_log("Track tweaks loaded !")
            end
        end
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