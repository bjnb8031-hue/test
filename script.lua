-- Создаем ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileActiveMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Переменные состояний
local isMinimized = false
local flyActive = false
local pushActive = false

-- Главный фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 200)
MainFrame.Position = UDim2.new(0.5, -130, 0.3, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Перетаскивание пальцем
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -40, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DIX MENU"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Контейнер для кнопок
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -20, 1, -45)
Container.Position = UDim2.new(0, 10, 0, 35)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Container

-- Стили для кнопок функций
local function styleButton(btn, text)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.SourceSansBold
    btn.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
end

-- ==========================================
-- ЛОГИКА ФУНКЦИИ: ПОЛЕТ (FLY)
-- ==========================================
local FlyBtn = Instance.new("TextButton")
styleButton(FlyBtn, "Полет: ВЫКЛ")
FlyBtn.Parent = Container

local bodyVelocity, bodyGyro
task.spawn(function()
    while task.wait() do
        if flyActive and Character and HumanoidRootPart and Character:FindFirstChild("Humanoid") then
            if not bodyVelocity then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bodyVelocity.Parent = HumanoidRootPart
                
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                bodyGyro.CFrame = HumanoidRootPart.CFrame
                bodyGyro.Parent = HumanoidRootPart
            end
            -- На мобильном персонаж летит туда, куда направлена камера (взгляд)
            local camera = workspace.CurrentCamera
            bodyVelocity.Velocity = camera.CFrame.LookVector * 50 -- 50 — скорость полета
            bodyGyro.CFrame = camera.CFrame
        else
            if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        end
    end
end)

FlyBtn.MouseButton1Click:Connect(function()
    flyActive = not flyActive
    if flyActive then
        FlyBtn.Text = "Полет: ВКЛ"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87) -- Зеленый
    else
        FlyBtn.Text = "Полет: ВЫКЛ"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)  -- Обычный
    end
end)

-- ==========================================
-- ЛОГИКА ФУНКЦИИ: ОТБРАСЫВАТЬ ЛЮДЕЙ (PUSH)
-- ==========================================
local PushBtn = Instance.new("TextButton")
styleButton(PushBtn, "Отбрасывание: ВЫКЛ")
PushBtn.Parent = Container

task.spawn(function()
    while task.wait(0.1) do -- Проверка каждые 0.1 сек для экономии заряда батареи
        if pushActive and HumanoidRootPart then
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = p.Character.HumanoidRootPart
                    -- Вычисляем дистанцию до другого игрока
                    local distance = (HumanoidRootPart.Position - targetHRP.Position).Magnitude
                    if distance < 12 then -- Расстояние срабатывания (12 шпилек/студов)
                        -- Направление импульса от нас к цели
                        local direction = (targetHRP.Position - HumanoidRootPart.Position).Unit
                        
                        -- Создаем мощный толчок
                        local velocity = Instance.new("BodyVelocity")
                        velocity.MaxForce = Vector3.new(5e5, 5e5, 5e5)
                        velocity.Velocity = (direction * 80) + Vector3.new(0, 35, 0) -- 80 сила вдаль, 35 вверх
                        velocity.Parent = targetHRP
                        
                        task.wait(0.1)
                        velocity:Destroy()
                    end
                end
            end
        end
    end
end)

PushBtn.MouseButton1Click:Connect(function()
    pushActive = not pushActive
    if pushActive then
        PushBtn.Text = "Отбрасывание: ВКЛ"
        PushBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
    else
        PushBtn.Text = "Отбрасывание: ВЫКЛ"
        PushBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end
end)

-- ==========================================
-- КНОПКА СВЕРНУТЬ / РАЗВЕРНУТЬ (ТРИГГЕР)
-- ==========================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
ToggleBtn.Position = UDim2.new(1, -35, 0, 5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "−"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 20
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    if not isMinimized then
        isMinimized = true
        Title.Visible = false
        Container.Visible = false
        MainFrame.Size = UDim2.new(0, 40, 0, 40)
        ToggleBtn.Position = UDim2.new(0, 5, 0, 5)
        ToggleBtn.Text = "+"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        isMinimized = false
        MainFrame.Size = UDim2.new(0, 260, 0, 200)
        ToggleBtn.Position = UDim2.new(1, -35, 0, 5)
        ToggleBtn.Text = "−"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Title.Visible = true
        Container.Visible = true
    end
end)
