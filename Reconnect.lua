local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local fileName = "status.json"

local isDisconnected = false
local connectionCheckInterval = 5  -- Kiểm tra mỗi 5 giây

-- Hàm ghi file trạng thái
local function writeStatus()
    local data = {
        time = os.time(),
        isDisconnected = isDisconnected,
    }
    local encoded = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        writefile(fileName, encoded)
        print("[LUA] Đã ghi " .. fileName .. ": " .. encoded)
    end)
    if not success then
        print("[LUA] Lỗi khi ghi " .. fileName .. ":", err)
    end
end

-- Xử lý sự kiện PlayerRemoving
Players.PlayerRemoving:Connect(function(removingPlayer)
    if removingPlayer == player then
        isDisconnected = true
        writeStatus()
        warn("[LUA] Player removed. Recording disconnection.")
    end
end)

-- Xử lý khi trò chơi đóng
game:BindToClose(function()
    isDisconnected = true
    writeStatus()
    warn("[LUA] Game is closing. Recording disconnection.")
end)

-- Kiểm tra định kỳ sự tồn tại của Player
game:GetService("RunService").Heartbeat:Connect(function()
    if not Players:FindFirstChild(player.Name) then
        if not isDisconnected then  -- Chỉ khi chưa báo ngắt kết nối
            isDisconnected = true
            writeStatus()
            warn("[LUA] Player object no longer exists. Recording disconnection.")
        end
    end
end)

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại mỗi 2 phút để cập nhật trạng thái
while true do
    task.wait(120)
    writeStatus()
end
