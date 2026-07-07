if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat wait() until game:IsLoaded()
repeat wait() until game.Players and game.Players.LocalPlayer

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local player = Players.LocalPlayer

--================================================================
-- CONFIG PERSISTENCE (unchanged logic)
--================================================================

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

--================================================================
-- THEME
--================================================================

local BG_COLOR      = Color3.fromRGB(7, 7, 16)
local GLOW_COLOR    = Color3.fromRGB(30, 200, 230)   -- cyan accent per user preference
local STROKE_COLOR  = Color3.fromRGB(40, 220, 240)
local COL_CYAN      = Color3.fromRGB(60, 230, 255)
local COL_GREEN     = Color3.fromRGB(80, 255, 150)
local COL_RED       = Color3.fromRGB(255, 90, 90)
local COL_MUTED     = Color3.fromRGB(150, 160, 185)
local COL_TEXT      = Color3.fromRGB(235, 240, 250)

local PANEL_WIDTH   = 300

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = inst
    return c
end

local function stroke(inst, thickness, color, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.4
    s.Color = color or STROKE_COLOR
    s.Transparency = transparency or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- Generic drag support attached to a "handle" that moves a "target" frame
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--================================================================
-- ROOT
--================================================================

local playerGui = player:WaitForChild("PlayerGui")

local SG = Instance.new("ScreenGui")
SG.Name = "OrderTrackerUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 999
SG.Parent = playerGui

--================================================================
-- MAIN PANEL
--================================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, PANEL_WIDTH, 0, 138)
MainFrame.Position = UDim2.new(0.5, -150, 0, 12)
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = SG
corner(MainFrame, 16)
local mainStroke = stroke(MainFrame, 1.6, STROKE_COLOR, 0.35)

-- soft cyan glow behind the top of the panel
local GlowBg = Instance.new("Frame")
GlowBg.Size = UDim2.new(1, 0, 0, 60)
GlowBg.Position = UDim2.new(0, 0, 0, 0)
GlowBg.BackgroundColor3 = GLOW_COLOR
GlowBg.BackgroundTransparency = 0.9
GlowBg.BorderSizePixel = 0
GlowBg.ZIndex = 1
GlowBg.Parent = MainFrame
corner(GlowBg, 16)

-- animated top accent bar
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.Position = UDim2.new(0, 0, 0, 0)
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 10
AccentBar.Parent = MainFrame
corner(AccentBar, 16)
local AccentGradient = Instance.new("UIGradient")
AccentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 60, 160)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(160, 60, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 170, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 255, 210)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 60, 160)),
})
AccentGradient.Parent = AccentBar

local fadeInMain = TweenService:Create(MainFrame,
    TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    { BackgroundTransparency = 0.08 })
fadeInMain:Play()

--================================================================
-- HEADER (draggable handle + pulse dot + title + buttons)
--================================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 24)
Header.Position = UDim2.new(0, 0, 0, 6)
Header.BackgroundTransparency = 1
Header.ZIndex = 12
Header.Parent = MainFrame

local PulseGlow = Instance.new("Frame")
PulseGlow.Size = UDim2.new(0, 14, 0, 14)
PulseGlow.Position = UDim2.new(0, 10, 0.5, -7)
PulseGlow.BackgroundColor3 = COL_GREEN
PulseGlow.BackgroundTransparency = 0.6
PulseGlow.BorderSizePixel = 0
PulseGlow.ZIndex = 12
PulseGlow.Parent = Header
corner(PulseGlow, 7)

