--==========================================================
--  AxaTab_ServerDashboard.lua
--  Dipanggil via loadstring dari CORE AxaHub
--  Env yang tersedia (dari core):
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, TweenService, HttpService,
--    UserInputService, VirtualInputManager, ContextActionService,
--    StarterGui, CoreGui, Camera, SetActiveTab, AXA_TWEEN (opsional)
--==========================================================

local frame        = TAB_FRAME
local player       = LocalPlayer
local players      = Players
local runService   = RunService
local tweenService = TweenService
local starterGui   = StarterGui

local TeleportService = game:GetService("TeleportService")
local Stats           = game:GetService("Stats")

--==========================================================
-- HELPER
--==========================================================
local function axaTween(obj, t, props)
    if _G.AxaHub_Tween then
        return _G.AxaHub_Tween(obj, t, props)
    end
    local info = TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = tweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function notify(title, text, dur)
    pcall(function()
        starterGui:SetCore("SendNotification", {
            Title    = title or "Info",
            Text     = text or "",
            Duration = dur or 2
        })
    end)
end

local function formatDuration(sec)
    sec = math.floor(sec + 0.5)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

local function formatIdle(sec)
    if not sec or sec <= 0 then return "0s" end
    sec = math.floor(sec + 0.5)
    local m = math.floor(sec / 60)
    local s = sec % 60
    if m > 0 then
        return string.format("%dm %02ds", m, s)
    else
        return string.format("%ds", s)
    end
end

--==========================================================
-- HEADER (TIDAK DI-SCROLL)
--==========================================================
local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextColor3 = Color3.fromRGB(40, 40, 60)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "📊 Server Dashboard"
header.Parent = frame

local sub = Instance.new("TextLabel")
sub.Name = "Sub"
sub.Size = UDim2.new(1, -10, 0, 32)
sub.Position = UDim2.new(0, 5, 0, 26)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextColor3 = Color3.fromRGB(90, 90, 120)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextYAlignment = Enum.TextYAlignment.Top
sub.TextWrapped = true
sub.Text = "Monitor info server, performa client, pemain online, AFK monitor, dan utilitas (rejoin, server hop, copy ID) dalam satu panel."
sub.Parent = frame

--==========================================================
-- BODY SCROLL (SEMUA KONTEN DI SINI, BISA SCROLL KE BAWAH)
--==========================================================
local bodyScroll = frame:FindFirstChild("BodyScroll")
if not bodyScroll or not bodyScroll:IsA("ScrollingFrame") then
    bodyScroll = Instance.new("ScrollingFrame")
    bodyScroll.Name = "BodyScroll"
    bodyScroll.Position = UDim2.new(0, 0, 0, 64)          -- di bawah header+sub
    bodyScroll.Size = UDim2.new(1, 0, 1, -64)
    bodyScroll.BackgroundTransparency = 1
    bodyScroll.BorderSizePixel = 0
    bodyScroll.ScrollBarThickness = 6
    bodyScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    bodyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    bodyScroll.Parent = frame
end

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Padding = UDim.new(0, 8)
bodyLayout.Parent = bodyScroll

bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    bodyScroll.CanvasSize = UDim2.new(0, 0, 0, bodyLayout.AbsoluteContentSize.Y + 10)
end)

local function makeCard(height)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, -12, 0, height)
    card.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
    card.BorderSizePixel = 0
    card.BackgroundTransparency = 0
    card.Parent = bodyScroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = card

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(210, 210, 225)
    s.Transparency = 0.3
    s.Parent = card

    return card
end

local function makeSectionTitle(parent, text)
    local label = Instance.new("TextLabel")
    label.Name = "SectionTitle"
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 8, 0, 8)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(60, 60, 90)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = parent
    return label
end

local function makeSectionSub(parent, text, offsetY)
    local label = Instance.new("TextLabel")
    label.Name = "SectionSub"
    label.Size = UDim2.new(1, -10, 0, 30)
    label.Position = UDim2.new(0, 8, 0, offsetY)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(110, 110, 135)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.Text = text
    label.Parent = parent
    return label
end

--==========================================================
-- CARD 1: RINGKASAN SERVER + PERFORMA
--==========================================================
local summaryCard = makeCard(110)
makeSectionTitle(summaryCard, "Ringkasan Server (Live)")

