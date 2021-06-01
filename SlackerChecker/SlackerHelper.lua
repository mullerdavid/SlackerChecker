--[[ SAVED VARIABLES ]]--

SlackerChecker_Settings = nil

--[[ Utility functions ]]--

local random = math.random
local lookup_default_settings = nil
local lookup_class_color = {}
local lookup_instance_map_id = nil

SlackerHelper = {}
SlackerHelper.date_format = "%Y-%m-%d %H:%M:%S"
SlackerHelper.Addon = "SlackerChecker"

function SlackerHelper.debug(text)
	print(text)
end

function SlackerHelper.info(text)
	print(text)
end

function SlackerHelper.warning(text)
	print("Warning: " .. text)
end

function SlackerHelper.error(text)
	print("Error: " .. text)
end

function SlackerHelper.in_array(needle, array)
	for i=1,#array,1 do
		if needle==array[i]
		then
			return true
		end
	end
	return false
end

function SlackerHelper.array_concat(array1, array2)
	local ret = {}
	for i=1,#array1 do
        table.insert(ret, array1[i])
    end
	for i=1,#array2 do
        table.insert(ret, array2[i])
    end
	return ret
end

function SlackerHelper.array_intersect(array1, array2)
	local tmp = {}
	local ret = {}
	for i=1,#array1 do
		local v = array1[i]
        tmp[v]=true
    end
	for i=1,#array2 do
		local v = array2[i]
        if (tmp[v]) then table.insert(ret, v) end
    end
	return ret
end

function SlackerHelper.get_setting(key)
	if not SlackerChecker_Settings
	then
		SlackerChecker_Settings = {}
	end
	local ret = SlackerChecker_Settings[key]
	if ret==nil
	then
		return lookup_default_settings[key]
	end
	return ret
end

function SlackerHelper.set_setting(key, value)
	if not SlackerChecker_Settings
	then
		SlackerChecker_Settings = {}
	end
	SlackerChecker_Settings[key]=value
end

function SlackerHelper.get_uuid4(prefix)
	local n = 0
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	if prefix
	then
		n = strlen(prefix)
		template = prefix .. strsub(template, n)
	end
	return string.gsub(template, '[xy]', function (c)
		local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
		return string.format('%x', v)
	end)
end

function SlackerHelper.int_to_hex(int, digit)
	local ret = string.format('%x', int)
	if digit
	then
		local n = strlen(ret)
		if digit<n
		then
			ret = strsub(ret, n-digit+1, n)
		elseif n<digit
		then
			ret = string.rep("0", digit-n) .. ret
		end
	end
	return ret
end

function SlackerHelper.hex_to_int(hex)
	return tonumber("0x"..hex)
end

