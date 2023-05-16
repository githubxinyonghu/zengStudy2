local attack = State{
    name = "homura_stickbang",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },

    onenter = function(inst)
        if inst.components.combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        inst.components.combat:SetTarget(target)
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        
        inst.sg:SetTimeout(30*FRAMES)

        inst.AnimState:PlayAnimation("spearjab")

        if target ~= nil then
            inst.components.combat:BattleCry()
            if target:IsValid() then
                inst:FacePoint(target:GetPosition())
                inst.sg.statemem.attacktarget = target
            end
        end
    end,

    timeline =
    {
        TimeEvent(13*FRAMES, function(inst)
        	local weapon = inst.components.combat:GetWeapon()
        	if weapon and weapon.prefab == "homura_stickbang" then
                if TheWorld.components.homura_time_manager:IsEntityInRange(inst) then
                    weapon.components.weapon:SetDamage(17)
                    inst:PerformBufferedAction()
                    weapon.components.weapon:SetDamage(HOMURA_GLOBALS.STICKBANG.damage)
                else
                    inst:ClearBufferedAction()
                    weapon:TryAttack(inst)
                end
            end
            inst.sg:RemoveStateTag("abouttoattack")
        end),
    },

    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
}

AddStategraphState("wilson", attack)

local attack_client = State{
    name = "homura_stickbang",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },

    onenter = function(inst)
        if inst.replica.combat and inst.replica.combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        -- inst.components.combat:SetTarget(target)
        if inst.replica.combat then
            inst.replica.combat:StartAttack()
        end
        inst.components.locomotor:Stop()
        
        inst.sg:SetTimeout(30*FRAMES)

        inst.AnimState:PlayAnimation("spearjab")

        if target ~= nil and target:IsValid() then
            inst:FacePoint(target:GetPosition())
            inst:PerformPreviewBufferedAction()
            inst.sg.statemem.attacktarget = target
        end
    end,

    timeline =
    {
        TimeEvent(13*FRAMES, function(inst)
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")           
        end),
    },

    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        if inst.replica.combat then
            inst.replica.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.replica.combat:CancelAttack()
            end
        end
    end,
}

AddStategraphState("wilson_client", attack_client)

local hit = State{
    name = "homura_stickbang_hit",
    tags = { "busy", "nopredict", "nomorph", "nodangle", "homura_stickbang_hit" },

    onenter = function(inst, data)
        -- ClearStatusAilments(inst)
        -- ForceStopHeavyLifting(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        inst.AnimState:PlayAnimation("bucked")
        -- inst.AnimState:PlayAnimation("hit_spike_heavy")
        local strength = HOMURA_GLOBALS.STICKBANG.knockback
        local rot = inst.Transform:GetRotation()
        inst.sg.statemem.speed = strength * 4
        inst.sg.statemem.dspeed = 0
        inst.Transform:SetRotation(rot + 180) --?
        inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
          
    end,

    onupdate = function(inst)
        inst.sg.statemem.speed = inst.sg.statemem.speed - inst.sg.statemem.dspeed
        if inst.sg.statemem.speed > 0 then
            inst.sg.statemem.dspeed = inst.sg.statemem.dspeed + .07
            inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
        else
            inst.sg.statemem.speed = nil
            inst.sg.statemem.dspeed = nil
            inst.Physics:Stop()
        end
    end,

    timeline =
    {
        TimeEvent(8 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("knockback_pst")
                -- inst.sg:GoToState("idle", true)
            end
        end),
    },

    onexit = function(inst)
        if inst.sg.statemem.speed ~= nil then
            inst.Physics:Stop()
        end
    end,
}

AddStategraphState("wilson", hit)

AddStategraphEvent("wilson", EventHandler("homuraevt_stickbang_hit", function(inst, data)
	if data and data.pos then
		-- 在推送事件前已经检查了生命值>0，所以此处不做检查
		inst.sg:GoToState("homura_stickbang_hit", data)
	end
end))

