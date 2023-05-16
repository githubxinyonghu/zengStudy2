local TAG = "homura_snowpea_debuff"
local SNOWPEA = HOMURA_GLOBALS.SNOWPEA
-- [USERDATA]

-- Linking
local links = {} -- key = AnimState, value = Entity
local function GetEntity(anim)
	return anim ~= nil and links[anim]
end

local function NewLink(anim, inst)
	if inst:IsValid() then
		links[anim] = inst
		inst:ListenForEvent("onremove", function() links[anim] = nil end)
	end
end

local old_add = Entity.AddAnimState
Entity.AddAnimState = function(ent, ...)
    local inst = Ents[ent:GetGUID()] -- Get lua instance
    if GetEntity(inst and inst.AnimState) then
    	links[inst.AnimState] = nil
    end
    local anim = old_add(ent, ...)
    NewLink(anim, inst)
    return anim
end

-- Mod interfaces
function AnimState.Homura_GetBaseDeltaTimeMultiplier(anim)
	local inst = GetEntity(anim)
	return inst and inst:HasTag(TAG) and (1 - SNOWPEA.debuffeffect) or 1
end

function AnimState.Homura_RefreshDeltaTimeMultiplier(anim)
	local inst = GetEntity(anim)
	if inst then 
		anim:SetDeltaTimeMultiplier(inst.homura_AnimState_timemult or 1)
	end
end

-- Hooks
local old_set = AnimState.SetDeltaTimeMultiplier
function AnimState.SetDeltaTimeMultiplier(anim, val, ...)
	local inst = GetEntity(anim)
	if inst then
		inst.homura_AnimState_timemult = val
	end
	return old_set(anim, val* anim:Homura_GetBaseDeltaTimeMultiplier(), ...)
end

-- [STATEGRAPH]

local function GetStateTimeMult(self)
	local inst = self.inst
	if inst ~= nil and inst:HasTag("homura_snowpea_debuff") then
		return (1 - SNOWPEA.debuffeffect)
	else
		return 1
	end
end

local function RescaleTimeline(self, val)
	local timeline = self.currentstate and self.currentstate.timeline
	if timeline ~= nil then
		for _,v in pairs(timeline)do
			if val == nil or val == 1 then
				v.time = v.homura_time or v.time
				v.homura_time = nil
			else
				v.homura_time = v.homura_time or v.time
				v.time = v.time/val
			end
		end
	end
end

AddGlobalClassPostConstruct("stategraph", "StateGraphInstance", function(self)
	-- interface for other mods
	self.Homura_GetStateTimeMult = GetStateTimeMult
	self.Homura_RescaleTimeline = RescaleTimeline

	-- Hooks
	local old_SetTimeout = self.SetTimeout
	function self:SetTimeout(time, ...)
		if time then
			return old_SetTimeout(self, time/self:Homura_GetStateTimeMult(), ...)
		else
			return old_SetTimeout(self, time, ...)
		end
	end

	local old_Update = self.Update
	function self:Update(...)
		local mult = self:Homura_GetStateTimeMult()
		if mult ~= 1 then
			self:Homura_RescaleTimeline(mult)
		end
		local time_to_sleep = old_Update(self, ...)
		-- if time_to_sleep ~= nil then
		-- 	time_to_sleep = time_to_sleep/mult
		-- end
		if mult ~= 1 then
			self:Homura_RescaleTimeline(1)
		end
		return time_to_sleep
	end
end)

-- [COMPONENT]

local function GetOffset(inst)
    local rider = inst.replica.rider
    return Vector3(1.0, rider and rider:IsRiding() and 3.75 or 1.75, 0)
end

AddPlayerPostInit(function(inst)
	inst:AddComponent("homura_snowpea_puff")
	inst.components.homura_snowpea_puff:SetOffsetFn(GetOffset)
end)

AddComponentPostInit("highlight", function(self)
	local old_highlight = self.Highlight
	function self:Highlight(r,g,b)
		if r == nil and self.inst:HasTag("homura_snowpea_debuff") then
			return old_highlight(self, 0, 0.16, 0.4)
		end
		return old_highlight(self, r, g, b)
	end
end)
