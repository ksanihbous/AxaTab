--==========================================================
--  AxaTab_ChatPublik.lua
--  Dipanggil via AxaHub CORE (loadstring + env TAB_FRAME)
--  Fitur:
--    - UI Filter Chat (All / System / Special / Caught Mirethos/Kaelvorn)
--    - ScrollingFrame untuk checkbox checklist (biar nggak keluar header)
--    - Log Chat + Subtitle besar bawah
--    - Tombol "Chat Filter: ON/OFF" (master switch filter)
--    - Integrasi STT: _G.AxaChatRelay_ReceiveSTT(player, text, channelType)
--    - Webhook (kalau WEBHOOK_URL diisi)
--==========================================================

-- Env dari CORE:
--  TAB_FRAME, CONTENT_HOLDER, AXA_TWEEN
--  Players, LocalPlayer, RunService, TweenService, HttpService
--  UserInputService, VirtualInputManager, ContextActionService
--  StarterGui, CoreGui, Camera, SetActiveTab

--------------------------------------------------
-- SAFETY: fallback kalau env nggak ada (debug mandiri)
--------------------------------------------------
local okEnv = (typeof(TAB_FRAME) == "Instance")

local Players              = Players              or game:GetService("Players")
local LocalPlayer          = LocalPlayer          or Players.LocalPlayer
local RunService           = RunService           or game:GetService("RunService")
local TweenService         = TweenService         or game:GetService("TweenService")
local HttpService          = HttpService          or game:GetService("HttpService")
local UserInputService     = UserInputService     or game:GetService("UserInputService")
local VirtualInputManager  = VirtualInputManager  or game:GetService("VirtualInputManager")
local ContextActionService = ContextActionService or game:GetService("ContextActionService")
local StarterGui           = StarterGui           or game:GetService("StarterGui")
local CoreGui              = CoreGui              or game:GetService("CoreGui")

local TextChatService = nil
pcall(function()
    TextChatService = game:GetService("TextChatService")
end)

local playerGui
pcall(function()
    playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end)

local chatTabFrame

if okEnv then
    chatTabFrame = TAB_FRAME
else
    -- Fallback: bikin ScreenGui sendiri (kalau dijalankan lepas dari CORE)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AxaTab_ChatPublik_Standalone"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = playerGui or CoreGui

    chatTabFrame = Instance.new("Frame")
    chatTabFrame.Name = "ChatPublikRoot"
    chatTabFrame.Size = UDim2.new(0, 520, 0, 320)
    chatTabFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    chatTabFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    chatTabFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
    chatTabFrame.Parent = screenGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = chatTabFrame
end

chatTabFrame.ClipsDescendants = true
chatTabFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
chatTabFrame.BackgroundTransparency = 0

-- Bersihkan isi lama (kecuali UICorner/UIStroke dari CORE)
for _, child in ipairs(chatTabFrame:GetChildren()) do
    if not child:IsA("UICorner") and not child:IsA("UIStroke") then
        child:Destroy()
    end
end

--------------------------------------------------
--  CONFIG
--------------------------------------------------
-- Isi webhook kamu di sini kalau mau kirim ke Discord
local WEBHOOK_URL = "" -- contoh: "https://discord.com/api/webhooks/xxxxx/yyyy"

-- Master switch semua filter
local ChatFilterEnabled = true

-- Filter state default
local FilterState = {
    AllChat          = true,  -- 1. All Chat
    SystemInfo       = true,  -- 2. System Info
    SpecialChat      = true,  -- 3. Special UserID / koneksi (chat)
    SpecialSystem    = true,  -- 4. System Info Special UserID / koneksi
    MythicCatch      = true,  -- 5. caught Mirethos / Kaelvorn
}

-- Daftar Special UserID / koneksi (isi sesuai punyamu)
local SPECIAL_USER_IDS = {
    [8957393843] = "AxaXyz999xBBHY",
    -- [UserId] = "Nama / Keterangan",
}

