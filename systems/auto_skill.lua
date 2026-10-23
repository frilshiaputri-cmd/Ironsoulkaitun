-- K5-HUB IRONSOUL V2 - Auto skill port from IronForge_AutoFarm_PremiumUI_v6_STABLE
-- Preserves source behavior: E/Q/R key events, 0.70/0.70/1.50 cooldowns,
-- and a 2.50-second skill cycle while a living enemy target is nearby.
-- Delta Android may not route VirtualInputManager keyboard events to mobile skill buttons.

local started = false

return function()
    if started then return end
    started = true

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local cooldowns = { Q = 0, E = 0, R = 0 }
    local cooldownConfig = { Q = 0.70, E = 0.70, R = 1.50 }
    local skillInterval = 2.50

    local function hasNearbyTarget()
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and model ~= character then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local targetRoot = model:FindFirstChild("HumanoidRootPart")
                    or model.PrimaryPart
                if humanoid and humanoid.Health > 0 and targetRoot
                    and not Players:GetPlayerFromCharacter(model) then
                    if (targetRoot.Position - root.Position).Magnitude <= 600 then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function pressKey(keyName)
        local keyCode = Enum.KeyCode[keyName]
        if not keyCode then return false end

        return pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end

    -- Ported from the user's IronHub.txt: after a skill cycle, equip the
    -- next available Tool from Backpack. Do not touch lobby equipment remotes.
    local function switchToNextWeapon()
        local backpack = player and player:FindFirstChildOfClass("Backpack")
        local character = player and player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not backpack or not humanoid then return false end

        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local ok = pcall(function()
                    humanoid:EquipTool(item)
                end)
                if ok then return true end
            end
        end
        return false
    end

    task.spawn(function()
        while player and player.Parent do
            local config = getgenv().IronSoulConfig or {}
            if not getgenv().IronSoulLevelStopReached
                and config.FARM ~= "OFF"
                and config.AutoSkill ~= false
                and hasNearbyTarget() then
                local now = os.clock()
                local usedAnySkill = false
                for _, key in ipairs({"E", "Q", "R"}) do
                    if now >= (cooldowns[key] or 0) then
                        local pressed = pressKey(key)
                        if pressed then usedAnySkill = true end
                        cooldowns[key] = now + cooldownConfig[key]
                        task.wait(0.15)
                    end
                end

                -- Match IronHub.txt behavior: switch weapon after skill use.
                -- A short pause prevents overlapping the equip with skill input.
                if usedAnySkill and config.AutoSwitchWeapon ~= false then
                    switchToNextWeapon()
                    task.wait(0.3)
                end
            end
            task.wait(skillInterval)
        end
    end)
end
