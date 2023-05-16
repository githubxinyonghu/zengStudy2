-- 2022年了, 老王终于发现晓美焰还有个武器叫做弓

local assets= 
{
    Asset("ANIM", "anim/homura_bow.zip"),        -- 地面贴图
    Asset("ANIM", "anim/homura_bow_anim.zip"),   -- 手持贴图 + 站桩射箭动画
    Asset("ANIM", "anim/homura_bow_anim2.zip"),  -- 移动射箭动画
    Asset("ANIM", "anim/homura_bow_anim3.zip"),  -- 骑牛射箭动画
    Asset("ANIM", "anim/homura_bow_electric_fx.zip"),

    Asset("ANIM", "anim/lw_rotation_anim.zip"),
    Asset("ANIM", "anim/homura_bow_fx.zip"),

    Asset("ATLAS","images/inventoryimages/homura_bow.xml"),
}

local L = HOMURA_GLOBALS.LANGUAGE
STRINGS.NAMES.HOMURA_BOW = L and "Magical Bow" or "魔法弓"
STRINGS.RECIPE_DESC.HOMURA_BOW = L and "A replica of another bow." or "这是另一把弓的仿制品"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_BOW = L and "I will continue to fight." or "我会继续战斗下去。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_BOW = L and "Only Homura can use the bow to its full power." or "只有精通魔法的人才能发挥这把弓的全部威力。"

local function onequip(inst,owner)
    owner.AnimState:OverrideSymbol("swap_object","homura_bow_anim","swap_object")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
end

