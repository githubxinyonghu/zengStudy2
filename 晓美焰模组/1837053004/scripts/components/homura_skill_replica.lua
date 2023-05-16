local Skill = Class(function(self, inst)
    self.inst = inst

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    self.iscenter = net_bool(inst.GUID, "homura_skill.iscenter", "homura_skill.iscenter")
    self.inst:ListenForEvent("homura_skill.iscenter", function()
        self:OnCenter()
    end)
    self.inst:ListenForEvent("onremove", function(inst)
        TheWorld.components.homura_time_manager:RemoveTimeMagicCenter(inst)
    end)
end)

--------------------------------------------------------------------------

function Skill:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Skill.OnRemoveEntity = Skill.OnRemoveFromEntity

function Skill:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Skill:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------


function Skill:SetLeftTime(p)
    if self.classified then
        self.classified.homura_skill_lefttime:set(p)
    end
end

function Skill:SetLeftCD(p)
    if self.classified then
        self.classified.homura_skill_cooldown:set(p)
    end
end

local fns = {
    [1] = 'OnTry', 
    [2] = 'ShowCD',
    [3] = 'OnAttacked',
    [4] = 'OnStart',
    [5] = 'OnCoolDown',
    [6] = 'OnEnd',
}

function Skill:PushBadgeFn(i)
    if fns[i] then 
        self.inst:PushEvent("homuraUI_callfn", {fn = fns[i]})
        if TheWorld.ismastersim and self.classified then
            self.classified.homura_badge_fn:set_local(i)
            self.classified.homura_badge_fn:set(i)
        end
    end
end

function Skill:GetLeftTime()
    if self.inst.components.homura_skill then
        return self.inst.components.homura_skill.left_time
    elseif self.classified then
        return self.classified.homura_skill_lefttime:value()
    end
    return 0
end

function Skill:GetLeftCD()
    if self.inst.components.homura_skill then
        return self.inst.components.homura_skill.left_cd
    elseif self.classified then
        return self.classified.homura_skill_cooldown:value()
    end
    return 0
end

function Skill:SetIsMagicCenter(val)
    if val and TheWorld.ismastersim and self.inst == ThePlayer then
        self.inst.components.homura_timepauseblast:Blast(.5, .5)
    end
    self.iscenter:set_local(val)
    self.iscenter:set(val)
end

function Skill:GetIsMagicCenter(val)
    return self.iscenter:value()
end

function Skill:OnCenter()
    if self:GetIsMagicCenter() then
        if not TheWorld.ismastersim and self.inst == ThePlayer then 
            self.inst.components.homura_timepauseblast:Blast(.5, .5)
        end
        TheWorld.components.homura_time_manager:AddTimeMagicCenter(self.inst)
    else
        TheWorld.components.homura_time_manager:RemoveTimeMagicCenter(self.inst)
    end
end

return Skill
