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
								["e"] = int -- expiration in seconds DEPRECATED
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

local GenerateReport = nil

local InstanceMapIDLookup = {
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

local ClassToColorLookup = {
	-- TODO: other locals as well
	["Offline"] = { ["r"] = 0.50, ["g"] = 0.50, ["b"] = 0.50, ["a"] = 1.0 },
	["Druid"]   = { ["r"] = 1.00, ["g"] = 0.49, ["b"] = 0.04, ["a"] = 1.0 },
	["Hunter"]  = { ["r"] = 0.67, ["g"] = 0.83, ["b"] = 0.45, ["a"] = 1.0 },
	["Mage"]    = { ["r"] = 0.41, ["g"] = 0.80, ["b"] = 0.94, ["a"] = 1.0 },
	["Paladin"] = { ["r"] = 0.96, ["g"] = 0.55, ["b"] = 0.73, ["a"] = 1.0 },
	["Priest"]  = { ["r"] = 1.00, ["g"] = 1.00, ["b"] = 1.00, ["a"] = 1.0 },
	["Rogue"]   = { ["r"] = 1.00, ["g"] = 0.96, ["b"] = 0.41, ["a"] = 1.0 },
	["Shaman"]  = { ["r"] = 0.96, ["g"] = 0.55, ["b"] = 0.73, ["a"] = 1.0 },
	["Warlock"] = { ["r"] = 0.58, ["g"] = 0.51, ["b"] = 0.79, ["a"] = 1.0 },
	["Warrior"] = { ["r"] = 0.78, ["g"] = 0.61, ["b"] = 0.43, ["a"] = 1.0 },
}

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
	if InstanceMapIDLookup[iid] ~= nil
	then
		return InstanceMapIDLookup[iid]
	end
	return "Unknown"
end

local function ClassToColor(classStr)
	if ClassToColorLookup[classStr] ~= nil
	then
		return ClassToColorLookup[classStr]
	end
	return { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5,	["a"] = 1.0 }
end

local function DoRecording(reason)
	local raidId, raidName = LastRaidInfo()
	if not raidId
	then
		return nil
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
				-- buff["e"] = expire
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
			return insert
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
	return insert
end

local function ResetDB()
	SlackerChecker_DB = nil
end

local function ProcessCommand(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	cmd = cmd:lower()
	if cmd == "show"
	then
		SlackerChecker_Frame:Show() 
	elseif cmd == "report" 
	then
		local t = string.upper(strsub(args,1,4))
		if t=="SNAP"
		then
			local snapshot = DoRecording("Report "..args)
			if snapshot
			then
				GenerateReport(args, snapshot)
			end
		else
			print("Only snapshot reports are supported")
		end
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
		print("Syntax: " .. SLASH_SlackerChecker1 .. " ( show | manual | report snap-reportname | reset )");
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

local ScrollingTablePlayers = nil
local LastIndex1 = nil
local LastIndex2 = nil

local RefreshUI = nil
local SelectInstance = nil

SlackerChecker_Frame_ReportContext = nil

local function ShowTooltip(parent, text)
	GameTooltip:SetOwner(parent, "ANCHOR_TOPRIGHT");
	GameTooltip:SetText( text )
	GameTooltip:Show()
end

local function ShowTooltipSpell(parent, name, description, spellid)
	local gtt = GameTooltip
	gtt:SetOwner(parent, "ANCHOR_TOPRIGHT");
	gtt:ClearLines()
	gtt:AddLine(name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, false)
	gtt:AddLine(description, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1, true)
	if SlackerChecker_Debug
	then
		gtt:AddLine(spellid, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1, true)
	end
	for i=1,gtt:NumLines() do
        local lineL = _G["GameTooltipTextLeft"..tostring(i)]
        local lineR = _G["GameTooltipTextRight"..tostring(i)]
        local fontNameL, fontSizeL = lineL:GetFont()
        if fontNameL == nil or fontSizeL == 0 then
            lineL:SetFont("Fonts\\FRIZQT__.TTF", i==1 and 14 or 12)
            lineL:SetJustifyH("LEFT")
        end
        local fontNameR, fontSizeR = lineR:GetFont()
        if fontNameR == nil or fontSizeR == 0 then
            lineR:SetFont("Fonts\\FRIZQT__.TTF", i==1 and 14 or 12)
            lineR:SetJustifyH("RIGHT")
        end
    end 
	gtt:Show()
end

local function HideTooltip()
	GameTooltip:Hide()
end

local function ClearInstance()
	LastIndex1 = nil
	local children = { SlackerChecker_Frame_InstanceList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function ClearData()
	LastIndex2 = nil
	local children = { SlackerChecker_Frame_DataList_ScrollChild:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function ClearPlayer()
	ScrollingTablePlayers:Hide();
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
	LastIndex1 = index
	LastIndex2 = index2
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
	local data = {}
	for i=1,#set,1
	do
		local offlinetext = ""
		local color = ClassToColor(set[i]["c"])
		if set[i]["o"] == 0 
		then 
			offlinetext=" (off)" 
			color = ClassToColor("Offline")
		end
		
		local name = {
			["value"] = string.format("%s%s",set[i]["n"], offlinetext),
			["color"] = color
		}
		local class = {
			["value"] = set[i]["c"],
			["color"] = color
		}
		local group = {
			["value"] = set[i]["g"]
		}
		local buffs = {
			["value"] = set[i]["b"]
		}
		local row = { ["cols"] = {name, class, group, buffs} }
		table.insert(data, row)
	end
	ScrollingTablePlayers:SetData(data);
	ScrollingTablePlayers:Refresh();
	ScrollingTablePlayers:Show();
end

local function CompareBuffs(first, second)
	first = first["id"]
	second = second["id"]
	firstprio = SlackerChecker_BuffPriorityLookup[tostring(first)] or 0
	secondprio = SlackerChecker_BuffPriorityLookup[tostring(second)] or 0
	if (firstprio ~= secondprio)
	then
		return firstprio > secondprio
	end
	return first < second
end

local function DoCellUpdateBuff(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, st, ...)
	local children = { cellFrame:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
	if fShow
	then
		local buffs = st:GetCell(realrow,column)["value"]
		local sortedbuffs = {}
		for j=1,#buffs,1 do table.insert(sortedbuffs, buffs[j]) end
		table.sort( sortedbuffs, CompareBuffs )
		local x = 0
		local colwidth = cellFrame:GetWidth()
		local width = colwidth/#sortedbuffs-1
		width = math.min(16, width)
		for j=1,#sortedbuffs,1
		do
			local spellid = sortedbuffs[j]["id"]
			local name, _, icon = GetSpellInfo(spellid)
			local description = GetSpellDescription(spellid)
			local b = CreateFrame("Frame",nil,cellFrame)
			b:SetWidth(width)
			b:SetHeight(width)
			local t = b:CreateTexture(nil,"BACKGROUND")
			t:SetTexture(icon)
			t:SetAllPoints(b)
			b.texture = t
			b:SetPoint("TOPLEFT", x, -1*(18-width)/2 );
			b.tooltip = { ["id"]=spellid, ["name"]=name, ["description"]=description }
			b:HookScript("OnEnter", function(self) ShowTooltipSpell(self, self.tooltip.name, self.tooltip.description, self.tooltip.id) end)
			b:HookScript("OnLeave", HideTooltip)
			b:EnableMouse(true)
			b:Show()
			x = x + width+1
		end
	end
end

local function NoSort(self, rowa, rowb, sortbycol) 
	return rowa<rowb;
end

local function InitTable()
	if ScrollingTablePlayers ~= nil
	then
		return
	end
	local ScrollingTable = LibStub("ScrollingTable");
	local cols = { 
		{
			["name"] = "Name",
			["width"] = 84,
			["align"] = "LEFT",
			["sort"] = "dsc",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Class",
			["width"] = 60,
			["align"] = "LEFT",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Gr",
			["width"] = 20,
			["align"] = "LEFT",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Buffs",
			["width"] = 336,
			["align"] = "LEFT",
			["comparesort"] = NoSort,
			["DoCellUpdate"] = DoCellUpdateBuff
		}, 
	}
	ScrollingTablePlayers = ScrollingTable:CreateST(cols, 32, 18, nil, SlackerChecker_Frame_PlayerList)
end

SelectInstance = function(index)
	ClearData()
	ClearPlayer()
	LastIndex1 = index
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
		f:HookScript("OnMouseDown", function(self, button) if button=="RightButton" then SlackerChecker_Frame_ReportContext("cursor",self.index, self.index2) else SelectData(self.index, self.index2) end end)
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
		local name = SlackerChecker_DB[index]["owner"] or "Old version"
		f.index = index
		f:SetPoint("TOPLEFT", 0, -34*(i-1) );
		f:HookScript("OnMouseDown", function(self, button) if button=="RightButton" then SlackerChecker_Frame_ReportContext("cursor",self.index) else SelectInstance(self.index) end end)
		f.DateTime:SetText(date(SlackerChecker_DateFormat, SlackerChecker_DB[index]["date"])) 
		f.Instance:SetText( string.format("%s (%s)", IID2Str(SlackerChecker_DB[index]["iid"]), name) )
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
	InitTable()
	RefreshUI()
end

local function ShowReport(title, cols, data, btn1, btn2)
	SlackerChecker_Report:Hide()
	local children = { SlackerChecker_Report_Table:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
	SlackerChecker_Report_Button1:Hide()
	SlackerChecker_Report_Button2:Hide()
	SlackerChecker_Report_Title:SetText(title)
	local ScrollingTable = LibStub("ScrollingTable");
	local tbl = ScrollingTable:CreateST(cols, 30, 18, nil, SlackerChecker_Report_Table)
	tbl:SetData(data);
	tbl:Refresh();
	tbl:Show();
	local width = math.max(tbl.frame:GetWidth()+40, 200)
	if btn1 ~= nil
	then
		SlackerChecker_Report_Button1:SetText(btn1.text)
		SlackerChecker_Report_Button1:SetScript("OnClick", btn1.callback)
		SlackerChecker_Report_Button1:Show()
	end
	if btn2 ~= nil
	then
		SlackerChecker_Report_Button2:SetText(btn1.text)
		SlackerChecker_Report_Button2:SetScript("OnClick", btn1.callback)
		SlackerChecker_Report_Button2:Show()
	end
	SlackerChecker_Report:SetWidth(width)
	SlackerChecker_Report:Show()
	
end

SlackerChecker_Frame_ReportContext = function(parent, index, index2)
	local isButton = (index==nil and index2==nil)
	local dropDown = SlackerChecker_Frame_ContextMenu
	local options = { 
		{["id"] = "raid-missing-buffs", ["name"] = "Missing Buffs on Pull"},
		{["id"] = "snap-worldbuffs", ["name"] = "Worldbuffs"},
		{["id"] = "snap-consumes", ["name"] = "Flasks, Consumes, Food"},
		{["id"] = "snap-missing-buffs", ["name"] = "Missing Buffs"}
	}
	local shown = {}
	for i=1,#options,1
	do
		local entry = options[i]
		entry.index = nil
		entry.index2 = nil
		local t = string.upper(strsub(entry.id,1,4))
		if isButton and LastIndex1 ~=nil and t=="RAID"
		then
			entry.name = t.." "..entry.name
			entry.index = LastIndex1
			table.insert(shown, entry)
		elseif isButton and LastIndex1 ~=nil and LastIndex2 ~=nil and t=="SNAP"
		then
			entry.name = t.." "..entry.name
			entry.index = LastIndex1
			entry.index2 = LastIndex2
			table.insert(shown, entry)
		elseif not isButton and index ~= nil and index2 == nil and t=="RAID"
		then
			entry.index = index
			table.insert(shown, entry)
		elseif not isButton and index ~= nil and index2 ~= nil and t=="SNAP"
		then
			entry.index = index
			entry.index2 = index2
			table.insert(shown, entry)
		end
	end
	UIDropDownMenu_Initialize(dropDown, 
	function()
		for i=1,#shown,1
		do
			local entry = shown[i]
			local info = { 
				["text"]=entry.name, 
				["value"]=entry.id,
				["arg1"]=entry,
				["notCheckable"]=true,
				["func"]=
				function(self, entry) 
					local data=nil
					if entry.index ~= nil and entry.index2 ~= nil
					then 
						data = SlackerChecker_DB[entry.index]["data"][entry.index2]
					elseif entry.index ~= nil 
					then
						data = SlackerChecker_DB[entry.index]
					end 
					GenerateReport(entry.id, data)
				end
			}
			UIDropDownMenu_AddButton(info)
		end
		local info = {
			["text"]="Cancel",
			["notCheckable"]=true,
			["func"]=function(self) self:Hide() end
		}
		UIDropDownMenu_AddButton(info)
	end,
	"MENU")
	ToggleDropDownMenu(1, nil, dropDown, parent, 0, 0);
end

function SlackerChecker_IsDMFWeek(timestamp)
	-- DMF spawns the following monday after first friday of the month at daily reset time and lasts for a week.
	-- TODO: Regional offsets, reset time offsets, EU Monday 4am UTC reset time
	local weekday = tonumber(date("%w", timestamp), 10)
	local dotm = tonumber(date("%d", timestamp), 10)
	local monday = dotm-weekday+1
	local friday = monday-3
	return (1<=friday and friday<7)
end

local function CalculateAward(buffs, class, timestamp)
	local dmfup = SlackerChecker_IsDMFWeek(timestamp)
	local count = 0
	local dmt = 0
	for j=1,#buffs,1
	do
		local b = buffs[j]["id"]
		if b==22817 or b==22818 or b==22820 -- DMT buffs
		then
			dmt = dmt+1
		else
			count = count+1
		end
	end
	if dmt==3
	then
		count = count+1
	end
	if dmfup and count==6
	then
		return 50
	elseif not dmfup and count==5
	then
		return 50
	elseif 3<=count
	then
		return 20
	end
	return 0
end

local function CalculateAward2(buffs, class, timestamp)
	for j=1,#buffs,1
	do
		local b = buffs[j]["id"]
		if b==17624 or b==17626 or b==17627 or b==17628 or b==17629 -- Flasks
		then
			return 40
		end
	end
	return 0
end

GenerateReport = function(id, data)
	print(id)
	if id=="snap-worldbuffs"
	then
		local cols = { 
			{
				["name"] = "Name",
				["width"] = 84,
				["align"] = "LEFT",
				["sort"] = "dsc",
				["defaultsort"] = "asc",
			}, 
			{
				["name"] = "Class",
				["width"] = 60,
				["align"] = "LEFT",
				["defaultsort"] = "asc",
			}, 
			{
				["name"] = "Gr",
				["width"] = 20,
				["align"] = "LEFT",
				["defaultsort"] = "asc",
			}, 
			{
				["name"] = "Buffs",
				["width"] = 200,
				["align"] = "LEFT",
				["comparesort"] = NoSort,
				["DoCellUpdate"] = DoCellUpdateBuff
			}, 
		}
		if CalculateAward ~= nil
		then
			table.insert(cols, 4,
			{
				["name"] = "Award",
				["width"] = 40,
				["align"] = "LEFT",
				["defaultsort"] = "asc",
			})
		end
		local datatable = {}
		set=data["p"]
		for i=1,#set,1
		do
			local offlinetext = ""
			local color = ClassToColor(set[i]["c"])
			if set[i]["o"] == 0 
			then 
				offlinetext=" (off)" 
				color = ClassToColor("Offline")
			end
			local name = {
				["value"] = string.format("%s%s",set[i]["n"], offlinetext),
				["color"] = color
			}
			local class = {
				["value"] = set[i]["c"],
				["color"] = color
			}
			local group = {
				["value"] = set[i]["g"]
			}
			local buffsfiltered = {}
			for j=1,#set[i]["b"],1
			do
				local b = set[i]["b"][j]
				local p = SlackerChecker_BuffPriorityLookup[tostring(b["id"])] or 0
				if SlackerChecker_BuffPriority.WB4<=p and p<=SlackerChecker_BuffPriority.DMF
				then
					table.insert(buffsfiltered, b)
				end
			end
			local buffs = {
				["value"] = buffsfiltered
			}
			local row = { ["cols"] = {name, class, group, buffs} }
			if CalculateAward ~= nil
			then
				local awrd = { ["value"] = CalculateAward(buffsfiltered, set[i]["c"], data["d"]) }
				table.insert(row["cols"], 4, awrd)
			end
			table.insert(datatable, row)
		end
		--ShowReport(id, cols, datatable, {text="Hello", callback=function() print("World") end })
		ShowReport(id, cols, datatable)
	elseif id=="snap-consumes"
	then
		local cols = { 
			{
				["name"] = "Name",
				["width"] = 84,
				["align"] = "LEFT",
				["sort"] = "dsc",
				["defaultsort"] = "asc",
			}, 
			{
				["name"] = "Class",
				["width"] = 60,
				["align"] = "LEFT",
				["defaultsort"] = "asc",
			}, 
			{
				["name"] = "Gr",
				["width"] = 20,
				["align"] = "LEFT",
				["defaultsort"] = "asc",
			}, 
			{
				["name"] = "Flask",
				["width"] = 40,
				["align"] = "LEFT",
				["comparesort"] = NoSort,
				["DoCellUpdate"] = DoCellUpdateBuff
			}, 
			{
				["name"] = "Zanza",
				["width"] = 40,
				["align"] = "LEFT",
				["comparesort"] = NoSort,
				["DoCellUpdate"] = DoCellUpdateBuff
			}, 
			{
				["name"] = "Prot",
				["width"] = 60,
				["align"] = "LEFT",
				["comparesort"] = NoSort,
				["DoCellUpdate"] = DoCellUpdateBuff
			}, 
			{
				["name"] = "Consumes",
				["width"] = 120,
				["align"] = "LEFT",
				["comparesort"] = NoSort,
				["DoCellUpdate"] = DoCellUpdateBuff
			}, 
			{
				["name"] = "Food",
				["width"] = 40,
				["align"] = "LEFT",
				["comparesort"] = NoSort,
				["DoCellUpdate"] = DoCellUpdateBuff
			}, 
		}
		if CalculateAward2 ~= nil
		then
			table.insert(cols, 4,
			{
				["name"] = "Award",
				["width"] = 40,
				["align"] = "LEFT",
				["defaultsort"] = "asc",
			})
		end
		local datatable = {}
		set=data["p"]
		for i=1,#set,1
		do
			local offlinetext = ""
			local color = ClassToColor(set[i]["c"])
			if set[i]["o"] == 0 
			then 
				offlinetext=" (off)" 
				color = ClassToColor("Offline")
			end
			local name = {
				["value"] = string.format("%s%s",set[i]["n"], offlinetext),
				["color"] = color
			}
			local class = {
				["value"] = set[i]["c"],
				["color"] = color
			}
			local group = {
				["value"] = set[i]["g"]
			}
			local flask = {}
			local zanza = {}
			local prot = {}
			local cons = {}
			local food = {}
			local all = {}
			for j=1,#set[i]["b"],1
			do
				local b = set[i]["b"][j]
				local p = SlackerChecker_BuffPriorityLookup[tostring(b["id"])] or 0
				if p==SlackerChecker_BuffPriority.FLASK
				then
					table.insert(all, b)
					table.insert(flask, b)
				elseif p==SlackerChecker_BuffPriority.ZANZA
				then
					table.insert(all, b)
					table.insert(zanza, b)
				elseif p==SlackerChecker_BuffPriority.GPROT or p==SlackerChecker_BuffPriority.PROT
				then
					table.insert(all, b)
					table.insert(prot, b)
				elseif p==SlackerChecker_BuffPriority.CONS
				then
					table.insert(all, b)
					table.insert(cons, b)
				elseif p==SlackerChecker_BuffPriority.FOOD
				then
					table.insert(all, b)
					table.insert(food, b)
				end
			end
			flask = {["value"] = flask}
			zanza = {["value"] = zanza}
			prot = {["value"] = prot}
			cons = {["value"] = cons}
			food = {["value"] = food}
			local row = { ["cols"] = {name, class, group, flask, zanza, prot, cons, food} }
			if CalculateAward2 ~= nil
			then
				local awrd = { ["value"] = CalculateAward2(all, set[i]["c"], data["d"]) }
				table.insert(row["cols"], 4, awrd)
			end
			table.insert(datatable, row)
		end
		ShowReport(id, cols, datatable)
	else
		print("NotImplemented")
	end
end