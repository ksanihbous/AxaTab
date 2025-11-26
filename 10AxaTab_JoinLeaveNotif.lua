--==========================================================
--  10AxaTab_JoinLeaveNotif.lua
--  Tab AxaHub: Join/Leave Notif + Log Pemain
--  Env dari core:
--      TAB_FRAME (Frame konten tab)
--      Players, RunService, TweenService, StarterGui, dll (biasanya sudah di-pass)
--==========================================================

local frame        = TAB_FRAME

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui   = game:GetService("StarterGui")
local TextService  = game:GetService("TextService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------
-- HELPER UI
------------------------------------------------------
local function rounded(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = instance
    return c
end

local function stroked(instance, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(255,255,255)
    s.Thickness = thickness or 1
    s.Transparency = transparency ~= nil and transparency or 0.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = instance
    return s
end

local function gradient(instance, cTop, cBottom, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cTop or Color3.fromRGB(245,247,255)),
        ColorSequenceKeypoint.new(1, cBottom or Color3.fromRGB(233,238,252))
    })
    g.Rotation = rot or 90
    g.Parent = instance
    return g
end

local function getAvatar(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    return ok and content or ""
end

local LOCALE_SEGMENT = "id"
local function profileUrl(userId)
    return string.format("https://www.roblox.com/%s/users/%d/profile", LOCALE_SEGMENT, userId)
end

local function copyOrAnnounce(url)
    local okCopy = pcall(function()
        if setclipboard then
            setclipboard(url)
        else
            error("no setclipboard")
        end
    end)

    if okCopy then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Profil",
                Text  = "Link profil tersalin.",
                Duration = 2
            })
        end)
        return
    end

    -- fallback: lempar ke chat
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[Profil] " .. url,
            Color = Color3.fromRGB(30, 30, 40),
            Font = Enum.Font.Gotham,
            TextSize = 14
        })
    end)
end

local function hhmm(ts)
    local t = os.date("*t", ts or os.time())
    return string.format("%02d:%02d", t.hour, t.min)
end

------------------------------------------------------
-- HEADER TAB
------------------------------------------------------
frame.BackgroundTransparency = 1

local header = Instance.new("TextLabel")
header.Name = "JoinLeaveHeader"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextXAlignment = Enum.TextXAlignment.Left
header.TextColor3 = Color3.fromRGB(40, 40, 70)
header.Text = "📡 Join/Leave Notif - Teman & Log Pemain"
header.Parent = frame

local sub = Instance.new("TextLabel")
sub.Name = "JoinLeaveSub"
sub.Size = UDim2.new(1, -10, 0, 32)
sub.Position = UDim2.new(0, 5, 0, 28)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextWrapped = true
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextYAlignment = Enum.TextYAlignment.Top
sub.TextColor3 = Color3.fromRGB(90, 90, 120)
sub.Text = "Pantau teman yang masuk/keluar dan semua pemain di server. Klik baris untuk salin link profil."
sub.Parent = frame

