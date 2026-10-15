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
-- AUTO-SELECT LEFT STARTER WEAPON CARD: SENJATA RINGAN
--========================================================--

-- On the game's starter screen the left card is labeled "Senjata Ringan"
-- and describes "Kecepatan Serangan/Mobilitas". The button itself says
-- "Memilih", so do not search for a button literally named "Sword".
local function swordButtonVisible(obj)
    local current = obj

    while current and current ~= LocalPlayer do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end
        if current:IsA("ScreenGui") and current.Enabled == false then
            return false
        end
        if current == LocalPlayer:FindFirstChildOfClass("PlayerGui") then
            break
        end
        current = current.Parent
    end

    return true
end

local function textOf(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        return tostring(obj.Text or "")
    end
    return tostring(obj.Name or "")
end

local function cardContainsLightSword(card)
    local labels = { string.lower(textOf(card)) }

    for _, child in ipairs(card:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            table.insert(labels, string.lower(tostring(child.Text or "")))
        end
    end

    for _, label in ipairs(labels) do
        local normalized = string.gsub(label, "%s+", "")
        if string.find(label, "senjata ringan", 1, true)
            or string.find(normalized, "senjateringan", 1, true)
            or string.find(label, "kecepatan serangan", 1, true)
            or string.find(label, "mobility", 1, true)
        then
            return true
        end
    end

    return false
end

local function findLightSwordSelectButton(timeout)
    local deadline = os.clock() + (timeout or 8)

    while os.clock() < deadline do
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if pg then
            -- Find the card by its displayed title/description, then click
            -- the "Memilih" button contained inside that same card.
            for _, label in ipairs(pg:GetDescendants()) do
                if (label:IsA("TextLabel") or label:IsA("TextButton"))
                    and string.find(string.lower(textOf(label)), "senjata ringan", 1, true)
                then
                    local ancestor = label.Parent
                    while ancestor and ancestor ~= pg do
                        if ancestor:IsA("GuiObject") and swordButtonVisible(ancestor)
                            and cardContainsLightSword(ancestor)
                        then
                            for _, item in ipairs(ancestor:GetDescendants()) do
                                if item:IsA("GuiButton") and swordButtonVisible(item) then
                                    local buttonText = string.lower(textOf(item))
                                    for _, child in ipairs(item:GetDescendants()) do
                                        if child:IsA("TextLabel") or child:IsA("TextButton") then
                                            buttonText = buttonText .. " " .. string.lower(tostring(child.Text or ""))
                                        end
                                    end

                                    if string.find(buttonText, "memilih", 1, true)
                                        or string.find(buttonText, "select", 1, true)
                                        or string.find(buttonText, "choose", 1, true)
                                    then
                                        return item
                                    end
                                end
                            end
                        end
                        ancestor = ancestor.Parent
                    end
                end
            end
        end

        task.wait(0.12)
    end
end

status("looking for left Senjata Ringan card")
local swordButton = findLightSwordSelectButton(8)

if swordButton then
    local selected, method = fireSignal(swordButton.Activated), "Activated"

    if not selected then
        selected = fireSignal(swordButton.MouseButton1Click)
        method = "MouseButton1Click"
    end

    if not selected then
        selected = virtualClick(swordButton)
        method = "VirtualClick"
    end

    status("left Senjata Ringan selected=" .. tostring(selected) .. " via=" .. method)
    task.wait(0.65)
else
    status("left Senjata Ringan card/button not found | continuing to Skip Tutorial")
end

if waitTeleport(0.20) then
    return
end

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
    local deadline = os.clock() + (timeout or 4.5)

    while os.clock() < deadline do
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if pg then
            local preferred, fallback, hidden = nil, nil, nil
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize
            local width = viewport and viewport.X or 1000

            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("GuiButton") and looksLikeSkip(obj) then
                    local labels = skipButtonLabels(obj)
                    local text = string.lower(table.concat(labels, " "))
                    local compact = string.gsub(text, "[%s_%-]", "")
                    local exactPhrase =
                        string.find(text, "lewati tutorial", 1, true) ~= nil
                        or string.find(compact, "lewatitutorial", 1, true) ~= nil
                        or string.find(text, "skip tutorial", 1, true) ~= nil
                        or string.find(compact, "skiptutorial", 1, true) ~= nil

                    if effectivelyVisible(obj) then
                        local pos = obj.AbsolutePosition
                        local size = obj.AbsoluteSize
                        local topRight = pos.X > width * 0.55 and pos.Y < 180

                        if exactPhrase and topRight then
                            return obj
                        elseif exactPhrase and not preferred then
                            preferred = obj
                        elseif not fallback then
                            fallback = obj
                        end
                    else
                        hidden = hidden or obj
                    end
                end
            end

            if preferred then return preferred end
            if fallback then return fallback end
            if hidden then return hidden end
        end

        task.wait(0.12)
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
