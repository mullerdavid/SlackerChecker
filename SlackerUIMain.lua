SlackerUI.MainWindow = {}
SlackerUI.MainWindow.ToggleWindow = nil
SlackerUI.MainWindow.SetDatabase = nil
SlackerUI.MainWindow.OnShow = nil
SlackerUI.MainWindow.SelectedDungeon = nil
SlackerUI.MainWindow.SelectedSnapshot = nil
SlackerUI.MainWindow.ToggleEdit = nil
SlackerUI.MainWindow.Export = nil
SlackerUI.MainWindow.ResetDatabase = nil

local TablePlayers = nil
local Database = nil
local EditMode = false
local RightClick = nil


local function ClearPlayers()
	TablePlayers:Hide();
end

local function InitTable()
	if TablePlayers ~= nil
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
			["comparesort"] = SlackerUI.ScrollTable.NoSort,
			["DoCellUpdate"] = SlackerUI.ScrollTable.RenderBuffs
		}, 
	}
	TablePlayers = ScrollingTable:CreateST(cols, 32, 18, nil, SlackerUI_MainWindow.PlayerList)
	ClearPlayers()
end

local function DrawPlayers()
	local snapshot = SlackerUI.MainWindow.SelectedSnapshot
	if (not snapshot) then return end
	local data = {}
	for player in snapshot:get_players_iterator()
	do
		local name = player:get_name()
		local class = player:get_class()
		local group = player:get_group()
		local buffs = player:get_all_buffs()
		local offlinetext = ""
		local color = SlackerHelper.class_to_color(class)
		if not player:get_online()
		then 
			offlinetext=" (off)" 
			color = SlackerHelper.class_to_color("Offline")
		end
		name = string.format("%s%s",name, offlinetext)
		name = { ["value"] = name, ["color"] = color }
		class = { ["value"] = class, ["color"] = color }
		group = { ["value"] = group }
		buffs = { ["value"] = buffs }
		local row = { ["cols"] = {name, class, group, buffs} }
		table.insert(data, row)
	end
	TablePlayers:SetData(data);
	TablePlayers:Refresh();
	TablePlayers:Show();
end

local function SelectSnapshot(menuframe,snapshot)
	if not SlackerUI.MainWindow.SelectedSnapshot or SlackerUI.MainWindow.SelectedSnapshot:get_uuid() ~= snapshot:get_uuid()
	then
		SlackerUI.MainWindow.SelectedSnapshot = snapshot
		local children = { SlackerUI_MainWindow.SnapshotList.ScrollChildFrame:GetChildren() }
		for i, child in ipairs(children) do
			if menuframe==child
			then
				child.Selected:Show()
			else
				child.Selected:Hide()
			end
		end
		ClearPlayers()
		DrawPlayers()
	end
end