------------------------------------------------------
-- TITLEBAR: judul + segmented control + tombol sound
------------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Name = "JoinLeaveTitleBar"
titleBar.Size = UDim2.new(1, -10, 0, 28)
titleBar.Position = UDim2.new(0, 5, 0, 64)
titleBar.BackgroundTransparency = 1
titleBar.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(0.3, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Font = Enum.Font.GothamSemibold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
titleLabel.Text = "Log Pemain"
titleLabel.Parent = titleBar

local soundBtn = Instance.new("TextButton")
soundBtn.Name = "SoundBtn"
soundBtn.AnchorPoint = Vector2.new(1, 0.5)
soundBtn.Position = UDim2.new(1, -4, 0.5, 0)
soundBtn.Size = UDim2.new(0, 32, 0, 22)
soundBtn.AutoButtonColor = false
soundBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
soundBtn.BackgroundTransparency = 0.35
soundBtn.BorderSizePixel = 0
soundBtn.Font = Enum.Font.Gotham
soundBtn.TextSize = 14
soundBtn.TextColor3 = Color3.fromRGB(40, 40, 70)
soundBtn.Text = "🔊"
soundBtn.Parent = titleBar
rounded(soundBtn, 8)
stroked(soundBtn, Color3.fromRGB(180, 190, 220), 1, 0.4)

local SEG_ITEM_W, SEG_PAD = 80, 4

local segScroll = Instance.new("ScrollingFrame")
segScroll.Name = "SegScroll"
segScroll.AnchorPoint = Vector2.new(1, 0)
segScroll.Position = UDim2.new(1, -40, 0, 0)
segScroll.Size = UDim2.new(0.6, -40, 1, 0)
segScroll.BackgroundTransparency = 1
segScroll.BorderSizePixel = 0
segScroll.ScrollBarThickness = 0
segScroll.ScrollingDirection = Enum.ScrollingDirection.X
segScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
segScroll.Parent = titleBar

local segWrap = Instance.new("Frame")
segWrap.Name = "SegWrap"
segWrap.Size = UDim2.new(0, 240, 0, 24)
segWrap.Position = UDim2.new(0, 0, 0, 2)
segWrap.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
segWrap.BackgroundTransparency = 0.35
segWrap.BorderSizePixel = 0
segWrap.Parent = segScroll
rounded(segWrap, 10)
stroked(segWrap, Color3.fromRGB(210, 215, 235), 1, 0.5)
gradient(segWrap, Color3.fromRGB(255, 255, 255), Color3.fromRGB(238, 243, 255), 90)

local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
indicator.BackgroundTransparency = 0.15
indicator.BorderSizePixel = 0
indicator.Parent = segWrap
rounded(indicator, 9)
stroked(indicator, Color3.fromRGB(10, 132, 255), 1, 0.35)
gradient(indicator, Color3.fromRGB(255, 255, 255), Color3.fromRGB(230, 240, 255), 90)

local function makeSeg(text)
    local btn = Instance.new("TextButton")
    btn.Name = "Seg_" .. text
    btn.Size = UDim2.new(0, SEG_ITEM_W, 1, 0)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(40, 40, 70)
    btn.Parent = segWrap
    return btn
end

local segJoin  = makeSeg("Join")
local segLeave = makeSeg("Leave")
local segAll   = makeSeg("Player")

------------------------------------------------------
-- BODY PANEL
------------------------------------------------------
local body = Instance.new("Frame")
body.Name = "JoinLeaveBody"
body.Size = UDim2.new(1, -10, 1, -104)
body.Position = UDim2.new(0, 5, 0, 96)
body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
body.BackgroundTransparency = 0.3
body.BorderSizePixel = 0
body.Parent = frame
rounded(body, 12)
stroked(body, Color3.fromRGB(210, 215, 235), 1, 0.55)
gradient(body, Color3.fromRGB(255, 255, 255), Color3.fromRGB(242, 246, 255), 90)

------------------------------------------------------
-- SEARCH BAR
------------------------------------------------------
local SEARCH_H = 28

local searchWrap = Instance.new("Frame")
searchWrap.Name = "SearchWrap"
searchWrap.BackgroundTransparency = 1
searchWrap.Size = UDim2.new(1, -12, 0, SEARCH_H)
searchWrap.Position = UDim2.new(0, 6, 0, 6)
searchWrap.Parent = body

local searchBg = Instance.new("Frame")
searchBg.Name = "SearchBg"
searchBg.Size = UDim2.new(1, 0, 1, 0)
searchBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
searchBg.BackgroundTransparency = 0.35
searchBg.BorderSizePixel = 0
searchBg.Parent = searchWrap
rounded(searchBg, 8)
stroked(searchBg, Color3.fromRGB(210, 215, 235), 1, 0.5)
gradient(searchBg, Color3.fromRGB(255, 255, 255), Color3.fromRGB(238, 243, 255), 90)

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -12, 1, 0)
searchBox.Position = UDim2.new(0, 6, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(40, 40, 70)
searchBox.PlaceholderText = "Cari displayname / username..."
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 125, 140)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = searchBg

