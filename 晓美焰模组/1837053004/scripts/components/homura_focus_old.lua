assert(false, "This file is deprecated.")

local FOCUS_DURATION = 20

local function onfocustarget(self, p)
    self.inst._focus_target:set(p)
end

local function onsetnewtarget(self, p)
    self.inst._to_focus_target:set(p)
end

local function onsetenabled(self, p)
    self.inst._focus_enabled:set(p ~= nil and p ~= false) --这个变量只能为true或false
end

local HomuraFocus = Class(function(self, inst)
    self.inst = inst

    inst:ListenForEvent('homura.StartFocus', function(i,data)
        self.to_focustarget = data.target 
        self.focustarget = nil
        self.focustimer = -1
    end)
    inst:ListenForEvent('homura.FinishFocus',function (i,data)  --发出者: sg
        self.focustarget = self.to_focustarget
        self.to_focustarget = nil
        self.focustimer = FOCUS_DURATION
        self.inst:StartUpdatingComponent(self) --开始20秒倒计时
    end)
    inst:ListenForEvent('homura.AbruptFocus',function(i,data) --发出者: sg
        self.to_focustarget = nil
        self.focustarget = nil
        self.focustimer = -1
    end)
    
    inst:ListenForEvent('unequipped',function(i,data) 
        if self.focustarget and data.owner then
            data.owner:PushEvent('homura.AbruptFocus')
            data.owner._uifocus_state:set(2)
        end
        self.to_focustarget = nil
        self.focustarget = nil
        self.focustimer = -1
    end)
    
    self.focustimer = 0
end,
nil,
{
    focustarget = onfocustarget,
    to_focustarget = onsetnewtarget,
    enabled = onsetenabled,
})

local L = HOMURA_GLOBALS.LANGUAGE

function HomuraFocus:ShouldFocus(newtarget)
    if not newtarget then --根本没传参数
        return false
    end
    if not self.enabled then --没有安装瞄准镜
        return false
    end
    if not self.inst.components.weapon.projectile then --没有子弹
        return false
    end
    if not (self.focustarget and self.focustarget:IsValid()) and not self.to_focustarget then  --初始状态
        --print(01)
        return true
    end
    if self.focustarget and self.focustarget ~= newtarget then --锁定状态下选择新目标
        --print(02)
        return true
    end
    if self.to_focustarget and self.to_focustarget ~= newtarget then --锁定过程中选择新目标
        --print(03)
        return true
    end
end

function HomuraFocus:IsFocusing()
    if not self.inst.components.weapon.projectile then
        return false
    end
    return self.inst.components.equippable:IsEquipped() and self.to_focustarget
end

function HomuraFocus:IsFocused()
    if not self.inst.components.weapon.projectile then
        return false
    end
    return self.inst.components.equippable:IsEquipped() and self.focustarget and self.focustarget:IsValid()
end

function HomuraFocus:OnUpdate(dt)
    if self.focustimer > 0 then
        self.focustimer = self.focustimer - dt
        if self.focustimer <= 0 then
            local owner = self.inst.components.inventoryitem:GetGrandOwner()
            if owner and owner._uifocus_state then
                owner:PushEvent('homura.AbruptFocus')
                owner._uifocus_state:set(2)
            end
            self.focustarget = nil
            self.to_focustarget = nil
            self.inst:StopUpdatingComponent(self)
        end
    end
    if self.focustimer <= 0 then
        self.inst:StopUpdatingComponent(self)
    end
end

function HomuraFocus:ShouldShowFocusTooltip(newtarget)
    if not self.enabled or not self.inst.components.weapon.projectile then
        return false
    end
    if self:IsFocused() and self.focustarget == newtarget then 
        return false
    end
    return true
end

return HomuraFocus

