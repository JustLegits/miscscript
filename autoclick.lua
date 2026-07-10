--[[
    ╔══════════════════════════════════════════╗
    ║         DELTA AUTO CLICKER v1.0          ║
    ║   Cycle-Click | GUI | Keybind | Markers  ║
    ╚══════════════════════════════════════════╝
    Keybind : Right Alt  → Toggle auto-click
    GUI     : Draggable, hideable
    Circles : Draggable numbered markers (only when OFF)
]]

-- ── Services ────────────────────────────────────────────────────────────────
local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── State ───────────────────────────────────────────────────────────────────
local isRunning      = false
local clickSpeed     = 0.1        -- seconds between clicks (default 10 cps)
local clickIndex     = 1          -- which circle to click next
local lastClickTime  = 0
local circles        = {}         -- { frame=Frame, label=TextLabel, pos={X,Y} }
local circleCount    = 0

-- ── ScreenGui ───────────────────────────────────────────────────────────────
local ScreenGui       = Instance.new("ScreenGui")
ScreenGui.Name        = "DeltaAutoClicker"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent      = PlayerGui

-- ── Main GUI Panel ───────────────────────────────────────────────────────────
local Panel = Instance.new("Frame")
Panel.Name             = "Panel"
Panel.Size             = UDim2.new(0, 260, 0, 210)
Panel.Position         = UDim2.new(0, 40, 0, 40)
Panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Panel.BorderSizePixel  = 0
Panel.Active           = true
Panel.Parent           = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 10)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color     = Color3.fromRGB(90, 90, 200)
PanelStroke.Thickness = 1.5
PanelStroke.Parent    = Panel

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Panel

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Fix bottom corners of title bar
local TitleFix = Instance.new("Frame")
TitleFix.Size             = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position         = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
TitleFix.BorderSizePixel  = 0
TitleFix.Parent           = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text            = "⚡ Delta Auto Clicker"
TitleLabel.Size            = UDim2.new(1, -40, 1, 0)
TitleLabel.Position        = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3      = Color3.fromRGB(200, 200, 255)
TitleLabel.TextSize        = 14
TitleLabel.Font            = Enum.Font.GothamBold
TitleLabel.TextXAlignment  = Enum.TextXAlignment.Left
TitleLabel.Parent          = TitleBar

-- Hide/Show button
local HideBtn = Instance.new("TextButton")
HideBtn.Text              = "−"
HideBtn.Size              = UDim2.new(0, 28, 0, 22)
HideBtn.Position          = UDim2.new(1, -32, 0, 7)
HideBtn.BackgroundColor3  = Color3.fromRGB(60, 60, 100)
HideBtn.TextColor3        = Color3.fromRGB(220, 220, 255)
HideBtn.TextSize          = 18
HideBtn.Font              = Enum.Font.GothamBold
HideBtn.BorderSizePixel   = 0
HideBtn.Parent            = TitleBar

local HideBtnCorner = Instance.new("UICorner")
HideBtnCorner.CornerRadius = UDim.new(0, 5)
HideBtnCorner.Parent = HideBtn

-- Content frame (everything below title bar)
local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Size             = UDim2.new(1, 0, 1, -36)
Content.Position         = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Parent           = Panel

-- ── Speed Input ──────────────────────────────────────────────────────────────
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Text           = "Click Speed (per sec)"
SpeedLabel.Size           = UDim2.new(1, -20, 0, 18)
SpeedLabel.Position       = UDim2.new(0, 10, 0, 8)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3     = Color3.fromRGB(170, 170, 210)
SpeedLabel.TextSize       = 12
SpeedLabel.Font           = Enum.Font.Gotham
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent         = Content

local SpeedBox = Instance.new("TextBox")
SpeedBox.Text             = "10"
SpeedBox.Size             = UDim2.new(1, -20, 0, 30)
SpeedBox.Position         = UDim2.new(0, 10, 0, 28)
SpeedBox.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
SpeedBox.TextColor3       = Color3.fromRGB(220, 220, 255)
SpeedBox.TextSize         = 14
SpeedBox.Font             = Enum.Font.GothamMedium
SpeedBox.PlaceholderText  = "e.g. 10"
SpeedBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 140)
SpeedBox.BorderSizePixel  = 0
SpeedBox.ClearTextOnFocus = false
SpeedBox.Parent           = Content

