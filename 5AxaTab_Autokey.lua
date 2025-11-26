--==========================================================
--  5AxaTab_Autokey.lua
--  Dipanggil via AxaHub CORE (loadstring + env TAB_FRAME)
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

local Players             = Players             or game:GetService("Players")
local LocalPlayer         = LocalPlayer         or Players.LocalPlayer
local UserInputService    = UserInputService    or game:GetService("UserInputService")
local VirtualInputManager = VirtualInputManager or game:GetService("VirtualInputManager")
local CoreGui             = CoreGui             or game:GetService("CoreGui")
local RunService          = RunService          or game:GetService("RunService")

local playerGui = nil
pcall(function()
    playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end)

local autokeyTabFrame

if okEnv then
    autokeyTabFrame = TAB_FRAME
else
    -- Fallback: bikin ScreenGui sendiri (kalau dijalankan lepas dari CORE)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AxaTab_Autokey_Standalone"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = playerGui or CoreGui

    autokeyTabFrame = Instance.new("Frame")
    autokeyTabFrame.Name = "AutokeyRoot"
    autokeyTabFrame.Size = UDim2.new(0, 420, 0, 240)
    autokeyTabFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    autokeyTabFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    autokeyTabFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
    autokeyTabFrame.Parent = screenGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = autokeyTabFrame
end

--------------------------------------------------
--  UI: HEADER + DESKRIPSI + LIST MENU
--------------------------------------------------
autokeyTabFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 248)
autokeyTabFrame.BackgroundTransparency = 0

-- Bersihkan isi lama kalau ada
for _, child in ipairs(autokeyTabFrame:GetChildren()) do
    if not child:IsA("UICorner") and not child:IsA("UIStroke") then
        child:Destroy()
    end
end

local akHeader = Instance.new("TextLabel")
akHeader.Name = "Header"
akHeader.Size = UDim2.new(1, -10, 0, 22)
akHeader.Position = UDim2.new(0, 5, 0, 6)
akHeader.BackgroundTransparency = 1
akHeader.Font = Enum.Font.GothamBold
akHeader.TextSize = 15
akHeader.TextColor3 = Color3.fromRGB(40, 40, 60)
akHeader.TextXAlignment = Enum.TextXAlignment.Left
akHeader.Text = "🔑 Autokey HG"
akHeader.Parent = autokeyTabFrame

local akDesc = Instance.new("TextLabel")
akDesc.Name = "Desc"
akDesc.Size = UDim2.new(1, -10, 0, 32)
akDesc.Position = UDim2.new(0, 5, 0, 26)
akDesc.BackgroundTransparency = 1
akDesc.Font = Enum.Font.Gotham
akDesc.TextSize = 12
akDesc.TextColor3 = Color3.fromRGB(90, 90, 120)
akDesc.TextXAlignment = Enum.TextXAlignment.Left
akDesc.TextYAlignment = Enum.TextYAlignment.Top
akDesc.TextWrapped = true
akDesc.Text = "Pilih script, lalu Autokey akan isi key & klik tombol Submit pada ModernKeyUI (Spade Key System) otomatis."
akDesc.Parent = autokeyTabFrame

local akKeyLabel = Instance.new("TextLabel")
akKeyLabel.Name = "KeyLabel"
akKeyLabel.Size = UDim2.new(1, -10, 0, 20)
akKeyLabel.Position = UDim2.new(0, 5, 0, 60)
akKeyLabel.BackgroundTransparency = 1
akKeyLabel.Font = Enum.Font.Gotham
akKeyLabel.TextSize = 12
akKeyLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
akKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
akKeyLabel.Text = "Key saat ini: (diset di script)"
akKeyLabel.Parent = autokeyTabFrame

-- LIST: ScrollingFrame
local akList = Instance.new("ScrollingFrame")
akList.Name = "MenuList"
akList.Position = UDim2.new(0, 5, 0, 84)
akList.Size = UDim2.new(1, -10, 1, -92)
akList.BackgroundTransparency = 1
akList.BorderSizePixel = 0
akList.ScrollBarThickness = 4
akList.ScrollingDirection = Enum.ScrollingDirection.Y
akList.CanvasSize = UDim2.new(0, 0, 0, 0)
akList.Parent = autokeyTabFrame

local akLayout = Instance.new("UIListLayout")
akLayout.FillDirection = Enum.FillDirection.Vertical
akLayout.SortOrder = Enum.SortOrder.LayoutOrder
akLayout.Padding = UDim.new(0, 4)
akLayout.Parent = akList

akLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local size = akLayout.AbsoluteContentSize
    akList.CanvasSize = UDim2.new(0, 0, 0, size.Y + 4)
end)

--------------------------------------------------
--  CONFIG: KEY + ENTRIES SCRIPT
--------------------------------------------------
local KEY_STRING = "b5a60c22-68f1-4ee9-8e73-16f66179bf36"

local ENTRIES = {
    {
        label  = "INDO HANGOUT",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/indohangout.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "INDO VOICE",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/indovoice.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "INDO CAMP",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/indocamp.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "CABIN INDO",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/cabinindo.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "KOTA ROLEPLAY",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/KotaRoleplay.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "INDO BEACH",
        url    = "https://raw.githubusercontent.com/Nearastro/Nearastro/refs/heads/main/indo_Beach.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "UNIVERSALL TROL",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/universaltroll.lua",
        method = "HttpGetAsync",
    },
    {
        label  = "UNIVERSALL INVISIBLE",
        url    = "https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Invisible%20Gui",
        method = "HttpGetAsync",
    },
    {
        label  = "COPY AVA",
        url    = "https://raw.githubusercontent.com/Nearastro/Nearastro/refs/heads/main/00CopyAvaFE.lua",
        method = "HttpGetAsync",
    },
}

if KEY_STRING and KEY_STRING ~= "" then
    akKeyLabel.Text = "Key saat ini: " .. KEY_STRING
else
    akKeyLabel.Text = "Key saat ini: (KOSONG – isi di KEY_STRING)"
end

--------------------------------------------------
--  UTIL ROOTS
--------------------------------------------------
local function getRoots()
    local roots = {}
    if playerGui then table.insert(roots, playerGui) end
    if CoreGui then table.insert(roots, CoreGui) end

    pcall(function()
        if gethui then
            local r = gethui()
            if r then table.insert(roots, r) end
        end
    end)

    pcall(function()
        if get_hidden_gui then
            local r = get_hidden_gui()
            if r then table.insert(roots, r) end
        end
    end)

    return roots
end

--------------------------------------------------
--  UTIL: visibility + finder by text
--------------------------------------------------
local function isGuiVisible(gui: Instance)
    local obj = gui
    while obj and obj:IsA("GuiObject") do
        if obj.Visible == false then
            return false
        end
        obj = obj.Parent
    end
    return true
end

local function textOf(x: Instance)
    local t = x and (x.Text or x.PlaceholderText) or ""
    if typeof(t) ~= "string" then
        return ""
    end
    return t
end

local function normTargets(targets)
    local want = {}
    if typeof(targets) == "string" then
        want = { string.lower(targets) }
    else
        for _, s in ipairs(targets) do
            table.insert(want, string.lower(s))
        end
    end
    return want
end

local function findFirstByText(root: Instance, targets)
    local want = normTargets(targets)
    for _, d in ipairs(root:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("TextLabel") or d:IsA("ImageButton")) and isGuiVisible(d) then
            local txt = string.lower(textOf(d))
            for _, w in ipairs(want) do
                if txt:find(w, 1, true) then
                    return d
                end
            end
        end
    end
end

local function findAnyByTextInRoots(targets)
    for _, r in ipairs(getRoots()) do
        local hit = findFirstByText(r, targets)
        if hit then return hit end
    end
end

local function waitForTextGlobal(targets, timeout)
    local t0 = os.clock()
    timeout = timeout or 8
    while os.clock() - t0 < timeout do
        local inst = findAnyByTextInRoots(targets)
        if inst and inst:IsA("GuiObject") and isGuiVisible(inst) then
            return inst
        end
        task.wait(0.15)
    end
    return nil
end

local function waitForTextInRoot(root: Instance, targets, timeout)
    if not root then return nil end
    local t0 = os.clock()
    timeout = timeout or 8
    while os.clock() - t0 < timeout do
        local inst = findFirstByText(root, targets)
        if inst and inst:IsA("GuiObject") and isGuiVisible(inst) then
            return inst
        end
        task.wait(0.15)
    end
    return nil
end

