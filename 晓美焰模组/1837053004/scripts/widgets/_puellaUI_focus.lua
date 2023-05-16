-- 本组件已弃用
assert(false)

local L = HOMURA_GLOBALS.LANGUAGE 

local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local CROSSLINE_SCALE = 
{
	NORMAL = 3, FADE = 4, IN = 4,
}
local CROSSLINE_LENGTH = 
{
	START = 0.2, END = 2,
}

local FOCUS_SPEED = 
{
	MAX = 10, MIN = 2,
}
local FOCUS_RANGE = 
{
	MAX = 100, MIN = 10,  --在距离范围内,移速和距离呈线性
}
local sin = function(num) return math.sin(num*DEGREES) end
local cos = function(num) return math.cos(num*DEGREES) end

local Rot = Class(function(self,inst)

	---极坐标角度预设值为定值,不作赋值和处理

	self.inst = inst
	self.scale = 1 ---限制值
	
	self.ar = 50 self.br = 100   ---椭圆的长轴和短轴(常)
	self.spinomiga = 1 --椭圆进动速度(常)
	self.spin = 0      --椭圆进动角度
	self.angleomiga = 2  --椭圆极坐标角增加速度(常)
	self.angle = 0   ----椭圆极坐标角

	inst:DoPeriodicTask(0,function()self:Tick()end)

	function self:CalcPos()
		local ar,br = self.ar*self.scale, self.br*self.scale
		local _x,_y = cos(self.angle)*ar, sin(self.angle)*br --原始椭圆坐标
		local x,y = _x*cos(self.spin)-_y*sin(self.spin), _x*sin(self.spin)+_y*cos(self.spin) --线性变换后的坐标
		return Vector3(x,y,0)
	end

	function self:Tick()
		self.spin = self.spin+self.spinomiga
		self.spin = self.spin == 360 and 0 or self.spin
		self.angle = self.angle+self.angleomiga
		self.angle = self.angle == 360 and 0 or self.angle
		
		self.inst.UITransform:SetPosition(self:CalcPos():Get())
	end

end)

local function SetAnim(ui,anim,loop,scale_x,scale_y)
	ui:GetAnimState():SetBank('puellaUI_homurafocus')
	ui:GetAnimState():SetBuild('puellaUI_homurafocus')
	ui:GetAnimState():PlayAnimation(anim,loop)
	if scale_x and scale_y then
		--ui:GetAnimState():SetScale(scale_x,scale_y)
		ui:SetScale(scale_x, scale_y)
	end
end

