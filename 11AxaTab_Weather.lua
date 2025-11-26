--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ContextActionService = game:GetService("ContextActionService")

-- Pantau Graphics Quality
local okUGS, UserGameSettings = pcall(function()
	return UserSettings():GetService("UserGameSettings")
end)

--// SINGLETON UI GUARD
if PlayerGui:FindFirstChild("RTXWeatherUI") then return end

--// CONFIG UI
local TWEEN_TIME = 0.9
local EASING = Enum.EasingStyle.Quad
local EASEDIR = Enum.EasingDirection.Out
local BTN_W, BTN_H = 148, 34
local BTN_PAD = 8
local TITLE = "Weather by Axa"

-- Batas aman global
local SAFE = {
	MinBrightness = 1.0,
	ExpMin = -0.08, ExpMax = 0.15,
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

--// HELPERS
local function ensure(name, className, parent)
	local obj = (parent or Lighting):FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = parent or Lighting
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
Effects.Bloom.Enabled = true
Effects.DOF.Enabled = true
Effects.SunRays.Enabled = true
Effects.ColorCorrection.Enabled = true

-- Sky placeholders
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
		local ok, val = pcall(function() return instance[p] end)
		if ok then t[p] = val end
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

-- Build tween goal aman
local function buildTweenableGoal(instance, goal)
	local t = {}
	for k, v in pairs(goal) do
		if v ~= nil and k ~= "Technology" then
			local ok = pcall(function() return instance[k] end)
			if ok then t[k] = v end
		end
	end
	return t
end

local function tweenProps(instance, goal, customTime)
	local g = buildTweenableGoal(instance, goal)
	if next(g) == nil then return end
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
	if not okUGS or not UserGameSettings then return nil end
	local props = {"QualityLevel","SavedQualityLevel"}
	for _,key in ipairs(props) do
		local ok, val = pcall(function() return UserGameSettings[key] end)
		if ok and val ~= nil then
			if typeof(val) == "EnumItem" then
				if val.Name == "Automatic" then return 8 end
				local n = tonumber((tostring(val) or ""):match("(%d+)"))
				if n then return n end
			elseif typeof(val) == "number" then
				if val > 0 then return val end
			end
		end
	end
	return nil
end

-- GUARD
local function visualGuard(doTween)
	local Lgoal = {}
	if Lighting.Brightness < SAFE.MinBrightness then Lgoal.Brightness = SAFE.MinBrightness end
	if Lighting.ExposureCompensation < SAFE.ExpMin or Lighting.ExposureCompensation > SAFE.ExpMax then
		Lgoal.ExposureCompensation = math.clamp(Lighting.ExposureCompensation, SAFE.ExpMin, SAFE.ExpMax)
	end
	local fs, fe = Lighting.FogStart or 0, Lighting.FogEnd or 1e9
	if fe - fs < SAFE.MinFogGap then Lgoal.FogEnd = fs + SAFE.MinFogGap end
	local t = Lighting.ClockTime or 12
	if t >= 19 or t <= 5 then
		Lgoal.Ambient = liftAmbient(Lighting.Ambient or Color3.new(), SAFE.MinAmbient)
	end
	if next(Lgoal) then
		if doTween then tweenProps(Lighting, Lgoal) else for k,v in pairs(Lgoal) do Lighting[k]=v end end
	end

	local Dgoal = {}
	if Effects.DOF.FarIntensity and Effects.DOF.FarIntensity > SAFE.MaxDOFFar then Dgoal.FarIntensity = SAFE.MaxDOFFar end
	if Effects.DOF.InFocusRadius and Effects.DOF.InFocusRadius < SAFE.MinInFocus then Dgoal.InFocusRadius = SAFE.MinInFocus end

	local q = getQualityLevelNumber() or 10
	if q >= SAFE.CrispQuality then
		if Effects.DOF.FarIntensity == nil or Effects.DOF.FarIntensity > SAFE.CrispFar then Dgoal.FarIntensity = SAFE.CrispFar end
		if Effects.DOF.NearIntensity and Effects.DOF.NearIntensity > 0 then Dgoal.NearIntensity = 0 end
		if Effects.DOF.InFocusRadius and Effects.DOF.InFocusRadius < SAFE.CrispInFocus then Dgoal.InFocusRadius = SAFE.CrispInFocus end
		if Effects.DOF.FocusDistance and Effects.DOF.FocusDistance < SAFE.CrispFocus then Dgoal.FocusDistance = SAFE.CrispFocus end
	end

	if next(Dgoal) then
		if doTween then tweenProps(Effects.DOF, Dgoal) else for k,v in pairs(Dgoal) do Effects.DOF[k]=v end end
	end

	if Effects.Bloom.Threshold and Effects.Bloom.Threshold < SAFE.BloomThreshMin then
		if doTween then tweenProps(Effects.Bloom, {Threshold = SAFE.BloomThreshMin})
		else Effects.Bloom.Threshold = SAFE.BloomThreshMin end
	end

	if Effects.ColorCorrection.Brightness and Effects.ColorCorrection.Brightness < -0.06 then
		if doTween then tweenProps(Effects.ColorCorrection, {Brightness = -0.02})
		else Effects.ColorCorrection.Brightness = -0.02 end
	end
end

-- APPLY PRESET + guard
local currentPreset
local function applyPreset(p, doTween)
	if not p then return end
	currentPreset = p
	if p.Lighting then
		if p.Lighting.Technology ~= nil then pcall(function() Lighting.Technology = p.Lighting.Technology end) end
		if doTween ~= false then tweenProps(Lighting, p.Lighting)
		else for k,v in pairs(buildTweenableGoal(Lighting, p.Lighting)) do Lighting[k]=v end end
	end
	if p.Atmosphere then (doTween~=false and tweenProps or function(i,g) for k,v in pairs(buildTweenableGoal(i,g)) do i[k]=v end end)(Effects.Atmosphere, p.Atmosphere) end
	if p.Color      then (doTween~=false and tweenProps or function(i,g) for k,v in pairs(buildTweenableGoal(i,g)) do i[k]=v end end)(Effects.ColorCorrection, p.Color) end
	if p.Bloom      then (doTween~=false and tweenProps or function(i,g) for k,v in pairs(buildTweenableGoal(i,g)) do i[k]=v end end)(Effects.Bloom, p.Bloom) end
	if p.DOF        then (doTween~=false and tweenProps or function(i,g) for k,v in pairs(buildTweenableGoal(i,g)) do i[k]=v end end)(Effects.DOF, p.DOF) end
	if p.SunRays    then (doTween~=false and tweenProps or function(i,g) for k,v in pairs(buildTweenableGoal(i,g)) do i[k]=v end end)(Effects.SunRays, p.SunRays) end
	visualGuard(true)
end

-- RESET aman
local function resetAll()
	if initialSnapshot.Lighting and initialSnapshot.Lighting.Technology ~= nil then
		pcall(function() Lighting.Technology = initialSnapshot.Lighting.Technology end)
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

--// PRESETS (pakai tabel panjangmu yang mantap)
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
		SunRays={Intensity=0.12, Spread=0.88}, Bloom={Intensity=0.18, Size=20, Threshold=0.94}
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
["Golden Hour"] = {
		Lighting={ClockTime=17.2, Brightness=2.2, ExposureCompensation=0.08},
		Atmosphere={Density=0.32, Color=Color3.fromRGB(255,200,120), Decay=Color3.fromRGB(160,110,60), Glare=0.15, Haze=1.2},
		Color={Brightness=0.02, Contrast=0.12, Saturation=0.15, TintColor=Color3.fromRGB(255,225,170)},
		SunRays={Intensity=0.12, Spread=0.88}, Bloom={Intensity=0.18, Size=20, Threshold=0.94}
},
["Crepuscular Beam"] = {
	Lighting={ClockTime=17.0, Brightness=2.2, ExposureCompensation=0.06},
	Atmosphere={Density=0.34, Color=Color3.fromRGB(245,205,160), Decay=Color3.fromRGB(160,120,90), Glare=0.18, Haze=1.3},
	Color={Brightness=0.01, Contrast=0.12, Saturation=0.10, TintColor=Color3.fromRGB(255,230,190)},
	Bloom={Intensity=0.20, Size=20, Threshold=0.93},
	SunRays={Intensity=0.22, Spread=0.92},
	DOF={FocusDistance=20000, InFocusRadius=10000, NearIntensity=0, FarIntensity=0.02}
}
}

