-- K5-HUB V4 STANDALONE BOOTSTRAP
-- This entry point loads only modules in v4_standalone/.
-- No V2 bootstrap, systems, patches, or main-branch fallback is used.

local BASE = "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/v4-standalone/v4_standalone/"

local function emit(message)
    local line = "[K5-HUB V4 STANDALONE] " .. tostring(message)
    if type(print) == "function" then pcall(print, line) end
    if type(warn) == "function" then pcall(warn, line) end
end

emit("K5-HUB V4 STANDALONE BOOTSTRAP started.")

local function loadModule(path)
    local okFetch, source = pcall(function()
        return game:HttpGet(BASE .. path)
    end)
    if not okFetch then
        return false, "download failed for " .. path .. ": " .. tostring(source)
    end
    if type(source) ~= "string" or #source < 10 then
        return false, "empty/invalid response for " .. path
    end
    local fn, compileError = loadstring(source)
    if type(fn) ~= "function" then
        return false, "compile failed for " .. path .. ": " .. tostring(compileError)
    end
    local okRun, result = pcall(fn)
    if not okRun then
        return false, "runtime failed for " .. path .. ": " .. tostring(result)
    end
    return true, result
end

local okDiag, Diagnostics = loadModule("diagnostics.lua")
if not okDiag or type(Diagnostics) ~= "table" then
    emit("FATAL: diagnostics module unavailable: " .. tostring(Diagnostics))
    return
end

local okConfig, Config = loadModule("config.lua")
if not okConfig or type(Config) ~= "table" then
    Diagnostics.error("Config module unavailable: " .. tostring(Config))
    return
end

getgenv().IronSoulV4Standalone = {
    Config = Config,
    Version = Config.VERSION,
    Started = os.time(),
}

Diagnostics.info("Configuration loaded.")
Diagnostics.info("Mode: " .. tostring(Config.FARM_MODE))
Diagnostics.info("Level stop: " .. tostring(Config.LEVEL_STOP))
Diagnostics.info("Auto Claim: " .. tostring(Config.AUTO_CLAIM))
Diagnostics.info("Auto Redeem: " .. tostring(Config.AUTO_REDEEM))
Diagnostics.info("Season Spin: " .. tostring(Config.SEASON_SPIN))
Diagnostics.warn("Standalone foundation is initialized; gameplay modules are not yet ported/reimplemented.")
