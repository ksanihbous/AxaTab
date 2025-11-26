--------------------------------------------------
-- AxaTab_Webhook - Backpack View → Discord
-- Dipanggil oleh CORE via loadstring, env punya:
--   TAB_ID, TAB_FRAME, CONTENT_HOLDER, Players, HttpService, dll
--------------------------------------------------

--------------------------------------------------
-- FRAME TAB (PAKAI DARI CORE)
--------------------------------------------------
local webhookTabFrame = TAB_FRAME

-- fallback kalau TAB_FRAME belum ada (misal test standalone)
if not webhookTabFrame or not webhookTabFrame.Parent then
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local holder = CONTENT_HOLDER
    if not holder then
        holder = Instance.new("Frame")
        holder.Name = "ContentHolder_Fallback"
        holder.Size = UDim2.new(0, 480, 0, 280)
        holder.Position = UDim2.new(0.5, -240, 0.5, -140)
        holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        holder.Parent = playerGui
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = holder
    end

    webhookTabFrame = Instance.new("Frame")
    webhookTabFrame.Name = "TabContent_webhook"
    webhookTabFrame.Size = UDim2.new(1, -16, 1, -16)
    webhookTabFrame.Position = UDim2.new(0, 8, 0, 8)
    webhookTabFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
    webhookTabFrame.BorderSizePixel = 0
    webhookTabFrame.Parent = holder

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = webhookTabFrame

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(210, 210, 225)
    s.Transparency = 0.3
    s.Parent = webhookTabFrame
end

--------------------------------------------------
-- SERVICE / ENV
--------------------------------------------------
local Players     = (typeof(Players) == "table" or typeof(Players) == "userdata") and Players or game:GetService("Players")
local HttpService = HttpService or game:GetService("HttpService")

local WEBHOOK_URL    = "https://discord.com/api/webhooks/1440379761389080597/yRL_Ek5RSttD-cMVPE6f0VtfpuRdMcVOjq4IkqtFOycPKjwFCiojViQGwXd_7AqXRM2P"
local BOT_AVATAR_URL = "https://mylogo.edgeone.app/Logo%20Ax%20(NO%20BG).png"
local MAX_DESC       = 3600

local FISH_KEYWORDS = {
    "ikan","fish","mirethos","kaelvorn","kraken",
    "shark","whale","ray","eel","salmon","tuna","cod"
}

local FAVORITE_FISH_NAMES = {
    "lumba pink",
    "lele",
    "mirethos",
    "kaelvorn",
}

local function safeLower(s)
    return (typeof(s) == "string") and s:lower() or ""
end

local function isFavoriteBaseName(baseName)
    local l = safeLower(baseName)
    for _, fav in ipairs(FAVORITE_FISH_NAMES) do
        if l:find(fav, 1, true) then
            return true
        end
    end
    return false
end

local function extractFishWeightKg(name)
    if not name then return nil end
    local lower = string.lower(name)
    local numStr = lower:match("(%d+%.?%d*)%s*kg") or lower:match("(%d+%.?%d*)")
    if not numStr then return nil end
    local w = tonumber(numStr)
    if not w then return nil end
    return w
end

