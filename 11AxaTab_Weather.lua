--==========================================================
--  11AxaTab_Weather.lua
--  Dipanggil via loadstring dari CORE AxaHub
--  Env yang tersedia (dari core):
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, TweenService, HttpService,
--    UserInputService, StarterGui, CoreGui, SetActiveTab, AXA_TWEEN (opsional)
--==========================================================

local frame        = TAB_FRAME
local tweenService = TweenService or game:GetService("TweenService")
local lighting     = game:GetService("Lighting")

--==========================================================
-- BERSIHKAN FRAME TAB (BIARKAN CORE YANG URUS HEADER GLOBAL)
--==========================================================
frame:ClearAllChildren()

--==========================================================
-- HELPER EFFECTS (Atmosphere, ColorCorrection, dll)
--==========================================================
local function ensureEffect(name, className)
    local inst = lighting:FindFirstChild(name)
    if not inst then
        inst = Instance.new(className)
        inst.Name = name
        inst.Parent = lighting
    end
    return inst
end

local Effects = {
    Atmosphere      = ensureEffect("_AxaWeather_Atmosphere",      "Atmosphere"),
    ColorCorrection = ensureEffect("_AxaWeather_ColorCorrection", "ColorCorrectionEffect"),
    Bloom           = ensureEffect("_AxaWeather_Bloom",           "BloomEffect"),
    DOF             = ensureEffect("_AxaWeather_DOF",             "DepthOfFieldEffect"),
    SunRays         = ensureEffect("_AxaWeather_SunRays",         "SunRaysEffect"),
    Sky             = ensureEffect("_AxaWeather_Sky",             "Sky"),
}

Effects.Bloom.Enabled           = true
Effects.DOF.Enabled             = true
Effects.SunRays.Enabled         = true
Effects.ColorCorrection.Enabled = true

