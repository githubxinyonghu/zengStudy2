local function ParseKey(name)
	local v = GetModConfigData(name.."_v2")
	if v == false then
		return nil
	else
		v = tostring(v):lower()
		return string.byte(v)
	end
end

GLOBAL.HOMURA_GLOBALS.SKILLKEY = ParseKey("skillkey")
GLOBAL.HOMURA_GLOBALS.SKILLKEY_STRING = GLOBAL.HOMURA_GLOBALS.SKILLKEY and string.char(GLOBAL.HOMURA_GLOBALS.SKILLKEY):upper()

GLOBAL.HOMURA_GLOBALS.RELOADKEY = ParseKey("reloadkey")
GLOBAL.HOMURA_GLOBALS.RELOADKEY_STRING = GLOBAL.HOMURA_GLOBALS.RELOADKEY and string.char(GLOBAL.HOMURA_GLOBALS.RELOADKEY):upper()

-- 2021.12.1
if BANTIMEMAGIC then
	HOMURA_GLOBALS.SKILLKEY = nil
	HOMURA_GLOBALS.SKILLKEY_STRING = nil
end

local function IsGun(weapon)
	return weapon.prefab == "homura_rpg" or weapon:HasTag("homuraTag_gun")
end

local GetCheckAmmoFn = require "homura.weapon".GetCheckAmmoFn

local function FindAmmo(weapon, items)
	local fn = GetCheckAmmoFn(weapon)
	for _,v in pairs(items)do
		if fn(v) then
			return v
		end
    end
end

local msg = {
	FUNCTION = Loc("[Auto reload - %s] ", "【%s键换弹】"),
	WEAPON = Loc("No gun in hand equip slot.", "手持栏内没有可装填的枪械。"),
	FULL = Loc("Full loaded.", "已填满。"),
	AMMO = Loc("No ammo in inventory.", "身上没带子弹。")
}

local RED 	= {207/255, 61/255, 61/255, 1}
local GREEN = {75/255, 255/255, 75/255, 1}

local function PushReloadError(err)
	if msg[err] ~= nil and ChatHistory ~= nil then
		local name = string.format(msg.FUNCTION, HOMURA_GLOBALS.RELOADKEY_STRING)
		ChatHistory:AddToHistory(ChatTypes.SystemMessage, nil, nil, name, msg[err], 
			err == "FULL" and GREEN or RED)
	end
end

-- local playercontroller = require "components/playercontroller"
local function RemoteReloadAction(self, weapon, ammo)
	local buffaction = BufferedAction(self.inst, weapon, ACTIONS.HOMURA_TAKEAMMO, ammo)
	if self.ismastersim then
		self.locomotor:PushAction(buffaction)
	else
		local function rpc()
			SendModRPCToServer(MOD_RPC["akemi_homura"].autoreload, ammo)
		end
		if self.locomotor == nil then
			rpc()
		else
			buffaction.preview_cb = rpc
			self.locomotor:PreviewAction(buffaction)
		end
	end
end

local function DoAutoReload(inst) 
	if inst.replica.health:IsDead() then return end
	if inst.components.playercontroller == nil or inst.components.playercontroller:IsBusy() then return end

	local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	local inventory = inst.replica.inventory
	if inventory == nil or weapon == nil or not IsGun(weapon) then
		PushReloadError("WEAPON")
		return
	end

	if weapon:HasTag("homuraTag_fullammo") then
		PushReloadError("FULL")
		return
	end
	local active = inventory:GetActiveItem()
	local items = inventory:GetItems()
	local container = inventory:GetOverflowContainer()
	local containeritems = container and container:GetItems() or {}
	
	local ammo = FindAmmo(weapon, {active}) or FindAmmo(weapon, items) or FindAmmo(weapon, containeritems)
	if ammo == nil then
		PushReloadError("AMMO")
	else
		RemoteReloadAction(inst.components.playercontroller, weapon, ammo)
	end
end

AddClassPostConstruct("screens/playerhud", function(self)
	self.inst:DoTaskInTime(0, function()
		local old_key = self.OnRawKey
		function self:OnRawKey(key, down, ...)
			if old_key(self, key, down, ...) then return true end
			if key == HOMURA_GLOBALS.SKILLKEY and down and 
				not TheInput:IsKeyDown(KEY_CTRL) then
				SendModRPCToServer(MOD_RPC.akemi_homura.timepause)
			elseif key == HOMURA_GLOBALS.RELOADKEY and down and 
				not TheInput:IsKeyDown(KEY_CTRL) then
				DoAutoReload(self.owner)
			end
		end
	end)
end)