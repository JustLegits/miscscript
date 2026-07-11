--[[
    ╔══════════════════════════════════════════╗
    ║       DELTA AUTO CLICKER v1.1 Mobile     ║
    ║   Cycle-Click | GUI | Keybind | Markers  ║
    ╚══════════════════════════════════════════╝
    Keybind : Right Alt  → Toggle (keyboard only)
    GUI     : Draggable via touch
    Circles : Draggable numbered markers (only when OFF)
]]

-- ── Services ────────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ── State ───────────────────────────────────────────────────────────────────
local isRunning     = false
local clickSpeed    = 0.1
local clickIndex    = 1
local lastClickTime = 0
local circles       = {}
local circleCount   = 0

-- ── ScreenGui ───────────────────────────────────────────────────────────────
local ScreenGui              = Instance.new("ScreenGui")
ScreenGui.Name               = "DeltaAutoClicker"
ScreenGui.ResetOnSpawn       = false
ScreenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset     = true   -- avoids the top-bar offset on mobile
ScreenGui.Parent             = PlayerGui

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function parseSpeed(txt)
    local n = tonumber(txt)
    if n and n > 0 then return 1 / n end
    return 0.1
end

-- Universal drag: works for both touch and mouse
local function makeDraggable(handle, target)
    local dragging  = false
    local dragStart = Vector2.zero
    local objStart  = Vector2.zero

    local function onInputBegan(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            objStart  = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
        end
    end

    local function onInputChanged(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            target.Position = UDim2.new(0, objStart.X + delta.X, 0, objStart.Y + delta.Y)
        end
    end

    local function onInputEnded(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    handle.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

-- ── Main GUI Panel ───────────────────────────────────────────────────────────
local Panel                  = Instance.new("Frame")
Panel.Name                   = "Panel"
Panel.Size                   = UDim2.new(0, 260, 0, 210)
Panel.Position               = UDim2.new(0, 40, 0, 40)
Panel.BackgroundColor3       = Color3.fromRGB(18, 18, 24)
Panel.BorderSizePixel        = 0
Panel.Active                 = true
Panel.Parent                 = ScreenGui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

local PanelStroke            = Instance.new("UIStroke", Panel)
PanelStroke.Color            = Color3.fromRGB(90, 90, 200)
PanelStroke.Thickness        = 1.5

-- Title bar
local TitleBar               = Instance.new("Frame", Panel)
TitleBar.Name                = "TitleBar"
TitleBar.Size                = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3    = Color3.fromRGB(30, 30, 50)
TitleBar.BorderSizePixel     = 0

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

-- Fill bottom half of title bar (so no rounded bottom corners)
local TitleFix               = Instance.new("Frame", TitleBar)
TitleFix.Size                = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position            = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3    = Color3.fromRGB(30, 30, 50)
TitleFix.BorderSizePixel     = 0

local TitleLabel             = Instance.new("TextLabel", TitleBar)
TitleLabel.Text              = "⚡ Delta Auto Clicker"
TitleLabel.Size              = UDim2.new(1, -40, 1, 0)
TitleLabel.Position          = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3        = Color3.fromRGB(200, 200, 255)
TitleLabel.TextSize          = 14
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left

local HideBtn                = Instance.new("TextButton", TitleBar)
HideBtn.Text                 = "−"
HideBtn.Size                 = UDim2.new(0, 28, 0, 22)
HideBtn.Position             = UDim2.new(1, -32, 0, 7)
HideBtn.BackgroundColor3     = Color3.fromRGB(60, 60, 100)
HideBtn.TextColor3           = Color3.fromRGB(220, 220, 255)
HideBtn.TextSize             = 18
HideBtn.Font                 = Enum.Font.GothamBold
HideBtn.BorderSizePixel      = 0
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 5)

makeDraggable(TitleBar, Panel)

-- Content
local Content                = Instance.new("Frame", Panel)
Content.Name                 = "Content"
Content.Size                 = UDim2.new(1, 0, 1, -36)
Content.Position             = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1

-- Speed label
local SpeedLabel             = Instance.new("TextLabel", Content)
SpeedLabel.Text              = "Click Speed (per sec)"
SpeedLabel.Size              = UDim2.new(1, -20, 0, 18)
SpeedLabel.Position          = UDim2.new(0, 10, 0, 8)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3        = Color3.fromRGB(170, 170, 210)
SpeedLabel.TextSize          = 12
SpeedLabel.Font              = Enum.Font.Gotham
SpeedLabel.TextXAlignment    = Enum.TextXAlignment.Left

-- Speed box
local SpeedBox               = Instance.new("TextBox", Content)
SpeedBox.Text                = "10"
SpeedBox.Size                = UDim2.new(1, -20, 0, 30)
SpeedBox.Position            = UDim2.new(0, 10, 0, 28)
SpeedBox.BackgroundColor3    = Color3.fromRGB(28, 28, 40)
SpeedBox.TextColor3          = Color3.fromRGB(220, 220, 255)
SpeedBox.TextSize            = 14
SpeedBox.Font                = Enum.Font.GothamMedium
SpeedBox.PlaceholderText     = "e.g. 10"
SpeedBox.PlaceholderColor3   = Color3.fromRGB(100, 100, 140)
SpeedBox.BorderSizePixel     = 0
SpeedBox.ClearTextOnFocus    = false
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 6)
local SpeedStroke            = Instance.new("UIStroke", SpeedBox)
SpeedStroke.Color            = Color3.fromRGB(80, 80, 160)
SpeedStroke.Thickness        = 1

-- Keybind label
local KeybindLabel           = Instance.new("TextLabel", Content)
KeybindLabel.Text            = "Keybind: Right Alt"
KeybindLabel.Size            = UDim2.new(1, -20, 0, 18)
KeybindLabel.Position        = UDim2.new(0, 10, 0, 68)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.TextColor3      = Color3.fromRGB(130, 130, 180)
KeybindLabel.TextSize        = 11
KeybindLabel.Font            = Enum.Font.Gotham
KeybindLabel.TextXAlignment  = Enum.TextXAlignment.Left

-- Toggle button
local ToggleBtn              = Instance.new("TextButton", Content)
ToggleBtn.Text               = "▶  Start Auto Click"
ToggleBtn.Size               = UDim2.new(1, -20, 0, 36)
ToggleBtn.Position           = UDim2.new(0, 10, 0, 90)
ToggleBtn.BackgroundColor3   = Color3.fromRGB(50, 180, 90)
ToggleBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize           = 14
ToggleBtn.Font               = Enum.Font.GothamBold
ToggleBtn.BorderSizePixel    = 0
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

-- Add circle button
local AddCircleBtn           = Instance.new("TextButton", Content)
AddCircleBtn.Text            = "+ Add Click Point"
AddCircleBtn.Size            = UDim2.new(1, -20, 0, 30)
AddCircleBtn.Position        = UDim2.new(0, 10, 0, 134)
AddCircleBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 180)
AddCircleBtn.TextColor3      = Color3.fromRGB(220, 220, 255)
AddCircleBtn.TextSize        = 13
AddCircleBtn.Font            = Enum.Font.GothamMedium
AddCircleBtn.BorderSizePixel = 0
Instance.new("UICorner", AddCircleBtn).CornerRadius = UDim.new(0, 7)

