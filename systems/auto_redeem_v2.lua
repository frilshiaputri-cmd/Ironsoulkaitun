-- K5-HUB IRONSOUL V2 - AUTO REDEEM
-- Keeps the existing tracker UI and code sequence; kick only after the full redeem list is sent.
-- Ported from K5_HUB_REDEEM_UPDATED.txt; includes a compact auto-jump Anti-AFK toggle.
-- Uses the game's CodeRE RemoteEvent and the K5 code list.
-- Runs once per client session; waits for the remote to become available.

if getgenv().IronSoulAutoRedeemV2Completed then
    print("[IronSoul AutoRedeem V2] Already completed; skipping duplicate run.")
    return
end
if getgenv().IronSoulAutoRedeemV2Started then
    return
end
getgenv().IronSoulAutoRedeemV2Started = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
if not Player then
    warn("[IronSoul AutoRedeem] LocalPlayer unavailable")
    getgenv().IronSoulAutoRedeemV2Started = nil
    return
end

local Codes = {
    "runekify", "Dray28", "RIKUSOULS", "Ahjughh", "T3nsei",
    "Ghifa", "Sukunay", "MERGIXS", "SIGURIH", "CA2",
    "Lulzsec", "druscxlla", "MAHAFEY", "LALAGANG", "Luthador2121",
    "AAM", "ToadPlaysGamesTTV", "Uzi", "TT_Mentally_ill_K.N", "luknojo",
    "Zeny", "Maple", "Fujiesane", "VeeruChan", "HELOS",
    "LezoCr", "ARES", "Laplace", "Deco", "dasher",
    "Nyxaria", "ProfGab", "SUB2BLAZESTARS", "Nothing", "Dism",
    "FannTzy", "Darkfeniks", "Sneptuno", "SUPER MBUD", "Marcell",
    "Markbhatra", "DrekathSenpai", "smiley", "Sine", "GT_HANNI",
    "Erijero", "DanoNano", "WettySNK", "obe", "Dekday",
    "Qyuu", "Gwynne", "PapiJoy", "Taalonely", "Darren",
    "MADUNN", "Clipz7112", "omjiwa", "PaPaX", "Ryu",
    "DEI_Yumeko", "Chrisss", "Gryffin", "ARKANGHEL", "tony_vt",
    "Ryokenn", "ReyPomuchi", "Freca", "Shan", "Bebek",
    "Les", "SEYUnever", "Izumi_Senpai", "Staysmoovey", "NisardHelpOnlyWoman",
    "Kiota2", "LZZ_019BEST", "PepCalcot", "Astral", "Lifauzi",
    "Shirooo0312_IRONSOUL", "Ewaa", "FRanime_OFFICIEL", "WerNate", "Ascart",
    "Sweetiee24", "Monarch", "Aetherix", "SUB2MULTIST789", "RENZEI100",
    "Skywinter86", "Heso", "Ghelayyy", "Heartguard", "ZARGAKSTONE",
    "RaykorBR", "EJ(YURU)", "Rujika", "Giovanni_GG", "GRAYWOLF",
    "SUB_TO_ITS_HUNTER", "Alex._.SINN", "AbuelaCalcot", "ChakGIM", "Zhien",
    "LacilBlueBerry", "SamudraSelatan", "qzq", "BaraWell", "Horrortoki",
    "Vinxies", "minamee", "IRONSOULWEEKEND27", "S4ENDLESSTOWER",
    "TRADEISLANDUPDATE", "North", "NEXCU", "EvLCrys", "Joy_Blox",
    "DEYMMM", "DD_Noir", "Maple_13xNoir"
}


