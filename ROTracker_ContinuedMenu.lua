function ROTracker_Continued.setupMenu()
	local LAM = LibAddonMenu2

	local panelData = {
		type = "panel",
		name = "RO Tracker Continued",
		displayName = "|cFFD700RO Tracker|r",
		author = "Kalinfe, Rytira",
		version = "1.1.3",
		registerForRefresh = true
	}

	LAM:RegisterAddonPanel("ROTracker_ContinuedOptions", panelData)

	local options = {
		{
			type = "header",
			name = "Options"
		},
		{
			type = "checkbox",
			name = "Given Slayer Only",
			tooltip = "Only displays procs caused by yourself if turned on",
			getFunc = function() return ROTracker_Continued.vars.givenSlayer end,
			setFunc = function(value) ROTracker_Continued.vars.givenSlayer = value end,
		},
		{
			type = "colorpicker",
			name = "Slayer Color",
			tooltip = "Color of the player when they have Major Slayer",
			warning = "Color changes go into effect next time Major Slayer is lost or gained",
			getFunc = function() return unpack(ROTracker_Continued.vars.colors.slayer) end,
			setFunc = function(r,g,b,a) ROTracker_Continued.vars.colors.slayer = {r,g,b,a} end,
		},
		{
			type = "colorpicker",
			name = "Cooldown Color",
			tooltip = "Color of the player when they are on Major Slayer Cooldown (But do not currently have slayer)",
			warning = "Color changes go into effect next time Major Slayer is lost or gained",
			getFunc = function() return unpack(ROTracker_Continued.vars.colors.cooldown) end,
			setFunc = function(r,g,b,a) ROTracker_Continued.vars.colors.cooldown = {r,g,b,a} end,
		},
	}

	LAM:RegisterOptionControls("ROTracker_ContinuedOptions", options)
end
