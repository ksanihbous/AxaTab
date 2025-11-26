--==========================================================
--  10AxaTab_JoinLeave.lua
--  TAB "Join/Leave Notif"
--==========================================================

local frame        = TAB_FRAME
local Players      = Players
local LocalPlayer  = LocalPlayer
local RunService   = RunService
local TweenService = TweenService
local UserInputService = UserInputService
local StarterGui   = StarterGui
local camera       = Camera or workspace.CurrentCamera

local Lighting     = game:GetService("Lighting")
local TextService  = game:GetService("TextService")
local SoundService = game:GetService("SoundService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------
-- UTIL: Tween helper
------------------------------------------------------
local function AXA_Tween(obj, time, goal)
    local info = TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, goal)
    tw:Play()
    return tw
end

------------------------------------------------------
-- SINGLETON: Toast ScreenGui (AxaJoinLeaveToast)
------------------------------------------------------
do
    local old = PlayerGui:FindFirstChild("AxaJoinLeaveToast")
    if old then old:Destroy() end
end

local ToastGui      = Instance.new("ScreenGui")
ToastGui.Name       = "AxaJoinLeaveToast"
ToastGui.IgnoreGuiInset = true
ToastGui.ResetOnSpawn   = false
ToastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToastGui.DisplayOrder   = 999999
ToastGui.Parent         = PlayerGui

local ToastRoot = Instance.new("Frame")
ToastRoot.Name = "Root"
ToastRoot.BackgroundTransparency = 1
ToastRoot.Size = UDim2.new(1, 0, 1, 0)
ToastRoot.Parent = ToastGui

local TOAST_WIDTH   = 560
local TOAST_HEIGHT  = 60
local TOAST_MARGINY = 72
local TOAST_IN      = 0.22
local TOAST_OUT     = 0.18
local TOAST_SHOW    = 2.4

local ToastCard = Instance.new("Frame")
ToastCard.Name = "Card"
ToastCard.AnchorPoint = Vector2.new(0.5, 0)
ToastCard.Size = UDim2.fromOffset(TOAST_WIDTH, TOAST_HEIGHT)
ToastCard.Position = UDim2.new(0.5, 0, 0, -TOAST_HEIGHT)
ToastCard.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
ToastCard.BackgroundTransparency = 1
ToastCard.BorderSizePixel = 0
ToastCard.Parent = ToastRoot

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = ToastCard

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 1
stroke.Parent = ToastCard

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 24, 1, 24)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency = 1
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10,10,118,118)
shadow.Parent = ToastCard

local toastAccent = Instance.new("Frame")
toastAccent.Name = "Accent"
toastAccent.Size = UDim2.new(0, 5, 1, 0)
toastAccent.Position = UDim2.new(0, 0, 0, 0)
toastAccent.BackgroundColor3 = Color3.fromRGB(62, 201, 89)
toastAccent.BackgroundTransparency = 1
toastAccent.BorderSizePixel = 0
toastAccent.Parent = ToastCard

local toastText = Instance.new("TextLabel")
toastText.Name = "Text"
toastText.BackgroundTransparency = 1
toastText.Size = UDim2.new(1, -18, 1, 0)
toastText.Position = UDim2.new(0, 12, 0, 0)
toastText.Font = Enum.Font.GothamMedium
toastText.TextSize = 16
toastText.TextColor3 = Color3.fromRGB(235,235,235)
toastText.TextTransparency = 1
toastText.TextXAlignment = Enum.TextXAlignment.Left
toastText.TextYAlignment = Enum.TextYAlignment.Center
toastText.Parent = ToastCard

local toastQueue = {}
local toastBusy  = false

-- NOTIF toggle (toast visual)
local notifEnabled = true

-- SOUND toggle (ikon 🔊)
local soundEnabled = true

-- 1 sound ID, beda speed buat join / leave
local BASE_SOUND_ID = "rbxassetid://6026984224"

local function playOneShot(speed)
    if not soundEnabled then return end
    local s = Instance.new("Sound")
    s.SoundId = BASE_SOUND_ID
    s.Volume = 0.45
    s.PlaybackSpeed = speed or 1
    s.Parent = SoundService
    s:Play()
    task.delay(3, function()
        if s then s:Destroy() end
    end)
end