------------------------------------------------------
-- LIST SCROLLINGFRAME (Join / Leave / Player)
------------------------------------------------------
local function newScroll(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageTransparency = 0.1
    scroll.ScrollBarImageColor3 = Color3.fromRGB(130, 138, 154)
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Parent = body

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    return scroll
end

local scrollJoin  = newScroll("ScrollJoin")
local scrollLeave = newScroll("ScrollLeave")
local scrollAll   = newScroll("ScrollAll")

local function applyListAreaLayout()
    local top = searchWrap.Position.Y.Offset + SEARCH_H + 6
    scrollJoin.Position  = UDim2.new(0, 6, 0, top)
    scrollLeave.Position = UDim2.new(0, 6, 0, top)
    scrollAll.Position   = UDim2.new(0, 6, 0, top)

    local bottomMargin = 6
    local size = UDim2.new(1, -12, 1, -(top + bottomMargin))
    scrollJoin.Size  = size
    scrollLeave.Size = size
    scrollAll.Size   = size
end

applyListAreaLayout()

------------------------------------------------------
-- FILTER (SEARCH)
------------------------------------------------------
local function filterScroll(scroll, qlower)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            if qlower == "" then
                child.Visible = true
            else
                local n = string.lower(child:GetAttribute("nameLower") or "")
                local u = string.lower(child:GetAttribute("userLower") or "")
                local t = ""
                local lbl = child:FindFirstChild("Text")
                if lbl and lbl:IsA("TextLabel") then
                    t = string.lower(lbl.Text)
                end
                local ok = (string.find(n, qlower, 1, true) ~= nil)
                        or (string.find(u, qlower, 1, true) ~= nil)
                        or (string.find(t, qlower, 1, true) ~= nil)
                child.Visible = ok
            end
        end
    end
end

local function applyGlobalFilter()
    local q = string.lower(searchBox.Text or "")
    filterScroll(scrollJoin,  q)
    filterScroll(scrollLeave, q)
    filterScroll(scrollAll,   q)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(applyGlobalFilter)

------------------------------------------------------
-- ROW BUILDER
------------------------------------------------------
local function glassRowBase(row)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.35
    row.BorderSizePixel = 0
    rounded(row, 10)
    gradient(row, Color3.fromRGB(255, 255, 255), Color3.fromRGB(238, 243, 255), 90)
    stroked(row, Color3.fromRGB(210, 215, 235), 1, 0.5)
end

local function makeLogItem(parentScroll, accentColor, info, kind, atTimestamp, isFriend)
    local row = Instance.new("TextButton")
    row.AutoButtonColor = false
    row.Name = string.format("%s_%d_%d", kind == "join" and "Join" or "Leave", info.userId, math.floor((atTimestamp or os.time()) % 1e6))
    row.Size = UDim2.new(1, 0, 0, 44)
    row.Text = ""
    glassRowBase(row)
    row.Parent = parentScroll
    row.ZIndex = 5

    row:SetAttribute("nameLower", string.lower(info.displayName or info.name or ""))
    row:SetAttribute("userLower", string.lower(info.name or ""))

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Parent = row

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 28, 0, 28)
    avatar.Position = UDim2.new(0, 10, 0.5, -14)
    avatar.BackgroundTransparency = 1
    avatar.Image = getAvatar(info.userId)
    rounded(avatar, 14)
    avatar.Parent = row

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -120, 1, 0)
    textLabel.Position = UDim2.new(0, 46, 0, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local prefix = (kind == "join") and "✅" or "🚪"
    local role   = isFriend and "Teman" or "Pemain"
    local timeStr= hhmm(atTimestamp)
    textLabel.Text = string.format("%s %s  (@%s) • %s • %s", prefix, info.displayName or info.name, info.name, role, timeStr)
    textLabel.Parent = row

    if isFriend then
        local chip = Instance.new("TextLabel")
        chip.Name = "FriendChip"
        chip.BackgroundColor3 = Color3.fromRGB(220, 240, 230)
        chip.BackgroundTransparency = 0.1
        chip.Size = UDim2.new(0, 70, 0, 20)
        chip.Position = UDim2.new(1, -80, 0.5, -10)
        chip.Font = Enum.Font.GothamMedium
        chip.TextSize = 12
        chip.Text = "Friend"
        chip.TextColor3 = Color3.fromRGB(40, 80, 50)
        chip.BorderSizePixel = 0
        chip.Parent = row
        rounded(chip, 10)
        stroked(chip, Color3.fromRGB(180, 210, 190), 1, 0.5)
    else
        local btn = Instance.new("TextButton")
        btn.Name = "Link"
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.2
        btn.Size = UDim2.new(0, 30, 0, 22)
        btn.Position = UDim2.new(1, -38, 0.5, -11)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = "🔗"
        btn.TextColor3 = Color3.fromRGB(40, 40, 70)
        btn.BorderSizePixel = 0
        btn.Parent = row
        rounded(btn, 8)
        stroked(btn, Color3.fromRGB(200, 210, 230), 1, 0.5)
        btn.MouseButton1Click:Connect(function()
            copyOrAnnounce(profileUrl(info.userId))
        end)
    end

    row.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    return row
end

local function makeAllItem(parentScroll, info, isFriend)
    local row = Instance.new("TextButton")
    row.AutoButtonColor = false
    row.Name = "All_" .. tostring(info.userId)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.Text = ""
    glassRowBase(row)
    row.Parent = parentScroll
    row.ZIndex = 4

    row:SetAttribute("nameLower", string.lower(info.displayName or info.name or ""))
    row:SetAttribute("userLower", string.lower(info.name or ""))

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 26, 0, 26)
    avatar.Position = UDim2.new(0, 10, 0.5, -13)
    avatar.BackgroundTransparency = 1
    avatar.Image = getAvatar(info.userId)
    rounded(avatar, 13)
    avatar.Parent = row

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -100, 1, 0)
    textLabel.Position = UDim2.new(0, 46, 0, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local txt = string.format("%s  (@%s)", info.displayName or info.name, info.name)
    if isFriend then
        txt = txt .. "  ⭐"
    end
    textLabel.Text = txt
    textLabel.Parent = row

    local btn = Instance.new("TextButton")
    btn.Name = "Link"
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.2
    btn.Size = UDim2.new(0, 30, 0, 22)
    btn.Position = UDim2.new(1, -38, 0.5, -11)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = "🔗"
    btn.TextColor3 = Color3.fromRGB(40, 40, 70)
    btn.BorderSizePixel = 0
    btn.Parent = row
    rounded(btn, 8)
    stroked(btn, Color3.fromRGB(200, 210, 230), 1, 0.5)

    btn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    return row
end

------------------------------------------------------
-- SEGMENTED CONTROL (Join / Leave / Player)
------------------------------------------------------
local function layoutSegments()
    local list = {segJoin, segLeave, segAll}
    local n = #list
    local totalW = SEG_PAD * 2 + SEG_ITEM_W * n
    segWrap.Size = UDim2.new(0, totalW, 0, 24)
    segScroll.CanvasSize = UDim2.new(0, totalW, 0, 0)

    indicator.Size = UDim2.new(0, SEG_ITEM_W - SEG_PAD * 2, 1, -SEG_PAD * 2)
    for i, btn in ipairs(list) do
        btn.Position = UDim2.new(0, SEG_PAD + (i - 1) * SEG_ITEM_W, 0, 0)
    end
end

layoutSegments()
segWrap:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    segScroll.CanvasSize = UDim2.new(0, segWrap.AbsoluteSize.X, 0, 0)
end)

