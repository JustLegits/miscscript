if not game:IsLoaded() then
    game.Loaded:Wait()
end

wait(math.random())

--// Reconnect JSON writer (final version)
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local username = LocalPlayer.Name
local folder = "Reconnect"
local filepath = folder .. "/reconnect_status_" .. username .. ".json"

-- Tạo folder nếu chưa có
if not isfolder(folder) then
    makefolder(folder)
end

-- Biến trạng thái để tránh bị ghi đè
local isOffline = false

-- Function ghi trạng thái
local function writeStatus(status)
    local data = {
        status = status,        -- "Online" hoặc "Offline"
        timestamp = os.time(),  -- thời gian Unix
        user = username         -- tên Roblox LocalPlayer
    }
    local jsonData = HttpService:JSONEncode(data)
    writefile(filepath, jsonData)
end

-- Luôn update Online mỗi 1 giây (chỉ khi chưa Offline)
task.spawn(function()
    while task.wait(1) do
        if not isOffline then
            writeStatus("Online")
        end
    end
end)

-- Detect ErrorPrompt (menu disconnect/kick/failed)
local PromptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")

PromptOverlay.ChildAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" and not isOffline then
        isOffline = true
        writeStatus("Offline")
    end
end)

-- Detect teleport fail
LocalPlayer.OnTeleportFailed:Connect(function()
    if not isOffline then
        isOffline = true
        writeStatus("Offline")
    end
end)

-- Detect player bị kick (LocalPlayer bị xoá khỏi game)
LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if parent == nil and not isOffline then
        isOffline = true
        writeStatus("Offline")
    end
end)

print("[Reconnect] JSON writer running. Saving to: " .. filepath)
