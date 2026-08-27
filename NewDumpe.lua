--[[
    Universal MEGA Dumper v1
    Works on ANY Roblox game
    Sections: Remotes, NPCs, Scripts, Values,
              Models Tree, Inventory, Attributes,
              GUIs, BaseParts, Bindables, Connections hint
    Compatible: Delta + MuMu + any executor with writefile
--]]

local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

-- ─────────────────────────────────────────
--  Safe pcall wrapper
-- ─────────────────────────────────────────
local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

-- ─────────────────────────────────────────
--  GUI
-- ─────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "UniversalMegaDumper"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.DisplayOrder = 999 end)
ScreenGui.Parent       = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size             = UDim2.new(0, 300, 0, 50) -- grows after buttons
Frame.Position         = UDim2.new(0, 10, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel  = 0
Frame.Parent           = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size             = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(80, 140, 200)
Title.TextColor3       = Color3.fromRGB(255, 255, 255)
Title.Text             = "🌍 Universal MEGA Dumper v1"
Title.Font             = Enum.Font.GothamBold
Title.TextSize         = 12
Title.Parent           = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local GameLabel = Instance.new("TextLabel")
GameLabel.Size             = UDim2.new(1, -10, 0, 20)
GameLabel.Position         = UDim2.new(0, 5, 0, 38)
GameLabel.BackgroundTransparency = 1
GameLabel.TextColor3       = Color3.fromRGB(100, 200, 100)
GameLabel.Text             = "🎮 " .. tostring(game.Name) .. " | " .. tostring(game.PlaceId)
GameLabel.Font             = Enum.Font.Gotham
GameLabel.TextSize         = 10
GameLabel.TextXAlignment   = Enum.TextXAlignment.Left
GameLabel.TextTruncate     = Enum.TextTruncate.AtEnd
GameLabel.Parent           = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size               = UDim2.new(1, -10, 0, 18)
StatusLabel.Position           = UDim2.new(0, 5, 0, 58)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
StatusLabel.Text               = "Ready!"
StatusLabel.Font               = Enum.Font.Gotham
StatusLabel.TextSize           = 10
StatusLabel.TextXAlignment     = Enum.TextXAlignment.Left
StatusLabel.Parent             = Frame

-- ─────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────
local function indent(n) return string.rep("  ", n) end

-- safe GetDescendants across any service
local function safeDescendants(root)
    local ok, list = pcall(function() return root:GetDescendants() end)
    return ok and list or {}
end

local function safeChildren(root)
    local ok, list = pcall(function() return root:GetChildren() end)
    return ok and list or {}
end

-- walk instance tree recursively
local function walkTree(root, lines, depth, maxDepth)
    if depth > maxDepth then return end
    for _, child in ipairs(safeChildren(root)) do
        local cls   = child.ClassName
        local extra = ""
        if child:IsA("BasePart") then
            local p = child.Position
            local s = child.Size
            extra = string.format(" | Pos(%.1f,%.1f,%.1f) Sz(%.1f,%.1f,%.1f)", p.X,p.Y,p.Z,s.X,s.Y,s.Z)
        end
        table.insert(lines, indent(depth) .. "[" .. cls .. "] " .. child.Name .. extra)
        walkTree(child, lines, depth + 1, maxDepth)
    end
end

-- get ALL accessible services (universal)
local serviceNames = {
    "Workspace", "Players", "ReplicatedStorage", "ReplicatedFirst",
    "ServerStorage", "ServerScriptService", "Lighting",
    "StarterGui", "StarterPack", "StarterPlayer",
    "Teams", "SoundService", "TextService", "TweenService",
    "MarketplaceService", "BadgeService", "DataStoreService",
    "HttpService", "RunService", "UserInputService",
    "ContextActionService", "GuiService", "PathfindingService",
    "PhysicsService", "InsertService", "Chat", "LocalizationService",
}

local function getAllServices()
    local svcs = {}
    for _, name in ipairs(serviceNames) do
        local ok, svc = pcall(function() return game:GetService(name) end)
        if ok and svc then
            table.insert(svcs, svc)
        end
    end
    return svcs
end

-- ─────────────────────────────────────────
--  Section: REMOTES
-- ─────────────────────────────────────────
local function sectionRemotes(lines, counts)
    table.insert(lines, "===== REMOTES =====")
    counts.remotes = 0
    for _, svc in ipairs(getAllServices()) do
        for _, v in ipairs(safeDescendants(svc)) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction")
            or v:IsA("UnreliableRemoteEvent") then
                table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName())
                counts.remotes += 1
            end
        end
    end
    table.insert(lines, "Total remotes: " .. counts.remotes)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: BINDABLES