local function playJoinSound()
    -- pitch sedikit lebih tinggi
    playOneShot(1.12)
end

local function playLeaveSound()
    -- pitch sedikit lebih rendah
    playOneShot(0.9)
end

local function showToast(kind, message)
    if not notifEnabled then return end

    toastAccent.BackgroundColor3 = (kind == "leave")
        and Color3.fromRGB(230, 76, 76)
        or  Color3.fromRGB(62, 201, 89)

    toastText.Text = message or ""

    ToastCard.Position = UDim2.new(0.5, 0, 0, -TOAST_HEIGHT)
    ToastCard.BackgroundTransparency = 1
    stroke.Transparency = 1
    toastAccent.BackgroundTransparency = 1
    toastText.TextTransparency = 1
    shadow.ImageTransparency = 1
    ToastCard.Visible = true

    AXA_Tween(ToastCard, TOAST_IN, {Position = UDim2.new(0.5, 0, 0, TOAST_MARGINY), BackgroundTransparency = 0.18})
    AXA_Tween(stroke, TOAST_IN,   {Transparency = 0.65})
    AXA_Tween(toastAccent, TOAST_IN, {BackgroundTransparency = 0})
    AXA_Tween(toastText, TOAST_IN + 0.05, {TextTransparency = 0})
    AXA_Tween(shadow, TOAST_IN,  {ImageTransparency = 0.75})

    task.wait(TOAST_SHOW)

    AXA_Tween(ToastCard, TOAST_OUT, {Position = UDim2.new(0.5, 0, 0, -TOAST_HEIGHT), BackgroundTransparency = 1})
    AXA_Tween(stroke, TOAST_OUT,   {Transparency = 1})
    AXA_Tween(toastAccent, TOAST_OUT, {BackgroundTransparency = 1})
    AXA_Tween(toastText, TOAST_OUT, {TextTransparency = 1})
    AXA_Tween(shadow, TOAST_OUT, {ImageTransparency = 1})

    task.wait(TOAST_OUT + 0.02)
    ToastCard.Visible = false
end

local function pumpToast()
    if toastBusy then return end
    toastBusy = true
    while #toastQueue > 0 do
        local item = table.remove(toastQueue, 1)
        showToast(item.kind, item.msg)
    end
    toastBusy = false
end

local function pushToast(kind, msg)
    table.insert(toastQueue, {kind = kind, msg = msg})
    pumpToast()
end

------------------------------------------------------
-- HELPER UI (Glass chips, field row)
------------------------------------------------------
local function glassChipButton(text)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Size = UDim2.new(0, 90, 0, 24)
    b.BackgroundColor3 = Color3.fromRGB(255,255,255)
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(40,40,70)
    b.Text = text or ""
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(180, 190, 220)
    s.Transparency = 0.4
    s.Parent = b
    return b
end

local function makeFieldRow(parent, labelText)
    local row = Instance.new("Frame")
    row.Name = "Row_"..(labelText:gsub("%s+",""))
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.35, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(70, 70, 110)
    lbl.Text = labelText
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.Size = UDim2.new(0.65, -10, 1, 0)
    val.Position = UDim2.new(0.35, 10, 0, 0)
    val.Font = Enum.Font.GothamMedium
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.TextYAlignment = Enum.TextYAlignment.Center
    val.TextColor3 = Color3.fromRGB(30, 30, 50)
    val.Text = "-"
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Parent = row

    return row, val
end

------------------------------------------------------
-- UI: Header, Search, Segments
------------------------------------------------------

-- Header title
local header = Instance.new("TextLabel")
header.Name = "JoinLeaveHeader"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextXAlignment = Enum.TextXAlignment.Left
header.TextColor3 = Color3.fromRGB(40, 40, 70)
header.Text = "📡 Join / Leave Notif & Player Log"
header.Parent = frame

local sub = Instance.new("TextLabel")
sub.Name = "JoinLeaveSub"
sub.Size = UDim2.new(1, -10, 0, 34)
sub.Position = UDim2.new(0, 5, 0, 28)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextWrapped = true
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextYAlignment = Enum.TextYAlignment.Top
sub.TextColor3 = Color3.fromRGB(100, 100, 140)
sub.Text = "Pantau siapa yang masuk/keluar map, daftar pemain aktif, dan detail profil."
sub.Parent = frame

