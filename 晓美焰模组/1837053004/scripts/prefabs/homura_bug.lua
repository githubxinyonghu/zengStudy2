local function fn()
	local inst = SpawnPrefab("icestaff")

	if inst.components.weapon then
		inst:AddComponent("homura_weapon")
		inst.components.weapon:SetProjectile("homura_projectile_hmg")
	end
	if inst.components.finiteuses then
		inst.components.finiteuses:SetUses(99999)
		inst.components.finiteuses:SetMaxUses(99999)
	end

	return inst
end

return Prefab("homura_bug", fn)

