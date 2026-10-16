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

    task.spawn(function()
        while player and player.Parent do
            local config = getgenv().IronSoulConfig or {}
            if not getgenv().IronSoulLevelStopReached
                and config.FARM ~= "OFF"
                and config.AutoSkill ~= false
                and hasNearbyTarget() then
                local now = os.clock()
                for _, key in ipairs({"E", "Q", "R"}) do
                    if now >= (cooldowns[key] or 0) then
                        pressKey(key)
                        cooldowns[key] = now + cooldownConfig[key]
                        task.wait(0.15)
                    end
                end
            end
            task.wait(skillInterval)
        end
    end)
end
