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
   GUARD = 11,
   BATTLE = 10,
   SCROLL = 9,
   CONS = 8,
   FOOD = 7,
   BUFF = 6,
   AURA = 5,
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
lookup_buff_priority = 
-- TBC
SlackerHelper.is_tbc() and {
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
	[39953] = p.WB1,   -- A'dal's Song of Battle
	[32049] = p.WB1,   -- Hellfire Superiority
	[32071] = p.WB1,   -- Hellfire Superiority
	[34410] = p.WB1,   -- Hellscream's Warsong
	[33377] = p.WB1,   -- Blessing of Auchindoun
	[35076] = p.WB1,   -- Blessing of A'dal
	-- flask
	[17624] = p.FLASK, -- Flask of Petrification
	[17626] = p.FLASK, -- Flask of the Titans
	[17627] = p.FLASK, -- Flask of Distilled Wisdom
	[17628] = p.FLASK, -- Flask of Supreme Power
	[17629] = p.FLASK, -- Flask of Chromatic Resistance
	[28518] = p.FLASK, -- Flask of Fortification
	[28540] = p.FLASK, -- Flask of Pure Death
	[28520] = p.FLASK, -- Flask of Relentless Assault
	[28521] = p.FLASK, -- Flask of Blinding Light
	[28519] = p.FLASK, -- Flask of Mighty Restoration
	[42735] = p.FLASK, -- Flask of Chromatic Wonder
	[41609] = p.FLASK, -- Shattrath Flask of Fortification
	[46837] = p.FLASK, -- Shattrath Flask of Pure Death
	[41608] = p.FLASK, -- Shattrath Flask of Relentless Assault
	[46839] = p.FLASK, -- Shattrath Flask of Blinding Light
	[41610] = p.FLASK, -- Shattrath Flask of Mighty Restoration
	[41611] = p.FLASK, -- Shattrath Flask of Supreme Power
	[40572] = p.FLASK, -- Unstable Flask of the Beast
	[40576] = p.FLASK, -- Unstable Flask of the Sorcerer
	[40567] = p.FLASK, -- Unstable Flask of the Bandit
	[40568] = p.FLASK, -- Unstable Flask of the Elder
	[40573] = p.FLASK, -- Unstable Flask of the Physician
	[40575] = p.FLASK, -- Unstable Flask of the Soldier
	-- prot potions
	[28511] = p.GPROT, -- Major Fire Protection Potion
	[28512] = p.GPROT, -- Major Frost Protection Potion
	[28538] = p.GPROT, -- Major Holy Protection Potion
	[28513] = p.GPROT, -- Major Nature Protection Potion 
	[28537] = p.GPROT, -- Major Shadow Protection Potion 
	[28536] = p.GPROT, -- Major Arcane Protection Potion
	[17543] = p.PROT,  -- Greater Fire Protection Potion
	[17544] = p.PROT,  -- Greater Frost Protection Potion
	[17545] = p.PROT,  -- Greater Holy Protection Potion
	[17546] = p.PROT,  -- Greater Nature Protection Potion 
	[17548] = p.PROT,  -- Greater Shadow Protection Potion 
	[17549] = p.PROT,  -- Greater Arcane Protection Potion
	[7233] = p.PROT,   -- Fire Protection Potion
	[7239] = p.PROT,   -- Frost Protection Potion
	[7242] = p.PROT,   -- Shadow Protection Potion 
	[7245] = p.PROT,   -- Holy Protection Potion
	[7254] = p.PROT,   -- Nature Protection Potion 
	-- guardian elixirs
	[28514] = p.GUARD, -- Elixir of Empowerment
	[28509] = p.GUARD, -- Elixir of Major Mageblood
	[28502] = p.GUARD, -- Elixir of Major Defense
	[39628] = p.GUARD, -- Elixir of Ironskin
	[39627] = p.GUARD, -- Elixir of Draenic Wisdom
	[39626] = p.GUARD, -- Earthen Elixir
	[39625] = p.GUARD, -- Elixir of Major Fortitude
	[24382] = p.GUARD, -- Spirit of Zanza
	[24383] = p.GUARD, -- Swiftness of Zanza
	[24417] = p.GUARD, -- Sheen of Zanza
	[24363] = p.GUARD, -- Mageblood Potion
	[24373] = p.GUARD, -- Major Troll's Blood Potion
	[17535] = p.GUARD, -- Elixir of the Sages
	[11348] = p.GUARD, -- Elixir of Superior Defense
	[10668] = p.GUARD, -- Lung Juice Cocktail
	[10692] = p.GUARD, -- Cerebral Cortex Compound
	[10693] = p.GUARD, -- Gizzard Gum
	-- battle elixirs
	[28503] = p.BATTLE, -- Elixir of Major Shadow Power
	[38954] = p.BATTLE, -- Fel Strength Elixir
	[28497] = p.BATTLE, -- Elixir of Major Agility
	[28501] = p.BATTLE, -- Elixir of Major Firepower
	[28493] = p.BATTLE, -- Elixir of Major Frost Power
	[28491] = p.BATTLE, -- Elixir of Healing Power
	[33726] = p.BATTLE, -- Elixir of Mastery
	[28490] = p.BATTLE, -- Elixir of Major Strength
	[33721] = p.BATTLE, -- Adept's Elixir
	[33720] = p.BATTLE, -- Onslaught Elixir
	[11406] = p.BATTLE, -- Elixir of Demonslaying
	[17538] = p.BATTLE, -- Elixir of the Mongoose
	[10667] = p.BATTLE, -- R.O.I.D.S.
	[10669] = p.BATTLE, -- Ground Scorpok Assay
	[17539] = p.BATTLE, -- Greater Arcane Elixir
	[17038] = p.BATTLE, -- Winterfall Firewater
	[16329] = p.BATTLE, -- Juju Might
	[16323] = p.BATTLE, -- Juju Power
	[26276] = p.BATTLE, -- Elixir of Greater Firepower
	[11474] = p.BATTLE, -- Elixir of Shadow Power
	[11405] = p.BATTLE, -- Elixir of the Giants
	[17537] = p.BATTLE, -- Elixir of Brute Force
	-- scrolls
	[33077] = p.SCROLL, -- Scroll of Agility V
	[33078] = p.SCROLL, -- Scroll of Intellect V
	[33079] = p.SCROLL, -- Scroll of Protection V
	[33080] = p.SCROLL, -- Scroll of Spirit V
	[33081] = p.SCROLL, -- Scroll of Stamina V
	[33082] = p.SCROLL, -- Scroll of Strength V
	-- consumes
	[28515] = p.CONS, -- Ironshield Potion
	[28508] = p.CONS, -- Destruction Potion
	[28507] = p.CONS, -- Haste Potion
	[28506] = p.CONS, -- Heroic Potion
	[28494] = p.CONS, -- Insane Strength Potion
	[28492] = p.CONS, -- Sneaking Potion
	[28548] = p.CONS, -- Shrouding Potion
	-- food
	[33257] = p.FOOD, -- Fisherman's Feast / Spicy Crawdad
	[33258] = p.FOOD, -- Fisherman's Feast / Spicy Crawdad
	[35271] = p.FOOD, -- Mok'Nathal Shortribs / Talbuk Steak
	[35272] = p.FOOD, -- Mok'Nathal Shortribs / Talbuk Steak
	[45020] = p.FOOD, -- Hot Apple Cider
	[45245] = p.FOOD, -- Hot Apple Cider
	[33253] = p.FOOD, -- Buzzard Bites / Clam Bar / Feltail Delight
	[33254] = p.FOOD, -- Buzzard Bites / Clam Bar / Feltail Delight
	[33269] = p.FOOD, -- Golden Fish Sticks
	[33268] = p.FOOD, -- Golden Fish Sticks
	[33264] = p.FOOD, -- Oronok's Tuber of Spell Power / Blackened Basilisk / Crunchy Serpent / Poached Bluefish
	[33263] = p.FOOD, -- Oronok's Tuber of Spell Power / Blackened Basilisk / Crunchy Serpent / Poached Bluefish
	[33260] = p.FOOD, -- Ravager Dog
	[33259] = p.FOOD, -- Ravager Dog
	[33262] = p.FOOD, -- Oronok's Tuber of Agility / Grilled Mudfish / Warp Burger
	[33261] = p.FOOD, -- Oronok's Tuber of Agility / Grilled Mudfish / Warp Burger
	[33256] = p.FOOD, -- Roasted Clefthoof
	[33255] = p.FOOD, -- Roasted Clefthoof
	[43764] = p.FOOD, -- Spicy Hot Talbuk
	[43763] = p.FOOD, -- Spicy Hot Talbuk
	[43722] = p.FOOD, -- Skullfish Soup
	[43706] = p.FOOD, -- Skullfish Soup
	[33265] = p.FOOD, -- Blackened Sporefish
	[33266] = p.FOOD, -- Blackened Sporefish
	[45619] = p.FOOD, -- Broiled Bloodfin
	[45618] = p.FOOD, -- Broiled Bloodfin
	[43730] = p.FOOD, -- Stormchops
	[25660] = p.FOOD, -- Dirge's Kickin' Chimaerok Chops
	[25661] = p.FOOD, -- Dirge's Kickin' Chimaerok Chops
	[22730] = p.FOOD, -- Runn Tum Tuber Surprise
	[22731] = p.FOOD, -- Runn Tum Tuber Surprise
	[24800] = p.FOOD, -- Smoked Desert Dumplings
	[24799] = p.FOOD, -- Smoked Desert Dumplings
	[18233] = p.FOOD, -- Nightfin Soup
	[18194] = p.FOOD, -- Nightfin Soup
	[25804] = p.CONS,  -- Rumsey Rum Black Label
	-- buffs
	[27239] = p.BUFF, -- Soulstone Resurrection
	[25392] = p.BUFF, -- Prayer of Fortitude
	[25389] = p.BUFF, -- Power Word: Fortitude
	[32999] = p.BUFF, -- Prayer of Spirit
	[25312] = p.BUFF, -- Divine Spirit
	[39374] = p.BUFF, -- Prayer of Shadow Protection
	[25433] = p.BUFF, -- Shadow Protection
	[26991] = p.BUFF, -- Gift of the Wild
	[26990]  = p.BUFF, -- Mark of the Wild
	[27127] = p.BUFF, -- Arcane Brilliance
	[27126] = p.BUFF, -- Arcane Intellect
	-- auras/totems
	[26992] = p.AURA, -- Thorns
	[17007] = p.AURA, -- Leader of the Pack
	[24907] = p.AURA, -- Moonkin Aura
	[27066] = p.AURA, -- Trueshot Aura
	[13159] = p.AURA, -- Aspect of the Pack
	[27045] = p.AURA, -- Aspect of the Wild
	[27149] = p.AURA, -- Devotion Aura
	[19746] = p.AURA, -- Concentration Aura
	[27153] = p.AURA, -- Fire Resistance Aura
	[27152] = p.AURA, -- Frost Resistance Aura
	[27151] = p.AURA, -- Shadow Resistance Aura
	[27150] = p.AURA, -- Retribution Aura
	[20218] = p.AURA, -- Sanctity Aura
	[25527] = p.AURA, -- Strength of Earth
	[25909] = p.AURA, -- Tranquil Air
	[25562] = p.AURA, -- Fire Resistance
	[25559] = p.AURA, -- Frost Resistance
	[25573] = p.AURA, -- Nature Resistance
	[25507] = p.AURA, -- Stoneskin
	[25576] = p.AURA, -- Windwall
	[25360] = p.AURA, -- Grace of Air
	[25569] = p.AURA, -- Mana Spring
	[17360] = p.AURA, -- Mana Tide
	[25566] = p.AURA, -- Healing Stream
	[27488] = p.AURA, -- Blood Pact
	[35079] = p.AURA, -- Misdirection
	[2048] = p.AURA,  -- Battle Shout
	[469] = p.AURA,   -- Commanding Shout
	[1044]  = p.AURA, -- Blessing of Freedom
	[20217] = p.AURA, -- Blessing of Kings
	[25898] = p.AURA, -- Greater Blessing of Kings
	[27144] = p.AURA, -- Blessing of Light
	[27145] = p.AURA, -- Greater Blessing of Light
	[27140] = p.AURA, -- Blessing of Might
	[27141] = p.AURA, -- Greater Blessing of Might
	[10278] = p.AURA, -- Blessing of Protection
	[27148] = p.AURA, -- Blessing of Sacrifice
	[1038]  = p.AURA, -- Blessing of Salvation
	[25895] = p.AURA, -- Greater Blessing of Salvation
	[27168] = p.AURA, -- Blessing of Sanctuary
	[27169] = p.AURA, -- Greater Blessing of Sanctuary
	[27142] = p.AURA, -- Blessing of Wisdom
	[27143] = p.AURA, -- Greater Blessing of Wisdom
}
-- Classic
or {
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
	[24907] = p.AURA, -- Moonkin Aura
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
	[1044]  = p.AURA, -- Blessing of Freedom
	[20217] = p.AURA, -- Blessing of Kings
	[25898] = p.AURA, -- Greater Blessing of Kings
	[19979] = p.AURA, -- Blessing of Light
	[25890] = p.AURA, -- Greater Blessing of Light
	[25291] = p.AURA, -- Blessing of Might
	[25916] = p.AURA, -- Greater Blessing of Might
	[10278] = p.AURA, -- Blessing of Protection
	[20729] = p.AURA, -- Blessing of Sacrifice
	[1038]  = p.AURA, -- Blessing of Salvation
	[25895] = p.AURA, -- Greater Blessing of Salvation
	[20914] = p.AURA, -- Blessing of Sanctuary
	[25899] = p.AURA, -- Greater Blessing of Sanctuary
	[25290] = p.AURA, -- Blessing of Wisdom
	[25918] = p.AURA, -- Greater Blessing of Wisdom
}

