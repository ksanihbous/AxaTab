--==========================================================
--  AxaTab_Util_JumpRunKompas.lua
--  Fokus: ShiftRun + Infinite Jump + Kompas HUD (Top/Bottom)
--  Env dari core:
--      TAB_FRAME = Frame konten tab Util (sudah dibuat di core AxaHub)
--==========================================================

------------------- SERVICES / ENV -------------------
local TAB_FRAME = TAB_FRAME  -- dari core AxaHub

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui           = game:GetService("StarterGui")
local Debris               = game:GetService("Debris")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local GuiService           = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

------------------------------------------------------
-- HELPER UI: Row Toggle (☐ / ☑)
------------------------------------------------------
local function createToggleRow(parent, orderName, labelText, defaultState)
    local row = Instance.new("Frame")
    row.Name = orderName
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    row.BackgroundTransparency = 0.1
    row.BorderSizePixel = 0
    row.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local checkBtn = Instance.new("TextButton")
    checkBtn.Name = "Check"
    checkBtn.Size = UDim2.new(0, 28, 1, -6)
    checkBtn.Position = UDim2.new(0, 6, 0, 3)
    checkBtn.BackgroundColor3 = Color3.fromRGB(210, 210, 230)
    checkBtn.TextColor3 = Color3.fromRGB(50, 50, 80)
    checkBtn.Font = Enum.Font.Gotham
    checkBtn.TextSize = 18
    checkBtn.Text = defaultState and "☑" or "☐"
    checkBtn.Parent = row
    Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 40, 0, 0)
    label.Size = UDim2.new(1, -45, 1, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(40, 40, 70)
    label.Text = labelText
    label.Parent = row

    local state = not not defaultState
    local callback

    local function applyVisual()
        checkBtn.Text = state and "☑" or "☐"
        checkBtn.BackgroundColor3 = state and Color3.fromRGB(140, 190, 255) or Color3.fromRGB(210, 210, 230)
    end

    local function setState(newState)
        state = not not newState
        applyVisual()
        if callback then task.spawn(callback, state) end
    end

    checkBtn.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.Parent = row
    hit.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    applyVisual()

    return {
        Frame = row,
        Set = setState,
        OnChanged = function(cb) callback = cb end,
        Get = function() return state end,
    }
end

------------------------------------------------------
-- SAFE CHAR PARTS + POSISI
------------------------------------------------------
local function safeCharParts(character)
    if not character then return end
    local hrp  = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not (hrp and head) then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    return hrp, head, hum
end

local function getCharPosition(char: Model?)
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp.Position end
    if char.PrimaryPart then return char.PrimaryPart.Position end
    local ok, cframe = pcall(function() return char:GetPivot() end)
    if ok and typeof(cframe) == "CFrame" then return cframe.Position end
    return nil
end

------------------------------------------------------
-- SHIFT RUN (mengikuti mesin referensi kamu)
------------------------------------------------------
local SR_AnimationID = 10862419793
local SR_RunningSpeed = 40
local SR_NormalSpeed  = 20
local SR_RunFOV       = 80
local SR_NormalFOV    = 70
local SR_KeyString    = "LeftShift"
local SR_ACTION_NAME  = "RunBind"

local SR_sprintEnabled = false
local SR_Running       = false
local SR_Humanoid      = nil
local SR_RAnimation    = nil
local SR_TweenRun      = nil
local SR_TweenWalk     = nil
local SR_HeartbeatConn = nil

local function SR_ensureTweens()
    local inInfo  = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local outInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    SR_TweenRun  = TweenService:Create(camera, inInfo,  { FieldOfView = SR_RunFOV })
    SR_TweenWalk = TweenService:Create(camera, outInfo, { FieldOfView = SR_NormalFOV })
end

local function SR_applyWalk()
    if SR_Humanoid then SR_Humanoid.WalkSpeed = SR_NormalSpeed end
    if SR_RAnimation and SR_RAnimation.IsPlaying then pcall(function() SR_RAnimation:Stop() end) end
    if SR_TweenWalk then SR_TweenWalk:Play() else camera.FieldOfView = SR_NormalFOV end
end

local function SR_applyRun()
    if SR_Humanoid then SR_Humanoid.WalkSpeed = SR_RunningSpeed end
    if SR_RAnimation and not SR_RAnimation.IsPlaying then pcall(function() SR_RAnimation:Play() end) end
    if SR_TweenRun then SR_TweenRun:Play() else camera.FieldOfView = SR_RunFOV end
end

local function SR_setSprintEnabled(newVal)
    SR_sprintEnabled = newVal and true or false
    if not SR_Humanoid then return end
    if not SR_sprintEnabled then
        SR_Running = false
        SR_applyWalk()
    else
        local keyEnum = Enum.KeyCode[SR_KeyString] or Enum.KeyCode.LeftShift
        local holding = UserInputService:IsKeyDown(keyEnum)
        if holding and SR_Humanoid.MoveDirection.Magnitude > 0 then
            SR_Running = true; SR_applyRun()
        else
            SR_Running = false; SR_applyWalk()
        end
    end
end

local function SR_bindShiftAction()
    local keyEnum = Enum.KeyCode[SR_KeyString] or Enum.KeyCode.LeftShift
    pcall(function() ContextActionService:UnbindAction(SR_ACTION_NAME) end)
    ContextActionService:BindAction(SR_ACTION_NAME, function(BindName, InputState)
        if BindName ~= SR_ACTION_NAME then return end
        if InputState == Enum.UserInputState.Begin then
            SR_Running = true
        elseif InputState == Enum.UserInputState.End then
            SR_Running = false
        end
        if not SR_sprintEnabled then
            SR_applyWalk()
            return
        end
        if SR_Running then
            SR_applyRun()
        else
            SR_applyWalk()
        end
    end, true, keyEnum)
end

local function SR_startHeartbeatEnforcement()
    if SR_HeartbeatConn then SR_HeartbeatConn:Disconnect(); SR_HeartbeatConn = nil end
    SR_HeartbeatConn = RunService.Heartbeat:Connect(function()
        if not SR_Humanoid then return end
        if not SR_sprintEnabled then
            if SR_Humanoid.WalkSpeed ~= SR_NormalSpeed
               or (SR_RAnimation and SR_RAnimation.IsPlaying)
               or camera.FieldOfView ~= SR_NormalFOV then
                SR_applyWalk()
            end
        else
            if SR_Running then
                if SR_Humanoid.WalkSpeed ~= SR_RunningSpeed
                   or (SR_RAnimation and not SR_RAnimation.IsPlaying)
                   or camera.FieldOfView ~= SR_RunFOV then
                    SR_applyRun()
                end
            else
                if SR_Humanoid.WalkSpeed ~= SR_NormalSpeed
                   or (SR_RAnimation and SR_RAnimation.IsPlaying)
                   or camera.FieldOfView ~= SR_NormalFOV then
                    SR_applyWalk()
                end
            end
        end
    end)
end

local function SR_attachCharacter(char)
    SR_Humanoid = char:WaitForChild("Humanoid", 5)
    if not SR_Humanoid then return end
    local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. SR_AnimationID
    local ok, track = pcall(function() return SR_Humanoid:LoadAnimation(anim) end)
    if ok then SR_RAnimation = track end
    SR_ensureTweens()
    camera.FieldOfView    = SR_NormalFOV
    SR_Humanoid.WalkSpeed = SR_NormalSpeed
    SR_Humanoid.Running:Connect(function(Speed)
        if not SR_sprintEnabled then SR_applyWalk(); return end
        if Speed >= 10 and SR_Running and SR_RAnimation and not SR_RAnimation.IsPlaying then
            SR_applyRun()
        elseif Speed >= 10 and (not SR_Running) and SR_RAnimation and SR_RAnimation.IsPlaying then
            SR_applyWalk()
        elseif Speed < 10 and SR_RAnimation and SR_RAnimation.IsPlaying then
            SR_applyWalk()
        end
    end)
    SR_Humanoid.Changed:Connect(function()
        if SR_Humanoid.Jump and SR_RAnimation and SR_RAnimation.IsPlaying then
            pcall(function() SR_RAnimation:Stop() end)
        end
    end)
    SR_bindShiftAction()
    SR_startHeartbeatEnforcement()
    SR_setSprintEnabled(SR_sprintEnabled)
end

if LocalPlayer.Character then SR_attachCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SR_attachCharacter)

