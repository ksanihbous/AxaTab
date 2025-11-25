--==========================================================
--  AxaTab_Autokey.lua
--  Tab: Autokey HG (Auto isi key + tekan Submit)
--  Env dari core:
--      TAB_FRAME = Frame konten tab Autokey (sudah dibuat di core AxaHub)
--==========================================================

------------------- SERVICES / ENV -------------------
local TAB_FRAME = TAB_FRAME  -- di-set sama core AxaHub sebelum require

local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local StarterGui       = game:GetService("StarterGui")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer      = Players.LocalPlayer

------------------- CONFIG GLOBAL (PERSIST SESI) -------------------
local cfg = _G.AxaHub_Autokey_CFG
if type(cfg) ~= "table" then
    cfg = {
        KeyString = "",   -- key HG kamu
        AutoRun   = false,
        DelaySec  = 12,   -- delay awal sebelum mulai scan UI (10–15 detik tadi)
    }
    _G.AxaHub_Autokey_CFG = cfg
end
cfg.DelaySec = tonumber(cfg.DelaySec) or 12

------------------- UI STATUS HELPER -------------------
local statusLabel

local function setStatus(text, color)
    if statusLabel then
        statusLabel.Text = text or ""
        if color then
            statusLabel.TextColor3 = color
        end
    end
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "Info",
            Text     = text or "",
            Duration = duration or 4,
        })
    end)
end

------------------- HELPER: ROW TOGGLE ☑ / ☐ -------------------
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
        if callback then
            task.spawn(callback, state)
        end
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
        Frame     = row,
        Set       = setState,
        OnChanged = function(cb) callback = cb end,
        Get       = function() return state end,
    }
end

------------------- HELPER: CARI UI KEY HG -------------------
local function getRootGuis()
    local roots = {}

    -- beberapa executor punya gethui()
    local ok, hui = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
    end)
    if ok and typeof(hui) == "Instance" then
        table.insert(roots, hui)
    end

    table.insert(roots, CoreGui)
    local okPg, pg = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui")
    end)
    if okPg and typeof(pg) == "Instance" then
        table.insert(roots, pg)
    end

    return roots
end

local function findKeyUI()
    local roots = getRootGuis()

    local bestTextBox
    local bestScore = -1
    local rootNameForKey = "?"

    -- cari TextBox yang keliatan "Key"
    for _, root in ipairs(roots) do
        if root and root:IsA("Instance") then
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA("TextBox") and inst.Visible and inst.TextEditable ~= false then
                    local meta = (inst.Name or "") .. " " .. (inst.PlaceholderText or "")
                    local lower = string.lower(meta)

                    local score = 0
                    if lower:find("key") then score = score + 3 end
                    if lower:find("license") or lower:find("whitelist") then score = score + 1 end
                    if lower:find("hg") then score = score + 1 end

                    if score > bestScore then
                        bestScore = score
                        bestTextBox = inst
                        rootNameForKey = root.Name
                    end
                end
            end
        end
    end

    if not bestTextBox then
        return nil
    end

    -- cari Submit/Verify di satu GUI yang sama
    local submitBtn
    local submitScore = -1

    local parentGui = bestTextBox:FindFirstAncestorOfClass("ScreenGui") or bestTextBox:FindFirstAncestorOfClass("Frame") or bestTextBox.Parent
    if parentGui then
        for _, inst in ipairs(parentGui:GetDescendants()) do
            if inst:IsA("TextButton") and inst.Visible then
                local lower = string.lower(inst.Text or "")
                local score = 0
                if lower:find("submit") then score = score + 3 end
                if lower:find("verify") or lower:find("check") then score = score + 2 end
                if lower:find("continue") or lower:find("confirm") or lower == "ok" then score = score + 1 end
                if score > submitScore then
                    submitScore = score
                    submitBtn = inst
                end
            end
        end
    end

    return bestTextBox, submitBtn, rootNameForKey
end

------------------- AUTOKEY CORE -------------------
local autoLoopId = 0
local restartAutoLoop -- forward declaration

local function doAutokey(opts)
    opts = opts or {}
    local silent = not not opts.silent

    local key = tostring(cfg.KeyString or "")
    if key == "" then
        if not silent then
            setStatus("❌ Key masih kosong. Isi dulu key HG kamu.", Color3.fromRGB(200, 70, 80))
        end
        return false, "EMPTY_KEY"
    end

    local textBox, submitBtn, rootName = findKeyUI()
    if not textBox then
        if not silent then
            setStatus("❌ UI key tidak ditemukan. Pastikan panel key HG sudah muncul.", Color3.fromRGB(200, 70, 80))
        end
        return false, "NO_UI"
    end

    local ok, err = pcall(function()
        -- isi key
        textBox.Text = key

        -- fokus sebentar biar kelihatan "diketik"
        pcall(function()
            textBox:CaptureFocus()
        end)
        task.wait(0.05)
        pcall(function()
            textBox:ReleaseFocus()
        end)

        task.wait(0.05)

        -- tekan tombol submit / verify
        if submitBtn then
            local clicked = false
            if typeof(firesignal) == "function" then
                clicked = pcall(function()
                    firesignal(submitBtn.MouseButton1Click)
                end)
            end
            if not clicked then
                pcall(function()
                    submitBtn:Activate()
                end)
            end
        end
    end)

    if not ok then
        if not silent then
            setStatus("⚠ Autokey error: " .. tostring(err), Color3.fromRGB(220, 140, 70))
        end
        return false, err
    end

    if not silent then
        setStatus("✅ Autokey dijalankan (GUI: " .. tostring(rootName) .. ")", Color3.fromRGB(70, 150, 90))
        notify("Autokey HG", "Key sudah diisi & tombol submit ditekan.")
    end

    return true
