ROTracker_Continued = {
	name = "ROTracker_Continued",

	-- Default settings
	defaults = {
		left = 1000,
		top = 500,
		maxRows = 6,
		givenSlayer = true;
		colors = {
			["slayer"] = {
				0, 1, 0, 1,
			},
			["cooldown"] = {
				0, .5, 0, 1,
			},
		},
	},

	roleIcons = {
		[LFG_ROLE_DPS] = "/esoui/art/lfg/lfg_icon_dps.dds",
		[LFG_ROLE_TANK] = "/esoui/art/lfg/lfg_icon_tank.dds",
		[LFG_ROLE_HEAL] = "/esoui/art/lfg/lfg_icon_healer.dds",
		[LFG_ROLE_INVALID] = "/esoui/art/crafting/gamepad/crafting_alchemy_trait_unknown.dds",
	},

	enabled = false,
	groupSize = 0,
	canReceiveCount = 0,
	activeRO = 0,
	lastLength = 0,
	topTimer = 0,
	RO = false,
	units = { },
	panels = { },
}

function ROTracker_Continued.OnAddOnLoaded( eventCode, addonName )
	if (addonName ~= ROTracker_Continued.name) then return end
	EVENT_MANAGER:UnregisterForEvent(ROTracker_Continued.name, EVENT_ADD_ON_LOADED)

	ROTracker_Continued.vars = ZO_SavedVars:NewCharacterIdSettings("ROTracker_ContinuedSavedVariables", 1, nil, ROTracker_Continued.defaults, GetWorldName())
	ROTracker_Continued.InitializeControls()

	ROTracker_Continued.setupMenu()
	ROTracker_Continued.gearUpdate()

	EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_PLAYER_ACTIVATED, ROTracker_Continued.CheckActivation)
	EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_RAID_TRIAL_STARTED, ROTracker_Continued.CheckActivation)
	EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name.."GearUpdate", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, ROTracker_Continued.gearUpdate)
	EVENT_MANAGER:AddFilterForEvent(ROTracker_Continued.name.."GearUpdate", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
end

function ROTracker_Continued.CheckActivation( eventCode )
	-- Check wiki.esoui.com/AvA_Zone_Detection if we want to enable this for PvP
	ROTracker_Continued.Reset()

		-- Workaround for when the game reports that the player is not in a group shortly after zoning
	if (ROTracker_Continued.groupSize == 0) then
		zo_callLater(ROTracker_Continued.Reset, 5000)
	end
	if (not ROTracker_Continued.enabled) then
		ROTracker_Continued.enabled = true
		EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_GROUP_MEMBER_JOINED, ROTracker_Continued.GroupUpdate)
		EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_GROUP_MEMBER_LEFT, ROTracker_Continued.GroupUpdate)
		EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_GROUP_MEMBER_ROLE_CHANGED, ROTracker_Continued.GroupMemberRoleChanged)
		EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_GROUP_SUPPORT_RANGE_UPDATE, ROTracker_Continued.GroupSupportRangeUpdate)
		EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_EFFECT_CHANGED, ROTracker_Continued.EffectChanged)

		SCENE_MANAGER:GetScene("hud"):AddFragment(ROTracker_Continued.fragment)
		SCENE_MANAGER:GetScene("hudui"):AddFragment(ROTracker_Continued.fragment)
	end
end

function ROTracker_Continued.GroupUpdate( eventCode )
	zo_callLater(ROTracker_Continued.Reset, 500)
end

function ROTracker_Continued.GroupMemberRoleChanged( eventCode, unitTag, newRole )
	if (ROTracker_Continued.units[unitTag]) then
		ROTracker_Continued.panels[ROTracker_Continued.units[unitTag].panelId].role:SetTexture(ROTracker_Continued.roleIcons[newRole])
	end
end

function ROTracker_Continued.GroupSupportRangeUpdate( eventCode, unitTag, status )
	if (ROTracker_Continued.units[unitTag]) then
		ROTracker_Continued.UpdateRange(ROTracker_Continued.units[unitTag].panelId, status)
	end
