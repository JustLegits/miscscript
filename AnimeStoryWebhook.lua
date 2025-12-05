-- Roblox Discord Webhook Sender (Delta / common executors)
-- Updated with Heartbeat Monitor (Healthchecks.io)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

wait(math.random())

--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

--// Config Save
local configFile = "webhook_config_v2.json" -- Changed name to avoid conflict with old config
local config = {
    webhook = "",
    heartbeat = "", -- New Config Field
    delay = 5,
    enabled = false,
    antiafk = true,
    minimized = true
}

-- Load config
pcall(function()
    if isfile(configFile) then
        config = HttpService:JSONDecode(readfile(configFile))
    end
end)

-- Save config function
local function SaveConfig()
    writefile(configFile, HttpService:JSONEncode(config))
end

--// Anti-AFK (toggleable)
local vu = game:GetService("VirtualUser")
plr.Idled:Connect(function()
    if config.antiafk then
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

--// Webhook Sender (with embed)
local function SendWebhook()
    -- 1. Send to Discord
    if config.webhook ~= "" then
        local leaderstats = plr:FindFirstChild("leaderstats")
        local data = plr:FindFirstChild("Data")

        local level = leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or "N/A"
        local gems = data and data:FindFirstChild("Gems") and data.Gems.Value or "N/A"
        local coins = data and data:FindFirstChild("Coins") and data.Coins.Value or "N/A"
        -- ▼▼ Trait Tokens ▼▼
        local tokens = "N/A"
        local inv = plr.PlayerGui:FindFirstChild("main")
        if inv then
            local inventory = inv:FindFirstChild("Inventory")
            if inventory then
                local base = inventory:FindFirstChild("Base")
                if base then
                    local content = base:FindFirstChild("Content")
                    if content then
                        local items = content:FindFirstChild("Items")
                        if items then
                            local trait = items:FindFirstChild("Trait Tokens")
                            if trait and trait:FindFirstChild("Quantity") then
                                tokens = trait.Quantity.Text
                            end
                        end
                    end
                end
            end
        end
        -- ▲▲ Trait Tokens ▲▲
        local timeSent = os.date("%Y-%m-%d %H:%M:%S")

        local embed = {
            ["title"] = "Anime Story",
            ["type"] = "rich",
            ["color"] = tonumber(0x00B2FF),
            ["fields"] = {
                {
                    ["name"] = "**Player Infos**",
                    ["value"] = "User: " .. plr.Name .. "\nLevels: " .. tostring(level),
                    ["inline"] = false
                },
                {
                    ["name"] = "**Player Stats**",
                    ["value"] = "Gems: " .. tostring(gems)
                       .. "\nGolds: " .. tostring(coins)
                       .. "\nTrait Tokens: " .. tostring(tokens),
                    ["inline"] = false
                },
                {
                    ["name"] = "**Send at**",
                    ["value"] = timeSent,
                    ["inline"] = false
                }
            }
        }

        request({
            Url = config.webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = {embed}})
        })
    end

    -- 2. Send Heartbeat Ping (The Dead Man's Switch)
    if config.heartbeat and config.heartbeat ~= "" then
        pcall(function()
            request({
                Url = config.heartbeat,
                Method = "GET"
            })
        end)
    end
end

--// Auto Loop Handler
task.spawn(function()
    while task.wait(1) do
        if config.enabled then
            SendWebhook()
            task.wait(config.delay * 60)
        end
    end
end)

--// Reduce Lag Functions
local function RemoveVFX()
    local rs = game:GetService("ReplicatedStorage")
    local vfx = rs:FindFirstChild("VFX")
    local keep = { ["Summon"] = true }
    if vfx then
        for _, obj in ipairs(vfx:GetChildren()) do
            if not keep[obj.Name] then obj:Destroy() end
        end
    end
    local uiFolder = rs:FindFirstChild("UI")
    if uiFolder then
        local dmg = uiFolder:FindFirstChild("Damage")
        if dmg then dmg:Destroy() end
    end
end

local function RemoveAnimations()
    local rs = game:GetService("ReplicatedStorage")
    local anm = rs:FindFirstChild("Animations")
    if anm then anm:Destroy() end
end

--// GUI SETUP
local ScreenGui = Instance.new("ScreenGui", plr.PlayerGui)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 310) -- Increased Height to fit new box
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

-- 1. Webhook Box
local WebhookBox = Instance.new("TextBox", Frame)
WebhookBox.Size = UDim2.new(1, -20, 0, 30)
WebhookBox.Position = UDim2.new(0, 10, 0, 40)
WebhookBox.PlaceholderText = "Enter Discord Webhook Link"
WebhookBox.Text = config.webhook
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WebhookBox.ClearTextOnFocus = false

