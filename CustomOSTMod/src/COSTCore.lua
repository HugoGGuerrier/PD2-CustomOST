------ The main mod classes which contains all mod components ------


CustomOST = CustomOST or {}

CustomOST.track_manager = nil
CustomOST.music_manager = nil
CustomOST.in_heist = false

CustomOST.heist_events_table = {
    music_heist_setup = true,
    music_stealth_setup = true,
    suspense_1 = true,

    music_heist_control = true,
    music_stealth_control = true,
    suspense_2 = true,

    music_heist_anticipation = true,
    music_stealth_anticipation = true,
    suspense_3 = true,
    suspense_4 = true,

    music_heist_assault = true,
    music_stealth_assault = true,
    suspense_5 = true
}


------ Init functions ------


-- Function to init the mod
function CustomOST:init ()
    -- Setup the XAudio API
    if not XAudio then
        COSTLogger:log_err("You need XAudio to make this mod work")
        return nil
    end
    blt.xaudio.setup()

    -- Load the mod sources
    CustomOST:load_sources()

    -- Set the CustomOST attributes
    CustomOST.track_manager = COSTTrackManager:new()
    CustomOST.music_manager = COSTMusicManager:new()

    -- Load the tracks in the track folder
    CustomOST:load_tracks("mods/CustomOSTTracks/")

    -- Load the track audio files into buffers
    if not COSTConfig.dynamic_load then
        CustomOST.track_manager:load_tracks_files(true)
    end

    -- Create the mod menu
    CustomOST:create_menu()

    -- Create the base hooks
    if COSTConfig.do_hook then
        CustomOST:create_hooks()
    end

    -- Log the init finish
    COSTLogger:log_dev("Core init ended correctly !")
end


-- Function to launch later than the init
function CustomOST:late_init ()
    -- Load all the tracks
    if not COSTConfig.dynamic_load then
        CustomOST.track_manager:load_tracks_files(false)
    end

    -- Create the late hooks
    if COSTConfig.do_hook then
        CustomOST:create_late_hooks()
    end

    COSTLogger:log_dev("Core late init ended correctly !")
end


-- Function to load all mod sources
function CustomOST:load_sources ()
    local misc_dir_path = ModPath .. "src/misc/"
    local bases_dir_path = ModPath .. "src/bases/"
    local classes_dir_path = ModPath .. "src/classes/"
    local managers_dir_path = ModPath .. "src/managers/"

    -- Load the misc sources
    if file.DirectoryExists(misc_dir_path) then
        local misc_source_files = file.GetFiles(misc_dir_path)

        for _, file in pairs(misc_source_files) do
            dofile(misc_dir_path .. file)
        end
    else
        log("[CustomOST] [Error] : Cannot find the misc source directory, please reinstall this mod !")
        return nil
    end

    -- Load the mod config
    COSTConfig:load_config()

    -- Load the bases sources
    if file.DirectoryExists(bases_dir_path) then
        local bases_source_files = file.GetFiles(bases_dir_path)

        for _, file in pairs(bases_source_files) do
            dofile(bases_dir_path .. file)
        end
    else
        COSTLogger:log_err("Cannot find the bases source directory, please reinstall this mod !")
        return nil
    end

    -- Load the classes sources
    if file.DirectoryExists(classes_dir_path) then
        local classes_source_files = file.GetFiles(classes_dir_path)

        for _, file in pairs(classes_source_files) do
            dofile(classes_dir_path .. file)
        end
    else
        COSTLogger:log_err("Cannot find the classes source directory, please reinstall this mod !")
        return nil
    end

    -- Load the managers sources
    if file.DirectoryExists(managers_dir_path) then
        local managers_source_files = file.GetFiles(managers_dir_path)

        for _, file in pairs(managers_source_files) do
            dofile(managers_dir_path .. file)
        end
    else
        COSTLogger:log_err("Cannot find the managers source directory, please reinstall this mod !")
        return nil
    end
