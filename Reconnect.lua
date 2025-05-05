local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
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

-- Hàm kiểm tra sự tồn tại của người chơi trong Workspace
local function checkPlayerInWorkspace()
    if not Workspace:FindFirstChild(player.Name) then
        if not isDisconnected then
            isDisconnected = true
            writeStatus()
            warn("[LUA] Player's username no longer exists in Workspace. Recording disconnection.")
        end
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

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại mỗi 2 giây để kiểm tra
while true do
    task.wait(2)
    checkPlayerInWorkspace()
    task.wait(120)  -- Vẫn cập nhật thời gian định kỳ
    writeStatus()
end
