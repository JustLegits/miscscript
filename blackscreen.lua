--// =========================================================
--// AntiBurnIn - Safe Mode (No 3D Engine Cut / Anti-Crash)
--// =========================================================

local CONFIG_FILE = "AntiBurnIn_autoexe.txt"
local SCRIPT_URL  = "https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/3drender.lua"
local GUI_NAME    = "AntiBurnInGui"
local STATE_KEY   = "AntiBurnInState_Secure"
local FADE_TIME   = 3   -- Giây không tương tác trước khi làm mờ nút
local RESTORE_FPS = 45  -- FPS khi mở lại màn hình hoặc cleanup

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local VirtualUser      = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

local gethuiFunc     = type(gethui) == "function" and gethui or nil
local setFpsCap      = type(setfpscap) == "function" and setfpscap or nil
local queueTeleport  = type(queue_on_teleport) == "function" and queue_on_teleport
    or (syn and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
    or (fluxus and type(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)

local fileSupported  = type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
local secureParent   = gethuiFunc and gethuiFunc() or CoreGui

-- Dọn dẹp phiên bản cũ nếu đang chạy
if getgenv()[STATE_KEY] and type(getgenv()[STATE_KEY].Cleanup) == "function" then
    pcall(function() getgenv()[STATE_KEY]:Cleanup() end)
end

pcall(function()
    local existingGui = secureParent:FindFirstChild(GUI_NAME)
    if existingGui then existingGui:Destroy() end
end)

--============================================================
-- CONFIG HANDLER (STRICT PARSING)
--============================================================

local function SaveConfig(val)
    if not fileSupported then return false end
    return pcall(function() writefile(CONFIG_FILE, val and "true" or "false") end)
end

local function LoadConfig()
    if not fileSupported or not isfile(CONFIG_FILE) then return true end
    local success, content = pcall(function() return readfile(CONFIG_FILE) end)
    if success and type(content) == "string" then
        content = content:lower():gsub("%s+", "")
        if content == "true" then return true end
        if content == "false" then return false end
    end
    return true
end

local isAutoExec = LoadConfig()
getgenv().AntiBurnIn_AutoExec = isAutoExec

--============================================================
-- STATE SETUP
--============================================================

local State = {
    Connections     = {},
    Gui             = nil,
    BlackFrame      = nil,
    ButtonContainer = nil,
    ScreenButton    = nil,
    AutoButton      = nil,
    ScreenOff       = false, -- Màn hình đen hay không
    AutoExecute     = isAutoExec,
    TeleportQueued  = false,
    Destroyed       = false,
    IsFaded         = false,
}
getgenv()[STATE_KEY] = State

local function AddConnection(conn)
    if conn then table.insert(State.Connections, conn) end
    return conn
end

--============================================================
-- UI CONSTRUCTION
--============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = secureParent
State.Gui = ScreenGui

local BlackFrame = Instance.new("Frame")
BlackFrame.Name = "BlackCover"
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackFrame.BorderSizePixel = 0
BlackFrame.Visible = false
BlackFrame.ZIndex = 1
BlackFrame.Parent = ScreenGui
State.BlackFrame = BlackFrame

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Name = "ButtonContainer"
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Size = UDim2.new(0, 240, 0, 40)
ButtonContainer.Position = UDim2.new(1, -250, 0, 20)
ButtonContainer.ZIndex = 2
ButtonContainer.Parent = ScreenGui
State.ButtonContainer = ButtonContainer

local function CreateButton(name, xOffset)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 110, 0, 35)
    btn.Position = UDim2.new(0, xOffset, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = true
    btn.Parent = ButtonContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

State.ScreenButton = CreateButton("ScreenButton", 0)
State.AutoButton   = CreateButton("AutoButton", 120)

--============================================================
-- AUTO-FADE UX (OLED PROTECTION)
--============================================================

local lastActive = os.clock()
local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function SetUIFade(faded)
    if State.Destroyed or State.IsFaded == faded then return end
    State.IsFaded = faded

    local targetTrans = faded and 0.85 or 0

    TweenService:Create(State.ScreenButton, tweenInfo, {
        BackgroundTransparency = targetTrans,
        TextTransparency = targetTrans
    }):Play()

    TweenService:Create(State.AutoButton, tweenInfo, {
        BackgroundTransparency = targetTrans,
        TextTransparency = targetTrans
    }):Play()
end

local function RegisterActivity()
    lastActive = os.clock()
    if State.IsFaded then
        SetUIFade(false)
    end
end

--============================================================
-- TELEPORT BOOTSTRAP PIPELINE
--============================================================

local function ApplyTeleportQueue()
    if State.TeleportQueued or not queueTeleport then return end

    local bootstrapPayload = table.concat({
        'local f = "' .. CONFIG_FILE .. '"',
        'local run = true',
        'if type(isfile) == "function" and type(readfile) == "function" and isfile(f) then',
        '    local s, c = pcall(readfile, f)',
        '    if s and tostring(c):lower():gsub("%%s+", "") == "false" then run = false end',
        'end',
        'if run then loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))() end'
    }, "; ")

    local success = pcall(function()
        queueTeleport(bootstrapPayload)
    end)

    if success then
        State.TeleportQueued = true
    end
end

--============================================================
-- LOGIC CONTROLS
--============================================================

local function UpdateUI()
    if State.ScreenOff then
        State.ScreenButton.Text = "Screen: OFF"
        State.ScreenButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
    else
        State.ScreenButton.Text = "Screen: ON"
        State.ScreenButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end

    if State.AutoExecute then
        State.AutoButton.Text = "AutoExec: ON"
        State.AutoButton.BackgroundColor3 = Color3.fromRGB(35, 110, 50)
    else
        State.AutoButton.Text = "AutoExec: OFF"
        State.AutoButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

local function SetScreen(turnOffScreen)
    if State.Destroyed then return end
    State.ScreenOff = turnOffScreen
    State.BlackFrame.Visible = turnOffScreen

    -- Giảm FPS về 30 để máy mát khi che màn hình, khôi phục lại khi bật màn hình
    if setFpsCap then
        if turnOffScreen then
            pcall(function() setFpsCap(30) end)
        else
            pcall(function() setFpsCap(RESTORE_FPS) end)
        end
    end

    RegisterActivity()
    UpdateUI()
end

local function SetAutoExecute(enable)
    State.AutoExecute = enable
    getgenv().AntiBurnIn_AutoExec = enable
    SaveConfig(enable)

    if enable then
        ApplyTeleportQueue()
    end

    RegisterActivity()
    UpdateUI()
end

--============================================================
-- PROACTIVE ANTI-AFK
--============================================================

local VirtualInputManager = (function()
    local success, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    return success and vim or nil
end)()

local function SendAntiAfkSignal()
    -- 1. Giả lập bấm Space
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end

    -- 2. Fallback VirtualUser click
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)

    -- 3. Kích hoạt nhảy nhân vật để phá kiểm tra tọa độ
    pcall(function()
        local character = LocalPlayer and LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

if LocalPlayer then
    AddConnection(LocalPlayer.Idled:Connect(function()
        SendAntiAfkSignal()
    end))
end

-- Chủ động gửi tín hiệu mỗi 8 phút
task.spawn(function()
    while not State.Destroyed do
        task.wait(480)
        SendAntiAfkSignal()
    end
end)

--============================================================
-- CONNECTIONS & EVENTS
--============================================================

AddConnection(State.ScreenButton.MouseButton1Click:Connect(function()
    SetScreen(not State.ScreenOff)
end))

AddConnection(State.AutoButton.MouseButton1Click:Connect(function()
    SetAutoExecute(not State.AutoExecute)
end))

AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if State.Destroyed or processed then return end
    RegisterActivity()

    if input.KeyCode == Enum.KeyCode.F4 then
        SetScreen(not State.ScreenOff)
    end
end))

AddConnection(ButtonContainer.MouseEnter:Connect(RegisterActivity))

-- Tự động làm mờ UI sau FADE_TIME giây
AddConnection(RunService.Heartbeat:Connect(function()
    if not State.IsFaded and (os.clock() - lastActive) > FADE_TIME then
        SetUIFade(true)
    end
end))

--============================================================
-- CLEANUP
--============================================================

function State:Cleanup()
    if self.Destroyed then return end
    self.Destroyed = true

    for _, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    table.clear(self.Connections)

    if setFpsCap then
        pcall(function() setFpsCap(RESTORE_FPS) end)
    end

    if self.Gui then
        pcall(function() self.Gui:Destroy() end)
    end

    if getgenv()[STATE_KEY] == self then
        getgenv()[STATE_KEY] = nil
    end
end

--============================================================
-- INITIALIZATION
--============================================================

UpdateUI()
SetScreen(true) -- Mặc định phủ màn hình đen khi khởi động

if State.AutoExecute then
    ApplyTeleportQueue()
end
