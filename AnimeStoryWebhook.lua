if not game:IsLoaded() then
    game.Loaded:Wait()
end
wait(math.random())

--==============================================================--
--  Anime Story Webhook - Final Version
--  Includes: GUI, Auto-save, Remove VFX, FPS Boost, Black Screen
--  Requirements: Roblox Executor (Delta / Syn / ScriptWare)
--==============================================================--

--==============================================================--
-- REMOVE PREVIOUS GUI IF EXISTS
--==============================================================--
pcall(function()
    if game.CoreGui:FindFirstChild("ASW_MainUI") then
        game.CoreGui.ASW_MainUI:Destroy()
    end
end)

--==============================================================--
-- ANTI-AFK (ALWAYS ON — NOT INSIDE GUI)
--==============================================================--
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

--==============================================================--
-- CONFIG MANAGER
--==============================================================--
local HttpService = game:GetService("HttpService")
local folder = "ASW_Config"
local file = folder.."/config.json"

if not isfolder(folder) then
    makefolder(folder)
end

local defaultConfig = {
    webhook = "",
    heartbeat = "",
    delay = 5,
    sending = false,
    removeVFX = false,
    blackscreen = false,
    traitShort = "TKN",
}

local function loadConfig()
    if isfile(file) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(file))
        end)
        if ok and data then
            return data
        end
    end
    return defaultConfig
end

local function saveConfig(cfg)
    writefile(file, HttpService:JSONEncode(cfg))
end

local Config = loadConfig()

--==============================================================--
-- CREATE GUI
--==============================================================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = "ASW_MainUI"
ScreenGui.Parent = game:GetService("CoreGui")

-- Container
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 380, 0, 420)
Main.Position = UDim2.new(0.32, 0, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Text = "Anime Story Webhook"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Hide/Unhide Button
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 50, 0, 26)
HideBtn.Position = UDim2.new(1, -55, 0, 3)
HideBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
HideBtn.Text = "Hide"
HideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 14
HideBtn.Parent = TitleBar

-- Scrollable Body
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -32)
Scroll.Position = UDim2.new(0, 0, 0, 32)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
Scroll.ScrollBarThickness = 6
Scroll.BackgroundTransparency = 1
Scroll.Parent = Main

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)

local function newLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 24)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll
end