------------------------------------------------------
-- INFINITE JUMP (sesuai scriptmu, dibungkus toggle)
------------------------------------------------------
local IJ_Settings = {
    ExtraJumps          = 5,
    WhiteList           = {},
    EnableAirStepVFX    = true,
    AirStepLife         = 0.5,
    AirStepSize         = Vector3.new(2.5, 0.35, 2.5),
    AirStepTransparency = 0.25,
    AirStepMaterial     = Enum.Material.Neon,
}

local IJ_Enabled   = false
local IJ_Humanoid  = nil
local IJ_Root      = nil
local IJ_JumpsDone = 0
local IJ_Grounded  = false
local IJ_AirTimer  = 0

local function IJ_isWhitelisted(p: Player): boolean
    local wl = IJ_Settings.WhiteList
    if wl and #wl > 0 then
        for _, id in ipairs(wl) do
            if id == p.UserId then return true end
        end
        return false
    end
    return true
end

local JumpPlatformTemplate = ReplicatedStorage:FindFirstChild("JumpPlatform")

local function IJ_spawnAirStepVFX(pos: Vector3)
    if not IJ_Settings.EnableAirStepVFX then return end
    if JumpPlatformTemplate then
        local obj = JumpPlatformTemplate:Clone()
        obj.Name = "DJ_Pivot"; obj.Parent = workspace

        if obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
            obj.CFrame = CFrame.new(pos)
        else
            if obj.PrimaryPart then
                obj:SetPrimaryPartCFrame(CFrame.new(pos))
            else
                obj:PivotTo(CFrame.new(pos))
            end
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = true
                    d.CanCollide = false
                end
            end
        end

        Debris:AddItem(obj, IJ_Settings.AirStepLife)
    else
        local p = Instance.new("Part")
        p.Name = "AirStep"
        p.Anchored = true
        p.CanCollide = false
        p.Size = IJ_Settings.AirStepSize
        p.Material = IJ_Settings.AirStepMaterial
        p.Color = Color3.new(1, 1, 1)
        p.Transparency = IJ_Settings.AirStepTransparency
        p.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad((tick()*180)%360), 0)
        p.Parent = workspace
        Debris:AddItem(p, IJ_Settings.AirStepLife)
    end
