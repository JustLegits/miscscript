repeat task.wait() until game:IsLoaded()



-- Anti-AFK
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new(0, 0))
end)

-- ▶▶ Starlight UI Library (replaces MacLib)
-- Docs: https://docs.nebulasoftworks.xyz/starlight
local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))() 
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// PERSISTENCE //////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local folderName = "Shouko_ARX"
local playerName = game.Players.LocalPlayer.Name
local fileName = playerName .. "_data.json"

if not isfolder(folderName) then
    makefolder(folderName)
end

local defaultSettings = {
    autoPlay = false,
    autoUpgrade = false,
    autoStart = false,
    autoNext = false,
    autoRetry = false,
    autoLeave = false,
    webhookURL = "",
    webhookEnabled = false,
    playAfterUpgrade = false,
    selectedActs = {},
    autoClaimQuest = false,
    autoEvolveRare = false,
    slots = {
        place = {true, true, true, true, true, true},
        upgrade = {0, 0, 0, 0, 0, 0}
    },
    selectPotential = {},
    selectStats     = {},
    selectUnit      = "",
    startRoll       = false,
    autoReloadOnTeleport = false,
    autoJoinChallenge = false,
    deleteMap = false,
    autoPortal = false,
    autoRejoin = false,
    autoJoinPortal = false,
    selectedPortals = {},
    selectBanner = "Standard",
    autoSellTiers = {},
    autoSummonX10 = false,
    autoSummonX1 = false,
}

local function loadSettings()
    if isfile(folderName.."/"..fileName) then
        return game:GetService("HttpService"):JSONDecode(readfile(folderName.."/"..fileName))
    else
        writefile(folderName.."/"..fileName, game:GetService("HttpService"):JSONEncode(defaultSettings))
        return defaultSettings
    end
end
local function saveSettings(tbl)
    writefile(folderName.."/"..fileName, game:GetService("HttpService"):JSONEncode(tbl))
end
local settings = loadSettings()

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// UTILITIES ////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local function clickScreen()
    local viewport = workspace.CurrentCamera.ViewportSize
    local x = viewport.X / 2
    local y = viewport.Y / 2
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function nativeClick(button)
    if not button or not button:IsA("GuiButton") then return end
    if not button.Visible or not button.Active then return end
    if button.Name == "Retry" and button.Text:match("0/") then return end
    GuiService.SelectedObject = button
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(0.3)
    GuiService.SelectedObject = nil
end

-- /////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////// GAME ENDED UI /////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local function handleGameEndedUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local max = LocalPlayer:FindFirstChild("Summon_Maximum") or LocalPlayer:WaitForChild("Summon_Maximum", 5)

    while LocalPlayer:FindFirstChild("Summon_Maximum") do
        clickScreen()
        task.wait(0.25)
    end
    task.wait(0.5)

    local success, buttonContainer = pcall(function()
        return playerGui:WaitForChild("RewardsUI", 5):WaitForChild("Main", 5)
            :WaitForChild("LeftSide", 5):WaitForChild("Button", 5)
    end)

    if not success or not buttonContainer then return end

    repeat
        local clicked = false
        local retryBtn = buttonContainer:FindFirstChild("Retry")
        local nextBtn = buttonContainer:FindFirstChild("Next")
        local leaveBtn = buttonContainer:FindFirstChild("Leave")

        local ar, an, al = settings.autoRetry, settings.autoNext, settings.autoLeave

        if ar and an and al then
            if nextBtn and nextBtn.Visible and nextBtn.Active then nativeClick(nextBtn) clicked = true task.wait(1) end
            if leaveBtn and leaveBtn.Visible and leaveBtn.Active then nativeClick(leaveBtn) clicked = true task.wait(1) end
            if retryBtn and retryBtn.Visible and retryBtn.Active then nativeClick(retryBtn) clicked = true task.wait(1) end
        elseif an and ar and not al then
            if retryBtn and retryBtn.Visible and retryBtn.Active then nativeClick(retryBtn) clicked = true task.wait(1) end
            if nextBtn and nextBtn.Visible and nextBtn.Active then nativeClick(nextBtn) clicked = true task.wait(1) end
        elseif an and al and not ar then
            if nextBtn and nextBtn.Visible and nextBtn.Active then nativeClick(nextBtn) clicked = true task.wait(1) end
            if leaveBtn and leaveBtn.Visible and leaveBtn.Active then nativeClick(leaveBtn) clicked = true task.wait(1) end
        elseif al and ar and not an then
            if retryBtn and retryBtn.Visible and retryBtn.Active then nativeClick(retryBtn) clicked = true task.wait(1) end
            if leaveBtn and leaveBtn.Visible and leaveBtn.Active then nativeClick(leaveBtn) clicked = true task.wait(1) end
        else
            if an and nextBtn and nextBtn.Visible and nextBtn.Active then nativeClick(nextBtn) clicked = true end
            if al and leaveBtn and leaveBtn.Visible and leaveBtn.Active then nativeClick(leaveBtn) clicked = true end
            if ar and retryBtn and retryBtn.Visible and retryBtn.Active then nativeClick(retryBtn) clicked = true end
        end

        task.wait(0.5)
        if not playerGui:FindFirstChild("GameEndedAnimationUI") then break end
        if not clicked then task.wait(0.5) end
    until not playerGui:FindFirstChild("GameEndedAnimationUI")
end

task.spawn(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("GameEndedAnimationUI")
    if existing then task.wait(1) handleGameEndedUI() end
    playerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") and child.Name == "GameEndedAnimationUI" then
            task.wait(1) handleGameEndedUI()
        end
    end)
end)

task.spawn(function()
    while true do
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local endUI = playerGui and playerGui:FindFirstChild("GameEndedAnimationUI")
        local ready = endUI and not LocalPlayer:FindFirstChild("Summon_Maximum")
        if ready and (settings.autoRetry or settings.autoNext or settings.autoLeave) then
            handleGameEndedUI()
            repeat task.wait(0.5) until not playerGui:FindFirstChild("GameEndedAnimationUI")
        end
        task.wait(1)
    end
end)

