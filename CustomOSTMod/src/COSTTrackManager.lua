COSTTrackManager = COSTTrackManager or {}

COSTTrackManager.custom_tracks_map = {}
COSTTrackManager.custom_tracks_ordered = {}

COSTTrackManager.beard_lib_event_trad = {
    setup = "setup",
    control = "control",
    anticipation = "buildup",
    assault = "assault"
}


-- Init a simple track object
function COSTTrackManager:init_simple_track (simple_track)
    simple_track.id = nil
    simple_track.cost_type = "CustomOSTSimpleTrack"
    simple_track.volume = 1
    simple_track.name = "Default simple track name"
    simple_track.dir = nil
    simple_track.file = nil
    simple_track.buffer = nil
end


-- Init a track object
function COSTTrackManager:init_track (track)
    track.id = nil
    track.cost_type = "CustomOSTTrack"
    track.volume = 1
    track.name = "Default track name"
    track.dir = nil
    track.is_ogg = true
    track.events_buffers = nil
    track.events_params = {
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
    track.events_files = {
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
end


-- Create a new track from a json file and the directory of this file
function COSTTrackManager:create_from_json_file (track_file, dir)
    -- Check the track file existence
    if not file.FileExists(track_file) then
        COSTLogger:log_err("Cannot load track from folder " .. dir .. " track file is missing")
        return nil
    end

    -- Load the track config
    local f = io.open(track_file, "r")
    local track_json = f:read("*all")
    local valid, track_obj = pcall(function () return json.decode(track_json) end)
    if not valid then
        COSTLogger:log_err(dir .. track_file .. " JSON file is malformed")
        return nil
    end
    track_obj.is_ogg = true
    f:close()

    -- Create the track
    COSTTrackManager:create_track(track_obj, dir)
end


-- Create a new track from an xml Beardlib file
function COSTTrackManager:create_from_xml_file (track_file, dir)
    -- Check the track file existence
    if not file.FileExists(track_file) then
        COSTLogger:log_err("Cannot load track from folder " .. dir .. " main.xml file is missing")
        return nil
    end

    -- Load the track config
    local f = io.open(track_file, "r")
    local track_xml = f:read("*all")
    local track_tmp_obj = ScriptSerializer:from_custom_xml(track_xml)
    f:close()

    -- Prepare the result to load the track
    local track_obj = {}
    local sound_dir = nil

    -- Get the track info
    if track_tmp_obj.HeistMusic then

        track_obj.id = track_tmp_obj.HeistMusic.id
        track_obj.volume = track_tmp_obj.HeistMusic.volume or 1
        track_obj.is_ogg = true
        track_obj.events = {
            setup = {},
            control = {},
            buildup = {},
            assault = {}
        }
        sound_dir = dir .. track_tmp_obj.HeistMusic.directory .. "/"

        for k, v in pairs(track_tmp_obj.HeistMusic) do
            if type(k) == "number" and type(v) == "table" then
                if v._meta and v._meta == "event" then
                    local event_name = COSTTrackManager.beard_lib_event_trad[v.name]
                    if event_name then
                        track_obj.events[event_name].start_file = v.start_source
                        track_obj.events[event_name].file = v.source
                    end
                end
            end
        end

    else
        COSTLogger:log_err("Cannot load Beardlib mods without ogg files, not supported yet")
        return nil
    end

    -- Get the localization info
    if track_tmp_obj.Localization then

        local loc_file = nil
        if track_tmp_obj.Localization.directory then
            loc_file = dir .. track_tmp_obj.Localization.directory .. "/" .. track_tmp_obj.Localization.default
        else
            loc_file = dir .. track_tmp_obj.Localization.default
        end

        if loc_file and file.FileExists(loc_file) then
            local f_loc = io.open(loc_file, "r")
            local valid, loc_obj = pcall(function () return json.decode(f_loc:read("*all")) end)
            if not valid then
                COSTLogger:log_err(loc_file .. " JSON file is malformed")
                return nil
            end
            track_obj.name = loc_obj["menu_jukebox_" .. track_obj.id]
        else
            COSTLogger:log_err("Cannot find the localization file")
            return nil
        end

    else
        COSTLogger:log_err("Beardlib music mod is malformed")
        return nil
    end

    -- Create the track
    COSTTrackManager:create_track(track_obj, sound_dir)
end


-- Create a simple track from an OGG file
function COSTTrackManager:create_simple_track (track_file, dir)
    -- Check the track file existence
    if not file.FileExists(dir .. track_file) then
        COSTLogger:log_err("Track file " .. track_file .. " is missing")
        return nil
    end

    -- Init the result
    local new_track = {}
    COSTTrackManager:init_simple_track(new_track)

    local splited_file_name = split_string(track_file, ".")
    splited_file_name[#splited_file_name] = nil

    local track_name = table.concat(splited_file_name, ".")

    -- Try to get the volume
    local splited_volume = split_string(track_name, "-")
    local volume_test = tonumber(splited_volume[#splited_volume])
    if volume_test ~= nil then
        new_track.volume = volume_test
        splited_volume[#splited_volume] = nil
        track_name = table.concat(splited_volume, "-")
    end

    local track_id = table.concat(split_string(string.lower(track_name)), "_")

    -- Get the simple track main parameters
    new_track.name = track_name
    new_track.id = "custom_ost_simple_" .. track_id
    new_track.dir = dir
    new_track.file = track_file

    -- Load the simple track buffer
    if COSTTrackManager:load_simple_track(new_track) then
        COSTLogger:dev_log(new_track.name .. " (simple track) loaded !")
        COSTTrackManager.custom_tracks_map[new_track.id] = new_track
        table.insert(COSTTrackManager.custom_tracks_ordered, new_track)
    end
end


-- Function to create the new track with a track obj
function COSTTrackManager:create_track (track_obj, dir)
    -- Init the result
    local new_track = {}
    COSTTrackManager:init_track(new_track)

    -- Get the track main params
    new_track.name = track_obj.name
    new_track.id = track_obj.id
    new_track.volume = track_obj.volume or 1
    new_track.is_ogg = track_obj.is_ogg or true
    new_track.dir = dir

    -- Get the default fade transition
    local fade_duration = track_obj.fade_duration or 0

    if not new_track.id or not new_track.name then
        COSTLogger:log_err("Cannot load track from folder " .. dir .. "track.json file is malformed, you need at leat a 'name' and an 'id'")
        return nil
    end

    if COSTTrackManager.custom_tracks_map[new_track.id] then
        COSTLogger:log_err("Cannot load the track " .. new_track.name .. " multiple id violation")
        return nil
    end

    -- Load the events params
    for event, params in pairs(track_obj.events) do
        new_track.events_files[event].start_source_file = params.start_file
        new_track.events_files[event].source_file = params.file
        new_track.events_params[event].volume = params.volume or 1
        new_track.events_params[event].fade_in = params.fade_in or fade_duration
        new_track.events_params[event].fade_out = params.fade_out or fade_duration
    end

    -- Load all the track buffers
    if new_track.is_ogg then

        if COSTTrackManager:load_track_ogg_files(new_track) then
            COSTLogger:dev_log(new_track.name .. " loaded !")
            COSTTrackManager.custom_tracks_map[new_track.id] = new_track
            table.insert(COSTTrackManager.custom_tracks_ordered, new_track)
        end

    else

        COSTLogger:dev_log("TODO : Make the compatibility with the .movie files")

    end
end


-- Load a simple track buffer
function COSTTrackManager:load_simple_track (simple_track)
    if simple_track.cost_type == "CustomOSTSimpleTrack" then

        local source_path = simple_track.dir .. simple_track.file
        simple_track.buffer = XAudio.Buffer:new(source_path)
        return true

    else

        COSTLogger:log_warn("Can only load a CustomOSTSimpleTrack with the function load_simple_track")
        return false

    end
end


-- Load all the track OGG files of the track object
function COSTTrackManager:load_track_ogg_files (track)
    if track.cost_type == "CustomOSTTrack" and track.is_ogg then

        -- Make a tmp var to avoid buffer loading problems
        local events_buffers_tmp = {
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

        for event, files in pairs(track.events_files) do
            -- Get the source paths
            local start_source_path = files.start_source_file and track.dir .. files.start_source_file
            local source_path = files.source_file and track.dir .. files.source_file

            -- Load the start source file in a buffer if it exists
            if start_source_path then
                if file.FileExists(start_source_path) then 
                    events_buffers_tmp[event].start_source_buffer = XAudio.Buffer:new(start_source_path)
                    COSTLogger:dev_log("Load " .. track.id .. " - " .. event .. " (start)")
                else
                    COSTLogger:log_warn("File " .. start_source_path .. " is missing or unreadable")
                end
            end

            -- Try to load the main source file in a buffer
            if source_path then
                if file.FileExists(source_path) then
                    events_buffers_tmp[event].source_buffer = XAudio.Buffer:new(source_path)
                    COSTLogger:dev_log("Load " .. track.id .. " - " .. event)
                else
                    COSTLogger:log_err("File " .. source_path .. " is missing")
                    return false
                end
            else
                COSTLogger:log_err("Track " .. track.name .. " does not have source file for event " .. event .. ", you need at least one source file for each event")
                return false
            end
        end

        -- If the load succeed, set the events buffers and return true 
        track.events_buffers = events_buffers_tmp
        return true

    end

    return false
end


-- Add the track title in the localization to display in the tracks menu
function COSTTrackManager:load_tracks_loc ()
    local content = {}
    for _, track in pairs(COSTTrackManager.custom_tracks_ordered) do
        if track.cost_type == "CustomOSTTrack" or track.cost_type == "CustomOSTSimpleTrack" then
            local menu_jukebox_id = "menu_jukebox_" .. track.id
            local menu_jukebox_screen_id = "menu_jukebox_screen_" .. track.id
            content[menu_jukebox_id] = track.name
            content[menu_jukebox_screen_id] = track.name
        end
    end
    LocalizationManager:add_localized_strings(content, false)
    COSTLogger:dev_log("Tracks localization loaded !")
end


-- Add the tracks tweaks to make them apear in the game menu
function COSTTrackManager:add_tracks_tweak()
    for _, track in pairs(COSTTrackManager.custom_tracks_ordered) do
        if track.cost_type == "CustomOSTTrack" or track.cost_type == "CustomOSTSimpleTrack" then
            if not tweak_data.music.track_list[track.id] then
                table.insert(tweak_data.music.track_list, {track = track.id})
            else
                COSTLogger:log_err("Duplicate track id in the game track list")
            end
        end
    end
    COSTLogger:dev_log("Tracks tweaks loaded !")
end