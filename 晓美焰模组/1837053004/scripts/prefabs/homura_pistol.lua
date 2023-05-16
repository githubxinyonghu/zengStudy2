local DeltaAngle = require "homura.math".DeltaAngle

local assets = {
    Asset("ANIM", "anim/homura_pistol.zip"),

    Asset("SOUNDPACKAGE", "sound/lw_homura.fev"),
    Asset("SOUND", "sound/lw_homura.fsb"), 
    
    Asset("ATLAS","images/inventoryimages/homura_pistol.xml"),
    Asset("ATLAS","images/inventoryimages/homura_gun.xml"),
    Asset("ATLAS","images/inventoryimages/homura_hmg.xml"),
    Asset("ATLAS","images/inventoryimages/homura_rifle.xml"),
    Asset("ATLAS","images/inventoryimages/homura_snowpea.xml"),
    Asset("ATLAS","images/inventoryimages/homura_watergun.xml"),
    Asset("ATLAS","images/inventoryimages/homura_tr_gun.xml"),


    Asset("ATLAS","images/inventoryimages/homura_gun_ammo1.xml"),
    -- [DEPRICATED]
    -- Asset("ATLAS","images/inventoryimages/homura_gun_ammo2.xml"),
    -- Asset("ATLAS","images/inventoryimages/homura_gun_ammo3.xml"),
    -- Asset("ATLAS","images/inventoryimages/homura_ammochain.xml"),

    Asset("ANIM", "anim/player_homura_gun.zip"),

    Asset("ANIM", "anim/homura_weapon_buff.zip"),

    Asset("ANIM", "anim/lavaarena_hit_sparks_fx.zip"),
    Asset("ANIM", "anim/homura_groundwater_build.zip"),
}

local L = HOMURA_GLOBALS.LANGUAGE
local function quickset(prefab,name,desc_data,recipe)
    prefab = string.upper(prefab)
    STRINGS.NAMES[prefab] = name 
    for cha,desc in pairs(desc_data)do
        cha = string.upper(cha)
        STRINGS.CHARACTERS[cha].DESCRIBE[prefab] = desc
    end
    STRINGS.RECIPE_DESC[prefab] = recipe
end
if L then
    quickset("homura_gun_ammo1","Bullets",
        {
            generic = "Bullets for pistols and rifles",
        },"A handful of bullets.")
    -- quickset("homura_gun_ammo2","Machine gun bullets",
    --     {
    --         generic = "Bullets for machine gun",
    --     },"Bullets for machine gun")
    -- quickset("homura_gun_ammo3","Origination",
    --     {
    --         generic = "",
    --     },"Deal significant damage to witches.")
    quickset("homura_pistol","Desert eagle",
        {
            generic = "The power of this pistol cannot be underestimated"
        },"The most popular one")
    quickset("homura_gun","SCAR-L",
        {
            generic = "It reminds me of game by Bluehole."
        },"A kind of ssault rifle")
    quickset("homura_hmg","RPK74",
        {
            generic = "It't a bit heavy..."
        },"Fire suppression!")
    quickset("homura_rifle", "AWM",
        {
            generic = "I'm a sniper!",
        },"Become a sniper.")
    quickset("homura_snowpea", "SnowPea",
        {
            generic = "It gave off a chill."
        }, "Stay cool.")
    quickset("homura_tr_gun", "Starving eye", {
        generic = "Are you hungry?",
    }, "Eat and shoot.")
    quickset("homura_watergun", "\"Holiday\"",
        {
            generic = "Good position!",
        }, "An incredibly powerful water gun")