local activeTab = "Join"

local function moveIndicatorTo(index)
    local x = SEG_PAD + (index - 1) * SEG_ITEM_W
    indicator.Position = UDim2.new(0, x, 0, SEG_PAD)
end

local function updateSegmentVisuals(index)
    local list = {segJoin, segLeave, segAll}
    for i, btn in ipairs(list) do
        btn.TextTransparency = (i == index) and 0 or 0.3
        btn.Font = (i == index) and Enum.Font.GothamSemibold or Enum.Font.GothamMedium
    end
end

local function setTab(tab)
    activeTab = tab
    if tab == "Join" then
        scrollJoin.Visible  = true
        scrollLeave.Visible = false
        scrollAll.Visible   = false
        moveIndicatorTo(1)
        updateSegmentVisuals(1)
    elseif tab == "Leave" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = true
        scrollAll.Visible   = false
        moveIndicatorTo(2)
        updateSegmentVisuals(2)
    else -- Player
        scrollJoin.Visible  = false
        scrollLeave.Visible = false
        scrollAll.Visible   = true
        moveIndicatorTo(3)
        updateSegmentVisuals(3)
    end
    applyGlobalFilter()
end

segJoin.MouseButton1Click:Connect(function() setTab("Join") end)
segLeave.MouseButton1Click:Connect(function() setTab("Leave") end)
segAll.MouseButton1Click:Connect(function() setTab("Player") end)

