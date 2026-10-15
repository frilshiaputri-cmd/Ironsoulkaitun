-- K5-HUB IRONSOUL V2 - Tutorial entry
-- Automatically attempts the game's real Skip Tutorial button, then Lobby fallback.
local loadRaw = getgenv().IronSoulLoadRaw
if type(loadRaw) == "function" then
    local ok, result = loadRaw("systems/tutorial_v61_11.lua")
    if ok then return result end
    warn("[K5-HUB] Tutorial module failed to load: " .. tostring(result))
    return false
end
warn("[K5-HUB] Tutorial entry requires bootstrap_v2.lua to be loaded first.")
return false