end

local function IJ_bindCharacter(char: Model)
    IJ_Humanoid = char:WaitForChild("Humanoid") :: Humanoid
    IJ_Root     = char:WaitForChild("HumanoidRootPart") :: BasePart
    IJ_JumpsDone = 0
    IJ_Grounded  = false

    IJ_Humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed
        or newState == Enum.HumanoidStateType.Running
        or newState == Enum.HumanoidStateType.RunningNoPhysics
        or newState == Enum.HumanoidStateType.Swimming then
            IJ_JumpsDone = 0
            IJ_Grounded  = true
        elseif newState == Enum.HumanoidStateType.Freefall then
            IJ_Grounded = false
        end
    end)
end

if LocalPlayer.Character then IJ_bindCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(IJ_bindCharacter)

UserInputService.JumpRequest:Connect(function()
    if not IJ_Enabled then return end
    if not IJ_Humanoid or IJ_Humanoid.Health <= 0 then return end
    if not IJ_isWhitelisted(LocalPlayer) then return end

    if IJ_Grounded then return end

    if IJ_JumpsDone < (IJ_Settings.ExtraJumps or 0) then
        IJ_JumpsDone += 1
        local v = IJ_Root.Velocity
        local upward = math.max(50, IJ_Humanoid.JumpPower * 1.15)
        IJ_Root.Velocity = Vector3.new(v.X, upward, v.Z)
        IJ_Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        IJ_spawnAirStepVFX(IJ_Root.Position - Vector3.new(0, 3, 0))
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if IJ_Humanoid and IJ_Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        IJ_AirTimer += dt
        if IJ_AirTimer > 3 then
            IJ_JumpsDone = math.min(IJ_JumpsDone, IJ_Settings.ExtraJumps or 0)
        end
    else
        IJ_AirTimer = 0
    end
end)

