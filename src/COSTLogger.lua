COSTLogger = {}

COSTLogger.dev = true

function COSTLogger:log_err ( msg )
    log("[CustomOST] [Error] : " .. msg)
end

function COSTLogger:log_warn ( msg )
    log("[CustomOST] [Warning] : " .. msg)
end

function COSTLogger:dev_log ( msg )
    if COSTLogger.dev then
        log("[CustomOST] [DevLog] : " .. msg)
    end
end