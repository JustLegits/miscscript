-- Credit: https://v3rm.net/threads/new-desync-method-leak.25068/

--========================================================--
-- UI Creation
--========================================================--

local ui = Instance.new("ScreenGui")
ui.Name = "DesyncUI"
ui.ResetOnSpawn = false
ui.Parent = game.CoreGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = ui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.BorderSizePixel = 0
title.Text = "Desync Control"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Parent = frame

-- Toggle button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0, 36)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 16
toggleBtn.Text = "Toggle Desync"
toggleBtn.Parent = frame

-- Hide button
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(1, -20, 0, 26)
hideBtn.Position = UDim2.new(0, 10, 0, 82)
hideBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.Text = "Hide UI"
hideBtn.TextSize = 15
hideBtn.Parent = frame

-- Unhide floating button
local unhideBtn = Instance.new("TextButton")
unhideBtn.Size = UDim2.new(0, 80, 0, 30)
unhideBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
unhideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
unhideBtn.TextColor3 = Color3.new(1, 1, 1)
unhideBtn.TextSize = 15
unhideBtn.Text = "Unhide"
unhideBtn.Visible = false
unhideBtn.Active = true
unhideBtn.Draggable = true
unhideBtn.Parent = ui


--========================================================--
-- Functionality
--========================================================--

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local desyncState = false


local function waitForRespawn(oldChar)
    repeat task.wait() until lp.Character and lp.Character ~= oldChar
    local hum = lp.Character:FindFirstChildOfClass("Humanoid") or lp.Character:WaitForChild("Humanoid")
end


local function toggleDesync()
    if desyncState == false then
        desyncState = true
        toggleBtn.Text = "Desync: Running..."

        setfflag("NextGenReplicatorEnabledWrite4", "True")
        task.wait(1)

        local oldChar = lp.Character
        pcall(function() oldChar:BreakJoints() end)

        waitForRespawn(oldChar)

        setfflag("NextGenReplicatorEnabledWrite4", "False")
        task.wait(1)

        setfflag("NextGenReplicatorEnabledWrite4", "True")

        toggleBtn.Text = "Desync: ON"

    else
        setfflag("NextGenReplicatorEnabledWrite4", "False")
        desyncState = false
        toggleBtn.Text = "Desync: OFF"
    end
end

toggleBtn.MouseButton1Click:Connect(toggleDesync)


-- Hide / Unhide
local hidden = false

hideBtn.MouseButton1Click:Connect(function()
    hidden = true
    frame.Visible = false
    unhideBtn.Visible = true
end)

unhideBtn.MouseButton1Click:Connect(function()
    hidden = false
    frame.Visible = true
    unhideBtn.Visible = false
end)