-- ─────────────────────────────────────────
local function sectionBindables(lines, counts)
    table.insert(lines, "===== BINDABLES =====")
    counts.bindables = 0
    for _, svc in ipairs(getAllServices()) do
        for _, v in ipairs(safeDescendants(svc)) do
            if v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName())
                counts.bindables += 1
            end
        end
    end
    table.insert(lines, "Total bindables: " .. counts.bindables)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: NPCS / MOBS
-- ─────────────────────────────────────────
local function sectionNPCs(lines, counts)
    table.insert(lines, "===== NPCS / MOBS =====")
    counts.npcs = 0
    for _, v in ipairs(safeDescendants(workspace)) do
        if v:IsA("Model") then
            local h   = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if h then
                local pos  = hrp and tostring(hrp.Position) or "unknown"
                local hp   = tostring(h.Health) .. "/" .. tostring(h.MaxHealth)
                local isPlayer = false
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character == v then isPlayer = true break end
                end
                local tag = isPlayer and "[PLAYER]" or "[MOB]"
                table.insert(lines, tag .. " " .. v.Name .. " | HP: " .. hp .. " | Pos: " .. pos)
                counts.npcs += 1
            end
        end
    end
    table.insert(lines, "Total NPCs/Players: " .. counts.npcs)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: SCRIPTS
-- ─────────────────────────────────────────
local function sectionScripts(lines, counts)
    table.insert(lines, "===== SCRIPTS =====")
    counts.scripts = 0
    for _, svc in ipairs(getAllServices()) do
        for _, v in ipairs(safeDescendants(svc)) do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                local src = ""
                -- try read source (executors that support decompile)
                local ok, s = pcall(function() return v.Source end)
                if ok and s and #s > 0 then
                    src = " | Src:" .. tostring(#s) .. "b"
                end
                table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName() .. src)
                counts.scripts += 1
            end
        end
    end
    table.insert(lines, "Total scripts: " .. counts.scripts)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: VALUES
-- ─────────────────────────────────────────
local valueClasses = {
    "IntValue","NumberValue","StringValue","BoolValue",
    "Vector3Value","CFrameValue","Color3Value","ObjectValue",
    "RayValue","IntConstrainedValue","NumberSequenceValue",
}
local function sectionValues(lines, counts)
    table.insert(lines, "===== VALUES =====")
    counts.values = 0
    for _, svc in ipairs(getAllServices()) do
        for _, v in ipairs(safeDescendants(svc)) do
            for _, cls in ipairs(valueClasses) do
                if v:IsA(cls) then
                    local val = safe(function() return tostring(v.Value) end) or "?"
                    table.insert(lines, "[" .. v.ClassName .. "] " .. v:GetFullName() .. " = " .. val)
                    counts.values += 1
                    break
                end
            end
        end
    end
    table.insert(lines, "Total values: " .. counts.values)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: MODELS / PARTS TREE
