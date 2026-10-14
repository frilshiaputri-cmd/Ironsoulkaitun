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

-- K5Hub V1 diagnostics: keep recent events and runtime snapshots for debugging.
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

local TUTORIAL_PLACE_ID = 76701861705540
local LOBBY_PLACE_ID = 117533937949084

-- LEVEL CAP: at/above the cap, stop farming and return to the lobby.
-- Do not kick the player. Auto Redeem is gated separately to run only in lobby.
local LEVEL_STOP = tonumber(Config.LEVEL_STOP)
if LEVEL_STOP == nil then LEVEL_STOP = 30 end

if LEVEL_STOP > 0 then
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local TeleportService = game:GetService("TeleportService")
        local dataModule
        local handlingCap = false

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

        while not handlingCap and LocalPlayer.Parent do
            local level = readAuthoritativeLevel()
            if level and level >= LEVEL_STOP then
                handlingCap = true
                getgenv().IronSoulLevelStopReached = true
                getgenv().IronSoulLevelStopLevel = level
                if type(getgenv().IronSoulConfig) == "table" then
                    getgenv().IronSoulConfig.FARM = "OFF"
                end

                if game.PlaceId ~= LOBBY_PLACE_ID then
                    warn("[IronSoul] Level cap reached; returning to lobby instead of kicking.")
                    local ok, err = pcall(function()
                        TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
                    end)
                    if not ok then
                        warn("[IronSoul] Lobby teleport failed: " .. tostring(err))
                        -- Keep the player in-game; never force-kick on failure.
                        handlingCap = false
                        task.wait(3)
                    end
                else
                    print("[IronSoul] Level cap reached in lobby; farming disabled.")
                end
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

    getgenv().IronSoulBootstrapGuard = {
        Key = key,
        At = os.clock(),
    }
end

-- Headless K5 Auto Redeem feature only; no K5 UI is loaded.
task.spawn(function()
    local url = "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/systems/auto_redeem.lua"
    local ok, err = pcall(function()
        local source = game:HttpGet(url .. "?t=" .. tostring(os.time()))
        local fn, loadErr = loadstring(source)
        assert(fn, loadErr)
        fn()
    end)
    if not ok then
        warn("[IronSoul AutoRedeem] Loader failed: " .. tostring(err))
    end
end)

if type(setfpscap) == "function"
    and tonumber(Config.FPS_CAP)
then
    pcall(setfpscap, tonumber(Config.FPS_CAP))
end

local function executorName()
    if type(identifyexecutor) == "function" then
        local ok, a, b = pcall(identifyexecutor)
        if ok then
            return tostring(a or b or "Unknown")
        end
    end

    if type(getexecutorname) == "function" then
        local ok, value = pcall(getexecutorname)
        if ok then
            return tostring(value or "Unknown")
        end
    end

    return "Unknown"
end

-- IMPORTANT: discover the REAL executor queue before installing any
-- compatibility alias. This prevents our manual fallback from masquerading
-- as a native persistent queue capability.
local function findRealTeleportQueue()
    local env = getgenv()
    local candidates = {
        {"queue_on_teleport", env.queue_on_teleport},
        {"queueonteleport", env.queueonteleport},
        {"queue_on_tp", env.queue_on_tp},
        {"queueontp", env.queueontp},
    }

    if type(syn) == "table" then
        table.insert(candidates, {
            "syn.queue_on_teleport",
            syn.queue_on_teleport,
        })
    end

    if type(fluxus) == "table" then
        table.insert(candidates, {
            "fluxus.queue_on_teleport",
            fluxus.queue_on_teleport,
        })
    end

    for _, row in ipairs(candidates) do
        if type(row[2]) == "function" then
            return row[2], row[1]
        end
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
    if statusLabel and statusLabel.Parent then
        return statusLabel
    end

    if not Caps.Touch and Config.MOBILE_STATUS ~= true then
        return nil
    end

    local pg =
        LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 5)

    if not pg then
        return nil
    end

    local old = pg:FindFirstChild("IronSoulMobileStatus")
    if old then
        pcall(function() old:Destroy() end)
    end

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

local function status(text)
    text = tostring(text or "")

    if string.sub(text, 1, 5) == "ERROR"
        or string.sub(text, 1, 5) == "STUCK"
    then
        stickyError = true
    elseif stickyError
        and string.sub(text, 1, 5) ~= "RESET"
    then
        return
    end

    diag((string.sub(text, 1, 5) == "ERROR" or string.sub(text, 1, 5) == "STUCK") and "ERROR" or "STATUS", text)
    local line = "K5Hub V1 | " .. text
    local label = ensureStatusGui()

    if label then
        pcall(function() label.Text = line end)
    end

    if type(writefile) == "function" then
        pcall(
            writefile,
            "K5Hub_V1_Status.txt",
            table.concat({
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
                "Status=" .. text,
            }, "\n")
        )
    end