--// UI ----------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RTXWeatherUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(360, 460) -- sedikit lebih tinggi agar muat search
Main.Position = UDim2.new(1, -380, 0, 90)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
Header.BorderSizePixel = 0
Header.Parent = Main

local TitleL = Instance.new("TextLabel")
TitleL.Size = UDim2.new(1, -200, 1, 0)
TitleL.Position = UDim2.new(0, 12, 0, 0)
TitleL.BackgroundTransparency = 1
TitleL.Text = TITLE
TitleL.TextXAlignment = Enum.TextXAlignment.Left
TitleL.Font = Enum.Font.GothamBold
TitleL.TextSize = 18
TitleL.TextColor3 = Color3.fromRGB(235,235,245)
TitleL.Parent = Header

local function pill(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(64, 28)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.BackgroundColor3 = Color3.fromRGB(55,55,65)
	b.TextColor3 = Color3.fromRGB(240,240,250)
	b.Text = text
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	return b
end

local HdBtn = pill("HD");        HdBtn.Position   = UDim2.new(1, -208, 0.5, -14); HdBtn.Parent = Header
local ResetBtn = pill("Reset");  ResetBtn.Position= UDim2.new(1, -136, 0.5, -14); ResetBtn.Parent = Header
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -72, 0.5, -14)
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
MinBtn.TextColor3 = Color3.fromRGB(220,220,230)
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,8)

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -16, 1, -64)
Body.Position = UDim2.new(0, 8, 0, 52)
Body.BackgroundTransparency = 1
Body.Parent = Main

