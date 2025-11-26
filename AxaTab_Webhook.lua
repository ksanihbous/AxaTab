--------------------------------------------------
-- AxaTab_Webhook (fungsi diperbaiki)
--------------------------------------------------
local webhookTabFrame = createTabContent("webhook")
createTabButton("webhook", "Webhook", 3)

local Players            = Players or game:GetService("Players")
local HttpService        = HttpService or game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local WEBHOOK_URL    = "https://discord.com/api/webhooks/1440379761389080597/yRL_Ek5RSttD-cMVPE6f0VtfpuRdMcVOjq4IkqtFOycPKjwFCiojViQGwXd_7AqXRM2P"
local BOT_AVATAR_URL = "https://mylogo.edgeone.app/Logo%20Ax%20(NO%20BG).png"

-- Discord embed batas aman (biar nggak kena 4k char)
local MAX_DESC       = 3600

-- Heuristik deteksi ikan
local FISH_KEYWORDS = {
    "ikan","fish","mirethos","kaelvorn","kraken",
    "shark","whale","ray","eel","salmon","tuna","cod"
}

-- Daftar favorit (deteksi by name contains)
local FAVORITE_FISH_NAMES = {
    "lumba pink",
    "lele",
    "mirethos",
    "kaelvorn",
}

-- ---------- UTIL TEKS / PARSE ----------
local function safeLower(s) return (typeof(s)=="string") and s:lower() or "" end

local function extractFishWeightKg(name)
    -- Ambil angka "xx.x kg" atau "xx.x"
    if not name then return nil end
    local lower = string.lower(name)
    local numStr = lower:match("(%d+%.?%d*)%s*kg") or lower:match("(%d+%.?%d*)")
    if not numStr then return nil end
    local w = tonumber(numStr)
    if not w then return nil end
    return w
end

