--==========================================================
--  AxaTab_BagView.lua
--  Env dari core:
--    TAB_FRAME, Players, LocalPlayer, RunService
--==========================================================

local bagTabFrame = TAB_FRAME

local bagHeader = Instance.new("TextLabel")
bagHeader.Name = "BagHeader"
bagHeader.Size = UDim2.new(1, -10, 0, 22)
bagHeader.Position = UDim2.new(0, 5, 0, 6)
bagHeader.BackgroundTransparency = 1
bagHeader.Font = Enum.Font.GothamBold
bagHeader.TextSize = 15
bagHeader.TextColor3 = Color3.fromRGB(40, 40, 60)
bagHeader.TextXAlignment = Enum.TextXAlignment.Left
bagHeader.Text = "🎒 Axa Backpack View"
bagHeader.Parent = bagTabFrame

local bagSub = Instance.new("TextLabel")
bagSub.Name = "BagSub"
bagSub.Size = UDim2.new(1, -10, 0, 18)
bagSub.Position = UDim2.new(0, 5, 0, 26)
bagSub.BackgroundTransparency = 1
bagSub.Font = Enum.Font.Gotham
bagSub.TextSize = 12
bagSub.TextColor3 = Color3.fromRGB(90, 90, 120)
bagSub.TextXAlignment = Enum.TextXAlignment.Left
bagSub.Text = "List Rod & Tools semua pemain (auto + manual refresh)"
bagSub.Parent = bagTabFrame

local bagRefreshBtn = Instance.new("TextButton")
bagRefreshBtn.Name = "RefreshBtn"
bagRefreshBtn.Size = UDim2.new(0, 90, 0, 22)
bagRefreshBtn.AnchorPoint = Vector2.new(1, 0)
bagRefreshBtn.Position = UDim2.new(1, -8, 0, 10)
bagRefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 200)
bagRefreshBtn.Font = Enum.Font.GothamBold
bagRefreshBtn.TextSize = 13
bagRefreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
bagRefreshBtn.Text = "Refresh"
bagRefreshBtn.Parent = bagTabFrame

local bagRefCorner = Instance.new("UICorner")
bagRefCorner.CornerRadius = UDim.new(0, 8)
bagRefCorner.Parent = bagRefreshBtn

local bagSearchBox = Instance.new("TextBox")
bagSearchBox.Name = "SearchBox"
bagSearchBox.Size = UDim2.new(1, -12, 0, 22)
bagSearchBox.Position = UDim2.new(0, 6, 0, 48)
bagSearchBox.BackgroundColor3 = Color3.fromRGB(230, 230, 245)
bagSearchBox.TextColor3 = Color3.fromRGB(80, 80, 110)
bagSearchBox.Font = Enum.Font.Gotham
bagSearchBox.TextSize = 13
bagSearchBox.TextXAlignment = Enum.TextXAlignment.Left
bagSearchBox.ClearTextOnFocus = false
bagSearchBox.Text = ""
bagSearchBox.PlaceholderText = "Search.."
bagSearchBox.Parent = bagTabFrame

local bagSearchCorner = Instance.new("UICorner")
bagSearchCorner.CornerRadius = UDim.new(0, 8)
bagSearchCorner.Parent = bagSearchBox

local bagList = Instance.new("ScrollingFrame")
bagList.Name = "BagList"
bagList.Position = UDim2.new(0, 6, 0, 74)
bagList.Size = UDim2.new(1, -12, 1, -80)
bagList.BackgroundTransparency = 1
bagList.BorderSizePixel = 0
bagList.ScrollBarThickness = 4
bagList.CanvasSize = UDim2.new(0, 0, 0, 0)
bagList.Parent = bagTabFrame

local bagLayout = Instance.new("UIListLayout")
bagLayout.FillDirection = Enum.FillDirection.Vertical
bagLayout.SortOrder = Enum.SortOrder.Name
bagLayout.Padding = UDim.new(0, 4)
bagLayout.Parent = bagList

bagLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    bagList.CanvasSize = UDim2.new(0, 0, 0, bagLayout.AbsoluteContentSize.Y + 10)
end)

