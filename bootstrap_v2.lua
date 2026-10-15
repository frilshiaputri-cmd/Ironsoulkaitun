--========================================================--
-- K5HUB V1 - MOBILE/STABLE BOOT WITH DIAGNOSTICS
--========================================================--

getgenv().IronSoulConfig =
    getgenv().IronSoulConfig
    or {
        FPS_CAP = 60,
        FARM = "NEWBIE",
        TICKETS = "SMART",
        HEADLESS = true,
    }

local Config = getgenv().IronSoulConfig
local VERSION = "K5HUB_IRONSOUL_V2"
local BASE =
    "https://raw.githubusercontent.com/"
    .. "frilshiaputri-cmd/Ironsoulkaitun/main/"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local DIAG_FILE = "K5Hub_V2_Diagnostics.txt"
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
    print("[K5-HUB IRONSOUL V2 Diagnostics] " .. line)
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
diag("INFO", "bootstrap entry started; version=K5-HUB IRONSOUL V2")

local LOBBY_PLACE_ID = 117533937949084

-- Level-cap monitor is handled directly by this bootstrap; no auto_redeem_v2 module is used.
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
                diag("INFO", "Level cap reached (" .. tostring(level) .. "); Auto Redeem disabled; kicking player")
                warn("[IronSoul] Level 30 reached; Auto Redeem is disabled. Leaving server.")
                task.wait(1)
                pcall(function()
                    LocalPlayer:Kick("Level 30 tercapai. Auto Redeem nonaktif; keluar dari server.")
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
    Version = "K5-HUB IRONSOUL V2",
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
    label.Text = "K5-HUB IRONSOUL V2 | booting"
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
    if label then pcall(function() label.Text = "K5-HUB IRONSOUL V2 | " .. value end) end
    if type(writefile) == "function" then
        pcall(writefile, "K5Hub_V2_Status.txt", table.concat({
            "Version=K5-HUB IRONSOUL V2",
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

-- MASTER ON/OFF: controls the whole K5-HUB session, not just graphics.
-- Modules can poll IronSoulMasterEnabled; managed connections/threads are stopped on OFF.
local function setMasterEnabled(value)
    local env = getgenv()
    env.IronSoulMasterEnabled = value == true
    local cfg = env.IronSoulConfig
    if type(cfg) == "table" then
        if value == true then
            if env.IronSoulPreviousFarmMode ~= nil then
                cfg.FARM = env.IronSoulPreviousFarmMode
                env.IronSoulPreviousFarmMode = nil
            end
        else
            if cfg.FARM ~= "OFF" then env.IronSoulPreviousFarmMode = cfg.FARM end
            cfg.FARM = "OFF"
        end
    end
    if value ~= true then
        env.IronSoulStopRequested = true
        if type(env.IronSoulManagedConnections) == "table" then
            for _, connection in pairs(env.IronSoulManagedConnections) do
                pcall(function() connection:Disconnect() end)
            end
            table.clear(env.IronSoulManagedConnections)
        end
        if type(env.IronSoulManagedThreads) == "table" then
            for _, thread in pairs(env.IronSoulManagedThreads) do
                pcall(task.cancel, thread)
            end
            table.clear(env.IronSoulManagedThreads)
        end
    else
        env.IronSoulStopRequested = false
    end
    local perf = env.K5PerformanceBooster
    if type(perf) == "table" and type(perf.SetEnabled) == "function" then
        pcall(perf.SetEnabled, value == true)
    end
    local statusFn = env.IronSoulStatus
    if type(statusFn) == "function" then
        pcall(statusFn, value and "MASTER ON | K5-HUB systems enabled" or "MASTER OFF | stop requested; farm mode OFF")
    end
    local btn = env.IronSoulMasterToggleButton
    if btn then
        pcall(function()
            btn.Text = value and "K5-HUB V2: ON" or "K5-HUB V2: OFF"
            btn.BackgroundColor3 = value and Color3.fromRGB(44, 130, 80) or Color3.fromRGB(115, 65, 65)
        end)
    end
end
getgenv().IronSoulSetMasterEnabled = setMasterEnabled
getgenv().IronSoulMasterEnabled = getgenv().IronSoulMasterEnabled ~= false
getgenv().IronSoulManagedConnections = getgenv().IronSoulManagedConnections or {}
getgenv().IronSoulManagedThreads = getgenv().IronSoulManagedThreads or {}

local function buildMasterToggle()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then return end
    local old = pg:FindFirstChild("K5MasterToggleGui")
    if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "K5MasterToggleGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 1000001
    local button = Instance.new("TextButton")
    button.Name = "MasterToggle"
    button.Size = UserInputService.TouchEnabled and UDim2.fromOffset(170, 32) or UDim2.fromOffset(190, 32)
    button.Position = UDim2.new(0, 8, 0, 62)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button
    button.Activated:Connect(function()
        setMasterEnabled(getgenv().IronSoulMasterEnabled ~= true)
    end)
    gui.Parent = pg
    getgenv().IronSoulMasterToggleButton = button
    setMasterEnabled(getgenv().IronSoulMasterEnabled ~= false)
end

task.spawn(buildMasterToggle)

-- V2 Anti-AFK: react to Roblox's idle signal without running a constant jump loop.
-- This can reduce idle-disconnect risk, but cannot prevent server-side kicks,
-- network loss, maintenance, or experience-specific AFK rules.
if Config.ANTI_AFK ~= false and LocalPlayer then
    local antiAfkConnected = false
    local function handleIdle()
        local ok, VirtualUser = pcall(function()
            return game:GetService("VirtualUser")
        end)
        local inputWorked = false
        if ok and VirtualUser then
            inputWorked = pcall(function()
                local camera = workspace.CurrentCamera
                VirtualUser:CaptureController()
                VirtualUser:Button2Down(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
                task.wait(0.8)
                VirtualUser:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
            end)
        end
        if not inputWorked then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                pcall(function()
                    humanoid.Jump = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
        end
        diag("INFO", "Anti-AFK idle signal handled")
    end
    local ok, connection = pcall(function()
        return LocalPlayer.Idled:Connect(handleIdle)
    end)
    antiAfkConnected = ok and connection ~= nil
    getgenv().IronSoulAntiAfkStatus = antiAfkConnected and "connected" or "unavailable"
    diag("INFO", "Anti-AFK status=" .. tostring(getgenv().IronSoulAntiAfkStatus))
end

task.spawn(function()
    while LocalPlayer and LocalPlayer.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        diag("DATA", string.format(
            "heartbeat version=K5-HUB IRONSOUL V2 level=%s health=%s/%s world=%s queue=%s",
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
        pcall(writefile, "IronSoul_Reexecute_AfterTeleport_V2.lua", payload)
    end
    status("Native teleport queue unavailable | manual re-execution required")
    return false
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
    if getgenv().IronSoulMasterEnabled == false and path ~= "systems/performance_booster.lua" then
        status("MASTER OFF | module blocked: " .. tostring(path))
        return false, "K5-HUB master switch is OFF"
    end
    if getgenv().IronSoulLevelStopReached and path ~= "systems/performance_booster.lua" then
        status("LEVEL STOP | farm module load blocked")
        return false, "level limit reached"
    end
    status("Loading | " .. tostring(path))
    local ok, source = pcall(game.HttpGet, game, cacheBust(path))
    if not ok or type(source) ~= "string" then
        local message = "HTTP load failed | " .. tostring(path) .. " | " .. tostring(source)
        diag("ERROR", message); warn("[K5-HUB IRONSOUL V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local normalized, normalizeErr = normalizeSource(source)
    if not normalized then
        local message = "Source normalization failed | " .. tostring(path) .. " | " .. tostring(normalizeErr)
        warn("[K5-HUB IRONSOUL V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local fn, err = loadstring(normalized)
    if not fn then
        local message = "Compile failed | " .. tostring(path) .. " | " .. tostring(err)
        warn("[K5-HUB IRONSOUL V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local runOk, result = pcall(fn)
    if not runOk then
        local message = "Runtime failed | " .. tostring(path) .. " | " .. tostring(result)
        warn("[K5-HUB IRONSOUL V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    return true, result
end

-- MANUAL START, SESSION CONTINUATION:
-- This function is called only when an already-running, manually started
-- session deliberately schedules a cross-place transition. It does not run
-- the loader on initial join or merely because a map was opened.
local function queueBootstrap(reason)
    if getgenv().IronSoulMasterEnabled == false then
        status("MASTER OFF | teleport continuation not queued")
        return false
    end
    if type(RealQueue) ~= "function" then
        getgenv().IronSoulManualExecutionOnly = true
        status("Teleport continuation unavailable | executor has no native queue; run LOADER.lua manually after teleport")
        return false
    end

    local config = getgenv().IronSoulConfig or {}
    local payload = string.format([[
task.wait(1.35)
getgenv().IronSoulConfig = {
    FPS_CAP = %s,
    FARM = %q,
    TICKETS = %q,
    HEADLESS = %s,
    DEBUG_LOGS = %s,
    LEVEL_STOP = %s,
}
local source = game:HttpGet(%q .. "?t=" .. tostring(os.time()))
local fn, err = loadstring(source)
assert(fn, err)
fn()
]],
        tostring(tonumber(config.FPS_CAP) or 60),
        tostring(config.FARM or "NEWBIE"),
        tostring(config.TICKETS or "SMART"),
        tostring(config.HEADLESS ~= false),
        tostring(config.DEBUG_LOGS == true),
        tostring(tonumber(config.LEVEL_STOP) or 30),
        BASE .. "bootstrap_v2.lua"
    )

    local ok, err = pcall(RealQueue, payload)
    if not ok then
        status("ERROR | teleport continuation queue failed | " .. tostring(err))
        return false
    end

    getgenv().IronSoulManualExecutionOnly = false
    status("Teleport continuation queued | " .. tostring(reason or "cross-place transition"))
    return true
end
getgenv().IronSoulBaseURL = BASE
getgenv().IronSoulQueueBootstrap = queueBootstrap
getgenv().IronSoulLoadRaw = loadRaw

-- Auto-start the graphics/FPS helper whenever this bootstrap is run on a map.
-- This does not auto-run the full farm script on a fresh join without the loader.
task.spawn(function()
    local perfOk, perfErr = loadRaw("systems/performance_booster.lua")
    if not perfOk then
        diag("ERROR", "Performance Booster failed: " .. tostring(perfErr))
    end
end)
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
        warn("[K5-HUB IRONSOUL V2] " .. message); status(message)
        return
    end
end

getgenv().IronSoulRuntime = {
    Version = "K5-HUB IRONSOUL V2",
    Route = route,
    PlaceId = game.PlaceId,
    StartedAt = os.clock(),
    NativeTeleportQueue = Caps.Queue,
}
print("[K5-HUB IRONSOUL V2]", routeName)
status(routeName .. " | starting")
local routeOk = loadRaw(route)
return routeOk