--==========================================================
-- PRESET WEATHER
--  (bisa kamu tambah/kurangi, grid 4 kolom otomatis ikut)
--==========================================================
local PRESETS = {
    ["Clear Day"] = {
        Lighting = {
            ClockTime = 12,
            Brightness = 3,
            ExposureCompensation = 0,
            GlobalShadows = true,
            EnvironmentDiffuseScale  = 1,
            EnvironmentSpecularScale = 1,
        },
        Atmosphere = {
            Density = 0.25,
            Color  = Color3.fromRGB(199,220,255),
            Decay  = Color3.fromRGB(104,124,155),
            Glare  = 0,
            Haze   = 1,
        },
        Color = {
            Brightness = 0,
            Contrast   = 0.05,
            Saturation = 0.05,
            TintColor  = Color3.fromRGB(255,255,255),
        },
        Bloom = {
            Intensity = 0.1,
            Size      = 12,
            Threshold = 1,
        },
        SunRays = {
            Intensity = 0.02,
            Spread    = 0.8,
        },
    },

    ["Sunrise"] = {
        Lighting = { ClockTime = 6.0, Brightness = 2.2, ExposureCompensation = 0.1 },
        Atmosphere = {
            Density = 0.35,
            Color   = Color3.fromRGB(255,198,150),
            Decay   = Color3.fromRGB(140,90,60),
            Glare   = 0.2,
            Haze    = 1.5,
        },
        Color = {
            Brightness = 0.02,
            Contrast   = 0.1,
            Saturation = 0.1,
            TintColor  = Color3.fromRGB(255,220,200),
        },
        Bloom = { Intensity = 0.15, Size = 18, Threshold = 0.95 },
        SunRays = { Intensity = 0.08, Spread = 0.85 },
    },

    ["Sunset"] = {
        Lighting = { ClockTime = 18.5, Brightness = 2.0, ExposureCompensation = 0.05 },
        Atmosphere = {
            Density = 0.38,
            Color   = Color3.fromRGB(255,170,120),
            Decay   = Color3.fromRGB(120,70,50),
            Glare   = 0.25,
            Haze    = 1.6,
        },
        Color = {
            Brightness = 0,
            Contrast   = 0.12,
            Saturation = 0.12,
            TintColor  = Color3.fromRGB(255,210,170),
        },
        Bloom   = { Intensity = 0.2, Size = 20, Threshold = 0.95 },
        SunRays = { Intensity = 0.1, Spread = 0.9 },
    },

    ["Moonlight"] = {
        Lighting = { ClockTime = 2.2, Brightness = 1.2, ExposureCompensation = -0.05, GlobalShadows = true },
        Atmosphere = {
            Density = 0.3,
            Color   = Color3.fromRGB(170,190,220),
            Decay   = Color3.fromRGB(70,85,110),
            Glare   = 0,
            Haze    = 0.8,
        },
        Color = {
            Brightness = -0.02,
            Contrast   = 0.08,
            Saturation = -0.05,
            TintColor  = Color3.fromRGB(190,210,255),
        },
        Bloom   = { Intensity = 0.08, Size = 16, Threshold = 0.9 },
        DOF     = { FocusDistance = 160, InFocusRadius = 30, NearIntensity = 0, FarIntensity = 0.05 },
        SunRays = { Intensity = 0.02, Spread = 0.7 },
    },

    ["Storm"] = {
        Lighting = {
            ClockTime = 14,
            Brightness = 1.1,
            ExposureCompensation = -0.25,
            GlobalShadows = true,
            FogStart = 0,
            FogEnd   = 350,
            FogColor = Color3.fromRGB(80,85,95),
        },
        Atmosphere = {
            Density = 0.7,
            Color   = Color3.fromRGB(130,145,160),
            Decay   = Color3.fromRGB(60,65,70),
            Glare   = 0.1,
            Haze    = 2.2,
        },
        Color = {
            Brightness = -0.08,
            Contrast   = 0.15,
            Saturation = -0.1,
            TintColor  = Color3.fromRGB(210,220,230),
        },
        Bloom = { Intensity = 0.05, Size = 10, Threshold = 1.0 },
    },

    ["Ocean Blue"] = {
        Lighting = { ClockTime = 11.3, Brightness = 2.6, ExposureCompensation = 0.05 },
        Atmosphere = {
            Density = 0.28,
            Color   = Color3.fromRGB(150,200,255),
            Decay   = Color3.fromRGB(60,120,180),
            Glare   = 0.05,
            Haze    = 1.0,
        },
        Color = {
            Brightness = 0.02,
            Contrast   = 0.06,
            Saturation = 0.1,
            TintColor  = Color3.fromRGB(200,230,255),
        },
        Bloom   = { Intensity = 0.12, Size = 14, Threshold = 0.97 },
        SunRays = { Intensity = 0.03, Spread = 0.85 },
    },

    ["Aurora"] = {
        Lighting = { ClockTime = 0.8, Brightness = 1.2, ExposureCompensation = -0.05 },
        Atmosphere = {
            Density = 0.35,
            Color   = Color3.fromRGB(180,220,200),
            Decay   = Color3.fromRGB(60,100,90),
            Glare   = 0.1,
            Haze    = 1.2,
        },
        Color = {
            Brightness = 0.02,
            Contrast   = 0.1,
            Saturation = 0.2,
            TintColor  = Color3.fromRGB(200,255,220),
        },
        Bloom = { Intensity = 0.2, Size = 20, Threshold = 0.9 },
    },

    ["Godrays Forest"] = {
        Lighting = { ClockTime = 15.5, Brightness = 2.2, ExposureCompensation = 0.05 },
        Atmosphere = {
            Density = 0.4,
            Color   = Color3.fromRGB(220,235,210),
            Decay   = Color3.fromRGB(120,140,110),
            Glare   = 0.2,
            Haze    = 1.6,
        },
        Color = {
            Brightness = 0.02,
            Contrast   = 0.08,
            Saturation = 0.08,
            TintColor  = Color3.fromRGB(235,245,230),
        },
        SunRays = { Intensity = 0.2, Spread = 0.92 },
    },

    ["Heatwave"] = {
        Lighting = { ClockTime = 13.3, Brightness = 2.8, ExposureCompensation = 0.15 },
        Atmosphere = {
            Density = 0.22,
            Color   = Color3.fromRGB(255,220,170),
            Decay   = Color3.fromRGB(200,150,90),
            Glare   = 0.2,
            Haze    = 1.0,
        },
        Color = {
            Brightness = 0.03,
            Contrast   = 0.12,
            Saturation = 0.06,
            TintColor  = Color3.fromRGB(255,235,200),
        },
        Bloom = { Intensity = 0.24, Size = 22, Threshold = 0.94 },
    },

    ["Tropical Noon"] = {
        Lighting = {
            ClockTime = 12.5,
            Brightness = 3.0,
            ExposureCompensation = 0.08,
            GlobalShadows = true,
            EnvironmentDiffuseScale  = 1.1,
            EnvironmentSpecularScale = 1.1,
        },
        Atmosphere = {
            Density = 0.22,
            Color   = Color3.fromRGB(210,235,255),
            Decay   = Color3.fromRGB(110,150,200),
            Glare   = 0.05,
            Haze    = 0.9,
        },
        Color = {
            Brightness = 0.01,
            Contrast   = 0.08,
            Saturation = 0.12,
            TintColor  = Color3.fromRGB(255,255,255),
        },
        Bloom   = { Intensity = 0.14, Size = 16, Threshold = 0.96 },
        SunRays = { Intensity = 0.07, Spread = 0.86 },
    },

    -- Nama–nama yang kamu sebut:
    ["Alpine Morning"] = {
        Lighting = { ClockTime = 8.0, Brightness = 2.1, ExposureCompensation = 0.04, GlobalShadows = true },
        Atmosphere = {
            Density = 0.26,
            Color   = Color3.fromRGB(205,230,255),
            Decay   = Color3.fromRGB(140,170,200),
            Glare   = 0.04,
            Haze    = 0.95,
        },
        Color = {
            Brightness = 0.01,
            Contrast   = 0.08,
            Saturation = 0.06,
            TintColor  = Color3.fromRGB(235,245,255),
        },
        Bloom   = { Intensity = 0.12, Size = 14, Threshold = 0.97 },
        SunRays = { Intensity = 0.10, Spread = 0.88 },
    },

    ["Sunrays"] = { -- preset ringkas, lebih fokus ke SunRays
        Lighting = { ClockTime = 16.0, Brightness = 2.2, ExposureCompensation = 0.06 },
        Atmosphere = {
            Density = 0.30,
            Color   = Color3.fromRGB(230,220,200),
            Decay   = Color3.fromRGB(160,130,100),
            Glare   = 0.18,
            Haze    = 1.2,
        },
        Color = {
            Brightness = 0.01,
            Contrast   = 0.10,
            Saturation = 0.08,
            TintColor  = Color3.fromRGB(255,240,210),
        },
        Bloom   = { Intensity = 0.16, Size = 18, Threshold = 0.95 },
        SunRays = { Intensity = 0.2, Spread = 0.92 },
    },

    ["Autumn Amber"] = {
        Lighting = { ClockTime = 16.9, Brightness = 2.1, ExposureCompensation = 0.04 },
        Atmosphere = {
            Density = 0.33,
            Color   = Color3.fromRGB(255,210,155),
            Decay   = Color3.fromRGB(165,110,60),
            Glare   = 0.1,
            Haze    = 1.2,
        },
        Color = {
            Brightness = 0.01,
            Contrast   = 0.14,
            Saturation = 0.10,
            TintColor  = Color3.fromRGB(255,225,185),
        },
        Bloom = { Intensity = 0.16, Size = 18, Threshold = 0.95 },
    },

    ["Foggy"] = {
        Lighting = {
            ClockTime = 9.5,
            Brightness = 1.5,
            ExposureCompensation = -0.05,
            FogStart = 0,
            FogEnd   = 180,
            FogColor = Color3.fromRGB(200,205,210),
        },
        Atmosphere = {
            Density = 0.9,
            Color   = Color3.fromRGB(210,215,220),
            Decay   = Color3.fromRGB(180,185,190),
            Glare   = 0,
            Haze    = 3.0,
        },
        Color = {
            Brightness = 0,
            Contrast   = -0.03,
            Saturation = -0.1,
            TintColor  = Color3.fromRGB(230,235,240),
        },
    },

    ["Blizzard"] = {
        Lighting = {
            ClockTime = 13.0,
            Brightness = 2.0,
            ExposureCompensation = -0.1,
            FogStart = 0,
            FogEnd   = 160,
            FogColor = Color3.fromRGB(230,235,240),
        },
        Atmosphere = {
            Density = 1.0,
            Color   = Color3.fromRGB(235,240,255),
            Decay   = Color3.fromRGB(210,220,240),
            Glare   = 0,
            Haze    = 3.2,
        },
        Color = {
            Brightness = 0.02,
            Contrast   = 0.1,
            Saturation = -0.15,
            TintColor  = Color3.fromRGB(240,245,255),
        },
    },

    ["Cyberpunk Night"] = {
        Lighting = { ClockTime = 0.2, Brightness = 1.1, ExposureCompensation = -0.05 },
        Atmosphere = {
            Density = 0.3,
            Color   = Color3.fromRGB(150,200,255),
            Decay   = Color3.fromRGB(80,70,120),
            Glare   = 0.15,
            Haze    = 1.1,
        },
        Color = {
            Brightness = 0.03,
            Contrast   = 0.18,
            Saturation = 0.35,
            TintColor  = Color3.fromRGB(210,210,255),
        },
        Bloom = { Intensity = 0.32, Size = 24, Threshold = 0.85 },
    },

    ["Rainy Night"] = {
        Lighting = {
            ClockTime = 23,
            Brightness = 0.9,
            ExposureCompensation = -0.25,
            FogStart = 0,
            FogEnd   = 300,
            FogColor = Color3.fromRGB(90,100,120),
        },
        Atmosphere = {
            Density = 0.65,
            Color   = Color3.fromRGB(150,170,200),
            Decay   = Color3.fromRGB(80,90,110),
            Glare   = 0.05,
            Haze    = 2.0,
        },
        Color = {
            Brightness = -0.05,
            Contrast   = 0.1,
            Saturation = -0.05,
            TintColor  = Color3.fromRGB(220,230,240),
        },
        Bloom = { Intensity = 0.06, Size = 12, Threshold = 0.92 },
    },
}

