--==========================================================
--  11AxaTab_Weather.lua
--  Dipanggil via loadstring dari CORE AxaHub
--  Env yang tersedia (dari core):
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, TweenService, HttpService,
--    UserInputService, VirtualInputManager, ContextActionService,
--    StarterGui, CoreGui, Camera, SetActiveTab, AXA_TWEEN (opsional)
--==========================================================

----------------- ENV & SERVICES -----------------
local frame        = TAB_FRAME
local tweenService = TweenService or game:GetService("TweenService")
local lighting     = game:GetService("Lighting")
local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer

local okUGS, UserGameSettings = pcall(function()
	return UserSettings():GetService("UserGameSettings")
end)

-- Bersihkan isi TAB
frame:ClearAllChildren()

----------------- SAFE CONFIG -----------------
local TWEEN_TIME = 0.9
local EASING     = Enum.EasingStyle.Quad
local EASEDIR    = Enum.EasingDirection.Out

local SAFE = {
	MinBrightness   = 1.0,
	ExpMin          = -0.08,
	ExpMax          = 0.15,
	MinAmbient      = 22,
	MinFogGap       = 150,
	MaxDOFFar       = 0.10,
	MinInFocus      = 28,
	BloomThreshMin  = 0.82,
	CrispQuality    = 8,
	CrispFar        = 0.02,
	CrispFocus      = 20000,
	CrispInFocus    = 10000,
}

----------------- EFFECT HELPERS -----------------
local function ensure(name, className, parent)
	local obj = (parent or lighting):FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = parent or lighting
	end
	return obj
end

local Effects = {
	Atmosphere      = ensure("_AxaWeather_Atmosphere","Atmosphere"),
	ColorCorrection = ensure("_AxaWeather_Color","ColorCorrectionEffect"),
	Bloom           = ensure("_AxaWeather_Bloom","BloomEffect"),
	DOF             = ensure("_AxaWeather_DOF","DepthOfFieldEffect"),
	SunRays         = ensure("_AxaWeather_SunRays","SunRaysEffect"),
	Sky             = ensure("_AxaWeather_Sky","Sky"),
}

Effects.Bloom.Enabled           = true
Effects.DOF.Enabled             = true
Effects.SunRays.Enabled         = true
Effects.ColorCorrection.Enabled = true

-- kosongkan Sky supaya nggak tabrakan sama skybox map
Effects.Sky.SkyboxBk = ""
Effects.Sky.SkyboxDn = ""
Effects.Sky.SkyboxFt = ""
Effects.Sky.SkyboxLf = ""
Effects.Sky.SkyboxRt = ""
Effects.Sky.SkyboxUp = ""

----------------- SNAPSHOT UTILITY -----------------
local function cloneProps(instance, props)
	local t = {}
	for _, p in ipairs(props) do
		local ok, val = pcall(function() return instance[p] end)
		if ok then
			t[p] = val
		end
	end
	return t
end

local initialSnapshot = {
	Lighting   = cloneProps(lighting, {
		"ClockTime","Brightness","Ambient",
		"EnvironmentDiffuseScale","EnvironmentSpecularScale",
		"GlobalShadows","ExposureCompensation",
		"FogEnd","FogStart","FogColor","Technology"
	}),
	Atmosphere = cloneProps(Effects.Atmosphere, {
		"Density","Offset","Color","Decay","Glare","Haze"
	}),
	Color      = cloneProps(Effects.ColorCorrection, {
		"Brightness","Contrast","Saturation","TintColor"
	}),
	Bloom      = cloneProps(Effects.Bloom, {
		"Intensity","Size","Threshold"
	}),
	DOF        = cloneProps(Effects.DOF, {
		"FocusDistance","InFocusRadius","NearIntensity","FarIntensity"
	}),
	SunRays    = cloneProps(Effects.SunRays, {
		"Intensity","Spread"
	}),
}

-- HANYA kumpulin property tweenable (skip bool / Enum)
local function buildTweenableGoal(instance, goal)
	local t = {}
	for k, v in pairs(goal) do
		if v ~= nil and k ~= "Technology" then
			local ok, current = pcall(function() return instance[k] end)
			if ok and current ~= nil then
				local valueType = typeof(current)
				-- TweenService aman untuk tipe numerik, Color3, Vector3, UDim, UDim2, CFrame, Rect, dsb
				if valueType ~= "boolean" and valueType ~= "EnumItem" then
					t[k] = v
				end
			end
		end
	end
	return t
