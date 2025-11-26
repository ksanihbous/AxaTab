--==========================================================
--  10AxaTab_JoinLeave.lua
--  TAB 10: "Join/Leave Notif"
--  Env dari CORE:
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, TweenService, HttpService,
--    UserInputService, StarterGui, CoreGui, Camera (opsional)
--==========================================================

local frame        = TAB_FRAME
local Players      = Players
local LocalPlayer  = LocalPlayer
local RunService   = RunService
local TweenService = TweenService
local UserInputService = UserInputService
local StarterGui   = StarterGui
local Camera       = Camera or workspace.CurrentCamera

local SoundService = game:GetService("SoundService")
local TextService  = game:GetService("TextService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------
-- TWEEN UTIL
------------------------------------------------------
local function AXA_Tween(obj, time, goal)
    local info = TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, goal)
    tw:Play()
    return tw
end

------------------------------------------------------
-- TOAST NOTIF (ScreenGui terpisah, 1x saja)
------------------------------------------------------
do
    local old = PlayerGui:FindFirstChild("AxaJoinLeaveToast")
    if old then old:Destroy() end
end

local ToastGui = Instance.new("ScreenGui")
ToastGui.Name = "AxaJoinLeaveToast"
ToastGui.IgnoreGuiInset = true
ToastGui.ResetOnSpawn = false
ToastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToastGui.DisplayOrder = 999999
ToastGui.Parent = PlayerGui

local ToastRoot = Instance.new("Frame")
ToastRoot.Name = "Root"
ToastRoot.BackgroundTransparency = 1
ToastRoot.Size = UDim2.new(1, 0, 1, 0)
ToastRoot.Parent = ToastGui

local TOAST_W, TOAST_H = 560, 60
local TOAST_MARGIN_Y   = 72
local TOAST_IN, TOAST_OUT, TOAST_STAY = 0.22, 0.18, 2.4

local ToastCard = Instance.new("Frame")
ToastCard.Name = "Card"
ToastCard.AnchorPoint = Vector2.new(0.5, 0)
ToastCard.Size = UDim2.fromOffset(TOAST_W, TOAST_H)
ToastCard.Position = UDim2.new(0.5, 0, 0, -TOAST_H)
ToastCard.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
ToastCard.BackgroundTransparency = 1
ToastCard.BorderSizePixel = 0
ToastCard.Visible = false
ToastCard.Parent = ToastRoot

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 14)
cCorner.Parent = ToastCard

local cStroke = Instance.new("UIStroke")
cStroke.Thickness = 1
cStroke.Color = Color3.fromRGB(255,255,255)
cStroke.Transparency = 1
cStroke.Parent = ToastCard

local cShadow = Instance.new("ImageLabel")
cShadow.Name = "Shadow"
cShadow.AnchorPoint = Vector2.new(0.5, 0.5)
cShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
cShadow.Size = UDim2.new(1, 24, 1, 24)
cShadow.BackgroundTransparency = 1
cShadow.Image = "rbxassetid://1316045217"
cShadow.ImageTransparency = 1
cShadow.ScaleType = Enum.ScaleType.Slice
cShadow.SliceCenter = Rect.new(10,10,118,118)
cShadow.Parent = ToastCard

local cAccent = Instance.new("Frame")
cAccent.Name = "Accent"
cAccent.Size = UDim2.new(0, 5, 1, 0)
cAccent.Position = UDim2.new(0, 0, 0, 0)
cAccent.BackgroundColor3 = Color3.fromRGB(62,201,89)
cAccent.BackgroundTransparency = 1
cAccent.BorderSizePixel = 0
cAccent.Parent = ToastCard

local cText = Instance.new("TextLabel")
cText.Name = "Text"
cText.BackgroundTransparency = 1
cText.Size = UDim2.new(1, -18, 1, 0)
cText.Position = UDim2.new(0, 12, 0, 0)
cText.Font = Enum.Font.GothamMedium
cText.TextSize = 16
cText.TextColor3 = Color3.fromRGB(235,235,235)
cText.TextTransparency = 1
cText.TextXAlignment = Enum.TextXAlignment.Left
cText.TextYAlignment = Enum.TextYAlignment.Center
cText.TextTruncate = Enum.TextTruncate.AtEnd
cText.Parent = ToastCard

