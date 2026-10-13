-- K5HUB V1 - DIAGNOSTIC ENTRY LOADER
-- Keeps the public entry URL stable and reports download/compile/runtime errors.

local DIAG_FILE = "K5Hub_V1_Diagnostics.txt"
local function report(stage, detail)
    local line = string.format(
        "[%s] [ERROR] stage=%s place=%s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        tostring(stage),
        tostring(game.PlaceId),
        tostring(detail)
    )
    warn("[K5Hub V1] " .. line)
    if type(writefile) == "function" then
        pcall(function()
            local old = ""
            if type(readfile) == "function" and type(isfile) == "function" and isfile(DIAG_FILE) then
                old = readfile(DIAG_FILE) or ""
            end
            local combined = old .. (old ~= "" and "\\n" or "") .. line
            if #combined > 12000 then
                combined = string.sub(combined, #combined - 11999)
            end
            writefile(DIAG_FILE, combined)
        end)
    end
end

local url =
    "https://raw.githubusercontent.com/"
    .. "frilshiaputri-cmd/Ironsoulkaitun/main/bootstrap_v61_11.lua"
    .. "?t="
    .. tostring(os.time())

local ok, source = pcall(function()
    return game:HttpGet(url)
end)
if not ok or type(source) ~= "string" then
    report("HTTP_GET bootstrap_v61_11.lua", source)
    return
end

local fn, err = loadstring(source)
if not fn then
    report("COMPILE bootstrap_v61_11.lua", err)
    return
end

local runOk, result = pcall(fn)
if not runOk then
    report("RUNTIME bootstrap_v61_11.lua", result)
end
return result