local PulseDot = Instance.new("Frame")
PulseDot.Size = UDim2.new(0, 8, 0, 8)
PulseDot.Position = UDim2.new(0, 13, 0.5, -4)
PulseDot.BackgroundColor3 = COL_GREEN
PulseDot.BorderSizePixel = 0
PulseDot.ZIndex = 13
PulseDot.Parent = Header
corner(PulseDot, 4)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -90, 1, 0)
TitleLbl.Position = UDim2.new(0, 28, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = player.Name
TitleLbl.TextColor3 = COL_TEXT
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 13
TitleLbl.Parent = Header

-- Icon buttons (settings + clear), top-right, glassy circular
local function makeIconButton(xOffFromRight, icon, bg)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.Position = UDim2.new(1, xOffFromRight, 0.5, -11)
    btn.BackgroundColor3 = bg or Color3.fromRGB(30, 32, 46)
    btn.BackgroundTransparency = 0.15
    btn.Text = icon
    btn.TextColor3 = COL_TEXT
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.ZIndex = 13
    btn.Parent = Header
    corner(btn, 6)
    stroke(btn, 1, STROKE_COLOR, 0.55)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.15 }):Play()
    end)
    return btn
end

local ClearButton = makeIconButton(-54, "🗑")
local SettingsButton = makeIconButton(-26, "⚙")

--================================================================
-- DIVIDER
--================================================================

local function makeDivider(y)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -16, 0, 1)
    d.Position = UDim2.new(0, 8, 0, y)
    d.BackgroundColor3 = Color3.fromRGB(70, 75, 100)
    d.BackgroundTransparency = 0.5
    d.BorderSizePixel = 0
    d.ZIndex = 11
    d.Parent = MainFrame
end
makeDivider(34)

--================================================================
-- INFO ROWS
--================================================================

local ROW_PADDING_X   = 8
local ROW_CONTENT_W   = PANEL_WIDTH - ROW_PADDING_X * 2 -- bề rộng khả dụng cho text
local ORDER_ROW_Y     = 42
local BOTTOM_PADDING  = 12
local MIN_PANEL_HEIGHT = 70

-- Row kiểu mới (dùng cho Đơn hàng) — giá trị wrap nhiều dòng
local OrderRow = Instance.new("Frame")
OrderRow.Size = UDim2.new(1, -(ROW_PADDING_X * 2), 0, 20)
OrderRow.Position = UDim2.new(0, ROW_PADDING_X, 0, ORDER_ROW_Y)
OrderRow.BackgroundTransparency = 1
OrderRow.ZIndex = 11
OrderRow.Parent = MainFrame

local OrderValueLbl = Instance.new("TextLabel")
OrderValueLbl.Size = UDim2.new(1, 0, 0, 20)
OrderValueLbl.Position = UDim2.new(0, 0, 0, 0)
OrderValueLbl.BackgroundTransparency = 1
OrderValueLbl.Text = ""
OrderValueLbl.TextColor3 = COL_CYAN
OrderValueLbl.Font = Enum.Font.GothamBold
OrderValueLbl.TextSize = 16
OrderValueLbl.TextXAlignment = Enum.TextXAlignment.Left
OrderValueLbl.TextYAlignment = Enum.TextYAlignment.Top
OrderValueLbl.TextWrapped = true
OrderValueLbl.ZIndex = 12
OrderValueLbl.Parent = OrderRow

--================================================================
-- LAYOUT TỰ ĐỘNG: tính lại chiều cao dựa trên độ dài nội dung đơn hàng
--================================================================

local function updateLayout()
    local text = (OrderValueLbl.Text ~= "" and OrderValueLbl.Text) or " "
    local bounds = TextService:GetTextSize(
        text,
        OrderValueLbl.TextSize,
        OrderValueLbl.Font,
        Vector2.new(ROW_CONTENT_W, math.huge)
    )
    local valueHeight = math.max(20, bounds.Y + 4)
    OrderValueLbl.Size = UDim2.new(1, 0, 0, valueHeight)

    local orderRowHeight = valueHeight
    OrderRow.Size = UDim2.new(1, -(ROW_PADDING_X * 2), 0, orderRowHeight)

    local panelHeight = math.max(MIN_PANEL_HEIGHT, ORDER_ROW_Y + orderRowHeight + BOTTOM_PADDING)
    MainFrame.Size = UDim2.new(0, PANEL_WIDTH, 0, panelHeight)
