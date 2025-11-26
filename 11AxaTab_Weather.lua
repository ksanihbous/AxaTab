--==========================================================
--  11AxaTab_Weather.lua
--  TAB 11 - Weather (Lighting / Atmosphere Presets) by Axa
--  Dipanggil via loadstring dari CORE AxaHub
--  Env dari CORE:
--    TAB_FRAME, TAB_ID
--    Players, LocalPlayer, RunService, TweenService, HttpService,
--    UserInputService, VirtualInputManager, ContextActionService,
--    StarterGui, CoreGui, Camera, SetActiveTab, AXA_TWEEN (opsional)
--==========================================================

local frame        = TAB_FRAME
local player       = LocalPlayer
local players      = Players
local runService   = RunService
local tweenService = TweenService
local starterGui   = StarterGui

local Lighting = game:GetService("Lighting")

-- pakai env TweenService kalau ada, fallback kalau tidak
local TweenService = tweenService or game:GetService("TweenService")

--==========================================================
--  PANTAU GRAPHICS QUALITY
--==========================================================
local okUGS, UserGameSettings = pcall(function()
	return UserSettings():GetService("UserGameSettings")
end)

--==========================================================
--  CONFIG & GUARD
--==========================================================
local TWEEN_TIME = 0.9
local EASING  = Enum.EasingStyle.Quad
local EASEDIR = Enum.EasingDirection.Out

-- Batas aman global
local SAFE = {
	MinBrightness = 1.0,
	ExpMin = -0.08,
	ExpMax = 0.15,
	MinAmbient = 22,
	MinFogGap = 150,
	MaxDOFFar = 0.10,
	MinInFocus = 28,
	BloomThreshMin = 0.82,
	CrispQuality = 8,
	CrispFar = 0.02,
	CrispFocus = 20000,
	CrispInFocus = 10000,
}

--==========================================================
--  HELPERS LIGHTING
--==========================================================
local function ensure(name, className, parent)
	parent = parent or Lighting
	local obj = parent:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = parent
	end
	return obj
end

local Effects = {
	Atmosphere      = ensure("_RTX_Atmosphere","Atmosphere"),
	ColorCorrection = ensure("_RTX_Color","ColorCorrectionEffect"),
	Bloom           = ensure("_RTX_Bloom","BloomEffect"),
	DOF             = ensure("_RTX_DOF","DepthOfFieldEffect"),
	SunRays         = ensure("_RTX_SunRays","SunRaysEffect"),
	Sky             = ensure("_RTX_Sky","Sky"),
}

-- Pastikan efek aktif
Effects.Bloom.Enabled           = true
Effects.DOF.Enabled             = true
Effects.SunRays.Enabled         = true
Effects.ColorCorrection.Enabled = true

-- Kosongkan skybox (biar map aslinya bisa override kalau mau)
Effects.Sky.SkyboxBk = ""
Effects.Sky.SkyboxDn = ""
Effects.Sky.SkyboxFt = ""
Effects.Sky.SkyboxLf = ""
Effects.Sky.SkyboxRt = ""
Effects.Sky.SkyboxUp = ""

-- Snapshot util
local function cloneProps(instance, props)
	local t = {}
	for _, p in ipairs(props) do
		local ok, val = pcall(function()
			return instance[p]
		end)
		if ok then
			t[p] = val
		end
	end
	return t
end

local initialSnapshot = {
	Lighting   = cloneProps(Lighting, {
		"ClockTime","Brightness","Ambient","EnvironmentDiffuseScale",
		"EnvironmentSpecularScale","GlobalShadows","ExposureCompensation",
		"FogEnd","FogStart","FogColor","Technology"
	}),
	Atmosphere = cloneProps(Effects.Atmosphere, {"Density","Offset","Color","Decay","Glare","Haze"}),
	Color      = cloneProps(Effects.ColorCorrection,{"Brightness","Contrast","Saturation","TintColor"}),
	Bloom      = cloneProps(Effects.Bloom,{"Intensity","Size","Threshold"}),
	DOF        = cloneProps(Effects.DOF,{"FocusDistance","InFocusRadius","NearIntensity","FarIntensity"}),
	SunRays    = cloneProps(Effects.SunRays,{"Intensity","Spread"}),
}

local function buildTweenableGoal(instance, goal)
	local t = {}
	for k, v in pairs(goal) do
		if v ~= nil and k ~= "Technology" then
			local ok = pcall(function()
				return instance[k]
			end)
			if ok then
				t[k] = v
			end
		end
	end
	return t
end

local function tweenProps(instance, goal, customTime)
	local g = buildTweenableGoal(instance, goal)
	if next(g) == nil then
		return
	end
	local info = TweenInfo.new(customTime or TWEEN_TIME, EASING, EASEDIR)
	TweenService:Create(instance, info, g):Play()
end

-- Ambience helper
local function liftAmbient(c3, min)
	local r = math.max((c3.R or 0)*255, min)/255
	local g = math.max((c3.G or 0)*255, min)/255
	local b = math.max((c3.B or 0)*255, min)/255
	return Color3.new(r,g,b)
end

-- Baca level kualitas
local function getQualityLevelNumber()
	if not okUGS or not UserGameSettings then
		return nil
	end
	local props = {"QualityLevel","SavedQualityLevel"}
	for _,key in ipairs(props) do
		local ok2, val = pcall(function()
			return UserGameSettings[key]
		end)
		if ok2 and val ~= nil then
			if typeof(val) == "EnumItem" then
				if val.Name == "Automatic" then
					return 8
				end
				local n = tonumber((tostring(val) or ""):match("(%d+)"))
				if n then
					return n
				end
			elseif typeof(val) == "number" then
				if val > 0 then
					return val
				end
			end
		end
	end
	return nil
end

-- GUARD
local function visualGuard(doTween)
	local Lgoal = {}

	if Lighting.Brightness < SAFE.MinBrightness then
		Lgoal.Brightness = SAFE.MinBrightness
	end

	if Lighting.ExposureCompensation < SAFE.ExpMin or Lighting.ExposureCompensation > SAFE.ExpMax then
		Lgoal.ExposureCompensation = math.clamp(Lighting.ExposureCompensation, SAFE.ExpMin, SAFE.ExpMax)
	end

	local fs, fe = Lighting.FogStart or 0, Lighting.FogEnd or 1e9
	if fe - fs < SAFE.MinFogGap then
		Lgoal.FogEnd = fs + SAFE.MinFogGap
	end

	local t = Lighting.ClockTime or 12
	if t >= 19 or t <= 5 then
		Lgoal.Ambient = liftAmbient(Lighting.Ambient or Color3.new(), SAFE.MinAmbient)
	end

	if next(Lgoal) then
		if doTween then
			tweenProps(Lighting, Lgoal)
		else
			for k,v in pairs(Lgoal) do
				Lighting[k] = v
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

--==========================================================
--  APPLY / RESET PRESET
--==========================================================
local currentPreset

local function applyPreset(p, doTween)
	if not p then
		return
	end
	currentPreset = p

	if p.Lighting then
		if p.Lighting.Technology ~= nil then
			pcall(function()
				Lighting.Technology = p.Lighting.Technology
			end)
		end

		if doTween ~= false then
			tweenProps(Lighting, p.Lighting)
		else
			for k,v in pairs(buildTweenableGoal(Lighting, p.Lighting)) do
				Lighting[k] = v
			end
		end
	end

	local function applyEffect(inst, goal)
		if not goal then
			return
		end
		if doTween ~= false then
			tweenProps(inst, goal)
		else
			for k,v in pairs(buildTweenableGoal(inst, goal)) do
				inst[k] = v
			end
		end
	end

	applyEffect(Effects.Atmosphere,      p.Atmosphere)
	applyEffect(Effects.ColorCorrection, p.Color)
	applyEffect(Effects.Bloom,           p.Bloom)
	applyEffect(Effects.DOF,             p.DOF)
	applyEffect(Effects.SunRays,         p.SunRays)

	visualGuard(true)
