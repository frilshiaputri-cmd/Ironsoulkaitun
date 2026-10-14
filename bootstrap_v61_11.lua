--========================================================--
-- K5HUB V1 - MOBILE/STABLE BOOT WITH DIAGNOSTICS
--========================================================--

getgenv().IronSoulConfig =
    getgenv().IronSoulConfig
    or {
        FPS_CAP = 8,
        FARM = "NEWBIE",
        TICKETS = "SMART",
        HEADLESS = true,
    }

local Config = getgenv().IronSoulConfig
local VERSION = "K5HubV1"
local BASE =
    "https://raw.githubusercontent.com/"
    .. "frilshiaputri-cmd/Ironsoulkaitun/main/"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local DIAG_FILE = "K5Hub_V1_Diagnostics.txt"
local DIAG_MAX_CHARS = 12000
local diagLines = {}
local function diag(level, message)
    local line = string.format(
        "[%s] [%s] place=%s user=%s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        tostring(level),
        tostring(game.PlaceId),
        LocalPlayer and tostring(LocalPlayer.Name) or "?",
        tostring(message)
    )
    table.insert(diagLines, line)
    while #diagLines > 80 do table.remove(diagLines, 1) end
    print("[K5Hub V1 Diagnostics] " .. line)
    if type(writefile) == "function" then
        pcall(function()
            local old = ""
            if type(readfile) == "function" and type(isfile) == "function" and isfile(DIAG_FILE) then
                old = readfile(DIAG_FILE) or ""
            end
            local combined = old .. (old ~= "" and "\\n" or "") .. line
            if #combined > DIAG_MAX_CHARS then
                combined = string.sub(combined, #combined - DIAG_MAX_CHARS + 1)
            end
            writefile(DIAG_FILE, combined)
        end)
    end
end
getgenv().K5HubDiagnostics = {
    Log = function(message) diag("INFO", message) end,
    Error = function(message) diag("ERROR", message) end,
    File = DIAG_FILE,
}
diag("INFO", "bootstrap entry started; version=K5Hub V1")

local LOBBY_PLACE_ID = 117533937949084

-- AUTO REDEEM DISABLED: the auto_redeem.lua module is intentionally not loaded.
getgenv().IronSoulAutoRedeemEnabled = false

-- At level 30, stop farming and leave the current server.
local LEVEL_STOP = tonumber(Config.LEVEL_STOP)
if LEVEL_STOP == nil then LEVEL_STOP = 30 end

if LEVEL_STOP > 0 then
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local dataModule
        local leavingAtCap = false

        local function readAuthoritativeLevel()
            if not dataModule or not dataModule.Parent then
                dataModule = nil
                for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                    if obj:IsA("ModuleScript") and obj.Name == "DataUtil" then
                        dataModule = obj
                        break
                    end
                end
            end

            if dataModule then
                local ok, util = pcall(require, dataModule)
                if ok and type(util) == "table"
                    and type(util.GetPlayerData) == "function" then
                    local okData, data = pcall(function()
                        return util:GetPlayerData(LocalPlayer)
                    end)
                    if okData and type(data) == "table"
                        and type(data.LevelData) == "table" then
                        local level = tonumber(data.LevelData.Level)
                        if level then return level end
                    end
                end
            end
            return tonumber(LocalPlayer:GetAttribute("LG_Level"))
        end

        while LocalPlayer and LocalPlayer.Parent do
            local level = readAuthoritativeLevel()
            if level and level >= LEVEL_STOP and not leavingAtCap then
                leavingAtCap = true
                getgenv().IronSoulLevelStopReached = true
                getgenv().IronSoulLevelStopLevel = level
                if type(getgenv().IronSoulConfig) == "table" then
                    getgenv().IronSoulConfig.FARM = "OFF"
                end
                diag("INFO", "Level cap reached (" .. tostring(level) .. "); leaving server")
                warn("[IronSoul] Level 30 reached; leaving the server.")
                task.wait(1)
                pcall(function()
                    LocalPlayer:Kick("Level 30 tercapai. Keluar otomatis dari server.")
                end)
                break
            end
            task.wait(0.5)
        end
    end)
end

-- Prevent duplicate queued copies in the same server/job.
do
    local key = tostring(game.PlaceId) .. "|" .. tostring(game.JobId)
    local old = getgenv().IronSoulBootstrapGuard
    if type(old) == "table"
        and old.Key == key
        and os.clock() - tonumber(old.At or 0) < 5
    then
        return
    end
    getgenv().IronSoulBootstrapGuard = { Key = key, At = os.clock() }
end

if type(setfpscap) == "function" and tonumber(Config.FPS_CAP) then
    pcall(setfpscap, tonumber(Config.FPS_CAP))
end

local function executorName()
    if type(identifyexecutor) == "function" then
        local ok, a, b = pcall(identifyexecutor)
        if ok then return tostring(a or b or "Unknown") end
    end
    if type(getexecutorname) == "function" then
        local ok, value = pcall(getexecutorname)
        if ok then return tostring(value or "Unknown") end
    end
    return "Unknown"