local FocusUI = Class(Widget, function(self, owner)

	Widget._ctor(self, "FocusUI")
	self.owner = owner
	self.inst.entity:AddSoundEmitter()
	self.target = nil
	self:SetClickable(false)
	self.cooldown = 0 --在这段时间内,标线不会进行响应

	self.root = self:AddChild(Widget('focus_root'))
	self.root:SetHAnchor(ANCHOR_TOP)
	self.root:SetVAnchor(ANCHOR_RIGHT)
	self.root:SetPosition(0,0,0)
	
	self.crossline = self.root:AddChild(Widget('crossline_root'))
	self.crossline.StartTween = function(_,...)
		self.crossline_H.inst.components.colourtweener:StartTween(...)
		self.crossline_V.inst.components.colourtweener:StartTween(...)
	end
	self.crossline.SetMultColour = function(_,...)
		self.crossline_H:GetAnimState():SetMultColour(...)
		self.crossline_V:GetAnimState():SetMultColour(...)
	end
	self.crossline.SetWidth = function(_,num)
		local a,b = self.crossline_H:GetScale():Get()
		self.crossline_H:SetScale(a,num)
		self.crossline_V:SetScale(num,a)
	end
	self.crossline.SetLength = function(_,num)
		local a,b = self.crossline_H:GetScale():Get()
		self.crossline_H:SetScale(num,b)
		self.crossline_V:SetScale(b,num)
	end

	self.crossline_H = self.crossline:AddChild(UIAnim())
	self.crossline_H:SetClickable(false)
	self.crossline_H:GetAnimState():SetMultColour(0,1,0,0.2)
	self.crossline_H.inst:AddComponent('colourtweener')
	SetAnim(self.crossline_H,'line',nil,10,.5)
	
	self.crossline_V = self.crossline:AddChild(UIAnim())
	self.crossline_V:SetClickable(false)
	self.crossline_V:GetAnimState():SetMultColour(0,1,0,0.2)
	self.crossline_V.inst:AddComponent('colourtweener')
	SetAnim(self.crossline_V,'line',nil,.5,10)
	self.crossline_V:SetRotation(90)
	

	--------------

	self.focus_root = self.root:AddChild(UIAnim()) --以root为中心做椭圆进动
	self.focus_root:SetClickable(false)
	--self.focus_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.focus_root.rot = Rot(self.focus_root.inst)
	self.focus_root:SetScale(0.4)

	self.focus1 = self.focus_root:AddChild(UIAnim())
	self.focus1:SetClickable(false)
	self.focus1:SetRotation(22.5)
	self.focus1.rotspeed = 2
	self.focus1.inst:AddComponent('colourtweener')
	SetAnim(self.focus1,'circle',nil,1,1)

	self.focus2 = self.focus_root:AddChild(UIAnim())
	self.focus2:SetClickable(false)
	self.focus2.inst:AddComponent('colourtweener')
	self.focus2.rotspeed = 2
	SetAnim(self.focus2,'circle',nil,1,1)

	self.inst:DoPeriodicTask(0,function()
		for i = 1,2 do
			local angle = self['focus'..i].inst.UITransform:GetRotation()
			self['focus'..i]:SetRotation(angle+self['focus'..i].rotspeed)
		end
	end)
	--------------

	self.crossfx = self.root:AddChild(UIAnim())
	self.crossfx:SetClickable(false)
	self.crossfx:SetScale(0.4)
	self.crossfx:SetRotation(45)
	self.crossfx.SetMultColour = function(_,...)
		for i = 1,4 do
			self.crossfx[i]:GetAnimState():SetMultColour(...)
		end
	end
	self.crossfx.SetPercent = function(_,...)
		for i = 1,4 do
			self.crossfx[i]:GetAnimState():SetPercent('cross_in',...)
		end
	end
	self.crossfx.SetRadius = function(_,r)
		for i = 1,4 do
			local angle = self.crossfx[i].inst.UITransform:GetRotation()
			self.crossfx[i]:SetPosition(r*cos(angle),-r*sin(angle))
		end
	end
	


	for i = 1,4 do
		self.crossfx[i] = self.crossfx:AddChild(UIAnim())
		self.crossfx[i]:SetClickable(false)
		self.crossfx[i]:SetRotation(i*90)
		self.crossfx[i]:GetAnimState():SetBuild('puellaUI_homurafocus')
		self.crossfx[i]:GetAnimState():SetBank('puellaUI_homurafocus')
		self.crossfx[i]:GetAnimState():SetPercent('cross_in',1)
	end

	self:StartUpdating()

	self.PlaySound = function(_,...)
		self.inst.SoundEmitter:PlaySound(...)
	end

	self.inst:ListenForEvent('homura.StartFocus',function(inst,data) --开始瞄准一个新目标
		if self.focusing and self.target == data.target then
			return
		end
		self.target = data.target
		self:StartFocus()
	end, owner)
	self.inst:ListenForEvent('homura.FinishFocus',function(inst,data) --瞄准完成(可能用不到吧)
		self.focusing = false
	end, owner)
	self.inst:ListenForEvent('homura.AbruptFocus',function(inst,data) --被打断
		self.target = nil
		if self.focusing then
			self:AbruptFocus()
		else
			self:EndFocus()
		end
	end, owner)

	self.crossline:Hide()
	self.crossfx:Hide()
	self.focus_root:Hide()
end)

