--[[ Globals ]]--

SlackerCore = {}
SlackerCore.DoRecording = nil

SLASH_SlackerChecker1 = "/slacker"

--[[ SAVED VARIABLES ]]--

SlackerChecker_DB = nil
SlackerChecker_Version = nil

--[[ Event and command handling ]]--

local Database = nil

local function DoRecording(reason)
	local ingroup = IsInGroup(LE_PARTY_CATEGORY_HOME) 
	local iid, iname, zid = SlackerHelper.instance_get_info()
	if not ingroup
	then
		error({message="Not in group."})
	end
	if not iid
	then
		error({message="No instance found."})
	end
	if not Database
	then
		error({message="Database error"})
	end
	local reset = SlackerHelper.instance_get_reset(iname) 
	local localtime = time()
	local owner = UnitName("player");
	local uuidprefix = SlackerHelper.int_to_hex(localtime,8).."-"..SlackerHelper.int_to_hex(zid,4)
	local dungeon = Database:get_dungeon_matching(owner, localtime, zid, iid, reset)
	if dungeon
	then
		if dungeon:get_zone_id()==0
		then
			dungeon:set_zone_id(zid)
		end
	else
		local ver = GetAddOnMetadata(SlackerHelper.Addon, "Version");
		local uuid = SlackerHelper.get_uuid4( uuidprefix )
		dungeon = SlackerData.Dungeon.new(owner, localtime, iname, iid, zid, reset, uuid, ver)
		Database:add_dungeon(dungeon)
	end
	local uuid = SlackerHelper.get_uuid4( uuidprefix )
	local snapshot = SlackerData.Snapshot.new(reason, localtime, uuid)
	local inraid = IsInRaid()
	for index=1,MAX_RAID_MEMBERS,1
	do  
		local player = nil
		local subgroup
		local class
		local online
		local _
		local unit
		if inraid
		then
			unit = string.format("raid%d", index)
			player, _, subgroup, _, _, _, _, online = GetRaidRosterInfo(index);
		else 
			if (index <= MAX_PARTY_MEMBERS)
			then
				unit = string.format("party%d", index)
			elseif (index == (MAX_PARTY_MEMBERS+1))
			then
				unit = "player"
			else
				break
			end
			player = UnitName(unit)
			online = UnitIsConnected(unit)
			subgroup = 1
		end
		if player 
		then
			_, class, _ = UnitClass(unit)
			class = class:sub(1,1):upper()..class:sub(2):lower()
			local player = SlackerData.Player.new(player, class, subgroup, index, online )
			local i = 1;
			local name, _, _, _, _, _, _, _, _, spellId, _, _, _ = UnitBuff(unit, i);
			while name and i<=64 do
				i = i + 1;
				local buff = SlackerData.Buff.new(spellId)
				player:add_buff(buff)
				name, _, _, _, _, _, _, _, _, spellId, _, _, _ = UnitBuff(unit, i);
			end
			snapshot:add_player(player)
		end
	end
	Database:add_snapshot(dungeon, snapshot)
	return snapshot
end


function SlackerCore.DoRecording(reason)
	local status, ret = pcall(DoRecording,reason);
	if not status
	then
		SlackerHelper.error(ret.message or ret)
		ret = nil
	else
		SlackerHelper.info("Recording buffs: " .. reason) 
	end
	return ret
end

local addon_loaded = false
local dbm_loaded = false

