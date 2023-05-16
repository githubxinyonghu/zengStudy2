table.insert(PrefabFiles, "homura_bow")
table.insert(PrefabFiles, "homura_bow_fire")
table.insert(PrefabFiles, "homura_bow_light")

local function ComponentPostInit(inst)
	if inst.components.locomotor ~= nil and inst.components.locomotor.homura_bow_hook == nil then
		inst.components.locomotor.homura_bow_hook = true

		local old_run = inst.components.locomotor.RunForward
		function inst.components.locomotor:RunForward(direct, ...)
			old_run(self, direct, ...)
			if self.inst:IsValid() and self.inst.sg ~= nil and self.inst.sg:HasStateTag("homura_bow") then
				local rotation = self.inst.Transform:GetRotation()
				local speed = self.inst.Physics:GetMotorVel()
				local direction = self.homura_run_direction
				if direction ~= nil then
					-- `direction` is where player is moving to
					-- `rotation` is where player is facing
					local a = (rotation - direction)* DEGREES
					local x, z = math.cos(a)*speed, math.sin(a)*speed
					self.inst.Physics:SetMotorVel(x, 0, z)

					if self.inst.sg then
						self.inst.sg.mem.homura_bow_reverse = x < 0
					end
				end
			end
		end

		local old_run_in_dir = inst.components.locomotor.RunInDirection
		function inst.components.locomotor:RunInDirection(direction, throttle, ...)
			self.homura_run_direction = direction
			return old_run_in_dir(self, direction, throttle, ...)
		end
	end
end

local function ChangeRun(inst)
	inst:DoTaskInTime(0, ComponentPostInit)
end

AddPlayerPostInit(function(inst)
	inst:AddComponent("homura_bowblast")

	ChangeRun(inst)
	inst:ListenForEvent("enablemovementprediction", ChangeRun)
end)
