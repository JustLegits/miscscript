if not game:IsLoaded() then
    game.Loaded:Wait()
end
wait(math.random())

--=====================================================
--  CLEANUP ON RE-EXECUTE
--=====================================================
if game.CoreGui:FindFirstChild("ASWebhookGUI") then
    game.CoreGui.ASWebhookGUI:Destroy()
end

--=====================================================
--  SERVICES
--=====================================================
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

--=====================================================
--  AUTO ANTI-AFK (ALWAYS ON)
--=====================================================
spawn(function()
    for _, v in pairs(getconnections(Player.Idled)) do
        v:Disable()
    end
    RS.Stepped:Connect(function()
        VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

--=====================================================
--  CONFIG SYSTEM (AUTO-SAVE)
--=====================================================
local config_path = "aswebhook_config.txt"

local default_config = {
    Heartbeat = "60",
    RemoveVFX = false,
    BlackScreen = false
}

local function load_config()
    if isfile and isfile(config_path) then
        local data = readfile(config_path)
        return game:GetService("HttpService"):JSONDecode(data)
    end
    return default_config
end

local function save_config(tbl)
    if writefile then
        writefile(config_path, game:GetService("HttpService"):JSONEncode(tbl))
    end
end

local config = load_config()

--=====================================================
--  GUI CONSTRUCTION
--=====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ASWebhookGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

-- SCROLLING WINDOW
local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 6
MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MainFrame.Parent = ScreenGui

-- COLLAPSE BUTTON
local Collapse = Instance.new("TextButton")
Collapse.Size = UDim2.new(0, 30, 0, 30)
Collapse.Position = UDim2.new(1, -35, 0, 5)
Collapse.Text = "+"
Collapse.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Collapse.Parent = MainFrame

-- TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "Anime Story Webhook"
Title.TextScaled = true
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 10)
UIList.Parent = MainFrame
UIList.SortOrder = Enum.SortOrder.LayoutOrder

--=====================================================
--  BLACK SCREEN (SAFE, DOESN'T HIDE GUI)
--=====================================================
local BlackFrame = Instance.new("Frame")
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.Position = UDim2.new(0, 0, 0, 0)
BlackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
BlackFrame.BackgroundTransparency = 1
BlackFrame.ZIndex = 0
BlackFrame.Parent = ScreenGui

local function setBlackScreen(state)
    config.BlackScreen = state
    save_config(config)
    BlackFrame.BackgroundTransparency = state and 0 or 1
end
setBlackScreen(config.BlackScreen)

local BlackToggle = Instance.new("TextButton")
BlackToggle.Size = UDim2.new(1, -20, 0, 35)
BlackToggle.Text = "Toggle Black Screen"
BlackToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
BlackToggle.TextColor3 = Color3.new(1, 1, 1)
BlackToggle.Parent = MainFrame

BlackToggle.MouseButton1Click:Connect(function()
    setBlackScreen(not config.BlackScreen)
end)

--=====================================================
--  REMOVE VFX TOGGLE
--=====================================================
local remove_vfx_paths = {
    game:GetService("ReplicatedStorage"):WaitForChild("UI"):WaitForChild("Damage"),
    game:GetService("ReplicatedStorage"):FindFirstChild("VFX")
}

local function apply_vfx_state(enabled)
    config.RemoveVFX = enabled
    save_config(config)

    for _, folder in ipairs(remove_vfx_paths) do
        if folder and folder:IsA("Instance") then
            for _, obj in ipairs(folder:GetChildren()) do
                if enabled then obj.Parent = nil end
            end
        end
    end
end

local VFXToggle = Instance.new("TextButton")
VFXToggle.Size = UDim2.new(1, -20, 0, 35)
VFXToggle.Text = "Toggle Remove VFX"
VFXToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
VFXToggle.TextColor3 = Color3.new(1, 1, 1)
VFXToggle.Parent = MainFrame

VFXToggle.MouseButton1Click:Connect(function()
    apply_vfx_state(not config.RemoveVFX)
end)

-- apply saved
apply_vfx_state(config.RemoveVFX)

--=====================================================
-- HEARTBEAT (AUTO-SAVE)
--=====================================================
local HeartbeatFrame = Instance.new("Frame")
HeartbeatFrame.Size = UDim2.new(1, -20, 0, 50)
HeartbeatFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HeartbeatFrame.Parent = MainFrame

local HBLabel = Instance.new("TextLabel")
HBLabel.Size = UDim2.new(0.5, 0, 1, 0)
HBLabel.Text = "Heartbeat"
HBLabel.TextColor3 = Color3.new(1,1,1)
HBLabel.BackgroundTransparency = 1
HBLabel.Parent = HeartbeatFrame

local HBBox = Instance.new("TextBox")
HBox = HBBox
HBBox.Size = UDim2.new(0.5, -10, 1, -10)
HBBox.Position = UDim2.new(0.5, 10, 0, 5)
HBBox.Text = config.Heartbeat
HBBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HBBox.TextColor3 = Color3.new(1,1,1)
HBBox.ClearTextOnFocus = false
HBBox.Parent = HeartbeatFrame

HBBox.FocusLost:Connect(function()
    config.Heartbeat = HBBox.Text
    save_config(config)
end)

--=====================================================
-- LOW QUALITY BUTTON (NO SAVE)
--=====================================================
local LowQ = Instance.new("TextButton")
LowQ.Size = UDim2.new(1, -20, 0, 35)
LowQ.Text = "Low Quality Mode"
LowQ.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LowQ.TextColor3 = Color3.new(1, 1, 1)
LowQ.Parent = MainFrame

LowQ.MouseButton1Click:Connect(function()
    _G.whiteScreen = false
    _G.fps = 60
    _G.Mode = true
    loadstring(game:HttpGet('https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/fpsboost.lua'))()
end)

--=====================================================
-- COLLAPSE LOGIC (DEFAULT COLLAPSED)
--=====================================================
local collapsed = true

local function refresh_collapse()
    if collapsed then
        MainFrame.CanvasSize = UDim2.new(0,0,0,0)
        MainFrame.Size = UDim2.new(0, 350, 0, 50)
        Collapse.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 350, 0, 400)
        Collapse.Text = "-"
    end
end

Collapse.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    refresh_collapse()
end)

refresh_collapse()
