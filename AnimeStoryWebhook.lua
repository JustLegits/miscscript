-- Roblox Auto Farm Manager (SPAM REMOTE REPLAY VERSION)
-- Features: Webhook, Heartbeat, Spam Auto Replay, No VFX, Anti-AFK

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

--// Executor Compatibility
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not request then
    return plr:Warn("Executor không hỗ trợ hàm request!")
end

--// Config Setup
local configFile = "anime_story_webhook.json" 
local config = {
    webhook = "",
    heartbeat = "",
    delay = 5,
    enabled = false,
    vfx = true,           
    autoreplay = true,   
    minimized = true
}

-- Load Config
pcall(function()
    if isfile(configFile) then
        local loaded = HttpService:JSONDecode(readfile(configFile))
        for k, v in pairs(loaded) do
            config[k] = v
        end
    end
end)

local function SaveConfig()
    writefile(configFile, HttpService:JSONEncode(config))
end

--// 1. SAFE Anti-AFK
plr.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--// 2. AUTO REPLAY LOGIC (SPAM REMOTE)
-- Hàm bắn Remote
local function FireReplayRemote()
    local args = {
        "battle_replay"
    }
    local remote = ReplicatedStorage:WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")
    if remote then
        remote:FireServer(unpack(args))
    end
end

-- Vòng lặp Spam (Đã bỏ check GUI)
task.spawn(function()
    while task.wait(1) do -- Spam mỗi 1 giây
        if config.autoreplay then
            pcall(function()
                FireReplayRemote()
            end)
        end
    end
end)

--// 3. SAFE Remove VFX
local function RemoveVFX()
    local rs = game:GetService("ReplicatedStorage")
    local vfx = rs:FindFirstChild("VFX")
    local keep = { ["Summon"] = true } 
    if vfx then
        for _, obj in ipairs(vfx:GetChildren()) do
            if not keep[obj.Name] then obj:Destroy() end
        end
    end
end

--// 4. WEBHOOK LOGIC
local function SendWebhook()
    local level, gems, coins, tokens = "N/A", "N/A", "N/A", "N/A"
    
    pcall(function()
        if plr:FindFirstChild("leaderstats") then level = plr.leaderstats.Level.Value end
        if plr:FindFirstChild("Data") then
            gems = plr.Data.Gems.Value
            coins = plr.Data.Coins.Value
        end
        local pGui = plr:WaitForChild("PlayerGui", 1)
        if pGui and pGui:FindFirstChild("main") then
            local items = pGui.main.Inventory.Base.Content.Items
            if items:FindFirstChild("Trait Tokens") then
                tokens = items["Trait Tokens"].Quantity.Text
            end
        end
    end)

    local embed = {
        ["title"] = "Anime Story Stats",
        ["color"] = tonumber(0x00B2FF),
        ["fields"] = {
            { ["name"] = "**User**", ["value"] = plr.Name .. " (Lvl: " .. tostring(level) .. ")", ["inline"] = true },
            { ["name"] = "**Resources**", ["value"] = "💎 " .. tostring(gems) .. "\n💰 " .. tostring(coins) .. "\n🎟️ " .. tostring(tokens), ["inline"] = false },
            { ["name"] = "**Time**", ["value"] = os.date("%Y-%m-%d %H:%M:%S"), ["inline"] = false }
        }
    }

    local payload = HttpService:JSONEncode({embeds = {embed}})

    task.spawn(function()
        if config.webhook ~= "" then
            pcall(function()
                request({
                    Url = config.webhook,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = payload
                })
            end)
        end
        if config.heartbeat and config.heartbeat ~= "" then
             pcall(function() request({ Url = config.heartbeat, Method = "GET" }) end)
        end
    end)
end

-- Loop Handler chính
task.spawn(function()
    while task.wait(1) do
        if config.enabled then
            SendWebhook()
            task.wait(config.delay * 60)
        end
    end
end)

--// GUI SETUP
ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Name = "Frame"
Frame.Size = UDim2.new(0, 300, 0, 330)
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "  Anime Story (Spam Replay)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.new(1,1,1)

-- 1. Webhook Input
local WebhookBox = Instance.new("TextBox", Frame)
WebhookBox.Name = "WebhookBox"
WebhookBox.Size = UDim2.new(1, -20, 0, 30)
WebhookBox.Position = UDim2.new(0, 10, 0, 40)
WebhookBox.PlaceholderText = "Dán Webhook URL vào đây..."
WebhookBox.Text = config.webhook
WebhookBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.Font = Enum.Font.SourceSans
WebhookBox.TextSize = 14
WebhookBox.ClearTextOnFocus = false
WebhookBox.ClipsDescendants = true
WebhookBox.TextXAlignment = Enum.TextXAlignment.Left
WebhookBox.TextTruncate = Enum.TextTruncate.AtEnd 

-- 2. Heartbeat Input
local HeartbeatBox = Instance.new("TextBox", Frame)
HeartbeatBox.Name = "HeartbeatBox"
HeartbeatBox.Size = UDim2.new(1, -20, 0, 30)
HeartbeatBox.Position = UDim2.new(0, 10, 0, 80)
HeartbeatBox.PlaceholderText = "Dán Heartbeat URL vào đây..."
HeartbeatBox.Text = config.heartbeat
HeartbeatBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HeartbeatBox.TextColor3 = Color3.new(1,1,1)
HeartbeatBox.Font = Enum.Font.SourceSans
HeartbeatBox.TextSize = 14
HeartbeatBox.ClearTextOnFocus = false
HeartbeatBox.ClipsDescendants = true
HeartbeatBox.TextXAlignment = Enum.TextXAlignment.Left
HeartbeatBox.TextTruncate = Enum.TextTruncate.AtEnd 

