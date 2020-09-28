--[[ Globals ]]--

SlackerChecker_Addon = "SlackerChecker"
SlackerChecker_DateFormat = "%Y-%m-%d %H:%M:%S"
SlackerChecker_Debug = false
SlackerChecker_Loaded = false
SlackerChecker_DBM_Loaded = false
SlackerChecker_LastRaidInstance = nil -- iid, time

SLASH_SlackerChecker1 = "/slacker"

--[[ SAVED VARIABLES ]]--

SlackerChecker_DB = nil

--[[
SlackerChecker_DB = {
	{
		["ver"] = str, -- addon version
		["date"] = datetime, -- first encounter, ordered by this
		["iid"] = int, -- instance id
		["iname"] = str, -- instance
		["reset"] = datetime, -- reset timer
		["owner"] = str, -- creator character
		["data"] = { -- data entries
			{
				["d"] = datetime, -- date of reccording
				["r"] = str, -- reaseon
				["p"] = { -- players
					{
						["i"] = int, -- index
						["o"] = int, -- online 0/1
						["g"] = int, -- group
						["n"] = str, -- name
						["c"] = str, -- class, localized
						["b"] = { -- active buffs
							{
								["id"] =  int, -- spell id
								["e"] = int -- expiration in seconds
							}, 
							...
						},
					},
					...
				},
			},
			...
		},
	},
	...
}

--]]

--[[ Code ]]--

local frame = CreateFrame("Frame")
--frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK_FINISHED")

local function LastRaidInfo()
	local localtime = time()
	local name, instanceType, _, _, maxPlayers, _, _, instanceID = GetInstanceInfo()
	if (maxPlayers>=20) or (SlackerChecker_Debug and instanceID == 389)
	then
		SlackerChecker_LastRaidInstance = {}
		SlackerChecker_LastRaidInstance["time"] = localtime
		SlackerChecker_LastRaidInstance["iid"] = instanceID
		SlackerChecker_LastRaidInstance["name"] = name
		return instanceID, name
	else
		if SlackerChecker_LastRaidInstance and (localtime-SlackerChecker_LastRaidInstance["time"]<1800) -- entered an instance in the last 30 mins
		then
			return SlackerChecker_LastRaidInstance["iid"], SlackerChecker_LastRaidInstance["name"]
		else
			SlackerChecker_LastRaidInstance = nil
		end
	end
	return nil, nil
end

local function GetRaidReset(iname)
	local localtime = time()
	local numInstances = GetNumSavedInstances()
	for raidIndex=1,numInstances,1
	do
		name, id, reset = GetSavedInstanceInfo(raidIndex)
		if iname == name
		then
			return localtime+reset
		end
	end
	return 0
end

local function IID2Str(iid)
	local InstanceMapID = {
		[0]="Eastern Kingdoms",
        [1]="Kalimdor",
        [389]="Ragefire Chasm",
        [309]="Zul'Gurub ",
        [509]="Ruins of Ahn'Qiraj",
        [249]="Onyxia's Lair",
        [409]="Molten Core",
        [469]="Blackwing Lair",
        [531]="Ahn'Qiraj",
        [533]="Naxxramas"
    }
	for k, v in pairs(InstanceMapID) do
		if iid == k 
		then 
			return v 
		end
	end
	return "Unknown"
end

