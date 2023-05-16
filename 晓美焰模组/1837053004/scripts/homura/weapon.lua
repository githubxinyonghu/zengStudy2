-- util functions about homura's weapon

local function IsGunAmmo(inst)
	return inst.prefab == "homura_gun_ammo1"
end

local function IsRPGAmmo(inst)
	return inst:HasTag("homuraTag_rpgammo")
end

local function IsIceAmmo(inst)
	return inst.prefab == "ice"
end

local function IsWater(inst)
	return inst:HasTag("watersource")
end

local function IsTRAmmo(inst)
	-- edible
end

local function GetCheckAmmoFn(item)
	if item.prefab == "homura_rpg" then
		return IsRPGAmmo
	elseif item.prefab == "homura_snowpea" then
		return IsIceAmmo
	elseif item.prefab == "homura_watergun" then
		return IsWater
	elseif item.prefab == "homura_tr_gun" then
		return IsTRAmmo
	elseif item:HasTag("homuraTag_gun") then
		return IsGunAmmo
	else
		return function() return false end
	end
end

local function MakeProjectile(prefab, data)
	-- data = {
	--     anim = {bank = "xxx", build = "xxx", anim = "xxx", onground = true},
	--     assets = { -- LIST -- },
	--     masterfn = ...,
	--     commonfn = ....,
	-- }
	
	local bank = data.anim.bank
	local build = data.anim.build
	local animation = data.anim.anim
	local onground = data.anim.onground == true

	local function fn()
	    local inst = CreateEntity()
	    local trans = inst.entity:AddTransform()
	    local anim = inst.entity:AddAnimState()
	    local sound = inst.entity:AddSoundEmitter()
	    local net = inst.entity:AddNetwork()

	    inst.prefabname = prefab

	    MakeProjectilePhysics(inst)
	    inst.Physics:SetFriction(0)
		inst.Physics:SetDamping(10)
		inst.Physics:SetRestitution(0)
    
	    anim:SetBank(bank)
	    anim:SetBuild(build)
	    anim:PlayAnimation(animation, true)
	    if onground then
	        anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	    end
    
	    inst:AddTag("projectile")
	    inst.persists = false
    
	    if data.commonfn then
	        data.commonfn(inst)
	    end

	    inst.entity:SetPristine()
	    if not TheWorld.ismastersim then
	        return inst
	    end

	    inst:AddComponent("projectile")
	    inst.components.projectile:SetSpeed(10)
	    inst.components.projectile:SetHoming(false)
	    inst.components.projectile:SetHitDist(10)
	    inst.components.projectile:SetOnHitFn(inst.Remove)
	    inst.components.projectile:SetOnMissFn(inst.Remove)
 
	    if data.masterfn then
	        data.masterfn(inst)
	    end

	    return inst
	end

    return Prefab(prefab, fn, data.assets) 
end

return {
	GetCheckAmmoFn = GetCheckAmmoFn,
	MakeProjectile = MakeProjectile,
}