--==========================================================
-- APPLY PRESET (simple, tanpa tween berat)
--==========================================================
local function applyPresetByName(name)
    local preset = PRESETS[name]
    if not preset then return end

    if preset.Lighting then
        for prop, val in pairs(preset.Lighting) do
            pcall(function()
                lighting[prop] = val
            end)
        end
    end

    if preset.Atmosphere then
        for prop, val in pairs(preset.Atmosphere) do
            pcall(function()
                Effects.Atmosphere[prop] = val
            end)
        end
    end

    if preset.Color then
        for prop, val in pairs(preset.Color) do
            pcall(function()
                Effects.ColorCorrection[prop] = val
            end)
        end
    end

    if preset.Bloom then
        for prop, val in pairs(preset.Bloom) do
            pcall(function()
                Effects.Bloom[prop] = val
            end)
        end
    end

    if preset.DOF then
        for prop, val in pairs(preset.DOF) do
            pcall(function()
                Effects.DOF[prop] = val
            end)
        end
    end

    if preset.SunRays then
        for prop, val in pairs(preset.SunRays) do
            pcall(function()
                Effects.SunRays[prop] = val
            end)
        end
    end
end

--==========================================================
-- SNAPSHOT DEFAULT, TOMBOL RESET
--==========================================================
local defaultSnapshot = {
    Lighting = {},
    Atmosphere = {},
    Color = {},
    Bloom = {},
    DOF = {},
    SunRays = {},
}

