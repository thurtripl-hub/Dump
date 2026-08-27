--[[
    DQ Reborn - MEGA Full Dumper v2
    Sections: Remotes, NPCs, Scripts, Values,
              Models/Parts Tree, Player Inventory/Tools,
              Instance Attributes, GUIs, BaseParts Positions
    Compatible: Delta + MuMu
--]]

local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ─────────────────────────────────────────
--  GUI
-- ─────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "MegaDumper"
ScreenGui.ResetOnSpawn  = false
ScreenGui.Parent        = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size              = UDim2.new(0, 290, 0, 360)
Frame.Position          = UDim2.new(0, 10, 0.5, -180)
Frame.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel   = 0
Frame.Parent            = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size             = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3       = Color3.fromRGB(255, 255, 255)
Title.Text             = "🔥 MEGA Full Dumper v2"
Title.Font             = Enum.Font.GothamBold
Title.TextSize         = 13
Title.Parent           = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size               = UDim2.new(1, -10, 0, 24)
StatusLabel.Position           = UDim2.new(0, 5, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
StatusLabel.Text               = "Ready!"
StatusLabel.Font               = Enum.Font.Gotham
StatusLabel.TextSize           = 11
StatusLabel.TextXAlignment     = Enum.TextXAlignment.Left
StatusLabel.Parent             = Frame

-- ─────────────────────────────────────────
--  Buttons config
-- ─────────────────────────────────────────
local buttons = {
    { text = "📡 Remotes Only",           file = "remotes"    },
    { text = "👾 NPCs / Mobs Only",        file = "npcs"       },
    { text = "📜 Scripts Only",            file = "scripts"    },
    { text = "💎 Values Only",             file = "values"     },
    { text = "🗺️  Models / Parts Tree",    file = "models"     },
    { text = "🎒 Inventory / Tools",       file = "inventory"  },
    { text = "🧩 Attributes",              file = "attributes" },
    { text = "🖼️  GUIs",                   file = "guis"       },
    { text = "📐 BaseParts Positions",     file = "baseparts"  },
    { text = "🌍 DUMP EVERYTHING",         file = "full"       },
}

-- ─────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────

-- indent string for tree display
local function indent(depth)
    return string.rep("  ", depth)
end

-- recursively walk instance tree, respect depth limit
local function walkTree(root, lines, depth, maxDepth)
    if depth > maxDepth then return end
    for _, child in ipairs(root:GetChildren()) do
        local className = child.ClassName
        local extra = ""
        -- attach position/size info for BaseParts inline
        if child:IsA("BasePart") then
            local p = child.Position
            local s = child.Size
            extra = string.format(
                " | Pos(%.1f,%.1f,%.1f) Size(%.1f,%.1f,%.1f)",
                p.X, p.Y, p.Z, s.X, s.Y, s.Z
            )
        end
        table.insert(lines, indent(depth) .. "[" .. className .. "] " .. child.Name .. extra)
        walkTree(child, lines, depth + 1, maxDepth)
    end
end

-- dump all Attributes of a single instance
local function dumpAttributes(inst, lines)
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if not ok then return end
    for k, v in pairs(attrs) do
        table.insert(lines, "    [ATTR] " .. inst:GetFullName() .. " → " .. tostring(k) .. " = " .. tostring(v))
    end
end

-- ─────────────────────────────────────────
--  Section builders
-- ─────────────────────────────────────────

local function sectionRemotes(lines, counts)
    table.insert(lines, "===== REMOTES =====")
    counts.remotes = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName())
            counts.remotes += 1
        end
    end
    table.insert(lines, "Total remotes: " .. counts.remotes)
    table.insert(lines, "")
end

local function sectionNPCs(lines, counts)
    table.insert(lines, "===== NPCS / MOBS =====")
    counts.npcs = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local h   = v:FindFirstChildOfClass("Humanoid")
            local pos = hrp and tostring(hrp.Position) or "unknown"
            local hp  = h   and (h.Health .. "/" .. h.MaxHealth) or "?"
            table.insert(lines, "[MOB] " .. v.Name .. " | HP: " .. hp .. " | Pos: " .. pos)
            counts.npcs += 1
        end
    end
    table.insert(lines, "Total NPCs: " .. counts.npcs)
    table.insert(lines, "")
end

