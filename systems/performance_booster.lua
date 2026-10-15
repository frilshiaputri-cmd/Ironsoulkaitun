-- K5-HUB IRONSOUL V2 | Performance Booster
-- Client-side visual optimization. Toggle button sits below the K5-HUB status.
-- This module only changes graphics/FPS settings; it does not stop farm/skills.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then return false end

local GEN = getgenv()
if GEN.K5PerformanceBooster and GEN.K5PerformanceBooster.Gui
    and GEN.K5PerformanceBooster.Gui.Parent then
    return true
end

local FPS_CAP = 60
local enabled = true
local snapshots = {}
local tracked = setmetatable({}, { __mode = "k" })
local connections = {}
local gui, button

local function setStatus(text)
    local statusFn = GEN.IronSoulStatus
    if type(statusFn) == "function" then pcall(statusFn, text) end
end

local function remember(obj, prop)
    if not obj or not obj.Parent then return end
    local ok, value = pcall(function() return obj[prop] end)
    if not ok then return end
    snapshots[obj] = snapshots[obj] or {}
    if snapshots[obj][prop] == nil then
        snapshots[obj][prop] = value
    end
end

local function setProp(obj, prop, value)
    remember(obj, prop)
    pcall(function() obj[prop] = value end)
end

local function optimizeObject(obj)
    if not enabled or not obj then return end
    local class = obj.ClassName
    if class == "ParticleEmitter" or class == "Trail" or class == "Beam"
        or class == "Smoke" or class == "Fire" or class == "Sparkles" then
        setProp(obj, "Enabled", false)
    elseif class == "BloomEffect" or class == "BlurEffect"
        or class == "ColorCorrectionEffect" or class == "DepthOfFieldEffect"
        or class == "SunRaysEffect" then
        setProp(obj, "Enabled", false)
    elseif obj:IsA("BasePart") then
        setProp(obj, "CastShadow", false)
        if obj:IsA("MeshPart") then setProp(obj, "TextureID", "") end
        if obj.Material ~= Enum.Material.SmoothPlastic then
            setProp(obj, "Material", Enum.Material.SmoothPlastic)
        end
        if obj.Reflectance ~= 0 then setProp(obj, "Reflectance", 0) end
    elseif class == "Decal" or class == "Texture" then
        setProp(obj, "Transparency", 1)
    end
end

local function optimizeAll()
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.FogEnd = 1000000 end)
    pcall(function()
        local settings = UserSettings():GetService("UserGameSettings")
        settings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
    for _, obj in ipairs(Lighting:GetDescendants()) do optimizeObject(obj) end
    for _, obj in ipairs(Workspace:GetDescendants()) do optimizeObject(obj) end
end

local function restoreAll()
    for obj, props in pairs(snapshots) do
        if obj and obj.Parent then
            for prop, value in pairs(props) do
                pcall(function() obj[prop] = value end)
            end
        end
    end
    snapshots = {}
end

local function apply()
    if enabled then
        if type(setfpscap) == "function" then pcall(setfpscap, FPS_CAP) end
        optimizeAll()
        if button then
            button.Text = "K5 FPS BOOST: ON"
            button.BackgroundColor3 = Color3.fromRGB(44, 130, 80)
        end
        setStatus("Performance Booster ON | FPS cap 60 | low graphics")
    else
        restoreAll()
        if button then
            button.Text = "K5 FPS BOOST: OFF"
            button.BackgroundColor3 = Color3.fromRGB(115, 65, 65)
        end
        setStatus("Performance Booster OFF | visual settings restored")
    end
end

local function buildGui()
    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end
    local old = playerGui:FindFirstChild("K5PerformanceBoosterGui")
    if old then old:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "K5PerformanceBoosterGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 1000000
    local touch = UserInputService.TouchEnabled
    button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.Size = touch and UDim2.fromOffset(170, 32) or UDim2.fromOffset(190, 32)
    button.Position = UDim2.new(0, 8, 0, 62)
    button.BackgroundColor3 = Color3.fromRGB(44, 130, 80)
    button.BorderSizePixel = 0
    button.Text = "K5 FPS BOOST: ON"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button
    button.Activated:Connect(function()
        enabled = not enabled
        apply()
    end)
    gui.Parent = playerGui
end

buildGui()
if not button then return false end
GEN.K5PerformanceBooster = {
    Gui = gui,
    SetEnabled = function(value)
        enabled = value == true
        apply()
    end,
    IsEnabled = function() return enabled end,
}
apply()

local function watch(container)
    table.insert(connections, container.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if enabled then optimizeObject(obj) end
        end)
    end))
end
watch(Lighting)
watch(Workspace)

-- Re-apply to effects/parts spawned after entering a new map.
task.spawn(function()
    while gui and gui.Parent do
        if enabled then optimizeAll() end
        task.wait(8)
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if enabled then optimizeAll() end
end)

return true
