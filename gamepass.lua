local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SeluwiaUI") then
    playerGui.SeluwiaUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SeluwiaUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local isMobile = UserInputService.TouchEnabled
local autoSpeed = 100  -- signals per second

-- Helper functions
local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(40, 40, 56)
    s.Thickness = thickness or 1
    return s
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function getTime()
    return os.date("%H:%M:%S")
end

-- Scale UI for mobile
local panelSize
local fontSizeScale = isMobile and 0.8 or 1
local buttonHeight = isMobile and 36 or 28
local titleBarHeight = isMobile and 44 or 52
local footerHeight = isMobile and 44 or 50

if isMobile then
    panelSize = UDim2.new(0.9, 0, 0.7, 0)
else
    panelSize = UDim2.new(0, 760, 0, 520)
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = panelSize
panel.Position = UDim2.new(0.5, -panelSize.X.Offset/2, 0.5, -panelSize.Y.Offset/2)
if isMobile then
    panel.Position = UDim2.new(0.05, 0, 0.15, 0)
end
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
panel.BorderSizePixel = 0
panel.Parent = screenGui
corner(panel, 16)
stroke(panel, Color3.fromRGB(30, 30, 42), 1)

-- Resize handle (PC only)
if not isMobile then
    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 20, 0, 20)
    resizeHandle.Position = UDim2.new(1, -20, 1, -20)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Parent = panel
    corner(resizeHandle, 4)
    stroke(resizeHandle, Color3.fromRGB(80, 80, 110), 1)

    local resizing = false
    local resizeStartPos, startSize
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStartPos = input.Position
            startSize = panel.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStartPos
            local newWidth = math.clamp(startSize.X + delta.X, 400, 1200)
            local newHeight = math.clamp(startSize.Y + delta.Y, 300, 800)
            panel.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
end

-- Dragging
local dragging = false
local dragStart, startPos

local function onInputBegan(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not resizing then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end

local function onInputChanged(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, titleBarHeight)
titleBar.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
corner(titleBar, 16)
stroke(titleBar, Color3.fromRGB(22, 22, 31), 1)

local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 18)
titleFill.Position = UDim2.new(0, 0, 1, -18)
titleFill.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
titleFill.BorderSizePixel = 0
titleFill.ZIndex = titleBar.ZIndex + 1
titleFill.Parent = titleBar

titleBar.InputBegan:Connect(onInputBegan)
UserInputService.InputChanged:Connect(onInputChanged)
UserInputService.InputEnded:Connect(onInputEnded)

-- Live dot
local liveDot = Instance.new("Frame")
liveDot.Size = UDim2.new(0, 9, 0, 9)
liveDot.Position = UDim2.new(0, 20, 0.5, -4)
liveDot.BackgroundColor3 = Color3.fromRGB(61, 255, 160)
liveDot.BorderSizePixel = 0
liveDot.ZIndex = titleBar.ZIndex + 2
liveDot.Parent = titleBar
corner(liveDot, 999)

local liveLabel = Instance.new("TextLabel")
liveLabel.Size = UDim2.new(0, 50, 0, 20)
liveLabel.Position = UDim2.new(0, 34, 0.5, -10)
liveLabel.BackgroundTransparency = 1
liveLabel.Text = "LIVE"
liveLabel.TextColor3 = Color3.fromRGB(61, 255, 160)
liveLabel.TextSize = 11 * fontSizeScale
liveLabel.Font = Enum.Font.GothamBold
liveLabel.TextXAlignment = Enum.TextXAlignment.Left
liveLabel.ZIndex = titleBar.ZIndex + 2
liveLabel.Parent = titleBar

task.spawn(function()
    while screenGui.Parent do
        TweenService:Create(liveDot, TweenInfo.new(1), {Size = UDim2.new(0,11,0,11), Position = UDim2.new(0,19,0.5,-5)}):Play()
        task.wait(1)
        TweenService:Create(liveDot, TweenInfo.new(1), {Size = UDim2.new(0,9,0,9), Position = UDim2.new(0,20,0.5,-4)}):Play()
        task.wait(1)
    end
end)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 200, 1, 0)
titleText.Position = UDim2.new(0.5, -100, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "SELUWIA"
titleText.TextColor3 = Color3.fromRGB(210, 210, 228)
titleText.TextSize = 14 * fontSizeScale
titleText.Font = Enum.Font.GothamBold
titleText.ZIndex = titleBar.ZIndex + 2
titleText.Parent = titleBar

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 76, 0, 30)
clearBtn.Position = UDim2.new(1, -92, 0.5, -15)
clearBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
clearBtn.Text = "X Clear"
clearBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
clearBtn.TextSize = 11 * fontSizeScale
clearBtn.Font = Enum.Font.GothamBold
clearBtn.BorderSizePixel = 0
clearBtn.ZIndex = titleBar.ZIndex + 3
clearBtn.Parent = titleBar
corner(clearBtn, 8)
stroke(clearBtn, Color3.fromRGB(80, 28, 28), 1)