local notifEnabled = true
local soundEnabled = true
local BASE_SOUND_ID = "rbxassetid://6026984224"

local toastQueue = {}
local toastBusy  = false

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

local function playJoinSound()  playOneShot(1.12) end
local function playLeaveSound() playOneShot(0.9)  end

local function showToast(kind, msg)
    if not notifEnabled then return end

    cAccent.BackgroundColor3 = (kind == "leave")
        and Color3.fromRGB(230,76,76)
        or  Color3.fromRGB(62,201,89)

    cText.Text = msg or ""

    ToastCard.Position = UDim2.new(0.5, 0, 0, -TOAST_H)
    ToastCard.BackgroundTransparency = 1
    cStroke.Transparency = 1
    cAccent.BackgroundTransparency = 1
    cText.TextTransparency = 1
    cShadow.ImageTransparency = 1
    ToastCard.Visible = true

    AXA_Tween(ToastCard, TOAST_IN, {Position = UDim2.new(0.5, 0, 0, TOAST_MARGIN_Y), BackgroundTransparency = 0.18})
    AXA_Tween(cStroke, TOAST_IN,   {Transparency = 0.65})
    AXA_Tween(cAccent, TOAST_IN,   {BackgroundTransparency = 0})
    AXA_Tween(cText,   TOAST_IN+0.05, {TextTransparency = 0})
    AXA_Tween(cShadow, TOAST_IN,   {ImageTransparency = 0.75})

    if kind == "join" then
        playJoinSound()
    else
        playLeaveSound()
    end

    task.wait(TOAST_STAY)

    AXA_Tween(ToastCard, TOAST_OUT, {Position = UDim2.new(0.5, 0, 0, -TOAST_H), BackgroundTransparency = 1})
    AXA_Tween(cStroke, TOAST_OUT,   {Transparency = 1})
    AXA_Tween(cAccent, TOAST_OUT,   {BackgroundTransparency = 1})
    AXA_Tween(cText,   TOAST_OUT,   {TextTransparency = 1})
    AXA_Tween(cShadow, TOAST_OUT,   {ImageTransparency = 1})

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
-- UI HELPERS
------------------------------------------------------
local function glassChipButton(text)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = true
    b.Size = UDim2.new(0, 90, 0, 24)
    b.BackgroundColor3 = Color3.fromRGB(255,255,255)
    b.BackgroundTransparency = 0.2
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
    s.Color = Color3.fromRGB(200,205,230)
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
    lbl.TextColor3 = Color3.fromRGB(90, 90, 130)
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
    val.TextColor3 = Color3.fromRGB(30,30,50)
    val.Text = "-"
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Parent = row

    return row, val
end

local function glassRowBase(row)
    row.BackgroundColor3 = Color3.fromRGB(255,255,255)
    row.BackgroundTransparency = 0.15
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

local function getAvatar(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    return ok and content or ""
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
-- HEADER + BODY FRAME DI TAB
------------------------------------------------------
frame:ClearAllChildren()

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -10, 0, 24)
title.Position = UDim2.new(0, 5, 0, 6)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(40,40,70)
title.Text = "📡 Join / Leave Notif & Player Log"
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, -10, 0, 30)
subtitle.Position = UDim2.new(0, 5, 0, 30)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextYAlignment = Enum.TextYAlignment.Top
subtitle.TextColor3 = Color3.fromRGB(100, 100, 140)
subtitle.Text = "Pantau siapa yang bergabung/keluar map, daftar pemain aktif, dan detail koneksi (friend) kamu."
subtitle.Parent = frame

local headerBar = Instance.new("Frame")
headerBar.Name = "HeaderBar"
headerBar.Size = UDim2.new(1, -10, 0, 32)
headerBar.Position = UDim2.new(0, 5, 0, 62)
headerBar.BackgroundColor3 = Color3.fromRGB(245,247,255)
headerBar.BackgroundTransparency = 0
headerBar.BorderSizePixel = 0
headerBar.Parent = frame

local hbCorner = Instance.new("UICorner")
hbCorner.CornerRadius = UDim.new(0, 8)
hbCorner.Parent = headerBar

