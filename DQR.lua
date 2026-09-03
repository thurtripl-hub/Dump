--[[
    DQ Reborn - Auto Upgrader v3 FIXED
    ใช้ ReplicatedStorage.SSSDSD231/Assets โดยตรง
    Delta compatible
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("remotes")
local upgradeRemote = remotes:WaitForChild("upgradeItem")

local Config = {
    AutoUpgrade = false,
    Delay = 0.05,
    UpgradeHealth = true,
    UpgradeSpell = true,
    UpgradePhysical = true,
}

-- // หา Assets folder ของ player
local function GetAssets()
    return ReplicatedStorage:FindFirstChild(LocalPlayer.Name .. "/Assets")
end

-- // หา items ทั้งหมดที่ยัง upgrade ได้
local function GetUpgradeableItems()
    local assets = GetAssets()
    local items = {}
    if not assets then return items end

    for _, item in pairs(assets:GetChildren()) do
        local currentUpgrade = item:FindFirstChild("currentUpgrade")
        local maxUpgrades = item:FindFirstChild("maxUpgrades")
        local isWeapon = item:FindFirstChild("Weapon")
        local itemType = item:FindFirstChild("type")

        -- weapon หรือ armor
        local valid = isWeapon 
            or (itemType and (itemType.Value == "weapon" or itemType.Value == "armor"))

        if valid and currentUpgrade and maxUpgrades then
            if currentUpgrade.Value < maxUpgrades.Value then
                table.insert(items, item)
            end
        end

        -- dual weapon (dualRight folder)
        for _, child in pairs(item:GetChildren()) do
            local cUpgrade = child:FindFirstChild("currentUpgrade")
            local mUpgrade = child:FindFirstChild("maxUpgrades")
            local cWeapon = child:FindFirstChild("Weapon")
            if cWeapon and cUpgrade and mUpgrade then
                if cUpgrade.Value < mUpgrade.Value then
                    table.insert(items, child)
                end
            end
        end
    end
    return items
end

-- // หา gold
local function GetGold()
    for _, v in pairs(LocalPlayer:GetDescendants()) do
        if (v.Name:lower():find("gold") or v.Name:lower():find("coin"))
        and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
        end
    end
    return nil
end

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoUpgraderV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 270, 0, 420)
Frame.Position = UDim2.new(0, 10, 0.5, -210)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

-- Title + Minimize
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Text = "Auto Upgrader v3"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 26)
MinBtn.Position = UDim2.new(1, -34, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 100)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Text = "—"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Content frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Parent = Frame

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Content.Visible = not isMinimized
    Frame.Size = isMinimized 
        and UDim2.new(0, 270, 0, 36) 
        or UDim2.new(0, 270, 0, 420)
    MinBtn.Text = isMinimized and "+" or "—"
end)

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0, 4)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
StatusLabel.Text = "Ready!"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Content

-- Gold
local GoldLabel = Instance.new("TextLabel")
GoldLabel.Size = UDim2.new(1, -10, 0, 20)
GoldLabel.Position = UDim2.new(0, 5, 0, 22)
GoldLabel.BackgroundTransparency = 1
GoldLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
GoldLabel.Text = "Gold: ?"
GoldLabel.Font = Enum.Font.GothamBold
GoldLabel.TextSize = 11
GoldLabel.TextXAlignment = Enum.TextXAlignment.Left
GoldLabel.Parent = Content

-- Count
local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.new(1, -10, 0, 20)
CountLabel.Position = UDim2.new(0, 5, 0, 40)
CountLabel.BackgroundTransparency = 1
CountLabel.TextColor3 = Color3.fromRGB(200, 80, 140)
CountLabel.Text = "Upgrades: 0"
CountLabel.Font = Enum.Font.GothamBold
CountLabel.TextSize = 11
CountLabel.TextXAlignment = Enum.TextXAlignment.Left
CountLabel.Parent = Content

-- Items found
local ItemsLabel = Instance.new("TextLabel")
ItemsLabel.Size = UDim2.new(1, -10, 0, 20)
ItemsLabel.Position = UDim2.new(0, 5, 0, 58)
ItemsLabel.BackgroundTransparency = 1
ItemsLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
ItemsLabel.Text = "Items: scanning..."
ItemsLabel.Font = Enum.Font.Gotham
ItemsLabel.TextSize = 11
ItemsLabel.TextXAlignment = Enum.TextXAlignment.Left
ItemsLabel.Parent = Content

