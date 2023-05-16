local INV = 10
local PRO = 3
--该组件会为刚出手的物体添加一个10帧的时间魔法抗性，优化攻击手感（可加可不加）

local IgnoreTime = Class(function(self, inst)           
    self.inst = inst
    self.resist = 0 
    self.max_resist = 0
    self.leave = false

    self.inst:ListenForEvent("onputininventory",function()self:ReturnToOwner()end)
    self.inst:ListenForEvent("onpickup",function ()self:ReturnToOwner() end)
    self.inst:ListenForEvent("ondropped",function ()self:SetInventory() self:LeaveOwner() end)
    self.inst:ListenForEvent("onthrown",function()self:SetProjectile() self:LeaveOwner() end) --子弹组件
    self.inst:ListenForEvent("homura.onthrown",function ()self:SetThrowable() self:LeaveOwner() end) --投掷组件

    self.inst:ListenForEvent('itemget', function(_, data) self:OnGetItem(data and data.item) end)
    self.inst:ListenForEvent('itemlose', function(_, data) self:OnLoseItem() end)

    self.inst:ListenForEvent('onopen', function() self:AddTag("OPENER") end)
    self.inst:ListenForEvent('onclose', function() self:RemoveTag("OPENER") self:SetInventory() self:LeaveOwner() end)

    self.tagsourse = {}
end)

function IgnoreTime:AddTag(sourse)
    self.tagsourse[sourse] = true
    self.inst:AddTag('homuraTag_ignoretimemagic_temp')
end

function IgnoreTime:RemoveTag(sourse)
    self.tagsourse[sourse] = nil
    if next(self.tagsourse) == nil then
        self.inst:RemoveTag('homuraTag_ignoretimemagic_temp')
    end
end

local function HasClock(inst)
    if inst and inst:IsValid() then
        return inst.components.container and inst.components.container:Has('homura_clock', 1)
            or inst.components.inventory and inst.components.inventory:Has('homura_clock', 1)
    end
end

function IgnoreTime:OnGetItem(item)
    if item and item.prefab == 'homura_clock' then
        self:AddTag('CLOCK')
    end
end

function IgnoreTime:OnLoseItem()
    if not HasClock(self.inst) then
        self:RemoveTag('CLOCK')
    end
end

function IgnoreTime:DoDec()
    if self.leave then
        self.resist = self.resist - 1
        if self.resist <= 0 then
            self.inst:StopUpdatingComponent(self)
            self:RemoveTag("UPDATE")
        end
    end
end

function IgnoreTime:IsIgnoring() --用标签判定
    return self.inst:HasTag('homuraTag_ignoretimemagic_temp')
end

function IgnoreTime:LeaveOwner() --开始倒计时
    self.resist = self.max_resist
    self:StartUpdating()
end

function IgnoreTime:ReturnToOwner() --停止倒计时，并刷新
    self.leave = false
    self.inst:StopUpdatingComponent(self)
end

function IgnoreTime:Set(num)
    self.max_resist = num
end

function IgnoreTime:SetInventory()
    self.max_resist = INV
end

function IgnoreTime:SetProjectile(speed)
    local speed = speed or (self.inst.components.projectile and self.inst.components.projectile.speed)
    
    if not speed then
        self.max_resist = 3
    elseif speed < 25 then
        self.max_resist = PRO
    elseif speed < 50 then
        self.max_resist = PRO/3
    elseif speed < 75 then
        self.max_resist = 0
    else
        self.max_resist = 0
    end
end

function IgnoreTime:SetThrowable()
    self.max_resist = PRO
    self.resist = PRO
end

function IgnoreTime:AddResistance(value)
    self.max_resist = self.max_resist+value
    self.resist = self.resist+value
end

function IgnoreTime:StartUpdating()
    self:AddTag('UPDATE')
    self.leave = true
    self.inst:StartUpdatingComponent(self)
end

function IgnoreTime:OnUpdate()
    self:DoDec()
end

return IgnoreTime