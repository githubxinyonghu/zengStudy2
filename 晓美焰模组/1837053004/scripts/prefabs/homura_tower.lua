-- 晓美焰mod玩到后期，有一个很大的不爽点: 子弹的耗材
-- 为此，我决定添加一个免费获取弹药的机制
-- 它的建造成本很高，获取效率也很低，但可以白嫖

require "prefabutil"

local L = HOMURA_GLOBALS.LANGUAGE
STRINGS.NAMES.HOMURA_TOWER_1 = L and "Reinforcement Beacon" or "支援信标"
STRINGS.RECIPE_DESC.HOMURA_TOWER_1 = L and "Send a signal for supplies." or "发送信号请求物资援助"
STRINGS.RECIPE_DESC.HOMURA_TOWER_2 = L and "Improved with ancient technology, the signal is more stable." or "用远古科技改良，信号更稳定"
STRINGS.RECIPE_DESC.HOMURA_TOWER_3 = L and "Top-of-the-line beacon with a long recharge time but luxury dirdrops." or "最顶级的信标，充能时间较长但空投物资豪华"

STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_TOWER_1 = L and "Where did the building call for an airdrop come from?" or "这座塔呼叫的空投是从哪里来的呢？"

STRINGS.NAMES.HOMURA_TOWER_1_READY = L and "Reinforcement is ready" or "空投物资已就绪"
 
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_TOWER_2 = STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_TOWER_1
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_TOWER_3 = STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_TOWER_1

STRINGS.NAMES.HOMURA_TOWER_2 = STRINGS.NAMES.HOMURA_TOWER_1.." Pro"
STRINGS.NAMES.HOMURA_TOWER_3 = STRINGS.NAMES.HOMURA_TOWER_1.." Pro Max"

-- STRINGS.NAMES.HOMURA_TOWER_2_UPGRADE = L and "Upgrade Beacon" or "升级设施"
-- STRINGS.RECIPE_DESC.HOMURA_TOWER_2_UPGRADE = L and "Double the time it takes to charge the beacon, but the airdrop will be richer." or "信标充能时间翻倍，但空投中的物资也会更丰富"
-- STRINGS.NAMES.HOMURA_TOWER_3_UPGRADE = L and "Upgrade Beacon Again" or "再次升级设施"
-- STRINGS.RECIPE_DESC.HOMURA_TOWER_3_UPGRADE = L and "The last time this beacon upgraded was last time" or "上次升级这个信标还是在上次"

local assets = 

{
    Asset("ANIM", "anim/homura_tower.zip"),       
    Asset("ANIM", "anim/homura_tower_fx.zip"),

    Asset("ANIM", "anim/homura_tower_electric.zip"), 

    Asset("ATLAS", "images/inventoryimages/homura_tower_1.xml"),      
    Asset("ATLAS", "images/inventoryimages/homura_tower_2.xml"),      
    Asset("ATLAS", "images/inventoryimages/homura_tower_3.xml"),      
}

local function displaynamefn(inst)
    local name = STRINGS.NAMES[inst.prefab:upper()]
    if TheWorld.worldprefab ~= "forest" then
        return (L and "Unable to send a signal " or "无法发送信号的")..name
    end
    if inst._interfered:value() then
        return (L and "Interfered " or "受到干扰的")..name
    end
    if not inst:HasTag("homuraTag_charge") then
        return name .. "\n" .. (L and "Charging..." or "充能中..")
    else
        return (L and "Fully Charged " or "充能完毕的")..name
    end
    return name
end

local function onactivate(inst)
    inst.Light:Enable(true)
end

local function ondeactivate(inst)
    inst.Light:Enable(false)
end

local function CommonLightOn(inst)
    if inst._interfered:value() then
        inst.Light:Enable(false)
    else
        inst.Light:Enable(true)
    end
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function maketower(level)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- inst.MiniMapEntity:SetIcon("lightningrod.png")--@--

    inst.Light:Enable(true)
    inst.Light:SetRadius(1.6)
    inst.Light:SetFalloff(.6)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235/255,121/255,12/255)

    inst:AddTag("structure")

    inst._interfered = net_bool(inst.GUID, "_interfered", "_interfered")
    inst._level = net_tinybyte(inst.GUID, "_level", "_level")
    inst._ready = net_event(inst.GUID, "_ready")

    inst:ListenForEvent("_interfered", CommonLightOn)

    inst.AnimState:SetBank("homura_tower")
    inst.AnimState:SetBuild("homura_tower")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    inst.displaynamefn = displaynamefn
    -- inst:AddTag("prototyper")

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst:ListenForEvent("lightningstrike", onlightning)

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(onhammered)
    -- inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:AddComponent("craftingstation")

    -- inst:AddComponent("prototyper")

    inst:AddComponent("homura_reinforcement")
    inst.components.homura_reinforcement.onactivate = onactivate
    inst.components.homura_reinforcement.ondeactivate = ondeactivate

    MakeSnowCovered(inst)

    -- inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

