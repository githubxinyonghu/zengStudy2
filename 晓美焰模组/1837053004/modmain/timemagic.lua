-- 总控制中心
AddPrefabPostInit("world", function(inst)
    inst:AddComponent("homura_time_manager")
    if BANTIMEMAGIC then
        inst.components.homura_time_manager:Disable()
    end
end)

-- 2021.12.1
-- component/prefab hooks are skipped if ban time magic
if USEBOW then
    AddPrefabPostInit("homura_1", function(inst)
        inst:AddTag("homura_bowmaker")
        inst.starting_inventory = inst.starting_inventory or {}
        table.insert(inst.starting_inventory, "homura_bow")
    end)

    TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.HOMURA_1 = { "homura_bow" }
    TUNING.STARTING_ITEM_IMAGE_OVERRIDE["homura_bow"] = {
        atlas = "images/inventoryimages/homura_bow.xml", image = "homura_bow.tex"
    }
    return
end

-- 延时任务
AddGlobalClassPostConstruct("scheduler", "Periodic", function(self)
    function self:AddTick()
        if not self.nexttick or not scheduler.attime[self.nexttick] then
            return
        end
        -- 2021.10.22 兼容staticScheduler
        if self.homura_isstatic then
            return
        end
        
        local thislist = scheduler.attime[self.nexttick]
        self.nexttick = self.nexttick + 1
        if not scheduler.attime[self.nexttick] then
            scheduler.attime[self.nexttick] = {}
        end
        local nextlist = scheduler.attime[self.nexttick]
        thislist[self] = nil
        nextlist[self] = true
        self.list = nextlist
    end
end)

-- 2021.10.22 兼容staticScheduler
if GLOBAL.staticScheduler ~= nil then
AddGlobalClassPostConstruct("scheduler", "staticScheduler", function(self)
    local old_ExecutePeriodic = self.ExecutePeriodic
    function self:ExecutePeriodic(period, fn, limit, initialdelay, id, ...)
        local periodic = old_ExecutePeriodic(self, period, fn, limit, initialdelay, ...)
        period.homura_isstatic = true
        return period
    end
end)
end

-- 状态
AddGlobalClassPostConstruct("stategraph", "StateGraphInstance", function(self)
    local old_update = self.Update
    function self:Update(...)
        local sleep_time = old_update(self, ...)
        if not sleep_time then
            self.homura_nextupdatetick = nil
        else
            -- 2022.1.14 fix state.onupdate() is not stopped
            if sleep_time == 0 then
                sleep_time = FRAMES
            end

            local sleep_ticks = sleep_time/GetTickTime()
            sleep_ticks = sleep_ticks == 0 and 1 or sleep_ticks
            self.homura_nextupdatetick = math.floor(sleep_ticks + GetTick())+1
        end

        return sleep_time
    end

    function self:AddTick(dt)
        dt = dt or GetTickTime()
        self.statestarttime = self.statestarttime + dt
        if self.homura_nextupdatetick then
            local thislist = SGManager.tickwaiters[self.homura_nextupdatetick]
            if not thislist then return end
            self.homura_nextupdatetick = self.homura_nextupdatetick + 1
            if not SGManager.tickwaiters[self.homura_nextupdatetick]then
                SGManager.tickwaiters[self.homura_nextupdatetick] = {}
            end
            local nextlist = SGManager.tickwaiters[self.homura_nextupdatetick]
            thislist[self] = nil
            nextlist[self] = true
        end
    end
end)

-- AI
AddGlobalClassPostConstruct("behaviourtree", "BT", function(self)
    local old_update = self.Update
    function self:Update(...)
        if self.inst:HasTag("homuraTag_pause") then
            return
        else
            return old_update(self, ...)
        end
    end
end)

do -- 控制天气粒子
    local Precipitation = {rain = 0.2, caverain = 0.2, pollen = .0001, snow = 0.8}
    for k, v in pairs(Precipitation)do
        AddPrefabPostInit(k, function(inst)
            inst.homuraVar_is_precipitation = true
            inst.lw_timemagic_onstart = function(inst)
                inst.VFXEffect:SetDragCoefficient(0,1)
            end
            inst.lw_timemagic_onstop = function(inst)
                inst.VFXEffect:SetDragCoefficient(0,v)
            end
        end)
    end
end


--------------------------
-- 玩家界面、本地音效 --
-------------------------------------------------------
local AMB = require "homura/amb"
local function Pause(inst, master)
    if inst ~= ThePlayer then
        return
    end

    if inst.HUD then
        for over,child in pairs({clouds = 1,sandover = 'bg',sanddustover = 1,drops_vig = 1})do
            if inst.HUD[over] then
                if child == 1 then
                    inst.HUD[over]:GetAnimState():Pause()
                else
                    inst.HUD[over][child]:GetAnimState():Pause()
                end
            end
        end
    end

    inst.components.homura_timepauseblast:Start()
    
    TheWorld.SoundEmitter:SetVolume("rain", 0)
    TheWorld.SoundEmitter:SetVolume("waves", 0)
    TheWorld.SoundEmitter:SetVolume("nightmare_loop",0)

    for _,v in pairs(AMB)do
        TheWorld.SoundEmitter:KillSound(v)
    end
    if TheWorld.components.ambientsound then
        TheWorld.components.ambientsound:SetWavesEnabled(false)
    end
    TheFocalPoint.SoundEmitter:SetVolume("treerainsound", 0)
