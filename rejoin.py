local HttpService = game:GetService("HttpService")

local webhook_url = "https://discord.com/api/webhooks/1368230361754243163/DL25j9slj-cbkWXysiMKopqEf-_YkT9DZUGk6m7wUq4RVXo7Q7Ex7ApBvxHRBqFdqZj6"

-- Gửi "online" mỗi 5 phút
while true do
    local data = {
        content = "online"
    }

    local success, err = pcall(function()
        HttpService:PostAsync(webhook_url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)

    if success then
        print("📡 Đã gửi tín hiệu 'online'")
    else
        warn("❌ Không gửi được tín hiệu:", err)
    end

    wait(300) -- Đợi 5 phút
end