clearBtn.MouseEnter:Connect(function()
    clearBtn.BackgroundColor3 = Color3.fromRGB(28, 10, 10)
end)
clearBtn.MouseLeave:Connect(function()
    clearBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
end)

-- Log area
local logArea = Instance.new("ScrollingFrame")
logArea.Name = "LogArea"
logArea.Size = UDim2.new(1, -12, 1, -(titleBarHeight + footerHeight + 10))
logArea.Position = UDim2.new(0, 6, 0, titleBarHeight + 6)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = isMobile and 6 or 3
logArea.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 90)
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.Parent = panel

local listLayout = Instance.new("UIListLayout", logArea)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, isMobile and 10 or 7)
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local logPad = Instance.new("UIPadding", logArea)
logPad.PaddingTop = UDim.new(0, 8)
logPad.PaddingBottom = UDim.new(0, 6)
logPad.PaddingLeft = UDim.new(0, 4)
logPad.PaddingRight = UDim.new(0, 4)

-- Footer
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, footerHeight)
footer.Position = UDim2.new(0, 0, 1, -footerHeight)
footer.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
footer.BorderSizePixel = 0
footer.Parent = panel
corner(footer, 16)

local footerFill = Instance.new("Frame")
footerFill.Size = UDim2.new(1, 0, 0, 18)
footerFill.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
footerFill.BorderSizePixel = 0
footerFill.Parent = footer

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0, 160, 1, 0)
countLabel.Position = UDim2.new(0, 20, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "0 events captured"
countLabel.TextColor3 = Color3.fromRGB(160, 155, 200)
countLabel.TextSize = 12 * fontSizeScale
countLabel.Font = Enum.Font.Gotham
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.ZIndex = footer.ZIndex + 1
countLabel.Parent = footer

local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 50, 0, buttonHeight)
settingsBtn.Position = UDim2.new(1, -90, 0.5, -buttonHeight/2)
settingsBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
settingsBtn.Text = "SET"
settingsBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
settingsBtn.TextSize = 11 * fontSizeScale
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.BorderSizePixel = 0
settingsBtn.ZIndex = footer.ZIndex + 1
settingsBtn.Parent = footer
corner(settingsBtn, 7)
stroke(settingsBtn, Color3.fromRGB(55, 50, 85), 1)

local stopAllBtn = Instance.new("TextButton")
stopAllBtn.Size = UDim2.new(0, 80, 0, buttonHeight)
stopAllBtn.Position = UDim2.new(1, -170, 0.5, -buttonHeight/2)
stopAllBtn.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
stopAllBtn.Text = "Stop All"
stopAllBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
stopAllBtn.TextSize = 11 * fontSizeScale
stopAllBtn.Font = Enum.Font.GothamBold
stopAllBtn.BorderSizePixel = 0
stopAllBtn.ZIndex = footer.ZIndex + 1
stopAllBtn.Parent = footer
corner(stopAllBtn, 7)
stroke(stopAllBtn, Color3.fromRGB(80, 30, 30), 1)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -6, 0, -6)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.TextSize = 17 * fontSizeScale
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 10
closeBtn.Parent = panel
corner(closeBtn, 999)

