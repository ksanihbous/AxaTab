--==========================================================
--  4AxaTab_AntiAFK.lua
--  Env:
--    TAB_FRAME, LocalPlayer, RunService, StarterGui, VirtualInputManager, Players
--==========================================================

local antiTabFrame = TAB_FRAME
local player       = LocalPlayer

------------------------------------------------------
-- WAKTU & FORMAT UPTIME
------------------------------------------------------
local playStartTime      = os.time()   -- awal main (saat script/tab jalan)
local antiStartTime      = nil         -- diisi saat AntiAFK di-enable
local antiAccumulatedSec = 0           -- total durasi AntiAFK untuk 1 session (freeze saat OFF)

local function formatHMS(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h = math.floor(sec / 3600)
    sec = sec % 3600
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

------------------------------------------------------
-- UI HEADER
------------------------------------------------------
local antiHeader = Instance.new("TextLabel")
antiHeader.Name = "Header"
antiHeader.Size = UDim2.new(1, -10, 0, 22)
antiHeader.Position = UDim2.new(0, 5, 0, 6)
antiHeader.BackgroundTransparency = 1
antiHeader.Font = Enum.Font.GothamBold
antiHeader.TextSize = 15
antiHeader.TextColor3 = Color3.fromRGB(40, 40, 60)
antiHeader.TextXAlignment = Enum.TextXAlignment.Left
antiHeader.Text = "🛏️ AntiAFK+ Simple"
antiHeader.Parent = antiTabFrame

local antiSub = Instance.new("TextLabel")
antiSub.Name = "Sub"
antiSub.Size = UDim2.new(1, -10, 0, 34)
antiSub.Position = UDim2.new(0, 5, 0, 26)
antiSub.BackgroundTransparency = 1
antiSub.Font = Enum.Font.Gotham
antiSub.TextSize = 12
antiSub.TextColor3 = Color3.fromRGB(90, 90, 120)
antiSub.TextXAlignment = Enum.TextXAlignment.Left
antiSub.TextYAlignment = Enum.TextYAlignment.Top
antiSub.TextWrapped = true
antiSub.Text = "Menahan idle kick Roblox + auto respawn + auto restart route (AxaXyzReplayUI)."
antiSub.Parent = antiTabFrame

local antiToggleBtn = Instance.new("TextButton")
antiToggleBtn.Name = "Toggle"
antiToggleBtn.Size = UDim2.new(0, 130, 0, 26)
antiToggleBtn.Position = UDim2.new(0, 5, 0, 60)
antiToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
antiToggleBtn.Font = Enum.Font.GothamBold
antiToggleBtn.TextSize = 13
antiToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
antiToggleBtn.Text = "AntiAFK: OFF"
antiToggleBtn.Parent = antiTabFrame

local antiCorner = Instance.new("UICorner")
antiCorner.CornerRadius = UDim.new(0, 8)
antiCorner.Parent = antiToggleBtn

local antiStatus = Instance.new("TextLabel")
antiStatus.Name = "Status"
antiStatus.Size = UDim2.new(1, -10, 0, 20)
antiStatus.Position = UDim2.new(0, 5, 0, 92)
antiStatus.BackgroundTransparency = 1
antiStatus.Font = Enum.Font.Gotham
antiStatus.TextSize = 12
antiStatus.TextColor3 = Color3.fromRGB(90, 90, 120)
antiStatus.TextXAlignment = Enum.TextXAlignment.Left
antiStatus.Text = "Status: Idle"
antiStatus.Parent = antiTabFrame

-- Uptime AntiAFK
local antiUptimeAFK = Instance.new("TextLabel")
antiUptimeAFK.Name = "UptimeAFK"
antiUptimeAFK.Size = UDim2.new(1, -10, 0, 18)
antiUptimeAFK.Position = UDim2.new(0, 5, 0, 112)
antiUptimeAFK.BackgroundTransparency = 1
antiUptimeAFK.Font = Enum.Font.Gotham
antiUptimeAFK.TextSize = 12
antiUptimeAFK.TextColor3 = Color3.fromRGB(90, 90, 120)
antiUptimeAFK.TextXAlignment = Enum.TextXAlignment.Left
antiUptimeAFK.Text = "Uptime AntiAFK: 00:00:00"
antiUptimeAFK.Parent = antiTabFrame

-- Uptime Play
local antiUptimePlay = Instance.new("TextLabel")
antiUptimePlay.Name = "UptimePlay"
antiUptimePlay.Size = UDim2.new(1, -10, 0, 18)
antiUptimePlay.Position = UDim2.new(0, 5, 0, 132)
antiUptimePlay.BackgroundTransparency = 1
antiUptimePlay.Font = Enum.Font.Gotham
antiUptimePlay.TextSize = 12
antiUptimePlay.TextColor3 = Color3.fromRGB(90, 90, 120)
antiUptimePlay.TextXAlignment = Enum.TextXAlignment.Left
antiUptimePlay.Text = "Uptime Play: 00:00:00"
antiUptimePlay.Parent = antiTabFrame

------------------------------------------------------
-- ==== AntiAFK+ LOGIC ====
------------------------------------------------------
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 8
        })
    end)
