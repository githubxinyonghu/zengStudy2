local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local ran = GetRandomMinMax

local NUM = 27
local SPEED = 1/10

-- 1.0 --> 0.6 --> 0.2 --> 0.1
local FADE_IN_PERCENT = 0.6
local FADE_OUT_PERCENT = 0.2
local KILL_PERCENT = 0.1

local EMIT_CD = 2*FRAMES
local FADE_TIME = 1
local ROT_SPEED = 3

local Formula = Class(Image, function(self)
	Image._ctor(self, "images/hud/homura_learning_formula.xml", math.random(NUM)..".tex")

	self:SetClickable(false)

	self:SetTint(1,1,1,0)
	self:SetScale(0)

	self.globalalpha = 0
	self.globalrotation = 0

	self.dist = 1
	self.scale = ran(0.2, 0.3)
	self.origin = {ran(-400, 400), ran(-300, 300)}
end)

function Formula:SetGlobalAlpha(a)
	self.globalalpha = a
end

function Formula:SetGlobalRotation(a)
	self.globalrotation = a
end

function Formula:Update(dt)
	self.dist = self.dist - dt* SPEED
	-- alpha
	local alpha = 1
	if self.dist > FADE_IN_PERCENT then -- fadein
		alpha = Remap(self.dist, FADE_IN_PERCENT, 1.0, 1.0, 0)
	elseif self.dist < FADE_OUT_PERCENT and self.dist > KILL_PERCENT then -- fadeout
		alpha = Remap(self.dist, KILL_PERCENT, FADE_OUT_PERCENT, 0, 1.0)
	elseif self.dist < KILL_PERCENT then -- kill
		self:Kill()
		return
	end
	self:SetTint(1,1,1, alpha* self.globalalpha)

	local mult = 1 / math.max(0.01, self.dist)
	self:SetScale(self.scale* mult)
	local x, y = self.origin[1]* mult, self.origin[2]* mult
	local a = self.globalrotation * DEGREES
	-- apply rotation
	x, y = math.cos(a)*x + math.sin(a)*y, -math.sin(a)*x + math.cos(a)*y
	self:SetPosition(x, y)
end

local LearningUI = Class(Widget, function(self, owner)
	Widget._ctor(self, "homuraUI_learning")

	self.bg = self:AddChild(Image("images/ui.xml", "white.tex"))
	self.bg:SetTint(0, 0, 0, 0)
	self.bg:SetHRegPoint(ANCHOR_MIDDLE)
	self.bg:SetVRegPoint(ANCHOR_MIDDLE)
	self.bg:SetHAnchor(ANCHOR_MIDDLE)
	self.bg:SetVAnchor(ANCHOR_MIDDLE)
	self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.bg:SetClickable(false)

	self.owner = owner
	self.alpha = 0
	self.targetalpha = 0
	self.rotation = 0
	self.formulas = {}

	self.froot = self:AddChild(Widget("froot"))
	self.froot:SetHAnchor(ANCHOR_MIDDLE)
	self.froot:SetVAnchor(ANCHOR_MIDDLE)
	self.froot:SetScaleMode(SCALEMODE_PROPORTIONAL)

	self.ticktoemit = 0

	-- init some uis
	for i = 1, 50 do
		self:AddFormula().dist = ran(0.3, 1.0)
	end

	self.inst:ListenForEvent("homura_startlearning", function() self:FadeIn() end, owner)
	self.inst:ListenForEvent("homura_stoplearning", function() self:FadeOut() end, owner)
end)

function LearningUI:AddFormula()
	local f = self.froot:AddChild(Formula())
	self.formulas[f] = true
	return f
end

function LearningUI:FadeIn()
	self.targetalpha = 0.8
	self:StartUpdating()
end

function LearningUI:FadeOut()
	self.targetalpha = 0
end

function LearningUI:OnUpdate(dt)
	if getmetatable(TheNet).__index.IsServerPaused ~= nil --[[兼容旧版本]] and TheNet:IsServerPaused() then
		return
	end

	self.rotation = self.rotation + ROT_SPEED*dt
	if self.rotation > 360 then
		self.rotation = self.rotation - 360
	end

	if self.targetalpha > self.alpha then
		self.alpha = math.min(self.targetalpha, self.alpha + dt/FADE_TIME)
	elseif self.targetalpha < self.alpha then
		self.alpha = math.max(0, self.alpha - dt/FADE_TIME)
	elseif self.alpha == 0 then
		self:StopUpdating()
	end

	if self.ticktoemit > 0 then
		self.ticktoemit = self.ticktoemit - dt
	else
		self:AddFormula()
		self.ticktoemit = EMIT_CD
	end

	self.bg:SetTint(0,0,0, self.alpha*0.66)

	for k in pairs(self.formulas)do
		if not k.inst:IsValid() then
			self.formulas[k] = nil
		else
			k:SetGlobalAlpha(self.alpha)
			k:SetGlobalRotation(self.rotation)
			k:Update(dt)
		end
	end
end

return LearningUI