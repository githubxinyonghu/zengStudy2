local function onalpha(self, p)
	self.inst.replica.homura_lightshocked:SetAlpha(p)
end

local LightShocked = Class(function(self, inst)
	self.inst = inst
	self.time = 0
	self.alpha = 0
end, 
nil, 
{
	alpha = onalpha,
})

local uptime = 1/10
local downtime = 2

function LightShocked:SetTime(time) --不传参时,表示未被闪光弹击中
	if time and time > 0 then
		-- SpawnPrefab('fake_target_player'):SetTarget(self.inst)

		self.inst.replica.homura_lightshocked:OnHit()
	else
		time = uptime
	end

	self.time = math.max(time, self.time)
	self.inst:StartUpdatingComponent(self)
end

function LightShocked:IsBlind()
	return self.alpha > 0
end

function LightShocked:OnUpdate(dt)
	self.time = self.time - dt
	self.alpha = self.alpha + (self.time > 0 and FRAMES/uptime or -FRAMES/downtime)
	self.alpha = math.clamp(self.alpha, 0, 1)

	if self.alpha == 0 and self.time < 0 then
		self.inst:StopUpdatingComponent(self)
	end
end

function LightShocked:GetDebugString()
	return string.format("TIME: %.1f, ALPHA: %.1f", self.time, self.alpha)
end

return LightShocked
