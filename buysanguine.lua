local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SanguineArtUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 60)
MainFrame.Position = UDim2.new(1, -220, 0, 20) 
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

local BuyButton = Instance.new("TextButton")
BuyButton.Name = "BuyButton"
BuyButton.Size = UDim2.new(1, -20, 1, -20)
BuyButton.Position = UDim2.new(0, 10, 0, 10)
BuyButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
BuyButton.Text = "Buy Sanguine Art"
BuyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyButton.TextSize = 16
BuyButton.Font = Enum.Font.GothamBold
BuyButton.BorderSizePixel = 0
BuyButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = BuyButton

function buySanguineArt()
    local args = {
        "BuySanguineArt"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
end

BuyButton.MouseButton1Click:Connect(function()
    BuyButton.BackgroundColor3 = Color3.fromRGB(180, 40, 55)
    wait(0.1)
    BuyButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    buySanguineArt()
    BuyButton.Text = "✓ Mua r"
    wait(1)
    BuyButton.Text = "Buy Sanguine Art"
end)

BuyButton.MouseEnter:Connect(function()
    BuyButton.BackgroundColor3 = Color3.fromRGB(200, 45, 60)
end)

BuyButton.MouseLeave:Connect(function()
    BuyButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
end)

print("Sanguine Art UI loaded!")
