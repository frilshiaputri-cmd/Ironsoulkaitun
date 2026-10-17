-- K5-Hub V4 - PUBLIC LOADER
-- Manual start only. Does not auto-run on initial server/map entry.
getgenv().IronSoulConfig = {
    FPS_CAP = 60,
    FARM = "NEWBIE",
    TICKETS = "SMART",
    HEADLESS = true,
    DEBUG_LOGS = false,
    LEVEL_STOP = 30,
    AUTO_REDEEM = false,
    AUTO_CLAIM = false,
    AUTO_DAILY = false,
    AUTO_REWARDS = false,
    ANTI_AFK = true,
}

local ok, result = pcall(function()
    local source = game:HttpGet(
        "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/bootstrap_v4.lua?t="
            .. tostring(os.time())
    )
    local fn, err = loadstring(source)
    assert(fn, err)
    return fn()
end)

if not ok then
    local message = "[K5-Hub V4] LOADER ERROR | " .. tostring(result)
    warn(message)
    if type(writefile) == "function" then
        pcall(function()
            local path = "K5Hub_V4_Diagnostics.txt"
            local old = ""
            if type(readfile) == "function" and type(isfile) == "function" and isfile(path) then
                old = readfile(path) or ""
            end
            local combined = old .. (old ~= "" and "\\n" or "") .. os.date("%Y-%m-%d %H:%M:%S") .. " " .. message
            if #combined > 12000 then
                combined = string.sub(combined, #combined - 11999)
            end
            writefile(path, combined)
        end)
    end
end