local function getFishBaseName(rawName)
    -- Bersihin dekorasi & angka
    if not rawName or rawName == "" then return "Unknown Fish" end
    local name = rawName
    name = name:gsub("%b[]", "")
    name = name:gsub("%b()", "")
    name = name:gsub("%s*%d+[%d%.]*%s*kg", "")
    name = name:gsub("%s*%d+[%d%.]*$", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = rawName end
    return name
end

local function isFishName(raw)
    local l = safeLower(raw)
    for _, k in ipairs(FISH_KEYWORDS) do
        if l:find(k, 1, true) then return true end
    end
    return false
end

local function isRodName(raw)
    local l = safeLower(raw)
    return l:find("rod", 1, true) or l:find("pancing", 1, true) or l:find("fishing", 1, true)
end

local function isFavoriteFishName(name)
    local l = safeLower(name)
    for _, fav in ipairs(FAVORITE_FISH_NAMES) do
        if l:find(fav, 1, true) then return true end
    end
    return false
end

local function safeTruncate(s, maxLen)
    if not s then return "" end
    if #s <= maxLen then return s end
    return s:sub(1, maxLen-10) .. "\n...[dipotong]"
end

-- ---------- INFO SERVER / WITA ----------
local PLACE_NAME = "Unknown Place"
local PLACE_ID   = game.PlaceId or 0

do
    local ok, result = pcall(function()
        return MarketplaceService:GetProductInfo(PLACE_ID)
    end)
    if ok and result and result.Name then
        PLACE_NAME = result.Name
    end
end

local function slugifyPlaceName(name)
    local slug = name or ""
    slug = slug:gsub("[^%w]+", "-")
    slug = slug:gsub("%-+", "-")
    slug = slug:gsub("^%-", ""):gsub("%-$", "")
    if slug == "" then slug = tostring(PLACE_ID) end
    return slug
end

local PLACE_SLUG = slugifyPlaceName(PLACE_NAME)
local PLACE_URL  = string.format("https://www.roblox.com/id/games/%d/%s", PLACE_ID, PLACE_SLUG)

local WITA_OFFSET_SECONDS = 8 * 60 * 60
local MONTH_NAMES_ID = {
    "Januari","Februari","Maret","April","Mei","Juni",
    "Juli","Agustus","September","Oktober","November","Desember"
}
local function getWITA()
    local utc = os.time()
    local wita = utc + WITA_OFFSET_SECONDS
    local t = os.date("!*t", wita)
    local tanggalStr = string.format("%02d %s %04d", t.day, MONTH_NAMES_ID[t.month] or t.month, t.year)
    local waktuStr   = string.format("%02d:%02d WITA", t.hour, t.min)
    return tanggalStr .. ", " .. waktuStr
end

-- ---------- HTTP REQUEST DETECT ----------
local function detectHttpRequest()
    local req = nil
    pcall(function() if syn and syn.request then req = syn.request end end)
    if not req then pcall(function() if http and http.request then req = http.request end end) end
    if not req and http_request then req = http_request end
    if not req and request then req = request end
    return req
end

-- ---------- UI (yang sudah ada dari kamu) ----------
local whHeader = Instance.new("TextLabel")
whHeader.Name = "Header"
whHeader.Size = UDim2.new(1, -10, 0, 22)
whHeader.Position = UDim2.new(0, 5, 0, 6)
whHeader.BackgroundTransparency = 1
whHeader.Font = Enum.Font.GothamBold
whHeader.TextSize = 15
whHeader.TextColor3 = Color3.fromRGB(40, 40, 60)
whHeader.TextXAlignment = Enum.TextXAlignment.Left
whHeader.Text = "📡 Webhook Backpack View"
whHeader.Parent = webhookTabFrame

local whSub = Instance.new("TextLabel")
whSub.Name = "Sub"
whSub.Size = UDim2.new(1, -10, 0, 32)
whSub.Position = UDim2.new(0, 5, 0, 26)
whSub.BackgroundTransparency = 1
whSub.Font = Enum.Font.Gotham
whSub.TextSize = 12
whSub.TextColor3 = Color3.fromRGB(90, 90, 120)
whSub.TextXAlignment = Enum.TextXAlignment.Left
whSub.TextYAlignment = Enum.TextYAlignment.Top
whSub.TextWrapped = true
whSub.Text = "Pilih player (checkbox). Rod & Ikan dinomori per kategori. Auto split Part ke Discord + Total & Ikan Favorite di Part terakhir."
whSub.Parent = webhookTabFrame

local whSendBtn = Instance.new("TextButton")
whSendBtn.Name = "SendBtn"
whSendBtn.Size = UDim2.new(0, 120, 0, 24)
whSendBtn.AnchorPoint = Vector2.new(1, 0)
whSendBtn.Position = UDim2.new(1, -8, 0, 10)
whSendBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
whSendBtn.Font = Enum.Font.GothamBold
whSendBtn.TextSize = 13
whSendBtn.TextColor3 = Color3.fromRGB(255,255,255)
whSendBtn.Text = "Send to Discord"
whSendBtn.Parent = webhookTabFrame

local whSendCorner = Instance.new("UICorner")
whSendCorner.CornerRadius = UDim.new(0, 8)
whSendCorner.Parent = whSendBtn

local whSelectAll = Instance.new("TextButton")
whSelectAll.Name = "SelectAll"
whSelectAll.Size = UDim2.new(0, 80, 0, 24)
whSelectAll.AnchorPoint = Vector2.new(0, 0)
whSelectAll.Position = UDim2.new(0, 5, 0, 46)
whSelectAll.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
whSelectAll.Font = Enum.Font.GothamBold
whSelectAll.TextSize = 12
whSelectAll.TextColor3 = Color3.fromRGB(60, 60, 90)
whSelectAll.Text = "Select All"
whSelectAll.Parent = webhookTabFrame

local whSelCorner = Instance.new("UICorner")
whSelCorner.CornerRadius = UDim.new(0, 8)
whSelCorner.Parent = whSelectAll

local whSearchBox = Instance.new("TextBox")
whSearchBox.Name = "SearchBox"
whSearchBox.Size = UDim2.new(0, 150, 0, 22)
whSearchBox.Position = UDim2.new(0, 90, 0, 46)
whSearchBox.BackgroundColor3 = Color3.fromRGB(230, 230, 245)
whSearchBox.TextColor3 = Color3.fromRGB(80, 80, 110)
whSearchBox.Font = Enum.Font.Gotham
whSearchBox.TextSize = 13
whSearchBox.TextXAlignment = Enum.TextXAlignment.Left
whSearchBox.ClearTextOnFocus = false
whSearchBox.Text = ""
whSearchBox.PlaceholderText = "Search.."
whSearchBox.Parent = webhookTabFrame

local whSearchCorner = Instance.new("UICorner")
whSearchCorner.CornerRadius = UDim.new(0, 8)
whSearchCorner.Parent = whSearchBox

local whStatus = Instance.new("TextLabel")
whStatus.Name = "Status"
whStatus.Size = UDim2.new(1, -10, 0, 18)
whStatus.Position = UDim2.new(0, 5, 1, -24)
whStatus.BackgroundTransparency = 1
whStatus.Font = Enum.Font.Gotham
whStatus.TextSize = 12
whStatus.TextColor3 = Color3.fromRGB(90, 90, 120)
whStatus.TextXAlignment = Enum.TextXAlignment.Left
whStatus.Text = "Status: Ready"
whStatus.Parent = webhookTabFrame

local whList = Instance.new("ScrollingFrame")
whList.Name = "WebhookList"
whList.Position = UDim2.new(0, 5, 0, 74)
whList.Size = UDim2.new(1, -10, 1, -104)
whList.BackgroundTransparency = 1
whList.BorderSizePixel = 0
whList.ScrollBarThickness = 4
whList.CanvasSize = UDim2.new(0, 0, 0, 0)
whList.Parent = webhookTabFrame

local whLayout = Instance.new("UIListLayout")
whLayout.FillDirection = Enum.FillDirection.Vertical
whLayout.SortOrder = Enum.SortOrder.Name
whLayout.Padding = UDim.new(0, 4)
whLayout.Parent = whList

whLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    whList.CanvasSize = UDim2.new(0, 0, 0, whLayout.AbsoluteContentSize.Y + 10)
end)

