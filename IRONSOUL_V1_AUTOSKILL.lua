-- K5-HUB | IronSoul V1 + Auto Skill dari repo K5-HUB
-- Loader terpisah: tidak mengubah LOADER_V2.lua atau bootstrap_v2.lua.
-- Runtime inti V1 berasal dari MUshihara; modul Auto Skill berasal dari repo ini.
-- Catatan: Auto Skill memakai input keyboard Q/E/R. Di Delta Android, input ini
-- mungkin tidak diteruskan ke tombol skill mobile game.

local V1_BOOTSTRAP_URL =
    "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/bootstrap_v61_11.lua"
local OWN_AUTO_SKILL_URL =
    "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/systems/auto_skill.lua"
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

local skillOk, skillSource = pcall(function()
    return game:HttpGet(OWN_AUTO_SKILL_URL .. "?k5=" .. tostring(os.time()))
end)
if skillOk and type(skillSource) == "string" then
    local skillChunk, skillCompileErr = loadstring(skillSource)
    if skillChunk then
        local runOk, startSkill = pcall(skillChunk)
        if runOk and type(startSkill) == "function" then
            local startOk, startErr = pcall(startSkill)
            if startOk then
                notify("Auto Skill dimulai sebagai modul terpisah; bootstrap V1 asli tanpa patch.")
            else
                warn("[K5-HUB V1 + AutoSkill] Gagal memulai Auto Skill: " .. tostring(startErr))
            end
        else
            warn("[K5-HUB V1 + AutoSkill] Modul Auto Skill tidak valid: " .. tostring(startSkill))
        end
    else
        warn("[K5-HUB V1 + AutoSkill] Compile Auto Skill gagal: " .. tostring(skillCompileErr))
    end
else
    warn("[K5-HUB V1 + AutoSkill] Gagal mengambil Auto Skill: " .. tostring(skillSource))
end

local chunk, compileErr = loadstring(source)
if not chunk then
    notify("Compile bootstrap V1 gagal: " .. tostring(compileErr))
    return
end

notify("Memulai bootstrap V1 asli tanpa patch; Auto Skill berjalan terpisah.")
local runOk, runErr = pcall(chunk)
if not runOk then
    notify("Runtime V1 error: " .. tostring(runErr))
    warn("[K5-HUB V1 + AutoSkill] " .. tostring(runErr))
end
