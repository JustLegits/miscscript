local HttpService = game:GetService("HttpService")
local filePath = "status.txt"

local success, err = pcall(function()
    if writefile then
        local currentTime = os.time()
        local data = { time = currentTime }
        writefile(filePath, HttpService:JSONEncode(data))
        warn("[✅] Đã ghi file status.txt:", currentTime)
    else
        warn("[❌] writefile không khả dụng.")
    end
end)

if not success then
    warn("[❌] Lỗi khi ghi file:", err)
end