-- Remove last button
local RemoveCircleBtn        = Instance.new("TextButton", Content)
RemoveCircleBtn.Text         = "− Remove Last"
RemoveCircleBtn.Size         = UDim2.new(1, -20, 0, 30)
RemoveCircleBtn.Position     = UDim2.new(0, 10, 0, 170)
RemoveCircleBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 60)
RemoveCircleBtn.TextColor3   = Color3.fromRGB(255, 210, 210)
RemoveCircleBtn.TextSize     = 13
RemoveCircleBtn.Font         = Enum.Font.GothamMedium
RemoveCircleBtn.BorderSizePixel = 0
Instance.new("UICorner", RemoveCircleBtn).CornerRadius = UDim.new(0, 7)

-- ── Hide / Show ──────────────────────────────────────────────────────────────
local isHidden = false
HideBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    Content.Visible = not isHidden
    Panel.Size  = isHidden and UDim2.new(0, 260, 0, 36) or UDim2.new(0, 260, 0, 210)
    HideBtn.Text = isHidden and "+" or "−"
end)

-- ── Toggle UI update ─────────────────────────────────────────────────────────
local function updateToggleUI()
    if isRunning then
        ToggleBtn.Text             = "⏹  Stop Auto Click"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    else
        ToggleBtn.Text             = "▶  Start Auto Click"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
    end
    for _, c in ipairs(circles) do
        c.frame.Active = not isRunning
    end
end

