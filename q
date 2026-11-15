-- ============================================================
--  Universal Visuals + ESP (no console output)
--  Features: ESP (Name, Distance, Health), Fullbright,
--            Remove Fog, Remove Grass
-- ============================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VisualsMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 260)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.BorderSizePixel = 0
Title.Text = "Visuals Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- ============================================================
--  Toggle buttons
-- ============================================================
local function createToggle(name, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40, 40, 40)
    end)
    return btn, function() return state end
end

local espBtn, getEspState = createToggle("ESP", 45)
local fbBtn, getFbState = createToggle("Fullbright", 80)

-- ============================================================
--  Action buttons
-- ============================================================
local function createActionButton(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

createActionButton("Remove Fog", 115, function()
    pcall(function()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Atmosphere") or obj:IsA("LightingLayer") then
                obj:Destroy()
            end
        end
    end)
end)

createActionButton("Remove Grass", 150, function()
    pcall(function()
        if Terrain then
            Terrain:Clear()
        end
    end)
end)

-- ============================================================
--  Fullbright
-- ============================================================
local function applyFullbright()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    end)
end

-- ============================================================
--  ESP
-- ============================================================
local espObjects = {} -- [player] = { billboard = ..., nameLabel, distLabel, healthLabel }

local function createESP(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.Enabled = false

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 0, 0, 20)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0 m"
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 12
    distLabel.TextStrokeTransparency = 0
    distLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 18)
    healthLabel.Position = UDim2.new(0, 0, 0, 38)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "HP: 100/100"
    healthLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Parent = billboard

    espObjects[player] = {
        billboard = billboard,
        nameLabel = nameLabel,
        distLabel = distLabel,
        healthLabel = healthLabel,
    }

    local char = player.Character
    if char and char:FindFirstChild("Head") then
        billboard.Parent = char.Head
    else
        billboard.Parent = ScreenGui
    end

    player.CharacterAdded:Connect(function(newChar)
        local head = newChar:WaitForChild("Head", 5)
        if head then
            billboard.Parent = head
        end
    end)
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].billboard:Destroy()
        espObjects[player] = nil
    end
end

-- ============================================================
--  ESP update loop
-- ============================================================
RunService.Heartbeat:Connect(function()
    local espOn = getEspState()
    local fbOn = getFbState()

    if fbOn then
        applyFullbright()
    end

    -- ESP
    for player, data in pairs(espObjects) do
        if not player.Parent then
            removeESP(player)
            continue
        end

        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        if not head then
            data.billboard.Enabled = false
            continue
        end

        data.billboard.Enabled = espOn
        if not espOn then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            data.healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
        end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local dist = (myRoot.Position - head.Position).Magnitude
            data.distLabel.Text = string.format("%d m", math.floor(dist))
        end
    end

    -- add ESP for new players if enabled
    if espOn then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not espObjects[player] then
                createESP(player)
            end
        end
    end
end)

-- player events
Players.PlayerAdded:Connect(function(player)
    if getEspState() then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- initial ESP creation
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end
