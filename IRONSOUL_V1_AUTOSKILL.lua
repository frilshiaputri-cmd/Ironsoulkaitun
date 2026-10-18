-- K5-HUB | IronSoul V1 dengan sistem Auto Skill native dari V2.
-- Bootstrap dan batas level V1 tetap dipertahankan; skill dipanggil oleh combat V2.
-- Tidak menjalankan modul keyboard Q/E/R terpisah agar tidak terjadi input ganda.

local V1_BOOTSTRAP_URL =
    "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/bootstrap_v61_11.lua"
local OWN_LOADER_URL =
    "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/IRONSOUL_V1_AUTOSKILL.lua"

local function notify(message)
    print("[K5-HUB V1 + AutoSkill] " .. tostring(message))
    local ok, StarterGui = pcall(function()
        return game:GetService("StarterGui")
    end)
    if ok and StarterGui then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "K5-HUB | IronSoul V1",
                Text = tostring(message),
                Duration = 5,
            })
        end)
    end
end

if type(getgenv) ~= "function" or type(loadstring) ~= "function" then
    warn("[K5-HUB V1 + AutoSkill] Executor tidak mendukung getgenv/loadstring.")
    return
end

local env = getgenv()
env.IronSoulConfig = env.IronSoulConfig or {
    FPS_CAP = 8,
    FARM = "NEWBIE",
    TICKETS = "SMART",
    HEADLESS = true,
}
-- Force the requested policy even if an older config already exists.
env.IronSoulConfig.LEVEL_STOP = 30
env.IronSoulConfig.AUTO_CLAIM_ALL = false
env.IronSoulConfig.AUTO_CLAIM = false
env.IronSoulConfig.AUTO_REDEEM = false
env.IronSoulConfig.AUTO_SEASON_SPIN = false
env.IronSoulConfig.AUTO_SEASON_PASS = false
env.IronSoulConfig.AUTO_SEVEN_DAILY = false
env.IronSoulConfig.AUTO_GUIDEBOOK = false
env.IronSoulConfig.AUTO_UPDATE_LOG = false
env.IronSoulConfig.AUTO_DAILY_LOGIN = false
env.K5V1AutoSkillLoader = OWN_LOADER_URL
-- Aktifkan sistem Auto Skill native yang berada di alur combat V2.
env.IronSoulConfig.AutoSkill = true

-- Local client-side level guard. Kick the local player at level 30 or above.
if not env.K5V1LevelGuardStarted then
    env.K5V1LevelGuardStarted = true
    task.spawn(function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer
        local function readLevel()
            local n = tonumber(player:GetAttribute("LG_Level"))
            if n then return n end
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("ModuleScript") and obj.Name == "DataUtil" then
                    local ok, util = pcall(require, obj)
                    if ok and type(util) == "table" and type(util.GetPlayerData) == "function" then
                        local dataOk, data = pcall(function() return util:GetPlayerData(player) end)
                        if dataOk and type(data) == "table" and type(data.LevelData) == "table" then
                            return tonumber(data.LevelData.Level)
                        end
                    end
                end
            end
            return nil
        end
        while player and player.Parent do
            local level = readLevel()
            if level and level >= 30 then
                env.IronSoulLevelStopReached = true
                env.IronSoulLevelStopLevel = level
                env.IronSoulNoAutoContinue = true
                env.IronSoulManualExecutionOnly = true
                if type(env.IronSoulConfig) == "table" then
                    env.IronSoulConfig.FARM = "OFF"
                end
                warn("[K5-HUB V1] Level cap reached (" .. tostring(level) .. "); farming/continuation stopped; kicking local player.")
                pcall(function() player:Kick("K5-HUB: batas level 30 tercapai.") end)
                return
            end
            task.wait(1)
        end
    end)
end

local okFetch, source = pcall(function()
    return game:HttpGet(V1_BOOTSTRAP_URL .. "?k5=" .. tostring(os.time()))
end)
if not okFetch or type(source) ~= "string" or #source < 1000 then
    notify("Gagal mengambil bootstrap V1: " .. tostring(source))
    return
end

-- Jalankan Auto Skill sebagai modul terpisah. Bootstrap V1 dibiarkan asli:
-- tidak ada source:gsub, injeksi loadRaw(route), atau penggantian antrean teleport.
env.IronSoulDisableAutoClaimAll = true
env.IronSoulDisableSeasonSpin = true

-- Auto Skill tidak dijalankan sebagai modul Q/E/R terpisah.
-- V1 menggunakan sistem skill native V2 di systems/combat.lua dan patch skill V2.


local chunk, compileErr = loadstring(source)
if not chunk then
    notify("Compile bootstrap V1 gagal: " .. tostring(compileErr))
    return
end

notify("Memulai bootstrap V1; Auto Skill memakai sistem combat V2.")
local runOk, runErr = pcall(chunk)
if not runOk then
    notify("Runtime V1 error: " .. tostring(runErr))
    warn("[K5-HUB V1 + AutoSkill] " .. tostring(runErr))
end
