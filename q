-- ============================================================
--  Visuals + ESP (Mobile optimized)
--  ESP: Name, Distance, Health, BOX (outline)
--  Features: Fullbright, Remove Fog, Remove Grass (only grass)
--  No console output
-- ============================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  GUI (крупный, под телефоны)
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ""
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
MainFrame.Size = UDim2.new(0, 270, 0, 300)
MainFrame.Position = UDim2.new(0, 15, 0, 15)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true   -- ВАЖНО: чтобы кнопки прятались при сворачивании
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Заголовок (пустой, тап = свернуть/развернуть)
local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.BorderSizePixel = 0
Title.Text = ""                    -- пустая шапка
Title.AutoButtonColor = false
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local collapsed = false
Title.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    MainFrame.Size = collapsed and UDim2.new(0, 270, 0, 50) or UDim2.new(0, 270, 0, 300)
end)

-- ============================================================
--  Кнопки (увеличенные, тач-френдли)
-- ============================================================
local function createToggle(name, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 250, 0, 46)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 130, 60) or Color3.fromRGB(40, 40, 40)
    end)
    return btn, function() return state end
end

local espBtn, getEspState = createToggle("ESP", 58)
local fbBtn, getFbState = createToggle("Fullbright", 112)

local function createActionButton(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 250, 0, 46)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(65, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

createActionButton("Remove Fog", 166, function()
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

-- Удаление ТОЛЬКО травы (Grass -> Ground), земля остаётся
createActionButton("Remove Grass", 220, function()
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if not terrain then return end

        local ok, size = pcall(function() return terrain:GetExtentsSize() end)
        if not ok or not size then
            size = Vector3.new(4096, 1024, 4096)
        end

        local halfX = math.ceil(size.X / 2) + 64
        local halfY = math.ceil(size.Y / 2) + 64
        local halfZ = math.ceil(size.Z / 2) + 64
        local chunk = 512

        local x = -halfX
        while x < halfX do
            local z = -halfZ
            while z < halfZ do
                local region = Region3.new(
                    Vector3.new(x, -halfY, z),
                    Vector3.new(math.min(x + chunk, halfX), halfY, math.min(z + chunk, halfZ))
                )
                pcall(function()
                    terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
                end)
                z = z + chunk
                task.wait(0.01)
            end
            x = x + chunk
            task.wait(0.01)
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
--  ESP + BOX
-- ============================================================
local espObjects = {}

local function createESP(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end

    -- Инфо
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Info_" .. player.Name
    billboard.Size = UDim2.new(0, 220, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.LightInfluence = 0
    billboard.Enabled = false

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 20)
    distLabel.Position = UDim2.new(0, 0, 0, 22)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0 m"
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 14
    distLabel.TextStrokeTransparency = 0
    distLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 20)
    healthLabel.Position = UDim2.new(0, 0, 0, 44)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "HP: 100/100"
    healthLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextSize = 14
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Parent = billboard

    -- Бокс
    local boxBillboard = Instance.new("BillboardGui")
    boxBillboard.Name = "ESP_Box_" .. player.Name
    boxBillboard.Size = UDim2.new(2.5, 0, 5.5, 0)
    boxBillboard.AlwaysOnTop = true
    boxBillboard.ResetOnSpawn = false
    boxBillboard.LightInfluence = 0
    boxBillboard.Enabled = false

    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundTransparency = 1
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = boxBillboard

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 2.5
    boxStroke.Color = Color3.fromRGB(0, 255, 0)
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Parent = boxFrame

    local char = player.Character
    if char then
        local head = char:FindFirstChild("Head")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if head then billboard.Parent = head end
        if hrp then boxBillboard.Adornee = hrp; boxBillboard.Parent = hrp end
    end

    espObjects[player] = {
        billboard    = billboard,
        boxBillboard = boxBillboard,
        nameLabel    = nameLabel,
        distLabel    = distLabel,
        healthLabel  = healthLabel,
        boxStroke    = boxStroke,
    }

    player.CharacterAdded:Connect(function(newChar)
        local head = newChar:WaitForChild("Head", 5)
        local hrp  = newChar:WaitForChild("HumanoidRootPart", 5)
        if head then billboard.Parent = head else billboard.Parent = ScreenGui end
        if hrp then
            boxBillboard.Adornee = hrp
            boxBillboard.Parent = hrp
        else
            boxBillboard.Parent = ScreenGui
        end
    end)
end

local function removeESP(player)
    if espObjects[player] then
        if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
        if espObjects[player].boxBillboard then espObjects[player].boxBillboard:Destroy() end
        espObjects[player] = nil
    end
end

-- ============================================================
--  Обновление
-- ============================================================
RunService.Heartbeat:Connect(function()
    local espOn = getEspState()
    local fbOn = getFbState()

    if fbOn then applyFullbright() end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(espObjects) do
        if not player.Parent then
            removeESP(player)
            continue
        end

        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        if not head or not hrp then
            data.billboard.Enabled = false
            data.boxBillboard.Enabled = false
            continue
        end

        data.billboard.Enabled = espOn
        data.boxBillboard.Enabled = espOn
        if not espOn then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if humanoid then
            local curHP = math.floor(humanoid.Health)
            local maxHP = math.floor(humanoid.MaxHealth)
            data.healthLabel.Text = string.format("HP: %d/%d", curHP, maxHP)

            local ratio = (maxHP > 0) and (curHP / maxHP) or 1
            if ratio > 0.6 then
                data.boxStroke.Color = Color3.fromRGB(0, 255, 0)
            elseif ratio > 0.3 then
                data.boxStroke.Color = Color3.fromRGB(255, 220, 0)
            else
                data.boxStroke.Color = Color3.fromRGB(255, 50, 50)
            end
        end

        if myRoot then
            local dist = (myRoot.Position - head.Position).Magnitude
            data.distLabel.Text = string.format("%d m", math.floor(dist))
        end
    end

    if espOn then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not espObjects[player] then
                createESP(player)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if getEspState() then createESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end
