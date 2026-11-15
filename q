-- ============================================================
--  Visuals + ESP (Mobile optimized, hardened, self-healing)
--  ESP: Name, Distance, Health, BOX (outline)
--  Features: Fullbright, Remove Fog, Remove Grass Decor
--  Auto-cleanup of previous version
--  No console output
-- ============================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  AUTO-CLEANUP предыдущей версии
-- ============================================================
if type(_G.__visuals_cleanup) == "function" then
    pcall(_G.__visuals_cleanup)
end

local cleanupInstances = {}
local cleanupConnections = {}

local function track(inst)
    table.insert(cleanupInstances, inst)
    return inst
end
local function trackConn(conn)
    table.insert(cleanupConnections, conn)
    return conn
end

_G.__visuals_cleanup = function()
    for _, c in pairs(cleanupConnections) do
        pcall(function() c:Disconnect() end)
    end
    cleanupConnections = {}
    for _, i in pairs(cleanupInstances) do
        pcall(function() i:Destroy() end)
    end
    cleanupInstances = {}
end

-- добиваем остатки от прежних запусков (если _G потерялся)
do
    local function nukeIn(parent)
        for _, obj in pairs(parent:GetChildren()) do
            if obj:GetAttribute("__visuals_menu") or obj:GetAttribute("__visuals_esp") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    pcall(nukeIn, CoreGui)
    pcall(nukeIn, LocalPlayer:WaitForChild("PlayerGui"))
end

-- ============================================================
--  GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ""
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui:SetAttribute("__visuals_menu", true)
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
track(ScreenGui)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 270, 0, 300)
MainFrame.Position = UDim2.new(0, 15, 0, 15)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
track(MainFrame)

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Шапка
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Active = true
TitleBar.Parent = MainFrame
track(TitleBar)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- ВИДИМАЯ кнопка сворачивания
local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size = UDim2.new(0, 40, 0, 40)
CollapseBtn.Position = UDim2.new(1, -45, 0, 5)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
CollapseBtn.BorderSizePixel = 0
CollapseBtn.Text = "▼"
CollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.TextSize = 22
CollapseBtn.Parent = TitleBar
track(CollapseBtn)

local CollapseCorner = Instance.new("UICorner")
CollapseCorner.CornerRadius = UDim.new(0, 8)
CollapseCorner.Parent = CollapseBtn

local collapsed = false
local function setCollapsed(state)
    collapsed = state
    MainFrame.Size = collapsed and UDim2.new(0, 270, 0, 50) or UDim2.new(0, 270, 0, 300)
    CollapseBtn.Text = collapsed and "▲" or "▼"
end

CollapseBtn.MouseButton1Click:Connect(function()
    setCollapsed(not collapsed)
end)

-- ============================================================
--  Кнопки
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
    track(btn)

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
    track(btn)

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

createActionButton("Remove Grass", 220, function()
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.Decoration = false
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
--  ESP + BOX (self-healing)
-- ============================================================
local espObjects = {}

local function attachToChar(data, char)
    if not char or not data or not data.billboard or not data.billboard.Parent then return end
    local head = char:FindFirstChild("Head")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local on   = getEspState()

    if head then
        data.billboard.Adornee = head
        data.billboard.Enabled = on
    else
        data.billboard.Adornee = nil
        data.billboard.Enabled = false
    end

    if hrp then
        data.boxBillboard.Adornee = hrp
        data.boxBillboard.Enabled = on
    else
        data.boxBillboard.Adornee = nil
        data.boxBillboard.Enabled = false
    end
end

local function detachChar(data)
    if not data then return end
    if data.billboard and data.billboard.Parent then
        data.billboard.Adornee = nil
        data.billboard.Enabled = false
    end
    if data.boxBillboard and data.boxBillboard.Parent then
        data.boxBillboard.Adornee = nil
        data.boxBillboard.Enabled = false
    end
end

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
    billboard.MaxDistance = 0
    billboard.Enabled = false
    billboard:SetAttribute("__visuals_esp", true)
    billboard.Parent = ScreenGui
    track(billboard)

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
    boxBillboard.MaxDistance = 0
    boxBillboard.Enabled = false
    boxBillboard:SetAttribute("__visuals_esp", true)
    boxBillboard.Parent = ScreenGui
    track(boxBillboard)

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

    local data = {
        billboard    = billboard,
        boxBillboard = boxBillboard,
        nameLabel    = nameLabel,
        distLabel    = distLabel,
        healthLabel  = healthLabel,
        boxStroke    = boxStroke,
        charAdded    = nil,
        charRemoving = nil,
    }
    espObjects[player] = data

    -- Мгновенная привязка при возрождении
    data.charAdded = player.CharacterAdded:Connect(function(char)
        task.spawn(function()
            char:WaitForChild("Head", 5)
            char:WaitForChild("HumanoidRootPart", 5)
            attachToChar(data, char)
        end)
    end)
    trackConn(data.charAdded)

    -- Мгновенное скрытие при смерти
    data.charRemoving = player.CharacterRemoving:Connect(function()
        detachChar(data)
    end)
    trackConn(data.charRemoving)

    -- Привязать к текущему персонажу (если уже есть)
    if player.Character then
        task.spawn(function()
            local c = player.Character
            if c then
                c:WaitForChild("Head", 3)
                c:WaitForChild("HumanoidRootPart", 3)
                attachToChar(data, c)
            end
        end)
    end
end

local function removeESP(player)
    local data = espObjects[player]
    if not data then return end
    if data.charAdded then pcall(function() data.charAdded:Disconnect() end) end
    if data.charRemoving then pcall(function() data.charRemoving:Disconnect() end) end
    if data.billboard then pcall(function() data.billboard:Destroy() end) end
    if data.boxBillboard then pcall(function() data.boxBillboard:Destroy() end) end
    espObjects[player] = nil
end

-- ============================================================
--  Быстрый путь: события игроков
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    if getEspState() then createESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ============================================================
--  Heartbeat: полная сверка (страховка)
-- ============================================================
RunService.Heartbeat:Connect(function()
    local espOn = getEspState()
    local fbOn = getFbState()

    if fbOn then applyFullbright() end

    -- Строим текущий набор игроков
    local present = {}
    for _, p in pairs(Players:GetPlayers()) do
        present[p] = true
    end

    -- 1) Удаляем ESP для ушедших / разрушенных
    for player, data in pairs(espObjects) do
        if not present[player] or not player.Parent then
            removeESP(player)
        elseif not data.billboard.Parent or not data.boxBillboard.Parent then
            -- билборд уничтожен — пересоздаём
            removeESP(player)
            if espOn then createESP(player) end
        end
    end

    -- 2) Создаём ESP для новых, если ESP включён
    if espOn then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not espObjects[player] then
                createESP(player)
            end
        end
    end

    -- 3) Обновляем состояние всех ESP
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(espObjects) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        -- всегда переустанавливаем Adornee (страховка от сброса)
        if head then data.billboard.Adornee = head
        else data.billboard.Adornee = nil end
        if hrp then data.boxBillboard.Adornee = hrp
        else data.boxBillboard.Adornee = nil end

        if not (head and hrp) then
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
end)

-- ============================================================
--  Начальная инициализация
-- ============================================================
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end