local DelayBox = Instance.new("TextBox", Frame)
DelayBox.Size = UDim2.new(1, -20, 0, 30)
DelayBox.Position = UDim2.new(0, 10, 0, 120)
DelayBox.PlaceholderText = "Delay (min)"
DelayBox.Text = tostring(config.delay)
DelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayBox.TextColor3 = Color3.new(1,1,1)
DelayBox.ClearTextOnFocus = false

-- Auto Save Text Inputs
WebhookBox.FocusLost:Connect(function() config.webhook = WebhookBox.Text; SaveConfig() end)
HeartbeatBox.FocusLost:Connect(function() config.heartbeat = HeartbeatBox.Text; SaveConfig() end)
DelayBox.FocusLost:Connect(function() config.delay = tonumber(DelayBox.Text) or 5; SaveConfig() end)

local MainToggle = Instance.new("TextButton", Frame)
MainToggle.Size = UDim2.new(1, -20, 0, 30)
MainToggle.Position = UDim2.new(0, 10, 0, 160)
MainToggle.BackgroundColor3 = config.enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
MainToggle.Text = config.enabled and "Webhook: ON" or "Webhook: OFF"
MainToggle.TextColor3 = Color3.new(1,1,1)
MainToggle.Font = Enum.Font.SourceSansBold
MainToggle.TextSize = 18

MainToggle.MouseButton1Click:Connect(function()
    config.enabled = not config.enabled
    MainToggle.Text = config.enabled and "Webhook: ON" or "Webhook: OFF"
    MainToggle.BackgroundColor3 = config.enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    SaveConfig()
end)

local Row = Instance.new("Frame", Frame)
Row.Name = "Row"
Row.Size = UDim2.new(1, -20, 0, 30)
Row.Position = UDim2.new(0, 10, 0, 200)
Row.BackgroundTransparency = 1

local VFXBtn = Instance.new("TextButton", Row)
VFXBtn.Name = "VFXBtn"
VFXBtn.Size = UDim2.new(0.5, -5, 1, 0)
VFXBtn.BackgroundColor3 = config.vfx and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
VFXBtn.Text = "No VFX: " .. (config.vfx and "ON" or "OFF")
VFXBtn.TextColor3 = Color3.new(1,1,1)
VFXBtn.Font = Enum.Font.SourceSansBold

local ReplayBtn = Instance.new("TextButton", Row)
ReplayBtn.Name = "ReplayBtn"
ReplayBtn.Size = UDim2.new(0.5, -5, 1, 0)
ReplayBtn.Position = UDim2.new(0.5, 5, 0, 0)
ReplayBtn.BackgroundColor3 = config.autoreplay and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
ReplayBtn.Text = "Spam Replay: " .. (config.autoreplay and "ON" or "OFF")
ReplayBtn.TextColor3 = Color3.new(1,1,1)
ReplayBtn.Font = Enum.Font.SourceSansBold

VFXBtn.MouseButton1Click:Connect(function()
    config.vfx = not config.vfx
    VFXBtn.Text = "No VFX: " .. (config.vfx and "ON" or "OFF")
    VFXBtn.BackgroundColor3 = config.vfx and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    if config.vfx then RemoveVFX() end
    SaveConfig()
end)

ReplayBtn.MouseButton1Click:Connect(function()
    config.autoreplay = not config.autoreplay
    ReplayBtn.Text = "Spam Replay: " .. (config.autoreplay and "ON" or "OFF")
    ReplayBtn.BackgroundColor3 = config.autoreplay and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    SaveConfig()
end)

local SaveBtn = Instance.new("TextButton", Frame)
SaveBtn.Size = UDim2.new(1, -20, 0, 30)
SaveBtn.Position = UDim2.new(0, 10, 0, 240)
SaveBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
SaveBtn.Text = "Force Save Config"
SaveBtn.TextColor3 = Color3.new(1,1,1)
SaveBtn.Font = Enum.Font.SourceSansBold

SaveBtn.MouseButton1Click:Connect(function()
    config.webhook = WebhookBox.Text; config.heartbeat = HeartbeatBox.Text; config.delay = tonumber(DelayBox.Text) or 5
    SaveConfig()
end)

-- Init
if config.vfx then RemoveVFX() end 

local minimized = config.minimized
local function ApplyMin()
    if minimized then
        Frame.Size = UDim2.new(0, 300, 0, 30)
        MinBtn.Text = "+"
        for _, v in pairs(Frame:GetChildren()) do if v ~= Title and v ~= MinBtn then v.Visible = false end end
    else
        Frame.Size = UDim2.new(0, 300, 0, 290)
        MinBtn.Text = "-"
        for _, v in pairs(Frame:GetChildren()) do v.Visible = true end
    end
end
ApplyMin()
MinBtn.MouseButton1Click:Connect(function() minimized = not minimized; config.minimized = minimized; SaveConfig(); ApplyMin() end)
