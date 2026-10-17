-- K5-HUB IRONSOUL V4 STANDALONE LOADER
-- This loader references only files in the v4-standalone branch.
-- It does not load V2 files or fall back to main/V2.

local REPO_BASE = "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/v4-standalone/"
local BOOTSTRAP_URL = REPO_BASE .. "v4_standalone/bootstrap.lua"

local function log(message)
    message = "[K5-HUB V4 STANDALONE] " .. tostring(message)
    if type(warn) == "function" then pcall(warn, message) end
    if type(print) == "function" then pcall(print, message) end
end

log("Loader started.")

if type(game) ~= "userdata" and type(game) ~= "table" then
    log("ERROR: Roblox game object is unavailable.")
    return
end

local okFetch, source = pcall(function()
    return game:HttpGet(BOOTSTRAP_URL)
end)

if not okFetch then
    log("ERROR: Could not download standalone bootstrap: " .. tostring(source))
    return
end

if type(source) ~= "string" or #source < 100 then
    log("ERROR: Bootstrap response is empty or too short.")
    return
end

if not string.find(source, "K5-HUB V4 STANDALONE BOOTSTRAP", 1, true) then
    log("ERROR: Downloaded response does not look like the expected bootstrap.")
    return
end

if type(loadstring) ~= "function" then
    log("ERROR: loadstring is unavailable in this executor.")
    return
end

local compileOk, chunkOrError = pcall(loadstring, source)
if not compileOk or type(chunkOrError) ~= "function" then
    log("ERROR: Bootstrap compile failed: " .. tostring(chunkOrError))
    return
end

local runOk, runError = pcall(chunkOrError)
if not runOk then
    log("ERROR: Bootstrap runtime failed: " .. tostring(runError))
    return
end

log("Standalone bootstrap returned without a top-level error.")
