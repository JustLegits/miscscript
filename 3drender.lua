--// =========================================================
--// AntiBurnIn
--// Long-run / Persistent AutoExecute / No Duplicate
--// =========================================================

--============================================================
-- CONFIG
--============================================================

local CONFIG_FILE = "AntiBurnIn_autoexe.txt"

local SCRIPT_URL =
    "https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/3drender.lua"

local GUI_NAME = "AntiBurnInGui"
local STATE_KEY = "AntiBurnInState"

--============================================================
-- SERVICES
--============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- EXECUTOR API
--============================================================

local gethuiFunc =
    type(gethui) == "function" and gethui or nil

local setFpsCap =
    type(setfpscap) == "function" and setfpscap or nil

local queueTeleport =
    type(queue_on_teleport) == "function"
        and queue_on_teleport
    or (syn and type(syn.queue_on_teleport) == "function"
        and syn.queue_on_teleport)
    or (fluxus and type(fluxus.queue_on_teleport) == "function"
        and fluxus.queue_on_teleport)

local fileSupported =
    type(isfile) == "function"
    and type(readfile) == "function"
    and type(writefile) == "function"

local secureGuiParent =
    gethuiFunc and gethuiFunc() or CoreGui

--============================================================
-- FILE CONFIG
--============================================================

local function SaveAutoExecute(value)

    if not fileSupported then
        return false
    end

    local content = value and "true" or "false"

    local success = pcall(function()
        writefile(CONFIG_FILE, content)
    end)

    return success
end


local function LoadAutoExecute()

    -- Executor không hỗ trợ file API
    if not fileSupported then
        return true
    end

    -- Chưa có file → tạo mặc định ON
    if not isfile(CONFIG_FILE) then
        SaveAutoExecute(true)
        return true
    end

    local success, content = pcall(function()
        return readfile(CONFIG_FILE)
    end)

    if not success then
        return true
    end

    content = tostring(content):lower()

    if content == "false" then
        return false
    end

    if content == "true" then
        return true
    end

    -- File bị lỗi → reset về ON
    SaveAutoExecute(true)

    return true
end


local autoExecute = LoadAutoExecute()

getgenv().autoexe = autoExecute

--============================================================
-- CLEANUP PREVIOUS INSTANCE
--============================================================

local oldState = getgenv()[STATE_KEY]

if oldState then

    if oldState.Connections then

        for _, connection in pairs(oldState.Connections) do

            if connection then

                pcall(function()
                    connection:Disconnect()
                end)

            end

        end

    end


    if oldState.Gui then

        pcall(function()
            oldState.Gui:Destroy()
        end)

    end

end


-- Fallback cleanup
pcall(function()

    local existingGui =
        secureGuiParent:FindFirstChild(GUI_NAME)

    if existingGui then
        existingGui:Destroy()
    end

end)


--============================================================
-- STATE
--============================================================

local State = {

    Connections = {},

    Gui = nil,
    BlackFrame = nil,

    RenderButton = nil,
    AutoButton = nil,

    RenderOff = false,
    AutoExecute = autoExecute,

    Destroyed = false,
}

getgenv()[STATE_KEY] = State


--============================================================
-- CONNECTION MANAGER
--============================================================

local function AddConnection(connection)

    if connection then
        table.insert(State.Connections, connection)
    end

    return connection
end


local function DisconnectAll()

    for index, connection in pairs(State.Connections) do

        if connection then

            pcall(function()
                connection:Disconnect()
            end)

        end

        State.Connections[index] = nil

    end

end


--============================================================
-- GUI
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
-- BLACK COVER
--============================================================

local BlackFrame = Instance.new("Frame")

BlackFrame.Name = "BlackCover"

BlackFrame.Size =
    UDim2.new(1, 0, 1, 0)

BlackFrame.Position =
    UDim2.new(0, 0, 0, 0)

BlackFrame.BackgroundColor3 =
    Color3.fromRGB(0, 0, 0)

BlackFrame.BorderSizePixel = 0

BlackFrame.Visible = false

BlackFrame.ZIndex = 999999998

BlackFrame.Parent = ScreenGui

State.BlackFrame = BlackFrame


--============================================================
-- BUTTON FACTORY
--============================================================