local function cloneProps(inst, keys)
    local t = {}
    for _, k in ipairs(keys) do
        local ok, v = pcall(function() return inst[k] end)
        if ok then t[k] = v end
    end
    return t
end

defaultSnapshot.Lighting   = cloneProps(lighting, {
    "ClockTime","Brightness","ExposureCompensation","GlobalShadows",
    "FogStart","FogEnd","FogColor","EnvironmentDiffuseScale","EnvironmentSpecularScale"
})
defaultSnapshot.Atmosphere = cloneProps(Effects.Atmosphere, {"Density","Color","Decay","Glare","Haze"})
defaultSnapshot.Color      = cloneProps(Effects.ColorCorrection, {"Brightness","Contrast","Saturation","TintColor"})
defaultSnapshot.Bloom      = cloneProps(Effects.Bloom, {"Intensity","Size","Threshold"})
defaultSnapshot.DOF        = cloneProps(Effects.DOF, {"FocusDistance","InFocusRadius","NearIntensity","FarIntensity"})
defaultSnapshot.SunRays    = cloneProps(Effects.SunRays, {"Intensity","Spread"})

local function resetWeather()
    for prop, val in pairs(defaultSnapshot.Lighting) do pcall(function() lighting[prop] = val end) end
    for prop, val in pairs(defaultSnapshot.Atmosphere) do pcall(function() Effects.Atmosphere[prop] = val end) end
    for prop, val in pairs(defaultSnapshot.Color) do pcall(function() Effects.ColorCorrection[prop] = val end) end
    for prop, val in pairs(defaultSnapshot.Bloom) do pcall(function() Effects.Bloom[prop] = val end) end
    for prop, val in pairs(defaultSnapshot.DOF) do pcall(function() Effects.DOF[prop] = val end) end
    for prop, val in pairs(defaultSnapshot.SunRays) do pcall(function() Effects.SunRays[prop] = val end) end
end

