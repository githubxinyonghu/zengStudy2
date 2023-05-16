local function Moveback(inst, length)
    local pos = inst:GetPosition()
    local facing = inst.Transform:GetRotation()
    local angle = (facing + 270)*DEGREES
    local targetpos = pos + Vector3(length*math.sin(angle),0,length*math.cos(angle))
    inst.Transform:SetPosition(targetpos:Get())
end

local GUN_MOVE = 1
local HMG_MOVE = 0.5
local HMG_SPEED = 20 -- Shoots per second

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

local function CheckWeaponCanRangeAttack(inst)
    return inst.sg.statemem.weapon and inst.sg.statemem.weapon:HasTag("homuraTag_ranged")
end

local function CheckTarget(inst, target, weapon)
    if target and target:IsValid() and CanEntitySeeTarget(inst, target) then
        return inst.replica.combat:CanTarget(target) and inst.replica.combat:CanHitTarget(target, weapon)
    end
end

local function CheckAttackAction(inst)  
    local pressingattack = GetClientKey(inst, "attack")
    local mouseover = GetClientKey(inst, "mouseover")

    -- 2021.6.1 考虑自动切换目标的行为
    local action = inst.sg.statemem.action
    local weapon = inst.replica.combat:GetWeapon()
    local current_target = action and action.target

    inst.sg:RemoveStateTag("attack")
    local combat_target = inst.components.playercontroller ~= nil and inst.components.playercontroller:GetAttackTarget()
    inst.sg:AddStateTag("attack")
    
    -- 键盘/手柄的攻击按键
    if pressingattack then
        if CheckTarget(inst, current_target, weapon) then
            return true
        elseif combat_target ~= nil and combat_target ~= current_target and
            CheckTarget(inst, combat_target, weapon) and
            distsq(combat_target:GetPosition(), current_target and current_target:IsValid() and current_target:GetPosition() or 
                combat_target:GetPosition()) < 4*4 then
            inst.sg.statemem.attacktarget = combat_target
            inst.sg.statemem.target = combat_target
            if action ~= nil then
                action.target = combat_target
            end
            return true
        end
    end
    
    --鼠标左键按下 判断鼠标下的目标
    if pressingattack then
        if not mouseent then --鼠标下无目标, 判定action目标 (可能是在锁定其他目标的途中)
            mouseent = current_target
        end
        if not CheckTarget(inst, mouseent, weapon) then
            return false
        end
        --鼠标下目标有效, 切换新目标
        if action ~= nil and action:IsValid() then
            action.target = mouseent
            inst.sg.statemem.target = mouseent
            return true
        end 
    end
end


local gun_atk = State{
    name = 'homura_gun_atk',
    tags = {"attack", "notalking", "abouttoattack", "homura_gun_atk"},

    onenter = function(inst, action)
        inst.components.locomotor:Stop()
        
        inst.AnimState:PlayAnimation('homura_gun_loop')

        local buffaction = action or inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        inst.components.combat:SetTarget(target)
        --inst.components.combat:StartAttack()
        inst.components.combat:CancelAttack() --连击动作，不记录攻击冷却时间
        inst.sg.statemem.target = target
        inst.sg.statemem.attacktarget = target

        local weapon = inst.components.combat:GetWeapon()
        inst.sg.statemem.weapon = weapon

        inst.sg.statemem.action = buffaction

        if action then 
            inst.bufferedaction = action
        end

        inst.sg.statemem.projectiledelay = (2 - 1)*FRAMES
    end,

    onupdate = function(inst, dt)
        if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
            inst:FacePoint(inst.sg.statemem.target:GetPosition())
        end
        CommonProjectileUpdate(inst, dt)
    end,

    timeline = {
        TimeEvent(2*FRAMES, function(inst)
            if not CheckWeaponCanRangeAttack(inst) then
                inst.sg.statemem.exit = true
                inst.sg:GoToState('homura_gun_pst')
                return
            end
            AddExtraFx(inst, 'homura_gun_light', Vector3(2,0,0))
            Moveback(inst, GUN_MOVE*FRAMES)
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag('abouttoattack')
            local weapon = inst.sg.statemem.weapon
            if weapon and weapon:HasTag("homuraTag_silentgun") then
                inst.SoundEmitter:PlaySound('lw_homura/gun/normal', nil, 0.2, true) --@--
            else
                inst.SoundEmitter:PlaySound('lw_homura/gun/normal', nil, 0.7, true)
            end

        end),

        TimeEvent(4*FRAMES, function(inst) 
            if not CheckWeaponCanRangeAttack(inst) then 
                inst.sg.statemem.exit = true
                inst.sg:GoToState('homura_gun_pst')
                return
            end
            if CheckAttackAction(inst) and inst.sg.statemem.action then

                --inst.sg:RemoveStateTag('attack')
                inst.components.locomotor:Stop()
                inst:ClearBufferedAction()
                inst:PushBufferedAction(inst.sg.statemem.action)
                inst.sg:GoToState('homura_gun_atk', inst.sg.statemem.action)
            else
                inst.sg:GoToState('homura_gun_pst')
                return
            end
        end),
    },

    events = {
        CommonEquip(),
        CommonUnequip(),
    },

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        inst:ClearBufferedAction()
    end,
}