local SpeedBoxCorner = Instance.new("UICorner")
SpeedBoxCorner.CornerRadius = UDim.new(0, 6)
SpeedBoxCorner.Parent = SpeedBox

local SpeedBoxStroke = Instance.new("UIStroke")
SpeedBoxStroke.Color     = Color3.fromRGB(80, 80, 160)
SpeedBoxStroke.Thickness = 1
SpeedBoxStroke.Parent    = SpeedBox

-- Keybind label
local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Text           = "Keybind: Right Alt"
KeybindLabel.Size           = UDim2.new(1, -20, 0, 18)
KeybindLabel.Position       = UDim2.new(0, 10, 0, 68)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.TextColor3     = Color3.fromRGB(130, 130, 180)
KeybindLabel.TextSize       = 11
KeybindLabel.Font           = Enum.Font.Gotham
KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
KeybindLabel.Parent         = Content

-- Toggle button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Text             = "▶  Start Auto Click"
ToggleBtn.Size             = UDim2.new(1, -20, 0, 36)
ToggleBtn.Position         = UDim2.new(0, 10, 0, 90)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
ToggleBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize         = 14
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Parent           = Content

local ToggleBtnCorner = Instance.new("UICorner")
ToggleBtnCorner.CornerRadius = UDim.new(0, 8)
ToggleBtnCorner.Parent = ToggleBtn

-- Add Circle button
local AddCircleBtn = Instance.new("TextButton")
AddCircleBtn.Text             = "+ Add Click Point"
AddCircleBtn.Size             = UDim2.new(1, -20, 0, 30)
AddCircleBtn.Position         = UDim2.new(0, 10, 0, 134)
AddCircleBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 180)
AddCircleBtn.TextColor3       = Color3.fromRGB(220, 220, 255)
AddCircleBtn.TextSize         = 13
AddCircleBtn.Font             = Enum.Font.GothamMedium
AddCircleBtn.BorderSizePixel  = 0
AddCircleBtn.Parent           = Content

local AddCircleBtnCorner = Instance.new("UICorner")
AddCircleBtnCorner.CornerRadius = UDim.new(0, 7)
AddCircleBtnCorner.Parent = AddCircleBtn

-- Remove Last Circle button
local RemoveCircleBtn = Instance.new("TextButton")
RemoveCircleBtn.Text             = "− Remove Last"
RemoveCircleBtn.Size             = UDim2.new(1, -20, 0, 30)
RemoveCircleBtn.Position         = UDim2.new(0, 10, 0, 170)
RemoveCircleBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 60)
RemoveCircleBtn.TextColor3       = Color3.fromRGB(255, 210, 210)
RemoveCircleBtn.TextSize         = 13
RemoveCircleBtn.Font             = Enum.Font.GothamMedium
RemoveCircleBtn.BorderSizePixel  = 0
RemoveCircleBtn.Parent           = Content

local RemoveCircleBtnCorner = Instance.new("UICorner")
RemoveCircleBtnCorner.CornerRadius = UDim.new(0, 7)
RemoveCircleBtnCorner.Parent = RemoveCircleBtn

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function parseSpeed(txt)
    local n = tonumber(txt)
    if n and n > 0 then
        return 1 / n      -- convert CPS → interval seconds
    end
    return 0.1            -- fallback 10 cps
end

local function updateToggleUI()
    if isRunning then
        ToggleBtn.Text             = "⏹  Stop Auto Click"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    else
        ToggleBtn.Text             = "▶  Start Auto Click"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
    end
    -- Lock/unlock circle dragging
    for _, c in ipairs(circles) do
        c.frame.Active = not isRunning
    end
end

local function setRunning(val)
    isRunning = val
    if isRunning then
        clickSpeed = parseSpeed(SpeedBox.Text)
        clickIndex = 1
        lastClickTime = 0
    end
    updateToggleUI()
end

-- ── Circle Marker Factory ────────────────────────────────────────────────────
local CIRCLE_SIZE = 36

