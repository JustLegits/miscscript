--[[
    Script này sẽ ghi thời gian vào một file khi người chơi vào server.
    Chỉ sử dụng cho mục đích thử nghiệm.
]]

local Players = game:GetService("Players")

-- Đường dẫn tuyệt đối đến file (nhớ thay đổi)
local filePath = "C:\\path\\to\\your\\log.txt"

-- Hàm để ghi nội dung vào file
local function writeFile(path, text)
    local file = io.open(path, "a")
    if file then
        file:write(text .. "\n")
        file:close()
        print("Đã ghi vào file thành công.")
    else
        error("Không thể mở file để ghi.")
    end
end

-- Hàm này sẽ được gọi khi người chơi đã sẵn sàng
local function onPlayerAdded(player)
    local joinTime = os.time()
    local content = "Người chơi: " .. player.Name .. " đã vào server lúc: " .. joinTime
    writeFile(filePath, content)
    print("Đã ghi thời gian vào file khi người chơi vào.")
end

-- Kết nối hàm onPlayerAdded với sự kiện PlayerAdded
Players.PlayerAdded:Connect(onPlayerAdded)

-- Nếu bạn muốn ghi thời gian của người chơi hiện tại khi script chạy, hãy thêm đoạn này:
if Players.LocalPlayer then
    onPlayerAdded(Players.LocalPlayer)
end
