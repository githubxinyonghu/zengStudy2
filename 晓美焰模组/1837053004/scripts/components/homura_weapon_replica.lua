local HomuraWeapon = Class(function(self, inst)
	self.inst = inst

	self.ammo_percent = net_byte(inst.GUID, "homuranet_ammo_percent", "homuranet_ammo_percent")
end)

function HomuraWeapon:OnPercent(p)
	if not self.inst:HasTag("homuraTag_no_ammo") then
		self.ammo_percent:set(math.clamp(math.floor(p*100+0.5), 0, 100))
	end
end

function HomuraWeapon:GetPercent()
	if self.inst.components.homura_weapon then
		return self.inst.components.homura_weapon:GetPercent()
	end
	
	local value = self.ammo_percent:value()
	if value ~= 255 then
		return value / 100
	else
		return 1
	end
end

return HomuraWeapon