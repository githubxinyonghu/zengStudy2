-- aiming: 玩家举起弓瞄准的状态
--   * 移速重定向
--   * 减速
--   * 面朝鼠标
-- charging: 玩家使用弓蓄力的状态
--   * curent+
--   * updating bar

local BOW = HOMURA_GLOBALS.BOW

local function IsRiding(inst)
	return inst.components.rider and inst.components.rider:IsRiding()
end

local function oncurrent(self, value)
	self.inst.replica.homura_archer:SetPercent(self:GetPercent())
end

local function onaiming(self, value)
	if value then
		self.inst:AddTag("homuraTag_bow_aiming")
		self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "homura_archer", HOMURA_GLOBALS.BOW.speedmult[IsRiding(self.inst) and 2 or 1])
	else
		self.inst:RemoveTag("homuraTag_bow_aiming")
		self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "homura_archer")
	end
end

local Archer = Class(function(self, inst)
	self.inst = inst

	self.max = 1
	self.current = 0
	self.aiming = false
	self.charging = false

	self.electric_symbol_id = 0
end, nil, 
{
	current = oncurrent,
	aiming = onaiming,
})

function Archer:GetMax()
	if self.inst:HasTag("homura") then
		return BOW.chargetime.homura
	else
		return BOW.chargetime.generic
	end
end

function Archer:GetCurrent()
	return self.current
end

function Archer:GetPercent()
	return self.current / self.max
end

function Archer:GetSpecialCharged()
	return self.specialcharged
end

function Archer:TryCharging()
	-- local weapon = self.inst.components.combat:GetWeapon()
	local weapon = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if weapon and weapon:HasTag("homura_bow") then
		if not self.charging then
			self:StartCharging()			
		end
		return true
	end
end

function Archer:StartCharging()
	self.max = self:GetMax()
	self.current = 0
	self.charging = true

	if self.inst:HasTag("homura") then
		self:AttachChargeFx():Start()
		self:AttachFire():Clear()
	end

	self.inst:StartUpdatingComponent(self)
end

function Archer:Reset()
	self.current = 0
	self.aiming = false
	self.charging = false
	self.specialcharged = false

	self:AttachFire():Stop()
	self:AttachChargeFx():Stop()
	self:AttachLight().Light:Enable(false)

	self.inst.AnimState:ClearOverrideSymbol("homura_arrow_override")

	self.inst:StopUpdatingComponent(self)
end

function Archer:StartAiming()
	self.aiming = true
	self.inst:StartUpdatingComponent(self)
end

function Archer:Launch()
	local weapon = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if weapon and weapon:HasTag("homura_bow") then
		weapon:Launch(self.inst, self.current, self:GetSpecialCharged())
		if self:GetSpecialCharged() then
			self.inst.homura_bowblast:push()
		end
	end
	self.inst.AnimState:OverrideSymbol("swap_object", "homura_bow_anim", "swap_object")
	self.current = 0
	self.charging = false
	self.specialcharged = false
	self:AttachFire():Stop()
end

local function Attach(inst, fx, symbol, y)
	fx.entity:SetParent(inst.entity)
	fx.entity:AddFollower():FollowSymbol(inst.GUID, symbol, 0, y or 0, 0)
end

function Archer:AttachFire()
	if self.fire ~= nil and self.fire:IsValid() then
		return self.fire
	end
	self.fire = SpawnPrefab("homura_bow_fire")
	Attach(self.inst, self.fire, "homura_bow_fire", -20)
	return self.fire
end

function Archer:AttachChargeFx()
	if self.chargefx ~= nil and self.chargefx:IsValid() then
		return self.chargefx
	end
	self.chargefx = SpawnPrefab("homura_bow_charge_fx")
	Attach(self.inst, self.chargefx, "homura_arrow_fx")
	return self.chargefx
end

function Archer:AttachLight()
	if self.light ~= nil and self.light:IsValid() then
		return self.light
	end
	self.light = SpawnPrefab("homura_bow_light")
	Attach(self.inst, self.light, "homura_bow_fire")
	return self.light
end

function Archer:OnUpdate(dt)
	if self.aiming then
		if not self.inst.components.homura_clientkey:IsPressing("raction") then
			self.inst:PushEvent("homura_bow_launch")
		end
	end

	if self.current < self.max then
		self.current = self.current + dt
		if self.current >= self.max then
			self.current = self.max
			self.inst:PushEvent("homura_bow_fullcharge")

			local fx = SpawnPrefab("homura_bow_shine_fx")
			fx.entity:AddFollower()
			fx.Follower:FollowSymbol(self.inst.GUID, "homura_arrow_fx", 0, 0, 0)

			if self.inst:HasTag("homura") then
				self.specialcharged = true
				self.inst.SoundEmitter:PlaySound("lw_homura/bow/charge_done")
				self:AttachFire():Burst()
				self:AttachChargeFx():Stable()
				self:AttachLight().Light:Enable(true)
				-- self.inst.AnimState:SetSymbolExchange("swap_object", "swap_object_magic")
				self.inst.AnimState:OverrideSymbol("swap_object", "homura_bow_anim", "swap_object_magic")
			end
		end
	end

	if self.specialcharged then
		local i = self.electric_symbol_id
		self.inst.AnimState:OverrideSymbol("homura_arrow_override", "homura_bow_electric_fx", "symbol"..i)
		self.electric_symbol_id = self.electric_symbol_id == 30 and 0 or self.electric_symbol_id + 1
	end
end

function Archer:GetDebugString()
	return string.format("aiming: %s charging: %s (%.1f/%.1f)", 
		tostring(self.aiming),
		tostring(self.charging),
		self.current, self.max)
end

return Archer