-- Header bar
local headerBar = Instance.new("Frame")
headerBar.Name = "HeaderBar"
headerBar.Size = UDim2.new(1, -10, 0, 30)
headerBar.Position = UDim2.new(0, 5, 0, 64)
headerBar.BackgroundColor3 = Color3.fromRGB(245, 247, 255)
headerBar.BackgroundTransparency = 0.1
headerBar.BorderSizePixel = 0
headerBar.Parent = frame

local hbCorner = Instance.new("UICorner")
hbCorner.CornerRadius = UDim.new(0, 8)
hbCorner.Parent = headerBar

local hbStroke = Instance.new("UIStroke")
hbStroke.Thickness = 1
hbStroke.Color = Color3.fromRGB(210, 214, 235)
hbStroke.Transparency = 0.4
hbStroke.Parent = headerBar

-- ICON SOUND (ganti teks "Tab:")
local soundBtn = glassChipButton("🔊")
soundBtn.Name = "SoundBtn"
soundBtn.Size = UDim2.new(0, 40, 0, 24)
soundBtn.Position = UDim2.new(0, 6, 0.5, -12)
soundBtn.Parent = headerBar

local function refreshSoundBtn()
    soundBtn.Text = soundEnabled and "🔊" or "🔇"
    soundBtn.TextColor3 = soundEnabled and Color3.fromRGB(20, 120, 60) or Color3.fromRGB(120, 50, 50)
    soundBtn.BackgroundTransparency = soundEnabled and 0.15 or 0.35
end
refreshSoundBtn()

soundBtn.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled
    refreshSoundBtn()
end)

-- Segments Scroll
local segScroll = Instance.new("ScrollingFrame")
segScroll.Name = "SegScroll"
segScroll.BackgroundTransparency = 1
segScroll.BorderSizePixel = 0
segScroll.Size = UDim2.new(1, -180, 1, 0)
segScroll.Position = UDim2.new(0, 54, 0, 0) -- geser dikit, karena soundBtn di kiri
segScroll.ScrollBarThickness = 0
segScroll.ScrollBarImageTransparency = 1
segScroll.ScrollingDirection = Enum.ScrollingDirection.X
segScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
segScroll.ClipsDescendants = true
segScroll.Parent = headerBar

local segContainer = Instance.new("Frame")
segContainer.Name = "SegContainer"
segContainer.BackgroundTransparency = 1
segContainer.Size = UDim2.new(0, 0, 1, 0)
segContainer.Position = UDim2.new(0, 0, 0, 0)
segContainer.Parent = segScroll

local segLayout = Instance.new("UIListLayout")
segLayout.FillDirection = Enum.FillDirection.Horizontal
segLayout.Padding = UDim.new(0, 6)
segLayout.SortOrder = Enum.SortOrder.LayoutOrder
segLayout.Parent = segContainer

local notifBtn = glassChipButton("NOTIF: ON")
notifBtn.Name = "NotifBtn"
notifBtn.Size = UDim2.new(0, 90, 0, 24)
notifBtn.Position = UDim2.new(1, -98, 0.5, -12)
notifBtn.Parent = headerBar

local function refreshNotifBtn()
    notifBtn.Text = notifEnabled and "NOTIF: ON" or "NOTIF: OFF"
    notifBtn.TextColor3 = notifEnabled and Color3.fromRGB(20, 120, 60) or Color3.fromRGB(120, 50, 50)
    notifBtn.BackgroundTransparency = notifEnabled and 0.2 or 0.35
end
refreshNotifBtn()

notifBtn.MouseButton1Click:Connect(function()
    notifEnabled = not notifEnabled
    refreshNotifBtn()
end)

-- Seg buttons
local segButtons = {}

local function layoutSegments()
    segContainer.Size = UDim2.new(0, segLayout.AbsoluteContentSize.X, 1, 0)
    segScroll.CanvasSize = UDim2.new(0, segLayout.AbsoluteContentSize.X, 0, 0)
end
segLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(layoutSegments)

local function createSegButton(name, label)
    local b = glassChipButton(label)
    b.Name = name
    b.Size = UDim2.new(0, 90, 0, 24)
    b.Parent = segContainer
    return b
end