-- /////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////// AUTOSTART ///////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
task.spawn(function()
    local hasFired = false
    while true do
        if settings.autoStart and not workspace:FindFirstChild("Lobby") and not hasFired then
            task.wait(2)
            game.ReplicatedStorage.Remote.Server.OnGame.Voting.VotePlaying:FireServer()
            hasFired = true
        elseif workspace:FindFirstChild("Lobby") then
            hasFired = false
        end
        task.wait(1)
    end
end)

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// AUTO RANGER //////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local ActMapping = {
    OnePiece_RangerStage1 = "Voocha Village Act 1",
    OnePiece_RangerStage2 = "Voocha Village Act 2",
    OnePiece_RangerStage3 = "Voocha Village Act 3",
    Namek_RangerStage1 = "Green Planet Act 1",
    Namek_RangerStage2 = "Green Planet Act 2",
    Namek_RangerStage3 = "Green Planet Act 3",
    DemonSlayer_RangerStage1 = "Demon Forest Act 1",
    DemonSlayer_RangerStage2 = "Demon Forest Act 2",
    DemonSlayer_RangerStage3 = "Demon Forest Act 3",
    Naruto_RangerStage1 = "Leaf Village Act 1",
    Naruto_RangerStage2 = "Leaf Village Act 2",
    Naruto_RangerStage3 = "Leaf Village Act 3",
    OPM_RangerStage1 = "Z City Act 1",
    OPM_RangerStage2 = "Z City Act 2",
    OPM_RangerStage3 = "Z City Act 3",
    TokyoGhoul_RangerStage1 = "Goul Act 1",
    TokyoGhoul_RangerStage2 = "Goul Act 2",
    TokyoGhoul_RangerStage3 = "Goul Act 3",
    TokyoGhoul_RangerStage4 = "Goul Act 4",
    TokyoGhoul_RangerStage5 = "Goul Act 5",
}

