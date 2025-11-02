-- Script: Script Manager GUI (local client)
-- Mô tả: Dropdown chọn username + TextBox để lưu script cho mỗi username (cấu hình lưu vào file JSON).
-- Lưu ý bảo mật: mã được lưu và thực thi cục bộ bằng loadstring; chỉ làm điều này với code tin tưởng.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local configFileName = "ScriptManagerConfig.json"
local config = {} -- sẽ có cấu trúc: { scripts = { ["PlayerName"] = "<code string>" }, autoRun = true }

-- Helper read/write
local function safeReadConfig()
    local ok, data = pcall(function()
        if isfile and isfile(configFileName) then
            return HttpService:JSONDecode(readfile(configFileName))
        end
        return { scripts = {}, autoRun = true }
    end)
    if ok and type(data) == "table" then
        return data
    else
        return { scripts = {}, autoRun = true }
    end
end

local function safeWriteConfig()
    local ok, err = pcall(function()
        if writefile then
            writefile(configFileName, HttpService:JSONEncode(config))
        end
    end)
    if not ok then warn("Lưu config thất bại:", err) end
end

-- load config on start
config = safeReadConfig()
config.scripts = config.scripts or {}
if config.autoRun == nil then config.autoRun = true end

-- GUI creation (dựa trên style bạn đưa)
repeat task.wait() until game:IsLoaded() and player and player:FindFirstChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptManagerGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainFrame.BorderColor3 = Color3.fromRGB(150, 150, 150)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleLabel.BorderColor3 = Color3.fromRGB(150, 150, 150)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Script Manager"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18

-- Left: Dropdown players
local LeftFrame = Instance.new("Frame")
LeftFrame.Parent = MainFrame
LeftFrame.BackgroundTransparency = 1
LeftFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
LeftFrame.Size = UDim2.new(0.32, 0, 0.76, 0)

local DropLabel = Instance.new("TextLabel")
DropLabel.Parent = LeftFrame
DropLabel.BackgroundTransparency = 1
DropLabel.Size = UDim2.new(1, 0, 0, 20)
DropLabel.Font = Enum.Font.SourceSans
DropLabel.Text = "Chọn player:"
DropLabel.TextSize = 14
DropLabel.TextColor3 = Color3.fromRGB(255,255,255)
DropLabel.TextXAlignment = Enum.TextXAlignment.Left

local DropdownButton = Instance.new("TextButton")
DropdownButton.Parent = LeftFrame
DropdownButton.Position = UDim2.new(0, 0, 0, 26)
DropdownButton.Size = UDim2.new(1, 0, 0, 30)
DropdownButton.Font = Enum.Font.SourceSans
DropdownButton.Text = "Chọn..."
DropdownButton.TextSize = 14
DropdownButton.TextColor3 = Color3.new(1,1,1)
DropdownButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
DropdownButton.AutoButtonColor = true

-- Scrolling list (ẩn/hiện)
local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Parent = LeftFrame
ListFrame.Position = UDim2.new(0, 0, 0, 62)
ListFrame.Size = UDim2.new(1, 0, 1, -62)
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.BackgroundColor3 = Color3.fromRGB(45,45,55)
ListFrame.BorderSizePixel = 0
ListFrame.Visible = false
ListFrame.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ListFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0,4)

-- Right: Script box + controls
local RightFrame = Instance.new("Frame")
RightFrame.Parent = MainFrame
RightFrame.BackgroundTransparency = 1
RightFrame.Position = UDim2.new(0.36, 0, 0.12, 0)
RightFrame.Size = UDim2.new(0.62, 0, 0.76, 0)

local ScriptLabel = Instance.new("TextLabel")
ScriptLabel.Parent = RightFrame
ScriptLabel.BackgroundTransparency = 1
ScriptLabel.Size = UDim2.new(1, 0, 0, 20)
ScriptLabel.Font = Enum.Font.SourceSans
ScriptLabel.Text = "Script cho username (chỉ bạn có thể lưu script cho mình)"
ScriptLabel.TextSize = 14
ScriptLabel.TextColor3 = Color3.fromRGB(255,255,255)
ScriptLabel.TextXAlignment = Enum.TextXAlignment.Left