else
    quickset("homura_gun_ammo1","子弹",
        {
            generic = "可以装填各种枪支",
            homura_1 = "没有它, 我的枪就毫无威力了",
        },"biu!")
    -- quickset("homura_gun_ammo2","机枪子弹",
    --     {
    --         generic = '可以用在机枪上',
    --         homura_1 = "适用于连发型的武器",
    --     },"biu!biu!biu!")
    -- quickset("homura_gun_ammo3","起源弹",
    --     {
    --         homura_1 = "你看这子弹...这好像是隔壁剧组的子弹?",
    --     },"对魔法生物造成重创。")
    quickset("homura_pistol","沙漠之鹰",
        {
            generic = "这手枪的威力不容小觑",
            homura_1 = "只要距离不远, 我就能轻松打中目标。",
        },"最著名的一款手枪")
    quickset("homura_gun","SCAR-L",
        {
            generic = "这让我想到了蓝洞公司的一个游戏",
            homura_1 = "看起来还不错.",
        },"可靠的半自动突击步枪")
    quickset("homura_hmg","RPK74",
        {
            generic = "我一梭子下去你可能会死",
            homura_1 = "唔, 有点沉。",
        },"火力压制!")
    quickset("homura_rifle", "AWM",
        {   
            generic = "我起了，一枪秒了，有什么好说的！"
        },"当一名狙击手")
    quickset("homura_snowpea", "寒冰射手",
        {
            generic = "它散发出阵阵寒气。"
        }, "让敌人“冷静”下来")
    quickset("homura_tr_gun", "饥饿之眼",
        {
            generic = "肚子饿了吗？" ,
        }, "吃得越多，吐得越多")
    quickset("homura_watergun", "“假日”",
        {
            generic = "好位置！",
        }, "一把水枪，不知为何威力相当惊人") -- 因为鹰角策划吃错药了
end

local function CommonAmmo(num)
    local function fn()
        -- 机枪子弹更新兼容
        if num == 2 then
            return SpawnPrefab("homura_gun_ammo1")
        end
        
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local snd = inst.entity:AddSoundEmitter()
        local net   = inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, nil, 0.12, 0.9)

        anim:SetBank("ammo")
        anim:SetBuild("homura_pistol")
        anim:PlayAnimation(tostring(num))

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("homura_ammo")
        inst.projectilename = 'homura_projectile'..num

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_gun_ammo"..num..".xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        MakeHauntableLaunch(inst)

        return inst
    end
    return Prefab("homura_gun_ammo"..num,fn,assets)
end

-- local function MakeAmmoChain()
--     local inst = CreateEntity()
--     local trans= inst.entity:AddTransform()
--     local anim = inst.entity:AddAnimState()
--     local net  = inst.entity:AddNetwork()

--     anim:SetBank("ammo")
--     anim:SetBuild("homura_pistol")
--     anim:PlayAnimation("4")

--     MakeInventoryPhysics(inst)

--     inst.entity:SetPristine()
--     if not TheWorld.ismastersim then
--         return inst
--     end

--     inst:AddComponent("inspectable")

--     inst:AddComponent("inventoryitem")
--     inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_ammochain.xml"

--     return inst
-- end

local function CreateTail(colour)
    --本地特效
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    anim:SetBuild("homura_pistol")

    if colour == 20 then
        -- snow flake
        anim:SetBuild("homura_pistol")
        anim:SetBank("snowflake")
        anim:PlayAnimation(tostring(math.random(1,6)), true)
        anim:SetDeltaTimeMultiplier(GetRandomMinMax(1, 1.2))
        anim:SetFinalOffset(3)

        local scale = GetRandomMinMax(0.4, 0.6)
        anim:SetScale(scale, scale)
    else
        -- tail fx
        anim:SetBuild("homura_pistol")
        anim:SetBank("pro")
        anim:PlayAnimation("tail")
        anim:SetOrientation(ANIM_ORIENTATION.OnGround)
        anim:SetLayer(LAYER_BACKGROUND)
        anim:SetSortOrder(3)

        if colour == 1 then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            inst.AnimState:SetLightOverride(1)
            inst.AnimState:SetMultColour(1, 0.2, 0.8, 0.8)
        elseif colour == 2 then
            inst.AnimState:OverrideSymbol('tail', 'homura_pistol', 'tail_ice')
            inst.AnimState:SetMultColour(1, 1, 1, 0.3)
        elseif colour == 3 then
            inst.AnimState:SetMultColour(1, 1, 1, 0.3)
        elseif colour == 4 then
            inst.AnimState:SetMultColour(1, 1, 0.8, 0.5)
        end
    end

    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:AddComponent("colourtweener")

    inst.entity:SetCanSleep(false)
    inst.persists = false
    
    inst.components.colourtweener:StartTween({0,0,0,0}, 4*FRAMES, inst.Remove)

    return inst