local summaryLabel = Instance.new("TextLabel")
summaryLabel.Name = "SummaryLabel"
summaryLabel.Size = UDim2.new(1, -16, 0, 70)
summaryLabel.Position = UDim2.new(0, 8, 0, 30)
summaryLabel.BackgroundTransparency = 1
summaryLabel.Font = Enum.Font.Code
summaryLabel.TextSize = 12
summaryLabel.TextColor3 = Color3.fromRGB(60, 60, 90)
summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
summaryLabel.TextYAlignment = Enum.TextYAlignment.Top
summaryLabel.TextWrapped = true
summaryLabel.Text = "Memuat info server..."
summaryLabel.Parent = summaryCard

local startTime  = tick()
local smoothFPS  = 60

runService.RenderStepped:Connect(function(dt)
    local current = 1 / math.max(dt, 0.0001)
    smoothFPS = smoothFPS + (current - smoothFPS) * 0.1
end)

local function getPingMs()
    local ok, ping = pcall(function()
        local network = Stats.Network
        if not network then return nil end
        local serverStats = network.ServerStatsItem
        if not serverStats then return nil end
        local stat = serverStats:FindFirstChild("Data Ping") or serverStats:FindFirstChild("Ping")
        if not stat then return nil end

        if stat.GetValue then
            return math.floor(stat:GetValue() + 0.5)
        elseif typeof(stat.Value) == "number" then
            return math.floor(stat.Value + 0.5)
        end
        return nil
    end)
    if ok then
        return ping
    end
    return nil
end

local function getMemoryMB()
    local ok, kb = pcall(function()
        return collectgarbage("count") -- KB
    end)
    if ok and typeof(kb) == "number" then
        return kb / 1024
    end
    return nil
end

local function refreshSummary()
    local currentPlayers = #players:GetPlayers()
    local maxPlayers     = players.MaxPlayers or 0
    local pingMs         = getPingMs()
    local memMb          = getMemoryMB()
    local uptime         = formatDuration(tick() - startTime)

    local lines = {}

    table.insert(lines, string.format("PlaceId   : %d", game.PlaceId or 0))
    table.insert(lines, string.format("JobId     : %s", tostring(game.JobId or "N/A")))
    table.insert(lines, string.format("Players   : %d / %d", currentPlayers, maxPlayers))

    local perf = {}

    if pingMs then
        table.insert(perf, string.format("Ping ~ %d ms", pingMs))
    end

    table.insert(perf, string.format("FPS ~ %.1f", smoothFPS))

    if memMb then
        table.insert(perf, string.format("Lua Mem ~ %.1f MB", memMb))
    end

    table.insert(lines, "Performa : " .. table.concat(perf, "  |  "))
    table.insert(lines, string.format("Uptime   : %s", uptime))

    summaryLabel.Text = table.concat(lines, "\n")
end

task.spawn(function()
    while summaryCard.Parent do
        refreshSummary()
        task.wait(1)
    end
end)

--==========================================================
-- CARD 2: TOMBOL UTILITAS SERVER (REJOIN, HOP, COPY ID)
--   -> BARIS TOMBOL DI DALAM SCROLLINGFRAME HORIZONTAL
--==========================================================
local actionCard = makeCard(90)
makeSectionTitle(actionCard, "Utilitas Server")

-- ScrollingFrame horizontal untuk tombol-tombol
local btnScroll = Instance.new("ScrollingFrame")
btnScroll.Name = "ButtonScroll"
btnScroll.Size = UDim2.new(1, -16, 0, 40)
btnScroll.Position = UDim2.new(0, 8, 0, 34)
btnScroll.BackgroundTransparency = 1
btnScroll.BorderSizePixel = 0
btnScroll.ScrollBarThickness = 4
btnScroll.ScrollingDirection = Enum.ScrollingDirection.X
btnScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
btnScroll.Parent = actionCard

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Padding = UDim.new(0, 6)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
btnLayout.Parent = btnScroll

btnLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    btnScroll.CanvasSize = UDim2.new(0, btnLayout.AbsoluteContentSize.X + 6, 0, 0)
end)

local function makeSmallButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 120, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(210, 220, 255)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(50, 60, 110)
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = btnScroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = b

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(160, 170, 220)
    s.Transparency = 0.3
    s.Parent = b

    b.MouseEnter:Connect(function()
        axaTween(b, 0.12, {BackgroundColor3 = Color3.fromRGB(225, 230, 255)})
    end)
    b.MouseLeave:Connect(function()
        axaTween(b, 0.16, {BackgroundColor3 = Color3.fromRGB(210, 220, 255)})
    end)

    return b
end

