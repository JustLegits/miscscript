--// =========================================================
--// AntiBurnIn - Long Run / No Duplicate / Cleanup
--// =========================================================

--============================================================
-- 1. CONFIG
--============================================================

if getgenv().autoexe == nil then
    getgenv().autoexe = true
end

local SCRIPT_URL =
    "https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/3drender.lua"

local GUI_NAME = "AntiBurnInGui"
local STATE_KEY = "AntiBurnInState"

--============================================================
-- 2. WAIT FOR GAME
--============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--============================================================
-- 3. SERVICES
--============================================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- 4. EXECUTOR COMPATIBILITY
--============================================================

local gethuiFunc =
    type(gethui) == "function" and gethui or nil

local queueTeleport =
    type(queue_on_teleport) == "function" and queue_on_teleport
    or (syn and type(syn.queue_on_teleport) == "function"
        and syn.queue_on_teleport)
    or (fluxus and type(fluxus.queue_on_teleport) == "function"
        and fluxus.queue_on_teleport)

local setFpsCap =
    type(setfpscap) == "function" and setfpscap or nil

local secureGuiParent =
    gethuiFunc and gethuiFunc() or CoreGui

--============================================================
-- 5. CLEANUP OLD INSTANCE
--============================================================

local oldState = getgenv()[STATE_KEY]

if oldState then

    -- Disconnect every registered connection
    if oldState.Connections then
        for _, connection in pairs(oldState.Connections) do
            if connection then
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end
    end

    -- Destroy old GUI
    if oldState.Gui then
        pcall(function()
            oldState.Gui:Destroy()
        end)
    end

    -- Fallback: destroy by name too
    pcall(function()
        local oldGui = secureGuiParent:FindFirstChild(GUI_NAME)

        if oldGui then
            oldGui:Destroy()
        end
    end)

    -- Clear old state
    getgenv()[STATE_KEY] = nil
end

--============================================================
-- 6. CREATE NEW STATE
--============================================================

local State = {
    Connections = {},
    Gui = nil,

    BlackFrame = nil,
    ToggleButton = nil,

    RenderOff = false,
    Destroyed = false,
}

getgenv()[STATE_KEY] = State

--============================================================
-- 7. CONNECTION MANAGER
--============================================================

local function AddConnection(connection)

    if connection then
        table.insert(State.Connections, connection)
    end

    return connection
end

local function DisconnectAll()

    for i, connection in pairs(State.Connections) do

        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        State.Connections[i] = nil
    end

end

--============================================================
-- 8. GUI
--============================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

pcall(function()
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
end)

ScreenGui.Parent = secureGuiParent

State.Gui = ScreenGui

--============================================================
-- 9. BLACK COVER
--============================================================

local BlackFrame = Instance.new("Frame")

BlackFrame.Name = "BlackCover"
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.Position = UDim2.new(0, 0, 0, 0)

BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackFrame.BorderSizePixel = 0

BlackFrame.Visible = false
BlackFrame.ZIndex = 999999998

BlackFrame.Parent = ScreenGui

State.BlackFrame = BlackFrame

--============================================================
-- 10. TOGGLE BUTTON
--============================================================

local ToggleButton = Instance.new("TextButton")

ToggleButton.Name = "ToggleBtn"

ToggleButton.Size = UDim2.new(0, 110, 0, 35)
ToggleButton.Position = UDim2.new(1, -130, 0, 20)

ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)

ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14

ToggleButton.Text = "Render: ON"

ToggleButton.AutoButtonColor = true

ToggleButton.ZIndex = 999999999

ToggleButton.Parent = ScreenGui

State.ToggleButton = ToggleButton

--============================================================
-- 11. BUTTON CORNER
--============================================================

local UICorner = Instance.new("UICorner")

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = ToggleButton

--============================================================
-- 12. RENDER TOGGLE
--============================================================

local function SetRender(enabled)

    if State.Destroyed then
        return
    end

    if enabled then

        State.RenderOff = false

        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)

        if BlackFrame then
            BlackFrame.Visible = false
        end

        if ToggleButton then
            ToggleButton.Text = "Render: ON"
            ToggleButton.BackgroundColor3 =
                Color3.fromRGB(40, 40, 40)
        end

        if setFpsCap then
            pcall(function()
                setFpsCap(60)
            end)
        end

    else

        State.RenderOff = true

        pcall(function()
            RunService:Set3dRenderingEnabled(false)
        end)

        if BlackFrame then
            BlackFrame.Visible = true
        end

        if ToggleButton then
            ToggleButton.Text = "Render: OFF"
            ToggleButton.BackgroundColor3 =
                Color3.fromRGB(180, 40, 40)
        end

        if setFpsCap then
            pcall(function()
                setFpsCap(30)
            end)
        end

    end

end

local function ToggleRender()

    SetRender(not State.RenderOff)

end

--============================================================
-- 13. BUTTON CONNECTION
--============================================================

AddConnection(
    ToggleButton.MouseButton1Click:Connect(function()

        ToggleRender()

    end)
)

--============================================================
-- 14. F4 CONNECTION
--============================================================

AddConnection(
    UserInputService.InputBegan:Connect(
        function(input, gameProcessed)

            if State.Destroyed then
                return
            end

            if gameProcessed then
                return
            end

            if input.KeyCode == Enum.KeyCode.F4 then
                ToggleRender()
            end

        end
    )
)

--============================================================
-- 15. OPTIONAL ANTI-AFK
--============================================================

-- Nếu muốn bật Anti-AFK, bỏ comment phần dưới.

--[[
AddConnection(
    LocalPlayer.Idled:Connect(function()

        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)

    end)
)
]]

--============================================================
-- 16. AUTO RENDER OFF
--============================================================

if getgenv().autoexe == true then
    SetRender(false)
end

--============================================================
-- 17. TELEPORT AUTO EXECUTE
--============================================================

if queueTeleport then

    local autoExeValue = tostring(getgenv().autoexe)

    local teleportCode =
        'getgenv().autoexe = ' ..
        autoExeValue ..
        '; ' ..
        'loadstring(game:HttpGet("' ..
        SCRIPT_URL ..
        '"))()'

    pcall(function()
        queueTeleport(teleportCode)
    end)

end

--============================================================
-- 18. CLEANUP FUNCTION
--============================================================

function State:Cleanup()

    if self.Destroyed then
        return
    end

    self.Destroyed = true

    -- Disconnect connections
    DisconnectAll()

    -- Restore rendering
    pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)

    -- Restore FPS
    if setFpsCap then
        pcall(function()
            setFpsCap(60)
        end)
    end

    -- Destroy GUI
    if self.Gui then
        pcall(function()
            self.Gui:Destroy()
        end)
    end

    -- Remove global state
    if getgenv()[STATE_KEY] == self then
        getgenv()[STATE_KEY] = nil
    end

end

--============================================================
-- 19. READY
--============================================================

print("[AntiBurnIn] Loaded successfully")
print("[AntiBurnIn] F4 = Toggle Render")
print("[AntiBurnIn] Render Off = 3D Rendering Disabled")
print("[AntiBurnIn] Long-run state initialized")