segButtons.Join   = createSegButton("SegJoin",   "Join")
segButtons.Leave  = createSegButton("SegLeave",  "Leave")
segButtons.Player = createSegButton("SegAll",    "Player")
segButtons.Profile= createSegButton("SegProfile","Profile")
segButtons.Profile.Visible = false

layoutSegments()

------------------------------------------------------
-- BODY: Search + Scrolls (XY)
------------------------------------------------------
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -10, 1, -104)
body.Position = UDim2.new(0, 5, 0, 100)
body.BackgroundColor3 = Color3.fromRGB(248,249,255)
body.BackgroundTransparency = 0.0
body.BorderSizePixel = 0
body.Parent = frame

local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0, 10)
bodyCorner.Parent = body

local bodyStroke = Instance.new("UIStroke")
bodyStroke.Thickness = 1
bodyStroke.Color = Color3.fromRGB(220,225,240)
bodyStroke.Transparency = 0.4
bodyStroke.Parent = body

-- Search bar
local SEARCH_H = 28

local searchWrap = Instance.new("Frame")
searchWrap.Name = "SearchWrap"
searchWrap.Size = UDim2.new(1, -12, 0, SEARCH_H)
searchWrap.Position = UDim2.new(0, 6, 0, 6)
searchWrap.BackgroundTransparency = 1
searchWrap.Parent = body

local searchBg = Instance.new("Frame")
searchBg.Name = "SearchBg"
searchBg.Size = UDim2.new(1, 0, 1, 0)
searchBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
searchBg.BackgroundTransparency = 0.2
searchBg.BorderSizePixel = 0
searchBg.Parent = searchWrap

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 8)
sbCorner.Parent = searchBg

local sbStroke = Instance.new("UIStroke")
sbStroke.Thickness = 1
sbStroke.Color = Color3.fromRGB(210, 214, 235)
sbStroke.Transparency = 0.45
sbStroke.Parent = searchBg

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.BackgroundTransparency = 1
searchBox.Size = UDim2.new(1, -12, 1, 0)
searchBox.Position = UDim2.new(0, 6, 0, 0)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(40,40,70)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.PlaceholderText = "Search User/DisplayName"
searchBox.PlaceholderColor3 = Color3.fromRGB(130,136,150)
searchBox.Text = "" -- no default text
searchBox.Parent = searchBg

-- Scroll factory (VERTIKAL + HORIZONTAL)
local function newScroll(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 6
    sf.ScrollBarImageColor3 = Color3.fromRGB(150,155,175)
    sf.ScrollBarImageTransparency = 0.1
    sf.ScrollingDirection = Enum.ScrollingDirection.XY
    sf.TopImage = "rbxassetid://7445543667"
    sf.BottomImage = "rbxassetid://7445543667"
    sf.Parent = body

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = sf

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        -- XY canvas: X dari lebar konten (row pakai width fix),
        -- Y dari tinggi konten
        sf.CanvasSize = UDim2.new(
            0, layout.AbsoluteContentSize.X + 8,
            0, layout.AbsoluteContentSize.Y + 8
        )
    end)

    return sf, layout
end

local scrollJoin,  layoutJoin  = newScroll("ScrollJoin")
local scrollLeave, layoutLeave = newScroll("ScrollLeave")
local scrollAll,   layoutAll   = newScroll("ScrollAll")

local function layoutBodyScrolls()
    local top = SEARCH_H + 12
    scrollJoin.Position  = UDim2.new(0, 6, 0, top)
    scrollLeave.Position = UDim2.new(0, 6, 0, top)
    scrollAll.Position   = UDim2.new(0, 6, 0, top)

    local h = body.AbsoluteSize.Y - top - 6
    scrollJoin.Size  = UDim2.new(1, -12, 0, math.max(0, h))
    scrollLeave.Size = UDim2.new(1, -12, 0, math.max(0, h))
    scrollAll.Size   = UDim2.new(1, -12, 0, math.max(0, h))
end
body:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBodyScrolls)
layoutBodyScrolls()

scrollJoin.Visible  = true
scrollLeave.Visible = false
scrollAll.Visible   = false

