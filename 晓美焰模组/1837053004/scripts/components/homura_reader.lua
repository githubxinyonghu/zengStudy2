local function currentlearning(self, i)
	self.inst.replica.homura_reader:SetCurrentLearning(i)
end

local KEYS = {
	[1] = true,
	[2] = true,
	[3] = true
}

local Reader = Class(function(self, inst)
	self.inst = inst

	self.progress = {}
	for k in pairs(KEYS)do
		self.progress[k] = 0
	end

	self.currentlearning = 0

	self.time = 0

	inst:DoTaskInTime(.3, function()
		if inst:HasTag("homura") then
			for k in pairs(KEYS)do
				self.progress[k] = 99999
			end
		 end
		self:OnDirty()
	end)

end, nil, 
{
	currentlearning = currentlearning,
})

function Reader:GetMax(i)
	-- print("MAX", i, HOMURA_GLOBALS.LEARNING[i])
	return KEYS[i] and HOMURA_GLOBALS.LEARNING[i] or -1
end

function Reader:GetCurrent(i)
	return KEYS[i] and self.progress[i] or 0
end

function Reader:GetPercent(i)
	return self:GetCurrent(i) / self:GetMax(i)
end

function Reader:Learnt(i)
	return self:GetPercent(i) >= 0
end

function Reader:CanLearn(i)
	return KEYS[i] and not self:Learnt(i) and self.currentlearning == nil
end

function Reader:HasDependence(i)
	return self.inst.replica.homura_reader:HasDependence(i)
end

function Reader:StartLearning(i)
	if KEYS[i] then
		self.currentlearning = i
	end
	self.inst:StartUpdatingComponent(self)
end

function Reader:StopLearning()
	self.currentlearning = 0
	self.inst:StopUpdatingComponent(self)
end

Reader.StopReading = Reader.StopLearning

function Reader:CanRead(book)
	return self.inst.replica.homura_reader:CanRead(book)
end

function Reader:StartReading(book)
	local can, reason = self:CanRead(book)
	if can then
		self:StartLearning(book.level)
		return true
	else
		self:StopLearning()
		return false, reason
	end
end

function Reader:CanBuildCrossover(i)
	return i == 2
end

function Reader:OnDirty()
	for i = 1, 3 do
		if self:GetPercent(i) >= 1 then
			self.inst:AddTag("homuraTag_level"..i.."_builder")
			-- auto unlock crossover building
			if self:CanBuildCrossover(i) then
				self.inst:AddTag("homura_crossover_builder_"..(self.inst.prefab or ""))
			end
		else
			self.inst:RemoveTag("homuraTag_level"..i.."_builder")
			if self:CanBuildCrossover(i) then
				self.inst:RemoveTag("homura_crossover_builder_"..(self.inst.prefab or ""))
			end
		end
	end

	if self.inst.player_classified then
		self.inst.player_classified.homura_learning_1:set(self:GetPercent(1))
		self.inst.player_classified.homura_learning_2:set(self:GetPercent(2))
		self.inst.player_classified.homura_learning_3:set(self:GetPercent(3))
	end
end

-- function Reader:GetBonus()
-- 	if self.inst:HasTag("homura") then
-- 		return 3.0
-- 	else
-- 		return 1.0
-- 	end
-- end

function Reader:AnnounceFinish(delay)
	if delay ~= nil then
		self.inst:DoTaskInTime(delay, function() self:AnnounceFinish() end)
		return
	end

	if not self.inst.components.health:IsDead() and not self.inst:HasTag("mime") then
		self.inst.components.talker:Say(GetActionFailString(self.inst, "HOMURA_READ", "LEARNT"))
	end
end


function Reader:OnUpdate(dt)
	if self.currentlearning ~= nil then
		local old = self:GetPercent(self.currentlearning)
		self.progress[self.currentlearning] = self.progress[self.currentlearning] + dt --* self:GetBonus()
		if old < 1 and self:GetPercent(self.currentlearning) >= 1 then
			self.inst:PushEvent("homuraevt_finishlearning")
			self:AnnounceFinish(1)
		end
		self:OnDirty()
	end
end

function Reader:OnSave()
	return { progress = self.progress }
end

function Reader:OnLoad(data)
	if data and data.progress then
		for k,v in pairs(data.progress)do
			if self.progress[k] then
				self.progress[k] = v
			end
		end
	end
end

return Reader