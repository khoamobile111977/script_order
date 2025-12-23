if not game:IsLoaded() then
    game.Loaded:Wait()
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local function getConfigFilePath(username)
    return username .. "_order_configs.json"
end

local function loadConfigs(username)
    local filePath = getConfigFilePath(username)
    if isfile(filePath) then
        local success, configData = pcall(function()
            return HttpService:JSONDecode(readfile(filePath))
        end)
        if success then
            return configData
        else
            warn("Lỗi giải mã JSON: ", configData)
        end
    end
    return { order = "[Trống]" }
end

local function saveConfigs(username, configData)
    local filePath = getConfigFilePath(username)
    local success, errorMessage = pcall(function()
        writefile(filePath, HttpService:JSONEncode(configData))
    end)
    if not success then
        warn("Lỗi khi lưu cấu hình: ", errorMessage)
    end
end

local playerGui = player:WaitForChild("PlayerGui")

local MainScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local ServerTimeLabel = Instance.new("TextLabel")
local OrderLabel = Instance.new("TextLabel")
local PlayerNameLabel = Instance.new("TextLabel")
local ClearButton = Instance.new("TextButton")
local SettingsButton = Instance.new("TextButton")
local UICornerMain = Instance.new("UICorner")

MainScreenGui.Parent = playerGui

MainFrame.Size = UDim2.new(0, 200, 0, 40)
MainFrame.Position = UDim2.new(0.5, -100, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = MainScreenGui

UICornerMain.CornerRadius = UDim.new(0, 10)
UICornerMain.Parent = MainFrame

local fadeInTweenMain = TweenService:Create(MainFrame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 0.4 })
fadeInTweenMain:Play()

ServerTimeLabel.Size = UDim2.new(1, -10, 0.2, 0)
ServerTimeLabel.Position = UDim2.new(0, 5, 0, 0)
ServerTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerTimeLabel.Font = Enum.Font.Roboto
ServerTimeLabel.TextScaled = true
ServerTimeLabel.BackgroundTransparency = 1
ServerTimeLabel.Parent = MainFrame

local injectStartTime = os.time()
task.spawn(function()
    while true do
        local elapsedTime = os.time() - injectStartTime
        local minutes = math.floor(elapsedTime / 60)
        local seconds = elapsedTime % 60
        ServerTimeLabel.Text = string.format("Thời gian: %02d:%02d", minutes, seconds)
        task.wait(1)
    end
end)

local username = player.Name
local configData = loadConfigs(username)

OrderLabel.Text = "Đơn hàng: " .. configData.order
OrderLabel.Size = UDim2.new(1, -10, 0.25, 0)
OrderLabel.Position = UDim2.new(0, 5, 0.25, 0)
OrderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
OrderLabel.Font = Enum.Font.Roboto
OrderLabel.TextScaled = true
OrderLabel.BackgroundTransparency = 1
OrderLabel.Parent = MainFrame

local visibleUsername = string.sub(username, 1, math.max(1, #username - 4)) .. "****"
PlayerNameLabel.Text = "Tên người chơi: " .. visibleUsername
PlayerNameLabel.Size = UDim2.new(1, -10, 0.25, 0)
PlayerNameLabel.Position = UDim2.new(0, 5, 0.55, 0)
PlayerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerNameLabel.Font = Enum.Font.Roboto
PlayerNameLabel.TextScaled = true
PlayerNameLabel.BackgroundTransparency = 1
PlayerNameLabel.Parent = MainFrame

ClearButton.Size = UDim2.new(0.1, 0, 0.2, 5)
ClearButton.Position = UDim2.new(0.03, 0, 0.25, 0)
ClearButton.Text = "🗑️"
ClearButton.TextColor3 = Color3.fromRGB(251, 251, 251)
ClearButton.Font = Enum.Font.GothamBold
ClearButton.TextScaled = true
ClearButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ClearButton.Parent = MainFrame

ClearButton.MouseButton1Click:Connect(function()
    saveConfigs(username, { order = "[Trống]" })
    OrderLabel.Text = "Đơn hàng: [Trống]"
    print("Đã xóa thông tin đơn hàng của tài khoản: " .. username)
end)

SettingsButton.Size = UDim2.new(0.1, 0, 0.25, 0)
SettingsButton.Position = UDim2.new(0, 5, 0.55, 0)
SettingsButton.Text = "⚙️"
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Font = Enum.Font.GothamBold
SettingsButton.TextScaled = true
SettingsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SettingsButton.Parent = MainFrame

local ConfigWindow = Instance.new("Frame")
local OrderInputBox = Instance.new("TextBox")
local DoneButton = Instance.new("TextButton")
local UICornerConfig = Instance.new("UICorner")

ConfigWindow.Size = UDim2.new(0, 175, 0, 75)
ConfigWindow.Position = UDim2.new(0.5, -87.5, 0.5, -37.5)
ConfigWindow.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ConfigWindow.BackgroundTransparency = 1
ConfigWindow.BorderSizePixel = 0
ConfigWindow.Visible = false
ConfigWindow.Parent = MainScreenGui

UICornerConfig.CornerRadius = UDim.new(0, 10)
UICornerConfig.Parent = ConfigWindow

OrderInputBox.Size = UDim2.new(0.8, 0, 0.4, 0)
OrderInputBox.Position = UDim2.new(0.1, 0, 0.3, 0)
OrderInputBox.PlaceholderText = "Nhập đơn hàng"
OrderInputBox.Text = ""
OrderInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
OrderInputBox.Font = Enum.Font.Roboto
OrderInputBox.TextScaled = true
OrderInputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OrderInputBox.Parent = ConfigWindow

DoneButton.Size = UDim2.new(0.3, 0, 0.3, 0)
DoneButton.Position = UDim2.new(0.35, 0, 0.7, 0)
DoneButton.Text = "Xong"
DoneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DoneButton.Font = Enum.Font.GothamBold
DoneButton.TextScaled = true
DoneButton.BackgroundColor3 = Color3.fromRGB(0, 128, 0)
DoneButton.Parent = ConfigWindow

local function showConfigWindow()
    ConfigWindow.Visible = true
    local fadeInTweenConfig = TweenService:Create(ConfigWindow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 })
    fadeInTweenConfig:Play()
end

local function hideConfigWindow()
    local fadeOutTweenConfig = TweenService:Create(ConfigWindow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
    fadeOutTweenConfig:Play()
    fadeOutTweenConfig.Completed:Connect(function()
        ConfigWindow.Visible = false
    end)
end

SettingsButton.MouseButton1Click:Connect(function()
    showConfigWindow()
end)

DoneButton.MouseButton1Click:Connect(function()
    local newOrder = OrderInputBox.Text
    if newOrder ~= "" then
        OrderLabel.Text = "Đơn hàng: " .. newOrder
        saveConfigs(username, { order = newOrder })
        print("Đã lưu chỉnh sửa đơn hàng cho tài khoản: " .. username)
    else
        warn("Không thể lưu đơn hàng vì giá trị trống!")
    end
    hideConfigWindow()
end)