------------------------------------------------------
-- PROFILE PAGE (scroll XY)
------------------------------------------------------
local profilePage = Instance.new("Frame")
profilePage.Name = "ProfilePage"
profilePage.Size = UDim2.new(1, -12, 1, -12)
profilePage.Position = UDim2.new(0, 6, 0, 6)
profilePage.BackgroundColor3 = Color3.fromRGB(255,255,255)
profilePage.BackgroundTransparency = 0.1
profilePage.Visible = false
profilePage.Parent = body

local pfCorner = Instance.new("UICorner")
pfCorner.CornerRadius = UDim.new(0, 10)
pfCorner.Parent = profilePage

local pfStroke = Instance.new("UIStroke")
pfStroke.Thickness = 1
pfStroke.Color = Color3.fromRGB(220,225,240)
pfStroke.Transparency = 0.4
pfStroke.Parent = profilePage

local pfHeader = Instance.new("Frame")
pfHeader.Name = "Header"
pfHeader.BackgroundTransparency = 1
pfHeader.Size = UDim2.new(1, -12, 0, 32)
pfHeader.Position = UDim2.new(0, 6, 0, 4)
pfHeader.Parent = profilePage

local pfTitle = Instance.new("TextLabel")
pfTitle.Name = "Title"
pfTitle.BackgroundTransparency = 1
pfTitle.Size = UDim2.new(1, -140, 1, 0)
pfTitle.Position = UDim2.new(0, 0, 0, 0)
pfTitle.Font = Enum.Font.GothamSemibold
pfTitle.TextSize = 15
pfTitle.TextXAlignment = Enum.TextXAlignment.Left
pfTitle.TextColor3 = Color3.fromRGB(40,40,70)
pfTitle.Text = "Profil Pemain"
pfTitle.Parent = pfHeader

local pfCopyBtn = glassChipButton("🔗 Copy Link")
pfCopyBtn.Name = "CopyLink"
pfCopyBtn.Size = UDim2.new(0, 90, 0, 24)
pfCopyBtn.Position = UDim2.new(1, -96, 0.5, -12)
pfCopyBtn.Parent = pfHeader

local pfScroll = Instance.new("ScrollingFrame")
pfScroll.Name = "ProfileScroll"
pfScroll.BackgroundTransparency = 1
pfScroll.BorderSizePixel = 0
pfScroll.ScrollBarThickness = 6
pfScroll.ScrollBarImageColor3 = Color3.fromRGB(150,155,175)
pfScroll.ScrollBarImageTransparency = 0.1
pfScroll.ScrollingDirection = Enum.ScrollingDirection.XY
pfScroll.Size = UDim2.new(1, -12, 1, -46)
pfScroll.Position = UDim2.new(0, 6, 0, 42)
pfScroll.Parent = profilePage

local pfList = Instance.new("Frame")
pfList.Name = "ProfileList"
pfList.BackgroundTransparency = 1
pfList.Size = UDim2.new(0, 720, 0, 0) -- lebar fix supaya bisa scroll horizontal
pfList.Position = UDim2.new(0, 2, 0, 0)
pfList.Parent = pfScroll

local pfLayout = Instance.new("UIListLayout")
pfLayout.FillDirection = Enum.FillDirection.Vertical
pfLayout.SortOrder = Enum.SortOrder.LayoutOrder
pfLayout.Padding = UDim.new(0, 4)
pfLayout.Parent = pfList

pfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    pfList.Size = UDim2.new(0, 720, 0, pfLayout.AbsoluteContentSize.Y)
    pfScroll.CanvasSize = UDim2.new(0, 720 + 8, 0, pfLayout.AbsoluteContentSize.Y + 8)
end)

local function clearProfile()
    for _, c in ipairs(pfList:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function profileUrl(userId)
    return string.format("https://www.roblox.com/id/users/%d/profile", userId)
end

local function copyOrAnnounce(url)
    local ok = pcall(function()
        if setclipboard then setclipboard(url) end
    end)
    if ok then
        StarterGui:SetCore("SendNotification", {
            Title = "Profil",
            Text  = "Link profil disalin.",
            Duration = 2
        })
    else
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "[Profile] "..url,
                Color = Color3.fromRGB(40,40,60),
                Font = Enum.Font.Gotham,
                TextSize = 14
            })
        end)
    end
end

------------------------------------------------------
-- TAB STATE
------------------------------------------------------
local activeTab = "Join" -- Join / Leave / Player / Profile
local activeProfileInfo = nil

