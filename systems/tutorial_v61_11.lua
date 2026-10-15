--========================================================--
-- IRON SOUL V61.11 - MOBILE-SAFE TUTORIAL / STARTER
--
-- Fresh account:
--   Sword -> real Skip Tutorial button signal -> verify teleport -> Lobby
-- Uses real executor queue capability status from bootstrap_v61_11.
--========================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local LOBBY_PLACE_ID = 117533937949084

-- Forward declarations: helper functions are assigned below before use.
local fireSignal, virtualClick

local function status(text)
    local fn = getgenv().IronSoulStatus
    if type(fn) == "function" then
        pcall(fn, "Tutorial | " .. tostring(text))
    end
end

local function findByName(root, wanted, className)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == wanted
            and (
                not className
                or obj:IsA(className)
            )
        then
            return obj
        end
    end
end

local function req(name)
    local obj = findByName(
        ReplicatedStorage,
        name,
        "ModuleScript"
    )

    if not obj then
        return nil
    end

    local ok, value = pcall(require, obj)
    return ok and value or nil
end

local teleportStarted = false
local teleportConn = LocalPlayer.OnTeleport:Connect(
    function(state, placeId)
        if string.find(
            tostring(state),
            "Failed",
            1,
            true
        ) == nil
        then
            teleportStarted = true
            status(
                "teleport started | "
                    .. tostring(state)
                    .. " | place="
                    .. tostring(placeId)
            )
        end
    end
)

local function waitTeleport(timeout)
    local deadline = os.clock() + (timeout or 4)

    while os.clock() < deadline do
        if teleportStarted
            or game.PlaceId == LOBBY_PLACE_ID
        then
            return true
        end

        task.wait(0.08)
    end

    return false
end

-- Queue the next bootstrap when the executor genuinely supports it. The
-- compatibility helper may also save a manual payload, but we report that
-- truthfully instead of pretending it is native persistence.
local queueBootstrap = getgenv().IronSoulQueueBootstrap

if type(queueBootstrap) == "function" then
    pcall(queueBootstrap, "tutorial -> lobby")
end

if getgenv().IronSoulTeleportQueueAvailable == true then
    status("native teleport persistence ready")
else
    status("no native teleport queue | re-execute loader once in Lobby")
end

fireSignal = function(signal)
    if not signal then
        return false
    end

    if type(firesignal) == "function"
        and pcall(firesignal, signal)
    then
        return true
    end

    if type(getconnections) == "function" then
        local ok, connections = pcall(getconnections, signal)

        if ok and type(connections) == "table" then
            for _, conn in ipairs(connections) do
                if type(conn.Function) == "function"
                    and pcall(conn.Function)
                then
                    return true
                end

                if type(conn.Fire) == "function"
                    and pcall(conn.Fire, conn)
                then
                    return true
                end
            end
        end
    end

    return false
end


virtualClick = function(button)
    if not button then
        return false
    end

    local pos = button.AbsolutePosition
    local size = button.AbsoluteSize
    local x = math.floor(pos.X + size.X * 0.5)
    local y = math.floor(pos.Y + size.Y * 0.5)

    return pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(
            x, y, 0, true, game, 0
        )
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(
            x, y, 0, false, game, 0
        )
    end)
end


--========================================================--
-- AUTO-SELECT LEFT STARTER CARD
--========================================================--

local function uiVisible(obj)
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg or not obj:IsA("GuiObject") then return false end
    local cur = obj
    while cur and cur ~= pg do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("ScreenGui") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    local p, s = obj.AbsolutePosition, obj.AbsoluteSize
    local cam = workspace.CurrentCamera
    local v = cam and cam.ViewportSize or Vector2.new(1000, 600)
    return s.X > 0 and s.Y > 0 and p.X < v.X and p.X+s.X > 0 and p.Y < v.Y and p.Y+s.Y > 0
end

