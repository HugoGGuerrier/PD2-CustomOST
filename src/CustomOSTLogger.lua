CustomOSTLogger = {}

CustomOSTLogger.dev = true

function CustomOSTLogger:log_err ( msg )
    log("[CustomOST] [Error] : " .. msg)
end

function CustomOSTLogger:log_warn ( msg )
    log("[CustomOST] [Warning] : " .. msg)
end

function CustomOSTLogger:dev_log ( msg )
    if CustomOSTLogger.dev then
        log("[CustomOST] [DevLog] : " .. msg)
    end
end