local rejoinBtn     = makeSmallButton("🔁 Rejoin Server")
local hopBtn        = makeSmallButton("🌐 Server Hop")
local copyJobBtn    = makeSmallButton("📋 Copy JobId")
local copyPlaceBtn  = makeSmallButton("📋 Copy PlaceId")

rejoinBtn.MouseButton1Click:Connect(function()
    notify("Rejoin", "Menghubungkan ulang ke server ini...", 1.5)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
    if not ok then
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
    end
end)

hopBtn.MouseButton1Click:Connect(function()
    notify("Server Hop", "Mencoba pindah ke server publik lain...", 1.5)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, player)
    end)
end)

copyJobBtn.MouseButton1Click:Connect(function()
    local text = tostring(game.JobId)
    local ok = pcall(function()
        setclipboard(text)
    end)
    if ok then
        notify("Copy JobId", "JobId disalin ke clipboard.", 1.5)
    else
        notify("Copy JobId", text, 2)
    end
end)

copyPlaceBtn.MouseButton1Click:Connect(function()
    local text = tostring(game.PlaceId)
    local ok = pcall(function()
        setclipboard(text)
    end)
    if ok then
        notify("Copy PlaceId", "PlaceId disalin ke clipboard.", 1.5)
    else
        notify("Copy PlaceId", text, 2)
    end
end)

--==========================================================
-- CARD 3: DAFTAR PLAYER ONLINE
--==========================================================
local playersCard = makeCard(210)
makeSectionTitle(playersCard, "Daftar Player Online")

makeSectionSub(
    playersCard,
    "Klik baris untuk highlight. LocalPlayer ditandai warna biru muda.",
    28
)

local listHolder = Instance.new("Frame")
listHolder.Name = "ListHolder"
listHolder.Size = UDim2.new(1, -16, 0, 150)
listHolder.Position = UDim2.new(0, 8, 0, 60)
listHolder.BackgroundColor3 = Color3.fromRGB(232, 235, 246)
listHolder.BorderSizePixel = 0
listHolder.Parent = playersCard

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 10)
listCorner.Parent = listHolder

local listStroke = Instance.new("UIStroke")
listStroke.Thickness = 1
listStroke.Color = Color3.fromRGB(200, 205, 225)
listStroke.Transparency = 0.4
listStroke.Parent = listHolder

local innerScroll = Instance.new("ScrollingFrame")
innerScroll.Name = "PlayerScroll"
innerScroll.Size = UDim2.new(1, -8, 1, -8)
innerScroll.Position = UDim2.new(0, 4, 0, 4)
innerScroll.BackgroundTransparency = 1
innerScroll.BorderSizePixel = 0
innerScroll.ScrollBarThickness = 4
innerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
innerScroll.ScrollingDirection = Enum.ScrollingDirection.Y
innerScroll.Parent = listHolder

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = innerScroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    innerScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
end)

local rowMap = {}
local highlightedRow = nil

local function setRowHighlight(row, on)
    if not row or not row:IsA("Frame") then return end
    local baseColor = row:GetAttribute("BaseColor")
    if on then
        axaTween(row, 0.12, {BackgroundColor3 = Color3.fromRGB(210, 230, 255)})
    elseif baseColor then
        row.BackgroundColor3 = baseColor
    end
end

local function buildRow(plr)
    local row = Instance.new("Frame")
    row.Name = plr.Name
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(244, 246, 252)
    row.BorderSizePixel = 0
    row.Parent = innerScroll

    local baseColor = row.BackgroundColor3
    if plr == player then
        baseColor = Color3.fromRGB(210, 230, 255)
        row.BackgroundColor3 = baseColor
    end
    row:SetAttribute("BaseColor", baseColor)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(0.55, -6, 1, 0)
    nameLabel.Position = UDim2.new(0, 6, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(55, 60, 90)
    nameLabel.Text = string.format("%s (@%s)", plr.DisplayName or plr.Name, plr.Name)
    nameLabel.Parent = row

    local idLabel = Instance.new("TextLabel")
    idLabel.Name = "UserId"
    idLabel.Size = UDim2.new(0.25, -6, 1, 0)
    idLabel.Position = UDim2.new(0.55, 0, 0, 0)
    idLabel.BackgroundTransparency = 1
    idLabel.Font = Enum.Font.Code
    idLabel.TextSize = 12
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.TextColor3 = Color3.fromRGB(90, 95, 120)
    idLabel.Text = tostring(plr.UserId)
    idLabel.Parent = row

    local meLabel = Instance.new("TextLabel")
    meLabel.Name = "Tag"
    meLabel.Size = UDim2.new(0.2, -6, 1, 0)
    meLabel.Position = UDim2.new(0.8, 0, 0, 0)
    meLabel.BackgroundTransparency = 1
    meLabel.Font = Enum.Font.GothamBold
    meLabel.TextSize = 11
    meLabel.TextXAlignment = Enum.TextXAlignment.Right
    meLabel.TextColor3 = Color3.fromRGB(120, 130, 170)
    meLabel.Text = (plr == player) and "YOU" or ""
    meLabel.Parent = row

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if highlightedRow and highlightedRow ~= row then
                setRowHighlight(highlightedRow, false)
            end
            highlightedRow = row
            setRowHighlight(row, true)
        end
    end)

    row.MouseEnter:Connect(function()
        if row ~= highlightedRow then
            axaTween(row, 0.10, {BackgroundColor3 = Color3.fromRGB(234, 238, 252)})
        end
    end)

    row.MouseLeave:Connect(function()
        if row ~= highlightedRow then
            setRowHighlight(row, false)
        end
    end)

    rowMap[plr] = row