local function ClearSnapshots(keepselected)
	if not keepselected
	then
		SlackerUI.MainWindow.SelectedSnapshot = nil
	end
	local children = { SlackerUI_MainWindow.SnapshotList.ScrollChildFrame:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function DrawSnapshots()
	local dungeon = SlackerUI.MainWindow.SelectedDungeon
	if (not dungeon) then return end
	ClearSnapshots(true)
	local i = 0
	for snapshot in dungeon:get_snapshots_iterator_reverse()
	do
		local f = CreateFrame("Frame", nil, SlackerUI_MainWindow.SnapshotList.ScrollChildFrame, "SlackerUI_MenuTemplate")
		f:SetPoint("TOPLEFT", 0, -34*i );
		f:HookScript("OnMouseDown", function(self, button) if button=="RightButton" then RightClick(nil,snapshot) else SelectSnapshot(f,snapshot) end end)
		f.DateTime:SetText(date(SlackerHelper.date_format, snapshot:get_datetime())) 
		f.Instance:SetText( snapshot:get_reason() )
		f.DeleteButton:HookScript("OnClick", function(self) Database:remove_snapshot(snapshot) end)
		if EditMode
		then
			f.DeleteButton:Show()
		else
			f.DeleteButton:Hide()
		end
		if SlackerUI.MainWindow.SelectedSnapshot and SlackerUI.MainWindow.SelectedSnapshot:get_uuid() == snapshot:get_uuid()
		then
			f.Selected:Show()
		end
		i = i+1
	end
end

local function SelectDungeon(menuframe,dungeon)
	if not SlackerUI.MainWindow.SelectedDungeon or SlackerUI.MainWindow.SelectedDungeon:get_uuid() ~= dungeon:get_uuid()
	then
		SlackerUI.MainWindow.SelectedDungeon = dungeon
		local children = { SlackerUI_MainWindow.DungeonList.ScrollChildFrame:GetChildren() }
		for i, child in ipairs(children) do
			if menuframe==child
			then
				child.Selected:Show()
			else
				child.Selected:Hide()
			end
		end
		ClearPlayers()
		ClearSnapshots()
		DrawSnapshots()
	end
end

local function ClearDungeons(keepselected)
	if not keepselected
	then
		SlackerUI.MainWindow.SelectedDungeon = nil
	end
	local children = { SlackerUI_MainWindow.DungeonList.ScrollChildFrame:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
end

local function DrawDungeons()
	if (not Database) then return end
	ClearDungeons(true)
	local i = 0
	for dungeon in Database:get_dungeons_iterator_reverse()
	do
		local f = CreateFrame("Frame", nil, SlackerUI_MainWindow.DungeonList.ScrollChildFrame, "SlackerUI_MenuTemplate")
		local name = dungeon:get_owner() or "Unknown"
		local iname = SlackerHelper.iid_to_str(dungeon:get_instance_id()) or dungeon:get_instance_name()
		f:SetPoint("TOPLEFT", 0, -34*i );
		f:HookScript("OnMouseDown", function(self, button) if button=="RightButton" then RightClick(dungeon,nil) else SelectDungeon(f,dungeon) end end)
		f.DateTime:SetText(date(SlackerHelper.date_format, dungeon:get_datetime())) 
		f.Instance:SetText( string.format("%s (%s)", iname, name) )
		f.DeleteButton:HookScript("OnClick", function(self) Database:remove_dungeon(dungeon) end)
		if EditMode
		then
			f.DeleteButton:Show()
		else
			f.DeleteButton:Hide()
		end
		if SlackerUI.MainWindow.SelectedDungeon and SlackerUI.MainWindow.SelectedDungeon:get_uuid() == dungeon:get_uuid()
		then
			f.Selected:Show()
		end
		i = i+1
	end
end

--where change="add"|"remove", what="dungeon"|"snapshot"|"multiple", dungeon and snapshots are the affected objects, nil if multiple
local function UpdateHook(change, what, dungeon, snapshot)
	if change=="remove"
	then
		if what=="dungeon" 
		then
			if SlackerUI.MainWindow.SelectedDungeon and SlackerUI.MainWindow.SelectedDungeon:get_uuid()==dungeon:get_uuid()
			then
				SlackerUI.MainWindow.SelectedDungeon = nil
				SlackerUI.MainWindow.SelectedSnapshot = nil
				ClearPlayers()
				ClearSnapshots()
			end
			DrawDungeons()
		elseif what=="snapshot" 
		then
			if SlackerUI.MainWindow.SelectedSnapshot and SlackerUI.MainWindow.SelectedSnapshot:get_uuid()==snapshot:get_uuid()
			then
				SlackerUI.MainWindow.SelectedSnapshot = nil
				ClearPlayers()
			end
			DrawSnapshots()
		else
			SlackerUI.MainWindow.SelectedDungeon = nil
			SlackerUI.MainWindow.SelectedSnapshot = nil
			ClearPlayers()
			ClearSnapshots()
			ClearDungeons()
			DrawDungeons()
			DrawSnapshots()
			DrawPlayers()
		end
	elseif change=="add"
	then
		if what=="dungeon" 
		then
			DrawDungeons()
		elseif what=="snapshot" 
		then
			DrawSnapshots()
		end
	end
end

function SlackerUI.MainWindow.SetDatabase(database)
	if database
	then
		Database = database	
		Database:onchange_add_hook(UpdateHook, "SlackerUI.MainWindow")
	end
end

function SlackerUI.MainWindow.ToggleWindow()
	local frame = SlackerUI_MainWindow
	if frame:IsShown()
	then
		frame:Hide()
	else
		frame:Show()
	end
end

function SlackerUI.MainWindow.OnShow()
	InitTable()
	DrawDungeons()
	DrawSnapshots()
	DrawPlayers()
end

function SlackerUI.MainWindow.ToggleEdit()
	EditMode = not EditMode
	for i, f in ipairs( { SlackerUI_MainWindow.DungeonList.ScrollChildFrame:GetChildren() }) do
		if EditMode
		then
			f.DeleteButton:Show()
		else
			f.DeleteButton:Hide()
		end
	end
	for i, f in ipairs({ SlackerUI_MainWindow.SnapshotList.ScrollChildFrame:GetChildren() }) do
		if EditMode
		then
			f.DeleteButton:Show()
		else
			f.DeleteButton:Hide()
		end
	end
end

local function ShowCopyTemplate(str)
	local f = CreateFrame("Frame", nil, UIParent, "SlackerUI_CopyTemplate")
	f.ScrollFrame.EditBox:SetText(str)
	f:Show()
end

local function GenerateExportMenu(dungeon, snapshot, hidetype)
    local typedungeon = "DUNGEON "
    local typesnapshot = "SNAPSHOT "
	if hidetype
	then
		typedungeon = ""
		typesnapshot = ""
	end
	local menu = {}
	local csvheaders = {
		"owner,date,iname,iid,zid,reset,uuid,ver",
		"d,r,uuid",
		"i,n,c,g,o",
		"b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15,b16,b17,b18,b19,b20,b21,b22,b23,b24,b25,b26,b27,b28,b29,b30,b31,b32"
	}
	if (dungeon)
	then
		table.insert(menu, {
			text="Export "..typedungeon.."as CSV", 
			value="dungeon-csv", 
			func=function()
				SlackerUI.ConfirmDialog("This might take a while", 
				function() 
					local str=dungeon:serialize("csv")
					ShowCopyTemplate(table.concat(csvheaders,",",1).."\n"..str)
				end,
				"Continue",
				"Cancel"
				)
			end
		})
		table.insert(menu, {
			text="Export "..typedungeon.."as JSON", 
			value="dungeon-json", 
			func=function()
				SlackerUI.ConfirmDialog("This might take a while", 
				function() 
					local str=dungeon:serialize("json")
					ShowCopyTemplate(str)
				end,
				"Continue",
				"Cancel"
				)
			end
		})
	end
	if (snapshot)
	then
		table.insert(menu, {
			text="Export "..typesnapshot.."as CSV", 
			value="snapshot-csv", 
			func=function() 
				local str=snapshot:serialize("csv")
				ShowCopyTemplate(table.concat(csvheaders,",",2).."\n"..str)
			end
		})
		table.insert(menu, {
			text="Export "..typesnapshot.."as JSON", 
			value="snapshot-json", 
			func=function() 
				local str=snapshot:serialize("json")
				ShowCopyTemplate(str)
			end
		})
	end
	return menu
end

function SlackerUI.MainWindow.Export(self)
	local menu = GenerateExportMenu(SlackerUI.MainWindow.SelectedDungeon, SlackerUI.MainWindow.SelectedSnapshot)
	if 0<#menu
	then
		SlackerUI.ContextMenu.Show(self, menu);
	end
end

local function GenerateReportMenu(dungeon, snapshot, hidetype)
    local typedungeon = "DUNGEON "
    local typesnapshot = "SNAPSHOT "
	if hidetype
	then
		typedungeon = ""
		typesnapshot = ""
	end
	local menu = {}
	for i=1,#SlackerUI.Reports.ReportData,1
	do
		local report = SlackerUI.Reports.ReportData[i]
		if (dungeon and report.type=="dungeon")
		then
			table.insert(menu, {
				text="Report "..typedungeon.."for "..report.name, 
				value="dungeon-"..report.id, 
				func=function() 
					report.func(dungeon)
				end
			})
		end
		if (snapshot and report.type=="snapshot")
		then
			table.insert(menu, {
				text="Report "..typesnapshot.."for "..report.name, 
				value="snapshot-"..report.id, 
				func=function() 
					report.func(snapshot)
				end
			})
		end
	end
	return menu
end

function SlackerUI.MainWindow.Report(self)
	local menu = GenerateReportMenu(SlackerUI.MainWindow.SelectedDungeon, SlackerUI.MainWindow.SelectedSnapshot)
	if 0<#menu
	then
		SlackerUI.ContextMenu.Show(self, menu);
	end
end

RightClick = function(dungeon, snapshot)
	local menu_rep = GenerateReportMenu(dungeon, snapshot, true)
	local menu_exp = GenerateExportMenu(dungeon, snapshot, true)
	local menu = SlackerHelper.array_concat(menu_rep, menu_exp)
	if 0<#menu
	then
		SlackerUI.ContextMenu.Show(nil, menu);
	end
end

function SlackerUI.MainWindow.ResetDatabase()
	SlackerUI.ConfirmDialog("Do you want to reset the database?", function() Database:reset() end)
end
