local L = HOMURA_GLOBALS.L 
-- STRINGS.NAMES.HOMURA_GUNPOWDER = L and "Smokeless powder" or "无烟火药"
-- STRINGS.NAMES.HOMURA_GUNPOWDER_RECIPETAB = STRINGS.NAMES.HOMURA_GUNPOWDER
-- STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_GUNPOWDER = L and "I can't craft ammos and bombs without it." or "没了它，我就制作不出炸药和子弹。"
-- STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_GUNPOWDER = L and "A heap of fine powder." or '一堆细碎的粉末。'
-- STRINGS.RECIPE_DESC.HOMURA_GUNPOWDER_1 = L and "Safer and more reliable." or "更安全，更可靠。"
-- STRINGS.RECIPE_DESC.HOMURA_GUNPOWDER_2 = L and "A lame joke." or "火药饼里当然也有火药。"

-- override

STRINGS.NAMES.HOMURA_GUNPOWDER = STRINGS.NAMES.GUNPOWDER
STRINGS.RECIPE_DESC.HOMURA_GUNPOWDER = L and "Gunpowder from Powcake" or "火药饼里当然有火药"

local assets = {
	Asset("ANIM", "anim/homura_gunpowder.zip"),
	Asset("ATLAS", "images/inventoryimages/homura_gunpowder.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("homura_gunpowder")
    inst.AnimState:SetBuild("homura_gunpowder")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetScale(1.5,1.5,1)

    inst:AddTag("molebait")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_gunpowder.xml"
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("bait")

    MakeHauntableLaunch(inst)

    return inst
end

-- rollback at 2022.3.25
local function fn()
    return SpawnPrefab("gunpowder")
end

return Prefab("homura_gunpowder", fn, assets)