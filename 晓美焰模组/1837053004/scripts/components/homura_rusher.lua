local Rusher = Class(function(self, inst)
	self.inst = inst

	self.time = 0
	self.run = false
	self.rush = false

	self:Stop()

	inst:ListenForEvent("newstate", function(_, data)
		local name = data and data.statename
		if name == "run_pre" or name == "run" then
			self:OnRun()
		end
	end)

	inst:ListenForEvent("unequip", function()
		self:Stop() -- 即使装备刺雷也执行Stop
	end)
end)

function Rusher:OnRun()
	if self.inst.components.rider:IsRiding() then
		self:Stop()
		return
	end
	if not self.inst.sg:HasStateTag("running") then
		self:Stop()
		return
	end

	local weapon = self.inst.components.combat:GetWeapon()
	if weapon and weapon.prefab == "homura_stickbang" then
		if not self.run then
			self:StartRunning()
		end
	else
		self:Stop()
	end
end

function Rusher:Stop()
	self.time = 0
	self.run = false
	self.rush = false
	self.inst:RemoveTag("homuraTag_rush")
	-- self.inst:StopUpdatingComponent(self)
	if self.inst.components.locomotor then
		self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "homura_rusher")
	end
end

function Rusher:StartRunning()
	self.time = 0
	self.run = true
	self.rush = false
	self.inst:StartUpdatingComponent(self)
end

function Rusher:StartRushing()
	self.time = 0
	self.rush = true
	self.inst:AddTag("homuraTag_rush")
end

local T = HOMURA_GLOBALS.STICKBANG

function Rusher:OnUpdate(dt)
	if self.inst.components.rider:IsRiding() then
		self:Stop()
		return
	end
	-- 这里有个bug我还没搞明白，为什么人跑着跑着就run_stop了呢...
	if not self.inst.sg:HasStateTag("running") then
		if self.inst.sg.currentstate.name ~= "run_stop" then
			self:Stop()
			return
		end
	end

	self.time = self.time + dt
	if self.run then
		if not self.rush then
			if self.time > T.rush_readytime then
				self:StartRushing()
			end
		else
			self:CheckCollideAndAttack()
			local locomotor = self.inst.components.locomotor
			if locomotor == nil then
				return
			end

			local mult = 1
			if self.time < 1 then
				mult = mult + self.time * T.rush_speedbonus
			else
				mult = mult + T.rush_speedbonus
				-- 这里理论上可以stopupdating，但是没必要这么严格去做优化
			end

			if self.time > 0.5 and self.time < 0.5 + 1.5*FRAMES then
				-- self.inst.components.combat.nextbattlecrytime = nil
				self.inst.components.combat:BattleCry()
			end
			locomotor:SetExternalSpeedMultiplier(self.inst, "homura_rusher", mult)
		end
	end
end

function Rusher:CheckCollideAndAttack()
	local weapon = self.inst.components.combat:GetWeapon()
	if weapon and weapon.prefab == "homura_stickbang" then
		weapon:TryAttack(self.inst, true)
	end
end

function Rusher:GetDebugString()
	return string.format("run: %s rush: %s time: %.1f", tostring(self.run), tostring(self.rush), self.time)
end


return Rusher