end

local function tweenProps(instance, goal, customTime)
	local g = buildTweenableGoal(instance, goal)
	if next(g) == nil then return end
	local info = TweenInfo.new(customTime or TWEEN_TIME, EASING, EASEDIR)
	tweenService:Create(instance, info, g):Play()
end

local function liftAmbient(c3, min)
	local r = math.max((c3.R or 0) * 255, min) / 255
	local g = math.max((c3.G or 0) * 255, min) / 255
	local b = math.max((c3.B or 0) * 255, min) / 255
	return Color3.new(r,g,b)
end

local function getQualityLevelNumber()
	if not okUGS or not UserGameSettings then return nil end

	local props = {"QualityLevel","SavedQualityLevel"}
	for _, key in ipairs(props) do
		local ok, val = pcall(function() return UserGameSettings[key] end)
		if ok and val ~= nil then
			if typeof(val) == "EnumItem" then
				if val.Name == "Automatic" then
					return 8
				end
				local n = tonumber((tostring(val) or ""):match("(%d+)"))
				if n then return n end
			elseif typeof(val) == "number" then
				if val > 0 then return val end
			end
		end
	end
	return nil
end

----------------- VISUAL GUARD -----------------
local function visualGuard(doTween)
	local Lgoal = {}

	if lighting.Brightness < SAFE.MinBrightness then
		Lgoal.Brightness = SAFE.MinBrightness
	end

	if lighting.ExposureCompensation < SAFE.ExpMin
		or lighting.ExposureCompensation > SAFE.ExpMax
	then
		Lgoal.ExposureCompensation = math.clamp(
			lighting.ExposureCompensation,
			SAFE.ExpMin,
			SAFE.ExpMax
		)
	end

	local fs, fe = lighting.FogStart or 0, lighting.FogEnd or 1e9
	if fe - fs < SAFE.MinFogGap then
		Lgoal.FogEnd = fs + SAFE.MinFogGap
	end

	local t = lighting.ClockTime or 12
	if t >= 19 or t <= 5 then
		Lgoal.Ambient = liftAmbient(lighting.Ambient or Color3.new(), SAFE.MinAmbient)
	end

	if next(Lgoal) then
		if doTween then
			tweenProps(lighting, Lgoal)
		else
			for k,v in pairs(Lgoal) do
				lighting[k] = v
			end
		end
	end

	local Dgoal = {}
	if Effects.DOF.FarIntensity and Effects.DOF.FarIntensity > SAFE.MaxDOFFar then
		Dgoal.FarIntensity = SAFE.MaxDOFFar
	end
	if Effects.DOF.InFocusRadius and Effects.DOF.InFocusRadius < SAFE.MinInFocus then
		Dgoal.InFocusRadius = SAFE.MinInFocus
	end

	local q = getQualityLevelNumber() or 10
	if q >= SAFE.CrispQuality then
		if Effects.DOF.FarIntensity == nil or Effects.DOF.FarIntensity > SAFE.CrispFar then
			Dgoal.FarIntensity = SAFE.CrispFar
		end
		if Effects.DOF.NearIntensity and Effects.DOF.NearIntensity > 0 then
			Dgoal.NearIntensity = 0
		end
		if Effects.DOF.InFocusRadius and Effects.DOF.InFocusRadius < SAFE.CrispInFocus then
			Dgoal.InFocusRadius = SAFE.CrispInFocus
		end
		if Effects.DOF.FocusDistance and Effects.DOF.FocusDistance < SAFE.CrispFocus then
			Dgoal.FocusDistance = SAFE.CrispFocus
		end
	end

	if next(Dgoal) then
		if doTween then
			tweenProps(Effects.DOF, Dgoal)
		else
			for k,v in pairs(Dgoal) do
				Effects.DOF[k] = v
			end
		end
	end

	if Effects.Bloom.Threshold and Effects.Bloom.Threshold < SAFE.BloomThreshMin then
		if doTween then
			tweenProps(Effects.Bloom, {Threshold = SAFE.BloomThreshMin})
		else
			Effects.Bloom.Threshold = SAFE.BloomThreshMin
		end
	end

	if Effects.ColorCorrection.Brightness and Effects.ColorCorrection.Brightness < -0.06 then
		if doTween then
			tweenProps(Effects.ColorCorrection, {Brightness = -0.02})
		else
			Effects.ColorCorrection.Brightness = -0.02
		end
	end
