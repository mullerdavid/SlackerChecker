SlackerUI.Settings = {}
SlackerUI.Settings.RegisterFrames = nil
SlackerUI.Settings.OpenSettings = nil
SlackerUI.Settings.MainLoadSettings = nil
SlackerUI.Settings.MainSaveSettings = nil

local mainpanel = nil

local scripts = {}

function SlackerUI.Settings.RegisterFrames()
	mainpanel = CreateFrame("Frame", nil, UIParent, "SlackerUI_SettingTemplate")
	mainpanel:Hide()
	mainpanel.name = SlackerHelper.Addon
	mainpanel.okay = SlackerUI.Settings.MainSaveSettings
	mainpanel.cancel = SlackerUI.Settings.MainLoadSettings
	SlackerUI.Settings.MainLoadSettings(mainpanel)
	InterfaceOptions_AddCategory(mainpanel)
	for i=1,#scripts,1
	do
		local script = scripts[i]
		local panel
		panel = CreateFrame("Frame", nil, UIParent, "SlackerUI_SettingScriptTemplate")
		local menu = {}
		for j=1,#script.examples,1
		do
			local example = script.examples[j]
			table.insert(menu, {text=example.name, value=example.name, func=function() panel.ChildFrame.ScrollFrame.EditBox:SetText(example.value) end})
		end
		panel.ExampleButton:SetScript("OnClick", 
		function(self) 
			SlackerUI.ContextMenu.Show(self, menu);
		end)
		panel.FunctionString:SetText(script.signature)
		panel.ChildFrame.ScrollFrame.EditBox:SetText(SlackerHelper.get_setting(script.settingkey) or "")
		panel.ChildFrame.ScrollFrame.EditBox:SetScript("OnTextChanged", function(self, ...) panel.Changed = true end )
		panel:Hide()
		panel.name = script.name
		panel.parent = mainpanel.name
		panel.okay = function(self) if panel.Changed then SlackerHelper.set_setting(script.settingkey, panel.ChildFrame.ScrollFrame.EditBox:GetText()) panel.Changed = false end end
		panel.cancel = function(self) panel.ChildFrame.ScrollFrame.EditBox:SetText(SlackerHelper.get_setting(script.settingkey) or "") panel.Changed = false end
		InterfaceOptions_AddCategory(panel)
	end
end

local firstopenfix = true -- Blizzard has a bug in Options panel

function SlackerUI.Settings.OpenSettings()
	InterfaceOptionsFrame_OpenToCategory(mainpanel) 
	if (firstopenfix)
	then
		InterfaceOptionsFrame_OpenToCategory(mainpanel) 
		firstopenfix = false
	end
end

local maintainvalues  = {
	[1] = { value="all", text = "Keep everything"},
	[2] = { value="num5", text = "Keep last 5 instances"},
	[3] = { value="num10", text = "Keep last 10 instances"},
	[4] = { value="num20", text = "Keep last 20 instances"},
	[5] = { value="num100", text = "Keep last 100 instances"},
	[6] = { value="time7", text = "Keep last 7 days"},
	[7] = { value="time14", text = "Keep last 14 days"},
	[8] = { value="time30", text = "Keep last 30 days"},
	[9] = { value="time180", text = "Keep last 180 days"},
};

local colorvalues  = {
	[1] = { value="classic", text = "Classic"},
	[2] = { value="classic_mod", text = "Classic (Pink shaman)"},
	[3] = { value="retail", text = "Retail"},
	[4] = { value="retail_mod", text = "Retail (Pink shaman)"},
};

