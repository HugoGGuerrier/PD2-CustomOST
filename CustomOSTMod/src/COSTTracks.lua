COSTTracks = COSTTracks or {}

COSTTracks.custom_tracks_map = {}
COSTTracks.custom_tracks_ordered = {}

COSTTracks.beard_lib_event_trad = {
    setup = "setup",
    control = "control",
    anticipation = "buildup",
    assault = "assault"
}

function COSTTracks:init_track (track)
    track.id = nil
    track.cost_type = "CustomOSTTrack"
    track.volume = 1
    track.name = "Default track name"
    track.dir = nil
    track.fade_transition = true
    track.is_ogg = true
    track.fade_duration = 1
    track.events_buffers = nil
    track.events_volumes = {
        setup = 1,
        control = 1,
        buildup = 1,
        assault = 1
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
function COSTTracks:create_from_json_file (track_file, dir)
    -- Check the track file existence
    if not file:FileExists(track_file) then
        COSTLogger:log_err("Cannot load track from folder " .. dir .. " track file is missing")
        return nil
    end

    -- Load the track config
    local f = io.open(track_file, "r")
    local track_json = f:read("*all")
    local track_obj = json.decode(track_json)
    f:close()

    -- Create the track
    COSTTracks:create_track(track_obj, dir)
end

-- Create a new track from an xml Beardlib file
function COSTTracks:create_from_xml_file (track_file, dir)
    -- Check the track file existence
    if not file:FileExists(track_file) then
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
        track_obj.events = {
            setup = {},
            control = {},
            buildup = {},
            assault = {}
        }
        sound_dir = dir .. track_tmp_obj.HeistMusic.directory .. "/"

        for _, v in pairs(track_tmp_obj.HeistMusic) do
            if v._meta == "event" then
                local event_name = COSTTracks.beard_lib_event_trad[v.name]
                track_obj.events[event_name].file = v.source
                track_obj.events[event_name].start_file = v.start_source
            end
        end
        
    else
        COSTLogger:log_err("Cannot load Beardlib mods without ogg files, not yet supported")
        return nil
    end

    -- Verify the track object
    if not track_obj.id then
        COSTLogger:log_err("Cannot find the track id, every track require an id")
        return nil
    end

    -- Get the localization info
    if track_tmp_obj.Localization then

        local loc_file = dir .. track_tmp_obj.Localization.directory .. "/" .. track_tmp_obj.Localization.default

        if file:FileExists(loc_file) then
            local f_loc = io.open(loc_file, "r")
            local loc_obj = json.decode(f_loc:read("*all"))
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
    COSTTracks:create_track(track_obj, sound_dir)
end

-- Function to create the new track with a track obj
function COSTTracks:create_track (track_obj, dir)
    -- Init the result
    local new_track = {}
    COSTTracks:init_track(new_track)

    -- Get the track main params
    new_track.name = track_obj.name
    new_track.id = track_obj.id
    new_track.volume = track_obj.volume or 1
    new_track.fade_transition = track_obj.fade_transition or true
    new_track.is_ogg = track_obj.is_ogg or true
    new_track.fade_duration = track_obj.fade_duration or 1
    new_track.dir = dir

    if not new_track.id or not new_track.name then
        COSTLogger:log_err("Cannot load track from folder " .. dir .. "track.json file is malformed, you need at leat a 'name' and an 'id'")
        return nil
    end

    if COSTTracks.custom_tracks_map[new_track.id] then
        COSTLogger:log_err("Cannot load the track " .. new_track.name .. " multiple id violation")
        return nil
    end

    -- Load the evens params
    for event, params in pairs(track_obj.events) do
        new_track.events_files[event].start_source_file = params.start_file
        new_track.events_files[event].source_file = params.file
        new_track.events_volumes[event] = params.volume or 1
    end

    -- Load all the track buffers
    if new_track.is_ogg then

        if COSTTracks:load_tracks_ogg_files(new_track) then
            COSTLogger:dev_log(new_track.name .. " loaded !")
            COSTTracks.custom_tracks_map[new_track.id] = new_track
            table.insert(COSTTracks.custom_tracks_ordered, new_track)
        end

    else
        COSTLogger:dev_log("TODO : Make the compatibility with the .movie files")
    end
end

-- Load all the track files of the track object
function COSTTracks:load_tracks_ogg_files (track)
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
            if file:FileExists(start_source_path) then 
                events_buffers_tmp[event].start_source_buffer = XAudio.Buffer:new(start_source_path)
                COSTLogger:dev_log("Load " .. track.id .. " - " .. event .. " (start)")
            else
                COSTLogger:log_warn("File " .. start_source_path .. " is missing or unreadable")
            end
        end

        -- Try to load the main source file in a buffer
        if source_path then
            if file:FileExists(source_path) then
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

-- Add the track title in the localization to display in the tracks menu
function COSTTracks:load_tracks_loc ()
    local content = {}
    for _, track in pairs(COSTTracks.custom_tracks_ordered) do
        if track.cost_type == "CustomOSTTrack" then
            local menu_jukebox_id = "menu_jukebox_" .. track.id
            local menu_jukebox_screen_id = "menu_jukebox_screen_" .. track.id
            content[menu_jukebox_id] = track.name
            content[menu_jukebox_screen_id] = track.name
        end
    end
    LocalizationManager:add_localized_strings(content, true)
    COSTLogger:dev_log("Tracks localization loaded !")
end

-- Add the tracks tweaks to make them apear in the game menu
function COSTTracks:add_tracks_tweak()
    for _, track in pairs(COSTTracks.custom_tracks_ordered) do
        if track.cost_type == "CustomOSTTrack" then
            table.insert(tweak_data.music.track_list, {track = track.id})
        end
    end
    COSTLogger:dev_log("Tracks tweaks loaded !")
end