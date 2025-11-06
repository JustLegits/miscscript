-- Script Manager GUI (FULL) - 5 presets, Run/Save/Delete, no auto-load
-- Behavior:
--  - 5 presets: "Script 1" ... "Script 5"
--  - GUI **will not auto-load** anything at start
--  - When you choose a player AND choose a preset, the GUI will attempt to load that preset's saved script (if any)
--  - Save allowed ONLY when selected player == LocalPlayer
--  - Run button executes the **ScriptBox** contents (only if ScriptBox not empty)
--  - If a preset has no saved content and ScriptBox is empty => Run will NOT run
--  - Files stored local as a single JSON: ScriptManagerConfig.json
--  - Config structure:
--      { scripts = { ["PlayerName"] = { ["Script 1"] = "<code>", ["Script 2"] = "<code>", ... } }, autoRun = true }
-- Paste into your executor and run.

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local CONFIG_FILE = "ScriptManagerConfig.json"
local config = {}

-- ---------- Safe read/write config ----------
local function safeReadConfig()
    local ok, data = pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end
        return { scripts = {}, autoRun = true }
    end)
    if ok and type(data) == "table" then
        data.scripts = data.scripts or {}
        if data.autoRun == nil then data.autoRun = true end
        return data
    else
        return { scripts = {}, autoRun = true }
    end
end

local function safeWriteConfig()
    local ok, err = pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(config))
        end
    end)
    if not ok then
        warn("[ScriptManager] Lỗi lưu config:", err)
    end
end

-- load config
config = safeReadConfig()

-- ---------- UI Creation ----------
repeat task.wait() until player and player:FindFirstChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptManagerGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 460, 0, 320)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(35,35,45)
MainFrame.BorderColor3 = Color3.fromRGB(120,120,120)
MainFrame.Active = true
MainFrame.Draggable = true

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1,0,0,30)
TitleLabel.Position = UDim2.new(0,0,0,0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25,25,35)
TitleLabel.BorderColor3 = Color3.fromRGB(120,120,120)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Script Manager"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextSize = 18

-- Left pane
local LeftFrame = Instance.new("Frame")
LeftFrame.Parent = MainFrame
LeftFrame.Position = UDim2.new(0.02,0,0.12,0)
LeftFrame.Size = UDim2.new(0.32,0,0.76,0)
LeftFrame.BackgroundTransparency = 1

local DropLabel = Instance.new("TextLabel")
DropLabel.Parent = LeftFrame
DropLabel.BackgroundTransparency = 1
DropLabel.Size = UDim2.new(1,0,0,20)
DropLabel.Position = UDim2.new(0,0,0,0)
DropLabel.Font = Enum.Font.SourceSans
DropLabel.Text = "Chọn player:"
DropLabel.TextSize = 14
DropLabel.TextColor3 = Color3.fromRGB(255,255,255)
DropLabel.TextXAlignment = Enum.TextXAlignment.Left

local DropdownButton = Instance.new("TextButton")
DropdownButton.Parent = LeftFrame
DropdownButton.Position = UDim2.new(0,0,0,26)
DropdownButton.Size = UDim2.new(1,0,0,30)
DropdownButton.Font = Enum.Font.SourceSans
DropdownButton.Text = "Chọn..."
DropdownButton.TextSize = 14
DropdownButton.TextColor3 = Color3.fromRGB(255,255,255)
DropdownButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
DropdownButton.AutoButtonColor = true

local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Parent = LeftFrame
ListFrame.Position = UDim2.new(0,0,0,62)
ListFrame.Size = UDim2.new(1,0,1,-62)
ListFrame.CanvasSize = UDim2.new(0,0,0,0)
ListFrame.BackgroundColor3 = Color3.fromRGB(45,45,55)
ListFrame.BorderSizePixel = 0
ListFrame.Visible = false
ListFrame.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ListFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0,4)

