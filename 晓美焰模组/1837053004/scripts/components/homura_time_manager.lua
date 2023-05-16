-- 2020.10.10 优化时停代码

----------------------------------
-- homuraTag_ignoretimemagic是完全免疫时停的标签，会阻止实体被搜索到，不要添加给玩家！
-- lw_timemagic_affected 变量代表一个实体被暂停
-- homuraTag_pause 标签代表实体在主机被暂停
------------------------------------

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")
local util = require("homura/time_util")

--------------------------------------------------------------------------
--[[ Class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local RADIUS = HOMURA_GLOBALS.RADIUS
local NOTAGS = {"INLIMBO", "homuraTag_ignoretimemagic"}


--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------
local _players = {}
local _ents = {}    -- 进入范围的 被控制 实体  （动画 物理 刷新逻辑）
local _centers = {} -- 圆心列表
local _search_local = not TheNet:IsDedicated() -- 是否搜索本地实例
local _disabled = false -- 是否被禁用

local ismastersim = TheWorld.ismastersim
local isclient = not ismastersim

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- local function debugprint( ... ) print(...) end
-- local function debugprint() end

local tu_Start = util.Start 
local tu_Stop = util.Stop
local tu_Update = util.Update
local tu_IsImmune = util.IsImmune

local IsClientReplica
if ismastersim then
	IsClientReplica = function() return false end
else
	IsClientReplica = function(inst)
		-- 客机副本，不操作userdata
		if inst.Network ~= nil then
			if inst:HasTag("player") and inst.components.locomotor ~= nil then
				return false
			end
			return true
		end
	end
end

local function ItemTimeMagicStart(inst)
	-- print('添加', inst)
	tu_Start(inst, IsClientReplica(inst))
	inst.lw_timemagic_affected = true
end

local function ItemTimeMagicStop(inst)
	-- print('移除', inst)
	tu_Stop(inst, IsClientReplica(inst))
	inst.lw_timemagic_affected = false
end

local function ItemTimeMagicUpdate(inst, dt)
	tu_Update(inst, dt)
end

local function PlayerMagicStart(inst)
	--print('玩家进入范围', inst)
	inst.lw_timemagic_inrange = true
	inst:PushEvent("homura_enter_timemagic")
end

local function PlayerMagicStop(inst)
	--print('玩家走出范围', inst)
	inst.lw_timemagic_inrange = false
	inst:PushEvent("homura_exit_timemagic")
end

local function RemoveItem(k)
	_ents[k] = nil
	ItemTimeMagicStop(k)
end

local function AddItem(k)
	_ents[k] = 2
	ItemTimeMagicStart(k)
end


local function AddPlayer(player)
	_players[player] = 2
	PlayerMagicStart(player)
end

local function RemovePlayer(player)
	_players[player] = nil
	PlayerMagicStop(player)
end

local function MakeSfx(volume)
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("homuraTag_ignoretimemagic")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst:DoTaskInTime(0, function(inst) inst.SoundEmitter:PlaySound("lw_homura/timemagic/start_3d", nil, volume) end)
    inst:DoTaskInTime(5, function(inst) inst:Remove() end)
    
    return inst
end

local function Inform(homura)
	local center = homura:GetPosition()
	local sx, sy = TheSim:GetScreenPos(center:Get())
	local sw, sh = TheSim:GetScreenSize()

	if ThePlayer ~= nil and ThePlayer ~= homura then 
		-- sfx
		local pos = ThePlayer:GetPosition()
		local offset = center - pos 
		local len = offset:Length()

		local volume = Remap(math.clamp(len, 10, 40), 10, 40, 0.15, 0.05)
		if len < 4 then
			MakeSfx(volume).Transform:SetPosition(pos:Get())
		elseif len < RADIUS then
			offset = offset:GetNormalized() * 10
			MakeSfx(volume).Transform:SetPosition((pos+offset):Get())
		end

		-- 2021.5.13 blast 
		if sx > -0.2*sw and sx < 1.2*sw and sy > -0/2*sh and sy < 1.2*sh then
			ThePlayer.components.homura_timepauseblast:Blast(sx/sw, sy/sh)
		end
	end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------


--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------


function self:AddTimeMagicCenter(player)
	if _disabled then
		return
	end
	
	_centers[player] = true
	inst:StartUpdatingComponent(self)
	Inform(player)
end

function self:RemoveTimeMagicCenter(player)
	_centers[player] = nil 
end

function self:OnUpdate(dt)
	-- self-check
	for k in pairs(_ents)do
		if tu_IsImmune(k) then
			RemoveItem(k)
		end
	end

	-- Add new ents / players
	local gethomura = false
	for player in pairs(_centers)do
		gethomura = true
		local x,y,z = player:GetPosition():Get()
		for _, k in ipairs(TheSim:FindEntities(x,0,z, RADIUS, nil, NOTAGS))do
			if not tu_IsImmune(k) and (k.Network ~= nil or _search_local) then 
				if not _ents[k] then
					AddItem(k)
				else
					_ents[k] = 2
				end
			end

			if k:HasTag("player") then
				if not _players[k] then 
					AddPlayer(k)
				else
					_players[k] = 2
				end
			end
		end
	end

	-- filter 1
	for k,v in pairs(_ents)do
		if v == 1 then 
			RemoveItem(k)
		end
		if v == 2 then 
			_ents[k] = 1
			ItemTimeMagicUpdate(k, dt)
		end
	end
	for k,v in pairs(_players)do
		if v == 1 then 
			RemovePlayer(k)
		end
		if v == 2 then 
			_players[k] = 1
		end
	end

	if not gethomura then 
		--print('HomuraTime:StopUpdating')
		inst:StopUpdatingComponent(self)
	end
end

function self:IsEntityInRange(ent)
	if ent and ent:IsValid() and ent.Transform then
		for k in pairs(_centers)do
			if k:GetDistanceSqToInst(ent) <= RADIUS * RADIUS then
				return true
			end
		end
	end
end

function self:Disable()
	_disabled = true
end

end)
