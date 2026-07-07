if not game:IsLoaded() then
    game.Loaded:Wait()
end

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
Header.Size = UDim2.new(1, 0, 0, 34)
Header.Position = UDim2.new(0, 0, 0, 8)
Header.BackgroundTransparency = 1
Header.ZIndex = 12
Header.Parent = MainFrame

local PulseGlow = Instance.new("Frame")
PulseGlow.Size = UDim2.new(0, 20, 0, 20)
PulseGlow.Position = UDim2.new(0, 12, 0.5, -10)
PulseGlow.BackgroundColor3 = COL_GREEN
PulseGlow.BackgroundTransparency = 0.6
PulseGlow.BorderSizePixel = 0
PulseGlow.ZIndex = 12
PulseGlow.Parent = Header
corner(PulseGlow, 10)

local PulseDot = Instance.new("Frame")
PulseDot.Size = UDim2.new(0, 10, 0, 10)
PulseDot.Position = UDim2.new(0, 17, 0.5, -5)
PulseDot.BackgroundColor3 = COL_GREEN
PulseDot.BorderSizePixel = 0
PulseDot.ZIndex = 13
PulseDot.Parent = Header
corner(PulseDot, 5)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -110, 1, 0)
TitleLbl.Position = UDim2.new(0, 38, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "ORDER TRACKER"
TitleLbl.TextColor3 = COL_TEXT
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 15
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 13
TitleLbl.Parent = Header

-- Icon buttons (settings + clear), top-right, glassy circular
local function makeIconButton(xOffFromRight, icon, bg)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.Position = UDim2.new(1, xOffFromRight, 0.5, -13)
    btn.BackgroundColor3 = bg or Color3.fromRGB(30, 32, 46)
    btn.BackgroundTransparency = 0.15
    btn.Text = icon
    btn.TextColor3 = COL_TEXT
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.ZIndex = 13
    btn.Parent = Header
    corner(btn, 8)
    stroke(btn, 1, STROKE_COLOR, 0.55)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.15 }):Play()
    end)
    return btn
end

local ClearButton = makeIconButton(-64, "🗑")
local SettingsButton = makeIconButton(-32, "⚙")

--================================================================
-- DIVIDER
--================================================================

local function makeDivider(y)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -28, 0, 1)
    d.Position = UDim2.new(0, 14, 0, y)
    d.BackgroundColor3 = Color3.fromRGB(70, 75, 100)
    d.BackgroundTransparency = 0.5
    d.BorderSizePixel = 0
    d.ZIndex = 11
    d.Parent = MainFrame
end
makeDivider(48)

--================================================================
-- INFO ROWS
-- Player row: giữ nguyên kiểu 1 dòng (username luôn ngắn, đã bị che bớt).
-- Order row: đổi sang bố cục 2 tầng (nhãn ở trên, giá trị wrap xuống dưới)
-- để không bao giờ bị cắt bớt (...) nữa, và panel sẽ tự giãn chiều cao.
--================================================================

local ROW_PADDING_X   = 14
local ROW_CONTENT_W   = PANEL_WIDTH - ROW_PADDING_X * 2 -- bề rộng khả dụng cho text
local ORDER_ROW_Y     = 60
local ROW_SPACING     = 10
local BOTTOM_PADDING  = 16
local MIN_PANEL_HEIGHT = 138

