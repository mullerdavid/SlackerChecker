--[[
SlackerChecker_DB = {
	{
		["ver"] = str, -- addon version
		["date"] = datetime, -- first encounter, ordered by this
		["iid"] = int, -- instance id
		["iname"] = str, -- instance name
		["zid"] = int, -- zone id
		["reset"] = datetime, -- reset timer
		["owner"] = str, -- creator character
		["uuid"] = str, -- uuid4 (date-zid-...)
		["snap"] = { -- snapshots
			{
				["d"] = datetime, -- date of reccording
				["r"] = str, -- reaseon
				["uuid"] = str, -- uuid4 (date-zid-...), must be same prefix as parent
				["p"] = { -- players
					{
						["i"] = int, -- index
						["o"] = int, -- online 0/1
						["g"] = int, -- group
						["n"] = str, -- name
						["c"] = str, -- class
						["b"] = { -- active buffs
							{
								["id"] =  int, -- spell id
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

--[[ Public interface ]]--

SlackerData = {}
SlackerData.Database = nil
SlackerData.Dungeon = nil
SlackerData.Snapshot = nil
SlackerData.Player = nil
SlackerData.Buff = nil

--[[ Locals ]]--

local LibJSON = LibStub("LibJSON-1.0") 

--[[ Buff ]]--

local Buff = {}
Buff.__index = Buff

function Buff.new_raw(data)
	local self = setmetatable({}, Buff)
	self.data = data
	return self
end

function Buff.new(id)
	local self = setmetatable({}, Buff)
	self.data = { ["id"] = id }
	return self
end

function Buff.set_id(self, newval)
	self.data["id"] = newval
end

function Buff.get_id(self)
	return self.data["id"]
end

function Buff.extract_id(buff)
	if type(buff) == "number"
	then
		return buff
	elseif buff.get_id
	then
		return buff:get_id()
	elseif buff["id"]
	then
		return buff["id"]
	end
	return buff
end

--[[ Player ]]--

local Player = {}
Player.__index = Player

function Player.new_raw(data)
	local self = setmetatable({}, Player)
	self.data = data
	return self
end

function Player.new(name, class, group, index, is_online )
	local self = setmetatable({}, Player)
	self.data = {
		["n"] = name,
		["c"] = class,
		["g"] = group,
		["i"] = index,
		["o"] = is_online and 1 or 0,
		["b"] = {}
	}
	return self
end

function Player.set_name(self, name)
	self.data["n"] = name
end

function Player.get_name(self)
	return self.data["n"]
end

function Player.set_class(self, class)
	self.data["c"] = class
end

function Player.get_class(self)
	return self.data["c"]
end

function Player.set_group(self, group)
	self.data["g"] = group
end

function Player.get_group(self)
	return self.data["g"]
end

function Player.set_index(self, index)
	self.data["i"] = index
end

function Player.get_index(self)
	return self.data["i"]
end

function Player.set_online(self, is_online)
	self.data["o"] = is_online and 1 or 0
end

function Player.get_online(self)
	return self.data["o"]==1
end

function Player.add_buff(self, buff)
	if buff.data
	then
		buff = buff.data
	end
	table.insert(self.data["b"], buff)
end

function Player.remove_buff(self, buff)
	local buffs = self.data["b"]
	if buff.get_id
	then
		buff = buff:get_id()
	end
	for i = #buffs, 1, -1
	do
		if (buffs[i]["id"]==buff)
		then
			table.remove(buffs, i)
		end
	end
end

function Player.get_buffs_iterator(self)
	local i = 0
	local t = self.data["b"]
	local n = #t
	return function()
		i = i + 1
		if i <= n then return Buff.new_raw(t[i]) end
	end
end

function Player.get_all_buffs(self)
	local ret = {}
	for buff in self:get_buffs_iterator()
	do
		table.insert(ret, buff)
	end
	return ret
end

function Player.get_all_buffs_idonly(self)
	local ret = {}
	local t = self.data["b"]
	local n = #t
	for i=1,#t,1
	do
		table.insert(ret, t[i]["id"])
	end
	return ret
end

function Player.serialize(self, frmt)
	if frmt == "csv" or frmt == "array"
	then
		local data = self.data
		local buffs = data["b"]
		local tmp = {data["i"],data["n"],data["c"],data["g"],data["o"]}
		for i = 1,#buffs,1
		do
			table.insert(tmp, buffs[i]["id"])
		end
		if frmt == "csv"
		then
			return table.concat(tmp,",")
		else
			return tmp
		end
	else -- json
		local data = self.data
		return LibJSON.Serialize(data)
	end
end

--[[ Snapshot ]]--

local Snapshot = {}
Snapshot.__index = Snapshot

function Snapshot.new_raw(data)
	local self = setmetatable({}, Snapshot)
	self.data = data
	return self
end

function Snapshot.new(reason, datetime, uuid)
	local self = setmetatable({}, Snapshot)
	datetime = datetime or time()
	uuid = uuid or SlackerHelper.get_uuid4( SlackerHelper.int_to_hex(datetime,8).."-0000" )
	self.data = { 
		["r"] = reason,
		["d"] = datetime,
		["uuid"] = uuid,
		["p"] = {}
	}
	return self
end

function Snapshot.set_reason(self, reason)
	self.data["r"] = reason
end

function Snapshot.get_reason(self)
	return self.data["r"]
end

function Snapshot.set_datetime(self, datetime)
	self.data["d"] = datetime
end

function Snapshot.get_datetime(self)
	return self.data["d"]
end

function Snapshot.set_uuid(self, uuid)
	self.data["uuid"] = uuid
end

function Snapshot.get_uuid(self)
	return self.data["uuid"]
end

function Snapshot.add_player(self, player)
	if player.data
	then
		player = player.data
	end
	table.insert(self.data["p"], player)
end

function Snapshot.remove_player(self, player)
	local players = self.data["p"]
	if player.get_name
	then
		player = player:get_name()
	end
	for i = #players, 1, -1
	do
		if (players[i]["n"]==player)
		then
			table.remove(players, i)
		end
	end
end

function Snapshot.get_players_iterator(self)
	local i = 0
	local t = self.data["p"]
	local n = #t
	return function()
		i = i + 1
		if i <= n then return Player.new_raw(t[i]) end
	end
end

function Snapshot.serialize(self, frmt)
	if frmt == "csv" or frmt == "array"
	then
		local data = self.data
		local tmp = {}
		for player in self:get_players_iterator()
		do
			local arr = player:serialize("array")
			table.insert(arr, 1, data["d"])
			table.insert(arr, 2, data["r"])
			table.insert(arr, 3, data["uuid"])
			table.insert(tmp, arr)
		end
		if frmt == "csv"
		then
			for i=1,#tmp,1 do
				tmp[i]=table.concat(tmp[i],",")
			end
			return table.concat(tmp,"\n")
		else
			return tmp
		end
	else -- json
		local data = self.data
		return LibJSON.Serialize(data)
	end
end

--[[ Dungeon ]]--

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon.new_raw(data)
	local self = setmetatable({}, Dungeon)
	self.data = data
	return self
end

function Dungeon.new(owner, datetime, iname, iid, zid, reset, uuid, ver)
	local self = setmetatable({}, Dungeon)
	datetime = datetime or time()
	iname = iname or "Unknown"
	iid = iid or 0
	zid = zid or 0
	reset = reset or 0
	uuid = uuid or SlackerHelper.get_uuid4( SlackerHelper.int_to_hex(datetime,8)..SlackerHelper.int_to_hex(zid,4) )
	ver = ver or GetAddOnMetadata(SlackerChecker_Addon, "Version")
	self.data = { 
		["owner"] = owner,
		["date"] = datetime,
		["iname"] = iname,
		["iid"] = iid,
		["zid"] = zid,
		["reset"] = reset,
		["uuid"] = uuid,
		["ver"] = ver,
		["snap"] = {}
	}
	return self
end

function Dungeon.set_owner(self, owner)
	self.data["owner"] = owner
end

function Dungeon.get_owner(self)
	return self.data["owner"]
end

function Dungeon.set_datetime(self, datetime)
	self.data["date"] = datetime
end

function Dungeon.get_datetime(self)
	return self.data["date"]
end

function Dungeon.set_instance_name(self, iname)
	self.data["iname"] = iname
end

function Dungeon.get_instance_name(self)
	return self.data["iname"]
end

function Dungeon.set_instance_id(self, iid)
	self.data["iid"] = iid
end

function Dungeon.get_instance_id(self)
	return self.data["iid"]
end

function Dungeon.set_zone_id(self, zid)
	self.data["zid"] = zid
end

function Dungeon.get_zone_id(self)
	return self.data["zid"]
end

function Dungeon.set_resettime(self, reset)
	self.data["reset"] = reset
end

function Dungeon.get_resettime(self)
	return self.data["reset"]
end

function Dungeon.set_uuid(self, uuid)
	self.data["uuid"] = uuid
end

function Dungeon.get_uuid(self)
	return self.data["uuid"]
end

function Dungeon.set_version(self, version)
	self.data["ver"] = version
end

function Dungeon.get_version(self)
	return self.data["ver"]
end

function Dungeon.add_snapshot(self, snapshot)
	if snapshot.data
	then
		snapshot = snapshot.data
	end
	table.insert(self.data["snap"], snapshot)
end

function Dungeon.remove_snapshot(self, snapshot)
	local snapshots = self.data["snap"]
	if snapshot.get_uuid
	then
		snapshot = snapshot:get_uuid()
	end
	for i = #snapshots, 1, -1
	do
		if (snapshots[i]["uuid"]==snapshot)
		then
			table.remove(snapshots, i)
		end
	end
end

function Dungeon.remove_snapshot_datetime(self, datetime)
	for i = #snapshots, 1, -1
	do
		if (snapshots[i]["date"]==datetime)
		then
			table.remove(snapshots, i)
		end
	end
end

function Dungeon.get_snapshots_iterator(self)
	local i = 0
	local t = self.data["snap"]
	local n = #t
	return function()
		i = i + 1
		if i <= n then return Snapshot.new_raw(t[i]) end
	end
end

function Dungeon.get_snapshots_iterator_reverse(self)
	local t = self.data["snap"]
	local i = #t + 1
	return function()
		i = i - 1
		if  1 <= i then return Snapshot.new_raw(t[i]) end
	end
end

function Dungeon.serialize(self, frmt)
	if frmt == "csv" or frmt == "array"
	then
		local data = self.data
		local tmp = {}
		for snapshot in self:get_snapshots_iterator()
		do
			local arr = snapshot:serialize("array")
			for i=1,#arr,1 do
				local arr2 = arr[i]
				table.insert(arr2, 1, data["owner"])
				table.insert(arr2, 2, data["date"])
				table.insert(arr2, 3, data["iname"])
				table.insert(arr2, 4, data["iid"])
				table.insert(arr2, 5, data["zid"])
				table.insert(arr2, 6, data["reset"])
				table.insert(arr2, 7, data["uuid"])
				table.insert(arr2, 8, data["ver"])
				table.insert(tmp, arr2)
			end
		end
		if frmt == "csv"
		then
			for i=1,#tmp,1 do
			   tmp[i]=table.concat(tmp[i],",")
			end
			return table.concat(tmp,"\n")
		else
			return tmp
		end
	else -- json
		local data = self.data
		return LibJSON.Serialize(data)
	end
end

--[[ Database ]]--

local Database = {}
Database.__index = Database

function Database.new(data)
	local self = setmetatable({}, Database)
	self.data = data or {}
	self.cache = {}
	self.hooks = {}
	return self
end

function Database.get_data(self)
	return self.data
end

function Database.clear_cache(self)
	local maxcache = 64
	local t = self.cache
	while maxcache<#t
	do
		k,_ = pairs(t)(t)
		t[k]=nil
	end
end

function Database.get_dungeons_iterator(self)
	local i = 0
	local t = self.data
	local n = #t
	return function()
		i = i + 1
		if i <= n then return Dungeon.new_raw(t[i]) end
	end
end

function Database.get_dungeons_iterator_reverse(self)
	local t = self.data
	local i = #t + 1
	return function()
		i = i - 1
		if  1 <= i then return Dungeon.new_raw(t[i]) end
	end
end

function Database.get_dungeon_by_uuid(self, uuid)
	local cache = self.cache[uuid]
	if cache
	then
		return cache
	end
	local uuid_datepart = SlackerHelper.hex_to_int(strsub(uuid,1,8))
	local dungeons = self.data
	for i = #dungeons,1,-1
	do
		local dungeon = dungeons[i]
		if dungeon["date"]<uuid_datepart
		then
			return nil
		end
		if dungeon["uuid"]==uuid
		then
			self.cache[uuid]=dungeon
			self:clear_cache()
			return Dungeon.new_raw(dungeon)
		end
	end
	return nil
end

function Database.get_dungeon_matching(self, owner, datetime, zid, iid, reset)
	local dungeons = self.data
	zid = zid or 0
	reset = reset or 0
	for i = #dungeons,1,-1
	do
		local dungeon = dungeons[i]
		local tmp_owner = dungeon["owner"]
		local tmp_datetime = dungeon["date"]
		local tmp_reset = dungeon["reset"]
		local tmp_iid = dungeon["iid"]
		local tmp_zid = dungeon["zid"]
		-- has reset timer and older than a week or no reset timer and older than a day, don't continue
		if (0<reset and (datetime-tmp_datetime)>604800) or (reset<=0 and (datetime-tmp_datetime)>86400) 
		then
			return nil
		end
		-- owner and instance id must be same
		if owner==tmp_owner and tmp_iid == iid
		then
			if 
				-- same zone id that was started in the last 3 hours
				(zid~=0 and tmp_zid==zid and datetime-tmp_datetime<10800) or 
				-- no zone id and was started in the last 1 hour
				((zid==0 or tmp_zid==0) and datetime-tmp_datetime<3600) or 
				-- has reset timer and still active
				(0<tmp_reset and tmp_reset>datetime)
			then
				return Dungeon.new_raw(dungeon)
			end
		end
	end
	return nil
end

function Database.get_snapshot_by_uuid(self, uuid)
	local cache = self.cache[uuid]
	if cache
	then
		return cache
	end
	local uuid_dung_prefix = strsub(uuid,1,14)
	local uuid_datepart = SlackerHelper.hex_to_int(strsub(uuid,1,8))
	local dungeons = self.data
	for i = #dungeons,1,-1
	do
		local dungeon = dungeons[i]
		if dungeon["date"]<uuid_datepart
		then
			return nil
		end
		if SlackerHelper.starts_with(dungeon["uuid"], uuid_dung_prefix)
		then
			local snapshots = dungeon["snap"]
			for j = #snapshots,1,-1
			do
				local snapshot = snapshots[j]
				if snapshot["uuid"]==uuid
				then
					self.cache[uuid]=snapshot
					self:clear_cache()
					return Snapshot.new_raw(snapshot)
				end
			end
		end
	end
	return nil
end

-- hook: function(change, what, dungeon, snapshot), where change="add"|"remove", what="dungeon"|"snapshot"|"multiple", dungeon and snapshots are COPIES of the affected objects, nil if multiple
function Database.onchange_add_hook(self, func, key ) 
	if key
	then
		self.hooks[key]=func
	else
		table.insert(self.hooks, func)
	end
end

function Database.onchange_remove_hook(self, key ) 
	self.hooks[key]=nil
end

function Database.onchange_clear_hooks(self, key ) 
	self.hooks = {}
end

function Database.onchange_fire_hooks(self, change, what, dungeon, snapshot ) 
	for _,func in pairs(self.hooks)
	do
		func(change,what,dungeon,snapshot)
	end
end

function Database.add_dungeon(self, dungeon)
	if dungeon.data
	then
		dungeon = dungeon.data
	end
	table.insert(self.data, dungeon)
	dungeon=Dungeon.new_raw(dungeon)
	self:onchange_fire_hooks("add","dungeon",dungeon,nil)
end

function Database.add_snapshot(self, dungeon, snapshot)
	if not dungeon.data
	then
		dungeon = self:get_dungeon_by_uuid(dungeon)
	end
	if dungeon
	then
		local uuid_pre = strsub(dungeon.data["uuid"],1,14)
		if snapshot.data
		then
			snapshot = snapshot.data
		end
		snapshot["uuid"]=uuid_pre..strsub(snapshot["uuid"],14)
		table.insert(dungeon.data["snap"], snapshot)
		snapshot=Snapshot.new_raw(snapshot)
		self:onchange_fire_hooks("add","snapshot",dungeon,snapshot)
	end
end

function Database.remove_dungeon(self, dungeon)
	local uuid = dungeon
	if dungeon.data
	then
		uuid = dungeon:get_uuid()
	end
	local uuid_datepart = SlackerHelper.hex_to_int(strsub(uuid,1,8))
	local dungeons = self.data
	for i = #dungeons,1,-1
	do
		local dungeon = dungeons[i]
		if dungeon["date"]<uuid_datepart
		then
			return
		end
		if dungeon["uuid"]==uuid
		then
			table.remove(dungeons, i)
			self.cache[uuid]=nil
			dungeon=Dungeon.new_raw(dungeon)
			self:onchange_fire_hooks("remove","dungeon",dungeon,nil)
			return
		end
	end
end

function Database.remove_dungeon_older(self, datetime)
	local dungeons = self.data
	local deleted = false
	local i = 1
	while i<=#dungeons
	do
		local dungeon = dungeons[i]
		if dungeon["date"]<datetime
		then
			table.remove(dungeons, i)
			self.cache[dungeon["uuid"]]=nil
			deleted=true
			i = i-1
		else
			break
		end
		i = i+1
	end
	if deleted
	then
		self:onchange_fire_hooks("remove","multiple",nil,nil)
	end
end

function Database.remove_dungeon_maxnum(self, maxnum)
	local dungeons = self.data
	local deleted = false
	while maxnum<#dungeons
	do
		local dungeon = dungeons[1]
		table.remove(dungeons, 1)
		self.cache[dungeon["uuid"]]=nil
		deleted=true
	end
	if deleted
	then
		self:onchange_fire_hooks("remove","multiple",nil,nil)
	end
end

function Database.reset(self, maxnum)
	self:remove_dungeon_maxnum(0)
end

function Database.remove_snapshot(self, snapshot)
	local uuid = snapshot
	if snapshot.data
	then
		uuid = snapshot:get_uuid()
	end
	local uuid_dung_prefix = strsub(uuid,1,14)
	local uuid_datepart = SlackerHelper.hex_to_int(strsub(uuid,1,8))
	local dungeons = self.data
	for i = #dungeons,1,-1
	do
		local dungeon = dungeons[i]
		if dungeon["date"]<uuid_datepart
		then
			return
		end
		if SlackerHelper.starts_with(dungeon["uuid"], uuid_dung_prefix)
		then
			local snapshots = dungeon["snap"]
			for j = #snapshots,1,-1
			do
				local snapshot = snapshots[j]
				if snapshot["uuid"]==uuid
				then
					table.remove(snapshots, j)
					self.cache[uuid]=nil
					snapshot=Snapshot.new_raw(snapshot)
					dungeon=Dungeon.new_raw(dungeon)
					self:onchange_fire_hooks("remove","snapshot",dungeon,snapshot)
					return 
				end
			end
		end
	end
end

function Database.serialize(self, frmt)
	if frmt == "csv" or frmt == "array"
	then
		local tmp = {}
		for dungeon in self:get_dungeons_iterator()
		do
			local arr = dungeon:serialize("array")
			for i=1,#arr,1 do
				local arr2 = arr[i]
				table.insert(tmp, arr2)
			end
		end
		if frmt == "csv"
		then
			for i=1,#tmp,1 do
			   tmp[i]=table.concat(tmp[i],",")
			end
			return table.concat(tmp,"\n")
		else
			return tmp
		end
	else -- json
		local data = self.data
		return LibJSON.Serialize(data)
	end
end

SlackerData.Database = Database
SlackerData.Dungeon = Dungeon
SlackerData.Snapshot = Snapshot
SlackerData.Player = Player
SlackerData.Buff = Buff

