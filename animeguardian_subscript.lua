local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Anime Guardian Sub-Script | Kero :333",
   LoadingTitle = "MOEWTIE",
   LoadingSubtitle = "Modified Version (Lobby TP)",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AnimeGuardianSub_V4",
      FileName = "KeroConfig"
   },
   KeySystem = false,
})

-- =============================================
-- VARIABLES & SERVICES
-- =============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- Lobby Variables
local selectedStage = "City of Shattered Frost" 
local isFriendOnly = true
local isAutoHosting = false
local hostDelay = 0

-- Restart & Runs Variables
local targetCoins = 0
local targetWave = 0
local isAutoRestart = false
local isAutoLobby = false -- [NEW]
local targetRuns = 0      -- [NEW]
local currentRunCount = 0 -- [NEW]

-- Teleport Variables
local isAutoBeherit = false
local targetBeherit = 0
local isAutoAncient = false
local targetAncient = 0

-- Shop Variables
local isAutoBuyCapsule = false
local buyCapsuleAmount = 1
local isAutoOpenCapsule = false
local openCapsuleAmount = 1

-- Modifier Variables
local isAutoBuy = false
local targetBuyWave = 0
local prioritySlot1 = "Saiya"
local prioritySlot2 = "Time Snare"
local prioritySlot3 = "Power Surge"
local prioritySlot4 = "None"

-- Defaults
local modifierList = {"None", "Golden Tribute", "Power Surge", "Saiya", "Time Snare"}
local defaultStages = {"City of Shattered Frost", "Priestella", "Roswaal Mansion"}

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

local function getAvailableStages()
    local list = {}
    local stagesFolder = LocalPlayer:WaitForChild("Stages", 3) 
    if stagesFolder then
        for _, stageObj in ipairs(stagesFolder:GetChildren()) do
            table.insert(list, stageObj.Name)
        end
    end
    if #list == 0 then return defaultStages end
    table.sort(list)
    return list
end

local function cleanNumber(str)
    if not str then return 0 end
    local cleanStr = string.gsub(str, "%D", "") 
    return tonumber(cleanStr) or 0
end

local function getMyMoney()
    local mainGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
    if mainGui then
        local unitBar = mainGui:FindFirstChild("UnitBar")
        if unitBar then
            local dataFrame = unitBar:FindFirstChild("DataFrame")
            if dataFrame then
                local coinsLabel = dataFrame:FindFirstChild("Coins")
                if coinsLabel then return cleanNumber(coinsLabel.Text) end
            end
        end
    end
    return 0
end

local function getModifierPrice(modName)
    local npcShop = LocalPlayer.PlayerGui:FindFirstChild("Npc_Shop")
    if npcShop then
        local modShop = npcShop:FindFirstChild("ModifierShop")
        if modShop then
            local inset = modShop:FindFirstChild("Inset")
            if inset then
                local scroll = inset:FindFirstChild("ScrollingFrame")
                if scroll then
                    local item = scroll:FindFirstChild(modName)
                    if item then
                        local priceLabel = item:FindFirstChild("PriceText")
                        if priceLabel then return cleanNumber(priceLabel.Text) end
                    end
                end
            end
        end
    end
    return 999999999 
end

local function getCurrentWave()
    if LocalPlayer.PlayerGui:FindFirstChild("GUI") 
       and LocalPlayer.PlayerGui.GUI:FindFirstChild("BaseFrame") 
       and LocalPlayer.PlayerGui.GUI.BaseFrame:FindFirstChild("Wave") then
        
        local waveText = LocalPlayer.PlayerGui.GUI.BaseFrame.Wave.Text
        return cleanNumber(waveText)
    end
    return 0
end

-- =============================================
-- TAB 1: LOBBY MANAGER
-- =============================================
local LobbyTab = Window:CreateTab("Lobby Manager", 4483362458)

LobbyTab:CreateSection("Room Settings")