end

----------------- APPLY PRESET -----------------
local currentPreset

local function applyPreset(p, doTween)
	if not p then return end
	currentPreset = p

	-- Lighting
	if p.Lighting then
		-- Technology nggak di-tween, di-set langsung saja
		if p.Lighting.Technology ~= nil then
			pcall(function() lighting.Technology = p.Lighting.Technology end)
		end

		if doTween ~= false then
			tweenProps(lighting, p.Lighting)
		else
			for k,v in pairs(p.Lighting) do
				if k ~= "Technology" then
					pcall(function() lighting[k] = v end)
				end
			end
		end
	end

	-- Atmosphere
	if p.Atmosphere then
		if doTween ~= false then
			tweenProps(Effects.Atmosphere, p.Atmosphere)
		else
			for k,v in pairs(p.Atmosphere) do
				pcall(function() Effects.Atmosphere[k] = v end)
			end
		end
	end

	-- ColorCorrection
	if p.Color then
		if doTween ~= false then
			tweenProps(Effects.ColorCorrection, p.Color)
		else
			for k,v in pairs(p.Color) do
				pcall(function() Effects.ColorCorrection[k] = v end)
			end
		end
	end

	-- Bloom
	if p.Bloom then
		if doTween ~= false then
			tweenProps(Effects.Bloom, p.Bloom)
		else
			for k,v in pairs(p.Bloom) do
				pcall(function() Effects.Bloom[k] = v end)
			end
		end
	end

	-- DOF
	if p.DOF then
		if doTween ~= false then
			tweenProps(Effects.DOF, p.DOF)
		else
			for k,v in pairs(p.DOF) do
				pcall(function() Effects.DOF[k] = v end)
			end
		end
	end

	-- SunRays
	if p.SunRays then
		if doTween ~= false then
			tweenProps(Effects.SunRays, p.SunRays)
		else
			for k,v in pairs(p.SunRays) do
				pcall(function() Effects.SunRays[k] = v end)
			end
		end
	end

	visualGuard(true)
end

local function resetAll()
	if initialSnapshot.Lighting and initialSnapshot.Lighting.Technology ~= nil then
		pcall(function() lighting.Technology = initialSnapshot.Lighting.Technology end)
	end

	applyPreset({
		Lighting   = initialSnapshot.Lighting,
		Atmosphere = initialSnapshot.Atmosphere,
		Color      = initialSnapshot.Color,
		Bloom      = initialSnapshot.Bloom,
		DOF        = initialSnapshot.DOF,
		SunRays    = initialSnapshot.SunRays,
	}, true)

	currentPreset = nil
end