-- ---------- ROW & SELECTION ----------
local whRows           = {}
local whSelected       = {}
local whSelectAllState = false

local function setWebhookStatus(msg)
    whStatus.Text = "Status: " .. msg
end

local function webhookMatchesSearch(pl)
    local q = string.lower(whSearchBox.Text or "")
    if q == "" then return true end
    local dn = string.lower(pl.DisplayName or pl.Name)
    local un = string.lower(pl.Name)
    return dn:find(q, 1, true) or un:find(q, 1, true)
end

local function applyWebhookSearchFilter()
    for pl, row in pairs(whRows) do
        local match = webhookMatchesSearch(pl)
        row.Visible = match
        if match then
            row.Size = UDim2.new(1, 0, 0, 32)
        else
            row.Size = UDim2.new(1, 0, 0, 0)
        end
    end
end

local function createWebhookRow(player)
    local row = Instance.new("Frame")
    row.Name = player.Name
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(230, 230, 244)
    row.BackgroundTransparency = 0.1
    row.BorderSizePixel = 0
    row.Parent = whList

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -60, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(60, 60, 90)
    nameLabel.Text = string.format("%s (@%s)", player.DisplayName or player.Name, player.Name)
    nameLabel.Parent = row

    local chkBtn = Instance.new("TextButton")
    chkBtn.Name = "Check"
    chkBtn.Size = UDim2.new(0, 28, 0, 24)
    chkBtn.AnchorPoint = Vector2.new(1, 0.5)
    chkBtn.Position = UDim2.new(1, -6, 0.5, 0)
    chkBtn.BackgroundColor3 = Color3.fromRGB(215, 215, 230)
    chkBtn.Font = Enum.Font.GothamBold
    chkBtn.TextSize = 16
    chkBtn.TextColor3 = Color3.fromRGB(60, 60, 90)
    chkBtn.Text = "☐"
    chkBtn.Parent = row

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = chkBtn

    local function applyState()
        local sel = not not whSelected[player]
        chkBtn.Text = sel and "☑" or "☐"
        chkBtn.BackgroundColor3 = sel and Color3.fromRGB(140, 190, 255) or Color3.fromRGB(215, 215, 230)
    end

    chkBtn.MouseButton1Click:Connect(function()
        whSelected[player] = not whSelected[player]
        applyState()
    end)

    whRows[player] = row
    whSelected[player] = false
    applyState()
