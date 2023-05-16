local ALLBUFF = HOMURA_GLOBALS.ALLBUFF

------------------------------------------------------------------------------
local ice         
local wind        
local flyingspeed 
local magic       
local time        
local silent      
local waterproof  
local clip        
local mouse       
local code        
local eye_lens    
local homing      
local wormhole 
local laser    
local lens        
local knife   
------------------------------------------------------------------------------    

local function onpercent(self)
    if self.currentammo and self.maxammo then
        self.inst.replica.homura_weapon:OnPercent(self:GetPercent())
    end
end

local HomuraWeapon = Class(function(self, inst)
    self.inst = inst
    self.basic_data = {}
    self.buffed_data = {}

    local function OnBuffChanged(_, data)
        self:Apply()
        self:UpdateProjectile()
        self:UpdateName()

        local item = type(data) == "table" and (data.item or data.prev_item)
        local prefab = type(item) == "table" and item.prefab
        if prefab == "homura_weapon_buff_clip" then
            self:UpdateMaxAmmo()
        end
    end

    inst:ListenForEvent("itemget", OnBuffChanged)
    inst:ListenForEvent("itemlose", OnBuffChanged)
    inst:ListenForEvent("wetnesschange", OnBuffChanged)

    inst:ListenForEvent("onputininventory", function() self:DoDelta(0) end)
    inst:ListenForEvent("unequipped", function() self:DoDelta(0) end)

    inst:ListenForEvent("homuraevt_openbuffslot", function(_,data) self:OnOpenAt(data.desk,data.player) end)

    inst:ListenForEvent("ondropped", function() self:CloseContainer() end)

    self.no_ammo = false
    self.maxammo = 0
    self.currentammo = 0

    self.ammo_prefabname = nil -- 指定了: 1. 迷你虫洞在物品栏消耗的子弹名 2. 卸下弹夹时溢出返还的子弹名

    inst:AddTag("homuraTag_weaponpercent")
end,
nil,
{
    maxammo = onpercent,
    currentammo = onpercent,
})

local L = HOMURA_GLOBALS.LANGUAGE

function HomuraWeapon:UpdateMaxAmmo()
    if self.buffed_data.has_clip then
        self:SetMaxAmmo(self.basic_data.maxammo*ALLBUFF.clip.value)
    else
        self:SetMaxAmmo(self.basic_data.maxammo)
    end
end

function HomuraWeapon:GetNormalBuff()
    local result = {}
    local container = self.inst.components.container
    if container == nil then
        return result
    end
    for i = 1, container.numslots do
        local item = container:GetItemInSlot(i)
        local buff = item and item.homura_weapon_buff

        while buff and buff.name == "code" do
            --@-- todo 修改贴图至灰度
            local pre_item = container:GetItemInSlot(i - 1)
            buff = pre_item and pre_item.homura_weapon_buff
        end

        if buff ~= nil then
            result[buff] = (result[buff] or 0) + 1
        end
    end
    return result -- { k = buff : v = stacknum }
end

