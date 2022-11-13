function ROTracker.setupMenu()
	local LAM = LibStub("LibAddonMenu-2.0")

	local panelData = {
		type = "panel",
		name = "RO Tracker",
		displayName = "|cFFD700RO Tracker|r",
		author = "Kalinfe",
		version = "1.0.0",
		registerForRefresh = true
	}

	LAM:RegisterAddonPanel("ROTrackerOptions", panelData)

	local options = {
		{
			type = "header",
			name = "Options"
		},
		{
			type = "checkbox",
			name = "Given Slayer Only",
			tooltip = "Only displays procs caused by yourself if turned on",
			getFunc = function() return ROTracker.vars.givenSlayer end,
			setFunc = function(value) ROTracker.vars.givenSlayer = value end,
		},
		{
			type = "colorpicker",
			name = "Slayer Color",
			tooltip = "Color of the player when they have Major Slayer",
			warning = "Color changes go into effect next time Major Slayer is lost or gained",
			getFunc = function() return unpack(ROTracker.vars.colors.slayer) end,
			setFunc = function(r,g,b,a) ROTracker.vars.colors.slayer = {r,g,b,a} end,
		},
		{
			type = "colorpicker",
			name = "Cooldown Color",
			tooltip = "Color of the player when they are on Major Slayer Cooldown (But do not currently have slayer)",
			warning = "Color changes go into effect next time Major Slayer is lost or gained",
			getFunc = function() return unpack(ROTracker.vars.colors.cooldown) end,
			setFunc = function(r,g,b,a) ROTracker.vars.colors.cooldown = {r,g,b,a} end,
		},
	}

	LAM:RegisterOptionControls("ROTrackerOptions", options)
end
