

local RechargeableWeapon = Class(function(self, inst)
    self.inst = inst
    self.cd = 0
    self.max = 30
    self.cdmod_add = {}
    self.cdmod_mult = {}
    self.redirect = true --依附于玩家

    self.inst:StartUpdatingComponent(self)
end)


function RechargeableWeapon:OnSave()
	return {cd = self.cd}
end

function RechargeableWeapon:OnLoad(data)
	if data and not self.redirect then
		self.cd = data.cd
	end
end

function RechargeableWeapon:GetLeft()
	return 
	self.cd,
	math.max(self.cd / self.max ,0)
end

function RechargeableWeapon:GetMod_Add()
	local r = 0
	for _,v in pairs(self.cdmod_add)do
		r = r + v
	end
	return r
end

function RechargeableWeapon:GetMod_Mult()
	local r = 1
	for _,v in pairs(self.cdmod_mult)do
		r = r*(v+1)
	end
	return r
end

function RechargeableWeapon:SetRedirectTarget(com)
	self.redirect_com = com
	self.redirect = true
	com.weapon_cd_com = self
end

function RechargeableWeapon:OnRemoveEntity()
	if self.redirect_com then
		self.redirect_com.weapon_cd_com = nil
	end
end

function RechargeableWeapon:OnUpdate(dt)
	if self.redirect_com then
		self.cd = self.redirect_com.weapon_cd
	end
end

return RechargeableWeapon
