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
sub.Text = "Monitor info server, performa client, pemain online, dan utilitas (rejoin, server hop, copy ID) dalam satu panel."
sub.Parent = frame

--==========================================================
-- BODY SCROLL (SEGALA KONTEN DI SINI, BISA SCROLL KE BAWAH)
--==========================================================
local bodyScroll = frame:FindFirstChild("BodyScroll")
if not bodyScroll or not bodyScroll:IsA("ScrollingFrame") then
    bodyScroll = Instance.new("ScrollingFrame")
    bodyScroll.Name = "BodyScroll"
    bodyScroll.Position = UDim2.new(0, 0, 0, 64)          -- di bawah header+sub
    bodyScroll.Size = UDim2.new(1, 0, 1, -64)
    bodyScroll.BackgroundTransparency = 1
    bodyScroll.BorderSizePixel = 0
    bodyScroll.ScrollBarThickness = 6                      -- lebih jelas
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

local startTime = tick()
local smoothFPS = 60

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
--==========================================================
local actionCard = makeCard(90)
makeSectionTitle(actionCard, "Utilitas Server")

local btnHolder = Instance.new("Frame")
btnHolder.Name = "ButtonHolder"
btnHolder.Size = UDim2.new(1, -16, 0, 40)
btnHolder.Position = UDim2.new(0, 8, 0, 34)
btnHolder.BackgroundTransparency = 1
btnHolder.Parent = actionCard

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Padding = UDim.new(0, 6)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
btnLayout.Parent = btnHolder

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
    b.Parent = btnHolder

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
