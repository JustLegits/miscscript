if not game:IsLoaded() then
    game.Loaded:Wait()
end
wait(math.random())

-- ===== services & locals =====
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- ===== remove previous GUI on re-execute =====
local GUI_NAME = "AnimeStoryWebhook_vFinal"
pcall(function()
    local prev = CoreGui:FindFirstChild(GUI_NAME)
    if prev then prev:Destroy() end
    local prevToggle = CoreGui:FindFirstChild(GUI_NAME .. "_TOGGLE")
    if prevToggle then prevToggle:Destroy() end
end)

-- ===== config =====
local CFG_FOLDER = "AnimeStoryCfg"
local CFG_FILE = CFG_FOLDER .. "/config_final.json"

if type(isfolder) == "function" and not isfolder(CFG_FOLDER) then
    pcall(function() makefolder(CFG_FOLDER) end)
end

local defaultConfig = {
    webhook = "",
    heartbeat = "",
    delay = 5,
    enabled = false,       -- sending on/off
    removevfx = false,     -- vfx toggle
    blackscreen = false,   -- black screen toggle (saved)
    minimized = true,      -- minimize state (saved)
    traitShort = "TKN"     -- short label (not strictly necessary, kept for compatibility)
}

local function loadConfig()
    if type(isfile) == "function" and isfile(CFG_FILE) then
        local ok, raw = pcall(readfile, CFG_FILE)
        if ok and raw then
            local ok2, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(tbl) == "table" then
                for k,v in pairs(defaultConfig) do
                    if tbl[k] == nil then tbl[k] = v end
                end
                return tbl
            end
        end
    end
    -- copy defaults
    local c = {}
    for k,v in pairs(defaultConfig) do c[k] = v end
    return c
end

local function saveConfig(cfg)
    if type(writefile) == "function" then
        pcall(writefile, CFG_FILE, HttpService:JSONEncode(cfg))
    end
end

local config = loadConfig()

-- ===== anti-afk (always-on) =====
do
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if LocalPlayer and LocalPlayer.Idled then
            LocalPlayer.Idled:Connect(function()
                -- simulate minimal activity
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
end

-- ===== helper: extract number from "Trait Tokens x617" style text =====
local function extractNumberFromString(s)
    if not s then return "N/A" end
    -- find first group of digits
    local num = string.match(tostring(s), "%d+")
    if num then return num else return tostring(s) end
end

-- ===== helper: safe request wrapper (POST JSON / GET) =====
local function request_post(url, body_json)
    if not url or url == "" then return false end
    pcall(function()
        if syn and syn.request then
            syn.request({Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body_json})
        elseif request then
            request({Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body_json})
        elseif http_request then
            http_request({Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body_json})
        end
    end)
end

local function request_get(url)
    if not url or url == "" then return false end
    pcall(function()
        if syn and syn.request then
            syn.request({Url = url, Method = "GET"})
        elseif request then
            request({Url = url, Method = "GET"})
        elseif http_request then
            http_request({Url = url, Method = "GET"})
        end
    end)
end

-- ===== VFX removal function =====
local function performVFXRemoval()
    pcall(function()
        local rs = ReplicatedStorage
        local vfx = rs:FindFirstChild("VFX")
        if vfx then
            for _, obj in ipairs(vfx:GetChildren()) do
                pcall(function() obj:Destroy() end)
            end
        end
        local ui = rs:FindFirstChild("UI")
        if ui then
            local dmg = ui:FindFirstChild("Damage")
            if dmg then
                pcall(function()
                    -- sometimes Damage is a folder with children; clear children
                    for _, c in ipairs(dmg:GetChildren()) do
                        pcall(function() c:Destroy() end)
                    end
                end)
            end
        end
    end)
end

-- background loop to enforce VFX removal when toggle on
local vfxEnforcerThread
local function startVFXEnforcer()
    if vfxEnforcerThread then return end
    vfxEnforcerThread = task.spawn(function()
        while config.removevfx do
            performVFXRemoval()
            task.wait(1)
        end
        vfxEnforcerThread = nil
    end)
end

-- ===== create GUI (keep your original layout, modify internals) =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- main Frame (same as you provided)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 310) -- increased height
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Anime Story Webhook"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 24

-- Floating Show/Hide (always-visible) button outside Frame
local ToggleGuiBtn = Instance.new("TextButton")
ToggleGuiBtn.Name = GUI_NAME .. "_TOGGLE"
ToggleGuiBtn.Size = UDim2.new(0, 80, 0, 28)
ToggleGuiBtn.Position = UDim2.new(0.02, 0, 0.5, 0)
ToggleGuiBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ToggleGuiBtn.TextColor3 = Color3.new(1,1,1)
ToggleGuiBtn.Font = Enum.Font.SourceSansBold
ToggleGuiBtn.TextSize = 14
ToggleGuiBtn.Text = "Show UI"
ToggleGuiBtn.Parent = CoreGui
ToggleGuiBtn.ZIndex = 99999