local hbStroke = Instance.new("UIStroke")
hbStroke.Thickness = 1
hbStroke.Color = Color3.fromRGB(215,220,240)
hbStroke.Transparency = 0.4
hbStroke.Parent = headerBar

-- Sound icon (🔊)
local soundBtn = glassChipButton("🔊")
soundBtn.Name = "SoundBtn"
soundBtn.Size = UDim2.new(0, 40, 0, 24)
soundBtn.Position = UDim2.new(0, 6, 0.5, -12)
soundBtn.Parent = headerBar

local function refreshSoundBtn()
    soundBtn.Text = soundEnabled and "🔊" or "🔇"
    soundBtn.BackgroundTransparency = soundEnabled and 0.1 or 0.3
    soundBtn.TextColor3 = soundEnabled and Color3.fromRGB(30,120,70) or Color3.fromRGB(150,50,50)
end
refreshSoundBtn()

soundBtn.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled
    refreshSoundBtn()
end)

-- Notif ON/OFF
local notifBtn = glassChipButton("NOTIF: ON")
notifBtn.Name = "NotifBtn"
notifBtn.Size = UDim2.new(0, 90, 0, 24)
notifBtn.Position = UDim2.new(1, -96, 0.5, -12)
notifBtn.Parent = headerBar

local function refreshNotifBtn()
    notifBtn.Text = notifEnabled and "NOTIF: ON" or "NOTIF: OFF"
    notifBtn.BackgroundTransparency = notifEnabled and 0.1 or 0.3
    notifBtn.TextColor3 = notifEnabled and Color3.fromRGB(30,120,70) or Color3.fromRGB(150,50,50)
end
refreshNotifBtn()

notifBtn.MouseButton1Click:Connect(function()
    notifEnabled = not notifEnabled
    refreshNotifBtn()
end)

-- Segmented tab buttons (Join / Leave / Player / Profile)
local segContainer = Instance.new("Frame")
segContainer.Name = "SegContainer"
segContainer.BackgroundTransparency = 1
segContainer.Size = UDim2.new(0, 260, 1, 0)
segContainer.Position = UDim2.new(0.5, -130, 0, 0)
segContainer.Parent = headerBar

local segLayout = Instance.new("UIListLayout")
segLayout.FillDirection = Enum.FillDirection.Horizontal
segLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
segLayout.VerticalAlignment = Enum.VerticalAlignment.Center
segLayout.Padding = UDim.new(0, 6)
segLayout.Parent = segContainer

local segButtons = {}

local function createSeg(name, label)
    local b = glassChipButton(label)
    b.Name = name
    b.Size = UDim2.new(0, 60, 0, 24)
    b.Parent = segContainer
    return b
end

segButtons.Join    = createSeg("SegJoin",   "Join")
segButtons.Leave   = createSeg("SegLeave",  "Leave")
segButtons.Player  = createSeg("SegPlayer", "Player")
segButtons.Profile = createSeg("SegProfile","Profile")
segButtons.Profile.Visible = false

local activeTab = "Join"

local function markSeg(name)
    for key, b in pairs(segButtons) do
        if not b.Visible then continue end
        if key == name then
            b.Font = Enum.Font.GothamSemibold
            b.TextTransparency = 0
        else
            b.Font = Enum.Font.Gotham
            b.TextTransparency = 0.3
        end
    end
end

------------------------------------------------------
-- BODY FRAME + SEARCH BAR
------------------------------------------------------
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -10, 1, -104)
body.Position = UDim2.new(0, 5, 0, 96)
body.BackgroundColor3 = Color3.fromRGB(248,249,255)
body.BackgroundTransparency = 0
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

local SEARCH_H = 28

local searchWrap = Instance.new("Frame")
searchWrap.Name = "SearchWrap"
searchWrap.BackgroundTransparency = 1
searchWrap.Size = UDim2.new(1, -12, 0, SEARCH_H)
searchWrap.Position = UDim2.new(0, 6, 0, 6)
searchWrap.Parent = body

local searchBg = Instance.new("Frame")
searchBg.Name = "SearchBg"
searchBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
searchBg.BackgroundTransparency = 0.1
searchBg.BorderSizePixel = 0
searchBg.Size = UDim2.new(1, 0, 1, 0)
searchBg.Parent = searchWrap

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 8)
sbCorner.Parent = searchBg

