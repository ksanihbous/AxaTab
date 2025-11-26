--==========================================================
--  AxaTab_ChatPublik.lua
--  Dipanggil via AxaHub CORE (loadstring + env TAB_FRAME)
--  Fitur:
--    - Relay Public Chat + System Info → Discord Webhook
--    - SPECIAL user (ID + friend koneksi) dengan warna & mention
--    - Filter Chat (All/System/Special/System Special/Chat Khusus)
--    - Master toggle "Chat Filter: ON/OFF"
--    - Subtitle Panel (1–3 pesan terakhir)
--    - History file: historychat.txt (multi-part upload)
--    - STT hook (_G + RemoteEvent + BindableEvent)
--==========================================================

------------------- SERVICES -------------------
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local TextChatService    = game:GetService("TextChatService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LOCAL_PLAYER = Players.LocalPlayer

-- Pastikan TAB_FRAME ada (env dari CORE)
local ROOT_FRAME = TAB_FRAME or CONTENT_HOLDER or nil

------------------- STT QUEUE (GLOBAL) -------------------
_G.AxaChatRelay_STTQueue = _G.AxaChatRelay_STTQueue or {}
local STT_QUEUE = _G.AxaChatRelay_STTQueue

------------------- CONFIG DISCORD -------------------
local WEBHOOK_URLS = {
    "https://discord.com/api/webhooks/1440379761389080597/yRL_Ek5RSttD-cMVPE6f0VtfpuRdMcVOjq4IkqtFOycPKjwFCiojViQGwXd_7AqXRM2P", -- utama
    --"https://discord.com/api/webhooks/....", -- tambahan kalau mau
}

local BOT_USERNAME = "AxaXyz - Chat Relay"
local BOT_AVATAR   = "https://mylogo.edgeone.app/Logo%20Ax%20(NO%20BG).png"

------------------- CONFIG FILTER CHAT (BASE) -------------------
local LOG_SYSTEM_MESSAGE  = true
local LOG_LOCAL_PLAYER    = true
local LOG_OTHER_PLAYERS   = true

------------------- CONFIG FILTER CHAT (UI RUNTIME) -------------------
-- Nilai awal (akan diubah lewat checkbox header)
local FILTER_ALLCHAT            = true   -- chat player biasa (non-special)
local FILTER_SYSTEMINFO         = true   -- system/info umum
local FILTER_SPECIALCHAT        = true   -- chat dari SPECIAL user
local FILTER_SYSTEMINFO_SPECIAL = true   -- system/info yang terkait SPECIAL userId/koneksi
local FILTER_CHAT_KHUSUS        = false  -- system info khusus Mirethos/Kaelvorn
local NEARBY_CAPTION_ONLY       = false  -- subtitle hanya player terdekat
local NEARBY_MAX_DISTANCE       = 17     -- studs (≈ 5–6 meter)

-- Master switch untuk filter (bukan matiin relay, cuma matiin efek checkbox filter)
local CHAT_FILTER_ENABLED       = true

------------------- CONFIG HISTORY FILE -------------------
local HISTORY_ENABLED      = true
local HISTORY_FILENAME     = "historychat.txt"
local HISTORY_MAX_LINES    = 90
local HISTORY_MAX_CHARS    = 6000
local HISTORY_SEND_ON_EACH = false   -- batch besar → baru kirim

------------------- CONFIG SPECIAL PUBLIC CHAT -------------------
local SPECIAL_USERS = {
    [8662842080] = {
        username = "@Fairymeyyy",
        name     = "Croffle IC",
        discord  = "<@1207987135093936149>",
    },
    [8858338738] = {
        username = "@zieeef",
        name     = "Zie IC",
        discord  = "<@1354602282418704536>",
    },
    [3902896904] = {
        username = "@kotjolo",
        name     = "Jeki IC",
        discord  = "<@914910569436418128>",
    },
    [8980225079] = {
        username = "@hanns_GOD",
        name     = "Hans IC",
        discord  = "<@1405950233929715863>",
    },
    [8661786368] = {
        username = "@chocotreadss",
        name     = "Yesha IC",
        discord  = "<@1419885298581639211>",
    },
    [9154320458] = {
        username = "@biwwa085",
        name     = "Bebybolo HG",
        discord  = "<@1425189351524012092>",
    },
    [8405726221] = {
        username = "@yipinsipi",
        name     = "Yiphin HG",
        discord  = "<@1400344558059126894>",
    },
    [7941438813] = {
        username = "@TripleA_666",
        name     = "Miaw HG",
        discord  = "<@1069652543203971174>",
    },
    [8957393843] = {
        username = "@AxaXyz999",
        name     = "AxaXyz999xBBHY",
        discord  = "<@1403052152691101857>",
    },
}

local SPECIAL_USER_IDS   = {}
local SPECIAL_DISCORD_MAP = {}

for userId, info in pairs(SPECIAL_USERS) do
    SPECIAL_USER_IDS[userId] = true
    if info.discord and info.discord ~= "" then
        SPECIAL_DISCORD_MAP[userId] = info.discord
    end
end

local DISCORD_MENTION = table.concat({
    "<@1207987135093936149>",
    "<@1354602282418704536>",
    "<@914910569436418128>",
    "<@1405950233929715863>",
    "<@1419885298581639211>",
    "<@1425189351524012092>",
    "<@1400344558059126894>",
    "<@1069652543203971174>",
    "<@1403052152691101857>",
}, " ")

local dynamicSpecialUserIds = {}

local SPECIAL_EMBED_COLOR = 0xFFFF00 -- kuning terang
local SPECIAL_LABEL       = "✨"
local KHUSUS_EMBED_COLOR  = 0xFF66CC -- merah muda

local function isSpecialUser(userId)
    if not userId then return false end
    if SPECIAL_USER_IDS[userId] then return true end
    if dynamicSpecialUserIds[userId] then return true end
    return false
end

local function updateConnectionSpecial(p)
    if not p or not p.UserId or p == LOCAL_PLAYER then return end

    local ok, isFriend = pcall(function()
        return LOCAL_PLAYER:IsFriendsWith(p.UserId)
    end)

    if ok and isFriend then
        dynamicSpecialUserIds[p.UserId] = true
        print(string.format("[Axa Chat Relay] SPECIAL connection detected: %s (%d)", p.Name, p.UserId))
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    updateConnectionSpecial(plr)
end

Players.PlayerAdded:Connect(function(plr)
    updateConnectionSpecial(plr)
end)

------------------- CONFIG WITA -------------------
local WITA_OFFSET_SECONDS = 8 * 60 * 60

local MONTH_NAMES_ID = {
    "Januari","Februari","Maret","April","Mei","Juni",
    "Juli","Agustus","September","Oktober","November","Desember"
}

local function getWITADateTimeTable()
    local utcNow  = os.time()
    local witaNow = utcNow + WITA_OFFSET_SECONDS
    return os.date("!*t", witaNow)
end

local function getWITAClockString()
    local t = getWITADateTimeTable()
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function getWITATimestampText()
    local t = getWITADateTimeTable()
    local monthName = MONTH_NAMES_ID[t.month] or tostring(t.month)

    local tanggalStr = string.format("%02d %s %04d", t.day, monthName, t.year)
    local waktuStr   = string.format("%02d.%02d WITA", t.hour, t.min)
    local fullStr    = string.format("Tanggal: %s, Waktu: %s", tanggalStr, waktuStr)

    return tanggalStr, waktuStr, fullStr
end

------------------------------------------------
--  STRING UTIL
------------------------------------------------
local function stripFontTags(str)
    if not str or str == "" then return str end
    str = str:gsub("<font[^>]*>", "")
    str = str:gsub("</font>", "")
    return str
end

------------------------------------------------
--  HTTP REQUEST HELPER (Executor)
------------------------------------------------
local function detectHttpRequest()
    local req = nil

    pcall(function()
        if syn and syn.request then
            req = syn.request
            return
        end
    end)

    if not req then
        pcall(function()
            if http and http.request then
                req = http.request
            end
        end)
    end

    if not req and http_request then
        req = http_request
    end

    if not req and request then
        req = request
    end

    if not req then
        warn("[Axa Chat Relay] Executor TIDAK support http_request/syn.request/http.request, webhook tidak bisa dikirim. (UI & subtitle tetap jalan)")
    end

    return req
end

local httpRequest = detectHttpRequest()

------------------------------------------------
--  INFO SERVER
------------------------------------------------
local PLACE_NAME = "Unknown Place"
do
    local ok, result = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and result and result.Name then
        PLACE_NAME = result.Name
    end
end

local PLACE_ID = game.PlaceId or 0

local function slugifyPlaceName(name)
    local slug = name or ""
    slug = slug:gsub("[^%w]+", "-")
    slug = slug:gsub("%-+", "-")
    slug = slug:gsub("^%-", ""):gsub("%-$", "")
    if slug == "" then
        slug = tostring(PLACE_ID)
    end
    return slug
end

local PLACE_SLUG = slugifyPlaceName(PLACE_NAME)
local PLACE_URL  = string.format("https://www.roblox.com/id/games/%d/%s", PLACE_ID, PLACE_SLUG)

------------------------------------------------
--  HISTORY BUFFER
------------------------------------------------
local historyLines   = {}
local historyCount   = 0
local historyCharLen = 0

local function buildHistoryContent()
    if historyCount == 0 then
        return ""
    end
    return table.concat(historyLines, "\n")
end

local function resetHistoryBuffer()
    historyLines   = {}
    historyCount   = 0
    historyCharLen = 0
end

local function sendHistoryFile()
    if not HISTORY_ENABLED then return end
    if historyCount == 0 then return end
    if not WEBHOOK_URLS or #WEBHOOK_URLS == 0 then return end
    if not httpRequest then return end

    local contentText = buildHistoryContent()
    if contentText == "" then return end

    if #contentText > 190000 then
        contentText = string.sub(contentText, 1, 190000) .. "\n...[dipotong karena terlalu panjang]"
    end

    local _, _, fullTs = getWITATimestampText()
    local boundary = "----AXA_CHAT_HISTORY_" .. HttpService:GenerateGUID(false)

    local payload = {
        username   = BOT_USERNAME,
        avatar_url = BOT_AVATAR,
        content    = "📄 History Chat (batch) " .. DISCORD_MENTION .. "\n" .. fullTs
    }

    local payloadJson = HttpService:JSONEncode(payload)

    local bodyParts = {}

    table.insert(bodyParts, "--" .. boundary)
    table.insert(bodyParts, 'Content-Disposition: form-data; name="payload_json"')
    table.insert(bodyParts, "Content-Type: application/json")
    table.insert(bodyParts, "")
    table.insert(bodyParts, payloadJson)

    table.insert(bodyParts, "--" .. boundary)
    table.insert(bodyParts, 'Content-Disposition: form-data; name="file"; filename="' .. HISTORY_FILENAME .. '"')
    table.insert(bodyParts, "Content-Type: text/plain")
    table.insert(bodyParts, "")
    table.insert(bodyParts, contentText)

    table.insert(bodyParts, "--" .. boundary .. "--")

    local body = table.concat(bodyParts, "\r\n")

    local anyOk = false

    for _, url in ipairs(WEBHOOK_URLS) do
        if url and url ~= "" then
            local ok, err = pcall(function()
                httpRequest({
                    Url = url,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
                    },
                    Body = body
                })
            end)

            if not ok then
                warn("[Axa Chat Relay] Gagal kirim file historychat ke " .. tostring(url) .. ":", err)
            else
                anyOk = true
            end
        end
    end

    if anyOk then
        print("[Axa Chat Relay] historychat.txt terkirim (batch " .. tostring(historyCount) .. " baris).")
        resetHistoryBuffer()
    end
