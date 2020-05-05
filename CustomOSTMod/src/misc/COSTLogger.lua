------ The Custom OST logger ------


COSTLogger = COSTLogger or {}


function COSTLogger:log_err (msg)
    if COSTConfig.dev and msg then
        log("[CustomOST] [Error] : " .. msg)
    end
end

function COSTLogger:show_err (msg)
    if msg then
        local valid, _ = pcall(function () return QuickMenu:new("Custom OST Error", msg, {}, true) end)
        if not valid then
            COSTLogger:log_err("Cannot display the quick menu : " .. msg)
        end
    end
end

function COSTLogger:log_warn (msg)
    if COSTConfig.dev and msg then
        log("[CustomOST] [Warning] : " .. msg)
    end
end

function COSTLogger:dev_log (msg)
    if COSTConfig.dev and msg then
        log("[CustomOST] [DevLog] : " .. msg)
    end
end