end

local function removeWebhookRow(player)
    local row = whRows[player]
    if row then
        row:Destroy()
        whRows[player] = nil
    end
    whSelected[player] = nil
end

local function refreshWebhookList()
    for _, pl in ipairs(Players:GetPlayers()) do
        if not whRows[pl] then
            createWebhookRow(pl)
        end
    end
    for pl, _ in pairs(whRows) do
        local stillHere = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p == pl then stillHere = true break end
        end
        if not stillHere then
            removeWebhookRow(pl)
        end
    end
    applyWebhookSearchFilter()
end

whSearchBox:GetPropertyChangedSignal("Text"):Connect(applyWebhookSearchFilter)
Players.PlayerAdded:Connect(function(pl) createWebhookRow(pl); applyWebhookSearchFilter() end)
Players.PlayerRemoving:Connect(function(pl) removeWebhookRow(pl) end)
refreshWebhookList()

whSelectAll.MouseButton1Click:Connect(function()
    whSelectAllState = not whSelectAllState
    for pl, row in pairs(whRows) do
        whSelected[pl] = whSelectAllState
        local chk = row:FindFirstChild("Check")
        if chk and chk:IsA("TextButton") then
            chk.Text = whSelectAllState and "☑" or "☐"
            chk.BackgroundColor3 = whSelectAllState and Color3.fromRGB(140, 190, 255) or Color3.fromRGB(215,215,230)
        end
    end
    whSelectAll.Text = whSelectAllState and "Unselect All" or "Select All"
end)

-- ---------- KOLEKSI INVENTORY ----------
local function collectInventoryFor(player)
    local data = {
        rods   = {},    -- list nama rod
        fish   = {},    -- map baseName -> {count=, sumKg=, maxKg=}
        other  = {},    -- selain rod/fish
        totals = { rod = 0, fish = 0, fishKg = 0, other = 0 },
        favorites = {}  -- list {name, count, maxKg}
    }

    local function pushFish(rawName)
        local base = getFishBaseName(rawName)
        local wkg  = extractFishWeightKg(rawName) or 0
        local rec  = data.fish[base]
        if not rec then
            rec = { count = 0, sumKg = 0, maxKg = 0 }
            data.fish[base] = rec
        end
        rec.count += 1
        rec.sumKg += wkg
        if wkg > rec.maxKg then rec.maxKg = wkg end
        data.totals.fish += 1
        data.totals.fishKg += wkg
    end

    local function scanContainer(container)
        if not container then return end
        for _, inst in ipairs(container:GetChildren()) do
            if inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("Folder") then
                local nm = inst.Name or "Item"
                if isFishName(nm) then
                    pushFish(nm)
                elseif isRodName(nm) then
                    table.insert(data.rods, nm)
                    data.totals.rod += 1
                else
                    table.insert(data.other, nm)
                    data.totals.other += 1
                end
            elseif inst:IsA("Tool") == false and inst:IsA("Accessory") == false and inst.Name then
                -- fallback: beberapa game simpan item bukan Tool
                local nm = inst.Name
                if isFishName(nm) then
                    pushFish(nm)
                end
            end
        end
    end

    scanContainer(player:FindFirstChildOfClass("Backpack"))
    scanContainer(player.Character)

    -- Favorites summary
    for baseName, rec in pairs(data.fish) do
        if isFavoriteFishName(baseName) then
            table.insert(data.favorites, { name = baseName, count = rec.count, maxKg = rec.maxKg })
        end
    end
    table.sort(data.favorites, function(a,b) return a.name < b.name end)

    return data
