--[[
    DQR Pro Script | Part 1: Auto Dungeon Enter
    by ENI x LO ☕
    Remote source: ReplicatedStorage dump verified
]]

-- ================================================
-- CORE SERVICES
-- ================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ================================================
-- REMOTE REFERENCES (verified from dump)
-- ================================================
local Remotes = {}

local function getRemote(name, rtype)
    local r = ReplicatedStorage:FindFirstChild(name, true)
    if r and r:IsA(rtype) then
        Remotes[name] = r
        return r
    end
    -- deep search fallback
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and v:IsA(rtype) then
            Remotes[name] = v
            return v
        end
    end
    warn("[DQR Pro] Remote not found: " .. name)
    return nil
end

-- Pre-cache remotes
local joinDungeon        = getRemote("joinDungeon", "RemoteFunction")
local startDungeon       = getRemote("startDungeon", "RemoteEvent")
local readyUp            = getRemote("readyUp", "RemoteEvent")
local replayDungeon      = getRemote("replayDungeon", "RemoteEvent")
local returnToLobby      = getRemote("ReturnToLobbyEvent", "RemoteEvent")
local getDungeonStats    = getRemote("getDungeonStats", "RemoteFunction")
local teleportRemote     = getRemote("Teleport", "RemoteFunction")

-- ================================================
-- STATE
-- ================================================
local State = {
    AutoDungeon  = false,
    TargetDungeon = nil,    -- จะ set หลังจากรู้ชื่อ dungeon
    Status = "Idle",
}

-- ================================================
-- GUI — PART 1
-- ================================================
pcall(function()
    if game.CoreGui:FindFirstChild("DQRPro") then
        game.CoreGui.DQRPro:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DQRPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

-- Main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 200)
Main.Position = UDim2.new(0, 20, 0.5, -100)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Title
local Title = Instance.new("Frame")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(88, 44, 160)
Title.BorderSizePixel = 0
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -10, 1, 0)
TitleLbl.Position = UDim2.new(0, 10, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "⚔ DQR Pro  |  Part 1"
TitleLbl.TextColor3 = Color3.white
TitleLbl.TextSize = 13
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Title

-- Status label
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, -20, 0, 24)
StatusLbl.Position = UDim2.new(0, 10, 0, 44)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "Status: Idle"
StatusLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
StatusLbl.TextSize = 12
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = Main

local function setStatus(msg)
    State.Status = msg
    StatusLbl.Text = "Status: " .. msg
end

-- Toggle builder
local function makeToggle(parent, label, yPos, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -20, 0, 34)
    Row.Position = UDim2.new(0, 10, 0, yPos)
    Row.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Row.BorderSizePixel = 0
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -55, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    Lbl.TextSize = 12
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 42, 0, 22)
    Btn.Position = UDim2.new(1, -50, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    Btn.Text = "OFF"
    Btn.TextColor3 = Color3.white
    Btn.TextSize = 11
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = Row
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local on = false
    Btn.MouseButton1Click:Connect(function()
        on = not on
        Btn.Text = on and "ON" or "OFF"
        TweenService:Create(Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on
                and Color3.fromRGB(88, 44, 160)
                or  Color3.fromRGB(55, 55, 75)
        }):Play()
        callback(on)
    end)

    return Btn
end

-- Toggles
makeToggle(Main, "🚪  Auto Enter Dungeon", 76, function(on)
    State.AutoDungeon = on
    setStatus(on and "Auto Dungeon: ON" or "Idle")
end)

makeToggle(Main, "🔁  Auto Ready Up", 118, function(on)
    State.AutoReady = on
end)

makeToggle(Main, "♻️  Auto Replay", 160, function(on)
    State.AutoReplay = on
end)

-- ================================================
-- LOGIC: AUTO DUNGEON ENTER
-- ================================================
local function tryJoinDungeon()
    if not joinDungeon then
        warn("[DQR Pro] joinDungeon remote not found")
        return
    end

    setStatus("Joining dungeon...")
    local ok, result = pcall(function()
        return joinDungeon:InvokeServer(State.TargetDungeon)
    end)

    if ok then
        setStatus("Joined! ✅")
        print("[DQR Pro] joinDungeon result:", result)
    else
        setStatus("Join failed — retrying...")
        warn("[DQR Pro] joinDungeon error:", result)
    end
end

local function tryReadyUp()
    if not readyUp then return end
    pcall(function() readyUp:FireServer() end)
    setStatus("Ready! ✅")
end

local function tryReplay()
    if not replayDungeon then return end
    pcall(function() replayDungeon:FireServer() end)
    setStatus("Replaying...")
end

-- ================================================
-- MAIN LOOP
-- ================================================
local lastAction = 0

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastAction < 3 then return end -- cooldown 3 วิ
    lastAction = now

    if State.AutoDungeon then
        tryJoinDungeon()
    end

    if State.AutoReady then
        tryReadyUp()
    end

    if State.AutoReplay then
        tryReplay()
    end
end)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(" DQR Pro | Part 1 loaded ✅")
print(" ► Auto Dungeon Enter ready")
print(" ► Part 2: Kill Aura + Auto Ability (next)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
