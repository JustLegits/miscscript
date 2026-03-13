local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local flying = true -- On by default
local speed = 50
local bv, bg
local keys = {w = false, s = false, a = false, d = false, space = false, lshift = false}

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
    
    task.spawn(function()
        while flying do
            local camera = workspace.CurrentCamera
            local moveDir = Vector3.new(0,0,0)
            
            if keys.w then moveDir = moveDir + camera.CFrame.LookVector end
            if keys.s then moveDir = moveDir - camera.CFrame.LookVector end
            if keys.a then moveDir = moveDir - camera.CFrame.RightVector end
            if keys.d then moveDir = moveDir + camera.CFrame.RightVector end
            if keys.space then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if keys.lshift then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            bv.Velocity = moveDir * speed
            bg.CFrame = camera.CFrame
            RunService.RenderStepped:Wait()
        end
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

-- Keyboard Listeners
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local key = input.KeyCode.Name:lower()
    
    if key == "p" then
        toggleFly()
    elseif keys[key] ~= nil then
        keys[key] = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local key = input.KeyCode.Name:lower()
    if keys[key] ~= nil then
        keys[key] = false
    end
end)

-- Initial Start
if LocalPlayer.Character then startFlying() end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if flying then startFlying() end
end)

print("Fly Script Loaded: P to toggle. Anti-AFK Active.")
