-- 2021.12.24 
-- 因为手枪瞄准模式已删除, 将抬枪和射击两个状态合并

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

local function PlayShootSound(inst)
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
        inst.SoundEmitter:PlaySound("lw_homura/snowpea/shoot", nil, nil, true)
        inst.SoundEmitter:PlaySound("lw_homura/snowpea/snow_pea_sparkles", nil, nil, true)
        inst.components.homura_snowpea_puff:OnShoot()
    end
end

local function OverrideBuild(inst)
    local weapon = GetWeapon(inst)
    if weapon and weapon.prefab == "homura_snowpea" then
        inst.AnimState:ClearOverrideBuild("lw_player_pistol")
    else
        inst.AnimState:AddOverrideBuild("lw_player_pistol")
    end
end

-- 主机
local atk = State{
    name = "homura_pistol_atk",
    tags = {"attack", "notalking", "abouttoattack", "autopredict", "homura_pistol_atk"},
        
    onenter = function(inst)
        inst.components.locomotor:Stop()

        OverrideBuild(inst)
        inst.AnimState:PlayAnimation("hand_shoot")

        PlayAimSound(inst)

        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target

        inst.components.combat:SetTarget(target)

        if target ~= nil and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end

        inst.sg.statemem.projectiledelay = (17 - 1)*FRAMES 

        -- inst.AnimState:SetTime(11*FRAMES)  
    end,

    timeline =
    {
        TimeEvent(17*FRAMES, function(inst) 
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack") 
            PlayShootSound(inst)
        end),

        TimeEvent(18*FRAMES, function(inst)
            inst.sg:AddStateTag("idle")
            inst.sg:RemoveStateTag("attack")
        end),
    },

    events = {
        CommonAnimover(),
        CommonEquip(),
        CommonUnequip(),
    },

    onupdate = function(inst, dt)
        CommonProjectileUpdate(inst, dt)
    end,

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        inst:ClearBufferedAction()
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
}

AddStategraphState("wilson", atk)

-- 客机
local atk = State{
    name = "homura_pistol_atk",
    tags = {"attack", "notalking", "abouttoattack", "homura_pistol_atk"},
        
    onenter = function(inst)
        inst.components.locomotor:Stop()

        OverrideBuild(inst)
        inst.AnimState:PlayAnimation("hand_shoot")

        PlayAimSound(inst)

        local buffaction = inst:GetBufferedAction()
        local target = buffaction and buffaction.target

        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()
        end

        if target ~= nil and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end

        inst.sg.statemem.projectiledelay = (17-1)*FRAMES

        -- inst.AnimState:SetTime(11*FRAMES)
    end,

    timeline =
    {
        TimeEvent(17*FRAMES, function(inst)
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
            PlayShootSound(inst)
        end),

        TimeEvent(18*FRAMES, function(inst)
            inst.sg:AddStateTag("idle")
            inst.sg:RemoveStateTag("attack")
        end),
    },

    events = {
        CommonAnimQueueOver(),
    },

    onupdate = function(inst, dt)
        CommonProjectileUpdate(inst,  dt)
    end,

    onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.replica.combat:CancelAttack()
        end
    end,
}

AddStategraphState("wilson_client", atk)