local function makeCircle(number, startX, startY)
    local frame = Instance.new("Frame")
    frame.Name             = "ClickCircle_" .. number
    frame.Size             = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE)
    frame.Position         = UDim2.new(0, startX, 0, startY)
    frame.BackgroundColor3 = Color3.fromRGB(90, 90, 220)
    frame.BorderSizePixel  = 0
    frame.Active           = true     -- allows drag when not running
    frame.ZIndex           = 5
    frame.Parent           = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)   -- perfect circle
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(180, 180, 255)
    stroke.Thickness = 2
    stroke.Parent    = frame

    local label = Instance.new("TextLabel")
    label.Text            = tostring(number)
    label.Size            = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3      = Color3.fromRGB(255, 255, 255)
    label.TextSize        = 14
    label.Font            = Enum.Font.GothamBold
    label.ZIndex          = 6
    label.Parent          = frame

    -- Drag logic
    local dragging, dragStart, frameStart = false, nil, nil

    frame.InputBegan:Connect(function(input)
        if isRunning then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            dragStart  = Vector2.new(input.Position.X, input.Position.Y)
            frameStart = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            frame.Position = UDim2.new(0, frameStart.X + delta.X, 0, frameStart.Y + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local entry = { frame = frame, label = label }
    table.insert(circles, entry)
    return entry
end

-- ── Panel Drag ───────────────────────────────────────────────────────────────
do
    local dragging, dragStart, panelStart = false, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            dragStart  = Vector2.new(input.Position.X, input.Position.Y)
            panelStart = Vector2.new(Panel.Position.X.Offset, Panel.Position.Y.Offset)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            Panel.Position = UDim2.new(0, panelStart.X + delta.X, 0, panelStart.Y + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Hide / Show ──────────────────────────────────────────────────────────────
local isHidden = false
HideBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    Content.Visible = not isHidden
    if isHidden then
        Panel.Size  = UDim2.new(0, 260, 0, 36)
        HideBtn.Text = "+"
    else
        Panel.Size  = UDim2.new(0, 260, 0, 210)
        HideBtn.Text = "−"
    end
end)

-- ── Add / Remove Circle Buttons ──────────────────────────────────────────────
AddCircleBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    circleCount = circleCount + 1
    -- Spawn near center of screen, offset by count
    local vp = workspace.CurrentCamera.ViewportSize
    makeCircle(circleCount,
        math.floor(vp.X / 2) - 18 + (circleCount - 1) * 50,
        math.floor(vp.Y / 2) - 18
    )
end)

RemoveCircleBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    if #circles == 0 then return end
    local last = table.remove(circles)
    last.frame:Destroy()
    circleCount = #circles
    -- Re-label remaining circles
    for i, c in ipairs(circles) do
        c.label.Text = tostring(i)
        c.frame.Name = "ClickCircle_" .. i
    end
    -- Reset index if out of bounds
    if clickIndex > #circles then
        clickIndex = 1
    end
end)

-- ── Toggle Button ────────────────────────────────────────────────────────────
ToggleBtn.MouseButton1Click:Connect(function()
    if #circles == 0 and not isRunning then
        -- Nothing to click — give feedback
        ToggleBtn.Text = "⚠ Add a click point!"
        task.delay(1.5, function()
            updateToggleUI()
        end)
        return
    end
    setRunning(not isRunning)
end)

-- ── Keybind: Right Alt ───────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        if #circles == 0 and not isRunning then return end
        setRunning(not isRunning)
    end
end)

-- ── Auto-Click Loop (RunService) ─────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    if #circles == 0 then
        setRunning(false)
        return
    end

    local now = tick()
    if (now - lastClickTime) >= clickSpeed then
        lastClickTime = now

        -- Clamp index
        if clickIndex > #circles then
            clickIndex = 1
        end

        local target = circles[clickIndex]
        local pos    = target.frame.AbsolutePosition
        local size   = target.frame.AbsoluteSize
        local cx     = math.floor(pos.X + size.X / 2)
        local cy     = math.floor(pos.Y + size.Y / 2)

        -- Move mouse and simulate click via mousemoveabs / mouse1click
        -- (Delta executor exposes these as globals)
        mousemoveabs(cx, cy)
        mouse1click()

        -- Highlight active circle briefly
        target.frame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        task.delay(math.min(clickSpeed * 0.4, 0.08), function()
            if target and target.frame and target.frame.Parent then
                target.frame.BackgroundColor3 = Color3.fromRGB(90, 90, 220)
            end
        end)

        -- Advance to next circle
        clickIndex = (clickIndex % #circles) + 1
    end
end)

-- ── Spawn a default circle so user sees the system immediately ──────────────
do
    local vp = workspace.CurrentCamera.ViewportSize
    circleCount = 1
    makeCircle(1, math.floor(vp.X / 2) - 18, math.floor(vp.Y / 2) - 18)
end

print("[Delta Auto Clicker] Loaded. Right Alt to toggle | Drag circles to position.")
