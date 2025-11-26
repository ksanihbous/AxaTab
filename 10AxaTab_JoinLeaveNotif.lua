--==========================================================
--  10AxaTab_JoinLeaveNotif.lua
--  Tab AxaHub: Join/Leave Notif + Log Pemain + Profile
--  Env dari core:
--      TAB_FRAME (Frame konten tab)
--==========================================================

local frame        = TAB_FRAME

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui   = game:GetService("StarterGui")
local TextService  = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------
-- FORWARD DECLARATIONS
------------------------------------------------------
local openProfile   -- akan diisi di bawah
local pushToast     -- toast kecil di atas

------------------------------------------------------
-- HELPER
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
        ColorSequenceKeypoint.new(1, cBottom or Color3.fromRGB(233,238,252)),
    })
    g.Rotation = rot or 90
    g.Parent = instance
    return g
end

local function getAvatar(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size48x48
        )
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
                Title    = "Profil",
                Text     = "Link profil tersalin.",
                Duration = 2,
            })
        end)
        return
    end

    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text     = "[Profil] " .. url,
            Color    = Color3.fromRGB(30, 30, 40),
            Font     = Enum.Font.Gotham,
            TextSize = 14,
        })
    end)
end

local function hhmm(ts)
    local t = os.date("*t", ts or os.time())
    return string.format("%02d:%02d", t.hour, t.min)
end

