local assets= 
{
    Asset("ANIM", "anim/homura_rpg.zip"),

    Asset("ATLAS","images/inventoryimages/homura_rpg.xml"),
    Asset("ATLAS","images/inventoryimages/homura_rpg_ammo1.xml"),
    Asset("ATLAS","images/inventoryimages/homura_rpg_ammo2.xml"),

    Asset("ANIM", "anim/player_homura_rpg.zip"),

    Asset("ANIM", "anim/homura_rpg_smoke.zip"),
}
local L = HOMURA_GLOBALS.LANGUAGE
local SPEECH_GENERIC = STRINGS.CHARACTERS.GENERIC
local SPEECH_HOMURA = STRINGS.CHARACTERS.HOMURA_1

if L then
STRINGS.NAMES.HOMURA_RPG = "AT4"
STRINGS.RECIPE_DESC.HOMURA_RPG = "A powerful hot weapon."
SPEECH_GENERIC.HOMURA_RPG = "A powerful hot weapon."

STRINGS.NAMES.HOMURA_RPG_AMMO1 = "Rocket propelled grenade"
STRINGS.RECIPE_DESC.HOMURA_RPG_AMMO1 = "Flying bomb."
SPEECH_GENERIC.HOMURA_RPG_AMMO1 = "Flying bomb."

else

STRINGS.NAMES.HOMURA_RPG = "AT4火箭筒"
STRINGS.RECIPE_DESC.HOMURA_RPG = "威力巨大的远程武器。"
SPEECH_GENERIC.HOMURA_RPG = "这是用来发射火箭弹的。"
SPEECH_HOMURA.HOMURA_RPG = "用这个甚至可以击落飞机。"

STRINGS.NAMES.HOMURA_RPG_AMMO1 = "火箭弹"
STRINGS.RECIPE_DESC.HOMURA_RPG_AMMO1 = "“一发入魂”"
SPEECH_GENERIC.HOMURA_RPG_AMMO1 = "装填到火箭发射器里就能打出去了"
SPEECH_HOMURA.HOMURA_RPG_AMMO1 = "一枚会飞的炸弹。"
end

local function MakeAmmo(num)
    local function fn()
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local net   = inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        anim:SetBank("ammo"..num)
        anim:SetBuild("homura_rpg")
        anim:PlayAnimation("idle")

        MakeInventoryFloatable(inst, "med")
        inst:AddTag('homuraTag_rpgammo')

        inst.projectilename = 'homura_missile'..num

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("tradable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_rpg_ammo"..num..".xml"
        inst:AddComponent('homura_ammo')
        inst:AddComponent("stackable")
        MakeHauntableLaunch(inst)

        return inst
    end
    return Prefab("homura_rpg_ammo"..num,fn,assets) 
end

local function OnThrown(inst,owner,target)
    inst.components.homura_acceleratingprojectile:StartUpdating()
end

local function CreateFire()
    local inst = CreateEntity()
    inst.entity:SetCanSleep(false)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    local light = inst.entity:AddLight()
    light:Enable(true)
    light:SetRadius(.5)
    light:SetFalloff(.5)
    light:SetIntensity(.8)
    light:SetColour(1,0.75,0.25)
    inst:AddComponent('lighttweener')
    inst.components.lighttweener:StartTween(light, 0.1, 0.5, 0.8, nil, 0.6, function()light:Enable(false) end)

    MakeInventoryPhysics(inst)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBuild("homura_rpg")
    inst.AnimState:SetBank("smoke")
    inst.AnimState:PlayAnimation("anim", true)
    inst.AnimState:SetMultColour(1,195/255,86/255,.8)
    inst.AnimState:SetTime(math.random())
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    local s = GetRandomMinMax(.4,.8)
    inst.Transform:SetScale(s,s,s)

    inst:AddComponent("colourtweener")
    inst.components.colourtweener:StartTween({0,0,0,.5},.5)
    inst:DoTaskInTime(.6,function(inst)
        inst.AnimState:ClearBloomEffectHandle()
        inst.components.colourtweener:StartTween({0,0,0,0},.5,inst.Remove)
    end)

    return inst
end

local function UpdateTail(inst,tails)
    local x, y, z = inst.Transform:GetWorldPosition()
    for tail, _ in pairs(tails) do
        tail:ForceFacePoint(x, y, z)
    end
 
    local loop = math.random(1,5)
    for i = 1,loop do
        local speed = 5
        local tail = CreateFire()
        local rot = inst.Transform:GetRotation()
        tail.Transform:SetRotation(rot)
        rot = rot * DEGREES
        local offsangle = math.random() * 6.283
        local offsradius = GetRandomMinMax(0,.2)
        local hoffset = math.cos(offsangle) * offsradius
        local voffset = math.sin(offsangle) * offsradius
        tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
        tail.Physics:SetMotorVel(speed * GetRandomMinMax(.2,.5), 0, 0)
        tails[tail] = true
        inst:ListenForEvent("onremove", function(tail) tails[tail] = nil end, tail)
        tail:ListenForEvent("onremove", function(inst)
            tail.Transform:SetRotation(tail.Transform:GetRotation() + GetRandomMinMax(-15,15))
        end, inst)
    end    
end

local function OnHit(inst, owner, target)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .03, 1, target, 40)

    local x, y, z = inst:GetPosition():Get()
    local explode = SpawnPrefab("explode_small")
    explode.Transform:SetPosition(x, y, z)

    local explosive = inst.components.explosive
    explosive.lightonexplode = not inst.components.homura_projectile.has_ice 
    explosive.redirect_to_player = owner
    explosive:OnBurnt()

    local range = explosive.explosiverange
    if target and target:IsValid() and target:GetDistanceSqToPoint(x, y, z) > range * range then
        target.components.combat:GetAttacked(owner, explosive.explosivedamage)
    end