end

local function UpdateTail(inst,tails)
    inst.colourID = inst.colourID or inst._tail_colour:value()
    if not(inst.colourID and inst.colourID >= 1)then
        return
    end

    if not inst.entity:IsVisible() then
        return
    end

    local pos = inst:GetPosition()
    local rot = inst.Transform:GetRotation()
    local tail = CreateTail(inst.colourID)
    tail.Transform:SetPosition(pos:Get())
    tail.Transform:SetRotation(rot)

    if inst.prefab == "homura_projectile_snowpea" then
        local var = 0.3
        tail.Transform:SetPosition((pos + Vector3(
            GetRandomMinMax(-var, var),
            GetRandomMinMax(-var, var) + 1.5,
            GetRandomMinMax(-var, var))):Get())
    elseif inst.lastpos and inst.lastrot then
        local pos2 = (pos + inst.lastpos)/2
        local rot2 = DeltaAngle(inst.lastrot,rot)/2 + inst.lastrot 
        local tail2 = CreateTail(inst.colourID, true)
        tail2.Transform:SetPosition(pos2:Get())
        tail2.Transform:SetRotation(rot2)
    end

    inst.lastpos = pos
    inst.lastrot = rot

    if inst:HasTag('homuraTag_ignoretimemagic') then
        tail:AddTag('homuraTag_ignoretimemagic')
    end
end

local function pro_common(inst)
    inst._tail_colour = net_smallbyte(inst.GUID, "homuraNet.ProjectileTail")
    inst:ListenForEvent("entitysleep", inst.Remove)
    
    inst:DoPeriodicTask(0, UpdateTail, nil, {})
end

local function pro_master(inst)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1)

    inst:AddComponent("homura_projectile")
end

-- [projectile for basic weapons]
local function pro1(inst) -- pistol
    inst.components.projectile:SetLaunchOffset(Vector3(0,1,0))
    pro_master(inst)
end

local function pro2(inst) -- gun
    inst.components.projectile:SetLaunchOffset(Vector3(1.3,1.1,0))
    pro_master(inst)
end

local function pro3(inst) -- hmg
    inst.components.projectile:SetLaunchOffset(Vector3(1.7,1,0))
    pro_master(inst)
end

local function pro4(inst) -- awm
    inst.AnimState:SetMultColour(1,1,0.5,1)
    inst.components.projectile:SetLaunchOffset(Vector3(2.3,1,0))
    pro_master(inst)
end

-- [projectile for special weapons]
local function pro_snow(inst) -- snowpea
    pro_master(inst)
    inst.components.projectile:SetLaunchOffset(Vector3(1.2, 0, 0))
    inst.components.homura_projectile.infinite_range = true
    inst.components.homura_projectile.no_miss_fx = true
end


local function pro_tr(inst) -- tr gun
    pro_master(inst)
    inst.components.projectile:SetLaunchOffset(Vector3(1, 1, 0))
    inst.components.homura_projectile.miss_fx = "spat_splash_fx_melted"
end


local function OnLaunched(inst,attacker,target)
    inst.components.homura_weapon:OnLaunched(attacker)
end