end

local function resetAll()
	if initialSnapshot.Lighting and initialSnapshot.Lighting.Technology ~= nil then
		pcall(function()
			Lighting.Technology = initialSnapshot.Lighting.Technology
		end)
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

--==========================================================
--  PRESETS (copied dari script Weather-mu)
--==========================================================
local PRESETS = {
	["Clear Day"] = {
		Lighting={ClockTime=12, Brightness=3, ExposureCompensation=0, GlobalShadows=true, EnvironmentDiffuseScale=1, EnvironmentSpecularScale=1},
		Atmosphere={Density=0.25, Offset=0, Color=Color3.fromRGB(199,220,255), Decay=Color3.fromRGB(104,124,155), Glare=0, Haze=1},
		Color={Brightness=0, Contrast=0.05, Saturation=0.05, TintColor=Color3.fromRGB(255,255,255)},
		Bloom={Intensity=0.1, Size=12, Threshold=1.0},
		DOF={FocusDistance=200, InFocusRadius=50, NearIntensity=0, FarIntensity=0},
		SunRays={Intensity=0.02, Spread=0.8}
	},
	["Sunrise"] = {
		Lighting={ClockTime=6, Brightness=2.2, ExposureCompensation=0.1},
		Atmosphere={Density=0.35, Color=Color3.fromRGB(255,198,150), Decay=Color3.fromRGB(140,90,60), Glare=0.2, Haze=1.5},
		Color={Brightness=0.02, Contrast=0.1, Saturation=0.1, TintColor=Color3.fromRGB(255,220,200)},
		Bloom={Intensity=0.15, Size=18, Threshold=0.95},
		SunRays={Intensity=0.08, Spread=0.85}
	},
	["Sunset"] = {
		Lighting={ClockTime=18.4, Brightness=2.0, ExposureCompensation=0.05},
		Atmosphere={Density=0.38, Color=Color3.fromRGB(255,170,120), Decay=Color3.fromRGB(120,70,50), Glare=0.25, Haze=1.6},
		Color={Brightness=0, Contrast=0.12, Saturation=0.12, TintColor=Color3.fromRGB(255,210,170)},
		Bloom={Intensity=0.2, Size=20, Threshold=0.95},
		SunRays={Intensity=0.1, Spread=0.9}
	},
	["Moonlight"] = {
		Lighting={ClockTime=2.2, Brightness=1.2, ExposureCompensation=-0.05, GlobalShadows=true},
		Atmosphere={Density=0.3, Color=Color3.fromRGB(170,190,220), Decay=Color3.fromRGB(70,85,110), Glare=0, Haze=0.8},
		Color={Brightness=-0.02, Contrast=0.08, Saturation=-0.05, TintColor=Color3.fromRGB(190,210,255)},
		Bloom={Intensity=0.08, Size=16, Threshold=0.9},
		DOF={FocusDistance=160, InFocusRadius=30, NearIntensity=0, FarIntensity=0.05},
		SunRays={Intensity=0.02, Spread=0.7}
	},
	["Storm"] = {
		Lighting={ClockTime=14, Brightness=1.1, ExposureCompensation=-0.25, GlobalShadows=true, FogStart=0, FogEnd=350, FogColor=Color3.fromRGB(80,85,95)},
		Atmosphere={Density=0.7, Color=Color3.fromRGB(130,145,160), Decay=Color3.fromRGB(60,65,70), Glare=0.1, Haze=2.2},
		Color={Brightness=-0.08, Contrast=0.15, Saturation=-0.1, TintColor=Color3.fromRGB(210,220,230)},
		Bloom={Intensity=0.05, Size=10, Threshold=1.0},
		SunRays={Intensity=0, Spread=1}
	},
	["Ocean Blue"] = {
		Lighting={ClockTime=11.3, Brightness=2.6, ExposureCompensation=0.05},
		Atmosphere={Density=0.28, Color=Color3.fromRGB(150,200,255), Decay=Color3.fromRGB(60,120,180), Glare=0.05, Haze=1.0},
		Color={Brightness=0.02, Contrast=0.06, Saturation=0.1, TintColor=Color3.fromRGB(200,230,255)},
		Bloom={Intensity=0.12, Size=14, Threshold=0.97},
		SunRays={Intensity=0.03, Spread=0.85}
	},
	["Overcast"] = {
		Lighting={ClockTime=13, Brightness=1.6, ExposureCompensation=-0.05},
		Atmosphere={Density=0.55, Color=Color3.fromRGB(190,195,205), Decay=Color3.fromRGB(120,120,120), Glare=0, Haze=1.8},
		Color={Brightness=-0.01, Contrast=0.06, Saturation=-0.05, TintColor=Color3.fromRGB(235,235,235)}
	},
	["Golden Hour"] = {
		Lighting={ClockTime=17.2, Brightness=2.2, ExposureCompensation=0.08},
		Atmosphere={Density=0.32, Color=Color3.fromRGB(255,200,120), Decay=Color3.fromRGB(160,110,60), Glare=0.15, Haze=1.2},
		Color={Brightness=0.02, Contrast=0.12, Saturation=0.15, TintColor=Color3.fromRGB(255,225,170)},
		SunRays={Intensity=0.12, Spread=0.88},
		Bloom={Intensity=0.18, Size=20, Threshold=0.94}
	},
	["Midnight Neon"] = {
		Lighting={ClockTime=1.2, Brightness=1.0, ExposureCompensation=-0.1},
		Atmosphere={Density=0.25, Color=Color3.fromRGB(180,200,255), Decay=Color3.fromRGB(70,90,140), Glare=0.05, Haze=0.9},
		Color={Brightness=0.02, Contrast=0.12, Saturation=0.25, TintColor=Color3.fromRGB(190,255,245)},
		Bloom={Intensity=0.28, Size=22, Threshold=0.86},
		DOF={FocusDistance=120, InFocusRadius=20, NearIntensity=0, FarIntensity=0.06}
	},
	["Foggy"] = {
		Lighting={ClockTime=9.5, Brightness=1.5, ExposureCompensation=-0.05, FogStart=0, FogEnd=180, FogColor=Color3.fromRGB(200,205,210)},
		Atmosphere={Density=0.9, Color=Color3.fromRGB(210,215,220), Decay=Color3.fromRGB(180,185,190), Glare=0, Haze=3.0},
		Color={Brightness=0, Contrast=-0.03, Saturation=-0.1, TintColor=Color3.fromRGB(230,235,240)}
	},
	["Sandstorm"] = {
		Lighting={ClockTime=15, Brightness=1.4, ExposureCompensation=-0.15, FogStart=0, FogEnd=220, FogColor=Color3.fromRGB(210,180,120)},
		Atmosphere={Density=0.85, Color=Color3.fromRGB(240,200,130), Decay=Color3.fromRGB(170,130,70), Glare=0.05, Haze=2.8},
		Color={Brightness=-0.02, Contrast=0.08, Saturation=-0.05, TintColor=Color3.fromRGB(255,230,180)}
	},
	["Rainy Night"] = {
		Lighting={ClockTime=23, Brightness=0.9, ExposureCompensation=-0.25, FogStart=0, FogEnd=300, FogColor=Color3.fromRGB(90,100,120)},
		Atmosphere={Density=0.65, Color=Color3.fromRGB(150,170,200), Decay=Color3.fromRGB(80,90,110), Glare=0.05, Haze=2.0},
		Color={Brightness=-0.05, Contrast=0.1, Saturation=-0.05, TintColor=Color3.fromRGB(220,230,240)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.92}
	},
	["Blizzard"] = {
		Lighting={ClockTime=13, Brightness=2.0, ExposureCompensation=-0.1, FogStart=0, FogEnd=160, FogColor=Color3.fromRGB(230,235,240)},
		Atmosphere={Density=1.0, Color=Color3.fromRGB(235,240,255), Decay=Color3.fromRGB(210,220,240), Glare=0, Haze=3.2},
		Color={Brightness=0.02, Contrast=0.1, Saturation=-0.15, TintColor=Color3.fromRGB(240,245,255)}
	},
	["Aurora"] = {
		Lighting={ClockTime=0.8, Brightness=1.2, ExposureCompensation=-0.05},
		Atmosphere={Density=0.35, Color=Color3.fromRGB(180,220,200), Decay=Color3.fromRGB(60,100,90), Glare=0.1, Haze=1.2},
		Color={Brightness=0.02, Contrast=0.1, Saturation=0.2, TintColor=Color3.fromRGB(200,255,220)},
		Bloom={Intensity=0.2, Size=20, Threshold=0.9}
	},
	["Godrays Forest"] = {
		Lighting={ClockTime=15.5, Brightness=2.2, ExposureCompensation=0.05},
		Atmosphere={Density=0.4, Color=Color3.fromRGB(220,235,210), Decay=Color3.fromRGB(120,140,110), Glare=0.2, Haze=1.6},
		Color={Brightness=0.02, Contrast=0.08, Saturation=0.08, TintColor=Color3.fromRGB(235,245,230)},
		SunRays={Intensity=0.2, Spread=0.92}
	},
	["Heatwave"] = {
		Lighting={ClockTime=13.3, Brightness=2.8, ExposureCompensation=0.15},
		Atmosphere={Density=0.22, Color=Color3.fromRGB(255,220,170), Decay=Color3.fromRGB(200,150,90), Glare=0.2, Haze=1.0},
		Color={Brightness=0.03, Contrast=0.12, Saturation=0.06, TintColor=Color3.fromRGB(255,235,200)},
		Bloom={Intensity=0.24, Size=22, Threshold=0.94}
	},
	["Cyberpunk Night"] = {
		Lighting={ClockTime=0.2, Brightness=1.1, ExposureCompensation=-0.05},
		Atmosphere={Density=0.3, Color=Color3.fromRGB(150,200,255), Decay=Color3.fromRGB(80,70,120), Glare=0.15, Haze=1.1},
		Color={Brightness=0.03, Contrast=0.18, Saturation=0.35, TintColor=Color3.fromRGB(210,210,255)},
		Bloom={Intensity=0.32, Size=24, Threshold=0.85}
	},
	["Tropical Noon"] = {
		Lighting={ClockTime=12.5, Brightness=3.0, ExposureCompensation=0.08, GlobalShadows=true, EnvironmentDiffuseScale=1.1, EnvironmentSpecularScale=1.1},
		Atmosphere={Density=0.22, Offset=0, Color=Color3.fromRGB(210,235,255), Decay=Color3.fromRGB(110,150,200), Glare=0.05, Haze=0.9},
		Color={Brightness=0.01, Contrast=0.08, Saturation=0.12, TintColor=Color3.fromRGB(255,255,255)},
		Bloom={Intensity=0.14, Size=16, Threshold=0.96},
		SunRays={Intensity=0.07, Spread=0.86}
	},
	["Dawn Mist"] = {
		Lighting={ClockTime=5.2, Brightness=1.8, ExposureCompensation=-0.02},
		Atmosphere={Density=0.75, Color=Color3.fromRGB(235,225,215), Decay=Color3.fromRGB(200,190,180), Glare=0.0, Haze=2.6},
		Color={Brightness=0, Contrast=-0.02, Saturation=-0.06, TintColor=Color3.fromRGB(245,235,230)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.98},
		SunRays={Intensity=0.03, Spread=0.9}
	},
	["Dusk Violet"] = {
		Lighting={ClockTime=18.9, Brightness=1.9, ExposureCompensation=0.02},
		Atmosphere={Density=0.34, Color=Color3.fromRGB(220,180,255), Decay=Color3.fromRGB(120,90,150), Glare=0.12, Haze=1.4},
		Color={Brightness=0.01, Contrast=0.14, Saturation=0.16, TintColor=Color3.fromRGB(240,210,255)},
		Bloom={Intensity=0.18, Size=20, Threshold=0.93},
		SunRays={Intensity=0.09, Spread=0.92}
	},
	["Monsoon Grey"] = {
		Lighting={ClockTime=15.0, Brightness=1.3, ExposureCompensation=-0.18, FogStart=0, FogEnd=280, FogColor=Color3.fromRGB(120,130,140)},
		Atmosphere={Density=0.8, Color=Color3.fromRGB(170,180,190), Decay=Color3.fromRGB(100,105,110), Glare=0.02, Haze=2.4},
		Color={Brightness=-0.04, Contrast=0.1, Saturation=-0.08, TintColor=Color3.fromRGB(225,230,235)},
		Bloom={Intensity=0.05, Size=12, Threshold=0.99},
		SunRays={Intensity=0.0, Spread=1}
	},
	["High Noon Harsh"] = {
		Lighting={ClockTime=12.0, Brightness=3.2, ExposureCompensation=0.12},
		Atmosphere={Density=0.18, Color=Color3.fromRGB(235,245,255), Decay=Color3.fromRGB(130,150,170), Glare=0.02, Haze=0.7},
		Color={Brightness=0, Contrast=0.06, Saturation=0.02, TintColor=Color3.fromRGB(255,255,255)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.99},
		SunRays={Intensity=0.03, Spread=0.82}
	},
	["Winter Overcast"] = {
		Lighting={ClockTime=13.0, Brightness=1.6, ExposureCompensation=-0.06},
		Atmosphere={Density=0.58, Color=Color3.fromRGB(220,230,245), Decay=Color3.fromRGB(170,180,200), Glare=0, Haze=1.9},
		Color={Brightness=0.0, Contrast=0.06, Saturation=-0.12, TintColor=Color3.fromRGB(235,240,255)},
		Bloom={Intensity=0.05, Size=10, Threshold=0.98}
	},
	["Desert Evening"] = {
		Lighting={ClockTime=17.8, Brightness=1.9, ExposureCompensation=0.02, FogStart=0, FogEnd=240, FogColor=Color3.fromRGB(230,190,130)},
		Atmosphere={Density=0.62, Color=Color3.fromRGB(245,205,140), Decay=Color3.fromRGB(180,130,70), Glare=0.08, Haze=2.2},
		Color={Brightness=0.01, Contrast=0.1, Saturation=0.08, TintColor=Color3.fromRGB(255,230,185)},
		Bloom={Intensity=0.16, Size=18, Threshold=0.95},
		SunRays={Intensity=0.12, Spread=0.9}
	},
	["Alpine Morning"] = {
		Lighting={ClockTime=8.0, Brightness=2.1, ExposureCompensation=0.04, GlobalShadows=true},
		Atmosphere={Density=0.26, Color=Color3.fromRGB(205,230,255), Decay=Color3.fromRGB(140,170,200), Glare=0.04, Haze=0.95},
		Color={Brightness=0.01, Contrast=0.08, Saturation=0.06, TintColor=Color3.fromRGB(235,245,255)},
		Bloom={Intensity=0.12, Size=14, Threshold=0.97},
		SunRays={Intensity=0.1, Spread=0.88}
	},
	["City Haze"] = {
		Lighting={ClockTime=16.0, Brightness=1.7, ExposureCompensation=-0.04, FogStart=0, FogEnd=260, FogColor=Color3.fromRGB(160,170,180)},
		Atmosphere={Density=0.7, Color=Color3.fromRGB(200,205,210), Decay=Color3.fromRGB(150,155,160), Glare=0.02, Haze=2.1},
		Color={Brightness=-0.01, Contrast=0.08, Saturation=-0.04, TintColor=Color3.fromRGB(235,235,235)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.97}
	},
	["Marine Layer"] = {
		Lighting={ClockTime=10.3, Brightness=1.8, ExposureCompensation=-0.02, FogStart=0, FogEnd=200, FogColor=Color3.fromRGB(210,220,230)},
		Atmosphere={Density=0.88, Color=Color3.fromRGB(225,230,240), Decay=Color3.fromRGB(200,205,215), Glare=0.0, Haze=2.9},
		Color={Brightness=0.0, Contrast=-0.02, Saturation=-0.08, TintColor=Color3.fromRGB(235,240,245)},
		Bloom={Intensity=0.04, Size=10, Threshold=0.99}
	},
	["Polar Twilight"] = {
		Lighting={ClockTime=22.4, Brightness=1.15, ExposureCompensation=-0.08, GlobalShadows=true},
		Atmosphere={Density=0.36, Color=Color3.fromRGB(205,225,255), Decay=Color3.fromRGB(120,150,190), Glare=0.06, Haze=1.1},
		Color={Brightness=0.0, Contrast=0.12, Saturation=-0.02, TintColor=Color3.fromRGB(220,235,255)},
		Bloom={Intensity=0.12, Size=18, Threshold=0.92},
		SunRays={Intensity=0.03, Spread=0.86}
	},
	["Meadow Spring"] = {
		Lighting={ClockTime=9.8, Brightness=2.5, ExposureCompensation=0.06},
		Atmosphere={Density=0.24, Color=Color3.fromRGB(225,245,230), Decay=Color3.fromRGB(140,185,150), Glare=0.04, Haze=0.9},
		Color={Brightness=0.02, Contrast=0.08, Saturation=0.12, TintColor=Color3.fromRGB(240,255,240)},
		Bloom={Intensity=0.14, Size=16, Threshold=0.96},
		SunRays={Intensity=0.09, Spread=0.88}
	},
	["Overcast Drizzle"] = {
		Lighting={ClockTime=14.2, Brightness=1.4, ExposureCompensation=-0.12, FogStart=0, FogEnd=300, FogColor=Color3.fromRGB(155,165,175)},
		Atmosphere={Density=0.76, Color=Color3.fromRGB(190,200,210), Decay=Color3.fromRGB(130,135,145), Glare=0.0, Haze=2.3},
		Color={Brightness=-0.02, Contrast=0.08, Saturation=-0.08, TintColor=Color3.fromRGB(230,235,240)},
		Bloom={Intensity=0.04, Size=10, Threshold=0.99}
	},
	["Sunshower"] = {
		Lighting={ClockTime=16.5, Brightness=2.0, ExposureCompensation=0.02, FogStart=0, FogEnd=360, FogColor=Color3.fromRGB(180,190,205)},
		Atmosphere={Density=0.52, Color=Color3.fromRGB(205,215,230), Decay=Color3.fromRGB(130,140,155), Glare=0.02, Haze=1.6},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.06, TintColor=Color3.fromRGB(245,245,255)},
		Bloom={Intensity=0.18, Size=20, Threshold=0.94},
		SunRays={Intensity=0.16, Spread=0.94}
	},
	["Autumn Amber"] = {
		Lighting={ClockTime=16.9, Brightness=2.1, ExposureCompensation=0.04},
		Atmosphere={Density=0.33, Color=Color3.fromRGB(255,210,155), Decay=Color3.fromRGB(165,110,60), Glare=0.1, Haze=1.2},
		Color={Brightness=0.01, Contrast=0.14, Saturation=0.1, TintColor=Color3.fromRGB(255,225,185)},
		Bloom={Intensity=0.16, Size=18, Threshold=0.95}
	},
	["Midnight Overcast"] = {
		Lighting={ClockTime=0.6, Brightness=1.0, ExposureCompensation=-0.14, FogStart=0, FogEnd=320, FogColor=Color3.fromRGB(95,105,120)},
		Atmosphere={Density=0.68, Color=Color3.fromRGB(160,175,195), Decay=Color3.fromRGB(90,100,115), Glare=0, Haze=2.0},
		Color={Brightness=-0.04, Contrast=0.1, Saturation=-0.06, TintColor=Color3.fromRGB(220,230,240)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.93}
	},
	["Volcanic Ash"] = {
		Lighting={ClockTime=15.6, Brightness=1.2, ExposureCompensation=-0.22, FogStart=0, FogEnd=220, FogColor=Color3.fromRGB(90,85,80)},
		Atmosphere={Density=0.92, Color=Color3.fromRGB(120,110,105), Decay=Color3.fromRGB(80,70,65), Glare=0.0, Haze=3.2},
		Color={Brightness=-0.06, Contrast=0.14, Saturation=-0.18, TintColor=Color3.fromRGB(210,200,190)},
		Bloom={Intensity=0.02, Size=8, Threshold=1.0}
	},
	["Coastal Pink"] = {
		Lighting={ClockTime=18.2, Brightness=2.0, ExposureCompensation=0.02},
		Atmosphere={Density=0.28, Color=Color3.fromRGB(255,205,220), Decay=Color3.fromRGB(160,120,140), Glare=0.08, Haze=1.1},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.18, TintColor=Color3.fromRGB(255,220,230)},
		Bloom={Intensity=0.2, Size=20, Threshold=0.92},
		SunRays={Intensity=0.12, Spread=0.9}
	},
	["Arctic Blue Hour"] = {
		Lighting={ClockTime=3.8, Brightness=1.3, ExposureCompensation=-0.02},
		Atmosphere={Density=0.3, Color=Color3.fromRGB(200,220,255), Decay=Color3.fromRGB(110,140,190), Glare=0.06, Haze=1.0},
		Color={Brightness=0.0, Contrast=0.1, Saturation=-0.04, TintColor=Color3.fromRGB(225,235,255)},
		Bloom={Intensity=0.1, Size=16, Threshold=0.94}
	},
	["Savannah Dust"] = {
		Lighting={ClockTime=16.1, Brightness=2.3, ExposureCompensation=0.0, FogStart=0, FogEnd=260, FogColor=Color3.fromRGB(215,190,140)},
		Atmosphere={Density=0.64, Color=Color3.fromRGB(235,205,150), Decay=Color3.fromRGB(170,130,80), Glare=0.06, Haze=2.0},
		Color={Brightness=0.0, Contrast=0.12, Saturation=0.04, TintColor=Color3.fromRGB(250,225,180)},
		Bloom={Intensity=0.14, Size=18, Threshold=0.95}
	},
	["Cerulean Noon"] = {
		Lighting={ClockTime=12.2, Brightness=2.8, ExposureCompensation=0.06, GlobalShadows=true},
		Atmosphere={Density=0.24, Color=Color3.fromRGB(195,225,255), Decay=Color3.fromRGB(110,160,210), Glare=0.06, Haze=0.9},
		Color={Brightness=0.01, Contrast=0.08, Saturation=0.10, TintColor=Color3.fromRGB(250,255,255)},
		Bloom={Intensity=0.12, Size=16, Threshold=0.96},
		SunRays={Intensity=0.08, Spread=0.86},
		DOF={FocusDistance=20000, InFocusRadius=10000, NearIntensity=0, FarIntensity=0.02}
	},
	["Peachy Daybreak"] = {
		Lighting={ClockTime=5.8, Brightness=2.1, ExposureCompensation=0.05},
		Atmosphere={Density=0.34, Color=Color3.fromRGB(255,205,175), Decay=Color3.fromRGB(170,120,90), Glare=0.14, Haze=1.3},
		Color={Brightness=0.02, Contrast=0.10, Saturation=0.12, TintColor=Color3.fromRGB(255,235,215)},
		Bloom={Intensity=0.18, Size=20, Threshold=0.94},
		SunRays={Intensity=0.12, Spread=0.9}
	},
	["Lavender Stormbreak"] = {
		Lighting={ClockTime=17.9, Brightness=1.8, ExposureCompensation=0.02, FogStart=0, FogEnd=320, FogColor=Color3.fromRGB(180,165,195)},
		Atmosphere={Density=0.62, Color=Color3.fromRGB(210,190,240), Decay=Color3.fromRGB(120,100,150), Glare=0.08, Haze=2.0},
		Color={Brightness=0.0, Contrast=0.12, Saturation=0.02, TintColor=Color3.fromRGB(235,220,255)},
		Bloom={Intensity=0.10, Size=16, Threshold=0.96}
	},
	["Emerald Coastline"] = {
		Lighting={ClockTime=13.1, Brightness=2.6, ExposureCompensation=0.06},
		Atmosphere={Density=0.26, Color=Color3.fromRGB(210,245,230), Decay=Color3.fromRGB(120,190,160), Glare=0.05, Haze=0.95},
		Color={Brightness=0.01, Contrast=0.08, Saturation=0.10, TintColor=Color3.fromRGB(235,255,245)},
		Bloom={Intensity=0.14, Size=16, Threshold=0.96},
		SunRays={Intensity=0.09, Spread=0.88}
	},
	["Copper Horizon"] = {
		Lighting={ClockTime=18.3, Brightness=2.0, ExposureCompensation=0.04},
		Atmosphere={Density=0.33, Color=Color3.fromRGB(255,190,130), Decay=Color3.fromRGB(170,110,70), Glare=0.12, Haze=1.3},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.10, TintColor=Color3.fromRGB(255,220,170)},
		Bloom={Intensity=0.18, Size=18, Threshold=0.95},
		SunRays={Intensity=0.13, Spread=0.9}
	},
	["Slate Drizzle"] = {
		Lighting={ClockTime=15.2, Brightness=1.5, ExposureCompensation=-0.06, FogStart=0, FogEnd=300, FogColor=Color3.fromRGB(150,155,165)},
		Atmosphere={Density=0.78, Color=Color3.fromRGB(185,190,200), Decay=Color3.fromRGB(120,125,135), Glare=0.0, Haze=2.4},
		Color={Brightness=-0.01, Contrast=0.08, Saturation=-0.08, TintColor=Color3.fromRGB(230,235,240)},
		Bloom={Intensity=0.05, Size=12, Threshold=0.99}
	},
	["Noctilucent Night"] = {
		Lighting={ClockTime=1.0, Brightness=1.1, ExposureCompensation=-0.04, GlobalShadows=true},
		Atmosphere={Density=0.28, Color=Color3.fromRGB(190,220,255), Decay=Color3.fromRGB(80,110,170), Glare=0.10, Haze=1.0},
		Color={Brightness=0.0, Contrast=0.10, Saturation=0.06, TintColor=Color3.fromRGB(220,235,255)},
		Bloom={Intensity=0.16, Size=20, Threshold=0.92},
		SunRays={Intensity=0.02, Spread=0.75}
	},
	["Glacier Morning"] = {
		Lighting={ClockTime=8.6, Brightness=2.2, ExposureCompensation=0.02},
		Atmosphere={Density=0.27, Color=Color3.fromRGB(225,240,255), Decay=Color3.fromRGB(150,180,210), Glare=0.04, Haze=0.9},
		Color={Brightness=0.01, Contrast=0.10, Saturation=-0.02, TintColor=Color3.fromRGB(235,245,255)},
		Bloom={Intensity=0.10, Size=14, Threshold=0.97}
	},
	["Sunburst Rain"] = {
		Lighting={ClockTime=16.2, Brightness=2.1, ExposureCompensation=0.03, FogStart=0, FogEnd=360, FogColor=Color3.fromRGB(185,195,210)},
		Atmosphere={Density=0.55, Color=Color3.fromRGB(210,220,235), Decay=Color3.fromRGB(130,140,160), Glare=0.06, Haze=1.5},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.04, TintColor=Color3.fromRGB(245,250,255)},
		Bloom={Intensity=0.20, Size=20, Threshold=0.94},
		SunRays={Intensity=0.18, Spread=0.94}
	},
	["Monsoon Sunset Glow"] = {
		Lighting={ClockTime=18.0, Brightness=1.8, ExposureCompensation=0.00, FogStart=0, FogEnd=300, FogColor=Color3.fromRGB(160,150,150)},
		Atmosphere={Density=0.80, Color=Color3.fromRGB(240,190,140), Decay=Color3.fromRGB(150,110,80), Glare=0.10, Haze=2.3},
		Color={Brightness=0.0, Contrast=0.10, Saturation=0.08, TintColor=Color3.fromRGB(255,215,180)},
		Bloom={Intensity=0.12, Size=18, Threshold=0.95},
		SunRays={Intensity=0.10, Spread=0.9}
	},
	["Tropical Squall"] = {
		Lighting={ClockTime=14.6, Brightness=1.7, ExposureCompensation=-0.04, FogStart=0, FogEnd=330, FogColor=Color3.fromRGB(145,160,170)},
		Atmosphere={Density=0.72, Color=Color3.fromRGB(180,205,220), Decay=Color3.fromRGB(95,120,135), Glare=0.06, Haze=2.0},
		Color={Brightness=-0.01, Contrast=0.10, Saturation=0.02, TintColor=Color3.fromRGB(225,235,240)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.98}
	},
	["Desert Mirage"] = {
		Lighting={ClockTime=13.8, Brightness=2.6, ExposureCompensation=0.10},
		Atmosphere={Density=0.30, Color=Color3.fromRGB(255,225,170), Decay=Color3.fromRGB(200,160,100), Glare=0.16, Haze=1.1},
		Color={Brightness=0.02, Contrast=0.10, Saturation=0.04, TintColor=Color3.fromRGB(255,235,190)},
		Bloom={Intensity=0.22, Size=22, Threshold=0.94}
	},
	["Urban Rain Night"] = {
		Lighting={ClockTime=0.9, Brightness=1.0, ExposureCompensation=-0.06, FogStart=0, FogEnd=300, FogColor=Color3.fromRGB(95,105,120)},
		Atmosphere={Density=0.70, Color=Color3.fromRGB(170,185,205), Decay=Color3.fromRGB(90,100,120), Glare=0.04, Haze=2.0},
		Color={Brightness=0.0, Contrast=0.14, Saturation=0.12, TintColor=Color3.fromRGB(225,235,245)},
		Bloom={Intensity=0.24, Size=22, Threshold=0.90}
	},
	["Starfield Clear"] = {
		Lighting={ClockTime=23.8, Brightness=1.2, ExposureCompensation=-0.02, GlobalShadows=true},
		Atmosphere={Density=0.22, Color=Color3.fromRGB(210,225,255), Decay=Color3.fromRGB(110,140,190), Glare=0.02, Haze=0.8},
		Color={Brightness=0.0, Contrast=0.10, Saturation=-0.02, TintColor=Color3.fromRGB(225,235,255)},
		Bloom={Intensity=0.08, Size=14, Threshold=0.95},
		DOF={FocusDistance=20000, InFocusRadius=12000, NearIntensity=0, FarIntensity=0.02}
	},
	["Iridescent Dusk"] = {
		Lighting={ClockTime=19.1, Brightness=1.9, ExposureCompensation=0.04},
		Atmosphere={Density=0.32, Color=Color3.fromRGB(240,200,255), Decay=Color3.fromRGB(140,110,170), Glare=0.12, Haze=1.3},
		Color={Brightness=0.01, Contrast=0.14, Saturation=0.16, TintColor=Color3.fromRGB(245,220,255)},
		Bloom={Intensity=0.20, Size=20, Threshold=0.93}
	},
	["Frosted Valley"] = {
		Lighting={ClockTime=10.0, Brightness=2.0, ExposureCompensation=-0.02, FogStart=0, FogEnd=200, FogColor=Color3.fromRGB(230,235,240)},
		Atmosphere={Density=0.95, Color=Color3.fromRGB(235,245,255), Decay=Color3.fromRGB(205,215,235), Glare=0.0, Haze=3.0},
		Color={Brightness=0.01, Contrast=0.08, Saturation=-0.12, TintColor=Color3.fromRGB(240,245,255)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.98}
	},
	["Polar Veil"] = {
		Lighting={ClockTime=2.8, Brightness=1.3, ExposureCompensation=-0.04, GlobalShadows=true},
		Atmosphere={Density=0.34, Color=Color3.fromRGB(205,225,245), Decay=Color3.fromRGB(120,150,190), Glare=0.08, Haze=1.1},
		Color={Brightness=0.0, Contrast=0.12, Saturation=-0.02, TintColor=Color3.fromRGB(220,235,250)},
		Bloom={Intensity=0.10, Size=16, Threshold=0.94}
	},
	["Rainbow After Rain"] = {
		Lighting={ClockTime=16.7, Brightness=2.2, ExposureCompensation=0.04, FogStart=0, FogEnd=380, FogColor=Color3.fromRGB(185,195,210)},
		Atmosphere={Density=0.52, Color=Color3.fromRGB(220,230,245), Decay=Color3.fromRGB(135,145,165), Glare=0.08, Haze=1.5},
		Color={Brightness=0.02, Contrast=0.10, Saturation=0.14, TintColor=Color3.fromRGB(250,250,255)},
		Bloom={Intensity=0.18, Size=18, Threshold=0.95},
		SunRays={Intensity=0.16, Spread=0.93}
	},
	["Highland Mist"] = {
		Lighting={ClockTime=7.6, Brightness=1.7, ExposureCompensation=-0.02, FogStart=0, FogEnd=180, FogColor=Color3.fromRGB(210,215,220)},
		Atmosphere={Density=0.88, Color=Color3.fromRGB(225,230,235), Decay=Color3.fromRGB(195,200,205), Glare=0, Haze=3.0},
		Color={Brightness=0.0, Contrast=-0.02, Saturation=-0.10, TintColor=Color3.fromRGB(235,240,245)},
		Bloom={Intensity=0.05, Size=10, Threshold=0.99}
	},
	["Harbor Dawn"] = {
		Lighting={ClockTime=5.6, Brightness=2.0, ExposureCompensation=0.04},
		Atmosphere={Density=0.30, Color=Color3.fromRGB(255,215,190), Decay=Color3.fromRGB(150,120,100), Glare=0.10, Haze=1.2},
		Color={Brightness=0.01, Contrast=0.10, Saturation=0.08, TintColor=Color3.fromRGB(255,235,215)},
		Bloom={Intensity=0.14, Size=16, Threshold=0.95},
		SunRays={Intensity=0.12, Spread=0.90}
	},
	["Cinder Skies"] = {
		Lighting={ClockTime=17.0, Brightness=1.6, ExposureCompensation=-0.04, FogStart=0, FogEnd=260, FogColor=Color3.fromRGB(120,110,105)},
		Atmosphere={Density=0.86, Color=Color3.fromRGB(150,130,120), Decay=Color3.fromRGB(95,80,70), Glare=0.02, Haze=2.8},
		Color={Brightness=-0.02, Contrast=0.12, Saturation=-0.12, TintColor=Color3.fromRGB(215,205,195)},
		Bloom={Intensity=0.02, Size=8, Threshold=1.0}
	},
	["Azure Zenith"] = {
		Lighting={ClockTime=11.8, Brightness=3.0, ExposureCompensation=0.10, GlobalShadows=true},
		Atmosphere={Density=0.20, Color=Color3.fromRGB(210,235,255), Decay=Color3.fromRGB(120,160,210), Glare=0.04, Haze=0.8},
		Color={Brightness=0.00, Contrast=0.06, Saturation=0.06, TintColor=Color3.fromRGB(255,255,255)},
		Bloom={Intensity=0.12, Size=14, Threshold=0.97},
		SunRays={Intensity=0.08, Spread=0.84}
	},
	["Gilded Morning"] = {
		Lighting={ClockTime=7.9, Brightness=2.3, ExposureCompensation=0.06},
		Atmosphere={Density=0.28, Color=Color3.fromRGB(255,230,180), Decay=Color3.fromRGB(190,150,100), Glare=0.12, Haze=1.0},
		Color={Brightness=0.02, Contrast=0.10, Saturation=0.10, TintColor=Color3.fromRGB(255,240,205)},
		Bloom={Intensity=0.16, Size=18, Threshold=0.95}
	},
	["Pearl Overcast"] = {
		Lighting={ClockTime=12.9, Brightness=1.7, ExposureCompensation=-0.02},
		Atmosphere={Density=0.60, Color=Color3.fromRGB(225,230,235), Decay=Color3.fromRGB(160,165,170), Glare=0.0, Haze=1.9},
		Color={Brightness=0.0, Contrast=0.06, Saturation=-0.06, TintColor=Color3.fromRGB(240,240,245)},
		Bloom={Intensity=0.06, Size=12, Threshold=0.98}
	},
	["Sunrise Halo"] = {
		Lighting={ClockTime=5.9, Brightness=2.2, ExposureCompensation=0.06, GlobalShadows=true},
		Atmosphere={Density=0.28, Color=Color3.fromRGB(255,215,180), Decay=Color3.fromRGB(170,120,90), Glare=0.14, Haze=1.1},
		Color={Brightness=0.02, Contrast=0.10, Saturation=0.10, TintColor=Color3.fromRGB(255,235,215)},
		Bloom={Intensity=0.18, Size=18, Threshold=0.95},
		SunRays={Intensity=0.14, Spread=0.90},
		DOF={FocusDistance=20000, InFocusRadius=10000, NearIntensity=0, FarIntensity=0.02}
	},
	["Noon Crystal Sun"] = {
		Lighting={ClockTime=12.0, Brightness=3.0, ExposureCompensation=0.10, GlobalShadows=true},
		Atmosphere={Density=0.20, Color=Color3.fromRGB(210,235,255), Decay=Color3.fromRGB(120,160,210), Glare=0.06, Haze=0.8},
		Color={Brightness=0.00, Contrast=0.08, Saturation=0.06, TintColor=Color3.fromRGB(255,255,255)},
		Bloom={Intensity=0.12, Size=14, Threshold=0.97},
		SunRays={Intensity=0.10, Spread=0.86},
		DOF={FocusDistance=22000, InFocusRadius=12000, NearIntensity=0, FarIntensity=0.02}
	},
	["Sunset Disk Clear"] = {
		Lighting={ClockTime=18.2, Brightness=2.1, ExposureCompensation=0.04},
		Atmosphere={Density=0.30, Color=Color3.fromRGB(255,190,140), Decay=Color3.fromRGB(170,110,70), Glare=0.12, Haze=1.0},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.10, TintColor=Color3.fromRGB(255,220,175)},
		Bloom={Intensity=0.18, Size=18, Threshold=0.95},
		SunRays={Intensity=0.15, Spread=0.90},
		DOF={FocusDistance=20000, InFocusRadius=10000, NearIntensity=0, FarIntensity=0.02}
	},
	["High Desert Sun"] = {
		Lighting={ClockTime=13.3, Brightness=2.7, ExposureCompensation=0.08},
		Atmosphere={Density=0.22, Color=Color3.fromRGB(255,225,170), Decay=Color3.fromRGB(200,160,100), Glare=0.16, Haze=0.9},
		Color={Brightness=0.02, Contrast=0.10, Saturation=0.04, TintColor=Color3.fromRGB(255,240,195)},
		Bloom={Intensity=0.20, Size=20, Threshold=0.94},
		SunRays={Intensity=0.12, Spread=0.88},
		DOF={FocusDistance=21000, InFocusRadius=11000, NearIntensity=0, FarIntensity=0.02}
	},
	["Winter Pale Sun"] = {
		Lighting={ClockTime=11.0, Brightness=2.2, ExposureCompensation=0.02},
		Atmosphere={Density=0.26, Color=Color3.fromRGB(235,245,255), Decay=Color3.fromRGB(160,185,210), Glare=0.04, Haze=0.9},
		Color={Brightness=0.00, Contrast=0.08, Saturation=-0.04, TintColor=Color3.fromRGB(240,245,255)},
		Bloom={Intensity=0.10, Size=14, Threshold=0.97},
		SunRays={Intensity=0.08, Spread=0.86},
		DOF={FocusDistance=20000, InFocusRadius=10000, NearIntensity=0, FarIntensity=0.02}
	},
	["Ocean Sun Glare"] = {
		Lighting={ClockTime=16.0, Brightness=2.4, ExposureCompensation=0.06},
		Atmosphere={Density=0.24, Color=Color3.fromRGB(210,235,255), Decay=Color3.fromRGB(110,150,200), Glare=0.10, Haze=0.9},
		Color={Brightness=0.01, Contrast=0.08, Saturation=0.10, TintColor=Color3.fromRGB(240,250,255)},
		Bloom={Intensity=0.22, Size=22, Threshold=0.94},
		SunRays={Intensity=0.16, Spread=0.90},
		DOF={FocusDistance=21000, InFocusRadius=11000, NearIntensity=0, FarIntensity=0.02}
	},
	["Moonrise Amber"] = {
		Lighting={ClockTime=19.6, Brightness=1.5, ExposureCompensation=0.00, GlobalShadows=true},
		Atmosphere={Density=0.30, Color=Color3.fromRGB(245,210,170), Decay=Color3.fromRGB(150,110,80), Glare=0.06, Haze=1.0},
		Color={Brightness=0.00, Contrast=0.12, Saturation=0.02, TintColor=Color3.fromRGB(235,220,205)},
		Bloom={Intensity=0.10, Size=16, Threshold=0.95},
		SunRays={Intensity=0.06, Spread=0.84},
		DOF={FocusDistance=22000, InFocusRadius=12000, NearIntensity=0, FarIntensity=0.02}
	},
	["Blue Moon Night"] = {
		Lighting={ClockTime=1.2, Brightness=1.25, ExposureCompensation=-0.02, GlobalShadows=true},
		Atmosphere={Density=0.24, Color=Color3.fromRGB(205,220,255), Decay=Color3.fromRGB(90,120,170), Glare=0.02, Haze=0.8},
		Color={Brightness=0.00, Contrast=0.10, Saturation=-0.06, TintColor=Color3.fromRGB(215,230,255)},
		Bloom={Intensity=0.08, Size=14, Threshold=0.95},
		SunRays={Intensity=0.02, Spread=0.76},
		DOF={FocusDistance=23000, InFocusRadius=13000, NearIntensity=0, FarIntensity=0.02}
	},
	["Supermoon Clear"] = {
		Lighting={ClockTime=0.3, Brightness=1.35, ExposureCompensation=0.00, GlobalShadows=true},
		Atmosphere={Density=0.20, Color=Color3.fromRGB(220,235,255), Decay=Color3.fromRGB(110,140,190), Glare=0.04, Haze=0.7},
		Color={Brightness=0.01, Contrast=0.12, Saturation=-0.02, TintColor=Color3.fromRGB(230,240,255)},
		Bloom={Intensity=0.12, Size=18, Threshold=0.94},
		SunRays={Intensity=0.02, Spread=0.74},
		DOF={FocusDistance=24000, InFocusRadius=14000, NearIntensity=0, FarIntensity=0.02}
	},
	["Harvest Moonrise"] = {
		Lighting={ClockTime=19.2, Brightness=1.4, ExposureCompensation=0.02, GlobalShadows=true},
		Atmosphere={Density=0.26, Color=Color3.fromRGB(255,210,165), Decay=Color3.fromRGB(170,120,80), Glare=0.10, Haze=0.9},
		Color={Brightness=0.00, Contrast=0.12, Saturation=0.06, TintColor=Color3.fromRGB(255,225,190)},
		Bloom={Intensity=0.16, Size=18, Threshold=0.94},
		SunRays={Intensity=0.06, Spread=0.84},
		DOF={FocusDistance=22000, InFocusRadius=12000, NearIntensity=0, FarIntensity=0.02}
	},
	["Snow Moon"] = {
		Lighting={ClockTime=2.0, Brightness=1.3, ExposureCompensation=-0.02, GlobalShadows=true},
		Atmosphere={Density=0.22, Color=Color3.fromRGB(235,245,255), Decay=Color3.fromRGB(160,185,210), Glare=0.02, Haze=0.8},
		Color={Brightness=0.01, Contrast=0.10, Saturation=-0.12, TintColor=Color3.fromRGB(240,245,255)},
		Bloom={Intensity=0.10, Size=16, Threshold=0.95},
		SunRays={Intensity=0.02, Spread=0.76},
		DOF={FocusDistance=23000, InFocusRadius=13000, NearIntensity=0, FarIntensity=0.02}
	},
	["Moon Above Pines"] = {
		Lighting={ClockTime=22.8, Brightness=1.2, ExposureCompensation=-0.02, GlobalShadows=true},
		Atmosphere={Density=0.24, Color=Color3.fromRGB(210,225,245), Decay=Color3.fromRGB(120,150,190), Glare=0.02, Haze=0.9},
		Color={Brightness=0.00, Contrast=0.10, Saturation=-0.04, TintColor=Color3.fromRGB(220,235,250)},
		Bloom={Intensity=0.08, Size=14, Threshold=0.95},
		SunRays={Intensity=0.02, Spread=0.74},
		DOF={FocusDistance=22000, InFocusRadius=12000, NearIntensity=0, FarIntensity=0.02}
	},
	["Moonset Violet"] = {
		Lighting={ClockTime=5.0, Brightness=1.6, ExposureCompensation=0.02, GlobalShadows=true},
		Atmosphere={Density=0.30, Color=Color3.fromRGB(230,200,255), Decay=Color3.fromRGB(140,110,170), Glare=0.06, Haze=1.0},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.04, TintColor=Color3.fromRGB(240,220,255)},
		Bloom={Intensity=0.12, Size=16, Threshold=0.95},
		SunRays={Intensity=0.06, Spread=0.84},
		DOF={FocusDistance=21000, InFocusRadius=11000, NearIntensity=0, FarIntensity=0.02}
	},
	["Tropical Moonlit"] = {
		Lighting={ClockTime=0.8, Brightness=1.3, ExposureCompensation=0.00, GlobalShadows=true},
		Atmosphere={Density=0.22, Color=Color3.fromRGB(200,230,240), Decay=Color3.fromRGB(100,170,160), Glare=0.06, Haze=0.9},
		Color={Brightness=0.01, Contrast=0.10, Saturation=0.06, TintColor=Color3.fromRGB(220,245,235)},
		Bloom={Intensity=0.14, Size=18, Threshold=0.94},
		SunRays={Intensity=0.02, Spread=0.76},
		DOF={FocusDistance=23000, InFocusRadius=13000, NearIntensity=0, FarIntensity=0.02}
	},
	["Golden Hour+"] = {
		Lighting={ClockTime=17.2, Brightness=2.2, ExposureCompensation=0.08},
		Atmosphere={Density=0.32, Color=Color3.fromRGB(255,200,120), Decay=Color3.fromRGB(160,110,60), Glare=0.15, Haze=1.2},
		Color={Brightness=0.02, Contrast=0.12, Saturation=0.15, TintColor=Color3.fromRGB(255,225,170)},
		SunRays={Intensity=0.12, Spread=0.88},
		Bloom={Intensity=0.18, Size=20, Threshold=0.94}
	},
	["Crepuscular Beam"] = {
		Lighting={ClockTime=17.0, Brightness=2.2, ExposureCompensation=0.06},
		Atmosphere={Density=0.34, Color=Color3.fromRGB(245,205,160), Decay=Color3.fromRGB(160,120,90), Glare=0.18, Haze=1.3},
		Color={Brightness=0.01, Contrast=0.12, Saturation=0.10, TintColor=Color3.fromRGB(255,230,190)},
		Bloom={Intensity=0.20, Size=20, Threshold=0.93},
		SunRays={Intensity=0.22, Spread=0.92},
		DOF={FocusDistance=20000, InFocusRadius=10000, NearIntensity=0, FarIntensity=0.02}
	},
}