end

local BRAND      = "AxaXyz"
local function BrandTitle() return BRAND .. " AntiAFK+" end

local BUTTON_ROOT_NAME = "AxaXyzReplayUI"

local lastState    = nil
local lastNotifyAt = 0
local NOTIFY_MIN_GAP = 6

local function push(msg, dur)
    local now = time()
    if now - lastNotifyAt >= NOTIFY_MIN_GAP then
        notify(BrandTitle(), msg, dur or 6)
        lastNotifyAt = now
    end
end

local AUTO_START             = true
local AUTO_RESPAWN           = true
local STOP_DELAY             = 25
local RESPAWN_DELAY          = 10
local POST_RESPAWN_DELAY     = 10
local MOVE_THRESHOLD         = 0.05
local RETRY_INTERVAL         = 10
local COOLDOWN_AFTER_RESPAWN = 30

local hrp, toggleBtn, lastPos = nil, nil, nil
local stillTime, totalDist = 0, 0
local lastAutoStart, justRestarted = 0, false
local afterRespawn = false

local antiEnabled = false
local antiIdleConn = nil

local function setStatus(text, color)
    if antiStatus then
        antiStatus.Text = "Status: " .. text
        if color then antiStatus.TextColor3 = color end
    end
    if _G.AxaXyzStatus then
        _G.AxaXyzStatus(text, color)
    end
end

_G.AxaXyzStatus = function(text, color)
    if antiStatus then
        antiStatus.Text = "Status: " .. text
        if color then antiStatus.TextColor3 = color end
    end
end

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("Humanoid")
    return char:WaitForChild("HumanoidRootPart")
end

local function clickButton(btn)
    if not btn or not btn.Parent then return end
    local ok = pcall(function() btn:Activate() end)
    if ok then return end

    local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
end

local function getButtonText()
    if not toggleBtn or not toggleBtn.Parent then return "" end
    return string.lower(toggleBtn.Text or "")
end

local function findToggleButtonOnce()
    for _, g in ipairs(game:GetDescendants()) do
        if g:IsA("TextButton") then
            local txt = g.Text or ""
            if (string.find(txt, "Start") or string.find(txt, "Stop")) then
                local p = g.Parent
                if p and (p.Name == BUTTON_ROOT_NAME or (p.Parent and p.Parent.Name == BUTTON_ROOT_NAME)) then
                    return g
                end
            end
        end
    end
    return nil
end

local function waitForToggleButton()
    local ui
    repeat
        task.wait(0.5)
        ui = findToggleButtonOnce()
    until ui
    print("["..BrandTitle().."] Tombol replay ditemukan:", ui.Text)
    return ui
end

local function respawnChar()
    if not antiEnabled then return end

    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        print("["..BrandTitle().."] Respawning...")
        setStatus("🔴 Respawning...", Color3.fromRGB(255,100,100))
        push("Respawning...")
        char.Humanoid.Health = 0
    end

    player.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")
    task.wait(POST_RESPAWN_DELAY)

    hrp = getHRP()
    afterRespawn = true

    toggleBtn = findToggleButtonOnce() or waitForToggleButton()

    local text = getButtonText()
    if string.find(text, "stop") then
        clickButton(toggleBtn)
        task.wait(0.5)
    end
    if string.find(getButtonText(), "start") then
        clickButton(toggleBtn)
        setStatus("🟢 Auto Start after Respawn", Color3.fromRGB(100,255,100))
        push("Auto-start after respawn ✅")
        lastState = "running"
    end

    task.spawn(function()
        task.wait(COOLDOWN_AFTER_RESPAWN)
        afterRespawn = false
    end)
end

local function setAntiEnabledUI(state)
    antiEnabled = state
    if antiEnabled then
        antiToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        antiToggleBtn.Text             = "AntiAFK: ON"
        setStatus("Menahan idle kick...", Color3.fromRGB(90, 150, 90))
    else
        antiToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
        antiToggleBtn.Text             = "AntiAFK: OFF"
        setStatus("Idle", Color3.fromRGB(90, 90, 120))
    end
end

local antiLoopStarted = false

