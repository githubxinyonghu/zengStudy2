local L = HOMURA_GLOBALS.LANGUAGE
local tooltip = {
	STRINGS.LMB .. (L and 'Move widget' or '移动图标'),
	STRINGS.RMB .. (L and 'Reset' or '复位'),
}
local Widget = require "widgets/widget"
local Image = require "widgets/image"

local SKILL_mover = Class(Widget, function(self, owner)
	Widget._ctor(self, "SKILL_mover")

	self.inst.entity:AddSoundEmitter()

	local mover = self:AddChild(Image('images/hud/homuraUI_mover.xml', 'homuraUI_mover.tex'))
    mover:SetPosition(0,0,0)
    mover:SetTint(1,1,1,0)
    mover:SetScale(0.25)
    self.mover = mover

    local bg = self:AddChild(Image("images/ui.xml", "blank.tex"))
    bg:SetSize(20,20)
    self.bg = bg

    self:SetTooltip(tooltip[1])

    --self.defalutPos = Vector3(0,0,0)
    self.offset = Vector3(0,0,0)
    self:StartUpdating()
    self.inst:DoTaskInTime(0, function() self:Init() end) 
end)

function SKILL_mover:Reset()
	self.offset = Vector3(0,0,0)
	self:Save()
	self.mainicon:SetPosition(self.defalutPos)
	self:SetTooltip(tooltip[1])
end

function SKILL_mover:Dirty()
	self:SetTooltip(tooltip[1] .. '\n' .. tooltip[2])
end

function SKILL_mover:OnGainFocus()
	SKILL_mover._base.OnGainFocus(self)
	self.mainicon.ismoving = true
	self.mover:SetTint(1,1,1,1)
end

function SKILL_mover:OnLoseFocus()
	SKILL_mover._base.OnLoseFocus(self)
	self.mainicon.ismoving = false
	self.mover:SetTint(1,1,1,0)
end

function SKILL_mover:OnControl(ctrl, down)
	if not self:IsEnabled() or not self.focus then return end
	if ctrl == CONTROL_CANCEL or ctrl == CONTROL_SECONDARY then 
		self:Reset()
	end
	return true
end

function SKILL_mover:GetScaleBetweenLG()
	return self.mainicon:GetScaleBetweenLG()
end

function SKILL_mover:OnUpdate(dt)

	if not self.shown then return end
	
	if TheInput:IsControlPressed(CONTROL_PRIMARY) then
		if not self.canmove and self.focus then 
			self.canmove = true
		end
	else
		self.canmove = false
	end

	if TheInput:IsControlPressed(CONTROL_PRIMARY) and self.canmove then
		local pos = TheInput:GetScreenPosition()
		if self.lastpos then
			local scale = self:GetScaleBetweenLG()
			local dx = scale * ( pos.x - self.lastpos.x )
			local dy = scale * ( pos.y - self.lastpos.y )
			self:Offset( dx, dy )
		end
		
		self.lastpos = pos
	else
		self.lastpos = nil
	end
end

function SKILL_mover:Offset(x,y)
	self.offset = self.offset + Vector3(x, y, 0)
	self.mainicon:SetPosition(self.defalutPos + self.offset)
	self:Dirty()
	self:Save()
end

function SKILL_mover:Save()
	local dx, dy = self.offset:Get()
	local data = DataDumper({dx or 0, dy or 0}, nil, false)
    local insz, outsz = SavePersistentString('homuraSave_skilliconoffset', data, ENCODE_SAVES)
end

function SKILL_mover:Init()
	TheSim:GetPersistentString('homuraSave_skilliconoffset', function(load_success, str)
		if load_success == true then
			local success, savedata = RunInSandbox(str)
			if success and string.len(str) > 0 then
				self.offset = Vector3(savedata[1] or 0,savedata[2] or 0, 0)
				if not self.offset == Vector3(0, 0, 0) then
					self.mainicon:SetPosition(self.defalutPos + self.offset)
					self:Dirty()
				end
			end
		end
	end)
end

return SKILL_mover