end

restartAutoLoop = function()
    autoLoopId += 1
    local myId = autoLoopId

    if not cfg.AutoRun then
        return
    end

    task.spawn(function()
        local delaySec = tonumber(cfg.DelaySec) or 12
        if delaySec > 0 then
            for i = delaySec, 1, -1 do
                if autoLoopId ~= myId or not cfg.AutoRun then
                    return
                end
                setStatus(("⏳ Autokey jalan dalam %d detik..."):format(i), Color3.fromRGB(120, 120, 160))
                task.wait(1)
            end
        end

        local maxTry = 20
        local tries = 0
        while autoLoopId == myId and cfg.AutoRun and tries < maxTry do
            local ok = doAutokey({ silent = true })
            if ok then
                setStatus("✅ Autokey: key diisi & submit berhasil.", Color3.fromRGB(70, 150, 90))
                notify("Autokey HG", "Berhasil menemukan UI key & mengirim key.")
                return
            end

            tries += 1
            setStatus(("🔍 Autokey mencari UI key... (percobaan %d/%d)"):format(tries, maxTry), Color3.fromRGB(160, 130, 60))
            task.wait(1)
        end

        if autoLoopId == myId and cfg.AutoRun and tries >= maxTry then
            setStatus("⚠ Autokey tidak menemukan UI key. Buka dulu panel key HG-mu.", Color3.fromRGB(200, 80, 80))
        end
    end)
end

local function cancelAutoLoop()
    autoLoopId += 1 -- cukup naikkan id supaya loop lama berhenti sendiri
end