------------------------------------------------------
-- KOMPAS HUD (Top / Bottom only, DEFAULT: TOP)
------------------------------------------------------
local Compass = {}
do
    local WIDTH            = 480
    local HEIGHT           = 44
    local MARGIN_TOP       = 16
    local MARGIN_BOTTOM    = 16
    local BG_TRANSP        = 0.35
    local PIXELS_PER_DEG   = 2
    local TICK_EVERY       = 10
    local TICK_H_MIN       = 8
    local TICK_H_MID       = 12
    local TICK_H_MAX       = 18

    local gui, container, headingLabel, centerArrow, tapeHolder, tape
    local SEG_W = 360 * PIXELS_PER_DEG
    local rsConn
    local positionMode = "top"  -- DEFAULT: TOP
    local enabled = false

    local FULL_DIRS = {
        "Utara","Timur Laut","Timur","Tenggara",
        "Selatan","Barat Daya","Barat","Barat Laut"
    }

    local function yawDegFromLook(v: Vector3)
        local deg = math.deg(math.atan2(v.X, v.Z))
        return (deg % 360 + 360) % 360
    end

    local function addTick(parent, x, h)
        local tick = Instance.new("Frame")
        tick.Size = UDim2.fromOffset(2, h)
        tick.AnchorPoint = Vector2.new(0.5, 1)
        tick.Position = UDim2.fromOffset(x, tapeHolder.AbsoluteSize.Y - 4)
        tick.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        tick.BorderSizePixel = 0
        tick.Parent = parent
        return tick
    end

    local function addText(parent, x, text, size)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = size
        lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        lbl.AnchorPoint = Vector2.new(0.5, 1)
        lbl.Position = UDim2.fromOffset(x, tapeHolder.AbsoluteSize.Y - 6 - TICK_H_MAX)
        lbl.Size = UDim2.fromOffset(44, 18)
        lbl.Parent = parent
        return lbl
    end

    local function labelForDeg(degInt)
        local d = (degInt % 360 + 360) % 360
        if d == 0   then return "U"
        elseif d == 45  then return "TL"
        elseif d == 90  then return "T"
        elseif d == 135 then return "TG"
        elseif d == 180 then return "S"
        elseif d == 225 then return "BD"
        elseif d == 270 then return "B"
        elseif d == 315 then return "BL"
        end
        return nil
    end

    local function buildSegment(parent, xOffset)
        for deg = 0, 359, TICK_EVERY do
            local px = xOffset + deg * PIXELS_PER_DEG
            local lbl = labelForDeg(deg)
            if lbl then
                addTick(parent, px, TICK_H_MAX)
                addText(parent, px, lbl, 12)
            elseif deg % 30 == 0 then
                addTick(parent, px, TICK_H_MID)
                addText(parent, px, tostring(deg), 10)
            else
                addTick(parent, px, TICK_H_MIN)
            end
        end
    end

    local function rebuildTicksY()
        for _, c in ipairs(tape:GetChildren()) do
            if c:IsA("Frame") then
                c.Position = UDim2.fromOffset(c.Position.X.Offset, tapeHolder.AbsoluteSize.Y - 4)
            elseif c:IsA("TextLabel") then
                c.Position = UDim2.fromOffset(c.Position.X.Offset, tapeHolder.AbsoluteSize.Y - 6 - TICK_H_MAX)
            end
        end
    end

    local function setPositionMode(mode)
        positionMode = (mode == "top") and "top" or "bottom"
        if not container then return end

        if positionMode == "top" then
            container.AnchorPoint = Vector2.new(0.5, 0)
            container.Position    = UDim2.new(0.5, 0, 0, MARGIN_TOP)
        else
            container.AnchorPoint = Vector2.new(0.5, 1)
            container.Position    = UDim2.new(0.5, 0, 1, -MARGIN_BOTTOM)
        end

        container.Size       = UDim2.fromOffset(WIDTH, HEIGHT)
        centerArrow.Rotation = 0
        centerArrow.AnchorPoint = Vector2.new(0.5, 1)
        centerArrow.Position = UDim2.new(0.5, 0, 1, -4)
    end

    local function updateTape()
        if not camera then return end
        local look = camera.CFrame.LookVector
        local deg  = yawDegFromLook(look)

        local centerX = math.floor(container.AbsoluteSize.X / 2 + 0.5)
        local desired = centerX - (SEG_W + deg * PIXELS_PER_DEG)
        tape.Position = UDim2.fromOffset(desired, 0)

        local idx8 = math.floor((deg + 22.5) / 45) % 8 + 1
        headingLabel.Text = ("Arah: %s (%.0f°)"):format(FULL_DIRS[idx8], deg)
    end

    local function destroy()
        enabled = false
        if rsConn then rsConn:Disconnect(); rsConn = nil end
        if gui then gui:Destroy(); gui = nil end
        container, headingLabel, centerArrow, tapeHolder, tape = nil, nil, nil, nil, nil
    end

    local function create()
        destroy()
        enabled = true

        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local old1 = pg:FindFirstChild("CenterCompassHUD")
        if old1 then old1:Destroy() end
        local old2 = pg:FindFirstChild("AxaHUD_Compass")
        if old2 then old2:Destroy() end

        gui = Instance.new("ScreenGui")
        gui.Name = "AxaHUD_Compass"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 50
        gui.Parent = pg

        container = Instance.new("Frame")
        container.Name = "CompassContainer"
        container.Size = UDim2.fromOffset(WIDTH, HEIGHT)
        container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        container.BackgroundTransparency = BG_TRANSP
        container.BorderSizePixel = 0
        container.ClipsDescendants = true
        container.Parent = gui
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", container)
        stroke.Thickness = 1
        stroke.Color = Color3.fromRGB(255,255,255)
        stroke.Transparency = 0.75

        headingLabel = Instance.new("TextLabel")
        headingLabel.BackgroundTransparency = 1
        headingLabel.Size = UDim2.new(1, -16, 0, 18)
        headingLabel.Position = UDim2.fromOffset(8, 4)
        headingLabel.Font = Enum.Font.GothamBold
        headingLabel.TextSize = 14
        headingLabel.TextColor3 = Color3.fromRGB(230,230,230)
        headingLabel.TextXAlignment = Enum.TextXAlignment.Left
        headingLabel.Text = "Arah: -"
        headingLabel.Parent = container

        centerArrow = Instance.new("TextLabel")
        centerArrow.BackgroundTransparency = 1
        centerArrow.Size = UDim2.fromOffset(20, 20)
        centerArrow.Font = Enum.Font.GothamBold
        centerArrow.TextSize = 16
        centerArrow.TextColor3 = Color3.fromRGB(255, 90, 90)
        centerArrow.Text = "▲"
        centerArrow.Parent = container

        tapeHolder = Instance.new("Frame")
        tapeHolder.Name = "TapeHolder"
        tapeHolder.BackgroundTransparency = 1
        tapeHolder.Size = UDim2.new(1, 0, 1, -20)
        tapeHolder.Position = UDim2.fromOffset(0, 20)
        tapeHolder.Parent = container

        tape = Instance.new("Frame")
        tape.Name = "Tape"
        tape.BackgroundTransparency = 1
        tape.Size = UDim2.fromOffset(SEG_W * 3, tapeHolder.AbsoluteSize.Y)
        tape.Position = UDim2.fromOffset(0, 0)
        tape.Parent = tapeHolder

        tapeHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            tape.Size = UDim2.fromOffset(SEG_W * 3, tapeHolder.AbsoluteSize.Y)
            rebuildTicksY()
        end)

        buildSegment(tape, 0)
        buildSegment(tape, SEG_W)
        buildSegment(tape, SEG_W * 2)

        -- DEFAULT POSISI: TOP
        setPositionMode(positionMode)

        rsConn = RunService.RenderStepped:Connect(function()
            if enabled then updateTape() end
        end)

        task.defer(function()
            for _ = 1, 5 do
                updateTape()
                task.wait(0.05)
            end
        end)
    end

    Compass.Create  = create
    Compass.Destroy = destroy
    Compass.SetVisible = function(v)
        if v and not gui then create()
        elseif (not v) and gui then destroy()
        end
    end
    Compass.SetPositionMode = function(mode)
        positionMode = (mode == "top") and "top" or "bottom"
        if gui and container then setPositionMode(positionMode) end
    end
    Compass.GetPositionMode = function() return positionMode end