--------------------------------------------------
--  FIRE SIGNAL KUAT + KLIK GENERIK + KEYPRESS
--------------------------------------------------
local function fireSignalStrong(signal)
    if not signal then return false end
    local anyFired = false

    if typeof(firesignal) == "function" then
        if pcall(function() firesignal(signal) end) then
            anyFired = true
        end
    end

    local getCons
    if typeof(getconnections) == "function" then
        getCons = getconnections
    elseif debug and typeof(debug.getconnections) == "function" then
        getCons = debug.getconnections
    end

    if getCons then
        pcall(function()
            for _, conn in ipairs(getCons(signal)) do
                if conn then
                    pcall(function()
                        if typeof(conn) == "table" and conn.Function then
                            conn.Function()
                        elseif typeof(conn) == "userdata" then
                            if conn.Function then
                                conn.Function()
                            elseif conn.Fire then
                                conn:Fire()
                            end
                        end
                    end)
                    anyFired = true
                end
            end
        end)
    end

    return anyFired
end

local function clickGuiObject(gui: GuiObject)
    if not gui then return false end

    local ok =
        fireSignalStrong(gui.MouseButton1Click)
        or fireSignalStrong(gui.MouseButton1Down)
        or fireSignalStrong(gui.Activated)

    if ok then
        return true
    end

    if not VirtualInputManager or not UserInputService then
        return false
    end

    local pos  = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    local x, y = pos.X + size.X/2, pos.Y + size.Y/2

    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    return true
end

local function pressKey(code: Enum.KeyCode, hold)
    if not VirtualInputManager then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        task.wait(hold or 0.06)
        VirtualInputManager:SendKeyEvent(false, code, false, game)
    end)
end

--------------------------------------------------
--  EQUIP ROD: Tekan "2" + coba equip Tool rod secara real
--------------------------------------------------
local function getEquippedTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function tryEquipRodDirect()
    local char     = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local hum      = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and backpack and hum) then return false end

    local candidate
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local n = string.lower(item.Name)
            if n:find("rod") or n:find("fish") or n:find("pancing") then
                candidate = item
                break
            end
            candidate = candidate or item
        end
    end

    if candidate then
        pcall(function()
            hum:EquipTool(candidate)
        end)
        return true
    end

    return false
end

local function equipRodSlot2()
    -- 1) Tekan angka 2 (virtual)
    pressKey(Enum.KeyCode.Two, 0.05)

    -- 2) Tunggu sedikit, cek apakah sudah ada Tool
    local t0 = os.clock()
    while os.clock() - t0 < 0.9 do
        if getEquippedTool() then
            return true
        end
        task.wait(0.08)
    end

    -- 3) Fallback: equip rod dari Backpack secara langsung
    if tryEquipRodDirect() then
        return true
    end

    return false
end