-- Scrolling content inside the frame (Option B)
local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Name = "Scroll"
Scroll.Size = UDim2.new(1, 0, 1, -34) -- leave space for title
Scroll.Position = UDim2.new(0, 0, 0, 34)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
Scroll.CanvasSize = UDim2.new(0, 0, 2, 0) -- will auto-size if you like, keep big enough
local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Webhook box
local WebhookBox = Instance.new("TextBox", Scroll)
WebhookBox.Size = UDim2.new(1, -20, 0, 30)
WebhookBox.Position = UDim2.new(0, 10, 0, 8)
WebhookBox.PlaceholderText = "Enter Discord Webhook Link"
WebhookBox.Text = config.webhook
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
WebhookBox.ClearTextOnFocus = false
WebhookBox.MultiLine = false
WebhookBox.TextWrapped = false

-- Heartbeat box
local HeartbeatBox = Instance.new("TextBox", Scroll)
HeartbeatBox.Size = UDim2.new(1, -20, 0, 30)
HeartbeatBox.PlaceholderText = "Enter Healthchecks.io URL"
HeartbeatBox.Text = config.heartbeat or ""
HeartbeatBox.TextColor3 = Color3.new(1,1,1)
HeartbeatBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
HeartbeatBox.ClearTextOnFocus = false
HeartbeatBox.MultiLine = false
HeartbeatBox.TextWrapped = false

-- Delay box
local DelayBox = Instance.new("TextBox", Scroll)
DelayBox.Size = UDim2.new(1, -20, 0, 30)
DelayBox.PlaceholderText = "Delay (minutes)"
DelayBox.Text = tostring(config.delay)
DelayBox.TextColor3 = Color3.new(1,1,1)
DelayBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
DelayBox.ClearTextOnFocus = false
DelayBox.MultiLine = false
DelayBox.TextWrapped = false

-- TraitShort box (if you still want it)
local TraitBox = Instance.new("TextBox", Scroll)
TraitBox.Size = UDim2.new(1, -20, 0, 30)
TraitBox.PlaceholderText = "Trait token short (optional)"
TraitBox.Text = config.traitShort or "TKN"
TraitBox.TextColor3 = Color3.new(1,1,1)
TraitBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
TraitBox.ClearTextOnFocus = false
TraitBox.MultiLine = false
TraitBox.TextWrapped = false

-- Sending toggle (ON/OFF)
local ToggleBtn = Instance.new("TextButton", Scroll)
ToggleBtn.Size = UDim2.new(1, -20, 0, 30)
ToggleBtn.BackgroundColor3 = config.enabled and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 18
ToggleBtn.Text = config.enabled and "Status: ON" or "Status: OFF"

-- (Removed Anti-AFK toggle from GUI — anti-afk runs by default)

-- RowFrame (VFX toggle + removed Anim button)
local RowFrame = Instance.new("Frame", Scroll)
RowFrame.Size = UDim2.new(1, -20, 0, 30)
RowFrame.BackgroundTransparency = 1

local VFXToggleBtn = Instance.new("TextButton", RowFrame)
VFXToggleBtn.Size = UDim2.new(0.5, -5, 1, 0)
VFXToggleBtn.BackgroundColor3 = config.removevfx and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
VFXToggleBtn.TextColor3 = Color3.new(1,1,1)
VFXToggleBtn.Font = Enum.Font.SourceSansBold
VFXToggleBtn.TextSize = 18
VFXToggleBtn.Text = config.removevfx and "Remove VFX: ON" or "Remove VFX: OFF"
VFXToggleBtn.Position = UDim2.new(0, 0, 0, 0)

-- Anim button removed as requested (no creation)

-- RowFrame2 (FPS Boost + Black Screen toggle)
local RowFrame2 = Instance.new("Frame", Scroll)
RowFrame2.Size = UDim2.new(1, -20, 0, 30)
RowFrame2.BackgroundTransparency = 1

local FPSBtn = Instance.new("TextButton", RowFrame2)
FPSBtn.Size = UDim2.new(0.5, -5, 1, 0)
FPSBtn.Position = UDim2.new(0, 0, 0, 0)
FPSBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
FPSBtn.TextColor3 = Color3.new(1,1,1)
FPSBtn.Font = Enum.Font.SourceSansBold
FPSBtn.TextSize = 16
FPSBtn.Text = "FPS Boost"