-- 2. Heartbeat Box (NEW)
local HeartbeatBox = Instance.new("TextBox", Frame)
HeartbeatBox.Size = UDim2.new(1, -20, 0, 30)
HeartbeatBox.Position = UDim2.new(0, 10, 0, 80)
HeartbeatBox.PlaceholderText = "Enter Healthchecks.io URL"
HeartbeatBox.Text = config.heartbeat or ""
HeartbeatBox.TextColor3 = Color3.new(1,1,1)
HeartbeatBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HeartbeatBox.ClearTextOnFocus = false

-- 3. Delay Box
local DelayBox = Instance.new("TextBox", Frame)
DelayBox.Size = UDim2.new(1, -20, 0, 30)
DelayBox.Position = UDim2.new(0, 10, 0, 120) -- Moved Down
DelayBox.PlaceholderText = "Delay (minutes)"
DelayBox.Text = tostring(config.delay)
DelayBox.TextColor3 = Color3.new(1,1,1)
DelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayBox.ClearTextOnFocus = false

-- 4. Toggle
local Toggle = Instance.new("TextButton", Frame)
Toggle.Size = UDim2.new(1, -20, 0, 30)
Toggle.Position = UDim2.new(0, 10, 0, 160) -- Moved Down
Toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Toggle.TextColor3 = Color3.new(1,1,1)
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextSize = 18
Toggle.Text = config.enabled and "Status: ON" or "Status: OFF"

Toggle.MouseButton1Click:Connect(function()
    config.enabled = not config.enabled
    Toggle.Text = config.enabled and "Status: ON" or "Status: OFF"
    SaveConfig()
end)

-- 5. Anti-AFK Toggle
local AAToggle = Instance.new("TextButton", Frame)
AAToggle.Size = UDim2.new(1, -20, 0, 30)
AAToggle.Position = UDim2.new(0, 10, 0, 200) -- Moved Down
AAToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
AAToggle.TextColor3 = Color3.new(1,1,1)
AAToggle.Font = Enum.Font.SourceSansBold
AAToggle.TextSize = 18
AAToggle.Text = config.antiafk and "Anti-AFK: ON" or "Anti-AFK: OFF"

AAToggle.MouseButton1Click:Connect(function()
    config.antiafk = not config.antiafk
    AAToggle.Text = config.antiafk and "Anti-AFK: ON" or "Anti-AFK: OFF"
    SaveConfig()
end)

-- 6. Tools (VFX/Anim)
local RowFrame = Instance.new("Frame", Frame)
RowFrame.Size = UDim2.new(1, -20, 0, 30)
RowFrame.Position = UDim2.new(0, 10, 0, 240) -- Moved Down
RowFrame.BackgroundTransparency = 1

local VFXBtn = Instance.new("TextButton", RowFrame)
VFXBtn.Size = UDim2.new(0.5, -5, 1, 0)
VFXBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
VFXBtn.TextColor3 = Color3.new(1,1,1)
VFXBtn.Text = "Remove VFX"
VFXBtn.Font = Enum.Font.SourceSansBold
VFXBtn.TextSize = 18
local AnimBtn = Instance.new("TextButton", RowFrame)
AnimBtn.Size = UDim2.new(0.5, -5, 1, 0)
AnimBtn.Position = UDim2.new(0.5, 5, 0, 0)
AnimBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
AnimBtn.TextColor3 = Color3.new(1,1,1)
AnimBtn.Text = "Remove Anim"
AnimBtn.Font = Enum.Font.SourceSansBold
AnimBtn.TextSize = 18

VFXBtn.MouseButton1Click:Connect(function() RemoveVFX() end)
AnimBtn.MouseButton1Click:Connect(function() RemoveAnimations() end)

-- 7. Save Button
local Save = Instance.new("TextButton", Frame)
Save.Size = UDim2.new(1, -20, 0, 30)
Save.Position = UDim2.new(0, 10, 0, 280) -- Moved Down
Save.BackgroundColor3 = Color3.fromRGB(120, 60, 255)
Save.TextColor3 = Color3.new(1,1,1)
Save.Font = Enum.Font.SourceSansBold
Save.TextSize = 18
Save.Text = "Save Config"

Save.MouseButton1Click:Connect(function()
    config.webhook = WebhookBox.Text
    config.heartbeat = HeartbeatBox.Text -- Save new field
    config.delay = tonumber(DelayBox.Text) or 1
    SaveConfig()
end)

-- Minimize Logic
local minimized = config.minimized
local function ApplyMinimizeState()
    if minimized then
        for _, ui in ipairs(Frame:GetChildren()) do
            if ui ~= Title and ui ~= MinBtn then ui.Visible = false end
        end
        Frame.Size = UDim2.new(0, 300, 0, 30)
        MinBtn.Text = "+"
    else
        for _, ui in ipairs(Frame:GetChildren()) do ui.Visible = true end
        Frame.Size = UDim2.new(0, 300, 0, 320) -- Match new height
        MinBtn.Text = "-"
    end
end
ApplyMinimizeState()

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    config.minimized = minimized
    SaveConfig()
    ApplyMinimizeState()
end)