local sbStroke = Instance.new("UIStroke")
sbStroke.Thickness = 1
sbStroke.Color = Color3.fromRGB(210,214,235)
sbStroke.Transparency = 0.45
sbStroke.Parent = searchBg

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.BackgroundTransparency = 1
searchBox.Size = UDim2.new(1, -12, 1, 0)
searchBox.Position = UDim2.new(0, 6, 0, 0)
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(40,40,70)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.PlaceholderText = "Search User/DisplayName"
searchBox.PlaceholderColor3 = Color3.fromRGB(130,136,150)
searchBox.Text = ""
searchBox.Parent = searchBg

------------------------------------------------------
-- SCROLLING LIST (Join / Leave / Player) - VERTIKAL SANTAI
------------------------------------------------------
local function newListScroll(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 6
    sf.ScrollBarImageColor3 = Color3.fromRGB(150,155,175)
    sf.ScrollBarImageTransparency = 0.1
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.ElasticBehavior = Enum.ElasticBehavior.Never
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.Parent = body

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = sf

    return sf, layout
end

local listJoin,  layoutJoin  = newListScroll("ListJoin")
local listLeave, layoutLeave = newListScroll("ListLeave")
local listPlayer,layoutPlayer= newListScroll("ListPlayer")

local function layoutLists()
    local top = SEARCH_H + 12
    local h   = body.AbsoluteSize.Y - top - 6
    h = math.max(0, h)

    for _, sf in ipairs({listJoin, listLeave, listPlayer}) do
        sf.Position = UDim2.new(0, 6, 0, top)
        sf.Size     = UDim2.new(1, -12, 0, h)
    end
end
body:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutLists)
layoutLists()

listJoin.Visible  = true
listLeave.Visible = false
listPlayer.Visible= false

------------------------------------------------------
-- PROFILE PAGE: VERTIKAL ONLY, NYAMAN
------------------------------------------------------
local profilePage = Instance.new("Frame")
profilePage.Name = "ProfilePage"
profilePage.BackgroundColor3 = Color3.fromRGB(255,255,255)
profilePage.BackgroundTransparency = 0
profilePage.BorderSizePixel = 0
profilePage.Size = UDim2.new(1, -12, 1, -12)
profilePage.Position = UDim2.new(0, 6, 0, 6)
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
pfHeader.Size = UDim2.new(1, -12, 0, 30)
pfHeader.Position = UDim2.new(0, 6, 0, 4)
pfHeader.Parent = profilePage

local pfTitle = Instance.new("TextLabel")
pfTitle.Name = "Title"
pfTitle.BackgroundTransparency = 1
pfTitle.Size = UDim2.new(1, -110, 1, 0)
pfTitle.Position = UDim2.new(0, 0, 0, 0)
pfTitle.Font = Enum.Font.GothamSemibold
pfTitle.TextSize = 15
pfTitle.TextXAlignment = Enum.TextXAlignment.Left
pfTitle.TextColor3 = Color3.fromRGB(40,40,70)
pfTitle.Text = "Profil Pemain"
pfTitle.Parent = pfHeader

local pfCopyBtn = glassChipButton("🔗 Link")
pfCopyBtn.Name = "CopyLink"
pfCopyBtn.Size = UDim2.new(0, 80, 0, 24)
pfCopyBtn.Position = UDim2.new(1, -84, 0.5, -12)
pfCopyBtn.Parent = pfHeader

local pfScroll = Instance.new("ScrollingFrame")
pfScroll.Name = "ProfileScroll"
pfScroll.BackgroundTransparency = 1
pfScroll.BorderSizePixel = 0
pfScroll.ScrollBarThickness = 6
pfScroll.ScrollBarImageColor3 = Color3.fromRGB(150,155,175)
pfScroll.ScrollBarImageTransparency = 0.1
pfScroll.ScrollingDirection = Enum.ScrollingDirection.Y
pfScroll.ElasticBehavior = Enum.ElasticBehavior.Never
pfScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
pfScroll.CanvasSize = UDim2.new(0,0,0,0)
pfScroll.Size = UDim2.new(1, -12, 1, -46)
pfScroll.Position = UDim2.new(0, 6, 0, 38)
pfScroll.Parent = profilePage

