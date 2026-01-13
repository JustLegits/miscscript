-- Configuration
local Config = {
    AutoSpin = false,
    SelectedTraits = {}, 
    
    -- TIMING SETTINGS
    RollSpeed = 0.1,       -- Normal rolling speed
    PopupRetryDelay = 1.5, -- Wait time if popup gets stubborn
    
    -- OFFSET ADJUSTMENT
    Y_Offset = 0 
}

-- Services
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

-- // UI SETUP //
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local TraitScroll = Instance.new("ScrollingFrame")
local ToggleButton = Instance.new("TextButton")
local RefreshButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local DebugFolder = Instance.new("Folder", ScreenGui)

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

ScreenGui.Name = "AnimeStorySpinUI_v14_GhostFix"
ScreenGui.ResetOnSpawn = false 

-- Styling
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
MainFrame.Size = UDim2.new(0, 300, 0, 380)
MainFrame.Active = true
MainFrame.Draggable = true 
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Anime Story Auto-Spin"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
Instance.new("UICorner", TitleLabel).CornerRadius = UDim.new(0, 10)

TraitScroll.Parent = MainFrame
TraitScroll.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TraitScroll.Position = UDim2.new(0.05, 0, 0.15, 0)
TraitScroll.Size = UDim2.new(0.9, 0, 0.55, 0)
TraitScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TraitScroll.ScrollBarThickness = 6

ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60) 
ToggleButton.Position = UDim2.new(0.05, 0, 0.75, 0)
ToggleButton.Size = UDim2.new(0.6, 0, 0.1, 0)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "START SPINNING"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)

RefreshButton.Parent = MainFrame
RefreshButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
RefreshButton.Position = UDim2.new(0.7, 0, 0.75, 0)
RefreshButton.Size = UDim2.new(0.25, 0, 0.1, 0)
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.Text = "Refresh"
RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshButton.TextSize = 14
Instance.new("UICorner", RefreshButton).CornerRadius = UDim.new(0, 8)

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
StatusLabel.Position = UDim2.new(0.05, 0, 0.88, 0)
StatusLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
StatusLabel.TextSize = 14
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)

-- // HELPER FUNCTIONS //

local function UpdateStatus(text)
    StatusLabel.Text = "Status: " .. text
end

local function SpawnDebugDot(x, y)
    local dot = Instance.new("Frame")
    dot.Parent = DebugFolder
    dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, x - 4, 0, y - 4)
    dot.ZIndex = 100
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    game.Debris:AddItem(dot, 0.5)
end

local function ForceClick(btn)
    if not btn or not btn.Visible then return end
    
    pcall(function()
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local inset = GuiService:GetGuiInset() 
        
        if pos.X < 1 and pos.Y < 1 then return end

        local centerX = pos.X + size.X/2
        local centerY = pos.Y + size.Y/2 + inset.Y + Config.Y_Offset
        
        SpawnDebugDot(centerX, centerY - inset.Y) 
        
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait() 
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    end)
    
    pcall(function()
        for _, event in pairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
            if btn[event] then
                for _, connection in pairs(getconnections(btn[event])) do
                    connection:Fire()
                end
            end
        end
    end)
end

