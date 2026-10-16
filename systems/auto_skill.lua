-- K5-HUB IRONSOUL V2 - Auto skill port from IronForge_AutoFarm_PremiumUI_v6_STABLE
-- Source behavior: press E, Q, R with per-skill cooldowns while this combat module is active.
-- This deliberately does not claim touch-screen support: VirtualInputManager key events
-- may not trigger mobile GUI skill buttons in Delta Android.

local started = false

return function()
    if started then return end
    started = true

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local cooldowns = { Q = 0, E = 0, R = 0 }
    local cooldownConfig = { Q = 0.70, E = 0.70, R = 1.50 }

    local function pressKey(keyName)
        local keyCode = Enum.KeyCode[keyName]
        if not keyCode then return false end

        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
        return ok
    end

    task.spawn(function()
        while player and player.Parent do
            -- This module is loaded by systems/combat.lua only, so it stays out of lobby flow.
            if not getgenv().IronSoulLevelStopReached
                and (getgenv().IronSoulConfig or {}).FARM ~= "OFF" then
                local now = os.clock()
                for _, key in ipairs({"E", "Q", "R"}) do
                    if now >= (cooldowns[key] or 0) then
                        pressKey(key)
                        cooldowns[key] = now + cooldownConfig[key]
                        task.wait(0.15)
                    end
                end
            end
            task.wait(0.10)
        end
    end)
end
