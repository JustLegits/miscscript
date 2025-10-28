--[[
    Script Cải Tiến: Auto Teleport v3
    - GUI Bật/Tắt
    - Tùy chỉnh giây teleport
    - Nút Lưu và Xóa Vị Trí
    - Tự động lưu và tải cấu hình (Giây, Bật/Tắt)
]]

-- Dịch vụ và Biến
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local fileName = "SavedPosition.json"
local configFileName = "TeleportConfig.json" -- MỚI: File để lưu cài đặt
local savedPos = nil
local isTeleporting = false
local teleportThread = nil

-- Hàm chờ Character và HRP (sẽ được gọi lại nếu nhân vật chết)
local function getHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    return hrp
end

local hrp = getHRP()

-- ===================================================================
-- TẠO GIAO DIỆN (GUI)
-- ===================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainFrame.BorderColor3 = Color3.fromRGB(150, 150, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Draggable = true
MainFrame.Active = true

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleLabel.BorderColor3 = Color3.fromRGB(150, 150, 150)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Auto Teleport v3" -- MỚI: Cập nhật tiêu đề
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Màu Đỏ (TẮT)
ToggleButton.Position = UDim2.new(0.05, 0, 0.28, 0)
ToggleButton.Size = UDim2.new(0.4, 0, 0, 35)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "TẮT"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16

local IntervalLabel = Instance.new("TextLabel")
IntervalLabel.Name = "IntervalLabel"
IntervalLabel.Parent = MainFrame
IntervalLabel.BackgroundTransparency = 1
IntervalLabel.Position = UDim2.new(0.5, 0, 0.28, 0)
IntervalLabel.Size = UDim2.new(0.2, 0, 0, 35)
IntervalLabel.Font = Enum.Font.SourceSans
IntervalLabel.Text = "Giây:"
IntervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
IntervalLabel.TextSize = 14
IntervalLabel.TextXAlignment = Enum.TextXAlignment.Right

local IntervalBox = Instance.new("TextBox")
IntervalBox.Name = "IntervalBox"
IntervalBox.Parent = MainFrame
IntervalBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
IntervalBox.BorderColor3 = Color3.fromRGB(150, 150, 150)
IntervalBox.Position = UDim2.new(0.72, 0, 0.28, 0)
IntervalBox.Size = UDim2.new(0.23, 0, 0, 35)
IntervalBox.Font = Enum.Font.SourceSans
IntervalBox.Text = "1" -- Mặc định 1 giây
IntervalBox.TextColor3 = Color3.fromRGB(255, 255, 255)
IntervalBox.TextSize = 14
IntervalBox.ClearTextOnFocus = false

local SetButton = Instance.new("TextButton")
SetButton.Name = "SetButton"
SetButton.Parent = MainFrame
SetButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
SetButton.Position = UDim2.new(0.05, 0, 0.65, 0)
SetButton.Size = UDim2.new(0.4, 0, 0, 35)
SetButton.Font = Enum.Font.SourceSansBold
SetButton.Text = "Lưu Vị Trí"
SetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SetButton.TextSize = 16

local DeleteButton = Instance.new("TextButton")
DeleteButton.Name = "DeleteButton"
DeleteButton.Parent = MainFrame
DeleteButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
DeleteButton.Position = UDim2.new(0.55, 0, 0.65, 0)
DeleteButton.Size = UDim2.new(0.4, 0, 0, 35)
DeleteButton.Font = Enum.Font.SourceSansBold
DeleteButton.Text = "Xóa Vị Trí"
DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteButton.TextSize = 16

-- ===================================================================
-- CHỨC NĂNG SCRIPT
-- ===================================================================

-- --- MỚI: Hàm lưu cài đặt (Giây, Bật/Tắt) ---
local function saveConfig()
    local configTable = {
        interval = tonumber(IntervalBox.Text) or 1,
        autoStart = isTeleporting
    }
    local encoded = HttpService:JSONEncode(configTable)
    writefile(configFileName, encoded)
    warn(":floppy_disk: Đã lưu cấu hình (Bật: " .. tostring(isTeleporting) .. ", Giây: " .. configTable.interval .. ")")
end

-- Hàm tải vị trí
local function loadPosition()
    local success, result = pcall(function()
        if isfile(fileName) then
            return HttpService:JSONDecode(readfile(fileName))
        end
        return nil
    end)

    if success and result and result.x and result.y and result.z then
        savedPos = Vector3.new(result.x, result.y, result.z)
        warn(":white_check_mark: Đã tải vị trí đã lưu:", savedPos)
    else
        savedPos = nil
        warn(":x: Không tìm thấy vị trí. Hãy 'Lưu Vị Trí' để bắt đầu.")
    end
end

-- Hàm dừng vòng lặp teleport
local function stopTeleporting()
    if teleportThread then
        task.cancel(teleportThread)
        teleportThread = nil
    end
    isTeleporting = false
    ToggleButton.Text = "TẮT"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Đỏ
    warn(":stop_button: Đã dừng auto teleport.")
end

-- Nút BẬT/TẮT
ToggleButton.MouseButton1Click:Connect(function()
    isTeleporting = not isTeleporting -- Đảo trạng thái

    if isTeleporting then
        -- BẮT ĐẦU
        if not savedPos then
            warn(":x: Không có vị trí để teleport! Vui lòng 'Lưu Vị Trí' trước.")
            isTeleporting = false -- Tắt lại
            saveConfig() -- MỚI: Lưu trạng thái TẮT vì không thành công
            return
        end

        local interval = tonumber(IntervalBox.Text)
        if not interval or interval <= 0 then
            warn(":warning: Số giây không hợp lệ. Đặt thành 1.")
            interval = 1
            IntervalBox.Text = "1"
        end

        ToggleButton.Text = "BẬT"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Xanh
        warn(":arrow_forward: Bắt đầu auto teleport mỗi " .. interval .. " giây.")

        -- Bắt đầu vòng lặp
        teleportThread = task.spawn(function()
            while isTeleporting do
                if player.Character and hrp then
                    hrp.CFrame = CFrame.new(savedPos)
                else
                    warn("Đang chờ nhân vật...")
                    hrp = getHRP()
                    if hrp then
                         hrp.CFrame = CFrame.new(savedPos)
                    end
                end
                task.wait(interval)
            end
        end)
    else
        -- DỪNG
        stopTeleporting()
    end
    
    saveConfig() -- MỚI: Lưu trạng thái BẬT hoặc TẮT mỗi khi nhấn nút
end)

-- Nút LƯU VỊ TRÍ
SetButton.MouseButton1Click:Connect(function()
    hrp = getHRP()
    local currentPos = hrp.Position
    local posTable = {
        x = currentPos.X,
        y = currentPos.Y,
        z = currentPos.Z
    }

    local encoded = HttpService:JSONEncode(posTable)
    writefile(fileName, encoded)
    
    savedPos = currentPos
    warn(":pushpin: Vị trí MỚI đã được lưu:", currentPos)
end)

-- Nút XÓA VỊ TRÍ
DeleteButton.MouseButton1Click:Connect(function()
    if isfile(fileName) then
        dile(fileName)
        savedPos = nil
        warn(":wastebasket: Đã xóa file lưu vị trí:", fileName)
        
        if isTeleporting then
            stopTeleporting()
            saveConfig() -- MỚI: Lưu trạng thái TẮT
            warn("Đã tự động tắt teleport vì file bị xóa.")
        end
    else
        warn(":x: Không tìm thấy file để xóa:", fileName)
    end
end)

-- --- MỚI: Hàm tải cài đặt (Giây, Bật/Tắt) ---
local function loadConfig()
    local success, result = pcall(function()
        if isfile(configFileName) then
            return HttpService:JSONDecode(readfile(configFileName))
        end
        return nil
    end)

    if success and result and result.interval then
        IntervalBox.Text = tostring(result.interval) -- Tải số giây vào TextBox
        warn(":floppy_disk: Đã tải cấu hình: Giây = " .. result.interval)
        
        if result.autoStart == true then
            warn("... Tự động BẬT theo cấu hình đã lưu.")
            -- Chờ một chút để script (đặc biệt là loadPosition) ổn định
            task.wait(0.2) 
            -- Tự động nhấn nút BẬT/TẮT để kích hoạt
            ToggleButton.MouseButton1Click:Fire()
        end
    else
        warn(":card_box: Không tìm thấy file config, dùng mặc định.")
    end
end


-- ===================================================================
-- KHỞI CHẠY SCRIPT
-- ===================================================================

-- 1. Tải vị trí đã lưu (nếu có) khi script bắt đầu
loadPosition()

-- 2. Tải cài đặt (nếu có) và tự động bật nếu được cài
loadConfig() -- MỚI: Gọi hàm tải config

-- Dọn dẹp
player.CharacterRemoving:Connect(function()
    if teleportThread then
        task.cancel(teleportThread)
    end
end)
