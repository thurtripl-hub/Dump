--[[
    DQ Reborn - Smart Full Dumper
    Dumps: Remotes, Scripts, Models, Values, NPCs
    Delta + MuMu compatible
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FullDumper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 280)
Frame.Position = UDim2.new(0, 10, 0.5, -140)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Smart Full Dumper"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 24)
StatusLabel.Position = UDim2.new(0, 5, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
StatusLabel.Text = "Ready!"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

-- Buttons
local buttons = {
    {text = "📡 Dump Remotes Only", file = "remotes"},
    {text = "👾 Dump NPCs/Mobs Only", file = "npcs"},
    {text = "📜 Dump Scripts Only", file = "scripts"},
    {text = "💎 Dump Values Only", file = "values"},
    {text = "🌍 Dump EVERYTHING", file = "full"},
}

local yOff = 68
local createdBtns = {}

for _, info in pairs(buttons) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, yOff)
    btn.BackgroundColor3 = info.file == "full" 
        and Color3.fromRGB(200, 80, 140) 
        or Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = info.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        btn.Text = "⏳ Dumping..."
        StatusLabel.Text = "Working..."
        task.wait(0.1)

        local lines = {}
        local counts = {}

        table.insert(lines, "=== DQ Reborn Smart Dump ===")
        table.insert(lines, "Type: " .. info.file)
        table.insert(lines, "Game: " .. game.Name)
        table.insert(lines, "PlaceId: " .. tostring(game.PlaceId))
        table.insert(lines, "Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
        table.insert(lines, "")

        -- Sections
        if info.file == "remotes" or info.file == "full" then
            table.insert(lines, "===== REMOTES =====")
            counts.remotes = 0
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName())
                    counts.remotes = counts.remotes + 1
                end
            end
            table.insert(lines, "Total remotes: " .. counts.remotes)
            table.insert(lines, "")
        end

        if info.file == "npcs" or info.file == "full" then
            table.insert(lines, "===== NPCS / MOBS =====")
            counts.npcs = 0
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    local h = v:FindFirstChildOfClass("Humanoid")
                    local pos = hrp and tostring(hrp.Position) or "unknown"
                    local hp = h and (h.Health .. "/" .. h.MaxHealth) or "?"
                    table.insert(lines, "[MOB] " .. v.Name .. " | HP: " .. hp .. " | Pos: " .. pos)
                    counts.npcs = counts.npcs + 1
                end
            end
            table.insert(lines, "Total NPCs: " .. counts.npcs)
            table.insert(lines, "")
        end

        if info.file == "scripts" or info.file == "full" then
            table.insert(lines, "===== SCRIPTS =====")
            counts.scripts = 0
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                    table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName())
                    counts.scripts = counts.scripts + 1
                end
            end
            table.insert(lines, "Total scripts: " .. counts.scripts)
            table.insert(lines, "")
        end

        if info.file == "values" or info.file == "full" then
            table.insert(lines, "===== VALUES =====")
            counts.values = 0
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") 
                or v:IsA("StringValue") or v:IsA("BoolValue") then
                    local val = tostring(v.Value)
                    table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName() .. " = " .. val)
                    counts.values = counts.values + 1
                end
            end
            table.insert(lines, "Total values: " .. counts.values)
            table.insert(lines, "")
        end

        -- Write file
        local filename = "DQReborn_" .. info.file .. ".txt"
        local content = table.concat(lines, "\n")

        local ok, err = pcall(function()
            writefile(filename, content)
        end)

        if ok then
            local total = 0
            for _, v in pairs(counts) do total = total + v end
            StatusLabel.Text = "✅ Saved: " .. filename .. " (" .. total .. " items)"
        else
            StatusLabel.Text = "❌ Error: " .. tostring(err)
        end

        btn.Text = info.text
    end)

    yOff = yOff + 34
    table.insert(createdBtns, btn)
end

-- Draggable
local UserInputService = game:GetService("UserInputService")
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

print("[DQ Reborn] Smart Full Dumper loaded ✓")