-- Row kiểu cũ (dùng cho Người chơi) — 1 dòng, có icon + nhãn + giá trị cùng hàng
local function makeInfoRow(y, icon, labelText, valueColor)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -28, 0, 30)
    row.Position = UDim2.new(0, 14, 0, y)
    row.BackgroundTransparency = 1
    row.ZIndex = 11
    row.Parent = MainFrame

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 24, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = icon
    iconLbl.TextSize = 17
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextXAlignment = Enum.TextXAlignment.Left
    iconLbl.ZIndex = 12
    iconLbl.Parent = row

    local tagLbl = Instance.new("TextLabel")
    tagLbl.Size = UDim2.new(0, 88, 1, 0)
    tagLbl.Position = UDim2.new(0, 26, 0, 0)
    tagLbl.BackgroundTransparency = 1
    tagLbl.Text = labelText
    tagLbl.TextColor3 = COL_MUTED
    tagLbl.Font = Enum.Font.GothamSemibold
    tagLbl.TextSize = 13
    tagLbl.TextXAlignment = Enum.TextXAlignment.Left
    tagLbl.ZIndex = 12
    tagLbl.Parent = row

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(1, -116, 1, 0)
    valueLbl.Position = UDim2.new(0, 116, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = ""
    valueLbl.TextColor3 = valueColor or COL_TEXT
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 17
    valueLbl.TextXAlignment = Enum.TextXAlignment.Left
    valueLbl.TextTruncate = Enum.TextTruncate.AtEnd
    valueLbl.ZIndex = 12
    valueLbl.Parent = row

    return row, valueLbl
end

-- Row kiểu mới (dùng cho Đơn hàng) — nhãn ở tầng trên, giá trị wrap nhiều dòng ở dưới
local OrderRow = Instance.new("Frame")
OrderRow.Size = UDim2.new(1, -28, 0, 20) -- chiều cao sẽ được tính lại trong updateLayout()
OrderRow.Position = UDim2.new(0, ROW_PADDING_X, 0, ORDER_ROW_Y)
OrderRow.BackgroundTransparency = 1
OrderRow.ZIndex = 11
OrderRow.Parent = MainFrame

local OrderHeaderRow = Instance.new("Frame")
OrderHeaderRow.Size = UDim2.new(1, 0, 0, 20)
OrderHeaderRow.Position = UDim2.new(0, 0, 0, 0)
OrderHeaderRow.BackgroundTransparency = 1
OrderHeaderRow.ZIndex = 11
OrderHeaderRow.Parent = OrderRow

local OrderIconLbl = Instance.new("TextLabel")
OrderIconLbl.Size = UDim2.new(0, 24, 1, 0)
OrderIconLbl.BackgroundTransparency = 1
OrderIconLbl.Text = "📦"
OrderIconLbl.TextSize = 17
OrderIconLbl.Font = Enum.Font.GothamBold
OrderIconLbl.TextXAlignment = Enum.TextXAlignment.Left
OrderIconLbl.ZIndex = 12
OrderIconLbl.Parent = OrderHeaderRow

local OrderTagLbl = Instance.new("TextLabel")
OrderTagLbl.Size = UDim2.new(1, -26, 1, 0)
OrderTagLbl.Position = UDim2.new(0, 26, 0, 0)
OrderTagLbl.BackgroundTransparency = 1
OrderTagLbl.Text = "Đơn hàng"
OrderTagLbl.TextColor3 = COL_MUTED
OrderTagLbl.Font = Enum.Font.GothamSemibold
OrderTagLbl.TextSize = 13
OrderTagLbl.TextXAlignment = Enum.TextXAlignment.Left
OrderTagLbl.ZIndex = 12
OrderTagLbl.Parent = OrderHeaderRow

local OrderValueLbl = Instance.new("TextLabel")
OrderValueLbl.Size = UDim2.new(1, 0, 0, 20) -- chiều cao sẽ được tính lại trong updateLayout()
OrderValueLbl.Position = UDim2.new(0, 0, 0, 22)
OrderValueLbl.BackgroundTransparency = 1
OrderValueLbl.Text = ""
OrderValueLbl.TextColor3 = COL_CYAN
OrderValueLbl.Font = Enum.Font.GothamBold
OrderValueLbl.TextSize = 17
OrderValueLbl.TextXAlignment = Enum.TextXAlignment.Left
OrderValueLbl.TextYAlignment = Enum.TextYAlignment.Top
OrderValueLbl.TextWrapped = true -- << cho phép xuống dòng thay vì bị cắt "..."
OrderValueLbl.ZIndex = 12
OrderValueLbl.Parent = OrderRow

local PlayerRow, PlayerValueLbl = makeInfoRow(94, "👤", "Người chơi", COL_TEXT)

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

    local orderRowHeight = 22 + valueHeight
    OrderRow.Size = UDim2.new(1, -28, 0, orderRowHeight)

    local playerY = ORDER_ROW_Y + orderRowHeight + ROW_SPACING
    PlayerRow.Position = UDim2.new(0, 14, 0, playerY)

    local panelHeight = math.max(MIN_PANEL_HEIGHT, playerY + 30 + BOTTOM_PADDING)
    MainFrame.Size = UDim2.new(0, PANEL_WIDTH, 0, panelHeight)
end

--================================================================
-- STATE LOAD
--================================================================

local username = player.Name
local configData = loadConfigs(username)

OrderValueLbl.Text = configData.order
local visibleUsername = string.sub(username, 1, math.max(1, #username - 4)) .. "****"
PlayerValueLbl.Text = visibleUsername

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
