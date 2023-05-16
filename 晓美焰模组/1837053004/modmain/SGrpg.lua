local function AddExtraFx(inst, prefabname, offset, postfn) --offset传入格式(半径,高度,是否反向)
    local fx = SpawnPrefab(prefabname)
    local pos = inst:GetPosition()
    local angle = inst.Transform:GetRotation()*DEGREES
    local dir = offset.z < 0 and -1 or 1
    local radius = offset.x
    local height = offset.y

    offset = Vector3(math.cos(angle)*radius*dir, height, -math.sin(angle)*radius*dir)

    fx.Transform:SetRotation(inst.Transform:GetRotation())
    fx.Transform:SetPosition((offset+pos):Get())

    if postfn then
        postfn(inst, fx)
    end
end


local homura_rpg = State{
    name = "homura_rpg",
    tags = {"attack", "notalking", "abouttoattack", "autopredict"},
        
    onenter = function(inst)
    	local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        inst.components.combat:SetTarget(target)
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("homura_rpg")

        if target ~= nil and target:IsValid() then
            inst.components.combat:BattleCry()
            inst:FacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target
        end

        inst.sg.statemem.projectiledelay = (11 - 1)*FRAMES	
        inst.SoundEmitter:PlaySound('lw_homura/rpg/pre_3d', nil, nil, true) 
    end,

    timeline=
    {
    	TimeEvent(11*FRAMES, function(inst)
    		inst:PerformBufferedAction()
            inst.SoundEmitter:PlaySound("lw_homura/rpg/atk_3d",nil,nil,true)
    		inst.sg:RemoveStateTag("abouttoattack")

    		AddExtraFx(inst, 'homura_gun_light', Vector3(1,0,0))
    		AddExtraFx(inst, 'homura_rpg_smoke', Vector3(0.5,1,-1))
    	end),
    	TimeEvent(20*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
    	TimeEvent(21*FRAMES, function(inst) inst.sg:GoToState('idle') end),
    },


    onupdate = function(inst, dt)
    	if (inst.sg.statemem.projectiledelay or 0) > 0 then
    		inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
    		if inst.sg.statemem.projectiledelay <= 0 then
    			inst:PerformBufferedAction()
    			inst.sg:RemoveStateTag("abouttoattack")
    		end
    	end
    end,

    events=
    {
    	CommonEquip(),
    	CommonUnequip(),
    },

    onexit = function(inst)
	    inst.components.combat:SetTarget(nil)
	    if inst.sg:HasStateTag("abouttoattack") then
	    	inst.components.combat:CancelAttack()
	    end
	end,
}

AddStategraphState("wilson", homura_rpg)

local homura_rpg_client = State{
    name = "homura_rpg",
    tags = {"attack", "notalking", "abouttoattack"},
        
    onenter = function(inst)
    	local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()
            if buffaction.target ~= nil and buffaction.target:IsValid() then
                inst:FacePoint(buffaction.target:GetPosition())
                inst.sg.statemem.attacktarget = buffaction.target
            end
        end
        if inst.replica.combat then
        	inst.replica.combat:StartAttack()
        end
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("homura_rpg")

        if target ~= nil and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target
        end

        inst.sg.statemem.projectiledelay = (11 - 1)*FRAMES

        inst.SoundEmitter:PlaySound('lw_homura/rpg/pre_3d', nil, nil, true)	
    end,

    timeline=
    {
    	TimeEvent(11*FRAMES, function(inst)
    		inst:ClearBufferedAction()
    		inst.sg:RemoveStateTag("abouttoattack")
            inst.SoundEmitter:PlaySound("lw_homura/rpg/atk_3d",nil,nil,true)

    		--AddExtraFx(inst, 'homura_gun_light', Vector3(1,0,0))
    		AddExtraFx(inst, 'homura_rpg_smoke', Vector3(0.5,1,-1))
    	end),
    	TimeEvent(20*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
    	TimeEvent(21*FRAMES, function(inst) inst.sg:GoToState('idle') end),
    },


    onupdate = function(inst, dt)
    	if (inst.sg.statemem.projectiledelay or 0) > 0 then
    		inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
    		if inst.sg.statemem.projectiledelay <= 0 then
    			inst:ClearBufferedAction()
    			inst.sg:RemoveStateTag("abouttoattack")
    		end
    	end
    end,

    events = {
        CommonAnimQueueOver(),
    },

    onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
            inst.replica.combat:CancelAttack()
        end
    end,
}

AddStategraphState('wilson_client', homura_rpg_client)