local function CommonGunFn(name, opts)
    opts = opts or {}

    local function onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object","homura_pistol",'swap_'..name)
        owner.AnimState:Show("arm_carry")
        owner.AnimState:Hide("arm_normal")
    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Hide("arm_carry")
        owner.AnimState:Show("arm_normal") 
    end

    local inst = CreateEntity()
    inst.entity:AddTransform() 
    inst.entity:AddAnimState() 
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("homura_pistol")
    inst.AnimState:SetBank(name)
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "large", 0.5, 0.6)

    inst:AddTag("_named")
    inst:AddTag("homuraTag_gun")

    inst.projectiledelay = FRAMES

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveTag("_named")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_"..name..".xml"
 
    MakeHauntableLaunch(inst)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

if opts.no_container then
    inst:AddTag("homuraTag_no_container")
else
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("homura_"..name)
    --inst.components.container.onopenfn = function(i) i.SoundEmitter:PlaySound("") end
    --inst.components.container.onclosefn = function(i) i.SoundEmitter:PlaySound("") end
end

    inst:AddComponent("weapon")
    inst.components.weapon:SetOnProjectileLaunched(OnLaunched)
    
    inst:AddComponent("homura_weapon")
    inst.components.homura_weapon.projectile = "homura_projectile_"..name
    inst.components.homura_weapon:SetBasicParam(HOMURA_GLOBALS[name:upper()])
    if opts.ammo_prefabname then
        inst.components.homura_weapon.ammo_prefabname = opts.ammo_prefabname
    end
    
    inst:AddComponent("named")
    
    return inst
end

local function PistolFn()
    local inst = CommonGunFn("pistol", {ammo_prefabname = "homura_gun_ammo1"})

    inst.components.floater:SetSize("med")

    return inst
end

local function GunFn()
    local inst = CommonGunFn("gun", {ammo_prefabname = "homura_gun_ammo1"})

    return inst
end

local function HMGFn()
    local inst = CommonGunFn("hmg", {ammo_prefabname = "homura_gun_ammo1"})
    
    inst.projectiledelay = nil

    return inst
end

local function SnowFn()
    local inst = CommonGunFn("snowpea", {ammo_prefabname = "ice", crossover = true})

    inst.AnimState:PlayAnimation("idle", true)
    
    return inst
end

local function TRFn()
    local inst = CommonGunFn("tr_gun", {crossover = true})

    return inst
end

local function OnFill(inst, from_object)
    if from_object ~= nil
        and from_object.components.watersource ~= nil
        and from_object.components.watersource.override_fill_uses ~= nil then

        inst.components.homura_weapon:Fill(from_object.components.watersource.override_fill_uses*4)
    else
        inst.components.homura_weapon:SetPercent(1)
    end
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/emerge/small")
    return true
end

local function WaterGun()
    local inst = CommonGunFn("watergun", {crossover = true})

    inst:AddTag("extinguisher")

    if TheWorld.ismastersim then
        inst:AddComponent("fillable")
        inst.components.fillable.overrideonfillfn = OnFill
        inst.components.fillable.showoceanaction = true
        inst.components.fillable.acceptsoceanwater = true
    end

    return inst
end

local function OnBuilt(inst)
    if inst.components.container then
        if next(inst.components.container:GetItemByName("homura_weapon_buff_eye_lens", 1)) == nil then
            inst.components.container:GiveItem(SpawnPrefab("homura_weapon_buff_eye_lens"), 1)
        end
    end
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 8, 4, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function RifleFn()
    local inst = CommonGunFn("rifle", {ammo_prefabname = "homura_gun_ammo1"})

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    if TheWorld.ismastersim then
        inst.OnBuilt = OnBuilt
        inst:DoTaskInTime(0, OnBuilt)

        if inst.components.container then
            local old_drop = inst.components.container.DropEverything
            function inst.components.container:DropEverything(drop_pos, ...)
                for k,v in pairs(self.slots) do
                    if v.prefab == "homura_weapon_buff_eye_lens" then
                        v:Remove()
                    end
                end
                return old_drop(self, drop_pos, ...)
            end
        end
    end

    return inst
