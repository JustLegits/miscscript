local path = "/sdcard/roblox_status/status.txt"
local HttpService = game:GetService("HttpService")
local function updateStatus()
    local now = os.time()
    writefile(path, tostring(now))
end

while true do
    updateStatus()
    wait(300)  -- 5 phút
end
