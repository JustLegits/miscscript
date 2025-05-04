local HttpService = game:GetService("HttpService")

-- Define a function to handle file writing
local function writeStatus(filePath)
    local data = {
        time = os.time(),
        -- Có thể thêm thông tin khác vào đây nếu cần
    }
    local encoded = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        local file = io.open(filePath, "w")
        if file then
            file:write(encoded)
            file:close()
            print("[RECONNECT] Đã ghi status.txt:", encoded, "vào", filePath)
        else
            error("Không thể mở file để ghi: " .. filePath)
        end
    end)

    if not success then
        print("[RECONNECT] Lỗi khi ghi status.txt:", err)
    end
end

-- Đường dẫn Workspace của Delta
local filePath = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/status.txt"

-- Kiểm tra sự tồn tại của thư mục và tạo nếu nó không tồn tại
local function ensureDirectoryExists(path)
    local dir = path:match("(.*/)")  -- Lấy đường dẫn thư mục
    if dir then
        local success, err = pcall(function()
            os.execute("mkdir -p " .. dir)  -- Tạo thư mục và các thư mục cha nếu cần
        end)
        if not success then
            print("[RECONNECT] Lỗi khi tạo thư mục:", err)
        end
    end
end

ensureDirectoryExists(filePath)

--[[
    Đoạn code Reconnect gốc của bạn sẽ ở đây.
    Ví dụ:
]]
local rejoining = false
local maxRetries = 5
local retryDelay = 5

local function reconnect()
    if rejoining then return end
    rejoining = true
    local retries = 0

    while retries < maxRetries do
        retries += 1
        print("[RECONNECT] Đang cố gắng kết nối lại lần thứ " .. retries .. "...")
        writeStatus(filePath)
        wait(retryDelay)
        if game.Players.LocalPlayer then
            game:GetService("ReplicatedFirst"):FireServer("Reconnect") -- Thay "Reconnect" bằng event bạn dùng
             if game.Players.LocalPlayer.Character then
               rejoining = false;
               return
            end
        end
    end
    print("[RECONNECT] Không thể kết nối lại sau " .. maxRetries .. " lần thử.")
    rejoining = false
end

game.Players.PlayerRemoving:Connect(function()
    reconnect()
end)

game.GuiService.OnGuiLost:Connect(reconnect)

-- Ghi trạng thái mỗi 2 phút
while true do
    wait(120)
    writeStatus(filePath)
end