local function ProcessCommand(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd
	then
		cmd = cmd:lower()
	end
	if cmd == "show"
	then
		SlackerUI_MainWindow:Show() 
	elseif cmd == "report" 
	then
		if SlackerUI.Reports.ReportAvailable("snapshot", args)
		then
			local snapshot = SlackerCore.DoRecording("Report "..args)
			if snapshot
			then
				SlackerUI.Reports.GenerateReport("snapshot", args, snapshot)
			end
		else
			SlackerHelper.error("Invalid report id")
		end
	elseif cmd == "manual" 
	then
		SlackerCore.DoRecording("Manual recording")
	elseif cmd == "reset" 
	then
		Database:reset()
		SlackerHelper.info("Database reset.")
	elseif cmd == "debug" 
	then
		if (args=="on")
		then
			SlackerHelper.set_setting("debug",true)
			SlackerHelper.info("Debug enabled")
		else
			SlackerHelper.set_setting("debug",false)
			SlackerHelper.info("Debug disbled")
		end
	else
		SlackerHelper.info("Syntax: " .. SLASH_SlackerChecker1 .. " ( show | manual | report snap-reportname | reset )");
	end
end

local function DBMCallback(event, mod)
	local name = "Unknown"
	local action = strsub(event, 5)
	if mod and mod["id"]
	then
		name = mod["id"]
	end
	if action == "Pull" and SlackerHelper.get_setting("record_pull")
	then
		SlackerCore.DoRecording("Pull on " .. name)
	elseif action == "Wipe" and SlackerHelper.get_setting("record_wipe")
	then
		SlackerCore.DoRecording("Wipe on " .. name)
	elseif action == "Kill" and SlackerHelper.get_setting("record_kill")
	then
		SlackerCore.DoRecording("Kill on " .. name)
	end
end

local function RegisterDBM()
	if (not dbm_loaded) and (DBM)
	then
		dbm_loaded = true
		DBM:RegisterCallback("DBM_Pull", DBMCallback)
		DBM:RegisterCallback("DBM_Wipe", DBMCallback)
		DBM:RegisterCallback("DBM_Kill", DBMCallback)
	end
end

local function CheckVersion()
	local ver = GetAddOnMetadata(SlackerHelper.Addon, "Version")
	if ver ~= SlackerChecker_Version
	then
		if SlackerChecker_Version==nil or SlackerHelper.starts_with(SlackerChecker_Version, "0.")
		then
			SlackerHelper.set_setting("dbmaintain", "all") -- keep all entries
			if SlackerChecker_DB -- upgrade old structure
			then
				SlackerHelper.info("Upgrading old database")
				for i=1,#SlackerChecker_DB,1
				do
					local dungeon_raw = SlackerChecker_DB[i]
					local uuidprefix = SlackerHelper.int_to_hex(dungeon_raw["date"],8).."-"..SlackerHelper.int_to_hex(0,4)
					dungeon_raw["snap"] = dungeon_raw["data"]
					dungeon_raw["data"] = nil
					dungeon_raw["zid"] = 0
					dungeon_raw["uuid"] = SlackerHelper.get_uuid4( uuidprefix )
					for j=1,#dungeon_raw["snap"],1
					do
						local snapshot_raw = dungeon_raw["snap"][j]
						snapshot_raw["uuid"] = SlackerHelper.get_uuid4( uuidprefix )
					end
				end
			end
		end
	end
	SlackerChecker_Version = ver
end

local function AddSlideIcon()
	if LibStub then
		local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
		if not LibDataBroker then return end
		local LDBButton = LibDataBroker:NewDataObject(SlackerHelper.Addon, {
					type = "launcher",
					icon = "Interface\\Icons\\Ability_Stealth",
					OnClick = function(self, button) 
						if button == "RightButton" then
							SlackerCore.DoRecording("Manual recording")
						else
							SlackerUI.MainWindow.ToggleWindow() 
						end
					end,
					})

		function LDBButton:OnTooltipShow()
			self:AddLine(SlackerHelper.Addon,  1,1,0.5, 1)
			self:AddLine(GetAddOnMetadata(SlackerHelper.Addon, "Notes"),  1,1,0.5, 1)
			self:AddLine("Left click to toggle main window.",  1,1,0.5, 1)
			self:AddLine("Right click to do manual recording.",  1,1,0.5, 1)
		end
		function LDBButton:OnEnter()
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
			GameTooltip:ClearLines()
			LDBButton.OnTooltipShow(GameTooltip)
			GameTooltip:Show()
		end
		function LDBButton:OnLeave()
			GameTooltip:Hide()
		end
	end
end

local function MaintainDB()
	local dbmaintain = SlackerHelper.get_setting("dbmaintain") or ""
	if SlackerHelper.starts_with(dbmaintain, "num")
	then
		local num = tonumber(strsub(dbmaintain,4))
		print("maintain num: " .. num)
		Database:remove_dungeon_maxnum(num)
	elseif SlackerHelper.starts_with(dbmaintain, "time")
	then
		local days = tonumber(strsub(dbmaintain,5))
		local timestamp = time() - days*86400
		Database:remove_dungeon_older(timestamp)
	end
end

local function Init()
	if (not addon_loaded)
	then
		addon_loaded = true
		CheckVersion()
		SlackerChecker_DB = SlackerChecker_DB or {}
		Database = SlackerData.Database.new(SlackerChecker_DB)
		MaintainDB()
		AddSlideIcon()
		SlackerUI.MainWindow.SetDatabase(Database)
		SlackerUI.Settings.RegisterFrames()
		SlackerHelper.load_colors()
		SlashCmdList[SlackerHelper.Addon] = ProcessCommand
		RegisterDBM()
	end
end

local function OnReadyCheck()
	if SlackerHelper.get_setting("record_readycheck")
	then
		SlackerCore.DoRecording("Ready Check")
	end
end

local function OnEvent(self, event, arg1)
	if event == "READY_CHECK_FINISHED"
	then
		OnReadyCheck()
	elseif event == "ADDON_LOADED" and arg1 == SlackerHelper.Addon
	then
		Init()
	elseif event == "ADDON_LOADED" and arg1 == "DBM-Core"
	then
		RegisterDBM()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK_FINISHED")
frame:SetScript("OnEvent", OnEvent)



