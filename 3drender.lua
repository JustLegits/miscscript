-- 1. Cài đặt biến tự động chạy (Mặc định là true nếu chưa được gán)
if getgenv().autoexe == nil then
    getgenv().autoexe = true 
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- 2. BẢO MẬT & XÂY DỰNG GIAO DIỆN
local secureGuiParent = type(gethui) == "function" and gethui() or CoreGui

if secureGuiParent:FindFirstChild("AntiBurnInGui") then
    secureGuiParent.AntiBurnInGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiBurnInGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 
ScreenGui.Parent = secureGuiParent

local BlackFrame = Instance.new("Frame")
BlackFrame.Name = "BlackCover"
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
BlackFrame.BorderSizePixel = 0
BlackFrame.ZIndex = 999999998 
BlackFrame.Visible = false
BlackFrame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleBtn"
ToggleButton.Size = UDim2.new(0, 110, 0, 35)
ToggleButton.Position = UDim2.new(1, -130, 0, 20) 
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Text = "Render: ON"
ToggleButton.ZIndex = 999999999 
ToggleButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = ToggleButton

local isRenderOff = false

-- 3. HÀM TẮT/BẬT
local function ToggleRender()
    isRenderOff = not isRenderOff
    
    if isRenderOff then
        RunService:Set3dRenderingEnabled(false)
        BlackFrame.Visible = true
        ToggleButton.Text = "Render: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        if type(setfpscap) == "function" then setfpscap(30) end
    else
        RunService:Set3dRenderingEnabled(true)
        BlackFrame.Visible = false
        ToggleButton.Text = "Render: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        if type(setfpscap) == "function" then setfpscap(60) end
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleRender)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    if input.KeyCode == Enum.KeyCode.F4 then
        ToggleRender()
    end
end)

-- 4. THỰC THI CHẾ ĐỘ AUTOXE
if getgenv().autoexe == true then
    if not isRenderOff then
        ToggleRender()
    end
end

-- 5. ANTI-AFK (CHỐNG KICK 20 PHÚT)
--if not getgenv().AntiAfkLoaded then
--    getgenv().AntiAfkLoaded = true
--    LocalPlayer.Idled:Connect(function()
--        VirtualUser:CaptureController()
--        VirtualUser:ClickButton2(Vector2.new())
--    end)
--    print("Anti-AFK đã được kích hoạt!")
--end

-- 6. TỰ ĐỘNG NỐI SCRIPT (Tự duy trì qua nhiều server)
local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queueTeleport then
    local scriptUrl = "https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/3drender.lua"
    local autoExeStr = tostring(getgenv().autoexe)
    
    local selfExecuteCode = 'getgenv().autoexe = ' .. autoExeStr .. '; loadstring(game:HttpGet("' .. scriptUrl .. '"))()'
    
    queueTeleport(selfExecuteCode)
end
