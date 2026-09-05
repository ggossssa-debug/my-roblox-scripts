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
Viewport.LightColor = Color3.fromRGB(255, 255, 255)
Viewport.LightDirection = Vector3.new(-1, -1, -1)
Viewport.Ambient = Color3.fromRGB(200, 200, 200)
Viewport.Parent = ScreenGui

local activeChams = {}

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
    if string.find(name, "VR") or string.find(name, "Controller") then
        return true
    end
    
    return false
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
            if activeChams[player].Model then activeChams[player].Model:Destroy() end
            activeChams[player] = nil
        end

        local cloneModel = Instance.new("Model")
        cloneModel.Name = player.Name .. "_Cham"

        local fakeHumanoid = Instance.new("Humanoid")
        fakeHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        fakeHumanoid.Parent = cloneModel

        local partPairs = {}

        -- Глубокий обход всех вложенных объектов для полного захвата аксессуаров VR
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                if isVRHand(obj) or obj.Name == "HumanoidRootPart" then
                    -- Игнорируем руки VR и служебный HumanoidRootPart
                else
                    local clonePart = obj:Clone()
                    
                    for _, child in ipairs(clonePart:GetDescendants()) do
                        if child:IsA("JointInstance") or child:IsA("Script") or child:IsA("LocalScript") then
                            child:Destroy()
                        end
                    end

                    clonePart.CanCollide = false
                    clonePart.Anchored = true
                    clonePart.CastShadow = false

                    -- Принудительно показываем аксессуары, даже если скрипты игры скрывают оригинал
                    if obj.Parent:IsA("Accessory") then
                        clonePart.Transparency = CHAMS_TRANSPARENCY
                    else
                        clonePart.Transparency = obj.Transparency > CHAMS_TRANSPARENCY and obj.Transparency or CHAMS_TRANSPARENCY
                    end

                    clonePart.Parent = cloneModel
                    table.insert(partPairs, {Orig = obj, Clone = clonePart})
                end
            elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("CharacterMesh") or obj:IsA("BodyColors") or obj:IsA("ShirtGraphic") then
                obj:Clone().Parent = cloneModel
            end
        end

        cloneModel.Parent = Viewport

        local renderConn = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not cloneModel or not cloneModel.Parent then
                if renderConn then renderConn:Disconnect() end
                if cloneModel then cloneModel:Destroy() end
                activeChams[player] = nil
                return
            end

            for _, pair in ipairs(partPairs) do
                if pair.Orig and pair.Orig.Parent and pair.Clone and pair.Clone.Parent then
                    pair.Clone.CFrame = pair.Orig.CFrame
                end
            end
        end)

        activeChams[player] = {
            Model = cloneModel,
            Connection = renderConn
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
        if activeChams[player].Model then activeChams[player].Model:Destroy() end
        activeChams[player] = nil
    end
end)

-- GUI
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
