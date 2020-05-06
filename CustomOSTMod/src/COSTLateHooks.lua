------ Create all in game hooks that cannot be created before the gamesetup ------


if COSTConfig.do_hook then

    -- When operator start talking
    Hooks:PostHook(DialogManager, "_play_dialog", "CustomOSTStartDialog", function ()
        COSTMusicManager:speak_mission()
    end)

    -- When operator stop talking
    Hooks:PostHook(DialogManager, "_stop_dialog", "CustomOSTStopDialog", function ()
        COSTMusicManager:stop_speak()
    end)

    -- When the plannig start talking 1
    Hooks:PostHook(VoiceBriefingManager, "post_event", "CustomOSTVoiceBriefingTalk", function ()
        COSTMusicManager:speak_planning()
    end)

    -- When the plannig start talking 2
    Hooks:PostHook(VoiceBriefingManager, "post_event_simple", "CustomOSTVoiceBriefingTalk2", function ()
        COSTMusicManager:speak_planning()
    end)

    -- When the planning stop talking 1
    Hooks:PostHook(VoiceBriefingManager, "stop_event", "CustomOSTVoiceBriefingStop", function ()
        COSTMusicManager:stop_speak()
    end)

    -- When the planning stop talking 2
    Hooks:PostHook(VoiceBriefingManager, "_clear_event", "CustomOSTVoiceBriefingStop2", function ()
        COSTMusicManager:stop_speak()
    end)

    -- When player get downed by normal way (no more health)
    Hooks:PostHook(IngameBleedOutState, "at_enter", "CustomOSTBleedoutEnter", function ()
        COSTMusicManager:bleedout_enter()
    end)

    -- When the player get downed by a cloaker or a taser
    Hooks:PostHook(IngameIncapacitatedState, "at_enter", "CustomOSTIncapacitatedEnter", function ()
        COSTMusicManager:bleedout_enter()
    end)

    -- When the player enter in the normal state
    Hooks:PostHook(IngameStandardState, "at_enter", "CustomOSTStandardEnter", function ()
        COSTMusicManager:standard_enter()
    end)

    -- When the player goes to jail
    Hooks:PostHook(IngameWaitingForRespawnState, "at_enter", "CustomOSTArrestedEnter", function ()
        COSTMusicManager:standard_enter()
    end)

    -- When there is a hint that appears on the screen
    Hooks:PostHook(HUDManager, "show_hint", "CustomOSTHintFeedbakcSoundSound", function (_, params)
        if params.event then
            if params.event == "stinger_feedback_positive" then
                COSTMusicManager:feedback_sound()
            end
        end
    end)

    -- When player get hit
    Hooks:PostHook(HUDManager, "on_hit_direction", "CustomOSTHitSound", function ()
        COSTMusicManager:hit_sound()
    end)

    -- When the objective is shown
    Hooks:PostHook(HUDPresenter, "_present_information", "CustomOSTPresenterSound", function (_, params)
        if params.event then
            if params.event == "stinger_objectivecomplete" then
                COSTMusicManager:objective_sound()
            end
        end
    end)

    -- When the player get flashbanged
    Hooks:PostHook(PlayerDamage, "on_flashbanged", "CustomOSTFlashbanged", function (_, sound_eff_mul)
        if sound_eff_mul then
            COSTMusicManager:flash_grenade(sound_eff_mul)
        end
    end)

    COSTLogger:dev_log("Late hooks loaded !")

end