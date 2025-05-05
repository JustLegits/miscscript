local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local fileName = "status.json"

local isDisconnected = false
local checkInterval = 120
local teleportFailed = false  -- Thay đổi thành boolean

-- Hàm ghi file trạng thái
local function writeStatus()
    local data = {
        time = os.time(),
        isDisconnected = isDisconnected,
        teleportFailed = teleportFailed,
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

-- 1. Xử lý sự kiện PlayerRemoving
Players.PlayerRemoving:Connect(function(removingPlayer)
    if removingPlayer == player then
        isDisconnected = true
        teleportFailed = false -- Reset teleportFailed
        writeStatus()
        warn("[LUA] PlayerRemoving: Player removed.")
    end
end)

-- 2. Kiểm tra sự tồn tại của PlayerGui
local function checkPlayerGui()
    if not player:FindFirstChild("PlayerGui") then
        if not isDisconnected then
            isDisconnected = true
            teleportFailed = false -- Reset teleportFailed
            writeStatus()
            warn("[LUA] PlayerGui không tồn tại: Có thể đã disconnect.")
        end
    end
end

-- 3. Kiểm tra Parent của Player
local function checkPlayerParent()
    if player.Parent ~= Players then
        if not isDisconnected then
            isDisconnected = true
            teleportFailed = false -- Reset teleportFailed
            writeStatus()
            warn("[LUA] Player.Parent không phải là Players: Có thể đã disconnect.")
        end
    end
end

-- 4. Phát hiện ErrorPrompt (mở rộng)
CoreGui.ChildAdded:Connect(function(child)
    if child:FindFirstChild("ErrorPrompt") then
        local errorPrompt = child:FindFirstChild("ErrorPrompt")
        local textLabel = errorPrompt:FindFirstChild("TextLabel")
        if textLabel then
            local errorText = textLabel.Text
            if string.find(errorText, "Error Code: ") then
                isDisconnected = true
                teleportFailed = false -- Reset teleportFailed
                writeStatus()
                warn("[LUA] ErrorPrompt: Phát hiện mã lỗi: " .. errorText)
            elseif string.find(errorText, "You were kicked") then
                isDisconnected = true
                teleportFailed = false -- Reset teleportFailed
                writeStatus()
                warn("[LUA] ErrorPrompt: Phát hiện thông báo bị kick: " .. errorText)
            elseif string.find(errorText, "connection lost") then
                isDisconnected = true
                teleportFailed = false -- Reset teleportFailed
                writeStatus()
                warn("[LUA] ErrorPrompt: Phát hiện mất kết nối: " .. errorText)
            elseif string.find(errorText, "Teleport Failed") then
                teleportFailed = true
                isDisconnected = false  -- Đặt isDisconnected thành false
                writeStatus()
                warn("[LUA] ErrorPrompt: Phát hiện Teleport Failed.")
            else
                teleportFailed = false
                isDisconnected = false
                writeStatus()
            end
        end
    end
end)

-- 5. Phát hiện bị kick (hook Kick function) - cải tiến
local mt = getrawmetatable(game)
if mt then
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "Kick" and self == player then
            isDisconnected = true
            teleportFailed = false  -- Reset teleportFailed
            writeStatus()
            warn("[LUA] __namecall: Phát hiện bị kick.")
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại để kiểm tra và cập nhật trạng thái định kỳ
while true do
    task.wait(checkInterval)
    checkPlayerGui()
    checkPlayerParent()
    writeStatus()
end
