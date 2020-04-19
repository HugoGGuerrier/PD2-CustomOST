CustomOSTTracks = {}

CustomOSTTracks._custom_tracks_map = {}
CustomOSTTracks._custom_tracks_ordered = {}

function CustomOSTTracks:init_track (track)
    track.id = nil
    track._meta = "CustomOSTTrack"
    track.volume = 1
    track.fade_transition = false
    track.name = "Default track name"
    track.dir = nil
    track.events_buffers = nil
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
function CustomOSTTracks:create_from_file (track_file, dir)
    -- Init the result
    local new_track = {}
    CustomOSTTracks:init_track(new_track)

    -- Check the track file existence
    if not file:FileExists(track_file) then
        CustomOSTLogger:log_err("Cannot load track from folder " .. dir .. " track.json file is missing")
        return nil
    end

    -- Load the track config
    local f = io.open(track_file, "r")
    local track_json = f:read("*all")
    local track_obj = json.decode(track_json)
    f:close()

    new_track.name = track_obj.name
    new_track.id = track_obj.id
    new_track.volume = track_obj.volume or 1
    new_track.fade_transition = track_obj.fade_transition or false
    new_track.dir = dir
    
    if not new_track.id or not new_track.name then
        CustomOSTLogger:log_err("Cannot load track from folder " .. dir .. " track.json file is malformed, you need at leat a 'name' and an 'id'")
        return nil
    end

    for event, sources_path in pairs(track_obj.events) do
        new_track.events_files[event].start_source_file = track_obj.events[event].start_source
        new_track.events_files[event].source_file = track_obj.events[event].source
    end

    if CustomOSTTracks:load_tracks_files(new_track) then
        CustomOSTLogger:dev_log(new_track.name .. " loaded !")
        CustomOSTTracks._custom_tracks_map[new_track.id] = new_track
        table.insert(CustomOSTTracks._custom_tracks_ordered, new_track)
    end
end

-- Load all the track files of the track object
function CustomOSTTracks:load_tracks_files (track)
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
                CustomOSTLogger:dev_log("Load " .. track.id .. " - " .. event .. "(start)")
            else
                CustomOSTLogger:log_warn("File " .. start_source_path .. " is missing or unreadable")
            end
        end

        -- Try to load the main source file in a buffer
        if source_path then
            if file:FileExists(source_path) then
                events_buffers_tmp[event].source_buffer = XAudio.Buffer:new(source_path)
                CustomOSTLogger:dev_log("Load " .. track.id .. " - " .. event)
            else
                CustomOSTLogger:log_err("File " .. source_path .. " is missing")
                return false
            end
        else
            CustomOSTLogger:log_err("Track " .. track.name .. " does not have source file for event " .. event .. ", you need at least one source file for each event")
            return false
        end
    end

    -- If the load succeed, set the events buffers and return true 
    track.events_buffers = events_buffers_tmp
    return true
end

-- Add the track title in the localization to display in the tracks menu
function CustomOSTTracks:load_tracks_loc ()
    local content = {}
    for _, track in pairs(CustomOSTTracks._custom_tracks_ordered) do
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

-- Add the tracks tweaks to make them apear in the game menu
function CustomOSTTracks:add_tracks_tweak()
    for _, track in pairs(CustomOSTTracks._custom_tracks_ordered) do
        if track._meta == "CustomOSTTrack" then
            table.insert(tweak_data.music.track_list, {track = track.id})
            CustomOSTLogger:dev_log("Track tweaks loaded !")
        end
    end
end