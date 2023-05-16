local ClientKey = Class(function(self, inst)
	self.inst = inst
	self.ismastersim = TheWorld.ismastersim
	self.isclient = not self.ismastersim

	inst:ListenForEvent("playeractivated", function() self:Init() end)
	inst:ListenForEvent("playerdeactivated", function() self:Remove() end)

	self.attack = false
	self.raction = false

	self.mouseover = nil
end)

function ClientKey:Remove()
	if self.handler ~= nil then
		self.handler:Remove()
		self.handler = nil
	end
end

ClientKey.OnRemoveEntity = ClientKey.Remove
ClientKey.OnRemoveFromEntity = ClientKey.Remove

function ClientKey:Init()
	self:Remove()
	if self.inst == ThePlayer then
		self.handler = TheInput:AddGeneralControlHandler(function(...) self:OnControl(...) end)
		self.inst:StartUpdatingComponent(self)
	end
end

local CONTROLS_ATTACK = {
	[CONTROL_PRIMARY] = true,
	[CONTROL_ATTACK] = true,
	[CONTROL_CONTROLLER_ATTACK] = true,
}

local CONTROLS_R_ACTION = {
	[CONTROL_SECONDARY] = true,
	[CONTROL_CONTROLLER_ALTACTION] = true
}

function ClientKey:OnControl(control, down)
	if control ~= nil then
		down = not (not down)
		if CONTROLS_ATTACK[control] then
			self:HandleAttack(down)
		elseif CONTROLS_R_ACTION[control] then
			self:HandleRAction(down)
		end
	end
end

function ClientKey:HandleAttack(down)
	if self.attack ~= down then
		self.attack = down
		if self.isclient then
			SendModRPCToServer(MOD_RPC.akemi_homura.clientkey, "attack", down)
		end
	end
	if down and self.handler ~= nil then
		self.inst:StartUpdatingComponent(self)
	end
end

function ClientKey:HandleRAction(down)
	if self.raction ~= down then
		self.raction = down
		if self.isclient then
			SendModRPCToServer(MOD_RPC.akemi_homura.clientkey, "raction", down)
		end
	end
	if down and self.handler ~= nil then
		self.inst:StartUpdatingComponent(self)
	end
end

function ClientKey:OnRemoteKey(type, down)
	if self.isclient then return end

	down = not (not down)
	if type == "attack" then
		self:HandleAttack(down)
	elseif type == "raction" then
		self:HandleRAction(down)
	end
end

function ClientKey:IsPressing(type)
	if type == "attack" or type == "raction" then
		return self[type]
	end
end

function ClientKey:OnRemoteEnt(ent)
	if optentity(ent) then
		self.mouseover = ent
	end
end

function ClientKey:OnUpdate(dt)
	-- collect mouseover entity when LMB is pressed.
    local ent = TheInput:IsControlPressed(CONTROL_PRIMARY) and TheInput:GetWorldEntityUnderMouse() or nil
    if ent ~= self.mouseover then
    	self.mouseover = ent
    	if self.isclient then
    		SendModRPCToServer(MOD_RPC.akemi_homura.mouseover, ent)
    	end
    end
    if self:IsPressing("raction") then
    	-- todo 检查手柄兼容性
		local pos = TheInput:GetWorldPosition()
		if self.inst.components.playercontroller 
			and self.inst.components.playercontroller.reticule ~= nil
			and self.inst.components.playercontroller.reticule.targetpos ~= nil then
			pos = self.inst.components.playercontroller.reticule.targetpos
		end

		if pos then
			local x, y, z = pos:Get()
			self:SetXZ(x, z)
		end
    end
    if not self:IsPressing("raction") and not self:IsPressing("attack") then
    	-- rpc will NOT send after stop updating
    	self.inst:StopUpdatingComponent(self)
    end
end

function ClientKey:SetXZ(x, z)
	if x ~= self.mousex or z ~= self.mousez then
		self.mousex = x
		self.mousez = z
		if self.isclient then
			SendModRPCToServer(MOD_RPC.akemi_homura.mousexz, x, z)
		end
	end
end

function ClientKey:OnRemoteXZ(x, z)
	self.mousex = x
	self.mousez = z
end

function ClientKey:GetWorldPosition()
	return Vector3(self.mousex, 0, self.mousez)
end

return ClientKey