function SlackerUI.Settings.MainLoadSettings(self)
	local zelf = self
	local dropdown = self.MaintainDropdown
	local dbmaintain = SlackerHelper.get_setting("dbmaintain")
	UIDropDownMenu_Initialize(
		dropdown, 
		function(frame, level, menuList)
			local found = false
			for index, value in ipairs(maintainvalues)
			do
				local info = UIDropDownMenu_CreateInfo()
				info.text = value.text
				info.value = value.value
				info.func = function(self, value) 
					UIDropDownMenu_SetSelectedValue(frame, self.value)
					zelf.Changed = true
				end
				local entry = UIDropDownMenu_AddButton(info);
				if value.value == dbmaintain
				then
					UIDropDownMenu_SetSelectedValue(dropdown, value.value)
					found = true
				end
			end
			if not found 
			then
				UIDropDownMenu_SetSelectedValue(dropdown, maintainvalues[1].value)
			end
		end
	)
	local dropdown2 = self.ClassColorDropdown
	local classcolors = SlackerHelper.get_setting("classcolors")
	UIDropDownMenu_Initialize(
		dropdown2, 
		function(frame, level, menuList)
			local found = false
			for index, value in ipairs(colorvalues)
			do
				local info = UIDropDownMenu_CreateInfo()
				info.text = value.text
				info.value = value.value
				info.func = function(self, value) 
					UIDropDownMenu_SetSelectedValue(frame, self.value)
					zelf.Changed = true
				end
				local entry = UIDropDownMenu_AddButton(info);
				if value.value == classcolors
				then
					UIDropDownMenu_SetSelectedValue(dropdown2, value.value)
					found = true
				end
			end
			if not found 
			then
				UIDropDownMenu_SetSelectedValue(dropdown2, colorvalues[1].value)
			end
		end
	)
	local party = SlackerHelper.get_setting("party")
	self.PartyCheckbox:HookScript("OnClick", 
		function(self)
			zelf.Changed = true
		end
	)
	self.PartyCheckbox:SetChecked(party)
	local record_readycheck = SlackerHelper.get_setting("record_readycheck")
	self.RecordReadyCheckCheckbox:HookScript("OnClick", 
		function(self)
			zelf.Changed = true
		end
	)
	self.RecordReadyCheckCheckbox:SetChecked(record_readycheck)
	local record_pull = SlackerHelper.get_setting("record_pull")
	self.RecordPullCheckbox:HookScript("OnClick", 
		function(self)
			zelf.Changed = true
		end
	)
	self.RecordPullCheckbox:SetChecked(record_pull)
	local record_kill = SlackerHelper.get_setting("record_kill")
	self.RecordKillCheckbox:HookScript("OnClick", 
		function(self)
			zelf.Changed = true
		end
	)
	self.RecordKillCheckbox:SetChecked(record_kill)
	local record_wipe = SlackerHelper.get_setting("record_wipe")
	self.RecordWipeCheckbox:HookScript("OnClick", 
		function(self)
			zelf.Changed = true
		end
	)
	self.RecordWipeCheckbox:SetChecked(record_wipe)
	local dbg = SlackerHelper.get_setting("debug")
	self.DebugCheckbox:HookScript("OnClick", 
		function(self)
			zelf.Changed = true
		end
	)
	self.DebugCheckbox:SetChecked(dbg)
	self.Changed = false
end

function SlackerUI.Settings.MainSaveSettings(self)
	if self.Changed
	then
		local dbmaintain = UIDropDownMenu_GetSelectedValue(self.MaintainDropdown)
		SlackerHelper.set_setting("dbmaintain", dbmaintain)
		local classcolors = UIDropDownMenu_GetSelectedValue(self.ClassColorDropdown)
		SlackerHelper.set_setting("classcolors", classcolors)
		local party = self.PartyCheckbox:GetChecked()
		SlackerHelper.set_setting("party", party)
		local record_readycheck = self.RecordReadyCheckCheckbox:GetChecked()
		SlackerHelper.set_setting("record_readycheck", record_readycheck)
		local record_pull = self.RecordPullCheckbox:GetChecked()
		SlackerHelper.set_setting("record_pull", record_pull)
		local record_kill = self.RecordKillCheckbox:GetChecked()
		SlackerHelper.set_setting("record_kill", record_kill)
		local record_wipe = self.RecordWipeCheckbox:GetChecked()
		SlackerHelper.set_setting("record_wipe", record_wipe)
		local dbg = self.DebugCheckbox:GetChecked()
		SlackerHelper.set_setting("debug", dbg)
		SlackerHelper.load_colors()
		self.Changed = false
	end