local function newBox(placeholder, default)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 0, 32)
    box.Position = UDim2.new(0, 5, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.Text = default
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.Parent = Scroll
    return box
end

local function newToggle(label, state)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 60) or Color3.fromRGB(80, 80, 80)
    btn.Text = label .. ": " .. (state and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = Scroll
    return btn
end

local function newButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = Scroll
    return btn
end

--==============================================================--
-- UI ELEMENTS
--==============================================================--

newLabel("Webhook URL")
local WebhookBox = newBox("Paste Webhook Here", Config.webhook)

newLabel("Heartbeat Link")
local HeartbeatBox = newBox("Heartbeat link for checking", Config.heartbeat)

newLabel("Delay (Minutes)")
local DelayBox = newBox("Delay (default 5)", tostring(Config.delay))

newLabel("Trait Token Short Name")
local TokenBox = newBox("Short name", Config.traitShort)

local SendToggle = newToggle("Webhook Sending", Config.sending)
local VFXToggle = newToggle("Remove VFX", Config.removeVFX)
local BlackToggle = newToggle("Black Screen", Config.blackscreen)

local FPSBtn = newButton("FPS Boost (No Save)")

--==============================================================--
-- AUTO SAVE HANDLERS
--==============================================================--
local function save()
    saveConfig(Config)
end

WebhookBox.FocusLost:Connect(function()
    Config.webhook = WebhookBox.Text
    save()
end)

HeartbeatBox.FocusLost:Connect(function()
    Config.heartbeat = HeartbeatBox.Text
    save()
end)

DelayBox.FocusLost:Connect(function()
    local n = tonumber(DelayBox.Text)
    if n then
        Config.delay = n
        save()
    end
end)

TokenBox.FocusLost:Connect(function()
    Config.traitShort = TokenBox.Text
    save()
end)

SendToggle.MouseButton1Click:Connect(function()
    Config.sending = not Config.sending
    SendToggle.BackgroundColor3 = Config.sending and Color3.fromRGB(0,150,60) or Color3.fromRGB(80,80,80)
    SendToggle.Text = "Webhook Sending: " .. (Config.sending and "ON" or "OFF")
    save()
end)

VFXToggle.MouseButton1Click:Connect(function()
    Config.removeVFX = not Config.removeVFX
    VFXToggle.BackgroundColor3 = Config.removeVFX and Color3.fromRGB(0,150,60) or Color3.fromRGB(80,80,80)
    VFXToggle.Text = "Remove VFX: " .. (Config.removeVFX and "ON" or "OFF")
    save()
end)

BlackToggle.MouseButton1Click:Connect(function()
    Config.blackscreen = not Config.blackscreen
    BlackToggle.BackgroundColor3 = Config.blackscreen and Color3.fromRGB(0,150,60) or Color3.fromRGB(80,80,80)
    BlackToggle.Text = "Black Screen: " .. (Config.blackscreen and "ON" or "OFF")
    save()
end)

--==============================================================--
-- BLACK SCREEN (SAFE, DOES NOT COVER GUI)
--==============================================================--
local BlackGui = Instance.new("Frame")
BlackGui.Name = "BlackOverlay"
BlackGui.Size = UDim2.new(1, 0, 1, 0)
BlackGui.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackGui.BackgroundTransparency = Config.blackscreen and 0 or 1
BlackGui.BorderSizePixel = 0
BlackGui.Parent = ScreenGui
BlackGui.ZIndex = 0

BlackToggle.MouseButton1Click:Connect(function()
    BlackGui.BackgroundTransparency = Config.blackscreen and 0 or 1
end)

--==============================================================--
-- FPS BOOST
--==============================================================--
FPSBtn.MouseButton1Click:Connect(function()
    _G.whiteScreen = false
    _G.fps = 60
    _G.Mode = true
    loadstring(game:HttpGet("https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/fpsboost.lua"))()
end)

--==============================================================--
-- REMOVE VFX LOOP
--==============================================================--
task.spawn(function()
    while true do
        task.wait(1)
        if Config.removeVFX then
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local vfx = rs:FindFirstChild("VFX")
                if vfx then
                    for _, o in ipairs(vfx:GetChildren()) do
                        o:Destroy()
                    end
                end

                local dmg = rs:FindFirstChild("UI")
                if dmg and dmg:FindFirstChild("Damage") then
                    dmg.Damage:ClearAllChildren()
                end
            end)
        end
    end
end)

--==============================================================--
-- HIDE / UNHIDE BUTTON
--==============================================================--
local hidden = false
HideBtn.MouseButton1Click:Connect(function()
    hidden = not hidden
    Main.Visible = not hidden
    HideBtn.Text = hidden and "Show" or "Hide"
end)

--==============================================================--
-- WEBHOOK SENDING LOOP (EMBED)
--==============================================================--
local Players = game:GetService("Players")
local Local = Players.LocalPlayer

task.spawn(function()
    while true do
        task.wait(Config.delay * 60)

        if Config.sending and Config.webhook ~= "" then
            local data = {
                ["username"] = "Anime Story",
                ["embeds"] = {{
                    ["title"] = "Anime Story",
                    ["color"] = 16711680,
                    ["fields"] = {
                        {["name"] = "Player Infos", ["value"] =
                            "User: " .. Local.Name .. "\n" ..
                            "Levels: " .. tostring(Local.leaderstats.Level.Value)
                        },
                        {["name"] = "Player Stats", ["value"] =
                            "Gems: " .. tostring(Local.Data.Gems.Value) .. "\n" ..
                            "Golds: " .. tostring(Local.Data.Coins.Value)
                        },
                    },
                    ["footer"] = {["text"] = "Sent at " .. os.date("%X")}
                }}
            }

            local json = HttpService:JSONEncode(data)

            pcall(function()
                request({
                    Url = Config.webhook,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = json
                })
            end)
        end
    end
end)
