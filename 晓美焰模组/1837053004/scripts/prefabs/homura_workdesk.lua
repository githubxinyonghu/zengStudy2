local L = HOMURA_GLOBALS.LANGUAGE 

STRINGS.NAMES.HOMURA_WORKDESK_1 = L and "Primary thermal weapon workbench" or "基础武器工作台"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_WORKDESK_1 = L and "I can make thermal weapons here." or "我可以制造热武器了。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_WORKDESK_1 = L and "It looks modern!" or "这个研究站看起来好高级啊!"
STRINGS.RECIPE_DESC.HOMURA_WORKDESK_1 = L and "Modern weapon technology." or "研制现代热武器!"

STRINGS.NAMES.HOMURA_WORKDESK_2 = L and "Advanced thermal weapon workbench" or "高级武器工作台"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_WORKDESK_2 = L and "Why did I put two monitors on it?" or "我为什么要给它装两个显示屏..."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_WORKDESK_2 = L and "It looks modern!!" or "这个研究站看起来好高级啊!!"
STRINGS.RECIPE_DESC.HOMURA_WORKDESK_2 = L and "State-of-the-art thermal weapons technology" or "最尖端的热武器科技站"

STRINGS.NAMES.HOMURA_WORKDESK_3 = L and "Holographic thermal weapon workbench" or "全息武器工作台"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_WORKDESK_3 = L and "The special resources from this world constitute its projection system." or "永恒大陆的特殊资源构成了它的投影系统。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_WORKDESK_3 = L and "It looks modern!!!" or "这个研究站看起来好高级啊!!!"
STRINGS.RECIPE_DESC.HOMURA_WORKDESK_3 = L and "Extremely portable, essential for outdoor operations" or "极致便携，野外行动必备"

STRINGS.NAMES.HOMURA_WRENCH = L and "Tech wrench" or "高科技的扳手"
STRINGS.CHARACTERS.HOMURA_1.DESCRIBE.HOMURA_WRENCH = L and "This widget allows me to craft more weapons from my workbench." or "这个小工具让我能在工作台上制造更多的武器"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOMURA_WRENCH = L and "A useful wrench." or "一个精致的小扳手"
STRINGS.RECIPE_DESC.HOMURA_WRENCH = L and "Right hand of the thermal weapon engineer" or "热武器装配师的得力助手"

require "prefabutil"

local assets = {
	Asset("ANIM", "anim/homura_workdesk_1.zip"),
	Asset("ANIM", "anim/homura_workdesk_2.zip"),
	-- Asset("ANIM", "anim/homura_workdesk3.zip"),

	Asset("ATLAS", "images/inventoryimages/homura_workdesk_1.xml"),
	Asset("ATLAS", "images/map_icons/homura_workdesk_1.xml"),
	Asset("ATLAS", "images/inventoryimages/homura_workdesk_2.xml"),
	Asset("ATLAS", "images/map_icons/homura_workdesk_2.xml"),
}

local function dropitems(inst)
    for i,k in ipairs(inst.components.craftingstation:GetItems()) do
        inst.components.lootdropper:SpawnLootPrefab(k)
    end
end

