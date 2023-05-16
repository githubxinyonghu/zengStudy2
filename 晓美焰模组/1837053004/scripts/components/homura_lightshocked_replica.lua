local LightShocked = Class(function(self, inst)
    self.inst = inst

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function LightShocked:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

LightShocked.OnRemoveEntity = LightShocked.OnRemoveFromEntity

function LightShocked:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function LightShocked:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------


function LightShocked:SetAlpha(p)
    if self.classified then
        self.classified.homura_lightshock_alpha:set(p)
    end
end

function LightShocked:GetAlpha(p)
    if self.inst.components.homura_lightshocked then
        return self.inst.components.homura_lightshocked.alpha
    elseif self.classified then
        return self.classified.homura_lightshock_alpha:value()
    end
    return 0
end

function LightShocked:IsBlind()
    return self:GetAlpha() > 0
end

function LightShocked:OnHit()
    if self.classified then
        self.classified.homura_lightshock_hit:push()
    end
end

return LightShocked