local function PopulateTraitList()
    local PGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PGui then return end

    local path = PGui:FindFirstChild("main") and PGui.main:FindFirstChild("Traits") and PGui.main.Traits.Index.ScrollingFrame
    if not path then 
        UpdateStatus("Open Trait Menu first!")
        return 
    end
    
    for _, v in pairs(TraitScroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    
    local foundTraits = {}
    for _, v in pairs(path:GetChildren()) do
        if v:IsA("ImageLabel") then
            table.insert(foundTraits, v.Name)
        end
    end
    table.sort(foundTraits)
    
    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.Parent = TraitScroll
    GridLayout.CellSize = UDim2.new(0.45, 0, 0, 30)
    GridLayout.CellPadding = UDim2.new(0.05, 0, 0.02, 0)
    
    for _, traitName in pairs(foundTraits) do
        local btn = Instance.new("TextButton")
        btn.Parent = TraitScroll
        btn.Name = traitName
        btn.Text = traitName
        btn.Font = Enum.Font.Gotham
        btn.BackgroundColor3 = Config.SelectedTraits[traitName] and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(80, 80, 80)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedTraits[traitName] then
                Config.SelectedTraits[traitName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80) 
            else
                Config.SelectedTraits[traitName] = true
                btn.BackgroundColor3 = Color3.fromRGB(60, 200, 60) 
            end
        end)
    end
    
    local rowCount = math.ceil(#foundTraits / 2)
    TraitScroll.CanvasSize = UDim2.new(0, 0, 0, rowCount * 40)
    UpdateStatus("List Refreshed")
end

local function UpdateState(state)
    Config.AutoSpin = state
    if state then
        ToggleButton.Text = "STOP SPINNING"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        UpdateStatus("Starting...")
    else
        ToggleButton.Text = "START SPINNING"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        UpdateStatus("Stopped")
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    UpdateState(not Config.AutoSpin)
end)

RefreshButton.MouseButton1Click:Connect(PopulateTraitList)

-- // MAIN LOGIC THREAD //
task.spawn(function()
    while true do
        task.wait(Config.RollSpeed)
        
        if Config.AutoSpin then
            pcall(function()
                local PGui = LocalPlayer:FindFirstChild("PlayerGui")
                if not PGui then return end
                
                local mainGui = PGui:FindFirstChild("main")
                if not mainGui then return end
                
                local traitsFrame = mainGui:FindFirstChild("Traits")
                local confirmFrame = mainGui:FindFirstChild("Confirm")
                
                -- READ TRAIT NAME
                local currentTraitName = "Unknown"
                if traitsFrame then
                    local label = traitsFrame:FindFirstChild("Base") 
                        and traitsFrame.Base:FindFirstChild("Content") 
                        and traitsFrame.Base.Content:FindFirstChild("Trait")
                        and traitsFrame.Base.Content.Trait:FindFirstChild("Text") 
                    
                    if label and label:IsA("TextLabel") then
                        currentTraitName = label.Text
                    end
                end
                
                local hasDesired = Config.SelectedTraits[currentTraitName] ~= nil

                -- ==========================================
                -- LOGIC PART 1: POPUP HANDLING
                -- ==========================================
                local popupActuallyVisible = false
                
                if confirmFrame and confirmFrame.Visible then
                    -- GHOST CHECK: Is the button actually on screen?
                    local btns = confirmFrame:FindFirstChild("Base") 
                        and confirmFrame.Base:FindFirstChild("Content") 
                        and confirmFrame.Base.Content:FindFirstChild("Buttons")
                    
                    if btns and btns:FindFirstChild("Yes") then
                        -- Check X Position. If it's near 0 or off screen, it's a ghost.
                        if btns.Yes.AbsolutePosition.X > 50 then
                             popupActuallyVisible = true
                             
                             if hasDesired then
                                UpdateStatus("POPUP: GOT " .. currentTraitName .. "! Keeping.")
                                UpdateState(false)
                                ForceClick(btns.No)
                            else
                                UpdateStatus("POPUP: Skipping " .. currentTraitName .. "...")
                                ForceClick(btns.Yes)
                                -- Small wait to prevent double clicking
                                task.wait(0.5)
                            end
                            return -- STOP HERE if popup is real
                        else
                             -- Debug info: Found ghost popup
                        end
                    end
                end

                -- ==========================================
                -- LOGIC PART 2: NORMAL ROLL
                -- ==========================================
                -- If we get here, either Popup is NOT visible OR it is a "Ghost"
                if traitsFrame and traitsFrame.Visible then
                    if hasDesired then
                        UpdateStatus("GOT: " .. currentTraitName)
                        UpdateState(false)
                    else
                        UpdateStatus("Rolling... (" .. currentTraitName .. ")")
                        local rollBtn = traitsFrame.Base.Content.Buttons.Roll
                        ForceClick(rollBtn)
                    end
                else
                    UpdateStatus("Waiting for UI... (Ghost Mode Active)")
                end
            end)
        end
    end
end)

PopulateTraitList()
