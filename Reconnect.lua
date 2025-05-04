local HttpService = game:GetService("HttpService")

-- Định nghĩa tên file trạng thái
local statusFileName = "status.txt"

-- Hàm ghi file trạng thái
local function writeStatus()
    local data = {
        time = os.time(),
    }
    local encoded = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        writefile(statusFileName, encoded)
        print("[LUA] Đã ghi status.txt: " .. encoded)
    end)

    if not success then
        print("[LUA] Lỗi khi ghi status.txt:", err)
    end
end

-- Ghi trạng thái lần đầu
writeStatus()

-- Lặp lại mỗi 2 phút
while true do
    task.wait(120)
    writeStatus()
end
