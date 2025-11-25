--==========================================================
--  AxaTab_Autokey.lua
--  Env:
--    TAB_FRAME, HttpService, Players, CoreGui, StarterGui,
--    UserInputService, VirtualInputManager, PlayerGui (tambahan dari core)
--==========================================================

local autokeyTabFrame = TAB_FRAME

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

local akList = Instance.new("Frame")
akList.Name = "MenuList"
akList.Position = UDim2.new(0, 5, 0, 84)
akList.Size = UDim2.new(1, -10, 1, -92)
akList.BackgroundTransparency = 1
akList.Parent = autokeyTabFrame

local akLayout = Instance.new("UIListLayout")
akLayout.FillDirection = Enum.FillDirection.Vertical
akLayout.SortOrder = Enum.SortOrder.LayoutOrder
akLayout.Padding = UDim.new(0, 4)
akLayout.Parent = akList

-- =================== KONFIG =================== --
local KEY_STRING = "b5a60c22-68f1-4ee9-8e73-16f66179bf36" -- GANTI SESUAI KEY
local ENTRIES = {
    {
        label  = "INDO HANGOUT",
        url    = "https://raw.githubusercontent.com/xxCary-UC/HotRoblox/refs/heads/main/indohangout.lua",
        method = "HttpGetAsync",
    },
    -- tambahin entry lain di sini
}

akKeyLabel.Text = "Key saat ini: " .. KEY_STRING

-- ROOTS: tempat kemungkinan ModernKeyUI muncul
local function getRoots()
    local roots = { PlayerGui, CoreGui }
    pcall(function()
        if gethui then table.insert(roots, gethui()) end
    end)
    pcall(function()
        if get_hidden_gui then table.insert(roots, get_hidden_gui()) end
    end)
    return roots
end

-- Click helper yang agresif (firesignal + getconnections)
local function fireSignalStrong(signal)
    if not signal then return false end
    local anyFired = false

    if typeof(firesignal) == "function" then
        local ok = pcall(function()
            firesignal(signal)
        end)
        if ok then anyFired = true end
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
                        elseif typeof(conn) == "userdata" and conn.Function then
                            conn:Fire()
                        end
                    end)
                    anyFired = true
                end
            end
        end)
    end

    return anyFired
end

local function clickSubmitWithCursor(submitButton)
    if not submitButton then return end

    local hit =
        fireSignalStrong(submitButton.MouseButton1Click)
        or fireSignalStrong(submitButton.MouseButton1Down)
        or fireSignalStrong(submitButton.MouseButton1Up)
        or fireSignalStrong(submitButton.Activated)

    if hit then return end

    local buttonPos  = submitButton.AbsolutePosition
    local buttonSize = submitButton.AbsoluteSize
    local targetX    = buttonPos.X + buttonSize.X/2
    local targetY    = buttonPos.Y + buttonSize.Y/2

    local oldPos     = UserInputService:GetMouseLocation()
    local oldX, oldY = oldPos.X, oldPos.Y

    local function moveMouse(x, y)
        pcall(function() VirtualInputManager:SendMouseMoveEvent(x, y, game) end)
        pcall(function() VirtualInputManager:SendMouseMoveEvent(x, y, 0) end)
        pcall(function() VirtualInputManager:SendMouseMoveEvent(x, y) end)
    end

    local function clickAt(x, y)
        moveMouse(x, y)
        task.wait(0.03)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end

    clickAt(targetX, targetY)
    moveMouse(oldX, oldY)
end

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
        warn("[Axa AutoLoader] KEY_STRING kosong, skip auto key.")
        return
    end

    local keyBox, submitButton
    for _ = 1, 60 do
        keyBox, submitButton = findModernKeyUI()
        if keyBox and submitButton then break end
        task.wait(0.5)
    end

    if not (keyBox and submitButton) then
        warn("[Axa AutoLoader] Tidak menemukan ModernKeyUI / Submit.")
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

local function runEntry(entry)
    if not entry or not entry.url then return end

    local method = string.lower(entry.method or "HttpGet")
    local source

    local ok, err = pcall(function()
        if method == "httpgetasync" then
            source = game:HttpGetAsync(entry.url)
        else
            source = game:HttpGet(entry.url)
        end
    end)

    if not ok then
        warn("[Axa AutoLoader] Gagal HttpGet:", err)
        return
    end

    local fn, loadErr = loadstring(source)
    if not fn then
        warn("[Axa AutoLoader] Gagal loadstring:", loadErr)
        return
    end

    local okRun, runErr = pcall(fn)
    if not okRun then
        warn("[Axa AutoLoader] Error saat menjalankan script:", runErr)
    end

    task.spawn(function()
        task.wait(2)
        autoKeyAndSubmit()
    end)
end

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
    btn.Parent = akList

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.Text = "Loading..."
        task.spawn(function()
            runEntry(entry)
            task.wait(0.4)
            if btn then
                btn.Text = entry.label or ("Entry " .. i)
            end
        end)
    end)
end