AddStategraphState("wilson", gun_atk)

local gun_atk_client = State{
    name = 'homura_gun_atk',
    tags = {"attack", "notalking", "abouttoattack", "homura_gun_atk"},

    onenter = function(inst, action)
        inst.components.locomotor:Stop()
        
        inst.AnimState:PlayAnimation('homura_gun_loop')

        local buffaction = action or inst:GetBufferedAction()
        local target = buffaction and buffaction.target

        inst.replica.combat:CancelAttack()
        inst.sg.statemem.target = target
        --inst.sg.statemem.attacktarget = target

        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst.sg.statemem.weapon = weapon

        inst.sg.statemem.action = buffaction

        inst.sg.statemem.projectiledelay = (2 - 1)*FRAMES
    end,

    onupdate = function(inst, dt)
        if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
            inst:FacePoint(inst.sg.statemem.target:GetPosition())
        end
        CommonProjectileUpdate(inst, dt)
    end,

    timeline = {
        TimeEvent(2*FRAMES, function(inst)
            Moveback(inst, GUN_MOVE*FRAMES)
            inst:PerformPreviewBufferedAction()
            inst.sg:RemoveStateTag('abouttoattack')
            local weapon = inst.sg.statemem.weapon
            inst.SoundEmitter:KillSound('homuraSG.gun')
            if weapon and weapon:HasTag("homuraTag_silentgun") then
                inst.SoundEmitter:PlaySound('lw_homura/gun/normal', nil, 0.2, true) --@--
            else
                inst.SoundEmitter:PlaySound('lw_homura/gun/normal', nil, 0.7, true)
            end

        end),

        TimeEvent(4*FRAMES, function(inst) 
            if not CheckWeaponCanRangeAttack(inst) then 
                inst.sg.statemem.exit = true
                inst.sg:GoToState('homura_gun_pst')
                return
            end
            if CheckAttackAction(inst) and inst.sg.statemem.action then
                inst.components.locomotor:Stop()
                inst:ClearBufferedAction()
                inst.sg:GoToState('homura_gun_atk', inst.sg.statemem.action)
            else
                inst.sg:GoToState('homura_gun_pst')
                return
            end
        end),
    },

    onexit = function(inst)
        inst:ClearBufferedAction()
    end,
}

AddStategraphState("wilson_client", gun_atk_client)