-- ===== SEARCH ROW =====
local SearchRow = Instance.new("Frame")
SearchRow.Size = UDim2.new(1, -8, 0, 36)
SearchRow.Position = UDim2.new(0, 4, 0, 0)
SearchRow.BackgroundTransparency = 1
SearchRow.Parent = Body

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -40, 1, 0)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 14
SearchBox.PlaceholderText = "Search weather…"
SearchBox.PlaceholderColor3 = Color3.fromRGB(140,145,160)
SearchBox.Text = ""
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.TextColor3 = Color3.fromRGB(235,235,245)
SearchBox.BackgroundColor3 = Color3.fromRGB(32,32,38)
SearchBox.Parent = SearchRow
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0,8)
local SearchStroke = Instance.new("UIStroke")
SearchStroke.Thickness = 1
SearchStroke.Color = Color3.fromRGB(70,80,110)
SearchStroke.Transparency = 0.25
SearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SearchStroke.Parent = SearchBox

-- ikon kaca pembesar
local SearchIcon = Instance.new("TextLabel")
SearchIcon.BackgroundTransparency = 1
SearchIcon.Size = UDim2.new(1, 30, 1, 0)
SearchIcon.Position = UDim2.new(0, -10, 0, 0)
SearchIcon.Font = Enum.Font.GothamBold
SearchIcon.Text = "🔍"
SearchIcon.TextXAlignment = Enum.TextXAlignment.Right
SearchIcon.TextSize = 16
SearchIcon.TextColor3 = Color3.fromRGB(180,185,200)
SearchIcon.Parent = SearchBox

-- padding agar teks tidak menimpa ikon
local SearchPad = Instance.new("UIPadding")
SearchPad.PaddingLeft = UDim.new(0, 32)
SearchPad.Parent = SearchBox