function runAutoRanger()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local PlayRoomEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("PlayRoom"):WaitForChild("Event")

    task.spawn(function()
        while settings.autoRanger do
            if not workspace:FindFirstChild("Lobby") then
                task.wait(1)
            else
                for _, actLabel in ipairs(settings.selectedActs or {}) do
                    local actKey = nil
                    for key, label in pairs(ActMapping) do
                        if label == actLabel then actKey = key break end
                    end
                    if actKey then
                        local mapKey = actKey:match("^(.-)_")
                        if mapKey then
                            PlayRoomEvent:FireServer(unpack({ "Create" }))
                            PlayRoomEvent:FireServer(unpack({ "Change-Mode", { Mode = "Ranger Stage" } }))
                            PlayRoomEvent:FireServer(unpack({ "Change-World", { World = mapKey } }))
                            PlayRoomEvent:FireServer(unpack({ "Change-Chapter", { Chapter = actKey } }))
                            PlayRoomEvent:FireServer(unpack({ "Submit" }))
                            PlayRoomEvent:FireServer(unpack({ "Start" }))
                            local hasSystemMessage = PlayerGui:FindFirstChild("SystemMessage")
                            if hasSystemMessage and hasSystemMessage.Enabled then
                                return
                            end
                            task.wait(1)
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- /////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////// AUTO REJOIN ///////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayRoomEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("PlayRoom"):WaitForChild("Event")

local MapLabelToName = {
    ["Voocha Village"] = "OnePiece",
    ["Green Planet"] = "Namek",
    ["Demon Forest"] = "DemonSlayer",
    ["Leaf Village"] = "Naruto",
    ["Z City"] = "OPM",
    ["Ghoul City"] = "TokyoGhoul",
}

local function getGameEndedInfo()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local endedUI = playerGui:FindFirstChild("RewardsUI") if not endedUI then return nil end
    local mainFrame = endedUI:FindFirstChild("Main") if not mainFrame then return nil end
    local leftSide = mainFrame:FindFirstChild("LeftSide") if not leftSide then return nil end

    local worldText, chapterText, difficultyText = "", "", ""
    if leftSide:FindFirstChild("World") and leftSide.World:IsA("TextLabel") then worldText = leftSide.World.Text end
    if leftSide:FindFirstChild("Chapter") and leftSide.Chapter:IsA("TextLabel") then chapterText = leftSide.Chapter.Text end
    if leftSide:FindFirstChild("Difficulty") and leftSide.Difficulty:IsA("TextLabel") then difficultyText = leftSide.Difficulty.Text end

    local mapKey = MapLabelToName[worldText] or nil
    local chapterNum = chapterText and chapterText:match("Chapter%s*(%d+)") or nil
    local chapterKey = (mapKey and chapterNum) and (mapKey .. "_Chapter" .. chapterNum) or nil
    if not mapKey or not chapterKey or not difficultyText then return nil end

    return { MapKey = mapKey, ChapterKey = chapterKey, Difficulty = difficultyText }
end

local function autoCreateRoom(info)
    if not info then return end
    if workspace:FindFirstChild("Lobby") then
        PlayRoomEvent:FireServer("Create"); task.wait(0.2)
        PlayRoomEvent:FireServer("Change-World", { World = info.MapKey }); task.wait(0.2)
        PlayRoomEvent:FireServer("Change-Chapter", { Chapter = info.ChapterKey }); task.wait(0.2)
        PlayRoomEvent:FireServer("Change-Difficulty", { Difficulty = info.Difficulty }); task.wait(0.2)
        PlayRoomEvent:FireServer("Submit"); task.wait(0.2)
        PlayRoomEvent:FireServer("Start")
    end
end

local latestGameInfo = nil

LocalPlayer.PlayerGui.ChildAdded:Connect(function(gui)
    if gui.Name == "GameEndedAnimationUI" then
        task.wait(2)
        latestGameInfo = getGameEndedInfo()
    end
end)

local serverStartTime = os.time()
local function getServerUptime() return os.time() - serverStartTime end

local function checkFPS(durationSeconds)
    local frameCount = 0
    local startTime = tick()
    local conn = RunService.Heartbeat:Connect(function() frameCount = frameCount + 1 end)
    task.wait(durationSeconds)
    conn:Disconnect()
    local elapsed = tick() - startTime
    if elapsed > 0 then return frameCount / elapsed else return 0 end
end

local function fpsMonitorLoop()
    while settings.autoRejoin do
        if workspace:FindFirstChild("Lobby") then
            task.wait(5)
        else
            local uptime = getServerUptime()
            if uptime >= 1000 then
                local fps = checkFPS(1)
                if fps <= 10 and latestGameInfo then
                    pcall(function() autoCreateRoom(latestGameInfo) end)
                    task.wait(15)
                else
                    task.wait(10)
                end
            else
                task.wait(30)
            end
        end
    end
end

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// AUTOPLAYER ///////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local unitNames = {}
local function getEquippedUnits()
    unitNames = {}
    for i = 1, 6 do
        local slotPath = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UnitsLoadout"):WaitForChild("Main"):FindFirstChild("UnitLoadout"..i)
        if slotPath and slotPath:FindFirstChild("Frame") and slotPath.Frame:FindFirstChild("UnitFrame") then
            local info = slotPath.Frame.UnitFrame:FindFirstChild("Info")
            if info and info:FindFirstChild("Folder") and info.Folder:IsA("ObjectValue") and info.Folder.Value then
                table.insert(unitNames, info.Folder.Value.Name)
            end
        end
    end
end

local function deployUnits()
    local player = game.Players.LocalPlayer
    local yen = player:FindFirstChild("Yen") and player.Yen.Value or 0
    for i = 1, 6 do
        if settings.slots.place[i] then
            local slot = player.PlayerGui:WaitForChild("UnitsLoadout"):WaitForChild("Main"):FindFirstChild("UnitLoadout"..i)
            if slot then
                local frame = slot:FindFirstChild("Frame")
                local unitFrame = frame and frame:FindFirstChild("UnitFrame")
                local info = unitFrame and unitFrame:FindFirstChild("Info")
                local folderObj = info and info:FindFirstChild("Folder")
                local costLabel = info and info:FindFirstChild("Cost")
                local isCooledDown = frame and not frame:FindFirstChild("CD_FRAME")
                if folderObj and folderObj:IsA("ObjectValue") and folderObj.Value and costLabel and isCooledDown then
                    local costText = costLabel.Text
                    local costNumber = tonumber(costText:match("%d+"))
                    if costNumber and yen >= costNumber then
                        game.ReplicatedStorage.Remote.Server.Units.Deployment:FireServer(folderObj.Value)
                    end
                end
            end
        end
    end
end

local function getYen()
    local success, yen = pcall(function()
        return game.Players.LocalPlayer.PlayerGui.HUD.InGame.Main.Stats.Yen.YenValue.Value
    end)
    return success and yen or 0
end

function tryUpgradeSlot(i)
    local player = game.Players.LocalPlayer
    local unitsFolder = player:WaitForChild("UnitsFolder")
    local upgradeInput = settings.slots.upgrade
    local targetUpgrade = upgradeInput[i]
    if not settings.slots.place[i] or targetUpgrade <= 0 then return false end

    local slot = player.PlayerGui:WaitForChild("UnitsLoadout"):WaitForChild("Main"):FindFirstChild("UnitLoadout"..i)
    if not slot then return false end
    local folderObj = slot:FindFirstChild("Frame") and slot.Frame:FindFirstChild("UnitFrame") and
        slot.Frame.UnitFrame:FindFirstChild("Info") and slot.Frame.UnitFrame.Info:FindFirstChild("Folder")
    if not folderObj or not folderObj:IsA("ObjectValue") or not folderObj.Value then return false end

    local unitName = folderObj.Value.Name
    local unitObject = unitsFolder:FindFirstChild(unitName)
    if not unitObject then return false end

    local upgradeFolder = unitObject:FindFirstChild("Upgrade_Folder")
    if not upgradeFolder then return false end

    local level = upgradeFolder:FindFirstChild("Level")
    local cost = upgradeFolder:FindFirstChild("Upgrade_Cost")
    if not level or not cost then return false end

    local currentLevel = level.Value
    if currentLevel >= targetUpgrade then return false end

    local yen = getYen()
    if yen < cost.Value then return false end

    local success = pcall(function()
        game.ReplicatedStorage.Remote.Server.Units.Upgrade:FireServer(unitObject)
    end)
    return success
end

local isUpgrading = false

local function waitForGameEndToDisappear()
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if not playerGui:FindFirstChild("GameEndedAnimationUI") then return false end
    while playerGui:FindFirstChild("GameEndedAnimationUI") do task.wait(0.5) end
    return true
end

function upgradeUnits()
    if isUpgrading then return end
    isUpgrading = true

    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local unitsFolder = player:WaitForChild("UnitsFolder")

    local preGameUI = playerGui:FindFirstChild("HUD") and playerGui.HUD:FindFirstChild("UnitSelectBeforeGameRunning_UI")
    if preGameUI then isUpgrading = false return end

    local paused = waitForGameEndToDisappear()
    if paused then task.wait(1) end

    while true do
        local anyNeedsUpgrade = false
        for i = 1, 6 do
            if settings.slots.place[i] then
                local slot = playerGui:WaitForChild("UnitsLoadout"):WaitForChild("Main"):FindFirstChild("UnitLoadout"..i)
                if slot then
                    local folderObj = slot:FindFirstChild("Frame") and slot.Frame:FindFirstChild("UnitFrame") and
                        slot.Frame.UnitFrame:FindFirstChild("Info") and slot.Frame.UnitFrame.Info:FindFirstChild("Folder")
                    if folderObj and folderObj:IsA("ObjectValue") and folderObj.Value then
                        local unitName = folderObj.Value.Name
                        local unitObject = unitsFolder:FindFirstChild(unitName)
                        if unitObject then
                            local level = unitObject:WaitForChild("Upgrade_Folder"):WaitForChild("Level").Value
                            local targetUpgrade = settings.slots.upgrade[i]
                            if level < targetUpgrade then
                                anyNeedsUpgrade = true
                                local didUpgrade = tryUpgradeSlot(i)
                                if didUpgrade then task.wait(0.5) break end
                            end
                        end
                    end
                end
            end
        end
        if not anyNeedsUpgrade then break end
        task.wait(0.3)
    end

    isUpgrading = false
end

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// WEBHOOK //////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local HttpService = game:GetService("HttpService")

local function collectData()
    local d = {}
    local expBar = LocalPlayer.PlayerGui:WaitForChild("HUD"):FindFirstChild("ExpBar")
    if expBar and expBar:FindFirstChild("Numbers") then
        local raw = expBar.Numbers.Text
        local lvl = raw:match("Level%s*(%d+)") or "0"
        local xp  = raw:match("%[(.-)%]</font>") or "0/0"
        d.levelText = "Level " .. lvl .. " [" .. xp .. "]"
    else
        d.levelText = "Level 0 [0/0]"
    end

    local menu = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                 and LocalPlayer.PlayerGui.HUD:FindFirstChild("MenuFrame")
                 and LocalPlayer.PlayerGui.HUD.MenuFrame:FindFirstChild("LeftSide")
                 and LocalPlayer.PlayerGui.HUD.MenuFrame.LeftSide:FindFirstChild("Frame")
    d.gems = (menu and menu:FindFirstChild("Gems")
                 and menu.Gems:FindFirstChildWhichIsA("TextLabel").Text) or "0"
    d.gold = (menu and menu:FindFirstChild("Gold")
                 and menu.Gold:FindFirstChildWhichIsA("TextLabel").Text) or "0"
    d.egg  = (menu and menu:FindFirstChild("Egg")
                 and menu.Egg:FindFirstChildWhichIsA("TextLabel").Text) or "0"

    d.matchInfo = {}
    local leftSide = LocalPlayer.PlayerGui:FindFirstChild("RewardsUI")
                   and LocalPlayer.PlayerGui.RewardsUI:FindFirstChild("Main")
                   and LocalPlayer.PlayerGui.RewardsUI.Main:FindFirstChild("LeftSide")
    if leftSide then
        for _, key in ipairs({"GameStatus","Chapter","Difficulty","Mode","World","TotalTime"}) do
            local lbl = leftSide:FindFirstChild(key)
            d.matchInfo[key] = (lbl and lbl:IsA("TextLabel") and lbl.Text) or ""
        end
    end

    d.rewardsList = {}
    local rewardsRoot = LocalPlayer:FindFirstChild("RewardsShow")
    local playerData = game:GetService("ReplicatedStorage"):FindFirstChild("Player_Data")
    local itemsFolder = playerData and playerData:FindFirstChild(LocalPlayer.Name)
                        and playerData[LocalPlayer.Name]:FindFirstChild("Items")
    if rewardsRoot and itemsFolder then
        for _, folder in ipairs(rewardsRoot:GetChildren()) do
            if folder:IsA("Folder") then
                local name = folder.Name
                local amt = (folder:FindFirstChild("Amount") and folder.Amount.Value) or 0
                local itemData = itemsFolder:FindFirstChild(name)
                local total = (itemData and itemData:FindFirstChild("Amount") and itemData.Amount.Value) or 0
                table.insert(d.rewardsList, "+" .. amt .. " " .. name .. " [total: " .. total .. "]")
            end
        end
    end
    return d
end

local function sendWebhook()
    if not settings.webhookURL or settings.webhookURL == "" then return end
    local d = collectData()
    local status = (d.matchInfo.GameStatus or ""):lower()
    local color = 0xffff00
    if status:find("won") then color = 0x00ff00 elseif status:find("defect") then color = 0xff0000 end

    local fields = {
        { name="Stats",  value=string.format("%s\nGems: %s\nGold: %s\nEgg: %s", d.levelText, d.gems, d.gold, d.egg), inline=false },
        { name="Rewards", value=#d.rewardsList > 0 and table.concat(d.rewardsList, "\n") or "None", inline=true },
        { name="Match Info", value=table.concat({
            d.matchInfo.GameStatus, d.matchInfo.Chapter, d.matchInfo.Difficulty,
            d.matchInfo.Mode, d.matchInfo.World, d.matchInfo.TotalTime }, "\n"), inline=false },
    }

    local payload = { embeds = {{
        title = "Anime Rangers X - Shouko.Dev - ARX",
        color = color,
        fields = fields,
        footer = { text = "Send " .. os.date("%Y-%m-%d %H:%M:%S") },
    }}}

    local ok, err = pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then error("None HTTP request") end
        req({ Url = settings.webhookURL, Method = "POST",
              Headers = { ["Content-Type"] = "application/json" },
              Body = HttpService:JSONEncode(payload), })
    end)
    if not ok then warn("❌ Webhook failed:", err) end
end

LocalPlayer.PlayerGui.ChildAdded:Connect(function(gui)
    if gui.Name == "GameEndedAnimationUI" and settings.webhookEnabled then
        task.wait(2)
        sendWebhook()
    end
end)

-- /////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////// SHOP / REROLL /////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local TierUnitNames = {
    "Naruto","Naruto:Shiny","Zoro","Zoro:Shiny","Chaozi:Shiny","Chaozi","Goku","Goku:Shiny",
    "Krillin","Luffy","Nezuko","Sanji","Usopp","Yamcha","Krillin:Shiny","Luffy:Shiny",
    "Nezuko:Shiny","Sanji:Shiny","Usopp:Shiny","Yamcha:Shiny",
}

