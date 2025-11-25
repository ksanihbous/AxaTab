--==========================================================
--  AxaTab_Spectate.lua
--  Dipanggil via loadstring dari CORE AxaHub
--  Env yang tersedia (dari core):
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, Camera
--==========================================================

local frame       = TAB_FRAME      -- frame putih di dalam ContentHolder
local player      = LocalPlayer
local players     = Players
local runService  = RunService
local camera      = Camera

-- HEADER
local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextColor3 = Color3.fromRGB(40, 40, 60)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "🎥 Spectate + ESP"
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
sub.Text = "Pilih player, nyalakan ESP (dengan jarak meter), spectate kamera, atau teleport ke target."
sub.Parent = frame

-- Search box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.PlaceholderText = "Search player..."
searchBox.Size = UDim2.new(1, -12, 0, 24)
searchBox.Position = UDim2.new(0, 6, 0, 60)
searchBox.BackgroundColor3 = Color3.fromRGB(230, 230, 245)
searchBox.TextColor3 = Color3.fromRGB(40, 40, 60)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.Parent = frame

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 8)
sbCorner.Parent = searchBox

-- List player
local list = Instance.new("ScrollingFrame")
list.Name = "PlayerList"
list.Position = UDim2.new(0, 6, 0, 88)
list.Size = UDim2.new(1, -12, 1, -130)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.Name
layout.Padding = UDim.new(0, 4)
layout.Parent = list

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
end)

-- Top bar (status + tombol)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, -12, 0, 28)
topBar.Position = UDim2.new(0, 6, 1, -34)
topBar.BackgroundTransparency = 1
topBar.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -220, 1, 0)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(70, 70, 100)
statusLabel.Text = "Status: Idle"
statusLabel.Parent = topBar

local stopBtn = Instance.new("TextButton")
stopBtn.Name = "StopSpectateButton"
stopBtn.Size = UDim2.new(0, 100, 1, 0)
stopBtn.Position = UDim2.new(1, -210, 0, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Text = "Stop Spectate"
stopBtn.Parent = topBar

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopBtn

local espAllBtn = Instance.new("TextButton")
espAllBtn.Name = "ESPAllButton"
espAllBtn.Size = UDim2.new(0, 100, 1, 0)
espAllBtn.Position = UDim2.new(1, -104, 0, 0)
espAllBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
espAllBtn.Font = Enum.Font.GothamBold
espAllBtn.TextSize = 13
espAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
espAllBtn.Text = "ESP ALL: OFF"
espAllBtn.Parent = topBar

local espAllCorner = Instance.new("UICorner")
espAllCorner.CornerRadius = UDim.new(0, 8)
espAllCorner.Parent = espAllBtn

--===================== LOGIC =====================--
local currentSpectateTarget = nil
local spectateLock          = false
local activeESP             = {}
local espAllOn              = false
local STUDS_TO_METERS       = 1

local function setSpectateStatus(text)
    statusLabel.Text = "Status: " .. text
end

local function stopSpectate()
    spectateLock          = true
    currentSpectateTarget = nil

    local char = player.Character or player.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraSubject = hum
        workspace.CurrentCamera.CameraType    = Enum.CameraType.Custom
    end

    spectateLock = false
    setSpectateStatus("Idle")
end

local function setESPOnTarget(plr, enabled)
    if not plr then return end

    local char = plr.Character
    if not char then
        activeESP[plr] = enabled or nil
        return
    end

    local hl   = char:FindFirstChild("AxaESPHighlight")
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char
    local bb   = head and head:FindFirstChild("AxaESPDistGui") or nil

    if enabled then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "AxaESPHighlight"
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillColor = Color3.fromRGB(90, 180, 255)
            hl.FillTransparency = 0.7
            hl.OutlineColor = Color3.fromRGB(40, 130, 255)
            hl.OutlineTransparency = 0.1
            hl.Parent = char
        end

        if head and not bb then
            bb = Instance.new("BillboardGui")
            bb.Name = "AxaESPDistGui"
            bb.Size = UDim2.new(0, 260, 0, 26)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = 2000
            bb.Parent = head

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            label.BackgroundTransparency = 0.35
            label.BorderSizePixel = 0
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.4
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Text = ""
            label.ZIndex = 2
            label.Parent = bb

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = label
        end

        activeESP[plr] = true
    else
        if hl then hl:Destroy() end
        if head and bb then bb:Destroy() end
        activeESP[plr] = nil
    end
end

local function teleportToPlayer(target)
    if not target then return end

    local tChar = target.Character
    local char  = player.Character or player.CharacterAdded:Wait()
    local hrp   = char:FindFirstChild("HumanoidRootPart")
    local thrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")

    if hrp and thrp then
        hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -3)
    end
end

-- Filter & row
local rows = {}

local function matchesSearch(plr)
    local q = string.lower(searchBox.Text or "")
    if q == "" then return true end
    local dn = string.lower(plr.DisplayName or plr.Name)
    local un = string.lower(plr.Name)
    return dn:find(q, 1, true) or un:find(q, 1, true)
end

local function applySearchFilter()
    for plr, row in pairs(rows) do
        local match = matchesSearch(plr)
        row.Visible = match
        if match then
            row.Size = UDim2.new(1, 0, 0, 40)
        else
            row.Size = UDim2.new(1, 0, 0, 0)
        end
    end
end

