local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local filePath = "status.txt"
local player = Players.LocalPlayer

local function writeStatus()
    local time = os.time()
    if isfile(filePath) then
        delfile(filePath)
    end
    writefile(filePath, tostring(time))
end

writeStatus()

while true do
    task.wait(60) -- chờ 60 giây
    writeStatus()
end
