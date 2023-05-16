local Opener = Class(function(self, inst)
	self.inst = inst
	self.inst:DoPeriodicTask(0.1, function() self:OnUpdate() end)

	self.current = nil
end)

function Opener:OnUpdate()
	if self.current and not self.current:IsValid() then
		self.current = nil
	end

	local x,y,z = self.inst.Transform:GetWorldPosition()
	local box, mindist
	for _,v in ipairs(TheSim:FindEntities(x,0,z, 4, {"homura_box"}, {"INLIMBO", "FX"}))do
		if not v.dropping then
			local dist = v:GetDistanceSqToPoint(x,0,z)
			if dist < 8.9 then
				if mindist == nil or mindist > dist then
					mindist = dist
					box = v
				end
			end
		end
	end

	if self.current ~= box then
		-- close current
		if self.current and self.current.components.container then
			self.current.components.container:Close(self.inst)
		end

		-- open box
		self.current = box
		if self.current and self.current.components.container then
			self.current.components.container:Open(self.inst)
		end
	end
end

return Opener

