local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local fileName = "status.json"

local isDisconnected = false
local checkInterval = 60  -- Đặt thời gian kiểm tra là 60 giây
local isChecking = false
local hasTeleported = false
local teleportStartTime = 0
local canWrite = true
local lastActivityTime = 0 -- Thời gian hoạt động cuối cùng

-- Hàm ghi file trạng thái
local function writeStatus()
    if not canWrite then return end
    canWrite = false

    local data = {
        time = lastActivityTime, -- Sử dụng lastActivityTime
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

    canWrite = false
    task.delay(checkInterval, function()
        canWrite = true
    end)
end

-- 1. Xử lý sự kiện PlayerRemoving
Players.PlayerRemoving:Connect(function(removingPlayer)
    if removingPlayer == player then
        isDisconnected = true
        writeStatus()
        warn("[LUA] PlayerRemoving: Player removed.")
    end
end)

-- 2. Hàm kiểm tra và cập nhật trạng thái
local function checkStatus()
    if isChecking then return end
    isChecking = true

    local currentTime = os.time()

    -- Kiểm tra nếu đang trong quá trình teleport
    if hasTeleported and (currentTime - teleportStartTime) < 10 then
        print("[LUA] Đang trong quá trình Teleport, bỏ qua kiểm tra...")
        isChecking = false
        return
    end

    -- 2. Kiểm tra sự tồn tại của PlayerGui
    if not player:FindFirstChild("PlayerGui") then
        isDisconnected = true
        writeStatus()
        warn("[LUA] PlayerGui không tồn tại: Có thể đã disconnect.")
        isChecking = false;
        return
    end

    -- 3. Kiểm tra Parent của Player
    if player.Parent ~= Players then
        isDisconnected = true
        writeStatus()
        warn("[LUA] Player.Parent không phải là Players: Có thể đã disconnect.")
        isChecking = false;
        return
    end

    -- Nếu vẫn còn kết nối, cập nhật thời gian hoạt động
    lastActivityTime = currentTime
    writeStatus() -- Ghi lại thời gian hoạt động

    isChecking = false
    hasTeleported = false
end

-- 4. Phát hiện ErrorPrompt
CoreGui.ChildAdded:Connect(function(child)
    if child:FindFirstChild("ErrorPrompt") then
        local errorPrompt = child:FindFirstChild("ErrorPrompt")
        local textLabel = errorPrompt:FindFirstChild("TextLabel")
        if textLabel then
            local errorText = textLabel.Text
            if string.find(errorText, "Error Code: ") or
               string.find(errorText, "You were kicked") or
               string.find(errorText, "connection lost") then
                isDisconnected = true
                writeStatus()
                warn("[LUA] ErrorPrompt: Phát hiện lỗi: " .. errorText)
            elseif string.find(errorText, "Teleporting") then
                hasTeleported = true
                teleportStartTime = os.time()
                warn("[LUA] Phát hiện Teleporting...")
            end
        end
    end
end)

-- 5. Phát hiện bị kick (hook Kick function)
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

-- 6. Xử lý khi Teleport xong
Players.LocalPlayer.Changed:Connect(function(property)
    if property == "Parent" then
        if player.Parent == Players then
            if hasTeleported then
                hasTeleported = false
                isDisconnected = false
                writeStatus()
                warn("[LUA] Teleport hoàn thành. Đặt lại trạng thái.")
            end
        end
    end
end)

-- Ghi trạng thái ban đầu
writeStatus()
lastActivityTime = os.time()

-- Lặp lại để kiểm tra và cập nhật trạng thái định kỳ
game:GetService("RunService").Heartbeat:Connect(function()
    checkStatus()
end)