end

local function findRealTeleportQueue()
    local env = getgenv()
    local candidates = {
        {"queue_on_teleport", env.queue_on_teleport},
        {"queueonteleport", env.queueonteleport},
        {"queue_on_tp", env.queue_on_tp},
        {"queueontp", env.queueontp},
    }
    if type(syn) == "table" then
        table.insert(candidates, {"syn.queue_on_teleport", syn.queue_on_teleport})
    end
    if type(fluxus) == "table" then
        table.insert(candidates, {"fluxus.queue_on_teleport", fluxus.queue_on_teleport})
    end
    for _, row in ipairs(candidates) do
        if type(row[2]) == "function" then return row[2], row[1] end
    end
    return nil, "none"
end

local RealQueue, RealQueueName = findRealTeleportQueue()
local Caps = {
    Version = "K5Hub V1",
    Executor = executorName(),
    Touch = UserInputService.TouchEnabled == true,
    Queue = type(RealQueue) == "function",
    QueueName = RealQueueName,
    WriteFile = type(writefile) == "function",
    ReadFile = type(readfile) == "function",
    MakeFolder = type(makefolder) == "function",
    FireSignal = type(firesignal) == "function",
    GetConnections = type(getconnections) == "function",
    FirePrompt = type(fireproximityprompt) == "function",
    FireTouch = type(firetouchinterest) == "function",
}
getgenv().IronSoulExecutorCaps = Caps
getgenv().IronSoulTeleportQueueAvailable = Caps.Queue
getgenv().IronSoulManualQueueMode = not Caps.Queue

local statusLabel = nil
local stickyError = false
local function ensureStatusGui()
    if statusLabel and statusLabel.Parent then return statusLabel end
    if not Caps.Touch and Config.MOBILE_STATUS ~= true then return nil end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then return nil end
    local old = pg:FindFirstChild("IronSoulMobileStatus")
    if old then pcall(function() old:Destroy() end) end
    local gui = Instance.new("ScreenGui")
    gui.Name = "IronSoulMobileStatus"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 999999
    local label = Instance.new("TextLabel")
    label.Name = "Status"
    label.Active = false
    label.Selectable = false
    label.Size = UDim2.new(0, 350, 0, 50)
    label.Position = UDim2.new(0, 8, 0, 8)
    label.BackgroundTransparency = 0.25
    label.BorderSizePixel = 0
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.TextSize = 12
    label.Font = Enum.Font.Code
    label.Text = "K5Hub V1 | booting"
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label
    gui.Parent = pg
    statusLabel = label
    return label
end

local function status(message)
    local value = tostring(message or "")
    if string.sub(value, 1, 5) == "ERROR" or string.sub(value, 1, 5) == "STUCK" then
        stickyError = true
    elseif stickyError and string.sub(value, 1, 5) ~= "RESET" then
        return
    end
    diag((string.sub(value, 1, 5) == "ERROR" or string.sub(value, 1, 5) == "STUCK") and "ERROR" or "STATUS", value)
    local label = ensureStatusGui()
    if label then pcall(function() label.Text = "K5Hub V1 | " .. value end) end
    if type(writefile) == "function" then
        pcall(writefile, "K5Hub_V1_Status.txt", table.concat({
            "Version=K5Hub V1",
            "Executor=" .. tostring(Caps.Executor),
            "Touch=" .. tostring(Caps.Touch),
            "NativeQueue=" .. tostring(Caps.Queue),
            "QueueName=" .. tostring(Caps.QueueName),
            "ManualQueueMode=" .. tostring(not Caps.Queue),
            "WriteFile=" .. tostring(Caps.WriteFile),
            "ReadFile=" .. tostring(Caps.ReadFile),
            "FireSignal=" .. tostring(Caps.FireSignal),
            "GetConnections=" .. tostring(Caps.GetConnections),
            "FirePrompt=" .. tostring(Caps.FirePrompt),
            "FireTouch=" .. tostring(Caps.FireTouch),
            "PlaceId=" .. tostring(game.PlaceId),
            "Status=" .. value,
        }, "\n"))
    end
end
getgenv().IronSoulStatus = status

task.spawn(function()
    while LocalPlayer and LocalPlayer.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        diag("DATA", string.format(
            "heartbeat version=K5Hub V1 level=%s health=%s/%s world=%s queue=%s",
            tostring(LocalPlayer:GetAttribute("LG_Level") or "n/a"),
            tostring(humanoid and humanoid.Health or "n/a"),
            tostring(humanoid and humanoid.MaxHealth or "n/a"),
            tostring(workspace:GetAttribute("WorldName") or "n/a"),
            tostring(Caps.Queue)
        ))
        task.wait(30)
    end
end)

status("Boot | " .. tostring(Caps.Executor) .. " | nativeQueue=" .. tostring(Caps.Queue))

