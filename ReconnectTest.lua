local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local fileName = "status.json"
local isDisconnected = false
local isWriting = false
local writeRetryDelay = 60
local MAX_WRITE_RETRIES = 3

-- Hàm ghi file trạng thái
local function writeStatus()
    if isWriting then
        print("[LUA] Đang ghi file, bỏ qua...")
        return
    end

    isWriting = true
    local retries = 0

    local data = {
        time = os.time(),
        isDisconnected = isDisconnected,
    }
    local encoded = HttpService:JSONEncode(data)
    local filePath = game.Workspace.Name .. "_" .. fileName

    local function tryWrite()
        local success, err = pcall(function()
            writefile(filePath, encoded)
            print("[LUA] Đã ghi " .. filePath .. ": " .. encoded)
        end)

        if success then
            isWriting = false
        else
            retries = retries + 1
            if retries <= MAX_WRITE_RETRIES then
                print("[LUA] Lỗi khi ghi " .. filePath .. ": " .. err .. ". Thử lại sau " .. writeRetryDelay .. " giây.")
                task.delay(writeRetryDelay, tryWrite)
            else
                print("[LUA] Đã thử lại nhiều lần nhưng vẫn không thành công. Bỏ qua.")
                isWriting = false
            end
        end
    end

    tryWrite()
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

-- 3. Xử lý khi Teleport xong
Players.LocalPlayer.Changed:Connect(function(property)
    if property == "Parent" then
        if player.Parent == Players then
            isDisconnected = false -- Đặt lại trạng thái khi teleport xong
            writeStatus()
            warn("[LUA] Teleport hoàn thành. Đặt lại trạng thái.")
        end
    end
end)

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại để ghi trạng thái định kỳ (ví dụ: mỗi 60 giây)
RunService.Heartbeat:Connect(function()
    if os.time() % 60 == 0 then -- Kiểm tra mỗi 60 giây
        writeStatus()
    end
end)