local function buildRow(plr)
    local row = Instance.new("Frame")
    row.Name = plr.Name
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(230, 230, 244)
    row.BackgroundTransparency = 0.1
    row.BorderSizePixel = 0
    row.Parent = list

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local rs = Instance.new("UIStroke")
    rs.Thickness = 1
    rs.Color = Color3.fromRGB(200, 200, 220)
    rs.Parent = row

    if plr == player then
        row.BackgroundColor3 = Color3.fromRGB(210, 230, 255)
        rs.Color             = Color3.fromRGB(120, 160, 235)
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(0.38, -6, 1, 0)
    nameLabel.Position = UDim2.new(0, 6, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(50, 50, 75)
    nameLabel.Text = string.format("%s (@%s)", plr.DisplayName or plr.Name, plr.Name)
    nameLabel.Parent = row

    local espBtn = Instance.new("TextButton")
    espBtn.Name = "ESPBtn"
    espBtn.Size = UDim2.new(0, 52, 0, 24)
    espBtn.Position = UDim2.new(0.40, 0, 0.5, -12)
    espBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
    espBtn.Font = Enum.Font.GothamBold
    espBtn.TextSize = 12
    espBtn.TextColor3 = Color3.fromRGB(60, 60, 90)
    espBtn.Text = "ESP"
    espBtn.Parent = row

    local ec = Instance.new("UICorner")
    ec.CornerRadius = UDim.new(0, 8)
    ec.Parent = espBtn

    local spectateBtn = Instance.new("TextButton")
    spectateBtn.Name = "SpectateBtn"
    spectateBtn.Size = UDim2.new(0, 62, 0, 24)
    spectateBtn.Position = UDim2.new(0.40, 56, 0.5, -12)
    spectateBtn.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    spectateBtn.Font = Enum.Font.GothamBold
    spectateBtn.TextSize = 12
    spectateBtn.TextColor3 = Color3.fromRGB(40, 60, 110)
    spectateBtn.Text = "Spectate"
    spectateBtn.Parent = row

    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 8)
    sc.Parent = spectateBtn

    local tpBtn = Instance.new("TextButton")
    tpBtn.Name = "TPBtn"
    tpBtn.Size = UDim2.new(0, 52, 0, 24)
    tpBtn.Position = UDim2.new(0.40, 124, 0.5, -12)
    tpBtn.BackgroundColor3 = Color3.fromRGB(210, 240, 220)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 12
    tpBtn.TextColor3 = Color3.fromRGB(40, 90, 60)
    tpBtn.Text = "TP"
    tpBtn.Parent = row

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = tpBtn

    espBtn.MouseButton1Click:Connect(function()
        local newState = not activeESP[plr]
        setESPOnTarget(plr, newState)
        if newState then
            espBtn.Text = "ESP ON"
            espBtn.BackgroundColor3 = Color3.fromRGB(130, 190, 255)
        else
            espBtn.Text = "ESP"
            espBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
        end
    end)

    spectateBtn.MouseButton1Click:Connect(function()
        if spectateLock then return end
        currentSpectateTarget = plr
        setSpectateStatus("Spectate → " .. (plr.DisplayName or plr.Name))
    end)

    tpBtn.MouseButton1Click:Connect(function()
        teleportToPlayer(plr)
    end)

    rows[plr] = row
end

local function rebuildList()
    for _, plr in ipairs(players:GetPlayers()) do
        if not rows[plr] then
            buildRow(plr)
        end
    end
    applySearchFilter()
end

searchBox:GetPropertyChangedSignal("Text"):Connect(applySearchFilter)

players.PlayerAdded:Connect(function(plr)
    buildRow(plr)
    applySearchFilter()
end)

players.PlayerRemoving:Connect(function(plr)
    local row = rows[plr]
    if row then
        row:Destroy()
        rows[plr] = nil
    end
    setESPOnTarget(plr, false)
end)

stopBtn.MouseButton1Click:Connect(function()
    stopSpectate()
end)

espAllBtn.MouseButton1Click:Connect(function()
    espAllOn = not espAllOn
    espAllBtn.Text = espAllOn and "ESP ALL: ON" or "ESP ALL: OFF"
    espAllBtn.BackgroundColor3 = espAllOn and Color3.fromRGB(110, 150, 255) or Color3.fromRGB(80, 80, 120)

    for plr, _ in pairs(rows) do
        if plr ~= player then
            setESPOnTarget(plr, espAllOn)
        end
    end
end)

-- Kamera + jarak
runService.RenderStepped:Connect(function()
    if currentSpectateTarget and not spectateLock then
        local cam  = workspace.CurrentCamera
        local char = currentSpectateTarget.Character
        if cam and char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                cam.CameraType = Enum.CameraType.Scriptable
                local offset   = hrp.CFrame.LookVector * -8 + Vector3.new(0, 4, 0)
                cam.CFrame     = CFrame.new(hrp.Position + offset, hrp.Position)
            end
        end
    end

    local myChar = player.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    for plr, _ in pairs(activeESP) do
        local char = plr.Character
        if char then
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head") or hrp
            if hrp and head then
                local gui = head:FindFirstChild("AxaESPDistGui")
                if gui then
                    local label = gui:FindFirstChild("Text")
                    if label and label:IsA("TextLabel") then
                        local distStuds = (hrp.Position - myHRP.Position).Magnitude
                        local meters = math.floor(distStuds * STUDS_TO_METERS + 0.5)
                        label.Text = string.format(
                            "%s | @%s | %d meter",
                            plr.DisplayName or plr.Name,
                            plr.Name,
                            meters
                        )
                    end
                end
            end
        end
    end
end)

rebuildList()
setSpectateStatus("Idle")
