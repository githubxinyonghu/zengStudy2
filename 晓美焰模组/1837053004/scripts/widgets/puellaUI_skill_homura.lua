local L = HOMURA_GLOBALS.LANGUAGE
local KEY = string.upper(HOMURA_GLOBALS.SKILLKEY_STRING or "")

local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Badge = require "widgets/badge"
local Image = require "widgets/image"
local Mover = require "widgets/puellaUI_skill_mover"

local SKILL_homura = Class(Widget, function(self, owner)

	Widget._ctor(self, "SKILL_homura")
	self.owner = owner
	self.inst.entity:AddSoundEmitter()

	self.MOD = 1

	self.cd = 0
	self.left = 0

	self.badge = self:AddChild(UIAnim())--技能图标
    self.badge:GetAnimState():SetBank("homura_badge")
    self.badge:GetAnimState():SetBuild("homura_badge")
    self.badge:GetAnimState():PlayAnimation("idle")	
    self.badge.texture = 1
    self.badge.SetAlphaFn = function (a)
    	self.badge:GetAnimState():SetMultColour(1,1,1,a)
    end
    self.badge:SetScale(.25)
    self.badge:SetPosition(-1, 3, 0)

    self.name = self:AddChild(Text(BODYTEXTFONT,25,L and "<Time magic>" or "<时间停止>"))--技能名字
    self.name:SetPosition(0,-50,0)
    self.name:Hide()

    self.text = self:AddChild(Text(BODYTEXTFONT,20,"")) ---cd数字/锁定/就绪
    self.text:SetPosition(0,-70,0)
    self.text:Hide()

    self.cdfan = self:AddChild(UIAnim())  --cd图形
    self.cdfan:SetPosition(0,2,0)
    self.cdfan:GetAnimState():SetBank("homura_cd_percent")
    self.cdfan:GetAnimState():SetBuild("homura_cd_percent")
    self.cdfan.SetAlphaFn = function(a)
    	self.cdfan:GetAnimState():SetMultColour(0,0,0,a)
    end
    self.cdfan:SetScale(.8)

    self.cdflash = self.cdfan:AddChild(UIAnim())
    self.cdflash:SetPosition(0,1)
    self.cdflash:GetAnimState():SetBank("homura_cd_flash")
    self.cdflash:GetAnimState():SetBuild("homura_cd_flash")
    self.cdflash:GetAnimState():SetDeltaTimeMultiplier(1.5)

    local keydesc = ""
    if KEY ~= "" then
    	keydesc = string.format(L and "(%s)" or "（%s）", KEY)
    end
    self.description = self:AddChild(Text(BODYTEXTFONT,20,(L and "Temporarily freeze time. " or "暂时冻结时间流逝。")..keydesc))
    self.description:SetPosition(0,-100,0)
    self.description:Hide()

    self.mover = self:AddChild(Mover())
    self.mover:SetPosition(0,32,0)
    self.mover.mainicon = self

    self.timer = 5

	self:StartUpdating()

	--动画触发器
	self.inst:ListenForEvent('homuraUI_callfn',function(inst,data) self:CallFn(data.fn) end, owner)

	self.RMdoubleclick = 0 --双击判定

	self:Fade(true)

end)

function SKILL_homura:CallFn(name)
	local fn = SKILL_homura[name]
	fn(self)
end

function SKILL_homura:Fade(vel)
	if vel then
		--self.badge.SetAlphaFn(.2)
		--self.cdfan.SetAlphaFn(.3)
		self:SetAlphaTarget(.2,.3)
	else
		self.badge.SetAlphaFn(1)
		self.cdfan.SetAlphaFn(.5)
		self:SetAlphaTarget(nil)
	end
end

function SKILL_homura:SetAlphaTarget(a1,a2)
	self.badge_alphatarget = a1
	self.cdfan_alphatarget = a2
end

function SKILL_homura:OnGainFocus()  --显示技能名称，/ 未变身：显示变身提示 / 冷却完成：显示介绍  / 冷却中：显示CD
    SKILL_homura._base.OnGainFocus(self)
    self.name:Show()
    self.text:Show()
    self:Fade(false)
    if not self.description_task then
    	self.description_task = self.inst:DoTaskInTime(2.5,function ()self.description:Show() end)
    end
end

function SKILL_homura:OnLoseFocus() 
	SKILL_homura._base.OnLoseFocus(self)
	self.name:Hide()
	self.text:Hide()
	self.timer = 2
	if self.description_task then 
		self.description_task:Cancel()
		self.description_task = nil
	end
	self.description:Hide()
	self:ScaleTo(self.MOD, self.MOD, 0)
end

