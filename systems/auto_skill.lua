-- IRONSOUL KAITUN V2 - legacy E/Q/R Auto Skill loop
-- Finds mobile skill controls by button name, visible text, descendant labels,
-- tooltip/attributes, and common Skill1/Skill2/Skill3/Skill4 aliases.

return function()
    local env = getgenv()
    if env.IronSoulMobileSkillLoopStarted then return end
    env.IronSoulMobileSkillLoopStarted = true

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local player = Players.LocalPlayer
    local keys = {"E", "Q", "R"}
    local cooldowns = {E = 0, Q = 0, R = 0}
    local cooldownsByKey = {E = 0.7, Q = 0.7, R = 1.5}
    local aliases = {
        E = {e=true, skille=true, skill2=true, secondskill=true, skilltwo=true},
        Q = {q=true, skillq=true, skill1=true, firstskill=true, skillone=true},
        R = {r=true, skillr=true, skill3=true, thirdskill=true, skillthree=true, ultimate=true, ult=true},
    }

    local function normalize(value)
        return string.lower(tostring(value or "")):gsub("[%s_%-%.:]", "")
    end

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

    local function candidateText(obj)
        local values = {obj.Name}
        pcall(function()
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                table.insert(values, obj.Text)
            end
            table.insert(values, obj:GetAttribute("KeyCode"))
            table.insert(values, obj:GetAttribute("Key"))
            table.insert(values, obj:GetAttribute("Skill"))
            table.insert(values, obj:GetAttribute("Action"))
            table.insert(values, obj:GetAttribute("Hotkey"))
            table.insert(values, obj:GetAttribute("ToolTip"))
        end)
        return values
    end

    local function matchesKey(obj, key)
        for _, value in ipairs(candidateText(obj)) do
            local n = normalize(value)
            if aliases[key][n] then return true end
            -- Accept strings such as "Press [Q]" or "Q Skill", but avoid
            -- treating arbitrary longer words containing the letter as a match.
            if n == "press"..string.lower(key)
                or n == "key"..string.lower(key)
                or n == "skill"..string.lower(key) then
                return true
            end
        end
        return false
    end

    local function isVisible(button, pg)
        local visible = true
        pcall(function()
            if not button.Visible or not button.Active then visible = false end
            local parent = button.Parent
            while visible and parent and parent ~= pg do
                if parent:IsA("GuiObject") and not parent.Visible then visible = false end
                parent = parent.Parent
            end
        end)
        return visible
    end

    local function findSkillButton(key)
        local pg = player and player:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        local best, bestScore
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("GuiButton") and isVisible(obj, pg) then
                local score = 0
                if matchesKey(obj, key) then score = score + 10 end
                -- Some games put the hotkey on a child TextLabel/ImageLabel.
                for _, child in ipairs(obj:GetDescendants()) do
                    if matchesKey(child, key) then score = score + 5 break end
                end
                if score > 0 and (not bestScore or score > bestScore) then
                    best, bestScore = obj, score
                end
            end
        end
        return best
    end

    local function activateSkill(key)
        local button = findSkillButton(key)
        if button then
            local ok, result = pcall(function() return button:Activate() end)
            if ok then return true end
            if type(firesignal) == "function" then
                for _, signalName in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down"}) do
                    local signal
                    pcall(function() signal = button[signalName] end)
                    if signal then
                        local success = pcall(firesignal, signal)
                        if success then return true end
                    end
                end
            end
        end

        -- Keyboard fallback is useful on desktop. On touch-only devices this
        -- may be ignored by the game, so the button lookup above is preferred.
        local keyCode = Enum.KeyCode[key]
        if not keyCode then return false end
        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
        if not ok and UserInputService.TouchEnabled then return false end
        return ok
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