local homura_hmg_atk = State{
    name = 'homura_hmg_atk',
    tags = {"attack", "notalking", "abouttoattack", "busy", "homura_hmg_atk"},

    onenter = function(inst, target)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation('homura_gun_loop', true)

        local buffaction = inst:GetBufferedAction()
        local weapon = inst.components.combat:GetWeapon()

        inst.sg.statemem.vol = (weapon and weapon:HasTag('homuraTag_silentgun')) and 0.1 or 0.7
        inst.SoundEmitter:PlaySound('lw_homura/hmg/pst', 'homura_hmg_PST', inst.sg.statemem.vol, true)

        if buffaction then
            inst.sg.statemem.target = buffaction.target 
            inst.sg.statemem.attacktarget = buffaction.target
            inst.sg.statemem.action = buffaction
        end
        inst.sg.statemem.weapon = weapon

        inst.sg.statemem.exittick = 3
        inst.sg.statemem.num = 1
    end,

    onupdate = function(inst,dt)
        inst.components.locomotor:Stop()
        inst.components.combat:SetTarget(inst.sg.statemem.target)
        if not CheckWeaponCanRangeAttack(inst) then 
            inst.sg.statemem.exit = true
            inst.sg:GoToState('homura_gun_pst')
            return
        end


        if CheckAttackAction(inst) then
            -- print("attack!")
        elseif inst.sg.statemem.exittick > 0 then
            -- print('not press but 3')
        else
            -- print('not press and exit')
            inst.sg:GoToState('homura_gun_pst')
            return
        end

        if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
            inst:FacePoint(inst.sg.statemem.target:GetPosition())
        end

        inst.sg.statemem.num = inst.sg.statemem.num + HMG_SPEED * dt 
        if inst.sg.statemem.num >= 1 then
            inst.sg.statemem.num = inst.sg.statemem.num - 1
            inst:PerformBufferedAction()
            inst.bufferedaction = inst.sg.statemem.action --@--
            
            AddExtraFx(inst, 'homura_gun_light', Vector3(2,0,0))
            Moveback(inst, HMG_MOVE*dt)
        end
        
        inst.sg.statemem.exittick = inst.sg.statemem.exittick - 1

        if inst.sg.statemem.exittick == 0 then
            inst.sg:RemoveStateTag('busy')
            if not inst.SoundEmitter:PlayingSound('homura_hmg_LOOP') then
                inst.SoundEmitter:PlaySound('lw_homura/hmg/loop', 'homura_hmg_LOOP', inst.sg.statemem.vol, true)
            end
        end
    end,

    events = {
        CommonEquip(),
        CommonUnequip(),
    },

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        inst.SoundEmitter:KillSound('homura_hmg_LOOP')
        inst:ClearBufferedAction()
    end,
}

AddStategraphState('wilson', homura_hmg_atk)


local homura_hmg_atk_client = State{
    name = 'homura_hmg_atk',
    tags = {"attack", "notalking", "abouttoattack", "busy", "homura_hmg_atk"},

    onenter = function(inst, target)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation('homura_gun_loop', true)

        local buffaction = inst:GetBufferedAction()
        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        inst:PerformPreviewBufferedAction()

        inst.sg.statemem.vol = (weapon and weapon:HasTag('homuraTag_silentgun')) and 0.1 or 0.7
        inst.SoundEmitter:PlaySound('lw_homura/hmg/pst', 'homura_hmg_PST', inst.sg.statemem.vol, true)

        if buffaction then
            inst.sg.statemem.target = buffaction.target 
            inst.sg.statemem.attacktarget = buffaction.target
            inst.sg.statemem.action = buffaction
        end
        inst.sg.statemem.weapon = weapon

        inst.sg.statemem.exittick = 3
        inst.sg.statemem.num = 1
    end,

    onupdate = function(inst,dt)
        inst.components.locomotor:Stop()
        if not CheckWeaponCanRangeAttack(inst) then 
            inst.sg.statemem.exit = true
            inst.sg:GoToState('homura_gun_pst')
            return
        end

        if CheckAttackAction(inst) then
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                inst:FacePoint(inst.sg.statemem.target:GetPosition())
            end
            inst:ClearBufferedAction()
        elseif inst.sg.statemem.exittick > 0 then
            inst:ClearBufferedAction()
        else
            inst.sg:GoToState('homura_gun_pst')
            return
        end
        
        inst.sg.statemem.num = inst.sg.statemem.num + HMG_SPEED*dt 
        if inst.sg.statemem.num >= 1 then
            inst.sg.statemem.num = inst.sg.statemem.num - 1
            Moveback(inst, HMG_MOVE*dt)
        end            

        inst.sg.statemem.exittick = inst.sg.statemem.exittick - 1

        if inst.sg.statemem.exittick == 0 then
            inst.sg:RemoveStateTag('busy')
            if not inst.SoundEmitter:PlayingSound('homura_hmg_LOOP') then
                inst.SoundEmitter:PlaySound('lw_homura/hmg/loop', 'homura_hmg_LOOP', inst.sg.statemem.vol, true)
            end
        end

    end,

    onexit = function(inst)
        inst.SoundEmitter:KillSound('homura_hmg_LOOP')
        inst:ClearBufferedAction()
    end,
}

AddStategraphState('wilson_client', homura_hmg_atk_client)