local function ownText(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        return string.lower(tostring(obj.Text or ""))
    end
    return string.lower(tostring(obj.Name or ""))
end

local function nearestButton(obj)
    local cur = obj
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    while cur and cur ~= pg do
        if cur:IsA("GuiButton") then return cur end
        cur = cur.Parent
    end
end

local function clickGuiObject(obj)
    if not obj then return false, "NO_OBJECT" end
    local button = obj:IsA("GuiButton") and obj or nearestButton(obj)
    if button then
        if fireSignal(button.Activated) then return true, "Activated" end
        if fireSignal(button.MouseButton1Click) then return true, "MouseButton1Click" end
    end
    if obj:IsA("GuiObject") then
        return virtualClick(obj), "VirtualClick"
    end
    return false, "NOT_GUI_OBJECT"
end

local function findLeftSelectTarget(timeout)
    local deadline = os.clock() + (timeout or 12)
    while os.clock() < deadline do
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local candidates = {}
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do
                if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("GuiButton"))
                    and uiVisible(obj)
                then
                    local t = ownText(obj)
                    if string.find(t, "memilih", 1, true) then
                        local target = nearestButton(obj) or obj
                        if uiVisible(target) then table.insert(candidates, target) end
                    end
                end
            end
        end
        if #candidates > 0 then
            table.sort(candidates, function(a,b)
                return a.AbsolutePosition.X < b.AbsolutePosition.X
            end)
            return candidates[1]
        end
        task.wait(0.15)
    end
end

status("searching visible Memilih labels")
local weaponTarget = findLeftSelectTarget(12)
if weaponTarget then
    status("leftmost Memilih target found: " .. weaponTarget:GetFullName())
    local ok, method = clickGuiObject(weaponTarget)
    status("left weapon click attempt=" .. tostring(ok) .. " via=" .. tostring(method))
    task.wait(1)
else
    status("NO visible Memilih label found")
end

if waitTeleport(0.20) then return end

--========================================================--
-- SKIP TUTORIAL
--========================================================--

local function effectivelyVisible(obj)
    if not obj then
        return false
    end

    local current = obj

    while current
        and current ~= LocalPlayer
    do
        if current:IsA("GuiObject")
            and current.Visible == false
        then
            return false
        elseif current:IsA("ScreenGui")
            and current.Enabled == false
        then
            return false
        end

        if current == LocalPlayer.PlayerGui then
            break
        end

        current = current.Parent
    end

    return true
end

local function looksLikeSkip(button)
    if not button or not button:IsA("GuiButton") then
        return false
    end

    local texts = {
        tostring(button.Name or ""),
    }

    if button:IsA("TextButton") then
        table.insert(texts, tostring(button.Text or ""))
    end

    for _, child in ipairs(button:GetDescendants()) do
        if child:IsA("TextLabel")
            or child:IsA("TextButton")
        then
            table.insert(
                texts,
                tostring(child.Text or "")
            )
        end
    end

    -- Match common translations of "Skip Tutorial". Roblox games may
    -- localize the button text, so support several languages and common
    -- button identifiers. This is broad multilingual matching, not a
    -- guarantee for every language or custom localization.
    local skipTerms = {
        "skip", "skip tutorial", "skiptutorial",
        "lewati", "lewati tutorial", "lewati tutorial",
        "saltar", "omitir", "saltar tutorial",
        "überspringen", "uberspringen", "tutorial überspringen",
        "ignorer", "passer", "passer le tutoriel",
        "salta", "saltare", "ignora",
        "überspringe", "pular", "pular tutorial",
        "bỏ qua", "bo qua", "bỏ qua hướng dẫn",
        "跳过", "跳過", "スキップ", "チュートリアルをスキップ",
        "건너뛰기", "튜토리얼 건너뛰기",
        "пропустить", "пропустить обучение",
        "تخطي", "تخطي البرنامج التعليمي",
        "прескочи", "прескочить обучение",
        "skippen", "sla over", "overslaan",
        "spring over", "hoppa över", "ohita",
        "пропусти", "zaobiđi", "preskoči",
        "atlaist", "praleisti", "kihagyás",
        "átugrás", "preskočiť", "preskočiť tutoriál",
        "skippaa", "skip tutorial",
    }

    for _, label in ipairs(texts) do
        local low = string.lower(label)
        -- Remove separators for common identifier-style names, e.g. SkipTutorial.
        local compact = string.gsub(low, "[%s_%-]", "")

        for _, term in ipairs(skipTerms) do
            if low == term
                or string.find(low, term, 1, true)
                or string.find(compact, string.gsub(term, "[%s_%-]", ""), 1, true)
            then
                return true
            end
        end
    end

    return false
