local assets = {

}

local WATERGUN = HOMURA_GLOBALS.WATERGUN

local function waterdrop()
	local inst = CreateEntity()

	return inst
end

local function onthrown(inst, owner, target)
	local player = inst.components.homura_projectile.player
	if player ~= nil and player:IsValid() then
		player:AddTag("homura_watergun_user")
		local pos = player:GetPosition()
		local angle = -player.Transform:GetRotation()*DEGREES
		local center = pos + Vector3(math.cos(angle), 0, math.sin(angle))* WATERGUN.offset
		local x,y,z = center:Get()

		inst.components.wateryprotection:SpreadProtectionAtPoint(x,0,z, WATERGUN.radius+2)

		local gw = SpawnPrefab("homura_groundwater_fx")
		gw.Transform:SetPosition(x,0,z)
		gw.Transform:SetRotation(player.Transform:GetRotation())

		local num = math.random(3,4)
		for i = 1, num do
			gw:DoTaskInTime(math.random()*0.15, function()
				local fx = SpawnPrefab("weregoose_splash_med"..math.random(1,2))
				local a = i / num * 2 * PI
				local offset = Vector3(math.cos(a), 0, math.sin(a))*1.4
				fx.Transform:SetPosition(
					x + offset.x + GetRandomWithVariance(0, .1),
					0,
					z + offset.z + GetRandomWithVariance(0, .1))
			end)
		end

		for _,v in ipairs(TheSim:FindEntities(x,0,z, WATERGUN.radius+2, {"_combat", "_health"}, {"INLIMBO", "FX", "player", "playerghost"}))do
			local dist = math.sqrt(v:GetDistanceSqToPoint(pos)) - v:GetPhysicsRadius(0) - player:GetPhysicsRadius(0)
			local mult = 0
			if dist < WATERGUN.radius then
				mult = WATERGUN.damagemult
			elseif dist < WATERGUN.radius*2 then
				mult = 1
			else
				mult = 1
			end

			if v:HasTag("wall") then
				mult = mult* 0.5
			end

			if mult > 0
				and not (v.components.domesticatable and v.components.domesticatable:IsDomesticated()) 
				and v.components.combat and v.components.combat:CanBeAttacked(player) then
				v.components.combat:GetAttacked(player, WATERGUN.damage1* mult)
			end
		end

		player:RemoveTag("homura_watergun_user")
	end

	inst.components.homura_projectile.stopupdating = true
	inst:DoTaskInTime(0, inst.Remove)
end

local function waterprojectile()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	-- no animstate

	inst.entity:AddNetwork()

	MakeProjectilePhysics(inst)
	inst:AddTag("projectile")
    inst.persists = false

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(1)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(0)

	inst:AddComponent("homura_projectile")
	inst.components.homura_projectile.onthrown = onthrown

	inst:AddComponent("wateryprotection")
	inst.components.wateryprotection.extinguishheatpercent = TUNING.WATERBALLOON_EXTINGUISH_HEAT_PERCENT
    inst.components.wateryprotection.temperaturereduction = TUNING.WATERBALLOON_TEMP_REDUCTION
    inst.components.wateryprotection.witherprotectiontime = TUNING.WATERBALLOON_PROTECTION_TIME
    inst.components.wateryprotection.addwetness = 10

	-- inst.components.wateryprotection:AddIgnoreTag("player")
	inst.components.wateryprotection:AddIgnoreTag("homura_watergun_user")

	return inst
end

return Prefab("homura_waterdrop", waterdrop),
	Prefab("homura_projectile_watergun", waterprojectile)