setTab("Join")

------------------------------------------------------
-- TOAST UI (buat teman join/leave)
------------------------------------------------------
local toastGui do
    local old = PlayerGui:FindFirstChild("AxaJoinLeaveToast")
    if old then old:Destroy() end

    toastGui = Instance.new("ScreenGui")
    toastGui.Name = "AxaJoinLeaveToast"
    toastGui.ResetOnSpawn = false
    toastGui.IgnoreGuiInset = true
    toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toastGui.DisplayOrder = 999999
    toastGui.Parent = PlayerGui
end

local toastRoot = Instance.new("Frame")
toastRoot.Name = "ToastCard"
toastRoot.AnchorPoint = Vector2.new(0.5, 0)
toastRoot.Size = UDim2.fromOffset(320, 46)
toastRoot.Position = UDim2.new(0.5, 0, 0, -50)
toastRoot.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
toastRoot.BackgroundTransparency = 1
toastRoot.Visible = false
toastRoot.Parent = toastGui
rounded(toastRoot, 12)

local toastStroke = stroked(toastRoot, Color3.fromRGB(255, 255, 255), 1, 1)

local toastText = Instance.new("TextLabel")
toastText.BackgroundTransparency = 1
toastText.Size = UDim2.new(1, -16, 1, 0)
toastText.Position = UDim2.new(0, 8, 0, 0)
toastText.Font = Enum.Font.GothamMedium
toastText.TextSize = 14
toastText.TextColor3 = Color3.fromRGB(235, 235, 235)
toastText.TextXAlignment = Enum.TextXAlignment.Left
toastText.TextYAlignment = Enum.TextYAlignment.Center
toastText.Text = ""
toastText.TextTransparency = 1
toastText.Parent = toastRoot

local function tweenOBJ(obj, t, props)
    return TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local toastBusy  = false
local toastQueue = {}

local function playToast(kind, msg)
    toastRoot.Visible = true
    toastRoot.BackgroundTransparency = 1
    toastStroke.Transparency = 1
    toastText.TextTransparency = 1
    toastText.Text = msg

    tweenOBJ(toastRoot, 0.18, {Position = UDim2.new(0.5, 0, 0, 60), BackgroundTransparency = 0.1}):Play()
    tweenOBJ(toastStroke, 0.18, {Transparency = 0.4}):Play()
    tweenOBJ(toastText, 0.18, {TextTransparency = 0}):Play()

    task.wait(2.0)

    tweenOBJ(toastRoot, 0.16, {Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 1}):Play()
    tweenOBJ(toastStroke, 0.16, {Transparency = 1}):Play()
    tweenOBJ(toastText, 0.16, {TextTransparency = 1}):Play()
    task.wait(0.18)
    toastRoot.Visible = false
end

local function pushToast(kind, msg)
    table.insert(toastQueue, {kind = kind, msg = msg})
    if toastBusy then return end
    toastBusy = true
    while #toastQueue > 0 do
        local item = table.remove(toastQueue, 1)
        playToast(item.kind, item.msg)
    end
    toastBusy = false
end

------------------------------------------------------
-- SOUND TOGGLE
------------------------------------------------------
local soundEnabled = true
local JOIN_SOUND_ID  = "rbxassetid://6026984224"
local LEAVE_SOUND_ID = "rbxassetid://6026984224"

local function setSoundUI(on)
    soundEnabled = on and true or false
    soundBtn.Text = on and "🔊" or "🔇"
    soundBtn.TextTransparency = on and 0 or 0.3
    soundBtn.BackgroundTransparency = on and 0.35 or 0.5