-- K5-HUB REDEEM TRACKER: observes localized client notifications, not FireServer pcall.
local function normalize(s) return tostring(s or ""):lower():gsub("[%p%c]", " "):gsub("%s+", " ") end
local good = {"kode tembus","kode berhasil","berhasil ditukar","code redeemed","redeem successful","successfully redeemed","redemption successful","code erfolgreich","code utilise","codigo canjeado","código resgatado","codice riscattato","コード引き換え成功","兑换成功","코드 사용 성공","แลกรหัสสำเร็จ","nhập mã thành công","تم استرداد الرمز","код активирован"}
local bad = {"code tidak ditemukan","kode tidak ditemukan","kode tidak valid","kode sudah digunakan","code not found","invalid code","code already used","already redeemed","code expired","redemption failed","failed to redeem","unknown code","code nicht gefunden","code introuvable","code invalide","código no encontrado","código inválido","codice non trovato","コードが見つかりません","无效兑换码","兑换码无效","유효하지 않은 코드","mã không tồn tại","không tìm thấy mã","ไม่พบรหัส","لم يتم العثور على الرمز","код не найден"}
local function hasPhrase(s, list)
 s = normalize(s)
 for _, p in ipairs(list) do if s:find(normalize(p),1,true) then return true end end
 return false
end
local tracker = {ok=0, failed={}, code=nil, resolved=false}
local function makeTracker()
 local pg = Player:WaitForChild("PlayerGui",15); if not pg then return end
 local gui = Instance.new("ScreenGui"); gui.Name="K5RedeemTracker"; gui.ResetOnSpawn=false; gui.DisplayOrder=999; gui.Parent=pg
 tracker.gui = gui
 -- Compact single-panel tracker: details stay collapsed so it does not cover the screen.
 local frame=Instance.new("Frame"); frame.Name="Panel"; frame.Size=UDim2.fromOffset(205,76); frame.Position=UDim2.new(1,-213,0,90); frame.BackgroundColor3=Color3.fromRGB(25,20,38); frame.BorderSizePixel=0; frame.Parent=gui
 Instance.new("UICorner",frame).CornerRadius=UDim.new(0,7)
 local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(115,75,155); stroke.Thickness=1; stroke.Parent=frame
 local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-48,0,22); title.Position=UDim2.fromOffset(7,2); title.BackgroundTransparency=1; title.Text="K5 • AUTO REDEEM"; title.TextColor3=Color3.fromRGB(210,165,255); title.Font=Enum.Font.GothamBold; title.TextSize=11; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=frame
 local detail=Instance.new("TextButton"); detail.Size=UDim2.fromOffset(34,19); detail.Position=UDim2.new(1,-39,0,3); detail.Text="INFO"; detail.TextSize=8; detail.Font=Enum.Font.GothamBold; detail.BackgroundColor3=Color3.fromRGB(72,48,95); detail.TextColor3=Color3.new(1,1,1); detail.Parent=frame
 Instance.new("UICorner",detail).CornerRadius=UDim.new(0,5)
 local stats=Instance.new("TextLabel"); stats.Name="Stats"; stats.Position=UDim2.fromOffset(7,25); stats.Size=UDim2.new(1,-14,0,17); stats.BackgroundTransparency=1; stats.TextColor3=Color3.new(1,1,1); stats.Font=Enum.Font.GothamSemibold; stats.TextSize=10; stats.TextXAlignment=Enum.TextXAlignment.Left; stats.Parent=frame
 local status=Instance.new("TextLabel"); status.Name="Status"; status.Position=UDim2.fromOffset(7,44); status.Size=UDim2.new(1,-14,0,25); status.BackgroundTransparency=1; status.Text="Menunggu notifikasi..."; status.TextColor3=Color3.fromRGB(205,200,215); status.TextSize=9; status.TextWrapped=true; status.TextXAlignment=Enum.TextXAlignment.Left; status.Font=Enum.Font.Gotham; status.Parent=frame
 local scroll=Instance.new("ScrollingFrame"); scroll.Name="FailedList"; scroll.Position=UDim2.fromOffset(7,76); scroll.Size=UDim2.new(1,-14,0,94); scroll.BackgroundColor3=Color3.fromRGB(38,30,48); scroll.BorderSizePixel=0; scroll.ScrollBarThickness=3; scroll.CanvasSize=UDim2.new(); scroll.Visible=false; scroll.Parent=frame
 local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,2); layout.Parent=scroll
 local expanded=false
 detail.MouseButton1Click:Connect(function()
  expanded=not expanded
  scroll.Visible=expanded
  detail.Text=expanded and "MIN" or "INFO"
  frame.Size=expanded and UDim2.fromOffset(205,176) or UDim2.fromOffset(205,76)
 end)
 local function refresh()
  stats.Text=("OK %d  |  Gagal %d"):format(tracker.ok,#tracker.failed)
  for _,v in ipairs(scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
  for i,item in ipairs(tracker.failed) do
   local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,22); row.BackgroundColor3=Color3.fromRGB(65,37,49); row.LayoutOrder=i; row.Parent=scroll
   local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-43,1,0); lbl.Position=UDim2.fromOffset(4,0); lbl.BackgroundTransparency=1; lbl.Text=item.code.." • gagal"; lbl.TextColor3=Color3.new(1,0.85,0.85); lbl.TextSize=9; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
   local del=Instance.new("TextButton"); del.Size=UDim2.fromOffset(36,18); del.Position=UDim2.new(1,-39,0,2); del.Text="Hapus"; del.TextSize=8; del.Parent=row
   del.MouseButton1Click:Connect(function() for n,x in ipairs(tracker.failed) do if x==item then table.remove(tracker.failed,n); break end end; refresh() end)
  end
  scroll.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+3)
 end
 tracker.refresh=refresh; tracker.status=function(s) status.Text=s end; refresh()
 layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+3) end)