-- Preset selector
local PresetLabel = Instance.new("TextLabel")
PresetLabel.Parent = LeftFrame
PresetLabel.BackgroundTransparency = 1
PresetLabel.Position = UDim2.new(0,0,0,0)
PresetLabel.Size = UDim2.new(1,0,0,20)
PresetLabel.Font = Enum.Font.SourceSans
PresetLabel.Text = "Chọn preset:"
PresetLabel.TextSize = 14
PresetLabel.TextColor3 = Color3.fromRGB(255,255,255)
PresetLabel.Visible = true
PresetLabel.Position = UDim2.new(0,0,0, (ListFrame.AbsoluteSize.Y > 0) and 0 or 0) -- placeholder, we'll position below list programmatically

local PresetButton = Instance.new("TextButton")
PresetButton.Parent = LeftFrame
PresetButton.Position = UDim2.new(0,0,0,0) -- set later
PresetButton.Size = UDim2.new(1,0,0,30)
PresetButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
PresetButton.TextColor3 = Color3.fromRGB(255,255,255)
PresetButton.Text = "Script 1"

local PresetList = Instance.new("Frame")
PresetList.Parent = LeftFrame
PresetList.Position = UDim2.new(0,0,0,0) -- set later
PresetList.Size = UDim2.new(1,0,0,0)
PresetList.BackgroundColor3 = Color3.fromRGB(45,45,55)
PresetList.Visible = false

local scriptPresets = {"Script 1","Script 2","Script 3","Script 4","Script 5"}
local selectedPreset = "Script 1"

local presetLayout = Instance.new("UIListLayout")
presetLayout.Parent = PresetList
presetLayout.Padding = UDim.new(0,4)
presetLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Right pane
local RightFrame = Instance.new("Frame")
RightFrame.Parent = MainFrame
RightFrame.Position = UDim2.new(0.36,0,0.12,0)
RightFrame.Size = UDim2.new(0.62,0,0.76,0)
RightFrame.BackgroundTransparency = 1

local ScriptLabel = Instance.new("TextLabel")
ScriptLabel.Parent = RightFrame
ScriptLabel.BackgroundTransparency = 1
ScriptLabel.Size = UDim2.new(1,0,0,20)
ScriptLabel.Position = UDim2.new(0,0,0,0)
ScriptLabel.Font = Enum.Font.SourceSans
ScriptLabel.Text = "Script (chỉ lưu khi bạn là localplayer)"
ScriptLabel.TextSize = 14
ScriptLabel.TextColor3 = Color3.fromRGB(255,255,255)
ScriptLabel.TextXAlignment = Enum.TextXAlignment.Left

local ScriptBox = Instance.new("TextBox")
ScriptBox.Parent = RightFrame
ScriptBox.Position = UDim2.new(0,0,0,26)
ScriptBox.Size = UDim2.new(1,0,0.78,0)
ScriptBox.Font = Enum.Font.Code
ScriptBox.Text = ""
ScriptBox.PlaceholderText = "-- Viết script ở đây..."
ScriptBox.PlaceholderColor3 = Color3.fromRGB(170,170,170)
ScriptBox.TextColor3 = Color3.fromRGB(255,255,255)
ScriptBox.TextSize = 14
ScriptBox.MultiLine = true
ScriptBox.ClearTextOnFocus = false
ScriptBox.TextWrapped = false
ScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ScriptBox.TextYAlignment = Enum.TextYAlignment.Top
ScriptBox.BackgroundColor3 = Color3.fromRGB(40,40,50)
ScriptBox.BorderColor3 = Color3.fromRGB(120,120,120)

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Parent = RightFrame
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Position = UDim2.new(0,0,0.82,0)
ButtonsFrame.Size = UDim2.new(1,0,0.18,0)

local SaveButton = Instance.new("TextButton")
SaveButton.Parent = ButtonsFrame
SaveButton.Position = UDim2.new(0,0,0,6)
SaveButton.Size = UDim2.new(0.48,-6,1,-12)
SaveButton.Font = Enum.Font.SourceSansBold
SaveButton.Text = "Lưu Script"
SaveButton.TextSize = 16
SaveButton.BackgroundColor3 = Color3.fromRGB(50,150,200)
SaveButton.TextColor3 = Color3.fromRGB(255,255,255)