local BlackBtn = Instance.new("TextButton", RowFrame2)
BlackBtn.Size = UDim2.new(0.5, -5, 1, 0)
BlackBtn.Position = UDim2.new(0.5, 5, 0, 0)
BlackBtn.BackgroundColor3 = config.blackscreen and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
BlackBtn.TextColor3 = Color3.new(1,1,1)
BlackBtn.Font = Enum.Font.SourceSansBold
BlackBtn.TextSize = 16
BlackBtn.Text = config.blackscreen and "Black Screen: ON" or "Black Screen: OFF"

-- (Save button removed: all changes auto-saved)

-- ===== floating Show UI logic (Option A style) =====
-- Start hidden if minimized or user hidden; we keep minimized separate from hidden.
local hiddenFlag = false
-- When hidden, Frame.Visible = false and ToggleGuiBtn visible; when shown, reverse.
-- Initialize: Frame visible by default; ToggleGuiBtn text set accordingly
ToggleGuiBtn.Text = "Show UI"
ToggleGuiBtn.Visible = false -- visible only when user hides or when minimized?
-- We'll treat "Hide" action as hiding; Minimize is separate.

-- Create an internal Hide button inside titlebar (position under Title? reuse MinBtn area)
local HideBtn = Instance.new("TextButton", Frame)
HideBtn.Size = UDim2.new(0, 50, 0, 24)
HideBtn.Position = UDim2.new(1, -95, 0, 3)
HideBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
HideBtn.Text = "Hide"
HideBtn.TextColor3 = Color3.new(1,1,1)
HideBtn.Font = Enum.Font.SourceSansBold
HideBtn.TextSize = 14

HideBtn.MouseButton1Click:Connect(function()
    Frame.Visible = false
    ToggleGuiBtn.Visible = true
    ToggleGuiBtn.Text = "Show UI"
    hiddenFlag = true
end)

ToggleGuiBtn.MouseButton1Click:Connect(function()
    Frame.Visible = true
    ToggleGuiBtn.Visible = false
    hiddenFlag = false
end)

-- ===== Minimize logic (preserve existing behavior) =====
local minimized = config.minimized == true
local function ApplyMinimizeState()
    if minimized then
        for _, ui in ipairs(Frame:GetChildren()) do
            if ui ~= Title and ui ~= MinBtn and ui ~= HideBtn then
                ui.Visible = false
            end
        end
        Frame.Size = UDim2.new(0, 300, 0, 30)
        MinBtn.Text = "+"
    else
        for _, ui in ipairs(Frame:GetChildren()) do
            ui.Visible = true
        end
        Frame.Size = UDim2.new(0, 300, 0, 320)
        MinBtn.Text = "-"
    end
end

ApplyMinimizeState()
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    config.minimized = minimized
    saveConfig(config)
    ApplyMinimizeState()
end)

-- ===== wiring: auto-save handlers =====
WebhookBox.FocusLost:Connect(function()
    config.webhook = tostring(WebhookBox.Text or "")
    saveConfig(config)
end)

HeartbeatBox.FocusLost:Connect(function()
    config.heartbeat = tostring(HeartbeatBox.Text or "")
    saveConfig(config)
end)

DelayBox.FocusLost:Connect(function()
    local n = tonumber(DelayBox.Text)
    config.delay = (n and n > 0) and n or 5
    DelayBox.Text = tostring(config.delay)
    saveConfig(config)
end)

TraitBox.FocusLost:Connect(function()
    config.traitShort = tostring(TraitBox.Text or "TKN")
    saveConfig(config)
end)

ToggleBtn.MouseButton1Click:Connect(function()
    config.enabled = not config.enabled
    ToggleBtn.Text = config.enabled and "Status: ON" or "Status: OFF"
    ToggleBtn.BackgroundColor3 = config.enabled and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
    saveConfig(config)
end)

VFXToggleBtn.MouseButton1Click:Connect(function()
    config.removevfx = not config.removevfx
    VFXToggleBtn.Text = config.removevfx and "Remove VFX: ON" or "Remove VFX: OFF"
    VFXToggleBtn.BackgroundColor3 = config.removevfx and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
    saveConfig(config)
    if config.removevfx then
        startVFXEnforcer()
    end
end)

