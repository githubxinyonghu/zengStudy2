local DoFoleySounds = SG.DoFoleySounds
local DoRunSounds	= SG.DoRunSounds

local function PlaySounds(inst)
	if inst.sg.statemem.homura_rush then
		DoRunSounds(inst)
		DoFoleySounds(inst)
	end
end

local function RunPostInit(self)
	local run = self.states.run
	local old_enter = run.onenter
	run.onenter = function(inst, data)
		old_enter(inst, data)
		if inst.replica.combat:GetWeapon() and inst.replica.combat:GetWeapon().prefab == "homura_stickbang" then
			if inst.sg.statemem.normal == true then
				if inst:HasTag("homuraTag_rush") then
					inst.sg.statemem.homura_rush = true
					local name = "homura_stickrush"
					if not inst.AnimState:IsCurrentAnimation(name) then
		                inst.AnimState:PlayAnimation(name, true)
		            end

		            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
				end
			end
		end
	end

	local function AddTimeEvent(time, fn)
		for _,v in pairs(run.timeline)do
			if v.time == time then
				local old_fn = v.fn
				v.fn = function(inst)
					old_fn(inst)
					fn(inst)
				end
			else
				table.insert(run.timeline, TimeEvent(time, fn))
			end
		end
	end

	table.sort(run.timeline, function(a,b) return a.time < b.time end)

	AddTimeEvent(5 * FRAMES, PlaySounds)
	AddTimeEvent(11 * FRAMES, PlaySounds)
end

AddStategraphPostInit("wilson", RunPostInit)
AddStategraphPostInit("wilson_client", RunPostInit)