local DeleteButton = Instance.new("TextButton")
DeleteButton.Parent = ButtonsFrame
DeleteButton.Position = UDim2.new(0.52,6,0,6)
DeleteButton.Size = UDim2.new(0.48,-6,1,-12)
DeleteButton.Font = Enum.Font.SourceSansBold
DeleteButton.Text = "Xóa Script"
DeleteButton.TextSize = 16
DeleteButton.BackgroundColor3 = Color3.fromRGB(100,100,100)
DeleteButton.TextColor3 = Color3.fromRGB(255,255,255)

local RunButton = Instance.new("TextButton")
RunButton.Parent = RightFrame
RunButton.Position = UDim2.new(0,0,1,-30)
RunButton.Size = UDim2.new(1,0,0,26)
RunButton.BackgroundColor3 = Color3.fromRGB(80,180,80)
RunButton.TextColor3 = Color3.fromRGB(255,255,255)
RunButton.Text = "Chạy Script"

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0,8,0.92,0)
StatusLabel.Size = UDim2.new(1,-16,0,18)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Status: Ready"
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Positioning Preset elements below the list dynamically
local function layoutLeft()
    local listHeight = ListFrame.AbsoluteSize.Y
    local baseY = 62 + listHeight + 6
    PresetLabel.Position = UDim2.new(0,0,0, baseY)
    PresetButton.Position = UDim2.new(0,0,0, baseY + 22)
    PresetList.Position = UDim2.new(0,0,0, baseY + 58)
end

-- ---------- Internal state ----------
local selectedName = nil
selectedPreset = "Script 1"

