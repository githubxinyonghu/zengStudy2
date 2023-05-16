local SnowDebuff = Class(function(self, inst)
	self.inst = inst
	self.time = 0

	inst:ListenForEvent("unfreeze", function() self:UpdateColour() end)
end)

function SnowDebuff:AddDebuff()
	if self.inst.components.combat 
		and self.inst.components.freezable 
		and self.inst.components.health and not self.inst.components.health:IsDead()
	    then
	    local old = self.time
    	self.time = HOMURA_GLOBALS.SNOWPEA.debufftime
    	if old <= 0 then
	    	self.inst:StartUpdatingComponent(self)
	    	self:TurnOn(true)
	    end
	end
end

function SnowDebuff:RemoveDebuff()
	self.time = 0
	self.inst:StopUpdatingComponent(self)
	self:TurnOff()
end

local function PushColour(inst)
    if inst.components.colouradder ~= nil then
        inst.components.colouradder:PushColour("homura_snowpea_debuff", 0.1, 0.4, 1, 0)
    else
        inst.AnimState:SetAddColour(0, 0.4, 1, 0)
    end
end

local function PopColour(inst)
    if inst.components.colouradder ~= nil then
        inst.components.colouradder:PopColour("homura_snowpea_debuff")
    else
        inst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

local SFX = "lw_homura/snowpea/frozen"
local VOLUME = 1.6
local SFXTIME = 3

SnowDebuff.sfx_queue = {}

function SnowDebuff:TurnOn(sfx)
	local pos = self.inst:IsValid() and self.inst.Transform and Point(self.inst.Transform:GetWorldPosition())
	if pos == nil then
		return
	end

	-- if sfx and self.inst.SoundEmitter ~= nil and SnowDebuff.sfx_queue[self.inst] == nil then
	-- 	local mindistsq = 4*4
	-- 	local playsfx = true
	-- 	local currenttime = GetTime()
	-- 	for k,v in pairs(SnowDebuff.sfx_queue)do
	-- 		if not k:IsValid() or currenttime - v > SFXTIME then
	-- 			SnowDebuff.sfx_queue[k] = nil
	-- 		else
	-- 			if k:GetDistanceSqToPoint(pos) < mindistsq then
	-- 				playsfx = false
	-- 				break
	-- 			end
	-- 		end
	-- 	end

	-- 	if playsfx then
	-- 		SnowDebuff.sfx_queue[self.inst] = currenttime
	-- 		self.inst.SoundEmitter:PlaySound(SFX, nil, 0.7)
	-- 	end
	-- end
	
	if sfx and self.inst.SoundEmitter ~= nil then
		self.inst.SoundEmitter:PlaySound(SFX, nil, VOLUME)
	end

	if self.inst.components.locomotor then
		self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "homura_snowpea_debuff", 0.5)
	end

	self.inst:AddTag("homura_snowpea_debuff")

	if self.inst.AnimState then
		self.inst.AnimState:Homura_RefreshDeltaTimeMultiplier()
	end

	PushColour(self.inst)
end

function SnowDebuff:TurnOff()
	if self.inst.components.locomotor then
		self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "homura_snowpea_debuff")
	end

	self.inst:RemoveTag("homura_snowpea_debuff")

	if self.inst.AnimState then
		self.inst.AnimState:Homura_RefreshDeltaTimeMultiplier()
	end

	PopColour(self.inst)
end

function SnowDebuff:UpdateColour()
	if self.inst:HasTag("homura_snowpea_debuff") then
		PushColour(self.inst)
	else
		PopColour(self.inst)
	end
end

function SnowDebuff:OnUpdate(dt)
	self.time = self.time - dt
	if self.time <= 0 then
		self:RemoveDebuff()
	end
end

function SnowDebuff:OnSave()
	return {time = self.time, add_component_if_missing = true}
end

function SnowDebuff:OnLoad(data)
	self.time = data and data.time or self.time
	if self.time > 0 then
		self.inst:StartUpdatingComponent(self)
		self:TurnOn()
	end
end

return SnowDebuff