end

local function MakeCommonMissileMaster(inst, damage, range)
    inst.components.projectile:SetLaunchOffset(Vector3(0,1.3,0))
    inst.components.projectile:SetHoming(true)

    inst:AddComponent("homura_acceleratingprojectile")
    inst.components.homura_acceleratingprojectile.a = 1.1

    inst:AddComponent('homura_projectile')
    inst.components.homura_projectile.infinite_range = true
    inst.components.homura_projectile.onthrown = OnThrown

    inst:AddComponent("homura_explosive")

    inst.components.explosive.explosivedamage = damage
    inst.components.explosive.explosiverange = range
    inst.components.explosive.ignorey = true

    inst:ListenForEvent("entitysleep", inst.Remove) 
end

local function MakeCommonMissileCommon(inst)
    inst:AddTag('homuraTag_rpgpro')
    inst.Transform:SetScale(0.8,0.8,0.8)
    inst.Physics:SetFriction(.8)
    inst:DoPeriodicTask(0,UpdateTail,nil,{})
end

local function missile1_master(inst) --榴弹
    MakeCommonMissileMaster(inst, HOMURA_GLOBALS.RPG.damage1, 3)
    inst.components.homura_projectile.onmaxhitsfn = OnHit
    inst.components.homura_projectile.onmissfn = OnHit
end

-- local function missile2_master(inst) --导弹
--     MakeCommonMissileMaster(inst, 500, 4)
--     inst.components.projectile:SetHoming(true)
--     inst.components.projectile:SetOnHitFn(OnHit)
--     inst.components.projectile:SetOnMissFn(OnHit)
-- end

local function onequip(inst,owner)
    owner.AnimState:OverrideSymbol("swap_object","homura_rpg","swap_rpg")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
end

local function onunequip(inst,owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end

local function OnAcceptAmmo(inst, ammo)
    if ammo and ammo.prefab == 'homura_rpg_ammo1' then
        inst.components.homura_weapon.projectile = 'homura_missile1'
    elseif ammo and ammo.prefab == 'homura_rpg_ammo2' then
        inst.components.homura_weapon.projectile = 'homura_missile2'
    end
end

local function OnLaunched(inst, attacker, target)
    inst.components.homura_weapon:OnLaunched(attacker)
end

local function launcherfn()
    local inst = CreateEntity()
    inst.entity:AddTransform() 
    local anim = inst.entity:AddAnimState() 
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    anim:SetBank("homura_rpg")
    anim:SetBuild("homura_rpg")
    anim:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    --MakeInventoryFloatable(inst, "idle_water", "idle")
    inst.Transform:SetScale(1.1,1.1,1.1)

    inst:AddTag('_named')
    inst.projectiledelay = FRAMES
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:RemoveTag('_named')

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("homura_rpg")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_rpg.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetOnProjectileLaunched(OnLaunched)

    inst:AddComponent("homura_weapon")
    inst.components.homura_weapon.projectile = 'homura_missile1'
    inst.components.homura_weapon.ammo_prefabname = 'homura_rpg_ammo1'
    inst.components.homura_weapon:SetBasicParam(HOMURA_GLOBALS.RPG)
    inst.components.homura_weapon.onacceptfn = OnAcceptAmmo

    inst:AddComponent('named')

    MakeHauntableLaunch(inst)

    return inst
end

local function homura_rpg_smoke()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    trans:SetFourFaced()
    
    anim:SetBuild("homura_rpg_smoke")
    anim:SetBank("homura_rpg_smoke")
    anim:PlayAnimation("idle")

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.entity:SetCanSleep(false)

    inst:AddComponent("ignoretimemagic")
    inst.components.ignoretimemagic:Set(3)
    inst.components.ignoretimemagic:StartUpdating()

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function light_fx(proxy)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local light = inst.entity:AddLight()

    inst.Transform:SetFromProxy(proxy.GUID)

    light:Enable(true)
    light:SetRadius(.1)
    light:SetFalloff(.5)
    light:SetIntensity(.5)
    light:SetColour(0.75,0.75,0)

    inst:AddComponent("lighttweener")
    local lighttweener = inst.components.lighttweener
    lighttweener:StartTween(light, 0.5, 0.3, 0.9, nil, 2/30)
    inst:DoTaskInTime(3/30, function() 
        lighttweener:StartTween(light, 0, 0.5, 0, nil, 3/30, inst.Remove) 
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.entity:SetCanSleep(false)

    inst:AddTag("homuraTag_ignoretimemagic")
    
    return inst
end

local function homura_gun_light()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local net   = inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, light_fx)
    end

    if TheWorld.ismastersim then
        inst:DoTaskInTime(1, inst.Remove)
    end
 
    inst.entity:SetPristine()
    return inst
end

local MakeProjectile = require "homura.weapon".MakeProjectile

return MakeProjectile("homura_missile1", {
    anim = {bank = "ammo1", build = "homura_rpg", anim = "pro", onground = true},
    assets = assets,
    masterfn = missile1_master,
    commonfn = MakeCommonMissileCommon,
}),
Prefab( "common/inventory/homura_rpg" ,launcherfn,assets), 
MakeAmmo(1),--MakeAmmo(2), --homura_rpg_ammo1~2
Prefab('homura_rpg_smoke',homura_rpg_smoke, assets),
Prefab('homura_gun_light',homura_gun_light)

