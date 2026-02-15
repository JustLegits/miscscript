if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- // 1. REMOTE SETUP //
local Remote = nil
pcall(function()
    Remote = ReplicatedStorage:WaitForChild("API", 5):WaitForChild("Utils", 5):WaitForChild("network", 5):WaitForChild("RemoteEvent", 5)
end)

if not Remote then warn("[CRITICAL] RemoteEvent not found!") end

-- // 2. CONFIGURATION & LOAD //
local FileName = "AnimeStoryInfinite.json"
local Config = {
    Map = "Demon City", 
    RestartWave = 10,
    AutoLoop = true, -- New: Saves the Toggle State
    IsRestarting = false
}

if isfile(FileName) then
    pcall(function()
        local loaded = HttpService:JSONDecode(readfile(FileName))
        if loaded then
            Config.Map = loaded.Map or Config.Map
            Config.RestartWave = tonumber(loaded.RestartWave) or 25
            if loaded.AutoLoop ~= nil then Config.AutoLoop = loaded.AutoLoop end
        end
    end)
end

-- // 3. GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ASInfinite"
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -110)
MainFrame.Size = UDim2.new(0, 250, 0, 220)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Title
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 5)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.GothamBold
Title.Text = "AS INFINITE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

-- Map Input
local MapBox = Instance.new("TextBox")
MapBox.Parent = MainFrame
MapBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MapBox.Position = UDim2.new(0.1, 0, 0.16, 0)
MapBox.Size = UDim2.new(0.8, 0, 0, 30)
MapBox.Font = Enum.Font.Gotham
MapBox.PlaceholderText = "Map Name"
MapBox.Text = Config.Map
MapBox.TextColor3 = Color3.fromRGB(230, 230, 230)
MapBox.TextSize = 14
Instance.new("UICorner", MapBox).CornerRadius = UDim.new(0, 6)

-- Wave Input
local WaveBox = Instance.new("TextBox")
WaveBox.Parent = MainFrame
WaveBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WaveBox.Position = UDim2.new(0.1, 0, 0.32, 0)
WaveBox.Size = UDim2.new(0.8, 0, 0, 30)
WaveBox.Font = Enum.Font.Gotham
WaveBox.PlaceholderText = "Restart at Wave"
WaveBox.Text = tostring(Config.RestartWave)
WaveBox.TextColor3 = Color3.fromRGB(230, 230, 230)
WaveBox.TextSize = 14
Instance.new("UICorner", WaveBox).CornerRadius = UDim.new(0, 6)

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.90, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 11

-- // BUTTONS //

-- 1. SETUP COMBO BUTTON
local SetupBtn = Instance.new("TextButton")
SetupBtn.Parent = MainFrame
SetupBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SetupBtn.Position = UDim2.new(0.1, 0, 0.48, 0)
SetupBtn.Size = UDim2.new(0.8, 0, 0, 35)
SetupBtn.Font = Enum.Font.GothamBold
SetupBtn.Text = "AUTO START"
SetupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetupBtn.TextSize = 12
Instance.new("UICorner", SetupBtn).CornerRadius = UDim.new(0, 6)

-- 2. SAVE CONFIG BUTTON
local SaveBtn = Instance.new("TextButton")
SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SaveBtn.Position = UDim2.new(0.1, 0, 0.66, 0)
SaveBtn.Size = UDim2.new(0.38, 0, 0, 30)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize = 12
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

-- 3. LOOP TOGGLE BUTTON
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = MainFrame
ToggleBtn.Position = UDim2.new(0.52, 0, 0.66, 0)
ToggleBtn.Size = UDim2.new(0.38, 0, 0, 30)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- Apply Initial State from Config
if Config.AutoLoop then
    ToggleBtn.Text = "LOOP: ON"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
else
    ToggleBtn.Text = "LOOP: OFF"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
end

-- // FUNCTION LOGIC //

-- JOIN -> CREATE -> START
SetupBtn.MouseButton1Click:Connect(function()
    local lp = Players.LocalPlayer
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    
    local infinite = Workspace:FindFirstChild("Rooms") and Workspace.Rooms:FindFirstChild("infinite")
    local roomNode = infinite and infinite:GetChildren()[4]
    
    if root and roomNode and roomNode:FindFirstChild("Touch") then
        StatusLabel.Text = "1/3 Joining..."
        firetouchinterest(root, roomNode.Touch, 0)
        task.wait()
        firetouchinterest(root, roomNode.Touch, 1)
    else
        StatusLabel.Text = "Error: Room Missing"
        return
    end

    task.wait(0.5)

    if Remote then
        StatusLabel.Text = "2/3 Creating: " .. MapBox.Text
        Remote:FireServer("room_select", MapBox.Text, 1)
    end

    task.wait(1)

    if Remote then
        StatusLabel.Text = "3/3 Starting..."
        Remote:FireServer("room_start")
        task.wait(0.5)
        StatusLabel.Text = "Done!"
    end
end)

-- SAVE LOGIC (Includes Loop State)
SaveBtn.MouseButton1Click:Connect(function()
    Config.Map = MapBox.Text
    Config.RestartWave = tonumber(WaveBox.Text) or 25
    -- Config.AutoLoop is already updated by the Toggle Button logic
    
    pcall(function() writefile(FileName, HttpService:JSONEncode(Config)) end)
    StatusLabel.Text = "Config Saved!"
    task.delay(1, function() StatusLabel.Text = "Idle" end)
end)

-- TOGGLE LOGIC
ToggleBtn.MouseButton1Click:Connect(function()
    Config.AutoLoop = not Config.AutoLoop -- Flip Bool
    
    if Config.AutoLoop then
        ToggleBtn.Text = "LOOP: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
    else
        ToggleBtn.Text = "LOOP: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

-- // MAIN LOOP (Uses Config.AutoLoop) //
task.spawn(function()
    while task.wait(1) do
        if not Config.AutoLoop or Config.IsRestarting then continue end

        local battleGui = Players.LocalPlayer.PlayerGui:FindFirstChild("battle")
        if not battleGui then continue end

        -- 1. Result Screen Check
        local resultScreen = battleGui:FindFirstChild("Result")
        if resultScreen and resultScreen:GetAttribute("Open") == true then
            print("--- Result Detected. Replaying... ---")
            Config.IsRestarting = true
            Remote:FireServer("battle_replay")
            task.wait(2)
            Config.IsRestarting = false
            continue
        end

        -- 2. Wave Check
        local hud = battleGui:FindFirstChild("Hud")
        local side = hud and hud:FindFirstChild("Side")
        local stageLabel = side and side:FindFirstChild("Stage")

        if stageLabel then
            local currentWave = tonumber(string.match(stageLabel.Text, "%d+$"))
            local target = tonumber(WaveBox.Text) or 25

            if currentWave and currentWave >= target then
                print("--- Target Wave Reached. Restarting... ---")
                Config.IsRestarting = true
                
                Remote:FireServer("battle_end")
                task.wait(0.5)
                Remote:FireServer("battle_replay")
                
                task.wait(3)
                Config.IsRestarting = false
            end
        end
    end
end)