end


-- Function to get all possible tracks in the specified folder
function CustomOST:load_tracks (custom_track_folder)
    if file.DirectoryExists(custom_track_folder) then
        -- Load all tracks directories
        local tracks_dirs = file.GetDirectories(custom_track_folder)

        for _, dir in pairs(tracks_dirs) do

            -- Prepare the vars to load the track
            dir = dir .. "/"
            local track_json_file = nil
            local track_xml_file = nil

            -- Get the track definition file type
            if file.FileExists(custom_track_folder .. dir .. "track.txt") then
                track_json_file = custom_track_folder .. dir .. "track.txt"
            elseif file.FileExists(custom_track_folder .. dir .. "track.json") then
                track_json_file = custom_track_folder .. dir .. "track.json"
            elseif file.FileExists(custom_track_folder .. dir .. "main.xml") then
                track_xml_file = custom_track_folder .. dir .. "main.xml"
            end

            if track_json_file then
                CustomOST.track_manager:create_track_from_json(track_json_file, custom_track_folder .. dir)
            elseif track_xml_file then
                CustomOST.track_manager:create_track_from_xml(track_xml_file, custom_track_folder .. dir)
            else
                COSTLogger:log_warn("Cannot load the track mod " .. dir .. " track definition file does not exists")
            end

        end

        -- Load all simple tracks
        local tracks_files = file.GetFiles(custom_track_folder)

        for _, track_file in pairs(tracks_files) do
            local file_extension = file.GetExtension(track_file)
            if file_extension == "ogg" or file_extension == "OGG" then
                CustomOST.track_manager:create_track_from_ogg(track_file, custom_track_folder)
            end
        end

        -- Create hooks to insert the custom tracks in the jukebox menu and the playlist menu
        Hooks:Add("LocalizationManagerPostInit", "CustomOSTTracksLocalization", function()
            CustomOST.track_manager:load_tracks_loc()
        end)

        Hooks:PostHook(MusicManager, "init", "CustomOSTTracksTweak", function()
            CustomOST.track_manager:load_tracks_tweak()
        end)
    else
        COSTLogger:log_dev("Custom tracks directory " .. custom_track_folder .. " was not found The mod has created one")
        file.MakeDir(custom_track_folder)
    end
end


-- Function to create the custom ost mod menu
function CustomOST:create_menu ()
    -- Load the menu localization
    local loc_file = ModPath .. "loc/en.txt"
    local menu_id = "costn_menu"
    local menu_file = ModPath .. "res/mod_menu.json"

    Hooks:Add("LocalizationManagerPostInit", "CustomOSTMenuLocalization", function ()
        if file.FileExists(loc_file) then
            LocalizationManager:load_localization_file(loc_file)
        else
            COSTLogger:log_err(loc_file .. " is missing or unreadable")
        end
    end)

    -- Function when you exit the menu
    MenuCallbackHandler.costn_save = function ()
        COSTConfig:save_config()
    end

    -- Function when you choose the default fade duration
    MenuCallbackHandler.costn_default_fade_duration_choice = function (_, v)
        COSTConfig.default_fade_duration = COSTConfig.fade_duration_trad[v._current_index]
    end

    MenuCallbackHandler.costn_dynamic_volume_toogle = function (_, v)
        COSTConfig.dynamic_volume = v.selected == 1
    end

    -- Function when you toogle the dynamic load
    MenuCallbackHandler.costn_dynamic_load_toogle = function (_, v)
        local _, timeout_choice = pcall(function () for _, item in pairs(MenuHelper:GetMenu(menu_id)._items) do if item._parameters.name == "costn_load_timeout_choice" then return item end end return nil end)
        if v.selected == 1 then
            COSTConfig.dynamic_load = true
            timeout_choice._enabled = false
        else
            COSTConfig.dynamic_load = false
            timeout_choice._enabled = true
        end
        timeout_choice:dirty_callback()
    end

    -- Function when you choose the load timeout
    MenuCallbackHandler.costn_load_timeout_choice = function (_, v)
        COSTConfig.load_timeout = COSTConfig.load_timeout_trad[v._current_index]
    end

    -- Function when you toogle the dev logging
    MenuCallbackHandler.costn_dev_toogle = function (_, v)
        COSTConfig.dev = v.selected == 1
    end

    -- Function when you toogle the hook loading
    MenuCallbackHandler.costn_hook_toogle = function (_, v)
        COSTConfig.do_hook = v.selected == 1
    end

    Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenus_Example", function(_, _)
        MenuHelper:NewMenu(menu_id)
    end)

    Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_Example", function(_, _)
        MenuHelper:LoadFromJsonFile(menu_file, {}, COSTConfig:get_menu_params())
    end)

    Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_Example", function(_, _)
        local _, timeout_choice = pcall(function () for _, item in pairs(MenuHelper:GetMenu(menu_id)._items_list) do if item._parameters.name == "costn_load_timeout_choice" then return item end end return nil end)
        if COSTConfig.dynamic_load then
            timeout_choice._enabled = false
        else
            timeout_choice._enabled = true
        end
    end)