end

getgenv().IronSoulStatus = status

-- Periodic diagnostic heartbeat: captures level/health and data readiness.
task.spawn(function()
    while LocalPlayer and LocalPlayer.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local health = humanoid and humanoid.Health or "n/a"
        local maxHealth = humanoid and humanoid.MaxHealth or "n/a"
        diag("DATA", string.format(
            "heartbeat version=K5Hub V1 level=%s health=%s/%s world=%s queue=%s",
            tostring(LocalPlayer:GetAttribute("LG_Level") or "n/a"),
            tostring(health),
            tostring(maxHealth),
            tostring(workspace:GetAttribute("WorldName") or "n/a"),
            tostring(Caps.Queue)
        ))
        task.wait(30)
    end
end)

status(
    "Boot | "
        .. tostring(Caps.Executor)
        .. " | nativeQueue="
        .. tostring(Caps.Queue)
)

--========================================================--
-- TELEPORT QUEUE COMPATIBILITY
--
-- Proven lobby V60/V61 expects a global queue_on_teleport symbol. Mobile
-- executors often expose a different alias. Normalize that here BEFORE
-- lobby.lua loads instead of patching the lobby's early environment block.
--
-- If there is no native queue at all, the compatibility function stores the
-- payload so lobby progression can still continue. The user then re-executes
-- the normal loader after teleport. We keep NativeQueue=false in diagnostics.
--========================================================--

local function compatibilityQueue(payload)
    -- Permit the bootstrap to re-run after teleporting back to the lobby.
    -- systems/lobby.lua separately blocks dungeon scheduling at the level cap.
    payload = tostring(payload or "")

    if type(RealQueue) == "function" then
        local ok, err = pcall(RealQueue, payload)

        if ok then
            return true
        end

        status("ERROR | native teleport queue failed | " .. tostring(err))
        return false
    end

    getgenv().IronSoulManualQueuedPayload = payload

    if type(writefile) == "function" then
        pcall(
            writefile,
            "IronSoul_Reexecute_AfterTeleport_V61_11.lua",
            payload
        )
    end

    -- Return success to the historical lobby so it does not abort. This does
    -- NOT claim native persistence; IronSoulTeleportQueueAvailable remains
    -- false and the HUD/status file explicitly says ManualQueueMode=true.
    status(
        "Manual persistence | re-execute loader after teleport"
    )

    return true
end

-- Normalize the name expected by the proven lobby script.
pcall(function()
    rawset(
        getgenv(),
        "queue_on_teleport",
        compatibilityQueue
    )
end)

local fetchCounter = 0

local function cacheBust(path)
    fetchCounter += 1

    return BASE
        .. path
        .. "?isv=" .. VERSION
        .. "&n=" .. tostring(fetchCounter)
        .. "&t=" .. tostring(os.time())
end

local function normalizeSource(source)
    if type(source) ~= "string" then
        return nil, "source is not a string"
    end

    if string.sub(source, 1, 3) == "\239\187\191" then
        source = string.sub(source, 4)
    end

    local b1 = string.byte(source, 1)
    local b2 = string.byte(source, 2)

    if (b1 == 255 and b2 == 254)
        or (b1 == 254 and b2 == 255)
    then
        return nil, "UTF-16 source received"
    end

    local prefixes = {
        "\226\128\139",
        "\226\128\140",
        "\226\128\141",
        "\226\129\160",
    }

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
    local text = tostring(err or "unknown")
    if #text > 190 then
        text = string.sub(text, 1, 190) .. "..."
    end
    return text
end

