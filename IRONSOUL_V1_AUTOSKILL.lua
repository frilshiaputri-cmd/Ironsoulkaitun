-- K5-HUB | IronSoul V1 + Auto Skill dari repo K5-HUB
-- Loader terpisah: tidak mengubah LOADER_V2.lua atau bootstrap_v2.lua.
-- Runtime inti V1 berasal dari MUshihara; modul Auto Skill berasal dari repo ini.
-- Catatan: Auto Skill memakai input keyboard Q/E/R. Di Delta Android, input ini
-- mungkin tidak diteruskan ke tombol skill mobile game.

local V1_BOOTSTRAP_URL =
    "https://raw.githubusercontent.com/MUshihara/ironsoulkaitun/main/bootstrap_v61_11.lua"
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

-- Saat masuk dungeon, start Auto Skill V2 dari repo milik pengguna sebelum
-- combat V1 berjalan. Modul dicegah berjalan dua kali dalam server yang sama.
-- Keep claim/spin routines explicitly disabled for any compatible V1 modules.
env.IronSoulDisableAutoClaimAll = true
env.IronSoulDisableSeasonSpin = true
local originalRouteCall = "loadRaw(route)"
local injectedRouteCall = [=[
if route == "systems/combat.lua" then
    task.spawn(function()
        local skillKey = tostring(game.PlaceId) .. "|" .. tostring(game.JobId)
        local previousSkill = getgenv().K5V1AutoSkillStarted
        if type(previousSkill) == "table" and previousSkill.Key == skillKey then return end
        getgenv().K5V1AutoSkillStarted = { Key = skillKey, At = os.clock() }
        local skillOk, skillSource = pcall(function()
            return game:HttpGet("AUTO_SKILL_URL" .. "?k5=" .. tostring(os.time()))
        end)
        if not skillOk or type(skillSource) ~= "string" then
            warn("[K5-HUB V1 + AutoSkill] Gagal mengambil Auto Skill: " .. tostring(skillSource))
            getgenv().K5V1AutoSkillStarted = nil
            return
        end
        local skillChunk, compileErr = loadstring(skillSource)
        if not skillChunk then
            warn("[K5-HUB V1 + AutoSkill] Compile Auto Skill gagal: " .. tostring(compileErr))
            getgenv().K5V1AutoSkillStarted = nil
            return
        end
        local runOk, startSkill = pcall(skillChunk)
        if not runOk or type(startSkill) ~= "function" then
            warn("[K5-HUB V1 + AutoSkill] Modul Auto Skill tidak valid: " .. tostring(startSkill))
            getgenv().K5V1AutoSkillStarted = nil
            return
        end
        local startOk, startErr = pcall(startSkill)
        if not startOk then
            warn("[K5-HUB V1 + AutoSkill] Gagal memulai Auto Skill: " .. tostring(startErr))
            getgenv().K5V1AutoSkillStarted = nil
            return
        end
        print("[K5-HUB V1 + AutoSkill] Auto Skill V2 dimulai di dungeon")
    end)
end
loadRaw(route)]=]

injectedRouteCall = injectedRouteCall:gsub("AUTO_SKILL_URL", OWN_AUTO_SKILL_URL)

local replacements = 0
source, replacements = source:gsub(originalRouteCall, injectedRouteCall, 1)
if replacements ~= 1 then
    notify("Patch gagal: format bootstrap V1 berubah. Tidak menjalankan versi tanpa patch.")
    return
end

-- Teleport berikutnya diarahkan kembali ke loader ini agar Auto Skill tetap
-- terpasang setelah pindah map, bukan langsung ke bootstrap upstream.
local queueOld = 'BASE .. "bootstrap_v61_11.lua"'
local queueNew = string.format("%q", OWN_LOADER_URL)
local queueReplacements
source, queueReplacements = source:gsub(queueOld, queueNew, 1)
if queueReplacements ~= 1 then
    notify("Peringatan: antrean teleport tetap memakai bootstrap V1 upstream.")
end

local chunk, compileErr = loadstring(source)
if not chunk then
    notify("Compile bootstrap V1 gagal: " .. tostring(compileErr))
    return
end

notify("Memulai runtime V1; Auto Skill V2 aktif otomatis di dungeon.")
local runOk, runErr = pcall(chunk)
if not runOk then
    notify("Runtime V1 error: " .. tostring(runErr))
    warn("[K5-HUB V1 + AutoSkill] " .. tostring(runErr))
end