local function sectionScripts(lines, counts)
    table.insert(lines, "===== SCRIPTS =====")
    counts.scripts = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
            table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName())
            counts.scripts += 1
        end
    end
    table.insert(lines, "Total scripts: " .. counts.scripts)
    table.insert(lines, "")
end

local function sectionValues(lines, counts)
    table.insert(lines, "===== VALUES =====")
    counts.values = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("IntValue") or v:IsA("NumberValue")
        or v:IsA("StringValue") or v:IsA("BoolValue")
        or v:IsA("Vector3Value") or v:IsA("CFrameValue")
        or v:IsA("ObjectValue") or v:IsA("Color3Value") then
            local val = tostring(v.Value)
            table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName() .. " = " .. val)
            counts.values += 1
        end
    end
    table.insert(lines, "Total values: " .. counts.values)
    table.insert(lines, "")
end

local function sectionModels(lines, counts)
    table.insert(lines, "===== MODELS / PARTS TREE (depth 6) =====")
    counts.models = 0
    -- walk top-level containers
    local roots = {
        workspace,
        game:GetService("ReplicatedStorage"),
        game:GetService("ServerStorage"),
        game:GetService("Lighting"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
    }
    for _, root in ipairs(roots) do
        table.insert(lines, "[ROOT] " .. root.Name)
        local before = #lines
        walkTree(root, lines, 1, 6)
        counts.models += (#lines - before)
    end
    table.insert(lines, "Total model entries: " .. counts.models)
    table.insert(lines, "")
end

local function sectionInventory(lines, counts)
    table.insert(lines, "===== PLAYER INVENTORY / TOOLS =====")
    counts.inventory = 0
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(lines, "[PLAYER] " .. player.Name)
        -- Backpack
        local bp = player:FindFirstChildOfClass("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                local grip = tool:IsA("Tool") and tool.ToolTip or ""
                table.insert(lines, "  [BACKPACK] " .. tool.ClassName .. " : " .. tool.Name .. " | ToolTip: " .. grip)
                counts.inventory += 1
            end
        end
        -- Equipped (character)
        local char = player.Character
        if char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") or tool:IsA("HopperBin") then
                    table.insert(lines, "  [EQUIPPED] " .. tool.ClassName .. " : " .. tool.Name)
                    counts.inventory += 1
                end
            end
        end
        -- StarterGear
        local sg = player:FindFirstChildOfClass("StarterGear")
        if sg then
            for _, tool in ipairs(sg:GetChildren()) do
                table.insert(lines, "  [STARTERGEAR] " .. tool.ClassName .. " : " .. tool.Name)
                counts.inventory += 1
            end
        end
    end
    table.insert(lines, "Total inventory items: " .. counts.inventory)
    table.insert(lines, "")
end

local function sectionAttributes(lines, counts)
    table.insert(lines, "===== INSTANCE ATTRIBUTES =====")
    counts.attributes = 0
    for _, v in ipairs(game:GetDescendants()) do
        local ok, attrs = pcall(function() return v:GetAttributes() end)
        if ok and next(attrs) ~= nil then
            for k, val in pairs(attrs) do
                table.insert(lines,
                    "[ATTR] " .. v:GetFullName()
                    .. " → " .. tostring(k)
                    .. " = " .. tostring(val)
                )
                counts.attributes += 1
            end
        end
    end
    table.insert(lines, "Total attributes: " .. counts.attributes)
    table.insert(lines, "")
end

local function sectionGUIs(lines, counts)
    table.insert(lines, "===== GUIS =====")
    counts.guis = 0
    -- PlayerGui (local only)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local guiRoots = {
        playerGui,
        game:GetService("StarterGui"),
        game:GetService("CoreGui"),
    }
    for _, root in ipairs(guiRoots) do
        if root then
            table.insert(lines, "[GUI ROOT] " .. root:GetFullName())
            for _, v in ipairs(root:GetDescendants()) do
                if v:IsA("ScreenGui") or v:IsA("SurfaceGui") or v:IsA("BillboardGui")
                or v:IsA("Frame") or v:IsA("TextLabel") or v:IsA("TextButton")
                or v:IsA("TextBox") or v:IsA("ImageLabel") or v:IsA("ImageButton")
                or v:IsA("ScrollingFrame") then
                    local sizeStr = ""
                    local ok, sz = pcall(function()
                        return v.AbsoluteSize
                    end)
                    if ok and sz then
                        sizeStr = string.format(" | AbsSize(%.0f,%.0f)", sz.X, sz.Y)
                    end
                    table.insert(lines,
                        "  [" .. v.ClassName .. "] " .. v:GetFullName() .. sizeStr
                    )
                    counts.guis += 1
                end
            end
        end
    end
    table.insert(lines, "Total GUI elements: " .. counts.guis)
    table.insert(lines, "")
end

local function sectionBaseParts(lines, counts)
    table.insert(lines, "===== BASEPARTS POSITIONS & SIZES =====")
    counts.baseparts = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local p = v.Position
            local s = v.Size
            local cf = v.CFrame
            -- euler angles in degrees for orientation
            local rx, ry, rz = cf:ToEulerAnglesXYZ()
            local toDeg = math.deg
            table.insert(lines, string.format(
                "[%s] %s | Pos(%.3f, %.3f, %.3f) | Size(%.3f, %.3f, %.3f) | Rot(%.1f°, %.1f°, %.1f°) | Anchored=%s | CanCollide=%s | Material=%s",
                v.ClassName, v:GetFullName(),
                p.X, p.Y, p.Z,
                s.X, s.Y, s.Z,
                toDeg(rx), toDeg(ry), toDeg(rz),
                tostring(v.Anchored), tostring(v.CanCollide),
                tostring(v.Material)
            ))
            counts.baseparts += 1
        end
    end
    table.insert(lines, "Total BaseParts: " .. counts.baseparts)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Button factory
-- ─────────────────────────────────────────
local yOff = 68

for _, info in ipairs(buttons) do
    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(1, -10, 0, 28)
    btn.Position        = UDim2.new(0, 5, 0, yOff)
    btn.BackgroundColor3 = (info.file == "full")
        and Color3.fromRGB(200, 80, 140)
        or  Color3.fromRGB(35, 35, 35)
    btn.TextColor3      = Color3.fromRGB(255, 255, 255)
    btn.Text            = info.text
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 11
    btn.Parent          = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local origText = btn.Text
        btn.Text        = "⏳ Dumping..."
        StatusLabel.Text = "Working..."
        task.wait(0.05)

        local lines  = {}
        local counts = {}

        table.insert(lines, "=== DQ Reborn MEGA Dump ===")
        table.insert(lines, "Type: "    .. info.file)
        table.insert(lines, "Game: "    .. game.Name)
        table.insert(lines, "PlaceId: " .. tostring(game.PlaceId))
        table.insert(lines, "Time: "    .. os.date("%Y-%m-%d %H:%M:%S"))
        table.insert(lines, "LocalPlayer: " .. LocalPlayer.Name)
        table.insert(lines, "")

        local f = info.file

        if f == "remotes"    or f == "full" then sectionRemotes(lines, counts)    end
        if f == "npcs"       or f == "full" then sectionNPCs(lines, counts)        end
        if f == "scripts"    or f == "full" then sectionScripts(lines, counts)     end
        if f == "values"     or f == "full" then sectionValues(lines, counts)      end
        if f == "models"     or f == "full" then sectionModels(lines, counts)      end
        if f == "inventory"  or f == "full" then sectionInventory(lines, counts)   end
        if f == "attributes" or f == "full" then sectionAttributes(lines, counts)  end
        if f == "guis"       or f == "full" then sectionGUIs(lines, counts)        end
        if f == "baseparts"  or f == "full" then sectionBaseParts(lines, counts)   end

        -- summary footer
        table.insert(lines, "===== SUMMARY =====")
        local total = 0
        for section, n in pairs(counts) do
            table.insert(lines, section .. ": " .. tostring(n))
            total += n
        end
        table.insert(lines, "TOTAL: " .. total)

        local filename = "DQReborn_" .. info.file .. ".txt"
        local content  = table.concat(lines, "\n")

        local ok, err = pcall(function()
            writefile(filename, content)
        end)

        if ok then
            StatusLabel.Text = "✅ " .. filename .. " (" .. total .. " items)"
        else
            StatusLabel.Text = "❌ " .. tostring(err)
        end

        btn.Text = origText
    end)

    yOff += 31
end

-- stretch frame height to fit all buttons
Frame.Size = UDim2.new(0, 290, 0, yOff + 8)

-- ─────────────────────────────────────────
--  Draggable
-- ─────────────────────────────────────────
local dragging, dragInput, dragStart, startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Frame.Position
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

print("[DQ Reborn] MEGA Full Dumper v2 loaded ✓")