local function CreateButton(name, position)

    local button = Instance.new("TextButton")

    button.Name = name

    button.Size =
        UDim2.new(0, 110, 0, 35)

    button.Position = position

    button.BackgroundColor3 =
        Color3.fromRGB(40, 40, 40)

    button.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    button.Font =
        Enum.Font.GothamBold

    button.TextSize = 14

    button.ZIndex = 999999999

    button.AutoButtonColor = true

    button.Parent = ScreenGui


    local corner = Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 6)

    corner.Parent = button


    return button

end


--============================================================
-- CREATE BUTTONS
--============================================================

local RenderButton = CreateButton(
    "RenderButton",
    UDim2.new(1, -250, 0, 20)
)

local AutoButton = CreateButton(
    "AutoExecuteButton",
    UDim2.new(1, -130, 0, 20)
)

State.RenderButton = RenderButton
State.AutoButton = AutoButton


--============================================================
-- BUTTON UPDATE
--============================================================

local function UpdateRenderButton()

    if State.RenderOff then

        RenderButton.Text = "Render: OFF"

        RenderButton.BackgroundColor3 =
            Color3.fromRGB(180, 40, 40)

    else

        RenderButton.Text = "Render: ON"

        RenderButton.BackgroundColor3 =
            Color3.fromRGB(40, 40, 40)

    end

end


local function UpdateAutoButton()

    if State.AutoExecute then

        AutoButton.Text = "AutoExec: ON"

        AutoButton.BackgroundColor3 =
            Color3.fromRGB(40, 120, 60)

    else

        AutoButton.Text = "AutoExec: OFF"

        AutoButton.BackgroundColor3 =
            Color3.fromRGB(100, 100, 100)

    end

end


--============================================================
-- RENDER CONTROL
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

        BlackFrame.Visible = false

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

        BlackFrame.Visible = true

        if setFpsCap then

            pcall(function()
                setFpsCap(30)
            end)

        end

    end


    UpdateRenderButton()

end


local function ToggleRender()

    SetRender(not State.RenderOff)

end


--============================================================
-- AUTO EXECUTE CONTROL
--============================================================

local function SetAutoExecute(enabled)

    State.AutoExecute = enabled

    getgenv().autoexe = enabled

    -- Chỉ ghi file khi người dùng thực sự thay đổi setting
    SaveAutoExecute(enabled)

    UpdateAutoButton()

end


local function ToggleAutoExecute()

    SetAutoExecute(not State.AutoExecute)

end


--============================================================
-- BUTTON EVENTS
--============================================================

AddConnection(

    RenderButton.MouseButton1Click:Connect(function()

        ToggleRender()

    end)

)


AddConnection(

    AutoButton.MouseButton1Click:Connect(function()

        ToggleAutoExecute()

    end)

)


--============================================================
-- F4
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
-- INITIAL STATE
--============================================================

UpdateAutoButton()

-- Render OFF mặc định khi AutoExecute đang ON
if State.AutoExecute then
    SetRender(false)
else
    SetRender(true)
end


--============================================================
-- QUEUE TELEPORT
--============================================================

if State.AutoExecute and queueTeleport then

    local autoExeValue =
        tostring(State.AutoExecute)

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
-- CLEANUP
--============================================================

function State:Cleanup()

    if self.Destroyed then
        return
    end

    self.Destroyed = true


    DisconnectAll()


    pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)


    if setFpsCap then

        pcall(function()
            setFpsCap(60)
        end)

    end


    if self.Gui then

        pcall(function()
            self.Gui:Destroy()
        end)

    end


    if getgenv()[STATE_KEY] == self then
        getgenv()[STATE_KEY] = nil
    end

end


--============================================================
-- STATUS
--============================================================

print("--------------------------------")
print("[AntiBurnIn] Loaded")
print("[AntiBurnIn] Render : F4")
print(
    "[AntiBurnIn] AutoExec : "
    .. tostring(State.AutoExecute)
)

if fileSupported then
    print(
        "[AntiBurnIn] Config : "
        .. CONFIG_FILE
    )
else
    print(
        "[AntiBurnIn] File API unavailable"
    )
end

print("--------------------------------")
