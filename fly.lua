--[[ Fly from Infinite Yield ]]--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Configuration
local FLY_SPEED = 1
local VEL_NAME = "MobileFlyVelocity"
local GYRO_NAME = "MobileFlyGyro"

-- Helper: Cleanup Function
local function stopFly()
    if _G.MobileFlyConnection then
        _G.MobileFlyConnection:Disconnect()
        _G.MobileFlyConnection = nil
    end
    if _G.MobileFlyCharConn then
        _G.MobileFlyCharConn:Disconnect()
        _G.MobileFlyCharConn = nil
    end

    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if root then
            if root:FindFirstChild(VEL_NAME) then root[VEL_NAME]:Destroy() end
            if root:FindFirstChild(GYRO_NAME) then root[GYRO_NAME]:Destroy() end
        end
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
    
    _G.MobileFlyActive = false
    print("Flight OFF")
end

-- Check if we are already flying
if _G.MobileFlyActive then
    stopFly()
    return -- Stop the script here
end

-- If not flying, start flying
_G.MobileFlyActive = true
print("Flight ON")

local controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
local v3zero = Vector3.new(0, 0, 0)
local v3inf = Vector3.new(9e9, 9e9, 9e9)

local function applyPhysics(char)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    
    local bv = Instance.new("BodyVelocity")
    bv.Name = VEL_NAME
    bv.Parent = root
    bv.MaxForce = v3inf
    bv.Velocity = v3zero

    local bg = Instance.new("BodyGyro")
    bg.Name = GYRO_NAME
    bg.Parent = root
    bg.MaxTorque = v3inf
    bg.P = 1000
    bg.D = 50
end

-- Initialize first time
if player.Character then applyPhysics(player.Character) end

-- Persistent Connection: Respawn Support
_G.MobileFlyCharConn = player.CharacterAdded:Connect(function(char)
    applyPhysics(char)
end)

-- Persistent Connection: Movement Loop
_G.MobileFlyConnection = RunService.RenderStepped:Connect(function()
    local char = player.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    
    if root and hum and root:FindFirstChild(VEL_NAME) and root:FindFirstChild(GYRO_NAME) then
        local bv = root[VEL_NAME]
        local bg = root[GYRO_NAME]
        
        hum.PlatformStand = true
        bg.CFrame = camera.CFrame
        
        local direction = controlModule:GetMoveVector()
        local moveDir = Vector3.new(0,0,0)
        
        if direction.X ~= 0 then
            moveDir = moveDir + (camera.CFrame.RightVector * (direction.X * (FLY_SPEED * 50)))
        end
        if direction.Z ~= 0 then
            moveDir = moveDir - (camera.CFrame.LookVector * (direction.Z * (FLY_SPEED * 50)))
        end
        
        bv.Velocity = moveDir
    end
end)
