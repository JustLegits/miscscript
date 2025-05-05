local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local fileName = "status.json"

local isDisconnected = false

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
        writeStatus() -- Ghi trạng thái ngắt kết nối
        warn("[LUA] Player removed.  Recording disconnection.")
    end
end)

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại mỗi 2 phút
while true do
    task.wait(120)
    writeStatus()
end