local pfList = Instance.new("Frame")
pfList.Name = "ProfileList"
pfList.BackgroundTransparency = 1
pfList.Size = UDim2.new(1, -8, 0, 0)
pfList.Position = UDim2.new(0, 4, 0, 0)
pfList.Parent = pfScroll

local pfLayout = Instance.new("UIListLayout")
pfLayout.FillDirection = Enum.FillDirection.Vertical
pfLayout.SortOrder = Enum.SortOrder.LayoutOrder
pfLayout.Padding = UDim.new(0, 4)
pfLayout.Parent = pfList

pfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    pfList.Size = UDim2.new(1, -8, 0, pfLayout.AbsoluteContentSize.Y)
end)

local function clearProfile()
    for _, c in ipairs(pfList:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

------------------------------------------------------
-- TAB SWITCH
------------------------------------------------------
local function setActiveTab(name)
    activeTab = name

    if name == "Join" then
        listJoin.Visible   = true
        listLeave.Visible  = false
        listPlayer.Visible = false
        profilePage.Visible= false
        searchWrap.Visible = true
    elseif name == "Leave" then
        listJoin.Visible   = false
        listLeave.Visible  = true
        listPlayer.Visible = false
        profilePage.Visible= false
        searchWrap.Visible = true
    elseif name == "Player" then
        listJoin.Visible   = false
        listLeave.Visible  = false
        listPlayer.Visible = true
        profilePage.Visible= false
        searchWrap.Visible = true
    elseif name == "Profile" then
        listJoin.Visible   = false
        listLeave.Visible  = false
        listPlayer.Visible = false
        profilePage.Visible= true
        searchWrap.Visible = false
    end
end

markSeg("Join")
setActiveTab("Join")

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

------------------------------------------------------
-- FRIEND/KONEKSI DETECTION
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

local function getFriendStatusSafe(targetPlayer)
    local ok, st = pcall(function()
        return LocalPlayer:GetFriendStatus(targetPlayer)
    end)
    return ok and st or Enum.FriendStatus.Unknown
end

local function sendFriendRequestSafe(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then
        return false, "Target tidak ditemukan / sudah keluar."
    end
    if targetPlayer == LocalPlayer then
        return false, "Tidak bisa mengirim ke diri sendiri."
    end

    local st = getFriendStatusSafe(targetPlayer)
    if st == Enum.FriendStatus.Friend then
        return false, "Kalian sudah berteman."
    elseif st == Enum.FriendStatus.FriendRequestSent then
        return false, "Permintaan sudah terkirim sebelumnya."
    elseif st == Enum.FriendStatus.FriendRequestReceived then
        return false, "Mereka sudah kirim permintaan — terima via overlay Roblox."
    end

    local ok, err = pcall(function()
        if LocalPlayer.RequestFriendship then
            LocalPlayer:RequestFriendship(targetPlayer)
        else
            Players:RequestFriendship(LocalPlayer, targetPlayer)
        end
    end)
    if not ok then
        return false, "Gagal memanggil API: "..tostring(err)
    end

    local t0 = os.clock()
    while os.clock() - t0 < 2.0 do
        RunService.Heartbeat:Wait()
        local now = getFriendStatusSafe(targetPlayer)
        if now == Enum.FriendStatus.FriendRequestSent or now == Enum.FriendStatus.Friend then
            return true
        end
    end

    return false, "Tidak ada konfirmasi (mungkin rate-limit / privasi / limit teman)."
end

local function revokeFriendshipSafe(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then
        return false, "Target tidak ditemukan / sudah keluar."
    end
    local st = getFriendStatusSafe(targetPlayer)
    if st ~= Enum.FriendStatus.Friend then
        return false, "Belum berteman."
    end

    local ok, err = pcall(function()
        if LocalPlayer.RevokeFriendship then
            LocalPlayer:RevokeFriendship(targetPlayer)
        else
            Players:RevokeFriendship(LocalPlayer, targetPlayer)
        end
    end)
    if not ok then
        return false, "Gagal menghapus pertemanan: "..tostring(err)
    end

    local t0 = os.clock()
    while os.clock() - t0 < 2.0 do
        RunService.Heartbeat:Wait()
        if getFriendStatusSafe(targetPlayer) ~= Enum.FriendStatus.Friend then
            return true
        end
    end

    return false, "Tidak ada konfirmasi (jaringan/rate-limit)."
end

local function statusToText(st)
    if st == Enum.FriendStatus.Friend then
        return "✅ Sudah berteman"
    elseif st == Enum.FriendStatus.NotFriend then
        return "❌ Belum berteman"
    elseif st == Enum.FriendStatus.FriendRequestSent then
        return "📨 Permintaan terkirim"
    elseif st == Enum.FriendStatus.FriendRequestReceived then
        return "📥 Permintaan masuk"
    else
        return "Tidak diketahui"
    end
end

------------------------------------------------------
-- JOIN / LEAVE / PLAYER ROWS
------------------------------------------------------
local joinTimes  = {}   -- userId -> waktu join lokal (os.time())
local playerRows = {}   -- userId -> row (di tab Player)

local function makeJoinLeaveRow(parent, info, kind)
    local row = Instance.new("TextButton")
    row.Name = string.format("%s_%d_%d", kind, info.userId, math.floor(os.clock()*100))
    row.AutoButtonColor = true
    row.Text = ""
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundTransparency = 0
    row.Parent = parent
    glassRowBase(row)

    row:SetAttribute("nameLower", string.lower(info.displayName or info.name or ""))
    row:SetAttribute("userLower", string.lower(info.name or ""))

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = (kind == "Join")
        and Color3.fromRGB(62,201,89)
        or  Color3.fromRGB(230,76,76)
    accent.BorderSizePixel = 0
    accent.Parent = row

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.BackgroundTransparency = 1
    avatar.Size = UDim2.new(0, 28, 0, 28)
    avatar.Position = UDim2.new(0, 8, 0.5, -14)
    avatar.Image = getAvatar(info.userId)
    local ac = Instance.new("UICorner")
    ac.CornerRadius = UDim.new(0, 14)
    ac.Parent = avatar
    avatar.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Text"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -96, 1, 0)
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
    linkBtn.Position = UDim2.new(1, -38, 0.5, -11)
    linkBtn.Parent = row

    linkBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        -- buka profile
        segButtons.Profile.Visible = true
        markSeg("Profile")
        setActiveTab("Profile")
        local openedInfo = {
            userId = info.userId,
            name = info.name,
            displayName = info.displayName
        }
        clearProfile()
        -- render akan dipanggil di bawah
        -- untuk memastikan info fresh
        local p = Players:GetPlayerByUserId(openedInfo.userId)
        if p then
            openedInfo.name = p.Name
            openedInfo.displayName = p.DisplayName
        end
        -- panggil renderer
        -- (fungsi didefinisikan setelah deklarasi)
        _G.__AxaJoinLeave_RenderProfile(openedInfo)
    end)

    return row
end

local function makePlayerRow(parent, info)
    local row = Instance.new("TextButton")
    row.Name = "Player_"..tostring(info.userId)
    row.AutoButtonColor = true
    row.Text = ""
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundTransparency = 0
    row.Parent = parent
    glassRowBase(row)

    row:SetAttribute("nameLower", string.lower(info.displayName or info.name or ""))
    row:SetAttribute("userLower", string.lower(info.name or ""))

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.BackgroundTransparency = 1
    avatar.Size = UDim2.new(0, 28, 0, 28)
    avatar.Position = UDim2.new(0, 8, 0.5, -14)
    avatar.Image = getAvatar(info.userId)
    local ac = Instance.new("UICorner")
    ac.CornerRadius = UDim.new(0, 14)
    ac.Parent = avatar
    avatar.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Text"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -96, 1, 0)
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
    linkBtn.Position = UDim2.new(1, -38, 0.5, -11)
    linkBtn.Parent = row

    linkBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        segButtons.Profile.Visible = true
        markSeg("Profile")
        setActiveTab("Profile")
        local openedInfo = {
            userId = info.userId,
            name = info.name,
            displayName = info.displayName
        }
        local p = Players:GetPlayerByUserId(openedInfo.userId)
        if p then
            openedInfo.name = p.Name
            openedInfo.displayName = p.DisplayName
        end
        _G.__AxaJoinLeave_RenderProfile(openedInfo)
    end)

    return row
end

------------------------------------------------------
-- SEARCH FILTER
------------------------------------------------------
local function filterList(sf, q)
    local ql = string.lower(q or "")
    for _, child in ipairs(sf:GetChildren()) do
        if child:IsA("TextButton") then
            if ql == "" then
                child.Visible = true
            else
                local nL = child:GetAttribute("nameLower") or ""
                local uL = child:GetAttribute("userLower") or ""
                local txt = ""
                local lbl = child:FindFirstChild("Text")
                if lbl and lbl:IsA("TextLabel") then
                    txt = string.lower(lbl.Text)
                end
                local ok = string.find(nL, ql, 1, true)
                    or string.find(uL, ql, 1, true)
                    or string.find(txt, ql, 1, true)
                child.Visible = ok and true or false
            end
        end
    end
end

local function applySearch()
    local q = searchBox.Text or ""
    filterList(listJoin, q)
    filterList(listLeave, q)
    filterList(listPlayer, q)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

------------------------------------------------------
-- PROFILE RENDER (di-export ke _G biar bisa dipanggil row)
------------------------------------------------------
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

    local rowName, vName = makeFieldRow(pfList, "Display Name")
    vName.Text = info.displayName or info.name

    local rowUser, vUser = makeFieldRow(pfList, "Username")
    vUser.Text = "@"..tostring(info.name)

    local rowId, vId = makeFieldRow(pfList, "UserId")
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

    local rowJoinLoc, vJoinLoc = makeFieldRow(pfList, "Join Server (lokal)")
    local rowDurLoc,  vDurLoc  = makeFieldRow(pfList, "Durasi di Server (lokal)")

    if joinTimes[info.userId] then
        local t = os.date("*t", joinTimes[info.userId])
        vJoinLoc.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
        vDurLoc.Text  = durHMS(os.time() - joinTimes[info.userId])
    else
        vJoinLoc.Text = "-"
        vDurLoc.Text  = "-"
    end

    local rowLink, vLink = makeFieldRow(pfList, "Link Profil")
    local url = profileUrl(info.userId)
    vLink.Text = url

    pfCopyBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(url)
    end)

    -- STATUS KONEKSI
    local rowConn, vConn = makeFieldRow(pfList, "Status Koneksi")

    local function refreshConnLabel()
        if not plr then
            vConn.Text = "❓ Pemain tidak ada di server"
            return
        end
        local st = getFriendStatusSafe(plr)
        vConn.Text = statusToText(st)
    end

    refreshConnLabel()

    -- ROW TOMBOL: Tambah / Hapus Koneksi
    local rowBtn = Instance.new("Frame")
    rowBtn.Name = "Row_KoneksiActions"
    rowBtn.BackgroundTransparency = 1
    rowBtn.Size = UDim2.new(1, 0, 0, 32)
    rowBtn.Parent = pfList

    local btnAdd = glassChipButton("Tambah Koneksi")
    btnAdd.Size = UDim2.new(0, 130, 0, 24)
    btnAdd.Position = UDim2.new(0, 0, 0.5, -12)
    btnAdd.Parent = rowBtn

    local btnDel = glassChipButton("Hapus Koneksi")
    btnDel.Size = UDim2.new(0, 120, 0, 24)
    btnDel.Position = UDim2.new(0, 140, 0.5, -12)
    btnDel.Parent = rowBtn

    -- warna merah untuk hapus
    do
        local s = btnDel:FindFirstChildOfClass("UIStroke")
        if s then
            s.Color = Color3.fromRGB(230,76,76)
        end
        btnDel.TextColor3 = Color3.fromRGB(150,40,40)
    end

    local function setBtnState(btn, enabled, label)
        btn.Active = enabled
        btn.AutoButtonColor = enabled
        btn.TextTransparency = enabled and 0 or 0.4
        if label then btn.Text = label end
    end

    local function refreshButtons()
        if not plr then
            setBtnState(btnAdd, false)
            setBtnState(btnDel, false)
            return
        end
        local st = getFriendStatusSafe(plr)
        if st == Enum.FriendStatus.Friend then
            setBtnState(btnAdd, false, "Sudah Teman")
            setBtnState(btnDel, true,  "Hapus Koneksi")
        elseif st == Enum.FriendStatus.NotFriend then
            setBtnState(btnAdd, true,  "Tambah Koneksi")
            setBtnState(btnDel, false, "Hapus Koneksi")
        elseif st == Enum.FriendStatus.FriendRequestSent then
            setBtnState(btnAdd, false, "Terkirim")
            setBtnState(btnDel, false, "Hapus Koneksi")
        elseif st == Enum.FriendStatus.FriendRequestReceived then
            setBtnState(btnAdd, false, "Menunggu")
            setBtnState(btnDel, false, "Hapus Koneksi")
        else
            setBtnState(btnAdd, false)
            setBtnState(btnDel, false)
        end
    end
    refreshButtons()

    btnAdd.MouseButton1Click:Connect(function()
        if not plr then return end
        setBtnState(btnAdd, false, "Mengirim…")
        local ok, reason = sendFriendRequestSafe(plr)
        if ok then
            pushToast("join", "Permintaan koneksi dikirim.")
        else
            pushToast("leave", "Gagal tambah koneksi: "..tostring(reason))
        end
        refreshConnLabel()
        refreshButtons()
    end)

    btnDel.MouseButton1Click:Connect(function()
        if not plr then return end
        setBtnState(btnDel, false, "Menghapus…")
        local ok, reason = revokeFriendshipSafe(plr)
        if ok then
            pushToast("leave", "Koneksi dihapus.")
        else
            pushToast("leave", "Gagal hapus koneksi: "..tostring(reason))
        end
        refreshConnLabel()
        refreshButtons()
    end)

    -- update durasi lokal setiap detik saat tab Profile aktif
    if joinTimes[info.userId] then
        task.spawn(function()
            while activeTab == "Profile" and profilePage.Visible and joinTimes[info.userId] do
                vDurLoc.Text = durHMS(os.time() - joinTimes[info.userId])
                task.wait(1)
            end
        end)
    end