----------------- PRESETS (dipersingkat tapi banyak) -----------------
-- NOTE: Tidak ada property boolean di sini yang ditween (GlobalShadows nggak dipaksa).
local PRESETS = {
	["Clear Day"] = {
		Lighting = {
			ClockTime = 12,
			Brightness = 3,
			ExposureCompensation = 0,
			EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1,
		},
		Atmosphere = {
			Density = 0.25,
			Offset  = 0,
			Color   = Color3.fromRGB(199,220,255),
			Decay   = Color3.fromRGB(104,124,155),
			Glare   = 0,
			Haze    = 1,
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
			Threshold = 1.0,
		},
		DOF = {
			FocusDistance = 200,
			InFocusRadius = 50,
			NearIntensity = 0,
			FarIntensity  = 0,
		},
		SunRays = {
			Intensity = 0.02,
			Spread    = 0.8,
		},
	},

	["Sunrise"] = {
		Lighting = {
			ClockTime = 6,
			Brightness = 2.2,
			ExposureCompensation = 0.1,
		},
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
		Bloom = {
			Intensity = 0.15,
			Size      = 18,
			Threshold = 0.95,
		},
		SunRays = {
			Intensity = 0.08,
			Spread    = 0.85,
		},
	},

	["Sunset"] = {
		Lighting = {
			ClockTime = 18.4,
			Brightness = 2.0,
			ExposureCompensation = 0.05,
		},
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
		Bloom = {
			Intensity = 0.2,
			Size      = 20,
			Threshold = 0.95,
		},
		SunRays = {
			Intensity = 0.1,
			Spread    = 0.9,
		},
	},

	["Moonlight"] = {
		Lighting = {
			ClockTime = 2.2,
			Brightness = 1.2,
			ExposureCompensation = -0.05,
		},
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
		Bloom = {
			Intensity = 0.08,
			Size      = 16,
			Threshold = 0.9,
		},
		DOF = {
			FocusDistance = 160,
			InFocusRadius = 30,
			NearIntensity = 0,
			FarIntensity  = 0.05,
		},
		SunRays = {
			Intensity = 0.02,
			Spread    = 0.7,
		},
	},

	["Storm"] = {
		Lighting = {
			ClockTime = 14,
			Brightness = 1.1,
			ExposureCompensation = -0.25,
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
		Bloom = {
			Intensity = 0.05,
			Size      = 10,
			Threshold = 1.0,
		},
		SunRays = {
			Intensity = 0,
			Spread    = 1,
		},
	},

	["Ocean Blue"] = {
		Lighting = {
			ClockTime = 11.3,
			Brightness = 2.6,
			ExposureCompensation = 0.05,
		},
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
		Bloom = {
			Intensity = 0.12,
			Size      = 14,
			Threshold = 0.97,
		},
		SunRays = {
			Intensity = 0.03,
			Spread    = 0.85,
		},
	},

	["Overcast"] = {
		Lighting = {
			ClockTime = 13,
			Brightness = 1.6,
			ExposureCompensation = -0.05,
		},
		Atmosphere = {
			Density = 0.55,
			Color   = Color3.fromRGB(190,195,205),
			Decay   = Color3.fromRGB(120,120,120),
			Glare   = 0,
			Haze    = 1.8,
		},
		Color = {
			Brightness = -0.01,
			Contrast   = 0.06,
			Saturation = -0.05,
			TintColor  = Color3.fromRGB(235,235,235),
		},
	},

	["Golden Hour"] = {
		Lighting = {
			ClockTime = 17.2,
			Brightness = 2.2,
			ExposureCompensation = 0.08,
		},
		Atmosphere = {
			Density = 0.32,
			Color   = Color3.fromRGB(255,200,120),
			Decay   = Color3.fromRGB(160,110,60),
			Glare   = 0.15,
			Haze    = 1.2,
		},
		Color = {
			Brightness = 0.02,
			Contrast   = 0.12,
			Saturation = 0.15,
			TintColor  = Color3.fromRGB(255,225,170),
		},
		SunRays = {
			Intensity = 0.12,
			Spread    = 0.88,
		},
		Bloom = {
			Intensity = 0.18,
			Size      = 20,
			Threshold = 0.94,
		},
	},

	["Aurora"] = {
		Lighting = {
			ClockTime = 0.8,
			Brightness = 1.2,
			ExposureCompensation = -0.05,
		},
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
		Bloom = {
			Intensity = 0.2,
			Size      = 20,
			Threshold = 0.9,
		},
	},

	["Alpine Morning"] = {
		Lighting = {
			ClockTime = 8.0,
			Brightness = 2.1,
			ExposureCompensation = 0.04,
		},
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
		Bloom = {
			Intensity = 0.12,
			Size      = 14,
			Threshold = 0.97,
		},
		SunRays = {
			Intensity = 0.1,
			Spread    = 0.88,
		},
	},

	["Autumn Amber"] = {
		Lighting = {
			ClockTime = 16.9,
			Brightness = 2.1,
			ExposureCompensation = 0.04,
		},
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
			Saturation = 0.1,
			TintColor  = Color3.fromRGB(255,225,185),
		},
		Bloom = {
			Intensity = 0.16,
			Size      = 18,
			Threshold = 0.95,
		},
	},

	["Sunrays"] = {
		Lighting = {
			ClockTime = 15.5,
			Brightness = 2.3,
			ExposureCompensation = 0.06,
		},
		Atmosphere = {
			Density = 0.3,
			Color   = Color3.fromRGB(240,225,200),
			Decay   = Color3.fromRGB(150,130,100),
			Glare   = 0.2,
			Haze    = 1.2,
		},
		Color = {
			Brightness = 0.02,
			Contrast   = 0.12,
			Saturation = 0.08,
			TintColor  = Color3.fromRGB(255,240,210),
		},
		SunRays = {
			Intensity = 0.25,
			Spread    = 0.92,
		},
		Bloom = {
			Intensity = 0.2,
			Size      = 20,
			Threshold = 0.93,
		},
	},

	-- (MASIH BANYAK – kamu bisa tambah preset lain di bawah ini
	--  pakai pattern yang sama; yang penting tipe datanya bener:
	--  angka / Color3, jangan boolean di-tween)
}

