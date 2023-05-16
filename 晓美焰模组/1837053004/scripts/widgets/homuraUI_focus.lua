local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"

local easing = require "easing"

local TICK_INTERVAL = 0.3
local RADIUS = 100
local RADIUS_PERCENT = 0.1
local MAGNIFY = 2

local BASE_COLOUR = {0.1,1,0.1,0.4}
local FLASH_COLOUR = {1,0.7,0.7,1}
local LOCK_COLOUR = {1,0.2,0.2,1}

local function torgba(r,g,b,a)
	return {r=r,g=g,b=b,a=a}
end

local Focus = Class(Widget, function(self, owner)
	Widget._ctor(self, "homuraUI_focus")
	self.owner = owner

	self:SetHAnchor(ANCHOR_LEFT)
	self:SetVAnchor(ANCHOR_BOTTOM)
	self:SetScaleMode(SCALEMODE_FILLSCREEN)

	self.root = self:AddChild(Widget("root"))
	-- self.root:SetClickable(false)

	self.shake = self.root:AddChild(Widget("shake"))

	self.aim = self.shake:AddChild(Image("images/hud/homuraUI_focus.xml", "homuraUI_focus.tex"))
	self.aim:SetSize(RADIUS*2,RADIUS*2)

	self.process = self.shake:AddChild(Image("images/hud/homuraUI_focus_ring.xml", "homuraUI_focus_ring.tex"))
	self.process:SetSize(RADIUS*2,RADIUS*2)
	self.process:SetEffect(resolvefilepath "shaders/mami_circle.ksh")
	self.process:SetEffectParams(0,0,0,0)
	self.process:SetRotation(180)
	self.process:SetScale(-1,1)

	self.currenttime = 0 
	self.dropcache = -1
	self.maxtime = 3

	self.vel = Vector3(0,0,0)

	self.joystick_control = {}
	self.screenradius = 0

	self.inst:ListenForEvent("homura_snipemode", function(_, v)
		if v then
			self:Open()
		else 
			self:Close()
		end
	end, owner)

	self.inst:ListenForEvent("homura_snipeshoot", function()
		self:OnShoot()
	end, owner)

	self.inst:ListenForEvent("homuraevt_rotcamera", function()
		self:LoseAim(0)
	end)

	self:Close()
end)

local function GetControllerVector()
    local xdir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_LEFT)
    local ydir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_UP) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_DOWN)
    local deadzone = .2
    if xdir*xdir + ydir*ydir >= deadzone*deadzone then
    	return Vector3(xdir, ydir)*2
    end
end

local JOYSTICK_FOCUS_CONTROL = {
	CONTROL_INVENTORY_UP = true,
	CONTROL_INVENTORY_DOWN = true,
	CONTROL_INVENTORY_RIGHT = true,
	CONTROL_INVENTORY_LEFT = true,
}

function Focus:Open()
	HOMURA_GLOBALS.SetFocusEnabled(true)
	TheInputProxy:SetCursorVisible(false)
	self.root:Show()
	self:StartUpdating()

	-- 2021.10.1 move to snipe state, handled by self:PointCursorAtTarget()
	-- local mousepos = TheInput:GetScreenPosition()
	-- self.root:SetPosition(mousepos)-- + Vector3(GetRandomMinMax(-32,32), GetRandomMinMax(-32,32), 0))

	self.currenttime = 0 
	self.dropcache = -1
	self.islocked = false
	self.rmbreleased = false
	self:SetTint(unpack(BASE_COLOUR))
end

function Focus:Close()
	HOMURA_GLOBALS.SetFocusEnabled(false)
	if not TheInput:ControllerAttached() then
		TheInputProxy:SetCursorVisible(true)
	end
	self.root:Hide()
	self:StopUpdating()

	SendModRPCToServer(MOD_RPC["akemi_homura"]["exitsniping"])
end

function Focus:LoseAim(dt)
	if self.islocked then 
		self:Unlock()
	end
	if self.dropcache < 0 then 
		self.dropcache = 0
	else
		self.dropcache = self.dropcache + dt 
		self.currenttime = math.min(self.currenttime + dt, self.maxtime)
		if self.dropcache > TICK_INTERVAL then
			self.currenttime = 0 
			self.dropcache = -1
		end
	end
end

function Focus:AddAim(dt)
	if TheInput:IsControlPressed(CONTROL_ATTACK) or 
		TheInput:IsControlPressed(CONTROL_PRIMARY) or
		TheInput:IsControlPressed(CONTROL_CONTROLLER_ATTACK) then 
		dt = dt * 0.5
	end
	if self.islocked then
		dt = dt * 1.5
	end

	if self.currenttime < self.maxtime then
		self.currenttime = self.currenttime + dt 

		if self.currenttime >= self.maxtime then
			self.currenttime = self.maxtime
			self:Lock()
		end
	end