-- Settings window (toggle)
local settingsWindow = nil
local function toggleSettings()
    if settingsWindow then
        settingsWindow:Destroy()
        settingsWindow = nil
    else
        settingsWindow = Instance.new("Frame")
        settingsWindow.Name = "SettingsWindow"
        settingsWindow.Size = UDim2.new(0, 300, 0, 200)
        settingsWindow.Position = UDim2.new(0.5, -150, 0.5, -100)
        settingsWindow.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
        settingsWindow.BorderSizePixel = 0
        settingsWindow.ZIndex = 50
        settingsWindow.Parent = screenGui
        corner(settingsWindow, 12)
        stroke(settingsWindow, Color3.fromRGB(30, 30, 45), 1)

        local settingsTitleBar = Instance.new("Frame")
        settingsTitleBar.Size = UDim2.new(1, 0, 0, 40)
        settingsTitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        settingsTitleBar.BorderSizePixel = 0
        settingsTitleBar.ZIndex = 51
        settingsTitleBar.Parent = settingsWindow
        corner(settingsTitleBar, 12)

        local settingsTitle = Instance.new("TextLabel")
        settingsTitle.Size = UDim2.new(1, -40, 1, 0)
        settingsTitle.Position = UDim2.new(0, 10, 0, 0)
        settingsTitle.BackgroundTransparency = 1
        settingsTitle.Text = "Settings"
        settingsTitle.TextColor3 = Color3.fromRGB(210, 210, 228)
        settingsTitle.TextSize = 14
        settingsTitle.Font = Enum.Font.GothamBold
        settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
        settingsTitle.ZIndex = 52
        settingsTitle.Parent = settingsTitleBar

        local closeSettingsBtn = Instance.new("TextButton")
        closeSettingsBtn.Size = UDim2.new(0, 24, 0, 24)
        closeSettingsBtn.Position = UDim2.new(1, -30, 0, 8)
        closeSettingsBtn.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
        closeSettingsBtn.Text = "X"
        closeSettingsBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
        closeSettingsBtn.TextSize = 14
        closeSettingsBtn.Font = Enum.Font.GothamBold
        closeSettingsBtn.BorderSizePixel = 0
        closeSettingsBtn.ZIndex = 52
        closeSettingsBtn.Parent = settingsTitleBar
        corner(closeSettingsBtn, 12)
        closeSettingsBtn.MouseButton1Click:Connect(function()
            if settingsWindow then
                settingsWindow:Destroy()
                settingsWindow = nil
            end
        end)

        -- Drag settings window
        local dragStartPos, dragStartMouse
        local draggingSettings = false
        settingsTitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSettings = true
                dragStartPos = settingsWindow.Position
                dragStartMouse = input.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if draggingSettings and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStartMouse
                settingsWindow.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSettings = false
            end
        end)

        local speedLabel = Instance.new("TextLabel")
        speedLabel.Size = UDim2.new(0, 140, 0, 30)
        speedLabel.Position = UDim2.new(0, 20, 0, 60)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = "Signals per second:"
        speedLabel.TextColor3 = Color3.fromRGB(170, 165, 220)
        speedLabel.TextSize = 12
        speedLabel.Font = Enum.Font.Gotham
        speedLabel.TextXAlignment = Enum.TextXAlignment.Left
        speedLabel.ZIndex = 51
        speedLabel.Parent = settingsWindow

        local speedBox = Instance.new("TextBox")
        speedBox.Size = UDim2.new(0, 100, 0, 30)
        speedBox.Position = UDim2.new(0, 170, 0, 60)
        speedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        speedBox.Text = tostring(autoSpeed)
        speedBox.TextColor3 = Color3.fromRGB(210, 210, 228)
        speedBox.TextSize = 12
        speedBox.Font = Enum.Font.Gotham
        speedBox.BorderSizePixel = 0
        speedBox.ZIndex = 51
        speedBox.Parent = settingsWindow
        corner(speedBox, 6)
        stroke(speedBox, Color3.fromRGB(55, 50, 85), 1)

        local speedHint = Instance.new("TextLabel")
        speedHint.Size = UDim2.new(0, 260, 0, 20)
        speedHint.Position = UDim2.new(0, 20, 0, 95)
        speedHint.BackgroundTransparency = 1
        speedHint.Text = "1 = slowest  |  10000 = fastest  |  Default: 100"
        speedHint.TextColor3 = Color3.fromRGB(120, 120, 158)
        speedHint.TextSize = 10
        speedHint.Font = Enum.Font.Gotham
        speedHint.TextXAlignment = Enum.TextXAlignment.Left
        speedHint.ZIndex = 51
        speedHint.Parent = settingsWindow

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 100, 0, 32)
        saveBtn.Position = UDim2.new(0.5, -50, 1, -45)
        saveBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        saveBtn.Text = "Save"
        saveBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
        saveBtn.TextSize = 12
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.BorderSizePixel = 0
        saveBtn.ZIndex = 51
        saveBtn.Parent = settingsWindow
        corner(saveBtn, 7)
        stroke(saveBtn, Color3.fromRGB(45, 80, 60), 1)

        local savedMsg = nil
        saveBtn.MouseButton1Click:Connect(function()
            local newSpeed = tonumber(speedBox.Text)
            if newSpeed then
                newSpeed = math.floor(newSpeed)
                if newSpeed >= 1 and newSpeed <= 10000 then
                    autoSpeed = newSpeed
                    speedBox.Text = tostring(autoSpeed)
                    speedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
                    if savedMsg then savedMsg:Destroy() end
                    savedMsg = Instance.new("TextLabel")
                    savedMsg.Size = UDim2.new(0, 100, 0, 20)
                    savedMsg.Position = UDim2.new(0.5, -50, 1, -20)
                    savedMsg.BackgroundTransparency = 1
                    savedMsg.Text = "Saved!"
                    savedMsg.TextColor3 = Color3.fromRGB(61, 255, 160)
                    savedMsg.TextSize = 10
                    savedMsg.Font = Enum.Font.GothamBold
                    savedMsg.ZIndex = 52
                    savedMsg.Parent = settingsWindow
                    task.wait(1.5)
                    if savedMsg then savedMsg:Destroy() end
                else
                    speedBox.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
                    task.wait(0.5)
                    speedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
                end
            else
                speedBox.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
                task.wait(0.5)
                speedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            end
        end)
    end
