-- K5-HUB IRONSOUL V4 STANDALONE DIAGNOSTICS
-- Diagnostics are self-contained and do not import V2 code.

local Diagnostics = {}
local PREFIX = "[K5-HUB V4 STANDALONE]"

local function emit(method, message)
    local line = PREFIX .. " " .. tostring(message)
    if method == "warn" then
        if type(warn) == "function" then pcall(warn, line) end
    else
        if type(print) == "function" then pcall(print, line) end
    end
end

function Diagnostics.info(message)
    emit("print", "INFO | " .. tostring(message))
end

function Diagnostics.warn(message)
    emit("warn", "WARN | " .. tostring(message))
end

function Diagnostics.error(message)
    emit("warn", "ERROR | " .. tostring(message))
end

return Diagnostics