end
local function result(kind, msg)
 if tracker.resolved or not tracker.code then return end
 tracker.resolved=true
 if kind=="ok" then tracker.ok+=1; if tracker.status then tracker.status("BERHASIL: "..tracker.code) end
 else
  local exists=false; for _,x in ipairs(tracker.failed) do if x.code==tracker.code then exists=true end end
  if not exists then table.insert(tracker.failed,{code=tracker.code,reason=tostring(msg)}) end
  if tracker.status then tracker.status("GAGAL: "..tracker.code) end
 end
 if tracker.refresh then tracker.refresh() end
end
local function watchMessages()
 local pg=Player:WaitForChild("PlayerGui",15); if not pg then return end
 local seen=setmetatable({}, {__mode="k"})
 local function hook(o)
  if not (o:IsA("TextLabel") or o:IsA("TextButton")) or seen[o] then return end; seen[o]=true
  local function check()
   if not tracker.code or tracker.resolved then return end
   if hasPhrase(o.Text,good) then result("ok",o.Text) elseif hasPhrase(o.Text,bad) then result("bad",o.Text) end
  end
  o:GetPropertyChangedSignal("Text"):Connect(check); check()
 end
 for _,o in ipairs(pg:GetDescendants()) do hook(o) end
 pg.DescendantAdded:Connect(function(o) hook(o); for _,c in ipairs(o:GetDescendants()) do hook(c) end end)
end

local REDEEM_DELAY = 16.1
local ANTI_AFK_INTERVAL = 20
-- Kick only after the complete redeem list has been sent.
local AUTO_KICK_AFTER_REDEEM = true
local isRedeeming = false