------------------- BANGUN UI TAB -------------------
do
    -- Header
    local header = Instance.new("TextLabel")
    header.Name = "AutokeyHeader"
    header.Size = UDim2.new(1, -10, 0, 22)
    header.Position = UDim2.new(0, 5, 0, 6)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 15
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = Color3.fromRGB(40, 40, 70)
    header.Text = "🔑 Autokey HG"
    header.Parent = TAB_FRAME

    local sub = Instance.new("TextLabel")
    sub.Name = "AutokeySub"
    sub.Size = UDim2.new(1, -10, 0, 40)
    sub.Position = UDim2.new(0, 5, 0, 28)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextWrapped = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top
    sub.TextColor3 = Color3.fromRGB(90, 90, 120)
    sub.Text = "Simpan key HG di sini. Autokey akan mencari UI key (CoreGui/PlayerGui/gethui), mengisi key, lalu menekan tombol Submit/Verify."
    sub.Parent = TAB_FRAME

    -- Label Key
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.new(1, -10, 0, 20)
    keyLabel.Position = UDim2.new(0, 5, 0, 70)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 13
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
    keyLabel.Text = "Key HG:"
    keyLabel.Parent = TAB_FRAME

    -- TextBox Key
    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyBox"
    keyBox.Size = UDim2.new(1, -10, 0, 28)
    keyBox.Position = UDim2.new(0, 5, 0, 92)
    keyBox.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    keyBox.BorderSizePixel = 0
    keyBox.ClearTextOnFocus = false
    keyBox.Font = Enum.Font.Code
    keyBox.TextSize = 14
    keyBox.TextXAlignment = Enum.TextXAlignment.Left
    keyBox.TextColor3 = Color3.fromRGB(40, 40, 70)
    keyBox.PlaceholderText = "Masukkan key HG kamu di sini..."
    keyBox.Text = cfg.KeyString or ""
    keyBox.Parent = TAB_FRAME
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)
    local kbPad = Instance.new("UIPadding")
    kbPad.PaddingLeft = UDim.new(0, 8)
    kbPad.PaddingRight = UDim.new(0, 8)
    kbPad.Parent = keyBox

    -- Tombol SIMPAN
    local saveBtn = Instance.new("TextButton")
    saveBtn.Name = "SaveKeyBtn"
    saveBtn.Size = UDim2.new(0, 110, 0, 26)
    saveBtn.Position = UDim2.new(0, 5, 0, 126)
    saveBtn.BackgroundColor3 = Color3.fromRGB(140, 190, 255)
    saveBtn.TextColor3 = Color3.fromRGB(20, 30, 50)
    saveBtn.Font = Enum.Font.GothamSemibold
    saveBtn.TextSize = 13
    saveBtn.Text = "Simpan Key"
    saveBtn.Parent = TAB_FRAME
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 7)

    -- Toggle AUTORUN
    local autoRow = createToggleRow(
        TAB_FRAME,
        "1_AutokeyAutoRun",
        "Autokey otomatis setelah delay (±".. tostring(cfg.DelaySec) .." detik)",
        not not cfg.AutoRun
    )
    autoRow.Frame.Position = UDim2.new(0, 5, 0, 160)
    autoRow.Frame.Size     = UDim2.new(1, -10, 0, 26)

    -- Row Tombol aksi (Test Now + Reset Status)
    local actionRow = Instance.new("Frame")
    actionRow.Name = "ActionRow"
    actionRow.Size = UDim2.new(1, -10, 0, 28)
    actionRow.Position = UDim2.new(0, 5, 0, 194)
    actionRow.BackgroundTransparency = 1
    actionRow.Parent = TAB_FRAME

    local testBtn = Instance.new("TextButton")
    testBtn.Name = "TestBtn"
    testBtn.Size = UDim2.new(0.6, -4, 1, 0)
    testBtn.Position = UDim2.new(0, 0, 0, 0)
    testBtn.BackgroundColor3 = Color3.fromRGB(90, 190, 120)
    testBtn.TextColor3 = Color3.fromRGB(20, 30, 40)
    testBtn.Font = Enum.Font.GothamSemibold
    testBtn.TextSize = 13
    testBtn.Text = "Test Autokey Sekarang"
    testBtn.Parent = actionRow
    Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 7)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Name = "ResetStatusBtn"
    resetBtn.Size = UDim2.new(0.4, -4, 1, 0)
    resetBtn.Position = UDim2.new(0.6, 4, 0, 0)
    resetBtn.BackgroundColor3 = Color3.fromRGB(220, 222, 235)
    resetBtn.TextColor3 = Color3.fromRGB(50, 60, 90)
    resetBtn.Font = Enum.Font.GothamSemibold
    resetBtn.TextSize = 13
    resetBtn.Text = "Reset Status"
    resetBtn.Parent = actionRow
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 7)

    -- Status label
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -10, 0, 34)
    statusLabel.Position = UDim2.new(0, 5, 0, 228)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.TextColor3 = Color3.fromRGB(90, 90, 120)
    statusLabel.Text = "Status: standby. Isi key HG lalu tekan \"Simpan Key\"."
    statusLabel.Parent = TAB_FRAME

    ------------------- EVENT HOOKS -------------------
    saveBtn.MouseButton1Click:Connect(function()
        cfg.KeyString = keyBox.Text or ""
        if cfg.KeyString == "" then
            setStatus("⚠ Key kosong. Simpan key HG kamu dulu.", Color3.fromRGB(200, 120, 60))
        else
            setStatus("✅ Key disimpan di sesi AxaHub (tidak permanen).", Color3.fromRGB(70, 150, 90))
            notify("Autokey HG", "Key disimpan. Aktifkan Autokey otomatis bila perlu.", 3)
            if cfg.AutoRun then
                restartAutoLoop()
            end
        end
    end)

    autoRow.OnChanged(function(state)
        cfg.AutoRun = state and true or false
        if cfg.AutoRun then
            setStatus("⏳ Autokey otomatis aktif. Menunggu delay & UI key HG.", Color3.fromRGB(120, 120, 160))
            restartAutoLoop()
        else
            cancelAutoLoop()
            setStatus("⏹ Autokey otomatis dimatikan. Kamu masih bisa pakai tombol Test Autokey.", Color3.fromRGB(120, 120, 160))
        end
    end)

    testBtn.MouseButton1Click:Connect(function()
        local ok = doAutokey({ silent = false })
        if not ok then
            notify("Autokey HG", "Gagal menemukan UI key / error. Pastikan panel key sudah muncul.", 4)
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        setStatus("Status: standby. Isi key HG lalu tekan \"Simpan Key\".", Color3.fromRGB(90, 90, 120))
    end)

    -- INIT STATUS + AUTOLOOP (kalau sudah ON & key ada)
    if (cfg.KeyString or "") ~= "" then
        if cfg.AutoRun then
            setStatus("⏳ Autokey otomatis aktif. Menunggu delay & UI key HG.", Color3.fromRGB(120, 120, 160))
            restartAutoLoop()
        else
            setStatus("Status: key sudah disimpan. Aktifkan Autokey otomatis atau tekan Test Autokey.", Color3.fromRGB(90, 90, 120))
        end
    else
        setStatus("Status: standby. Isi key HG lalu tekan \"Simpan Key\".", Color3.fromRGB(90, 90, 120))
    end
end
