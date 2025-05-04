local HttpService = game:GetService("HttpService")

-- Define a function to handle file writing
local function writeStatus(filePath)
    local data = {
        time = os.time()
    }
    local encoded = HttpService:JSONEncode(data)
    
    local success, err = pcall(function()
        local file = io.open(filePath, "w")
        if file then
            file:write(encoded)
            file:close()
            print("[DELTA] Đã ghi status.txt:", encoded, "vào", filePath)
        else
            error("Không thể mở file để ghi: " .. filePath)
        end
    end)
    
    if not success then
        print("[DELTA] Lỗi khi ghi status.txt:", err)
    end
end

-- Định nghĩa đường dẫn file
local filePath = "/sdcard/Delta_Workspace/status.txt"  -- ĐIỀU CHỈNH ĐƯỜNG DẪN NẾU CẦN

-- Kiểm tra sự tồn tại của thư mục và tạo nếu nó không tồn tại
local function ensureDirectoryExists(path)
    local dir = path:match("(.*/)")  -- Lấy đường dẫn thư mục
    if dir then
        local success, err = pcall(function()
            os.execute("mkdir -p " .. dir)  -- Tạo thư mục và các thư mục cha nếu cần
        end)
        if not success then
            print("[DELTA] Lỗi khi tạo thư mục:", err)
        end
    end
end

ensureDirectoryExists(filePath) -- Gọi hàm để đảm bảo thư mục tồn tại

-- Ghi lần đầu
writeStatus(filePath)

-- Lặp lại mỗi 2 phút
while true do
    task.wait(120)
    writeStatus(filePath)
end