-- ─────────────────────────────────────────
local function sectionModels(lines, counts)
    table.insert(lines, "===== MODELS / PARTS TREE (depth 5) =====")
    counts.models = 0
    local roots = getAllServices()
    for _, root in ipairs(roots) do
        table.insert(lines, "[ROOT] " .. root.Name)
        local before = #lines
        walkTree(root, lines, 1, 5)
        counts.models += (#lines - before)
    end
    table.insert(lines, "Total model entries: " .. counts.models)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: PLAYER INVENTORY
-- ─────────────────────────────────────────
local function sectionInventory(lines, counts)
    table.insert(lines, "===== PLAYER INVENTORY / TOOLS =====")
    counts.inventory = 0
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(lines, "[PLAYER] " .. player.Name)
        -- Backpack
        local bp = player:FindFirstChildOfClass("Backpack")
        if bp then
            for _, item in ipairs(safeChildren(bp)) do
                local tip = safe(function() return item.ToolTip end) or ""
                table.insert(lines, "  [BACKPACK] " .. item.ClassName .. " : " .. item.Name .. " | ToolTip: " .. tip)
                counts.inventory += 1
            end
        end
        -- Character (equipped)
        local char = player.Character
        if char then
            for _, item in ipairs(safeChildren(char)) do
                if item:IsA("Tool") or item:IsA("HopperBin") then
                    table.insert(lines, "  [EQUIPPED] " .. item.ClassName .. " : " .. item.Name)
                    counts.inventory += 1
                end
            end
        end
        -- StarterGear
        local sg = player:FindFirstChildOfClass("StarterGear")
        if sg then
            for _, item in ipairs(safeChildren(sg)) do
                table.insert(lines, "  [STARTERGEAR] " .. item.ClassName .. " : " .. item.Name)
                counts.inventory += 1
            end
        end
        -- Leaderstats (stats panel)
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            for _, stat in ipairs(safeChildren(ls)) do
                local val = safe(function() return tostring(stat.Value) end) or "?"
                table.insert(lines, "  [LEADERSTAT] " .. stat.Name .. " = " .. val)
            end
        end
    end
    table.insert(lines, "Total inventory items: " .. counts.inventory)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: ATTRIBUTES
-- ─────────────────────────────────────────
local function sectionAttributes(lines, counts)
    table.insert(lines, "===== INSTANCE ATTRIBUTES =====")
    counts.attributes = 0
    for _, svc in ipairs(getAllServices()) do
        for _, v in ipairs(safeDescendants(svc)) do
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
    end
    table.insert(lines, "Total attributes: " .. counts.attributes)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: GUIs
-- ─────────────────────────────────────────
local guiClasses = {
    "ScreenGui","SurfaceGui","BillboardGui","Frame","ScrollingFrame",
    "TextLabel","TextButton","TextBox","ImageLabel","ImageButton",
    "VideoFrame","ViewportFrame","UIListLayout","UIGridLayout",
}
local function sectionGUIs(lines, counts)
    table.insert(lines, "===== GUIS =====")
    counts.guis = 0
    local guiRoots = {
        safe(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end),
        safe(function() return game:GetService("StarterGui") end),
        safe(function() return game:GetService("CoreGui") end),
    }
    for _, root in ipairs(guiRoots) do
        if root then
            table.insert(lines, "[GUI ROOT] " .. root:GetFullName())
            for _, v in ipairs(safeDescendants(root)) do
                for _, cls in ipairs(guiClasses) do
                    if v:IsA(cls) then
                        local sizeStr = ""
                        local ok, sz = pcall(function() return v.AbsoluteSize end)
                        if ok and sz then
                            sizeStr = string.format(" | AbsSize(%.0f,%.0f)", sz.X, sz.Y)
                        end
                        table.insert(lines, "  [" .. v.ClassName .. "] " .. v:GetFullName() .. sizeStr)
                        counts.guis += 1
                        break
                    end
                end
            end
        end
    end
    table.insert(lines, "Total GUI elements: " .. counts.guis)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: BASEPARTS
-- ─────────────────────────────────────────
local function sectionBaseParts(lines, counts)
    table.insert(lines, "===== BASEPARTS POSITIONS & SIZES =====")
    counts.baseparts = 0
    for _, svc in ipairs({workspace, game:GetService("ReplicatedStorage")}) do
        for _, v in ipairs(safeDescendants(svc)) do
            if v:IsA("BasePart") then
                local p  = v.Position
                local s  = v.Size
                local cf = v.CFrame
                local rx, ry, rz = cf:ToEulerAnglesXYZ()
                local d  = math.deg
                table.insert(lines, string.format(
                    "[%s] %s | Pos(%.2f,%.2f,%.2f) | Sz(%.2f,%.2f,%.2f) | Rot(%.1f°,%.1f°,%.1f°) | Anch=%s | Col=%s | Mat=%s",
                    v.ClassName, v:GetFullName(),
                    p.X, p.Y, p.Z,
                    s.X, s.Y, s.Z,
                    d(rx), d(ry), d(rz),
                    tostring(v.Anchored),
                    tostring(v.CanCollide),
                    tostring(v.Material)
                ))
                counts.baseparts += 1
            end
        end
    end
    table.insert(lines, "Total BaseParts: " .. counts.baseparts)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Section: SOUNDS
-- ─────────────────────────────────────────
local function sectionSounds(lines, counts)
    table.insert(lines, "===== SOUNDS =====")
    counts.sounds = 0
    for _, svc in ipairs(getAllServices()) do
        for _, v in ipairs(safeDescendants(svc)) do
            if v:IsA("Sound") then
                local sid   = safe(function() return tostring(v.SoundId) end) or "?"
                local vol   = safe(function() return tostring(v.Volume) end) or "?"
                local play  = safe(function() return tostring(v.Playing) end) or "?"
                table.insert(lines,
                    "[Sound] " .. v:GetFullName()
                    .. " | SoundId: " .. sid
                    .. " | Vol: " .. vol
                    .. " | Playing: " .. play
                )
                counts.sounds += 1
            end
        end
    end
    table.insert(lines, "Total sounds: " .. counts.sounds)
    table.insert(lines, "")
end

-- ─────────────────────────────────────────
--  Buttons config
-- ─────────────────────────────────────────
local buttons = {
    { text = "📡 Remotes",           file = "remotes"    },
    { text = "🔗 Bindables",         file = "bindables"  },
    { text = "👾 NPCs / Players",    file = "npcs"       },
    { text = "📜 Scripts",           file = "scripts"    },
    { text = "💎 Values",            file = "values"     },
    { text = "🗺️  Models Tree",       file = "models"     },
    { text = "🎒 Inventory",         file = "inventory"  },
    { text = "🧩 Attributes",        file = "attributes" },
    { text = "🖼️  GUIs",              file = "guis"       },
    { text = "📐 BaseParts",         file = "baseparts"  },
    { text = "🔊 Sounds",            file = "sounds"     },
    { text = "🌍 DUMP EVERYTHING",   file = "full"       },
}

local yOff = 80

for _, info in ipairs(buttons) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -10, 0, 26)
    btn.Position         = UDim2.new(0, 5, 0, yOff)
    btn.BackgroundColor3 = (info.file == "full")
        and Color3.fromRGB(80, 140, 200)
        or  Color3.fromRGB(30, 30, 30)
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Text             = info.text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.Parent           = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local origText   = btn.Text
        btn.Text         = "⏳ Dumping..."
        StatusLabel.Text = "Working on: " .. info.file

        task.wait(0.05)

        local lines  = {}
        local counts = {}

        -- Header
        table.insert(lines, "=== Universal MEGA Dump ===")
        table.insert(lines, "Type: "        .. info.file)
        table.insert(lines, "Game: "        .. tostring(game.Name))
        table.insert(lines, "PlaceId: "     .. tostring(game.PlaceId))
        table.insert(lines, "JobId: "       .. tostring(game.JobId))
        table.insert(lines, "Creator: "     .. tostring(game.CreatorId))
        table.insert(lines, "Time: "        .. os.date("%Y-%m-%d %H:%M:%S"))
        table.insert(lines, "LocalPlayer: " .. LocalPlayer.Name)
        table.insert(lines, "IsStudio: "    .. tostring(RunService:IsStudio()))
        table.insert(lines, "")

        local f = info.file
        if f == "remotes"    or f == "full" then sectionRemotes(lines, counts)    end
        if f == "bindables"  or f == "full" then sectionBindables(lines, counts)  end
        if f == "npcs"       or f == "full" then sectionNPCs(lines, counts)       end
        if f == "scripts"    or f == "full" then sectionScripts(lines, counts)    end
        if f == "values"     or f == "full" then sectionValues(lines, counts)     end
        if f == "models"     or f == "full" then sectionModels(lines, counts)     end
        if f == "inventory"  or f == "full" then sectionInventory(lines, counts)  end
        if f == "attributes" or f == "full" then sectionAttributes(lines, counts) end
        if f == "guis"       or f == "full" then sectionGUIs(lines, counts)       end
        if f == "baseparts"  or f == "full" then sectionBaseParts(lines, counts)  end
        if f == "sounds"     or f == "full" then sectionSounds(lines, counts)     end

        -- Summary footer
        table.insert(lines, "===== SUMMARY =====")
        local total = 0
        for sec, n in pairs(counts) do
            table.insert(lines, sec .. ": " .. tostring(n))
            total += n
        end
        table.insert(lines, "TOTAL: " .. total)

        -- Filename: gamename_type_timestamp
        local gameName = tostring(game.Name):gsub("[^%w]", "_"):sub(1, 20)
        local filename = gameName .. "_" .. info.file .. "_" .. os.date("%H%M%S") .. ".txt"
        local content  = table.concat(lines, "\n")

        local ok, err = pcall(function() writefile(filename, content) end)

        if ok then
            StatusLabel.Text = "✅ " .. filename .. " (" .. total .. ")"
        else
            StatusLabel.Text = "❌ " .. tostring(err)
        end

        btn.Text = origText
    end)

    yOff += 29
end

-- resize frame to fit all buttons
Frame.Size = UDim2.new(0, 300, 0, yOff + 8)

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

print("[Universal MEGA Dumper] Loaded on: " .. tostring(game.Name) .. " (" .. tostring(game.PlaceId) .. ")")