--------------------------------------------------
--  UI HEADER + DESC
--------------------------------------------------
local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextColor3 = Color3.fromRGB(40, 40, 60)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "💬 CHAT PUBLIK HG + IC"
header.Parent = chatTabFrame

local desc = Instance.new("TextLabel")
desc.Name = "Desc"
desc.Size = UDim2.new(1, -10, 0, 34)
desc.Position = UDim2.new(0, 5, 0, 26)
desc.BackgroundTransparency = 1
desc.Font = Enum.Font.Gotham
desc.TextSize = 12
desc.TextColor3 = Color3.fromRGB(90, 90, 120)
desc.TextXAlignment = Enum.TextXAlignment.Left
desc.TextYAlignment = Enum.TextYAlignment.Top
desc.TextWrapped = true
desc.Text = "Filter chat publik + system info + Special UserID, sekaligus relay ke Discord + subtitle besar untuk dibaca."
desc.Parent = chatTabFrame

--------------------------------------------------
--  PANEL KIRI: FILTER + SCROLLINGFRAME CHECKBOX
--------------------------------------------------
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.BackgroundTransparency = 1
leftPanel.Position = UDim2.new(0, 8, 0, 64)
leftPanel.Size = UDim2.new(0.42, -8, 1, -72)
leftPanel.Parent = chatTabFrame

local leftTitle = Instance.new("TextLabel")
leftTitle.Name = "LeftTitle"
leftTitle.Size = UDim2.new(1, 0, 0, 20)
leftTitle.Position = UDim2.new(0, 0, 0, 0)
leftTitle.BackgroundTransparency = 1
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 13
leftTitle.TextColor3 = Color3.fromRGB(40, 40, 60)
leftTitle.TextXAlignment = Enum.TextXAlignment.Left
leftTitle.Text = "Filter Chat"
leftTitle.Parent = leftPanel

local filterOutline = Instance.new("Frame")
filterOutline.Name = "FilterOutline"
filterOutline.Position = UDim2.new(0, 0, 0, 22)
filterOutline.Size = UDim2.new(1, 0, 1, -22)
filterOutline.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
filterOutline.BorderSizePixel = 0
filterOutline.Parent = leftPanel

local foCorner = Instance.new("UICorner")
foCorner.CornerRadius = UDim.new(0, 8)
foCorner.Parent = filterOutline

local foStroke = Instance.new("UIStroke")
foStroke.Thickness = 1
foStroke.Color = Color3.fromRGB(200, 200, 215)
foStroke.Transparency = 0.4
foStroke.Parent = filterOutline

-- ScrollingFrame untuk semua checkbox checklist
local filterScroll = Instance.new("ScrollingFrame")
filterScroll.Name = "FilterScroll"
filterScroll.Position = UDim2.new(0, 4, 0, 4)
filterScroll.Size = UDim2.new(1, -8, 1, -8)
filterScroll.BackgroundTransparency = 1
filterScroll.BorderSizePixel = 0
filterScroll.ScrollBarThickness = 4
filterScroll.ScrollingDirection = Enum.ScrollingDirection.Y
filterScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
filterScroll.Parent = filterOutline

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Vertical
filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
filterLayout.Padding = UDim.new(0, 4)
filterLayout.Parent = filterScroll

local function updateFilterCanvas()
    local abs = filterLayout.AbsoluteContentSize
    filterScroll.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 8)
end

filterLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateFilterCanvas)

-- Definisi filter
local FILTER_DEFS = {
    {
        id    = "AllChat",
        label = "1. All Chat (semua pesan)",
    },
    {
        id    = "SystemInfo",
        label = "2. System Info (server / notifikasi game)",
    },
    {
        id    = "SpecialChat",
        label = "3. Special UserID / koneksi (chat)",
    },
    {
        id    = "SpecialSystem",
        label = "4. System Info Special UserID / koneksi",
    },
    {
        id    = "MythicCatch",
        label = "5. Filter khusus: \"caught a Mirethos\" / \"caught a Kaelvorn\"",
    },
}

local filterButtons = {}

