local DeltaAngleAbs = require "homura.math".DeltaAngleAbs

local function HookComponent(name, fn)
    fn(require ("components/"..name))
end

AddReplicableComponent("homura_weapon")

local function OnBowBlast(inst)
    if ThePlayer ~= nil then
        ThePlayer.components.homura_bowblast:Blast(inst)
    end
end

AddPlayerPostInit(function(inst)
    inst.homura_bowblast = net_event(inst.GUID, "homura_bowblast") -- attach to player instance to notify all players!

    inst:DoTaskInTime(0, function()
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("homura_bowblast", OnBowBlast)
        end
    end)

    if TheWorld.ismastersim then
        inst:AddComponent("homura_lightshocked")    -- 致盲
        inst:AddComponent("homura_sniper")          -- 狙击
        inst:AddComponent("homura_rusher")          -- 冲刺动作
        inst:AddComponent("homura_reader")          -- 阅读
        inst:AddComponent("homura_archer")          -- 射箭
        inst:AddComponent("homura_boxopener")       -- 空投

        if inst.components.combat then
            local old_get = inst.components.combat.GetBattleCryString
            inst.components.combat.GetBattleCryString = function(combat, target)
                if (combat:GetWeapon() or {}).prefab == "homura_stickbang" then
                    return STRINGS.NAMES.HOMURA_STICKBANG_RUSH
                else
                    return old_get(combat, target)
                end
            end
        end
    end

    inst:AddComponent("homura_clientkey")
end)

AddPrefabPostInitAny(function(inst)
    if inst.components.combat then
        local old_killed = inst.components.combat.onkilledbyother
        if old_killed then
            inst.components.combat.onkilledbyother = function(...)
                if not inst.components.health:IsDead() then
                    return
                end
                old_killed(...)
                inst.components.combat.onkilledbyother = nil
            end
        end
    end
end)

--在时停期间隐藏的本地特效
local function DontShowInTimeMagic(inst)
    if ThePlayer and ThePlayer.lw_timemagic_inrange then
        inst:Hide()
    end
end

for _,v in pairs{"raindrop","wave_shimmer","wave_shimmer_med",
"wave_shimmer_deep","wave_shimmer_flood","wave_shore","impact","shatter",}do 
    AddPrefabPostInit(v, DontShowInTimeMagic) 
end

local function SetImmune(inst)
    inst:AddTag("homuraTag_ignoretimemagic")
end

for _,v in pairs{"dyc_damagedisplay","damagenumber",'boat_player_collision','boat_item_collision'}do
    AddPrefabPostInit(v, SetImmune)
end

--船的物理修复
local function OnBoatStop(inst)
    if inst.lw_mvels then
        inst.components.boatphysics.velocity_x = inst.lw_mvels[1]
        inst.components.boatphysics.velocity_z = inst.lw_mvels[3]
    end
end

AddPrefabPostInit("boat", function(inst) 
    inst.lw_timemagic_onstop = OnBoatStop
end)

-- HookComponent("health", function(Health)

--     local function OnStop(inst)
--         inst:AddTag("NOCLICK")
--     end

--     local old_setval = Health.SetVal 
--     function Health:SetVal(val, ...)
--         local clickable = not self.inst:HasTag("NOCLICK")

--         old_setval(self, val, ...)

--         if val <= 0 and self.inst:HasTag("homuraTag_pause") and not self.inst:HasTag("homuraTag_die") then
--             if not self.inst:HasTag("homuraTag_livecorpse") then
--                 self.inst:AddTag("homuraTag_livecorpse")
--                 if clickable then
--                     self.inst:RemoveTag("NOCLICK")
--                     self.inst:ListenForEvent("homuraevt_timemagic_stop", OnStop)
--                 end
--             end
--         end
--     end
-- end)

--2019.8.19
--如果一个生物在时停期间被击杀, 则在其位置生成一个隐性的目标, 并将玩家的仇恨转移到这个目标上(如果有)

--2021.6.1 
--修复bug，函数放外面优化内存占用
-- local function OnDeath(inst, data)
--     if inst.components.health and inst.components.combat then
--         if not inst:HasTag('homuraTag_pause') then
--             inst:AddTag('homuraTag_die') -- 标记，进入时停后不再僵直
--         else
--             if not inst:HasTag('homuraTag_die') then
--                 local faketarget = SpawnPrefab('fake_target_death')
--                 faketarget:LinkTo(inst)
--             end
--         end
--     end
-- end
-- AddPrefabPostInitAny(function(inst)
--     inst:ListenForEvent("death", OnDeath)
-- end)