local function SwitchLight(inst)
    inst.lighton = not inst.lighton
    if inst.lighton and not inst._interfered:value() then
        inst.AnimState:ShowSymbol("light")
        inst.Light:SetIntensity(.5)
    else
        inst.AnimState:HideSymbol("light")
        inst.Light:SetIntensity(0)
    end

    inst:DoTaskInTime(inst:HasTag("homuraTag_charge") and 0.5 
        or inst.lighton and 1 or 3, SwitchLight)
end

local function tower1()
    local inst = maketower()
    inst.AnimState:PlayAnimation("1")
    inst.Light:SetFalloff(.8)

    inst:DoTaskInTime(0, SwitchLight)

    if TheWorld.ismastersim then
        inst.components.homura_reinforcement.maxlevel = 1
        inst.components.craftingstation:LearnItem("none", "homura_tower_2_upgrade")
        inst.components.homura_reinforcement:Register()
    end

    return inst
end

local function tower2()
    local inst = maketower()
    inst.AnimState:PlayAnimation("2")

    inst.Light:SetColour(1, .8, .2)

    inst:ListenForEvent("_level", function(inst)
        if inst._level:value() >= 2 then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        else
            inst.AnimState:ClearBloomEffectHandle()
        end
    end)

    if TheWorld.ismastersim then
        inst.components.craftingstation:LearnItem("none", "homura_tower_3_upgrade")
        inst.components.homura_reinforcement.maxlevel = 2
        inst.components.homura_reinforcement:Register()
    end

    return inst
end

local function electric()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    anim:SetBank("homura_tower_electric")
    anim:SetBuild("homura_tower_electric")
    anim:PlayAnimation("1", true)
    anim:SetLightOverride(.5)
    anim:SetBloomEffectHandle("shaders/anim.ksh")
    anim:SetLayer(LAYER_BACKGROUND)

    inst:AddTag("FX")
    inst.persists = false

    return inst
end

local function tower3()
    local inst = maketower()
    inst.AnimState:PlayAnimation("3")

    inst.Light:SetColour(.25,.25, 1)

    inst.electric = electric()
    inst.electric.entity:AddFollower():FollowSymbol(inst.GUID, "light", 0,0,0)

    inst:ListenForEvent("_level", function(inst)
        local v = inst._level:value()
        if v <= 3 and v >= 0 then
            inst.electric.AnimState:PlayAnimation(tostring(v+1), true)
            inst.Light:SetIntensity(v*0.1+.5)
            inst.Light:SetRadius(v*0.2+1.6)
        end
    end)

    inst:ListenForEvent("_interfered", function(inst)
        if inst._interfered:value() then
            inst.electric:Show()
        else
            inst.electric:Hide()
        end
    end)

    if TheWorld.ismastersim then
        -- 信号枪
        inst.components.homura_reinforcement.maxlevel = 3
        inst.components.homura_reinforcement:Register()
    end

    return inst
end

local function fx()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    inst.entity:AddNetwork()

    anim:SetBank("diviningrod_fx")
    anim:SetBuild("homura_tower_fx")
    anim:PlayAnimation("hot_loop", true)
    anim:SetScale(1.5,1.5)
    anim:SetLightOverride(.5)
    anim:SetMultColour(.6,.6,.6,.6)

    inst:AddTag("FX")
    inst.persists = false

    inst:AddComponent("colourtweener")

    inst:DoTaskInTime(2, function(inst)
        inst.components.colourtweener:StartTween({0,0,0,0}, 1)
    end)

    inst:DoTaskInTime(3, function(inst)
        if TheWorld.ismastersim then
            inst:Remove()
        end
    end)

    return inst
end

-- local function MakeRecipeItem(name)
--     local function fn()
--         local inst = CreateEntity()
--         inst.entity:AddNetwork()
--         inst.entity:AddTransform()

--         inst.entity:SetPristine()
--         if not TheWorld.ismastersim then
--             return inst
--         end

--         inst:DoTaskInTime(0, inst.Remove)
--         inst.persists = false

--         inst:AddComponent("inventoryitem")

--         return inst
--     end

--     return Prefab(name, fn)
-- end

return Prefab("homura_tower_1", tower1, assets),
	Prefab("homura_tower_2", tower2, assets),
	Prefab("homura_tower_3", tower3, assets),
    MakePlacer("homura_tower_1_placer", "homura_tower", "homura_tower", "1"),
    MakePlacer("homura_tower_2_placer", "homura_tower", "homura_tower", "2"),
    MakePlacer("homura_tower_3_placer", "homura_tower", "homura_tower", "3"),

    Prefab("homura_tower_fx", fx, assets),
    Prefab("homura_tower_electric", electric, assets)
    -- MakeRecipeItem("homura_tower_2_upgrade"),
    -- MakeRecipeItem("homura_tower_3_upgrade")