local function DoRecording(reason)
	local raidId, raidName = LastRaidInfo()
	if not raidId
	then
		return false
	end
	print("Recording buffs: " .. reason .. ".") 
	local localtime = time()
	local runtime = GetTime()
	local playerName = UnitName("player");
	local players = {}
	for raidIndex=1,MAX_RAID_MEMBERS,1
	do  
		local player, _, subgroup, _, class, _, _, online = GetRaidRosterInfo(raidIndex);
		if player 
		then
			local playerEntry = {}
			local buffs = {}
			local target = string.format("raid%d", raidIndex)
			local i = 1;
			local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(target, i);
			while name and i<100 do
				i = i + 1;
				expire = expirationTime-runtime
				if (expirationTime<0) then
					expire = 0
				end
				local buff = {}
				buff["id"] = spellId
				buff["e"] = expire
				table.insert(buffs, buff)
				name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(target, i);
			end;
			local o = 0
			if online then o = 1 end
			playerEntry["i"] = raidIndex
			playerEntry["n"] = player
			playerEntry["g"] = subgroup
			playerEntry["o"] = o
			playerEntry["b"] = buffs
			playerEntry["c"] = class
			table.insert(players, playerEntry)
		end
	end
	local reset = GetRaidReset(raidName) 
	local insert = {}
	insert["d"] = localtime
	insert["r"] = reason
	insert["p"] = players
	if SlackerChecker_DB == nil
	then
		SlackerChecker_DB = {}
	end
	for i=#SlackerChecker_DB,1,-1
	do
		local tmpDate = SlackerChecker_DB[i]["date"]
		local tmpReset = SlackerChecker_DB[i]["reset"]
		local tmpId = SlackerChecker_DB[i]["iid"]
		local tmpOwner = SlackerChecker_DB[i]["owner"]
		if (localtime-tmpDate)>604800 -- older than a week
		then
			break
		-- find first entry with same instance id that has (reset=0 and localtime-date<3600) or reset>localtime
		elseif (tmpId == raidId) and (tmpOwner == playerName) and ((tmpReset==0 and (localtime-tmpDate<3600)) or (tmpReset>localtime))
		then
			table.insert(SlackerChecker_DB[i]["data"], insert)
			SlackerChecker_DB[i]["reset"] = math.max(reset, tmpReset)
			return true
		end
    end
	local entry = {}
	entry["iid"] = raidId
	entry["iname"] = raidName
	entry["date"] = localtime
	entry["reset"] = reset
	entry["owner"] = playerName
	entry["ver"] = GetAddOnMetadata(SlackerChecker_Addon, "Version");
	entry["data"] = {}
	table.insert(entry["data"], insert)
	table.insert(SlackerChecker_DB, entry)
	return true
end

local function ResetDB()
	SlackerChecker_DB = nil
end

local function ProcessCommand(cmd)
	if cmd == "show"
	then
		SlackerChecker_Frame:Show() 
	elseif cmd == "manual" 
	then
		if not DoRecording("Manual recording")
		then
			print("Error: Not in raid instance.")
		end
	elseif cmd == "reset" 
	then
		ResetDB()
		print("Database reset")
	elseif cmd == "debug" 
	then
		SlackerChecker_Debug = true
		print("Debug enabled")
	else
		print("Syntax: " .. SLASH_SlackerChecker1 .. " ( show | manual | reset )");
	end
end

local function DBMCallback(event, mod)
	local name = "Unknown"
	local action = strsub(event, 5)
	if mod and mod["id"]
	then
		name = mod["id"]
	end
	DoRecording(action .. " on " .. name)
end

local function RegisterDBM()
	if (not SlackerChecker_DBM_Loaded) and (DBM)
	then
		SlackerChecker_DBM_Loaded = true
		DBM:RegisterCallback("DBM_Pull", DBMCallback)
		DBM:RegisterCallback("DBM_Wipe", DBMCallback)
		DBM:RegisterCallback("DBM_Kill", DBMCallback)
	end
end

local function OnReadyCheck()
	DoRecording("Ready Check")
end

local function Init()
	if (not SlackerChecker_Loaded)
	then
		SlackerChecker_Loaded = true
		SlashCmdList[SlackerChecker_Addon] = ProcessCommand
		RegisterDBM()
	end
end

local function OnEvent(self, event, arg1)
	if event == "READY_CHECK_FINISHED"
	then
		OnReadyCheck()
	elseif event == "ADDON_LOADED" and arg1 == SlackerChecker_Addon
	then
		Init()
	elseif event == "ADDON_LOADED" and arg1 == "DBM-Core"
	then
		RegisterDBM()
	end
end

frame:SetScript("OnEvent", OnEvent)

--[[ UI ]]--

local RefreshUI = nil
local SelectInstance = nil

local function ShowTooltip(parent, text)
	GameTooltip:SetOwner(parent, "ANCHOR_TOPRIGHT");
	GameTooltip:SetText( text )
	GameTooltip:Show()
end

local function ShowTooltipSpell(parent, name, description, expire)
	GameTooltip:SetOwner(parent, "ANCHOR_TOPRIGHT");
	local text = string.format("%s", name, description)
	if (expire>0) 
	then
		text =  text .. string.format("\n%ds", expire)
	end
	GameTooltip:SetText( text, 1, 1, 1, 1, true )
	GameTooltip:Show()
end

local function HideTooltip()
	GameTooltip:Hide()
end