end

-- ---------- FORMAT TEKS LIST ----------
local function makeNumberedLinesFromFishMap(fishMap)
    local entries = {}
    for name, rec in pairs(fishMap) do
        table.insert(entries, { name = name, count = rec.count, sumKg = rec.sumKg, maxKg = rec.maxKg })
    end
    table.sort(entries, function(a,b)
        if a.count == b.count then return a.name < b.name end
        return a.count > b.count
    end)

    local lines = {}
    for i, e in ipairs(entries) do
        local line = string.format("%d) %s — %dx (Σ %.2f kg; max %.2f kg)", i, e.name, e.count, e.sumKg, e.maxKg)
        table.insert(lines, line)
    end
    return lines
end

local function makeFavoritesLines(favs)
    if #favs == 0 then return {"(Tidak ada ikan favorite yang terdeteksi)"} end
    local out = {}
    for i, f in ipairs(favs) do
        table.insert(out, string.format("%d) %s — %dx (max %.2f kg) (Favorite)", i, f.name, f.count, f.maxKg))
    end
    return out
end

-- ---------- KIRIM DISCORD ----------
local function sendDiscordEmbeds(req, embeds, username, avatar)
    if not req then return false end
    local payload = {
        username   = username or "Axa Backview",
        avatar_url = avatar   or BOT_AVATAR_URL,
        embeds     = embeds
    }
    local ok, err = pcall(function()
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    if not ok then warn("[Webhook] gagal kirim:", err) end
    return ok
end

local function makeBaseFieldsFor(player)
    local avatar = string.format("https://www.roblox.com/avatar-thumbnail/image?userId=%d&width=420&height=420&format=png", player.UserId)
    local pengirim = table.concat({
        "Username: " .. player.Name,
        "DisplayName: " .. player.DisplayName,
        "UserId: " .. tostring(player.UserId),
        "ProfileUrl: https://www.roblox.com/id/users/"..tostring(player.UserId).."/profile"
    }, "\n")

    local server = table.concat({
        "PlaceName: " .. PLACE_NAME,
        "PlaceId: " .. tostring(PLACE_ID),
        "PlaceUrl: " .. PLACE_URL,
        "JobId: " .. tostring(game.JobId or "N/A"),
        "Players: " .. tostring(#Players:GetPlayers())
    }, "\n")

    local fields = {
        { name = "Pengirim", value  = "```yaml\n"..pengirim.."\n```", inline = false },
        { name = "Server",   value  = "```yaml\n"..server.."\n```", inline  = false },
        { name = "Timestamp",value  = "```yaml\nTanggal: "..getWITA().."\n```", inline = false },
    }
    return fields, avatar
end

local function buildEmbedsForPlayer(player, inv)
    local embeds = {}

    local fields, avatar = makeBaseFieldsFor(player)

    -- PART 1: Summary
    local desc1 = table.concat({
        "**Ringkasan Inventory**",
        string.format("- Rod: %d", inv.totals.rod),
        string.format("- Fish: %d (Σ %.2f kg)", inv.totals.fish, inv.totals.fishKg),
        string.format("- Other: %d", inv.totals.other),
        "",
        "**Rod List (nama):**",
        (#inv.rods > 0) and ("- " .. table.concat(inv.rods, ", ")) or "(tidak ada)",
    }, "\n")

    table.insert(embeds, {
        title       = "🎣 Backpack View — Summary (Part 1)",
        description = safeTruncate(desc1, MAX_DESC),
        color       = 0x33CCFF,
        fields      = fields,
        thumbnail   = { url = avatar },
        footer      = { text = getWITA() },
    })

    -- PART 2..N: Fish per nama (dinomori, autosplit)
    local fishLines = makeNumberedLinesFromFishMap(inv.fish)
    if #fishLines == 0 then
        table.insert(embeds, {
            title       = "🐟 Fish List (Kosong) (Part 2)",
            description = "(Tidak ada ikan yang terdeteksi di Backpack/Character).",
            color       = 0x00D1B2,
            footer      = { text = getWITA() },
            thumbnail   = { url = avatar },
        })
    else
        local chunk = {}
        local length = 0
        local partIdx = 2
        local function pushChunk()
            if #chunk == 0 then return end
            local desc = table.concat(chunk, "\n")
            table.insert(embeds, {
                title       = string.format("🐟 Fish List (Part %d)", partIdx),
                description = safeTruncate(desc, MAX_DESC),
                color       = 0x00D1B2,
                footer      = { text = getWITA() },
                thumbnail   = { url = avatar },
            })
            partIdx += 1
            chunk = {}
            length = 0
        end

        for _, line in ipairs(fishLines) do
            local addLen = #line + 1
            if length + addLen > MAX_DESC then
                pushChunk()
            end
            table.insert(chunk, line)
            length += addLen
        end
        pushChunk()
    end

    -- PART LAST: Favorites + Jumlah Rod (sesuai permintaan “Jumlah Rod di bagian Part paling akhir”)
    local favLines = makeFavoritesLines(inv.favorites)
    local tail = table.concat({
        "**Favorite Fish**",
        table.concat(favLines, "\n"),
        "",
        string.format("**Jumlah Rod:** %d", inv.totals.rod),
        string.format("**Total Fish:** %d (Σ %.2f kg)", inv.totals.fish, inv.totals.fishKg),
    }, "\n")

    table.insert(embeds, {
        title       = "⭐ Rekap Favorit & Total (Part Akhir)",
        description = safeTruncate(tail, MAX_DESC),
        color       = 0xFFAA33,
        footer      = { text = getWITA() },
        thumbnail   = { url = avatar },
    })

    -- Numerasi judul (Part X/Y)
    local totalParts = #embeds
    for i, em in ipairs(embeds) do
        em.title = string.format("%s — [%d/%d]", em.title, i, totalParts)
    end

    return embeds
end

-- ---------- HANDLE KLIK SEND ----------
local function getSelectedPlayers()
    local list = {}
    for pl, sel in pairs(whSelected) do
        if sel and pl and pl.Parent == Players then
            table.insert(list, pl)
        end
    end
    table.sort(list, function(a,b) return (a.DisplayName or a.Name) < (b.DisplayName or b.Name) end)
    return list
end

local sending = false

whSendBtn.MouseButton1Click:Connect(function()
    if sending then return end
    local req = detectHttpRequest()
    if not req then
        setWebhookStatus("Executor tidak mendukung http_request/syn.request.")
        return
    end

    local targets = getSelectedPlayers()
    if #targets == 0 then
        setWebhookStatus("Tidak ada player terpilih.")
        return
    end

    sending = true
    setWebhookStatus("Mengirim ("..tostring(#targets).." pemain)...")

    task.spawn(function()
        local okCount, failCount = 0, 0
        for idx, pl in ipairs(targets) do
            setWebhookStatus(string.format("Kumpulkan data: %s (%d/%d)...", pl.Name, idx, #targets))
            local inv = collectInventoryFor(pl)

            local embeds = buildEmbedsForPlayer(pl, inv)

            setWebhookStatus(string.format("Kirim ke Discord: %s (%d/%d)...", pl.Name, idx, #targets))
            local ok = sendDiscordEmbeds(req, embeds, "Axa Backview", BOT_AVATAR_URL)
            if ok then okCount += 1 else failCount += 1 end

            task.wait(0.25) -- jeda ringan antarpemain
        end

        setWebhookStatus(string.format("Selesai. OK: %d, Gagal: %d", okCount, failCount))
        sending = false
    end)
end)