local function onhammered(inst, worker)
	dropitems(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    if inst.prefab == "homura_workdesk_1" then
    	fx:SetMaterial("wood")
    else
    	fx:SetMaterial("metal")
    end
    inst:Remove()
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function sketch(inst, item)
	if item and item:HasTag("homura_sketch") then
		if inst.components.craftingstation:KnowsItem(item.prefab) then
			return false, "HAS"
		else
			inst.components.craftingstation:LearnItem(item.prefab, item.recipename)
			inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/moonstaff_place")
			item:Remove()
			return true
		end
	end
	return false
end

local function onhit(inst, worker)
	--inst.AnimState:PlayAnimation("hit")
	--inst.AnimState:PushAnimation(inst.on and "proximity_loop" or "idle", true)
end

local function onturnon(inst)
	inst.AnimState:PlayAnimation("loop_pre")
	inst.AnimState:PushAnimation("loop_loop")
	if inst.prefab == "homura_workdesk_2" then
		inst.SoundEmitter:PlaySound("lw_homura/sfx/workdesk2_on", nil, 0.5)
		inst.Light:Enable(true)
		inst.components.lighttweener:StartTween(nil, 2, nil, nil, nil, 0.2) 
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_idle_LP", "idlesound")
end

local function onturnoff(inst)
    inst.AnimState:PlayAnimation("loop_pst")
    inst.AnimState:PushAnimation("idle",false)
    if inst.prefab == "homura_workdesk_2" then
    	inst.SoundEmitter:PlaySound('lw_homura/sfx/workdesk2_off', nil, 0.6)
    	inst.components.lighttweener:StartTween(nil, 0, nil, nil, nil, 0.2, function(inst) inst.Light:Enable(false) end)
    end
	inst.SoundEmitter:KillSound("idlesound")
end

local function createmachine()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local minimap = inst.entity:AddMiniMapEntity()
	local light = inst.entity:AddLight()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	light:Enable(false)
	light:SetRadius(.6)
	light:SetFalloff(.5)
	light:SetIntensity(.5)
	light:SetColour(0.25,0.25,1)

	minimap:SetPriority( 5 )    

	MakeObstaclePhysics(inst, .4)

	local s = 1.2
	trans:SetScale(s,s,s)
    
	inst:AddTag("homura_prototyper")
	inst:AddTag("homura_workdesk")
    inst:AddTag("structure")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
    	return inst
	end
		
	inst:AddComponent("inspectable")

	inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff

    inst:AddComponent("craftingstation")

	inst:AddComponent("lighttweener")
	inst.components.lighttweener:StartTween(light, 1, .9, 0.9, {0.25,0.25,1}, 0, function(inst)inst.Light:Enable(false)end)

	-- inst:ListenForEvent( "onbuilt", function()
	-- 	anim:PlayAnimation("place")
	-- 	anim:PlayAnimation("loop_pre")
	-- 	anim:PushAnimation("loop_loop", true)				
	-- end)

	inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(6)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.level = 1

	inst.OnSave = onsave
	inst.OnLoad = onload
	inst.AddSketch = sketch

	inst:ListenForEvent("ondeconstructstructure", dropitems)
	
 	--MakeLargeBurnable(inst, nil, nil, true)
    --MakeLargePropagator(inst)

	MakeSnowCovered(inst, .01)
	return inst
end

local function primary()
	local inst = createmachine()

	inst.AnimState:SetBank("homura_workdesk_1")
	inst.AnimState:SetBuild("homura_workdesk_1")
	inst.AnimState:PlayAnimation("idle")

	inst.prefab = "homura_workdesk_1"
	inst.level = 1
	inst.MiniMapEntity:SetIcon("homura_workdesk_1.tex")

	if inst.components.prototyper then
	    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.HOMURA_TECH_ONE
	end

	return inst
end

local function advanced()
	local inst = createmachine()

	inst.AnimState:SetBank("homura_workdesk_2")
	inst.AnimState:SetBuild("homura_workdesk_2")
	inst.AnimState:PlayAnimation("idle")

	inst.prefab = "homura_workdesk_2"
	inst.level = 2
	inst.MiniMapEntity:SetIcon("homura_workdesk_2.tex")

	if inst.components.prototyper then
	    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.HOMURA_TECH_THREE
	end

	if TheWorld.components.homura_boxloot then
		TheWorld.components.homura_boxloot:RegisterWorkdesk2(inst)
	end

	return inst
end

local wrenchassets = 
{
    Asset("ANIM","anim/homura_wrench.zip"),
    Asset("ATLAS","images/inventoryimages/homura_wrench.xml"),
}

local function wrench()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local net   = inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.12, 0.7)

    anim:SetBank("homura_wrench")
    anim:SetBuild("homura_wrench")
    anim:PlayAnimation("anim")

    trans:SetScale(.8,.8,.8)

    inst:AddTag("irreplacable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeHauntableLaunch(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_wrench.xml"

    return inst
end

local function workdesk_backward()
	return SpawnPrefab("homura_workdesk_1")
end

return Prefab("homura_workdesk", workdesk_backward), -- for old save compatible
	Prefab("homura_workdesk_1", primary, assets),
	Prefab("homura_workdesk_2", advanced, assets),
	MakePlacer("homura_workdesk_1_placer", "homura_workdesk_1", "homura_workdesk_1", "idle"),
	MakePlacer("homura_workdesk_2_placer", "homura_workdesk_2", "homura_workdesk_2", "idle"),

	Prefab("homura_wrench", wrench, wrenchassets)