end

function ROFade(unitTag)
	if(ROTracker_Continued.units[unitTag]) then
		ROTracker_Continued.units[unitTag].timer = ROTracker_Continued.units[unitTag].timer - 1.0;
		if(ROTracker_Continued.topTimer > ROTracker_Continued.units[unitTag].timer) then
			ROTracker_Continued.topTimer = math.max(ROTracker_Continued.units[unitTag].timer, 0)
			ROTracker_ContinuedFrameTime:SetText(ROTracker_Continued.topTimer)
		end
		ROTracker_Continued.panels[ROTracker_Continued.units[unitTag].panelId].name:SetText(GetUnitDisplayName(unitTag) .. " " .. ROTracker_Continued.units[unitTag].timer)
		if(ROTracker_Continued.units[unitTag].timer <= 2) then
			-- We can now register this person can receive RO again
			if(not ROTracker_Continued.units[unitTag].canReceive) then
				ROTracker_Continued.units[unitTag].canReceive = true
				ROTracker_Continued.canReceiveCount = ROTracker_Continued.canReceiveCount + 1
				ROTracker_ContinuedFrameReceive:SetText(ROTracker_Continued.canReceiveCount)
			end

			if(ROTracker_Continued.units[unitTag].timer <= 0) then
				ROTracker_Continued.units[unitTag].timer = 0;
				ROTracker_Continued.UpdateStatus(unitTag)
				EVENT_MANAGER:UnregisterForUpdate("ROTracker_ContinuedCooldown"..unitTag)
			end
		end
	end
end

function ROTracker_Continued.EffectChanged( eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType )
	-- Ensure the source i	s from the player (unless set to allow for everyone)
	if (true) then
		-- Ensure this is the RO buff and that the player recieving it is in the group / being tracked
		if (ROTracker_ContinuedData.effects[abilityId] and ROTracker_Continued.units[unitTag]) then
			if (changeType == EFFECT_RESULT_FADED) then
				if (ROTracker_Continued.units[unitTag].effects[abilityId]) then
					ROTracker_Continued.units[unitTag].count = ROTracker_Continued.units[unitTag].count - 1
					ROTracker_Continued.UpdateStatus(unitTag)
				end
				ROTracker_Continued.units[unitTag].effects[abilityId] = nil
			elseif (stackCount >= ROTracker_ContinuedData.effects[abilityId]) then
				if (not ROTracker_Continued.units[unitTag].effects[abilityId]) then
					ROTracker_Continued.canReceiveCount = ROTracker_Continued.canReceiveCount - 1
					ROTracker_ContinuedFrameReceive:SetText(ROTracker_Continued.canReceiveCount)
					if(ROTracker_Continued.topTimer == 0) then
						ROTracker_Continued.topTimer = 22
						ROTracker_ContinuedFrameTime:SetText(ROTracker_Continued.topTimer)
					end
					ROTracker_Continued.lastLength = endTime - beginTime
					ROTracker_Continued.units[unitTag].timer = 22.0
					ROTracker_Continued.units[unitTag].canReceive = false
					ROTracker_Continued.panels[ROTracker_Continued.units[unitTag].panelId].name:SetText(GetUnitDisplayName(unitTag) .. " 22")
					EVENT_MANAGER:RegisterForUpdate("ROTracker_ContinuedCooldown"..unitTag, 1000, function() ROFade(unitTag) end)
					ROTracker_Continued.units[unitTag].count = ROTracker_Continued.units[unitTag].count + 1
					ROTracker_Continued.UpdateStatus(unitTag)
				end
				ROTracker_Continued.units[unitTag].effects[abilityId] = endTime
			end

			if (ROTracker_Continued.debug) then
				local entry = string.format("[%d] [%d/%d] %s - %d/%s/%d - %d", changeType, GetTimeStamp(), GetGameTimeMilliseconds(), GetUnitDisplayName(unitTag), abilityId, effectName, endTime, ROTracker_Continued.units[unitTag].count)
				table.insert(ROTracker_Continued.vars.debug, entry)
				if (ROTracker_Continued.units[unitTag].self) then
					CHAT_SYSTEM:AddMessage(entry)
				end
			end
		end
	end