end

function Focus:Lock()
	self.islocked = true
	TheFrontEnd:GetSound():PlaySound("lw_homura/focus/lock", nil, 0.5)
	self:TintTo(torgba(unpack(FLASH_COLOUR)),torgba(unpack(LOCK_COLOUR)), 1)
end

function Focus:Unlock()
	self.islocked = false
	self:TintTo(torgba(unpack(LOCK_COLOUR)), torgba(unpack(BASE_COLOUR)), 0.4)
end

function Focus:CanShoot()
	return self.root.shown and self.currenttime >= self.maxtime
end

function Focus:CanReleaseControl(control) 
	-- 是否放行和射击相关的控制 CONTROL_ATTACK, CONTROL_PRIMARY
	-- * 未开镜
	-- * 开镜+锁定+鼠标下方有可攻击的实体
	if not self.root.shown then 
		return true
	elseif  control == CONTROL_ATTACK or control == CONTROL_CONTROLLER_ATTACK then -- 通过self:OnControl转发
		return false
	elseif self:CanShoot() then
		if TheInput:ControllerAttached() then
			-- 手柄模式下检测目标与准心的距离
			local target = self.owner.components.playercontroller:GetControllerAttackTarget()
			if target and self.owner.replica.combat:IsValidTarget(target) then
				local pos = target:GetPosition()
				local screenpos = Vector3(TheSim:GetScreenPos(pos:Get()))
				local aimpos = self.aim:GetWorldPosition()
				if DistXYSq(screenpos, aimpos) < self.screenradius * self.screenradius then
					return true
				end
			end
		else
			local target = TheInput:GetWorldEntityUnderMouse()
			return target ~= nil and self.owner.replica.combat:IsValidTarget(target)
		end
	end
end

function Focus:CanReleaseControl(control)
	-- feature
	if not self.root.shown then
		return true
	elseif control == CONTROL_PRIMARY or control == CONTROL_ATTACK or control == CONTROL_CONTROLLER_ATTACK then
		return false
	else
		return true
	end
end

function Focus:OnShoot()
	self.currenttime = self.maxtime * 0.5 
	-- self.shaking = true
	self.shake:MoveTo(
		Point(0,0,0), 
		Vector3(GetRandomMinMax(-1,1), GetRandomMinMax(10,12), 0),
		0.1,
		function() self.shake:MoveTo(
			self.shake:GetPosition(),
			Point(0,0,0),0.4, function() self.shaking = false end)
		end
	)
end


function Focus:SetTint(...)
	self.aim:SetTint(...)
	self.process:SetTint(...)
end

function Focus:TintTo(...)
	self.aim:TintTo(...)
	self.process:TintTo(...)
end

function Focus:UpdateRing()
	local t = easing.outSine(self.currenttime-0.1, 0, 1, self.maxtime)
	self.process:SetEffectParams(0.45,0.45,t*PI*2,1)
end

function Focus:MoveCursorTo(x, y)
	TheInputProxy:SetOSCursorPos(x, y)
end

function Focus:PointCursorAtTarget(target)
	if target ~= nil and target.IsVector3 then
		local x, y = TheSim:GetScreenPos(target:Get())
		self.lastpos = Vector3(x,y,0)
		self.root:SetPosition(x,y)
	elseif target ~= nil and target:IsValid() --[[and TheInput:ControllerAttached()]] then
		local w, h = TheSim:GetScreenSize()
		local x, y = TheSim:GetScreenPos(target.Transform:GetWorldPosition())
		local padding = 0.1
		if x <= 0 then
			x = padding*w
		end
		if x >= w then
			x = (1- padding)*w
		end
		if y <= 0 then
			y = padding*h
		end
		if y >= h then
			y = (1- padding)*h
		end
		self.lastpos = Vector3(x,y,0)
		self.root:SetPosition(x,y)
		if not TheInput:ControllerAttached() then
			self:MoveCursorTo(x,y)
		end
	end
	self:UpdateShader()
end

function Focus:Shoot()
	local pos = self:GetFocusWorldPosition()
	local ent = not TheInput:ControllerAttached() and TheInput:GetWorldEntityUnderMouse() or nil
	if ent and self.owner.replica.combat:IsValidTarget(ent) then
		pos = ent:GetPosition()
	end
	if pos then
		local x,y,z = pos:Get()
		self.owner:PushEvent("homuraevt_snipeshoot", {x = x, z = z})
		if not TheWorld.ismastersim then
			SendModRPCToServer(MOD_RPC.akemi_homura.snipeshoot, x, z)
		end
	end
