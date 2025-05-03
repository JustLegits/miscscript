local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local statusFile = "/sdcard/roblox_status/status.txt"

-- Hàm ghi thời gian hiện tại vào file
local function updateStatusFile()
    local timestamp = os.time()
    local data = {
        username = player.Name,
        time = timestamp
    }

    local encoded = HttpService:JSONEncode(data)

    -- Ghi file
    local success, err = pcall(function()
        writefile(statusFile, encoded)
    end)

    if success then
        warn("[✔] Đã ghi trạng thái:", encoded)
    else
        warn("[✘] Ghi file lỗi:", err)
    end
end

-- Ghi mỗi 60 giây
while true do
    updateStatusFile()
    task.wait(60)
end
