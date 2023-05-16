-- 2022.1.13 弓箭冲击波
-- 讲道理这个最好写成widget而不是component

local easing = require "easing"
local outCubic = easing.outCubic

local BLAST_TIME = 0.3

local Blast = Class(function(self, inst)
	self.inst = inst
	self.time = -1
end)

local SetBowBlastParams = HOMURA_GLOBALS.SetBowBlastParams

function Blast:Blast(inst)
	if TheNet:IsDedicated() or ThePlayer ~= self.inst then 
		return
	end

	local px, py = TheSim:GetScreenPos(inst.AnimState:GetSymbolPosition("homura_arrow_fx", 0, 0, 0))
	local w, h = TheSim:GetScreenSize()
	if self.time == -1 then
		self.px = px / w
		self.py = py / h
		self.time = 0
		self.inst:StartUpdatingComponent(self)
	end
end

function Blast:OnUpdate(dt)
	if self.time < BLAST_TIME then
		local r = outCubic(self.time, .04, .16, BLAST_TIME)
		local i = outCubic(self.time, 0.3, -0.3, BLAST_TIME)
		SetBowBlastParams(self.px, self.py, r, i)

		self.time = self.time + dt
	else
		self.time = -1
		self.inst:StopUpdatingComponent(self)
		SetBowBlastParams(0, 0, 0, 0)
	end
end

return Blast