local function setCheckboxVisual(btn, on)
    if on then
        btn.Text = "✔"
        btn.BackgroundColor3 = Color3.fromRGB(90, 160, 250)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        btn.Text = ""
        btn.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
        btn.TextColor3 = Color3.fromRGB(80, 80, 110)
    end
end

local function makeFilterRow(def)
    local row = Instance.new("Frame")
    row.Name = "Filter_" .. def.id
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = filterScroll

    local check = Instance.new("TextButton")
    check.Name = "Check"
    check.Size = UDim2.fromOffset(20, 20)
    check.Position = UDim2.new(0, 2, 0, 3)
    check.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
    check.BorderSizePixel = 0
    check.Font = Enum.Font.GothamBold
    check.TextSize = 14
    check.TextColor3 = Color3.fromRGB(80, 80, 110)
    check.AutoButtonColor = true
    check.Text = ""
    check.Parent = row
    Instance.new("UICorner", check).CornerRadius = UDim.new(0, 4)

    local label = Instance.new("TextButton")
    label.Name = "Label"
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 28, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(40, 40, 70)
    label.Text = def.label
    label.AutoButtonColor = false
    label.Parent = row

    local function setFromState()
        local on = FilterState[def.id]
        if on == nil then
            on = true
        end
        FilterState[def.id] = on
        setCheckboxVisual(check, on)
    end

    check.MouseButton1Click:Connect(function()
        FilterState[def.id] = not (FilterState[def.id] == true)
        setFromState()
    end)

    label.MouseButton1Click:Connect(function()
        FilterState[def.id] = not (FilterState[def.id] == true)
        setFromState()
    end)

    filterButtons[def.id] = {
        Row   = row,
        Check = check,
        Label = label,
        Set   = setFromState,
    }

    setFromState()
end

for _, def in ipairs(FILTER_DEFS) do
    makeFilterRow(def)
end
updateFilterCanvas()

--------------------------------------------------
--  PANEL KANAN: LOG CHAT + SUBTITLE + CHAT FILTER TOGGLE
--------------------------------------------------
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.BackgroundTransparency = 1
rightPanel.Position = UDim2.new(0.44, 0, 0, 64)
rightPanel.Size = UDim2.new(0.56, -8, 1, -72)
rightPanel.Parent = chatTabFrame

local rightTitle = Instance.new("TextLabel")
rightTitle.Name = "RightTitle"
rightTitle.Size = UDim2.new(1, 0, 0, 20)
rightTitle.Position = UDim2.new(0, 0, 0, 0)
rightTitle.BackgroundTransparency = 1
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 13
rightTitle.TextColor3 = Color3.fromRGB(40, 40, 60)
rightTitle.TextXAlignment = Enum.TextXAlignment.Left
rightTitle.Text = "Log + Subtitle"
rightTitle.Parent = rightPanel

-- === Chat Filter: ON/OFF (master switch) ===
local chatFilterRow = Instance.new("Frame")
chatFilterRow.Name = "ChatFilterRow"
chatFilterRow.Size = UDim2.new(1, 0, 0, 24)
chatFilterRow.Position = UDim2.new(0, 0, 0, 22)
chatFilterRow.BackgroundTransparency = 1
chatFilterRow.Parent = rightPanel

local cfLabel = Instance.new("TextLabel")
cfLabel.Name = "CFLabel"
cfLabel.Size = UDim2.new(0.5, -4, 1, 0)
cfLabel.Position = UDim2.new(0, 0, 0, 0)
cfLabel.BackgroundTransparency = 1
cfLabel.Font = Enum.Font.Gotham
cfLabel.TextSize = 12
cfLabel.TextXAlignment = Enum.TextXAlignment.Left
cfLabel.TextColor3 = Color3.fromRGB(80, 80, 110)
cfLabel.Text = "Chat Filter:"
cfLabel.Parent = chatFilterRow

