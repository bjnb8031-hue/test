-- DIX FLIGHT + PUSH HUD v2.0
-- Полёт + репульсивное поле с управлением через интерфейс

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Настройки
local flySpeed = 70
local pushForce = 5000
local pushRadius = 8
local pushInterval = 0.15

-- Состояния
local flying = false
local pushEnabled = false
local bodyVelocity = nil
local bodyGyro = nil

-- Создание HUD
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DIX_HUD"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Фоновое окно
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 110)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "DIX CONTROL"
title.TextColor3 = Color3.fromRGB(255, 0, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Кнопка полёта
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0, 80, 0, 35)
flyBtn.Position = UDim2.new(0, 10, 0, 40)
flyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
flyBtn.Text = "FLY: OFF"
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Parent = frame

-- Кнопка отбрасывания
local pushBtn = Instance.new("TextButton")
pushBtn.Size = UDim2.new(0, 80, 0, 35)
pushBtn.Position = UDim2.new(0, 110, 0, 40)
pushBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
pushBtn.Text = "PUSH: OFF"
pushBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pushBtn.TextScaled = true
pushBtn.Font = Enum.Font.GothamBold
pushBtn.Parent = frame

-- Логика полёта
local function toggleFly()
    flying = not flying
    flyBtn.Text = flying and "FLY: ON" or "FLY: OFF"
    flyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)

    if flying then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bodyGyro.CFrame = rootPart.CFrame
        bodyGyro.Parent = rootPart

        game:GetService("RunService").RenderStepped:Connect(function()
            if not flying then return end
            local moveDirection = Vector3.new()
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + rootPart.CFrame.LookVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - rootPart.CFrame.LookVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - rootPart.CFrame.RightVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + rootPart.CFrame.RightVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
            if moveDirection.Magnitude > 0 then
                bodyVelocity.Velocity = moveDirection.Unit * flySpeed
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            bodyGyro.CFrame = rootPart.CFrame
        end)
    else
        if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    end
end

-- Логика отбрасывания (пульс)
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
    pushBtn.Text = pushEnabled and "PUSH: ON" or "PUSH: OFF"
    pushBtn.BackgroundColor3 = pushEnabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(60, 60, 60)

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

-- Назначение кнопок
flyBtn.MouseButton1Click:Connect(toggleFly)
pushBtn.MouseButton1Click:Connect(togglePush)

-- Обновление при респавне
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if flying then
        -- пересоздаём полёт
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        flying = false
        toggleFly()
    end
end)

print("[DIX]: HUD загружен. Кнопки на экране — FLY и PUSH. Перетаскиваемые.")