--[[
    DQR Full Dump Pipeline
    Compatible: Solara | UNC-compliant executors
    Output: Workspace dump + Scripts + Remote log
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ================================================
-- PART 1: FULL INSTANCE SAVE (rbxlx)
-- ================================================
print("[DQR Dump] Starting full instance save...")

local saveOptions = {
    SavePlayers     = false,
    SaveNonCreatable = true,
    DecompileScripts = true,
    IsolateStarterPlayer = false,
    ShowStatus = true,
}

local ok, err = pcall(function()
    saveinstance(saveOptions)
end)

if ok then
    print("[DQR Dump] ✅ Instance saved! Check workspace folder.")
else
    warn("[DQR Dump] saveinstance failed: " .. tostring(err))
    warn("[DQR Dump] Falling back to manual script dump...")

    -- ================================================
    -- FALLBACK: Manual Script Decompiler
    -- ================================================
    local dumpedScripts = {}

    local function tryDecompile(script)
        if not script or not script:IsA("LuaSourceContainer") then return nil end
        local src = ""
        local s, r = pcall(function()
            src = decompile(script) or getscriptbytecode and decompile(getscriptbytecode(script)) or "-- failed"
        end)
        if not s then src = "-- decompile error: " .. tostring(r) end
        return src
    end

    local function dumpAllScripts()
        local scripts = getscripts and getscripts() or {}
        if #scripts == 0 then
            -- fallback scan
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("LuaSourceContainer") then
                    table.insert(scripts, v)
                end
            end
        end

        print(string.format("[DQR Dump] Found %d scripts to decompile...", #scripts))

        local output = {}
        for i, scr in ipairs(scripts) do
            local src = tryDecompile(scr)
            if src then
                local entry = string.format(
                    "-- [%d] Path: %s\n-- Name: %s\n-- Class: %s\n\n%s\n\n%s\n\n",
                    i,
                    scr:GetFullName(),
                    scr.Name,
                    scr.ClassName,
                    src,
                    string.rep("-", 80)
                )
                table.insert(output, entry)
                table.insert(dumpedScripts, {
                    name = scr.Name,
                    path = scr:GetFullName(),
                    source = src
                })
            end
        end

        -- Write to file
        local fullDump = table.concat(output, "\n")
        if writefile then
            writefile("DQR_ScriptDump.txt", fullDump)
            print("[DQR Dump] ✅ Script dump saved → DQR_ScriptDump.txt")
        else
            print("[DQR Dump] writefile not supported — printing to console")
            print(fullDump)
        end
    end

    dumpAllScripts()
end

-- ================================================
-- PART 2: REMOTE SPY + LOGGER
-- ================================================
print("[DQR Dump] Starting Remote Spy...")

local remoteLog = {}
local logLines  = {}

local function logRemote(rType, remote, args)
    local argStrs = {}
    for i, arg in ipairs(args) do
        local t = typeof(arg)
        local display = ""
        if t == "string"  then display = string.format('"%s"', tostring(arg))
        elseif t == "number" or t == "boolean" then display = tostring(arg)
        elseif t == "Instance" then display = string.format("[%s] %s", arg.ClassName, arg:GetFullName())
        elseif t == "Vector3" then display = string.format("Vector3(%0.2f, %0.2f, %0.2f)", arg.X, arg.Y, arg.Z)
        elseif t == "table" then display = "[table]"
        else display = string.format("[%s]", t) end
        table.insert(argStrs, string.format("  arg%d (%s) = %s", i, t, display))
    end

    local entry = string.format(
        "[%s] %s → %s\n%s\n",
        rType,
        remote:GetFullName(),
        remote.Name,
        #argStrs > 0 and table.concat(argStrs, "\n") or "  (no args)"
    )

    table.insert(logLines, entry)
    print(entry)

    -- Save every 20 logs
    if #logLines % 20 == 0 and writefile then
        writefile("DQR_RemoteLog.txt", table.concat(logLines, "\n"))
    end
end

-- Hook all existing remotes
local function hookRemote(remote)
    if remote:IsA("RemoteEvent") then
        local oldFire = remote.FireServer
        hookfunction(remote.FireServer, function(self, ...)
            logRemote("RemoteEvent:Fire", remote, {...})
            return oldFire(self, ...)
        end)

    elseif remote:IsA("RemoteFunction") then
        local oldInvoke = remote.InvokeServer
        hookfunction(remote.InvokeServer, function(self, ...)
            logRemote("RemoteFunction:Invoke", remote, {...})
            return oldInvoke(self, ...)
        end)
    end
end

-- Hook existing
for _, v in pairs(game:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        pcall(hookRemote, v)
    end
end

-- Hook new ones added later
game.DescendantAdded:Connect(function(v)
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        task.wait(0.1) -- wait for it to settle
        pcall(hookRemote, v)
    end
end)

print("[DQR Dump] ✅ Remote Spy active — firing remotes จะ log ใน console + DQR_RemoteLog.txt")

-- ================================================
-- PART 3: ANTI-CHEAT DETECTOR
-- ================================================
print("[DQR Dump] Scanning for Anti-Cheat scripts...")

local acKeywords = {
    "anticheat", "anti_cheat", "detection", "exploit",
    "cheatdetect", "integrity", "sanitycheck", "validate"
}

for _, v in pairs(game:GetDescendants()) do
    if v:IsA("LuaSourceContainer") then
        local name = v.Name:lower()
        for _, keyword in ipairs(acKeywords) do
            if name:find(keyword) then
                warn(string.format(
                    "[AC Detector] ⚠️ Suspicious script found: %s → %s",
                    v.ClassName, v:GetFullName()
                ))
                break
            end
        end
    end
end

-- ================================================
-- SUMMARY
-- ================================================
task.wait(2)
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(" DQR Dump Complete!")
print(" 📁 DQR_ScriptDump.txt  → decompiled scripts")
print(" 📡 DQR_RemoteLog.txt   → remote spy log (live)")
print(" 🎮 Instance .rbxlx     → full game dump")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(" ต่อไป: เอา RemoteLog ไปดูว่า remote ชื่ออะไร")
print(" แล้ว ping กลับมา จะทำโปรให้ตรงๆ เลย ☕")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
