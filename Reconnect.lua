local HttpService = game:GetService("HttpService")

-- Define a function to handle file writing with error handling
local function writeStatus(filePath)
    local data = {
        time = os.time()
    }
    local encoded = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        -- Attempt to write to the specified file path
        local file = io.open(filePath, "w")
        if file then
            file:write(encoded)
            file:close()
            print("[KRNL] Đã ghi status.txt:", encoded, "vào", filePath)
        else
            error("Không thể mở file để ghi.") -- Explicitly raise an error if io.open fails
        end
    end)

    if not success then
        print("[KRNL] Lỗi khi ghi status.txt:", err)
        -- Consider adding a retry mechanism here if the error is recoverable
    end
end

-- Define the file path.  This is the key change.
local filePath = "/sdcard/roblox_status.txt"  -- Default to /sdcard/

-- Check if the executor is KRNL and adjust the path if needed.
if KRNL then --Check if KRNL is defined.  Most executors don't define KRNL.
  filePath = "/sdcard/roblox_status.txt" --Force /sdcard
  print("[KRNL] Using /sdcard/roblox_status.txt")
elseif  true then -- add a condition for another executor
    filePath = "/sdcard/roblox_status.txt"
    print("[EXE] Using /sdcard/roblox_status.txt")
else
  filePath = "/sdcard/roblox_status.txt"
  print("[DEFAULT] Using /sdcard/roblox_status.txt")
end


-- Ghi lần đầu
writeStatus(filePath)

-- Lặp lại mỗi 2 phút
while true do
    task.wait(120)
    writeStatus(filePath)
end
