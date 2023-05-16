assert(false, "This file is deprecated.")

local HomuraFocus = Class(function(self, inst)
	self.inst = inst

	inst._focus_target = net_entity(inst.GUID, 'homuraweapon.focus', 'homuraweapon.focusdirty')
    inst._to_focus_target = net_entity(inst.GUID, 'homuraweapon.tofocus', 'homuraweapon.tofocusdirty')
    inst._focus_enabled = net_bool(inst.GUID, 'homuraweapon.focus_enabled', 'homuraweapon.focusenableddirty')

    --[[
    if not TheWorld.ismastersim then
        inst:ListenForEvent('homuraweapon.focusdirty', function()
            local owner = inst.replica.inventoryitem:GetGrandOwner()
            if owner then
                owner:PushEvent('homura.StartFocus',{target = inst._focus_target:value()})
            end
        end)
    end
    --]]
end)

local function IsValid(inst)
	return inst and inst:IsValid()
end

function HomuraFocus:IsFocusing() --这个函数仅在sg内判定, 所以不需要考虑武器是否被玩家装备
	if self.inst.components.homura_focus then
		return self.inst.components.homura_focus:IsFocusing()
	else
		return self.inst:HasTag('homuraTag_ranged') and IsValid(self.inst._to_focus_target:value())
	end
end

function HomuraFocus:IsFocused()
	if self.inst.components.homura_focus then
		return self.inst.components.homura_focus:IsFocused()
	else
		return self.inst:HasTag("homuraTag_ranged") and IsValid(self.inst._focus_target:value())
	end
end

function HomuraFocus:ShouldFocus(newtarget)
	if self.inst.components.homura_focus then
        --print(0)
		return self.inst.components.homura_focus:ShouldFocus(newtarget)
	end

    if not newtarget then --根本没传参数
        print(1)
        return false
    end
    if not self.inst._focus_enabled:value() then --没有安装瞄准镜
        print(2)
        return false
    end
    if not self.inst:HasTag('homuraTag_ranged') then --没有子弹
        return false
    end
    if not self:IsFocused() and not self:IsFocusing() then  --初始状态
        return true
    end
    if self:IsFocused() and self.inst._focus_target:value() ~= newtarget then --锁定状态下选择新目标
        return true
    end
    if self:IsFocusing() and self.inst._to_focus_target:value() ~= newtarget then --锁定过程中选择新目标
        return true
    end
end

function HomuraFocus:ShouldShowFocusTooltip(newtarget)
    if self.inst.components.homura_focus then
        return self.inst.components.homura_focus:ShouldShowFocusTooltip(newtarget)
    end
    if not self.inst:HasTag('homuraTag_ranged') or not self.inst._focus_enabled:value() then
        return false
    end
    if self:IsFocused() and self.inst._focus_target:value() == newtarget then
        return false
    end
    return true
end

return HomuraFocus
