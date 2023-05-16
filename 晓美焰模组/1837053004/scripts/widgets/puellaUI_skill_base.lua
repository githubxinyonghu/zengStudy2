local L = HOMURA_GLOBALS.LANGUAGE
local tooltip = STRINGS.LMB .. (L and 'Reset' or '复位')

local Mover = require "widgets/puellaUI_skill_mover"

local SKILL_mover = Class(Mover, function(self, owner)
	Mover._ctor(self, "SKILL_base")
	self.mover:SetScale(0.4)
	self.mover:SetTint(1,1,1,0)
	self.bg:SetSize(50,50)
    self:SetTooltip(tooltip)
    self:StopUpdating()
end)

function SKILL_mover:Reset()
	self.homuraUI_skillmover:Reset()
	self:SetTooltip(tooltip)
end

function SKILL_mover:OnGainFocus()
	SKILL_mover._base.OnGainFocus(self)
	self.mover:SetTint(1,1,1,0.5)
end

function SKILL_mover:OnLoseFocus()
	SKILL_mover._base.OnLoseFocus(self)
	self.mover:SetTint(1,1,1,0)
end

function SKILL_mover:OnControl(ctrl, down)
	if not self:IsEnabled() or not self.focus then return end
	if ctrl == CONTROL_ACCEPT then 
		self:Reset()
	end
	return true
end

return SKILL_mover