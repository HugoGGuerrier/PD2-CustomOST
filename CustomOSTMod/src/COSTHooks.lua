-- Create all game hooks to make this mod works
-- If you just want to test music loading, set this value to "false"
local do_hooks = true

if do_hooks then

    -- Create the hook to insert the custom tracks in the jukebox menu
    Hooks:Add("LocalizationManagerPostInit", "CustomOSTTracksLocalization", function()
        COSTTracks:load_tracks_loc()
    end)

    Hooks:PostHook(MusicManager, "init", "CustomOSTTracksTweak", function()
        COSTTracks:add_tracks_tweak()
    end)

    -- Create hooks to make the custom music play
    Hooks:PostHook(MusicManager, "track_listen_start", "CustomOSTTrackListerStart", function(_, event, track)
        COSTMusicManager:track_listen_start(event, track)
    end)

    Hooks:PostHook(MusicManager, "track_listen_stop", "CustomOSTTrackListenStop", function()
        COSTMusicManager:track_listen_stop()
    end)

    Hooks:PostHook(MusicManager, "stop", "CustomOSTStop", function()
        COSTMusicManager:stop_custom(false, 1)
    end)

    Hooks:PostHook(MusicManager, "post_event", "CustomOSTPostEvent", function(_, name)
        COSTMusicManager:post_event(name)
    end)

    -- Create the hooks to make the dynamic music integration
    Hooks:PostHook(DialogManager, "_play_dialog", "CustomOSTStartDialog", function ()
        COSTMusicManager:speak_mission()
    end)

    Hooks:PostHook(DialogManager, "_stop_dialog", "CustomOSTStopDialog", function ()
        COSTMusicManager:stop_speak()
    end)

    Hooks:PostHook(VoiceBriefingManager, "post_event", "CustomOSTVoiceBriefingTalk", function ()
        COSTMusicManager:speak_planning()
    end)

    Hooks:PostHook(VoiceBriefingManager, "post_event_simple", "CustomOSTVoiceBriefingTalk2", function ()
        COSTMusicManager:speak_planning()
    end)

    Hooks:PostHook(VoiceBriefingManager, "stop_event", "CustomOSTVoiceBriefingStop", function ()
        COSTMusicManager:stop_speak()
    end)

    Hooks:PostHook(VoiceBriefingManager, "_clear_event", "CustomOSTVoiceBriefingStop2", function ()
        COSTMusicManager:stop_speak()
    end)

    Hooks:PostHook(IngameBleedOutState, "at_enter", "CustomOSTBleedoutEnter", function ()
        COSTMusicManager:bleedout_enter()
    end)

    Hooks:PostHook(IngameStandardState, "at_enter", "CustomOSTStandardEnter", function ()
        COSTMusicManager:standard_enter()
    end)

    Hooks:PostHook(IngameWaitingForRespawnState, "at_enter", "CustomOSTArrestedEnter", function ()
        COSTMusicManager:standard_enter()
    end)

    Hooks:PostHook(HUDManager, "show_hint", "CustomOSTHintFeedbakcSoundSound", function (_, params)
        if params.event then
            if params.event == "stinger_feedback_positive" then
                COSTMusicManager:feedback_sound()
            end
        end
    end)

    Hooks:PostHook(HUDManager, "on_hit_direction", "CustomOSTHitSound", function ()
        COSTMusicManager:hit_sound()
    end)

    Hooks:PostHook(HUDPresenter, "_present_information", "CustomOSTPresenterSound", function (_, params)
        if params.event then
            if params.event == "stinger_objectivecomplete" then
                COSTMusicManager:objective_sound()
            end
        end
    end)

    COSTLogger:dev_log("Hooks loaded !")

end