--[[ Globals ]]--

SlackerChecker_BuffPriorityLookup = {
	-- dmf
	["23735"] = 20, -- Sayge's Dark Fortune of Strength
	["23736"] = 20, -- Sayge's Dark Fortune of Agility
	["23737"] = 20, -- Sayge's Dark Fortune of Stamina
	["23738"] = 20, -- Sayge's Dark Fortune of Spirit
	["23766"] = 20, -- Sayge's Dark Fortune of Intelligence
	["23767"] = 20, -- Sayge's Dark Fortune of Armor
	["23768"] = 20, -- Sayge's Dark Fortune of Damage
	["23769"] = 20, -- Sayge's Dark Fortune of Resistance
	-- worldbuffs
	["16609"] = 19, -- Warchief's Blessing
	["22888"] = 19, -- Rallying Cry of the Dragonslayer
	["15366"] = 18, -- Songflower Serenade
	["24425"] = 17, -- Spirit of Zandalar
	["22817"] = 16, -- Fengus' Ferocity
	["22818"] = 16, -- Mol'dar's Moxie
	["22820"] = 16, -- Slip'kik's Savvy
	["15123"] = 16, -- Resist Fire UBRS
	-- flask
	["17624"] = 15, -- Flask of Petrification
	["17626"] = 15, -- Flask of the Titans
	["17627"] = 15, -- Flask of Distilled Wisdom
	["17628"] = 15, -- Flask of Supreme Power
	["17629"] = 15, -- Flask of Chromatic Resistance
	-- zanza/blasted lands
	["10667"] = 14, -- R.O.I.D.S.
	["10668"] = 14, -- Lung Juice Cocktail
	["10669"] = 14, -- Ground Scorpok Assay
	["10692"] = 14, -- Cerebral Cortex Compound
	["10693"] = 14, -- Gizzard Gum
	["24382"] = 14, -- Spirit of Zanza
	["24383"] = 14, -- Swiftness of Zanza
	["24417"] = 14, -- Sheen of Zanza
	-- prot potions
	["17543"] = 13, -- Greater Fire Protection Potion
	["17544"] = 13, -- Greater Frost Protection Potion
	["17545"] = 13, -- Greater Holy Protection Potion
	["17546"] = 13, -- Greater Nature Protection Potion 
	["17548"] = 13, -- Greater Shadow Protection Potion 
	["17549"] = 13, -- Greater Arcane Protection Potion
	["7233"] = 12,  -- Fire Protection Potion
	["7239"] = 12,  -- Frost Protection Potion
	["7242"] = 12,  -- Shadow Protection Potion 
	["7245"] = 12,  -- Holy Protection Potion
	["7254"] = 12,  -- Nature Protection Potion 
	-- consumes
	["11405"] = 10, -- Elixir of the Giants
	["17038"] = 10, -- Winterfall Firewater
	["17538"] = 10, -- Elixir of the Mongoose
	["11334"] = 10, -- Elixir of Greater Agility
	["11390"] = 10, -- Arcane Elixir
	["11474"] = 10, -- Elixir of Shadow Power
	["26276"] = 10, -- Elixir of Greater Firepower
	["21920"] = 10, -- Elixir of Frost Power
	["17539"] = 10, -- Greater Arcane Elixir
	["17535"] = 10, -- Elixir of the Sages
	["11348"] = 10, -- Elixir of Superior Defense
	["3593"] = 10,  -- Elixir of Fortitude
	["3223"] = 10,  -- Mighty Troll's Blood Potion
	["24373"] = 10, -- Major Troll's Blood Potion
	["24363"] = 10, -- Mageblood Potion
	["16321"] = 10, -- Juju Escape
	["16322"] = 10, -- Juju Flurry
	["16323"] = 10, -- Juju Power
	["16325"] = 10, -- Juju Chill
	["16326"] = 10, -- Juju Ember
	["16327"] = 10, -- Juju Guile
	["16329"] = 10, -- Juju Might
	["22789"] = 10, -- Gordok Green Grog
	-- food
	["22730"] = 9, -- Runn Tum Tuber Surprise
	["22731"] = 9, -- Runn Tum Tuber Surprise
	["24800"] = 9, -- Smoked Desert Dumplings
	["24799"] = 9, -- Smoked Desert Dumplings
	["18192"] = 9, -- Grilled Squid
	["18230"] = 9, -- Grilled Squid
	["19709"] = 9, -- Hot Wolf Ribs / Barbecued Buzzard Wing / etc
	["5007"]  = 9, -- Hot Wolf Ribs / Barbecued Buzzard Wing / etc
	["19710"] = 9, -- Tender Wolf Steak / Spiced Chili Crab / etc
	["10256"] = 9, -- Tender Wolf Steak / Spiced Chili Crab / etc
	["18233"] = 9, -- Nightfin Soup
	["18194"] = 9, -- Nightfin Soup
	["25660"] = 9, -- Dirge's Kickin' Chimaerok Chops
	["25661"] = 9, -- Dirge's Kickin' Chimaerok Chops
	["15852"] = 9, -- Dragonbreath Chili
	["18124"] = 9, -- Blessed Sunfruit
	["18125"] = 9, -- Blessed Sunfruit
	-- buffs
	["20765"] = 8, -- Soulstone Resurrection
	["21564"] = 8, -- Prayer of Fortitude
	["10938"] = 8, -- Power Word: Fortitude
	["27681"] = 8, -- Prayer of Spirit
	["27841"] = 8, -- Divine Spirit
	["27683"] = 8, -- Prayer of Shadow Protection
	["21850"] = 8, -- Gift of the Wild
	["9885"] = 8, -- Mark of the Wild
	["23028"] = 8, -- Arcane Brilliance
	["10157"] = 8, -- Arcane Intellect
	-- auras/totems
	["17007"] = 7, -- Leader of the Pack
	["24907"] = 7, -- Leader of the Pack
	["20906"] = 7, -- Trueshot Aura
	["13159"] = 7, -- Aspect of the Pack
	["20190"] = 7, -- Aspect of the Wild
	["10293"] = 7, -- Devotion Aura
	["19746"] = 7, -- Concentration Aura
	["19900"] = 7, -- Fire Resistance Aura
	["19898"] = 7, -- Frost Resistance Aura
	["19896"] = 7, -- Shadow Resistance Aura
	["10301"] = 7, -- Retribution Aura
	["20218"] = 7, -- Sanctity Aura
	["10441"] = 7, -- Strength of Earth
	["25909"] = 7, -- Tranquil Air
	["10535"] = 7, -- Fire Resistance
	["10477"] = 7, -- Frost Resistance
	["10599"] = 7, -- Nature Resistance
	["10405"] = 7, -- Stoneskin
	["15110"] = 7, -- Windwall
	["10626"] = 7, -- Grace of Air
	["24853"] = 7, -- Mana Spring
	["17360"] = 7, -- Mana Tide
	["10461"] = 7, -- Healing Stream
	["11767"] = 7, -- Blood Pact
	["25289"] = 7, -- Battle Shout
}