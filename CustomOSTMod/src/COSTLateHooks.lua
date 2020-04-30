-- Create all in game hooks that cannot be loaded before
-- If you just want to test music loading, set this value to "false"
local do_hooks = true

if do_hooks then

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