local function setActiveTab(tabName)
    activeTab = tabName

    if tabName == "Join" then
        scrollJoin.Visible  = true
        scrollLeave.Visible = false
        scrollAll.Visible   = false
        profilePage.Visible = false
        searchWrap.Visible  = true
    elseif tabName == "Leave" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = true
        scrollAll.Visible   = false
        profilePage.Visible = false
        searchWrap.Visible  = true
    elseif tabName == "Player" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = false
        scrollAll.Visible   = true
        profilePage.Visible = false
        searchWrap.Visible  = true
    elseif tabName == "Profile" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = false
        scrollAll.Visible   = false
        profilePage.Visible = true
        searchWrap.Visible  = false
    end
end

local function markSeg(name)
    for key, btn in pairs(segButtons) do
        if not btn.Visible then continue end
        if key == name then
            btn.TextTransparency = 0
            btn.Font = Enum.Font.GothamSemibold
        else
            btn.TextTransparency = 0.2
            btn.Font = Enum.Font.Gotham
        end
    end
end

segButtons.Join.MouseButton1Click:Connect(function()
    markSeg("Join")
    setActiveTab("Join")
end)
segButtons.Leave.MouseButton1Click:Connect(function()
    markSeg("Leave")
    setActiveTab("Leave")
end)
segButtons.Player.MouseButton1Click:Connect(function()
    markSeg("Player")
    setActiveTab("Player")
end)
segButtons.Profile.MouseButton1Click:Connect(function()
    markSeg("Profile")
    setActiveTab("Profile")
end)

markSeg("Join")
setActiveTab("Join")

------------------------------------------------------
-- SEARCH FILTER
------------------------------------------------------
local function filterScroll(sf, q)
    local qlower = string.lower(q or "")
    for _, child in ipairs(sf:GetChildren()) do
        if child:IsA("TextButton") then
            if qlower == "" then
                child.Visible = true
            else
                local nL = child:GetAttribute("nameLower") or ""
                local uL = child:GetAttribute("userLower") or ""
                local text = ""
                local lbl = child:FindFirstChild("Text")
                if lbl and lbl:IsA("TextLabel") then
                    text = string.lower(lbl.Text)
                end
                local ok = string.find(nL, qlower, 1, true)
                    or string.find(uL, qlower, 1, true)
                    or string.find(text, qlower, 1, true)
                child.Visible = ok and true or false
            end
        end
    end
end

local function applySearchFilter()
    local q = searchBox.Text or ""
    filterScroll(scrollJoin,  q)
    filterScroll(scrollLeave, q)
    filterScroll(scrollAll,   q)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(applySearchFilter)

------------------------------------------------------
-- FRIEND / KONEKSI DETECTION
------------------------------------------------------
local friendSet = {}

local function seedFriends()
    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(LocalPlayer.UserId)
    end)
    if not ok or not pages then return end

    repeat
        for _, info in ipairs(pages:GetCurrentPage()) do
            if info and type(info) == "table" and info.Id then
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

local function isFriendUserId(uid)
    if not uid then return false end
    if friendSet[uid] then return true end
    local ok, res = pcall(function()
        return LocalPlayer:IsFriendsWith(uid)
    end)
    if ok and res then
        friendSet[uid] = true
        return true
    end
    return false
end

------------------------------------------------------
-- LOG ITEM MAKERS (rows lebar fix supaya bisa scroll horizontal)
------------------------------------------------------
local ROW_WIDTH = 720

