local CHAMS_TRANSPARENCY = 0

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local espState = true
local chamsState = true

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ViewportXRay"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Viewport = Instance.new("ViewportFrame")
Viewport.Size = UDim2.new(1, 0, 1, 0)
Viewport.BackgroundTransparency = 1
Viewport.CurrentCamera = Camera
Viewport.Parent = ScreenGui

local activeChams = {}

-- Функция для определения VR-рук
local function isVRHand(part)
    if not part:IsA("BasePart") then return false end
    
    if part.Material == Enum.Material.Neon then
        return true
    end
    
    local color = part.Color
    if color.G > 0.7 and color.R < 0.3 and color.B < 0.3 then
        return true
    end
    
    local name = part.Name
    if name == "RightHand" or name == "LeftHand" or 
       name == "RightUpperArm" or name == "LeftUpperArm" or
       name == "RightLowerArm" or name == "LeftLowerArm" or
       name == "Skull" or name == "Head" then
        return true
    end
    
    if string.find(name, "VR") or string.find(name, "Hand") or 
       string.find(name, "Controller") or string.find(name, "Skull") then
        return true
    end
    
    return false
end

-- Функция для очистки VR-рук в клоне
local function fixVRHands(model)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            if isVRHand(obj) then
                obj.Transparency = 1
            end
        end
    end
end

-- Функция для копирования аксессуаров
local function copyAccessories(originalChar, cloneChar)
    local originalHead = originalChar:FindFirstChild("Head")
    local cloneHead = cloneChar:FindFirstChild("Head")
    if not originalHead or not cloneHead then return end
    
    -- Удаляем старые аксессуары из клона
    for _, child in ipairs(cloneHead:GetChildren()) do
        if child:IsA("Accessory") then
            child:Destroy()
        end
    end
    
    -- Копируем все аксессуары из оригинала
    for _, accessory in ipairs(originalHead:GetChildren()) do
        if accessory:IsA("Accessory") then
            local cloneAccessory = accessory:Clone()
            cloneAccessory.Parent = cloneHead
            
            local cloneHandle = cloneAccessory:FindFirstChild("Handle")
            if cloneHandle and cloneHandle:IsA("BasePart") then
                cloneHandle.Transparency = CHAMS_TRANSPARENCY
                cloneHandle.CanCollide = false
                cloneHandle.Anchored = true
            end
        end
    end
end

local function applyNameESP(player, char)
    local head = char:WaitForChild("Head", 15)
    if not head then return end

    local oldGui = head:FindFirstChild("NameESP")
    if oldGui then oldGui:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameESP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = espState
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 18
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard
end

