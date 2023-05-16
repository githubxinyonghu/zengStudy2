local GetWeapon = GetWeapon

local function PlayAimSound(inst)
    local weapon = GetWeapon(inst)
    if weapon == nil then
        return
    end

    if weapon.prefab == "homura_pistol" then
        inst.SoundEmitter:PlaySound("lw_homura/sfx/load_up_3d", nil, 0.7, true)
    elseif weapon.prefab == "homura_snowpea" then
        --?
    end
end

local function PlayShootSound(inst, weapon)
    local weapon = GetWeapon(inst)
    if weapon == nil then
        return
    end

    if weapon.prefab == "homura_pistol" then
        if weapon:HasTag("homuraTag_silentgun") then
            inst.SoundEmitter:PlaySound("lw_homura/pistol/silent", nil, 0.5, true)
        else
            inst.SoundEmitter:PlaySound("lw_homura/pistol/normal", nil, 0.7, true)
        end
    elseif weapon.prefab == "homura_snowpea" then
        inst.SoundEmitter:PlaySound("lw_homura/snowpea/shoot")
    end
end

-- 主机 抬枪
local pre = State{
    name = "homura_pistol_pre",
    tags = {"attack", "notalking", "abouttoattack", "autopredict", "homura_pistol_pre"},
        
    onenter = function(inst)
        inst.components.locomotor:Stop()

        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
       
        inst.AnimState:PlayAnimation("hand_shoot")

        PlayAimSound(inst)

        if target and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end
        --inst.sg.statemem.projectiledelay = 17 - 1   
    end,

    timeline =
    {
        TimeEvent(11*FRAMES, function(inst)
            inst.sg.statemem.gotoatk = true
            inst.sg:GoToState("homura_pistol_atk")
        end),
    },

    events = {
        CommonAnimover(),
        CommonEquip(),
        CommonUnequip(),
    },

    onexit = function(inst)
        if not inst.sg.statemem.gotoatk then
            -- goto other states
            inst:ClearBufferedAction()
        end
    end,
}

-- 主机 开枪射击
local atk = State{
    name = "homura_pistol_atk",
    tags = {"abouttoattack", "attack", "notalking", "autopredict", "homura_pistol_atk"},

    onenter = function (inst)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        if not inst.AnimState:IsCurrentAnimation("hand_shoot")then
            inst.AnimState:PlayAnimation("hand_shoot")
        end
        inst.AnimState:SetTime(11*FRAMES)
        inst.sg.statemem.gun = inst.components.combat:GetWeapon()

        inst.components.combat:SetTarget(target)
        if target and target:IsValid() then
            inst:FacePoint(target:GetPosition():Get())
        end

        inst.sg.statemem.projectiledelay = (6 - 1)*FRAMES 
    end,

    timeline = {
        --17帧攻击（11+6）
        TimeEvent(6*FRAMES, function(inst) 
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack") 
            --inst.sg:AddStateTag("idle")
            PlayShootSound(inst)
            
        end),
        TimeEvent(7*FRAMES, function(inst)
            --inst.sg:RemoveStateTag("attack")
        end),
    }, 

    events = {
        CommonAnimover(),
        CommonEquip(),
        CommonUnequip(),
    },

    onupdate = CommonProjectileUpdate,

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        inst:ClearBufferedAction()
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
}

AddStategraphState("wilson", pre)
AddStategraphState('wilson',atk)


local homura_pistol_pre_client = State{
    name = "homura_pistol_pre",
    tags = {"attack", "notalking", "abouttoattack", "homura_pistol_pre"},
        
    onenter = function(inst)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()
        end
        if target ~= nil and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end

        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("hand_shoot")
        inst.SoundEmitter:PlaySound('lw_homura/sfx/load_up_3d',nil, PRE_SFX_VOLUME,true)

        inst.sg:SetTimeout(1) 
    end,

    timeline =
    {
        TimeEvent(11*FRAMES, function(inst)
            inst.sg:GoToState('homura_pistol_atk')
        end),
    },

    onupdate = function(inst)
        if inst:HasTag("doing") then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end,
}

local homura_pistol_atk_client = State{
    name = 'homura_pistol_atk',
    tags = {'abouttoattack','attack','notalking','homura_pistol_atk'},

    onenter = function (inst)
        local buffaction = inst:GetBufferedAction() 
        local target = buffaction and buffaction.target
        if buffaction then
            inst:PerformPreviewBufferedAction()
        end
        if not inst.AnimState:IsCurrentAnimation('hand_shoot')then
            inst.AnimState:PlayAnimation('hand_shoot')
        end
        inst.AnimState:SetTime(11*FRAMES) --设置动画时间为11/30s
        inst.sg.statemem.gun = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if target and target:IsValid() then
            inst:FacePoint(target:GetPosition():Get())
        end

        inst.sg.statemem.projectiledelay = (6 - 1)*FRAMES
    end,

    timeline = {
        --17帧攻击（11+6）
        TimeEvent(6*FRAMES, function(inst) 
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
            local weapon = inst.sg.statemem.gun
            if weapon and weapon:HasTag('homuraTag_silentgun') then
                inst.SoundEmitter:PlaySound('lw_homura/pistol/silent', nil, SILENT_SFX_VOLUME, true)
            else
                inst.SoundEmitter:PlaySound('lw_homura/pistol/normal', nil, ATK_SFX_VOLUME, true)
            end
        end),
    }, 

    onupdate = CommonProjectileUpdate,

    events = {
        CommonAnimQueueOver(),
    },

    onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.replica.combat:CancelAttack()
        end
    end,
}

AddStategraphState('wilson_client', homura_pistol_pre_client)
AddStategraphState('wilson_client', homura_pistol_atk_client)