-- tombol clear
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 28, 0, 28)
ClearBtn.AnchorPoint = Vector2.new(1,0.5)
ClearBtn.Position = UDim2.new(1, -6, 0.5, 0)
ClearBtn.Text = "✕"
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 14
ClearBtn.TextColor3 = Color3.fromRGB(210,215,225)
ClearBtn.BackgroundColor3 = Color3.fromRGB(45,48,56)
ClearBtn.AutoButtonColor = false
ClearBtn.Visible = false
ClearBtn.Parent = SearchBox
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(1,0)

-- ===== GRID LIST =====
local Grid = Instance.new("ScrollingFrame")
Grid.Size = UDim2.new(1, 0, 1, -44)   -- sisihkan ruang untuk search
Grid.Position = UDim2.new(0, 0, 0, 44)
Grid.ScrollBarThickness = 6
Grid.Active = true
Grid.AutomaticCanvasSize = Enum.AutomaticSize.XY   -- ⬅️ sekarang auto X + Y
Grid.ScrollingDirection = Enum.ScrollingDirection.XY -- ⬅️ pastikan bisa scroll dua arah
Grid.BackgroundTransparency = 1
Grid.Parent = Body

local UIGrid = Instance.new("UIGridLayout")
UIGrid.CellPadding = UDim2.fromOffset(BTN_PAD, BTN_PAD)
UIGrid.CellSize = UDim2.fromOffset(BTN_W, BTN_H)
UIGrid.FillDirection = Enum.FillDirection.Horizontal -- ⬅️ isi ke samping dulu
UIGrid.FillDirectionMaxCells = 4                     -- ⬅️ 4 tombol per baris
UIGrid.SortOrder = Enum.SortOrder.Name              -- ⬅️ pakai nama buat urutan
UIGrid.Parent = Grid

local UIPad = Instance.new("UIPadding")
UIPad.PaddingLeft = UDim.new(0, 6)
UIPad.PaddingTop = UDim.new(0, 6)
UIPad.Parent = Grid

-- Minimized orb
local Orb = Instance.new("TextButton")
Orb.Name = "Orb"
Orb.Size = UDim2.fromOffset(44,44)
Orb.Position = UDim2.new(1, -56, 0, 90)
Orb.Text = "☀️"
Orb.Font = Enum.Font.GothamBold
Orb.TextSize = 20
Orb.BackgroundColor3 = Color3.fromRGB(32,32,38)
Orb.TextColor3 = Color3.fromRGB(250, 235, 120)
Orb.Visible = false
Orb.Parent = ScreenGui
Instance.new("UICorner", Orb).CornerRadius = UDim.new(1,0)

-- ==== DRAGIFY (mouse & touch, clamp ke layar) ====
local function Dragify(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos = false, nil, nil

	local function parentSize()
		local ps = frame.Parent and frame.Parent.AbsoluteSize
		if ps then return ps end
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1920,1080)
	end

	local function clampToScreen()
		local ps = parentSize()
		local fs = frame.AbsoluteSize
		local x = math.clamp(frame.Position.X.Offset, 0, math.max(0, ps.X - fs.X))
		local y = math.clamp(frame.Position.Y.Offset, 0, math.max(0, ps.Y - fs.Y))
		frame.Position = UDim2.fromOffset(x, y)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Once(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					clampToScreen()
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - dragStart
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y
		frame.Position = UDim2.fromOffset(newX, newY)
	end)

	-- jaga posisi saat resolusi berubah
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(clampToScreen)
	end
end

-- Aktifkan drag
Dragify(Main, Header) -- drag via header
Dragify(Orb)          -- orb juga bisa di-drag

-- Button factory
local function makeBtn(label, callback)
	local b = Instance.new("TextButton")
	b.Name = label -- ⬅️ supaya SortOrder.Name bekerja
	b.Size = UDim2.fromOffset(BTN_W, BTN_H)
	b.BackgroundColor3 = Color3.fromRGB(40,40,50)
	b.TextColor3 = Color3.fromRGB(235,235,245)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.Text = label
	b.Parent = Grid
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(55,55,70)}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(40,40,50)}):Play()
	end)
	b.MouseButton1Click:Connect(callback)
	return b