end

function SlackerUI.Settings.MainSetDropdown(frame, level, menuList)
	
end

local helperinfo = [[
--
-- You can use various helper functions as well
-- 
-- SlackerHelper.in_array(needle, array)
--   returns true if needle found in the array
--
-- SlackerHelper.array_intersect(array1, array2)
--   returns the elements found in both arrays in a new array
-- 
-- SlackerHelper.is_dmf_week(timestamp)
--   return true if the timestamp is on a DMF week (currently calculated for EU only)
-- 
]]

scripts = {
	{
		["name"]="Script - Worldbuff",
		["settingkey"]="script_report_worldbuff",
		["signature"]="function script_report_worldbuff(class, buffs, timestamp, is_dmfweek)",
		["examples"]= {
			{
				["name"] = "Info",
				["value"] = [[
-- This function is used to generate the amount a set of worldbuffs awards in the reports
--   class is the english classname of the player
--   buffs is an array of buff ids
--   timestamp is the unix timestamp of the recording
--   is_dmfweek is true if the time of recording was a Darkmoon Faire week otherwise false
]] .. helperinfo
			},
			{
				["name"] = "Clear",
				["value"] = ""
			},
			{
				["name"] = "Buffcount",
				["value"] = [[
-- awards 10 for each buff, dmt is counted one for at least 2 dmt buffs
local dmt = SlackerHelper.array_intersect(buffs, {22817,22818,22820})
local count = #buffs - #dmt + (2<=#dmt and 1 or 0)
return count * 10
]]
			},
			{
				["name"] = "C17 WB",
				["value"] = [[
-- awards bonus based on count, dmt is counted one for at least 2 dmt buffs
-- on dmf week, need all 6 type of worldbuffs
-- all worldbuffs is 50, at least 3 is 20, otherwise 0
local dmt = SlackerHelper.array_intersect(buffs, {22817,22818,22820})
local count = #buffs - #dmt + (2<=#dmt and 1 or 0)
if is_dmfweek and 6<=count
then
    return 50
elseif not is_dmfweek and 5<=count
then
    return 50
elseif 3<=count
then
    return 20
end
return 0
]]
			},
		}
	},
	{
		["name"]="Script - Consumes",
		["settingkey"]="script_report_consume",
		["signature"]="function script_report_consume(class, buffs, timestamp)",
		["examples"]= {
			{
				["name"] = "Info",
				["value"] = [[
-- This function is used to generate the amount a set of consumes awards in the reports
--   class is the english classname of the player
--   buffs is an array of buff ids the player has
--   timestamp is the unix timestamp of the recording
]] .. helperinfo
			},
			{
				["name"] = "Clear",
				["value"] = ""
			},
			{
				["name"] = "Buffcount",
				["value"] = [[
-- awards 2 for each consume related buff
local count = #buffs
return count * 2
]]
			},
			{
				["name"] = "C17 Flasks",
				["value"] = [[
-- awards 40 for a flask
local flask = SlackerHelper.array_intersect(buffs, {17626,17627,17628,17629})
if #flask>0
then
    return 40
end
return 0
]]
			},
		}
	},
	{
		["name"]="Script - Awarding",
		["settingkey"]="script_award",
		["signature"]="function script_award(player, amount, message)",
		["examples"]= {
			{
				["name"] = "Info",
				["value"] = [[
-- This function is used to award the player with the amount earned
-- If set, there is a button on the corresponding report to award players realtime
--   player is the name of the player
--   amount is the amount awarded
--   message is the reason for award
]]
			},
			{
				["name"] = "Clear",
				["value"] = ""
			},
			{
				["name"] = "Classic EPGP",
				["value"] = [[
CEPGP_addEP(player, amount, message)
]]
			},
			{
				["name"] = "Monolith DKP",
				["value"] = [[
-- Not implemented yet.
-- TODO: Monolith DKP example
print("Awarding " .. player .. " with " .. amount .. " dkp (" .. message .. ").")
]]
			},
		}
	},
}

