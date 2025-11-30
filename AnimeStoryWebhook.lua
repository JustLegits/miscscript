-- Roblox Discord Webhook Sender (Delta / common executors)
-- Features: movable GUI, webhook input, minutes delay, toggle on/off (saved), save config, send now
-- Sends:
--   1) Player Name in Discord spoiler tags (||Name||)
--   2) Player Level (leaderstats.Level)
--   3) Total Gems (LocalPlayer.Data.Gems)
--   4) Total Coins (LocalPlayer.Data.Coins)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

wait(math.random())

--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

--// Config Save
local configFile = "webhook_config.json"
local config = {
    webhook = "",
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
    if config.webhook == "" then return end

    local leaderstats = plr:FindFirstChild("leaderstats")
    local data = plr:FindFirstChild("Data")

    local level = leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or "N/A"
    local gems = data and data:FindFirstChild("Gems") and data.Gems.Value or "N/A"
    local coins = data and data:FindFirstChild("Coins") and data.Coins.Value or "N/A"

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
                ["value"] = "Gems: " .. tostring(gems) .. "\nGolds: " .. tostring(coins),
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

--// Auto Loop Handler
task.spawn(function()
    while task.wait(1) do
        if config.enabled then
            SendWebhook()
            task.wait(config.delay * 60)
        end
    end
end)

--// Reduce Lag: VFX Remover
local function RemoveVFX()
    local rs = game:GetService("ReplicatedStorage")
    local vfx = rs:FindFirstChild("VFX")

    local keep = {
        ["Summon"] = true,
        -- you can add more here
    }

    if vfx then
        for _, obj in ipairs(vfx:GetChildren()) do
            if not keep[obj.Name] then
                obj:Destroy()
            end
        end
    end
end
-- Remove damage text
    local uiFolder = rs:FindFirstChild("UI")
    if uiFolder then
        local dmg = uiFolder:FindFirstChild("Damage")
        if dmg then
            dmg:Destroy()
        end
    end
end
--// Reduce Lag: Animation Folder Remover
local function RemoveAnimations()
    local rs = game:GetService("ReplicatedStorage")
    local anm = rs:FindFirstChild("Animations")

    if anm then
        anm:Destroy()
    end
end

--// GUI
local ScreenGui = Instance.new("ScreenGui", plr.PlayerGui)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 230)
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

-- Minimize Button
local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 24

-- Webhook Box
local WebhookBox = Instance.new("TextBox", Frame)
WebhookBox.Size = UDim2.new(1, -20, 0, 30)
WebhookBox.Position = UDim2.new(0, 10, 0, 40)
WebhookBox.PlaceholderText = "Enter Webhook Link"
WebhookBox.Text = config.webhook
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WebhookBox.ClearTextOnFocus = false
WebhookBox.TextWrapped = false
WebhookBox.MultiLine = false

-- Delay Box
local DelayBox = Instance.new("TextBox", Frame)
DelayBox.Size = UDim2.new(1, -20, 0, 30)
DelayBox.Position = UDim2.new(0, 10, 0, 80)
DelayBox.PlaceholderText = "Delay (minutes)"
DelayBox.Text = tostring(config.delay)
DelayBox.TextColor3 = Color3.new(1,1,1)
DelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayBox.ClearTextOnFocus = false
DelayBox.TextWrapped = false
DelayBox.MultiLine = false

-- Toggle
local Toggle = Instance.new("TextButton", Frame)
Toggle.Size = UDim2.new(1, -20, 0, 30)
Toggle.Position = UDim2.new(0, 10, 0, 120)
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

-- Anti-AFK Toggle
local AAToggle = Instance.new("TextButton", Frame)
AAToggle.Size = UDim2.new(1, -20, 0, 30)
AAToggle.Position = UDim2.new(0, 10, 0, 160)
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

-- Row Frame to hold two buttons
local RowFrame = Instance.new("Frame", Frame)
RowFrame.Size = UDim2.new(1, -20, 0, 30)
RowFrame.Position = UDim2.new(0, 10, 0, 200)  -- Adjust if Save Button is using this space
RowFrame.BackgroundTransparency = 1

-- VFX Button
local VFXBtn = Instance.new("TextButton", RowFrame)
VFXBtn.Size = UDim2.new(0.5, -5, 1, 0)
VFXBtn.Position = UDim2.new(0, 0, 0, 0)
VFXBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
VFXBtn.TextColor3 = Color3.new(1,1,1)
VFXBtn.Text = "Remove VFX"
VFXBtn.Font = Enum.Font.SourceSansBold
VFXBtn.TextSize = 18
-- Anim Button
local AnimBtn = Instance.new("TextButton", RowFrame)
AnimBtn.Size = UDim2.new(0.5, -5, 1, 0)
AnimBtn.Position = UDim2.new(0.5, 5, 0, 0)
AnimBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
AnimBtn.TextColor3 = Color3.new(1,1,1)
AnimBtn.Text = "Remove Anim"
AnimBtn.Font = Enum.Font.SourceSansBold
AnimBtn.TextSize = 18
-- Connect Actions
VFXBtn.MouseButton1Click:Connect(function()
    RemoveVFX()
end)
AnimBtn.MouseButton1Click:Connect(function()
    RemoveAnimations()
end)

-- Save Button
local Save = Instance.new("TextButton", Frame)
Save.Size = UDim2.new(1, -20, 0, 30)
Save.Position = UDim2.new(0, 10, 0, 240)
Save.BackgroundColor3 = Color3.fromRGB(120, 60, 255)
Save.TextColor3 = Color3.new(1,1,1)
Save.Font = Enum.Font.SourceSansBold
Save.TextSize = 18
Save.Text = "Save Config"

Save.MouseButton1Click:Connect(function()
    config.webhook = WebhookBox.Text
    config.delay = tonumber(DelayBox.Text) or 1
    SaveConfig()
end)

-- Minimized
local minimized = config.minimized

local function ApplyMinimizeState()
    if minimized then
        for _, ui in ipairs(Frame:GetChildren()) do
            if ui ~= Title and ui ~= MinBtn then
                ui.Visible = false
            end
        end

        Frame.Size = UDim2.new(0, 300, 0, 30)
        MinBtn.Text = "+"
    else
        for _, ui in ipairs(Frame:GetChildren()) do
            ui.Visible = true
        end

        Frame.Size = UDim2.new(0, 300, 0, 230)
        MinBtn.Text = "-"
    end
end
-- Apply state on load
ApplyMinimizeState()

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    config.minimized = minimized
    SaveConfig()
    ApplyMinimizeState()
end)