function FocusUI:StartFocus()
	print('ui call StartFocus')
	self:EndFocus()
	if self.cooldown > 0 then
		return
	end
	self.root:SetPosition(self:GetFocusTargetPos()+Vector3(math.random(-200,200),math.random(-200,200),0))
	self.focusing = true
	self.focused = false
	self.crossline:Hide()
	self.crossfx:Hide()
	self.crossfx:SetRadius(200)
	self.focus_root:Show()
	self.focus1.inst.components.colourtweener:EndTween()
	self.focus2.inst.components.colourtweener:EndTween()
	self.focus1:GetAnimState():SetMultColour(1,1,1,0)
	self.focus2:GetAnimState():SetMultColour(1,1,1,0)
	local inst = self.inst
	inst.buffedtasks = {}

	inst.buffedtasks['snd1'] = inst:DoTaskInTime(1,function()self:PlaySound('lw_homura/focus/1',nil,.7)end)
	inst.buffedtasks['snd2'] = inst:DoTaskInTime(2,function()self:PlaySound('lw_homura/focus/1',nil,.7)end)
	inst.buffedtasks['snd3'] = inst:DoTaskInTime(3,function()self:PlaySound('lw_homura/focus/2',nil,.7)end)

	for i = 1,60 do
		inst.buffedtasks['rot_'..i] = inst:DoTaskInTime(i/30,function()
			self.focus_root.rot.scale = Remap(i,1,60,1,0)
		end)
	end

	local timeoffset = 0
	inst.buffedtasks['0_'] = inst:DoTaskInTime(timeoffset,function()
		self.focus1:SetRotation(0)
		self.focus1.inst.components.colourtweener:StartTween({1,1,1,1},1)
	end)
	for i = 1,30 do
		local time = timeoffset + i/30
		local speed = Remap(i,1,30,2,5)
		local scale = Lerp(2,0.6,(i/30)^2)
		inst.buffedtasks['1_'..i] = inst:DoTaskInTime(time,function()
			self.focus1.rotspeed = speed 
			self.focus1:SetScale(scale)
		end)
	end

	local timeoffset = 1
	inst.buffedtasks['1_'] = inst:DoTaskInTime(timeoffset,function()
		self.focus2:SetRotation(24)
		--self.focus2:GetAnimState():SetMultColour(0.5,0.5,0,0)
		self.focus2.inst.components.colourtweener:StartTween({1,1,1,1},1)
		--self.focus1.inst.components.colourtweener:StartTween({0,1,0,1},1)
	end)
	for i = 1,30 do
		local time = timeoffset + i/30
		local speed = Remap(i,1,30,2,5)
		local scale = Lerp(1.5,0.6,(i/30)^2)
		inst.buffedtasks['2_'..i] = inst:DoTaskInTime(time,function()
			self.focus2.rotspeed = speed 
			self.focus2:SetScale(scale)
		end)
	end

	local timeoffset = 2
	inst.buffedtasks['2_'] = inst:DoTaskInTime(timeoffset,function()
		self.crossfx:Show()
		self.crossfx:SetMultColour(1,1,1,0)
	end)
	for i = 1,30 do
		local p = i/30
		local p2 = p^2
		local time = timeoffset + i/30
		local speed = Remap(i,1,30,5,10)
		inst.buffedtasks['3_'..i] = inst:DoTaskInTime(time,function()
			self.focus1.rotspeed = speed
			self.focus2.rotspeed = speed 
			self.crossfx:SetMultColour(1,1,1,p*0.5)
			self.crossfx:SetRotation(Remap(i,1,30,45,90))
			self.crossfx:SetScale(Lerp(0.4,0.2,p))
			self.crossfx:SetRadius(200*(1-p2))
		end)
	end

	local timeoffset = 3
	inst.buffedtasks['3_'] = inst:DoTaskInTime(timeoffset,function()
		self.focus1:ScaleTo(0.6,1.5,0.4)
		self.focus2:ScaleTo(0.6,1.5,0.4)
		self.focus1.inst.components.colourtweener:StartTween({1,1,1,0},0.4)
		self.focus2.inst.components.colourtweener:StartTween({1,1,1,0},0.4)
	end)

	local timeoffset = 3
	inst.buffedtasks['crossline'] = inst:DoTaskInTime(timeoffset,function()
		self.crossline:SetLength(0.5)
		self.crossline:SetWidth(1)
		self.crossline:SetMultColour(0,1,0,1)
		self.crossline:Show()
		--self.crossline:StartTween({0,1,0,0.2},0.2)
	end)
	for i = 1,15 do
		inst.buffedtasks['4_'..i] = inst:DoTaskInTime(timeoffset+i/30,function()
			local p = i/15
			self.crossline:SetMultColour(0,1,0,Lerp(1,0.2,p))
			self.crossline:SetWidth(Lerp(1,0.5,p))
			self.crossline:SetLength(math.min(12.5,Lerp(0.5,12.5,i/15)))
			self.crossfx:SetMultColour(1,1,1,Lerp(0.5,0,p))
			self.crossfx:SetScale(Lerp(0.2,0.3,p))
		end)
	end
	inst.buffedtasks['exit'] = inst:DoTaskInTime(timeoffset+0.2,function()
		self.focusing = false
		self.focused = true
		self.owner:PushEvent('homura.FocusDownInUI')
		if inst.timeout_task then
			inst.timeout_task:Cancel()
		end
	end)

	if self.owner then
		self.owner.lw_pendingtasks[inst.buffedtasks] = true
	end