end

--================================================================
-- STATE LOAD
--================================================================

local username = player.Name
local configData = loadConfigs(username)

OrderValueLbl.Text = configData.order

updateLayout()

--================================================================
-- SINGLE ANIMATION LOOP (rainbow bar scroll + pulse dot)
--================================================================

task.spawn(function()
    local off = 0
    while SG and SG.Parent do
        off = (off + 0.004) % 1
        pcall(function() AccentGradient.Offset = Vector2.new(off, 0) end)
        local s = (math.sin(tick() * 3) + 1) / 2
        pcall(function()
            PulseDot.BackgroundTransparency = s * 0.4
            PulseGlow.BackgroundTransparency = 0.5 + s * 0.3
        end)
        RunService.Heartbeat:Wait()
    end
end)

--================================================================
-- CONFIG (edit order) WINDOW — separate draggable glass panel
--================================================================

local ConfigWindow = Instance.new("Frame")
ConfigWindow.Size = UDim2.new(0, 260, 0, 132)
ConfigWindow.Position = UDim2.new(0.5, -130, 0.5, -66)
ConfigWindow.BackgroundColor3 = BG_COLOR
ConfigWindow.BackgroundTransparency = 1
ConfigWindow.BorderSizePixel = 0
ConfigWindow.Visible = false
ConfigWindow.ZIndex = 20
ConfigWindow.Parent = SG
corner(ConfigWindow, 14)
stroke(ConfigWindow, 1.4, STROKE_COLOR, 0.35)

local CfgGlow = Instance.new("Frame")
CfgGlow.Size = UDim2.new(1, 0, 0, 50)
CfgGlow.BackgroundColor3 = GLOW_COLOR
CfgGlow.BackgroundTransparency = 0.9
CfgGlow.BorderSizePixel = 0
CfgGlow.ZIndex = 20
CfgGlow.Parent = ConfigWindow
corner(CfgGlow, 14)

local CfgHeader = Instance.new("Frame")
CfgHeader.Size = UDim2.new(1, 0, 0, 30)
CfgHeader.BackgroundTransparency = 1
CfgHeader.ZIndex = 22
CfgHeader.Parent = ConfigWindow

local CfgTitle = Instance.new("TextLabel")
CfgTitle.Size = UDim2.new(1, -40, 1, 0)
CfgTitle.Position = UDim2.new(0, 14, 0, 0)
CfgTitle.BackgroundTransparency = 1
CfgTitle.Text = "CHỈNH SỬA ĐƠN HÀNG"
CfgTitle.TextColor3 = COL_TEXT
CfgTitle.Font = Enum.Font.GothamBold
CfgTitle.TextSize = 12
CfgTitle.TextXAlignment = Enum.TextXAlignment.Left
CfgTitle.ZIndex = 22
CfgTitle.Parent = CfgHeader

local CfgCloseBtn = Instance.new("TextButton")
CfgCloseBtn.Size = UDim2.new(0, 22, 0, 22)
CfgCloseBtn.Position = UDim2.new(1, -30, 0.5, -11)
CfgCloseBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 46)
CfgCloseBtn.BackgroundTransparency = 0.15
CfgCloseBtn.Text = "✕"
CfgCloseBtn.TextColor3 = COL_MUTED
CfgCloseBtn.Font = Enum.Font.GothamBold
CfgCloseBtn.TextSize = 11
CfgCloseBtn.AutoButtonColor = false
CfgCloseBtn.ZIndex = 22
CfgCloseBtn.Parent = CfgHeader
corner(CfgCloseBtn, 6)

