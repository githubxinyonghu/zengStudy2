local Archer = Class(function(self, inst)
	self.inst = inst
	self.aimingdir = Vector3(1,0,0)

	if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)


--------------------------------------------------------------------------

function Archer:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Archer.OnRemoveEntity = Archer.OnRemoveFromEntity

function Archer:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Archer:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

-------------------------------------------------------------------------

function Archer:SetPercent(i)
	if i > 0 then
		self.inst:AddTag("homuraTag_bow_charging")
	else
		self.inst:RemoveTag("homuraTag_bow_charging")
	end

	if self.classified then
		self.classified.homura_archer_charge:set(math.clamp(i, 0, 1))
	end
end

function Archer:GetPercent()
	if self.inst.components.homura_archer then
		return self.inst.components.homura_archer:GetPercent()
	elseif self.classified then
		return self.classified.homura_archer_charge:value()
	else
		return 0
	end
end

function Archer:StartAiming()
	self.aiming = true
	if self.inst.components.homura_archer then
		return self.inst.components.homura_archer:StartAiming()
	end
	self.inst:StartUpdatingComponent(self)
end

function Archer:Reset()
	self.aiming = false
	if self.inst.components.homura_archer then
		return self.inst.components.homura_archer:Reset()
	end
	self.inst:StopUpdatingComponent(self)
end

-- support for joystick aiming
local function GetWorldControllerVector()
    local xdir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_LEFT)
    local ydir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_UP) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_DOWN)
    local deadzone = .3
    if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
        local dir = TheCamera:GetRightVec() * xdir - TheCamera:GetDownVec() * ydir
        return dir:GetNormalized()
    end
end

function Archer:OnUpdate()
	local dir = GetWorldControllerVector()
	if dir ~= nil then
		self.aimingdir = dir
	end

	if self.inst.sg and self.inst.sg:HasStateTag("homura_bow") then
		if not self.inst.components.homura_clientkey:IsPressing("raction") then
			self.inst:PushEvent("homura_bow_launch_client")
		end
	end
end

return Archer
