-- IRON SOUL V2: keyboard-only Auto Skill (G/E/R).
-- No GUI button activation and no weapon swapping; game validates each skill cast.

local started = false

return function()
    if started then return end

    local env = getgenv()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then
        env.IronSoulAutoSkillStatus = "waiting for LocalPlayer"
        return
    end

    local okInput, VirtualInputManager = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if not okInput or not VirtualInputManager then
        env.IronSoulAutoSkillStatus = "keyboard input service unavailable"
        return
    end

    started = true
    env.IronSoulAutoSkillStatus = "keyboard loop active"

    local keys = { "G", "E", "R" }
    local fallbackCD = { G = 0.75, E = 0.75, R = 1.60 }
    local nextAllowed = { G = 0, E = 0, R = 0 }
    local scanInterval = 0.12
    local maxRange = 180

    local function hasNearbyTarget()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local seen = {}
        for _, folderName in ipairs({ "EnemyNpc", "WorldEnemys" }) do
            local folder = workspace:FindFirstChild(folderName, true)
            if folder then
                for _, model in ipairs(folder:GetDescendants()) do
                    if model:IsA("Model") and not seen[model] and model ~= character then
                        seen[model] = true
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        local targetRoot = model:FindFirstChild("HumanoidRootPart")
                            or model.PrimaryPart
                            or model:FindFirstChildWhichIsA("BasePart")
                        if humanoid and humanoid.Health > 0 and targetRoot
                            and not Players:GetPlayerFromCharacter(model)
                            and (targetRoot.Position - root.Position).Magnitude <= maxRange then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    local function pressKey(keyName)
        local keyCode = Enum.KeyCode[keyName]
        if not keyCode then return false, "invalid key " .. tostring(keyName) end

        local downOk, downErr = pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        end)
        if not downOk then return false, tostring(downErr) end

        task.wait(0.035)
        local upOk, upErr = pcall(function()
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
        if not upOk then return false, tostring(upErr) end
        return true
    end

    task.spawn(function()
        while player.Parent do
            local loopOk, loopErr = pcall(function()
                local config = getgenv().IronSoulConfig or {}
                local canFarm = not getgenv().IronSoulLevelStopReached
                    and not getgenv().IronSoulStopRequested
                    and config.FARM ~= "OFF"
                    and config.AutoSkill ~= false

                if canFarm and hasNearbyTarget() then
                    for _, key in ipairs(keys) do
                        local now = os.clock()
                        if now >= (nextAllowed[key] or 0) then
                            local pressed, err = pressKey(key)
                            if pressed then
                                nextAllowed[key] = now + fallbackCD[key]
                                env.IronSoulAutoSkillStatus = "pressed " .. key
                            else
                                nextAllowed[key] = now + 0.50
                                env.IronSoulAutoSkillStatus = "input failed " .. key .. ": " .. tostring(err)
                            end
                            task.wait(0.045)
                        end
                    end
                end
            end)

            if not loopOk then
                env.IronSoulAutoSkillStatus = "loop recovered: " .. tostring(loopErr)
            end
            task.wait(scanInterval)
        end
        env.IronSoulAutoSkillStatus = "player unavailable"
    end)
end