local function applyPlayerFeatures(player)
    if player == LocalPlayer then return end

    local function onCharacterAdded(char)
        task.spawn(function()
            applyNameESP(player, char)
        end)

        char:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.5)
        if not char.Parent then return end

        if activeChams[player] then
            if activeChams[player].Connection then activeChams[player].Connection:Disconnect() end
            if activeChams[player].Conn1 then activeChams[player].Conn1:Disconnect() end
            if activeChams[player].Conn2 then activeChams[player].Conn2:Disconnect() end
            if activeChams[player].Model then activeChams[player].Model:Destroy() end
            activeChams[player] = nil
        end

        char.Archivable = true
        local cloneModel = char:Clone()
        char.Archivable = false

        -- Удаляем ненужные объекты
        for _, obj in ipairs(cloneModel:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Sound") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.CanCollide = false
                obj.Anchored = true
                if obj.Name ~= "HumanoidRootPart" then
                    obj.Transparency = CHAMS_TRANSPARENCY
                else
                    obj.Transparency = 1
                end
            end
        end

        -- Удаляем аксессуары из клона
        for _, obj in ipairs(cloneModel:GetChildren()) do
            if obj:IsA("Accessory") then
                obj:Destroy()
            end
        end

        fixVRHands(cloneModel)
        cloneModel.Parent = Viewport
        
        task.wait(0.1)
        copyAccessories(char, cloneModel)

        local childConn1
        local childConn2
        local renderConn

        childConn1 = char.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if not char.Parent or not cloneModel then return end

            if child:IsA("Accessory") then
                copyAccessories(char, cloneModel)
                return
            end

            -- Полное обновление клона
            cloneModel:Destroy()
            char.Archivable = true
            cloneModel = char:Clone()
            char.Archivable = false

            for _, obj in ipairs(cloneModel:GetDescendants()) do
                if obj:IsA("LuaSourceContainer") or obj:IsA("Sound") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CanCollide = false
                    obj.Anchored = true
                    if obj.Name ~= "HumanoidRootPart" then
                        obj.Transparency = CHAMS_TRANSPARENCY
                    else
                        obj.Transparency = 1
                    end
                end
            end
            
            for _, obj in ipairs(cloneModel:GetChildren()) do
                if obj:IsA("Accessory") then
                    obj:Destroy()
                end
            end
            
            fixVRHands(cloneModel)
            cloneModel.Parent = Viewport
            task.wait(0.1)
            copyAccessories(char, cloneModel)
        end)

        childConn2 = char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") or child:IsA("Accoutrement") or child:IsA("Accessory") then
                task.wait(0.1)
                if cloneModel then
                    for _, obj in ipairs(cloneModel:GetDescendants()) do
                        if obj.Name == child.Name and obj:IsA("Accessory") then
                            obj:Destroy()
                            break
                        end
                    end
                end
            end
        end)

        -- ГЛАВНОЕ ИЗМЕНЕНИЕ: Обновление по имени каждый кадр
        renderConn = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not cloneModel or not cloneModel.Parent then
                if renderConn then renderConn:Disconnect() end
                if childConn1 then childConn1:Disconnect() end
                if childConn2 then childConn2:Disconnect() end
                if cloneModel then cloneModel:Destroy() end
                activeChams[player] = nil
                return
            end

            -- Обновляем ВСЕ BasePart в клоне по имени из оригинала
            for _, clonePart in ipairs(cloneModel:GetDescendants()) do
                if clonePart:IsA("BasePart") then
                    -- Ищем оригинальную часть с таким же путем/именем
                    local origPart
                    
                    -- Сначала пробуем найти по полному пути
                    local fullPath = clonePart:GetFullName():sub(#cloneModel:GetFullName() + 2)
                    if fullPath ~= "" then
                        origPart = char:FindFirstChild(fullPath, true)
                    end
                    
                    -- Если не нашли, пробуем найти по имени (для аксессуаров)
                    if not origPart then
                        -- Проверяем, является ли часть аксессуаром
                        local parent = clonePart.Parent
                        local isAccessory = false
                        while parent do
                            if parent:IsA("Accessory") then
                                isAccessory = true
                                break
                            end
                            parent = parent.Parent
                        end
                        
                        if isAccessory then
                            -- Для аксессуаров ищем Handle в голове
                            local cloneHead = cloneModel:FindFirstChild("Head")
                            local origHead = char:FindFirstChild("Head")
                            if cloneHead and origHead then
                                -- Ищем аксессуар с таким же именем
                                for _, cloneAccessory in ipairs(cloneHead:GetChildren()) do
                                    if cloneAccessory:IsA("Accessory") and cloneAccessory.Name == clonePart.Parent.Name then
                                        local origAccessory = origHead:FindFirstChild(cloneAccessory.Name)
                                        if origAccessory then
                                            local origHandle = origAccessory:FindFirstChild("Handle")
                                            if origHandle and origHandle:IsA("BasePart") then
                                                origPart = origHandle
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        else
                            -- Обычная часть - ищем по имени
                            origPart = char:FindFirstChild(clonePart.Name, true)
                        end
                    end
                    
                    -- Если нашли оригинал - копируем CFrame
                    if origPart and origPart:IsA("BasePart") and origPart.Parent then
                        clonePart.CFrame = origPart.CFrame
                    end
                end
            end
        end)

        activeChams[player] = {
            Model = cloneModel,
            Connection = renderConn,
            Conn1 = childConn1,
            Conn2 = childConn2
        }
    end

    if player.Character then
        task.spawn(onCharacterAdded, player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in ipairs(Players:GetPlayers()) do
    applyPlayerFeatures(player)
end

Players.PlayerAdded:Connect(applyPlayerFeatures)

Players.PlayerRemoving:Connect(function(player)
    if activeChams[player] then
        if activeChams[player].Connection then activeChams[player].Connection:Disconnect() end
        if activeChams[player].Conn1 then activeChams[player].Conn1:Disconnect() end
        if activeChams[player].Conn2 then activeChams[player].Conn2:Disconnect() end
        if activeChams[player].Model then activeChams[player].Model:Destroy() end
        activeChams[player] = nil
    end
end)

-- GUI код (без изменений)
local MenuGui = Instance.new("ScreenGui")
MenuGui.Name = "ChamsMenuGui"
MenuGui.ResetOnSpawn = false
MenuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 230)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -115)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = MenuGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Chams & Visuals Settings"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local ToggleChamsBtn = Instance.new("TextButton")
ToggleChamsBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleChamsBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
ToggleChamsBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
ToggleChamsBtn.Text = "Viewport Chams: ON"
ToggleChamsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleChamsBtn.Font = Enum.Font.SourceSansBold
ToggleChamsBtn.TextSize = 14
ToggleChamsBtn.Parent = MainFrame

