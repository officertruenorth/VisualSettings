Config = {}

-- Chat commands
Config.StyleCommand      = 'visualstyle'   -- /visualstyle [off|vanilla]
Config.BrightnessCommand = 'brightness'    -- /brightness [low|medium|high]
Config.DebugCommand      = 'visualsdebug'  -- /visualsdebug

-- What new players start on
Config.DefaultStyle      = 'vanilla'
Config.DefaultBrightness = 'high'

-- Visual styles, in the order they are listed to players.
--   file = nil   Off: nothing is applied, the game's own Enhanced visual settings are used.
-- GTA V Enhanced blocks local graphics mods, so there are no VisualV or VisualVanilla styles.
-- Styles whose file is missing from the resource are hidden automatically.
Config.Styles = {
	{ id = 'off',     label = 'Off',     file = nil },
	{ id = 'vanilla', label = 'Vanilla', file = 'styles/vanilla.dat' },
}

-- Emergency light brightness, applied on top of the style (not used with Off).
-- A profile with no file keeps the style's own values.
Config.Brightness = {
	{ id = 'low',    label = 'Low',    file = 'brightness/low.dat' },
	{ id = 'medium', label = 'Medium', file = 'brightness/medium.dat' },
	{ id = 'high',   label = 'High',   file = nil },
}

-- Keys in the .dat files that are never applied
Config.Skip = {
	['weather.CycleDuration'] = true,
}