local function loadRaw(path)
    if getgenv().IronSoulLevelStopReached then
        status("LEVEL STOP | module load blocked")
        return false, "level limit reached"
    end
    status("Loading | " .. tostring(path))

    local ok, source =
        pcall(game.HttpGet, game, cacheBust(path))

    if not ok or type(source) ~= "string" then
        local message =
            "HTTP load failed | "
            .. tostring(path)
            .. " | "
            .. tostring(source)

        diag("ERROR", message)
        warn("[K5Hub V1] " .. message)
        status("ERROR | " .. shortError(message))
        return false
    end

    local normalized, normalizeErr = normalizeSource(source)

    if not normalized then
        local message =
            "Source normalization failed | "
            .. tostring(path)
            .. " | "
            .. tostring(normalizeErr)

        warn("[K5Hub V1] " .. message)
        status("ERROR | " .. shortError(message))
        return false
    end

    local fn, err = loadstring(normalized)

    if not fn then
        local message =
            "Compile failed | "
            .. tostring(path)
            .. " | "
            .. tostring(err)

        warn("[K5Hub V1] " .. message)
        status("ERROR | " .. shortError(message))
        return false
    end

    local runOk, result = pcall(fn)

    if not runOk then
        local message =
            "Runtime failed | "
            .. tostring(path)
            .. " | "
            .. tostring(result)

        warn("[K5Hub V1] " .. message)
        status("ERROR | " .. shortError(message))
        return false
    end

    return true, result
end

local function queueBootstrap(reason)
    local payload = string.format([[
task.wait(1.35)
getgenv().IronSoulConfig = getgenv().IronSoulConfig or {
    FPS_CAP = %s,
    FARM = %q,
    TICKETS = %q,
    HEADLESS = %s,
    LEVEL_STOP = %s,
}
loadstring(game:HttpGet(
    %q .. "?isv=k5hub-v1&t=" .. tostring(os.time())
))()
]],
        tostring(tonumber(Config.FPS_CAP) or 8),
        tostring(Config.FARM or "NEWBIE"),
        tostring(Config.TICKETS or "SMART"),
        tostring(Config.HEADLESS ~= false),
        tostring(LEVEL_STOP),
        BASE .. "bootstrap_v61_11.lua"
    )

    local ok = compatibilityQueue(payload)

    if ok and Caps.Queue then
        status(
            "Queued next teleport | "
                .. tostring(Caps.QueueName)
        )
    elseif ok then
        status(
            "Manual persistence | "
                .. tostring(reason)
                .. " | re-execute after teleport"
        )
    end

    return ok
end

getgenv().IronSoulBaseURL = BASE
getgenv().IronSoulQueueBootstrap = queueBootstrap
getgenv().IronSoulLoadRaw = loadRaw

-- Arm the next teleport on every map, not only when lobby.lua happens to run.
-- Native executor queue is required for true automatic re-execution after teleport.
queueBootstrap("arm next teleport from current place")

local function looksLikeDungeon()
    local rs = game:GetService("ReplicatedStorage")

    local hasRound =
        rs:FindFirstChild("GameRoundCfg") ~= nil

    local hasCombatWorld =
        workspace:FindFirstChild("RoundDoor")
        or workspace:FindFirstChild("EnemyNpc")
        or workspace:FindFirstChild("WorldEnemys")

    return hasRound and hasCombatWorld
end

local route
local routeName

if game.PlaceId == TUTORIAL_PLACE_ID then
    -- Tutorial automation disabled: do not load systems/tutorial*.lua.
    -- Move directly to the lobby so the normal lobby flow can take over.
    status("Tutorial system disabled | returning to Lobby")
    local TeleportService = game:GetService("TeleportService")
    local ok, err = pcall(function()
        TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
    end)
    if not ok then
        status("ERROR | tutorial disabled but Lobby teleport failed | " .. shortError(err))
    end
    return

elseif game.PlaceId == LOBBY_PLACE_ID
    or workspace:GetAttribute("WorldName") == "Lobby"
then
    route = "systems/lobby.lua"
    routeName = "Lobby"

elseif looksLikeDungeon() then
    route = "systems/combat.lua"
    routeName = "Dungeon"
else
    -- World/round objects can appear several seconds after the teleport finishes.
    -- Retry route detection instead of exiting immediately during map loading.
    for attempt = 1, 30 do
        task.wait(0.5)

        if game.PlaceId == TUTORIAL_PLACE_ID then
            -- Tutorial automation is disabled; return to Lobby instead.
            local TeleportService = game:GetService("TeleportService")
            pcall(function()
                TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
            end)
            status("Tutorial system disabled | returning to Lobby")
            return
        elseif game.PlaceId == LOBBY_PLACE_ID
            or workspace:GetAttribute("WorldName") == "Lobby"
        then
            route = "systems/lobby.lua"
            routeName = "Lobby"
            break
        elseif looksLikeDungeon() then
            route = "systems/combat.lua"
            routeName = "Dungeon"
            break
        end
    end

    if not route then
        local message =
            "Unknown place after 15s | "
            .. tostring(game.PlaceId)
            .. " | WorldName="
            .. tostring(workspace:GetAttribute("WorldName"))

        warn("[K5Hub V1] " .. message)
        status(message)
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
