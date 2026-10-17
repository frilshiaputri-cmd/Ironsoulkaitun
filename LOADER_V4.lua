-- K5-Hub V4 - ROBUST PUBLIC LOADER
-- Manual start only. Does not auto-run on initial server/map entry.

local ENV = getgenv()
ENV.IronSoulConfig = {
    FPS_CAP = 60,
    FARM = "NEWBIE",
    TICKETS = "SMART",
    HEADLESS = true,
    DEBUG_LOGS = true,
    LEVEL_STOP = 30,
    AUTO_REDEEM = false,
    AUTO_CLAIM = false,
    AUTO_DAILY = false,
    AUTO_REWARDS = false,
    ANTI_AFK = true,
}

local URL = "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/v4-level30-no-auto-claim/bootstrap_v4.lua"

local function report(message)
    message = "[K5-Hub V4 Loader] " .. tostring(message)
    warn(message)
    print(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "K5-Hub V4 Loader",
            Text = tostring(message):sub(1, 180),
            Duration = 8,
        })
    end)
    if type(writefile) == "function" then
        pcall(writefile, "K5Hub_V4_Diagnostics.txt", os.date("%Y-%m-%d %H:%M:%S") .. "\n" .. message)
    end
end

local function fetchSource(url)
    local failures = {}

    -- Standard Roblox executor HTTP method.
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 100 then
        return body, "game:HttpGet"
    end
    table.insert(failures, "game:HttpGet=" .. tostring(ok and ("short response (" .. tostring(type(body) == "string" and #body or 0) .. " bytes)") or body))

    -- Some executor builds expose request/http_request instead.
    local requestFns = {}
    if type(ENV.request) == "function" then table.insert(requestFns, {"request", ENV.request}) end
    if type(ENV.http_request) == "function" then table.insert(requestFns, {"http_request", ENV.http_request}) end
    if type(http_request) == "function" then table.insert(requestFns, {"http_request", http_request}) end
    if type(syn) == "table" and type(syn.request) == "function" then table.insert(requestFns, {"syn.request", syn.request}) end

    for _, entry in ipairs(requestFns) do
        local name, fn = entry[1], entry[2]
        local reqOk, response = pcall(fn, {Url = url, Method = "GET"})
        if reqOk and type(response) == "table" then
            local statusCode = tonumber(response.StatusCode or response.Status or 0) or 0
            local responseBody = response.Body or response.body
            if type(responseBody) == "string" and #responseBody > 100 and (statusCode == 0 or statusCode == 200) then
                return responseBody, name
            end
            table.insert(failures, name .. "=" .. tostring(statusCode) .. "/" .. tostring(type(responseBody) == "string" and #responseBody or "no body"))
        else
            table.insert(failures, name .. "=" .. tostring(response))
        end
    end

    return nil, table.concat(failures, " | ")
end

local ok, err = pcall(function()
    report("Fetching bootstrap...")
    local source, methodOrError = fetchSource(URL)
    assert(type(source) == "string" and #source > 100,
        "Cannot download bootstrap. Check Delta HTTP access. " .. tostring(methodOrError))

    if not string.find(source, "K5%-Hub V4") then
        assert(not string.find(source, "404: Not Found", 1, true), "GitHub returned 404 for bootstrap URL")
        assert(not string.find(source, "<!DOCTYPE html>", 1, true), "GitHub returned HTML instead of Lua source")
    end

    report("Bootstrap downloaded (" .. tostring(#source) .. " bytes via " .. tostring(methodOrError) .. "); compiling...")
    local fn, compileErr = loadstring(source)
    assert(type(fn) == "function", "Bootstrap compile error: " .. tostring(compileErr))

    report("Starting bootstrap...")
    fn()
end)

if not ok then
    report("FAILED: " .. tostring(err))
end
