local DoFoleySounds = SG.DoFoleySounds
local DoRunSounds	= SG.DoRunSounds
local DoMountedFoleySounds = SG.DoMountedFoleySounds
local ConfigureRunState = SG.ConfigureRunState

local SANDSTORM = Loc("I can't see.", "我看不清.")

local function IsDirectWalking(inst)
	-- wasd方向键被按下/手柄左摇杆被拨动
	if inst.components.playercontroller then
		if inst.components.playercontroller.directwalking then
			return true
		elseif inst.components.playercontroller:GetRemoteDirectVector() ~= nil then
			return true
		end
	end
	return false
end

local function CanAim(inst)
	return inst.sg.statemem.normal == true
		or inst.sg.statemem.riding == true
		or inst.sg.statemem.groggy == true
		or inst.sg.statemem.careful == true
		or inst.sg.statemem.sandstorm == true -- can aim but not charge
end

local function CommonStopCharging(inst)
	if not inst.sg.statemem.bow then
		inst.SoundEmitter:KillSound("homura_bow_charge")
		inst.SoundEmitter:KillSound("homura_bow_charge_magic")
		inst.SoundEmitter:KillSound("homura_bow_charge_LOOP")
		inst.replica.homura_archer:Reset()
	end
end

local function RunOrStop(inst)
	if not inst.sg:HasStateTag("homura_bow") then
		return
	end

	if inst.sg.statemem.directwalking then
		inst.sg:AddStateTag("moving")
		inst.sg:AddStateTag("running")
		inst.components.locomotor:RunForward()
	else
		inst.sg:RemoveStateTag("moving")
		inst.sg:RemoveStateTag("running")
		inst.sg.mem.footsteps = 0
		inst.components.locomotor:Stop()
	end

	if inst.sg.statemem.animpostfix then
		local temp = {"homura_bow"}
		if inst.sg.statemem.directwalking then
			table.insert(temp, "walk")
		end
		table.insert(temp, inst.sg.statemem.animpostfix)
		if inst.sg.statemem.directwalking and inst.sg.mem.homura_bow_reverse then
			table.insert(temp, "reverse")
		end

		local anim = table.concat(temp, "_")

		local time = inst.AnimState:GetCurrentAnimationTime()
		local length = inst.AnimState:GetCurrentAnimationLength()
		-- play foot step here
		if inst.sg.statemem.directwalking then
			local reverse = inst.sg.mem.homura_bow_reverse
			local frame = math.floor(time / FRAMES + 0.5)
			if inst.sg.statemem.riding then
				if inst.sg.statemem.animpostfix == "loop" and frame % 29 == (reverse and 17 or 11) then
					DoMountedFoleySounds(inst)
					DoRunSounds(inst)

					if TheWorld.ismastersim then
						inst.SoundEmitter:PlaySound("dontstarve/beefalo/walk", nil, .5)
					end
				end
			else
				if inst.sg.statemem.animpostfix == "pre" and frame == 7
					or inst.sg.statemem.animpostfix == "pst" and frame == (reverse and 6 or 10)
					or inst.sg.statemem.animpostfix == "loop" and frame % 10 == (reverse and 5 or 7) then

					DoRunSounds(inst)
					DoFoleySounds(inst)
				end
			end
		end

		if time > length - FRAMES then
			inst.AnimState:PlayAnimation(anim)
		elseif not inst.AnimState:IsCurrentAnimation(anim) then
			inst.AnimState:PlayAnimation(anim)
			if inst.sg.statemem.animpostfix ~= "loop" and inst.sg.statemem.flag then
				inst.AnimState:SetTime(time)
			end
		end

		inst.sg.statemem.flag = true
	end
end

local function CommonUpdate(inst, dt)
	inst.sg.statemem.directwalking = IsDirectWalking(inst)
	local pos = inst.components.homura_clientkey:GetWorldPosition()
	if pos then
		inst:ForceFacePoint(pos)
	end
	if inst:HasTag("homura") and inst.SoundEmitter:PlayingSound("homura_bow_charge_LOOP") then
		inst.SoundEmitter:SetVolume("homura_bow_charge_LOOP", 
			Lerp(0, 0.2, inst.replica.homura_archer:GetPercent()))
	end
	
	RunOrStop(inst)
end