--==========================================================
-- UI UTAMA DI DALAM TAB (GRID 4 KOLOM)
--==========================================================
local Body = Instance.new("Frame")
Body.Name = "AxaWeatherBody"
Body.BackgroundTransparency = 1
Body.Size = UDim2.fromScale(1,1)
Body.Parent = frame

local padding = Instance.new("UIPadding")
padding.Parent = Body
padding.PaddingTop    = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft   = UDim.new(0, 12)
padding.PaddingRight  = UDim.new(0, 12)

-- Bar atas kecil: label + tombol reset
local TopRow = Instance.new("Frame")
TopRow.Name = "TopRow"
TopRow.BackgroundTransparency = 1
TopRow.Size = UDim2.new(1, 0, 0, 28)
TopRow.Parent = Body

local TopLayout = Instance.new("UIListLayout")
TopLayout.FillDirection = Enum.FillDirection.Horizontal
TopLayout.Padding = UDim.new(0, 6)
TopLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TopLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TopLayout.SortOrder = Enum.SortOrder.LayoutOrder
TopLayout.Parent = TopRow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(0, 150, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextColor3 = Color3.fromRGB(230,230,240)
TitleLabel.Text = "Weather Preset"
TitleLabel.LayoutOrder = 1
TitleLabel.Parent = TopRow

local ResetButton = Instance.new("TextButton")
ResetButton.Name = "ResetButton"
ResetButton.Size = UDim2.new(0, 80, 1, 0)
ResetButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
ResetButton.AutoButtonColor = true
ResetButton.Font = Enum.Font.GothamSemibold
ResetButton.TextSize = 14
ResetButton.TextColor3 = Color3.fromRGB(220, 220, 230)
ResetButton.Text = "Reset"
ResetButton.LayoutOrder = 2
ResetButton.Parent = TopRow
local ResetCorner = Instance.new("UICorner", ResetButton)
ResetCorner.CornerRadius = UDim.new(0, 8)

ResetButton.MouseButton1Click:Connect(resetWeather)

-- Garis pemisah tipis
local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
Divider.BorderSizePixel = 0
Divider.AnchorPoint = Vector2.new(0.5, 0)
Divider.Position = UDim2.new(0.5, 0, 0, 34)
Divider.Size = UDim2.new(1, -4, 0, 1)
Divider.Parent = Body

-- ScrollingFrame untuk tombol preset
local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Name = "PresetList"
ListFrame.BackgroundTransparency = 1
ListFrame.BorderSizePixel = 0
ListFrame.Position = UDim2.new(0, 0, 0, 40)
ListFrame.Size = UDim2.new(1, 0, 1, -40)
ListFrame.ScrollBarThickness = 6
ListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ListFrame.Parent = Body

local ListPadding = Instance.new("UIPadding")
ListPadding.Parent = ListFrame
ListPadding.PaddingTop = UDim.new(0, 6)

-- GRID 4 KOLOM: 4 tombol horizontal, lalu baris berikutnya ke bawah
local GridLayout = Instance.new("UIGridLayout")
GridLayout.Parent = ListFrame
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.FillDirection = Enum.FillDirection.Horizontal
GridLayout.FillDirectionMaxCells = 4           -- ⬅️ 4 tombol per baris
GridLayout.CellPadding = UDim2.fromOffset(6, 6)
GridLayout.CellSize = UDim2.new(0.25, -12, 0, 30) -- ⬅️ relative 4 kolom (0.25 per kolom)

--==========================================================
-- GENERATE TOMBOL PRESET
--==========================================================
local function createPresetButton(name, order)
    local btn = Instance.new("TextButton")
    btn.Name = "Preset_" .. name
    btn.LayoutOrder = order or 0
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(230, 230, 240)
    btn.Parent = ListFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(70, 75, 95)
    stroke.Transparency = 0.2
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(55, 55, 70)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        applyPresetByName(name)
    end)
end

-- urutkan nama preset A-Z biar rapi
local presetNames = {}
for name in pairs(PRESETS) do
    table.insert(presetNames, name)
end
table.sort(presetNames, function(a, b)
    return string.lower(a) < string.lower(b)
end)

for i, name in ipairs(presetNames) do
    createPresetButton(name, i)
end

--==========================================================
-- Selesai, tab 11AxaTab_Weather sekarang:
-- - Layout ikut UI CORE (pakai TAB_FRAME)
-- - Tombol preset 4 horizontal per baris
-- - Weather lainnya lanjut ke baris bawah (grid vertikal)
-- - Reset mengembalikan ke lighting awal masuk tab
--==========================================================