end


-- Function to create the base hooks (at the start of the game)
function CustomOST:create_hooks ()

    -- Create hooks to make the custom heist music play in the preplannig menu
    Hooks:PostHook(MusicManager, "track_listen_start", "CustomOSTTrackListenStart", function(_, event, track)
        CustomOST:track_listen_start(event, track)
    end)

    Hooks:PostHook(MusicManager, "track_listen_stop", "CustomOSTTrackListenStop", function()
        CustomOST:track_listen_stop()
    end)

    -- Create hooks to make the stealth music play in the preplanning menu
    Hooks:PostHook(MusicManager, "music_ext_listen_start", "CustomOSTStealthTrackListenStart", function(_, track)
        CustomOST:track_listen_start("suspense_3", track)
    end)

    Hooks:PostHook(MusicManager, "stop_listen_all", "CustomOSTStealthTrackListenStop", function()
        CustomOST:track_listen_stop()
    end)

    Hooks:PostHook(MusicManager, "music_ext_listen_stop", "CustomOSTStealthTrackListenStopMenu", function()
        CustomOST:track_listen_stop()
    end)

    -- Create hook to make the music playting during the mission
    Hooks:PostHook(MusicManager, "post_event", "CustomOSTPostEvent", function(_, name)
        CustomOST:post_event(name)
    end)
    
    Hooks:PostHook(MusicManager, "stop", "CustomOSTStop", function()
        CustomOST.in_heist = false
        CustomOST:force_stop(false, 0)
    end)

    Hooks:PostHook(MusicManager, "on_mission_end", "CustomOSTMissionEnd", function ()
        CustomOST.in_heist = false
        CustomOST:force_stop(true, 1)
    end)

    -- Compatibility with Music Control
    if Music then
        Hooks:PreHook(Music, "Call", "CustomOSTMusicControlCompats", function (_, _, song, _, _)
            Global.music_manager.current_track = song
        end)
    end

    -- Compatibility with Music Jukebox Control
    if MusicJukeBoxControl then
        Hooks:PreHook(MusicJukeBoxControl, "force_stop_music", "CustomOSTMusicJukeboxSwitchTrack", function ()
            CustomOST:force_stop(false, 0)
        end)
    end

end


