local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local statusFile = "status.txt" -- file sẽ được lưu ở thư mục mặc định của KRNL

local function updateStatusFile()
    local timestamp = os.time()
    local data = {
        username = player.Name,
        time = timestamp
    }

    local encoded = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        writefile(statusFile, encoded)
    end)

    if success then
        warn("[✔] Ghi thành công:", encoded)
    else
        warn("[✘] Lỗi ghi file:", err)
    end
end

while true do
    updateStatusFile()
    task.wait(60)
end