function SlackerHelper.starts_with(str, start)
	return str:sub(1, #start) == start
end

function SlackerHelper.ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

function SlackerHelper.load_colors()
	local lookup_class_color_classic = {
		["Offline"] = { ["r"] = 0.50, ["g"] = 0.50, ["b"] = 0.50, ["a"] = 1.0 },
		["Druid"]   = { ["r"] = 1.00, ["g"] = 0.49, ["b"] = 0.04, ["a"] = 1.0 },
		["Hunter"]  = { ["r"] = 0.67, ["g"] = 0.83, ["b"] = 0.45, ["a"] = 1.0 },
		["Mage"]    = { ["r"] = 0.41, ["g"] = 0.80, ["b"] = 0.94, ["a"] = 1.0 },
		["Paladin"] = { ["r"] = 0.96, ["g"] = 0.55, ["b"] = 0.73, ["a"] = 1.0 },
		["Priest"]  = { ["r"] = 1.00, ["g"] = 1.00, ["b"] = 1.00, ["a"] = 1.0 },
		["Rogue"]   = { ["r"] = 1.00, ["g"] = 0.96, ["b"] = 0.41, ["a"] = 1.0 },
		["Shaman"]  = { ["r"] = 0.00, ["g"] = 0.44, ["b"] = 0.87, ["a"] = 1.0 },
		["Warlock"] = { ["r"] = 0.58, ["g"] = 0.51, ["b"] = 0.79, ["a"] = 1.0 },
		["Warrior"] = { ["r"] = 0.78, ["g"] = 0.61, ["b"] = 0.43, ["a"] = 1.0 },
	}
	local lookup_class_color_retail = {
		["Offline"] = { ["r"] = 0.50, ["g"] = 0.50, ["b"] = 0.50, ["a"] = 1.0 },
		["Druid"]   = { ["r"] = 1.00, ["g"] = 0.49, ["b"] = 0.04, ["a"] = 1.0 },
		["Hunter"]  = { ["r"] = 0.67, ["g"] = 0.83, ["b"] = 0.45, ["a"] = 1.0 },
		["Mage"]    = { ["r"] = 0.25, ["g"] = 0.78, ["b"] = 0.92, ["a"] = 1.0 },
		["Paladin"] = { ["r"] = 0.96, ["g"] = 0.55, ["b"] = 0.73, ["a"] = 1.0 },
		["Priest"]  = { ["r"] = 1.00, ["g"] = 1.00, ["b"] = 1.00, ["a"] = 1.0 },
		["Rogue"]   = { ["r"] = 1.00, ["g"] = 0.96, ["b"] = 0.41, ["a"] = 1.0 },
		["Shaman"]  = { ["r"] = 0.00, ["g"] = 0.44, ["b"] = 0.87, ["a"] = 1.0 },
		["Warlock"] = { ["r"] = 0.53, ["g"] = 0.53, ["b"] = 0.93, ["a"] = 1.0 },
		["Warrior"] = { ["r"] = 0.78, ["g"] = 0.61, ["b"] = 0.43, ["a"] = 1.0 },
	}
	local key = SlackerHelper.get_setting("classcolors")
	if key == "classic"
	then
		lookup_class_color = lookup_class_color_classic
	elseif key == "classic_mod"
	then
		lookup_class_color = lookup_class_color_classic
		lookup_class_color["Shaman"] = lookup_class_color["Paladin"]
	elseif key == "retail"
	then
		lookup_class_color = lookup_class_color_retail
	elseif key == "retail_mod"
	then
		lookup_class_color = lookup_class_color_retail
		lookup_class_color["Shaman"] = lookup_class_color["Paladin"]
	end
end

function SlackerHelper.class_to_color(class_str)
	if lookup_class_color[class_str]
	then
		return lookup_class_color[class_str]
	end
	return { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5,	["a"] = 1.0 }
end

function SlackerHelper.iid_to_str(iid)
	if lookup_instance_map_id[iid]
	then
		return lookup_instance_map_id[iid]
	end
	return nil
end

function SlackerHelper.valid_creature(npc_id)
	if lookup_companion_creatures[npc_id]
	then
		return false
	end
	if lookup_critter_creatures[npc_id]
	then
		return false
	end
	return true
end

function SlackerHelper.loadstring(func_str, name)
	local func = nil
	if func_str ~= ""
	then
		func, err = loadstring(func_str, name);
		if not func
		then
			SlackerHelper.error(err)
		end
	end
	return func
end

function SlackerHelper.eval(func_or_str, context, name)
	local tmp = {}
	local t = type(func_or_str)
	local func = nil
	local err = nil
	if (t=="function")
	then
		func = func_or_str
	elseif (t=="string")
	then
		func, err = loadstring(func_str, name);
	else
		err = "Invalid input"
	end
	if (func)
	then
		setmetatable(tmp, { __index = _G }) 
		for i,v in pairs(context)
		do
			tmp[i] = v
		end
		setfenv(func, tmp)
		return func()
	else
		SlackerHelper.error(err)
	end
	return nil
end

--[[ Lookup tables ]]--

lookup_default_settings = {
	["party"] = false,
	["debug"] = false,
	["dbmaintain"] = "time30",
	["classcolors"] = "classic",
	["record_readycheck"] = true,
	["record_pull"] = true,
	["record_kill"] = false,
	["record_wipe"] = false,
	["script_report_worldbuff"] = "",
	["script_report_consume"] = "",
	["script_award"] = "",
}

lookup_instance_map_id = {
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
	--TODO: add dungeons
}

-- credit fir NIT for tables

lookup_companion_creatures = {
	[9662] = "Sprite Darter Hatchling",
	[7392] = "Prairie Chicken",
	[8376] = "Mechanical Chicken",
	[15699] = "Tranquil Mechanical Yeti",
	[9657] = "Lil' Smoky",
	[9656] = "Tiny Walking Bomb",
	[12419] = "Lifelike Toad",
	[2671] = "Mechanical Squirrel",
	[7544] = "Crimson Whelpling",
	[7543] = "Dark Whelpling",
	[7545] = "Emerald Whelpling",
	[15429] = "Disgusting Oozeling",
	[7391] = "Hyacinth Macaw",
	[7383] = "Black Tabby",
	[10598] = "Smolderweb Hatchling",
	[10259] = "Worg Pup",
	[7387] = "Green Wing Macaw",
	[7380] = "Siamese",
	[7394] = "Ancona Chicken",
	[7390] = "Cockatiel",
	[7389] = "Senegal",
	[7565] = "Black Kingsnake",
	[7562] = "Brown Snake",
	[7567] = "Crimson Snake",
	[7395] = "Cockroach",
	[14421] = "Brown Prairie Dog",
	[7560] = "Snowshoe Rabbit",
	[7555] = "Hawk Owl",
	[7553] = "Great Horned Owl",
	[7385] = "Bombay",
	[7384] = "Cornish Rex",
	[7382] = "Orange Tabby",
	[7381] = "Silver Tabby",
	[7386] = "White Kitten",
	[16085] = "Peddlefeet",
	[16548] = "Mr. Wiggles",
	[16549] = "Whiskers the Rat",
	[16547] = "Speedy",
	[16701] = "Spirit of Summer",
	[15706] = "Winter Reindeer",
	[15710] = "Tiny Snowman",
	[15705] = "Winter's Little Helper",
	[15698] = "Father Winter's Helper",
	[7550] = "Wood Frog",
	[7549] = "Tree Frog",
	[14878] = "Jubling",
	[11327] = "Zergling",
	[11326] = "Mini Diablo <Lord of Terror>",
	[11325] = "Panda Cub",
	[23713] = "Hippogryph Hatchling",
	[15186] = "Murky",
	[16456] = "Poley",
	[14756] = "Tiny Red Dragon",
	[14755] = "Tiny Green Dragon",
	[15361] = "Murki",
	[16069] = "Gurky",
	[16445] = "Terky", --On wowhead for classic, but WOTLK I think?
	[3619] = "Ghost Saber", --Combat compnaion spawned from an item.
	[17255] = "Hippogryph Hatchling",
	[47687] = "Winna's Kitten", --Felwood quest.
	[15661] = "Baby Shark",
	[9936] = "Corrupted Kitten",
	[17254] = "White Tiger Cub", --Not ingame?
	--[999999999] = "Snapjaw", --Turtle Egg (Albino), never made it into game? No ID found.
}

lookup_critter_creatures = {
	[7186] = "A",
	[3300] = "Adder",
	[15475] = "Beetle",
	[10716] = "Belfry Bat",
	[3835] = "Biletoad",
	[2110] = "Black Rat",
	[1932] = "Black Sheep",
	[5740] = "Caged Chicken",
	[5741] = "Caged Rabbit",
	[5743] = "Caged Sheep",
	[5739] = "Caged Squirrel",
	[5742] = "Caged Toad",
	[6368] = "Cat",
	[620] = "Chicken",
	[15066] = "Cleo",
	[13338] = "Core Rat",
	[2442] = "Cow",
	[6827] = "Crab",
	[12299] = "Cured Deer",
	[12297] = "Cured Gazelle",
	[13016] = "Deeprun Rat",
	[883] = "Deer",
	[3444] = "Dig Rat",
	[9658] = "Distract Test",
	[10582] = "Dog",
	[8963] = "Effsee",
	[13017] = "Enthralled Deeprun Rat",
	[5866] = "Equipment Squirrel",
	[5868] = "Evil Squirrel",
	[14892] = "Fang",
	[890] = "Fawn",
	[9699] = "Fire Beetle",
	[1352] = "Fluffy",
	[13321] = "Frog",
	[4166] = "Gazelle",
	[2848] = "Glyx Brewright",
	[5951] = "Hare",
	[385] = "Horse",
	[6653] = "Huge Toad",
	[10780] = "Infected Deer",
	[10779] = "Infected Squirrel",
	[15010] = "Jungle Toad",
	[10541] = "Krakle's Thermometer",
	[15065] = "Lady",
	[16068] = "Larva",
	[9700] = "Lava Crab",
	[16030] = "Maggot",
	[5867] = "Maximum Squirrel",
	[4953] = "Moccasin",
	[6271] = "Mouse",
	[16998] = "Mr. Bigglesworth",
	[12383] = "Nibbles",
	[7208] = "Noarm",
	[582] = "Old Blanchy",
	[9600] = "Parrot",
	[7898] = "Pirate treasure trigger mob",
	[10461] = "Plagued Insect",
	[10536] = "Plagued Maggot",
	[10441] = "Plagued Rat",
	[10510] = "Plagued Slime",
	[12120] = "Plagueland Termite",
	[16479] = "Polymorph Clone",
	[16369] = "Polymorphed Chicken",
	[16779] = "Polymorphed Cow",
	[16373] = "Polymorphed Rat",
	[16372] = "Polymorphed Sheep",
	[2620] = "Prairie Dog",
	[721] = "Rabbit",
	[2098] = "Ram",
	[4075] = "Rat",
	[8881] = "Riding Ram",
	[4076] = "Roach",
	[11776] = "Salome",
	[6145] = "School of Fish",
	[15476] = "Scorpion",
	[1933] = "Sheep",
	[14361] = "Shen'dralar Wisp",
	[12298] = "Sickly Deer",
	[12296] = "Sickly Gazelle",
	[2914] = "Snake",
	[14881] = "Spider",
	[15072] = "Spike",
	[1412] = "Squirrel",
	[5689] = "Steed",
	[10685] = "Swine",
	[10017] = "Tainted Cockroach",
	[10016] = "Tainted Rat",
	[18078] = "The Evil Rabbit",
	[14886] = "The Good Rabbit",
	[1420] = "Toad",
	[14681] = "Transporter Malfunction",
	[15219] = "Trick - Critter",
	[15071] = "Underfoot",
	[12152] = "Voice of Elune",
	[1262] = "White Ram",
	[14801] = "Wild Polymorph Target",
	[3681] = "Wisp",
	[12861] = "Wisp (Ghost Visual Only)",
};