end

local function MissAnim(proxy)
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

    inst.AnimState:SetBank("hits_sparks")
    inst.AnimState:SetBuild("lavaarena_hit_sparks_fx")
    inst.AnimState:PlayAnimation("hit_"..math.random(5))
    -- inst.AnimState:Hide("glow")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetMultColour(1, 1, 0.5, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)
    if math.random() < 0.5 then
        inst.AnimState:SetScale(-1, 1)
    end

    inst.SoundEmitter:PlaySound("lw_homura/sfx/miss"..math.random(2), nil, 0.4)

    inst:ListenForEvent("animover", inst.Remove)
end

local function GroundWaterAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)
    inst.Transform:SetScale(1.8, 1.8, 1.8)

    local colour = {.5, .5, 1}
    local alpha = .5

    inst.AnimState:SetBank("squid_puddle")
    inst.AnimState:SetBuild("homura_groundwater_build")
    inst.AnimState:PlayAnimation("puddle_wet")
    inst.AnimState:SetMultColour(colour[1]*alpha, colour[2]*alpha, colour[3]*alpha, alpha)
    inst.AnimState:SetFinalOffset(1)

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    -- inst.SoundEmitter:PlaySound("lw_homura/sfx/miss"..math.random(2), nil, 0.4)

    inst:ListenForEvent("animover", inst.Remove)
end

local function MakeSimpleFx(fx, time)
    local function fn()
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local net   = inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("NOBLOCK")

        if not TheNet:IsDedicated() then
            inst:DoTaskInTime(0, fx)
        end

        inst:DoTaskInTime(time or 1, inst.Remove)
     
        inst.entity:SetPristine()
        return inst
    end

    return fn
end




local MakeProjectile = require "homura.weapon".MakeProjectile

return 
MakeProjectile("homura_projectile_pistol", {
    anim = {bank = "pro", build = "homura_pistol", anim = "anim", onground = true},
    assets = assets,
    masterfn = pro1,
    commonfn = pro_common,
}),
MakeProjectile("homura_projectile_gun", {
    anim = {bank = "pro", build = "homura_pistol", anim = "anim", onground = true},
    assets = assets,
    masterfn = pro2,
    commonfn = pro_common,
}),
MakeProjectile("homura_projectile_hmg", {
    anim = {bank = "pro", build = "homura_pistol", anim = "anim", onground = true},
    assets = assets,
    masterfn = pro3,
    commonfn = pro_common,
}),
MakeProjectile("homura_projectile_rifle", {
    anim = {bank = "pro", build = "homura_pistol", anim = "anim", onground = true},
    assets = assets,
    masterfn = pro4,
    commonfn = pro_common,
}),
MakeProjectile("homura_projectile_snowpea", {
    anim = {bank = "snowpea", build = "homura_pistol", anim = "pro", onground = false},
    assets = assets,
    masterfn = pro_snow,
    commonfn = function(inst)
        pro_common(inst)
        inst.Transform:SetEightFaced()
    end,
}),
MakeProjectile("homura_projectile_tr_gun", {
    anim = {bank = "spat_bomb", build = "spat_bomb", anim = "spin_loop"},
    assets = assets,
    masterfn = pro_tr,
    commonfn = pro_common,
}),

Prefab("homura_pistol", PistolFn,assets),
Prefab("homura_gun", GunFn,assets),
Prefab("homura_hmg", HMGFn,assets),
Prefab("homura_rifle", RifleFn,assets),
Prefab("homura_snowpea", SnowFn, assets),
Prefab("homura_tr_gun", TRFn, assets),
Prefab("homura_watergun", WaterGun, assets),

CommonAmmo(1),CommonAmmo(2),CommonAmmo(3), --homura_gun_ammo1~3
Prefab("homura_miss_fx", MakeSimpleFx(MissAnim), assets),
Prefab("homura_groundwater_fx", MakeSimpleFx(GroundWaterAnim), assets)

