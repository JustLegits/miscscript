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
local canWrite = true
local lastActivityTime = 0 -- Thời gian hoạt động cuối cùng
local MAX_TELEPORT_TIME = 10 -- Thời gian tối đa cho phép teleport (giây)

-- Hàm ghi file trạng thái
local function writeStatus()
    if not canWrite then
        print("[LUA] Đang chờ để ghi trạng thái...")
        return
    end
    canWrite = false

    local data = {
        time = lastActivityTime,
        isDisconnected = isDisconnected,
    }
    local encoded = HttpService:JSONEncode(data)
    local filePath = game.Workspace.Name .. "_" .. fileName -- Tạo tên file duy nhất

    local success, err = pcall(function()
        writefile(filePath, encoded)
        print("[LUA] Đã ghi " .. filePath .. ": " .. encoded)
    end)
    if not success then
        print("[LUA] Lỗi khi ghi " .. filePath .. ":", err)
    end

    -- Sử dụng task.delay thay vì delay
    task.delay(checkInterval, function()
        canWrite = true
        print("[LUA] Có thể ghi lại trạng thái.")
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
    if isChecking then
        --print("[LUA] Đang kiểm tra trạng thái, bỏ qua...")
        return
    end
    isChecking = true

    local currentTime = os.time()

    -- Kiểm tra nếu đang trong quá trình teleport
    if hasTeleported and (currentTime - teleportStartTime) < MAX_TELEPORT_TIME then
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
RunService.Heartbeat:Connect(function()
    checkStatus()
end)
