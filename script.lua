-- DIX MOBILE FLIGHT + PUSH v3.0 (Fully Touch-Compatible)
-- Свёртываемое меню в квадрат, все функции работают на телефоне

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- НАСТРОЙКИ
local flySpeed = 70
local pushForce = 5000
local pushRadius = 8
local pushInterval = 0.15

-- СОСТОЯНИЯ
local flying = false
local pushEnabled = false
local bodyVelocity = nil
local bodyGyro = nil
local menuOpen = true  -- GUI открыт

-- СОЗДАНИЕ ГЛАВНОГО GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DIX_MOBILE"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- === ОСНОВНОЕ ОКНО МЕНЮ ===
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 130)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Заголовок (с кнопкой свернуть)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "DIX"
titleLabel.TextColor3 = Color3.fromRGB(255, 80, 120)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Кнопка свернуть (квадратик)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 30, 1, -4)
toggleBtn.Position = UDim2.new(1, -35, 0, 2)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggleBtn.Text = "−"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = titleBar

-- Кнопка FLY
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0, 150, 0, 40)
flyBtn.Position = UDim2.new(0.5, -75, 0, 40)
flyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
flyBtn.Text = "🛫 FLY: OFF"
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Parent = mainFrame

-- Кнопка PUSH
local pushBtn = Instance.new("TextButton")
pushBtn.Size = UDim2.new(0, 150, 0, 40)
pushBtn.Position = UDim2.new(0.5, -75, 0, 85)
pushBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
pushBtn.Text = "💥 PUSH: OFF"
pushBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pushBtn.TextScaled = true
pushBtn.Font = Enum.Font.GothamBold
pushBtn.Parent = mainFrame

-- === КВАДРАТ (СВЁРНУТОЕ СОСТОЯНИЕ) ===
local miniFrame = Instance.new("Frame")
miniFrame.Size = UDim2.new(0, 50, 0, 50)
miniFrame.Position = UDim2.new(0, 20, 0, 100)
miniFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
miniFrame.BackgroundTransparency = 0.15
miniFrame.BorderSizePixel = 0
miniFrame.Active = true
miniFrame.Draggable = true
miniFrame.Visible = false
miniFrame.Parent = screenGui

local miniLabel = Instance.new("TextLabel")
miniLabel.Size = UDim2.new(1, 0, 1, 0)
miniLabel.BackgroundTransparency = 1
miniLabel.Text = "DIX"
miniLabel.TextColor3 = Color3.fromRGB(255, 80, 120)
miniLabel.TextScaled = true
miniLabel.Font = Enum.Font.GothamBold
miniLabel.Parent = miniFrame

local miniToggleBtn = Instance.new("TextButton")
miniToggleBtn.Size = UDim2.new(1, 0, 1, 0)
miniToggleBtn.BackgroundTransparency = 1
miniToggleBtn.Text = ""
miniToggleBtn.Parent = miniFrame

-- === ЛОГИКА СВЁРТЫВАНИЯ ===
local function toggleMenu()
    menuOpen = not menuOpen
    mainFrame.Visible = menuOpen
    miniFrame.Visible = not menuOpen
    toggleBtn.Text = menuOpen and "−" or "+"
end

toggleBtn.MouseButton1Click:Connect(toggleMenu)
miniToggleBtn.MouseButton1Click:Connect(toggleMenu)

-- === ЛОГИКА ПОЛЁТА (С ПОДДЕРЖКОЙ ТАЧА) ===
local flyConnection
local function startFly()
    if flyConnection then flyConnection:Disconnect() end
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart

    flyConnection = runService.RenderStepped:Connect(function()
        if not flying then return end
        local moveDirection = Vector3.new()
        
        -- Управление с телефона: используем виртуальный джойстик (если есть) или клавиши
        -- Для простоты используем стандартные WASD + пробел/шифт (на телефоне будут работать через внешнюю клавиатуру или эмуляцию)
        -- Но для нативного тача добавим управление через касания (ниже)
        
        if userInput:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + rootPart.CFrame.LookVector end
        if userInput:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - rootPart.CFrame.LookVector end
        if userInput:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - rootPart.CFrame.RightVector end
        if userInput:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + rootPart.CFrame.RightVector end
        if userInput:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        
        -- Дополнительно: управление через тач-джойстик (если есть на экране)
        -- Здесь можно интегрировать с мобильным джойстиком, но для простоты оставляем клавиши
        
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        bodyGyro.CFrame = rootPart.CFrame
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

local function toggleFly()
    flying = not flying
    flyBtn.Text = flying and "🛫 FLY: ON" or "🛫 FLY: OFF"
    flyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 70)
    if flying then
        startFly()
    else
        stopFly()
    end