local function evolveRareUnits()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local collection = ReplicatedStorage:FindFirstChild("Player_Data")
        and ReplicatedStorage.Player_Data:FindFirstChild(LocalPlayer.Name)
        and ReplicatedStorage.Player_Data[LocalPlayer.Name]:FindFirstChild("Collection")
    if not collection then return end
    for _, unitFolder in ipairs(collection:GetChildren()) do
        if unitFolder:IsA("Folder") and table.find(TierUnitNames, unitFolder.Name) then
            local tag = unitFolder:FindFirstChild("Tag")
            local evolveTier = unitFolder:FindFirstChild("EvolveTier")
            if tag and tag:IsA("StringValue") and tag.Value ~= "" then
                local tier = evolveTier and evolveTier.Value or ""
                if tier == "" then
                    local args = { tag.Value, "Hyper" }
                    ReplicatedStorage.Remote.Server.Units.EvolveTier:FireServer(unpack(args))
                    task.wait(0.1)
                end
            end
        end
    end
end

local isRolling = false
local startRollToggle -- reference to UI toggle to programmatically turn off

local function autoRoll()
    local rs  = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer
    local collection = rs:WaitForChild("Player_Data"):WaitForChild(plr.Name):WaitForChild("Collection")
    local rerollRemote = rs:WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("Gambling"):WaitForChild("RerollPotential")

    local unitEntry = settings.selectUnit
    local unitName = unitEntry:match("^(.-)%s*%[") or unitEntry
    local folder = collection:FindFirstChild(unitName)
    if not folder then warn("Not found folder của unit:", unitName) return end

    local pending = {}
    for _, potential in ipairs(settings.selectPotential) do
        local resultNV = folder:FindFirstChild(potential .. "Potential")
        local resultVal = resultNV and resultNV.Value or ""
        local matched = false
        for _, desired in ipairs(settings.selectStats) do
            if resultVal == desired then matched = true break end
        end
        if not matched then pending[potential] = true end
    end

    if not next(pending) then
        if startRollToggle then startRollToggle:Set({CurrentValue=false}) end
        settings.startRoll = false
        saveSettings(settings)
        return
    end

    isRolling = true
    while isRolling and next(pending) do
        for potential in pairs(pending) do
            if not isRolling then break end
            local tagNV = folder:FindFirstChild("Tag")
            if not tagNV then warn("Not found tag của unit:", unitName) isRolling=false return end
            local tagStr = tagNV.Value
            rerollRemote:FireServer(potential, tagStr, "Selective")
            task.wait(0.3)
            local resultNV = folder:FindFirstChild(potential .. "Potential")
            local resultVal = resultNV and resultNV.Value or ""
            for _, desired in ipairs(settings.selectStats) do
                if resultVal == desired then pending[potential] = nil break end
            end
        end
    end

    isRolling = false
    if startRollToggle then startRollToggle:Set({CurrentValue=false}) end
    settings.startRoll = false
    saveSettings(settings)