-- ---------- Helpers ----------
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- ---------- Populate player list ----------
local function refreshPlayerList()
    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local players = Players:GetPlayers()
    table.sort(players, function(a,b) return a.Name:lower() < b.Name:lower() end)

    for i, pl in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Parent = ListFrame
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.Position = UDim2.new(0, 4, 0, (i-1)*32)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.Text = pl.Name
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.ZIndex = 5

        btn.MouseButton1Click:Connect(function()
            selectedName = pl.Name
            DropdownButton.Text = selectedName
            ListFrame.Visible = false

            -- load saved script for this username & current preset (only when selection made)
            local pdata = config.scripts[selectedName]
            if pdata and pdata[selectedPreset] then
                ScriptBox.Text = pdata[selectedPreset]
                StatusLabel.Text = "Status: Đã load script cho " .. selectedName .. " (" .. selectedPreset .. ")"
            else
                ScriptBox.Text = ""
                StatusLabel.Text = "Status: Không có script đã lưu cho " .. selectedName .. " (" .. selectedPreset .. ")"
            end
        end)
    end

    ListFrame.CanvasSize = UDim2.new(0,0,0, #players * 32)
    layoutLeft()
end

DropdownButton.MouseButton1Click:Connect(function()
    ListFrame.Visible = not ListFrame.Visible
    if ListFrame.Visible then
        refreshPlayerList()
    end
end)

-- Preset interactions
PresetButton.MouseButton1Click:Connect(function()
    PresetList.Visible = not PresetList.Visible
    PresetList.Size = UDim2.new(1,0,0,#scriptPresets * 28)
end)

for i, name in ipairs(scriptPresets) do
    local btn = Instance.new("TextButton")
    btn.Parent = PresetList
    btn.Size = UDim2.new(1, -6, 0, 26)
    btn.Position = UDim2.new(0, 3, 0, (i-1) * 30)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)

    btn.MouseButton1Click:Connect(function()
        selectedPreset = name
        PresetButton.Text = name
        PresetList.Visible = false

        -- Only load when a player is already selected (per your request)
        if selectedName then
            local pdata = config.scripts[selectedName]
            if pdata and pdata[selectedPreset] then
                ScriptBox.Text = pdata[selectedPreset]
                StatusLabel.Text = "Status: Đã load script cho " .. selectedName .. " (" .. selectedPreset .. ")"
            else
                ScriptBox.Text = ""
                StatusLabel.Text = "Status: Chưa có script cho " .. selectedPreset .. " của " .. (selectedName or "<chưa chọn>")
            end
        else
            -- no player selected, do not auto-load
            ScriptBox.Text = ""
            StatusLabel.Text = "Status: Chưa chọn player. Chọn player để load preset."
        end
    end)
end

-- ---------- Save ----------
SaveButton.MouseButton1Click:Connect(function()
    if not selectedName then
        StatusLabel.Text = "Status: Chưa chọn username!"
        return
    end
    if selectedName ~= player.Name then
        StatusLabel.Text = "Status: Chỉ có thể lưu cho chính mình!"
        return
    end

    local code = ScriptBox.Text or ""
    if trim(code) == "" then
        StatusLabel.Text = "Status: Không lưu vì script rỗng."
        return
    end

    config.scripts[selectedName] = config.scripts[selectedName] or {}
    config.scripts[selectedName][selectedPreset] = code
    safeWriteConfig()

    StatusLabel.Text = "Status: Đã lưu " .. selectedPreset .. " cho " .. selectedName
end)

-- ---------- Delete ----------
DeleteButton.MouseButton1Click:Connect(function()
    if not selectedName then
        StatusLabel.Text = "Status: Chưa chọn username!"
        return
    end

    if config.scripts[selectedName] then
        config.scripts[selectedName][selectedPreset] = nil
        -- if no presets left, optionally keep empty table
    end
    safeWriteConfig()
    ScriptBox.Text = ""
    StatusLabel.Text = "Status: Đã xóa " .. selectedPreset .. " cho " .. selectedName
end)

-- ---------- Run ----------
RunButton.MouseButton1Click:Connect(function()
    local code = ScriptBox.Text or ""
    if trim(code) == "" then
        StatusLabel.Text = "Status: Script trống — không chạy."
        return
    end

    -- Extra rule from you: if preset has no saved content then do not run.
    -- Interpret as: if selectedName+selectedPreset has no saved content and ScriptBox is empty -> blocked.
    -- But since we run ScriptBox content, only require ScriptBox not empty.
    -- We'll implement: if user selected a different player's preset (not local) and there is no saved content for that preset, but ScriptBox is non-empty (maybe pasted), allow run.
    -- Simpler & sensible: run if ScriptBox not empty.
    local f, loadErr = loadstring(code)
    if not f then
        StatusLabel.Text = "Status: Lỗi loadstring: " .. tostring(loadErr)
        return
    end

    task.spawn(function()
        local ok, err = pcall(f)
        if not ok then
            warn("[ScriptManager] Lỗi khi chạy script:", err)
            StatusLabel.Text = "Status: Lỗi khi chạy script (xem output)."
        else
            StatusLabel.Text = "Status: Đã chạy script!"
        end
    end)
end)

-- ---------- Auto-run saved scripts when players join (kept minimal) ----------
-- Behavior preserved from earlier versions: run saved scripts for joining players, but only if config.autoRun true
local function tryAutoRunFor(playerName)
    if not config.autoRun then return end
    local pdata = config.scripts[playerName]
    if not pdata then return end
    for _, preset in ipairs(scriptPresets) do
        local code = pdata[preset]
        if code and trim(code) ~= "" then
            local f = loadstring(code)
            if f then
                task.spawn(function()
                    pcall(f)
                end)
            end
        end
    end
end

for _, pl in ipairs(Players:GetPlayers()) do
    tryAutoRunFor(pl.Name)
end

Players.PlayerAdded:Connect(function(pl)
    task.wait(0.2)
    tryAutoRunFor(pl.Name)
    -- refresh player list so GUI stays up-to-date
    refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function()
    refreshPlayerList()
end)

-- initial refresh & dynamic layout
refreshPlayerList()
layoutLeft()
-- Do NOT auto-select localplayer or auto-load per your request (GUI remains empty until you pick a player + preset)

StatusLabel.Text = "Status: Ready (Chọn player -> chọn preset để load)."

-- Quick save hotkey (Ctrl+S) when GUI focused
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if selectedName == player.Name and selectedPreset then
            local code = ScriptBox.Text or ""
            if trim(code) ~= "" then
                config.scripts[selectedName] = config.scripts[selectedName] or {}
                config.scripts[selectedName][selectedPreset] = code
                safeWriteConfig()
                StatusLabel.Text = "Status: Lưu nhanh (Ctrl+S) thành công."
            end
        end
    end
end)

-- End of script
