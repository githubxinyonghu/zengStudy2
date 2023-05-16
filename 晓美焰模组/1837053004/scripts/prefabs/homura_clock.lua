local L = HOMURA_GLOBALS.LANGUAGE
STRINGS.NAMES.HOMURA_CLOCK = L and "Pocket watch" or "精致的怀表"
STRINGS.RECIPE_DESC.HOMURA_CLOCK = L and "Help you manage the time." or "拥有你自己的时间"
STRINGS.CHARACTERS.GENERIC.HOMURA_CLOCK = L and "The inside of this watch must be very complicated." or "这块表的内部构造一定非常复杂"
STRINGS.CHARACTERS.HOMURA_1.HOMURA_CLOCK = L and "Take this watch and you will not be affected by my magic." or "带上这块表，就不会受我的魔法影响。"

local assets = {
    Asset("ANIM", "anim/homura_clock.zip"),
    Asset("ATLAS", "images/inventoryimages/homura_clock.xml"),
}

local function CheckOwnerTime(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if not owner and inst.usetask ~= nil then
        inst.usetask:Cancel()
        inst.usetask = nil
        return
    end
    if not owner:HasTag("homura") and owner.components.locomotor
        and TheWorld.components.homura_time_manager:IsEntityInRange(owner) then
        inst.components.finiteuses:Use()
    end
end

local function OnPutInInv(inst)
    if not inst.usetask then
        inst.usetask = inst:DoPeriodicTask(1, CheckOwnerTime)
    end
end

local function clock()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local net   = inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    anim:SetBuild("homura_clock")
    anim:SetBank("homura_clock")
    anim:PlayAnimation("anim")

    inst:AddTag("irreplacable")
    -- inst:AddTag("homuraTag_invanim")--@--
    inst:AddTag("homuraTag_ignoretimemagic")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    MakeHauntableLaunch(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(400)
    inst.components.finiteuses:SetUses(400)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.usetask = inst:DoPeriodicTask(1, CheckOwnerTime)

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 1

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_clock.xml"
    inst:ListenForEvent("onputininventory", OnPutInInv)

    return inst
end

return Prefab("homura_clock", clock, assets)