end

-- Trait Reroll
local rerollConfig = { unit = nil, trail = {}, start = false }
function autoRollTrail(unitEntry, desiredTrails)
    local rs = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer
    local unitName = unitEntry:match("^(.-)%s*%[") or unitEntry
    local collection = rs:WaitForChild("Player_Data"):WaitForChild(plr.Name):WaitForChild("Collection")
    local rerollRemote = rs:WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("Gambling"):WaitForChild("RerollTrait")

    local folder = collection:FindFirstChild(unitName)
    if not folder then warn("Not found unit:", unitName) return end

    local function hasDesiredTrail()
        local primary = folder:FindFirstChild("PrimaryTrait")
        local secondary = folder:FindFirstChild("SecondaryTrait")
        local pVal = primary and primary.Value or ""
        local sVal = secondary and secondary.Value or ""
        for _, desired in ipairs(desiredTrails) do
            if pVal == desired or sVal == desired then return true end
        end
        return false
    end

    if hasDesiredTrail() then print("🎉 Đã có trail mong muốn trước khi roll:", unitName) return end
    print("🔁 Bắt đầu roll trail cho:", unitName)

    while rerollConfig.start do
        rerollRemote:FireServer(folder, "Reroll", "Main", "Shards")
        task.wait(0.3)
        if hasDesiredTrail() then
            print("✅ Roll thành công:", unitName)
            rerollConfig.start = false
            break
        end
    end
