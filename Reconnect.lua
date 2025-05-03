-- Script chạy trong Roblox qua KRNL
-- Ghi file trạng thái mỗi 60 giây với thời gian hiện tại

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Đường dẫn ghi file (lưu trên Android)
local filepath = "/sdcard/roblox_status/status.txt"

-- Hàm ghi trạng thái
local function writeStatus()
    local timeStr = os.date("%Y-%m-%d %H:%M:%S")
    writefile(filepath, timeStr)
    print("[✅] Đã ghi trạng thái:", timeStr)
end

-- Ghi ngay khi script bắt đầu
writeStatus()

-- Ghi lại mỗi 60 giây
while true do
    wait(60)
    writeStatus()
end
