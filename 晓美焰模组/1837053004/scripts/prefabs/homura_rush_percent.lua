local assets = {
	Asset("ANIM", "anim/homura_cd_percent.zip"),
}

local function SetPercent(inst, p)
	if p < 0 then
		inst:Hide()
	else
		inst:Show()
	end
end

local function fn()
	local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("homura_cd_percent")
    inst.AnimState:SetBuild("homura_cd_percent")

    return inst
end

return Prefab("homura_rush_percent", fn, assets)