local pre = function(ismastersim) return State{
	name = "homura_bow_pre",
	tags = { "moving", "running", --[["canrotate",]] "autopredict", "homura_bow" },

	onenter = function(inst)
		-- print("***** pre", GetTick())
		local action = inst:GetBufferedAction()
		local pos = action and action:GetActionPoint()

		if action ~= nil and not ismastersim then
			inst:PerformPreviewBufferedAction()
		end

		inst.AnimState:OverrideSymbol("homura_arrow", "homura_bow_anim", "homura_arrow")

		if pos then
			inst:ForceFacePoint(pos)
		end

		ConfigureRunState(inst)

		if not CanAim(inst) then
			inst.sg:GoToState("idle")
			return
		end

		inst.sg.statemem.animpostfix = "pre"
		inst.sg.statemem.directwalking = IsDirectWalking(inst)

		inst.replica.homura_archer:StartAiming()

		inst.SoundEmitter:PlaySound("lw_homura/bow/charge", "homura_bow_charge", .9, true)

		RunOrStop(inst)
	end,

	timeline = {
		TimeEvent(8*FRAMES, function(inst)
			inst:ClearBufferedAction()
			if inst.sg.statemem.sandstorm then
				if inst.components.talker ~= nil and not inst:HasTag("mime") then
					inst.components.talker:Say(SANDSTORM)
					return
				end
			end

			inst.sg.statemem.bow = true
			if inst.sg.statemem.launch then
				inst.sg:GoToState("homura_bow_pst")
			else
				if ismastersim and inst:HasTag("homura") then
					-- don't play sound in client
					inst.SoundEmitter:PlaySound("lw_homura/bow/charge_magic_1", "homura_bow_charge_magic", 0.25)
					inst.SoundEmitter:PlaySound("lw_homura/bow/charge_magic_loop", "homura_bow_charge_LOOP", 0)
				end
				inst.sg:GoToState("homura_bow_loop")
			end
		end),
	},

	onupdate = function(inst, dt)
		CommonUpdate(inst, dt)
	end,

	events = {
		EventHandler("homura_bow_launch", function(inst)
			inst.sg.statemem.launch = true
		end),
		CommonEquip(),
		CommonUnequip(),
		-- client handler
		not ismastersim and EventHandler("homura_bow_launch_client", function(inst)
			inst.sg.statemem.launch = true
		end) or nil,
	},

	onexit = function(inst)
		inst:ClearBufferedAction()
		CommonStopCharging(inst)
	end,
}
end

local loop = function(ismastersim) return State{
	name = "homura_bow_loop",
	tags = { "moving", "running", --[["canrotate",]] "autopredict", "homura_bow" },

	onenter = function(inst)
		-- print('***** loop', GetTick())

		ConfigureRunState(inst)

		if not CanAim(inst) then
			inst.sg:GoToState("idle")
			return
		end

		if inst.components.homura_archer then
			if not inst.components.homura_archer:TryCharging() then
				inst.sg:GoToState("idle")
				return
			end
		end

		if inst.sg.statemem.sandstorm then
			if inst.components.talker and not inst:HasTag("mime") then
				inst.components.talker:Say(SANDSTORM)
				return
			end
		end

		inst.sg.statemem.animpostfix = "loop"
		inst.sg.statemem.directwalking = IsDirectWalking(inst)

		RunOrStop(inst)
	end,

	timeline = {
		TimeEvent(80*FRAMES, function(inst)
			inst.sg.statemem.bow = true
			inst.sg:GoToState("homura_bow_loop")
		end)
	},

	onupdate = function(inst, dt)
		CommonUpdate(inst, dt)
	end,

	events = {
		EventHandler("homura_bow_launch", function(inst)
			inst.sg.statemem.bow = true
			inst.sg:GoToState("homura_bow_pst")
		end),
		CommonEquip(),
		CommonUnequip(),
		-- client handler
		not ismastersim and EventHandler("homura_bow_launch_client", function(inst)
			inst.sg.statemem.bow = true
			inst.sg:GoToState("homura_bow_pst")
		end) or nil,
	},

	onexit = function(inst)
		CommonStopCharging(inst)
	end,
}
end

local pst = function() return State{
	name = "homura_bow_pst",
	tags = {"autopredict", "homura_bow"},

	onenter = function(inst)
		-- print('***** pst', GetTick())
		ConfigureRunState(inst)

		inst.sg.statemem.animpostfix = "pst"
		inst.sg.statemem.directwalking = IsDirectWalking(inst)

		RunOrStop(inst)
	end,

	timeline = {
		TimeEvent(1*FRAMES, function(inst)
			if inst.components.homura_archer then
				inst.sg.statemem.ignore_unequip = true
				inst.components.homura_archer:Launch()
			end
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.sg:RemoveStateTag("homura_bow")
		end),
		TimeEvent(13*FRAMES, function(inst)
			inst.sg:GoToState("idle")
		end),
	},

	events = {
		-- CommonEquip(),
		-- CommonUnequip(),
		EventHandler("equip", function(inst)
			if not inst.sg.statemem.ignore_unequip then
				inst.sg:GoToState("idle")
			end
		end),
		EventHandler("unequip", function(inst)
			if not inst.sg.statemem.ignore_unequip then
				inst.sg:GoToState("idle")
			end
		end),
	},

	onupdate = function(inst, dt)
		CommonUpdate(inst, dt)
	end,

	onexit = function(inst)
		CommonStopCharging(inst)
	end,
}
end

AddStategraphState("wilson", pre(true))
AddStategraphState("wilson", loop(true))
AddStategraphState("wilson", pst(true))

AddStategraphState("wilson_client", pre(false))
AddStategraphState("wilson_client", loop(false))
AddStategraphState("wilson_client", pst(false))

local function WalkPostInit(self)
	local locomote = self.events["locomote"]
	local old_fn = locomote.fn
	function locomote.fn(inst, data)
		if inst.sg:HasStateTag("homura_bow") then
			return
		end
		return old_fn(inst, data)
	end
end

AddStategraphPostInit("wilson", WalkPostInit)
AddStategraphPostInit("wilson_client", WalkPostInit)