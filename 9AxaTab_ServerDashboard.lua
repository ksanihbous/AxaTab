--==========================================================
--  AxaTab_ServerDashboard.lua
--  Dipanggil via loadstring dari CORE AxaHub
--  Env yang tersedia (dari core):
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, Camera, StarterGui
--    AXA_TWEEN (optional)
--==========================================================

local frame       = TAB_FRAME      -- frame putih di dalam ContentHolder
local player      = LocalPlayer
local players     = Players
local runService  = RunService
local starterGui  = StarterGui or game:GetService("StarterGui")

local statsSvc    = game:GetService("Stats")
local tween       = AXA_TWEEN      -- kalau mau animasi ringan (opsional)

--==========================================================
--  HEADER
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
header.Text = "📡 Server Dashboard"
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
sub.Text = "Monitor info server: JobId, pemain, ping, FPS, dan jarak setiap pemain dari posisimu."
sub.Parent = frame

--==========================================================
--  UTILS
--==========================================================

local function safeNotify(title, text, duration)
    pcall(function()
        starterGui:SetCore("SendNotification", {
            Title   = title,
            Text    = text,
            Duration = duration or 2
        })
    end)
end

local function formatSeconds(sec)
    sec = math.max(0, math.floor(sec or 0 + 0.5))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

local function getPingMs()
    local ok, result = pcall(function()
        local network = statsSvc.Network
        local dataPingItem = network.ServerStatsItem["Data Ping"]
        if dataPingItem and dataPingItem.GetValue then
            local v = dataPingItem:GetValue()
            if type(v) == "number" then
                return v
            end
        end
        return nil
    end)
    if ok and result then
        return result
    end
    return nil
end

local function trySetClipboard(str)
    if not str or str == "" then return end
    pcall(function()
        setclipboard(str)
    end)
end

--==========================================================
--  KARTU INFO SERVER (ATAS)
--==========================================================

local infoCard = Instance.new("Frame")
infoCard.Name = "InfoCard"
infoCard.Size = UDim2.new(1, -12, 0, 130)
infoCard.Position = UDim2.new(0, 6, 0, 60)
infoCard.BackgroundColor3 = Color3.fromRGB(235, 238, 252)
infoCard.BorderSizePixel = 0
infoCard.Parent = frame

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = infoCard

local infoStroke = Instance.new("UIStroke")
infoStroke.Thickness = 1
infoStroke.Color = Color3.fromRGB(200, 205, 230)
infoStroke.Transparency = 0.3
infoStroke.Parent = infoCard

local infoTitle = Instance.new("TextLabel")
infoTitle.Name = "InfoTitle"
infoTitle.Size = UDim2.new(1, -10, 0, 20)
infoTitle.Position = UDim2.new(0, 6, 0, 6)
infoTitle.BackgroundTransparency = 1
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextSize = 13
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.TextColor3 = Color3.fromRGB(50, 50, 80)
infoTitle.Text = "Ringkasan Server"
infoTitle.Parent = infoCard

-- helper buat row kecil di dalam infoCard
local function makeStatRow(offsetY, labelText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 18)
    row.Position = UDim2.new(0, 6, 0, offsetY)
    row.BackgroundTransparency = 1
    row.Parent = infoCard

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.40, -4, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(90, 90, 125)
    label.Text = labelText
    label.Parent = row

    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0.60, 0, 1, 0)
    value.Position = UDim2.new(0.40, 0, 0, 0)
    value.BackgroundTransparency = 1
    value.Font = Enum.Font.Code
    value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.TextColor3 = Color3.fromRGB(40, 40, 80)
    value.Text = "-"
    value.Parent = row

    return value
end

local jobIdValue     = makeStatRow(32,  "JobId")
local placeIdValue   = makeStatRow(52,  "PlaceId")
local playersValue   = makeStatRow(72,  "Players")
local pingValue      = makeStatRow(92,  "Ping")
local fpsValue       = makeStatRow(112, "FPS / Uptime")

