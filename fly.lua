--[[ Fly from Infinite Yield ]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Configuration
local FLY_SPEED = 1 -- Multiplied by 50 in logic, so 1 is normal fast speed
local VELOCITY_NAME = "MobileFlyVelocity"
local GYRO_NAME = "MobileFlyGyro"

-- State
local flying = false
local connections = {} -- To store event connections (RenderStepped, CharacterAdded)

-- Helper: Get Root Part
local function getRoot(char)
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

-- Helper: Stop Flying (Cleanup)
local function stopFly()
	flying = false
	
	-- Disconnect all events
	for _, conn in pairs(connections) do
		conn:Disconnect()
	end
	connections = {}

	-- Remove Physics Movers
	if player.Character then
		local root = getRoot(player.Character)
		if root then
			if root:FindFirstChild(VELOCITY_NAME) then root[VELOCITY_NAME]:Destroy() end
			if root:FindFirstChild(GYRO_NAME) then root[GYRO_NAME]:Destroy() end
		end
		
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
	print("Flight Deactivated")
end

-- Main Fly Function
local function startFly()
	if flying then return stopFly() end -- Toggle off if already on
	flying = true
	
	print("Flight Activated")

	local controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	local v3zero = Vector3.new(0, 0, 0)
	local v3inf = Vector3.new(9e9, 9e9, 9e9)

	-- Function to apply BodyGyro/Velocity
	local function applyPhysics(root)
		-- Remove old ones if they exist
		if root:FindFirstChild(VELOCITY_NAME) then root[VELOCITY_NAME]:Destroy() end
		if root:FindFirstChild(GYRO_NAME) then root[GYRO_NAME]:Destroy() end

		local bv = Instance.new("BodyVelocity")
		bv.Name = VELOCITY_NAME
		bv.Parent = root
		bv.MaxForce = v3zero -- Started at zero, updated in loop
		bv.Velocity = v3zero

		local bg = Instance.new("BodyGyro")
		bg.Name = GYRO_NAME
		bg.Parent = root
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 50
	end

	-- Apply immediately to current character
	if player.Character and getRoot(player.Character) then
		applyPhysics(getRoot(player.Character))
	end

	-- Connection 1: Re-apply if character respawns
	local charAddedConn = player.CharacterAdded:Connect(function(char)
		-- Wait for root part to exist
		local root = char:WaitForChild("HumanoidRootPart", 5)
		if root then
			applyPhysics(root)
		end
	end)
	table.insert(connections, charAddedConn)

	-- Connection 2: RenderStepped (Movement Loop)
	local loopConn = RunService.RenderStepped:Connect(function()
		if not player.Character then return end
		local root = getRoot(player.Character)
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

		if root and humanoid and root:FindFirstChild(VELOCITY_NAME) and root:FindFirstChild(GYRO_NAME) then
			local VelocityHandler = root:FindFirstChild(VELOCITY_NAME)
			local GyroHandler = root:FindFirstChild(GYRO_NAME)

			VelocityHandler.MaxForce = v3inf
			GyroHandler.MaxTorque = v3inf
			
			humanoid.PlatformStand = true -- Prevents falling animations/physics
			GyroHandler.CFrame = camera.CFrame
			VelocityHandler.Velocity = v3zero

			-- Get movement direction from Roblox's native control module (Mobile/PC compatible)
			local direction = controlModule:GetMoveVector()

			-- Calculate new velocity based on Camera direction
			-- Note: The original script used specific checks for X/Z > 0, simplified here for math efficiency
			local moveDir = Vector3.new()
			
			if direction.X ~= 0 then
				moveDir = moveDir + (camera.CFrame.RightVector * (direction.X * (FLY_SPEED * 50)))
			end
			if direction.Z ~= 0 then
				-- LookVector is usually reversed for controls (W is negative Z), so we subtract
				moveDir = moveDir - (camera.CFrame.LookVector * (direction.Z * (FLY_SPEED * 50)))
			end
			
			VelocityHandler.Velocity = moveDir
		end
	end)
	table.insert(connections, loopConn)
end

-- Execute
startFly()