--==========================================================
--  UI TAB 11 - WEATHER (FOLLOW CORE UI)
--==========================================================

-- bersihin isi TAB_FRAME, biar tab ini full kontrol
for _, child in ipairs(frame:GetChildren()) do
	child:Destroy()
end

frame.BackgroundTransparency = 1

-- padding utama
local root = Instance.new("Frame")
root.Name = "WeatherRoot"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = frame

local pad = Instance.new("UIPadding")
pad.PaddingTop    = UDim.new(0, 10)
pad.PaddingLeft   = UDim.new(0, 12)
pad.PaddingRight  = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = root

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.fromOffset(0, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 248)
title.Text = "Weather • Lighting Presets"
title.Parent = root

-- Sub info
local info = Instance.new("TextLabel")
info.Name = "Info"
info.BackgroundTransparency = 1
info.Size = UDim2.new(1, 0, 0, 20)
info.Position = UDim2.fromOffset(0, 24)
info.Font = Enum.Font.Gotham
info.TextSize = 13
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextWrapped = true
info.TextColor3 = Color3.fromRGB(170, 175, 190)
info.Text = "Pilih preset cuaca / lighting. 4 tombol per baris (horizontal), selebihnya kebawah • Scroll bisa vertikal & horizontal."
info.Parent = root

