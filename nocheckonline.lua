--// Reconnect JSON writer (updates every 1s)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local username = Players.LocalPlayer.Name
local folder = "Reconnect"
local filepath = folder .. "/reconnect_status_" .. username .. ".json"

-- Create folder if missing
if not isfolder(folder) then
    makefolder(folder)
end

-- Loop to update file every 1 second
task.spawn(function()
    while task.wait(1) do
        local data = {
            status = "Online",
            timestamp = os.time(),
            user = username
        }

        -- Convert to JSON (compact, no extra spaces)
        local jsonData = HttpService:JSONEncode(data)

        -- Write file
        writefile(filepath, jsonData)
    end
end)

print("[Reconnect] Auto-updating JSON every 1s at: " .. filepath)