local function compatibilityQueue(payload)
    payload = tostring(payload or "")
    if type(RealQueue) == "function" then
        local ok, err = pcall(RealQueue, payload)
        if ok then return true end
        status("ERROR | native teleport queue failed | " .. tostring(err))
        return false
    end
    getgenv().IronSoulManualQueuedPayload = payload
    if type(writefile) == "function" then
        pcall(writefile, "IronSoul_Reexecute_AfterTeleport_V61_11.lua", payload)
    end
    status("Manual persistence | re-execute loader after teleport")
    return true
end
pcall(function() rawset(getgenv(), "queue_on_teleport", compatibilityQueue) end)

local fetchCounter = 0
local function cacheBust(path)
    fetchCounter += 1
    return BASE .. path .. "?isv=" .. VERSION .. "&n=" .. tostring(fetchCounter) .. "&t=" .. tostring(os.time())
end

local function normalizeSource(source)
    if type(source) ~= "string" then return nil, "source is not a string" end
    if string.sub(source, 1, 3) == "\239\187\191" then source = string.sub(source, 4) end
    local b1, b2 = string.byte(source, 1), string.byte(source, 2)
    if (b1 == 255 and b2 == 254) or (b1 == 254 and b2 == 255) then return nil, "UTF-16 source received" end
    local prefixes = {"\226\128\139", "\226\128\140", "\226\128\141", "\226\129\160"}
    local changed = true
    while changed do
        changed = false
        for _, prefix in ipairs(prefixes) do
            if string.sub(source, 1, #prefix) == prefix then
                source = string.sub(source, #prefix + 1)
                changed = true
            end
        end
    end
    return source
end

local function shortError(err)
    local value = tostring(err or "unknown")
    if #value > 190 then value = string.sub(value, 1, 190) .. "..." end
    return value
end

local function loadRaw(path)
    if getgenv().IronSoulLevelStopReached then
        status("LEVEL STOP | module load blocked")
        return false, "level limit reached"
    end
    status("Loading | " .. tostring(path))
    local ok, source = pcall(game.HttpGet, game, cacheBust(path))
    if not ok or type(source) ~= "string" then
        local message = "HTTP load failed | " .. tostring(path) .. " | " .. tostring(source)
        diag("ERROR", message); warn("[K5Hub V1] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local normalized, normalizeErr = normalizeSource(source)
    if not normalized then
        local message = "Source normalization failed | " .. tostring(path) .. " | " .. tostring(normalizeErr)
        warn("[K5Hub V1] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local fn, err = loadstring(normalized)
    if not fn then
        local message = "Compile failed | " .. tostring(path) .. " | " .. tostring(err)
        warn("[K5Hub V1] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local runOk, result = pcall(fn)
    if not runOk then
        local message = "Runtime failed | " .. tostring(path) .. " | " .. tostring(result)
        warn("[K5Hub V1] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    return true, result
end

-- MANUAL-ONLY MODE:
-- Never queue this bootstrap for automatic execution after teleport/map changes.
-- The user must execute LOADER.lua manually whenever they want to start the script.
local function queueBootstrap(reason)
    getgenv().IronSoulManualExecutionOnly = true
    getgenv().IronSoulManualQueuedPayload = nil
    status("Manual-only mode | auto execute on teleport disabled")
    return false
end
getgenv().IronSoulBaseURL = BASE
getgenv().IronSoulQueueBootstrap = queueBootstrap
getgenv().IronSoulLoadRaw = loadRaw
-- Intentionally do not queue on startup; run LOADER.lua manually each session/map.

local function looksLikeDungeon()
    local rs = game:GetService("ReplicatedStorage")
    local hasRound = rs:FindFirstChild("GameRoundCfg") ~= nil
    local hasCombatWorld = workspace:FindFirstChild("RoundDoor")
        or workspace:FindFirstChild("EnemyNpc")
        or workspace:FindFirstChild("WorldEnemys")
    return hasRound and hasCombatWorld
end

local route, routeName
if game.PlaceId == LOBBY_PLACE_ID or workspace:GetAttribute("WorldName") == "Lobby" then
    route, routeName = "systems/lobby.lua", "Lobby"
elseif looksLikeDungeon() then
    route, routeName = "systems/combat.lua", "Dungeon"
else
    for attempt = 1, 30 do
        task.wait(0.5)
        if game.PlaceId == LOBBY_PLACE_ID or workspace:GetAttribute("WorldName") == "Lobby" then
            route, routeName = "systems/lobby.lua", "Lobby"
            break
        elseif looksLikeDungeon() then
            route, routeName = "systems/combat.lua", "Dungeon"
            break
        end
    end
    if not route then
        local message = "Unknown place after 15s | " .. tostring(game.PlaceId)
            .. " | WorldName=" .. tostring(workspace:GetAttribute("WorldName"))
        warn("[K5Hub V1] " .. message); status(message)
        return
    end
end

getgenv().IronSoulRuntime = {
    Version = "K5Hub V1",
    Route = route,
    PlaceId = game.PlaceId,
    StartedAt = os.clock(),
    NativeTeleportQueue = Caps.Queue,
}
print("[K5Hub V1]", routeName)
status(routeName .. " | starting")
loadRaw(route)
