--[[
	VisualSettings
	Applies the player's visual style once when the resource starts, then their
	brightness profile on top. Nothing runs afterwards (0.00 ms idle).
]]

local RESOURCE       = GetCurrentResourceName()
local KVP_STYLE      = 'visualsettings:style'
local KVP_BRIGHTNESS = 'visualsettings:profile'

local setVisualSetting = SetVisualSettingFloat or function(name, value)
	Citizen.InvokeNative(GetHashKey('SET_VISUAL_SETTING_FLOAT') & 0xFFFFFFFF, name, value)
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function index(list)
	local byId = {}
	for _, entry in ipairs(list) do byId[entry.id] = entry end
	return byId
end

local styleList = Config.Styles

local styles     = index(styleList)
local brightness = index(Config.Brightness)

local function fileExists(path)
	return path == nil or LoadResourceFile(RESOURCE, path) ~= nil
end

-- Reads a .dat file into a list of { key, value } pairs, in file order.
-- Accepts values written as "1.0" or "1.0f" and skips comments.
local function readDat(path)
	local text = LoadResourceFile(RESOURCE, path)
	if not text then return {} end

	local entries = {}
	for line in text:gmatch('[^\r\n]+') do
		local key, raw = line:match('^%s*(%S+)%s+(%S+)')
		if key and key:sub(1, 1) ~= '#' and key:sub(1, 2) ~= '//' and not Config.Skip[key] then
			local value = tonumber((raw:gsub('[fF]$', '')))
			if value then
				entries[#entries + 1] = { key, value }
			end
		end
	end
	return entries
end

local function applyDat(path)
	if not path then return 0 end
	local entries = readDat(path)
	for i = 1, #entries do
		setVisualSetting(entries[i][1], entries[i][2] + 0.0)
	end
	return #entries
end

local function notify(message)
	BeginTextCommandThefeedPost('STRING')
	AddTextComponentSubstringPlayerName(message)
	EndTextCommandThefeedPostTicker(false, false)
end

local function labels(list, onlyAvailable)
	local out = {}
	for _, entry in ipairs(list) do
		if not onlyAvailable or fileExists(entry.file) then
			out[#out + 1] = entry.label
		end
	end
	return table.concat(out, ', ')
end

-- Returns the saved choice (or the default) and whether one was saved.
local function saved(key, byId, default)
	local value = GetResourceKvpString(key)
	if byId[value] then return byId[value], true end
	return byId[default], false
end

-- ---------------------------------------------------------------------------
-- Apply on load
-- ---------------------------------------------------------------------------
local style = saved(KVP_STYLE, styles, Config.DefaultStyle) or styleList[1]
if not fileExists(style.file) then
	print(('^3[VisualSettings] %s is not available, using %s^7'):format(style.label, styles[Config.DefaultStyle].label))
	style = styles[Config.DefaultStyle]
end

local profile = saved(KVP_BRIGHTNESS, brightness, Config.DefaultBrightness)

if style.file then
	local styleCount   = applyDat(style.file)
	local profileCount = applyDat(profile.file)
	print(('[VisualSettings] Style %s (%d settings), brightness %s (%d changes)'):format(
		style.label, styleCount, profile.label, profileCount))
else
	print('[VisualSettings] Style Off, using the game\'s own visual settings')
end

-- ---------------------------------------------------------------------------
-- /visualstyle [off|vanilla|visualv|visualvanilla]
-- ---------------------------------------------------------------------------
RegisterCommand(Config.StyleCommand, function(_, args)
	local choice = args[1] and args[1]:lower()

	if not choice then
		notify(('Visual style: %s. Options: %s.'):format(style.label, labels(styleList, true)))
		return
	end

	local picked = styles[choice]
	if not picked or not fileExists(picked.file) then
		notify(('Unknown style. Choose from: %s.'):format(labels(styleList, true)))
		return
	end

	SetResourceKvp(KVP_STYLE, picked.id)

	if picked.id == style.id then
		notify(('Visual style is set to %s.'):format(picked.label))
		return
	end

	local message = ('Visual style set to %s. Restart FiveM to apply it.'):format(picked.label)
	if picked.requires then
		message = message .. (' Requires %s installed.'):format(picked.requires)
	end
	notify(message)
end, false)

-- ---------------------------------------------------------------------------
-- /brightness [low|medium|high]
-- ---------------------------------------------------------------------------
RegisterCommand(Config.BrightnessCommand, function(_, args)
	local choice = args[1] and args[1]:lower()

	if not choice then
		notify(('Brightness: %s. Options: %s.'):format(profile.label, labels(Config.Brightness)))
		return
	end

	local picked = brightness[choice]
	if not picked then
		notify(('Unknown option. Choose from: %s.'):format(labels(Config.Brightness)))
		return
	end

	SetResourceKvp(KVP_BRIGHTNESS, picked.id)

	if picked.id == profile.id then
		notify(('Brightness is set to %s.'):format(picked.label))
	elseif not style.file then
		notify(('Brightness set to %s. It applies when your visual style is not Off.'):format(picked.label))
	else
		notify(('Brightness set to %s. Reconnect to apply it.'):format(picked.label))
	end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.StyleCommand, 'Choose your visual style (applies after restarting FiveM)', {
	{ name = 'style', help = labels(styleList, true):lower() },
})
TriggerEvent('chat:addSuggestion', '/' .. Config.BrightnessCommand, 'Choose your emergency light brightness (applies when you reconnect)', {
	{ name = 'level', help = labels(Config.Brightness):lower() },
})

-- ---------------------------------------------------------------------------
-- /visualsdebug
-- Reads the files only when run, so it costs nothing the rest of the time.
-- ---------------------------------------------------------------------------
local function toMap(entries, into)
	into = into or {}
	for i = 1, #entries do
		into[entries[i][1]] = entries[i][2]
	end
	return into
end

RegisterCommand(Config.DebugCommand, function()
	local savedStyle, hasStyle      = saved(KVP_STYLE, styles, Config.DefaultStyle)
	local savedProfile, hasProfile  = saved(KVP_BRIGHTNESS, brightness, Config.DefaultBrightness)

	local function row(label, now, next, isSaved)
		print(('^5[VisualSettings]^7   %-11s %-14s next: %s%s'):format(label, now, next, isSaved and '' or ' (default)'))
	end

	print('^5[VisualSettings]^7 Current setup')
	row('Style', style.label, savedStyle.label, hasStyle)
	row('Brightness', profile.label, savedProfile.label, hasProfile)
	print(('^5[VisualSettings]^7   Available:  %s'):format(labels(styleList, true)))

	if savedStyle.id ~= style.id then
		print(('^3[VisualSettings]^7   Restart FiveM to switch to %s'):format(savedStyle.label))
	elseif savedProfile.id ~= profile.id and style.file then
		print(('^3[VisualSettings]^7   Reconnect to switch to %s'):format(savedProfile.label))
	end

	if not style.file then
		print('^5[VisualSettings]^7   Off: nothing is applied, your own visualsettings.dat is used.')
	else
		-- Every key a brightness profile changes, with the value in use and the style's value.
		local seen, keys = {}, {}
		for _, entry in ipairs(Config.Brightness) do
			if entry.file then
				for key in pairs(toMap(readDat(entry.file))) do
					if not seen[key] then seen[key] = true keys[#keys + 1] = key end
				end
			end
		end
		table.sort(keys)

		local base   = toMap(readDat(style.file))
		local active = toMap(readDat(style.file))
		if profile.file then toMap(readDat(profile.file), active) end

		for _, key in ipairs(keys) do
			print(('^5[VisualSettings]^7   %-36s %-8s (style %s)'):format(key, tostring(active[key]), tostring(base[key] or 'not set')))
		end
	end

	notify(('Style: %s | Brightness: %s. Details in F8.'):format(style.label, profile.label))
end, false)
