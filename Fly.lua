local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local flying = true -- On by default
local speed = 50
local bv, bg
local flyConnection 

-- Grab Roblox's core movement module (Bypasses the GPE issue and adds mobile support)
local controlModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
local FlyButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "DeltaFlyUI"

FlyButton.Name = "FlyButton"
FlyButton.Parent = ScreenGui
FlyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FlyButton.Position = UDim2.new(0.1, 0, 0.5, 0)
FlyButton.Size = UDim2.new(0, 80, 0, 40)
FlyButton.Font = Enum.Font.SourceSansBold
FlyButton.Text = "FLY: ON"
FlyButton.TextColor3 = Color3.fromRGB(0, 255, 100)
FlyButton.TextSize = 18
FlyButton.Active = true
FlyButton.Draggable = true 

UICorner.Parent = FlyButton

--- Anti-AFK Logic ---
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    warn("Anti-AFK: Prevented idle kick.")
end)

--- Flight Logic ---
local function stopFlying()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
end

local function startFlying()
    stopFlying() 
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    bv = Instance.new("BodyVelocity", root)
    bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
    bv.Velocity = Vector3.new(0, 0, 0)
    
    bg = Instance.new("BodyGyro", root)
    bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
    bg.P = 90000
    
    char.Humanoid.PlatformStand = true
    
    flyConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        local direction = controlModule:GetMoveVector()
        local moveDir = Vector3.new(0,0,0)
        
        -- Forward, Backward, Left, Right (Based on camera direction)
        if direction.X ~= 0 then
            moveDir = moveDir + (camera.CFrame.RightVector * direction.X)
        end
        if direction.Z ~= 0 then
            moveDir = moveDir - (camera.CFrame.LookVector * direction.Z)
        end
        
        -- Up and Down (Checking keys directly bypasses GPE interference)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end
        
        -- Normalize vector so diagonal flying isn't twice as fast
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end
        
        bv.Velocity = moveDir * speed
        bg.CFrame = camera.CFrame
    end)
end

local function toggleFly()
    flying = not flying
    if flying then
        FlyButton.Text = "FLY: ON"
        FlyButton.TextColor3 = Color3.fromRGB(0, 255, 100)
        startFlying()
    else
        FlyButton.Text = "FLY: OFF"
        FlyButton.TextColor3 = Color3.fromRGB(255, 50, 50)
        stopFlying()
    end
end

-- Button Toggle
FlyButton.MouseButton1Click:Connect(toggleFly)

-- Keyboard Toggle (P to toggle, but ignore if typing in chat)
UserInputService.InputBegan:Connect(function(input, gpe)
    -- GetFocusedTextBox checks if the player is typing in chat so "P" doesn't trigger flight
    if UserInputService:GetFocusedTextBox() then return end 
    
    if input.KeyCode == Enum.KeyCode.P then
        toggleFly()
    end
end)

-- Initial Start
if LocalPlayer.Character then startFlying() end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if flying then startFlying() end
end)

print("Fly Script Loaded: P to toggle. Anti-AFK Active.")