end

settingsBtn.MouseButton1Click:Connect(toggleSettings)

-- Visibility toggles
local uiVisible = true
local reopenButton = nil

local function showGui()
    if not screenGui.Enabled then
        screenGui.Enabled = true
        uiVisible = true
        if reopenButton then reopenButton.Visible = false end
    end
end

local function hideGui()
    if screenGui.Enabled then
        screenGui.Enabled = false
        uiVisible = false
        if isMobile then
            if not reopenButton or not reopenButton.Parent then
                reopenButton = Instance.new("TextButton")
                reopenButton.Size = UDim2.new(0, 56, 0, 56)
                reopenButton.Position = UDim2.new(1, -70, 1, -70)
                reopenButton.AnchorPoint = Vector2.new(1, 1)
                reopenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
                reopenButton.Text = "S"
                reopenButton.TextColor3 = Color3.fromRGB(210, 210, 228)
                reopenButton.TextSize = 24
                reopenButton.Font = Enum.Font.GothamBold
                reopenButton.BorderSizePixel = 0
                reopenButton.ZIndex = 100
                reopenButton.Parent = playerGui
                corner(reopenButton, 28)
                stroke(reopenButton, Color3.fromRGB(80, 70, 120), 1.5)

                local dragStartPos, dragStartMouse
                reopenButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragStartPos = reopenButton.Position
                        dragStartMouse = input.Position
                        local moveConn, endConn
                        moveConn = UserInputService.InputChanged:Connect(function(input2)
                            if input2.UserInputType == input.UserInputType then
                                local delta = input2.Position - dragStartMouse
                                reopenButton.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
                            end
                        end)
                        endConn = UserInputService.InputEnded:Connect(function(input2)
                            if input2.UserInputType == input.UserInputType then
                                moveConn:Disconnect()
                                endConn:Disconnect()
                            end
                        end)
                    end
                end)

                reopenButton.MouseButton1Click:Connect(showGui)
            else
                reopenButton.Visible = true
            end
        end
    end
end

closeBtn.MouseButton1Click:Connect(hideGui)

if not isMobile then
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            if uiVisible then hideGui() else showGui() end
        end
    end)
end

-- Log management
local eventCount = 0
local entries = {}
local suppressCounter = 0

