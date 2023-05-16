-- 2021.5.13 发动时停时，在屏幕上显示冲击波特效（本地）
-- 讲道理这个最好写成widget而不是component

local SPEED_UP = 2.0
local SPEED_DOWN = 3.2

local Blast = Class(function(self, inst)
	self.inst = inst

	self.px = 0.5
	self.py = 0.5
	self.process = 0

	self.world = TheWorld.components.homura_time_manager
end)

local SetShaderParams = HOMURA_GLOBALS.SetShaderParams

local function GetWH()
	local w, h = TheSim:GetScreenSize()
	return w / h 
end

function Blast:Blast(px, py) -- 0~1
	if self.process == 0 then
		self.px = px or 0.5
		self.py = py or 0.5

		-- 计算圆覆盖整个屏幕的半径
		local a = math.max(math.abs(self.px - 1.0), math.abs(self.px))
		local b = math.max(math.abs(self.py - 1.0), math.abs(self.py))
		self.processmax = math.sqrt(a*a+b*b) + 0.25

		-- self.inblast = true
		self.inblast = HOMURA_GLOBALS.BLAST
		self:Start()
	end
end

function Blast:Start()
	-- 仅本地生效
	if TheNet:IsDedicated() or ThePlayer ~= self.inst then 
		return
	end

	self.inst:StartUpdatingComponent(self)
end

function Blast:OnUpdate(dt)
	if self.inblast then
		self.process = math.min(self.processmax, self.process + dt * SPEED_UP)
		SetShaderParams(self.px, self.py, self.process, math.min(1, 0.5 + self.process))

		if self.process == self.processmax then
			self.inblast = false 
		end
	else 
		local inrange = self.world:IsEntityInRange(self.inst)
		self.process = math.clamp(self.process + (inrange and 1 or -1) * dt * SPEED_DOWN, 0, 1)
		SetShaderParams(0.5, 0.5, 999, self.process)

		if self.process == 0 then
			self.inst:StopUpdatingComponent(self)
		end
	end
end

return Blast