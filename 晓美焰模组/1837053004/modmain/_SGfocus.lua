assert(false, "This module is deprecated.")









---主机 瞄准sg，结束后进入loop
local homura_focus = State{
    name = 'homura_focus',
    tags = {"notalking", "attack", "abouttoattack", "homura_focus"},

    onenter = function(inst,p)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        local weapon = inst.components.combat:GetWeapon()
        inst.components.locomotor:Stop()

        if target and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end

        inst.sg.statemem.target = target
        inst.sg.statemem.attacktarget = target
        inst.sg.statemem.weapon = weapon

        if weapon then
            weapon:PushEvent('homura.StartFocus', {target = target})
            if weapon.prefab == 'homura_pistol' then
                inst.AnimState:PlayAnimation('hand_shoot')
                inst.SoundEmitter:PlaySound('lw_homura/sfx/load_up_3d',nil,0.7,true)
            else
                inst.AnimState:PlayAnimation('homura_gun_pre')
                inst.SoundEmitter:PlaySound('lw_homura/sfx/load_down_3d',nil,0.7,true)
            end
        end

        inst:PushEvent('homura.StartFocus',{target = target})
        inst._uifocus_state:set(1)
        --print('sg push event')

        inst.sg:SetTimeout(3.1)
    end,

    timeline = {
        --和抬枪前摇播放相同的动画, 但在结束时暂停或loop
        TimeEvent(11*FRAMES,function(inst)
            if inst.sg.statemem.weapon and inst.sg.statemem.weapon.prefab == 'homura_pistol' then
                inst.AnimState:Pause() --极致偷懒...
            end
        end),
        TimeEvent(12*FRAMES,function(inst)
            if inst.sg.statemem.weapon and inst.sg.statemem.weapon.prefab ~= 'homura_pistol' then
                inst.AnimState:PlayAnimation('homura_gun_focus',true)
            end
        end),
    },

    onupdate = function(inst)
        local target = inst.sg.statemem.target
        local actiontarget = inst:GetBufferedAction() and inst:GetBufferedAction().target
        if target == actiontarget then --攻击目标与锁定目标相同
            ---
        elseif actiontarget then
            inst.sg.statemem.changetarget = true --由于切换目标而重新进入state
            inst.sg:GoToState('homura_focus', 'fromfocus')
        end

        if target and target:IsValid() and not target:HasTag("INLIMBO")and not target.components.health:IsDead()then
            inst:FacePoint(target:GetPosition():Get())
        else
            --inst.sg.statemem.weapon:PushEvent('homura.AbruptFocus')
            inst.sg:GoToState('idle')--@--
        end
    end,

    ontimeout = function(inst)
        inst.sg.statemem.down = true
        local weapon = inst.sg.statemem.weapon
        if weapon and weapon.prefab == 'homura_pistol' then
            inst.sg:GoToState('homura_pistol_atk')
        elseif weapon and weapon.prefab == 'homura_gun' then
            inst.sg:GoToState('homura_gun_atk')
        elseif weapon and weapon.prefab == 'homura_hmg' then
            inst.sg:GoToState('homura_hmg_atk')
        end
    end,

    events = 
    {
        CommonEquip(),
        CommonUnequip(),
    },    

    onexit = function(inst)
        if inst.sg.statemem.down then
            inst.sg.statemem.weapon:PushEvent('homura.FinishFocus')
            inst:PushEvent('homura.FinishFocus')
            inst._uifocus_state:set(3)
            print('focus down')
        else
            inst.sg.statemem.weapon:PushEvent('homura.AbruptFocus')
            inst:PushEvent('homura.AbruptFocus')
            inst._uifocus_state:set(2)
            if inst.sg.statemem.changetarget then
                print('change target')
            else
                print('focus abrupt')
            end
        end
        inst.AnimState:Resume()
    end,
}

AddStategraphState("wilson", homura_focus)


---客机 瞄准
local homura_focus_client = State{
    name = 'homura_focus',
    tags = {"notalking", "attack", "abouttoattack", "homura_focus"},

    onenter = function(inst,p)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst.components.locomotor:Stop()

        if target and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end

        inst.sg.statemem.target = target
        inst.sg.statemem.attacktarget = target
        inst.sg.statemem.weapon = weapon

        if weapon then
            if weapon.prefab == 'homura_pistol' then
                inst.AnimState:PlayAnimation('hand_shoot')
                inst.SoundEmitter:PlaySound('lw_homura/sfx/load_up_3d',nil,0.7,true)
            else
                inst.AnimState:PlayAnimation('homura_gun_pre')
                inst.SoundEmitter:PlaySound('lw_homura/sfx/load_down_3d',nil,0.7,true)
            end
        end

        inst:PerformPreviewBufferedAction()--@--??
        inst.sg:SetTimeout(4)
    end,

    timeline = {
        TimeEvent(11*FRAMES,function(inst)
            if inst.sg.statemem.weapon and inst.sg.statemem.weapon.prefab == 'homura_pistol' then
                inst.AnimState:Pause()
            end
        end),
        TimeEvent(12*FRAMES,function(inst)
            if inst.sg.statemem.weapon and inst.sg.statemem.weapon.prefab ~= 'homura_pistol' then
                inst.AnimState:PlayAnimation('homura_gun_focus',true)
            end
        end),
    },

    onupdate = function(inst)
        local target = inst.sg.statemem.target
        local actiontarget = inst:GetBufferedAction() and inst:GetBufferedAction().target
        if target == actiontarget then --攻击目标与锁定目标相同
            ---
        elseif actiontarget then
            inst.sg.statemem.changetarget = true --由于切换目标而重新进入state
            inst.sg:GoToState('homura_focus', 'fromfocus')
        end

        if target and target:IsValid() and not target:HasTag("INLIMBO")and not target.replica.health:IsDead()then
            inst:FacePoint(target:GetPosition():Get())
        else
            inst.sg:GoToState('idle')
        end
    end,

    ontimeout = function(inst)
    --[[
        inst.sg.statemem.down = true
        local weapon = inst.sg.statemem.weapon
        if weapon and weapon.prefab == 'homura_pistol' then
            inst.sg:GoToState('homura_pistol_atk')
        elseif weapon and weapon.prefab == 'homura_gun' then
            inst.sg:GoToState('homura_gun_atk')
        elseif weapon and weapon.prefab == 'homura_hmg' then
            inst.sg:GoToState('homura_hmg_atk')
        end
        --]]
    end,

    onexit = function(inst)
        inst.AnimState:Resume()
    end,
}

AddStategraphState('wilson_client', homura_focus_client)


