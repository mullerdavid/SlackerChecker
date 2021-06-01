--[[ Buff info ]]--

local lookup_buff_priority = nil

SlackerHelper.BuffPriority = {
   DMF = 20,
   WB1 = 19,
   WB2 = 18,
   WB3 = 17,
   WB4 = 16,
   FLASK = 15,
   ZANZA = 14,
   GPROT = 13,
   PROT = 12,
   CONS = 10,
   FOOD = 9,
   BUFF = 8,
   AURA = 7,
   OTHER = 0,
}

function SlackerHelper.get_buff_priority(buffid)
	return lookup_buff_priority[buffid] or 0
end

function SlackerHelper.buff_compare(first, second)
	local firstprio = SlackerHelper.get_buff_priority(first)
	local secondprio = SlackerHelper.get_buff_priority(second)
	if (firstprio ~= secondprio)
	then
		return firstprio > secondprio
	end
	return first < second
end

function SlackerHelper.is_dmf_week(timestamp)
	-- DMF spawns the following monday after first friday of the month at daily reset time and lasts for a week.
	-- TODO: Regional offsets, reset time offsets, EU Monday 4am UTC reset time
	local weekday = tonumber(date("%w", timestamp), 10)
	local dotm = tonumber(date("%d", timestamp), 10)
	local monday = dotm-weekday+1
	local friday = monday-3
	return (1<=friday and friday<7)
end

--[[ Lookup tables ]]--

