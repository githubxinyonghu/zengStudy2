local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddLight()

	inst.Light:SetColour(.4, .1, 1.0)
	inst.Light:SetRadius(2)
	inst.Light:SetFalloff(.5)
	inst.Light:SetIntensity(.75)

	inst.persists = false
	inst:AddTag("FX")
	inst:AddTag("playerlight")

	inst.entity:SetPristine()

	return inst
end

return Prefab("homura_bow_light", fn)