local L = HOMURA_GLOBALS.L
STRINGS.NAMES.HOMURA_STICKBANG = L and "Stick bomb" or "刺突爆雷"
STRINGS.CHARACTERS.GENERIC.HOMURA_STICKBANG = L and "Looks like a toilet plunger." or "看着像个马桶搋子"
STRINGS.RECIPE_DESC.HOMURA_STICKBANG = L and "Rush!" or "冲锋陷阵！"

STRINGS.NAMES.HOMURA_STICKBANG_RUSH = L and "BanZai!" or "板载!"

local assets = {
	Asset("ANIM", "anim/homura_stickbang.zip"),
	Asset("ATLAS", "images/inventoryimages/homura_stickbang.xml"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "homura_stickbang", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function getdist(center, v)
	local r = v:GetPhysicsRadius(0)
	return math.sqrt(DistXZSq(center, v:GetPosition())) - r
end

local function BitAND(a,b) local p,c=1,0 while a>0 and b>0 do local ra,rb=a%2,b%2 if ra+rb>1 then c=c+p end a,b,p=(a-ra)/2,(b-rb)/2,p*2 end return c end

local function CheckCollide(owner, v)
	if owner:IsValid() and owner.Physics  and owner.Physics:IsActive()
        and v:IsValid() and v.Physics and v.Physics:IsActive() then
        if v.sg ~= nil and v.sg:HasStateTag("flying") then
        	return false
        end
		local group = v.Physics:GetCollisionGroup()
		if group == COLLISION.OBSTACLES or
		    group == COLLISION.SMALLOBSTACLES or
		    group == COLLISION.CHARACTERS or
		    group == COLLISION.GIANTS then
		   	local mask = v.Physics:GetCollisionMask()
		   	if mask >= COLLISION.CHARACTERS then
		   		return BitAND(mask, COLLISION.CHARACTERS) > 0
		   	end
		end
	end
end

local function findtargets(inst, owner, checkphysics)
	local dist = HOMURA_GLOBALS.STICKBANG.offset
	local r1 = HOMURA_GLOBALS.STICKBANG.radius
	local r2 = HOMURA_GLOBALS.STICKBANG.radius_trigger

	local temp = {}
	local angle = -owner.Transform:GetRotation()*PI/180
	local pos = owner:GetPosition()
	local offset = Vector3(math.cos(angle), 0, math.sin(angle))* dist
	local center = pos + offset 
	local x,y,z = center:Get()
	for _,v in ipairs(TheSim:FindEntities(x,0,z, r1 + 4, nil, {"INLIMBO"}))do
		if v.components.workable and v.components.workable:CanBeWorked() and v.components.workable.action ~= ACTIONS.NET or
		   v.components.combat and v.components.health and not v.components.health:IsDead() and not v:HasTag("playerghost") then
			table.insert(temp, {v, getdist(center, v)})
		end
	end

	table.sort(temp, function(a, b) return a[2] < b[2] end)
	for _,v in ipairs(temp)do
		-- 检查是否有触发半径内的非玩家单位
		if v[1] ~= owner and v[2] < r2 then
			-- 冲锋时，需要检查碰撞
		   	-- 不排除队友：关闭友伤时，撞击到其他玩家也会引爆刺雷，但只对使用者造成伤害
			if checkphysics ~= true or CheckCollide(owner, v[1]) then
				return temp
			end
		end
	end
end

local function onhit(inst, owner, targets)
	local r1 = HOMURA_GLOBALS.STICKBANG.radius
	local damage = HOMURA_GLOBALS.STICKBANG.damage
	local playerdamage = HOMURA_GLOBALS.STICKBANG.playerdamage

	local hitpos = nil
	local hitowner = false
	for _,v in ipairs(targets or findtargets(inst, owner) or {})do
		if v[2] < r1 then
			local v = v[1]
			if v.components.workable and v.components.workable:CanBeWorked() and v.components.workable.action ~= ACTIONS.NET then
				hitpos = hitpos or v:GetPosition() -->
				v.components.workable:Destroy(inst)
			end
			if v:IsValid() and not v:IsInLimbo() then
				if v.components.combat and v.components.health and not v.components.health:IsDead() then
					local value = damage
					if v:HasTag("player") then
						-- 对使用者 -> 20
						-- 对其他玩家（关闭友伤） -> 0
						-- 对其他玩家（开启友伤，关闭pvp） -> 20
						-- 对其他玩家（开启pvp） -> 250
						if v == owner then
							value = playerdamage
						elseif TheNet:GetPVPEnabled() then
							value = damage
						elseif HOMURA_GLOBALS.PLAYERDMG then
							value = playerdamage
						else
							value = 0
						end
					end
					if value > 0 then
						hitpos = hitpos or v ~= owner and v:GetPosition() -->
						if v == owner then -- 对使用者的伤害单独处理，防止 hit state 被触发
							hitowner = true
						else
							v.components.combat:GetAttacked(owner, value)
						end
					end
				end
			end
		end
	end

	if hitpos then
		inst.SoundEmitter:PlaySound("lw_homura/stickbang/explode", nil, 0.75)
		inst.SoundEmitter:PlaySound("lw_homura/stickbang/fire", nil, 1)
		local smoke = SpawnPrefab("homura_stickbang_smoke")
		smoke.player = owner
		smoke.Transform:SetPosition(hitpos.x, 2, hitpos.z)
		local dirt = SpawnPrefab("groundpound_fx")
		dirt.Transform:SetScale(0.5,0.5,0.5)
		dirt.Transform:SetPosition(hitpos.x, 0, hitpos.z)

		ShakeAllCameras(CAMERASHAKE.FULL, .3, .03, 0.4, hitpos, 25)
		inst.explode = true
		inst:Remove()
		
		if hitowner then
			-- 单独施加一个伤害
			if owner.components.combat and owner.components.health and not owner.components.health:IsDead() then
				owner:PushEvent("homuraevt_stickbang_hit", {pos = hitpos})
				owner.components.combat:GetAttacked(owner, playerdamage)
			end
		end
	end
end

local function tryattack(inst, owner, checkphysics)
	if owner and TheWorld.components.homura_time_manager:IsEntityInRange(owner) then
		return false
	end

	local temp = findtargets(inst, owner, checkphysics)
	if temp ~= nil then
		onhit(inst, owner, temp)
	end
end


local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("homura_stickbang")
    inst.AnimState:SetBuild("homura_stickbang")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeHauntableLaunch(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_stickbang.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(HOMURA_GLOBALS.STICKBANG.damage)

    inst.FindTargets = findtargets
    inst.OnHit = onhit
    inst.TryAttack = tryattack

    return inst
end

return Prefab("homura_stickbang", fn, assets)