-- Create the late hooks (during the game loading)
function CustomOST:create_late_hooks ()

    -- Hooks to do the dynamic volume
    if COSTConfig.dynamic_volume then

        -- When operator start talking
        Hooks:PostHook(DialogManager, "_play_dialog", "CustomOSTStartDialog", function ()
            CustomOST.music_manager:speak_mission()
        end)

        -- When operator stop talking
        Hooks:PostHook(DialogManager, "_stop_dialog", "CustomOSTStopDialog", function ()
            CustomOST.music_manager:stop_speak()
        end)

        -- When the plannig start talking 1
        Hooks:PostHook(VoiceBriefingManager, "post_event", "CustomOSTVoiceBriefingTalk", function ()
            CustomOST.music_manager:speak_planning()
        end)

        -- When the plannig start talking 2
        Hooks:PostHook(VoiceBriefingManager, "post_event_simple", "CustomOSTVoiceBriefingTalk2", function ()
            CustomOST.music_manager:speak_planning()
        end)

        -- When the planning stop talking 1
        Hooks:PostHook(VoiceBriefingManager, "stop_event", "CustomOSTVoiceBriefingStop", function ()
            CustomOST.music_manager:stop_speak()
        end)

        -- When the planning stop talking 2
        Hooks:PostHook(VoiceBriefingManager, "_clear_event", "CustomOSTVoiceBriefingStop2", function ()
            CustomOST.music_manager:stop_speak()
        end)

        -- When player get downed by normal way (no more health)
        Hooks:PostHook(IngameBleedOutState, "at_enter", "CustomOSTBleedoutEnter", function ()
            CustomOST.music_manager:bleedout_enter()
        end)

        -- When the player get downed by a cloaker or a taser
        Hooks:PostHook(IngameIncapacitatedState, "at_enter", "CustomOSTIncapacitatedEnter", function ()
            CustomOST.music_manager:bleedout_enter()
        end)

        -- When the player enter in the normal state
        Hooks:PostHook(IngameStandardState, "at_enter", "CustomOSTStandardEnter", function ()
            CustomOST.music_manager:standard_enter()
        end)

        -- When the player goes to jail
        Hooks:PostHook(IngameWaitingForRespawnState, "at_enter", "CustomOSTArrestedEnter", function ()
            CustomOST.music_manager:standard_enter()
        end)

        -- When player get hit
        Hooks:PostHook(HUDManager, "on_hit_direction", "CustomOSTHitSound", function ()
            CustomOST.music_manager:hit_sound()
        end)

        -- When there is a hint that appears on the screen
        Hooks:PostHook(HUDManager, "show_hint", "CustomOSTHintFeedbakcSoundSound", function (_, params)
            if params.event and params.event == "stinger_feedback_positive" then
                CustomOST.music_manager:feedback_sound()
            end
        end)

        -- When the objective is shown
        Hooks:PostHook(HUDPresenter, "_present_information", "CustomOSTPresenterSound", function (_, params)
            if params.event and params.event == "stinger_objectivecomplete" then
                CustomOST.music_manager:objective_sound()
            end
        end)

        -- When the player get flashbanged
        Hooks:PostHook(PlayerDamage, "on_flashbanged", "CustomOSTFlashbanged", function (_, sound_eff_mul)
            if sound_eff_mul then
                CustomOST.music_manager:flash_grenade(sound_eff_mul)
            end
        end)

    end

end


------ Hooked functions ------


-- Hook for the track listen start
function CustomOST:track_listen_start (event, track)
    if not CustomOST.in_heist then
        CustomOST.music_manager:track_listen_start(event, track)
    end
end


-- Hook for the track listen stop
function CustomOST:track_listen_stop ()
    if not CustomOST.in_heist then
        CustomOST.music_manager:track_listen_stop()
    end
end


-- Hook for the stop and clean
function CustomOST:force_stop (fade_out, fade_duration)
    CustomOST.music_manager:set_current_track(nil)
    CustomOST.music_manager:set_current_event(nil)
    CustomOST.music_manager:stop_custom(fade_out, fade_duration)
end


-- Hook for the post event
function CustomOST:post_event (event)
    if CustomOST.heist_events_table[event] then
        CustomOST.in_heist = true
    end

    CustomOST.music_manager:post_event(event)
end


------ End of the class ------


-- Launch the mod init
CustomOST:init()