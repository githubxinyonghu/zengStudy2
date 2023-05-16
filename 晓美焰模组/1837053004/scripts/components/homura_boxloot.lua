--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
require "components/lootdropper"
local OffsetQueue = require "homura.container".OffsetQueue

--------------------------------------------------------------------------
--[[ Boxloot class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "Homura_Boxloot should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local PRICES = {
	raw_material = 2.5,    -- 3~4
	semi_material = 4,     -- 2~3
	high_material = 6,     -- 1~2

	homura_gun_ammo1 = 0.2, -- ~40
	homura_rpg_ammo1 = 1,   -- ~8
	bomb = 1.5,			   -- 4~7

	weapon = 999,
	fitting = 999,
	blueprint = 999,
}

local DEFS = {
	-- 硝石/鸟蛋/木炭/金块/蝙蝠粪便
	raw_material = {"nitre", "bird_egg", "charcoal", "goldnugget", "guano"},

	-- 吹箭/火药/雷管
	semi_material = {"blowdart_pipe", "gunpowder", "homura_detonator"},

	-- 齿轮
	high_material = {"gears"},

	bomb = {"homura_bomb_flash", "homura_bomb_bomb", "homura_bomb_fire"},
	weapon = {"homura_hmg", "homura_rpg", "homura_rifle", "homura_gun"},
	fitting = {"homura_weapon_buff_random"},
}

local LOOTLIST_SIZE = 100
local BLUEPRINT_INTERVAL = 10

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------
local _lootlist = nil
local _lootlistlevel = 0
local _lootversion = "new-blueprint-220327"
local _seed = 0
local _index = 0
local _workdesks = {}

local _looter = CreateEntity()
_looter.mr_ignore_luckwater = true
_looter:AddComponent("lootdropper")
local lootdropper = _looter.components.lootdropper

--------------------------------------------------------------------------
--[[ Loot initalization ]]
--------------------------------------------------------------------------
-- 注: blueprint单独添加
SetSharedLootTable("homura_box_loot_1", {
	-- total = 1.5
	{"raw_material", 1.0},
	{"raw_material", 0.5},
})

SetSharedLootTable("homura_box_loot_2", {
	-- total = 3.2
	{"raw_material", 1.0},
	{"semi_material", 1.0},
	{"high_material", 0.2},
	{"homura_gun_ammo1", 0.5},
	{"bomb", 0.5},
})

SetSharedLootTable("homura_box_loot_3", {
	-- total = 5.0
	{"semi_material", 1.0},
	{"high_material", 0.5},
	{"homura_gun_ammo1", 1.0},
	{"homura_gun_ammo1/homura_gun_ammo1/homura_rpg_ammo1", 1.0},
	{"bomb", 1.0},
	{"weapon/fitting/fitting/fitting", 0.5},
})

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetNextSeed()
	if _seed == 0 then
		_seed = inst.meta.seed or 812311194
	else
		_seed = tonumber(tostring(_seed + 1):reverse():sub(1,8))
	end
end

local function ParseAlias(name, price)
	-- print("**",name, price)
	if string.find(name, "/") then
		local list = {}
		for n in string.gmatch(name, "[^/]+")do
			table.insert(list, n)
		end
		return ParseAlias(GetRandomItem(list))
	end
	if DEFS[name] ~= nil then
		return ParseAlias(GetRandomItem(DEFS[name]), PRICES[name] or price)
	end
	price = PRICES[name] or price

	return name, assert(price)
end

local function ParseAliasSafe(name)
	-- print("Try to parse:", name)
	return ParseAlias(name, nil)
end

local function GetMoney()
	return GetRandomWithVariance(8,2)
end

local function DebugPrintLootList()
	for i,v in ipairs(_lootlist)do
		print("Loot ", i)
		for k,v in pairs(v)do
			print("  ", k, v)
		end
		print("---------------------\n")
	end
end

local function Shuffle(t, i, j)
	assert(i < j)
	assert(#t >= j)
	for index = i, j-1 do
		local newindex = math.random(index+1, j)
		if newindex ~= index then
			t[index], t[newindex] = t[newindex], t[index]
		end
	end
end

local function GenerateLootList(level)
	print("[homura] GenerateLootList with level ", level)
	_lootlist = {}
	_lootlistlevel = level
	_index = 0
	GetNextSeed()


	math.randomseed(_seed)

	local blueprints = {}
	for i = 1, LOOTLIST_SIZE do
		table.insert(blueprints, i % BLUEPRINT_INTERVAL == 0)
	end
	for i = 1, LOOTLIST_SIZE/BLUEPRINT_INTERVAL/2 do
		-- 1~5
		-- 1~20, 21~40, ...
		Shuffle(blueprints, 1+(i-1)*BLUEPRINT_INTERVAL*2, i*BLUEPRINT_INTERVAL*2)
	end
	-- 保证第一次出现在 < 5
	local i = 0
	repeat i = i + 1 until blueprints[i]
	local j = math.random(5)
	if i > j then
		blueprints = OffsetQueue(blueprints, i - j)
	end

	lootdropper:SetChanceLootTable("homura_box_loot_"..level)
	for i = 1, LOOTLIST_SIZE do
		local loot = {}
		for _,v in pairs(lootdropper:GenerateLoot())do
			local prefab, price = ParseAliasSafe(v)
			local num = math.ceil(GetMoney()/price)
			loot[prefab] = (loot[prefab] or 0) + num
		end

		loot["insertblueprint"] = blueprints[i]

		table.insert(_lootlist, loot)
	end

	-- DebugPrintLootList()
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:GetNextLoot(level)
	if _lootlist == nil or _index >= LOOTLIST_SIZE or _lootlistlevel ~= level then
		GenerateLootList(level)
	end

	_index = _index + 1
	return _lootlist[_index]
end

function self:DebugLoot(level)
	_lootlistlevel = -1
	self:GetNextLoot(level)
end

function self:RegisterWorkdesk2(ent)
	if ent and ent:IsValid() then
		_workdesks[ent] = true
	end
end

function self:CheckPlayerLearntBlueprint()
	local result = {}
	for _,name in ipairs({"homura_tower_2", "homura_tower_3"})do
		local name = name .. "_blueprint"
		for _,v in pairs(AllPlayers)do
			if not v.components.builder:KnowsRecipe(name) then
				result[name] = true
				break
			end
		end
	end
	return result
end

function self:CheckSketchInWorld()
	local result = {}
	for k in pairs(_workdesks)do
		if k:IsValid() and k.components.craftingstation then
			for _, prefab in ipairs(k.components.craftingstation:GetItems())do
				result[prefab] = true
			end
		end
	end

	return result
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	return {
		lootlist = _lootlist,
		lootlistlevel = _lootlistlevel,
		index = _index,
		seed = _seed,
		version = _lootversion,
	}
end

function self:OnLoad(data)
	if data and data.version == _lootversion then
		_lootlist = data.lootlist
		_lootlistlevel = data.lootlistlevel
		_index = data.index
		_seed = data.seed
	end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	return string.format("index: %d", _index)
end

end)