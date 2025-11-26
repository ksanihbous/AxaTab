--==========================================================
--  AxaTab_TPArea.lua  (TAB 8 - "TP Area")
--  Env dari CORE:
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService (opsional, kalau tidak ada pakai GetService)
--==========================================================

------------------- SERVICES -------------------
local players        = Players or game:GetService("Players")
local player         = LocalPlayer or players.LocalPlayer
local runService     = RunService or game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local TeleportService= game:GetService("TeleportService")
local StarterGui     = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TextChatService  = game:GetService("TextChatService")

------------------- ENV FRAME -------------------
local frame = TAB_FRAME  -- frame putih di dalam ContentHolder (dari CORE)

------------------- STATE KARAKTER -------------------
local char = player.Character or player.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
end)

------------------- HELPERS -------------------
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title   = title or "Info",
            Text    = text or "",
            Duration= dur or 2
        })
    end)
end

local function ensureReady(timeout)
    timeout = timeout or 5
    local c = player.Character or player.CharacterAdded:Wait()
    local hum = c:FindFirstChildOfClass("Humanoid") or c:WaitForChild("Humanoid")
    local root = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart")

    local t0 = os.clock()
    while os.clock() - t0 < timeout do
        if hum.Health > 0 and root and root.Parent == c then
            break
        end
        task.wait(0.05)
    end

    if root then
        if root.Anchored then root.Anchored = false end
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if hum then
        hum.Sit = false
        hum.PlatformStand = false
    end

    return c, hum, root
end

local function teleportTo(vec)
    local c, hum, root = ensureReady(5)
    if not (c and hum and root and hum.Health > 0) then
        notify("Teleport", "Karakter belum siap.", 1.2)
        return
    end

    c:PivotTo(CFrame.new(vec + Vector3.new(0, 3, 0)))

    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    notify("Teleport", string.format("Ke (%.2f, %.2f, %.2f)", vec.X, vec.Y, vec.Z), 1.2)
end

local function safeSetClipboard(text, labelName)
    local ok = pcall(function()
        setclipboard(text)
    end)
    if ok then
        notify("Disalin", (labelName and (labelName .. " → ") or "") .. "Koordinat disalin ke clipboard.", 1.2)
    else
        -- fallback: tunjukkan teksnya saja
        notify("Clipboard", text, 2.5)
    end
end

------------------- REJOIN VIA !rejoin -------------------
local function tryRejoin()
    notify("Rejoin", "Menghubungkan ulang...", 1.2)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
    if not ok then
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
    end
end

local function handleChatForRejoin(text, fromUserId)
    if not text or fromUserId ~= player.UserId then return end
    local msg = text:lower():gsub("^%s+",""):gsub("%s+$","")
    if msg:sub(1, 7) == "!rejoin" then
        tryRejoin()
    end
end

-- Biar tidak double hook kalau tab dipanggil ulang
if not _G.AxaHub_TP_RejoinHooked then
    _G.AxaHub_TP_RejoinHooked = true

    -- TextChatService (chat baru)
    if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local function hookChannel(ch)
            if ch:IsA("TextChannel") then
                ch.MessageReceived:Connect(function(message)
                    local src = message.TextSource
                    if src and src.UserId == player.UserId then
                        handleChatForRejoin(message.Text, src.UserId)
                    end
                end)
            end
        end
        local chans = TextChatService:FindFirstChild("TextChannels")
        if chans then
            for _, ch in ipairs(chans:GetChildren()) do
                hookChannel(ch)
            end
            chans.ChildAdded:Connect(hookChannel)
        end
    end

    -- Legacy chat
    player.Chatted:Connect(function(msg)
        handleChatForRejoin(msg, player.UserId)
    end)
end

------------------- DATA AREA (WAYPOINTS) -------------------
local AREAS = {
    { name = "Basecamp",           vec = Vector3.new(-88.61, 3.27, 196.80) },
    { name = "Bangunan 1",         vec = Vector3.new(7.35, 56.56, -38.19) },
    { name = "Bangunan 2",         vec = Vector3.new(-119.99, 38.37, -347.70) },
    { name = "Api Unggun",         vec = Vector3.new(14.02, 51.87, -395.30) },
    { name = "Menara 1",           vec = Vector3.new(-380.69, 84.22, 27.85) },
    { name = "Menara 2",           vec = Vector3.new(-374.64, 106.27, 29.05) },
    { name = "Peti 2 NPC",         vec = Vector3.new(-374.64, 106.27, 29.05) },

    -- Area khusus HG
    { name = "Basecamp HG",        vec = Vector3.new(30.82, 39.87, -17.30) },
    { name = "Sell Fish HG",       vec = Vector3.new(196.72, -0.05, -457.84) },
    { name = "Buy Rod HG",         vec = Vector3.new(229.67, 2.65, -277.26) },
    { name = "Tengah Laut HG (Bawah)", vec = Vector3.new(-193.03, 6.95, -2769.54) },
    { name = "Tengah Laut HG (Atas)",  vec = Vector3.new(-166.55, 17.17, -2770.24) },
}