--------------------------------------------------
--  UTIL: klik di sekitar label (untuk toggle)
--------------------------------------------------
local function findClickableNear(labelObj: GuiObject)
    if not labelObj then return nil end
    local parent = labelObj.Parent
    if not parent then return nil end

    -- Cari tombol di parent dulu
    for _, d in ipairs(parent:GetChildren()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiVisible(d) then
            return d
        end
    end

    -- Kalau nggak ada, baru scan subtree
    for _, d in ipairs(parent:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiVisible(d) then
            return d
        end
    end

    if parent:IsA("TextButton") then
        return parent
    end

    return labelObj
end

--------------------------------------------------
--  ModernKeyUI (key + submit)
--------------------------------------------------
local function findModernKeyUI()
    local keyBox, submitButton

    for _, root in ipairs(getRoots()) do
        if root and root.Parent then
            for _, gui in ipairs(root:GetDescendants()) do
                if gui:IsA("ScreenGui") and gui.Name == "ModernKeyUI" then
                    for _, inst in ipairs(gui:GetDescendants()) do
                        if inst:IsA("TextBox") then
                            local ph = string.lower(inst.PlaceholderText or "")
                            if ph == "enter your key" then
                                keyBox = inst
                            end
                        elseif inst:IsA("TextButton") then
                            local txt = string.lower(inst.Text or "")
                            if txt == "submit" then
                                submitButton = inst
                            end
                        end
                    end
                    if keyBox and submitButton then
                        return keyBox, submitButton
                    end
                end
            end
        end
    end

    return nil, nil
end

local function autoKeyAndSubmit()
    if not KEY_STRING or KEY_STRING == "" then
        warn("[Axa Autokey] KEY_STRING kosong, skip auto key.")
        return false
    end

    local keyBox, submitButton

    -- Tunggu ModernKeyUI muncul (maks ~20 detik)
    local t0 = os.clock()
    while os.clock() - t0 < 20 do
        keyBox, submitButton = findModernKeyUI()
        if keyBox and submitButton then
            break
        end
        task.wait(0.25)
    end

    if not (keyBox and submitButton) then
        warn("[Axa Autokey] Tidak menemukan ModernKeyUI / tombol Submit.")
        return false
    end

    pcall(function()
        keyBox:CaptureFocus()
        keyBox.Text = KEY_STRING
        keyBox:ReleaseFocus()
    end)

    task.wait(0.25)
    clickGuiObject(submitButton)
    return true
end

--------------------------------------------------
--  SPADES WINDOW: root + minimize
--------------------------------------------------
local function findSpadesRootWindow(timeout)
    local t0 = os.clock()
    timeout = timeout or 20

    while os.clock() - t0 < timeout do
        for _, root in ipairs(getRoots()) do
            for _, d in ipairs(root:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton"))
                    and isGuiVisible(d) then
                    local txt = string.lower(textOf(d))
                    if txt:find("of spades", 1, true) then
                        -- Naik sampai frame tertinggi di bawah ScreenGui (main window)
                        local win = d
                        while win and win.Parent and not win.Parent:IsA("ScreenGui") do
                            win = win.Parent
                        end
                        if win and win:IsA("GuiObject") then
                            return win
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end

    return nil
end

local function findSpadesMinimizeButton(timeout, spadesRoot)
    local t0 = os.clock()
    timeout = timeout or 8

    while os.clock() - t0 < timeout do
        local root = spadesRoot or findSpadesRootWindow(3)
        if root then
            local header = findFirstByText(root, { "of spades" })
            if header and header:IsA("GuiObject") then
                local bar = header.Parent
                if bar and bar:IsA("GuiObject") then
                    local candidates = {}

                    local function collect(from)
                        for _, d in ipairs(from:GetDescendants()) do
                            if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiVisible(d) then
                                table.insert(candidates, d)
                            end
                        end
                    end

                    collect(bar)

                    if bar.Parent and bar.Parent:IsA("GuiObject") then
                        collect(bar.Parent)
                    end

                    if #candidates > 0 then
                        -- unique
                        local seen, uniq = {}, {}
                        for _, d in ipairs(candidates) do
                            if not seen[d] then
                                seen[d] = true
                                table.insert(uniq, d)
                            end
                        end
                        candidates = uniq

                        table.sort(candidates, function(a, b)
                            return a.AbsolutePosition.X < b.AbsolutePosition.X
                        end)

                        local function looksLikeMinus(btn)
                            local t = string.lower(textOf(btn))
                            return t:find("-", 1, true) or t:find("min", 1, true)
                        end

                        -- 1) tombol yang teksnya '-' / ada 'min'
                        for _, btn in ipairs(candidates) do
                            if looksLikeMinus(btn) then
                                return btn
                            end
                        end

                        -- 2) fallback: kedua dari kanan (kanan = X, kiri = -)
                        if #candidates >= 2 then
                            return candidates[#candidates - 1]
                        else
                            return candidates[#candidates]
                        end
                    end
                end
            end
        end

        task.wait(0.2)
    end

    return nil
end

--------------------------------------------------
--  KHUSUS: Auto Sell Disable option di blok Auto Sell
--------------------------------------------------
local function findDisableOptionInAutoSell(autoSellHeader, spadesRoot)
    if autoSellHeader and autoSellHeader:IsA("GuiObject") then
        local container = autoSellHeader:FindFirstAncestorOfClass("Frame")
        if container and container.Parent then
            for _, d in ipairs(container.Parent:GetDescendants()) do
                if d:IsA("TextButton") and isGuiVisible(d) then
                    local txt = string.lower(textOf(d))
                    if txt:find("disable", 1, true) then
                        return d
                    end
                end
            end
        end
    end
    -- fallback: cari saja "Disable" di seluruh window
    if spadesRoot then
        return waitForTextInRoot(spadesRoot, { "disable" }, 4)
    end
    return nil
end

--------------------------------------------------
--  KHUSUS: Makro UI INDO HANGOUT (1–4)
--------------------------------------------------
local function performIndoHangoutFlow()
    -- Cari window utama Spades dulu
    local spadesRoot = findSpadesRootWindow(20)
    if not spadesRoot then
        warn("[Axa Autokey] Spades window tidak ditemukan, batal makro INDO.")
        return
    end

    -- STEP 1: Tekan angka 2 (equip Rod)
    equipRodSlot2()
    task.wait(0.25)

    -- STEP 2: Centang Auto Fishing
    do
        local lbl = waitForTextInRoot(spadesRoot, { "auto fishing" }, 10)
        if lbl and lbl:IsA("GuiObject") then
            local target = findClickableNear(lbl)
            clickGuiObject(target)
        else
            warn("[Axa Autokey] Tidak menemukan label 'Auto Fishing'.")
        end
    end
    task.wait(0.25)

    -- STEP 3: Buka panel Auto Sell lalu pilih Disable
    local autoSellHeader = nil
    do
        autoSellHeader = waitForTextInRoot(spadesRoot, { "auto sell under", "auto sell" }, 10)
        if autoSellHeader and autoSellHeader:IsA("GuiObject") then
            local clickTarget = findClickableNear(autoSellHeader)
            clickGuiObject(clickTarget)
        else
            warn("[Axa Autokey] Tidak menemukan header 'Auto Sell'.")
        end

        task.wait(0.25)

        local disableBtn = findDisableOptionInAutoSell(autoSellHeader, spadesRoot)
        if disableBtn and disableBtn:IsA("GuiObject") then
            clickGuiObject(disableBtn)
        else
            warn("[Axa Autokey] Tidak menemukan opsi 'Disable' di Auto Sell.")
        end
    end

    task.wait(0.3)

    -- STEP 4: Klik tombol Minimize UI Spades
    do
        local minBtn = findSpadesMinimizeButton(10, spadesRoot)
        if minBtn and minBtn:IsA("GuiObject") then
            clickGuiObject(minBtn)
        else
            -- Fallback global
            local fallback = waitForTextGlobal({ " - ", "-", "minimize" }, 4)
            if fallback and fallback:IsA("GuiObject") then
                clickGuiObject(fallback)
            else
                for _, root in ipairs(getRoots()) do
                    for _, d in ipairs(root:GetDescendants()) do
                        if (d:IsA("TextButton") or d:IsA("ImageButton"))
                            and isGuiVisible(d)
                            and string.lower(d.Name):find("min") then
                            clickGuiObject(d)
                            return
                        end
                    end
                end
                warn("[Axa Autokey] Tidak menemukan tombol Minimize Spades.")
            end
        end
    end
end

--------------------------------------------------
--  LOAD SCRIPT PILIHAN + AUTOKEY + MAKRO INDO
--------------------------------------------------
local function runEntry(entry, buttonInstance)
    if not entry or not entry.url then return end

    local method = string.lower(entry.method or "HttpGet")
    local source

    if buttonInstance then
        buttonInstance.Text = "Loading..."
    end

    local ok, err = pcall(function()
        if method == "httpgetasync" then
            source = game:HttpGetAsync(entry.url)
        else
            source = game:HttpGet(entry.url)
        end
    end)

    if not ok then
        warn("[Axa Autokey] Gagal HttpGet:", err)
        if buttonInstance then
            buttonInstance.Text = entry.label or "Entry"
        end
        return
    end

    local fn, loadErr = loadstring(source)
    if not fn then
        warn("[Axa Autokey] Gagal loadstring:", loadErr)
        if buttonInstance then
            buttonInstance.Text = entry.label or "Entry"
        end
        return
    end

    local okRun, runErr = pcall(fn)
    if not okRun then
        warn("[Axa Autokey] Error saat menjalankan script:", runErr)
        if buttonInstance then
            buttonInstance.Text = entry.label or "Entry"
        end
        return
    end

    -- Setelah script jalan, jalankan Autokey + makro INDO (di thread terpisah)
    task.spawn(function()
        autoKeyAndSubmit()

        if string.lower(entry.label or "") == "indo hangout" then
            -- kasih waktu UI Spades kebuka penuh
            task.wait(2.0)
            performIndoHangoutFlow()
        end

        if buttonInstance and buttonInstance.Parent then
            buttonInstance.Text = entry.label or "Entry"
        end
    end)
end

--------------------------------------------------
--  RENDER TOMBOL MENU ENTRIES
--------------------------------------------------
for i, entry in ipairs(ENTRIES) do
    local btn = Instance.new("TextButton")
    btn.Name = "Entry_" .. i
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(225, 225, 235)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(60, 60, 90)
    btn.Text = entry.label or ("Entry " .. i)
    btn.AutoButtonColor = true
    btn.Parent = akList

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        runEntry(entry, btn)
    end)
end

-- Expose buat debugging
_G.AxaAutokeyHG = {
    KEY_STRING        = KEY_STRING,
    ENTRIES           = ENTRIES,
    AutoKeyAndSubmit  = autoKeyAndSubmit,
    FindModernKeyUI   = findModernKeyUI,
    PerformIndoFlow   = performIndoHangoutFlow,
    FindSpadesRoot    = findSpadesRootWindow,
    FindSpadesMinBtn  = findSpadesMinimizeButton,
}
