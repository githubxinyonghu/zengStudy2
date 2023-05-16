local function common_update(inst)
	if inst._parent and inst._parent:IsValid() and inst._parent:HasTag('homuraTag_blind')
		and inst._parent.replica.combat then
		local range = inst._parent.replica.combat:GetAttackRangeWithWeapon() or 1
		local weapon = inst._parent.replica.combat:GetWeapon()
		local ranged_atk = weapon and weapon:HasTag('projectile') or weapon.components.weapon.projectile
		local canhit = ranged_atk ~= nil  --使用远程武器进攻会消耗耐久
		if range then
			--canhit = 
		end
		if not inst._parent:HasTag('player') then --迫使生物移动
			range = range + 4
		end
	else
		inst:Remove()
	end
end

local function player_update(inst)
	if inst._parent and inst._parent:IsValid() and inst._parent:HasTag('homuraTag_blind')
		and inst._parent.components.health and not inst._parent.components.health:IsDead()
		and inst._parent.components.combat then

		local range = inst._parent.components.combat:GetAttackRange()
		local target = inst._parent.components.combat.target

		--local rot = inst._parent.Transform:GetRotation()*(-DEGREES)
		local radius = 0.1
		local pos = Vector3(radius, 0, 0)
		inst.Transform:SetPosition(pos:Get())

		if target ~= nil and target ~= inst then --玩家此时正锁定某个目标
			inst.lasttargettime = GetTime()
		elseif target == nil then 				 --玩家此时没有目标
			if GetTime() - inst.lasttargettime >= 1 then
				inst:AddTag('hostile')
			end
		end
	else
		inst:Remove()
	end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local net = inst.entity:AddNetwork()
	local phy = inst.entity:AddPhysics()
	RemovePhysicsColliders(inst)

	inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")
	inst:AddTag("homuraTag_ignoretimemagic")
	inst.entity:SetCanSleep(false)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent('health')
	inst.components.health:SetInvincible(true)
	inst.components.health:SetAbsorptionAmount(1)
	inst.components.health:SetAbsorptionAmountFromPlayer(1)
	inst.components.health:SetMinHealth(100)

	inst:AddComponent('combat')

	return inst
end

local function common(Sim)
	local inst = fn()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:DoPeriodicTask(0, common_update)
	return inst
end

local function SetTarget(inst, target)
	if not (target and target:IsValid()) then
		inst:Remove()
	else
		inst._parent = target
		inst.entity:SetParent(target.entity)
	end
end

local function player(Sim)
	local inst = fn()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.lasttargettime = GetTime()

	inst.SetTarget = SetTarget

	inst:DoPeriodicTask(0, player_update)

	return inst
end

local function LinkTo(inst, victim)
	inst.entity:SetParent(victim.entity)
    inst.homuraEnt_fake = victim
    -- victim.homuraEnt_fake_death = inst -- 似乎不需要反向引用

    for _,v in pairs{'monster', 'hostile', 'shadow'} do
        if victim:HasTag(v) then 
            inst:AddTag(v) 
        end
    end

    for _,v in pairs(AllPlayers)do
    	if v.components.combat then
    		if v.components.combat.target == victim then
    			v.components.combat:SetTarget(inst)
    		elseif v.components.combat.target == nil and v.components.combat:IsRecentTarget(victim) then
    			v.components.combat:SetLastTarget(inst)
    		end
    	end
    end
end

local function DeathGetPhysicsRadius(inst, ...)
	return inst.homuraEnt_fake ~= nil and 
		   inst.homuraEnt_fake:IsValid() and 
		   inst.homuraEnt_fake:GetPhysicsRadius(...)
		   or 0
end

local function death()
	local inst = fn()

	inst:AddTag('homuraTag_deathtarget')

	inst.persists = false

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.LinkTo = LinkTo
	inst.GetPhysicsRadius = DeathGetPhysicsRadius

	inst:ListenForEvent("homuraevt_timemagic_stop", inst.Remove)

	return inst
end

return Prefab('fake_target_common', common),Prefab('fake_target_player', player),Prefab('fake_target_death', death)


