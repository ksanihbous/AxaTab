--==========================================================
--  AxaTab_Util_JumpRunKompas.lua (TAB 6)
--  Fitur:
--    - ShiftRun (hold Shift → lari + FOV melebar)
--    - Infinite Jump (space spam di udara)
--    - Kompas arah kamera (N / NE / E / ... + derajat)
--
--  Env dari CORE:
--    TAB_FRAME     -- frame putih konten TAB
--    LocalPlayer
--    Players
--    RunService
--    UserInputService
--    TweenService
--    Camera        -- (opsional, fallback ke workspace.CurrentCamera)
--    StarterGui    -- (opsional, buat notifikasi)
--==========================================================

local tabFrame      = TAB_FRAME
local player        = LocalPlayer
local players       = Players
local runService    = RunService
local userInput     = UserInputService
local tweenService  = TweenService
local starterGui    = StarterGui
local camera        = Camera or workspace.CurrentCamera

------------------------------------------------------------
-- HEADER UI
------------------------------------------------------------
local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextColor3 = Color3.fromRGB(40, 40, 60)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "⚙️ Utilitas: Jump / Run / Kompas"
header.Parent = tabFrame

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
sub.Text = "ShiftRun (hold Shift), Infinite Jump, dan Kompas arah kamera (N/NE/E/... + derajat)."
sub.Parent = tabFrame

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function safeNotify(title, text, dur)
    if not starterGui then return end
    pcall(function()
        starterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = dur or 5
        })
    end)
end

local function getHumanoid()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:FindFirstChildOfClass("Humanoid")
end

local humanoid = getHumanoid()
local normalSpeed = 16
local normalFOV   = (camera and camera.FieldOfView) or 70
local runSpeed    = 40
local runFOV      = 80

if humanoid then
    normalSpeed = humanoid.WalkSpeed
end

player.CharacterAdded:Connect(function(char)
    humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        normalSpeed = humanoid.WalkSpeed
    end
end)

------------------------------------------------------------
-- UI: LIST TOGGLE (kiri)
------------------------------------------------------------
local toggleList = Instance.new("Frame")
toggleList.Name = "ToggleList"
toggleList.Position = UDim2.new(0, 5, 0, 64)
toggleList.Size = UDim2.new(0.6, -10, 0, 120)
toggleList.BackgroundTransparency = 1
toggleList.Parent = tabFrame

local toggleLayout = Instance.new("UIListLayout")
toggleLayout.FillDirection = Enum.FillDirection.Vertical
toggleLayout.SortOrder = Enum.SortOrder.LayoutOrder
toggleLayout.Padding = UDim.new(0, 6)
toggleLayout.Parent = toggleList

local function createToggleRow(titleText, descText)
    local row = Instance.new("Frame")
    row.Name = titleText
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    row.BackgroundTransparency = 0.05
    row.BorderSizePixel = 0
    row.Parent = toggleList

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -90, 0, 18)
    title.Position = UDim2.new(0, 8, 0, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(50, 50, 80)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = titleText
    title.Parent = row

    local desc = Instance.new("TextLabel")
    desc.Name = "Desc"
    desc.Size = UDim2.new(1, -90, 0, 16)
    desc.Position = UDim2.new(0, 8, 0, 20)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextColor3 = Color3.fromRGB(110, 110, 140)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Text = descText or ""
    desc.Parent = row

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.new(0, 70, 0, 26)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = "OFF"
    btn.Parent = row

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 999)
    bc.Parent = btn

    return row, btn
end

------------------------------------------------------------
-- UI: KOMPAS (kanan atas)
------------------------------------------------------------
local compassFrame = Instance.new("Frame")
compassFrame.Name = "Compass"
compassFrame.Size = UDim2.new(0, 120, 0, 80)
compassFrame.AnchorPoint = Vector2.new(1, 0)
compassFrame.Position = UDim2.new(1, -8, 0, 64)
compassFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
compassFrame.BorderSizePixel = 0
compassFrame.Parent = tabFrame

local cfCorner = Instance.new("UICorner")
cfCorner.CornerRadius = UDim.new(0, 10)
cfCorner.Parent = compassFrame

local cfStroke = Instance.new("UIStroke")
cfStroke.Thickness = 1
cfStroke.Color = Color3.fromRGB(70, 80, 110)
cfStroke.Parent = compassFrame

local compassTitle = Instance.new("TextLabel")
compassTitle.Name = "Title"
compassTitle.Size = UDim2.new(1, -10, 0, 18)
compassTitle.Position = UDim2.new(0, 5, 0, 4)
compassTitle.BackgroundTransparency = 1
compassTitle.Font = Enum.Font.GothamBold
compassTitle.TextSize = 12
compassTitle.TextColor3 = Color3.fromRGB(180, 190, 230)
compassTitle.TextXAlignment = Enum.TextXAlignment.Center
compassTitle.Text = "🧭 Kompas"
compassTitle.Parent = compassFrame

local compassDir = Instance.new("TextLabel")
compassDir.Name = "Direction"
compassDir.Size = UDim2.new(1, -10, 0, 24)
compassDir.Position = UDim2.new(0, 5, 0, 26)
compassDir.BackgroundTransparency = 1
compassDir.Font = Enum.Font.GothamBold
compassDir.TextSize = 16
compassDir.TextColor3 = Color3.fromRGB(230, 235, 255)
compassDir.TextXAlignment = Enum.TextXAlignment.Center
compassDir.Text = "N (0°)"
compassDir.Parent = compassFrame

