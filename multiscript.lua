repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptManagerGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 500, 0, 320)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainFrame.BorderColor3 = Color3.fromRGB(120, 120, 120)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Title.BorderColor3 = Color3.fromRGB(120, 120, 120)
Title.Text = "Local Script Manager"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255, 255, 255)

local LeftFrame = Instance.new("Frame")
LeftFrame.Parent = MainFrame
LeftFrame.Size = UDim2.new(0, 150, 1, -30)
LeftFrame.Position = UDim2.new(0, 0, 0, 30)
LeftFrame.BackgroundColor3 = Color3.fromRGB(45,45,55)
LeftFrame.BorderColor3 = Color3.fromRGB(100,100,100)

local RightFrame = Instance.new("Frame")
RightFrame.Parent = MainFrame
RightFrame.Size = UDim2.new(1, -150, 1, -30)
RightFrame.Position = UDim2.new(0, 150, 0, 30)
RightFrame.BackgroundColor3 = Color3.fromRGB(50,50,60)
RightFrame.BorderColor3 = Color3.fromRGB(100,100,100)

--------------------------------------------------------------------------------
-- USER DROPDOWN
--------------------------------------------------------------------------------

local UserLabel = Instance.new("TextLabel")
UserLabel.Parent = LeftFrame
UserLabel.Text = "Local User:"
UserLabel.Size = UDim2.new(1,0,0,25)
UserLabel.BackgroundTransparency = 1
UserLabel.TextColor3 = Color3.fromRGB(255,255,255)
UserLabel.Position = UDim2.new(0,0,0,5)
UserLabel.TextSize = 14

local UsernameDropdown = Instance.new("TextButton")
UsernameDropdown.Parent = LeftFrame
UsernameDropdown.Size = UDim2.new(1,0,0,25)
UsernameDropdown.Position = UDim2.new(0,0,0,30)
UsernameDropdown.BackgroundColor3 = Color3.fromRGB(60,60,75)
UsernameDropdown.Text = player.Name
UsernameDropdown.TextColor3 = Color3.fromRGB(255,255,255)

--------------------------------------------------------------------------------
-- SCRIPT PRESET DROPDOWN (5 preset lưu riêng file)
--------------------------------------------------------------------------------

local PresetLabel = Instance.new("TextLabel")
PresetLabel.Parent = LeftFrame
PresetLabel.Text = "Script Preset:"
PresetLabel.Size = UDim2.new(1,0,0,25)
PresetLabel.Position = UDim2.new(0,0,0,80)
PresetLabel.BackgroundTransparency = 1
PresetLabel.TextColor3 = Color3.fromRGB(255,255,255)
PresetLabel.TextSize = 14

local PresetDropdown = Instance.new("TextButton")
PresetDropdown.Parent = LeftFrame
PresetDropdown.Size = UDim2.new(1,0,0,25)
PresetDropdown.Position = UDim2.new(0,0,0,105)
PresetDropdown.BackgroundColor3 = Color3.fromRGB(60,60,75)
PresetDropdown.Text = "Chọn Script..."
PresetDropdown.TextColor3 = Color3.fromRGB(255,255,255)

local PresetMenu = Instance.new("Frame")
PresetMenu.Parent = LeftFrame
PresetMenu.Position = UDim2.new(0,0,0,130)
PresetMenu.Size = UDim2.new(1,0,0,0)
PresetMenu.BackgroundTransparency = 1
PresetMenu.Visible = false

local presetList = {"Script 1","Script 2","Script 3","Script 4","Script 5"}

PresetDropdown.MouseButton1Click:Connect(function()
    PresetMenu.Visible = not PresetMenu.Visible
    PresetMenu.Size = UDim2.new(1,0,0,#presetList * 25)
end)

for _, name in ipairs(presetList) do
    local btn = Instance.new("TextButton")
    btn.Parent = PresetMenu
    btn.Size = UDim2.new(1,0,0,25)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,95)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255,255,255)

    btn.MouseButton1Click:Connect(function()
        PresetDropdown.Text = name
        PresetMenu.Visible = false
        loadConfig() -- tự load script của preset đó
    end)
end

--------------------------------------------------------------------------------
-- SCRIPT BOX
--------------------------------------------------------------------------------

local ScriptBox = Instance.new("TextBox")
ScriptBox.Parent = RightFrame
ScriptBox.Position = UDim2.new(0, 5, 0, 5)
ScriptBox.Size = UDim2.new(1, -10, 1, -55)
ScriptBox.Font = Enum.Font.Code
ScriptBox.Text = ""
ScriptBox.PlaceholderText = "-- Viết script ở đây..."
ScriptBox.PlaceholderColor3 = Color3.fromRGB(180,180,180)
ScriptBox.TextColor3 = Color3.fromRGB(255,255,255)
ScriptBox.BackgroundColor3 = Color3.fromRGB(40,40,50)
ScriptBox.BorderColor3 = Color3.fromRGB(120,120,120)
ScriptBox.TextSize = 14
ScriptBox.MultiLine = true
ScriptBox.ClearTextOnFocus = false
ScriptBox.TextWrapped = false
ScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ScriptBox.TextYAlignment = Enum.TextYAlignment.Top

--------------------------------------------------------------------------------
-- SAVE BUTTON
--------------------------------------------------------------------------------

local SaveBtn = Instance.new("TextButton")
SaveBtn.Parent = RightFrame
SaveBtn.Size = UDim2.new(1, -10, 0, 40)
SaveBtn.Position = UDim2.new(0, 5, 1, -45)
SaveBtn.BackgroundColor3 = Color3.fromRGB(50,150,70)
SaveBtn.Text = "LƯU SCRIPT"
SaveBtn.TextColor3 = Color3.fromRGB(255,255,255)
SaveBtn.TextSize = 18
SaveBtn.Font = Enum.Font.SourceSansBold

--------------------------------------------------------------------------------
-- SAVE / LOAD (Preset riêng)
--------------------------------------------------------------------------------

function getFileName()
    local user = UsernameDropdown.Text
    local preset = PresetDropdown.Text
    return "UserScript_"..user.."_"..preset..".json"
end

function saveConfig()
    local code = ScriptBox.Text

    if code == "" or code:find("template") then
        warn("⛔ Không lưu vì script là template hoặc rỗng.")
        return
    end

    local data = { script = code }
    writefile(getFileName(), HttpService:JSONEncode(data))
    warn("✅ Đã lưu script cho preset: "..PresetDropdown.Text)
end

function loadConfig()
    local file = getFileName()

    if not isfile(file) then
        ScriptBox.Text = ""
        warn("⛔ Không có script của preset này → để trống.")
        return
    end

    local data = HttpService:JSONDecode(readfile(file))
    ScriptBox.Text = data.script or ""
    warn("✅ Đã load script cho preset: "..PresetDropdown.Text)
end

SaveBtn.MouseButton1Click:Connect(saveConfig)

--------------------------------------------------------------------------------
-- KHI MỞ GUI → không auto load cho đến khi chọn preset
--------------------------------------------------------------------------------