end

function ROTracker_Continued.AttributeVisualChanged( eventCode, unitTag, unitAttributeVisual, _, _, _, value, newValue )
	if (unitAttributeVisual == ATTRIBUTE_VISUAL_TRAUMA) then
		if (eventCode == EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED) then
			ROTracker_Continued.units[unitTag].trauma = value
		elseif (eventCode == EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED) then
			ROTracker_Continued.units[unitTag].trauma = 0
		elseif (eventCode == EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED) then
			ROTracker_Continued.units[unitTag].trauma = newValue
		end
		ROTracker_Continued.UpdateStatus(unitTag)
	end
end

function ROTracker_Continued.OnMoveStop( )
	ROTracker_Continued.vars.left = ROTracker_ContinuedFrame:GetLeft()
	ROTracker_Continued.vars.top = ROTracker_ContinuedFrame:GetTop()
end

function ROTracker_Continued.InitializeControls( )
	local wm = GetWindowManager()

	for i = 1, GROUP_SIZE_MAX do
			local panel = wm:CreateControlFromVirtual("ROTracker_ContinuedPanel" .. i, ROTracker_ContinuedFrame, "ROTracker_ContinuedPanel")

		ROTracker_Continued.panels[i] = {
			panel = panel,
			bg = panel:GetNamedChild("Backdrop"),
			name = panel:GetNamedChild("Name"),
			role = panel:GetNamedChild("Role"),
			stat = panel:GetNamedChild("Stat"),
		}

		ROTracker_Continued.panels[i].bg:SetEdgeColor(0, 0, 0, 0)
		ROTracker_Continued.panels[i].bg:SetCenterColor(0, 0, 0, .5)
		ROTracker_Continued.panels[i].stat:SetColor(1, 0, 1, 1)
	end

	ROTracker_ContinuedFrame:ClearAnchors()
	ROTracker_ContinuedFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, ROTracker_Continued.vars.left, ROTracker_Continued.vars.top)

	ROTracker_Continued.fragment = ZO_HUDFadeSceneFragment:New(ROTracker_ContinuedFrame)
end

function ROTracker_Continued.Reset( )
	if (ROTracker_Continued.debug) then
		CHAT_SYSTEM:AddMessage("[RO Tracker] Resetting")
	end

	ROTracker_Continued.groupSize = GetGroupSize()
	ROTracker_Continued.canReceiveCount = GetGroupSize()
	ROTracker_Continued.units = { }

	for i = 1, GROUP_SIZE_MAX do
		local soloPanel = i == 1 and ROTracker_Continued.groupSize == 0

		if (i <= ROTracker_Continued.groupSize or soloPanel) then
			local unitTag = (soloPanel) and "player" or GetGroupUnitTagByIndex(i)

			ROTracker_Continued.units[unitTag] = {
				panelId = i,
				count = 0,
				effects = { },
				trauma = 0,
				timer = 0.0,
				self = AreUnitsEqual("player", unitTag),
				canReceive = true,
			}

			ROTracker_ContinuedFrameReceive:SetText(ROTracker_Continued.canReceiveCount)

			ROTracker_Continued.panels[i].name:SetText(GetUnitDisplayName(unitTag) .. " 0")
			ROTracker_Continued.panels[i].role:SetTexture(ROTracker_Continued.roleIcons[GetGroupMemberSelectedRole(unitTag)])

			ROTracker_Continued.UpdateStatus(unitTag)
			ROTracker_Continued.UpdateRange(i, IsUnitInGroupSupportRange(unitTag))

			if(not ROTracker_Continued.RO) then
				ROTracker_Continued.panels[i].panel:SetHidden(true)
			else
				ROTracker_Continued.panels[i].panel:SetHidden(false)
			end
		else

			ROTracker_Continued.panels[i].name:SetText("")
			ROTracker_Continued.panels[i].role:SetTexture(ROTracker_Continued.roleIcons[LFG_ROLE_INVALID])

			if(i > 12 or not ROTracker_Continued.RO) then
				ROTracker_Continued.panels[i].panel:SetHidden(true)
			else
				ROTracker_Continued.panels[i].panel:SetHidden(false)
			end
		end

		if (i == 1) then
			ROTracker_Continued.panels[i].panel:SetAnchor(TOPLEFT, ROTracker_ContinuedFrame, TOPLEFT, 0, 0)
		elseif (i <= ROTracker_Continued.vars.maxRows) then
			ROTracker_Continued.panels[i].panel:SetAnchor(TOPLEFT, ROTracker_Continued.panels[i - 1].panel, BOTTOMLEFT, 0, 0)
		else
			ROTracker_Continued.panels[i].panel:SetAnchor(TOPLEFT, ROTracker_Continued.panels[i - ROTracker_Continued.vars.maxRows].panel, TOPRIGHT, 0, 0)
		end

	end
