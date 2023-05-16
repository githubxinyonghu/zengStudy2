local L = HOMURA_GLOBALS.LANGUAGE 
STRINGS.NAMES.HOMURA_DETONATOR = L and "Detonator" or "雷管"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_DETONATOR = L and "Core component of bombs." or "这是炸弹不可或缺的组件"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_DETONATOR = L and "It's tiny." or '很小巧'
STRINGS.RECIPE_DESC.HOMURA_DETONATOR = L and "Explode on collision." or "遇到撞击就会引爆"
-- STRINGS.RECIPE_DESC.HOMURA_DETONATOR1 = L and "Explode on collision." or "遇到撞击就会引爆"
-- STRINGS.RECIPE_DESC.HOMURA_DETONATOR2 = L and "A lame joke..." or "这是个冷笑话吗?"

local assets =
{
    Asset("ANIM", "anim/homura_detonator.zip"),
    Asset("ATLAS","images/inventoryimages/homura_detonator.xml"),
}

local prefabs =
{
    "explode_small"
}

local function OnExplodeFn(inst)
    SpawnPrefab("explode_small").Transform:SetPosition(inst:GetPosition():Get())
end

local function Explode(inst)
    if not inst.explode then
        inst.explode = true
        inst.components.explosive:OnBurnt()
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("homura_detonator")
    inst.AnimState:SetBuild("homura_detonator")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag('notarget')

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("homura_explosive")

    inst.components.explosive:SetOnExplodeFn(OnExplodeFn)
    inst.components.explosive.explosivedamage = 20
    inst.components.explosive.buildingdamage = 6
    inst.components.explosive.lightonexplode = false
    inst.components.explosive.explosiverange = 2
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_detonator.xml"

    inst:AddComponent('combat')

    -- inst:AddComponent('health')
    -- inst.components.health:SetMaxHealth(1)
    -- inst.components.health.vulnerabletopoisondamage = 1
    -- inst.components.health.canmurder = false
    -- inst.components.health.canheal = false

    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true
    
    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst) 
        if math.random() < 0.33 then Explode(inst) return true end 
    end, false, true, false)

    -- inst:ListenForEvent("death", Explode)

    return inst
end

return Prefab( "common/inventory/homura_detonator", fn, assets, prefabs) 