-- Bar tombol atas (HD + Reset)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundTransparency = 1
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.Position = UDim2.fromOffset(0, 48)
topBar.Parent = root

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
topLayout.Padding = UDim.new(0, 6)
topLayout.SortOrder = Enum.SortOrder.LayoutOrder
topLayout.Parent = topBar

local function pillButton(text)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.Size = UDim2.fromOffset(90, 26)
	b.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
	b.TextColor3 = Color3.fromRGB(235, 235, 245)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 13
	b.Text = text

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(70, 80, 110)
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b

	return b
end

local ResetBtn = pillButton("Reset")
ResetBtn.Name = "ResetBtn"
ResetBtn.LayoutOrder = 2
ResetBtn.Parent = topBar

local HdBtn = pillButton("HD")
HdBtn.Name = "HdBtn"
HdBtn.LayoutOrder = 1
HdBtn.Parent = topBar

-- ScrollingFrame untuk grid preset
local gridFrame = Instance.new("ScrollingFrame")
gridFrame.Name = "PresetGrid"
gridFrame.BackgroundTransparency = 1
gridFrame.BorderSizePixel = 0
gridFrame.ScrollBarThickness = 6
gridFrame.ScrollingDirection = Enum.ScrollingDirection.XY -- bisa vertikal & horizontal
gridFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
gridFrame.Size = UDim2.new(1, 0, 1, - (48 + 30 + 10)) -- sisa tinggi setelah title+info+topbar
gridFrame.Position = UDim2.fromOffset(0, 48 + 30 + 8)
gridFrame.ClipsDescendants = true
gridFrame.Parent = root