end

-- ===== SORT + SEARCH =====
local function getSortedPresetNames()
	local t = {}
	for name in pairs(PRESETS) do table.insert(t, name) end
	table.sort(t, function(a,b) return string.lower(a) < string.lower(b) end) -- A-Z
	return t
end

local function clearGridButtons()
	for _, child in ipairs(Grid:GetChildren()) do
		if child:IsA("TextButton") or child.Name == "_NoResult" then
			child:Destroy()
		end
	end
end

local function rebuildGrid(query)
	query = (query or ""):lower()
	clearGridButtons()

	local count = 0
	for _, name in ipairs(getSortedPresetNames()) do
		if query == "" or string.find(name:lower(), query, 1, true) then
			count += 1
			makeBtn(name, function()
				applyPreset(PRESETS[name], true)
			end)
		end
	end

	-- no result state
	if count == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "_NoResult"
		lbl.Size = UDim2.fromOffset(BTN_W, BTN_H)
		lbl.BackgroundTransparency = 1
		lbl.Text = "No results"
		lbl.TextColor3 = Color3.fromRGB(160,165,180)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.Parent = Grid
	end
end

-- Search events
local function updateClearVisibility()
	ClearBtn.Visible = (SearchBox.Text and #SearchBox.Text > 0)
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	updateClearVisibility()
	rebuildGrid(SearchBox.Text)
end)
ClearBtn.MouseButton1Click:Connect(function()
	SearchBox.Text = ""
	SearchBox:CaptureFocus()
end)
updateClearVisibility()
rebuildGrid("") -- initial build (A-Z)

--// HD TOGGLE ---------------------------------------------------------------
local isHD = false
local hdSnapshot = nil

local function styleHd(active)
	TweenService:Create(HdBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = active and Color3.fromRGB(90, 140, 255) or Color3.fromRGB(55,55,65),
		TextColor3 = active and Color3.fromRGB(15, 20, 35) or Color3.fromRGB(240,240,250)
	}):Play()
	HdBtn.Text = active and "HD On" or "HD"
end

local function supportsFuture()
	local ok = pcall(function() Lighting.Technology = Enum.Technology.Future end)
	return ok and Lighting.Technology == Enum.Technology.Future
end

local setHD
setHD = function(state)
	if state and not isHD then
		hdSnapshot = {
			Lighting = cloneProps(Lighting, {"EnvironmentDiffuseScale","EnvironmentSpecularScale","ExposureCompensation","Technology","Ambient","Brightness"}),
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
			Contrast = (Effects.ColorCorrection.Contrast or 0) + 0.14,
			Saturation = (Effects.ColorCorrection.Saturation or 0) + 0.10,
			Brightness = math.clamp((Effects.ColorCorrection.Brightness or 0) + 0.01, -0.02, 0.12),
		})
		tweenProps(Effects.Bloom, {
			Intensity = math.min(1, (Effects.Bloom.Intensity or 0.12) * 1.25),
			Size = (Effects.Bloom.Size or 14) + 3,
			Threshold = math.max(SAFE.BloomThreshMin, (Effects.Bloom.Threshold or 0.97) - 0.03),
		})
		tweenProps(Effects.DOF, {
			InFocusRadius = math.max(SAFE.MinInFocus, (Effects.DOF.InFocusRadius or 50) + 8),
			FarIntensity = math.min(SAFE.MaxDOFFar, (Effects.DOF.FarIntensity or 0) + 0.02),
		})
		tweenProps(Effects.SunRays, {Intensity = math.clamp((Effects.SunRays.Intensity or 0.02) + 0.02, 0, 1)})
		tweenProps(Effects.Atmosphere, {
			Density = math.clamp((Effects.Atmosphere.Density or 0.25) + 0.04, 0, 1),
			Haze = (Effects.Atmosphere.Haze or 1.0) + 0.15,
			Glare = math.clamp((Effects.Atmosphere.Glare or 0.05) + 0.04, 0, 1),
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
				Lighting = hdSnapshot.Lighting,
				Color = hdSnapshot.Color,
				Bloom = hdSnapshot.Bloom,
				DOF = hdSnapshot.DOF,
				SunRays = hdSnapshot.SunRays,
				Atmosphere = hdSnapshot.Atmos,
			}, true)
		end
		isHD = false
		styleHd(false)
	end