local compassHint = Instance.new("TextLabel")
compassHint.Name = "Hint"
compassHint.Size = UDim2.new(1, -10, 0, 18)
compassHint.Position = UDim2.new(0, 5, 0, 52)
compassHint.BackgroundTransparency = 1
compassHint.Font = Enum.Font.Gotham
compassHint.TextSize = 10
compassHint.TextColor3 = Color3.fromRGB(160, 170, 210)
compassHint.TextXAlignment = Enum.TextXAlignment.Center
compassHint.Text = "Arah kamera"
compassHint.Parent = compassFrame

------------------------------------------------------------
-- LOGIC: SHIFT RUN
------------------------------------------------------------
local sprintFeatureOn = false
local shiftHeld       = false

local function applySprintState()
    local hum = humanoid or getHumanoid()
    if not hum then return end

    if sprintFeatureOn and shiftHeld then
        hum.WalkSpeed = runSpeed
        if camera then
            camera.FieldOfView = runFOV
        end
    else
        hum.WalkSpeed = normalSpeed
        if camera then
            camera.FieldOfView = normalFOV
        end
    end
end

local function setSprintEnabled(state)
    sprintFeatureOn = state
    if not sprintFeatureOn then
        shiftHeld = false
        applySprintState()
    else
        applySprintState()
    end
end

local function isShift(input)
    return input.KeyCode == Enum.KeyCode.LeftShift
        or input.KeyCode == Enum.KeyCode.RightShift
end

userInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if isShift(input) then
        shiftHeld = true
        applySprintState()
    end
end)

userInput.InputEnded:Connect(function(input, gp)
    if isShift(input) then
        shiftHeld = false
        applySprintState()
    end
end)

------------------------------------------------------------
-- LOGIC: INFINITE JUMP
------------------------------------------------------------
local infiniteJumpOn = false
local jumpConn

local function setInfiniteJumpEnabled(state)
    infiniteJumpOn = state

    if infiniteJumpOn then
        if not jumpConn then
            jumpConn = userInput.JumpRequest:Connect(function()
                if not infiniteJumpOn then return end
                local hum = humanoid or getHumanoid()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    else
        if jumpConn then
            jumpConn:Disconnect()
            jumpConn = nil
        end
    end
end

------------------------------------------------------------
-- LOGIC: KOMPAS UPDATE
------------------------------------------------------------
local function angleToDir(angle)
    -- angle: 0 = N, 90 = E, 180 = S, 270 = W
    if angle >= 337.5 or angle < 22.5 then
        return "N"
    elseif angle < 67.5 then
        return "NE"
    elseif angle < 112.5 then
        return "E"
    elseif angle < 157.5 then
        return "SE"
    elseif angle < 202.5 then
        return "S"
    elseif angle < 247.5 then
        return "SW"
    elseif angle < 292.5 then
        return "W"
    else
        return "NW"
    end
end

runService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera or camera
    if not cam then return end

    local look = cam.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 1e-4 then
        return
    end

    flat = flat.Unit
    -- Hitung bearing: 0° = N, searah jarum jam
    local bearing = math.deg(math.atan2(-flat.X, -flat.Z))
    if bearing < 0 then
        bearing = bearing + 360
    end

    if compassDir then
        local dir = angleToDir(bearing)
        compassDir.Text = string.format("%s (%.0f°)", dir, bearing)
    end
end)

------------------------------------------------------------
-- BIND TOGGLE UI
------------------------------------------------------------
local function bindToggleButton(btn, defaultState, onChanged)
    local state = defaultState

    local function applyVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
            btn.Text             = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
            btn.Text             = "OFF"
        end
    end

    applyVisual()
    if onChanged then
        onChanged(state)
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        applyVisual()
        if onChanged then
            onChanged(state)
        end
    end)
end

-- Row 1: ShiftRun
local shiftRow, shiftBtn = createToggleRow(
    "ShiftRun",
    "Hold Shift → lari + FOV melebar."
)
bindToggleButton(shiftBtn, false, function(on)
    setSprintEnabled(on)
    if on then
        safeNotify("ShiftRun", "Hold Shift untuk lari cepat.", 4)
    end
end)

-- Row 2: Infinite Jump
local ijRow, ijBtn = createToggleRow(
    "Infinite Jump",
    "Spam lompat di udara (anti batas jump)."
)
bindToggleButton(ijBtn, false, function(on)
    setInfiniteJumpEnabled(on)
end)

------------------------------------------------------------
-- RESET / CLEANUP (opsional untuk dipanggil dari CORE)
------------------------------------------------------------
local function resetUtil()
    setSprintEnabled(false)
    setInfiniteJumpEnabled(false)

    local hum = humanoid or getHumanoid()
    if hum then
        hum.WalkSpeed = normalSpeed
    end
    local cam = workspace.CurrentCamera or camera
    if cam then
        cam.FieldOfView = normalFOV
    end
end

_G.AxaHub_Util_Reset = resetUtil