end

function FocusUI:AbruptFocus()
	--self.cooldown = 0.5
	self:EndFocus()
end

function FocusUI:EndFocus()
	self.focusing = false
	self.focused = false
	if self.inst.buffedtasks then
		for _,v in pairs(self.inst.buffedtasks)do
			v:Cancel()
		end
		if self.owner then
			self.owner.lw_pendingtasks[self.inst.buffedtasks] = nil 
		end
	end
	self.crossline:StartTween({0,1,0,0},0.5)
	self.focus1.inst.components.colourtweener:StartTween({1,1,1,0},0.5)
	self.focus2.inst.components.colourtweener:StartTween({1,1,1,0},0.5)
	self.focus_root:Hide()
	self.crossfx:Hide()
end

function FocusUI:GetFocusTargetPos()
	if not self.target or not self.target.AnimState then 
		return Vector3(0,0,0) 
	end

	local symbol = self.target.replica.combat and self.target.replica.combat._lw_combat_hiteffectsymbol 
		and self.target.replica.combat._lw_combat_hiteffectsymbol:value()
	local hx, hy, hz = self.target.AnimState:GetSymbolPosition(symbol or '', 0, 0, 0)
	local px, py = TheSim:GetScreenPos(hx,hy,hz)
	return Vector3(px, py, 0)
end

function FocusUI:FocusOnTarget() ---由root追踪目标
	if not self.target then return end
	local pos = self:GetFocusTargetPos()
	--local pos = TheInput:GetScreenPosition()
	local uipos = self.root:GetPosition()
	local dist = math.sqrt((pos.x-uipos.x)^2+(pos.y-uipos.y)^2)
	local vec = (pos - uipos):Normalize()
	local speed = Remap(dist,FOCUS_RANGE.MIN, FOCUS_RANGE.MAX, FOCUS_SPEED.MIN, FOCUS_SPEED.MAX)
	speed = math.clamp(speed, FOCUS_SPEED.MIN, FOCUS_SPEED.MAX)
	speed = math.min(dist, speed) --移速不能超过当前距离

	local distpos = vec*speed + uipos

	self.root:SetPosition(distpos)
end

function FocusUI:OnTargetDeath()
	self.target = nil
	self.crossline:StartTween({0,1,0,0},0.5)
end

function FocusUI:CheckIsValidTarget()
	local target = self.target
	return target and target:IsValid() and not target:HasTag("INLIMBO")
	and not target.replica.health:IsDead()
end

function FocusUI:OnUpdate(dt)
	--if self.cooldown > 0 then
	--	self.cooldown = self.cooldown - dt
	--end
	if self.target then
		if self:CheckIsValidTarget() then
			self:FocusOnTarget()
		else
			self:OnTargetDeath()
		end
	end
end

return FocusUI