end

HdBtn.MouseButton1Click:Connect(function() setHD(not isHD) end)

-- Utility buttons
ResetBtn.MouseButton1Click:Connect(function()
	if isHD then setHD(false) end
	resetAll()
end)
MinBtn.MouseButton1Click:Connect(function() Main.Visible=false; Orb.Visible=true end)
Orb.MouseButton1Click:Connect(function() Main.Visible=true; Orb.Visible=false end)

-- Keyboard toggles (pakai CAS biar tidak ngetik 'k' di textbox)
local function setMainVisible(v)
	Main.Visible = v
	Orb.Visible = not v
end

local function toggleUI()
	if not ScreenGui.Enabled then return end -- hormati key gate / cancel
	setMainVisible(not Main.Visible)
end

-- Bind K = toggle UI, H = toggle HD, F = fokus search
ContextActionService:BindAction(
	"RTX_ToggleUI",
	function(_, state)
		if state == Enum.UserInputState.Begin then toggleUI() end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.K
)

ContextActionService:BindAction(
	"RTX_ToggleHD",
	function(_, state)
		if state == Enum.UserInputState.Begin then setHD(not isHD) end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.H
)

ContextActionService:BindAction(
	"RTX_FocusSearch",
	function(_, state)
		if state == Enum.UserInputState.Begin and Main.Visible then
			SearchBox:CaptureFocus()
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.F
)


-- Quality change handler: reapply + guard
if okUGS and UserGameSettings then
	local function onQualityChanged()
		if currentPreset then applyPreset(currentPreset, true) else visualGuard(true) end
	end
	pcall(function() UserGameSettings:GetPropertyChangedSignal("QualityLevel"):Connect(onQualityChanged) end)
	pcall(function() UserGameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(onQualityChanged) end)
end

-- ====================================================================
-- RTX Weather - KEY GATE (enter key before accessing Weather UI)
-- Default key: "WeatherAxa"
-- ====================================================================
local ACCESS_KEY = "WeatherAxa"
local REMEMBER_ATTR = "RTXWeatherKeyOK"

-- Kunci UI Weather sampai key benar
ScreenGui.Enabled = false

-- Jika sesi ini sudah pernah verifikasi, buka langsung
if PlayerGui:GetAttribute(REMEMBER_ATTR) == true then
	ScreenGui.Enabled = true
