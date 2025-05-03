local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function writeStatus()
    local success, err = pcall(function()
        local timestamp = os.time()
        writefile("/sdcard/roblox_status/status.txt", tostring(timestamp))
    end)
    if not success then
        warn("Ghi file lỗi: " .. tostring(err))
    end
end

writeStatus()

-- Ghi mỗi 60 giây
while true do
    wait(60)
    writeStatus()
end