end

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// PORTALS //////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local function autoPortalFunc()
    local player = Players.LocalPlayer
    local function getCharacter()
        local char = player.Character or player.CharacterAdded:Wait()
        while not char:FindFirstChild("HumanoidRootPart") do char.ChildAdded:Wait() end
        return char
    end
    local function getAllParts(folder)
        local parts = {}
        for _, obj in ipairs(folder:GetChildren()) do if obj:IsA("Part") then table.insert(parts, obj) end end
        return parts
    end
    local function activatePrompt(prompt)
        for i = 1, 10 do
            if prompt:IsA("ProximityPrompt") then fireproximityprompt(prompt) end
            task.wait(0.1)
        end
    end
    task.spawn(function()
        local character = getCharacter()
        local hrp = character:WaitForChild("HumanoidRootPart")
        while settings.autoPortal do
            local portalFolder = workspace:FindFirstChild("Portal")
            if portalFolder then
                local parts = getAllParts(portalFolder)
                if #parts > 0 then
                    local selectedPart = parts[math.random(1, #parts)]
                    hrp.CFrame = selectedPart.CFrame + Vector3.new(0, 5, 0)
                    local prompt = selectedPart:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then activatePrompt(prompt) end
                end
            end
            task.wait(1)
        end
    end)
end

local RemoteItemUse = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("Lobby"):WaitForChild("ItemUse")
local RemotePortalEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("Lobby"):WaitForChild("PortalEvent")

function autoJoinPortalLoop()
    while settings.autoJoinPortal do
        if not workspace:FindFirstChild("Lobby") then
            task.wait(1)
        else
            local playerData = ReplicatedStorage:FindFirstChild("Player_Data")
            if not playerData then task.wait(1) continue end
            local clone = playerData:FindFirstChild(LocalPlayer.Name)
            if not clone then task.wait(1) continue end
            local items = clone:FindFirstChild("Items")
            if not items then task.wait(1) continue end
            for _, portalName in ipairs(settings.selectedPortals) do
                local portalItem = items:FindFirstChild(portalName)
                if portalItem then
                    pcall(function() RemoteItemUse:FireServer(portalItem) end)
                    task.wait(1)
                    pcall(function() RemotePortalEvent:FireServer("Start") end)
                    task.wait(3)
                end
            end
            task.wait(2)
        end
    end
end

-- /////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////// UI (STARLIGHT) ///////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
local Window = Starlight:CreateWindow({
    Name = "Shouko.Dev - ARX",
    Subtitle = "Shouko.Dev script game",
    ConfigurationSettings = { FolderName = folderName },
    DefaultSize = UDim2.new(0, 650, 0, 500),
})

pcall(function() Window.Instance.Name = "ShoukoDev" end)

-- A single Tab Section to group our tabs in the sidebar
local RootSection = Window:CreateTabSection("Shouko.ARX")

-- Tabs
local MainTab     = RootSection:CreateTab({ Name = "Main",     Icon = NebulaIcons:GetIcon('layout-grid','Lucide'),           Columns = 2 }, "MAIN")
local AutoPlayTab = RootSection:CreateTab({ Name = "Auto Play", Icon = NebulaIcons:GetIcon('gamepad-2','Lucide'),      Columns = 2 }, "AUTOPLAY")
local WebhookTab  = RootSection:CreateTab({ Name = "Webhook",   Icon = NebulaIcons:GetIcon('link','Material'),           Columns = 2 }, "WEBHOOK")
local ShopTab     = RootSection:CreateTab({ Name = "Shop",      Icon = NebulaIcons:GetIcon('shopping_cart','Lucide'),  Columns = 2 }, "SHOP")
local PortalTab   = RootSection:CreateTab({ Name = "Portal",    Icon = NebulaIcons:GetIcon('badge','Lucide'),  Columns = 2 }, "PORTAL")

-- ========================= Main Tab =========================
local controlGB = MainTab:CreateGroupbox({ Name = "Auto Options", Column = 1 }, "MAIN_AUTOOPTS")
controlGB:CreateToggle({
    Name = "Auto Start",
    CurrentValue = settings.autoStart,
    Callback = function(val) settings.autoStart = val; saveSettings(settings) end
}, "MAIN_AUTOSTART")
controlGB:CreateToggle({
    Name = "Auto Next",
    CurrentValue = settings.autoNext,
    Callback = function(val) settings.autoNext = val; saveSettings(settings) end
}, "MAIN_AUTONEXT")
controlGB:CreateToggle({
    Name = "Auto Retry",
    CurrentValue = settings.autoRetry,
    Callback = function(val) settings.autoRetry = val; saveSettings(settings) end
}, "MAIN_AUTORETRY")
controlGB:CreateToggle({
    Name = "Auto Leave",
    CurrentValue = settings.autoLeave,
    Callback = function(val) settings.autoLeave = val; saveSettings(settings) end
}, "MAIN_AUTOLEAVE")

controlGB:CreateToggle({
    Name = "Auto Execute (Queue On Teleport)",
    CurrentValue = settings.autoReloadOnTeleport or false,
    Callback = function(val)
        settings.autoReloadOnTeleport = val
        saveSettings(settings)
        if val then
            queue_on_teleport([[
                repeat task.wait() until game:IsLoaded()
                loadstring(game:HttpGet('https://cdn.shouko.dev/RokidManager/neyoshiiuem/main/arx_main.lua'))()
            ]])
        end
    end
}, "MAIN_AUTOEXECUTE")

controlGB:CreateToggle({
    Name = "Delete Map",
    CurrentValue = settings.deleteMap or false,
    Callback = function(val)
        settings.deleteMap = val
        saveSettings(settings)
        if val then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/junggamyeon/MyScript/refs/heads/main/betterfps.lua"))()
        end
    end
}, "MAIN_DELETEMAP")

local miscGB = MainTab:CreateGroupbox({ Name = "Misc", Column = 1 }, "MAIN_MISC")
miscGB:CreateToggle({
    Name = "Auto Claim Quest",
    CurrentValue = settings.autoClaimQuest or false,
    Callback = function(val)
        settings.autoClaimQuest = val; saveSettings(settings)
        if val then
            task.spawn(function()
                while settings.autoClaimQuest do
                    local lobbyFolder = workspace:FindFirstChild("Lobby")
                    if lobbyFolder and lobbyFolder:IsA("Folder") then
                        local args = { "ClaimAll" }
                        game:GetService("ReplicatedStorage"):WaitForChild("Remote")
                            :WaitForChild("Server"):WaitForChild("Gameplay")
                            :WaitForChild("QuestEvent"):FireServer(unpack(args))
                    end
                    task.wait(10)
                end
            end)
        end
    end
}, "MAIN_CLAIMQUEST")

-- Auto Ranger on Right
local rangerGB = MainTab:CreateGroupbox({ Name = "Auto Ranger", Column = 2 }, "MAIN_RANGER")
-- Dropdown (nested) for Acts
local actLabelList = {}
for _, label in pairs(ActMapping) do table.insert(actLabelList, label) end
local actLabel = rangerGB:CreateLabel({ Name = "Select Act(s)" }, "MAIN_ACTLABEL")
actLabel:AddDropdown({
    Options = actLabelList,
    CurrentOptions = settings.selectedActs or {},
    MultipleOptions = true,
    Placeholder = "None Selected",
    Callback = function(opts)
        settings.selectedActs = opts
        saveSettings(settings)
    end
}, "MAIN_ACTS")
rangerGB:CreateToggle({
    Name = "Auto Ranger",
    CurrentValue = settings.autoRanger or false,
    Callback = function(val)
        settings.autoRanger = val; saveSettings(settings)
        if val then task.spawn(runAutoRanger) end
    end
}, "MAIN_AUTORANGER")

-- Challenge
local challengeGB = MainTab:CreateGroupbox({ Name = "Challenge", Column = 2 }, "MAIN_CHALLENGE")
challengeGB:CreateToggle({
    Name = "Auto Join Challenge",
    CurrentValue = settings.autoJoinChallenge or false,
    Callback = function(val)
        settings.autoJoinChallenge = val; saveSettings(settings)
        if val then
            task.spawn(function()
                local PlayRoomEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remote")
                    :WaitForChild("Server"):WaitForChild("PlayRoom"):WaitForChild("Event")
                while settings.autoJoinChallenge do
                    if workspace:FindFirstChild("Lobby") then
                        PlayRoomEvent:FireServer("Create", { CreateChallengeRoom = true })
                        task.wait(0.5)
                        PlayRoomEvent:FireServer("Start")
                    end
                    task.wait(3)
                end
            end)
        end
    end
}, "MAIN_AUTOCHALLENGE")

-- Auto Rejoin
local rejoinGB = MainTab:CreateGroupbox({ Name = "Auto Rejoin", Column = 2 }, "MAIN_REJOIN")
rejoinGB:CreateToggle({
    Name = "Auto Rejoin When FPS Drop",
    CurrentValue = settings.autoRejoin or false,
    Callback = function(val)
        settings.autoRejoin = val; saveSettings(settings)
        if val then task.spawn(fpsMonitorLoop) end
    end
}, "MAIN_AUTOREJOIN")

-- ========================= Auto Play Tab =========================
local apLeft = AutoPlayTab:CreateGroupbox({ Name = "Auto Options", Column = 1 }, "AP_LEFT")
apLeft:CreateToggle({
    Name = "Auto Play",
    CurrentValue = settings.autoPlay,
    Callback = function(val)
        settings.autoPlay = val; saveSettings(settings)
        if val then
            getEquippedUnits()
            task.spawn(function()
                local playerGui = LocalPlayer:WaitForChild("PlayerGui")
                while settings.autoPlay do
                    local isPreGame = playerGui:FindFirstChild("HUD") and playerGui.HUD:FindFirstChild("UnitSelectBeforeGameRunning_UI")
                    local isEndGame = playerGui:FindFirstChild("GameEndedAnimationUI")
                    if isPreGame or isEndGame then
                        repeat task.wait(0.5)
                            isPreGame = playerGui:FindFirstChild("HUD") and playerGui.HUD:FindFirstChild("UnitSelectBeforeGameRunning_UI")
                            isEndGame = playerGui:FindFirstChild("GameEndedAnimationUI")
                        until not isPreGame and not isEndGame
                        task.wait(1.5)
                    end
                    if settings.playAfterUpgrade and settings.autoUpgrade then
                        if not isUpgrading then upgradeUnits() end
                        while isUpgrading do task.wait(0.2) end
                    end
                    deployUnits()
                    task.wait(1)
                end
            end)
        end
    end
}, "AP_AUTOPLAY")

apLeft:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = settings.autoUpgrade,
    Callback = function(val)
        settings.autoUpgrade = val; saveSettings(settings)
        if val then
            task.spawn(function()
                while settings.autoUpgrade do
                    upgradeUnits()
                    task.wait(1)
                end
            end)
        end
    end
}, "AP_AUTOUPGRADE")

