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
        if valid then
            COSTLogger:log_err(msg)
        else
            COSTLogger:log_err("Cannot display the quick menu : " .. msg)
        end
    end
end

function COSTLogger:log_warn (msg)
    if COSTConfig.dev and msg then
        log("[CustomOST] [Warning] : " .. msg)
    end
end

function COSTLogger:show_warn (msg)
    if msg then
        local valid, _ = pcall(function () return QuickMenu:new("Custom OST Warning", msg, {}, true) end)
        if valid then
            COSTLogger:log_warn(msg)
        else
            COSTLogger:log_err("Cannot display the quick menu : " .. msg)
        end
    end
end

function COSTLogger:log_dev (msg)
    if COSTConfig.dev and msg then
        log("[CustomOST] [DevLog] : " .. msg)
    end
end