local gridPad = Instance.new("UIPadding")
gridPad.PaddingTop = UDim.new(0, 6)
gridPad.PaddingLeft = UDim.new(0, 2)
gridPad.Parent = gridFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.CellSize = UDim2.fromOffset(200, 32) -- lumayan lebar, biar butuh scroll horizontal
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.FillDirectionMaxCells = 4 -- <= 4 tombol per baris
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = gridFrame

--==========================================================
--  GRID BUILDER (SORT A-Z, 4 per baris)
--==========================================================
local function getSortedPresetNames()
	local t = {}
	for name in pairs(PRESETS) do
		table.insert(t, name)
	end
	table.sort(t, function(a,b)
		return string.lower(a) < string.lower(b)
	end)
	return t
end

local selectedButton

local function styleButtonNormal(btn)
	TweenService:Create(btn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(40, 42, 54),
		TextColor3       = Color3.fromRGB(235, 235, 245)
	}):Play()
end

local function styleButtonHover(btn)
	TweenService:Create(btn, TweenInfo.new(0.12), {
		BackgroundColor3 = Color3.fromRGB(55, 58, 72)
	}):Play()
end

local function styleButtonSelected(btn)
	TweenService:Create(btn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(90, 140, 255),
		TextColor3       = Color3.fromRGB(15, 20, 35)
	}):Play()
