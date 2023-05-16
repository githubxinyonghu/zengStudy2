local Learner = Class(function(self, inst)
	self.inst = inst

	if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)


--------------------------------------------------------------------------

function Learner:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Learner.OnRemoveEntity = Learner.OnRemoveFromEntity

function Learner:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Learner:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------

local KEYS = {
	[1] = true,
	[2] = true,
	[3] = true,
}

function Learner:GetPercent(i)
	if not KEYS[i] then
		return 0
	end

	if self.inst.components.homura_reader then
		return self.inst.components.homura_reader:GetPercent(i)
	elseif self.classified ~= nil then
		return self.classified["homura_learning_"..i]:value()
	else
		return 0
	end
end

function Learner:Learnt(i)
	if not KEYS[i] then
		return false
	end

	return self:GetPercent(i) >= 1
end

function Learner:CanLearn(i)
	if not KEYS[i] then
		return false
	end

	return self:GetPercent(i) < 1 and self:GetCurrentLearning() == 0
end

function Learner:HasDependence(i)
	if i == 1 then
		return true
	elseif i == 2 or i == 3 then
		return self:Learnt(1)
	else
		return true
	end
end

function Learner:CanRead(book)
	if book ~= nil and string.find(book.prefab or "", "homura_book_") and book.level ~= nil then
		if self:Learnt(book.level) then
			return false, "LEARNT"
		elseif not self:HasDependence(book.level) then
			return false, "DEPEND"
		elseif self:CanLearn(book.level) then
			return true
		end
	end
	return false
end

function Learner:SetCurrentLearning(i)
	if self.classified then
		self.classified.homura_currentlearning:set_local(0)
		self.classified.homura_currentlearning:set(i or 0)
	end
end

function Learner:GetCurrentLearning()
	if self.inst.components.homura_reader then
		return self.inst.components.homura_reader.currentlearning
	elseif self.classified ~= nil then
		return self.classified.homura_currentlearning:value()
	else
		return 0
	end
end

return Learner