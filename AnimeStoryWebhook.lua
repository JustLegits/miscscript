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

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Config / storage
local CONFIG_FILE = "webhook_config.txt" -- JSON: { webhook = "...", minutes = 5, running = true/false }

-- Helper: safe request function (works with many executors)
local function http_post_json(url, data_table)
    local body = HttpService:JSONEncode(data_table)
    local headers = {
        ["Content-Type"] = "application/json"
    }

    local req = nil
    if syn and syn.request then
        req = syn.request({Url = url, Method = "POST", Headers = headers, Body = body})
        return req
    elseif request then
        req = request({Url = url, Method = "POST", Headers = headers, Body = body})
        return req
    elseif http_request then
        req = http_request({Url = url, Method = "POST", Headers = headers, Body = body})
        return req
    else
        error("No supported http request function found (syn.request / request / http_request).")
    end
end

-- Build message content (with spoiler for name)
local function build_content()
    local success, level = pcall(function()
        return tostring(LocalPlayer:WaitForChild("leaderstats"):FindFirstChild("Level").Value)
    end)
    if not success or not level then
        level = "N/A"
    end

    local gems = "N/A"
    pcall(function()
        local data = LocalPlayer:FindFirstChild("Data")
        if data and data:FindFirstChild("Gems") then
            gems = tostring(data.Gems.Value)
        end
    end)

    local coins = "N/A"
    pcall(function()
        local data = LocalPlayer:FindFirstChild("Data")
        if data and data:FindFirstChild("Coins") then
            coins = tostring(data.Coins.Value)
        end
    end)

    local name_spoiler = "||" .. tostring(LocalPlayer.Name) .. "||"

    local content = string.format("%s\nPlayer Level: %s\nTotal Gems: %s\nTotal Coins: %s",
        name_spoiler, level, gems, coins)

    return content
end

local function send_to_webhook(webhook_url)
    if not webhook_url or webhook_url == "" then
        return false, "Webhook URL empty."
    end
    local content = build_content()
    local ok, res = pcall(function()
        return http_post_json(webhook_url, { content = content })
    end)
    if not ok then
        return false, ("Request failed: %s"):format(tostring(res))
    end
    if type(res) == "table" and (res.Success == true or res.StatusCode == 204 or res.StatusCode == 200) then
        return true, res
    end
    return true, res
end

-- Simple file save/load
local function save_config(cfg)
    local ok, err = pcall(function()
        local raw = HttpService:JSONEncode(cfg)
        if writefile then
            writefile(CONFIG_FILE, raw)
        else
            error("writefile not available in this executor")
        end
    end)
    return ok, err
end

local function load_config()
    local ok, val = pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local raw = readfile(CONFIG_FILE)
            return HttpService:JSONDecode(raw)
        end
        return nil
    end)
    if ok then
        return val
    end
    return nil
end

-- GUI creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WebhookSenderGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 360, 0, 200)
Frame.Position = UDim2.new(0.5, -180, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundTransparency = 1
Title.Text = "Discord Webhook Sender"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

local webhookLabel = Instance.new("TextLabel")
webhookLabel.Size = UDim2.new(1, -16, 0, 18)
webhookLabel.Position = UDim2.new(0, 8, 0, 36)
webhookLabel.BackgroundTransparency = 1
webhookLabel.Text = "Webhook URL:"
webhookLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookLabel.TextColor3 = Color3.new(1,1,1)
webhookLabel.Font = Enum.Font.SourceSans
webhookLabel.TextSize = 14
webhookLabel.Parent = Frame

local webhookBox = Instance.new("TextBox")
webhookBox.Size = UDim2.new(1, -16, 0, 28)
webhookBox.Position = UDim2.new(0, 8, 0, 56)
webhookBox.PlaceholderText = "https://discord.com/api/webhooks/..."
webhookBox.ClearTextOnFocus = false
webhookBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
webhookBox.TextColor3 = Color3.new(1,1,1)
webhookBox.Text = ""
webhookBox.Font = Enum.Font.SourceSans
webhookBox.TextSize = 14
webhookBox.Parent = Frame

local minutesLabel = Instance.new("TextLabel")
minutesLabel.Size = UDim2.new(0.5, -12, 0, 18)
minutesLabel.Position = UDim2.new(0, 8, 0, 92)
minutesLabel.BackgroundTransparency = 1
minutesLabel.Text = "Minutes delay:"
minutesLabel.TextXAlignment = Enum.TextXAlignment.Left
minutesLabel.TextColor3 = Color3.new(1,1,1)
minutesLabel.Font = Enum.Font.SourceSans
minutesLabel.TextSize = 14
minutesLabel.Parent = Frame

local minutesBox = Instance.new("TextBox")
minutesBox.Size = UDim2.new(0.5, -12, 0, 28)
minutesBox.Position = UDim2.new(0, 8, 0, 112)
minutesBox.PlaceholderText = "e.g. 5"
minutesBox.ClearTextOnFocus = false
minutesBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
minutesBox.TextColor3 = Color3.new(1,1,1)
minutesBox.Text = "5"
minutesBox.Font = Enum.Font.SourceSans
minutesBox.TextSize = 14
minutesBox.Parent = Frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.5, -12, 0, 28)
toggleBtn.Position = UDim2.new(0.5, 4, 0, 112)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Text = "Toggle: OFF"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 14
toggleBtn.Parent = Frame

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.5, -12, 0, 28)
saveBtn.Position = UDim2.new(0, 8, 0, 150)
saveBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.Text = "Save Config"
saveBtn.Font = Enum.Font.SourceSans
saveBtn.TextSize = 14
saveBtn.Parent = Frame