end

local function skipButtonLabels(button)
    local labels = { tostring(button.Name or "") }

    if button:IsA("TextButton") then
        table.insert(labels, tostring(button.Text or ""))
    end

    for _, child in ipairs(button:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            table.insert(labels, tostring(child.Text or ""))
        end
    end

    return labels
end

local function findSkipButton(timeout)
    local deadline = os.clock() + (timeout or 8)
    while os.clock() < deadline do
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local candidates = {}
        local cam = workspace.CurrentCamera
        local width = cam and cam.ViewportSize.X or 1000
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do
                if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("GuiButton"))
                    and uiVisible(obj)
                then
                    local t = ownText(obj)
                    local compact = string.gsub(t, "[%s_%-]", "")
                    local exact = string.find(t, "lewati tutorial", 1, true)
                        or string.find(compact, "lewatitutorial", 1, true)
                        or string.find(t, "skip tutorial", 1, true)
                        or string.find(compact, "skiptutorial", 1, true)
                    if exact then
                        local target = nearestButton(obj) or obj
                        if uiVisible(target) then
                            local p = target.AbsolutePosition
                            table.insert(candidates, {
                                target = target,
                                topRight = p.X > width * 0.5 and p.Y < 220
                            })
                        end
                    end
                end
            end
        end
        if #candidates > 0 then
            table.sort(candidates, function(a,b)
                if a.topRight ~= b.topRight then return a.topRight end
                return a.target.AbsolutePosition.Y < b.target.AbsolutePosition.Y
            end)
            return candidates[1].target
        end
        task.wait(0.15)
    end
end

local function activateSkip(button)
    if not button then
        return false, "NO_BUTTON"
    end

    status(
        "Skip Tutorial found | "
            .. tostring(button:GetFullName())
    )

    if fireSignal(button.Activated) then
        return true, "ACTIVATED"
    end

    if fireSignal(button.MouseButton1Click) then
        return true, "MOUSE_CLICK_SIGNAL"
    end

    if fireSignal(button.MouseButton1Down) then
        return true, "MOUSE_DOWN_SIGNAL"
    end

    if virtualClick(button) then
        return true, "VIRTUAL_CLICK"
    end

    return false, "NO_SUPPORTED_TRIGGER"
end

local skip = findSkipButton(4.5)

if skip then
    local sent, route = activateSkip(skip)

    status(
        "Skip sent="
            .. tostring(sent)
            .. " via="
            .. tostring(route)
    )

    if sent and waitTeleport(5.0) then
        return
    end
else
    status("Skip button not found | direct Lobby fallback")
end

--========================================================--
-- CLIENT LOBBY FALLBACK
--========================================================--

local errors = {}

for attempt = 1, 2 do
    status(
        "direct Lobby teleport | attempt "
            .. tostring(attempt)
    )

    local ok, err = pcall(function()
        TeleportService:Teleport(
            LOBBY_PLACE_ID,
            LocalPlayer
        )
    end)

    if not ok then
        table.insert(errors, tostring(err))
    end

    if ok and waitTeleport(4.0) then
        return
    end

    task.wait(0.45)
end

status(
    "STUCK | Lobby teleport did not start | "
        .. table.concat(errors, " | ")
)

warn(
    "[IronSoul V61.11] Tutorial could not start Lobby teleport: "
        .. table.concat(errors, " | ")
)

pcall(function()
    teleportConn:Disconnect()
end)
