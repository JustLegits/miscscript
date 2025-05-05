local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
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

-- Hàm kiểm tra mã lỗi chung
local function checkGenericErrorCode(text)
    return string.find(text, "Error Code: ") ~= nil
end

-- Phát hiện ErrorPrompt xuất hiện
CoreGui.ChildAdded:Connect(function(child)
    if child:FindFirstChild("ErrorPrompt") then
        local errorPrompt = child:FindFirstChild("ErrorPrompt")
        local textLabel = errorPrompt:FindFirstChild("TextLabel")

        if textLabel and checkGenericErrorCode(textLabel.Text) then
            isDisconnected = true
            writeStatus()
            warn("[LUA] Phát hiện ErrorPrompt với mã lỗi. Recording disconnection.")
        end
    end
end)

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

-- Lặp lại mỗi 2 phút
while true do
    task.wait(120)
    writeStatus()
end