local function durHMS(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h = math.floor(sec / 3600)
    sec = sec % 3600
    local m = math.floor(sec / 60)
    sec = sec % 60
    return string.format("%02d:%02d:%02d", h, m, sec)
end

local function splitYMD(days)
    local years = math.floor(days / 365)
    local rem   = days % 365
    local months= math.floor(rem / 30)
    local d     = rem % 30
    return years, months, d
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
sub.Text = "Pantau teman yang masuk/keluar dan semua pemain di server. Klik baris untuk buka profil & salin link."
sub.Parent = frame

------------------------------------------------------
-- TITLEBAR (JOIN/LEAVE/PLAYER/PROFILE + SOUND + NOTIF)
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
titleLabel.Size = UDim2.new(0, 120, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Font = Enum.Font.GothamSemibold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
titleLabel.Text = "Log Pemain"
titleLabel.Parent = titleBar

-- Tombol Sound (suara join/leave)
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

-- Tombol NOTIF: ON/OFF (toast teman join/leave)
local notifBtn = Instance.new("TextButton")
notifBtn.Name = "NotifBtn"
notifBtn.AnchorPoint = Vector2.new(1, 0.5)
notifBtn.Position = UDim2.new(1, -4 - 32 - 4, 0.5, 0)
notifBtn.Size = UDim2.new(0, 82, 0, 22)
notifBtn.AutoButtonColor = false
notifBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
notifBtn.BackgroundTransparency = 0.35
notifBtn.BorderSizePixel = 0
notifBtn.Font = Enum.Font.Gotham
notifBtn.TextSize = 12
notifBtn.TextColor3 = Color3.fromRGB(40, 40, 70)
notifBtn.Text = "NOTIF: ON"
notifBtn.Parent = titleBar
rounded(notifBtn, 8)
stroked(notifBtn, Color3.fromRGB(180, 190, 220), 1, 0.4)

-- Segmented control Join / Leave / Player / Profile
local segScroll = Instance.new("ScrollingFrame")
segScroll.Name = "SegScroll"
segScroll.BackgroundTransparency = 1
segScroll.BorderSizePixel = 0
segScroll.ScrollBarThickness = 0
segScroll.ScrollingDirection = Enum.ScrollingDirection.X
-- area antara titleLabel dan tombol notif/sound
local LEFT_OFFSET = 130
local RIGHT_FIXED = 4 + 82 + 4 + 32 + 4
segScroll.Position = UDim2.new(0, LEFT_OFFSET, 0, 0)
segScroll.Size = UDim2.new(1, -LEFT_OFFSET - RIGHT_FIXED, 1, 0)
segScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
segScroll.Parent = titleBar

local segWrap = Instance.new("Frame")
segWrap.Name = "SegWrap"
segWrap.Size = UDim2.new(0, 260, 0, 24)
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

local SEG_ITEM_W, SEG_PAD = 80, 4

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

local segJoin    = makeSeg("Join")
local segLeave   = makeSeg("Leave")
local segAll     = makeSeg("Player")
local segProfile = makeSeg("Profile")

local function layoutSegments()
    local list = {segJoin, segLeave, segAll, segProfile}
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
searchBox.PlaceholderText = "Search User/DisplayName"
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
    local size = UDim2.new(1, -12, 1, -(top + 6))

    scrollJoin.Position  = UDim2.new(0, 6, 0, top)
    scrollLeave.Position = UDim2.new(0, 6, 0, top)
    scrollAll.Position   = UDim2.new(0, 6, 0, top)

    scrollJoin.Size  = size
    scrollLeave.Size = size
    scrollAll.Size   = size
end

applyListAreaLayout()

------------------------------------------------------
-- PROFILE UI DALAM BODY
------------------------------------------------------
local ProfilePage      = Instance.new("Frame")
local ProfileName      = Instance.new("TextLabel")
local ProfileCopy      = Instance.new("TextButton")
local ProfileRefresh   = Instance.new("TextButton")
local ProfileScroll    = Instance.new("ScrollingFrame")
local ProfileList      = Instance.new("Frame")
local ProfileLayout    = Instance.new("UIListLayout")

ProfilePage.Name = "ProfilePage"
ProfilePage.Size = UDim2.new(1, -12, 1, -12)
ProfilePage.Position = UDim2.new(0, 6, 0, 6)
ProfilePage.BackgroundTransparency = 1
ProfilePage.Visible = false
ProfilePage.Parent = body

local profileHeader = Instance.new("Frame")
profileHeader.Name = "ProfileHeader"
profileHeader.Size = UDim2.new(1, 0, 0, 32)
profileHeader.BackgroundTransparency = 1
profileHeader.Parent = ProfilePage

ProfileName.Name = "ProfileTitle"
ProfileName.BackgroundTransparency = 1
ProfileName.Size = UDim2.new(1, -170, 1, 0)
ProfileName.Position = UDim2.new(0, 0, 0, 0)
ProfileName.Font = Enum.Font.GothamSemibold
ProfileName.TextSize = 16
ProfileName.TextColor3 = Color3.fromRGB(40, 40, 70)
ProfileName.TextXAlignment = Enum.TextXAlignment.Left
ProfileName.Text = ""
ProfileName.Parent = profileHeader

local function smallGlassButton(label)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel = 0
    b.Size = UDim2.new(0, 36, 0, 24)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(40, 40, 70)
    b.Text = label
    rounded(b, 8)
    stroked(b, Color3.fromRGB(200, 210, 230), 1, 0.45)
    return b
end

ProfileCopy = smallGlassButton("🔗")
ProfileCopy.Name = "CopyLink"
ProfileCopy.Position = UDim2.new(1, -40, 0.5, -12)
ProfileCopy.Parent = profileHeader

ProfileRefresh = smallGlassButton("↻")
ProfileRefresh.Name = "Refresh"
ProfileRefresh.Position = UDim2.new(1, -80, 0.5, -12)
ProfileRefresh.Parent = profileHeader

local infoRoot = Instance.new("Frame")
infoRoot.Name = "InfoRoot"
infoRoot.Size = UDim2.new(1, 0, 1, -40)
infoRoot.Position = UDim2.new(0, 0, 0, 36)
infoRoot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
infoRoot.BackgroundTransparency = 0.2
infoRoot.BorderSizePixel = 0
infoRoot.Parent = ProfilePage
rounded(infoRoot, 10)
gradient(infoRoot, Color3.fromRGB(255, 255, 255), Color3.fromRGB(238, 243, 255), 90)
stroked(infoRoot, Color3.fromRGB(210, 215, 235), 1, 0.45)

ProfileScroll = Instance.new("ScrollingFrame")
ProfileScroll.Name = "ProfileScroll"
ProfileScroll.BackgroundTransparency = 1
ProfileScroll.BorderSizePixel = 0
ProfileScroll.Size = UDim2.new(1, -12, 1, -12)
ProfileScroll.Position = UDim2.new(0, 6, 0, 6)
ProfileScroll.ScrollBarThickness = 6
ProfileScroll.ScrollBarImageTransparency = 0.1
ProfileScroll.ScrollBarImageColor3 = Color3.fromRGB(130, 138, 154)
ProfileScroll.ScrollingDirection = Enum.ScrollingDirection.Y
ProfileScroll.Parent = infoRoot

ProfileList = Instance.new("Frame")
ProfileList.Name = "ProfileList"
ProfileList.BackgroundTransparency = 1
ProfileList.Size = UDim2.new(1, -8, 0, 0)
ProfileList.Position = UDim2.new(0, 4, 0, 0)
ProfileList.Parent = ProfileScroll

ProfileLayout = Instance.new("UIListLayout")
ProfileLayout.FillDirection = Enum.FillDirection.Vertical
ProfileLayout.Padding = UDim.new(0, 6)
ProfileLayout.SortOrder = Enum.SortOrder.LayoutOrder
ProfileLayout.Parent = ProfileList

ProfileLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ProfileList.Size = UDim2.new(1, -8, 0, ProfileLayout.AbsoluteContentSize.Y)
    ProfileScroll.CanvasSize = UDim2.new(0, 0, 0, ProfileLayout.AbsoluteContentSize.Y + 8)
end)

local function clearInfo()
    for _, c in ipairs(ProfileList:GetChildren()) do
        if c:IsA("GuiObject") then
            c:Destroy()
        end
    end
end

local function makeField(labelTxt, valueTxt, opts)
    opts = opts or {}
    local row = Instance.new("Frame")
    row.Name = "Row_" .. (labelTxt:gsub("%s+", ""))
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = ProfileList

    local L = Instance.new("TextLabel")
    L.BackgroundTransparency = 1
    L.Size = UDim2.new(0.35, 0, 1, 0)
    L.Position = UDim2.new(0, 0, 0, 0)
    L.Font = Enum.Font.Gotham
    L.TextSize = 14
    L.TextColor3 = Color3.fromRGB(40, 40, 70)
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Text = labelTxt
    L.Parent = row

    local V = Instance.new("TextLabel")
    V.BackgroundTransparency = 1
    V.Position = UDim2.new(0.35, 8, 0, 0)
    V.Size = UDim2.new(1 - 0.35 - (opts.hasButtons and 0.22 or 0), -8, 1, 0)
    V.Font = Enum.Font.GothamMedium
    V.TextSize = 14
    V.TextColor3 = Color3.fromRGB(40, 40, 70)
    V.TextXAlignment = Enum.TextXAlignment.Left
    V.TextTruncate = Enum.TextTruncate.AtEnd
    V.Text = valueTxt
    V.Parent = row

    if opts.copyText then
        local Btn = Instance.new("TextButton")
        Btn.AutoButtonColor = false
        Btn.Size = UDim2.new(0, 32, 0, 24)
        Btn.Position = UDim2.new(1, -36, 0.5, -12)
        Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Btn.BackgroundTransparency = 0.2
        Btn.BorderSizePixel = 0
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 14
        Btn.TextColor3 = Color3.fromRGB(40, 40, 70)
        Btn.Text = opts.icon or "📋"
        Btn.Parent = row
        rounded(Btn, 8)
        stroked(Btn, Color3.fromRGB(200, 210, 230), 1, 0.5)

        Btn.MouseButton1Click:Connect(function()
            copyOrAnnounce(opts.copyText)
        end)
    end

    return row, V
end

local function addBadgeRow(labelTxt, color3)
    local row = Instance.new("Frame")
    row.Name = "Row_Badge"
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = ProfileList

    local chip = Instance.new("TextLabel")
    chip.Size = UDim2.new(0, 220, 0, 22)
    chip.Position = UDim2.new(0, 0, 0.5, -11)
    chip.BackgroundColor3 = color3 or Color3.fromRGB(220, 230, 255)
    chip.BackgroundTransparency = 0.1
    chip.BorderSizePixel = 0
    chip.Font = Enum.Font.GothamMedium
    chip.TextSize = 13
    chip.TextColor3 = Color3.fromRGB(40, 40, 70)
    chip.Text = labelTxt
    chip.Parent = row
    rounded(chip, 11)
    stroked(chip, Color3.fromRGB(200, 210, 230), 1, 0.5)
end

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
-- ROW BUILDER (LOG & ALL PLAYER) - klik = buka Profile
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

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 46, 0, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextColor3 = Color3.fromRGB(40, 40, 70)
    label.TextTruncate = Enum.TextTruncate.AtEnd
    local prefix = (kind == "join") and "✅" or "🚪"
    local role   = isFriend and "Teman" or "Pemain"
    local timeStr= hhmm(atTimestamp)
    label.Text = string.format("%s %s  (@%s) • %s • %s", prefix, info.displayName or info.name, info.name, role, timeStr)
    label.Parent = row

    local linkBtn = smallGlassButton("🔗")
    linkBtn.Name = "Link"
    linkBtn.Size = UDim2.new(0, 30, 0, 22)
    linkBtn.Position = UDim2.new(1, -38, 0.5, -11)
    linkBtn.Parent = row

    linkBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        if openProfile then
            openProfile(info)
        else
            copyOrAnnounce(profileUrl(info.userId))
        end
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

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 46, 0, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextColor3 = Color3.fromRGB(40, 40, 70)
    label.TextTruncate = Enum.TextTruncate.AtEnd
    local txt = string.format("%s  (@%s)", info.displayName or info.name, info.name)
    if isFriend then
        txt = txt .. "  ⭐"
    end
    label.Text = txt
    label.Parent = row

    local linkBtn = smallGlassButton("🔗")
    linkBtn.Name = "Link"
    linkBtn.Size = UDim2.new(0, 30, 0, 22)
    linkBtn.Position = UDim2.new(1, -38, 0.5, -11)
    linkBtn.Parent = row

    linkBtn.MouseButton1Click:Connect(function()
        copyOrAnnounce(profileUrl(info.userId))
    end)

    row.MouseButton1Click:Connect(function()
        if openProfile then
            openProfile(info)
        else
            copyOrAnnounce(profileUrl(info.userId))
        end
    end)

    return row
end

------------------------------------------------------
-- SEGMENTED CONTROL LOGIC (Join / Leave / Player / Profile)
------------------------------------------------------
local activeTab = "Join"

local function moveIndicatorTo(index)
    local x = SEG_PAD + (index - 1) * SEG_ITEM_W
    indicator.Position = UDim2.new(0, x, 0, SEG_PAD)
end

local function updateSegmentVisuals(index)
    local list = {segJoin, segLeave, segAll, segProfile}
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
        ProfilePage.Visible = false
        searchWrap.Visible  = true
        applyListAreaLayout()
        moveIndicatorTo(1)
        updateSegmentVisuals(1)

    elseif tab == "Leave" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = true
        scrollAll.Visible   = false
        ProfilePage.Visible = false
        searchWrap.Visible  = true
        applyListAreaLayout()
        moveIndicatorTo(2)
        updateSegmentVisuals(2)

    elseif tab == "Player" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = false
        scrollAll.Visible   = true
        ProfilePage.Visible = false
        searchWrap.Visible  = true
        applyListAreaLayout()
        moveIndicatorTo(3)
        updateSegmentVisuals(3)

    elseif tab == "Profile" then
        scrollJoin.Visible  = false
        scrollLeave.Visible = false
        scrollAll.Visible   = false
        ProfilePage.Visible = true
        searchWrap.Visible  = false
        moveIndicatorTo(4)
        updateSegmentVisuals(4)
    end

    applyGlobalFilter()
end

segJoin.MouseButton1Click:Connect(function()  setTab("Join")    end)
segLeave.MouseButton1Click:Connect(function() setTab("Leave")   end)
segAll.MouseButton1Click:Connect(function()   setTab("Player")  end)
segProfile.MouseButton1Click:Connect(function() setTab("Profile") end)

setTab("Join")

------------------------------------------------------
-- TOAST UI (NOTIF teman join/leave)
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
    return TweenService:Create(
        obj,
        TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    )
end

local toastBusy  = false
local toastQueue = {}
local notifEnabled = true

local function setNotifUI(on)
    notifEnabled = on and true or false
    notifBtn.Text = on and "NOTIF: ON" or "NOTIF: OFF"
    notifBtn.TextTransparency = on and 0 or 0.25
    notifBtn.BackgroundTransparency = on and 0.35 or 0.5
end

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

pushToast = function(kind, msg)
    if not notifEnabled then return end
    table.insert(toastQueue, {kind = kind, msg = msg})
    if toastBusy then return end
    toastBusy = true
    while #toastQueue > 0 do
        local item = table.remove(toastQueue, 1)
        playToast(item.kind, item.msg)
    end
    toastBusy = false
end

setNotifUI(true)
notifBtn.MouseButton1Click:Connect(function()
    setNotifUI(not notifEnabled)
end)

------------------------------------------------------
-- SOUND TOGGLE (CHIME join/leave)
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
    if not id or id == "" then return end
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
-- FRIEND CACHE & STATUS SAFE
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
    if not userId then return false end
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

local function getFriendStatusSafe(targetPlayer)
    local ok, status = pcall(function()
        return LocalPlayer:GetFriendStatus(targetPlayer)
    end)
    return ok and status or Enum.FriendStatus.Unknown
end

local function sendFriendRequestSafe(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then
        return false, "Target tidak ditemukan / sudah keluar."
    end
    if targetPlayer == LocalPlayer then
        return false, "Tidak bisa kirim ke diri sendiri."
    end

    local st = getFriendStatusSafe(targetPlayer)
    if st == Enum.FriendStatus.Friend then
        return false, "Sudah berteman."
    elseif st == Enum.FriendStatus.FriendRequestSent then
        return false, "Permintaan sudah dikirim."
    elseif st == Enum.FriendStatus.FriendRequestReceived then
        return false, "Mereka sudah kirim permintaan."
    end

    local ok, err = pcall(function()
        if LocalPlayer.RequestFriendship then
            LocalPlayer:RequestFriendship(targetPlayer)
        else
            Players:RequestFriendship(LocalPlayer, targetPlayer)
        end
    end)
    if not ok then
        return false, "Gagal kirim: " .. tostring(err)
    end

    local t0 = os.clock()
    while os.clock() - t0 < 2.0 do
        RunService.Heartbeat:Wait()
        local now = getFriendStatusSafe(targetPlayer)
        if now == Enum.FriendStatus.FriendRequestSent or now == Enum.FriendStatus.Friend then
            return true
        end
    end
    return false, "Tidak ada konfirmasi (limit/privasi)."
end

local function revokeFriendshipSafe(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then
        return false, "Target tidak ditemukan / sudah keluar."
    end
    if getFriendStatusSafe(targetPlayer) ~= Enum.FriendStatus.Friend then
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
        return false, "Gagal hapus: " .. tostring(err)
    end

    local t0 = os.clock()
    while os.clock() - t0 < 2.0 do
        RunService.Heartbeat:Wait()
        if getFriendStatusSafe(targetPlayer) ~= Enum.FriendStatus.Friend then
            return true
        end
    end
    return false, "Tidak ada konfirmasi (jaringan/limit)."
end

------------------------------------------------------
-- PROFILE LOGIC
------------------------------------------------------
local ActiveProfile
local DurConn
local geoChangeConns = {}

local function disconnectGeoConns()
    for _, c in ipairs(geoChangeConns) do
        if c then c:Disconnect() end
    end
    geoChangeConns = {}
end

local function statusToText(st)
    if st == Enum.FriendStatus.Friend then
        return "✅ Sudah berteman"
    elseif st == Enum.FriendStatus.NotFriend then
        return "❌ Belum berteman"
    elseif st == Enum.FriendStatus.FriendRequestSent then
        return "📨 Permintaan dikirim"
    elseif st == Enum.FriendStatus.FriendRequestReceived then
        return "📥 Permintaan masuk"
    else
        return "-"
    end
end

local function readGeo(plr)
    if not plr then
        return "Tidak tersedia", "Tidak tersedia", "Tidak tersedia"
    end
    local cc  = plr:GetAttribute("GeoCountryCode")
    local cn  = plr:GetAttribute("GeoCountryName")
    local prv = plr:GetAttribute("GeoProvince")
    local cty = plr:GetAttribute("GeoCity")

    local negara = (cn and #tostring(cn) > 0) and tostring(cn) or "Tidak tersedia"
    if cc and #tostring(cc) > 0 then
        negara = string.format("%s (%s)", negara, tostring(cc))
    end
    local prov = (prv and #tostring(prv) > 0) and tostring(prv) or "Tidak tersedia"
    local kota = (cty and #tostring(cty) > 0) and tostring(cty) or "Tidak tersedia"
    return negara, prov, kota
end

local joinTimes = {}
local allRows   = {}

local function renderProfile(info)
    clearInfo()
    if DurConn then DurConn:Disconnect() end
    DurConn = nil
    disconnectGeoConns()

    ProfileName.Text = string.format("%s  (@%s)", info.displayName or info.name, info.name)

    local plr = Players:GetPlayerByUserId(info.userId)
    local accountAgeDays = plr and plr.AccountAge or nil
    local createdDateTxt = "-"
    if accountAgeDays then
        local createdT = os.date("*t", os.time() - accountAgeDays * 24 * 60 * 60)
        createdDateTxt = string.format("%02d/%02d/%04d", createdT.day, createdT.month, createdT.year)
    end

    local usiaTxt = "-"
    if accountAgeDays then
        local y, m, d = splitYMD(accountAgeDays)
        usiaTxt = string.format("%d hari  (≈ %d th %d bln %d hr)", accountAgeDays, y, m, d)
    end

    local memberTxt = "-"
    if plr and plr.MembershipType then
        if plr.MembershipType == Enum.MembershipType.Premium then
            memberTxt = "Premium"
        elseif plr.MembershipType == Enum.MembershipType.None then
            memberTxt = "None"
        else
            memberTxt = tostring(plr.MembershipType):gsub("Enum%.MembershipType%.", "")
        end
    end

    if accountAgeDays then
        if accountAgeDays < 7 then
            addBadgeRow("🚩 Akun Baru (<7 hari)", Color3.fromRGB(255, 220, 220))
        elseif accountAgeDays < 30 then
            addBadgeRow("⚠️ Akun <30 hari", Color3.fromRGB(255, 240, 210))
        elseif accountAgeDays >= 365 then
            addBadgeRow("⭐ Veteran (≥1 tahun)", Color3.fromRGB(230, 255, 230))
        end
    end

    local usernameDisplay = "@" .. tostring(info.name)
    makeField("Display Name", tostring(info.displayName or info.name))
    makeField("Username", usernameDisplay, {
        hasButtons = true,
        copyText   = usernameDisplay,
        icon       = "📋",
    })
    makeField("UserId", tostring(info.userId), {
        hasButtons = true,
        copyText   = tostring(info.userId),
        icon       = "🆔",
    })

    local initialStatus = (plr and getFriendStatusSafe(plr)) or Enum.FriendStatus.Unknown
    local _, friendLbl = makeField("Friendship dengan Kamu", statusToText(initialStatus))

    -- Row tombol tambahan: Tambah Teman / Hapus Teman
    local btnRow = Instance.new("Frame")
    btnRow.Name = "Row_FriendActions"
    btnRow.Size = UDim2.new(1, 0, 0, 32)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = ProfileList

    local addBtn = smallGlassButton("Tambah Teman")
    addBtn.Size = UDim2.new(0, 130, 0, 24)
    addBtn.Position = UDim2.new(0, 0, 0.5, -12)
    addBtn.Parent = btnRow

    local remBtn = smallGlassButton("Hapus Teman")
    remBtn.Size = UDim2.new(0, 130, 0, 24)
    remBtn.Position = UDim2.new(0, 140, 0.5, -12)
    remBtn.Parent = btnRow
    local remStroke = remBtn:FindFirstChildOfClass("UIStroke")
    if remStroke then
        remStroke.Color = Color3.fromRGB(255, 69, 58)
    end

    local function setBtnState(b, enabled, label)
        b.Active = enabled
        b.AutoButtonColor = enabled
        b.TextTransparency = enabled and 0 or 0.35
        if label then b.Text = label end
    end

    local function refreshFriendUI()
        if not plr then
            friendLbl.Text = "-"
            setBtnState(addBtn, false)
            setBtnState(remBtn, false)
            return
        end
        local st = getFriendStatusSafe(plr)
        friendLbl.Text = statusToText(st)

        if st == Enum.FriendStatus.Friend then
            setBtnState(addBtn, false, "Sudah Teman")
            setBtnState(remBtn, true, "Hapus Teman")
        elseif st == Enum.FriendStatus.NotFriend then
            setBtnState(addBtn, true, "Tambah Teman")
            setBtnState(remBtn, false, "Hapus Teman")
        elseif st == Enum.FriendStatus.FriendRequestSent then
            setBtnState(addBtn, false, "Terkirim")
            setBtnState(remBtn, false, "Hapus Teman")
        elseif st == Enum.FriendStatus.FriendRequestReceived then
            setBtnState(addBtn, false, "Menunggu")
            setBtnState(remBtn, false, "Hapus Teman")
        else
            setBtnState(addBtn, false)
            setBtnState(remBtn, false)
        end
    end

    refreshFriendUI()

    addBtn.MouseButton1Click:Connect(function()
        if not plr then return end
        setBtnState(addBtn, false, "Mengirim…")
        local ok, reason = sendFriendRequestSafe(plr)
        if ok then
            friendLbl.Text = "📨 Permintaan dikirim"
            pushToast("join", "Permintaan pertemanan dikirim")
        else
            friendLbl.Text = "❌ Gagal: " .. tostring(reason)
            pushToast("leave", "Gagal kirim: " .. tostring(reason))
        end
        refreshFriendUI()
    end)

    remBtn.MouseButton1Click:Connect(function()
        if not plr then return end
        setBtnState(remBtn, false, "Menghapus…")
        local ok, reason = revokeFriendshipSafe(plr)
        if ok then
            friendLbl.Text = "❌ Belum berteman"
            pushToast("leave", "Pertemanan dihapus")
        else
            friendLbl.Text = "⚠️ Gagal hapus: " .. tostring(reason)
            pushToast("leave", "Gagal hapus: " .. tostring(reason))
        end
        refreshFriendUI()
    end)

    local genderTxt = "-"
    if plr then
        local g = plr:GetAttribute("Gender")
        if typeof(g) == "string" and #g > 0 then
            genderTxt = g
        end
    end

    local joinAtTxt, durTxt = "-", "-"
    if joinTimes[info.userId] then
        local jt = os.date("*t", joinTimes[info.userId])
        joinAtTxt = string.format("%02d:%02d:%02d", jt.hour, jt.min, jt.sec)
        durTxt = durHMS(os.time() - joinTimes[info.userId])
    end

    makeField("Jenis Kelamin", genderTxt)
    makeField("Tanggal Buat Akun", createdDateTxt)
    makeField("Usia Akun", usiaTxt)
    makeField("Membership", memberTxt)
    makeField("Bergabung ke Server (lokal)", joinAtTxt)

    local _, durLbl = makeField("Durasi di Server (lokal)", durTxt)

    local _, linkLbl = makeField("Link Profil (copy)", profileUrl(info.userId), {
        hasButtons = true,
        copyText   = profileUrl(info.userId),
        icon       = "🔗",
    })
    linkLbl.TextTruncate = Enum.TextTruncate.AtEnd

    addBadgeRow("🌏 Lokasi Saat Ini", Color3.fromRGB(220, 230, 255))
    local negara, prov, kota = readGeo(plr)
    local _, negaraLbl = makeField("Negara",  negara)
    local _, provLbl   = makeField("Provinsi", prov)
    local _, kotaLbl   = makeField("Kota",    kota)

    if joinTimes[info.userId] then
        DurConn = RunService.Heartbeat:Connect(function()
            if activeTab == "Profile" and ProfilePage.Visible and durLbl then
                durLbl.Text = durHMS(os.time() - joinTimes[info.userId])
            end
        end)
    end

    if plr then
        table.insert(geoChangeConns, plr:GetAttributeChangedSignal("GeoCountryCode"):Connect(function()
            local ng, _, _ = readGeo(plr)
            negaraLbl.Text = ng
        end))
        table.insert(geoChangeConns, plr:GetAttributeChangedSignal("GeoCountryName"):Connect(function()
            local ng, _, _ = readGeo(plr)
            negaraLbl.Text = ng
        end))
        table.insert(geoChangeConns, plr:GetAttributeChangedSignal("GeoProvince"):Connect(function()
            local _, p, _ = readGeo(plr)
            provLbl.Text = p
        end))
        table.insert(geoChangeConns, plr:GetAttributeChangedSignal("GeoCity"):Connect(function()
            local _, _, k = readGeo(plr)
            kotaLbl.Text = k
        end))
    end
end

openProfile = function(info)
    ActiveProfile = info
    renderProfile(info)
    setTab("Profile")
end

ProfileCopy.MouseButton1Click:Connect(function()
    if ActiveProfile then
        copyOrAnnounce(profileUrl(ActiveProfile.userId))
    end
end)

ProfileRefresh.MouseButton1Click:Connect(function()
    if ActiveProfile then
        renderProfile(ActiveProfile)
    end
end)

------------------------------------------------------
-- ROSTER & EVENT JOIN/LEAVE
------------------------------------------------------
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
        userId      = p.UserId,
        name        = p.Name,
        displayName = p.DisplayName,
    })
end

-- Event join/leave
Players.PlayerAdded:Connect(function(p)
    joinTimes[p.UserId] = os.time()
    local info = {
        userId      = p.UserId,
        name        = p.Name,
        displayName = p.DisplayName,
    }
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
    local info = {
        userId      = p.UserId,
        name        = p.Name,
        displayName = p.DisplayName,
    }
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
