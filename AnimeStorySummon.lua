-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local SelectedBanner = "Standard" 
local SelectedAmount = 10
local SelectedDelay = 0.2 
local AutoSummonActive = false

-- Remote Event Check
local RemotePath = ReplicatedStorage:WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")

-- Function to Fire Remote
local function PerformSummon()
    if RemotePath then
        local args = {
            "summon_roll",
            SelectedBanner,
            SelectedAmount
        }
        RemotePath:FireServer(unpack(args))
        print("Summoned on: " .. SelectedBanner .. " | Amount: " .. tostring(SelectedAmount))
    end
end

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local Container = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

-- Setup Main GUI
ScreenGui.Name = "SummonUI_Final"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -100)
-- Exact height calculation to remove empty space: 
-- Title(30) + Pad(5) + Drop1(32) + Pad(5) + Drop2(32) + Pad(5) + Delay(32) + Pad(5) + Button(35) + Pad(5) = ~190
MainFrame.Size = UDim2.new(0, 240, 0, 195) 
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "Anime Story Summon"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14.000

Container.Name = "Container"
Container.Parent = MainFrame
Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Container.BackgroundTransparency = 1.000
Container.Position = UDim2.new(0, 10, 0, 35)
Container.Size = UDim2.new(1, -20, 1, -40)

UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5) -- Very tight spacing

-- --- HELPER: Create Dropdown ---
local function CreateDropdown(name, options, defaultChoice, callback)
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = name .. "Dropdown"
    DropdownFrame.Parent = Container
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    DropdownFrame.Size = UDim2.new(1, 0, 0, 32)
    DropdownFrame.ClipsDescendants = true
    DropdownFrame.ZIndex = 5 -- High ZIndex to sit on top
    
    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 4)
    DropCorner.Parent = DropdownFrame

    -- Clickable Header Area
    local HeaderBtn = Instance.new("TextButton")
    HeaderBtn.Parent = DropdownFrame
    HeaderBtn.Size = UDim2.new(1, 0, 0, 32)
    HeaderBtn.BackgroundTransparency = 1
    HeaderBtn.Text = "" -- No text on button, using Label instead
    HeaderBtn.ZIndex = 6

    -- Explicit Text Label (Fixes invisible text issue)
    local HeaderLabel = Instance.new("TextLabel")
    HeaderLabel.Parent = HeaderBtn
    HeaderLabel.BackgroundTransparency = 1
    HeaderLabel.Size = UDim2.new(1, -30, 1, 0)
    HeaderLabel.Position = UDim2.new(0, 10, 0, 0)
    HeaderLabel.Font = Enum.Font.GothamBold
    HeaderLabel.Text = name .. ": " .. defaultChoice
    HeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    HeaderLabel.TextSize = 12
    HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    HeaderLabel.ZIndex = 7 -- Highest ZIndex

    local Arrow = Instance.new("TextLabel")
    Arrow.Parent = HeaderBtn
    Arrow.BackgroundTransparency = 1
    Arrow.Size = UDim2.new(0, 30, 1, 0)
    Arrow.Position = UDim2.new(1, -30, 0, 0)
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Text = "+"
    Arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
    Arrow.TextSize = 14
    Arrow.ZIndex = 7

    -- Options List
    local OptionList = Instance.new("Frame")
    OptionList.Parent = DropdownFrame
    OptionList.Position = UDim2.new(0, 0, 0, 32)
    OptionList.Size = UDim2.new(1, 0, 0, #options * 25)
    OptionList.BackgroundTransparency = 1
    OptionList.ZIndex = 6

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = OptionList
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, optionVal in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Parent = OptionList
        OptBtn.Size = UDim2.new(1, 0, 0, 25)
        OptBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        OptBtn.BorderSizePixel = 0
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.Text = tostring(optionVal)
        OptBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        OptBtn.TextSize = 11
        OptBtn.ZIndex = 7
        
        OptBtn.MouseEnter:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end)
        OptBtn.MouseLeave:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) end)

        OptBtn.MouseButton1Click:Connect(function()
            HeaderLabel.Text = name .. ": " .. tostring(optionVal)
            DropdownFrame:TweenSize(UDim2.new(1, 0, 0, 32), "Out", "Quad", 0.1, true)
            Arrow.Text = "+"
            callback(optionVal)
        end)
    end

    local isOpen = false
    HeaderBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local expandedHeight = 32 + (#options * 25)
            DropdownFrame:TweenSize(UDim2.new(1, 0, 0, expandedHeight), "Out", "Quad", 0.1, true)
            Arrow.Text = "-"
        else
            DropdownFrame:TweenSize(UDim2.new(1, 0, 0, 32), "Out", "Quad", 0.1, true)
            Arrow.Text = "+"
        end
    end)