local function onunequip(inst,owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end

local function Calc(data, charge, isspecialcharge)
    -- 1 = basic, 2 = bonus, 3 = special
    if isspecialcharge then
        return data[3]
    else
        return data[1] + data[2] * charge
    end
end

local function Launch(inst, owner, charge, isspecialcharge)
    inst.SoundEmitter:PlaySound("lw_homura/bow/launch")
    if isspecialcharge then
        inst.SoundEmitter:PlaySound("lw_homura/bow/launch_magic")
    end

    inst.components.weapon:SetProjectile("homura_arrow"..(isspecialcharge and "_magic" or ""))

    local data = inst.homura_projectile_data
    data.maxhits = isspecialcharge and math.huge or 1
    data.infinite_range = isspecialcharge == true
    data.damage1 = Calc(HOMURA_GLOBALS.BOW.damage, charge, isspecialcharge)
    data.speed = Calc(HOMURA_GLOBALS.BOW.flyingspeed, charge, isspecialcharge)

    -- local pos = owner:GetPosition()
    -- local angle = -owner.Transform:GetRotation()* DEGREES
    -- pos = pos + Vector3(math.cos(angle), 0, math.sin(angle))
    local pos = owner.components.homura_clientkey:GetWorldPosition()
    local target = CreateEntity()
    target.entity:AddTransform():SetPosition(pos:Get())
    target:DoTaskInTime(0, target.Remove)
    inst.components.weapon:LaunchProjectile(owner, target)
    inst.components.weapon:SetProjectile(nil)

    inst.components.finiteuses:Use(1)
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()

    local offset = player.replica.homura_archer.aimingdir
    return player:GetPosition() + offset * 8
end

local function bow()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform() 
    local anim = inst.entity:AddAnimState() 
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    anim:SetBank("homura_bow")
    anim:SetBuild("homura_bow")
    anim:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.projectiledelay = FRAMES

    inst:AddTag("homura_bow")
    -- inst:AddTag("rangedweapon")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.homura_projectile_data = HOMURA_GLOBALS.BOW

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_bow.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(10)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(HOMURA_GLOBALS.BOW.maxuses)
    inst.components.finiteuses:SetUses(HOMURA_GLOBALS.BOW.maxuses)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("homura_bow")

    inst.Launch = Launch

    MakeHauntableLaunch(inst)

    return inst
end

local DeltaAngle = require "homura.math".DeltaAngle

local function CreateTail(colour)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    if colour == 1 then
        anim:SetBuild("homura_bow_anim")
        anim:SetBank("homura_arrow")
        anim:SetPercent("flying", 0.5)
        anim:SetMultColour(0.5, 0.5, 0.5, 0.5)
        anim:SetOrientation(ANIM_ORIENTATION.OnGround)
        anim:SetLayer(LAYER_BACKGROUND)
        anim:SetSortOrder(3)
    elseif colour == 2 then
        anim:SetBuild("homura_bow_electric_fx")
        anim:SetBank("homura_arrow")
        anim:PlayAnimation("tail", true)
        anim:SetTime(math.random()*8.9)
        anim:SetMultColour(.3, .1, 1.0, .5)
        anim:SetSortOrder(3)
    end

    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:AddComponent("colourtweener")

    inst.entity:SetCanSleep(false)
    inst.persists = false
    
    local fadeouttime = colour == 2 and 1 or 8*FRAMES
    inst.components.colourtweener:StartTween({0,0,0,0}, fadeouttime, inst.Remove)

    return inst
end

local function Animate(inst)
    if inst.i > 30 then
        inst.i = 0
    end

    inst.AnimState:OverrideSymbol("symbol1", "homura_bow_electric_fx", "symbol"..inst.i)
    inst.i = inst.i + 1
end

local function UpdateTail(inst,tails)
    if not inst.entity:IsVisible() then
        return
    end

    local isspecialcharge = inst.prefabname == "homura_arrow_magic"

    local pos = inst:GetPosition()
    local rot = inst.Transform:GetRotation()
    local tail = CreateTail(1)
    tail.Transform:SetPosition(pos:Get())
    tail.Transform:SetRotation(rot)

    if isspecialcharge then
        Animate(inst)
        for i = 1, math.random(2, 3)do
            local tail = CreateTail(2)
            local scale = GetRandomMinMax(.3, .8)
            tail.Transform:SetScale(scale, scale, scale)
            tail.Transform:SetPosition((pos + Vector3(
                GetRandomWithVariance(0, .5),
                GetRandomWithVariance(0, .5),
                GetRandomWithVariance(0, .5))):Get())
        end
    end
end

local function arrow_common(inst)
    inst._status = net_tinybyte(inst.GUID, "status", "status")
    inst._status:set_local(0)

    inst.AnimState:SetLightOverride(0.5)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    if inst.prefabname == "homura_arrow_magic" then
        inst.i = 0
        Animate(inst)

        local light = inst.entity:AddLight()
        light:SetRadius(2.0)
        light:SetColour(.6, .1, 1.0)
        light:SetFalloff(.5)
        light:SetIntensity(.8)
    end

    inst.task = inst:DoPeriodicTask(0, UpdateTail, nil)
end

local function arrow_master(inst)
    inst:AddComponent("homura_projectile")
    inst.components.homura_projectile.no_miss_fx = true

    inst.components.projectile:SetLaunchOffset(Vector3(1, 1, 0))

end

local function Animate(inst)
    -- 00000 -> 00034
    if inst.i <= 34 then
        inst.AnimState:OverrideSymbol("symbol1", "homura_bow_fx", string.format("glow_%05d", math.floor(inst.i)))
        inst.i = inst.i + inst.speed
    else
        inst:Remove()
    end
end

local function Particle()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    anim:SetBank("lw_rotation_anim")
    anim:SetBuild("log")
    anim:PlayAnimation("anim"..math.random(1, 360))
    anim:SetMultColour(0.4, 0.3, 1.0, 1.0)
    anim:SetLightOverride(0.5)
    anim:SetBloomEffectHandle("shaders/anim.ksh")

    trans:SetScale(0.8, 0.8, 0.8)

    inst.i = 0
    inst.speed = 1

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(Animate)

    return inst
end

local function SpawnParticle(inst)
    inst.num_to_emit = inst.num_to_emit + TheSim:GetTickTime()* inst.emit_per_second
    inst.speed = inst.speed + TheSim:GetTickTime()* inst.speedup

    while inst.num_to_emit > 0 do
        inst.num_to_emit = inst.num_to_emit - 1
        if not TheNet:IsDedicated() then
            inst:AddChild(Particle())
        end
    end

    local parent = inst.entity:GetParent()
    if parent and parent:IsValid() then
        local facing = parent.AnimState:GetCurrentFacing()
        local bg = facing == FACING_UP or facing == FACING_UPRIGHT or facing == FACING_UPLEFT
        for k in pairs(inst.children or {})do
            if bg then
                k.AnimState:SetLayer(LAYER_BACKGROUND)
                k.speed = inst.speed
            else
                k.AnimState:SetLayer(LAYER_WORLD)
                k.speed = inst.speed
            end
        end
    end
end

local function chargefx()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local net = inst.entity:AddNetwork()

    inst.entity:AddFollower()

    inst:AddTag("FX")
    inst.persists = false

    inst:AddComponent("updatelooper")

    inst.num_to_emit = 0
    inst.emit_per_second = 0
    inst.speed = 1
    inst.speedup = 0.5

    inst._start = net_event(inst.GUID, "_start")
    inst._stable = net_event(inst.GUID, "_stable")
    inst._stop = net_event(inst.GUID, "_stop")

    local push = TheWorld.ismastersim and function(inst, event)
        inst[event]:push()
    end or function() end

    inst.Start = function(inst)
        push(inst, "_start")
        inst.speed = 1
        inst.speedup = 0.5
        inst.emit_per_second = 50
        inst.components.updatelooper:AddOnUpdateFn(SpawnParticle)
    end

    inst.Stable = function(inst)
        push(inst, "_stable")
        inst.speedup = 0
        inst.emit_per_second = 10
    end

    inst.Stop = function(inst)
        push(inst, "_stop")
        inst.emit_per_second = 0
        inst.components.updatelooper:RemoveOnUpdateFn(SpawnParticle) 
    end

    if not TheWorld.ismastersim then
        inst:ListenForEvent("_start", inst.Start)
        inst:ListenForEvent("_stop", inst.Stop)
        inst:ListenForEvent("_stable", inst.Stable)
    end

    return inst
end

local function SpawnShine(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)
    inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst.AnimState:SetBank("crab_king_shine")
    inst.AnimState:SetBuild("crab_king_shine")
    inst.AnimState:PlayAnimation("shine")
    inst.AnimState:HideSymbol("sparkle")
    inst.AnimState:SetTime(0.1)

    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:DoTaskInTime(1, inst.Remove)
end

local function shinefx()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local net   = inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, SpawnShine)
    end

    inst:DoTaskInTime(1, inst.Remove)
 
    inst.entity:SetPristine()
    return inst
end

local MakeProjectile = require "homura.weapon".MakeProjectile

return Prefab("homura_bow", bow, assets),
    Prefab("homura_bow_charge_fx", chargefx, assets),
    Prefab("homura_bow_shine_fx", shinefx, assets),
    MakeProjectile("homura_arrow", {
        anim = {bank = "homura_arrow", build = "homura_bow_anim", anim = "flying", onground = true},
        assets = assets,
        masterfn = arrow_master,
        commonfn = arrow_common,
    }),
    MakeProjectile("homura_arrow_magic", {
        anim = {bank = "lw_rotation_anim", build = "log", anim = "anim0", onground = true},
        assets = assets,
        masterfn = arrow_master,
        commonfn = arrow_common,
    })