local function getToolsForPlayer(player)
    local rods  = {}
    local other = {}

    local function scan(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") then
                local lower = string.lower(child.Name)
                if string.find(lower, "rod") then
                    table.insert(rods, child.Name)
                else
                    table.insert(other, child.Name)
                end
            end
        end
    end

    scan(player:FindFirstChild("Backpack"))
    scan(player.Character)

    local rodsText   = (#rods > 0) and table.concat(rods, ", ") or "-"
    local othersText = (#other > 0) and table.concat(other, ", ") or "-"
    return rodsText, othersText
end

local bagRows = {}

local function bagMatchesSearch(pl)
    local q = string.lower(bagSearchBox.Text or "")
    if q == "" then return true end
    local dn = string.lower(pl.DisplayName or pl.Name)
    local un = string.lower(pl.Name)
    return dn:find(q, 1, true) or un:find(q, 1, true)
end

local function applyBagSearchFilter()
    for pl, row in pairs(bagRows) do
        local match = bagMatchesSearch(pl)
        if match then
            row.Visible = true
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.Size = UDim2.new(1, 0, 0, 52)
        else
            row.Visible = false
            row.AutomaticSize = Enum.AutomaticSize.None
            row.Size = UDim2.new(1, 0, 0, 0)
        end
    end
end

local function createBagRow(player)
    local row = Instance.new("Frame")
    row.Name = player.Name
    row.Size = UDim2.new(1, 0, 0, 52)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = Color3.fromRGB(230, 230, 244)
    row.BackgroundTransparency = 0.1
    row.BorderSizePixel = 0
    row.Parent = bagList

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local rs = Instance.new("UIStroke")
    rs.Thickness = 1
    rs.Color = Color3.fromRGB(200, 200, 220)
    rs.Parent = row

    if player == LocalPlayer then
        row.BackgroundColor3 = Color3.fromRGB(210, 230, 255)
        rs.Color             = Color3.fromRGB(120, 160, 235)
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -10, 0, 18)
    nameLabel.Position = UDim2.new(0, 5, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(50, 50, 75)
    nameLabel.Text = string.format("%s (@%s)", player.DisplayName or player.Name, player.Name)
    nameLabel.Parent = row

    local toolsLabel = Instance.new("TextLabel")
    toolsLabel.Name = "Tools"
    toolsLabel.Size = UDim2.new(1, -10, 0, 30)
    toolsLabel.Position = UDim2.new(0, 5, 0, 22)
    toolsLabel.BackgroundTransparency = 1
    toolsLabel.Font = Enum.Font.Gotham
    toolsLabel.TextSize = 12
    toolsLabel.TextXAlignment = Enum.TextXAlignment.Left
    toolsLabel.TextYAlignment = Enum.TextYAlignment.Top
    toolsLabel.TextColor3 = Color3.fromRGB(80, 80, 110)
    toolsLabel.TextWrapped = true
    toolsLabel.AutomaticSize = Enum.AutomaticSize.Y
    toolsLabel.Parent = row

    bagRows[player] = row
end

local function removeBagRow(player)
    local row = bagRows[player]
    if row then
        row:Destroy()
        bagRows[player] = nil
    end
end

local function updateBagRow(player)
    local row = bagRows[player]
    if not row then return end

    local rodsText, othersText = getToolsForPlayer(player)
    local nameLabel  = row:FindFirstChild("Name")
    local toolsLabel = row:FindFirstChild("Tools")
    if not (nameLabel and toolsLabel) then return end

    nameLabel.Text = string.format("%s (@%s)", player.DisplayName or player.Name, player.Name)
    toolsLabel.Text = string.format("Rod: %s  |  Tools lain: %s", rodsText, othersText)
end

local function refreshBagAll()
    for _, pl in ipairs(Players:GetPlayers()) do
        if not bagRows[pl] then
            createBagRow(pl)
        end
        updateBagRow(pl)
    end

    for pl, _ in pairs(bagRows) do
        local stillHere = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p == pl then stillHere = true break end
        end
        if not stillHere then
            removeBagRow(pl)
        end
    end

    applyBagSearchFilter()
end

bagSearchBox:GetPropertyChangedSignal("Text"):Connect(applyBagSearchFilter)

bagRefreshBtn.MouseButton1Click:Connect(function()
    bagRefreshBtn.Text = "Refreshing..."
    refreshBagAll()
    task.delay(0.3, function()
        if bagRefreshBtn then
            bagRefreshBtn.Text = "Refresh"
        end
    end)
end)

Players.PlayerAdded:Connect(function(pl)
    createBagRow(pl)
    updateBagRow(pl)
    applyBagSearchFilter()
end)

Players.PlayerRemoving:Connect(function(pl)
    removeBagRow(pl)
end)

refreshBagAll()

local bagAcc = 0
RunService.RenderStepped:Connect(function(dt)
    bagAcc += dt
    if bagAcc >= 1.0 then
        bagAcc = 0
        refreshBagAll()
    end
end)

-- expose buat TAB lain (Webhook) kalau mau auto refresh BAG VIEW
_G.AxaHub_BagView_Refresh = refreshBagAll