-- Section
local sectionLabel = Instance.new("TextLabel")
sectionLabel.Size = UDim2.new(1, -10, 0, 20)
sectionLabel.Position = UDim2.new(0, 5, 0, 82)
sectionLabel.BackgroundTransparency = 1
sectionLabel.TextColor3 = Color3.fromRGB(200, 80, 140)
sectionLabel.Text = "เลือกสายที่อัพ:"
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.TextSize = 12
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = Content

local function CreateToggle(name, configKey, color, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 36)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = Config[configKey] and color or Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = (Config[configKey] and "✅ " or "❌ ") .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = Content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        btn.Text = (Config[configKey] and "✅ " or "❌ ") .. name
        btn.BackgroundColor3 = Config[configKey] and color or Color3.fromRGB(35, 35, 35)
    end)
end

CreateToggle("🟢 Health", "UpgradeHealth", Color3.fromRGB(60, 180, 60), 106)
CreateToggle("🟣 Spell", "UpgradeSpell", Color3.fromRGB(120, 60, 200), 148)
CreateToggle("🔴 Physical", "UpgradePhysical", Color3.fromRGB(200, 60, 60), 190)

-- Delay
local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(1, -10, 0, 20)
delayLabel.Position = UDim2.new(0, 5, 0, 234)
delayLabel.BackgroundTransparency = 1
delayLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
delayLabel.Text = "Delay (s): 0.05"
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextSize = 11
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = Content

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(1, -10, 0, 26)
delayBox.Position = UDim2.new(0, 5, 0, 256)
delayBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.Text = "0.05"
delayBox.Font = Enum.Font.Gotham
delayBox.TextSize = 12
delayBox.Parent = Content
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
mainToggle.Position = UDim2.new(0, 5, 0, 296)
mainToggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainToggle.Text = "[ OFF ]  Auto Upgrade"
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 14
mainToggle.Parent = Content
Instance.new("UICorner", mainToggle).CornerRadius = UDim.new(0, 6)

-- // Auto Upgrade Loop
local upgradeCount = 0
local function AutoUpgradeLoop()
    while Config.AutoUpgrade do
        local gold = GetGold()
        if gold ~= nil and gold <= 0 then
            Config.AutoUpgrade = false
            StatusLabel.Text = "⛔ Gold หมด!"
            mainToggle.Text = "[ OFF ]  Auto Upgrade"
            mainToggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            break
        end

        local items = GetUpgradeableItems()
        ItemsLabel.Text = "Items: " .. #items .. " upgradeable"

        if #items == 0 then
            StatusLabel.Text = "✅ ทุก item อัพ max แล้ว!"
            Config.AutoUpgrade = false
            mainToggle.Text = "[ OFF ]  Auto Upgrade"
            mainToggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            break
        end

        for _, item in pairs(items) do
            if not Config.AutoUpgrade then break end

            -- ลอง args แบบต่างๆ
            if Config.UpgradeHealth then
                pcall(function()
                    upgradeRemote:FireServer(item, "Health")
                    upgradeCount = upgradeCount + 1
                end)
                task.wait(Config.Delay)
            end
            if Config.UpgradeSpell then
                pcall(function()
                    upgradeRemote:FireServer(item, "Spell")
                    upgradeCount = upgradeCount + 1
                end)
                task.wait(Config.Delay)
            end
            if Config.UpgradePhysical then
                pcall(function()
                    upgradeRemote:FireServer(item, "Physical")
                    upgradeCount = upgradeCount + 1
                end)
                task.wait(Config.Delay)
            end
        end

        CountLabel.Text = "Upgrades: " .. upgradeCount
        if gold then
            GoldLabel.Text = "Gold: " .. tostring(math.floor(gold)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        end
        task.wait(0.1)
    end
end

-- Gold updater
task.spawn(function()
    while true do
        local gold = GetGold()
        if gold then
            GoldLabel.Text = "Gold: " .. tostring(math.floor(gold)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        end
        local items = GetUpgradeableItems()
        ItemsLabel.Text = "Items: " .. #items .. " upgradeable"
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
        task.spawn(AutoUpgradeLoop)
    end
end)

-- Draggable
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
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
TitleBar.InputChanged:Connect(function(input)
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

print("[DQ Reborn] Auto Upgrader v3 loaded ✓")