local btnCorner1 = Instance.new("UICorner")
btnCorner1.CornerRadius = UDim.new(0, 6)
btnCorner1.Parent = ToggleChamsBtn

local ToggleESPBtn = Instance.new("TextButton")
ToggleESPBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleESPBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleESPBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
ToggleESPBtn.Text = "Name ESP: ON"
ToggleESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleESPBtn.Font = Enum.Font.SourceSansBold
ToggleESPBtn.TextSize = 14
ToggleESPBtn.Parent = MainFrame

local btnCorner2 = Instance.new("UICorner")
btnCorner2.CornerRadius = UDim.new(0, 6)
btnCorner2.Parent = ToggleESPBtn

local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Size = UDim2.new(0.9, 0, 0, 35)
KeybindBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
KeybindBtn.Text = "Toggle Menu Key: [RightShift]"
KeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
KeybindBtn.Font = Enum.Font.SourceSans
KeybindBtn.TextSize = 13
KeybindBtn.Parent = MainFrame

local btnCorner3 = Instance.new("UICorner")
btnCorner3.CornerRadius = UDim.new(0, 6)
btnCorner3.Parent = KeybindBtn

local SubText = Instance.new("TextLabel")
SubText.Size = UDim2.new(1, 0, 0, 25)
SubText.Position = UDim2.new(0, 0, 0.82, 0)
SubText.BackgroundTransparency = 1
SubText.Text = "Click button to rebind key"
SubText.TextColor3 = Color3.fromRGB(150, 150, 150)
SubText.TextSize = 12
SubText.Font = Enum.Font.SourceSansItalic
SubText.Parent = MainFrame

ToggleChamsBtn.MouseButton1Click:Connect(function()
    chamsState = not chamsState
    Viewport.Visible = chamsState
    ToggleChamsBtn.Text = chamsState and "Viewport Chams: ON" or "Viewport Chams: OFF"
    ToggleChamsBtn.BackgroundColor3 = chamsState and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(160, 40, 40)
end)

ToggleESPBtn.MouseButton1Click:Connect(function()
    espState = not espState
    ToggleESPBtn.Text = espState and "Name ESP: ON" or "Name ESP: OFF"
    ToggleESPBtn.BackgroundColor3 = espState and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(160, 40, 40)

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local esp = p.Character.Head:FindFirstChild("NameESP")
            if esp then
                esp.Enabled = espState
            end
        end
    end
end)

local currentToggleKey = Enum.KeyCode.RightShift
local isBinding = false

KeybindBtn.MouseButton1Click:Connect(function()
    isBinding = true
    KeybindBtn.Text = "Press any key..."
    KeybindBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 40)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
        currentToggleKey = input.KeyCode
        isBinding = false
        KeybindBtn.Text = "Toggle Menu Key: [" .. input.KeyCode.Name .. "]"
        KeybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        return
    end

    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == currentToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end)
