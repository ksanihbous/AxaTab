--==========================================================
--  AxaTab_Webhook.lua
--  TAB "Webhook" - Kirim Backpack View ke Discord (per player, checkbox)
--==========================================================

-- Ambil services dari env (kalau ada), fallback ke game:GetService kalau standalone
local Players     = Players     or game:GetService("Players")
local HttpService = HttpService or game:GetService("HttpService")

local LocalPlayer = LocalPlayer or Players.LocalPlayer
local AXA_TWEEN   = AXA_TWEEN   -- optional, mungkin nil

--------------------------------------------------
-- ROOT UI (TAB_FRAME dari CORE, atau fallback)
--------------------------------------------------
local webhookTabFrame = TAB_FRAME

if not webhookTabFrame then
    -- fallback standalone kalau dijalankan tanpa CORE
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "AxaTab_Webhook_Standalone"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = pg

    webhookTabFrame = Instance.new("Frame")
    webhookTabFrame.Name = "WebhookTab"
    webhookTabFrame.Size = UDim2.new(0, 480, 0, 320)
    webhookTabFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    webhookTabFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    webhookTabFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
    webhookTabFrame.BorderSizePixel = 0
    webhookTabFrame.Parent = sg

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = webhookTabFrame
end

-- Bersihin anak lama di TAB_FRAME (kalau ada)
for _, child in ipairs(webhookTabFrame:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

--------------------------------------------------
-- KONFIG DISCORD & FISH
--------------------------------------------------
local WEBHOOK_URL    = "https://discord.com/api/webhooks/1440379761389080597/yRL_Ek5RSttD-cMVPE6f0VtfpuRdMcVOjq4IkqtFOycPKjwFCiojViQGwXd_7AqXRM2P"
local BOT_USERNAME   = "Axa Backview"
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
    -- buang [RARITY], (info), dan angka KG di belakang
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

local function isFishName(str)
    if not str or str == "" then return false end
    local lower = string.lower(str)
    for _, kw in ipairs(FISH_KEYWORDS) do
        if lower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function classifyTool(name)
    if not name or name == "" then return "other" end
    local lower = string.lower(name)
    if lower:find("rod", 1, true) or lower:find("pancing", 1, true) then
        return "rod"
    end
    if isFishName(lower) then
        return "fish"
    end
    return "other"
end

--------------------------------------------------
-- UI
--------------------------------------------------
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

-- tombol Refresh kecil di samping
local whRefreshBtn = Instance.new("TextButton")
whRefreshBtn.Name = "RefreshBtn"
whRefreshBtn.Size = UDim2.new(0, 80, 0, 24)
whRefreshBtn.AnchorPoint = Vector2.new(1, 0)
whRefreshBtn.Position = UDim2.new(1, -138, 0, 10)
whRefreshBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
whRefreshBtn.Font = Enum.Font.GothamBold
whRefreshBtn.TextSize = 12
whRefreshBtn.TextColor3 = Color3.fromRGB(60, 60, 90)
whRefreshBtn.Text = "Refresh"
whRefreshBtn.Parent = webhookTabFrame

local whRefreshCorner = Instance.new("UICorner")
whRefreshCorner.CornerRadius = UDim.new(0, 8)
whRefreshCorner.Parent = whRefreshBtn

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
-- STATE LIST PLAYER
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
    -- tambah row baru kalau ada Player baru
    for _, pl in ipairs(Players:GetPlayers()) do
        if not whRows[pl] then
            createWebhookRow(pl)
        end
    end
    -- buang row kalau player sudah leave
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

whRefreshBtn.MouseButton1Click:Connect(function()
    setWebhookStatus("Refresh daftar player...")
    refreshWebhookList()
    setWebhookStatus("Ready")
end)

refreshWebhookList()

--------------------------------------------------
-- SCAN BACKPACK & RINGKAS IKAN
--------------------------------------------------
local function scanPlayerBackpack(plr)
    local result = {
        rods            = {},
        rodCount        = 0,
        fishList        = {},  -- { {name, count, totalWeight, maxWeight} }
        fishByName      = {},
        otherTools      = {},
        totalFishCount  = 0,
        totalFishWeight = 0,
        favoriteList    = {},  -- diisi belakangan
    }

    if not plr then
        return result
    end

    local backpack = plr:FindFirstChildOfClass("Backpack") or plr:FindFirstChild("Backpack")
    if not backpack then
        return result
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local class = classifyTool(item.Name)
            if class == "rod" then
                table.insert(result.rods, item.Name)
                result.rodCount = result.rodCount + 1
            elseif class == "fish" then
                local baseName = getFishBaseName(item.Name)
                local w = extractFishWeightKg(item.Name) or 0
                local rec = result.fishByName[baseName]
                if not rec then
                    rec = {
                        name        = baseName,
                        count       = 0,
                        totalWeight = 0,
                        maxWeight   = 0,
                    }
                    result.fishByName[baseName] = rec
                end
                rec.count = rec.count + 1
                rec.totalWeight = rec.totalWeight + w
                if w > rec.maxWeight then
                    rec.maxWeight = w
                end

                result.totalFishCount  = result.totalFishCount  + 1
                result.totalFishWeight = result.totalFishWeight + w
            else
                table.insert(result.otherTools, item.Name)
            end
        end
    end

    for _, rec in pairs(result.fishByName) do
        table.insert(result.fishList, rec)
    end
    table.sort(result.fishList, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    -- Favorite list berdasarkan keyword di FAVORITE_FISH_NAMES
    local favOut = {}
    for _, favKey in ipairs(FAVORITE_FISH_NAMES) do
        local keyLower = favKey:lower()
        local agg = nil
        for _, rec in ipairs(result.fishList) do
            if rec.name:lower():find(keyLower, 1, true) then
                if not agg then
                    agg = {
                        label     = rec.name,
                        count     = rec.count,
                        maxWeight = rec.maxWeight,
                    }
                else
                    agg.count = agg.count + rec.count
                    if rec.maxWeight > agg.maxWeight then
                        agg.maxWeight = rec.maxWeight
                    end
                end
            end
        end
        if agg then
            agg.favoriteKey = favKey
            table.insert(favOut, agg)
        end
    end

    result.favoriteList = favOut
    return result
end

local function buildLinesForPlayer(plr)
    local data = scanPlayerBackpack(plr)
    local lines = {}

    local disp     = plr.DisplayName or plr.Name
    local username = plr.Name
    local userId   = plr.UserId

    table.insert(lines, string.format("Backpack View: %s (@%s) [UserId: %d]", disp, username, userId))
    table.insert(lines, " ")

    table.insert(lines, "[ROD]")
    if #data.rods == 0 then
        table.insert(lines, "- (Tidak ada Rod terdeteksi)")
    else
        table.insert(lines, string.format("Jumlah Rod: %d", data.rodCount))
        for i, rodName in ipairs(data.rods) do
            table.insert(lines, string.format("%d. %s", i, rodName))
        end
    end

    table.insert(lines, " ")
    table.insert(lines, "[FISH PER NAMA]")
    if #data.fishList == 0 then
        table.insert(lines, "- (Tidak ada ikan terdeteksi)")
    else
        for i, rec in ipairs(data.fishList) do
            local line = string.format(
                "%d. %s: %d ekor (Total %.2f Kg, Max %.2f Kg)",
                i,
                rec.name,
                rec.count or 0,
                rec.totalWeight or 0,
                rec.maxWeight or 0
            )
            table.insert(lines, line)
        end
    end

    table.insert(lines, " ")
    table.insert(lines, "[SUMMARY]")
    table.insert(lines, string.format("Total Ikan: %d ekor", data.totalFishCount or 0))
    table.insert(lines, string.format("Total Berat: %.2f Kg", data.totalFishWeight or 0))
    table.insert(lines, string.format("Jumlah Rod: %d", data.rodCount or 0))

    if #data.favoriteList > 0 then
        table.insert(lines, " ")
        table.insert(lines, "[Favorite Fish]")
        for i, fav in ipairs(data.favoriteList) do
            local line = string.format(
                "%d. %s - %d ekor (Max %.2f Kg) (Favorite)",
                i,
                fav.label or fav.favoriteKey or "?",
                fav.count or 0,
                fav.maxWeight or 0
            )
            table.insert(lines, line)
        end
    end

    return lines
end

local function buildDiscordPartsForPlayer(plr)
    local lines = buildLinesForPlayer(plr)
    local parts = {}
    local current = ""
    local partIndex = 1

    local function pushCurrent()
        if current ~= "" then
            table.insert(parts, {
                index = partIndex,
                description = current,
            })
            partIndex = partIndex + 1
            current = ""
        end
    end

    for _, line in ipairs(lines) do
        local toAdd = (current == "" and line) or ("\n" .. line)
        if #current + #toAdd > MAX_DESC then
            pushCurrent()
            current = line
        else
            current = current .. ((current == "" and "") or "\n") .. line
        end
    end
    pushCurrent()

    return parts
end

--------------------------------------------------
-- HTTP REQUEST HELPER
--------------------------------------------------
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
        warn("[AxaTab_Webhook] Executor TIDAK support http_request/syn.request/http.request, webhook tidak bisa dikirim.")
    end

    return req
end

local httpRequest = detectHttpRequest()

--------------------------------------------------
-- KIRIM WEBHOOK
--------------------------------------------------
local function sendWebhookForPlayer(plr)
    local parts = buildDiscordPartsForPlayer(plr)
    if #parts == 0 then
        return false
    end

    if not httpRequest then
        httpRequest = detectHttpRequest()
        if not httpRequest then
            return false
        end
    end

    local disp     = plr.DisplayName or plr.Name
    local username = plr.Name
    local userId   = plr.UserId

    local anyOk = false

    for idx, part in ipairs(parts) do
        local totalParts = #parts
        local title
        if totalParts > 1 then
            title = string.format("🎣 Backpack View - %s (@%s) [Part %d/%d]", disp, username, idx, totalParts)
        else
            title = string.format("🎣 Backpack View - %s (@%s)", disp, username)
        end

        local embed = {
            title = title,
            description = part.description,
            color = 0x3498DB,
            footer = {
                text = string.format("UserId: %d • Players: %d", userId, #Players:GetPlayers()),
            },
        }

        local payload = {
            username   = BOT_USERNAME,
            avatar_url = BOT_AVATAR_URL,
            embeds     = {embed},
        }

        local jsonData = HttpService:JSONEncode(payload)

        local ok, err = pcall(function()
            httpRequest({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonData,
            })
        end)

        if not ok then
            warn("[AxaTab_Webhook] Gagal kirim webhook untuk", username, ":", err)
        else
            anyOk = true
        end

        task.wait(0.5) -- jaga-jaga rate limit
    end

    return anyOk
end

local function sendWebhookSelection()
    local selectedPlayers = {}
    for pl, sel in pairs(whSelected) do
        if sel and pl.Parent == Players then
            table.insert(selectedPlayers, pl)
        end
    end

    if #selectedPlayers == 0 then
        setWebhookStatus("Tidak ada player terpilih.")
        return
    end

    setWebhookStatus("Mengirim " .. tostring(#selectedPlayers) .. " player ke Discord...")

    task.spawn(function()
        local okAny = false
        for _, pl in ipairs(selectedPlayers) do
            local ok = sendWebhookForPlayer(pl)
            if ok then
                okAny = true
            end
        end

        if okAny then
            setWebhookStatus("Selesai kirim ke Discord (" .. tostring(#selectedPlayers) .. " player).")
        else
            setWebhookStatus("Gagal kirim ke Discord.")
        end
    end)
end

whSendBtn.MouseButton1Click:Connect(sendWebhookSelection)

-- selesai
