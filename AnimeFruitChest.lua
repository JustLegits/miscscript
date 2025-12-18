--[[
    Auto Chest Script v3 (Fixed)
    Logic: Detect -> TP -> Wait(TP Delay) -> Fire -> Wait(Next Delay) -> Repeat
]]
if not game:IsLoaded() then
    game.Loaded:Wait()
end

wait(math.random())

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURATION DEFAULTS //
local Config = {
    IsRunning = false,
    AutoHop = false,
    FireDelay = 0.5,   -- Time to wait AFTER TP before interacting
    TpDelay = 3.0  -- Time to wait AFTER interacting before next chest
}

local FileName = "AutoChestConfig.json"

-- // PRIORITY SYSTEM //
local PriorityList = {
    ["Christmas"] = 1,
    ["Chest4"] = 2,
    ["Chest3"] = 3,
    ["Chest2"] = 4,
    ["Chest1"] = 5
}

-- // GUI CREATION //
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local HopBtn = Instance.new("TextButton")
local SaveBtn = Instance.new("TextButton")

-- Delay 1 (TP Wait)
local FireDelayLabel = Instance.new("TextLabel") -- FIXED: Was "FireDelay"
local FireDelayInput = Instance.new("TextBox")

-- Delay 2 (Next Wait)
local TpDelayLabel = Instance.new("TextLabel") -- FIXED: Was "TpDelay"
local TpDelayInput = Instance.new("TextBox")

ScreenGui.Name = "AutoChestGUI"
ScreenGui.Parent = game:GetService("CoreGui") 

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 320)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Auto Chest v3"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18

-- Toggle Button
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.12, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 30)
ToggleBtn.Font = Enum.Font.SourceSans
ToggleBtn.Text = "Status: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 16

-- Auto Hop Button
HopBtn.Parent = MainFrame
HopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
HopBtn.Position = UDim2.new(0.1, 0, 0.24, 0)
HopBtn.Size = UDim2.new(0.8, 0, 0, 30)
HopBtn.Font = Enum.Font.SourceSans
HopBtn.Text = "Auto Hop: OFF"
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.TextSize = 16

-- Input 1: TP Delay
FireDelayLabel.Parent = MainFrame
FireDelayLabel.BackgroundTransparency = 1
FireDelayLabel.Position = UDim2.new(0.1, 0, 0.36, 0)
FireDelayLabel.Size = UDim2.new(0.8, 0, 0, 20)
FireDelayLabel.Font = Enum.Font.SourceSans
FireDelayLabel.Text = "Wait before Fire (sec):"
FireDelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FireDelayLabel.TextSize = 14

FireDelayInput.Parent = MainFrame
FireDelayInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FireDelayInput.Position = UDim2.new(0.1, 0, 0.44, 0)
FireDelayInput.Size = UDim2.new(0.8, 0, 0, 30)
FireDelayInput.Font = Enum.Font.SourceSans
FireDelayInput.Text = tostring(Config.FireDelay)
FireDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FireDelayInput.TextSize = 16

-- Input 2: Fire Delay (Next Chest)
TpDelayLabel.Parent = MainFrame
TpDelayLabel.BackgroundTransparency = 1
TpDelayLabel.Position = UDim2.new(0.1, 0, 0.56, 0)
TpDelayLabel.Size = UDim2.new(0.8, 0, 0, 20)
TpDelayLabel.Font = Enum.Font.SourceSans
TpDelayLabel.Text = "Wait before TP (sec):"
TpDelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TpDelayLabel.TextSize = 14

TpDelayInput.Parent = MainFrame
TpDelayInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TpDelayInput.Position = UDim2.new(0.1, 0, 0.64, 0)
TpDelayInput.Size = UDim2.new(0.8, 0, 0, 30)
TpDelayInput.Font = Enum.Font.SourceSans
TpDelayInput.Text = tostring(Config.TpDelay)
TpDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TpDelayInput.TextSize = 16

-- Save Button
SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
SaveBtn.Position = UDim2.new(0.1, 0, 0.85, 0)
SaveBtn.Size = UDim2.new(0.8, 0, 0, 30)
SaveBtn.Font = Enum.Font.SourceSans
SaveBtn.Text = "Save Config"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize = 16

