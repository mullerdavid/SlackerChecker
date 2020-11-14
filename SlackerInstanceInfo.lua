--[[ Instance info ]]--

local last_info_manual = nil
local last_info_dynamic = nil

function SlackerHelper.instance_info(localtime)
	local ret
	local is_party_alloved = SlackerHelper.get_setting("party")
	local is_debug = SlackerHelper.get_setting("debug")
	local name, instance_type, _, _, max_players, _, _, instance_id = GetInstanceInfo()
	if 
		(is_party_alloved and (instance_type == "party" or instance_type == "raid") ) or
		(not is_party_alloved and (instance_type == "raid" and max_players>=20) ) or
		(is_debug and instance_id == 389 )
	then
		ret = {}
		ret["time"] = localtime or time()
		ret["iid"] = instance_id
		ret["name"] = name
		ret["zid"] = 0
		return ret
	end
	return nil
end

function SlackerHelper.instance_do_update_manual(localtime)
	local info = SlackerHelper.instance_info(localtime)
	if info
	then
		if (last_info_manual["iid"]==info["iid"])
		then
			info["zid"] = last_info_manual["zid"]
		end
		last_info_manual = info
	end
end

function  SlackerHelper.instance_do_update_dynamic(unit)
	local localtime = time()
	local doupdate = false
	if not unit -- entering world
	then
		last_info_dynamic = SlackerHelper.instance_info(localtime)
		doupdate = (last_info_dynamic ~= nil)
	elseif last_info_dynamic and (last_info_dynamic["zid"]==0 or (localtime-last_info_dynamic["time"]>600)) -- targeting an npc or nameplate and zid is not filled yet or was updated more than 10 mins ago
	then
		local guid = UnitGUID(unit);
		if guid
		then
			local unit_type, _, _, _, zone_id, npc_id = strsplit("-", guid);
			if (unit_type == "Creature" and SlackerHelper.valid_creature(npc_id)) then
				last_info_dynamic["zid"]=zone_id
				last_info_dynamic["time"]=localtime
				doupdate = true
			end
		end
	end
	if doupdate
	then
		if not last_info_manual
		then
			last_info_manual = last_info_dynamic
		elseif (last_info_manual["iid"]==last_info_dynamic["iid"])
		then
			last_info_manual["time"]=math.max(last_info_manual["time"],last_info_dynamic["time"])
			if last_info_dynamic["zid"]~=0
			then
				last_info_manual["zid"]=last_info_dynamic["zid"]
			end
		end
	end
end

function SlackerHelper.instance_get_info()
	local localtime = time()
	SlackerHelper.instance_do_update_manual(localtime)
	if last_info_manual and (localtime-last_info_manual["time"]<1800) -- if entered or updated in last 30 minute
	then
		return last_info_manual["iid"], last_info_manual["name"], last_info_manual["zid"]
	end
	return nil
end

function SlackerHelper.instance_get_reset(iname)
	local localtime = time()
	local numInstances = GetNumSavedInstances()
	for raidIndex=1,numInstances,1
	do
		name, id, reset = GetSavedInstanceInfo(raidIndex)
		if iname == name
		then
			return math.max(localtime+reset, 0)
		end
	end
	return 0
end

local function OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD"
	then
		SlackerHelper.instance_do_update_dynamic();
	elseif event == "PLAYER_TARGET_CHANGED"
	then
		SlackerHelper.instance_do_update_dynamic("target");
	elseif event == "UPDATE_MOUSEOVER_UNIT"
	then
		SlackerHelper.instance_do_update_dynamic("mouseover");
	elseif event == "NAME_PLATE_UNIT_ADDED"
	then
		SlackerHelper.instance_do_update_dynamic("nameplate1");
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:SetScript("OnEvent", OnEvent)