function SKILL_homura:OnControl(control, down) 
	
	if not self:IsEnabled() or not self.focus then return end

	if self.ismoving then 
		return self.mover:OnControl(control, down)
	end
	
	if control == CONTROL_ACCEPT then
		if down then
			self:ScaleTo(1*self.MOD, 0.9*self.MOD, 1/15)
			self.down = true
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		elseif self.down then
			self:ScaleTo(0.9*self.MOD, 1*self.MOD, 1/15)
			self.down = false
			SendModRPCToServer(MOD_RPC['akemi_homura']['timepause'])
		end
		return true
	end

	if control == CONTROL_SECONDARY and down then 
		local time = rawget(_G, "GetStaticTime") and GetStaticTime() or GetTime()
		local dt = time - self.RMdoubleclick 
		if dt <= 0.75 then 
			self.mover:Reset()
		end
		self.RMdoubleclick = time
	end
end

function SKILL_homura:ShowCD()
	self.name:Show()
	self.text:Show()
	self:Fade(false)
	self.timer = 5
end

function SKILL_homura:OnTry()
	self:Fade(false)
	self.timer = 2
	self.badge:GetAnimState():PlayAnimation("enter_2")
end

function SKILL_homura:OnStart()
	self:Fade(false)
	self.timer = 2
	self.badge:GetAnimState():PushAnimation("run",true)
	self.inst.SoundEmitter:PlaySound("lw_homura/timemagic/start","tp1",.2)
	self.inst.SoundEmitter:PlaySound("lw_homura/timemagic/tick_loop","TICK",.5)
	self.inst.SoundEmitter:SetParameter('TICK','intensity',.5)
end

function SKILL_homura:OnAttacked( )
	self.badge:GetAnimState():PlayAnimation("idle")
end

function SKILL_homura:OnEnd()
	self.timer = 2
	self.badge:GetAnimState():PlayAnimation("end")
	self.badge:GetAnimState():PushAnimation("idle",false)
	self.inst.SoundEmitter:KillSound("TICK")
	self.inst.SoundEmitter:PlaySound("lw_homura/timemagic/end","tp2",.2)
end

function SKILL_homura:OnCoolDown()
	self.cdflash:GetAnimState():PlayAnimation("anim2")
end

local ALPHA_STEP = 1/30
local ALPHA_STEP = 1

local function format(num)
	if num > 10 then 
		return tostring(math.ceil(num))
	else
		num = num - math.mod(num, 0.1)
		if num % 1 == 0 then
			return num .. '.0'
		else
			return num
		end
	end
end

function SKILL_homura:OnUpdate(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt 
	end

	if self.timer <= 0 and self.left <= 0 and not self.focus then
		self:Fade(true)
		self.name:Hide()
		self.text:Hide()
		self.description:Hide()
	end

	local skill = self.owner.replica.homura_skill
	local lefttime = skill:GetLeftTime()
	local leftcd = skill:GetLeftCD()
	local leftcd_p = leftcd / HOMURA_GLOBALS.SKILLCD

	local iscd = (leftcd > 0)
	local isactivated = (lefttime > 0 )

	self.cdfan:GetAnimState():SetPercent("anim",1-leftcd_p )

	if isactivated then
		self.timer = self.timer + dt --技能激活期间不变透明
		self.text:SetString(string.format(L and "Activated (%s)" or "使用中 (%s)", format(lefttime)))
		self.text:SetColour(0,1,0,1)
	elseif iscd then
		self.text:SetString(string.format(L and "Cooling down (%s)" or "冷却中 (%s)", format(leftcd)))
		self.text:SetColour(147/255,120/255,193/255,1)
	else 
		self.text:SetString(L and "Ready" or "就绪")
		self.text:SetColour(0,1,0,1)
	end

	--透明度缓动
	if self.badge_alphatarget then
		local r,g,b,a = self.badge:GetAnimState():GetMultColour()
		local step = math.clamp(self.badge_alphatarget - a, -ALPHA_STEP, ALPHA_STEP)
		self.badge:GetAnimState():SetMultColour(r,g,b,a+step)
	end
	if self.cdfan_alphatarget then
		local r,g,b,a = self.cdfan:GetAnimState():GetMultColour()
		local step = math.clamp(self.cdfan_alphatarget - a, -ALPHA_STEP, ALPHA_STEP)
		self.cdfan:GetAnimState():SetMultColour(r,g,b,a+step)
	end
end

function SKILL_homura:GetScaleBetweenLG() --获取缩放比例
	local w1 = self.mover
	local w2 = self.text
	--local distLocal = distsq(w1:GetLocalPosition(),w2:GetLocalPosition())
	local distLocal = 102 * 102
	local distGlobal = distsq(w1:GetWorldPosition(),w2:GetWorldPosition())
	return math.sqrt(distLocal/distGlobal)
end

return SKILL_homura