BlackBtn.MouseButton1Click:Connect(function()
    config.blackscreen = not config.blackscreen
    BlackBtn.Text = config.blackscreen and "Black Screen: ON" or "Black Screen: OFF"
    BlackBtn.BackgroundColor3 = config.blackscreen and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
    -- apply black screen overlay without hiding GUI; create overlay (or reuse)
    -- create overlay if not exists
    if not CoreGui:FindFirstChild(GUI_NAME .. "_BLACK") then
        local overlay = Instance.new("Frame")
        overlay.Name = GUI_NAME .. "_BLACK"
        overlay.Size = UDim2.new(1,0,1,0)
        overlay.Position = UDim2.new(0,0,0,0)
        overlay.BackgroundColor3 = Color3.new(0,0,0)
        overlay.BorderSizePixel = 0
        overlay.Parent = CoreGui
        overlay.ZIndex = 9998
    end
    local overlay = CoreGui:FindFirstChild(GUI_NAME .. "_BLACK")
    if overlay then
        overlay.BackgroundTransparency = config.blackscreen and 0 or 1
    end
    saveConfig(config)
end)

-- FPS Boost (no save)
FPSBtn.MouseButton1Click:Connect(function()
    pcall(function()
        _G.whiteScreen = false
        _G.fps = 60
        _G.Mode = true
        local ok, res = pcall(function()
            return loadstring(game:HttpGet('https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/fpsboost.lua'))()
        end)
        -- brief visual feedback
        local original = FPSBtn.Text
        FPSBtn.Text = ok and "FPS Applied" or "FPS Failed"
        task.delay(2, function() FPSBtn.Text = original end)
    end)
end)

-- ensure overlay initial state according to config
if config.blackscreen then
    if not CoreGui:FindFirstChild(GUI_NAME .. "_BLACK") then
        local overlay = Instance.new("Frame")
        overlay.Name = GUI_NAME .. "_BLACK"
        overlay.Size = UDim2.new(1,0,1,0)
        overlay.Position = UDim2.new(0,0,0,0)
        overlay.BackgroundColor3 = Color3.new(0,0,0)
        overlay.BorderSizePixel = 0
        overlay.Parent = CoreGui
        overlay.ZIndex = 9998
    end
    CoreGui[GUI_NAME .. "_BLACK"].BackgroundTransparency = 0
else
    if CoreGui:FindFirstChild(GUI_NAME .. "_BLACK") then
        CoreGui[GUI_NAME .. "_BLACK"].BackgroundTransparency = 1
    end
end

-- ===== webhook sender (embed) & heartbeat ping loop =====
task.spawn(function()
    while true do
        local waitSeconds = (tonumber(config.delay) or 5) * 60
        -- check sending loop: send immediately if enabled, then wait
        if config.enabled and config.webhook and config.webhook ~= "" then
            pcall(function()
                -- gather stats with defensive checks
                local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                local data = LocalPlayer:FindFirstChild("Data")
                local level = (leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value) or "N/A"
                local gems = (data and data:FindFirstChild("Gems") and data.Gems.Value) or "N/A"
                local coins = (data and data:FindFirstChild("Coins") and data.Coins.Value) or "N/A"

                -- trait tokens: try GUI path, pull Quantity.Text then extract number
                local tokens = "N/A"
                pcall(function()
                    local mainGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("main")
                    if mainGui then
                        local inv = mainGui:FindFirstChild("Inventory")
                        if inv then
                            local base = inv:FindFirstChild("Base")
                            if base then
                                local content = base:FindFirstChild("Content")
                                if content then
                                    local items = content:FindFirstChild("Items")
                                    if items then
                                        local trait = items:FindFirstChild("Trait Tokens")
                                        if trait then
                                            -- Quantity may be TextLabel or TextBox or Value
                                            local q = trait:FindFirstChild("Quantity")
                                            if q then
                                                local textval = ""
                                                if q:IsA("TextLabel") or q:IsA("TextBox") then
                                                    textval = q.Text
                                                elseif q.Value ~= nil then
                                                    textval = tostring(q.Value)
                                                else
                                                    textval = tostring(q)
                                                end
                                                tokens = extractNumberFromString(textval)
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
                            ["value"] = "User: " .. tostring(LocalPlayer and LocalPlayer.Name or "N/A") .. "\nLevels: " .. tostring(level),
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
                -- send to webhook
                request_post(config.webhook, payload)
            end)

            -- heartbeat ping
            if config.heartbeat and config.heartbeat ~= "" then
                pcall(function() request_get(config.heartbeat) end)
            end
        end

        -- wait loop with early exit if disabled
        local elapsed = 0
        while elapsed < waitSeconds do
            if not config.enabled then break end
            task.wait(1)
            elapsed = elapsed + 1
        end
    end
end)

-- apply initial VFX enforcer if config said so
if config.removevfx then startVFXEnforcer() end

-- finalize: save initial config to ensure file exists and contains defaults
saveConfig(config)

-- done