local function getAvatar(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    return ok and content or ""
end

local function glassRowBase(row)
    row.BackgroundColor3 = Color3.fromRGB(255,255,255)
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = row
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(220,225,240)
    s.Transparency = 0.45
    s.Parent = row
end

local function makeJoinLeaveItem(parentScroll, info, kind)
    local row = Instance.new("TextButton")
    row.Name = string.format("%s_%d_%d", kind, info.userId, math.floor(os.clock()*100))
    row.AutoButtonColor = false
    row.Text = ""
    row.Size = UDim2.new(0, ROW_WIDTH, 0, 42) -- width fix => bisa scroll horizontal
    row.Parent = parentScroll
    glassRowBase(row)

    row:SetAttribute("nameLower", string.lower(info.displayName or info.name or ""))
    row:SetAttribute("userLower", string.lower(info.name or ""))

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = (kind == "Join") and Color3.fromRGB(62,201,89) or Color3.fromRGB(230,76,76)
    accent.BorderSizePixel = 0
    accent.Parent = row

    local img = Instance.new("ImageLabel")
    img.Name = "Avatar"
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(0, 28, 0, 28)
    img.Position = UDim2.new(0, 8, 0.5, -14)
    img.Image = getAvatar(info.userId)
    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 14)
    ic.Parent = img
    img.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Text"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 44, 0, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.TextColor3 = Color3.fromRGB(40,40,70)
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Text = string.format("%s  (@%s)", info.displayName or info.name, info.name)
    lbl.Parent = row

    local linkBtn = glassChipButton("🔗")
    linkBtn.Size = UDim2.new(0, 32, 0, 22)
    linkBtn.Position = UDim2.new(1, -40, 0.5, -11)
    linkBtn.Parent = row

    linkBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        activeProfileInfo = info
        segButtons.Profile.Visible = true
        layoutSegments()
        markSeg("Profile")
        setActiveTab("Profile")
    end)

    return row
end

local function makeAllItem(parentScroll, info)
    local row = Instance.new("TextButton")
    row.Name = "All_"..tostring(info.userId)
    row.AutoButtonColor = false
    row.Text = ""
    row.Size = UDim2.new(0, ROW_WIDTH, 0, 42)
    row.Parent = parentScroll
    glassRowBase(row)

    row:SetAttribute("nameLower", string.lower(info.displayName or info.name or ""))
    row:SetAttribute("userLower", string.lower(info.name or ""))

    local img = Instance.new("ImageLabel")
    img.Name = "Avatar"
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(0, 28, 0, 28)
    img.Position = UDim2.new(0, 8, 0.5, -14)
    img.Image = getAvatar(info.userId)
    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 14)
    ic.Parent = img
    img.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Text"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 44, 0, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.TextColor3 = Color3.fromRGB(40,40,70)
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Text = string.format("%s  (@%s)", info.displayName or info.name, info.name)
    lbl.Parent = row

    local linkBtn = glassChipButton("🔗")
    linkBtn.Size = UDim2.new(0, 32, 0, 22)
    linkBtn.Position = UDim2.new(1, -40, 0.5, -11)
    linkBtn.Parent = row
    linkBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        activeProfileInfo = info
        segButtons.Profile.Visible = true
        layoutSegments()
        markSeg("Profile")
        setActiveTab("Profile")
    end)

    return row
end

------------------------------------------------------
-- PROFILE RENDER
------------------------------------------------------
local joinTimes = {}  -- userId -> os.time() join lokal

local function durHMS(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec/3600)
    sec = sec % 3600
    local m = math.floor(sec/60)
    sec = sec % 60
    return string.format("%02d:%02d:%02d", h, m, sec)
end

local function renderProfile(info)
    if not info then return end
    clearProfile()

    local plr = Players:GetPlayerByUserId(info.userId)

    pfTitle.Text = string.format("%s  (@%s)", info.displayName or info.name, info.name)

    local rowName,  vName  = makeFieldRow(pfList, "Display Name")
    vName.Text = info.displayName or info.name

    local rowUser, vUser = makeFieldRow(pfList, "Username")
    vUser.Text = "@"..tostring(info.name)

    local rowId,   vId   = makeFieldRow(pfList, "UserId")
    vId.Text = tostring(info.userId)

    local rowMem, vMem = makeFieldRow(pfList, "Membership")
    local member = "-"
    if plr and plr.MembershipType then
        if plr.MembershipType == Enum.MembershipType.Premium then
            member = "Premium"
        elseif plr.MembershipType == Enum.MembershipType.None then
            member = "None"
        else
            member = tostring(plr.MembershipType):gsub("Enum%.MembershipType%.","")
        end
    end
    vMem.Text = member

    local ageDays = plr and plr.AccountAge or nil
    local rowAge, vAge = makeFieldRow(pfList, "Umur Akun (hari)")
    if ageDays then
        vAge.Text = string.format("%d hari", ageDays)
    else
        vAge.Text = "-"
    end

    local joinedRow, vJoined = makeFieldRow(pfList, "Join Server (lokal)")
    local durRow,    vDur    = makeFieldRow(pfList, "Durasi di Server (lokal)")

    if joinTimes[info.userId] then
        local t = os.date("*t", joinTimes[info.userId])
        vJoined.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
        vDur.Text = durHMS(os.time() - joinTimes[info.userId])
    else
        vJoined.Text = "-"
        vDur.Text = "-"
    end

    local linkRow, vLink = makeFieldRow(pfList, "Link Profil")
    local url = profileUrl(info.userId)
    vLink.Text = url

    pfCopyBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(url)
    end)

    if joinTimes[info.userId] then
        task.spawn(function()
            while activeTab == "Profile" and profilePage.Visible and joinTimes[info.userId] do
                vDur.Text = durHMS(os.time() - joinTimes[info.userId])
                task.wait(1)
            end
        end)
    end