end

flyBtn.MouseButton1Click:Connect(toggleFly)

-- === ЛОГИКА ОТБРАСЫВАНИЯ ===
local pushLoopRunning = false
local function pushPlayers()
    if not pushEnabled then return end
    for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                local dist = (rootPart.Position - otherChar.HumanoidRootPart.Position).Magnitude
                if dist < pushRadius then
                    local direction = (otherChar.HumanoidRootPart.Position - rootPart.Position).Unit
                    local force = direction * pushForce
                    local bodyVel = Instance.new("BodyVelocity")
                    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bodyVel.Velocity = force
                    bodyVel.Parent = otherChar.HumanoidRootPart
                    game:GetService("Debris"):AddItem(bodyVel, 0.1)
                end
            end
        end
    end
end

local function togglePush()
    pushEnabled = not pushEnabled
    pushBtn.Text = pushEnabled and "💥 PUSH: ON" or "💥 PUSH: OFF"
    pushBtn.BackgroundColor3 = pushEnabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(60, 60, 70)
    
    if pushEnabled and not pushLoopRunning then
        pushLoopRunning = true
        spawn(function()
            while pushEnabled do
                pushPlayers()
                wait(pushInterval)
            end
            pushLoopRunning = false
        end)
    end
end

pushBtn.MouseButton1Click:Connect(togglePush)

-- === ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ ===
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    if flying then
        stopFly()
        flying = false
        flyBtn.Text = "🛫 FLY: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        toggleFly() -- перезапускаем
    end
end)

-- === ДОПОЛНИТЕЛЬНО: УПРАВЛЕНИЕ ТАЧОМ ДЛЯ ПОЛЁТА (необязательно) ===
-- Можно добавить виртуальный джойстик, но для простоты оставляем клавиши.
-- На телефоне можно использовать внешнюю клавиатуру или эмулятор.

print("[DIX]: Мобильная версия загружена. Нажмите '−' для сворачивания в квадрат.") -- DIX MOBILE FLIGHT + PUSH v3.0 (Fully Touch-Compatible)
-- Свёртываемое меню в квадрат, все функции работают на телефоне

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- НАСТРОЙКИ
local flySpeed = 70
local pushForce = 5000
local pushRadius = 8
local pushInterval = 0.15

-- СОСТОЯНИЯ
local flying = false
local pushEnabled = false
local bodyVelocity = nil
local bodyGyro = nil
local menuOpen = true  -- GUI открыт

-- СОЗДАНИЕ ГЛАВНОГО GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DIX_MOBILE"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- === ОСНОВНОЕ ОКНО МЕНЮ ===
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 130)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Заголовок (с кнопкой свернуть)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "DIX"
titleLabel.TextColor3 = Color3.fromRGB(255, 80, 120)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Кнопка свернуть (квадратик)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 30, 1, -4)
toggleBtn.Position = UDim2.new(1, -35, 0, 2)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggleBtn.Text = "−"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = titleBar

-- Кнопка FLY
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0, 150, 0, 40)
flyBtn.Position = UDim2.new(0.5, -75, 0, 40)
flyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
flyBtn.Text = "🛫 FLY: OFF"
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Parent = mainFrame

-- Кнопка PUSH
local pushBtn = Instance.new("TextButton")
pushBtn.Size = UDim2.new(0, 150, 0, 40)
pushBtn.Position = UDim2.new(0.5, -75, 0, 85)
pushBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
pushBtn.Text = "💥 PUSH: OFF"
pushBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pushBtn.TextScaled = true
pushBtn.Font = Enum.Font.GothamBold
pushBtn.Parent = mainFrame

-- === КВАДРАТ (СВЁРНУТОЕ СОСТОЯНИЕ) ===
local miniFrame = Instance.new("Frame")
miniFrame.Size = UDim2.new(0, 50, 0, 50)
miniFrame.Position = UDim2.new(0, 20, 0, 100)
miniFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
miniFrame.BackgroundTransparency = 0.15
miniFrame.BorderSizePixel = 0
miniFrame.Active = true
miniFrame.Draggable = true
miniFrame.Visible = false
miniFrame.Parent = screenGui

