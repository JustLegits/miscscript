if not game:IsLoaded() then
    game.Loaded:Wait()
end
wait(math.random())

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- === Config file ===
local CFG_FOLDER = "AnimeStoryCfg"
local CFG_FILE = CFG_FOLDER .. "/config_final.json"

if type(isfolder) == "function" and not isfolder(CFG_FOLDER) then
    pcall(function() makefolder(CFG_FOLDER) end)
end

local defaultConfig = {
    webhook = "",
    heartbeat = "",
    delay = 5,
    sending = false,
    removeVFX = false,
    blackscreen = false,
    minimized = true,
    traitShort = "TKN"
}

local function loadConfig()
    if type(isfile) == "function" and isfile(CFG_FILE) then
        local ok, raw = pcall(readfile, CFG_FILE)
        if ok and raw then
            local suc, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
            if suc and type(tbl) == "table" then
                for k,v in pairs(defaultConfig) do
                    if tbl[k] == nil then tbl[k] = v end
                end
                return tbl
            end
        end
    end
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
-- ensure config has all keys
for k,v in pairs(defaultConfig) do if config[k] == nil then config[k] = v end end
saveConfig(config)

-- === Anti-AFK (always-on) ===
do
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if LocalPlayer and LocalPlayer.Idled then
            LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
end

-- === Helpers ===
local function safe_request_post(url, body_json)
    if not url or url == "" then return end
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

local function safe_request_get(url)
    if not url or url == "" then return end
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

local function extractNumberFromString(s)
    if not s then return "N/A" end
    local num = string.match(tostring(s), "%d+")
    if num then return num end
    return tostring(s)
end

-- === VFX enforcer (runs only when toggle on) ===
local vfxThread
local function performVFXRemovalOnce()
    pcall(function()
        local rs = ReplicatedStorage
        local vfx = rs:FindFirstChild("VFX")
        if vfx then
            for _, c in ipairs(vfx:GetChildren()) do
                pcall(function() c:Destroy() end)
            end
        end
        local ui = rs:FindFirstChild("UI")
        if ui then
            local dmg = ui:FindFirstChild("Damage")
            if dmg then
                pcall(function()
                    for _, cc in ipairs(dmg:GetChildren()) do
                        pcall(function() cc:Destroy() end)
                    end
                end)
            end
        end
    end)
end

local function startVFXEnforcer()
    if vfxThread then return end
    vfxThread = task.spawn(function()
        while config.removeVFX do
            performVFXRemovalOnce()
            task.wait(1)
        end
        vfxThread = nil
    end)
end

-- start enforcer if saved enabled
if config.removeVFX then startVFXEnforcer() end

-- === GUI (use your provided layout; keep changes minimal) ===
local GUI_NAME = "AnimeStoryWebhook_FinalGUI"

-- NOTE: per last instruction, do NOT remove previous UI automatically.
-- (You told "maybe remove that" and chose not to remove.)
-- So we create the GUI with unique name; if user wants removal they'd re-run with manual cleanup.

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 310)
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Anime Story Webhook"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.BackgroundTransparency = 0

local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 24

-- Floating Show UI button (always visible when hidden)
local ShowBtn = Instance.new("TextButton")
ShowBtn.Name = GUI_NAME .. "_SHOWBTN"
ShowBtn.Size = UDim2.new(0, 84, 0, 28)
ShowBtn.Position = UDim2.new(0.02, 0, 0.5, 0)
ShowBtn.Text = "Show UI"
ShowBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ShowBtn.TextColor3 = Color3.new(1,1,1)
ShowBtn.Font = Enum.Font.SourceSansBold
ShowBtn.TextSize = 14
ShowBtn.Parent = CoreGui
ShowBtn.Visible = false
ShowBtn.ZIndex = 99999

-- ScrollingFrame inside Frame (Option B)
local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1, 0, 1, -34)
Scroll.Position = UDim2.new(0, 0, 0, 34)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
Scroll.CanvasSize = UDim2.new(0,0,2,0)
local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0,8)

