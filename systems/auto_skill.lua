-- K5-HUB IRONSOUL V2 - Auto skill / attack cooldown controller
-- Keyboard skill loop: G/E/R. Uses UI cooldown indicators when readable and
-- local fallback cooldowns otherwise. No weapon swapping during combat.

local started = false

return function()
    if started then return end
    started = true

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local keys = { "G", "E", "R" }
    local fallbackCD = { G = 0.70, E = 0.70, R = 1.50 }
    local nextAllowed = { G = 0, E = 0, R = 0 }
    local lastPressed = { G = 0, E = 0, R = 0 }
    local scanInterval = 0.10
    local maxRange = 180

    local function skillTokens(key)
        if key == "G" then return { "g", "skillg", "skill1", "skill_1", "skillone" } end
        if key == "E" then return { "e", "skille", "skill2", "skill_2", "skilltwo" } end
        return { "r", "skillr", "skill3", "skill_3", "skillultimate", "ultimate" }
    end

    local function normalized(s)
        return string.lower(tostring(s or "")):gsub("[%s%p_]+", "")
    end

    local function cooldownFromGui(key)
        local pg = player and player:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        local tokens = skillTokens(key)
        for _, obj in ipairs(pg:GetDescendants()) do
            local name = normalized(obj.Name)
            local matched = false
            for _, token in ipairs(tokens) do
                if name == normalized(token) or name:find(normalized(token), 1, true) then
                    matched = true
                    break
                end
            end
            if matched then
                for _, attr in ipairs({ "Cooldown", "CooldownRemaining", "CD", "OnCooldown", "IsCooldown", "Ready" }) do
                    local value = obj:GetAttribute(attr)
                    if type(value) == "number" then
                        if value > 0 then return value end
                        if attr == "Cooldown" or attr == "CooldownRemaining" or attr == "CD" then return 0 end
                    elseif type(value) == "boolean" then
                        if (attr == "OnCooldown" or attr == "IsCooldown") and value then return 0.25 end
                        if attr == "Ready" and not value then return 0.25 end
                    end
                end
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local txt = tostring(obj.Text or ""):gsub(",", ".")
                    local n = tonumber(txt:match("(%d+%.?%d*)"))
                    if n and n > 0 and n <= 120 then return n end
                    if txt:find("cooldown", 1, true) or txt:find("recharging", 1, true) then return 0.25 end
                end
                if obj:IsA("GuiObject") then
                    local overlay = obj:FindFirstChild("Cooldown", true)
                        or obj:FindFirstChild("CD", true)
                        or obj:FindFirstChild("CooldownFrame", true)
                    if overlay and overlay:IsA("GuiObject") and overlay.Visible then
                        local label = overlay:FindFirstChildWhichIsA("TextLabel", true)
                        local n = label and tonumber((tostring(label.Text or "")):match("(%d+%.?%d*)"))
                        if n and n > 0 and n <= 120 then return n end
                        return 0.25
                    end
                end
            end
        end
        return nil
    end

    local function hasNearbyTarget()
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local seen = {}
        for _, folderName in ipairs({ "EnemyNpc", "WorldEnemys" }) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, model in ipairs(folder:GetDescendants()) do
                    if model:IsA("Model") and not seen[model] then
                        seen[model] = true
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        local targetRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
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
        if not keyCode then return false end
        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.025)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
        return ok
    end

    task.spawn(function()
        while player and player.Parent do
            local config = getgenv().IronSoulConfig or {}
            local canFarm = not getgenv().IronSoulLevelStopReached
                and not getgenv().IronSoulStopRequested
                and config.FARM ~= "OFF"
                and config.AutoSkill ~= false
            if canFarm and hasNearbyTarget() then
                for _, key in ipairs(keys) do
                    local now = os.clock()
                    if now >= (nextAllowed[key] or 0) then
                        local observedCD = cooldownFromGui(key)
                        if observedCD == nil or observedCD <= 0 then
                            local ok = pressKey(key)
                            if ok then
                                lastPressed[key] = now
                                nextAllowed[key] = now + fallbackCD[key]
                            else
                                nextAllowed[key] = now + 0.25
                            end
                        else
                            -- Trust visible cooldown; retry shortly after its remaining time.
                            nextAllowed[key] = now + math.max(0.10, math.min(observedCD, 2.0))
                        end
                        task.wait(0.04)
                    end
                end
            end
            task.wait(scanInterval)
        end
    end)
end