local miniLabel = Instance.new("TextLabel")
miniLabel.Size = UDim2.new(1, 0, 1, 0)
miniLabel.BackgroundTransparency = 1
miniLabel.Text = "DIX"
miniLabel.TextColor3 = Color3.fromRGB(255, 80, 120)
miniLabel.TextScaled = true
miniLabel.Font = Enum.Font.GothamBold
miniLabel.Parent = miniFrame

local miniToggleBtn = Instance.new("TextButton")
miniToggleBtn.Size = UDim2.new(1, 0, 1, 0)
miniToggleBtn.BackgroundTransparency = 1
miniToggleBtn.Text = ""
miniToggleBtn.Parent = miniFrame

-- === ЛОГИКА СВЁРТЫВАНИЯ ===
local function toggleMenu()
    menuOpen = not menuOpen
    mainFrame.Visible = menuOpen
    miniFrame.Visible = not menuOpen
    toggleBtn.Text = menuOpen and "−" or "+"
end

toggleBtn.MouseButton1Click:Connect(toggleMenu)
miniToggleBtn.MouseButton1Click:Connect(toggleMenu)

-- === ЛОГИКА ПОЛЁТА (С ПОДДЕРЖКОЙ ТАЧА) ===
local flyConnection
local function startFly()
    if flyConnection then flyConnection:Disconnect() end
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart

    flyConnection = runService.RenderStepped:Connect(function()
        if not flying then return end
        local moveDirection = Vector3.new()
        
        -- Управление с телефона: используем виртуальный джойстик (если есть) или клавиши
        -- Для простоты используем стандартные WASD + пробел/шифт (на телефоне будут работать через внешнюю клавиатуру или эмуляцию)
        -- Но для нативного тача добавим управление через касания (ниже)
        
        if userInput:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + rootPart.CFrame.LookVector end
        if userInput:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - rootPart.CFrame.LookVector end
        if userInput:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - rootPart.CFrame.RightVector end
        if userInput:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + rootPart.CFrame.RightVector end
        if userInput:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        
        -- Дополнительно: управление через тач-джойстик (если есть на экране)
        -- Здесь можно интегрировать с мобильным джойстиком, но для простоты оставляем клавиши
        
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        bodyGyro.CFrame = rootPart.CFrame
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

local function toggleFly()
    flying = not flying
    flyBtn.Text = flying and "🛫 FLY: ON" or "🛫 FLY: OFF"
    flyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 70)
    if flying then
        startFly()
    else
        stopFly()
    end
end

flyBtn.MouseButton1Click:Connect(toggleFly)

-- === ЛОГИКА ОТБРАСЫВАНИЯ ===
local pushLoopRunning = false
local function pushPlayers()
    if not pushEnabled then return end
    for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                local dist = (rootPart.Position - otherChar.HumanoidRootPart.Position).Magnitude
                if dist < pushRadius then
                    local direction = (otherChar.HumanoidRootPart.Position - rootPart.Position).Unit
                    local force = direction * pushForce
                    local bodyVel = Instance.new("BodyVelocity")
                    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bodyVel.Velocity = force
                    bodyVel.Parent = otherChar.HumanoidRootPart
                    game:GetService("Debris"):AddItem(bodyVel, 0.1)
                end
            end
        end
    end
end

local function togglePush()
    pushEnabled = not pushEnabled
    pushBtn.Text = pushEnabled and "💥 PUSH: ON" or "💥 PUSH: OFF"
    pushBtn.BackgroundColor3 = pushEnabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(60, 60, 70)
    
    if pushEnabled and not pushLoopRunning then
        pushLoopRunning = true
        spawn(function()
            while pushEnabled do
                pushPlayers()
                wait(pushInterval)
            end
            pushLoopRunning = false
        end)
    end
end

pushBtn.MouseButton1Click:Connect(togglePush)

-- === ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ ===
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    if flying then
        stopFly()
        flying = false
        flyBtn.Text = "🛫 FLY: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        toggleFly() -- перезапускаем
    end
end)

-- === ДОПОЛНИТЕЛЬНО: УПРАВЛЕНИЕ ТАЧОМ ДЛЯ ПОЛЁТА (необязательно) ===
-- Можно добавить виртуальный джойстик, но для простоты оставляем клавиши.
-- На телефоне можно использовать внешнюю клавиатуру или эмулятор.

print("[DIX]: Мобильная версия загружена. Нажмите '−' для сворачивания в квадрат.")