-- Webhook box
local WebhookBox = Instance.new("TextBox", Scroll)
WebhookBox.Size = UDim2.new(1, -20, 0, 30)
WebhookBox.Position = UDim2.new(0, 10, 0, 8)
WebhookBox.PlaceholderText = "Enter Discord Webhook Link"
WebhookBox.Text = tostring(config.webhook)
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
WebhookBox.ClearTextOnFocus = false
WebhookBox.MultiLine = false
WebhookBox.TextWrapped = false

-- Heartbeat box
local HeartbeatBox = Instance.new("TextBox", Scroll)
HeartbeatBox.Size = UDim2.new(1, -20, 0, 30)
HeartbeatBox.PlaceholderText = "Enter Healthchecks.io URL"
HeartbeatBox.Text = tostring(config.heartbeat or "")
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

-- Trait short box (optional)
local TraitBox = Instance.new("TextBox", Scroll)
TraitBox.Size = UDim2.new(1, -20, 0, 30)
TraitBox.PlaceholderText = "Trait token short (optional)"
TraitBox.Text = tostring(config.traitShort or "TKN")
TraitBox.TextColor3 = Color3.new(1,1,1)
TraitBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
TraitBox.ClearTextOnFocus = false
TraitBox.MultiLine = false
TraitBox.TextWrapped = false

-- Sending toggle
local SendToggle = Instance.new("TextButton", Scroll)
SendToggle.Size = UDim2.new(1, -20, 0, 30)
SendToggle.BackgroundColor3 = config.sending and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
SendToggle.TextColor3 = Color3.new(1,1,1)
SendToggle.Font = Enum.Font.SourceSansBold
SendToggle.TextSize = 18
SendToggle.Text = config.sending and "Status: ON" or "Status: OFF"

-- RowFrame: VFX toggle + (we removed Anim)
local RowFrame = Instance.new("Frame", Scroll)
RowFrame.Size = UDim2.new(1, -20, 0, 34)
RowFrame.BackgroundTransparency = 1

local VFXToggle = Instance.new("TextButton", RowFrame)
VFXToggle.Size = UDim2.new(0.5, -6, 1, 0)
VFXToggle.Position = UDim2.new(0, 0, 0, 0)
VFXToggle.BackgroundColor3 = config.removeVFX and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
VFXToggle.TextColor3 = Color3.new(1,1,1)
VFXToggle.Font = Enum.Font.SourceSansBold
VFXToggle.TextSize = 16
VFXToggle.Text = config.removeVFX and "Remove VFX: ON" or "Remove VFX: OFF"

-- RowFrame2: Black screen toggle placed on the right side of same row (per your request to keep GUI short)
local BlackToggle = Instance.new("TextButton", RowFrame)
BlackToggle.Size = UDim2.new(0.5, -6, 1, 0)
BlackToggle.Position = UDim2.new(0.5, 6, 0, 0)
BlackToggle.BackgroundColor3 = config.blackscreen and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
BlackToggle.TextColor3 = Color3.new(1,1,1)
BlackToggle.Font = Enum.Font.SourceSansBold
BlackToggle.TextSize = 16
BlackToggle.Text = config.blackscreen and "Black Screen: ON" or "Black Screen: OFF"

-- (No Save button per auto-save requirement)

-- === Floating Black Overlay (opaque, ZIndex less than GUI so GUI stays interactive) ===
local OVERLAY_NAME = GUI_NAME .. "_BLACK"
if not CoreGui:FindFirstChild(OVERLAY_NAME) then
    local overlay = Instance.new("Frame")
    overlay.Name = OVERLAY_NAME
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BorderSizePixel = 0
    overlay.BackgroundTransparency = config.blackscreen and 0 or 1
    overlay.ZIndex = 2 -- lower than GUI elements which have default higher z when parented to PlayerGui
    overlay.Parent = CoreGui
else
    CoreGui[OVERLAY_NAME].BackgroundTransparency = config.blackscreen and 0 or 1
end

-- Ensure GUI (ScreenGui) sits above overlay by giving it higher ZIndex
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- === Hide / Show button logic (Option A) ===
-- "Hide" button placed inside UI; ShowBtn (floating) remains in CoreGui
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
    ShowBtn.Visible = true
end)

ShowBtn.MouseButton1Click:Connect(function()
    Frame.Visible = true
    ShowBtn.Visible = false
end)