local sendNowBtn = Instance.new("TextButton")
sendNowBtn.Size = UDim2.new(0.5, -12, 0, 28)
sendNowBtn.Position = UDim2.new(0.5, 4, 0, 150)
sendNowBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
sendNowBtn.TextColor3 = Color3.new(1,1,1)
sendNowBtn.Text = "Send Now"
sendNowBtn.Font = Enum.Font.SourceSans
sendNowBtn.TextSize = 14
sendNowBtn.Parent = Frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 16)
statusLabel.Position = UDim2.new(0, 8, 0, 184)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 12
statusLabel.Parent = Frame

-- Load saved config
local running = false
local saved = load_config()
if saved then
    if saved.webhook then webhookBox.Text = tostring(saved.webhook) end
    if saved.minutes then minutesBox.Text = tostring(saved.minutes) end
    if saved.running ~= nil then
        running = saved.running
        toggleBtn.Text = "Toggle: " .. (running and "ON" or "OFF")
        statusLabel.Text = running and "Status: Running" or "Status: Paused"
    end
end

local function update_status(txt)
    pcall(function() statusLabel.Text = "Status: " .. txt end)
end

-- Toggle handler (auto-save)
toggleBtn.MouseButton1Click:Connect(function()
    running = not running
    toggleBtn.Text = "Toggle: " .. (running and "ON" or "OFF")
    update_status(running and "Running" or "Paused")
    local cfg = {
        webhook = webhookBox.Text,
        minutes = tonumber(minutesBox.Text) or 0,
        running = running
    }
    pcall(function() save_config(cfg) end)
end)

-- Save config button
saveBtn.MouseButton1Click:Connect(function()
    local cfg = {
        webhook = webhookBox.Text,
        minutes = tonumber(minutesBox.Text) or 0,
        running = running
    }
    local ok, err = save_config(cfg)
    if ok then
        update_status("Config saved.")
    else
        update_status("Save failed: " .. tostring(err))
    end
end)

-- Send now button
sendNowBtn.MouseButton1Click:Connect(function()
    local url = webhookBox.Text
    update_status("Sending now...")
    local ok, res = send_to_webhook(url)
    if ok then
        update_status("Sent successfully.")
    else
        update_status("Send failed: " .. tostring(res))
    end
end)

-- Background loop
spawn(function()
    while true do
        if running then
            local url = webhookBox.Text
            local minutes = tonumber(minutesBox.Text) or 0
            if not url or url == "" then
                update_status("No webhook set.")
            else
                update_status("Sending...")
                local ok, res = send_to_webhook(url)
                if ok then
                    update_status("Last send: OK at " .. os.date("%X"))
                else
                    update_status("Last send: Failed - " .. tostring(res))
                end
            end
            local wait_seconds = (minutes > 0) and (minutes * 60) or 60
            local elapsed = 0
            while elapsed < wait_seconds do
                if not running then break end
                wait(1)
                elapsed = elapsed + 1
            end
        else
            wait(0.5)
        end
    end
end)

update_status("Ready. Set webhook and minutes, then Toggle ON.")

--// Reduce Lag
local rs = game:GetService("ReplicatedStorage")

-- Delete VFX folder
local vfx = rs:FindFirstChild("VFX")
if vfx then
    vfx:Destroy()
end

-- Delete UI folder
local ui = rs:FindFirstChild("UI")
if ui then
    ui:Destroy()
end

--// Anti‑AFK Script

local vu = game:GetService("VirtualUser")
local plr = game:GetService("Players").LocalPlayer

plr.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--// Anti lag

_G.Settings = {
    Players = {
        ["Ignore Me"] = true,
        ["Ignore Others"] = true,
        ["Ignore Tools"] = true
    },
    Meshes = {
        NoMesh = false,
        NoTexture = false,
        Destroy = false
    },
    Images = {
        Invisible = true,
        Destroy = false
    },
    Explosions = {
        Smaller = true,
        Invisible = true, -- Not recommended for PVP games
        Destroy = true-- Not recommended for PVP games
    },
    Particles = {
        Invisible = true,
        Destroy = true
    },
    TextLabels = {
        LowerQuality = false,
        Invisible = false,
        Destroy = false
    },
    MeshParts = {
        LowerQuality = true,
        Invisible = false,
        NoTexture = false,
        NoMesh = false,
        Destroy = false
    },
    Other = {
        ["FPS Cap"] = false, -- Set this true to uncap FPS
        ["No Camera Effects"] = true,
        ["No Clothes"] = true,
        ["Low Water Graphics"] = true,
        ["No Shadows"] = true,
        ["Low Rendering"] = true,
        ["Low Quality Parts"] = true,
        ["Low Quality Models"] = true,
        ["Reset Materials"] = true,
        ["Lower Quality MeshParts"] = true,
        ClearNilInstances = false -- NEW (EXPERIMENTAL)
    }
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()
