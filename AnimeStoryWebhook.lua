if not game:IsLoaded() then
    game.Loaded:Wait()
end
wait(math.random())

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Config storage
local CFG_FOLDER = "AnimeStoryConfig"
local CFG_FILE = CFG_FOLDER .. "/config_v3.json"

-- Ensure folder exists (executors typically provide isfolder/makefolder)
if type(isfolder) == "function" and not isfolder(CFG_FOLDER) then
    pcall(function() makefolder(CFG_FOLDER) end)
end

-- Default config
local defaultConfig = {
    webhook = "",
    heartbeat = "",
    traitShort = "TKN",
    delay = 5,
    enabled = false,
    antiafk = true,
    blackscreen = false,   -- collapsed-by-default requirement requested earlier (this is blackscreen default true)
    removevfx = true,
    minimized = true      -- GUI collapsed by default
}

-- Load config
local config = table.create(0)
local function loadConfig()
    if type(isfile) == "function" and isfile(CFG_FILE) then
        local ok, raw = pcall(readfile, CFG_FILE)
        if ok and raw then
            local suc, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
            if suc and type(tbl) == "table" then
                for k,v in pairs(defaultConfig) do
                    tbl[k] = (tbl[k] ~= nil) and tbl[k] or v
                end
                return tbl
            end
        end
    end
    -- fallback: return copy of defaults
    local copy = {}
    for k,v in pairs(defaultConfig) do copy[k] = v end
    return copy
end

local function saveConfig()
    local encoded = HttpService:JSONEncode(config)
    if type(writefile) == "function" then
        pcall(writefile, CFG_FILE, encoded)
    end
end

-- Initialize config
config = loadConfig()

-- Remove previous GUI if exists (avoid duplicate when re-executing)
local GUI_NAME = "AnimeStoryWebhookGUI_v3"
local existing = game:GetService("CoreGui"):FindFirstChild(GUI_NAME)
if existing then
    pcall(function() existing:Destroy() end)
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.IgnoreGuiInset = true

-- Black Screen overlay (toggleable)
local BlackScreen = Instance.new("Frame")
BlackScreen.Name = "BlackScreenOverlay"
BlackScreen.Size = UDim2.new(1, 0, 1, 0)
BlackScreen.Position = UDim2.new(0, 0, 0, 0)
BlackScreen.BackgroundColor3 = Color3.new(0,0,0)
BlackScreen.BorderSizePixel = 0
BlackScreen.ZIndex = 99999
BlackScreen.Visible = config.blackscreen
BlackScreen.Parent = ScreenGui

-- Utility: apply black screen state
local function setBlackScreen(state)
    BlackScreen.Visible = not not state
end
setBlackScreen(config.blackscreen)

-- VFX removal function (removes VFX children and ReplicatedStorage.UI.Damage)
local function performVFXRemoval()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local vfx = rs:FindFirstChild("VFX")
        if vfx then
            for _, obj in ipairs(vfx:GetChildren()) do
                pcall(function() obj:Destroy() end)
            end
        end
        local uiFolder = rs:FindFirstChild("UI")
        if uiFolder then
            local dmg = uiFolder:FindFirstChild("Damage")
            if dmg then
                pcall(function() dmg:Destroy() end)
            end
        end
    end)
end

-- If removevfx is enabled on load, start a loop that keeps removing (defensive)
local vfxLoopThread
local function startVFXLoop()
    if vfxLoopThread then return end
    vfxLoopThread = task.spawn(function()
        while config.removevfx do
            performVFXRemoval()
            task.wait(1)
        end
        vfxLoopThread = nil
    end)
end
local function stopVFXLoop()
    config.removevfx = false
    -- loop thread checks config and ends by itself
end
if config.removevfx then
    startVFXLoop()
end

-- Anti-AFK (runs by default if available)
do
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if LocalPlayer and LocalPlayer.Idled then
            LocalPlayer.Idled:Connect(function()
                if config.antiafk then
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end
            end)
        end
    end)
end

-- Webhook and Heartbeat sending function (auto loop controlled by config.enabled)
local function sendHeartbeat(url)
    if not url or url == "" then return end
    pcall(function()
        if request then
            request({ Url = url, Method = "GET" })
        elseif http_request then
            http_request({ Url = url, Method = "GET" })
        elseif syn and syn.request then
            syn.request({ Url = url, Method = "GET" })
        end
    end)
end

