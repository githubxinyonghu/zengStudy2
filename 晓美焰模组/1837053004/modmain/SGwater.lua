local water = function(ismastersim) return State{
    name = "homura_watergun",
    tags = {"attack", "notalking", "abouttoattack", "autopredict", "homura_watergun"},
        
    onenter = function(inst)
    	local action = inst:GetBufferedAction()
        local target = action and action.target
if ismastersim then
        inst.components.combat:SetTarget(target)
        inst.components.combat:StartAttack()
else
        if inst.replica.combat then
            inst.replica.combat:StartAttack()
        end
        inst:PerformPreviewBufferedAction()
end
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("homura_rpg")

        if target ~= nil and target:IsValid() then
            if inst.components.combat then
                inst.components.combat:BattleCry()
            end
            inst:FacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target
        end

        inst.SoundEmitter:PlaySound("lw_homura/watergun/shoot_pre", nil, .8, true)
    end,

    timeline=
    {
    	TimeEvent(11*FRAMES, function(inst)
if ismastersim then
    		inst:PerformBufferedAction()
else
            inst:ClearBufferedAction()
end
            inst.SoundEmitter:PlaySound("lw_homura/watergun/shoot", nil, .8, true)
    		inst.sg:RemoveStateTag("abouttoattack")

    	end),
    	TimeEvent(20*FRAMES, function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:RemoveStateTag("homura_watergun")
        end),
    	TimeEvent(21*FRAMES, function(inst)
            inst.sg:GoToState("idle")
        end),
    },

    events=
    {
    	CommonEquip(),
    	CommonUnequip(),
    },

    onexit = function(inst)
        local combat = inst.components.combat or inst.replica.combat
        if combat ~= nil then
            combat:SetTarget(nil)
    	    if inst.sg:HasStateTag("abouttoattack") then
    	       combat:CancelAttack()
    	    end
        end
	end,
}
end

AddStategraphState("wilson", water(true))
AddStategraphState("wilson_client", water(false))