local function antiAfkJump()
    if not Player.Parent then return end
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        pcall(function()
            humanoid.Jump = true
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end
local LEVEL_STOP = tonumber((getgenv().IronSoulConfig or {}).LEVEL_STOP) or 30
local LOBBY_PLACE_ID = 117533937949084

local function readLevel()
    local attr = tonumber(Player:GetAttribute("LG_Level"))
    if attr then return attr end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "DataUtil" then
            local ok, util = pcall(require, obj)
            if ok and type(util) == "table" and type(util.GetPlayerData) == "function" then
                local okData, data = pcall(function()
                    return util:GetPlayerData(Player)
                end)
                if okData and type(data) == "table" and type(data.LevelData) == "table" then
                    local level = tonumber(data.LevelData.Level)
                    if level then return level end
                end
            end
        end
    end
    return nil
end

local function getCodeRemote()
    local framework = ReplicatedStorage:FindFirstChild("Framework")
    local systems = framework and framework:FindFirstChild("Systems")
    local codeSystem = systems and systems:FindFirstChild("CodesSystem")
    local remote = codeSystem and codeSystem:FindFirstChild("CodeRE")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

task.spawn(function()
    -- At the level cap, stop farming and request a return to the lobby.
    -- TeleportService may be restricted from client executors; if so, keep waiting
    -- for the game's own return-to-lobby transition rather than redeeming in a dungeon.
    local returnAttemptAt = 0
    while Player.Parent do
        local level = readLevel()
        local inLobby = game.PlaceId == LOBBY_PLACE_ID
        if level and level >= LEVEL_STOP and inLobby then
            break
        end
        if level and level >= LEVEL_STOP and not inLobby and os.clock() >= returnAttemptAt then
            returnAttemptAt = os.clock() + 12
            -- Queue V2 bootstrap so the redeem module starts again after the lobby teleport.
            local queueBootstrap = getgenv().IronSoulQueueBootstrap
            if type(queueBootstrap) == "function" then
                pcall(queueBootstrap, "level cap return to lobby")
            end
            local ok, err = pcall(function()
                game:GetService("TeleportService"):Teleport(LOBBY_PLACE_ID)
            end)
            if ok then
                print("[IronSoul AutoRedeem V2] Requested return to lobby.")
            else
                warn("[IronSoul AutoRedeem V2] Client teleport request unavailable; waiting for game lobby transition: " .. tostring(err))
            end
        end
        task.wait(2)
    end

    if not Player.Parent then
        getgenv().IronSoulAutoRedeemV2Started = nil
        return
    end

    local remote
    local deadline = os.clock() + 90
    repeat
        remote = getCodeRemote()
        if remote then break end
        task.wait(1)
    until os.clock() >= deadline

    if not remote then
        warn("[IronSoul AutoRedeem] CodeRE remote not found after 90 seconds; feature skipped")
        getgenv().IronSoulAutoRedeemV2Started = nil
        return
    end

    makeTracker()
    task.spawn(watchMessages)
    isRedeeming = true
    task.spawn(function()
        while isRedeeming and Player.Parent do
            task.wait(ANTI_AFK_INTERVAL)
            if isRedeeming then antiAfkJump() end
        end
    end)
    print("[IronSoul AutoRedeem] Level " .. tostring(readLevel()) .. " in lobby; starting " .. #Codes .. " codes; auto-jump every " .. ANTI_AFK_INTERVAL .. "s")
    local succeeded = 0
    for index, code in ipairs(Codes) do
        tracker.code = code
        tracker.resolved = false
        if tracker.status then tracker.status(("Mengirim %d/%d: %s"):format(index, #Codes, code)) end
        if not Player.Parent then break end
        local ok, err = pcall(function()
            remote:FireServer({
                event = "usecode",
                code = code
            })
        end)

        if ok then
            succeeded += 1
            print(("[IronSoul AutoRedeem] Sent %d/%d: %s"):format(index, #Codes, code))
        else
            warn(("[IronSoul AutoRedeem] Failed to send %s: %s"):format(code, tostring(err)))
        end

        if index < #Codes then
            task.wait(REDEEM_DELAY)
        end
    end

    isRedeeming = false
    -- Mark completion before cleanup so this module cannot restart and resend codes.
    getgenv().IronSoulAutoRedeemV2Completed = true
    getgenv().IronSoulAutoRedeemV2Stopped = true
    tracker.resolved = true
    tracker.code = nil
    if tracker.status then tracker.status("SELESAI • Auto Redeem ditutup") end
    print(("[IronSoul AutoRedeem V2] Finished: %d/%d requests sent."):format(succeeded, #Codes))

    -- Close only the redeem tracker/module UI. Keep the main hub and its Anti-AFK alive.
    task.wait(3)
    if tracker.gui then
        pcall(function() tracker.gui:Destroy() end)
        tracker.gui = nil
    end
    getgenv().IronSoulAutoRedeemV2Started = false
    if AUTO_KICK_AFTER_REDEEM and Player.Parent then
        task.wait(2)
        Player:Kick("Auto Redeem selesai.")
    else
        print("[IronSoul AutoRedeem V2] Redeem module closed; main hub/session remains active.")
    end
end)