local cfToggle = Instance.new("TextButton")
cfToggle.Name = "CFToggle"
cfToggle.Size = UDim2.new(0, 70, 0, 20)
cfToggle.AnchorPoint = Vector2.new(1, 0.5)
cfToggle.Position = UDim2.new(1, -4, 0.5, 0)
cfToggle.BackgroundColor3 = Color3.fromRGB(90, 160, 250)
cfToggle.BorderSizePixel = 0
cfToggle.Font = Enum.Font.GothamBold
cfToggle.TextSize = 12
cfToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
cfToggle.Text = "ON"
cfToggle.AutoButtonColor = true
cfToggle.Parent = chatFilterRow
Instance.new("UICorner", cfToggle).CornerRadius = UDim.new(1, 0)

local function refreshChatFilterToggle()
    if ChatFilterEnabled then
        cfToggle.Text = "ON"
        cfToggle.BackgroundColor3 = Color3.fromRGB(90, 160, 250)
        cfToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        cfLabel.TextColor3 = Color3.fromRGB(80, 80, 110)
    else
        cfToggle.Text = "OFF"
        cfToggle.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
        cfToggle.TextColor3 = Color3.fromRGB(60, 60, 80)
        cfLabel.TextColor3 = Color3.fromRGB(140, 80, 80)
    end
end

cfToggle.MouseButton1Click:Connect(function()
    ChatFilterEnabled = not ChatFilterEnabled
    refreshChatFilterToggle()
end)

refreshChatFilterToggle()

-- === LOG FRAME (dipush turun karena ada ChatFilterRow) ===
local logFrame = Instance.new("Frame")
logFrame.Name = "LogFrame"
logFrame.Position = UDim2.new(0, 0, 0, 48) -- 22 (judul) + 24 (ChatFilter) + 2 gap
logFrame.Size = UDim2.new(1, 0, 1, -86)   -- disesuaikan supaya nggak tabrakan subtitle
logFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
logFrame.BorderSizePixel = 0
logFrame.Parent = rightPanel

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 8)
logCorner.Parent = logFrame

local logStroke = Instance.new("UIStroke")
logStroke.Thickness = 1
logStroke.Color = Color3.fromRGB(200, 200, 215)
logStroke.Transparency = 0.4
logStroke.Parent = logFrame

local logScroll = Instance.new("ScrollingFrame")
logScroll.Name = "LogScroll"
logScroll.Position = UDim2.new(0, 4, 0, 4)
logScroll.Size = UDim2.new(1, -8, 1, -8)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 4
logScroll.ScrollingDirection = Enum.ScrollingDirection.Y
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.Parent = logFrame

local logLayout = Instance.new("UIListLayout")
logLayout.FillDirection = Enum.FillDirection.Vertical
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 2)
logLayout.Parent = logScroll

local function updateLogCanvas()
    local abs = logLayout.AbsoluteContentSize
    logScroll.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 8)
end

logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    updateLogCanvas()
    -- auto scroll ke bawah
    logScroll.CanvasPosition = Vector2.new(
        0,
        math.max(0, logScroll.CanvasSize.Y.Offset - logScroll.AbsoluteWindowSize.Y)
    )
end)

-- Subtitle besar bawah
local subtitleFrame = Instance.new("Frame")
subtitleFrame.Name = "SubtitleFrame"
subtitleFrame.Size = UDim2.new(1, 0, 0, 32)
subtitleFrame.Position = UDim2.new(0, 0, 1, -32)
subtitleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
subtitleFrame.BorderSizePixel = 0
subtitleFrame.Parent = rightPanel

local subCorner = Instance.new("UICorner")
subCorner.CornerRadius = UDim.new(0, 8)
subCorner.Parent = subtitleFrame

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(1, -10, 1, -4)
subtitleLabel.Position = UDim2.new(0, 5, 0, 2)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextSize = 14
subtitleLabel.TextColor3 = Color3.fromRGB(235, 235, 255)
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
subtitleLabel.TextWrapped = true
subtitleLabel.Text = "(Subtitle terakhir tampil di sini)"
subtitleLabel.Parent = subtitleFrame

local subtitleBuffer = {}

local function pushSubtitleLine(text)
    table.insert(subtitleBuffer, text)
    while #subtitleBuffer > 3 do
        table.remove(subtitleBuffer, 1)
    end
    subtitleLabel.Text = table.concat(subtitleBuffer, "   |   ")