end

local function playChime(kind)
    if not soundEnabled then return end
    local id = (kind == "join") and JOIN_SOUND_ID or LEAVE_SOUND_ID
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 0.5
    s.Parent = SoundService
    SoundService:PlayLocalSound(s)
    task.delay(3, function()
        if s then s:Destroy() end
    end)
end

setSoundUI(true)
soundBtn.MouseButton1Click:Connect(function()
    setSoundUI(not soundEnabled)
end)

------------------------------------------------------
-- FRIEND CACHE
------------------------------------------------------
local friendSet = {}

local function seedFriends()
    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(LocalPlayer.UserId)
    end)
    if not ok or not pages then return end

    repeat
        for _, info in ipairs(pages:GetCurrentPage()) do
            if info and typeof(info) == "table" and info.Id then
                friendSet[info.Id] = true
            end
        end
        if pages.IsFinished then break end
        local okNext = pcall(function()
            pages:AdvanceToNextPageAsync()
        end)
        if not okNext then break end
    until false
end

task.spawn(seedFriends)

local function isFriendUserId(userId)
    if userId == nil then return false end
    if friendSet[userId] then return true end
    local ok, res = pcall(function()
        return LocalPlayer:IsFriendsWith(userId)
    end)
    if ok and res then
        friendSet[userId] = true
        return true
    end
    return false
end

------------------------------------------------------
-- DATA & EVENT HANDLERS
------------------------------------------------------
local joinTimes = {}
local allRows   = {}

local function upsertAll(info)
    local isFriend = isFriendUserId(info.userId)
    local row = allRows[info.userId]
    if row and row.Parent then
        local label = row:FindFirstChild("Text")
        if label and label:IsA("TextLabel") then
            local txt = string.format("%s  (@%s)", info.displayName or info.name, info.name)
            if isFriend then
                txt = txt .. "  ⭐"
            end
            label.Text = txt
        end
        local avatar = row:FindFirstChild("Avatar")
        if avatar and avatar:IsA("ImageLabel") then
            avatar.Image = getAvatar(info.userId)
        end
    else
        row = makeAllItem(scrollAll, info, isFriend)
        allRows[info.userId] = row
    end
    applyGlobalFilter()
end

local function removeAll(uid)
    local row = allRows[uid]
    if row and row.Parent then
        row:Destroy()
    end
    allRows[uid] = nil
    applyGlobalFilter()
end

local function addJoinLog(info, isFriend)
    local accent = isFriend and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(120, 180, 255)
    makeLogItem(scrollJoin, accent, info, "join", os.time(), isFriend)
    applyGlobalFilter()
end

local function addLeaveLog(info, isFriend)
    local accent = isFriend and Color3.fromRGB(255, 69, 58) or Color3.fromRGB(230, 90, 90)
    makeLogItem(scrollLeave, accent, info, "leave", os.time(), isFriend)
    applyGlobalFilter()
end

-- Seed awal roster
for _, p in ipairs(Players:GetPlayers()) do
    joinTimes[p.UserId] = os.time()
    upsertAll({
        userId = p.UserId,
        name = p.Name,
        displayName = p.DisplayName,
    })
end

-- Event join/leave
Players.PlayerAdded:Connect(function(p)
    joinTimes[p.UserId] = os.time()
    local info = { userId = p.UserId, name = p.Name, displayName = p.DisplayName }
    upsertAll(info)

    if p ~= LocalPlayer then
        local friend = isFriendUserId(p.UserId)
        addJoinLog(info, friend)
        if friend then
            playChime("join")
            pushToast("join", string.format("Teman bergabung: %s (@%s)", info.displayName or info.name, info.name))
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    local info = { userId = p.UserId, name = p.Name, displayName = p.DisplayName }
    removeAll(p.UserId)

    if p ~= LocalPlayer then
        local friend = isFriendUserId(p.UserId)
        addLeaveLog(info, friend)
        if friend then
            playChime("leave")
            pushToast("leave", string.format("Teman keluar: %s (@%s)", info.displayName or info.name, info.name))
        end
    end
end)