local function fireFakeSignal(signalType, id)
    suppressCounter = suppressCounter + 1
    pcall(function()
        if signalType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif signalType == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Purchase" then
            MarketplaceService:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    suppressCounter = suppressCounter - 1
end

local function makeEmptyLabel()
    local el = Instance.new("TextLabel")
    el.Name = "EmptyState"
    el.Size = UDim2.new(1, 0, 0, 260)
    el.BackgroundTransparency = 1
    el.Text = "Waiting for events…\nAll marketplace events will appear here."
    el.TextColor3 = Color3.fromRGB(120, 120, 158)
    el.TextSize = 13 * fontSizeScale
    el.Font = Enum.Font.Gotham
    el.TextWrapped = true
    el.LayoutOrder = 99999
    el.Parent = logArea
    return el
end

local function setEmpty(show)
    local e = logArea:FindFirstChild("EmptyState")
    if show and not e then
        makeEmptyLabel()
    elseif not show and e then
        e:Destroy()
    end
end

local activeAutoButtons = {}
local activeSpamButtons = {}

local function stopAllAutoAndSpam()
    for btn, data in pairs(activeAutoButtons) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Auto"
            btn.TextColor3 = Color3.fromRGB(170, 165, 220)
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end
    table.clear(activeAutoButtons)
    for btn, data in pairs(activeSpamButtons) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Run"
            btn.TextColor3 = Color3.fromRGB(170, 165, 220)
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end
    table.clear(activeSpamButtons)
end

stopAllBtn.MouseButton1Click:Connect(stopAllAutoAndSpam)

local function addLog(label, id, signalType)
    if suppressCounter > 0 then return end
    setEmpty(false)
    local entryHeight = isMobile and 56 or 46
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -2, 0, entryHeight)
    entry.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
    entry.BorderSizePixel = 0
    entry.LayoutOrder = -(eventCount)
    entry.Parent = logArea
    corner(entry, 10)
    stroke(entry, Color3.fromRGB(48, 46, 70), 1)
    entry.BackgroundTransparency = 1
    TweenService:Create(entry, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(61, 255, 160)
    dot.BorderSizePixel = 0
    dot.Parent = entry
    corner(dot, 999)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 76, 1, 0)
    lbl.Position = UDim2.new(0, 28, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(label)
    lbl.TextColor3 = Color3.fromRGB(160, 150, 210)
    lbl.TextSize = 10 * fontSizeScale
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = entry

    local idEl = Instance.new("TextLabel")
    idEl.Size = UDim2.new(0, 200, 1, 0)
    idEl.Position = UDim2.new(0, 108, 0, 0)
    idEl.BackgroundTransparency = 1
    idEl.Text = tostring(id)
    idEl.TextColor3 = Color3.fromRGB(220, 220, 240)
    idEl.TextSize = 14 * fontSizeScale
    idEl.Font = Enum.Font.GothamBold
    idEl.TextXAlignment = Enum.TextXAlignment.Left
    idEl.TextTruncate = Enum.TextTruncate.AtEnd
    idEl.Parent = entry

    local timeEl = Instance.new("TextLabel")
    timeEl.Size = UDim2.new(0, 70, 1, 0)
    timeEl.Position = UDim2.new(0, 320, 0, 0)
    timeEl.BackgroundTransparency = 1
    timeEl.Text = getTime()
    timeEl.TextColor3 = Color3.fromRGB(140, 135, 180)
    timeEl.TextSize = 11 * fontSizeScale
    timeEl.Font = Enum.Font.Gotham
    timeEl.Parent = entry

    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(0, 200, 1, 0)
    buttonFrame.Position = UDim2.new(1, -200, 0, 0)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = entry

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0, 56, 0, buttonHeight)
    autoBtn.Position = UDim2.new(0, 0, 0.5, -buttonHeight/2)
    autoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    autoBtn.Text = "Auto"
    autoBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
    autoBtn.TextSize = 11 * fontSizeScale
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    autoBtn.Parent = buttonFrame
    corner(autoBtn, 7)
    stroke(autoBtn, Color3.fromRGB(55, 50, 85), 1)

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 56, 0, buttonHeight)
    copyBtn.Position = UDim2.new(0, 62, 0.5, -buttonHeight/2)
    copyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    copyBtn.Text = "Copy"
    copyBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
    copyBtn.TextSize = 11 * fontSizeScale
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.BorderSizePixel = 0
    copyBtn.Parent = buttonFrame
    corner(copyBtn, 7)
    stroke(copyBtn, Color3.fromRGB(55, 50, 85), 1)

    local runBtn = Instance.new("TextButton")
    runBtn.Size = UDim2.new(0, 52, 0, buttonHeight)
    runBtn.Position = UDim2.new(0, 124, 0.5, -buttonHeight/2)
    runBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    runBtn.Text = "Run"
    runBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
    runBtn.TextSize = 11 * fontSizeScale
    runBtn.Font = Enum.Font.GothamBold
    runBtn.BorderSizePixel = 0
    runBtn.Parent = buttonFrame
    corner(runBtn, 7)
    stroke(runBtn, Color3.fromRGB(55, 50, 85), 1)

    copyBtn.MouseEnter:Connect(function()
        copyBtn.TextColor3 = Color3.fromRGB(190, 180, 255)
        copyBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 40)
    end)
    copyBtn.MouseLeave:Connect(function()
        if copyBtn.Text ~= "Copied!" then
            copyBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            copyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(setclipboard, tostring(id))
        copyBtn.Text = "Copied!"
        copyBtn.TextColor3 = Color3.fromRGB(200, 190, 255)
        task.wait(1.5)
        copyBtn.Text = "Copy"
        copyBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
        copyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    end)

    local autoActive = false
    local autoLoop = nil
    local function startAuto()
        if autoActive then return end
        autoActive = true
        autoBtn.Text = "Auto ON"
        autoBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        autoBtn.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
        autoLoop = task.spawn(function()
            local delay = autoSpeed > 0 and (1 / autoSpeed) or 0.01
            while autoActive and autoBtn.Parent do
                fireFakeSignal(signalType, id)
                task.wait(delay)
            end
        end)
        activeAutoButtons[autoBtn] = {active = true, loop = autoLoop}
    end
    local function stopAuto()
        autoActive = false
        if autoLoop then task.cancel(autoLoop) end
        activeAutoButtons[autoBtn] = nil
        if autoBtn.Parent then
            autoBtn.Text = "Auto"
            autoBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            autoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end
    autoBtn.MouseButton1Click:Connect(function()
        if autoActive then stopAuto() else startAuto() end
    end)

    local holdStart = nil
    local holdConnection = nil
    local spamLoop = nil
    local isSpamming = false
    local function startSpam()
        if isSpamming then return end
        isSpamming = true
        runBtn.Text = "Spamming..."
        runBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
        spamLoop = task.spawn(function()
            while isSpamming and runBtn.Parent do
                fireFakeSignal(signalType, id)
                task.wait(0.1)
            end
        end)
        activeSpamButtons[runBtn] = {active = true, loop = spamLoop}
    end
    local function stopSpam()
        isSpamming = false
        if spamLoop then task.cancel(spamLoop) end
        activeSpamButtons[runBtn] = nil
        if runBtn.Parent then
            runBtn.Text = "Run"
            runBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            runBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end

    -- Use InputBegan/InputEnded for both mouse and touch
    local function onRunPress()
        if isSpamming then return end
        holdStart = tick()
        holdConnection = task.spawn(function()
            while holdStart and (tick() - holdStart) < 3 do
                task.wait(0.1)
            end
            if holdStart and not isSpamming then
                startSpam()
            end
        end)
    end

    local function onRunRelease()
        local heldDuration = holdStart and (tick() - holdStart) or 0
        holdStart = nil
        if holdConnection then task.cancel(holdConnection) end
        if isSpamming then
            stopSpam()
        elseif heldDuration < 3 then
            fireFakeSignal(signalType, id)
            runBtn.Text = "Sent!"
            runBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
            task.wait(1.5)
            if runBtn.Parent then
                runBtn.Text = "Run"
                runBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            end
        end
    end

    runBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onRunPress()
        end
    end)
    runBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onRunRelease()
        end
    end)

    runBtn.MouseEnter:Connect(function()
        if not isSpamming then
            runBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
            runBtn.BackgroundColor3 = Color3.fromRGB(10, 22, 18)
        end
    end)
    runBtn.MouseLeave:Connect(function()
        if not isSpamming and runBtn.Text == "Run" then
            runBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            runBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end)

    entry.AncestryChanged:Connect(function()
        if not entry.Parent then
            if autoActive then stopAuto() end
            if isSpamming then stopSpam() end
            for i, e in ipairs(entries) do
                if e == entry then
                    table.remove(entries, i)
                    break
                end
            end
        end
    end)

    eventCount = eventCount + 1
    countLabel.Text = eventCount .. (eventCount == 1 and " event captured" or " events captured")
    table.insert(entries, entry)
end

clearBtn.MouseButton1Click:Connect(function()
    stopAllAutoAndSpam()
    for _, e in ipairs(entries) do
        e:Destroy()
    end
    entries = {}
    eventCount = 0
    countLabel.Text = "0 events captured"
    setEmpty(true)
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(plr, id, bought)
    if suppressCounter == 0 then addLog("Product", id, "Product") end
end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, bought)
    if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
end)
MarketplaceService.PromptBulkPurchaseFinished:Connect(function(userId, id, bought)
    if suppressCounter == 0 then addLog("Bulk", id, "Bulk") end
end)
MarketplaceService.PromptPurchaseFinished:Connect(function(userId, id, bought)
    if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
end)

setEmpty(true)
