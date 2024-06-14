local _, LatencyLens = ...
local L = LatencyLens.L

LatencyLens:RegisterSettings("LatencyLensDB", {
	{
		key = "enableStats",
		type = "toggle",
		title = "Toggle LatencyLens",
		tooltip = "Toggle to display the stats.",
		default = false,
	},
	{
		key = "noLabel",
		type = "toggle",
		title = "Hide Labels",
		tooltip = "Toggle to hide labels and show only values.",
		default = false,
	},
	{
		key = "classColorText",
		type = "toggle",
		title = "Class Color Text",
		tooltip = "Toggle to show values in class color.",
		default = false,
	},
})

LatencyLens:RegisterSettingsSlash("/ll")
