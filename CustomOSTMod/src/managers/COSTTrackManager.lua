------ The manager that contains all mod tracks ------


COSTTrackManager = COSTTrackManager or {}

COSTTrackManager.custom_tracks_map = {}
COSTTrackManager.custom_tracks_ordered = {}

COSTTrackManager.beard_lib_event_trad = {
    setup = "setup",
    control = "control",
    anticipation = "buildup",
    assault = "assault"
}


-- Create a new simple track from an OGG file
function COSTTrackManager:create_track_from_ogg (track_file, dir)
    -- Init the track table to create the track after
    local simple_track_table = {}

    local splited_file_name = split_string(track_file, ".")
    splited_file_name[#splited_file_name] = nil

    local track_name = table.concat(splited_file_name, ".")

    -- Try to get the volume
    local splited_volume = split_string(track_name, "-")
    local volume_test = tonumber(splited_volume[#splited_volume])
    if volume_test ~= nil then
        simple_track_table.volume = volume_test
        splited_volume[#splited_volume] = nil
        track_name = table.concat(splited_volume, "-")
    end

    local track_id = table.concat(split_string(string.lower(track_name)), "_")

    -- Get the simple track main parameters
    simple_track_table.id = "custom_ost_simple_" .. track_id
    simple_track_table.name = track_name
    simple_track_table.dir = dir
    simple_track_table.file = track_file

    -- Load the simple track buffer
    COSTTrackManager:_add_simple_track(simple_track_table)
end


-- Create a new track from a json file and the directory of this file
function COSTTrackManager:create_track_from_json (track_file, dir)
    -- Load the track config JSON
    local f = io.open(track_file, "r")
    local track_json_string = f:read("*all")
    f:close()

    local valid, track_table = pcall(function () return json.decode(track_json_string) end)
    if not valid then
        COSTLogger:log_err(track_file .. " JSON file is malformed")
        return nil
    end

    if track_table and type(track_table) == "table" then
        track_table.dir = dir
        track_table.fade_duration = track_table.fade_duration or COSTConfig.default_fade_duration
        COSTTrackManager:_add_standard_track(track_table)
    end
end


-- Create a new track from an xml Beardlib file
function COSTTrackManager:create_track_from_xml (track_file, dir)
    -- Load the track config
    local f = io.open(track_file, "r")
    local track_xml_string = f:read("*all")
    f:close()

    local valid, track_xml_table = pcall(function () return ScriptSerializer:from_custom_xml(track_xml_string) end)
    if not valid then
        COSTLogger:log_err(track_file .. " XML file is malformed")
        return nil
    end

    -- Prepare the localizations array
    local locs_table = {}

    -- Interate in the XML structure to find all localizations
    for k, v in pairs(track_xml_table) do
        if type(k) == "number" and type(v) == "table" then
            if v._meta == "Localization" then
                local directory = (v.directory and dir .. v.directory .. "/") or dir
                local loc_json_file = directory .. v.default
                
                -- Load the loc json file
                if file.FileExists(loc_json_file) then
                    local f_loc = io.open(loc_json_file, "r")
                    local loc_json_string = f_loc:read("*all")
                    f_loc:close()

                    local valid, loc_json_table = pcall(function () return json.decode(loc_json_string) end)
                    if valid then
                        for loc_k, loc_v in pairs(loc_json_table) do locs_table[loc_k] = loc_v end
                    else
                        COSTLogger:log_err("Localization file " .. loc_json_file .. " is malformed")
                        return nil
                    end
                else
                    COSTLogger:log_err("Localization file " .. loc_json_file .. " is missing or unreadable")
                    return nil
                end
            end
        end
    end

    -- Prepare the tracks tables array
    local tracks_tables = {}

    -- Iterate in the XML structure to find all tracks
    for k, v in pairs(track_xml_table) do
        if type(k) == "number" and type(v) == "table" then
            if v._meta == "HeistMusic" then
                local new_track_table = {}

                new_track_table.id = v.id
                new_track_table.name = locs_table["menu_jukebox_" .. v.id]
                new_track_table.volume = v.volume
                new_track_table.fade_duration = COSTConfig.default_fade_duration
                new_track_table.dir = (v.directory and dir .. v.directory .. "/") or dir
                new_track_table.events = {
                    setup = {},
                    control = {},
                    buildup = {},
                    assault = {}
                }

                for ev_k, ev_v in pairs(v) do
                    if type(ev_k) == "number" and type(ev_v) == "table" then
                        if ev_v._meta == "event" then
                            local event = COSTTrackManager.beard_lib_event_trad[ev_v.name]
                            new_track_table.events[event].start_file = ev_v.start_source
                            new_track_table.events[event].file = ev_v.source
                            new_track_table.events[event].volume = ev_v.volume

                            new_track_table.events[event].alt = ev_v.alt_source
                            new_track_table.events[event].alt_start = ev_v.alt_start_source
                            new_track_table.events[event].alt_chance = ev_v.alt_chance
                        end
                    end
                end

                table.insert(tracks_tables, new_track_table)
            end
        end
    end

    -- Add all tracks to the manager
    for _, track_table in pairs(tracks_tables) do
        COSTTrackManager:_add_standard_track(track_table)
    end
end


-- Function to add a simple track to the manager
function COSTTrackManager:_add_simple_track (simple_track_table)
    -- Create the new simple track object
    local new_simple_track = COSTSimpleTrack:new()

    new_simple_track:set_id(simple_track_table.id)
    new_simple_track:set_name(simple_track_table.name)
    new_simple_track:set_volume(simple_track_table.volume)
    new_simple_track:set_context("heist")
    new_simple_track:set_dir(simple_track_table.dir)
    new_simple_track:set_file(simple_track_table.file)

    -- Add the track to the array
    if new_simple_track:is_valid() then
        COSTTrackManager.custom_tracks_map[new_simple_track:get_id()] = new_simple_track
        table.insert(COSTTrackManager.custom_tracks_ordered, new_simple_track)
    end
end


-- Function to add a standard track to the manager
function COSTTrackManager:_add_standard_track (track_table)
    -- Create the new track object
    local new_track = COSTTrack:new()

    new_track:set_id(track_table.id)
    new_track:set_name(track_table.name)
    new_track:set_volume(track_table.volume or 1)
    new_track:set_context(track_table.context or "heist")
    new_track:set_dir(track_table.dir)

    for event, params in pairs(track_table.events) do
        -- Handle the other event name
        if event == "stealth" then event = "setup" end
        if event == "anticipation" then event = "buildup" end

        new_track:set_event_start_file(event, params.start_file)
        new_track:set_event_alt_start_file(event, params.alt_start)
        new_track:set_event_file(event, params.file)
        new_track:set_event_alt_file(event, params.alt)

        new_track:set_event_volume(event, (params.volume or 1))
        new_track:set_event_fade_in(event, (params.fade_in or track_table.fade_duration))
        new_track:set_event_fade_out(event, (params.fade_out or track_table.fade_duration))
        new_track:set_event_alt_chance(event, (params.alt_chance or 0))
    end

    -- Add the track to the array
    if new_track:is_valid() then
        COSTTrackManager.custom_tracks_map[new_track:get_id()] = new_track
        table.insert(COSTTrackManager.custom_tracks_ordered, new_track)
    end
end


-- Function to load all tracks files with optimiziation
function COSTTrackManager:load_tracks_files ()
    local start_time = os.clock()

    for _, track in pairs(COSTTrackManager.custom_tracks_ordered) do
        -- Check the loading duration for the game start timeout
        if (os.clock() - start_time >= COSTConfig.load_timeout) and COSTConfig.load_timeout >= 0 and not Global.custom_ost_indicators.game_init then
            break
        end
        
        track:load_files()
    end
end

-- Add the track title in the localization to display in the tracks menu
function COSTTrackManager:load_tracks_loc ()
    local content = {}
    for _, track in pairs(COSTTrackManager.custom_tracks_ordered) do
        local menu_jukebox_id = "menu_jukebox_" .. track:get_id()
        local menu_jukebox_screen_id = "menu_jukebox_screen_" .. track:get_id()
        content[menu_jukebox_id] = track:get_name()
        content[menu_jukebox_screen_id] = track:get_name()
    end
    LocalizationManager:add_localized_strings(content, false)
    COSTLogger:log_dev("Tracks localization loaded !")
end


-- Add the tracks tweaks to make them apear in the game menu
function COSTTrackManager:add_tracks_tweak()
    for _, track in pairs(COSTTrackManager.custom_tracks_ordered) do

        if track:get_context() == "heist" then

            if not tweak_data.music.track_list[track:get_id()] then
                table.insert(tweak_data.music.track_list, {track = track:get_id()})
            else
                COSTLogger:log_err("Duplicate track id : " .. track:get_id() .. " in the game track list")
            end

        elseif track:get_context() == "stealth" then

            if not tweak_data.music.track_ghost_list[track:get_id()] then
                table.insert(tweak_data.music.track_ghost_list, {track = track:get_id()})
            else
                COSTLogger:log_err("Duplicate track id : " .. track:get_id() .. " in the game track stealth list")
            end

        end

    end
    COSTLogger:log_dev("Tracks tweaks loaded !")
end