local function setRunning(val)
    isRunning = val
    if isRunning then
        clickSpeed    = parseSpeed(SpeedBox.Text)
        clickIndex    = 1
        lastClickTime = 0
    end
    updateToggleUI()
end

-- ── Circle Marker Factory ────────────────────────────────────────────────────
local CIRCLE_SIZE = 44   -- slightly bigger for easier touch targeting

local function makeCircle(number, startX, startY)
    local frame                  = Instance.new("Frame", ScreenGui)
    frame.Name                   = "ClickCircle_" .. number
    frame.Size                   = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE)
    frame.Position               = UDim2.new(0, startX, 0, startY)
    frame.BackgroundColor3       = Color3.fromRGB(90, 90, 220)
    frame.BorderSizePixel        = 0
    frame.Active                 = true
    frame.ZIndex                 = 5

    Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)

    local stroke                 = Instance.new("UIStroke", frame)
    stroke.Color                 = Color3.fromRGB(180, 180, 255)
    stroke.Thickness             = 2

    local label                  = Instance.new("TextLabel", frame)
    label.Text                   = tostring(number)
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3             = Color3.fromRGB(255, 255, 255)
    label.TextSize               = 15
    label.Font                   = Enum.Font.GothamBold
    label.ZIndex                 = 6

    -- Drag (blocked when running)
    local dragging  = false
    local dragStart = Vector2.zero
    local objStart  = Vector2.zero

    frame.InputBegan:Connect(function(input)
        if isRunning then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            objStart  = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            frame.Position = UDim2.new(0, objStart.X + delta.X, 0, objStart.Y + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local entry = { frame = frame, label = label }
    table.insert(circles, entry)
    return entry
end

-- ── Buttons ───────────────────────────────────────────────────────────────────
AddCircleBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    circleCount = circleCount + 1
    local vp = workspace.CurrentCamera.ViewportSize
    makeCircle(circleCount,
        math.floor(vp.X / 2) - (CIRCLE_SIZE / 2) + (circleCount - 1) * 60,
        math.floor(vp.Y / 2) - (CIRCLE_SIZE / 2)
    )
end)

RemoveCircleBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    if #circles == 0 then return end
    local last = table.remove(circles)
    last.frame:Destroy()
    circleCount = #circles
    for i, c in ipairs(circles) do
        c.label.Text = tostring(i)
        c.frame.Name = "ClickCircle_" .. i
    end
    if clickIndex > #circles then clickIndex = 1 end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if #circles == 0 and not isRunning then
        ToggleBtn.Text = "⚠ Add a click point!"
        task.delay(1.5, updateToggleUI)
        return
    end
    setRunning(not isRunning)
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        if #circles == 0 and not isRunning then return end
        setRunning(not isRunning)
    end
end)

-- ── Auto-Click Loop ──────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not isRunning or #circles == 0 then
        if isRunning then setRunning(false) end
        return
    end

    local now = tick()
    if (now - lastClickTime) < clickSpeed then return end
    lastClickTime = now

    if clickIndex > #circles then clickIndex = 1 end

    local target = circles[clickIndex]
    local ap     = target.frame.AbsolutePosition  -- top-left in screen coords
    local as     = target.frame.AbsoluteSize

    -- Exact center of the circle in screen pixels
    local cx = math.floor(ap.X + as.X * 0.5)
    local cy = math.floor(ap.Y + as.Y * 0.5)

    -- Delta mobile executor uses tap() or writefile-based virtual touch;
    -- most mobile executors expose these two globals:
    if tap then
        tap(cx, cy)
    else
        -- PC fallback
        mousemoveabs(cx, cy)
        mouse1click()
    end

    -- Flash highlight
    target.frame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    task.delay(math.min(clickSpeed * 0.4, 0.08), function()
        if target.frame and target.frame.Parent then
            target.frame.BackgroundColor3 = Color3.fromRGB(90, 90, 220)
        end
    end)

    clickIndex = (clickIndex % #circles) + 1
end)

-- ── Default circle ───────────────────────────────────────────────────────────
do
    local vp = workspace.CurrentCamera.ViewportSize
    circleCount = 1
    makeCircle(1,
        math.floor(vp.X / 2) - (CIRCLE_SIZE / 2),
        math.floor(vp.Y / 2) - (CIRCLE_SIZE / 2)
    )
end

print("[Delta Auto Clicker v1.1] Loaded. Right Alt to toggle.")