------------------- UI: HEADER -------------------
local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -10, 0, 22)
header.Position = UDim2.new(0, 5, 0, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextColor3 = Color3.fromRGB(40, 40, 60)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "🧭 TP Area"
header.Parent = frame

local sub = Instance.new("TextLabel")
sub.Name = "Sub"
sub.Size = UDim2.new(1, -10, 0, 34)
sub.Position = UDim2.new(0, 5, 0, 26)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextColor3 = Color3.fromRGB(90, 90, 120)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextYAlignment = Enum.TextYAlignment.Top
sub.TextWrapped = true
sub.Text = "Klik tombol TP untuk teleport ke area favorit. SHIFT + klik kartu = salin Vector3. Ketik !rejoin di chat untuk rejoin server."
sub.Parent = frame

------------------- UI: LIST AREA -------------------
local list = Instance.new("ScrollingFrame")
list.Name = "AreaList"
list.Position = UDim2.new(0, 6, 0, 70)
list.Size = UDim2.new(1, -12, 1, -120)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarImageTransparency = 0.1
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = list

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end)

------------------- UI: FOOTER (INFO + REJOIN BUTTON) -------------------
local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, -12, 0, 26)
footer.Position = UDim2.new(0, 6, 1, -30)
footer.BackgroundTransparency = 1
footer.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "Info"
infoLabel.Size = UDim2.new(1, -140, 1, 0)
infoLabel.Position = UDim2.new(0, 0, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextColor3 = Color3.fromRGB(90, 90, 120)
infoLabel.Text = "Total area: " .. tostring(#AREAS)
infoLabel.Parent = footer

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Name = "RejoinButton"
rejoinBtn.Size = UDim2.new(0, 120, 1, 0)
rejoinBtn.Position = UDim2.new(1, -120, 0, 0)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(110, 140, 210)
rejoinBtn.AutoButtonColor = true
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = 13
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.Text = "Rejoin Server"
rejoinBtn.Parent = footer

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 8)
rejoinCorner.Parent = rejoinBtn

rejoinBtn.MouseButton1Click:Connect(function()
    tryRejoin()
end)

------------------- UI: KARTU AREA -------------------
local function createAreaCard(idx, data)
    local card = Instance.new("Frame")
    card.Name = "Area_" .. tostring(idx)
    card.Size = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = Color3.fromRGB(230, 230, 244)
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.Parent = list

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(200, 200, 225)
    stroke.Transparency = 0.3
    stroke.Parent = card

    -- Highlight dikit kalau area HG
    if string.find(string.lower(data.name), "hg", 1, true) then
        card.BackgroundColor3 = Color3.fromRGB(215, 235, 255)
        stroke.Color          = Color3.fromRGB(130, 170, 230)
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -130, 0, 26)
    nameLabel.Position = UDim2.new(0, 10, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(40, 40, 70)
    nameLabel.Text = data.name
    nameLabel.Parent = card

    local coordLabel = Instance.new("TextLabel")
    coordLabel.Name = "Coords"
    coordLabel.Size = UDim2.new(1, -130, 0, 20)
    coordLabel.Position = UDim2.new(0, 10, 0, 32)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Font = Enum.Font.Code
    coordLabel.TextSize = 12
    coordLabel.TextXAlignment = Enum.TextXAlignment.Left
    coordLabel.TextColor3 = Color3.fromRGB(90, 90, 120)
    coordLabel.Text = string.format("(%.2f, %.2f, %.2f)", data.vec.X, data.vec.Y, data.vec.Z)
    coordLabel.Parent = card

    local tpBtn = Instance.new("TextButton")
    tpBtn.Name = "TPButton"
    tpBtn.Size = UDim2.new(0, 80, 0, 28)
    tpBtn.Position = UDim2.new(1, -88, 0.5, -14)
    tpBtn.BackgroundColor3 = Color3.fromRGB(80, 170, 120)
    tpBtn.AutoButtonColor = true
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 13
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.Text = "TP"
    tpBtn.Parent = card

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 10)
    tpCorner.Parent = tpBtn

    -- Hover efek
    tpBtn.MouseEnter:Connect(function()
        TweenService:Create(tpBtn, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(95, 190, 140)
        }):Play()
    end)
    tpBtn.MouseLeave:Connect(function()
        TweenService:Create(tpBtn, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(80, 170, 120)
        }):Play()
    end)

    tpBtn.MouseButton1Click:Connect(function()
        teleportTo(data.vec)
    end)

    -- SHIFT + klik kartu = copy Vector3 ke clipboard
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                local text = string.format("Vector3.new(%.2f, %.2f, %.2f)", data.vec.X, data.vec.Y, data.vec.Z)
                safeSetClipboard(text, data.name)
            end
        end
    end)

    -- Hover kartu (warna + stroke)
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = card.BackgroundColor3:lerp(Color3.fromRGB(255, 255, 255), 0.08)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Thickness = 2,
            Transparency = 0.1
        }):Play()
    end)

    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = (string.find(string.lower(data.name), "hg", 1, true)
                and Color3.fromRGB(215, 235, 255)
                or  Color3.fromRGB(230, 230, 244))
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Thickness = 1,
            Transparency = 0.3
        }):Play()
    end)
end

------------------- BUILD LIST -------------------
for i, area in ipairs(AREAS) do
    createAreaCard(i, area)
end

infoLabel.Text = string.format("Total area: %d  |  SHIFT + klik = copy Vector3", #AREAS)