local StageDropdown = LobbyTab:CreateDropdown({
   Name = "Select Stage",
   Options = getAvailableStages(), 
   CurrentOption = {defaultStages[1]},
   MultipleOptions = false,
   Flag = "Lobby_Stage",
   Callback = function(Option)
      selectedStage = Option[1]
   end,
})

LobbyTab:CreateButton({
   Name = "Refresh List",
   Callback = function()
       local newStages = getAvailableStages()
       StageDropdown:Refresh(newStages, true)
       Rayfield:Notify({Title = "Updated", Content = "Found " .. #newStages .. " stages.", Duration = 2})
   end,
})

LobbyTab:CreateToggle({
   Name = "Friend Only",
   CurrentValue = true,
   Flag = "Lobby_FriendOnly", 
   Callback = function(Value)
      isFriendOnly = Value
   end,
})

LobbyTab:CreateSection("Automation")

LobbyTab:CreateToggle({
   Name = "Auto Host",
   CurrentValue = false,
   Flag = "Lobby_AutoHost", 
   Callback = function(Value)
      isAutoHosting = Value
   end,
})

LobbyTab:CreateSlider({
   Name = "Start Delay (Seconds)",
   Range = {0, 30},
   Increment = 1,
   Suffix = "s",
   CurrentValue = 0,
   Flag = "Lobby_StartDelay", 
   Callback = function(Value)
      hostDelay = Value
   end,
})

-- =============================================
-- TAB 2: IN-GAME MANAGER
-- =============================================
local GameTab = Window:CreateTab("In-Game Manager", 4483362458)

-- --- SECTION: MODIFIER SHOP ---
GameTab:CreateSection("Modifier Shop")

GameTab:CreateToggle({
   Name = "Auto Buy Modifiers",
   CurrentValue = false,
   Flag = "Shop_AutoBuy",
   Callback = function(Value)
      isAutoBuy = Value
   end,
})

GameTab:CreateInput({
   Name = "Min Wave to Buy",
   PlaceholderText = "0 to disable (Buy instantly)",
   RemoveTextAfterFocusLost = false,
   Flag = "Shop_MinWave",
   Callback = function(Text)
       targetBuyWave = tonumber(Text) or 0
   end,
})

GameTab:CreateLabel("Priority Order:")

GameTab:CreateDropdown({
   Name = "Priority 1",
   Options = modifierList,
   CurrentOption = {"Golden Tribute"},
   MultipleOptions = false,
   Flag = "Shop_Slot1",
   Callback = function(Option) prioritySlot1 = Option[1] end,
})

GameTab:CreateDropdown({
   Name = "Priority 2",
   Options = modifierList,
   CurrentOption = {"Power Surge"},
   MultipleOptions = false,
   Flag = "Shop_Slot2",
   Callback = function(Option) prioritySlot2 = Option[1] end,
})

GameTab:CreateDropdown({
   Name = "Priority 3",
   Options = modifierList,
   CurrentOption = {"Saiya"},
   MultipleOptions = false,
   Flag = "Shop_Slot3",
   Callback = function(Option) prioritySlot3 = Option[1] end,
})

GameTab:CreateDropdown({
   Name = "Priority 4",
   Options = modifierList,
   CurrentOption = {"Time Snare"},
   MultipleOptions = false,
   Flag = "Shop_Slot4",
   Callback = function(Option) prioritySlot4 = Option[1] end,
})

-- --- SECTION: AUTO RESTART ---
GameTab:CreateSection("Auto Restart")

GameTab:CreateToggle({
   Name = "Auto Restart",
   CurrentValue = false,
   Flag = "Restart_Master", 
   Callback = function(Value)
      isAutoRestart = Value
   end,
})

GameTab:CreateInput({
   Name = "Target Coins",
   PlaceholderText = "0 to disable",
   RemoveTextAfterFocusLost = false,
   Flag = "Restart_Coins", 
   Callback = function(Text)
       targetCoins = tonumber(Text) or 0
   end,
})

GameTab:CreateInput({
   Name = "Target Wave",
   PlaceholderText = "0 to disable",
   RemoveTextAfterFocusLost = false,
   Flag = "Restart_Wave", 
   Callback = function(Text)
       targetWave = tonumber(Text) or 0
   end,
})

-- [NEW] Lobby Teleport Settings
GameTab:CreateLabel("--- Lobby TP Settings ---")

GameTab:CreateToggle({
   Name = "Teleport to Lobby After Runs",
   CurrentValue = false,
   Flag = "Restart_AutoLobby", 
   Callback = function(Value)
      isAutoLobby = Value
   end,
})

GameTab:CreateInput({
   Name = "Target Runs Amount",
   PlaceholderText = "How many runs before Lobby?",
   RemoveTextAfterFocusLost = false,
   Flag = "Restart_TargetRuns", 
   Callback = function(Text)
       targetRuns = tonumber(Text) or 0
   end,
})

local StatusLabel = GameTab:CreateLabel("Status: Waiting...")
local RunStatusLabel = GameTab:CreateLabel("Runs Completed: 0 / 0")

-- --- SECTION: AUTO TELEPORT (FARM) ---
GameTab:CreateSection("Auto Teleport (Item Farm)")

-- Beherit
GameTab:CreateToggle({
   Name = "TP on Beherit Amount",
   CurrentValue = false,
   Flag = "TP_Beherit_Toggle",
   Callback = function(Value)
      isAutoBeherit = Value
   end,
})

GameTab:CreateInput({
   Name = "Target Beherit",
   PlaceholderText = "e.g., 10000",
   RemoveTextAfterFocusLost = false,
   Flag = "TP_Beherit_Input",
   Callback = function(Text)
       targetBeherit = tonumber(Text) or 0
   end,
})

-- Ancient (Dragonpoints)
GameTab:CreateToggle({
   Name = "TP on Ancient Points",
   CurrentValue = false,
   Flag = "TP_Ancient_Toggle",
   Callback = function(Value)
      isAutoAncient = Value
   end,
})

GameTab:CreateInput({
   Name = "Target Ancient Points",
   PlaceholderText = "e.g., 10000",
   RemoveTextAfterFocusLost = false,
   Flag = "TP_Ancient_Input",
   Callback = function(Text)
       targetAncient = tonumber(Text) or 0
   end,
})

local TeleportLabel = GameTab:CreateLabel("Inventory: Waiting...")

-- =============================================
-- TAB 3: SHOP MANAGER
-- =============================================
local ShopTab = Window:CreateTab("Shop Manager", 4483362458)

ShopTab:CreateSection("Ragna Capsule (Event)")

-- Auto Buy
ShopTab:CreateInput({
   Name = "Buy Amount",
   PlaceholderText = "Default: 1",
   RemoveTextAfterFocusLost = false,
   Flag = "Ragna_BuyAmount",
   Callback = function(Text)
       buyCapsuleAmount = tonumber(Text) or 1
   end,
})

ShopTab:CreateToggle({
   Name = "Auto Buy Capsule (1s Loop)",
   CurrentValue = false,
   Flag = "Ragna_AutoBuy",
   Callback = function(Value)
      isAutoBuyCapsule = Value
   end,
})

-- Auto Open
ShopTab:CreateInput({
   Name = "Open Amount",
   PlaceholderText = "Default: 1",
   RemoveTextAfterFocusLost = false,
   Flag = "Ragna_OpenAmount",
   Callback = function(Text)
       openCapsuleAmount = tonumber(Text) or 1
   end,
})

ShopTab:CreateToggle({
   Name = "Auto Open Capsule (1s Loop)",
   CurrentValue = false,
   Flag = "Ragna_AutoOpen",
   Callback = function(Value)
      isAutoOpenCapsule = Value
   end,
})


-- =============================================
-- LOGIC LOOPS
-- =============================================

-- 1. Auto Host Loop
task.spawn(function()
    while true do
        if isAutoHosting then
            local RoomFunction = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("RoomFunction")
            if RoomFunction then
                pcall(function()
                    local args = {
                        [1] = "host",
                        [2] = { ["stage"] = selectedStage, ["friendOnly"] = isFriendOnly }
                    }
                    RoomFunction:InvokeServer(unpack(args))
                    task.wait(1.5 + hostDelay)
                    RoomFunction:InvokeServer("start")
                end)
                task.wait(3)
            end
        end
        task.wait(1)
    end
end)

-- =============================================
-- 2. Run Counter, Lobby TP & Auto Restart (FIXED VISIBILITY & LOGIC)
-- =============================================
local hasCountedThisRun = false 

task.spawn(function()
    while true do
        -- 1. Get Current Data
        local currentCoin = 0
        local isGameOver = false
        
        -- Check for Game Over (Reward Screen) AND MAKE SURE IT IS VISIBLE
        if LocalPlayer.PlayerGui:FindFirstChild("GUI") 
           and LocalPlayer.PlayerGui.GUI:FindFirstChild("BaseFrame") 
           and LocalPlayer.PlayerGui.GUI.BaseFrame:FindFirstChild("RewardFrame") then
            
            local rewardFrame = LocalPlayer.PlayerGui.GUI.BaseFrame.RewardFrame
            
            -- FIX: Only count if the frame is actually visible on screen
            if rewardFrame.Visible then
                isGameOver = true
                if rewardFrame:FindFirstChild("ChristmasCoin") then
                    currentCoin = cleanNumber(rewardFrame.ChristmasCoin.Text)
                end
            end
        end
        
        local currentWave = getCurrentWave()

        -- Update Labels
        StatusLabel:Set("Coin: " .. currentCoin .. " / " .. targetCoins .. " | Wave: " .. currentWave .. " / " .. targetWave)
        RunStatusLabel:Set("Runs Completed: " .. currentRunCount .. " / " .. targetRuns)

        -- 2. Reset Counter Flag (Critical Fix)
        -- If we are currently at a wave LOWER than our target, it means we must have restarted.
        -- So we reset the flag to allow counting again when we reach the target.
        if targetWave > 0 then
            if currentWave < targetWave then
                hasCountedThisRun = false
            end
        else
            -- If target is 0 (counting by Game Over), reset only at the start
            if currentWave <= 1 and not isGameOver then
                hasCountedThisRun = false
            end
        end

        -- 3. Check Conditions to Count a Run
        local targetReached = false
        
        -- A. Reached Target Wave
        if targetWave > 0 and currentWave >= targetWave then
            targetReached = true
        end
        
        -- B. Game Over (Always counts as a run finish)
        if isGameOver then
            targetReached = true
        end

        -- C. Reached Target Coins
        if targetCoins > 0 and currentCoin >= targetCoins then
            targetReached = true
        end

        -- 4. EXECUTE COUNTING
        if targetReached and not hasCountedThisRun then
            currentRunCount = currentRunCount + 1
            hasCountedThisRun = true -- Lock it so we don't count this run again
            RunStatusLabel:Set("Runs Completed: " .. currentRunCount .. " / " .. targetRuns)
            
            -- Check Lobby Teleport Logic
            if isAutoLobby and targetRuns > 0 and currentRunCount >= targetRuns then
                Rayfield:Notify({Title = "COMPLETE", Content = "Target Runs Reached! Teleporting in 5s...", Duration = 5})
                
                task.wait(5) 
                
                local args = { "Lobby" }
                local TeleportRemote = ReplicatedStorage:FindFirstChild("Remotes")
                    and ReplicatedStorage.Remotes:FindFirstChild("Misc")
                    and ReplicatedStorage.Remotes.Misc:FindFirstChild("Teleport")
                
                if TeleportRemote then
                    TeleportRemote:FireServer(unpack(args))
                end
                
                task.wait(9999) 
            end
        end

        -- 5. EXECUTE RESTART (Only if Toggle is ON)
        if isAutoRestart and targetReached then
            local MiscAction = ReplicatedStorage:FindFirstChild("Remotes") 
                               and ReplicatedStorage.Remotes:FindFirstChild("Misc") 
                               and ReplicatedStorage.Remotes.Misc:FindFirstChild("Action")
            
            if MiscAction then
                -- Only restart if we haven't just restarted (simple debounce)
                pcall(function() MiscAction:FireServer("Restart") end)
                task.wait(10)
                hasCountedThisRun = false 
            end
        end

        task.wait(0.5)
    end
end)

-- 3. Auto Buy Modifier Loop (CHECK WAVE)
task.spawn(function()
    while true do
        if isAutoBuy then
            local currentWave = getCurrentWave()
            
            if currentWave >= targetBuyWave then
                local myMoney = getMyMoney()
                local ModifierShop = ReplicatedStorage:FindFirstChild("ModifierShop")
                local currentQueue = {prioritySlot1, prioritySlot2, prioritySlot3, prioritySlot4}

                if ModifierShop then
                    for _, modName in ipairs(currentQueue) do
                        if modName and modName ~= "None" then
                            local price = getModifierPrice(modName)
                            if myMoney >= price then
                                pcall(function()
                                    ModifierShop:InvokeServer(modName)
                                    myMoney = myMoney - price 
                                end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- 4. Auto Teleport Loop (Beherit & Ancient)
task.spawn(function()
    while true do
        local inv = LocalPlayer:FindFirstChild("ItemsInventory")
        local currentBeherit = 0
        local currentAncient = 0
        
        if inv then
            if inv:FindFirstChild("Beherit") and inv.Beherit:FindFirstChild("Amount") then
                currentBeherit = inv.Beherit.Amount.Value
            end
            if inv:FindFirstChild("Dragonpoints") and inv.Dragonpoints:FindFirstChild("Amount") then
                currentAncient = inv.Dragonpoints.Amount.Value
            end
        end
        
        TeleportLabel:Set("Beherit: " .. currentBeherit .. " | Ancient: " .. currentAncient)
        
        if isAutoBeherit and targetBeherit > 0 and currentBeherit >= targetBeherit then
            Rayfield:Notify({Title = "Teleporting", Content = "Beherit Target Reached!", Duration = 3})
            TeleportService:Teleport(17282336195, LocalPlayer)
            break
        end

        if isAutoAncient and targetAncient > 0 and currentAncient >= targetAncient then
            Rayfield:Notify({Title = "Teleporting", Content = "Ancient Points Target Reached!", Duration = 3})
            TeleportService:Teleport(17282336195, LocalPlayer)
            break
        end
        
        task.wait(5)
    end
end)

-- 5. Auto Buy Ragna Capsule Loop
task.spawn(function()
    while true do
        if isAutoBuyCapsule and buyCapsuleAmount > 0 then
            local PlayMode = ReplicatedStorage:FindFirstChild("PlayMode")
            local Events = PlayMode and PlayMode:FindFirstChild("Events")
            local EventShop = Events and Events:FindFirstChild("EventShop")
            
            if EventShop then
                pcall(function()
                    local args = {
                        [1] = buyCapsuleAmount,
                        [2] = "Ragna Capsule",
                        [3] = "RagnaShop"
                    }
                    EventShop:InvokeServer(unpack(args))
                end)
            end
        end
        task.wait(1)
    end
end)

-- 6. Auto Open Ragna Capsule Loop
task.spawn(function()
    while true do
        if isAutoOpenCapsule and openCapsuleAmount > 0 then
            local PlayMode = ReplicatedStorage:FindFirstChild("PlayMode")
            local Events = PlayMode and PlayMode:FindFirstChild("Events")
            local UseEvent = Events and Events:FindFirstChild("Use")
            
            if UseEvent then
                pcall(function()
                    local args = {
                        [1] = "Ragna Capsule",
                        [2] = openCapsuleAmount
                    }
                    UseEvent:InvokeServer(unpack(args))
                end)
            end
        end
        task.wait(1)
    end
end)

Rayfield:LoadConfiguration()