local function startAntiLoop()
    if antiLoopStarted then return end
    antiLoopStarted = true

    task.spawn(function()
        while true do
            task.wait(1)

            -- UPDATE UPTIME SETIAP DETIK
            local now = os.time()

            -- Uptime Play: selalu jalan
            if antiUptimePlay then
                local playSec = now - playStartTime
                antiUptimePlay.Text = "Uptime Play: " .. formatHMS(playSec)
            end

            -- Uptime AntiAFK:
            --   - Saat ON: accumulated + (now - antiStartTime)
            --   - Saat OFF: pakai accumulated saja (freeze)
            if antiUptimeAFK then
                local antiSec = antiAccumulatedSec
                if antiEnabled and antiStartTime then
                    antiSec = antiAccumulatedSec + (now - antiStartTime)
                end
                antiUptimeAFK.Text = "Uptime AntiAFK: " .. formatHMS(antiSec)
            end

            -- LOGIC ANTI AFK
            if not antiEnabled then
                continue
            end

            if not hrp or not hrp.Parent then
                hrp = getHRP()
                lastPos = hrp.Position
                stillTime, totalDist, justRestarted, lastState = 0, 0, false, nil
                continue
            end

            local dist = (hrp.Position - lastPos).Magnitude
            totalDist += dist
            lastPos = hrp.Position

            if dist < MOVE_THRESHOLD then
                stillTime += 1
            else
                stillTime, totalDist, justRestarted = 0, 0, false
            end

            if afterRespawn then
                stillTime = 0
                continue
            end

            if stillTime == 0 then
                setStatus("🟢 Running", Color3.fromRGB(100,255,100))
                if lastState ~= "running" then
                    push("Running ✅")
                    lastState = "running"
                end
            elseif stillTime < RESPAWN_DELAY then
                setStatus(("🟡 Idle %ds"):format(stillTime), Color3.fromRGB(255,255,150))
                if lastState ~= "idle" and stillTime >= math.max(2, math.floor(RESPAWN_DELAY/2)) then
                    push(("Idle %ds"):format(stillTime))
                    lastState = "idle"
                end
            end

            if AUTO_RESPAWN and stillTime >= RESPAWN_DELAY then
                print("["..BrandTitle().."] Auto respawn triggered.")
                respawnChar()
                stillTime, totalDist, justRestarted = 0, 0, false
                continue
            end

            local now2 = time()
            if AUTO_START and stillTime >= STOP_DELAY and totalDist < 0.5 and (now2 - lastAutoStart > RETRY_INTERVAL) then
                if not toggleBtn or not toggleBtn.Parent then
                    toggleBtn = waitForToggleButton()
                end
                if justRestarted and (now2 - lastAutoStart) > (RETRY_INTERVAL * 2) then
                    justRestarted = false
                end

                if not justRestarted then
                    setStatus("🔵 Restarting Route...", Color3.fromRGB(100,150,255))
                    push("Restarting route... 🔄")

                    local text2 = getButtonText()
                    if string.find(text2, "stop") then
                        clickButton(toggleBtn)
                        task.wait(0.6)
                    end
                    if string.find(getButtonText(), "start") then
                        clickButton(toggleBtn)
                        lastAutoStart = now2
                        justRestarted = true
                        setStatus("🟢 Running", Color3.fromRGB(100,255,100))
                        push("Running ✅")
                        lastState = "running"
                    end
                end
                stillTime, totalDist = 0, 0
            end
        end
    end)
end

local function enableAntiAFK()
    if antiEnabled then return end

    hrp = getHRP()
    if not toggleBtn or not toggleBtn.Parent then
        toggleBtn = findToggleButtonOnce()
    end

    if not antiIdleConn then
        local vu = game:GetService("VirtualUser")
        antiIdleConn = Players.LocalPlayer.Idled:Connect(function()
            if not antiEnabled then return end
            vu:CaptureController()
            vu:ClickButton2(
                Vector2.new(0, 0),
                (workspace.CurrentCamera and workspace.CurrentCamera.CFrame) or CFrame.new()
            )
        end)
    end

    -- Mulai session AntiAFK baru
    antiAccumulatedSec = 0
    antiStartTime      = os.time()

    setAntiEnabledUI(true)
    push("UI AntiAFK+ aktif ✅")
    startAntiLoop()
end

local function disableAntiAFK()
    if not antiEnabled then return end

    -- Freeze uptime di nilai terakhir (akumulasi)
    if antiStartTime then
        antiAccumulatedSec = antiAccumulatedSec + (os.time() - antiStartTime)
        antiStartTime = nil
    end

    setAntiEnabledUI(false)
    stillTime, totalDist, justRestarted = 0, 0, false
    lastState = nil
    afterRespawn = false
    push("AntiAFK+ dimatikan ⛔️")
end

antiToggleBtn.MouseButton1Click:Connect(function()
    if antiEnabled then
        disableAntiAFK()
    else
        enableAntiAFK()
    end
end)

-- expose untuk core kalau mau matikan saat Close
_G.AxaHub_AntiAFK_Disable = disableAntiAFK

------------------------------------------------------
-- DEFAULT: AntiAFK LANGSUNG AKTIF (AUTO TRUE)
------------------------------------------------------
enableAntiAFK()