end

local function addHistoryLine(line)
    if not HISTORY_ENABLED then return end
    if not line or line == "" then return end

    historyCount   = historyCount + 1
    historyLines[historyCount] = line
    historyCharLen = historyCharLen + #line + 1

    if not HISTORY_SEND_ON_EACH then
        if historyCount >= HISTORY_MAX_LINES or historyCharLen >= HISTORY_MAX_CHARS then
            task.spawn(sendHistoryFile)
        end
    else
        if historyCount >= 10 then
            task.spawn(sendHistoryFile)
        end
    end
end

------------------------------------------------
--  SUBTITLE PANEL (ScreenGui terpisah)
------------------------------------------------
local subtitleGui
local subtitleFrame
local subtitleLines = {}

local function createSubtitleUI()
    if subtitleGui and subtitleGui.Parent then
        return
    end

    local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui") or LOCAL_PLAYER:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AxaSubtitleUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    subtitleGui = screenGui

    local frame = Instance.new("Frame")
    frame.Name = "SubtitleFrame"
    frame.Parent = screenGui
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Position = UDim2.new(0.5, 0, 1, -60)
    frame.Size = UDim2.new(0.8, 0, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft  = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frame

    subtitleFrame = frame
end

local function getSubtitleFrame()
    if subtitleFrame and subtitleFrame.Parent then
        return subtitleFrame
    end
    createSubtitleUI()
    return subtitleFrame
end

local function updateSubtitleUI()
    local frame = getSubtitleFrame()
    if not frame then return end

    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for index, text in ipairs(subtitleLines) do
        local label = Instance.new("TextLabel")
        label.Name = "SubtitleLine" .. index
        label.Parent = frame
        label.Size = UDim2.new(1, 0, 0, 26)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.2
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = text
    end

    frame.Visible = (#subtitleLines > 0)
end

local function pushSubtitleLine(text)
    if not text or text == "" then return end
    table.insert(subtitleLines, text)
    if #subtitleLines > 3 then
        table.remove(subtitleLines, 1)
    end
    updateSubtitleUI()
end

local function pushSubtitleMessage(channelName, displayName, authorName, messageText, isSystem, isSpecial, isPrivate, isKhusus, speakerPlayer)
    if not messageText or messageText == "" then return end

    if NEARBY_CAPTION_ONLY and speakerPlayer and speakerPlayer ~= LOCAL_PLAYER then
        local char   = speakerPlayer.Character
        local myChar = LOCAL_PLAYER.Character
        if char and myChar then
            local hrp   = char:FindFirstChild("HumanoidRootPart")
            local myHrp = myChar:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if dist > NEARBY_MAX_DISTANCE then
                    return
                end
            end
        end
    end

    local prefixParts = {}

    if isSystem then
        table.insert(prefixParts, "[System]")
    else
        if channelName and channelName ~= "" then
            table.insert(prefixParts, "[" .. tostring(channelName) .. "]")
        end
        local nameToUse = (displayName and displayName ~= "" and displayName) or authorName
        if nameToUse and nameToUse ~= "" then
            table.insert(prefixParts, tostring(nameToUse) .. ":")
        end
    end

    local header = table.concat(prefixParts, " ")
    local fullText = header ~= "" and (header .. " " .. messageText) or messageText

    pushSubtitleLine(fullText)
end

------------------------------------------------
--  DETEKSI "System Info Special" dari isi teks
------------------------------------------------
local function detectSystemSpecialFromText(text)
    if not text or text == "" then
        return false, nil, nil, nil
    end

    local lowerText = text:lower()

    for _, plr in ipairs(Players:GetPlayers()) do
        local n = plr.Name and plr.Name:lower() or ""
        local d = plr.DisplayName and plr.DisplayName:lower() or ""

        if (n ~= "" and lowerText:find(n, 1, true)) or (d ~= "" and lowerText:find(d, 1, true)) then
            if isSpecialUser(plr.UserId) then
                return true, plr.Name, plr.DisplayName, plr.UserId
            end
        end
    end

    return false, nil, nil, nil
end

------------------------------------------------
--  FILTER LOGIC
------------------------------------------------
local function shouldRelayChat(isSystem, player, isSpecial, isKhusus)
    isKhusus = isKhusus and true or false

    -- Base gate (bukan dari UI filter)
    if isSystem then
        if not LOG_SYSTEM_MESSAGE then
            return false
        end
    else
        if player then
            if player == LOCAL_PLAYER then
                if not LOG_LOCAL_PLAYER then return false end
            else
                if not LOG_OTHER_PLAYERS then return false end
            end
        end
    end

    -- Kalau master filter dimatikan → semua lewat (abaikan checkbox filter)
    if not CHAT_FILTER_ENABLED then
        return true
    end

    -- Di bawah ini baru filter dari UI (checkbox)
    if isKhusus and not FILTER_CHAT_KHUSUS then
        return false
    end

    if isSystem then
        if isSpecial then
            if not FILTER_SYSTEMINFO_SPECIAL then
                return false
            end
        else
            if not FILTER_SYSTEMINFO then
                return false
            end
        end
        return true
    end

    if isSpecial then
        if not FILTER_SPECIALCHAT then
            return false
        end
    else
        if not FILTER_ALLCHAT then
            return false
        end
    end

    return true
end

------------------------------------------------
--  DISCORD WEBHOOK SENDER
------------------------------------------------
local function sendDiscordChat(authorName, displayName, userId, messageText, channelName, isSystem, isSpecialOverride, isKhususOverride)
    if not WEBHOOK_URLS or #WEBHOOK_URLS == 0 then return end
    if not httpRequest then return end
    if not messageText or messageText == "" then return end

    if #messageText > 1900 then
        messageText = string.sub(messageText, 1, 1900) .. "..."
    end

    authorName   = authorName   or "Unknown"
    displayName  = displayName  or "-"
    userId       = userId       or 0
    channelName  = channelName  or "Global"
    isSystem     = isSystem and true or false

    local jenisChat = isSystem and "System / Info" or "Public Chat"

    local isSpecialFlag = isSpecialOverride
    if isSpecialFlag == nil then
        isSpecialFlag = isSpecialUser(userId)
    end

    local isKhusus = isKhususOverride and true or false

    local profileUrl
    if userId ~= 0 then
        profileUrl = string.format("https://www.roblox.com/id/users/%d/profile", userId)
    end

    local pengirimLines = {}

    local firstLine = "Username: " .. tostring(authorName)
    if isSpecialFlag and not isSystem then
        firstLine = SPECIAL_LABEL .. " " .. firstLine
    end
    table.insert(pengirimLines, firstLine)
    table.insert(pengirimLines, "DisplayName: " .. tostring(displayName))
    table.insert(pengirimLines, "UserId: " .. tostring(userId))
    if profileUrl then
        table.insert(pengirimLines, "ProfileUrl: " .. profileUrl)
    end

    local pengirimFieldValue = "```yaml\n" .. table.concat(pengirimLines, "\n") .. "\n```"
    local channelFieldValue  = "```yaml\nChannel: " .. tostring(channelName) .. "\n```"

    local serverLines = {
        "PlaceName: " .. tostring(PLACE_NAME),
        "PlaceId: " .. tostring(PLACE_ID),
        "PlaceUrl: " .. tostring(PLACE_URL),
        "JobId: " .. tostring(game.JobId or "N/A"),
        "Players: " .. tostring(#Players:GetPlayers())
    }
    local serverFieldValue = "```yaml\n" .. table.concat(serverLines, "\n") .. "\n```"

    local _, _, fullTs = getWITATimestampText()
    local timestampLines = {
        "Timestamp: " .. fullTs
    }
    local timestampFieldValue = "```yaml\n" .. table.concat(timestampLines, "\n") .. "\n```"

    local specialFieldValue = nil
    if isSpecialFlag then
        local perUserMention = SPECIAL_DISCORD_MAP[userId]
        if perUserMention then
            specialFieldValue = perUserMention
        else
            specialFieldValue = "<@1403052152691101857>"
        end
    end

    local avatarUrl = BOT_AVATAR
    if userId ~= 0 then
        avatarUrl = string.format(
            "https://www.roblox.com/avatar-thumbnail/image?userId=%d&width=420&height=420&format=png",
            userId
        )
    end

    local embedTitle = "💬 " .. jenisChat
    local embedColor = isSystem and 0xFFCC00 or 0x00FFFF
    if isSpecialFlag then
        if isSystem then
            embedTitle = "💬 System / Info (SPECIAL)"
        else
            embedTitle = "💬 Public Chat (SPECIAL)"
        end
        embedColor = SPECIAL_EMBED_COLOR
    end

    if isKhusus then
        embedColor = KHUSUS_EMBED_COLOR
    end

    local fields = {}

    table.insert(fields, {
        name = "Pengirim",
        value = pengirimFieldValue,
        inline = false
    })

    table.insert(fields, {
        name = "Channel",
        value = channelFieldValue,
        inline = false
    })

    table.insert(fields, {
        name = "Server",
        value = serverFieldValue,
        inline = false
    })

    table.insert(fields, {
        name = "Timestamp",
        value = timestampFieldValue,
        inline = false
    })

    if specialFieldValue then
        table.insert(fields, {
            name  = "Special Mention",
            value = specialFieldValue,
            inline = false
        })
    end

    local embed = {
        title = embedTitle,
        description = messageText,
        color = embedColor,
        fields = fields,
        footer = {
            text = fullTs
        },
        image = {
            url = avatarUrl
        },
        thumbnail = {
            url = avatarUrl
        }
    }

    local payload = {
        username   = BOT_USERNAME,
        avatar_url = BOT_AVATAR,
        content    = "",
        embeds     = {embed}
    }

    local jsonData = HttpService:JSONEncode(payload)

    for _, url in ipairs(WEBHOOK_URLS) do
        if url and url ~= "" then
            local ok, err = pcall(function()
                httpRequest({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = jsonData
                })
            end)

            if not ok then
                warn("[Axa Chat Relay] Gagal kirim webhook chat ke " .. tostring(url) .. ":", err)
            end
        end
    end
end

------------------------------------------------
--  UI: HEADER CHECKBOX DALAM CORE TAB
------------------------------------------------
local function createHeaderFilterUI()
    if not ROOT_FRAME then return end

    -- Styling TAB agar senada gelap
    ROOT_FRAME.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    ROOT_FRAME.BackgroundTransparency = 0

    -- Bersihin header lama kalau ada
    local oldHeader = ROOT_FRAME:FindFirstChild("ChatPublikHeader")
    if oldHeader then
        oldHeader:Destroy()
    end

    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "ChatPublikHeader"
    headerFrame.Parent = ROOT_FRAME
    headerFrame.BackgroundTransparency = 1
    headerFrame.Size = UDim2.new(1, -16, 0, 120)
    headerFrame.Position = UDim2.new(0, 8, 0, 8)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Parent = headerFrame
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Size = UDim2.new(1, -140, 0, 22)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
    titleLabel.Text = "CHAT PUBLIK  •  Chat Filter"

    -- Master toggle
    local masterToggle
    local checkButtons = {}

    local function refreshMaster()
        if not masterToggle then return end
        if CHAT_FILTER_ENABLED then
            masterToggle.Text = "Chat Filter: ON"
            masterToggle.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
            masterToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            masterToggle.Text = "Chat Filter: OFF"
            masterToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
            masterToggle.TextColor3 = Color3.fromRGB(205, 205, 215)
        end

        for _, btn in ipairs(checkButtons) do
            if CHAT_FILTER_ENABLED then
                btn.AutoButtonColor = true
                btn.BackgroundTransparency = 0.15
                btn.TextTransparency = 0
            else
                btn.AutoButtonColor = false
                btn.BackgroundTransparency = 0.35
                btn.TextTransparency = 0.3
            end
        end
    end

    masterToggle = Instance.new("TextButton")
    masterToggle.Name = "MasterToggle"
    masterToggle.Parent = headerFrame
    masterToggle.AnchorPoint = Vector2.new(1, 0)
    masterToggle.Position = UDim2.new(1, 0, 0, 0)
    masterToggle.Size = UDim2.new(0, 130, 0, 22)
    masterToggle.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    masterToggle.BorderSizePixel = 0
    masterToggle.AutoButtonColor = true
    masterToggle.Font = Enum.Font.GothamBold
    masterToggle.TextSize = 12
    masterToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    masterToggle.Text = "Chat Filter: ON"

    local mtCorner = Instance.new("UICorner")
    mtCorner.CornerRadius = UDim.new(0, 8)
    mtCorner.Parent = masterToggle

    masterToggle.MouseButton1Click:Connect(function()
        CHAT_FILTER_ENABLED = not CHAT_FILTER_ENABLED
        refreshMaster()
    end)

    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Desc"
    descLabel.Parent = headerFrame
    descLabel.BackgroundTransparency = 1
    descLabel.Position = UDim2.new(0, 0, 0, 24)
    descLabel.Size = UDim2.new(1, 0, 0, 18)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 12
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 195)
    descLabel.Text = "Webhook + History + Subtitle • Checkbox hanya aktif kalau Chat Filter: ON"

    local filterList = Instance.new("Frame")
    filterList.Name = "FilterList"
    filterList.Parent = headerFrame
    filterList.BackgroundTransparency = 1
    filterList.Position = UDim2.new(0, 0, 0, 46)
    filterList.Size = UDim2.new(1, 0, 0, 70)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = filterList
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)

    local function makeCheck(label, initial, onToggle)
        local btn = Instance.new("TextButton")
        btn.Parent = filterList
        btn.Size = UDim2.new(1, 0, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextColor3 = Color3.fromRGB(230, 230, 240)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        local state = initial and true or false

        local function refresh()
            local mark = state and "✔" or " "
            btn.Text = string.format("[%s] %s", mark, label)
        end

        btn.MouseButton1Click:Connect(function()
            state = not state
            refresh()
            if onToggle then
                onToggle(state)
            end
        end)

        refresh()
        table.insert(checkButtons, btn)
        return btn
    end

    -- 1. All Chat
    makeCheck("All Chat", FILTER_ALLCHAT, function(state)
        FILTER_ALLCHAT = state
    end)

    -- 2. System Info
    makeCheck("System Info", FILTER_SYSTEMINFO, function(state)
        FILTER_SYSTEMINFO = state
    end)

    -- 3. Special UserID / koneksi
    makeCheck("Special UserID / koneksi", FILTER_SPECIALCHAT, function(state)
        FILTER_SPECIALCHAT = state
    end)

    -- 4. System Info Special UserID / koneksi
    makeCheck("System Info Special UserID / koneksi", FILTER_SYSTEMINFO_SPECIAL, function(state)
        FILTER_SYSTEMINFO_SPECIAL = state
    end)

    -- 5. Filter chat khusus (Mirethos / Kaelvorn)
    makeCheck("Filter chat khusus (Mirethos / Kaelvorn)", FILTER_CHAT_KHUSUS, function(state)
        FILTER_CHAT_KHUSUS = state
    end)

    -- 6. Subtitle hanya player terdekat
    makeCheck("Subtitle hanya player terdekat", NEARBY_CAPTION_ONLY, function(state)
        NEARBY_CAPTION_ONLY = state
    end)

    refreshMaster()
end

------------------------------------------------
--  HOOK NEW CHAT
------------------------------------------------
local function hookNewChat()
    print("[Axa Chat Relay] Menggunakan TextChatService (new chat).")

    TextChatService.MessageReceived:Connect(function(message)
        local text = message.Text
        if not text or text == "" then return end

        local textSource = message.TextSource
        local player = nil
        local isSystem = false
        local sourceUserId = nil

        if textSource then
            sourceUserId = textSource.UserId
            if sourceUserId then
                player = Players:GetPlayerByUserId(sourceUserId)
            end
        end

        if not player then
            isSystem = true
        end

        local userId = 0
        if player then
            userId = player.UserId
        elseif sourceUserId then
            userId = sourceUserId
        end

        if isSystem then
            text = stripFontTags(text)
        end

        local authorName  = player and player.Name or (message.PrefixText or "System")
        local displayName = player and player.DisplayName or (isSystem and "System" or "-")
        local channelName = (message.TextChannel and message.TextChannel.Name) or "Global"

        local isSpecialFlag = false

        if isSystem then
            local specialDetected, newAuthor, newDisplay, detectedUserId = detectSystemSpecialFromText(text)
            if specialDetected then
                isSpecialFlag = true
                if newAuthor then authorName   = newAuthor end
                if newDisplay then displayName = newDisplay end
                if detectedUserId then userId  = detectedUserId end
            end
        else
            isSpecialFlag = isSpecialUser(userId)
        end

        local isKhusus = false
        if isSystem and userId ~= 0 and SPECIAL_USER_IDS[userId] then
            local lowerText = text:lower()
            if lowerText:find("caught a mirethos", 1, true) or lowerText:find("caught a kaelvorn", 1, true) then
                isKhusus = true
            end
        end

        if not shouldRelayChat(isSystem, player, isSpecialFlag, isKhusus) then
            pushSubtitleMessage(channelName, displayName, authorName, text, isSystem, isSpecialFlag, false, isKhusus, player)
            return
        end

        pushSubtitleMessage(channelName, displayName, authorName, text, isSystem, isSpecialFlag, false, isKhusus, player)
        sendDiscordChat(authorName, displayName, userId, text, channelName, isSystem, isSpecialFlag, isKhusus)

        local tsShort = getWITAClockString()
        local shinyPrefix = isSpecialFlag and (SPECIAL_LABEL .. " ") or ""

        local line = string.format("[%s] [%s] %s%s (%s/%d): %s",
            tsShort,
            channelName,
            shinyPrefix,
            displayName,
            authorName,
            userId,
            text
        )
        addHistoryLine(line)
    end)
end

------------------------------------------------
--  HOOK LEGACY CHAT
------------------------------------------------
local function hookLegacyChat()
    print("[Axa Chat Relay] Menggunakan Legacy Chat (Player.Chatted).")

    local function attachPlayer(p)
        p.Chatted:Connect(function(msg)
            local isSystem = false
            local isSpecialFlag = isSpecialUser(p.UserId)
            local isKhusus = false

            if not shouldRelayChat(false, p, isSpecialFlag, isKhusus) then
                pushSubtitleMessage("LegacyChat", p.DisplayName, p.Name, msg, isSystem, isSpecialFlag, false, isKhusus, p)
                return
            end

            pushSubtitleMessage("LegacyChat", p.DisplayName, p.Name, msg, isSystem, isSpecialFlag, false, isKhusus, p)
            sendDiscordChat(p.Name, p.DisplayName, p.UserId, msg, "LegacyChat", isSystem, isSpecialFlag, isKhusus)

            local timeStr = getWITAClockString()
            local shinyPrefix = isSpecialFlag and (SPECIAL_LABEL .. " ") or ""

            local line = string.format("[%s] [LegacyChat] %s%s (%s/%d): %s",
                timeStr,
                shinyPrefix,
                p.DisplayName,
                p.Name,
                p.UserId,
                msg
            )
            addHistoryLine(line)
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        attachPlayer(p)
    end

    Players.PlayerAdded:Connect(attachPlayer)
end

------------------------------------------------
--  HELPER: RESOLVE SPEAKER UNTUK STT
------------------------------------------------
local function resolveSpeakerInfo(speaker)
    local player
    local userId
    local authorName
    local displayName

    local t = typeof(speaker)

    if t == "Instance" and speaker:IsA("Player") then
        player = speaker
        userId = player.UserId
        authorName = player.Name
        displayName = player.DisplayName
    elseif t == "number" then
        userId = speaker
        player = Players:GetPlayerByUserId(userId)
        if player then
            authorName = player.Name
            displayName = player.DisplayName
        else
            authorName = "UserId_" .. tostring(userId)
            displayName = "User " .. tostring(userId)
        end
    elseif t == "table" then
        if typeof(speaker.UserId) == "number" then
            userId = speaker.UserId
            player = Players:GetPlayerByUserId(userId)
        end
        if typeof(speaker.Name) == "string" then
            authorName = speaker.Name
        end
        if typeof(speaker.DisplayName) == "string" then
            displayName = speaker.DisplayName
        end
        if player and not authorName then
            authorName = player.Name
        end
        if player and not displayName then
            displayName = player.DisplayName
        end
    end

    if not player and LOCAL_PLAYER then
        player = LOCAL_PLAYER
        userId = userId or LOCAL_PLAYER.UserId
        authorName = authorName or LOCAL_PLAYER.Name
        displayName = displayName or LOCAL_PLAYER.DisplayName
    end

    userId      = userId or 0
    authorName  = authorName or "Unknown"
    displayName = displayName or "-"

    return player, userId, authorName, displayName
end

------------------------------------------------
--  PUBLIC API: STT
------------------------------------------------
local STT_REMOTE_FOLDER_NAME = "AxaChatRelay_Remotes"
local STT_REMOTE_EVENT_NAME  = "AxaChatRelay_STT"
local STT_BINDABLE_NAME      = "AxaChatRelay_STTBindable"

local STT_REMOTE_EVENT
local STT_BINDABLE_EVENT

local function relaySTTMessage(speaker, transcribedText, sourceChannelName)
    if not transcribedText or transcribedText == "" then
        return
    end

    local channelName = sourceChannelName or "Voice"

    local speakerPlayer, userId, authorName, displayName = resolveSpeakerInfo(speaker)
    local isSystem      = false
    local isSpecialFlag = isSpecialUser(userId)
    local isKhusus      = false

    local decoratedText = "[VOICE] " .. transcribedText

    print(string.format("[Axa Chat Relay][STT] %s (%d) @ %s: %s", authorName, userId, channelName, transcribedText))

    -- Subtitle selalu dicoba tampil
    pushSubtitleMessage(
        channelName,
        displayName,
        authorName,
        decoratedText,
        isSystem,
        isSpecialFlag,
        false,
        isKhusus,
        speakerPlayer
    )

    -- Filter untuk Discord + History
    if not shouldRelayChat(isSystem, speakerPlayer, isSpecialFlag, isKhusus) then
        return
    end

    sendDiscordChat(
        authorName,
        displayName,
        userId,
        decoratedText,
        channelName,
        isSystem,
        isSpecialFlag,
        isKhusus
    )

    local tsShort = getWITAClockString()
    local shinyPrefix = isSpecialFlag and (SPECIAL_LABEL .. " ") or ""

    local line = string.format(
        "[%s] [%s] %s%s (%s/%d): %s",
        tsShort,
        channelName,
        shinyPrefix,
        displayName,
        authorName,
        userId,
        decoratedText
    )
    addHistoryLine(line)
end

-- Auto-create RemoteEvent + BindableEvent di ReplicatedStorage
local function setupSTTRemotes()
    local folder = ReplicatedStorage:FindFirstChild(STT_REMOTE_FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = STT_REMOTE_FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    local remote = folder:FindFirstChild(STT_REMOTE_EVENT_NAME)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = STT_REMOTE_EVENT_NAME
        remote.Parent = folder
    end

    local bindable = folder:FindFirstChild(STT_BINDABLE_NAME)
    if not bindable then
        bindable = Instance.new("BindableEvent")
        bindable.Name = STT_BINDABLE_NAME
        bindable.Parent = folder
    end

    STT_REMOTE_EVENT   = remote
    STT_BINDABLE_EVENT = bindable

    STT_REMOTE_EVENT.OnClientEvent:Connect(function(speakerInfo, text, channelName)
        relaySTTMessage(speakerInfo, text, channelName)
    end)

    STT_BINDABLE_EVENT.Event:Connect(function(speakerInfo, text, channelName)
        relaySTTMessage(speakerInfo, text, channelName)
    end)
end

-- Global function (override stub dari CORE)
_G.AxaChatRelay_ReceiveSTT = relaySTTMessage

-- Replay semua STT yang sudah ngantri sebelum fungsi siap
if STT_QUEUE and #STT_QUEUE > 0 then
    for _, args in ipairs(STT_QUEUE) do
        local ok, err = pcall(function()
            relaySTTMessage(table.unpack(args))
        end)
        if not ok then
            warn("[Axa Chat Relay][STT] Gagal replay queue:", err)
        end
    end
    for i = #STT_QUEUE, 1, -1 do
        STT_QUEUE[i] = nil
    end
end

------------------------------------------------
--  START
------------------------------------------------
local function startChatRelay()
    local version = TextChatService.ChatVersion
    if version == Enum.ChatVersion.TextChatService then
        hookNewChat()
    else
        hookLegacyChat()
    end

    createSubtitleUI()
    setupSTTRemotes()
    createHeaderFilterUI()

    print("[Axa Chat Relay] Aktif: relay chat → Discord webhook + history file + SPECIAL shiny ✨"
        .. " + avatar thumbnail 420x420 + per-user Special Mention (+ fallback Axa)"
        .. " + Chat Khusus Mirethos/Kaelvorn (pink)"
        .. " + UI Filter Chat di header TAB + Master Chat Filter ON/OFF"
        .. " + Subtitle Panel (1–3 pesan terakhir)"
        .. " + STT hook (_G + RemoteEvent + BindableEvent).")
end

startChatRelay()

local okBind = pcall(function()
    game:BindToClose(function()
        pcall(sendHistoryFile)
    end)
end)
-- best-effort
