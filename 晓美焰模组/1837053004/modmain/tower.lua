table.insert(PrefabFiles, "homura_box")
table.insert(PrefabFiles, "homura_sketch")
table.insert(PrefabFiles, "homura_tower")

AddPrefabPostInit("world", function(inst)
	if TheWorld.ismastersim then
		inst:AddComponent("homura_boxloot")
	end
end)