local function buildAndSendWebhook()
    if not config.webhook or config.webhook == "" then return end
    pcall(function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local data = LocalPlayer:FindFirstChild("Data")

        local level = (leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value) or "N/A"
        local gems = (data and data:FindFirstChild("Gems") and data.Gems.Value) or "N/A"
        local coins = (data and data:FindFirstChild("Coins") and data.Coins.Value) or "N/A"

        -- Trait Tokens fetch (safe)
        local tokens = "N/A"
        pcall(function()
            local mainGui = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("main")
            if mainGui then
                local inventory = mainGui:FindFirstChild("Inventory")
                if inventory then
                    local base = inventory:FindFirstChild("Base")
                    if base then
                        local content = base:FindFirstChild("Content")
                        if content then
                            local items = content:FindFirstChild("Items")
                            if items then
                                local trait = items:FindFirstChild("Trait Tokens")
                                if trait and trait:FindFirstChild("Quantity") then
                                    -- Quantity might be a TextLabel; support .Text or .Value
                                    local q = trait.Quantity
                                    if q then
                                        if q:IsA("TextLabel") or q:IsA("TextBox") then
                                            tokens = tostring(q.Text)
                                        elseif q.Value ~= nil then
                                            tokens = tostring(q.Value)
                                        else
                                            tokens = tostring(q)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        local timeSent = os.date("%Y-%m-%d %H:%M:%S")

        local embed = {
            ["title"] = "Anime Story",
            ["type"] = "rich",
            ["color"] = tonumber(0x00B2FF),
            ["fields"] = {
                {
                    ["name"] = "**Player Infos**",
                    ["value"] = "User: " .. tostring(LocalPlayer.Name) .. "\nLevels: " .. tostring(level),
                    ["inline"] = false
                },
                {
                    ["name"] = "**Player Stats**",
                    ["value"] = "Gems: " .. tostring(gems) .. "\nGolds: " .. tostring(coins) .. "\nTrait Tokens: " .. tostring(tokens),
                    ["inline"] = false
                },
                {
                    ["name"] = "**Send at**",
                    ["value"] = timeSent,
                    ["inline"] = false
                }
            }
        }

        local payload = HttpService:JSONEncode({ embeds = { embed } })
        -- send via available request function
        if request then
            request({ Url = config.webhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        elseif http_request then
            http_request({ Url = config.webhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        elseif syn and syn.request then
            syn.request({ Url = config.webhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        end
    end)
end

-- Auto send loop (controlled by config.enabled)
task.spawn(function()
    while true do
        if config.enabled then
            pcall(function()
                buildAndSendWebhook()
                if config.heartbeat and config.heartbeat ~= "" then
                    sendHeartbeat(config.heartbeat)
                end
            end)
            local sleepT = tonumber(config.delay) or 5
            local elapsed = 0
            while elapsed < (sleepT * 60) do
                if not config.enabled then break end
                task.wait(1)
                elapsed = elapsed + 1
            end
        else
            task.wait(1)
        end
    end
end)

-- GUI creation
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 360, 0, 360)
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 34)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.BorderSizePixel = 0
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.TextColor3 = Color3.new(1,1,1)
Title.Text = "Anime Story Webhook"

-- Minimize / Collapse button (top-right)
local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0, 34, 0, 34)
MinBtn.Position = UDim2.new(1, -38, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 20
MinBtn.TextColor3 = Color3.new(1,1,1)

-- Container for body (so we can hide/show easily)
local Body = Instance.new("Frame", Frame)
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -34)
Body.Position = UDim2.new(0, 0, 0, 34)
Body.BackgroundTransparency = 1

-- Layout values
local margin = 12
local curY = 8

local function createLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, - (margin*2), 0, 18)
    lbl.Position = UDim2.new(0, margin, 0, curY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    curY = curY + 20
    return lbl
end

local function createTextbox(parent, default, placeholder)
    local tb = Instance.new("TextBox", parent)
    tb.Size = UDim2.new(1, - (margin*2), 0, 30)
    tb.Position = UDim2.new(0, margin, 0, curY)
    tb.BackgroundColor3 = Color3.fromRGB(50,50,50)
    tb.TextColor3 = Color3.new(1,1,1)
    tb.Font = Enum.Font.SourceSans
    tb.TextSize = 14
    tb.Text = default or ""
    tb.PlaceholderText = placeholder or ""
    tb.ClearTextOnFocus = false
    tb.MultiLine = false
    tb.TextWrapped = false
    curY = curY + 36
    return tb
end

local function createToggleButton(parent, text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, - (margin*2), 0, 34)
    btn.Position = UDim2.new(0, margin, 0, curY)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text
    curY = curY + 40
    return btn
end

-- Webhook URL
createLabel(Body, "Webhook URL (auto-save)")
local WebhookBox = createTextbox(Body, config.webhook or "", "https://discord.com/api/webhooks/...")
WebhookBox.FocusLost:Connect(function(enterPressed)
    config.webhook = tostring(WebhookBox.Text or "")
    saveConfig()
end)

-- Heartbeat URL
createLabel(Body, "Heartbeat URL (Healthchecks.io) (auto-save)")
local HeartbeatBox = createTextbox(Body, config.heartbeat or "", "https://hc.example.com/uuid")
HeartbeatBox.FocusLost:Connect(function()
    config.heartbeat = tostring(HeartbeatBox.Text or "")
    saveConfig()
end)

-- Trait token short name
createLabel(Body, "Trait Tokens Short (auto-save)")
local TraitBox = createTextbox(Body, config.traitShort or "TKN", "TKN")
TraitBox.FocusLost:Connect(function()
    config.traitShort = tostring(TraitBox.Text or "")
    saveConfig()
end)

-- Delay (minutes)
createLabel(Body, "Delay (minutes) for auto-send")
local DelayBox = createTextbox(Body, tostring(config.delay or 5), "5")
DelayBox.FocusLost:Connect(function()
    local n = tonumber(DelayBox.Text)
    config.delay = (n and n > 0) and n or 5
    saveConfig()
end)

-- Enabled toggle (auto-send enabled)
local enabledText = config.enabled and "Auto-Send: ON" or "Auto-Send: OFF"
local EnabledBtn = createToggleButton(Body, enabledText)
EnabledBtn.MouseButton1Click:Connect(function()
    config.enabled = not config.enabled
    EnabledBtn.Text = config.enabled and "Auto-Send: ON" or "Auto-Send: OFF"
    saveConfig()
end)

-- Anti-AFK info (runs automatically; allow toggle to disable)
local afText = config.antiafk and "Anti-AFK: ON (running)" or "Anti-AFK: OFF"
local AFToggleBtn = createToggleButton(Body, afText)
AFToggleBtn.MouseButton1Click:Connect(function()
    config.antiafk = not config.antiafk
    AFToggleBtn.Text = config.antiafk and "Anti-AFK: ON (running)" or "Anti-AFK: OFF"
    saveConfig()
end)

-- Black Screen toggle
local bsText = config.blackscreen and "Black Screen: ON" or "Black Screen: OFF"
local BlackBtn = createToggleButton(Body, bsText)
BlackBtn.MouseButton1Click:Connect(function()
    config.blackscreen = not config.blackscreen
    BlackBtn.Text = config.blackscreen and "Black Screen: ON" or "Black Screen: OFF"
    setBlackScreen(config.blackscreen)
    saveConfig()
end)

-- Remove VFX toggle (auto-save)
local vfxText = config.removevfx and "Remove VFX: ON" or "Remove VFX: OFF"
local VFXBtn = createToggleButton(Body, vfxText)
VFXBtn.MouseButton1Click:Connect(function()
    config.removevfx = not config.removevfx
    VFXBtn.Text = config.removevfx and "Remove VFX: ON" or "Remove VFX: OFF"
    saveConfig()
    if config.removevfx then
        startVFXLoop()
    else
        -- setting flag false will let the loop finish
        -- we also perform a final removal to be sure
        performVFXRemoval()
    end
end)

-- Low Quality button (no save) — executes provided fpsboost script
local LQBtn = createToggleButton(Body, "Apply Low Quality (instant)")
LQBtn.MouseButton1Click:Connect(function()
    -- Execute snippet exactly as requested; wrapped in pcall to avoid breaking
    pcall(function()
        _G.whiteScreen = false
        _G.fps = 60
        _G.Mode = true
        local ok, res = pcall(function()
            return loadstring(game:HttpGet('https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/fpsboost.lua'))()
        end)
        -- feedback (temporarily change button text)
        local old = LQBtn.Text
        if ok then
            LQBtn.Text = "Low Quality: Applied"
        else
            LQBtn.Text = "Low Quality: Failed"
        end
        task.delay(2, function() LQBtn.Text = old end)
    end)
end)

-- Remove Save button: auto-save everywhere so we don't create Save

-- Adjust layout final height
Frame.Size = UDim2.new(0, 360, 0, math.max(200, curY + 24))

-- Minimize behavior (collapsed by default per config.minimized)
local minimized = config.minimized == true
local function applyMinimizedState()
    if minimized then
        Body.Visible = false
        Frame.Size = UDim2.new(0, 360, 0, 34)
        MinBtn.Text = "+"
    else
        Body.Visible = true
        Frame.Size = UDim2.new(0, 360, 0, math.max(200, curY + 24))
        MinBtn.Text = "-"
    end
end
applyMinimizedState()
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    config.minimized = minimized
    saveConfig()
    applyMinimizedState()
end)

-- Ensure black screen is not hidden when minimized (BlackScreen is separate in CoreGui)

-- Final: save config at end (ensure defaults persisted)
saveConfig()

-- Safe cleanup on script end if necessary (nothing required)
-- Script ready.
