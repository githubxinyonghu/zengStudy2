local assets = {
	Asset("ANIM", "anim/homura_book.zip"),
	Asset("ANIM", "anim/swap_homura_book_1.zip"),
	Asset("ANIM", "anim/swap_homura_book_2.zip"),

	Asset("ATLAS", "images/inventoryimages/homura_book_1.xml"),
	Asset("ATLAS", "images/inventoryimages/homura_book_2.xml"),
}

local L = HOMURA_GLOBALS.L
if L then
	STRINGS.NAMES.HOMURA_BOOK_1 = "Handbook for Primary Workbench"
	STRINGS.NAMES.HOMURA_BOOK_2 = "Handbook for Advanced Workbench"
	STRINGS.NAMES.HOMURA_BOOK_3 = "Handbook for Holographic Workbench"

	STRINGS.RECIPE_DESC.HOMURA_BOOK_1 = "Make it possible for ordinary people to use workbench."
	STRINGS.RECIPE_DESC.HOMURA_BOOK_2 = "Knowledge is deeper and more useful."

	STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_BOOK_1 = "A small handbook"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_BOOK_2 = "A small handbook"
else
	STRINGS.NAMES.HOMURA_BOOK_1 = "基础工作台操作手册"
	STRINGS.NAMES.HOMURA_BOOK_2 = "高级工作台操作手册"
	STRINGS.NAMES.HOMURA_BOOK_3 = "全息工作台操作手册"

	STRINGS.RECIPE_DESC.HOMURA_BOOK_1 = "让普通人也能学会使用工作台"
	STRINGS.RECIPE_DESC.HOMURA_BOOK_2 = "知识更深奥，也更有用"

	STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_BOOK_1 = "一本小册子"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_BOOK_2 = "知识就是力量"
end


local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("homura_book")
    inst.AnimState:SetBuild("homura_book")

	inst.Transform:SetScale(1.2, 1.2, 1.2)

    MakeInventoryFloatable(inst, "med", nil, 0.75)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

	inst:AddComponent("homura_book")

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunch(inst)

    return inst
end

local prefabs = {}
for i = 1, 3 do
	local function fn()
		local inst = commonfn()
		inst.level = i
		inst.AnimState:PlayAnimation(tostring(i))

		if inst.components.inventoryitem then
			inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_book_"..i..".xml"
		end

		return inst
	end
	table.insert(prefabs, Prefab("homura_book_"..i, fn, assets))
end

return unpack(prefabs)