end

local function rebuildPlayerList()
    for _, row in pairs(rowMap) do
        if row then row:Destroy() end
    end
    rowMap = {}

    local list = players:GetPlayers()
    table.sort(list, function(a, b)
        if a == player then
            return true
        elseif b == player then
            return false
        end
        return a.Name:lower() < b.Name:lower()
    end)

    for _, plr in ipairs(list) do
        buildRow(plr)
    end
end

players.PlayerAdded:Connect(function()
    rebuildPlayerList()
end)

players.PlayerRemoving:Connect(function(plr)
    local row = rowMap[plr]
    if row then
        row:Destroy()
        rowMap[plr] = nil
    end
end)

rebuildPlayerList()
refreshSummary()

--==========================================================
-- CARD 4: AFK MONITOR (DAFTAR PLAYER AFK)
--==========================================================
local AFK_THRESHOLD = 60 -- detik idle jadi AFK (silakan ubah)

local afkData = {}

local afkCard = makeCard(210)
makeSectionTitle(afkCard, "AFK Monitor")

makeSectionSub(
    afkCard,
    "Deteksi AFK client-side berdasarkan gerakan karakter dan arah jalan. AFK jika idle ≥ "
        .. tostring(AFK_THRESHOLD) .. " detik.",
    28
)

local afkHolder = Instance.new("Frame")
afkHolder.Name = "AFKHolder"
afkHolder.Size = UDim2.new(1, -16, 0, 150)
afkHolder.Position = UDim2.new(0, 8, 0, 60)
afkHolder.BackgroundColor3 = Color3.fromRGB(232, 235, 246)
afkHolder.BorderSizePixel = 0
afkHolder.Parent = afkCard

local afkCorner = Instance.new("UICorner")
afkCorner.CornerRadius = UDim.new(0, 10)
afkCorner.Parent = afkHolder

local afkStroke = Instance.new("UIStroke")
afkStroke.Thickness = 1
afkStroke.Color = Color3.fromRGB(200, 205, 225)
afkStroke.Transparency = 0.4
afkStroke.Parent = afkHolder

local afkScroll = Instance.new("ScrollingFrame")
afkScroll.Name = "AFKScroll"
afkScroll.Size = UDim2.new(1, -8, 1, -8)
afkScroll.Position = UDim2.new(0, 4, 0, 4)
afkScroll.BackgroundTransparency = 1
afkScroll.BorderSizePixel = 0
afkScroll.ScrollBarThickness = 4
afkScroll.ScrollingDirection = Enum.ScrollingDirection.Y
afkScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
afkScroll.Parent = afkHolder

local afkLayout = Instance.new("UIListLayout")
afkLayout.FillDirection = Enum.FillDirection.Vertical
afkLayout.SortOrder = Enum.SortOrder.LayoutOrder
afkLayout.Padding = UDim.new(0, 4)
afkLayout.Parent = afkScroll

afkLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    afkScroll.CanvasSize = UDim2.new(0, 0, 0, afkLayout.AbsoluteContentSize.Y + 6)
end)

local afkRows = {}

