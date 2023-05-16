local EVENT = "homura_snowpea_puff.breathevent"

local FrostyBreather = Class(function(self, inst)
    self.inst = inst
    self.breath = nil
    self.offset = Vector3(0, 0, 0)
    self.offset_fn = nil
    self.enabled = true

    self.breathevent = net_event(inst.GUID, EVENT)

    self:WatchWorldState("temperature", self.OnTemperatureChanged)
    self:OnTemperatureChanged(TheWorld.state.temperature)

    if not TheWorld.ismastersim then
        inst:ListenForEvent(EVENT, self.EmitOnce)
    end
        
    inst:DoTaskInTime(0, function() self:StartBreath() end)
end)

function FrostyBreather:OnRemoveFromEntity()
    self:StopWatchingWorldState("temperature", self.OnTemperatureChanged)
    self:StopBreath()
end

function FrostyBreather:OnShoot()
    if self.enabled and TheWorld.ismastersim then
        self:EmitOnce()
        self.breathevent:push()
    end
end

function FrostyBreather:StartBreath()
    if self.breath == nil then
        self.breath = SpawnPrefab("frostbreath")
        self.inst:AddChild(self.breath)
        self.breath.Transform:SetPosition(self:GetOffset())
    end
end

function FrostyBreather:StopBreath()
    if self.breath ~= nil then
        self.inst:RemoveChild(self.breath)
        self.breath:Remove()
        self.breath = nil
    end
end

function FrostyBreather:OnTemperatureChanged(temperature)
    self.enabled = temperature > TUNING.FROSTY_BREATH
end

function FrostyBreather:EmitOnce()
    if self.breath ~= nil then
        self.breath.Transform:SetPosition(self:GetOffset())
        self.breath:Emit()
    end
end

function FrostyBreather:SetOffset(x, y, z)
    self.offset.x, self.offset.y, self.offset.z = x, y, z
end

function FrostyBreather:SetOffsetFn(fn)
    self.offset_fn = fn
end

function FrostyBreather:GetOffset()
    local offset = self.offset_fn ~= nil and self.offset_fn(self.inst) or self.offset
    return offset:Get()
end

return FrostyBreather
