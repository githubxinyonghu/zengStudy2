local assets = {
	Asset("ANIM", "anim/homura_box.zip"),
	Asset("ANIM", "anim/balloon_shapes2.zip"),
	Asset("ATLAS", "images/map_icons/homura_box.xml"),
}
--@-- todo 修复水上漂浮贴图
local L = HOMURA_GLOBALS.LANGUAGE
STRINGS.NAMES.HOMURA_BOX = L and "Airdop box" or "空投箱"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_BOX = L and "A gift from outer space." or "一件天外来客"

local function OnUpdate(inst, dt)
	inst.etime = inst.etime + dt
	if inst.etime > 0 then
		inst:Show()
	end

	if inst.etime >= inst.maxtime then
		inst.Transform:SetPosition(inst.targetpos:Get())
		inst.dropping = false
		inst.AnimState:ShowSymbol("shadow")
		-- inst.DynamicShadow:Enable(true)
		inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
		inst.shadow:Remove()
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdate)
		return
	end

	local p = inst.etime / inst.maxtime
	local pos = inst.targetpos * p + inst.startpos * (1 - p)
	inst.Transform:SetPosition(pos:Get())

	local a = Lerp(.3, 1, p)
	inst.shadow.Transform:SetPosition(pos.x, 0, pos.z)
	inst.shadow.AnimState:SetMultColour(a,a,a,a)
end

local function Drop(inst, targetpos)
	inst.AnimState:HideSymbol("shadow")

	targetpos = targetpos or inst:GetPosition()

	local dir = math.random()*2*PI
	local speed = Vector3(math.cos(dir), -5, math.sin(dir))
	local startpos = targetpos + speed * -2

	local fx = SpawnPrefab("pocketwatch_portal_exit_fx")
	fx.Transform:SetPosition(startpos:Get())

	local shadow = SpawnPrefab("warningshadow")
	shadow.Transform:SetPosition(startpos.x, 0, startpos.z)
	shadow.AnimState:SetMultColour(.3,.3,.3,.3)
	inst.shadow = shadow

	inst:Hide()

	inst.startpos = startpos
	inst.targetpos = targetpos
	inst.etime = -0.5
	inst.maxtime = GetRandomMinMax(8,12)
	inst.dropping = true

	inst.components.updatelooper:AddOnUpdateFn(OnUpdate)
end

local function OnSave(inst, data)
	if inst.dropping then
		data.dropping = true
		data.startpos = {inst.startpos:Get()}
		data.targetpos = {inst.targetpos:Get()}
	end

	data.israre = inst.israre
end

local function OnLoad(inst, data)
	if data and data.dropping then
		if data.targetpos then
			inst:Drop(Vector3(unpack(data.targetpos)))
		else
			inst:Drop()
		end
	end

	if data.israre then
		inst:SetSSR()
	end
end

local function GiveLoot(prefab, num, container)
	local item = SpawnPrefab(prefab)
	if item == nil then
		assert(false, prefab)
	end

	if container:IsFull() then
		return
	end

	if item.components.stackable == nil then
		container:GiveItem(item)
	else
		if num <= item.components.stackable.maxsize then
			item.components.stackable:SetStackSize(num)
			container:GiveItem(item)
		else
			item.components.stackable:SetStackSize(item.components.stackable.maxsize)
			container:GiveItem(item)
			return num - item.components.stackable.maxsize
		end
	end
end

local function SetLoot(inst)
	local loot = TheWorld.components.homura_boxloot:GetNextLoot(inst.level)
	local blueprint_data = TheWorld.components.homura_boxloot:CheckPlayerLearntBlueprint()
	-- 2022.3.27 set `blueprint` to max priority
	if loot["insertblueprint"] then
		loot["insertblueprint"] = nil

		if inst.level <= 2 then
			local prefab = "homura_tower_"..(inst.level+1).."_blueprint"
			if blueprint_data[prefab] == true or math.random() < 0.1 then
				GiveLoot(prefab, 1, inst.components.container)
			end
		else
			GiveLoot("homura_sketch_random", 1, inst.components.container)
			inst:SetSSR()
		end
	else
		loot["insertblueprint"] = nil
	end

	for k,v in pairs(loot)do
		while true do
			local left = GiveLoot(k, v, inst.components.container)
			if left == nil then
				break
			else
				v = left
			end
		end

		if k == "homura_sketch_random" then
			inst:SetSSR()
		end
	end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function common(i)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local net = inst.entity:AddNetwork()

	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity():SetIcon("homura_box.tex")

	inst.nameoverride = "homura_box"

	anim:SetBank("homura_box")
	anim:SetBuild("homura_box")

	inst:AddTag("homura_box")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	MakeSmallBurnable(inst, 5, nil, false)
    MakeMediumPropagator(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst:AddComponent("updatelooper")

	inst:AddComponent("container")
	inst.components.container.canbeopened = false
	inst.components.container:WidgetSetup("homura_box_"..i)

	inst:AddComponent("lootdropper")

	inst.Drop = Drop

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.SetLoot = SetLoot

	inst.level = i

	return inst
end

local function box1()
	local inst = common(1)
	inst.AnimState:PlayAnimation("1", true)

	return inst
end

local function box2()
	local inst = common(2)
	inst.AnimState:PlayAnimation("2", true)

	return inst
end

-- the index is saved and also used as a net var on balloon_held_child
local colours =
{
	-- index 0 is no colour tint
    { 198/255,  43/255,  43/255, 1 },
    {  79/255, 153/255,  68/255, 1 },
    {  35/255, 105/255, 235/255, 1 },
    { 109/255,  50/255, 163/255, 1 },
    { 222/255, 126/255,  39/255, 1 },
    { 233/255, 208/255,  69/255, 1 },
}

local function SetSSR(inst)
	if TheWorld.ismastersim then
		inst._israre:set(true)
		inst.israre = true
	end

	local b = GetRandomItem(inst.ballons)
	if b ~= nil and b.isballon then
		b.AnimState:OverrideSymbol("balloon_"..b.index, "homura_box", "balloon_qb")
		b.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		b.AnimState:SetMultColour(unpack(colours[6]))
	end
end

local function OnRare(inst)
	if inst._israre:value() and not TheWorld.ismastersim then
		SetSSR(inst)
	end
end

local function SingleBalloon(index, overrideid)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()

	anim:SetBank("homura_box")
	anim:SetBuild("log")
	anim:PlayAnimation("3", true)
	anim:OverrideSymbol("balloon_"..index, "balloon_shapes2", "balloon_"..overrideid)

	anim:SetMultColour(unpack(colours[math.random(1,6)]))

	inst:AddTag("fx")
	inst.persists = false
	inst.isballon = true

	inst.index = index

	return inst
end

local function box3()
	local inst = common(3)
	inst.AnimState:PlayAnimation("3", true)
	inst.AnimState:HideSymbol("balloon_7")
	inst.AnimState:HideSymbol("balloon_8")
	inst.AnimState:HideSymbol("balloon_9")

	inst._israre = net_bool(inst.GUID, "_israre", "_israre")
	inst._israre:set_local(false)

	inst.ballons = {}

	local ids = PickSome(3, math.range(1, 9))
	for i = 1, 3 do
		local b = SingleBalloon(i+6, ids[i])
		inst:AddChild(b)
		table.insert(inst.ballons, b)
	end

	inst.SetSSR = SetSSR
	inst:ListenForEvent("_israre", OnRare)

	return inst
end

return Prefab("homura_box_1", box1, assets),
	Prefab("homura_box_2", box2, assets),
	Prefab("homura_box_3", box3, assets)