local ScriptBox = Instance.new("TextBox")
ScriptBox.Parent = RightFrame
ScriptBox.Position = UDim2.new(0, 0, 0, 26)
ScriptBox.Size = UDim2.new(1, 0, 0.78, 0)
ScriptBox.Font = Enum.Font.Code
ScriptBox.Text = "-- Viết script ở đây (lua). Lưu ý: đây là mã cục bộ."
ScriptBox.TextSize = 14
ScriptBox.MultiLine = true
ScriptBox.ClearTextOnFocus = false
ScriptBox.TextWrapped = true
ScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ScriptBox.TextYAlignment = Enum.TextYAlignment.Top
ScriptBox.BackgroundColor3 = Color3.fromRGB(40,40,50)
ScriptBox.BorderColor3 = Color3.fromRGB(120,120,120)
ScriptBox.TextColor3 = Color3.fromRGB(255,255,255)

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Parent = RightFrame
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Position = UDim2.new(0, 0, 0.82, 0)
ButtonsFrame.Size = UDim2.new(1, 0, 0.18, 0)

local SaveButton = Instance.new("TextButton")
SaveButton.Parent = ButtonsFrame
SaveButton.Position = UDim2.new(0, 0, 0, 6)
SaveButton.Size = UDim2.new(0.48, -6, 1, -12)
SaveButton.Font = Enum.Font.SourceSansBold
SaveButton.Text = "Lưu Script"
SaveButton.TextSize = 16
SaveButton.BackgroundColor3 = Color3.fromRGB(50,150,200)
SaveButton.TextColor3 = Color3.new(1,1,1)

local DeleteButton = Instance.new("TextButton")
DeleteButton.Parent = ButtonsFrame
DeleteButton.Position = UDim2.new(0.52, 6, 0, 6)
DeleteButton.Size = UDim2.new(0.48, -6, 1, -12)
DeleteButton.Font = Enum.Font.SourceSansBold
DeleteButton.Text = "Xóa Script"
DeleteButton.TextSize = 16
DeleteButton.BackgroundColor3 = Color3.fromRGB(100,100,100)
DeleteButton.TextColor3 = Color3.new(1,1,1)

-- Status bar
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 8, 0.92, 0)
StatusLabel.Size = UDim2.new(1, -16, 0, 18)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Status: Ready"
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Internal state
local selectedName = nil

