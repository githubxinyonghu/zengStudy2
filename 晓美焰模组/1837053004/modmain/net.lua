local REP = {
	"homura_skill",
	"homura_lightshocked",
	"homura_reader",
	"homura_archer",
}

for _,v in ipairs(REP)do
	AddReplicableComponent(v)
end

local function OnAlphaDirty(inst)
	if inst._parent then
		inst._parent:PushEvent("homura_lightshock_alpha", {alpha = inst.homura_lightshock_alpha:value()})
	end
end

local function OnHit(inst)
	if inst._parent then
		inst._parent:PushEvent("homura_lightshock_hit")
	end
end

local function OnBadgeFn(inst)
	if inst._parent and inst._parent.replica.homura_skill then
		inst._parent.replica.homura_skill:PushBadgeFn(inst.homura_badge_fn:value())
	end
end

local function OnFocusMode(inst)
	if inst._parent then
		inst._parent:PushEvent("homura_snipemode", inst.homura_snipemode:value())

		if inst.homura_snipemode:value() == false then
			inst._parent:PushEvent("homura_exitsniping")
		end
	end
end

local function OnSnipeShoot(inst)
	if inst._parent then
		inst._parent:PushEvent("homura_snipeshoot")
	end
end

local function OnLearning(inst)
	if inst._parent then
		local data = {
			[1] = inst.homura_learning_1:value(),
			[2] = inst.homura_learning_2:value(),
			[3] = inst.homura_learning_3:value(),
		}
		local i = inst.homura_currentlearning:value()
		data.percent = data[i] or nil
		inst._parent:PushEvent("homura_learning_percent", data)
	end
end

local function OnCurrentLearning(inst)
	if inst._parent then
		if inst.homura_currentlearning:value() == 0 then
			inst._parent:PushEvent("homura_stoplearning")
		else
			inst._parent:PushEvent("homura_startlearning")
		end
	end
end

local function OnArcherCharge(inst)
	if inst._parent then
		inst._parent:PushEvent("homuraevt_barpercent", {percent = inst.homura_archer_charge:value()})
		-- if inst.homura_archer_charge:value() > 0 then
		-- 	inst._parent:PushEvent("homuraevt_barstyle", {style = inst._parent:HasTag("homura") and "magic" or "charge"})
		-- else
		-- 	inst._parent:PushEvent("homuraevt_barstyle", {style = "hidden"})
		-- end
	end
end

local function OnTowerReady(inst)
	if inst._parent and inst._parent == ThePlayer then
	    if ChatHistory ~= nil then
	        ChatHistory:AddToHistory(ChatTypes.SystemMessage, nil, nil, STRINGS.NAMES.HOMURA_TOWER_1, STRINGS.NAMES.HOMURA_TOWER_1_READY, TWITCH_COLOR)
	    end
	end
end

local function RegisterNetListeners(inst)
	inst:DoTaskInTime(0, function()	
		inst:ListenForEvent("homura_lightshock_alpha", OnAlphaDirty)
		inst:ListenForEvent("homura_lightshock_hit", OnHit)
		inst:ListenForEvent("homura_snipemode", OnFocusMode)
		inst:ListenForEvent("homura_snipeshoot", OnSnipeShoot)
		-- inst:ListenForEvent("homura_rush", OnRush) -- read only
		inst:ListenForEvent("homura_learning", OnLearning)
		inst:ListenForEvent("homura_currentlearning", OnCurrentLearning)
		inst:ListenForEvent("homura_archer_charge", OnArcherCharge)
		inst:ListenForEvent("homura_tower_ready", OnTowerReady)
		if not TheWorld.ismastersim then
			inst:ListenForEvent("homura_badge_fn", OnBadgeFn)
			-- inst:ListenForEvent("homura_skill_on", OnSkill)
		end
	end)
end

AddPrefabPostInit("player_classified", function(inst)
	-- Netvars 
	local GUID = inst.GUID

	-- For homura 
	inst.homura_skill_lefttime = net_float(GUID, "homura_skill_lefttime")
	inst.homura_skill_cooldown = net_float(GUID, "homura_skill_cooldown")
	-- inst.homura_skill_on = net_bool(GUID, "homura_skill_on", "homura_skill_on")
	inst.homura_skill_lefttime:set_local(0)
	inst.homura_skill_cooldown:set_local(0)
	-- inst.homura_skill_on:set_local(false)

	inst.homura_badge_fn = net_tinybyte(GUID, "homura_badge_fn", "homura_badge_fn")
	inst.homura_badge_fn:set_local(0)

	-- 2021.6.1
	inst.homura_gunpowder_crafting_mode = net_tinybyte(inst.GUID, 'homura_detonator_crafting_mode')
	inst.homura_gunpowder_crafting_mode:set_local(1)

	-- For all players
	inst.homura_lightshock_alpha = net_float(GUID, "homura_lightshock_alpha", "homura_lightshock_alpha")
	inst.homura_lightshock_alpha:set_local(0)
	inst.homura_lightshock_hit = net_event(GUID, "homura_lightshock_hit")

	-- 2021.7.1
	-- Focus system
	inst.homura_snipemode = net_bool(GUID, "homura_snipemode", "homura_snipemode")
	inst.homura_snipemode:set_local(false)
	inst.homura_snipeshoot = net_event(GUID, "homura_snipeshoot", "homura_snipeshoot")

	-- 2021.11.1
	-- Rusher
	inst.homura_rush = net_bool(GUID, "homura_rush", "homura_rush")
	inst.homura_rush:set_local(false)

	-- 2021.12.25
	-- Learner
	inst.homura_learning_1 = net_float(GUID, "homura_learning_1", "homura_learning")
	inst.homura_learning_1:set_local(0)
	inst.homura_learning_2 = net_float(GUID, "homura_learning_2", "homura_learning")
	inst.homura_learning_2:set_local(0)
	inst.homura_learning_3 = net_float(GUID, "homura_learning_3", "homura_learning")
	inst.homura_learning_3:set_local(0)
	inst.homura_currentlearning = net_byte(GUID, "homura_currentlearning", "homura_currentlearning")
	inst.homura_currentlearning:set_local(0)

	-- Archer
	inst.homura_archer_charge = net_float(GUID, "homura_archer_charge", "homura_archer_charge")
	inst.homura_archer_charge:set_local(0)

	-- Tower
	inst.homura_tower_ready = net_event(GUID, "homura_tower_ready")

	RegisterNetListeners(inst)

	if TheWorld.ismastersim then 
		-- Setters
	else
		local old_rep = inst.OnEntityReplicated
		inst.OnEntityReplicated = function(inst)
			old_rep(inst)
			if inst._parent then
				for i,v in ipairs(REP)do
					if inst._parent.replica[v] ~= nil then
						inst._parent.replica[v]:AttachClassified(inst)
					end
				end
			end
		end
	end
end)