----------------- UI BUILD (4 kolom horizontal) -----------------
local Body = Instance.new("Frame")
Body.Name = "AxaWeatherBody"
Body.BackgroundTransparency = 1
Body.Size = UDim2.fromScale(1, 1)
Body.Parent = frame

local pad = Instance.new("UIPadding")
pad.Parent = Body
pad.PaddingTop    = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft   = UDim.new(0, 12)
pad.PaddingRight  = UDim.new(0, 12)

-- top bar
local TopRow = Instance.new("Frame")
TopRow.Name = "TopRow"
TopRow.BackgroundTransparency = 1
TopRow.Size = UDim2.new(1, 0, 0, 30)
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
TitleLabel.Size = UDim2.new(0, 180, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextColor3 = Color3.fromRGB(230,230,240)
TitleLabel.Text = "Weather Presets"
TitleLabel.LayoutOrder = 1
TitleLabel.Parent = TopRow

local HdButton = Instance.new("TextButton")
HdButton.Name = "HdButton"
HdButton.Size = UDim2.new(0, 70, 1, 0)
HdButton.BackgroundColor3 = Color3.fromRGB(55,55,65)
HdButton.AutoButtonColor = true
HdButton.Font = Enum.Font.GothamSemibold
HdButton.TextSize = 13
HdButton.TextColor3 = Color3.fromRGB(240,240,250)
HdButton.Text = "HD"
HdButton.LayoutOrder = 2
HdButton.Parent = TopRow

local HdCorner = Instance.new("UICorner")
HdCorner.CornerRadius = UDim.new(0, 8)
HdCorner.Parent = HdButton

local ResetButton = Instance.new("TextButton")
ResetButton.Name = "ResetButton"
ResetButton.Size = UDim2.new(0, 80, 1, 0)
ResetButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
ResetButton.AutoButtonColor = true
ResetButton.Font = Enum.Font.GothamSemibold
ResetButton.TextSize = 13
ResetButton.TextColor3 = Color3.fromRGB(220, 220, 230)
ResetButton.Text = "Reset"
ResetButton.LayoutOrder = 3
ResetButton.Parent = TopRow

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 8)
ResetCorner.Parent = ResetButton

local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
Divider.BorderSizePixel = 0
Divider.AnchorPoint = Vector2.new(0.5, 0)
Divider.Position = UDim2.new(0.5, 0, 0, 34)
Divider.Size = UDim2.new(1, -4, 0, 1)
Divider.Parent = Body

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
ListPadding.PaddingLeft = UDim.new(0, 2)
ListPadding.PaddingRight = UDim.new(0, 2)

local GridLayout = Instance.new("UIGridLayout")
GridLayout.Parent = ListFrame
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.FillDirection = Enum.FillDirection.Horizontal
GridLayout.FillDirectionMaxCells = 4 -- 4 tombol per baris
GridLayout.CellPadding = UDim2.fromOffset(6, 6)
GridLayout.CellSize = UDim2.new(0.25, -8, 0, 30)

----------------- HD MODE -----------------
local isHD = false
local hdSnapshot = nil

local function styleHd(active)
	tweenService:Create(HdButton, TweenInfo.new(0.15), {
		BackgroundColor3 = active and Color3.fromRGB(90, 140, 255) or Color3.fromRGB(55,55,65),
		TextColor3 = active and Color3.fromRGB(15, 20, 35) or Color3.fromRGB(240,240,250)
	}):Play()
	HdButton.Text = active and "HD On" or "HD"
end

local function supportsFuture()
	local ok = pcall(function()
		lighting.Technology = Enum.Technology.Future
	end)
	return ok and lighting.Technology == Enum.Technology.Future
end