end

_G.__AxaJoinLeave_RenderProfile = renderProfile

------------------------------------------------------
-- SNAPSHOT AWAL & EVENT JOIN/LEAVE
------------------------------------------------------
local function snapshotPlayers()
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

local function rebuildPlayerList(map)
    for _, row in pairs(playerRows) do
        if row and row.Parent then row:Destroy() end
    end
    playerRows = {}

    local ordered = {}
    for _, info in pairs(map) do
        table.insert(ordered, info)
    end
    table.sort(ordered, function(a,b)
        local ad = string.lower(a.displayName or a.name or "")
        local bd = string.lower(b.displayName or b.name or "")
        if ad == bd then
            return (a.name or "") < (b.name or "")
        end
        return ad < bd
    end)

    for i, info in ipairs(ordered) do
        local row = makePlayerRow(listPlayer, info)
        row.LayoutOrder = i
        playerRows[info.userId] = row
    end

    applySearch()
end

-- seed awal
local snap = snapshotPlayers()
local nowTs = os.time()
for uid,_ in pairs(snap) do
    joinTimes[uid] = nowTs
end
rebuildPlayerList(snap)

local function onPlayerAdded(p)
    if p == LocalPlayer then return end

    local info = {
        userId = p.UserId,
        name = p.Name,
        displayName = p.DisplayName
    }

    joinTimes[p.UserId] = os.time()

    makeJoinLeaveRow(listJoin, info, "Join")
    rebuildPlayerList(snapshotPlayers())

    local isConn = isFriendUserId(p.UserId)
    local msg
    if isConn then
        msg = string.format("%s (@%s) koneksi anda bergabung dalam map", info.displayName or info.name, info.name)
    else
        msg = string.format("%s (@%s) bergabung dalam map", info.displayName or info.name, info.name)
    end
    pushToast("join", msg)
end

local function onPlayerRemoving(p)
    if p == LocalPlayer then return end

    local info = {
        userId = p.UserId,
        name = p.Name,
        displayName = p.DisplayName
    }

    makeJoinLeaveRow(listLeave, info, "Leave")
    rebuildPlayerList(snapshotPlayers())

    local isConn = isFriendUserId(p.UserId)
    local msg
    if isConn then
        msg = string.format("%s (@%s) koneksi anda keluar dari map", info.displayName or info.name, info.name)
    else
        msg = string.format("%s (@%s) keluar dari map", info.displayName or info.name, info.name)
    end
    pushToast("leave", msg)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