local function getOrCreateAfkRow(plr)
    local row = afkRows[plr]
    if row and row.Parent ~= afkScroll then
        row:Destroy()
        row = nil
    end
    if not row then
        row = Instance.new("Frame")
        row.Name = plr.Name
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(244, 246, 252)
        row.BorderSizePixel = 0
        row.Parent = afkScroll

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(0.45, -6, 1, 0)
        nameLabel.Position = UDim2.new(0, 6, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextColor3 = Color3.fromRGB(55, 60, 90)
        nameLabel.Text = string.format("%s (@%s)", plr.DisplayName or plr.Name, plr.Name)
        nameLabel.Parent = row

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.Size = UDim2.new(0.25, -6, 1, 0)
        statusLabel.Position = UDim2.new(0.45, 0, 0, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextSize = 11
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.TextColor3 = Color3.fromRGB(80, 120, 80)
        statusLabel.Text = "Active"
        statusLabel.Parent = row

        local idleLabel = Instance.new("TextLabel")
        idleLabel.Name = "Idle"
        idleLabel.Size = UDim2.new(0.3, -6, 1, 0)
        idleLabel.Position = UDim2.new(0.75, 0, 0, 0)
        idleLabel.BackgroundTransparency = 1
        idleLabel.Font = Enum.Font.Code
        idleLabel.TextSize = 11
        idleLabel.TextXAlignment = Enum.TextXAlignment.Right
        idleLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
        idleLabel.Text = "Idle: 0s"
        idleLabel.Parent = row

        afkRows[plr] = row
    end
    return row
end

local function updateAfkData()
    local now = tick()
    for _, plr in ipairs(players:GetPlayers()) do
        local info = afkData[plr]
        if not info then
            info = {
                lastPos      = nil,
                lastMoveTime = now,
                idleTime     = 0,
                isAfk        = false,
            }
            afkData[plr] = info
        end

        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not hrp or not hum or hum.Health <= 0 then
            info.lastPos      = nil
            info.lastMoveTime = now
            info.idleTime     = 0
            info.isAfk        = false
        else
            if not info.lastPos then
                info.lastPos = hrp.Position
                info.lastMoveTime = now
            end

            local moved = (hrp.Position - info.lastPos).Magnitude > 0.5
                or hum.MoveDirection.Magnitude > 0.01

            if moved then
                info.lastPos      = hrp.Position
                info.lastMoveTime = now
            end

            info.idleTime = now - info.lastMoveTime
            info.isAfk    = info.idleTime >= AFK_THRESHOLD
        end
    end

    -- bersihkan data player yang sudah leave
    for plr, _ in pairs(afkData) do
        if not plr.Parent then
            afkData[plr] = nil
        end
    end
end

local function refreshAfkList()
    local list = players:GetPlayers()

    table.sort(list, function(a, b)
        local da = afkData[a]
        local db = afkData[b]
        local aAfk = da and da.isAfk or false
        local bAfk = db and db.isAfk or false

        if aAfk ~= bAfk then
            return aAfk -- AFK duluan
        end
        return a.Name:lower() < b.Name:lower()
    end)

    local seen = {}

    for idx, plr in ipairs(list) do
        local info = afkData[plr]
        local row  = getOrCreateAfkRow(plr)
        row.LayoutOrder = idx
        row.Visible = true
        seen[row] = true

        local idleSec = info and info.idleTime or 0
        local isAfk   = info and info.isAfk or false

        local nameLabel   = row:FindFirstChild("Name")
        local statusLabel = row:FindFirstChild("Status")
        local idleLabel   = row:FindFirstChild("Idle")

        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = string.format("%s (@%s)", plr.DisplayName or plr.Name, plr.Name)
        end

        if statusLabel and statusLabel:IsA("TextLabel") then
            if isAfk then
                statusLabel.Text = "AFK"
                statusLabel.TextColor3 = Color3.fromRGB(190, 80, 80)
            else
                statusLabel.Text = "Active"
                statusLabel.TextColor3 = Color3.fromRGB(80, 120, 80)
            end
        end

        if idleLabel and idleLabel:IsA("TextLabel") then
            idleLabel.Text = "Idle: " .. formatIdle(idleSec)
        end

        if isAfk then
            row.BackgroundColor3 = Color3.fromRGB(252, 238, 238)
        else
            row.BackgroundColor3 = Color3.fromRGB(244, 246, 252)
        end
    end

    -- sembunyikan row yang tidak lagi ada playernya
    for plr, row in pairs(afkRows) do
        if row and not seen[row] then
            row.Visible = false
        end
    end
end

task.spawn(function()
    while afkCard.Parent do
        updateAfkData()
        refreshAfkList()
        task.wait(1)
    end
end)
