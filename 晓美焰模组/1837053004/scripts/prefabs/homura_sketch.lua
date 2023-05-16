local assets =
{
    Asset("ANIM", "anim/homura_sketch.zip"),
    Asset("ATLAS", "images/inventoryimages/homura_sketch.xml"),
}

local L = HOMURA_GLOBALS.LANGUAGE
STRINGS.NAMES.HOMURA_SKETCH = L and "Design Draft of {item}" or "{item}的设计图"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_SKETCH = L and "I think it's time to place this draft on a weapon workbench." or "我得把设计图放到武器工作台上。"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_SKETCH = L and "Some weapon inspiration from another time and space... Where's my workbench?" or "来自其他时空的一些武器灵感.. 我工作台在哪？"

local function MakeSketchPrefab(name)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("homura_sketch")
        inst.AnimState:SetBuild("homura_sketch")
        inst.AnimState:PlayAnimation("idle")

        --Sneak these into pristine state for optimization
        inst:AddTag("_named")
        inst:AddTag("homura_sketch")

        -- inst.nameoverride = "homura_sketch"

        MakeInventoryFloatable(inst, "med", nil, 0.75)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_named")

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "homura_sketch"

        inst:AddComponent("named")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_sketch.xml"
        inst.components.inventoryitem.imagename = "homura_sketch"

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        inst:AddComponent("homura_sketch")

        MakeHauntableLaunch(inst)

        inst.recipename = "homura_"..name
        inst.components.named:SetName(subfmt(STRINGS.NAMES.HOMURA_SKETCH, { item = STRINGS.NAMES[string.upper(inst.recipename)]}))

        return inst
    end

    return Prefab("homura_sketch_"..name, fn, assets)
end

local prefabs = {}
local names = {
    "snowpea",
    "stickbang",
    "watergun",
    "tr_gun",
}

for _,v in ipairs(names)do
    table.insert(prefabs, MakeSketchPrefab(v))
end

local function random()
    local loot = {}
    for _,v in ipairs(names)do
        loot["homura_sketch_"..v] = 1
    end

    if TheWorld and TheWorld.components.homura_boxloot then
        for k in pairs(TheWorld.components.homura_boxloot:CheckSketchInWorld())do
            loot[k] = 0.3
        end
    end

    -- print("Loot weight:", json.encode(loot))

    return SpawnPrefab(weighted_random_choice(loot))
end

table.insert(prefabs, Prefab("homura_sketch_random", random))

return unpack(prefabs)