-- initialize ShowBtn visibility if Frame was hidden by minimize
if config.minimized then
    -- keep minimized inside the visible Frame; do not auto-hide the entire UI
    -- Frame remains visible; ShowBtn remains hidden
    ShowBtn.Visible = false
else
    ShowBtn.Visible = false
end

-- === Minimize logic (preserve saved minimized state) ===
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

-- === Auto-save handlers ===
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

SendToggle.MouseButton1Click:Connect(function()
    config.sending = not config.sending
    SendToggle.Text = config.sending and "Status: ON" or "Status: OFF"
    SendToggle.BackgroundColor3 = config.sending and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
    saveConfig(config)
end)

VFXToggle.MouseButton1Click:Connect(function()
    config.removeVFX = not config.removeVFX
    VFXToggle.Text = config.removeVFX and "Remove VFX: ON" or "Remove VFX: OFF"
    VFXToggle.BackgroundColor3 = config.removeVFX and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
    saveConfig(config)
    if config.removeVFX then startVFXEnforcer() end
end)

BlackToggle.MouseButton1Click:Connect(function()
    config.blackscreen = not config.blackscreen
    BlackToggle.Text = config.blackscreen and "Black Screen: ON" or "Black Screen: OFF"
    BlackToggle.BackgroundColor3 = config.blackscreen and Color3.fromRGB(0,150,60) or Color3.fromRGB(70,70,70)
    -- toggle overlay
    if CoreGui:FindFirstChild(OVERLAY_NAME) then
        CoreGui[OVERLAY_NAME].BackgroundTransparency = config.blackscreen and 0 or 1
    end
    saveConfig(config)
end)

-- === Webhook send + heartbeat loop (embed) ===
task.spawn(function()
    while true do
        local delayMinutes = (tonumber(config.delay) or 5)
        local waitSeconds = math.max(1, delayMinutes) * 60

        if config.sending and config.webhook and config.webhook ~= "" then
            pcall(function()
                -- gather stats
                local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                local data = LocalPlayer:FindFirstChild("Data")
                local level = (leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value) or "N/A"
                local gems = (data and data:FindFirstChild("Gems") and data.Gems.Value) or "N/A"
                local coins = (data and data:FindFirstChild("Coins") and data.Coins.Value) or "N/A"

                -- trait tokens extraction: try PlayerGui path, then fallback to "N/A"
                local traitTokens = "N/A"
                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    if pg then
                        local mainGui = pg:FindFirstChild("main")
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
                                                local q = trait:FindFirstChild("Quantity")
                                                if q then
                                                    local txt = ""
                                                    if q:IsA("TextLabel") or q:IsA("TextBox") then
                                                        txt = q.Text
                                                    elseif q.Value ~= nil then
                                                        txt = tostring(q.Value)
                                                    else
                                                        txt = tostring(q)
                                                    end
                                                    traitTokens = extractNumberFromString(txt)
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
                            ["value"] = "Gems: " .. tostring(gems) .. "\nGolds: " .. tostring(coins) .. "\nTrait Tokens: " .. tostring(traitTokens),
                            ["inline"] = false
                        },
                        {
                            ["name"] = "**Send at**",
                            ["value"] = timeSent,
                            ["inline"] = false
                        }
                    }
                }

                local payload = HttpService:JSONEncode({embeds = {embed}})
                safe_request_post(config.webhook, payload)
            end)

            -- heartbeat ping
            if config.heartbeat and config.heartbeat ~= "" then
                safe_request_get(config.heartbeat)
            end
        end

        -- wait with early exit if sending toggled off
        local elapsed = 0
        while elapsed < waitSeconds do
            if not config.sending then break end
            task.wait(1)
            elapsed = elapsed + 1
        end
    end
end)

-- ensure overlay initial state
if CoreGui:FindFirstChild(OVERLAY_NAME) then
    CoreGui[OVERLAY_NAME].BackgroundTransparency = config.blackscreen and 0 or 1
end

-- ensure vfx enforcer if needed
if config.removeVFX then startVFXEnforcer() end

-- final save
saveConfig(config)

-- Script ready.