end

local function createPresetButton(name, order)
	local preset = PRESETS[name]
	if not preset then
		return
	end

	local btn = Instance.new("TextButton")
	btn.Name = "Preset_" .. (name:gsub("%W","_"))
	btn.LayoutOrder = order or 0
	btn.Size = UDim2.fromOffset(200, 32)
	btn.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
	btn.TextColor3 = Color3.fromRGB(235, 235, 245)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 13
	btn.Text = name
	btn.AutoButtonColor = false
	btn.Parent = gridFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(65, 70, 95)
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		if selectedButton ~= btn then
			styleButtonHover(btn)
		end
	end)

	btn.MouseLeave:Connect(function()
		if selectedButton ~= btn then
			styleButtonNormal(btn)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		applyPreset(preset, true)
		if selectedButton and selectedButton ~= btn then
			styleButtonNormal(selectedButton)
		end
		selectedButton = btn
		styleButtonSelected(btn)
	end)

	return btn
end

-- Bangun grid awal
do
	local names = getSortedPresetNames()
	for i, name in ipairs(names) do
		createPresetButton(name, i)
	end
end

--==========================================================
--  HD TOGGLE (SAMA LOGIKA DENGAN SCRIPT WEATHER)
--==========================================================
local isHD = false
local hdSnapshot = nil