function HomuraWeapon:Apply()
    local buffs = self:GetNormalBuff()
    local buff_tags = {}
    for buff, stack in pairs(buffs)do
        buff:ApplyOnData(buff_tags, stack)
    end

    -- 计算加成后的数值
    local buffed_data = deepcopy(self.basic_data)
    for buff, stack in pairs(buffs)do
        buffed_data["has_"..buff.name] = true
        buffed_data["num_"..buff.name] = stack
    end
    for k,v in pairs(buff_tags)do

        local key, id
        for i, postfix in ipairs{ [1]="_ADD", [2]="_MULT",[3]="_REPLACE"}do
            if string.sub(k, -#postfix, -1) == postfix then
                key = string.sub(k, 1, #k - #postfix)
                id = i 
                break
            end
        end
        if id == 1 then
            buffed_data[key] = (buffed_data[key] or 0) + v
        elseif id == 2 then
            assert(buffed_data[key] ~= nil, "Key not exists: "..key)
            buffed_data[key] = buffed_data[key] * (1 + v)
        elseif id == 3 then
            buffed_data[key] = v
        else
            error("Invalid key: "..k)
        end
    end

    -- table.foreach(buffed_data, print)

    self.buffed_data = buffed_data

    --------
    local inst = self.inst
    
    if buffed_data.has_waterproof then
        if not inst.components.waterproofer then
            inst:AddComponent("waterproofer")
        end
        inst.components.waterproofer.effectiveness = 0
        if inst.components.moisturelistener then
            inst.components.moisturelistener.moisture = 0
        end
    else
        if inst.components.waterproofer then
            inst:RemoveComponent("waterproofer")
        end
        if inst:GetIsWet() then
            buffed_data.damage1 = buffed_data.damage1 * (1 + ALLBUFF.waterproof.value) -- 潮湿debuff
        end
    end

    if buffed_data.has_silent then
        self.inst:AddTag("homuraTag_silentgun")
    else
        self.inst:RemoveTag("homuraTag_silentgun")
    end

    self:UpdateProjectile()
end

function HomuraWeapon:GetBuff(name)
    return self.buffed_data[name]
end

local function oneat(inst, food)
    local health = math.abs(food.components.edible:GetHealth(inst)) * inst.components.eater.healthabsorption
    local hunger = math.abs(food.components.edible:GetHunger(inst)) * inst.components.eater.hungerabsorption
    local delta  = math.ceil((health + hunger)* 0.11)
    inst.components.homura_weapon:Fill(delta)

    if not inst.inlimbo then
        inst.SoundEmitter:PlaySound("terraria1/eyemask/eat")
    end
end

function HomuraWeapon:SetCanFeed()
    local inst = self.inst
    inst:AddTag("handfed")
    inst:AddTag("fedbyall")

    inst:AddTag("eatsrawmeat")
    inst:AddTag("strongstomach")

    inst:AddComponent("eater")
    inst.components.eater:SetOnEatFn(oneat)
    inst.components.eater:SetAbsorptionModifiers(4.0, 1.75, 0)
    inst.components.eater:SetCanEatRawMeat(true)
    inst.components.eater:SetStrongStomach(true)
    inst.components.eater:SetCanEatHorrible(true)
end

function HomuraWeapon:SetBasicParam(data)
    for _,v in ipairs{
        "speed",    -- 子弹飞行速度 距离/秒
        "range",    -- 射程
        -- "range_var",-- 射程偏移 0.9代表射程可取 (0.9~1.0)*range
        "angle",    -- 子弹最大偏角
        "damage1",  -- 伤害
        "damage2",  -- 近战伤害
        "width",    -- 子弹宽度
        "maxammo",  -- 载弹量
        "maxhits",  -- 击中计数
    }do
        assert(data[v] ~= nil)
        self.basic_data[v] = data[v]
    end

    self.basic_data.range_var = data.range_var or 1.0
    self.attackrange = data.attackrange or nil

    self.maxammo = data.maxammo
    self.currentammo = data.maxammo
    -- static
    if self.maxammo == math.huge then
        self.no_ammo = true
        self.inst:AddTag("homuraTag_no_ammo")
    end

    if data.infinite_range == true then
        self.infinite_range = true
    end

    if data.ammotaken_mult ~= nil then
        self.ammotaken_mult = data.ammotaken_mult
    end

    if data.eater then
        self:SetCanFeed()
    end

    self.buffed_data = deepcopy(data)

    self:UpdateProjectile()
    self:UpdateName()
end

function HomuraWeapon:UpdateName()
    --
end

function HomuraWeapon:PlaySound(item) --配件装备音效
    if item and item.OnPutInBuffSlotFn then
        item:OnPutInBuffSlotFn()
    end
end

function HomuraWeapon:OnLaunched(attacker)
    self:ConsumeAmmo()
end

function HomuraWeapon:ConsumeAmmo()
    if not self.no_ammo then
        if self.ammo_prefabname ~= nil and self.inst:HasTag("homuraTag_gun") and self.buffed_data.has_wormhole then 
            local owner = self.inst.components.inventoryitem.owner
            local inventory = owner and owner.components.inventory
            if inventory ~= nil then
                local ammo = next(inventory:GetItemByName(self.ammo_prefabname, 1))
                local ammo = inventory:RemoveItem(ammo, false)
                if ammo ~= nil then
                    ammo:Remove()
                    return
                end
            end
        end
        self:DoDelta(-1)
    end
end

function HomuraWeapon:SetPercent(p)
    p = math.clamp(p, 0, 1)
    self.currentammo = math.floor(self.maxammo * p)
    self:DoDelta(0)
end

function HomuraWeapon:Fill(num)
    if num > 0 then
        self:DoDelta(math.min(num, self.maxammo - self.currentammo))
    end
end

function HomuraWeapon:GetPercent()
    if self.no_ammo then
        return 1.0
    else
        return self.currentammo/self.maxammo
    end
end

function HomuraWeapon:DoDelta(num)
    if self.no_ammo then
        return
    end
    local ammo = self.currentammo
    self.currentammo = math.max(0, self.currentammo + num)
    self.inst:PushEvent("percentusedchange", {percent=self.currentammo/self.maxammo})

    self:UpdateProjectile()

    -- for action
    if self.currentammo >= self.maxammo then
        self.inst:AddTag('homuraTag_fullammo')
    else
        self.inst:RemoveTag('homuraTag_fullammo')
    end
end

function HomuraWeapon:OnAccept(item, giver)
    -- 2022.1.16 don't consume stacks for `ammotaken_mult`
    local delta1 = self.maxammo - self.currentammo
    if self.ammotaken_mult ~= nil then
        local delta2 = self.ammotaken_mult
        -- ignore overrides
        self:DoDelta(math.min(delta1, delta2))
        if item.components.stackable then
            item.components.stackable:Get():Remove()
        else
            item:Remove()
        end
        -- if self.ammotaken_replacement then
        -- end
    else
        local delta2 = item.components.stackable.stacksize
        self:DoDelta(math.min(delta1, delta2))
        item.components.homura_ammo:OnConsume(math.min(delta1, delta2))
    end

    if self.onacceptfn then
        self.onacceptfn(self.inst,item)
    end
    
    -- 2022.8.12 
    -- 已确认一个武器的弹药类型固定（不再会有普通子弹/特殊子弹/普通榴弹/特殊榴弹的区别）
    -- 所以将这一行赋值注释掉
    -- self.ammo_prefabname = item.prefab
    self:Apply()
end  

function HomuraWeapon:SetMaxAmmo(max)
    if self.no_ammo then
        return
    end

    local old_max = self.maxammo
    self.maxammo = max
    
    if self.maxammo < self.currentammo then
        local overflow = self.currentammo - self.maxammo --扔掉多余子弹
        if self.ammotaken_mult and self.ammotaken_mult > 1 then
            overflow = math.floor(overflow / self.ammotaken_mult)
        end

        local owner = self.inst.components.inventoryitem:GetGrandOwner()

        if self.ammo_prefabname ~= nil then
            local items = {}
            while overflow > 0 do
                local item = SpawnPrefab(self.ammo_prefabname)
                if item ~= nil then
                    if item.components.stackable then
                        local size = math.min(overflow, item.components.stackable:StackSize())
                        item.components.stackable:SetStackSize(size)

                        table.insert(items, item)
                        overflow = overflow - size
                    else
                        table.insert(items, item)
                        overflow = overflow - 1 
                    end
                else
                    print("[HomuraWeapon] Fail to spawn ammo! (prefab = "..tostring(self.ammo_prefabname)..")")
                    overflow = -1
                end
            end

            for _, item in ipairs(items)do
                if owner and owner.components.inventory then
                    owner.components.inventory:GiveItem(item)
                else
                    item.Physics:Teleport(self.inst.Transform:GetWorldPosition())
                end
            end
        elseif self.inst.prefab == "homura_watergun" then
            -- 水枪特殊效果: 增加玩家湿度
            if owner and owner:HasTag("player") then
                 SpawnPrefab("waterballoon_splash").Transform:SetPosition(owner.Transform:GetWorldPosition())
                if owner.components.moisture ~= nil then
                    local delta = owner.components.inventory ~= nil and 10 * (1 - math.min(owner.components.inventory:GetWaterproofness(), 1)) or 10
                    owner.components.moisture:DoDelta(delta* math.min(overflow / 16, 1))
                end
            end
        end

        self.currentammo = self.maxammo 
    end

    self:DoDelta(0)
end

function HomuraWeapon:UpdateProjectile()
    if self.currentammo == 0 then
        self.inst.components.weapon:SetProjectile(nil)
        self.inst.components.weapon:SetDamage(self.buffed_data.damage2)
        self.inst.components.weapon:SetRange(nil)
        self.inst:RemoveTag("homuraTag_ranged")
        self.inst:RemoveTag("rangedweapon")
    else
        self.inst.components.weapon:SetProjectile(self.projectile)
        self.inst.components.weapon:SetDamage(self.buffed_data.damage1)
        self.inst.components.weapon:SetRange(self.attackrange or self.buffed_data.range, self.buffed_data.range+2)
        self.inst:AddTag("homuraTag_ranged")
        self.inst:AddTag("rangedweapon")
    end
end

function HomuraWeapon:OnSave()
    return {
        currentammo = self.currentammo,
    }
end

function HomuraWeapon:OnLoad(data)
    if data then
        self.currentammo = data.currentammo
    end
end

function HomuraWeapon:GetDebugString()
    local str = '\n'
    ---[[
    for k,v in pairs(self:GetNormalBuff())do
        str = str..string.format("%s : %s\n",k.name,v)
    end
    str = str..'----------\n'
    for k,v in pairs(self.buffed_data)do
        str = str..string.format("%s : %s\n",tostring(k),tostring(v))
    end
    str = str..'\n'..self.currentammo..' / '..self.maxammo
    --]]
    return str
end

function HomuraWeapon:OnUpdate(dt)
    self.inst:StopUpdatingComponent(self)
end

function HomuraWeapon:OnOpenAt(desk, player)
    local function updatedist(inst)
        if desk and desk:IsValid() and desk:IsNear(inst, 3) and inst.replica.inventoryitem:IsHeld() then
            inst:DoTaskInTime(0.1, updatedist)
        else
            self:DetachWorkdesk()
        end
    end
    desk.user = player
    desk.gun = self.inst
    self.desk = desk
    self.inst:DoTaskInTime(0, updatedist)
end

function HomuraWeapon:DetachWorkdesk()
    local desk = self.desk
    local player = desk and desk.user
    self:CloseContainer()

    if desk then
        desk.user = nil 
        desk.gun = nil
        self.desk = nil
    end
    if player then
        player:PushEvent("closecontainer", {container = self.inst})
    end
end

function HomuraWeapon:CloseContainer()
    if self.inst.components.container ~= nil and self.inst.components.container:IsOpen() then
        return self.inst.components.container:Close()
    end
end

return HomuraWeapon

