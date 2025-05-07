local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local fileName = "status.json"
local isDisconnected = false
local lastWriteTime = 0  -- Biến để theo dõi thời điểm ghi cuối cùng

-- Hàm ghi file trạng thái
local function writeStatus()
    local data = {
        time = os.time(),
        isDisconnected = isDisconnected,
    }
    local encoded = HttpService:JSONEncode(data)
    local filePath = fileName

    writefile(filePath, encoded)
    warn(":pushpin: Status saved to " .. filePath)
    print("[LUA] Đã ghi " .. filePath .. ": " .. encoded)
    lastWriteTime = os.time() -- Cập nhật thời điểm ghi
end

-- 1. Xử lý sự kiện PlayerRemoving
Players.PlayerRemoving:Connect(function(removingPlayer)
    if removingPlayer == player then
        isDisconnected = true
        writeStatus()
        warn("[LUA] PlayerRemoving: Player removed.")
    end
end)

-- 2. Phát hiện bị kick (hook Kick function)
local mt = getrawmetatable(game)
if mt then
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "Kick" and self == player then
            isDisconnected = true
            writeStatus()
            warn("[LUA] __namecall: Phát hiện bị kick.")
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại để ghi trạng thái định kỳ
RunService.Heartbeat:Connect(function()
    -- Kiểm tra nếu đã 60 giây kể từ lần ghi cuối
    if os.time() - lastWriteTime >= 60 then
        writeStatus()
    end
end)
