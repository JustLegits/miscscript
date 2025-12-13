-- Roblox Auto Farm Manager (FULL VERSION: Webhook + FPS Saver)
-- Features: Webhook, Heartbeat, Black Screen (Stats + 5 FPS), Anti-AFK, Auto Save

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local plr = Players.LocalPlayer

--// Executor Compatibility
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not request then
    return plr:Warn("Executor không hỗ trợ hàm request!")
end

--// Config Setup
local configFile = "anime_story_full_v5.json" 
local config = {
    webhook = "",
    heartbeat = "",
    delay = 5,
    enabled = false,
    vfx = false,          
    blackscreen = false,  
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

--// 2. Black Screen Logic (FPS Saver + Stats)
local BlackScreenGui = Instance.new("ScreenGui")
if gethui then BlackScreenGui.Parent = gethui() 
elseif syn and syn.protect_gui then 
    syn.protect_gui(BlackScreenGui)
    BlackScreenGui.Parent = CoreGui
else BlackScreenGui.Parent = CoreGui end

BlackScreenGui.Enabled = false
BlackScreenGui.IgnoreGuiInset = true
BlackScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local BlackFrame = Instance.new("Frame", BlackScreenGui)
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
BlackFrame.ZIndex = 9999

local TurnOffBtn = Instance.new("TextButton", BlackFrame)
TurnOffBtn.Size = UDim2.new(0, 250, 0, 50)
TurnOffBtn.Position = UDim2.new(0.5, -125, 0.8, 0) 
TurnOffBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
TurnOffBtn.TextColor3 = Color3.new(1, 1, 1)
TurnOffBtn.Text = "TẮT MÀN HÌNH ĐEN (HỒI PHỤC FPS)"
TurnOffBtn.Font = Enum.Font.SourceSansBold
TurnOffBtn.TextSize = 16
TurnOffBtn.AutoButtonColor = true

local StatsLabel = Instance.new("TextLabel", BlackFrame)
StatsLabel.Size = UDim2.new(1, -40, 0.6, 0)
StatsLabel.Position = UDim2.new(0, 20, 0.1, 0) 
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.new(1, 1, 1)
StatsLabel.TextXAlignment = Enum.TextXAlignment.Center
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Font = Enum.Font.SourceSansBold
StatsLabel.TextSize = 28
StatsLabel.Text = "Đang tải thông tin..."

-- Hàm cập nhật thông số (Stats) trên màn hình đen
local function UpdateStats()
    local level, gems, coins, tokens = "...", "...", "...", "..."
    pcall(function()
        if plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level") then
            level = plr.leaderstats.Level.Value
        end
        if plr:FindFirstChild("Data") then
            if plr.Data:FindFirstChild("Gems") then gems = plr.Data.Gems.Value end
            if plr.Data:FindFirstChild("Coins") then coins = plr.Data.Coins.Value end
        end
        local pGui = plr:FindFirstChild("PlayerGui")
        if pGui then
            local inv = pGui:FindFirstChild("main")
            if inv and inv:FindFirstChild("Inventory") then
                local items = inv.Inventory.Base.Content.Items
                if items and items:FindFirstChild("Trait Tokens") then
                    tokens = items["Trait Tokens"].Quantity.Text
                end
            end
        end
    end)
    StatsLabel.Text = string.format(
        "PLAYER INFOS (FPS: %s)\n\nUser: %s\nLevel: %s\n\n💎 Gems: %s\n💰 Golds: %s\n🎫 Trait Tokens: %s",
        (config.blackscreen and "5 (Tiết kiệm)" or "60 (Mượt)"),
        plr.Name, tostring(level), tostring(gems), tostring(coins), tostring(tokens)
    )
end

-- Hàm set FPS
local function SetFPS(val)
    if setfpscap then setfpscap(val) end
end

-- Logic Bật/Tắt Black Screen
local function UpdateBlackScreenState(state)
    config.blackscreen = state
    BlackScreenGui.Enabled = state 
    
    if state then SetFPS(5) else SetFPS(60) end -- Tự động giảm FPS khi bật
    
    pcall(function()
        local frame = ScreenGui:FindFirstChild("Frame")
        if frame and frame:FindFirstChild("Row") and frame.Row:FindFirstChild("BlackBtn") then
            local btn = frame.Row.BlackBtn
            btn.Text = "Black Scrn: " .. (state and "ON" or "OFF")
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(70, 70, 70)
        end
    end)
    SaveConfig()
end

TurnOffBtn.MouseButton1Click:Connect(function() UpdateBlackScreenState(false) end)

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

--// 4. WEBHOOK LOGIC (Đã khôi phục)
local function SendWebhook()
    local level, gems, coins, tokens = "N/A", "N/A", "N/A", "N/A"
    
    -- Lấy data an toàn
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

    -- Gửi trong luồng riêng để đảm bảo mượt game
    task.spawn(function()
        if config.webhook ~= "" then
            pcall(function()
                request({
                    Url = config.webhook,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"}, -- Thêm lại header cơ bản
                    Body = payload
                })
            end)
        end
        -- Heartbeat
        if config.heartbeat and config.heartbeat ~= "" then
             pcall(function() request({ Url = config.heartbeat, Method = "GET" }) end)
        end
    end)
end

-- Loop Handler chính
task.spawn(function()
    while task.wait(1) do
        -- 1. Xử lý Webhook
        if config.enabled then
            SendWebhook()
            -- Chờ theo phút (Delay)
            local start = tick()
            while tick() - start < (config.delay * 60) do
                -- Trong lúc chờ delay webhook, vẫn phải cập nhật Stats màn hình đen
                if config.blackscreen then UpdateStats() end
                task.wait(1) 
            end
        else
            -- Nếu tắt webhook thì chỉ cập nhật Stats
            if config.blackscreen then UpdateStats() end
            task.wait(1)
        end
    end
end)

--// GUI SETUP
ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Name = "Frame"
Frame.Size = UDim2.new(0, 300, 0, 330) -- Kích thước đầy đủ
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "  Anime Story (Full Manager)"
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

-- Inputs
local WebhookBox = Instance.new("TextBox", Frame)
WebhookBox.Size = UDim2.new(1, -20, 0, 30)
WebhookBox.Position = UDim2.new(0, 10, 0, 40)
WebhookBox.PlaceholderText = "Webhook URL"
WebhookBox.Text = config.webhook
WebhookBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.ClearTextOnFocus = false

local HeartbeatBox = Instance.new("TextBox", Frame)
HeartbeatBox.Size = UDim2.new(1, -20, 0, 30)
HeartbeatBox.Position = UDim2.new(0, 10, 0, 80)
HeartbeatBox.PlaceholderText = "Heartbeat URL"
HeartbeatBox.Text = config.heartbeat
HeartbeatBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HeartbeatBox.TextColor3 = Color3.new(1,1,1)
HeartbeatBox.ClearTextOnFocus = false

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

local BlackBtn = Instance.new("TextButton", Row)
BlackBtn.Name = "BlackBtn"
BlackBtn.Size = UDim2.new(0.5, -5, 1, 0)
BlackBtn.Position = UDim2.new(0.5, 5, 0, 0)
BlackBtn.BackgroundColor3 = config.blackscreen and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(70, 70, 70)
BlackBtn.Text = "Black Scrn: " .. (config.blackscreen and "ON" or "OFF")
BlackBtn.TextColor3 = Color3.new(1,1,1)
BlackBtn.Font = Enum.Font.SourceSansBold

VFXBtn.MouseButton1Click:Connect(function()
    config.vfx = not config.vfx
    VFXBtn.Text = "No VFX: " .. (config.vfx and "ON" or "OFF")
    VFXBtn.BackgroundColor3 = config.vfx and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    if config.vfx then RemoveVFX() end
    SaveConfig()
end)

BlackBtn.MouseButton1Click:Connect(function() UpdateBlackScreenState(not config.blackscreen) end)

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
if config.blackscreen then UpdateBlackScreenState(true) end

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
