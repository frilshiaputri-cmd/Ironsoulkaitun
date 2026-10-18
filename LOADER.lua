-- K5-HUB | Stable entry loader for IronSoul V1
-- Keep this file path, repository, and branch unchanged.
-- Update the target file's contents instead of changing the public loader URL.

local V1_URL = "https://raw.githubusercontent.com/frilshiaputri-cmd/Ironsoulkaitun/main/IRONSOUL_V1_AUTOSKILL.lua"

if type(loadstring) ~= "function" then
    warn("[K5-HUB V1 Loader] Executor tidak mendukung loadstring.")
    return
end

local ok, source = pcall(function()
    return game:HttpGet(V1_URL .. "?k5=" .. tostring(os.time()))
end)

if not ok or type(source) ~= "string" or #source < 1000 then
    warn("[K5-HUB V1 Loader] Gagal mengambil script V1: " .. tostring(source))
    return
end

local chunk, compileErr = loadstring(source)
if not chunk then
    warn("[K5-HUB V1 Loader] Compile gagal: " .. tostring(compileErr))
    return
end

local runOk, runErr = pcall(chunk)
if not runOk then
    warn("[K5-HUB V1 Loader] Runtime error: " .. tostring(runErr))
end