end

function Focus:LockInvBar() -- Lock inventory cursor when focus is enabled (see modmain/ui.lua)
	return self.root.shown
end

function Focus:GetFocusWorldPosition() -- For playercontroller joystick target
	if self.root.shown then
		return Vector3(TheSim:ProjectScreenPos(self.root:GetPosition():Get()))
	end
end


function Focus:OnUpdate(dt)
	if getmetatable(TheNet).__index.IsServerPaused ~= nil --[[兼容旧版本]] and TheNet:IsServerPaused() then
		return
	end

	if not TheInput:IsControlPressed(CONTROL_SECONDARY) then 
		self.rmbreleased = true
	elseif self.rmbreleased then -- Pressing rmb and have released before
		self:Close()
		return
	end

	local rootpos = self.root:GetPosition()
	local mousepos = TheInput:GetScreenPosition()
	local w,h = TheSim:GetScreenSize()

	if TheInput:ControllerAttached() then
		mousepos = rootpos
		local joystick_delta = dt*math.max(w, h)
		local vec = GetControllerVector()
		if vec ~= nil then
			mousepos = mousepos + vec* joystick_delta
		else
		end
	end

	local offset = mousepos - rootpos
	local norm, len = offset:GetNormalizedAndLength()

	if self.lastpos == nil then 
		self.lastpos = mousepos
	elseif self.dropcache >= 0 then 
		self:LoseAim(dt)
	elseif self.lastpos:DistSq(mousepos) > 4 then 
		self:LoseAim(dt)
	else
		self:AddAim(dt)
	end

	-- self.root:SetClickable(not self:CanShoot())
	
	self.lastpos = mousepos

	if self.shaking then 
		-- pass
	elseif len < 1e-4 then 
		-- pass
	else
		local move = math.min(len, len*0.5+8, len*0.25+16, len*0.1+32)*0.4
		self.root:SetPosition(rootpos + norm* move)
	end

	self:UpdateRing()

	self.root:SetScale(RADIUS_PERCENT*w/RADIUS)
	self.screenradius = RADIUS_PERCENT*w
	self:UpdateShader()
end

function Focus:UpdateShader()
	local w,h = TheSim:GetScreenSize()
	local x,y = self.aim:GetWorldPosition():Get()
	HOMURA_GLOBALS.SetFocusParams(x/w, y/h, RADIUS_PERCENT, MAGNIFY)
end

function Focus:OnControl(control, down)
	if not self.root.shown then 
		return
	end

	local target = TheInput:GetWorldEntityUnderMouse()

	if control == CONTROL_ACCEPT or control == CONTROL_ATTACK or control == CONTROL_CONTROLLER_ATTACK then
		if self:CanShoot() then
			self:Shoot() 
		end
		return true
	end

	-- if control == CONTROL_ATTACK then 
	-- 	if self:CanReleaseControl() then
	-- 		if self.owner.components.playercontroller ~= nil then 
	-- 			self.owner.components.playercontroller:DoAttackButton(target)
	-- 		end
	-- 	end
	-- 	return true
	-- end

	-- if control == CONTROL_CONTROLLER_ATTACK then 
	-- 	if self:CanReleaseControl() then 
	-- 		if self.owner.components.playercontroller ~= nil then 
	-- 			self.owner.components.playercontroller:DoControllerAttackButton(target)
	-- 		end
	-- 	end
	-- 	return true
	-- end

	if JOYSTICK_FOCUS_CONTROL[control] ~= nil then
		self.joystick_control[control] = down
		return true
	end

	-- if control == CONTROL_PRIMARY or control == CONTROL_ACCEPT then 
	-- 	if target == nil then 
	-- 		return true
	-- 	end
	-- end

	if control == CONTROL_CANCEL and down then 
		self:Close()
		return true
	end
end

local L = HOMURA_GLOBALS.L
local attack = L and "Shoot" or "射击"
local aim = L and "Aim" or "瞄准"
local cancel = L and "Cancel" or "取消"

function Focus:HasExclusiveHelpText()
	-- print("HasExclusiveHelpText")
	return self.root.shown
end

function Focus:GetHelpText()
	-- print("GetHelpText")
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if self.root.shown then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ATTACK, false, false).. " "..attack)
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL, false, false).. " "..cancel)
		local dirs = {}
		table.foreach(JOYSTICK_FOCUS_CONTROL, function(k) 
			table.insert(dirs, TheInput:GetLocalizedControl(controller_id, k, false, false))
		end)
		table.insert(t, table.concat(dirs, "/").. " "..aim)
		return table.concat(t, "  ")
	else
		return ""
	end
end


return Focus