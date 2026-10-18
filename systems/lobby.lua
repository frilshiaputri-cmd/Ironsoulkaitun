-- IRON SOUL - V61.23 24/7 LOBBY PREFLIGHT
--
-- Fresh-account PlayerData readiness + post-Cave audit.
-- Upgrade-driven Cave planning now runs AFTER historical Forge/EquipBest via
-- the small post-forge hook, so Cave decisions use current equipment/material
-- demand instead of stale pre-maintenance reserve counts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local BASE = "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/"

local function status(text)
    text = tostring(text or "")
    local fn = getgenv().IronSoulStatus
    if type(fn) == "function" then
        pcall(fn, text)
    end
    print("[IronSoul Lobby V61.23]", text)
end

local function writeReadiness(text)
    if type(writefile) == "function" then
        pcall(writefile, "IronSoul_LobbyReadiness_V61_18.txt", tostring(text or ""))
    end
end

local DataUtilModule
local DataUtil

local function getDataUtil()
    if type(DataUtil) == "table" then
        return DataUtil
    end

    if not DataUtilModule or not DataUtilModule.Parent then
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("ModuleScript") and obj.Name == "DataUtil" then
                DataUtilModule = obj
                break
            end
        end
    end

    if not DataUtilModule then
        return nil, "DataUtil module missing"
    end

    local ok, value = pcall(require, DataUtilModule)
    if not ok or type(value) ~= "table" then
        return nil, "DataUtil require failed"
    end

    DataUtil = value
    return DataUtil
end

local function readiness()
    local missing = {}
    local data

    local util, utilErr = getDataUtil()
    if not util then
        table.insert(missing, utilErr or "DataUtil unavailable")
    elseif type(util.GetPlayerData) ~= "function" then
        table.insert(missing, "DataUtil.GetPlayerData missing")
    else
        local ok, value = pcall(function()
            return util:GetPlayerData(LocalPlayer)
        end)

        if ok and type(value) == "table" then
            data = value
        else
            table.insert(missing, "PlayerData table unavailable")
        end
    end

    local loadedAttr = LocalPlayer:GetAttribute("Loaded")
    local levelAttr = tonumber(LocalPlayer:GetAttribute("LG_Level"))
    local dataLevel = data and type(data.LevelData) == "table" and tonumber(data.LevelData.Level) or nil
    local resolvedLevel = levelAttr or dataLevel
    local powerAttr = tonumber(LocalPlayer:GetAttribute("LG_PowerNew1"))

    if loadedAttr == false then
        table.insert(missing, "Loaded=false")
    end
    if resolvedLevel == nil then
        table.insert(missing, "Level unavailable")
    end
    if powerAttr == nil then
        table.insert(missing, "LG_PowerNew1=nil")
    end

    return #missing == 0 and data ~= nil,
        table.concat(missing, ", "),
        data,
        loadedAttr,
        resolvedLevel,
        levelAttr and "LG_Level" or (dataLevel and "PlayerData.LevelData.Level" or "none"),
        powerAttr
end

local started = os.clock()
local lastReport = -math.huge
local stableReady = 0
local finalLevel
local finalLevelSource

while stableReady < 4 do
    local ready, missing, data, loadedAttr, level, levelSource, power = readiness()

    if ready then
        stableReady += 1
        finalLevel = level
        finalLevelSource = levelSource
    else
        stableReady = 0
    end

    local elapsed = os.clock() - started
    if os.clock() - lastReport >= 2 or ready then
        lastReport = os.clock()

        writeReadiness(table.concat({
            "Version=V61.23",
            "Elapsed=" .. string.format("%.2f", elapsed),
            "Ready=" .. tostring(ready),
            "StableChecks=" .. tostring(stableReady) .. "/4",
            "Loaded=" .. tostring(loadedAttr),
            "ResolvedLevel=" .. tostring(level),
            "LevelSource=" .. tostring(levelSource),
            "LG_PowerNew1=" .. tostring(power),
            "PlayerData=" .. tostring(type(data)),
            "Missing=" .. tostring(missing),
        }, "\n"))

        if ready then
            status("Lobby data stabilizing | " .. stableReady .. "/4 | Lv" .. tostring(level) .. " via " .. tostring(levelSource))
        else
            status("Lobby waiting for data | " .. (missing ~= "" and missing or "unknown") .. " | " .. string.format("%.1fs", elapsed))
        end
    end

    if stableReady < 4 then
        task.wait(0.25)
    end