end

function ROTracker_Continued.UpdateStatus( unitTag )
	local bg = ROTracker_Continued.panels[ROTracker_Continued.units[unitTag].panelId].bg

	if (ROTracker_Continued.units[unitTag].count < 1) then
		if(ROTracker_Continued.units[unitTag].timer > 0) then
			bg:SetCenterColor(unpack(ROTracker_Continued.vars.colors.cooldown))
		else
			bg:SetCenterColor(0, 0, 0, 0.5)
		end
	else
		bg:SetCenterColor(unpack(ROTracker_Continued.vars.colors.slayer))
	end

	local stat = ROTracker_Continued.panels[ROTracker_Continued.units[unitTag].panelId].stat

	if (ROTracker_Continued.units[unitTag].trauma == 0) then
		stat:SetText("")
	else
		stat:SetText(string.format("%dk", (ROTracker_Continued.units[unitTag].trauma + 500) / 1000))
	end
end

function ROTracker_Continued.UpdateRange( panelId, status )
	if (status) then
		ROTracker_Continued.panels[panelId].panel:SetAlpha(1)
	else
		ROTracker_Continued.panels[panelId].panel:SetAlpha(0.4)
	end
end

function ROTracker_Continued.gearUpdate()
	ROTracker_Continued.RO = ROTracker_Continued.hasRO()
	if ROTracker_Continued.RO then
		ROTracker_ContinuedFrameReceive:SetHidden(false)
		ROTracker_ContinuedFrameTime:SetHidden(false)
	else
		ROTracker_ContinuedFrameReceive:SetHidden(true)
		ROTracker_ContinuedFrameTime:SetHidden(true)
	end
	for i = 1, 12 do
		if(not ROTracker_Continued.RO) then
			ROTracker_Continued.panels[i].panel:SetHidden(true)
		else
			ROTracker_Continued.panels[i].panel:SetHidden(false)
		end
	end
end

local types = {
	[1] = "|H1:item:162508:364:50:45884:370:50:0:0:0:0:0:0:0:0:1:0:0:1:0:0:0|h|h",
	[2] = "|H1:item:162044:363:50:0:0:0:0:0:0:0:0:0:0:0:1:102:0:1:0:10000:0|h|h",
}

function ROTracker_Continued.hasRO()
	local np, p = 0, 0
	_,_,_,np,_,_,p = GetItemLinkSetInfo(types[1], true)
	if (np >= 3) or (p >= 3) then return true end
	return false
end

EVENT_MANAGER:RegisterForEvent(ROTracker_Continued.name, EVENT_ADD_ON_LOADED, ROTracker_Continued.OnAddOnLoaded)
