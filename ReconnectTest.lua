local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local fileName = "status.json"

local isDisconnected = false
local checkInterval = 60  -- Đặt thời gian kiểm tra là 60 giây
local isChecking = false
local hasTeleported = false
local teleportStartTime = 0
local isWriting = false  -- Sử dụng biến này để kiểm soát việc ghi
local lastActivityTime = 0
local MAX_TELEPORT_TIME = 10
local MAX_WRITE_RETRIES = 3 -- Số lần thử lại tối đa

-- Hàm ghi file trạng thái
local function writeStatus()
    if isWriting then
        print("[LUA] Đang ghi file, bỏ qua...")
        return
    end

    isWriting = true
    local retries = 0

    local data = {
        time = lastActivityTime,
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
                print("[LUA] Lỗi khi ghi " .. filePath .. ": " .. err .. ". Thử lại sau " .. checkInterval .. " giây.")
                task.delay(checkInterval, tryWrite) -- Sử dụng task.delay
            else
                print("[LUA] Đã thử lại nhiều lần nhưng vẫn không thành công. Bỏ qua.")
                isWriting = false
            end
        end
    end

    tryWrite() -- Bắt đầu quá trình ghi
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
    if isChecking then
        return
    end
    isChecking = true
    local currentTime = os.time()

    if hasTeleported and (currentTime - teleportStartTime) < MAX_TELEPORT_TIME then
        print("[LUA] Đang trong quá trình Teleport, bỏ qua kiểm tra...")
        isChecking = false
        return
    end

    if not player:FindFirstChild("PlayerGui") then
        isDisconnected = true
        writeStatus()
        warn("[LUA] PlayerGui không tồn tại: Có thể đã disconnect.")
        isChecking = false
        return
    end

    if player.Parent ~= Players then
        isDisconnected = true
        writeStatus()
        warn("[LUA] Player.Parent không phải là Players: Có thể đã disconnect.")
        isChecking = false
        return
    end

    lastActivityTime = currentTime
    writeStatus()
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
RunService.Heartbeat:Connect(function()
    checkStatus()
end)