local function setHD(state)
	if state and not isHD then
		-- snapshot sebelum HD
		hdSnapshot = {
			Lighting = cloneProps(lighting, {
				"EnvironmentDiffuseScale","EnvironmentSpecularScale",
				"ExposureCompensation","Technology","Ambient","Brightness"
			}),
			Color   = cloneProps(Effects.ColorCorrection, {
				"Brightness","Contrast","Saturation","TintColor"
			}),
			Bloom   = cloneProps(Effects.Bloom, {
				"Intensity","Size","Threshold"
			}),
			DOF     = cloneProps(Effects.DOF, {
				"FocusDistance","InFocusRadius","NearIntensity","FarIntensity"
			}),
			SunRays = cloneProps(Effects.SunRays, {
				"Intensity","Spread"
			}),
			Atmos   = cloneProps(Effects.Atmosphere, {
				"Density","Haze","Glare"
			}),
		}

		if supportsFuture() then
			tweenProps(lighting, {
				EnvironmentDiffuseScale  = math.min(1.2, (lighting.EnvironmentDiffuseScale or 1) * 1.12),
				EnvironmentSpecularScale = math.min(1.2, (lighting.EnvironmentSpecularScale or 1) * 1.12),
				ExposureCompensation     = math.clamp((lighting.ExposureCompensation or 0) + 0.04, SAFE.ExpMin, SAFE.ExpMax),
			})
		end

		tweenProps(Effects.ColorCorrection, {
			Contrast   = (Effects.ColorCorrection.Contrast or 0) + 0.14,
			Saturation = (Effects.ColorCorrection.Saturation or 0) + 0.10,
			Brightness = math.clamp((Effects.ColorCorrection.Brightness or 0) + 0.01, -0.02, 0.12),
		})

		tweenProps(Effects.Bloom, {
			Intensity = math.min(1, (Effects.Bloom.Intensity or 0.12) * 1.25),
			Size      = (Effects.Bloom.Size or 14) + 3,
			Threshold = math.max(SAFE.BloomThreshMin, (Effects.Bloom.Threshold or 0.97) - 0.03),
		})

		tweenProps(Effects.DOF, {
			InFocusRadius = math.max(SAFE.MinInFocus, (Effects.DOF.InFocusRadius or 50) + 8),
			FarIntensity  = math.min(SAFE.MaxDOFFar, (Effects.DOF.FarIntensity or 0) + 0.02),
		})

		tweenProps(Effects.SunRays, {
			Intensity = math.clamp((Effects.SunRays.Intensity or 0.02) + 0.02, 0, 1)
		})

		tweenProps(Effects.Atmosphere, {
			Density = math.clamp((Effects.Atmosphere.Density or 0.25) + 0.04, 0, 1),
			Haze    = (Effects.Atmosphere.Haze or 1.0) + 0.15,
			Glare   = math.clamp((Effects.Atmosphere.Glare or 0.05) + 0.04, 0, 1),
		})

		visualGuard(true)
		isHD = true
		styleHd(true)

	elseif (not state) and isHD then
		if hdSnapshot then
			pcall(function()
				if hdSnapshot.Lighting and hdSnapshot.Lighting.Technology ~= nil then
					lighting.Technology = hdSnapshot.Lighting.Technology
				end
			end)

			applyPreset({
				Lighting   = hdSnapshot.Lighting,
				Color      = hdSnapshot.Color,
				Bloom      = hdSnapshot.Bloom,
				DOF        = hdSnapshot.DOF,
				SunRays    = hdSnapshot.SunRays,
				Atmosphere = hdSnapshot.Atmos,
			}, true)
		end

		isHD = false
		styleHd(false)
	end
end

styleHd(false)

HdButton.MouseButton1Click:Connect(function()
	setHD(not isHD)
end)

ResetButton.MouseButton1Click:Connect(function()
	if isHD then
		setHD(false)
	end
	resetAll()
end)

----------------- GENERATE BUTTON 4 KOLOM -----------------
local function createPresetButton(name, order)
	local btn = Instance.new("TextButton")
	btn.Name = "Preset_" .. name
	btn.LayoutOrder = order or 0
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 12
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
		applyPreset(PRESETS[name], true)
	end)
end

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

----------------- QUALITY LISTENER -----------------
if okUGS and UserGameSettings then
	local function onQualityChanged()
		if currentPreset then
			applyPreset(currentPreset, true)
		else
			visualGuard(true)
		end
	end

	pcall(function()
		UserGameSettings:GetPropertyChangedSignal("QualityLevel"):Connect(onQualityChanged)
	end)
	pcall(function()
		UserGameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(onQualityChanged)
	end)
end

-- Guard awal
visualGuard(true)

--==========================================================
-- Selesai:
-- - UI ngikut CORE: TAB_FRAME
-- - Tombol preset 4 kolom horizontal + scroll ke bawah
-- - HD & Reset jalan
-- - Tween aman (nggak ngetween bool/Enum, nggak spam error)
--==========================================================
