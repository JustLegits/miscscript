local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
local SettingLagGUI = Instance.new("ScreenGui")
SettingLagGUI.Name = "SettingLag"
SettingLagGUI.ResetOnSpawn = false
SettingLagGUI.Parent = playerGui
local SettingFrame = Instance.new("Frame")
SettingFrame.Parent = SettingLagGUI
SettingFrame.Size = UDim2.new(0, 200, 0, 180)
SettingFrame.Position = UDim2.new(0.5, -100, 0.5, -90)
SettingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingFrame.BorderSizePixel = 0
SettingFrame.Active = false
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = SettingFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.Text = "Setting Lag"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.BackgroundTransparency = 1
local WaitTimeBox = Instance.new("TextBox")
WaitTimeBox.Parent = SettingFrame
WaitTimeBox.Size = UDim2.new(0.8, 0, 0, 30)
WaitTimeBox.Position = UDim2.new(0.1, 0, 0.3, 0)
WaitTimeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WaitTimeBox.Text = "Wait Time (Default: 0.05)"
WaitTimeBox.TextColor3 = Color3.new(1, 1, 1)
WaitTimeBox.Font = Enum.Font.SourceSans
WaitTimeBox.TextSize = 14
WaitTimeBox.BorderSizePixel = 0
WaitTimeBox.ClearTextOnFocus = true
local DelayTimeBox = Instance.new("TextBox")
DelayTimeBox.Parent = SettingFrame
DelayTimeBox.Size = UDim2.new(0.8, 0, 0, 30)
DelayTimeBox.Position = UDim2.new(0.1, 0, 0.55, 0)
DelayTimeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayTimeBox.Text = "Delay Time (Default: 0.5)"
DelayTimeBox.TextColor3 = Color3.new(1, 1, 1)
DelayTimeBox.Font = Enum.Font.SourceSans
DelayTimeBox.TextSize = 14
DelayTimeBox.BorderSizePixel = 0
DelayTimeBox.ClearTextOnFocus = true
local ToggleGUI = Instance.new("ScreenGui")
ToggleGUI.Name = "ToggleGUI"
ToggleGUI.ResetOnSpawn = false
ToggleGUI.Parent = playerGui
local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ToggleGUI
ToggleButton.Size = UDim2.new(0, 80, 0, 35)
ToggleButton.Position = UDim2.new(1, -90, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.Text = "Setting"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 16
ToggleButton.BorderSizePixel = 0
ToggleButton.AutoButtonColor = false
ToggleButton.MouseButton1Click:Connect(function()
    SettingLagGUI.Enabled = not SettingLagGUI.Enabled
end)
local ActionGUI = Instance.new("ScreenGui")
ActionGUI.Name = "ActionGUI"
ActionGUI.ResetOnSpawn = false
ActionGUI.Parent = playerGui
local FallingButton = Instance.new("TextButton")
FallingButton.Parent = ActionGUI
FallingButton.Size = UDim2.new(0, 100, 0, 40)
FallingButton.Position = UDim2.new(0.8, 0, 0.83, 0)
FallingButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FallingButton.Text = "Falling: OFF"
FallingButton.TextColor3 = Color3.new(1, 1, 1)
FallingButton.Font = Enum.Font.SourceSans
FallingButton.TextSize = 16
FallingButton.BorderSizePixel = 0
FallingButton.Active = true
FallingButton.Draggable = true
local FakeLagButton = Instance.new("TextButton")
FakeLagButton.Parent = ActionGUI
FakeLagButton.Size = UDim2.new(0, 100, 0, 40)
FakeLagButton.Position = UDim2.new(0.8, 0, 0.9, 0)
FakeLagButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FakeLagButton.Text = "FakeLag: OFF"
FakeLagButton.TextColor3 = Color3.new(1, 1, 1)
FakeLagButton.Font = Enum.Font.SourceSans
FakeLagButton.TextSize = 16
FakeLagButton.BorderSizePixel = 0
FakeLagButton.Active = true
FakeLagButton.Draggable = true

local isFalling = false
local isFakeLag = false

FallingButton.MouseButton1Click:Connect(function()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            isFalling = not isFalling
            humanoid.PlatformStand = isFalling
            FallingButton.Text = isFalling and "Falling: ON" or "Falling: OFF"

            if isFalling then
                humanoid:Move(Vector3.new(0, -50, 0))
            end
        end
    end
end)

FakeLagButton.MouseButton1Click:Connect(function()
    isFakeLag = not isFakeLag
    FakeLagButton.Text = isFakeLag and "FakeLag: ON" or "FakeLag: OFF"
end)

coroutine.wrap(function()
    while task.wait(0.05) do
        if isFakeLag then
            local character = player.Character
            local waitTime = tonumber(WaitTimeBox.Text) or 0.05
            local delayTime = tonumber(DelayTimeBox.Text) or 0.5

            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.Anchored = true
                task.wait(delayTime)
                character.HumanoidRootPart.Anchored = false
            end
        end
    end
end)()