-- // FUNCTIONS //

local function SaveConfig()
    Config.FireDelay = tonumber(FireDelayInput.Text) or 0.2
    Config.TpDelay = tonumber(TpDelayInput.Text) or 1.0
    
    local json = HttpService:JSONEncode(Config)
    writefile(FileName, json)
    SaveBtn.Text = "Saved!"
    task.wait(1)
    SaveBtn.Text = "Save Config"
end

local function LoadConfig()
    if isfile(FileName) then
        local content = readfile(FileName)
        local success, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if success then
            Config = decoded
            FireDelayInput.Text = tostring(Config.FireDelay or 0.2)
            TpDelayInput.Text = tostring(Config.TpDelay or 1.0)
            
            if Config.AutoHop then
                HopBtn.Text = "Auto Hop: ON"
                HopBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            end
        end
    end
end

local function ServerHop()
    Title.Text = "Hopping Server..."
    local PlaceId = game.PlaceId
    local Api = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
        local success, result = pcall(function()
            return game:HttpGet(Api .. (cursor and "&cursor="..cursor or ""))
        end)
        if success then return HttpService:JSONDecode(result) end
        return nil
    end

    local serverList = ListServers()
    if serverList and serverList.data then
        for _, server in ipairs(serverList.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                return
            end
        end
    end
    Title.Text = "Hop Failed, Retrying..."
    task.wait(3)
    ServerHop()
end

local function GetChestPriority(chestName)
    return PriorityList[chestName] or 999
end

local function GetSortedChests()
    local chests = {}
    local chestFolder = Workspace:FindFirstChild("Chest")
    
    if chestFolder then
        for _, model in pairs(chestFolder:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("ProximityPrompt", true) then
                table.insert(chests, model)
            end
        end
    end

    table.sort(chests, function(a, b)
        return GetChestPriority(a.Name) < GetChestPriority(b.Name)
    end)

    return chests
end

local function TeleportAndCollect()
    while Config.IsRunning do
        local availableChests = GetSortedChests()
        
        if #availableChests == 0 then
            Title.Text = "No Chests Found"
            if Config.AutoHop then
                ServerHop()
                break
            end
            task.wait(2)
        else
            for _, chest in ipairs(availableChests) do
                if not Config.IsRunning then break end
                
                if chest and chest.Parent then
                    local prompt = chest:FindFirstChild("ProximityPrompt", true)
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if root and prompt then
                        Title.Text = "Taking: " .. chest.Name
                        
                        -- 1. TELEPORT
                        if chest.PrimaryPart then
                            root.CFrame = chest.PrimaryPart.CFrame
                        else
                            root.CFrame = chest:GetModelCFrame()
                        end
                        
                        -- 2. WAIT AFTER TP
                        local tpWait = tonumber(FireDelayInput.Text) or 0.2
                        if tpWait > 0 then task.wait(tpWait) end
                        
                        -- 3. FIRE PROMPT
                        fireproximityprompt(prompt)
                        
                        -- 4. WAIT BEFORE NEXT
                        local fireWait = tonumber(TpDelayInput.Text) or 1.0
                        if fireWait > 0 then task.wait(fireWait) end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end

-- // EVENT LISTENERS //

ToggleBtn.MouseButton1Click:Connect(function()
    Config.IsRunning = not Config.IsRunning
    if Config.IsRunning then
        ToggleBtn.Text = "Status: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        task.spawn(TeleportAndCollect)
    else
        ToggleBtn.Text = "Status: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Title.Text = "Auto Chest v3"
    end
end)

HopBtn.MouseButton1Click:Connect(function()
    Config.AutoHop = not Config.AutoHop
    if Config.AutoHop then
        HopBtn.Text = "Auto Hop: ON"
        HopBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        HopBtn.Text = "Auto Hop: OFF"
        HopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

SaveBtn.MouseButton1Click:Connect(SaveConfig)

-- // ANTI-AFK //
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Initialize
LoadConfig()
