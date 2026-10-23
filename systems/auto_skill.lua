-- K5-HUB IRONSOUL V2 - Mobile-first Auto Skill
-- Activates on-screen skill buttons labelled G/Q/E/R first; keyboard events
-- are only a fallback when the corresponding button cannot be found.

return function()
    local env = getgenv()
    if env.IronSoulMobileSkillLoopStarted then return end
    env.IronSoulMobileSkillLoopStarted = true

    local Players = game:GetService("Players")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local player = Players.LocalPlayer
    local keys = {"G", "Q", "E", "R"}
    local cooldowns = {G = 0, Q = 0, E = 0, R = 0}
    local cooldownsByKey = {G = 1.0, Q = 0.7, E = 0.7, R = 1.5}

    local function hasNearbyTarget()
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and model ~= character then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local targetRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                if humanoid and humanoid.Health > 0 and targetRoot
                    and not Players:GetPlayerFromCharacter(model)
                    and (targetRoot.Position - root.Position).Magnitude <= 600 then
                    return true
                end
            end
        end
        return false
    end

    local function buttonMatches(button, key)
        local name = string.lower(tostring(button.Name or "")):gsub("[%s_%-]", "")
        local text = ""
        pcall(function() text = string.lower(tostring(button.Text or "")):gsub("%s+", "") end)
        local aliases = {
            G = {g = true, skillg = true, skill4 = true},
            Q = {q = true, skillq = true, skill1 = true},
            E = {e = true, skille = true, skill2 = true},
            R = {r = true, skillr = true, skill3 = true, ultimate = true},
        }
        return aliases[key][name] == true or aliases[key][text] == true
    end

    local function findSkillButton(key)
        local pg = player and player:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("GuiButton") and buttonMatches(obj, key) then
                local visible = true
                pcall(function()
                    visible = obj.Visible and obj.Active
                    local parent = obj.Parent
                    while visible and parent and parent ~= pg do
                        if parent:IsA("GuiObject") and not parent.Visible then visible = false end
                        parent = parent.Parent
                    end
                end)
                if visible then return obj end
            end
        end
        return nil
    end

    local function activateSkill(key)
        local button = findSkillButton(key)
        if button then
            local ok = pcall(function() button:Activate() end)
            if ok then return true end
            if type(firesignal) == "function" then
                for _, signalName in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down"}) do
                    local success = pcall(function() firesignal(button[signalName]) end)
                    if success then return true end
                end
            end
        end

        local keyCode = Enum.KeyCode[key]
        if not keyCode then return false end
        return pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end

    task.spawn(function()
        while player and player.Parent do
            local config = getgenv().IronSoulConfig or {}
            if not getgenv().IronSoulLevelStopReached
                and getgenv().IronSoulMasterEnabled ~= false
                and config.FARM ~= "OFF"
                and config.AutoSkill ~= false
                and hasNearbyTarget() then
                for _, key in ipairs(keys) do
                    local now = os.clock()
                    if now >= (cooldowns[key] or 0) then
                        activateSkill(key)
                        cooldowns[key] = now + cooldownsByKey[key]
                        task.wait(0.12)
                    end
                end
            end
            task.wait(0.35)
        end
        getgenv().IronSoulMobileSkillLoopStarted = nil
    end)
end
