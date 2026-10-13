-- IRON SOUL - HEADLESS AUTO REDEEM
-- Ported from K5_HUB_REDEEM_UPDATED.txt; UI, Anti-AFK and Anti-Lag removed.
-- Uses the game's CodeRE RemoteEvent and the K5 code list.
-- Runs once per client session; waits for the remote to become available.

if getgenv().IronSoulAutoRedeemStarted then
    return
end
getgenv().IronSoulAutoRedeemStarted = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
if not Player then
    warn("[IronSoul AutoRedeem] LocalPlayer unavailable")
    getgenv().IronSoulAutoRedeemStarted = nil
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

local REDEEM_DELAY = 16.1
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
    local remote
    local deadline = os.clock() + 90
    repeat
        remote = getCodeRemote()
        if remote then break end
        task.wait(1)
    until os.clock() >= deadline

    if not remote then
        warn("[IronSoul AutoRedeem] CodeRE remote not found after 90 seconds; feature skipped")
        getgenv().IronSoulAutoRedeemStarted = nil
        return
    end

    print("[IronSoul AutoRedeem] Starting " .. #Codes .. " codes (no UI)")
    local succeeded = 0
    for index, code in ipairs(Codes) do
        if not Player.Parent then break end
        if getgenv().IronSoulLevelStopReached then
            print("[IronSoul AutoRedeem] Stopped because level cap was reached")
            break
        end

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

    print(("[IronSoul AutoRedeem] Finished. Requests sent: %d/%d"):format(succeeded, #Codes))
end)