end

getgenv().IronSoulResolvedLevel = finalLevel
getgenv().IronSoulResolvedLevelSource = finalLevelSource

if LocalPlayer:GetAttribute("LG_Level") == nil and tonumber(finalLevel) then
    pcall(LocalPlayer.SetAttribute, LocalPlayer, "LG_Level", tonumber(finalLevel))
    status("Fresh level compatibility | LG_Level=" .. tostring(finalLevel) .. " from " .. tostring(finalLevelSource))
end

status("Lobby PlayerData ready | Lv" .. tostring(finalLevel) .. " via " .. tostring(finalLevelSource))

-- HARD LEVEL CAP: never schedule another dungeon when the player is already
-- at the configured level limit. The bootstrap monitor handles level-ups mid-run.
do
    local cap = tonumber((getgenv().IronSoulConfig or {}).LEVEL_STOP) or 30
    if cap > 0 and tonumber(finalLevel) and tonumber(finalLevel) >= cap then
        getgenv().IronSoulLevelStopReached = true
        getgenv().IronSoulLevelStopLevel = tonumber(finalLevel)
        if type(getgenv().IronSoulConfig) == "table" then
            getgenv().IronSoulConfig.FARM = "OFF"
        end
        status("LEVEL CAP | Lv" .. tostring(finalLevel) .. "/" .. tostring(cap) .. " | stay in lobby; dungeon queue blocked")
        -- Keep lobby maintenance running so level-40 reward claims can complete.
        -- Combat remains blocked by IronSoulLevelStopReached.
    end
end

-- Resolve any Cave material delta after authoritative Lobby PlayerData readiness.
do
    local loadRaw = getgenv().IronSoulLoadRaw
    if type(loadRaw) == "function" then
        local okAudit, auditResult = loadRaw("systems/cave_audit.lua")
        if not okAudit then
            status("Cave audit deferred | " .. tostring(auditResult))
        end
    end
end

-- Preserve the canonical queueBootstrap created by bootstrap_v2.lua.

-- K5-HUB V1: use the maintained local lobby source only.
-- Do not silently fall back to an upstream lobby build that can re-enable
-- reward claims or SeasonTicket spending if a patch fails.
local cfg = getgenv().IronSoulConfig or {}
cfg.AUTO_CLAIM_ALL = false
cfg.AUTO_CLAIM = false
cfg.AUTO_SEASON_SPIN = false
cfg.AUTO_SEASON_PASS = false
cfg.AUTO_SEVEN_DAILY = false
cfg.AUTO_GUIDEBOOK = false
cfg.AUTO_UPDATE_LOG = false
cfg.AUTO_DAILY_LOGIN = false
getgenv().IronSoulConfig = cfg
getgenv().IronSoulDisableAutoClaimAll = true
getgenv().IronSoulDisableSeasonSpin = true

local loadRaw = getgenv().IronSoulLoadRaw
if type(loadRaw) ~= "function" then
    error("K5-HUB V1: local loader unavailable; refusing unsafe lobby fallback")
end
-- V2-style lobby execution boundary: preserve loader diagnostics and never
-- silently switch to an upstream reward/season implementation.
local ok, result = loadRaw("systems/lobby_base_v60_1.lua")
if not ok then
    local detail = tostring(result or "loader returned false without an error detail")
    status("V1 lobby load failed | " .. detail)
    error("K5-HUB V1: local safe lobby failed | " .. detail)
end
return result
