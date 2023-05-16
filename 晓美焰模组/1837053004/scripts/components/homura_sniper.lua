local function onsniping(self, val)
	if self.inst.player_classified then
		self.inst.player_classified.homura_snipemode:set(val)
	end

	if val then
		self.inst:AddTag("homuraTag_issniping")
	else
		self.inst:RemoveTag("homuraTag_issniping")
	end
end

local Sniper = Class(function(self, inst)
	self.inst = inst
	self.sniping = false
	self.cooldown = 0
end, nil,
{
	sniping = onsniping
})

function Sniper:StartSniping()
	self.sniping = true
end

function Sniper:StopSniping()
	self.sniping = false
end

function Sniper:IsSniping()
	return self.sniping
end

function Sniper:OnShoot()
	if self.inst.player_classified then
		self.inst.player_classified.homura_snipeshoot:push()
	end
end

function Sniper:EnterCooldown()
	self.cooldown = 0.75
	self.inst:AddTag("homuraTag_snipeCD")
	self.inst:StartUpdatingComponent(self)
end

function Sniper:IsReady()
	return self.cooldown <= 0
end

function Sniper:OnUpdate(dt)
	if self.cooldown > 0 then
		self.cooldown = self.cooldown - dt 
		if self.cooldown <= 0 then
			self.inst:RemoveTag("homuraTag_snipeCD")
		end
	end
end

function Sniper:CheckCooldownAndEnter()
	if self:IsReady() then
		self:EnterCooldown()
		return true
	else
		return false
	end
end

return Sniper