-- Populate player list function
local function refreshPlayerList()
    -- clear existing buttons
    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local players = Players:GetPlayers()
    table.sort(players, function(a,b) return a.Name:lower() < b.Name:lower() end)
    for i, pl in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Parent = ListFrame
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.Position = UDim2.new(0, 4, 0, 0)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.Text = pl.Name
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.ZIndex = 5

        btn.MouseButton1Click:Connect(function()
            selectedName = pl.Name
            DropdownButton.Text = selectedName
            ListFrame.Visible = false

            -- load saved script for this username (if có)
            ScriptBox.Text = config.scripts[selectedName] or "-- Không có script đã lưu cho " .. selectedName
            -- enable Save only if local player
            if selectedName == player.Name then
                SaveButton.Active = true
                SaveButton.AutoButtonColor = true
                SaveButton.BackgroundColor3 = Color3.fromRGB(50,150,200)
                StatusLabel.Text = "Status: Chọn bản thân, có thể lưu script."
            else
                SaveButton.Active = false
                SaveButton.AutoButtonColor = false
                SaveButton.BackgroundColor3 = Color3.fromRGB(120,120,120)
                StatusLabel.Text = "Status: Bạn không được phép lưu script cho người khác (chỉ localplayer mới lưu được)."
            end
        end)
    end

    -- update canvas size
    local listHeight = (#players) * 32
    ListFrame.CanvasSize = UDim2.new(0, 0, 0, listHeight)
end

-- Toggle dropdown visibility
DropdownButton.MouseButton1Click:Connect(function()
    ListFrame.Visible = not ListFrame.Visible
    if ListFrame.Visible then
        refreshPlayerList()
    end
end)

-- Save script (only allowed if selected == localplayer)
SaveButton.MouseButton1Click:Connect(function()
    if not selectedName then
        StatusLabel.Text = "Status: Hãy chọn một username để lưu."
        return
    end
    if selectedName ~= player.Name then
        StatusLabel.Text = "Status: Không được phép lưu cho người khác."
        return
    end
    local code = ScriptBox.Text or ""
    config.scripts[selectedName] = tostring(code)
    safeWriteConfig()
    StatusLabel.Text = "Status: Đã lưu script cho " .. selectedName
end)

-- Delete script (allowed for anyone locally) — note: this only deletes local config copy
DeleteButton.MouseButton1Click:Connect(function()
    if not selectedName then
        StatusLabel.Text = "Status: Hãy chọn một username để xóa."
        return
    end
    if config.scripts[selectedName] then
        config.scripts[selectedName] = nil
        safeWriteConfig()
        ScriptBox.Text = "-- Đã xóa script cho " .. selectedName
        StatusLabel.Text = "Status: Đã xóa script (local) cho " .. selectedName
    else
        StatusLabel.Text = "Status: Không có script nào để xóa cho " .. selectedName
    end
end)

-- Allow pressing Enter to save when editing and selected is localplayer
ScriptBox.FocusLost:Connect(function(enter)
    if enter and selectedName == player.Name then
        config.scripts[selectedName] = tostring(ScriptBox.Text or "")
        safeWriteConfig()
        StatusLabel.Text = "Status: Tự động lưu khi rời ô (local) cho " .. selectedName
    end
end)

-- Auto-run: when a player joins (or already present), if there's a saved script for them, run it locally (pcall + loadstring)
local function tryRunScriptFor(playerName)
    if not playerName then return end
    local code = config.scripts[playerName]
    if code and type(code) == "string" and #code > 0 then
        -- WARNING: executing code from config. It's local to this client only.
        local ok, err = pcall(function()
            local f = loadstring(code)
            if f then
                -- run in protected call
                task.spawn(function()
                    local ok2, err2 = pcall(f)
                    if not ok2 then
                        warn("[ScriptManager] Lỗi khi chạy script cho", playerName, ":", err2)
                    else
                        print("[ScriptManager] Đã chạy script cho", playerName)
                    end
                end)
            end
        end)
        if not ok then
            warn("[ScriptManager] Lỗi loadstring cho", playerName, ":", err)
        end
    end
end

-- When script starts, try existing players
for _, pl in ipairs(Players:GetPlayers()) do
    tryRunScriptFor(pl.Name)
end

-- Listen for new players
Players.PlayerAdded:Connect(function(pl)
    -- small delay để character/PlayerGui ổn định nếu script cần
    task.wait(0.2)
    tryRunScriptFor(pl.Name)
    refreshPlayerList()
end)

-- Keep the list updated when someone leaves (so dropdown reflects current players)
Players.PlayerRemoving:Connect(function(pl)
    refreshPlayerList()
end)

-- initial populate
refreshPlayerList()

-- Expose quick save shortcut (Ctrl+S) while GUI focused (optional)
-- Note: Some exploit environments don't forward InputBegan to TextBox; this is best-effort
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if selectedName == player.Name then
            config.scripts[selectedName] = tostring(ScriptBox.Text or "")
            safeWriteConfig()
            StatusLabel.Text = "Status: Lưu nhanh (Ctrl+S) thành công."
        end
    end
end)

-- Final status
StatusLabel.Text = "Status: Ready (Chọn username để xem/ sửa script)."

-- End of Script Manager
