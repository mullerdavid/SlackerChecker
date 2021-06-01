SlackerUI.Reports = {}
SlackerUI.Reports.ReportData = nil
SlackerUI.Reports.ReportAvailable = nil
SlackerUI.Reports.GenerateReport = nil

function SlackerUI.Reports.ReportAvailable(typ, id)
	for i=1,#SlackerUI.Reports.ReportData,1
	do
		local report = SlackerUI.Reports.ReportData[i]
		if (typ==report["type"] and id==report["id"])
		then
			return true
		end
	end
	return false
end

function SlackerUI.Reports.GenerateReport(typ, id, data)
	for i=1,#SlackerUI.Reports.ReportData,1
	do
		local report = SlackerUI.Reports.ReportData[i]
		if (report.type==typ and report.id==id)
		then
			local report = SlackerUI.Reports.ReportData[i]
			report.func(data)
			return
		end
	end
	SlackerHelper.error("No report found.")
end

local function ShowReport(title, cols, data, btn1, btn2)
	local f = CreateFrame("Frame", nil, UIParent, "SlackerUI_ReportTemplate")
	f.Button1:Hide()
	f.Button2:Hide()
	f.Title:SetText(title)
	local ScrollingTable = LibStub("ScrollingTable");
	local tbl = ScrollingTable:CreateST(cols, 30, 18, nil, f.Table)
	tbl:SetData(data);
	tbl:Refresh();
	tbl:Show();
	local width = math.max(tbl.frame:GetWidth()+40, 200)
	if btn1 ~= nil
	then
		f.Button1:SetText(btn1.text)
		f.Button1:SetScript("OnClick", btn1.callback)
		f.Button1:Show()
	end
	if btn2 ~= nil
	then
		f.Button2:SetText(btn1.text)
		f.Button2:SetScript("OnClick", btn1.callback)
		f.Button2:Show()
	end
	f:SetWidth(width)
	f:Show()
end

local function AwardButton(datatable, indexname, indexaward, func, reason)
	return  {
		text="Award", 
		callback=function()
			SlackerUI.ConfirmDialog("Award the players?", 
			function() 
				for i=1,#datatable,1
				do
					local player = datatable[i]["cols"][indexname]["value"]
					local amount = datatable[i]["cols"][indexaward]["value"]
					if amount ~= nil and amount ~= 0
					then
						SlackerHelper.eval(func, {player=player, amount=amount, message=reason})
					end
				end
			end,
			"Continue",
			"Cancel"
			)
		end
	}
end

local function DungeonMissingBuffs(data)
	local cols = { 
		{
			["name"] = "Ind",
			["width"] = 50,
			["align"] = "LEFT",
			["sort"] = "dsc",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Snapshot",
			["width"] = 150,
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
			["name"] = "MotW",
			["width"] = 60,
			["align"] = "CENTER",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Intellect",
			["width"] = 60,
			["align"] = "CENTER",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Fortitude",
			["width"] = 60,
			["align"] = "CENTER",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Spirit",
			["width"] = 60,
			["align"] = "CENTER",
			["defaultsort"] = "asc",
		} 
	}
	local datatable = {}
	local i = 0
	for snapshot in data:get_snapshots_iterator()
	do
		local reason = snapshot:get_reason()
		if SlackerHelper.starts_with(reason, "Pull on ") 
		then
			i = i+1
			local snap = {
				["value"] = reason
			}
			local groups = {}
			local classes = {}
			for player in snapshot:get_players_iterator()
			do
				local group = player:get_group()
				local class = player:get_class()
				if groups[group]==nil
				then
					groups[group] = {}
				end
				table.insert(groups[group], player)
				classes[class] = true
			end
			for group,members in pairs(groups)
			do
				local index = {
					["value"] = string.format("%03d.%d",i, group)
				}
				local grp = {
					["value"] = group
				}
				local need =  { ["motw"] = 0, ["int"] = 0, ["stam"] = 0, ["spirit"] = 0 }
				local have =  { ["motw"] = 0, ["int"] = 0, ["stam"] = 0, ["spirit"] = 0 }
				for j=1,#members,1
				do
					local player = members[j]
					local class = player:get_class()
					local online = player:get_online()
					local isCaster = 0
					if SlackerHelper.in_array(class, {"Druid", "Mage", "Hunter", "Priest", "Shaman", "Warlock"}) -- is caster
					then
						isCaster = 1
					end
					if online
					then
						need["motw"] = need["motw"] + 1
						need["stam"] = need["stam"] + 1
						need["int"] = need["int"] + isCaster
						need["spirit"] = need["spirit"] + isCaster
						local buffs = player:get_all_buffs_idonly()
						for k=1,#buffs,1
						do
							local b = buffs[k]
							if b==9885 or b==21850 -- motw
							then
								have["motw"] = have["motw"] + 1
							elseif b==10157 or b==23028 -- int
							then
								have["int"] = have["int"] + isCaster
							elseif b==10938 or b==21564 -- fort
							then
								have["stam"] = have["stam"] + 1
							elseif b==27841 or b==27681 -- spirit
							then
								have["spirit"] = have["spirit"] + isCaster
							end
						end
					end
				end
				local haveClass =  { ["motw"] = classes["Druid"], ["int"] = classes["Mage"], ["stam"] = classes["Priest"], ["spirit"] = classes["Priest"] }
				local text =  { ["motw"] = "0", ["int"] = "0", ["stam"] = "0", ["spirit"] = "0" }
				local color =  { ["motw"] = nil, ["int"] = nil, ["stam"] = nil, ["spirit"] =nil }
				for i,v in ipairs({"motw", "int", "stam", "spirit"})
				do
					if haveClass[v] and 0<need[v]
					then
						text[v] = string.format("%d/%d",have[v],need[v])
						color[v] = { ["r"] = 0.14, ["g"] = 0.53, ["b"] = 0.14, ["a"] = 1.0 } -- green
						if have[v]==0
						then
							color[v] = { ["r"] = 0.82, ["g"] = 0.13, ["b"] = 0.18, ["a"] = 1.0 } -- red
						elseif have[v]<need[v]
						then
							color[v] = { ["r"] = 1.0, ["g"] = 0.75, ["b"] = 0.0, ["a"] = 1.0 } -- amber
						end
					end
				end
				local motw = {
					["value"] = text["motw"],
					["color"] = color["motw"]
				}
				local int = {
					["value"] = text["int"],
					["color"] = color["int"]
				}
				local stam = {
					["value"] = text["stam"],
					["color"] = color["stam"]
				}
				local spirit = {
					["value"] = text["spirit"],
					["color"] = color["spirit"]
				}
				local row = { ["cols"] = {index, snap, grp, motw, int, stam, spirit} }
				table.insert(datatable, row)
			end
		end
	end
	local title = "Missing Buffs for "..data:get_instance_name()
	ShowReport(title, cols, datatable)