end

------------------------------------------------------
-- UI TAB: Layout + Toggle Connect
------------------------------------------------------
do
    local header = Instance.new("TextLabel")
    header.Name = "UtilHeader"
    header.Size = UDim2.new(1, -10, 0, 22)
    header.Position = UDim2.new(0, 5, 0, 6)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 15
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = Color3.fromRGB(40, 40, 70)
    header.Text = "⚙️ Utilitas - ShiftRun, Infinite Jump, Kompas"
    header.Parent = TAB_FRAME

    local sub = Instance.new("TextLabel")
    sub.Name = "UtilSub"
    sub.Size = UDim2.new(1, -10, 0, 38)
    sub.Position = UDim2.new(0, 5, 0, 28)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextWrapped = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top
    sub.TextColor3 = Color3.fromRGB(90, 90, 120)
    sub.Text = "ShiftRun: tahan LeftShift (WalkSpeed 40 + anim + FOV 80).  Infinite Jump: +5 lompatan udara.\nKompas: pita derajat U/T/S/B (ID) dengan posisi Atas/Bawah."
    sub.Parent = TAB_FRAME

    local listHolder = Instance.new("Frame")
    listHolder.Name = "ToggleList"
    listHolder.Size = UDim2.new(1, -10, 1, -110)
    listHolder.Position = UDim2.new(0, 5, 0, 70)
    listHolder.BackgroundTransparency = 1
    listHolder.Parent = TAB_FRAME

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.Name
    layout.Padding = UDim.new(0, 6)
    layout.Parent = listHolder

    -- Toggle: ShiftRun
    local rowShift = createToggleRow(
        listHolder,
        "1_ShiftRun",
        "ShiftRun (LeftShift, anim, FOV 80 / 70)",
        false
    )
    rowShift.OnChanged(function(state)
        SR_sprintEnabled = state
        SR_setSprintEnabled(state)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "ShiftRun",
                Text  = state and "ShiftRun AKTIF (tahan LeftShift)." or "ShiftRun dimatikan.",
                Duration = 3
            })
        end)
    end)

    -- Toggle: Infinite Jump
    local rowInfJump = createToggleRow(
        listHolder,
        "2_InfiniteJump",
        ("Infinite Jump (%d extra jump di udara + pijakan VFX)"):format(IJ_Settings.ExtraJumps),
        false
    )
    rowInfJump.OnChanged(function(state)
        IJ_Enabled = state
        IJ_JumpsDone = 0
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Infinite Jump",
                Text  = state and ("Aktif (%d extra jump)."):format(IJ_Settings.ExtraJumps) or "Dimatikan.",
                Duration = 3
            })
        end)
    end)

    -- Toggle: Kompas HUD
    local rowCompass = createToggleRow(
        listHolder,
        "3_CompassHUD",
        "Kompas HUD (pita derajat & heading)",
        true -- default aktif
    )
    rowCompass.OnChanged(function(state)
        Compass.SetVisible(state)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Kompas",
                Text  = state and "Kompas ditampilkan." or "Kompas disembunyikan.",
                Duration = 2
            })
        end)
    end)
    Compass.SetVisible(rowCompass.Get())

    -- Posisi Kompas: Atas / Bawah
    local posRow = Instance.new("Frame")
    posRow.Name = "3b_CompassPos"
    posRow.Size = UDim2.new(1, 0, 0, 30)
    posRow.BackgroundTransparency = 1
    posRow.Parent = listHolder

    local posLabel = Instance.new("TextLabel")
    posLabel.BackgroundTransparency = 1
    posLabel.Size = UDim2.new(0, 140, 1, 0)
    posLabel.Font = Enum.Font.Gotham
    posLabel.TextSize = 13
    posLabel.TextXAlignment = Enum.TextXAlignment.Left
    posLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
    posLabel.Text = "Posisi Kompas:"
    posLabel.Parent = posRow

    local function styleBtn(btn, active)
        btn.BackgroundColor3 = active and Color3.fromRGB(140, 190, 255) or Color3.fromRGB(220, 222, 235)
        btn.TextColor3       = active and Color3.fromRGB(20, 30, 50)   or Color3.fromRGB(50, 60, 90)
    end

    local btnTop = Instance.new("TextButton")
    btnTop.Size = UDim2.new(0, 100, 0, 26)
    btnTop.Position = UDim2.new(0, 150, 0, 2)
    btnTop.Font = Enum.Font.GothamSemibold
    btnTop.TextSize = 13
    btnTop.Text = "Atas"
    btnTop.Parent = posRow
    Instance.new("UICorner", btnTop).CornerRadius = UDim.new(0, 7)

    local btnBottom = Instance.new("TextButton")
    btnBottom.Size = UDim2.new(0, 100, 0, 26)
    btnBottom.Position = UDim2.new(0, 256, 0, 2)
    btnBottom.Font = Enum.Font.GothamSemibold
    btnBottom.TextSize = 13
    btnBottom.Text = "Bawah"
    btnBottom.Parent = posRow
    Instance.new("UICorner", btnBottom).CornerRadius = UDim.new(0, 7)

    local currentPos = Compass.GetPositionMode() -- "top"/"bottom" (DEFAULT: "top")
    styleBtn(btnTop,    currentPos == "top")
    styleBtn(btnBottom, currentPos == "bottom")

    btnTop.MouseButton1Click:Connect(function()
        Compass.SetPositionMode("top")
        styleBtn(btnTop, true)
        styleBtn(btnBottom, false)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Kompas",
                Text  = "Posisi: Atas",
                Duration = 2
            })
        end)
    end)

    btnBottom.MouseButton1Click:Connect(function()
        Compass.SetPositionMode("bottom")
        styleBtn(btnTop, false)
        styleBtn(btnBottom, true)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Kompas",
                Text  = "Posisi: Bawah",
                Duration = 2
            })
        end)
    end)
end

-- Tab util selesai: ShiftRun + Infinite Jump + Kompas (default di atas, bisa pindah ke bawah lewat UI).
