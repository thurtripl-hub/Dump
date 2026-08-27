--[[
    DQ Reborn - Auto Upgrader v2
    - ไม่ต้องเปิด Blacksmith
    - หยุดอัตโนมัติเมื่อ gold หมด
    - อัพเร็วสุด
    Delta compatible
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("remotes")
local upgradeRemote = remotes:WaitForChild("upgradeItem")

-- // Config
local Config = {
    AutoUpgrade = false,
    Delay = 0.05,
    UpgradeHealth = true,
    UpgradeSpell = true,
    UpgradePhysical = true,
}

-- // หา gold
local function GetGold()
    -- ลองหาใน leaderstats
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local gold = leaderstats:FindFirstChild("Gold")
            or leaderstats:FindFirstChild("Coins")
            or leaderstats:FindFirstChild("Money")
        if gold then return gold.Value end
    end
    -- ลองหาใน PlayerValues
    for _, v in pairs(LocalPlayer:GetDescendants()) do
        if (v.Name:lower():find("gold") or v.Name:lower():find("coin")) 
        and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
        end
    end
    return nil
end

-- // Auto Upgrade Loop
local upgradeCount = 0
local function AutoUpgradeLoop(statusLabel, countLabel, goldLabel)
    while Config.AutoUpgrade do
        local gold = GetGold()

        -- เช็ค gold
        if gold ~= nil and gold <= 0 then
            Config.AutoUpgrade = false
            statusLabel.Text = "⛔ Gold หมด! หยุดอัพแล้ว"
            break
        end

        -- อัพตามสายที่เลือก
        if Config.UpgradeHealth then
            pcall(function()
                upgradeRemote:FireServer("Health")
                upgradeCount = upgradeCount + 1
            end)
            task.wait(Config.Delay)
        end

        if Config.UpgradeSpell then
            pcall(function()
                upgradeRemote:FireServer("Spell")
                upgradeCount = upgradeCount + 1
            end)
            task.wait(Config.Delay)
        end

        if Config.UpgradePhysical then
            pcall(function()
                upgradeRemote:FireServer("Physical")
                upgradeCount = upgradeCount + 1
            end)
            task.wait(Config.Delay)
        end

        -- update labels
        countLabel.Text = "Upgrades: " .. upgradeCount
        if gold then
            goldLabel.Text = "Gold: " .. tostring(gold):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        else
            goldLabel.Text = "Gold: ?"
        end
    end
end

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoUpgraderV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 400)
Frame.Position = UDim2.new(0, 10, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Auto Upgrader v2"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
StatusLabel.Text = "Ready!"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

-- Gold label
local GoldLabel = Instance.new("TextLabel")
GoldLabel.Size = UDim2.new(1, -10, 0, 20)
GoldLabel.Position = UDim2.new(0, 5, 0, 58)
GoldLabel.BackgroundTransparency = 1
GoldLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
GoldLabel.Text = "Gold: ?"
GoldLabel.Font = Enum.Font.GothamBold
GoldLabel.TextSize = 11
GoldLabel.TextXAlignment = Enum.TextXAlignment.Left
GoldLabel.Parent = Frame

-- Count label
local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.new(1, -10, 0, 20)
CountLabel.Position = UDim2.new(0, 5, 0, 76)
CountLabel.BackgroundTransparency = 1
CountLabel.TextColor3 = Color3.fromRGB(200, 80, 140)
CountLabel.Text = "Upgrades: 0"
CountLabel.Font = Enum.Font.GothamBold
CountLabel.TextSize = 11
CountLabel.TextXAlignment = Enum.TextXAlignment.Left
CountLabel.Parent = Frame

-- Section
local sectionLabel = Instance.new("TextLabel")
sectionLabel.Size = UDim2.new(1, -10, 0, 20)
sectionLabel.Position = UDim2.new(0, 5, 0, 100)
sectionLabel.BackgroundTransparency = 1
sectionLabel.TextColor3 = Color3.fromRGB(200, 80, 140)
sectionLabel.Text = "เลือกสายที่อัพ:"
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.TextSize = 12
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = Frame

-- Toggle factory
local function CreateToggle(name, configKey, color, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 36)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = Config[configKey] and color or Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = (Config[configKey] and "✅ " or "❌ ") .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        btn.Text = (Config[configKey] and "✅ " or "❌ ") .. name
        btn.BackgroundColor3 = Config[configKey] and color or Color3.fromRGB(35, 35, 35)
    end)
    return btn
end

CreateToggle("🟢 Health", "UpgradeHealth", Color3.fromRGB(60, 180, 60), 124)
CreateToggle("🟣 Spell", "UpgradeSpell", Color3.fromRGB(120, 60, 200), 166)
CreateToggle("🔴 Physical", "UpgradePhysical", Color3.fromRGB(200, 60, 60), 208)

-- Delay
local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(1, -10, 0, 20)
delayLabel.Position = UDim2.new(0, 5, 0, 252)
delayLabel.BackgroundTransparency = 1
delayLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
delayLabel.Text = "Delay (s): 0.05"
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextSize = 11
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = Frame

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(1, -10, 0, 26)
delayBox.Position = UDim2.new(0, 5, 0, 274)
delayBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.Text = "0.05"
delayBox.Font = Enum.Font.Gotham
delayBox.TextSize = 12
delayBox.Parent = Frame
Instance.new("UICorner", delayBox).CornerRadius = UDim.new(0, 6)

delayBox.FocusLost:Connect(function()
    local val = tonumber(delayBox.Text)
    if val then
        Config.Delay = math.clamp(val, 0.05, 5)
        delayLabel.Text = "Delay (s): " .. Config.Delay
    end
end)

-- Main Toggle
local mainToggle = Instance.new("TextButton")
mainToggle.Size = UDim2.new(1, -10, 0, 44)
mainToggle.Position = UDim2.new(0, 5, 0, 314)
mainToggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainToggle.Text = "[ OFF ]  Auto Upgrade"
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 14
mainToggle.Parent = Frame
Instance.new("UICorner", mainToggle).CornerRadius = UDim.new(0, 6)

-- Gold check on start
task.spawn(function()
    while true do
        local gold = GetGold()
        if gold then
            GoldLabel.Text = "Gold: " .. tostring(gold):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,","")
        end
        task.wait(1)
    end
end)

mainToggle.MouseButton1Click:Connect(function()
    Config.AutoUpgrade = not Config.AutoUpgrade
    mainToggle.Text = (Config.AutoUpgrade and "[ ON ]   " or "[ OFF ]  ") .. "Auto Upgrade"
    mainToggle.BackgroundColor3 = Config.AutoUpgrade
        and Color3.fromRGB(200, 80, 140)
        or Color3.fromRGB(35, 35, 35)
    StatusLabel.Text = Config.AutoUpgrade and "⚡ Upgrading..." or "Stopped"
    if Config.AutoUpgrade then
        task.spawn(function()
            AutoUpgradeLoop(StatusLabel, CountLabel, GoldLabel)
        end)
    end
end)

-- Draggable
local dragging, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("[DQ Reborn] Auto Upgrader v2 loaded ✓")