local function ClearInstance()
	local children = { SlackerChecker_Frame_InstanceList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function ClearData()
	local children = { SlackerChecker_Frame_DataList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function ClearPlayer()
	local children = { SlackerChecker_Frame_PlayerList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function DeleteInstance(index)
	table.remove(SlackerChecker_DB, index)
	RefreshUI()
end

local function DeleteData(index,index2)
	table.remove(SlackerChecker_DB[index]["data"], index2)
	SelectInstance(index)
end

local function SelectData(index, index2)
	ClearPlayer()
	local children = { SlackerChecker_Frame_DataList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		if (#children+1-i) == index2
		then
			child.Selected:Show()
		else
			child.Selected:Hide()
		end
	end
	local set = SlackerChecker_DB[index]["data"][index2]["p"]
	local num = #set
	local y = 0
	for i=1,num,1
	do
		local f = CreateFrame("Frame", nil, SlackerChecker_Frame_PlayerList_ScrollChild, "SlackerChecker_PlayerEntry")
		f:SetPoint("TOPLEFT", 0, y );
		local offlinesuff = ""
		if set[i]["o"] == 0 then offlinesuff=" (off)" end
		f.Player:SetText(string.format("%s (grp %d)%s",set[i]["n"], set[i]["g"], offlinesuff) )
		local buffs = set[i]["b"]
		local xx = 170
		local yy = 0
		for j=1,#buffs,1
		do
			local spellid = buffs[j]["id"]
			local expire = buffs[j]["e"]
			if (j==21) -- new row for buffs
			then
				f:SetHeight(33)
				y = y-17
				xx = 170
				yy = -17
			end	
			local name, _, icon = GetSpellInfo(spellid)
			local description = GetSpellDescription(spellid)
			local b = CreateFrame("Frame",nil,f)
			b:SetWidth(16)
			b:SetHeight(16)
			local t = b:CreateTexture(nil,"BACKGROUND")
			t:SetTexture(icon)
			t:SetAllPoints(b)
			b.texture = t
			b:SetPoint("TOPLEFT", xx, yy );
			b.tooltip = { ["name"]=name, ["description"]=description, ["expire"]=expire}
			b:HookScript("OnEnter", function(self) ShowTooltipSpell(self, self.tooltip.name, self.tooltip.description, self.tooltip.expire) end)
			b:HookScript("OnLeave", HideTooltip)
			b:EnableMouse(true)
			b:Show()
			xx = xx + 17
		end
		y = y-18
	end
	
end

SelectInstance = function(index)
	ClearData()
	ClearPlayer()
	local children = { SlackerChecker_Frame_InstanceList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		if (#children+1-i) == index
		then
			child.Selected:Show()
		else
			child.Selected:Hide()
		end
	end
	local set = SlackerChecker_DB[index]["data"]
	local num = #set
	for i=1,num,1
	do
		local index2 = num+1-i
		local f = CreateFrame("Frame", nil, SlackerChecker_Frame_DataList_ScrollChild, "SlackerChecker_MenuEntry")
		f.index = index
		f.index2 = index2
		f:SetPoint("TOPLEFT", 0, -34*(i-1) );
		f:HookScript("OnMouseDown", function(self) SelectData(self.index, self.index2) end)
		f.DateTime:SetText(date(SlackerChecker_DateFormat, set[index2]["d"])) 
		f.Instance:SetText(set[index2]["r"])
		f.DeleteButton:HookScript("OnClick", function(self) DeleteData(self:GetParent().index, self:GetParent().index2) end)
	end
end

RefreshUI = function()
	-- Clear all lists
	ClearInstance()
	ClearData()
	ClearPlayer()
	-- Populate left list, Order by date, latest on top
	if (not SlackerChecker_DB) then return end
	local num = #SlackerChecker_DB
	for i=1,num,1
	do
		local index = num+1-i
		local f = CreateFrame("Frame", nil, SlackerChecker_Frame_InstanceList_ScrollChild, "SlackerChecker_MenuEntry")
		f.index = index
		f:SetPoint("TOPLEFT", 0, -34*(i-1) );
		f:HookScript("OnMouseDown", function(self) SelectInstance(self.index) end)
		f.DateTime:SetText(date(SlackerChecker_DateFormat, SlackerChecker_DB[index]["date"])) 
		f.Instance:SetText(IID2Str(SlackerChecker_DB[index]["iid"]))
		f.DeleteButton:HookScript("OnClick", function(self) DeleteInstance(self:GetParent().index) end)
	end
end

function SlackerChecker_Frame_Reset()
	StaticPopupDialogs["SlackerChecker_ConfirmReset"] = {
		text = "Do you want to reset the database?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			ResetDB()
			RefreshUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3
	}
	StaticPopup_Show("SlackerChecker_ConfirmReset")
end

function SlackerChecker_Frame_OnShow()
	RefreshUI()


end
