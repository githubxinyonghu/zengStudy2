local function OnTimerDone(inst, data)
	if data and data.name == "charge" then
		inst.components.homura_reinforcement:OnCharge()
	end
end

local function currentlevel(self, i)
	-- if i > 0 and self.inactive then
	self.inst._level:set(i)
	if i >= self.maxlevel and self.inactive then
		self.inst:AddTag("homuraTag_charge")
	else
		self.inst:RemoveTag("homuraTag_charge")
	end
end

local function inactive(self, i)
	if i then
		self.inst._interfered:set(false)
	else
		self.inst._interfered:set(true)
		self.inst:RemoveTag("homuraTag_charge")
	end
end

local Reinforcement = Class(function(self, inst)
	self.inst = inst
	self.maxlevel = 1
	self.currentlevel = 0

	self.timer = inst.components.timer

	inst:ListenForEvent("timerdone", OnTimerDone)
	inst:ListenForEvent("onbuilt", function() self:OnBuilt() end)

end, nil, 
{
	currentlevel = currentlevel,
	inactive = inactive,
})

local function UpdateActive()
	-- print("-----X------")
	local level = 0
	local ent = nil
	for k in pairs(TheWorld.homura_reinforcent_beacon or {})do
		if k:IsValid() and k.components.homura_reinforcement then
			-- print(k, k.components.homura_reinforcement.maxlevel)
			if k.components.homura_reinforcement.maxlevel > level then
				level = k.components.homura_reinforcement.maxlevel
				ent = k
			end
		end
	end

	if TheWorld.worldprefab ~= "forest" then
		ent = nil
	end
	
	for k in pairs(TheWorld.homura_reinforcent_beacon or {})do
		if k == ent then
			k.components.homura_reinforcement:Activate()
		else
			k.components.homura_reinforcement:Deactivate()
		end
	end

	return ent
end

function Reinforcement:Register()
	assert(TheWorld.ismastersim)
	if TheWorld.homura_reinforcent_beacon == nil then
		TheWorld.homura_reinforcent_beacon = {}
	end

	TheWorld.homura_reinforcent_beacon[self.inst] = true

	UpdateActive()
end

function Reinforcement:Unregister()
	assert(TheWorld.ismastersim)
	if TheWorld.homura_reinforcent_beacon ~= nil then
		TheWorld.homura_reinforcent_beacon[self.inst] = nil
	end

	UpdateActive()
end


function Reinforcement:OnRemoveEntity()
	self:Unregister()
end

Reinforcement.OnRemoveFromEntity = Reinforcement.OnRemoveEntity

function Reinforcement:StartCharging(restart)
	if self.currentlevel >= self.maxlevel then
		return
	end

	if restart then
		self.timer:StopTimer("charge")
	end

	if self.timer:TimerExists("charge") then
		self.timer:ResumeTimer("charge")
	else
		self.timer:StartTimer("charge", HOMURA_GLOBALS.SUPPORT_BEACON.chargetime)
	end
end

function Reinforcement:Activate()
	self.inactive = true
	self:StartCharging()
	self.onactivate(self.inst)
end

function Reinforcement:Deactivate() 
	self.inactive = false
	if self.timer:TimerExists("charge") then
		self.timer:PauseTimer("charge")
	end
	self.ondeactivate(self.inst)
end

function Reinforcement:Touch(pos)
	pos = pos or self.inst:GetPosition()

	local targetpos = nil
	for i = 1, 10 do
		targetpos = pos + Vector3(GetRandomWithVariance(0, 8), 0, GetRandomWithVariance(0, 8))
		local x, y, z = targetpos:Get()
		local obs = false
		if next(TheSim:FindEntities(x, y, z, 2, nil, {"blocker"}, {"inlimbo"})) == nil then
			break
		end
	end

	if self.inactive and self.currentlevel > 0 then
		self.inst.SoundEmitter:PlaySound("lw_homura/tower/radar", nil, nil)
		local fx = SpawnPrefab("homura_tower_fx")
		fx.entity:AddFollower():FollowSymbol(self.inst.GUID, "fx", 0,0,0)

		self.inst:RemoveTag("homuraTag_charge")
		self.inst:DoTaskInTime(3.5, function()
			local box = SpawnPrefab("homura_box_"..self.currentlevel)
			if box ~= nil then
				box:SetLoot()
				box:Drop(targetpos)
			end
			self.currentlevel = 0
			self:StartCharging()
		end)
	end
end

function Reinforcement:OnCharge()
	if self.currentlevel < self.maxlevel and self.inactive then
		self.currentlevel = self.currentlevel + 1

		self:StartCharging(true)
		if self.currentlevel >= self.maxlevel then
			for _,v in pairs(AllPlayers)do
				if v.player_classified ~= nil then
					v.player_classified.homura_tower_ready:push()
				end
			end
		end
	end
end

function Reinforcement:OnSave()
	return {
		currentlevel = self.currentlevel,
	}
end

function Reinforcement:OnLoad(data)
	if data then
		self.currentlevel = data.currentlevel or self.currentlevel
	end
end

function Reinforcement:OnBuilt()
	self.currentlevel = math.max(self.currentlevel, self.maxlevel - 1)
	local t = 3

	if self.timer:TimerExists("charge") then
		self.timer:SetTimeLeft("charge", t)
	else
		self.timer:StartTimer("charge", t)
	end

	return self.inst
end

function Reinforcement:GetDebugString()
	return string.format("level: %d time: %d", self.currentlevel, self.inst.components.timer:GetTimeElapsed("charge") or -1)
end

return Reinforcement