apLeft:CreateToggle({
    Name = "Play After Upgrade",
    CurrentValue = settings.playAfterUpgrade,
    Callback = function(val) settings.playAfterUpgrade = val; saveSettings(settings) end
}, "AP_PLAYAFTERUPG")

local placeGB = AutoPlayTab:CreateGroupbox({ Name = "Place Slot", Column = 2 }, "AP_PLACE")
for i = 1, 6 do
    placeGB:CreateToggle({
        Name = ("Slot %d"):format(i),
        CurrentValue = settings.slots.place[i],
        Callback = function(val) settings.slots.place[i] = val; saveSettings(settings) end
    }, "AP_PLACE_"..i)
end

local upgGB = AutoPlayTab:CreateGroupbox({ Name = "Upgrade Slot", Column = 1 }, "AP_UPG")
for i = 1, 6 do
    upgGB:CreateInput({
        Name = ("Slot %d Target Level"):format(i),
        CurrentValue = tostring(settings.slots.upgrade[i] or 0),
        PlaceholderText = "0",
        Numeric = true,
        Callback = function(value)
            local num = tonumber(value) or 0
            settings.slots.upgrade[i] = num
            saveSettings(settings)
        end
    }, "AP_UPG_"..i)
end

-- ========================= Webhook Tab =========================
local whGB = WebhookTab:CreateGroupbox({ Name = "Webhook Settings", Column = 1 }, "WH_GB")
whGB:CreateInput({
    Name = "Webhook Link",
    CurrentValue = settings.webhookURL or "",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Callback = function(value) settings.webhookURL = value; saveSettings(settings) end
}, "WH_URL")

whGB:CreateToggle({
    Name = "Result Webhook",
    CurrentValue = settings.webhookEnabled,
    Callback = function(val) settings.webhookEnabled = val; saveSettings(settings) end
}, "WH_ENABLE")

whGB:CreateButton({
    Name = "Test Webhook",
    Callback = function() sendWebhook() end
}, "WH_TEST")

-- ========================= Shop Tab =========================
local rareGB = ShopTab:CreateGroupbox({ Name = "Auto Tier (Rare)", Column = 1 }, "SHOP_RARE")
rareGB:CreateToggle({
    Name = "Auto Evolve Tier (Rare)",
    CurrentValue = settings.autoEvolveRare,
    Callback = function(val)
        settings.autoEvolveRare = val; saveSettings(settings)
        if val then evolveRareUnits() end
    end
}, "SHOP_AUTORARE")

local summonGB = ShopTab:CreateGroupbox({ Name = "Summon", Column = 1 }, "SHOP_SUMMON")

local bannerLabel = summonGB:CreateLabel({ Name = "Select Banner" }, "SHOP_BANNER_LBL")
bannerLabel:AddDropdown({
    Options = {"Standard", "Rateup"},
    CurrentOptions = {settings.selectBanner or "Standard"},
    MultipleOptions = false,
    Placeholder = "--",
    Callback = function(opts)
        local choice = (type(opts) == "table" and opts[1]) or opts
        settings.selectBanner = choice or "Standard"
        saveSettings(settings)
    end
}, "SHOP_BANNER")

local autosellLabel = summonGB:CreateLabel({ Name = "Select Auto Sell" }, "SHOP_AUTOSELL_LBL")
autosellLabel:AddDropdown({
    Options = { "Rare", "Epic", "Legendary", "Shiny" },
    CurrentOptions = (function()
        local t = {}
        for k,v in pairs(settings.autoSellTiers or {}) do if v == true then table.insert(t, k) end end
        if #t == 0 and type(settings.autoSellTiers) == "table" then
            for _,k in ipairs(settings.autoSellTiers) do table.insert(t, k) end
        end
        return t
    end)(),
    MultipleOptions = true,
    Placeholder = "None",
    Callback = function(opts)
        -- store as array
        settings.autoSellTiers = {}
        for _,v in ipairs(opts) do table.insert(settings.autoSellTiers, v) end
        saveSettings(settings)
    end
}, "SHOP_AUTOSELL")

summonGB:CreateToggle({
    Name = "Auto Summon x10",
    CurrentValue = settings.autoSummonX10 or false,
    Callback = function(val)
        settings.autoSummonX10 = val
        saveSettings(settings)
        if val then
            task.spawn(function()
                while settings.autoSummonX10 do
                    local args = { "x10", settings.selectBanner or "Standard" }
                    if settings.autoSellTiers and next(settings.autoSellTiers) ~= nil then
                        table.insert(args, settings.autoSellTiers)
                    end
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote")
                        :WaitForChild("Server"):WaitForChild("Gambling")
                        :WaitForChild("UnitsGacha"):FireServer(unpack(args))
                    task.wait(0.3)
                end
            end)
        end
    end
}, "SHOP_SUMMON10")

summonGB:CreateToggle({
    Name = "Auto Summon x1",
    CurrentValue = settings.autoSummonX1 or false,
    Callback = function(val)
        settings.autoSummonX1 = val
        saveSettings(settings)
        if val then
            task.spawn(function()
                while settings.autoSummonX1 do
                    local args = { "x1", settings.selectBanner or "Standard" }
                    if settings.autoSellTiers and next(settings.autoSellTiers) ~= nil then
                        table.insert(args, settings.autoSellTiers)
                    end
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote")
                        :WaitForChild("Server"):WaitForChild("Gambling")
                        :WaitForChild("UnitsGacha"):FireServer(unpack(args))
                    task.wait(0.3)
                end
            end)
        end
    end
}, "SHOP_SUMMON1")

