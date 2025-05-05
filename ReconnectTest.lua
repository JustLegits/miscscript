local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local fileName = "status.json"

local isDisconnected = false
local checkInterval = 120
local isTeleporting = false  -- Thêm biến theo dõi trạng thái Teleport

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

-- 1. Xử lý sự kiện PlayerRemoving
Players.PlayerRemoving:Connect(function(removingPlayer)
    if removingPlayer == player then
        isDisconnected = true
        writeStatus()
        warn("[LUA] PlayerRemoving: Player removed.")
    end
end)

-- 2. Kiểm tra sự tồn tại của PlayerGui
local function checkPlayerGui()
    if not player:FindFirstChild("PlayerGui") then
        if not isDisconnected and not isTeleporting then -- Thêm kiểm tra isTeleporting
            isDisconnected = true
            writeStatus()
            warn("[LUA] PlayerGui không tồn tại: Có thể đã disconnect.")
        end
    end
end

-- 3. Kiểm tra Parent của Player
local function checkPlayerParent()
    if player.Parent ~= Players then
        if not isDisconnected and not isTeleporting then -- Thêm kiểm tra isTeleporting
            isDisconnected = true
            writeStatus()
            warn("[LUA] Player.Parent không phải là Players: Có thể đã disconnect.")
        end
    end
end

-- 4. Phát hiện ErrorPrompt (đã chỉnh sửa)
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
            elseif string.find(errorText, "Teleporting") then -- Phát hiện bắt đầu Teleport
                isTeleporting = true
                warn("[LUA] Phát hiện Teleporting...")
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
            writeStatus()
            warn("[LUA] __namecall: Phát hiện bị kick.")
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- 6. Xử lý khi Teleport xong (PlayerGui xuất hiện trở lại)
Players.LocalPlayer.Changed:Connect(function(property)
    if property == "PlayerGui" then
        if isTeleporting then
            isTeleporting = false -- Reset trạng thái Teleport
            isDisconnected = false -- Đặt lại isDisconnected để tránh nhận diện sai
            writeStatus()
            warn("[LUA] Teleport hoàn thành. Đặt lại trạng thái.")
        end
    end
end)

-- Ghi trạng thái ban đầu
writeStatus()

-- Lặp lại để kiểm tra và cập nhật trạng thái định kỳ
while true do
    task.wait(checkInterval)
    checkPlayerGui()
    checkPlayerParent()
    writeStatus()
end
