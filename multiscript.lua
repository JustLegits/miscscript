-- Script: Script Manager GUI (local client, full version)
-- Features:
-- ✅ Dropdown chọn player
-- ✅ Dropdown chọn Script 1 – Script 5
-- ✅ Mỗi preset lưu riêng
-- ✅ Run Script button
-- ✅ Auto-run nếu script trùng player
-- ✅ Chỉ localplayer mới save script cho mình
-- ✅ Hoạt động độc lập 100% (file hoàn chỉnh)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local configFileName = "ScriptManagerConfig.json"
local config = {}

-- ============================
-- Load Config
-- ============================
local function safeReadConfig()
    local ok, data = pcall(function()
        if isfile and isfile(configFileName) then
            return HttpService:JSONDecode(readfile(configFileName))
        end
        return { scripts = {}, autoRun = true }
    end)
    if ok and type(data) == "table" then
        return data
    else
        return { scripts = {}, autoRun = true }
    end
end

local function safeWriteConfig()
    pcall(function()
        if writefile then
            writefile(configFileName, HttpService:JSONEncode(config))
        end
    end)
end

config = safeReadConfig()
config.scripts = config.scripts or {}
config.autoRun = config.autoRun ~= false

-- ============================
-- GUI CREATION
-- ============================
repeat task.wait() until game:IsLoaded() and player:FindFirstChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptManagerGUI"
ScreenGui.Parent = player.PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainFrame.BorderColor3 = Color3.fromRGB(150, 150, 150)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Script Manager"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.BackgroundColor3 = Color3.fromRGB(25,25,35)
Title.TextColor3 = Color3.fromRGB(255,255,255)

-- LEFT FRAME
local LeftFrame = Instance.new("Frame")
LeftFrame.Parent = MainFrame
LeftFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
LeftFrame.Size = UDim2.new(0.32, 0, 0.8, 0)
LeftFrame.BackgroundTransparency = 1

--------------------------------------------------
-- PLAYER DROPDOWN
--------------------------------------------------
local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Parent = LeftFrame
PlayerLabel.Text = "Chọn player:"
PlayerLabel.Size = UDim2.new(1,0,0,20)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.TextColor3 = Color3.new(1,1,1)
PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left

local PlayerButton = Instance.new("TextButton")
PlayerButton.Parent = LeftFrame
PlayerButton.Position = UDim2.new(0, 0, 0, 26)
PlayerButton.Size = UDim2.new(1,0,0,30)
PlayerButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
PlayerButton.TextColor3 = Color3.new(1,1,1)
PlayerButton.Text = "Chọn..."

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Parent = LeftFrame
PlayerList.Position = UDim2.new(0, 0, 0, 60)
PlayerList.Size = UDim2.new(1, 0, 0, 100)
PlayerList.CanvasSize = UDim2.new(0,0,0,0)
PlayerList.BackgroundColor3 = Color3.fromRGB(45,45,55)
PlayerList.Visible = false
PlayerList.ScrollBarThickness = 6

local PL_Layout = Instance.new("UIListLayout")
PL_Layout.Parent = PlayerList
PL_Layout.SortOrder = Enum.SortOrder.LayoutOrder
PL_Layout.Padding = UDim.new(0,4)

local selectedName = nil