end

--------------------------------------------------
--  UTIL: DETEKSI SPECIAL / MIRETHOS / KAELVORN
--------------------------------------------------
local function isSpecialUser(player)
    if not player then return false end
    local uid = player.UserId
    return SPECIAL_USER_IDS[uid] ~= nil
end

local function isMythicCatch(text)
    if not text then return false end
    local lower = string.lower(text)
    if string.find(lower, "caught a mirethos", 1, true) then
        return true
    end
    if string.find(lower, "caught a kaelvorn", 1, true) then
        return true
    end
    return false
end

--------------------------------------------------
--  UTIL: FILTER CHECK
--------------------------------------------------
local function passFilter(opts)
    -- Master switch: kalau ChatFilterEnabled = false, semua lolos
    if not ChatFilterEnabled then
        return true
    end

    -- opts: {IsSystem, IsSpecialUser, IsMythic, ChannelType}
    local isSystem   = opts.IsSystem   or false
    local isSpecial  = opts.IsSpecialUser or false
    local isMythic   = opts.IsMythic   or false

    -- Filter Mythic catch dulu
    if isMythic then
        if FilterState.MythicCatch == false then
            return false
        end
        -- Boleh tembus walau filter lain off
        return true
    end

    -- System info?
    if isSystem then
        if isSpecial then
            if FilterState.SpecialSystem == false then
                return false
            end
        else
            if FilterState.SystemInfo == false then
                return false
            end
        end
        return true
    end

    -- Chat biasa
    if not FilterState.AllChat then
        -- Kalau AllChat dimatikan, tapi dia SpecialChat & filter special ON, boleh lewat
        if isSpecial and FilterState.SpecialChat then
            return true
        end
        return false
    end

    -- AllChat ON
    if isSpecial and not FilterState.SpecialChat then
        -- Kalau special chat dimatikan, skip yang special
        return false
    end

    return true
end

--------------------------------------------------
--  UTIL: TAMBAH BARIS LOG + KIRIM WEBHOOK
--------------------------------------------------
local function addLogLine(opts)
    -- opts: Player, Text, ChannelType, IsSystem, IsSpecialUser, IsMythic, Source
    local player       = opts.Player
    local text         = opts.Text or ""
    local channelType  = opts.ChannelType or "Chat"
    local isSystem     = opts.IsSystem or false
    local isSpecial    = opts.IsSpecialUser or false
    local isMythic     = opts.IsMythic or false
    local source       = opts.Source or "Text"

    if not passFilter(opts) then
        return
    end

    local playerName   = player and player.Name or "System"
    local displayName  = player and player.DisplayName or playerName

    local prefixParts = {}
    table.insert(prefixParts, "[" .. channelType .. "]")
    if isSystem then
        table.insert(prefixParts, "[SYSTEM]")
    end
    if isSpecial then
        table.insert(prefixParts, "[SPECIAL]")
    end
    if isMythic then
        table.insert(prefixParts, "[MIRETHOS/KAELVORN]")
    end
    if source == "STT" then
        table.insert(prefixParts, "[STT]")
    end

    local prefix = table.concat(prefixParts, " ")
    local lineText = string.format("%s %s (%s): %s", prefix, displayName, playerName, text)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    if isMythic then
        -- Warna pink khusus Mirethos/Kaelvorn
        lbl.TextColor3 = Color3.fromRGB(255, 120, 200)
    elseif isSpecial then
        lbl.TextColor3 = Color3.fromRGB(255, 210, 120)
    elseif isSystem then
        lbl.TextColor3 = Color3.fromRGB(255, 235, 150)
    else
        lbl.TextColor3 = Color3.fromRGB(40, 40, 70)
    end

    lbl.Text = lineText
    lbl.Parent = logScroll

    pushSubtitleLine(string.format("%s: %s", displayName, text))

    -- Optional: kirim ke Discord
    if WEBHOOK_URL ~= "" then
        -- warna embed
        local color = 0xFFD778 -- default kuning
        if isMythic then
            color = 0xFF78C8 -- pink
        elseif isSpecial then
            color = 0xFFE37A
        elseif isSystem then
            color = 0xFFE37A
        end

        local embed = {
            title = "Chat Publik HG + IC",
            description = lineText,
            color = color,
            footer = {
                text = os.date("!%Y-%m-%d %H:%M:%S UTC"),
            },
            fields = {
                {
                    name = "Channel / Source",
                    value = string.format("`%s / %s`", channelType, source),
                    inline = true,
                },
            },
        }

        local body = HttpService:JSONEncode({
            username = "Axa ChatPublik",
            embeds = {embed},
        })

        task.spawn(function()
            pcall(function()
                HttpService:PostAsync(WEBHOOK_URL, body, Enum.HttpContentType.ApplicationJson, false)
            end)
        end)
    end
