-- 1. Make sure the script only runs AFTER the game has fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- 2. Secure GUI Parenting (Hides UI from anti-cheats)
local secureGuiParent = type(gethui) == "function" and gethui() or CoreGui

-- 3. Create the Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiBurnInGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 
ScreenGui.Parent = secureGuiParent

-- 4. Create the Black Cover Frame
local BlackFrame = Instance.new("Frame")
BlackFrame.Name = "BlackCover"
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
BlackFrame.BorderSizePixel = 0
BlackFrame.ZIndex = 999999998 
BlackFrame.Visible = false
BlackFrame.Parent = ScreenGui

-- 5. Create the Toggle Button (Top Right)
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

-- 6. Toggle Logic
local function ToggleRender()
    isRenderOff = not isRenderOff
    
    if isRenderOff then
        -- TURN OFF
        RunService:Set3dRenderingEnabled(false)
        BlackFrame.Visible = true
        ToggleButton.Text = "Render: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        
        if type(setfpscap) == "function" then
            setfpscap(30)
        end
    else
        -- TURN ON
        RunService:Set3dRenderingEnabled(true)
        BlackFrame.Visible = false
        ToggleButton.Text = "Render: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
        if type(setfpscap) == "function" then
            setfpscap(60)
        end
    end
end

-- 7. Input Connections
ToggleButton.MouseButton1Click:Connect(ToggleRender)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    if input.KeyCode == Enum.KeyCode.F4 then
        ToggleRender()
    end
end)

-- 8. AUTORUN: Turn off render immediately upon execution
ToggleRender()