end

local function Resume(inst, master)
    if inst.HUD then
        for over,child in pairs({clouds = 1,sandover = 'bg',sanddustover = 1,drops_vig = 1})do
            if inst.HUD[over] then
                if child == 1 then
                    inst.HUD[over]:GetAnimState():Resume()
                else
                    inst.HUD[over][child]:GetAnimState():Resume()
                end
            end
        end
    end

    TheWorld.SoundEmitter:SetVolume("rain", 1)
    TheWorld.SoundEmitter:SetVolume("nightmare_loop", 1)
    if TheWorld.components.ambientsound and TheWorld.prefab ~= 'cave' and TheWorld.prefab ~= 'lavaarena' then
        TheWorld.components.ambientsound:SetWavesEnabled(true)
    end
    TheFocalPoint.SoundEmitter:SetVolume("treerainsound", 1)
end

AddPlayerPostInit(function(inst) 
    inst:AddComponent("homura_timepauseblast")
    inst:ListenForEvent("homura_enter_timemagic", Pause)
    inst:ListenForEvent("homura_exit_timemagic", Resume)
end)

AddPrefabPostInitAny(function(inst)
    if not inst.components.ignoretimemagic and not inst.Pathfinder then
        if (TheWorld and TheWorld.ismastersim) or not inst.Network then
            inst:AddComponent("ignoretimemagic")
        end
    end
end)

local LoadComponent = function(path) return require("components/"..path) end

do -- 所有实例的组件更新
    local SKIP_COMPOENNTS = {
        ignoretimemagic = true,
        homura_timepauseblast = true, -- 特效更新
        container = true,           --保证容器正常关闭
        playercontroller = true,    --动作获取
        highlight = true,           --高亮
        homura_skill = true,        --方便测试, 无实际意义
    }
    AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
        local old_add = self.AddComponent
        function self:AddComponent(name, ...)
            local bugtracker_ignore_flag__AddComponent = true
            local cmp = old_add(self, name, ...) or self.components[name]
            if not SKIP_COMPOENNTS[name] and cmp.OnUpdate then 
                local old_update = cmp.OnUpdate
                local inst = self
                function cmp:OnUpdate(dt)
                    local bugtracker_ignore_flag__OnUpdate = true
                    if not inst:HasTag('homuraTag_pause') then 
                        old_update(self, dt)
                    end
                end
            end
            return cmp
        end
    end)
end

do -- 人物的组件更新
    local COMPONENTS = {
        grue = true,
    }

    for k in pairs(COMPONENTS)do
        local self = LoadComponent(k)
        local old_update = self.OnUpdate
        self.OnUpdate = function(self, ...)
            if self.inst:HasTag("player") and not self.inst.lw_timemagic_inrange then
                old_update(self, ...)
            end
        end
    end
end


do -- 环境湿度
    local self = LoadComponent("moisture")
    local old_get = self.GetMoistureRate 
    function self:GetMoistureRate(...)
        return self.inst.lw_timemagic_inrange and 0 or old_get(self, ...)
    end
end

----------------------
--禁用船桨船帆---------
-------------------------------

do -- 交易怀表
    local function CanGiveClock(inst)
        if inst.components.trader then
            local old_test = inst.components.trader.java.test
            inst.components.trader.java.test = function(inst, item, ...)
                if item and item.prefab == 'homura_clock' then
                    return true
                else
                    return old_test(inst, item, ...)
                end
            end
        end
    end

    for _,v in pairs{"pigman", "bunnyman"}do
        AddPrefabPostInit(v, CanGiveClock)
    end
end



do -- 禁用玩家控制
    local self = LoadComponent("playercontroller")
    local old_isenabled = self.IsEnabled
    function self:IsEnabled(...)
        if self.inst:HasTag("homuraTag_pause") then
            return false
        else
            return old_isenabled(self, ...)
        end
    end
end


-- 偷偷刮毛 (欣愿)
AddPrefabPostInit("beefalo", function(inst)
    if inst.components.beard then
        local old_can = inst.components.beard.canshavetest
        inst.components.beard.canshavetest = function(inst, ...)
            if inst:HasTag("homuraTag_pause") then
                return true
            else
                return old_can(inst, ...)
            end
        end
    end
end)


-- 蜘蛛巢 / 蜂巢 / 猪人房子
AddComponentPostInit("childspawner", function(self)
    local old_spawnall = self.ReleaseAllChildren
    function self:ReleaseAllChildren(...)
        if self.inst:HasTag("homuraTag_pause") then
            if not self.homura_delay then
                local args = {...}
                self.homura_delay = self.inst:DoTaskInTime(2.5*FRAMES, function()
                    -- 延时任务被阻断，解除时停后才会执行
                    -- 为避免下一帧直接触发任务，设置为两帧
                    self.homura_delay = nil
                    if self.inst.components.childspawner ~= nil then
                        old_spawnall(self, unpack(args))
                    end
                end)
                return {}
            end
        else
            return old_spawnall(self, ...)
        end
    end

    local old_spawn = self.SpawnChild
    function self:SpawnChild(...)
        if self.inst:HasTag("homuraTag_pause") then
            return nil
        else
            return old_spawn(self, ...)
        end
    end
end)