-- Stats Group (Right)
local statsGB = ShopTab:CreateGroupbox({ Name = "Stats", Column = 2 }, "SHOP_STATS")

local potentialsLabel = statsGB:CreateLabel({ Name = "Select Potential" }, "SHOP_POT_LBL")
potentialsLabel:AddDropdown({
    Options = { "Damage", "Health", "Speed", "Range", "AttackCooldown" },
    CurrentOptions = settings.selectPotential or {},
    MultipleOptions = true,
    Placeholder = "None",
    Callback = function(opts) settings.selectPotential = opts; saveSettings(settings) end
}, "SHOP_POTENTIAL")

local statsLabel = statsGB:CreateLabel({ Name = "Select Stats" }, "SHOP_STATS_LBL")
statsLabel:AddDropdown({
    Options = { "S", "SS", "SSS", "O-", "O", "O+" },
    CurrentOptions = settings.selectStats or {},
    MultipleOptions = true,
    Placeholder = "None",
    Callback = function(opts) settings.selectStats = opts; saveSettings(settings) end
}, "SHOP_STATGRADES")

local unitLabel = statsGB:CreateLabel({ Name = "Select Unit" }, "SHOP_UNIT_LBL")
unitLabel:AddDropdown({
    Options = (function()
        local rs  = game:GetService("ReplicatedStorage")
        local plr = game:GetService("Players").LocalPlayer
        local col = rs:WaitForChild("Player_Data"):WaitForChild(plr.Name):WaitForChild("Collection")
        local names = {}
        for _, folder in ipairs(col:GetChildren()) do
            local lvlNV = folder:FindFirstChild("Level")
            local lvl = (lvlNV and lvlNV.Value) or 0
            table.insert(names, string.format("%s [%d]", folder.Name, lvl))
        end
        table.sort(names)
        return names
    end)(),
    CurrentOptions = { settings.selectUnit or "" },
    MultipleOptions = false,
    Placeholder = "--",
    Callback = function(opts)
        local choice = (type(opts) == "table" and opts[1]) or opts
        settings.selectUnit = choice or ""
        saveSettings(settings)
    end
}, "SHOP_UNIT")

startRollToggle = statsGB:CreateToggle({
    Name = "Start Roll",
    CurrentValue = settings.startRoll or false,
    Callback = function(val)
        settings.startRoll = val; saveSettings(settings)
        if val then if not isRolling then isRolling = true; coroutine.wrap(autoRoll)() end else isRolling = false end
    end
}, "SHOP_STARTROLL")

-- Trail Reroll (Right)
local trailGB = ShopTab:CreateGroupbox({ Name = "Trail Reroll", Column = 2 }, "SHOP_TRAIL")

local trailUnitLabel = trailGB:CreateLabel({ Name = "Select Unit" }, "SHOP_TRAIL_UNIT_LBL")
trailUnitLabel:AddDropdown({
    Options = (function()
        local rs = game:GetService("ReplicatedStorage")
        local plr = game:GetService("Players").LocalPlayer
        local collection = rs:WaitForChild("Player_Data"):WaitForChild(plr.Name):WaitForChild("Collection")
        local unitList = {}
        for _, unit in ipairs(collection:GetChildren()) do
            local levelVal = unit:FindFirstChild("Level")
            local label = unit.Name
            if levelVal then label = label .. " [" .. levelVal.Value .. "]" end
            table.insert(unitList, label)
        end
        table.sort(unitList)
        return unitList
    end)(),
    CurrentOptions = rerollConfig.unit and {rerollConfig.unit} or {},
    MultipleOptions = false,
    Placeholder = "--",
    Callback = function(opts)
        local choice = (type(opts) == "table" and opts[1]) or opts
        rerollConfig.unit = choice
    end
}, "SHOP_TRAIL_UNIT")

local trailLabel = trailGB:CreateLabel({ Name = "Select Trail" }, "SHOP_TRAIL_LBL")
trailLabel:AddDropdown({
    Options = { "Blitz", "Juggernaut", "Millionaire", "Violent", "Seraph", "Capitalist", "Duplicator", "Sovereign" },
    CurrentOptions = {},
    MultipleOptions = true,
    Placeholder = "None",
    Callback = function(selected) rerollConfig.trail = selected end
}, "SHOP_TRAIL_PICK")

trailGB:CreateToggle({
    Name = "Start Roll Trail",
    CurrentValue = false,
    Callback = function(val)
        rerollConfig.start = val
        if val and rerollConfig.unit and rerollConfig.trail and #rerollConfig.trail > 0 then
            coroutine.wrap(function() autoRollTrail(rerollConfig.unit, rerollConfig.trail) end)()
        end
    end
}, "SHOP_TRAIL_START")

-- ========================= Portal Tab =========================
local portalGB = PortalTab:CreateGroupbox({ Name = "Portal Helper", Column = 1 }, "PORTAL_HELPER")
portalGB:CreateToggle({
    Name = "Auto Click Portal",
    CurrentValue = settings.autoPortal or false,
    Callback = function(val)
        settings.autoPortal = val; saveSettings(settings)
        if val then task.spawn(autoPortalFunc) end
    end
}, "PORTAL_CLICK")

local portalJoinGB = PortalTab:CreateGroupbox({ Name = "Auto Join Portal", Column = 1 }, "PORTAL_JOIN")
local portalOptions = { "Ghoul City Portal I", "Ghoul City Portal II", "Ghoul City Portal III" }

local portalLabel = portalJoinGB:CreateLabel({ Name = "Select Portal(s)" }, "PORTAL_SELECT_LBL")
portalLabel:AddDropdown({
    Options = portalOptions,
    CurrentOptions = settings.selectedPortals or {},
    MultipleOptions = true,
    Placeholder = "None",
    Callback = function(opts)
        settings.selectedPortals = opts
        saveSettings(settings)
    end
}, "PORTAL_SELECT")

portalJoinGB:CreateToggle({
    Name = "Auto Join",
    CurrentValue = settings.autoJoinPortal or false,
    Callback = function(val)
        settings.autoJoinPortal = val; saveSettings(settings)
        if val then task.spawn(autoJoinPortalLoop) end
    end
}, "PORTAL_AUTOJOIN")
