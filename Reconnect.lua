local HttpService = game:GetService("HttpService")

local function writeStatus()
    local data = {
        time = os.time()
    }
    local encoded = HttpService:JSONEncode(data)

    pcall(function()
        writefile("status.txt", encoded)
        print("[KRNL] Đã ghi status.txt:", encoded)
    end)
end

-- Ghi lần đầu
writeStatus()

-- Lặp lại mỗi 2 phút
while true do
    task.wait(120)
    writeStatus()
end
