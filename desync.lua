-- Credit: https://v3rm.net/threads/new-desync-method-leak.25068/

--========================================================--
-- UI Creation
--========================================================--

local ui = Instance.new("ScreenGui")
ui.Name = "DesyncUI"
ui.ResetOnSpawn = false
ui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = ui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.BorderSizePixel = 0
title.Text = "Desync Control"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0, 36)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 16
toggleBtn.Text = "Toggle Desync"
toggleBtn.Parent = frame

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(1, -20, 0, 26)
hideBtn.Position = UDim2.new(0, 10, 0, 82)
hideBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.Text = "Hide UI"
hideBtn.TextSize = 15
hideBtn.Parent = frame


--========================================================--
-- Functionality
--========================================================--

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local desyncState = false


local function waitForRespawn(oldChar)
    -- Wait for new Character different from old one
    repeat
        task.wait()
    until lp.Character and lp.Character ~= oldChar

    -- Optional: wait for Humanoid loaded
    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        hum = lp.Character:WaitForChild("Humanoid")
    end
end


local function toggleDesync()
    if desyncState == false then
        desyncState = true
        toggleBtn.Text = "Desync: Running..."

        -- Step 1: Enable flag
        setfflag("NextGenReplicatorEnabledWrite4", "True")
        task.wait(1)

        -- Step 2: Reset character
        local oldChar = lp.Character
        pcall(function()
            oldChar:BreakJoints()
        end)

        waitForRespawn(oldChar)  -- Wait until fully respawned

        -- Step 3: Disable flag
        setfflag("NextGenReplicatorEnabledWrite4", "False")
        task.wait(1)

        -- Step 4: Re-enable flag
        setfflag("NextGenReplicatorEnabledWrite4", "True")

        toggleBtn.Text = "Desync: ON"

    else
        -- Disable desync
        setfflag("NextGenReplicatorEnabledWrite4", "False")

        desyncState = false
        toggleBtn.Text = "Desync: OFF"
    end
end


toggleBtn.MouseButton1Click:Connect(toggleDesync)

-- Hide / Show
local hidden = false
hideBtn.MouseButton1Click:Connect(function()
    hidden = not hidden
    frame.Visible = not hidden
    hideBtn.Text = hidden and "Show UI" or "Hide UI"
end)