local function getFishBaseName(rawName)
    if not rawName or rawName == "" then
        return "Unknown Fish"
    end

    local name = rawName
    name = name:gsub("%b[]", "")
    name = name:gsub("%b()", "")
    name = name:gsub("%s*%d+[%d%.]*%s*kg", "")
    name = name:gsub("%s*%d+[%d%.]*$", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        name = rawName
    end
    return name
end

--------------------------------------------------
-- UI HEADER
--------------------------------------------------
for _, child in ipairs(webhookTabFrame:GetChildren()) do
    child:Destroy()
end

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

--------------------------------------------------
-- ROW LIST & FILTER
--------------------------------------------------
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
            if p == pl then
                stillHere = true
                break
            end
        end
        if not stillHere then
            removeWebhookRow(pl)
        end
    end

    applyWebhookSearchFilter()
end

whSearchBox:GetPropertyChangedSignal("Text"):Connect(applyWebhookSearchFilter)

Players.PlayerAdded:Connect(function(pl)
    createWebhookRow(pl)
    applyWebhookSearchFilter()
end)

Players.PlayerRemoving:Connect(function(pl)
    removeWebhookRow(pl)
end)

refreshWebhookList()

whSelectAll.MouseButton1Click:Connect(function()
    whSelectAllState = not whSelectAllState

    for pl, row in pairs(whRows) do
        whSelected[pl] = whSelectAllState
        local chk = row:FindFirstChild("Check")
        if chk and chk:IsA("TextButton") then
            chk.Text = whSelectAllState and "☑" or "☐"
            chk.BackgroundColor3 = whSelectAllState and Color3.fromRGB(140, 190, 255)
                or Color3.fromRGB(215,215,230)
        end
    end

    whSelectAll.Text = whSelectAllState and "Unselect All" or "Select All"
end)

--------------------------------------------------
-- BACKPACK → KATEGORI
--------------------------------------------------
local function getBackpackCategoriesForWebhook(player)
    local rods, fish, others = {}, {}, {}

    local function classifyTool(tool)
        local name  = tool.Name
        local lower = string.lower(name)

        if lower:find("rod") or lower:find("pancing") then
            table.insert(rods, name)
            return
        end

        for _, kw in ipairs(FISH_KEYWORDS) do
            if lower:find(kw, 1, true) then
                table.insert(fish, name)
                return
            end
        end

        table.insert(others, name)
    end

    local function scan(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") then
                classifyTool(child)
            end
        end
    end

    scan(player:FindFirstChild("Backpack"))
    scan(player.Character)

    return rods, fish, others
end

local function buildWebhookBlockForPlayer(pl, rods, fish, others)
    if not rods or not fish or not others then
        rods, fish, others = getBackpackCategoriesForWebhook(pl)
    end

    local parts = {}

    table.insert(parts, string.format("**%s (@%s)**", pl.DisplayName or pl.Name, pl.Name))

    local function addCategory(label, list)
        if #list == 0 then return end
        table.insert(parts, label .. ":")
        for i, itemName in ipairs(list) do
            table.insert(parts, string.format("  %d. %s", i, itemName))
        end
    end

    addCategory("Rod",     rods)
    addCategory("Ikan",    fish)
    addCategory("Lainnya", others)

    return table.concat(parts, "\n")
end

--------------------------------------------------
-- HTTP → DISCORD
--------------------------------------------------
local function getRequestFunction()
    local g = getgenv and getgenv() or _G
    local req =
        (syn and syn.request)
        or (g and (g.request or g.http_request))
        or (g and g.http_request)
        or (http and (http.request or http_request))
        or http_request
        or request

    return req
end

local function postDiscord(payloadTable)
    local body = HttpService:JSONEncode(payloadTable)

    local req = getRequestFunction()
    if req then
        local ok, res = pcall(function()
            return req({
                Url     = WEBHOOK_URL,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = body
            })
        end)

        if ok then
            local status = res and (res.StatusCode or res.Status) or nil
            if status == nil or status == 200 or status == 204 then
                return true, nil
            end
            return false, "HTTP status " .. tostring(status)
        else
            return false, "Executor request error"
        end
    end

    local ok, errMsg = pcall(function()
        return HttpService:PostAsync(
            WEBHOOK_URL,
            body,
            Enum.HttpContentType.ApplicationJson,
            false
        )
    end)

    if not ok then
        warn("[Axa Backview] Gagal kirim webhook:", errMsg)
    end

    return ok, errMsg
end

--------------------------------------------------
-- UTIL SPLIT TEKS
--------------------------------------------------
local function splitTextByLength(text, maxLen)
    local chunks = {}
    local current = ""

    for line in (text .. "\n"):gmatch("(.-)\n") do
        if #current == 0 then
            current = line
        else
            local candidate = current .. "\n" .. line
            if #candidate > maxLen then
                table.insert(chunks, current)
                current = line
            else
                current = candidate
            end
        end
    end

    if #current > 0 then
        table.insert(chunks, current)
    end

    return chunks
end

--------------------------------------------------
-- KUMPUL & KIRIM
--------------------------------------------------
local function sendWebhookBackview()
    local blocks = {}

    local totalRods   = 0
    local totalFish   = 0
    local totalOthers = 0

    local range_1_100    = 0
    local range_101_400  = 0
    local range_401_599  = 0
    local range_600_799  = 0
    local range_801_1000 = 0

    local fishNameCounts = {}
    local fishMaxWeight  = {}
    local favoriteFishEntries = {}

    for pl, _ in pairs(whRows) do
        if whSelected[pl] and pl and pl.Parent == Players then
            local rods, fish, others = getBackpackCategoriesForWebhook(pl)

            totalRods   = totalRods   + #rods
            totalFish   = totalFish   + #fish
            totalOthers = totalOthers + #others

            for _, fishName in ipairs(fish) do
                local baseName = getFishBaseName(fishName)
                fishNameCounts[baseName] = (fishNameCounts[baseName] or 0) + 1

                local w = extractFishWeightKg(fishName)
                if w then
                    local curMax = fishMaxWeight[baseName]
                    if not curMax or w > curMax then
                        fishMaxWeight[baseName] = w
                    end

                    if w >= 1 and w <= 100 then
                        range_1_100 = range_1_100 + 1
                    elseif w >= 101 and w <= 400 then
                        range_101_400 = range_101_400 + 1
                    elseif w >= 401 and w <= 599 then
                        range_401_599 = range_401_599 + 1
                    elseif w >= 600 and w <= 799 then
                        range_600_799 = range_600_799 + 1
                    elseif w >= 800 and w <= 1000 then
                        range_801_1000 = range_801_1000 + 1
                    end
                end

                local lowerFishName = string.lower(fishName)
                if lowerFishName:find("(favorite)", 1, true) or isFavoriteBaseName(baseName) then
                    table.insert(favoriteFishEntries, {
                        rawName  = fishName,
                        baseName = baseName,
                        weight   = w or 0
                    })
                end
            end

            table.insert(blocks, buildWebhookBlockForPlayer(pl, rods, fish, others))
        end
    end

    if #blocks == 0 then
        setWebhookStatus("Tidak ada player yang dicentang.")
        return
    end

    local baseDesc = table.concat(blocks, "\n\n")

    local summaryLines = {}
    local totalTools = totalRods + totalFish + totalOthers

    table.insert(summaryLines, string.format(
        "**Total Rod:** %d  |  **Total Ikan:** %d  |  **Total Tools:** %d",
        totalRods, totalFish, totalTools
    ))

    table.insert(summaryLines, string.format(
        "**Total Berat Ikan (range):** 1-100 kg: %d, 101-400 kg: %d, 401-599 kg: %d, 600-799 kg: %d, 801-1000 kg: %d",
        range_1_100, range_101_400, range_401_599, range_600_799, range_801_1000
    ))

    if next(fishNameCounts) ~= nil then
        table.insert(summaryLines, "")
        table.insert(summaryLines, "**Jumlah per Nama Ikan:**")

        local fishArray = {}
        for name, count in pairs(fishNameCounts) do
            table.insert(fishArray, {
                name      = name,
                count     = count,
                maxWeight = fishMaxWeight[name] or 0
            })
        end

        table.sort(fishArray, function(a, b)
            if a.count == b.count then
                return a.name:lower() < b.name:lower()
            end
            return a.count > b.count
        end)

        local MAX_FISH_SUMMARY = 25
        local shown = 0
        local totalSpecies = #fishArray

        for _, entry in ipairs(fishArray) do
            if shown >= MAX_FISH_SUMMARY then
                local remaining = totalSpecies - shown
                if remaining > 0 then
                    table.insert(summaryLines, string.format("  ...(+%d jenis ikan lainnya)", remaining))
                end
                break
            end
            if entry.maxWeight > 0 then
                table.insert(summaryLines, string.format(
                    "  - %s: %d (max %.1f Kg)",
                    entry.name, entry.count, entry.maxWeight
                ))
            else
                table.insert(summaryLines, string.format(
                    "  - %s: %d",
                    entry.name, entry.count
                ))
            end
            shown += 1
        end
    end

    if #favoriteFishEntries > 0 then
        table.insert(summaryLines, "")
        table.insert(summaryLines, "**Ikan Favorite:**")
        table.sort(favoriteFishEntries, function(a, b)
            return a.baseName:lower() < b.baseName:lower()
        end)
        for i, entry in ipairs(favoriteFishEntries) do
            if entry.weight and entry.weight > 0 then
                table.insert(summaryLines, string.format(
                    "%d. %s (%.1f Kg) (Favorite)",
                    i, entry.baseName, entry.weight
                ))
            else
                table.insert(summaryLines, string.format(
                    "%d. %s (Favorite)",
                    i, entry.baseName
                ))
            end
        end
    end

    local totalsText = table.concat(summaryLines, "\n")

    local baseChunks = {}
    if baseDesc ~= "" then
        baseChunks = splitTextByLength(baseDesc, MAX_DESC)
    end

    local summaryChunks = {}
    if totalsText ~= "" then
        summaryChunks = splitTextByLength(totalsText, MAX_DESC)
    end

    local totalParts = #baseChunks + #summaryChunks
    if totalParts == 0 then
        setWebhookStatus("Tidak ada data backpack untuk dikirim.")
        return
    end

    local allOk    = true
    local firstErr = nil
    local partIndex = 0

    local function sendOnePart(desc, isSummary)
        partIndex += 1

        local title
        if isSummary then
            if totalParts > 1 then
                title = string.format("📊 Ringkasan & Ikan Favorite (Part %d/%d)", partIndex, totalParts)
            else
                title = "📊 Ringkasan & Ikan Favorite"
            end
        else
            if totalParts > 1 then
                title = string.format("🎒 Backpack View (Part %d/%d)", partIndex, totalParts)
            else
                title = "🎒 Backpack View"
            end
        end

        local payload = {
            username   = "Axa Backview",
            avatar_url = BOT_AVATAR_URL,
            embeds = {{
                title       = title,
                description = desc,
                color       = 0x5b8def
            }}
        }

        local ok, err = postDiscord(payload)
        if not ok then
            allOk    = false
            firstErr = firstErr or err
        end
    end

    for _, desc in ipairs(baseChunks) do
        sendOnePart(desc, false)
        task.wait(0.15)
    end

    for _, desc in ipairs(summaryChunks) do
        sendOnePart(desc, true)
        task.wait(0.15)
    end

    if allOk then
        if totalParts == 1 then
            setWebhookStatus("Terkirim ✅")
        else
            setWebhookStatus("Terkirim " .. totalParts .. " Part ✅")
        end
    else
        setWebhookStatus("Sebagian error: " .. tostring(firstErr or "unknown"))
    end
end

--------------------------------------------------
-- BUTTON SEND
--------------------------------------------------
whSendBtn.MouseButton1Click:Connect(function()
    if whSendBtn.Text == "Sending..." then return end

    whSendBtn.Text = "Sending..."
    setWebhookStatus("Mengirim ke Discord...")

    task.spawn(function()
        local ok, err = pcall(sendWebhookBackview)
        if not ok then
            warn("[Axa Backview] Error fatal:", err)
            setWebhookStatus("Error: " .. tostring(err))
        end

        if typeof(refreshBagAll) == "function" then
            pcall(refreshBagAll)
        end
        refreshWebhookList()

        task.wait(0.4)
        if whSendBtn then
            whSendBtn.Text = "Send to Discord"
        end
    end)
end)
