--==========================================================
--  AxaTab_Autokey.lua
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

-- LIST: diganti jadi ScrollingFrame biar nggak keluar area TAB
local akList = Instance.new("ScrollingFrame")
akList.Name = "MenuList"
akList.Position = UDim2.new(0, 5, 0, 84)
akList.Size = UDim2.new(1, -10, 1, -92) -- tetap sama, tapi sekarang bisa scroll
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

-- Auto sesuaikan CanvasSize agar scrollbar muncul kalau kepanjangan
akLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local size = akLayout.AbsoluteContentSize
    akList.CanvasSize = UDim2.new(0, 0, 0, size.Y + 4)
end)

--------------------------------------------------
--  CONFIG: KEY + ENTRIES SCRIPT
--------------------------------------------------
-- EDIT KEY DI SINI (satu key untuk semua script ENTRIES)
local KEY_STRING = "b5a60c22-68f1-4ee9-8e73-16f66179bf36"

-- Tambah script lain tinggal push ke tabel ini
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
}

if KEY_STRING and KEY_STRING ~= "" then
    akKeyLabel.Text = "Key saat ini: " .. KEY_STRING
else
    akKeyLabel.Text = "Key saat ini: (KOSONG – isi di KEY_STRING)"
end

--------------------------------------------------
--  UTIL: ROOT GUI PENCARIAN ModernKeyUI
--------------------------------------------------
local function getRoots()
    local roots = {}

    if playerGui then
        table.insert(roots, playerGui)
    end
    if CoreGui then
        table.insert(roots, CoreGui)
    end

    -- Executor UI (kalau ada)
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
--  UTIL: firesignal kuat (getconnections)
--------------------------------------------------
local function fireSignalStrong(signal)
    if not signal then return false end
    local anyFired = false

    -- 1) Coba firesignal langsung (kalau didukung executor)
    if typeof(firesignal) == "function" then
        local ok = pcall(function()
            firesignal(signal)
        end)
        if ok then
            anyFired = true
        end
    end

    -- 2) Coba getconnections
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

--------------------------------------------------
--  UTIL: klik submit dengan VirtualInputManager
--------------------------------------------------
local function clickSubmitWithCursor(submitButton)
    if not submitButton then return end

    -- 1) Coba firing semua event dulu
    local hit =
        fireSignalStrong(submitButton.MouseButton1Click)
        or fireSignalStrong(submitButton.MouseButton1Down)
        or fireSignalStrong(submitButton.MouseButton1Up)
        or fireSignalStrong(submitButton.Activated)

    if hit then
        return
    end

    -- 2) Fallback: gerakkin cursor + klik kiri pakai VirtualInputManager
    if not VirtualInputManager or not UserInputService then
        warn("[Axa Autokey] VirtualInputManager / UserInputService tidak tersedia, tidak bisa klik pakai cursor.")
        return
    end

    local buttonPos  = submitButton.AbsolutePosition
    local buttonSize = submitButton.AbsoluteSize
    local targetX    = buttonPos.X + buttonSize.X/2
    local targetY    = buttonPos.Y + buttonSize.Y/2

    local oldPos     = UserInputService:GetMouseLocation()
    local oldX, oldY = oldPos.X, oldPos.Y

    local function moveMouse(x, y)
        pcall(function() VirtualInputManager:SendMouseMoveEvent(x, y, game) end)
    end

    local function clickAt(x, y)
        moveMouse(x, y)
        task.wait(0.03)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end

    clickAt(targetX, targetY)
    moveMouse(oldX, oldY)
end

--------------------------------------------------
--  CARI: TextBox + Submit di ModernKeyUI
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

--------------------------------------------------
--  ISI KEY + TEKAN SUBMIT
--------------------------------------------------
local function autoKeyAndSubmit()
    if not KEY_STRING or KEY_STRING == "" then
        warn("[Axa Autokey] KEY_STRING kosong, skip auto key.")
        return
    end

    local keyBox, submitButton

    -- Tunggu ModernKeyUI muncul (maks ~30 detik)
    for _ = 1, 60 do
        keyBox, submitButton = findModernKeyUI()
        if keyBox and submitButton then
            break
        end
        task.wait(0.5)
    end

    if not (keyBox and submitButton) then
        warn("[Axa Autokey] Tidak menemukan ModernKeyUI / tombol Submit.")
        return
    end

    pcall(function()
        keyBox:CaptureFocus()
        keyBox.Text = KEY_STRING
        keyBox:ReleaseFocus()
    end)

    task.wait(0.4)
    clickSubmitWithCursor(submitButton)
end

--------------------------------------------------
--  LOAD SCRIPT PILIHAN + TRIGGER AUTOKEY
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

    -- Setelah script jalan, tunggu sebentar lalu hunting ModernKeyUI
    task.spawn(function()
        task.wait(2) -- kalau mau diubah ke 10–15 detik tinggal ganti di sini
        autoKeyAndSubmit()
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

-- Expose dikit buat debugging manual kalau perlu
_G.AxaAutokeyHG = {
    KEY_STRING        = KEY_STRING,
    ENTRIES           = ENTRIES,
    AutoKeyAndSubmit  = autoKeyAndSubmit,
    FindModernKeyUI   = findModernKeyUI,
}
