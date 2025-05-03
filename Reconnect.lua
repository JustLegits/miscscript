-- reconnect.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local webhookURL = "https://discord.com/api/webhooks/1368230361754243163/DL25j9slj-cbkWXysiMKopqEf-_YkT9DZUGk6m7wUq4RVXo7Q7Ex7ApBvxHRBqFdqZj6"
local playerName = Players.LocalPlayer.Name

while true do
    local data = {
        content = "online|" .. playerName
    }
    HttpService:PostAsync(webhookURL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    wait(300) -- gửi mỗi 5 phút
end
