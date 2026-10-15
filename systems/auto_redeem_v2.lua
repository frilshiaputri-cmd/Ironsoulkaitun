-- IronSoulKaitun V1/V2 - Level cap exit only
-- Auto Redeem has been removed from this module.
-- Monitor the local player's level; once level 30 is reached, leave the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

if not Player then
    warn("[IronSoul] LocalPlayer unavailable; level exit module stopped.")
    return
end

local LEVEL_STOP = tonumber((getgenv().IronSoulConfig or {}).LEVEL_STOP) or 30
local CHECK_INTERVAL = 2
local kicked = false

local function readLevel()
    local attr = tonumber(Player:GetAttribute("LG_Level"))
    if attr then
        return attr
    end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "DataUtil" then
            local ok, util = pcall(require, obj)
            if ok and type(util) == "table" and type(util.GetPlayerData) == "function" then
                local okData, data = pcall(function()
                    return util:GetPlayerData(Player)
                end)
                if okData and type(data) == "table" and type(data.LevelData) == "table" then
                    local level = tonumber(data.LevelData.Level)
                    if level then
                        return level
                    end
                end
            end
        end
    end

    return nil
end

while Player.Parent and not kicked do
    local level = readLevel()
    if level and level >= LEVEL_STOP then
        kicked = true
        print(("[IronSoul] Level %d reached (limit %d). Leaving server; Auto Redeem is disabled."):format(level, LEVEL_STOP))
        task.wait(1)
        Player:Kick("Level 30 tercapai. Keluar dari server.")
        break
    end
    task.wait(CHECK_INTERVAL)
end