-- Tombol kecil copy JobId & PlaceId
local copyJobBtn = Instance.new("TextButton")
copyJobBtn.Name = "CopyJobBtn"
copyJobBtn.Size = UDim2.new(0, 90, 0, 22)
copyJobBtn.Position = UDim2.new(1, -96, 0, 6)
copyJobBtn.BackgroundColor3 = Color3.fromRGB(210, 220, 255)
copyJobBtn.AutoButtonColor = true
copyJobBtn.Font = Enum.Font.GothamBold
copyJobBtn.TextSize = 11
copyJobBtn.TextColor3 = Color3.fromRGB(40, 60, 110)
copyJobBtn.Text = "Copy JobId"
copyJobBtn.Parent = infoCard

local cjCorner = Instance.new("UICorner")
cjCorner.CornerRadius = UDim.new(0, 8)
cjCorner.Parent = copyJobBtn

local copyPlaceBtn = Instance.new("TextButton")
copyPlaceBtn.Name = "CopyPlaceBtn"
copyPlaceBtn.Size = UDim2.new(0, 90, 0, 22)
copyPlaceBtn.Position = UDim2.new(1, -96, 0, 30)
copyPlaceBtn.BackgroundColor3 = Color3.fromRGB(225, 230, 255)
copyPlaceBtn.AutoButtonColor = true
copyPlaceBtn.Font = Enum.Font.GothamBold
copyPlaceBtn.TextSize = 11
copyPlaceBtn.TextColor3 = Color3.fromRGB(40, 60, 110)
copyPlaceBtn.Text = "Copy PlaceId"
copyPlaceBtn.Parent = infoCard

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, 8)
cpCorner.Parent = copyPlaceBtn

copyJobBtn.MouseButton1Click:Connect(function()
    local jid = game.JobId or ""
    if jid == "" then
        safeNotify("Server Dashboard", "JobId tidak tersedia.", 2)
        return
    end
    trySetClipboard(jid)
    safeNotify("Server Dashboard", "JobId disalin ke clipboard.", 1.5)
end)

copyPlaceBtn.MouseButton1Click:Connect(function()
    local pid = tostring(game.PlaceId or "")
    if pid == "" then
        safeNotify("Server Dashboard", "PlaceId tidak tersedia.", 2)
        return
    end
    trySetClipboard(pid)
    safeNotify("Server Dashboard", "PlaceId disalin ke clipboard.", 1.5)
end)

--==========================================================
--  LIST PLAYER DI SERVER
--==========================================================

local playersLabel = Instance.new("TextLabel")
playersLabel.Name = "PlayersLabel"
playersLabel.Size = UDim2.new(1, -10, 0, 20)
playersLabel.Position = UDim2.new(0, 5, 0, 196)
playersLabel.BackgroundTransparency = 1
playersLabel.Font = Enum.Font.GothamBold
playersLabel.TextSize = 13
playersLabel.TextXAlignment = Enum.TextXAlignment.Left
playersLabel.TextColor3 = Color3.fromRGB(50, 50, 80)
playersLabel.Text = "Pemain di Server"
playersLabel.Parent = frame

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Position = UDim2.new(0, 6, 0, 220)
playerList.Size = UDim2.new(1, -12, 1, -226)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 5
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.Parent = frame

local playerLayout = Instance.new("UIListLayout")
playerLayout.FillDirection = Enum.FillDirection.Vertical
playerLayout.SortOrder = Enum.SortOrder.Name
playerLayout.Padding = UDim.new(0, 4)
playerLayout.Parent = playerList

playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerList.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 6)
end)

local playerRows = {}  -- [Player] = { distanceLabel = ..., statusLabel = ..., row = ... }

local STUDS_TO_METERS = 1