local p = SlackerHelper.BuffPriority
lookup_buff_priority = {
	-- dmf
	[23735] = p.DMF,   -- Sayge's Dark Fortune of Strength
	[23736] = p.DMF,   -- Sayge's Dark Fortune of Agility
	[23737] = p.DMF,   -- Sayge's Dark Fortune of Stamina
	[23738] = p.DMF,   -- Sayge's Dark Fortune of Spirit
	[23766] = p.DMF,   -- Sayge's Dark Fortune of Intelligence
	[23767] = p.DMF,   -- Sayge's Dark Fortune of Armor
	[23768] = p.DMF,   -- Sayge's Dark Fortune of Damage
	[23769] = p.DMF,   -- Sayge's Dark Fortune of Resistance
	-- worldbuffs        
	[355366] = p.WB1,  -- Warchief's Blessing
	[16609] = p.WB1,   -- Warchief's Blessing
	[355363] = p.WB1,  -- Rallying Cry of the Dragonslayer
	[22888] = p.WB1,   -- Rallying Cry of the Dragonslayer
	[15366] = p.WB2,   -- Songflower Serenade
	[355365] = p.WB3,  -- Spirit of Zandalar
	[24425] = p.WB3,   -- Spirit of Zandalar
	[22817] = p.WB4,   -- Fengus' Ferocity
	[22818] = p.WB4,   -- Mol'dar's Moxie
	[22820] = p.WB4,   -- Slip'kik's Savvy
	[15123] = p.WB4,   -- Resist Fire UBRS
	-- flask
	[17624] = p.FLASK, -- Flask of Petrification
	[17626] = p.FLASK, -- Flask of the Titans
	[17627] = p.FLASK, -- Flask of Distilled Wisdom
	[17628] = p.FLASK, -- Flask of Supreme Power
	[17629] = p.FLASK, -- Flask of Chromatic Resistance
	-- zanza/blasted lands
	[10667] = p.ZANZA, -- R.O.I.D.S.
	[10668] = p.ZANZA, -- Lung Juice Cocktail
	[10669] = p.ZANZA, -- Ground Scorpok Assay
	[10692] = p.ZANZA, -- Cerebral Cortex Compound
	[10693] = p.ZANZA, -- Gizzard Gum
	[24382] = p.ZANZA, -- Spirit of Zanza
	[24383] = p.ZANZA, -- Swiftness of Zanza
	[24417] = p.ZANZA, -- Sheen of Zanza
	-- prot potions
	[17543] = p.GPROT, -- Greater Fire Protection Potion
	[17544] = p.GPROT, -- Greater Frost Protection Potion
	[17545] = p.GPROT, -- Greater Holy Protection Potion
	[17546] = p.GPROT, -- Greater Nature Protection Potion 
	[17548] = p.GPROT, -- Greater Shadow Protection Potion 
	[17549] = p.GPROT, -- Greater Arcane Protection Potion
	[7233] = p.PROT,   -- Fire Protection Potion
	[7239] = p.PROT,   -- Frost Protection Potion
	[7242] = p.PROT,   -- Shadow Protection Potion 
	[7245] = p.PROT,   -- Holy Protection Potion
	[7254] = p.PROT,   -- Nature Protection Potion 
	-- consumes
	[11405] = p.CONS,  -- Elixir of the Giants
	[17038] = p.CONS,  -- Winterfall Firewater
	[17538] = p.CONS,  -- Elixir of the Mongoose
	[11334] = p.CONS,  -- Elixir of Greater Agility
	[11390] = p.CONS,  -- Arcane Elixir
	[11474] = p.CONS,  -- Elixir of Shadow Power
	[26276] = p.CONS,  -- Elixir of Greater Firepower
	[21920] = p.CONS,  -- Elixir of Frost Power
	[17539] = p.CONS,  -- Greater Arcane Elixir
	[17535] = p.CONS,  -- Elixir of the Sages
	[11348] = p.CONS,  -- Elixir of Superior Defense
	[3593]  = p.CONS,  -- Elixir of Fortitude
	[3223]  = p.CONS,  -- Mighty Troll's Blood Potion
	[24373] = p.CONS,  -- Major Troll's Blood Potion
	[24363] = p.CONS,  -- Mageblood Potion
	[16321] = p.CONS,  -- Juju Escape
	[16322] = p.CONS,  -- Juju Flurry
	[16323] = p.CONS,  -- Juju Power
	[16325] = p.CONS,  -- Juju Chill
	[16326] = p.CONS,  -- Juju Ember
	[16327] = p.CONS,  -- Juju Guile
	[16329] = p.CONS,  -- Juju Might
	[22789] = p.CONS,  -- Gordok Green Grog
	[22790] = p.CONS,  -- Kreeg's Stout Beatdown
	[25804] = p.CONS,  -- Rumsey Rum Black Label
	[25722] = p.CONS,  -- Rumsey Rum Dark
	[20875] = p.CONS,  -- Rumsey Rum
	[25037] = p.CONS,  -- Rumsey Rum Light
	-- food
	[22730] = p.FOOD, -- Runn Tum Tuber Surprise
	[22731] = p.FOOD, -- Runn Tum Tuber Surprise
	[24800] = p.FOOD, -- Smoked Desert Dumplings
	[24799] = p.FOOD, -- Smoked Desert Dumplings
	[18192] = p.FOOD, -- Grilled Squid
	[18230] = p.FOOD, -- Grilled Squid
	[19709] = p.FOOD, -- Hot Wolf Ribs / Barbecued Buzzard Wing / etc
	[5007]  = p.FOOD, -- Hot Wolf Ribs / Barbecued Buzzard Wing / etc
	[19710] = p.FOOD, -- Tender Wolf Steak / Spiced Chili Crab / etc
	[10256] = p.FOOD, -- Tender Wolf Steak / Spiced Chili Crab / etc
	[18233] = p.FOOD, -- Nightfin Soup
	[18194] = p.FOOD, -- Nightfin Soup
	[25660] = p.FOOD, -- Dirge's Kickin' Chimaerok Chops
	[25661] = p.FOOD, -- Dirge's Kickin' Chimaerok Chops
	[15852] = p.FOOD, -- Dragonbreath Chili
	[18124] = p.FOOD, -- Blessed Sunfruit
	[18125] = p.FOOD, -- Blessed Sunfruit
	-- buffs
	[20765] = p.BUFF, -- Soulstone Resurrection
	[21564] = p.BUFF, -- Prayer of Fortitude
	[10938] = p.BUFF, -- Power Word: Fortitude
	[27681] = p.BUFF, -- Prayer of Spirit
	[27841] = p.BUFF, -- Divine Spirit
	[27683] = p.BUFF, -- Prayer of Shadow Protection
	[10958] = p.BUFF, -- Shadow Protection
	[21850] = p.BUFF, -- Gift of the Wild
	[9885]  = p.BUFF, -- Mark of the Wild
	[23028] = p.BUFF, -- Arcane Brilliance
	[10157] = p.BUFF, -- Arcane Intellect
	-- auras/totems
	[17007] = p.AURA, -- Leader of the Pack
	[24907] = p.AURA, -- Leader of the Pack
	[20906] = p.AURA, -- Trueshot Aura
	[13159] = p.AURA, -- Aspect of the Pack
	[20190] = p.AURA, -- Aspect of the Wild
	[10293] = p.AURA, -- Devotion Aura
	[19746] = p.AURA, -- Concentration Aura
	[19900] = p.AURA, -- Fire Resistance Aura
	[19898] = p.AURA, -- Frost Resistance Aura
	[19896] = p.AURA, -- Shadow Resistance Aura
	[10301] = p.AURA, -- Retribution Aura
	[20218] = p.AURA, -- Sanctity Aura
	[10441] = p.AURA, -- Strength of Earth
	[25909] = p.AURA, -- Tranquil Air
	[10535] = p.AURA, -- Fire Resistance
	[10477] = p.AURA, -- Frost Resistance
	[10599] = p.AURA, -- Nature Resistance
	[10405] = p.AURA, -- Stoneskin
	[15110] = p.AURA, -- Windwall
	[10626] = p.AURA, -- Grace of Air
	[24853] = p.AURA, -- Mana Spring
	[17360] = p.AURA, -- Mana Tide
	[10461] = p.AURA, -- Healing Stream
	[11767] = p.AURA, -- Blood Pact
	[25289] = p.AURA, -- Battle Shout
}