end

local function SnapshotWorldBuffs(data)
	local CalculateAward = SlackerHelper.loadstring(SlackerHelper.get_setting("script_report_worldbuff") or "", "script_report_worldbuff")
	local AwardPlayer = SlackerHelper.loadstring(SlackerHelper.get_setting("script_award") or "", "script_award")
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
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
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
	local datetime = data:get_datetime()
	local dmfweek = SlackerHelper.is_dmf_week(datetime)
	for player in data:get_players_iterator()
	do
		local name = player:get_name()
		local class = player:get_class()
		local classstr = class
		local group = player:get_group()
		local buffs = player:get_all_buffs_idonly()
		local offlinetext = ""
		local color = SlackerHelper.class_to_color(class)
		if not player:get_online()
		then 
			offlinetext=" (off)" 
			color = SlackerHelper.class_to_color("Offline")
		end
		local buffsfiltered = {}
		for i=1,#buffs,1
		do
			local b = buffs[i]
			local p = SlackerHelper.get_buff_priority(b)
			if SlackerHelper.BuffPriority.WB4<=p and p<=SlackerHelper.BuffPriority.DMF
			then
				table.insert(buffsfiltered, b)
			end
		end
		name = string.format("%s%s",name, offlinetext)
		name = { ["value"] = name, ["color"] = color }
		class = { ["value"] = class, ["color"] = color }
		group = { ["value"] = group }
		buffs = { ["value"] = buffsfiltered }
		local row = { ["cols"] = {name, class, group, buffs} }
		if CalculateAward ~= nil
		then
			local awrd = { ["value"] = SlackerHelper.eval(CalculateAward, {class=classstr, buffs=buffsfiltered, timestamp=datetime, is_dmfweek=dmfweek}) }
			table.insert(row["cols"], 4, awrd)
		end
		table.insert(datatable, row)
	end
	local title = "World Buffs for "..data:get_reason()
	local btn1 = nil
	if CalculateAward and AwardPlayer
	then
		btn1 = AwardButton(datatable, 1, 4, AwardPlayer, "WorldBuffs")
	end
	ShowReport(title, cols, datatable, btn1)
end