local function refreshPlayerList()
    for _,child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local list = Players:GetPlayers()
    table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)

    for _, pl in ipairs(list) do
        local b = Instance.new("TextButton")
        b.Parent = PlayerList
        b.Size = UDim2.new(1,-6,0,26)
        b.Position = UDim2.new(0,3,0,0)
        b.Text = pl.Name
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.TextColor3 = Color3.new(1,1,1)

        b.MouseButton1Click:Connect(function()
            selectedName = pl.Name
            PlayerButton.Text = pl.Name
            PlayerList.Visible = false

            -- load script preset
            local pdata = config.scripts[selectedName]
            if pdata and pdata[selectedPreset] then
                ScriptBox.Text = pdata[selectedPreset]
            else
                ScriptBox.Text = "-- Chưa có script cho preset này"
            end
        end)
    end

    PlayerList.CanvasSize = UDim2.new(0,0,0,#list * 30)
end

PlayerButton.MouseButton1Click:Connect(function()
    PlayerList.Visible = not PlayerList.Visible
    if PlayerList.Visible then refreshPlayerList() end
end)

--------------------------------------------------
-- SCRIPT PRESET DROPDOWN
--------------------------------------------------
local PresetLabel = Instance.new("TextLabel")
PresetLabel.Parent = LeftFrame
PresetLabel.Position = UDim2.new(0,0,0,100)
PresetLabel.Size = UDim2.new(1,0,0,20)
PresetLabel.Text = "Chọn Script:"
PresetLabel.TextColor3 = Color3.new(1,1,1)
PresetLabel.BackgroundTransparency = 1
PresetLabel.TextXAlignment = Enum.TextXAlignment.Left

local PresetButton = Instance.new("TextButton")
PresetButton.Parent = LeftFrame
PresetButton.Position = UDim2.new(0,0,0,126)
PresetButton.Size = UDim2.new(1,0,0,30)
PresetButton.Text = "Script 1"
PresetButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
PresetButton.TextColor3 = Color3.new(1,1,1)

local PresetList = Instance.new("Frame")
PresetList.Parent = LeftFrame
PresetList.Position = UDim2.new(0,0,0,160)
PresetList.BackgroundColor3 = Color3.fromRGB(45,45,55)
PresetList.Visible = false

local scriptPresets = {"Script 1","Script 2","Script 3","Script 4","Script 5"}
local selectedPreset = "Script 1"

local PR_Layout = Instance.new("UIListLayout")
PR_Layout.Parent = PresetList
PR_Layout.Padding = UDim.new(0,4)
PR_Layout.SortOrder = Enum.SortOrder.LayoutOrder

PresetButton.MouseButton1Click:Connect(function()
    PresetList.Visible = not PresetList.Visible
    PresetList.Size = UDim2.new(1,0,0,#scriptPresets * 30)
end)

for _, presetName in ipairs(scriptPresets) do
    local x = Instance.new("TextButton")
    x.Parent = PresetList
    x.Size = UDim2.new(1,-6,0,26)
    x.Position = UDim2.new(0,3,0,0)
    x.Text = presetName
    x.BackgroundColor3 = Color3.fromRGB(60,60,60)
    x.TextColor3 = Color3.new(1,1,1)

    x.MouseButton1Click:Connect(function()
        selectedPreset = presetName
        PresetButton.Text = presetName
        PresetList.Visible = false

        if selectedName then
            local pdata = config.scripts[selectedName]
            if pdata and pdata[selectedPreset] then
                ScriptBox.Text = pdata[selectedPreset]
            else
                ScriptBox.Text = "-- Chưa có script cho preset này"
            end
        end
    end)
end

--------------------------------------------------
-- RIGHT: SCRIPT BOX
--------------------------------------------------
local RightFrame = Instance.new("Frame")
RightFrame.Parent = MainFrame
RightFrame.Position = UDim2.new(0.36,0,0.12,0)
RightFrame.Size = UDim2.new(0.62,0,0.78,0)
RightFrame.BackgroundTransparency = 1

local ScriptBox = Instance.new("TextBox")
ScriptBox.Parent = RightFrame
ScriptBox.Size = UDim2.new(1,0,0.75,0)
ScriptBox.Font = Enum.Font.Code
ScriptBox.TextSize = 14
ScriptBox.Text = "-- Viết script ở đây"
ScriptBox.MultiLine = true
ScriptBox.ClearTextOnFocus = false
ScriptBox.BackgroundColor3 = Color3.fromRGB(40,40,50)
ScriptBox.TextColor3 = Color3.fromRGB(255,255,255)
ScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ScriptBox.TextYAlignment = Enum.TextYAlignment.Top

local SaveBtn = Instance.new("TextButton")
SaveBtn.Parent = RightFrame
SaveBtn.Position = UDim2.new(0,0,0.78,0)
SaveBtn.Size = UDim2.new(0.48, -4, 0.22, -4)
SaveBtn.BackgroundColor3 = Color3.fromRGB(50,150,200)
SaveBtn.TextColor3 = Color3.new(1,1,1)
SaveBtn.Text = "Lưu Script"

local DeleteBtn = Instance.new("TextButton")
DeleteBtn.Parent = RightFrame
DeleteBtn.Position = UDim2.new(0.52,0,0.78,0)
DeleteBtn.Size = UDim2.new(0.48, -4, 0.22, -4)
DeleteBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
DeleteBtn.TextColor3 = Color3.new(1,1,1)
DeleteBtn.Text = "Xóa Script"

local RunBtn = Instance.new("TextButton")
RunBtn.Parent = RightFrame
RunBtn.Position = UDim2.new(0,0,1, -30)
RunBtn.Size = UDim2.new(1,0,0,26)
RunBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
RunBtn.TextColor3 = Color3.new(1,1,1)
RunBtn.Text = "Chạy Script"

local Status = Instance.new("TextLabel")
Status.Parent = MainFrame
Status.BackgroundTransparency = 1
Status.Position = UDim2.new(0, 8, 0.92,0)
Status.Size = UDim2.new(1, -16, 0, 18)
Status.Text = "Status: Ready"
Status.TextColor3 = Color3.fromRGB(200,200,200)

--------------------------------------------------
-- SAVE SCRIPT
--------------------------------------------------
SaveBtn.MouseButton1Click:Connect(function()
    if not selectedName then
        Status.Text = "Status: Chưa chọn username!"
        return
    end

    if selectedName ~= player.Name then
        Status.Text = "Status: Chỉ tự lưu script cho chính mình!"
        return
    end

    config.scripts[selectedName] = config.scripts[selectedName] or {}
    config.scripts[selectedName][selectedPreset] = ScriptBox.Text

    safeWriteConfig()

    Status.Text = "Status: Đã lưu script (" .. selectedPreset .. ")"
end)

--------------------------------------------------
-- DELETE SCRIPT
--------------------------------------------------
DeleteBtn.MouseButton1Click:Connect(function()
    if not selectedName then return end
    if config.scripts[selectedName] then
        config.scripts[selectedName][selectedPreset] = nil
    end

    safeWriteConfig()
    ScriptBox.Text = "-- Script đã bị xóa"

    Status.Text = "Status: Đã xóa script"
end)

--------------------------------------------------
-- RUN SCRIPT BUTTON
--------------------------------------------------
RunBtn.MouseButton1Click:Connect(function()
    local code = ScriptBox.Text
    if not code or #code < 1 then
        Status.Text = "Status: Script trống!"
        return
    end

    local f = loadstring(code)
    if f then
        task.spawn(function()
            local ok, err = pcall(f)
            if not ok then
                warn("[ScriptManager] Lỗi khi chạy:", err)
            end
        end)
        Status.Text = "Status: Đã chạy script!"
    end
end)

--------------------------------------------------
-- AUTO RUN WHEN PLAYER JOINS
--------------------------------------------------
local function autoRun(playerName)
    local pdata = config.scripts[playerName]
    if pdata then
        for _, preset in ipairs(scriptPresets) do
            local code = pdata[preset]
            if code then
                local f = loadstring(code)
                if f then task.spawn(function() pcall(f) end) end
            end
        end
    end
end

for _, pl in ipairs(Players:GetPlayers()) do
    autoRun(pl.Name)
end

Players.PlayerAdded:Connect(function(pl)
    task.wait(0.2)
    autoRun(pl.Name)
    refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function()
    refreshPlayerList()
end)

--------------------------------------------------
Status.Text = "Status: Ready!"