local function buildPlayerRow(plr)
    local row = Instance.new("Frame")
    row.Name = plr.Name
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(230, 232, 246)
    row.BackgroundTransparency = 0.1
    row.BorderSizePixel = 0
    row.Parent = playerList

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local rs = Instance.new("UIStroke")
    rs.Thickness = 1
    rs.Color = Color3.fromRGB(200, 200, 220)
    rs.Transparency = 0.3
    rs.Parent = row

    if plr == player then
        row.BackgroundColor3 = Color3.fromRGB(210, 230, 255)
        rs.Color             = Color3.fromRGB(120, 160, 235)
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(0.45, -6, 1, 0)
    nameLabel.Position = UDim2.new(0, 6, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(50, 50, 80)
    nameLabel.Text = string.format("%s (@%s)", plr.DisplayName or plr.Name, plr.Name)
    nameLabel.Parent = row

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0.18, 0, 1, 0)
    statusLabel.Position = UDim2.new(0.45, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextColor3 = Color3.fromRGB(90, 90, 120)
    statusLabel.Text = "Player"
    statusLabel.Parent = row

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(0.37, -6, 1, 0)
    distanceLabel.Position = UDim2.new(0.63, 0, 0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Font = Enum.Font.Code
    distanceLabel.TextSize = 11
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
    distanceLabel.TextColor3 = Color3.fromRGB(50, 70, 100)
    distanceLabel.Text = "-- m"
    distanceLabel.Parent = row

    playerRows[plr] = {
        row          = row,
        statusLabel  = statusLabel,
        distanceLabel = distanceLabel,
    }

    -- Set status friend / player
    local isFriend = false
    pcall(function()
        isFriend = player:IsFriendsWith(plr.UserId)
    end)
    if plr == player then
        statusLabel.Text = "Kamu"
        statusLabel.TextColor3 = Color3.fromRGB(70, 120, 200)
    elseif isFriend then
        statusLabel.Text = "Friend"
        statusLabel.TextColor3 = Color3.fromRGB(60, 150, 100)
    else
        statusLabel.Text = "Player"
        statusLabel.TextColor3 = Color3.fromRGB(90, 90, 120)
    end
end

local function rebuildPlayerList()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    playerRows = {}

    local listPlayers = players:GetPlayers()
    table.sort(listPlayers, function(a, b)
        local aSelf = (a == player)
        local bSelf = (b == player)
        if aSelf ~= bSelf then
            return aSelf -- local player di atas
        end
        return (a.DisplayName or a.Name) < (b.DisplayName or b.Name)
    end)

    for _, plr in ipairs(listPlayers) do
        buildPlayerRow(plr)
    end
end

players.PlayerAdded:Connect(function(plr)
    buildPlayerRow(plr)
end)

players.PlayerRemoving:Connect(function(plr)
    local rowInfo = playerRows[plr]
    if rowInfo and rowInfo.row then
        rowInfo.row:Destroy()
    end
    playerRows[plr] = nil
end)

rebuildPlayerList()

--==========================================================
--  UPDATE LOOP (FPS, PING, UPTIME, JARAK, DLL)
--==========================================================

-- Set nilai stat yang sifatnya statis / jarang berubah
jobIdValue.Text   = game.JobId ~= "" and game.JobId or "(non-standard server)"
placeIdValue.Text = tostring(game.PlaceId)

local function updatePlayersCount()
    local count = #players:GetPlayers()
    local max   = players.MaxPlayers or "?"
    playersValue.Text = string.format("%d / %s", count, tostring(max))
end

updatePlayersCount()
players.PlayerAdded:Connect(updatePlayersCount)
players.PlayerRemoving:Connect(updatePlayersCount)

-- FPS + ping + uptime diupdate berkala
local accumTime   = 0
local frameCount  = 0
local currentFPS  = 0

runService.RenderStepped:Connect(function(dt)
    -- Hitung FPS approx
    frameCount += 1
    accumTime  += dt
    if accumTime >= 0.5 then
        currentFPS = math.floor((frameCount / accumTime) + 0.5)
        frameCount = 0
        accumTime  = 0
    end

    -- Ping
    local pingMs = getPingMs()
    if pingMs then
        pingValue.Text = string.format("%.0f ms", pingMs)
    else
        pingValue.Text = "-- ms"
    end

    -- Uptime (pakai DistributedGameTime)
    local uptimeSec = workspace.DistributedGameTime
    fpsValue.Text = string.format("%d FPS  •  %s", currentFPS, formatSeconds(uptimeSec))

    -- Update jarak setiap player
    local myChar = player.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for plr, info in pairs(playerRows) do
        if plr ~= player then
            local char = plr.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and hrp then
                local distStuds = (hrp.Position - myHRP.Position).Magnitude
                local meters    = math.floor(distStuds * STUDS_TO_METERS + 0.5)
                info.distanceLabel.Text = string.format("%d m", meters)
            else
                info.distanceLabel.Text = "-- m"
            end
        else
            info.distanceLabel.Text = "0 m"
        end
    end
end)