end

--------------------------------------------------
--  INTEGRASI STT: _G.AxaChatRelay_ReceiveSTT
--------------------------------------------------
_G.AxaChatRelay_STTQueue = _G.AxaChatRelay_STTQueue or {}
local sttQueue = _G.AxaChatRelay_STTQueue

local function handleSTT(player, text, channelType)
    local isSpecial = isSpecialUser(player)
    local isMythic  = isMythicCatch(text)

    addLogLine({
        Player        = player,
        Text          = text,
        ChannelType   = channelType or "Voice",
        IsSystem      = false,
        IsSpecialUser = isSpecial,
        IsMythic      = isMythic,
        Source        = "STT",
    })
end

_G.AxaChatRelay_ReceiveSTT = handleSTT

-- Flush queue yang sudah dikumpulkan sebelum TAB ini kebuka
for _, args in ipairs(sttQueue) do
    local ok, err = pcall(function()
        handleSTT(table.unpack(args))
    end)
    if not ok then
        warn("[Axa ChatPublik] Gagal proses STT queue:", err)
    end
end

table.clear(sttQueue)

--------------------------------------------------
--  HOOK CHAT TEXT BIASA (OPSIONAL, GENERIK)
--------------------------------------------------
local function handleTextChat(player, text, channelType, isSystem)
    local isSpecial = isSpecialUser(player)
    local isMythic  = isMythicCatch(text)

    addLogLine({
        Player        = player,
        Text          = text,
        ChannelType   = channelType or "Chat",
        IsSystem      = isSystem or false,
        IsSpecialUser = isSpecial,
        IsMythic      = isMythic,
        Source        = "Text",
    })
end

-- Coba pakai TextChatService (chat baru)
if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(message)
        local txt = message.Text
        local channelName = "Chat"
        if message.TextChannel then
            channelName = message.TextChannel.Name
        end

        local isSystem = (message.Status ~= Enum.TextChatMessageStatus.Success)
        local p = nil

        if message.TextSource and message.TextSource.UserId then
            p = Players:GetPlayerByUserId(message.TextSource.UserId)
        end

        handleTextChat(p, txt, channelName, isSystem)
    end)
else
    -- Fallback: legacy chat (nggak selalu work di game yang pakai TextChatService)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local defaultChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if defaultChatEvents then
        local onMessageDone = defaultChatEvents:FindFirstChild("OnMessageDoneFiltering")
        if onMessageDone and onMessageDone:IsA("RemoteEvent") then
            onMessageDone.OnClientEvent:Connect(function(data)
                local p
                if data.FromSpeaker and Players:FindFirstChild(data.FromSpeaker) then
                    p = Players[data.FromSpeaker]
                end
                local txt = data.Message or ""
                local channelName = data.OriginalChannel or "Chat"
                handleTextChat(p, txt, channelName, false)
            end)
        end
    end
end

--------------------------------------------------
--  EXPOSE DI _G (OPTIONAL)
--------------------------------------------------
_G.AxaChatPublik = {
    FilterState        = FilterState,
    ChatFilterEnabled  = function() return ChatFilterEnabled end,
    AddLogLine         = addLogLine,
    IsSpecialUser      = isSpecialUser,
    IsMythicCatch      = isMythicCatch,
}