end

-- --- 1. Banner Dropdown ---
local banners = {"Standard", "Immortal"}
CreateDropdown("Banner", banners, "Standard", function(val)
    SelectedBanner = val
end)

-- --- 2. Amount Dropdown ---
local amounts = {1, 10}
CreateDropdown("Amount", amounts, "1", function(val)
    SelectedAmount = tonumber(val)
end)

-- --- 3. Delay Input Box ---
local DelayFrame = Instance.new("Frame")
DelayFrame.Name = "DelayFrame"
DelayFrame.Parent = Container
DelayFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DelayFrame.Size = UDim2.new(1, 0, 0, 32)
DelayFrame.ZIndex = 2

local DelayCorner = Instance.new("UICorner")
DelayCorner.CornerRadius = UDim.new(0, 4)
DelayCorner.Parent = DelayFrame

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Parent = DelayFrame
DelayLabel.BackgroundTransparency = 1
DelayLabel.Size = UDim2.new(0.6, 0, 1, 0)
DelayLabel.Position = UDim2.new(0, 10, 0, 0)
DelayLabel.Font = Enum.Font.GothamBold
DelayLabel.Text = "Delay (s):"
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.ZIndex = 3

local DelayBox = Instance.new("TextBox")
DelayBox.Parent = DelayFrame
DelayBox.BackgroundTransparency = 1
DelayBox.Size = UDim2.new(0.3, 0, 1, 0)
DelayBox.Position = UDim2.new(0.7, -10, 0, 0)
DelayBox.Font = Enum.Font.Gotham
DelayBox.Text = "0.5"
DelayBox.PlaceholderText = "0.5"
DelayBox.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayBox.TextSize = 12
DelayBox.TextXAlignment = Enum.TextXAlignment.Right
DelayBox.ZIndex = 3

DelayBox.FocusLost:Connect(function()
    local num = tonumber(DelayBox.Text)
    if num and num >= 0 then
        SelectedDelay = num
    else
        DelayBox.Text = tostring(SelectedDelay)
    end
end)

-- --- 4. Toggle Auto Button ---
local AutoBtn = Instance.new("TextButton")
AutoBtn.Parent = Container
AutoBtn.Size = UDim2.new(1, 0, 0, 35)
AutoBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
AutoBtn.Font = Enum.Font.GothamBold
AutoBtn.Text = "Auto: OFF"
AutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBtn.TextSize = 14
AutoBtn.ZIndex = 2
local CornerAuto = Instance.new("UICorner"); CornerAuto.Parent = AutoBtn; CornerAuto.CornerRadius = UDim.new(0, 4)

AutoBtn.MouseButton1Click:Connect(function()
    AutoSummonActive = not AutoSummonActive
    if AutoSummonActive then
        AutoBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        AutoBtn.Text = "Auto: ON"
    else
        AutoBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        AutoBtn.Text = "Auto: OFF"
    end
end)

-- Auto Loop
task.spawn(function()
    while true do
        if AutoSummonActive then
            PerformSummon()
        end
        local waitTime = tonumber(SelectedDelay) or 0.5 
        task.wait(waitTime) 
    end
end)

print("Anime Story Summon Loaded")
