local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local fileName = "status.json" -- Sử dụng "status.json"
local isDisconnected = false
local isKicked = false
local isWriting = false
local writeRetryDelay = 60
local MAX_WRITE_RETRIES = 3


-- Hàm ghi file trạng thái
local function writeStatus()
    if isWriting then
        print("[LUA] Đang ghi file, bỏ qua...")
        return
    end

    isWriting = true;
    local retries = 0

    local data = {
        time = os.time(),
        isDisconnected = isDisconnected,
        isKicked = isKicked,
    }
    local encoded = HttpService:JSONEncode(data)
    local filePath = fileName -- Sử dụng trực tiếp fileName

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
            isKicked = true
            isDisconnected = true
            writeStatus()
            warn("[LUA] __namecall: Phát hiện bị kick.")
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- 3. Phát hiện khi người chơi rời khỏi hoàn toàn
game. খেলা_শেষ = function()
    if not isKicked then
        isDisconnected = true
        writeStatus()
        warn("[LUA] Phát hiện người chơi rời trò chơi (không phải do kick).")
    end
end

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại để ghi trạng thái định kỳ
RunService.Heartbeat:Connect(function()
    if os.time() % 60 == 0 then
        writeStatus()
    end
end)