-- HookComponent("combat", function(Combat)
--     local old_valid = Combat.IsRecentTarget
--     function Combat:IsRecentTarget(target, ...)
--         if target and target.prefab == 'fake_target_death' then
--             return old_valid(self, target.homuraEnt_fake, ...)
--         else
--             return old_valid(self, target, ...)
--         end
--     end
-- end)

-- HookComponent("combat_replica", function(Combat)
--     local old_valid = Combat.IsRecentTarget
--     function Combat:IsRecentTarget(target, ...)
--         if target and target.prefab == 'fake_target_death' then
--             return old_valid(self, target.entity:GetParent(), ...)
--         else
--             return old_valid(self, target, ...)
--         end
--     end
-- end)
-- 
-- 2021.12.16 klei使用了新的api，我们也适应新版本吧

do
    local old_dead = IsEntityDead
    function GLOBAL.IsEntityDead(inst, require_health)
        if inst:IsValid() and not inst.inlimbo and inst:HasTag("homuraTag_livecorpse") then
            return false
        else
            return old_dead(inst, require_health)
        end
    end
end

local function IsBack(attacker, target)
    if target:IsValid() and target.Transform and attacker:IsValid() and attacker.Transform then
        local angle1 = target.Transform:GetRotation()
        local angle2 = target:GetAngleToPoint(attacker:GetPosition())
        local deltaangle = DeltaAngleAbs(angle1, angle2)
        if deltaangle > 100 then
            return true
        elseif deltaangle > 80 and math.random() < 0.75 then
            return true
        end
    end
end 

HookComponent("combat", function (Combat)

    local old_hit = Combat.GetAttacked
    function Combat:GetAttacked(...)
        local snd = self.hurtsound
        if self.inst:HasTag('homuraTag_pause') then
            self.hurtsound = nil
        end
        old_hit(self, ...)
        if not self.hurtsound then
            self.hurtsound = snd
        end
    end

    local old_settarget = Combat.SetTarget
    function Combat:SetTarget(target, ...)
        if target and target:HasTag('homuraTag_silencer') and IsBack(target, self.inst) then
            return
        else
            return old_settarget(self, target, ...)
        end
    end

    local old_share = Combat.ShareTarget
    function Combat:ShareTarget(target, ...)
        if target and target:HasTag('homuraTag_silencer') and IsBack(target, self.inst) then
            return
        else
            return old_share(self, target, ...)
        end
    end

    local old_canhit = Combat.CanHitTarget
    function Combat:CanHitTarget(target,...)
        if target and target.prefab == 'fake_target_player' and target._parent == self.inst then
            return false
        end
        --@--
        if target and target.prefab == 'fake_target_common' and target._parent == self.inst then
            return false
        end

        return old_canhit(self, target, ...)
    end

end)
---[[
HookComponent("combat_replica", function(Combat)
    local old_isvalid = Combat.IsValidTarget
    function Combat:IsValidTarget(target, ...)
        if target and (target.prefab == 'fake_target_common' or target.prefab == 'fake_target_player') then
            if target.entity:GetParent() ~= self.inst then
                return false
            end
        end
        return old_isvalid(self, target, ...)
    end
end)
--]]


HookComponent('armor', function(Armor) 
    local old_can = Armor.CanResist
    function Armor:CanResist(attacker, weapon, ...)
        if (attacker and attacker:HasTag('homuraTag_ignorearmor')) or (weapon and weapon:HasTag('homuraTag_ignorearmor')) then
            return false
        else
            return old_can(self, attacker, weapon, ...)
        end
    end
end)

HookComponent('complexprojectile', function(self)
    local old_launch = self.Launch
    function self:Launch(...)
        self.inst:PushEvent('homura.onthrown')
        old_launch(self, ...)
    end
end)

do -- 炸弹系物品不会掉落灵魂
    local wortox = require("prefabs/wortox_soul_common")
    local old_soul = wortox.HasSoul
    wortox.HasSoul = function(inst, ...)
        if inst.prefab == 'homura_detonator' or inst:HasTag('homura_bomb') then
            return false
        else
            return old_soul(inst, ...)
        end
    end
end