else
	-- Blur latar saat gate tampil
	local KeyBlur = Instance.new("BlurEffect")
	KeyBlur.Name = "_RTX_KeyBlur"
	KeyBlur.Size = 18
	KeyBlur.Parent = Lighting

	local KeyGui = Instance.new("ScreenGui")
	KeyGui.Name = "RTXKeyGateUI"
	KeyGui.ResetOnSpawn = false
	KeyGui.IgnoreGuiInset = true
	KeyGui.DisplayOrder = 9999
	KeyGui.Parent = PlayerGui

	local Overlay = Instance.new("Frame")
	Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	Overlay.BackgroundTransparency = 0.35
	Overlay.Size = UDim2.fromScale(1,1)
	Overlay.Parent = KeyGui

	local Card = Instance.new("Frame")
	Card.Size = UDim2.fromOffset(420, 240)
	Card.AnchorPoint = Vector2.new(0.5,0.5)
	Card.Position = UDim2.fromScale(0.5, 0.5)
	Card.BackgroundColor3 = Color3.fromRGB(24,24,28)
	Card.Parent = Overlay
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0,14)

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = 1
	Stroke.Color = Color3.fromRGB(60,60,72)
	Stroke.Transparency = 0.2
	Stroke.Parent = Card

	local Title = Instance.new("TextLabel")
	Title.BackgroundTransparency = 1
	Title.Size = UDim2.new(1, -32, 0, 32)
	Title.Position = UDim2.new(0, 16, 0, 16)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextColor3 = Color3.fromRGB(235,235,245)
	Title.Text = "Enter Access Key"
	Title.Parent = Card

	local Sub = Instance.new("TextLabel")
	Sub.BackgroundTransparency = 1
	Sub.Size = UDim2.new(1, -32, 0, 20)
	Sub.Position = UDim2.new(0, 16, 0, 48)
	Sub.Font = Enum.Font.Gotham
	Sub.TextSize = 14
	Sub.TextXAlignment = Enum.TextXAlignment.Left
	Sub.TextColor3 = Color3.fromRGB(170,175,190)
	Sub.Text = "Masukkan key untuk membuka Weather by Axa."
	Sub.Parent = Card

	local Input = Instance.new("TextBox")
	Input.Size = UDim2.new(1, -32, 0, 40)
	Input.Position = UDim2.new(0, 16, 0, 86)
	Input.Font = Enum.Font.GothamSemibold
	Input.TextSize = 16
	Input.PlaceholderText = "Enter key here"
	Input.PlaceholderColor3 = Color3.fromRGB(135,140,155)
	Input.Text = ""
	Input.TextColor3 = Color3.fromRGB(235,235,245)
	Input.BackgroundColor3 = Color3.fromRGB(32,32,38)
	Input.ClearTextOnFocus = false
	Input.Parent = Card
	Instance.new("UICorner", Input).CornerRadius = UDim.new(0,10)

	local InputStroke = Instance.new("UIStroke")
	InputStroke.Thickness = 1
	InputStroke.Color = Color3.fromRGB(70,80,110)
	InputStroke.Transparency = 0.25
	InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	InputStroke.Parent = Input

	local RememberBtn = Instance.new("TextButton")
	RememberBtn.Size = UDim2.new(0, 20, 0, 20)
	RememberBtn.Position = UDim2.new(0, 16, 0, 136)
	RememberBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
	RememberBtn.Text = ""
	RememberBtn.AutoButtonColor = false
	RememberBtn.Parent = Card
	Instance.new("UICorner", RememberBtn).CornerRadius = UDim.new(0,5)

	local RememberTick = Instance.new("Frame")
	RememberTick.Size = UDim2.fromScale(0.6, 0.6)
	RememberTick.AnchorPoint = Vector2.new(0.5,0.5)
	RememberTick.Position = UDim2.fromScale(0.5,0.5)
	RememberTick.BackgroundColor3 = Color3.fromRGB(120,200,255)
	RememberTick.Visible = false
	RememberTick.Parent = RememberBtn
	Instance.new("UICorner", RememberTick).CornerRadius = UDim.new(0,3)

	local RememberLbl = Instance.new("TextLabel")
	RememberLbl.BackgroundTransparency = 1
	RememberLbl.Size = UDim2.new(1, -44, 0, 20)
	RememberLbl.Position = UDim2.new(0, 40, 0, 136)
	RememberLbl.Font = Enum.Font.Gotham
	RememberLbl.TextSize = 14
	RememberLbl.TextXAlignment = Enum.TextXAlignment.Left
	RememberLbl.Text = "Remember this session"
	RememberLbl.TextColor3 = Color3.fromRGB(185,190,205)
	RememberLbl.Parent = Card

	local Status = Instance.new("TextLabel")
	Status.BackgroundTransparency = 1
	Status.Size = UDim2.new(1, -32, 0, 18)
	Status.Position = UDim2.new(0, 16, 1, -86)
	Status.Font = Enum.Font.Gotham
	Status.TextSize = 13
	Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.TextColor3 = Color3.fromRGB(200,120,120)
	Status.Text = ""
	Status.Parent = Card

	local Verify = Instance.new("TextButton")
	Verify.Size = UDim2.new(0, 120, 0, 36)
	Verify.Position = UDim2.new(1, -136, 1, -52)
	Verify.Text = "Verify"
	Verify.Font = Enum.Font.GothamSemibold
	Verify.TextSize = 16
	Verify.TextColor3 = Color3.fromRGB(20,30,45)
	Verify.BackgroundColor3 = Color3.fromRGB(120,200,255)
	Verify.AutoButtonColor = true
	Verify.Parent = Card
	Instance.new("UICorner", Verify).CornerRadius = UDim.new(0,10)

	local Cancel = Instance.new("TextButton")
	Cancel.Size = UDim2.new(0, 120, 0, 36)
	Cancel.Position = UDim2.new(1, -268, 1, -52)
	Cancel.Text = "Cancel"
	Cancel.Font = Enum.Font.GothamSemibold
	Cancel.TextSize = 16
	Cancel.TextColor3 = Color3.fromRGB(230,235,245)
	Cancel.BackgroundColor3 = Color3.fromRGB(45,48,56)
	Cancel.AutoButtonColor = true
	Cancel.Parent = Card
	Instance.new("UICorner", Cancel).CornerRadius = UDim.new(0,10)

	local function hover(btn, c1, c0)
		btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = c1}):Play() end)
		btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2),  {BackgroundColor3 = c0}):Play() end)
	end
	hover(Verify, Color3.fromRGB(140,208,255), Color3.fromRGB(120,200,255))
	hover(Cancel, Color3.fromRGB(60,64,74), Color3.fromRGB(45,48,56))

	local remember = false
	local function setRemember(v)
		remember = v and true or false
		RememberTick.Visible = remember
	end
	RememberBtn.MouseButton1Click:Connect(function() setRemember(not remember) end)
	RememberLbl.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 then setRemember(not remember) end end)

	local function shakeCard()
		local p0 = Card.Position
		local seq = {
			UDim2.new(p0.X.Scale, p0.X.Offset-8, p0.Y.Scale, p0.Y.Offset),
			UDim2.new(p0.X.Scale, p0.X.Offset+8, p0.Y.Scale, p0.Y.Offset),
			p0
		}
		local t = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		for i=1,#seq do TweenService:Create(Card, t, {Position = seq[i]}):Play() task.wait(0.06) end
	end

	local function unlock()
		Status.Text = ""
		TweenService:Create(KeyBlur, TweenInfo.new(0.25), {Size = 0}):Play()
		TweenService:Create(Overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
		TweenService:Create(Card, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
		task.delay(0.24, function()
			KeyGui:Destroy()
			if KeyBlur and KeyBlur.Parent then KeyBlur:Destroy() end
		end)
		if remember then PlayerGui:SetAttribute(REMEMBER_ATTR, true) end
		ScreenGui.Enabled = true
	end

	local function dismissGate()
		TweenService:Create(KeyBlur, TweenInfo.new(0.25), {Size = 0}):Play()
		TweenService:Create(Overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
		TweenService:Create(Card, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
		task.delay(0.24, function()
			if KeyGui and KeyGui.Parent then KeyGui:Destroy() end
			if KeyBlur and KeyBlur.Parent then KeyBlur:Destroy() end
		end)
		ScreenGui.Enabled = false
	end

	local function validate()
		local txt = (Input.Text or ""):gsub("^%s+",""):gsub("%s+$","")
		if txt == "" then
			Status.Text = "Key belum diisi."
			shakeCard()
			return
		end
		if txt == ACCESS_KEY then
			unlock()
		else
			Status.Text = "Key salah. Coba lagi."
			shakeCard()
		end
	end

	Verify.MouseButton1Click:Connect(validate)
	Cancel.MouseButton1Click:Connect(dismissGate)
	Input.FocusLost:Connect(function(enterPressed) if enterPressed then validate() end end)
	task.defer(function() Input:CaptureFocus() end)
end
-- ====================================================================