end

------------------------------------------------------
-- ROSTER & EVENTS
------------------------------------------------------
local allRows = {}  -- userId -> row di Player tab

local function snapshot()
    local map = {}
    for _, p in ipairs(Players:GetPlayers()) do
        map[p.UserId] = {
            userId = p.UserId,
            name = p.Name,
            displayName = p.DisplayName
        }
    end
    return map
end

local function rebuildAll(nowMap)
    for _, row in pairs(allRows) do
        if row and row.Parent then row:Destroy() end
    end
    allRows = {}
    local list = {}
    for _, info in pairs(nowMap) do
        table.insert(list, info)
    end
    table.sort(list, function(a,b)
        local ad = string.lower(a.displayName or a.name or "")
        local bd = string.lower(b.displayName or b.name or "")
        if ad == bd then
            return (a.name or "") < (b.name or "")
        end
        return ad < bd
    end)
    for i, info in ipairs(list) do
        local row = makeAllItem(scrollAll, info)
        row.LayoutOrder = i
        allRows[info.userId] = row
    end
    applySearchFilter()
end

local function upsertAll(info)
    rebuildAll(snapshot())
end

local function removeFromAll(uid)
    if allRows[uid] and allRows[uid].Parent then
        allRows[uid]:Destroy()
    end
    allRows[uid] = nil
end

-- Initial seed
local initialSnap = snapshot()
local nowTs = os.time()
for uid,_ in pairs(initialSnap) do
    joinTimes[uid] = nowTs
end
rebuildAll(initialSnap)

-- JOIN / LEAVE HANDLERS
local function handlePlayerJoin(p)
    if p == LocalPlayer then return end

    local info = {
        userId = p.UserId,
        name = p.Name,
        displayName = p.DisplayName
    }

    joinTimes[p.UserId] = os.time()

    makeJoinLeaveItem(scrollJoin, info, "Join")
    upsertAll(info)

    local isConn = isFriendUserId(p.UserId)
    local msg
    if isConn then
        msg = string.format("%s (@%s) koneksi anda bergabung dalam map", info.displayName or info.name, info.name)
    else
        msg = string.format("%s (@%s) bergabung dalam map", info.displayName or info.name, info.name)
    end
    pushToast("join", msg)
    playJoinSound()
end

local function handlePlayerLeave(p)
    if p == LocalPlayer then return end

    local info = {
        userId = p.UserId,
        name = p.Name,
        displayName = p.DisplayName
    }

    makeJoinLeaveItem(scrollLeave, info, "Leave")
    removeFromAll(p.UserId)

    local isConn = isFriendUserId(p.UserId)
    local msg
    if isConn then
        msg = string.format("%s (@%s) koneksi anda keluar dari map", info.displayName or info.name, info.name)
    else
        msg = string.format("%s (@%s) keluar dari map", info.displayName or info.name, info.name)
    end
    pushToast("leave", msg)
    playLeaveSound()
end

Players.PlayerAdded:Connect(handlePlayerJoin)
Players.PlayerRemoving:Connect(handlePlayerLeave)

------------------------------------------------------
-- AUTO-RENDER PROFILE SAAT TAB PROFILE
------------------------------------------------------
task.spawn(function()
    while true do
        if activeTab == "Profile" and activeProfileInfo then
            renderProfile(activeProfileInfo)
            activeProfileInfo = nil
        end
        task.wait(0.2)
    end
end)