local function SnapshotConsumes(data)
	local CalculateAward = SlackerHelper.loadstring(SlackerHelper.get_setting("script_report_consume") or "", "script_report_consume")
	local AwardPlayer = SlackerHelper.loadstring(SlackerHelper.get_setting("script_award") or "", "script_award")
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
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Zanza",
			["width"] = 40,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Prot",
			["width"] = 60,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Consumes",
			["width"] = 120,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Food",
			["width"] = 40,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
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
	local datetime = data:get_datetime()
	for player in data:get_players_iterator()
	do
		local name = player:get_name()
		local class = player:get_class()
		local classstr = class
		local group = player:get_group()
		local buffs = player:get_all_buffs_idonly()
		local offlinetext = ""
		local color = SlackerHelper.class_to_color(class)
		local flask = {}
		local zanza = {}
		local prot = {}
		local cons = {}
		local food = {}
		local all = {}
		if not player:get_online()
		then 
			offlinetext=" (off)" 
			color = SlackerHelper.class_to_color("Offline")
		end
		local buffsfiltered = {}
		for i=1,#buffs,1
		do
			
			local b = buffs[i]
			local p = SlackerHelper.get_buff_priority(b)
			if p==SlackerHelper.BuffPriority.FLASK
			then
				table.insert(all, b)
				table.insert(flask, b)
			elseif p==SlackerHelper.BuffPriority.ZANZA
			then
				table.insert(all, b)
				table.insert(zanza, b)
			elseif p==SlackerHelper.BuffPriority.GPROT or p==SlackerHelper.BuffPriority.PROT
			then
				table.insert(all, b)
				table.insert(prot, b)
			elseif p==SlackerHelper.BuffPriority.CONS
			then
				table.insert(all, b)
				table.insert(cons, b)
			elseif p==SlackerHelper.BuffPriority.FOOD
			then
				table.insert(all, b)
				table.insert(food, b)
			end
		end
		name = string.format("%s%s",name, offlinetext)
		name = { ["value"] = name, ["color"] = color }
		class = { ["value"] = class, ["color"] = color }
		group = { ["value"] = group }
		flask = {["value"] = flask}
		zanza = {["value"] = zanza}
		prot = {["value"] = prot}
		cons = {["value"] = cons}
		food = {["value"] = food}
		local row = { ["cols"] = {name, class, group, flask, zanza, prot, cons, food} }
		if CalculateAward ~= nil
		then
			local awrd = { ["value"] = SlackerHelper.eval(CalculateAward, {class=classstr, buffs=all, timestamp=datetime}) }
			table.insert(row["cols"], 4, awrd)
		end
		table.insert(datatable, row)
	end
	local title = "Consumes for "..data:get_reason()
	local btn1 = nil
	if CalculateAward and AwardPlayer
	then
		btn1 =AwardButton(datatable, 1, 4, AwardPlayer, "Consumes")
	end
	ShowReport(title, cols, datatable, btn1)
end

local function SnapshotMissingBuffs(data)
	local cols = { 
		{
			["name"] = "Name",
			["width"] = 84,
			["align"] = "LEFT",
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
			["sort"] = "dsc",
			["defaultsort"] = "asc",
		}, 
		{
			["name"] = "Druid",
			["width"] = 40,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Mage",
			["width"] = 40,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Priest",
			["width"] = 60,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Warr",
			["width"] = 40,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
		{
			["name"] = "Other",
			["width"] = 80,
			["align"] = "LEFT",
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
	}
	local datatable = {}
	for player in data:get_players_iterator()
	do
		local name = player:get_name()
		local class = player:get_class()
		local classstr = class
		local group = player:get_group()
		local buffs = player:get_all_buffs_idonly()
		local offlinetext = ""
		local color = SlackerHelper.class_to_color(class)
		local druid = {}
		local mage = {}
		local priest = {}
		local warr = {}
		local other = {}
		if not player:get_online()
		then 
			offlinetext=" (off)" 
			color = SlackerHelper.class_to_color("Offline")
		end
		local buffsfiltered = {}
		for i=1,#buffs,1
		do
			local b = buffs[i]
			local p = SlackerHelper.get_buff_priority(b)
			if SlackerHelper.in_array(b, {9885, 21850}) -- motw
			then
				table.insert(druid, b)
			elseif SlackerHelper.in_array(b, {10157, 23028}) -- int
			then
				table.insert(mage, b)
			elseif SlackerHelper.in_array(b, {10938, 21564, 27841, 27681}) -- fort, spirit
			then
				table.insert(priest, b)
			elseif b==25289 -- battle shout
			then
				table.insert(warr, b)
			elseif 
				SlackerHelper.in_array(b, {11767, 20765, 10958, 27683, 20190}) or -- soulstone, blood pact, shadow prot, hunter resist aura 
				SlackerHelper.in_array(b, {10535, 10477, 10599, 10405, 15110}) or -- shaman resist/prot totems
				SlackerHelper.in_array(b, {19900, 19898, 19896, 10293}) -- paladin resist/prot auras
			then
				table.insert(other, b)
			end
		end
		name = { ["value"] = name, ["color"] = color }
		class = { ["value"] = class, ["color"] = color }
		group = { ["value"] = group }
		druid = {["value"] = druid}
		mage = {["value"] = mage}
		priest = {["value"] = priest}
		warr = {["value"] = warr}
		other = {["value"] = other}
		local row = { ["cols"] = {name, class, group, druid, mage, priest, warr, other} }
		table.insert(datatable, row)
	end
	local title = "Class Buffs for "..data:get_reason()
	ShowReport(title, cols, datatable)
end

local function DummyReport(data)
	SlackerHelper.error("NotImplemented")
end

SlackerUI.Reports.ReportData = {
	{ ["type"] = "dungeon", ["id"] = "missing-buffs", ["name"] = "Missing Buffs", ["func"] = DungeonMissingBuffs },
	{ ["type"] = "snapshot", ["id"] = "worldbuffs", ["name"] = "World Buffs", ["func"] = SnapshotWorldBuffs },
	{ ["type"] = "snapshot", ["id"] = "consumes", ["name"] = "Consumes", ["func"] = SnapshotConsumes },
	{ ["type"] = "snapshot", ["id"] = "missing-buffs", ["name"] = "Class Buffs", ["func"] = SnapshotMissingBuffs },
}