local function styleHd(active)
	local bg = active and Color3.fromRGB(90, 140, 255) or Color3.fromRGB(40, 42, 54)
	local fg = active and Color3.fromRGB(15, 20, 35)  or Color3.fromRGB(235, 235, 245)
	TweenService:Create(HdBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = bg,
		TextColor3       = fg,
	}):Play()
	HdBtn.Text = active and "HD On" or "HD"
end

local function supportsFuture()
	local ok = pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	return ok and Lighting.Technology == Enum.Technology.Future
end

local function setHD(state)
	if state and not isHD then
		-- snapshot dulu
		hdSnapshot = {
			Lighting = cloneProps(Lighting, {
				"EnvironmentDiffuseScale","EnvironmentSpecularScale",
				"ExposureCompensation","Technology","Ambient","Brightness"
			}),
			Color    = cloneProps(Effects.ColorCorrection,{"Brightness","Contrast","Saturation","TintColor"}),
			Bloom    = cloneProps(Effects.Bloom,{"Intensity","Size","Threshold"}),
			DOF      = cloneProps(Effects.DOF,{"FocusDistance","InFocusRadius","NearIntensity","FarIntensity"}),
			SunRays  = cloneProps(Effects.SunRays,{"Intensity","Spread"}),
			Atmos    = cloneProps(Effects.Atmosphere,{"Density","Haze","Glare"}),
		}

		if supportsFuture() then
			tweenProps(Lighting, {
				EnvironmentDiffuseScale = math.min(1.2, (Lighting.EnvironmentDiffuseScale or 1) * 1.12),
				EnvironmentSpecularScale = math.min(1.2, (Lighting.EnvironmentSpecularScale or 1) * 1.12),
				ExposureCompensation = math.clamp((Lighting.ExposureCompensation or 0) + 0.04, SAFE.ExpMin, SAFE.ExpMax),
			})
		end

		tweenProps(Effects.ColorCorrection, {
			Contrast   = (Effects.ColorCorrection.Contrast   or 0) + 0.14,
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
			FarIntensity  = math.min(SAFE.MaxDOFFar,   (Effects.DOF.FarIntensity  or 0) + 0.02),
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
					Lighting.Technology = hdSnapshot.Lighting.Technology
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

HdBtn.MouseButton1Click:Connect(function()
	setHD(not isHD)
end)

ResetBtn.MouseButton1Click:Connect(function()
	if isHD then
		setHD(false)
	end
	resetAll()
end)

styleHd(false)
visualGuard(false)

--==========================================================
--  REAPPLY SAAT QUALITY DIUBAH USER
--==========================================================
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
