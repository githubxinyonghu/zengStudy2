
local SKILLDURATION = HOMURA_GLOBALS.SKILLDURATION
local SKILLCD = HOMURA_GLOBALS.SKILLCD
local PRE = 0.5

local function onleftcd(self, p)
	self.inst.replica.homura_skill:SetLeftCD(p)
end

local function onlefttime(self, p)
	self.inst.replica.homura_skill:SetLeftTime(p)
end

local Skill = Class(function(self, inst)
    self.inst = inst
    
    self.left_cd = 0
    self.left_time = 0
    self.left_ready_time = 0

    self.inst:StartUpdatingComponent(self)

	self.inst:ListenForEvent("newstate",function (inst,data)
		local name = data and data.statename
		local states = {"electrocute","hit","sneeze"}
		for _,v in pairs(states)do
			if name == v then
				self:OnAttacked()
				break
			end
		end
	end)
    
    self.inst:ListenForEvent("death",function() self:ForceEndSkill() end)
    self.inst:ListenForEvent("onsink",function() self:ForceEndSkill() end)
end
,nil,
{
	left_cd = onleftcd,
	left_time = onlefttime,
})

function Skill:Trigger()
	if self.inst.components.health:IsDead() or self.inst:HasTag("playerghost") then
		return
	end

	if self.left_cd <= 0 and self.left_time <= 0 and self.left_ready_time <= 0 then 		
		self:GetReady()
	else
		self:PushBadgeFn(2)
	end
end

function Skill:GetReady() --前摇
	self.left_ready_time = PRE
	self:PushBadgeFn(1)
end

function Skill:OnAttacked(data) --硬直会打断技能
	if self.left_ready_time > 0 then
    	self.left_ready_time = -1
    	self:PushBadgeFn(3)
    end
end

function Skill:UseSkill() --触发
	self.left_time = SKILLDURATION 
	self:StartPauseFn()
	self:PushBadgeFn(4)
end

function Skill:StartPauseFn()
	self.inst.replica.homura_skill:SetIsMagicCenter(true)
end

function Skill:EndSkill()
	self.inst.replica.homura_skill:SetIsMagicCenter(false)

	self.left_cd = SKILLCD
	self:PushBadgeFn(6)
end

function Skill:_Debug()
	self.inst:DoTaskInTime(1, function() self:StartPauseFn() end)
	self.inst:DoTaskInTime(5, function() self:EndSkill() end)
end

function Skill:PushBadgeFn(i) 
	self.inst.replica.homura_skill:PushBadgeFn(i)
end

function Skill:CanCoolDown()
	return not TheWorld.components.homura_time_manager:IsEntityInRange(self.inst)
end

function Skill:OnUpdate(dt)
	if self.left_cd > 0 and self:CanCoolDown() then --处于时停区域内, cd不减少
		self.left_cd = self.left_cd - dt
		if self.left_cd <= 0 then
			self:PushBadgeFn(5)
		end
	end
	
	if self.left_time > 0 then
		self.left_time = self.left_time - dt
		if self.left_time <= 0 then
			self:EndSkill()
		elseif self.inst.components.health:IsDead()then
			self:ForceEndSkill()
		end
	end

	if self.left_ready_time > 0 then
		self.left_ready_time = self.left_ready_time - dt
		if self.left_ready_time <= 0 then
			self:UseSkill()
		end
	end
end

function Skill:OnSave( )
	return {left_cd = self.left_cd}
end

function Skill:OnLoad(data)
	if data then
		self.left_cd = data.left_cd
	end
end

function Skill:ForceEndSkill()
	if self.left_time > 0 then
    	self.left_time = -1
    	self:EndSkill()
    end
end

return Skill