local OrderInputBox = Instance.new("TextBox")
OrderInputBox.Size = UDim2.new(1, -28, 0, 38)
OrderInputBox.Position = UDim2.new(0, 14, 0, 40)
OrderInputBox.PlaceholderText = "Nhập đơn hàng..."
OrderInputBox.PlaceholderColor3 = COL_MUTED
OrderInputBox.Text = ""
OrderInputBox.TextColor3 = COL_TEXT
OrderInputBox.Font = Enum.Font.Gotham
OrderInputBox.TextSize = 13
OrderInputBox.TextXAlignment = Enum.TextXAlignment.Left
OrderInputBox.ClearTextOnFocus = false
OrderInputBox.BackgroundColor3 = Color3.fromRGB(16, 17, 28)
OrderInputBox.BackgroundTransparency = 0.1
OrderInputBox.ZIndex = 22
OrderInputBox.Parent = ConfigWindow
corner(OrderInputBox, 8)
stroke(OrderInputBox, 1, STROKE_COLOR, 0.5)

-- inner left padding for the textbox text
local inputPad = Instance.new("UIPadding")
inputPad.PaddingLeft = UDim.new(0, 10)
inputPad.PaddingRight = UDim.new(0, 10)
inputPad.Parent = OrderInputBox

local DoneButton = Instance.new("TextButton")
DoneButton.Size = UDim2.new(1, -28, 0, 32)
DoneButton.Position = UDim2.new(0, 14, 0, 88)
DoneButton.Text = "LƯU THAY ĐỔI"
DoneButton.TextColor3 = Color3.fromRGB(6, 10, 10)
DoneButton.Font = Enum.Font.GothamBold
DoneButton.TextSize = 12
DoneButton.AutoButtonColor = false
DoneButton.BackgroundColor3 = COL_CYAN
DoneButton.ZIndex = 22
DoneButton.Parent = ConfigWindow
corner(DoneButton, 8)

local DoneGradient = Instance.new("UIGradient")
DoneGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 255, 210)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 170, 255)),
})
DoneGradient.Parent = DoneButton

DoneButton.MouseEnter:Connect(function()
    TweenService:Create(DoneButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)
DoneButton.MouseLeave:Connect(function()
    TweenService:Create(DoneButton, TweenInfo.new(0.15), { BackgroundColor3 = COL_CYAN }):Play()
end)

--================================================================
-- SHOW / HIDE CONFIG WINDOW
--================================================================

local function showConfigWindow()
    OrderInputBox.Text = ""
    ConfigWindow.Visible = true
    TweenService:Create(ConfigWindow,
        TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.08 }):Play()
end

local function hideConfigWindow()
    local t = TweenService:Create(ConfigWindow,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 })
    t:Play()
    t.Completed:Connect(function()
        ConfigWindow.Visible = false
    end)
end

SettingsButton.MouseButton1Click:Connect(showConfigWindow)
CfgCloseBtn.MouseButton1Click:Connect(hideConfigWindow)

ClearButton.MouseButton1Click:Connect(function()
    saveConfigs(username, { order = "[Trống]" })
    OrderValueLbl.Text = "[Trống]"
    updateLayout()
    print("Đã xóa thông tin đơn hàng của tài khoản: " .. username)
end)

local function commitOrder()
    local newOrder = OrderInputBox.Text
    if newOrder ~= "" then
        OrderValueLbl.Text = newOrder
        updateLayout()
        saveConfigs(username, { order = newOrder })
        print("Đã lưu chỉnh sửa đơn hàng cho tài khoản: " .. username)
        hideConfigWindow()
    else
        warn("Không thể lưu đơn hàng vì giá trị trống!")
        stroke(OrderInputBox, 1.4, COL_RED, 0.2)
    end
end

DoneButton.MouseButton1Click:Connect(commitOrder)

OrderInputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        commitOrder()
    end
end)

--================================================================
-- DRAG SUPPORT (both panels move independently to avoid overlap)
--================================================================

makeDraggable(Header, MainFrame)
makeDraggable(CfgHeader, ConfigWindow)
