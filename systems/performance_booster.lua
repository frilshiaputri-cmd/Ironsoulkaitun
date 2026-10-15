-- K5-HUB IRONSOUL V2 | Graphics optimizer controlled by the master switch.
-- No separate UI button: K5-HUB V2 master toggle owns ON/OFF.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
if not player then return false end

local GEN = getgenv()
if GEN.K5PerformanceBooster and GEN.K5PerformanceBooster.Active then
    GEN.K5PerformanceBooster.SetEnabled(GEN.IronSoulMasterEnabled ~= false)
    return true
end

local enabled = false
local snapshots = {}
local connections = {}
local state = { Active = true }

local function remember(obj, prop)
    if not obj or not obj.Parent then return end
    local ok, value = pcall(function() return obj[prop] end)
    if not ok then return end
    snapshots[obj] = snapshots[obj] or {}
    if snapshots[obj][prop] == nil then snapshots[obj][prop] = value end
end

local function setProp(obj, prop, value)
    remember(obj, prop)
    pcall(function() obj[prop] = value end)
end

local function optimizeObject(obj)
    if not enabled or not obj then return end
    local class = obj.ClassName
    if class == "ParticleEmitter" or class == "Trail" or class == "Beam"
        or class == "Smoke" or class == "Fire" or class == "Sparkles"
        or class == "BloomEffect" or class == "BlurEffect"
        or class == "ColorCorrectionEffect" or class == "DepthOfFieldEffect"
        or class == "SunRaysEffect" then
        setProp(obj, "Enabled", false)
    elseif obj:IsA("BasePart") then
        setProp(obj, "CastShadow", false)
        if obj:IsA("MeshPart") then setProp(obj, "TextureID", "") end
        setProp(obj, "Material", Enum.Material.SmoothPlastic)
        setProp(obj, "Reflectance", 0)
    elseif class == "Decal" or class == "Texture" then
        setProp(obj, "Transparency", 1)
    end
end

local function optimizeAll()
    if not enabled then return end
    setProp(Lighting, "GlobalShadows", false)
    setProp(Lighting, "FogEnd", 1000000)
    pcall(function()
        local settings = UserSettings():GetService("UserGameSettings")
        setProp(settings, "SavedQualityLevel", Enum.SavedQualitySetting.QualityLevel1)
    end)
    for _, obj in ipairs(Lighting:GetDescendants()) do optimizeObject(obj) end
    for _, obj in ipairs(Workspace:GetDescendants()) do optimizeObject(obj) end
end

local function restoreAll()
    for obj, props in pairs(snapshots) do
        if obj and obj.Parent then
            for prop, value in pairs(props) do pcall(function() obj[prop] = value end) end
        end
    end
    snapshots = {}
end

function state.SetEnabled(value)
    enabled = value == true
    if enabled then
        if type(setfpscap) == "function" then pcall(setfpscap, 60) end
        optimizeAll()
    else
        restoreAll()
    end
end
function state.IsEnabled() return enabled end
GEN.K5PerformanceBooster = state
state.SetEnabled(GEN.IronSoulMasterEnabled ~= false)

local function watch(container)
    table.insert(connections, container.DescendantAdded:Connect(function(obj)
        task.defer(function() if enabled then optimizeObject(obj) end end)
    end))
end
watch(Lighting)
watch(Workspace)
for _, connection in ipairs(connections) do
    table.insert(GEN.IronSoulManagedConnections or {}, connection)
end
task.spawn(function()
    while state.Active do
        if enabled then optimizeAll() end
        task.wait(8)
    end
end)
player.CharacterAdded:Connect(function()
    task.wait(1)
    if enabled then optimizeAll() end
end)
return true
