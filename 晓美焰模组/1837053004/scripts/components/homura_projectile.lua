-- 2022.8.12
-- 反射重置射程 注意: 本次更改后，新增一个变量 rangebonus
-- 更高的兼容性

local MATH = require "homura.math"
local Polygon = MATH.Polygon
local DeltaAngle = MATH.DeltaAngle
local DeltaAngleAbs = MATH.DeltaAngleAbs
local Segment = MATH.Segment
local DistPointToLine = MATH.DistPointToLine

local function OnThrown(inst, owner, target)
    inst:StopUpdatingComponent(inst.components.projectile)
    inst.components.homura_projectile:OnTrow(inst, owner, target)
end

local HomuraProjectile = Class(function(self, inst)
    self.inst = inst

    self.hits = {}
    self.hitcount = 0
    self.maxhits = 1

    self.reflectcount = 0
    self.reflectprotect = 0
    self.maxreflects = 0
    self.reflectcount_damagedown = 0
    self.rangebonus = 0

    self.onthrown = nil
    -----
    assert(inst.components.projectile ~= nil)
    inst.components.projectile.onthrown = OnThrown
end)

-- function DebugTwigs()
--     local o = ThePlayer:GetPosition()
--     for i = -10, 10 do
--         for j = -10, 10 do
--             local x,z = i + o.x, j + o.z 
--             if not TheWorld.Map:IsOceanAtPoint(x, 0, z) then
--                 SpawnPrefab("twigs").Transform:SetPosition(x,0,z)
--             end
--         end
--     end
-- end

local function SortByDist(origin)
    local origin = Vector3(origin.x, 0, origin.z)
    return function(a, b)
        return a:GetDistanceSqToPoint(origin) < b:GetDistanceSqToPoint(origin)
    end
end

function HomuraProjectile:OnUpdate(dt)
    if self.stopupdating then -- flag for `homura_water`
        self.inst:StopUpdatingComponent(self)
        return
    end

    self.reflectflag = false -- Reflect only once in a frame.

    local lastpos = self.lastpos
    local currentpos = self.inst:GetPosition()
    local firstframe = self.startpos == self.lastpos

    -- Homing 
    if self.has_homing then
        self.homingrate = (self.homingrate or 0.2) + 0.02
        local dest = self:RecordTargetPosition()
        if dest then
            local angle1 = self.inst.Transform:GetRotation()
            local angle2 = self.inst:GetAngleToPoint(dest)
            local delta = DeltaAngle(angle1, angle2)
            if delta < 180 then
                delta = math.min(10, delta * self.homingrate)
            else
                delta = math.max(-10, (delta - 360) * self.homingrate)
            end
            self.inst.Transform:SetRotation(angle1 + delta)
        end
    end

    -- Dist
    if self.totaldist > self.range + self.rangebonus then
        self:Miss()
        return
    end

    -- Search and hit
    if lastpos ~= nil then
        if currentpos.x ~= lastpos.x or currentpos.z ~= lastpos.z then
            local offset = currentpos - lastpos
            offset.y = 0
            local dir, len = offset:GetNormalizedAndLength()
            self.totaldist = self.totaldist + len

            -- 骑牛下坠
            if self.dropping and len > 0 then
                local y = currentpos.y
                local x,_,z = self.inst.Physics:GetMotorVel()
                if y > 0 then
                    self.inst.Physics:SetMotorVel(x,-x*Remap(math.min(1,y),1,0,.05,.01),z)
                else
                    self.inst.Physics:SetMotorVel(x,0,z)
                    self.dropping = false
                end
            end

            currentpos = currentpos + dir * 0.50
            -- 先进行反射判定
            if self.reflectcount < self.maxreflects then
                local walls = TheSim:FindEntities(currentpos.x, 0, currentpos.z, 4, 
                    {"wall"}, {"INLIMBO"})
                local mirrors = {}
                for _, wall in ipairs(walls)do
                    if wall.components.health and not wall.components.health:IsDead() then
                        local x,y,z = wall.Transform:GetWorldPosition()
                        local points = {
                            Point(x+.5,0,z+.5),
                            Point(x+.5,0,z-.5),
                            Point(x-.5,0,z-.5),
                            Point(x-.5,0,z+.5),  
                        }
                        for i = 1, 4 do
                            local seg = Segment(points[i], points[i==4 and 1 or i+1])
                            local hash = seg:Hash()
                            if mirrors[hash] == nil then 
                                mirrors[hash] = {}
                            end
                            table.insert(mirrors[hash], {wall = wall, seg = seg})
                        end
                    end
                end

                local vec = Segment(lastpos, currentpos)
                local dir = vec.dir
                local dot = function(v) return dir.x * v.x + dir.z * v.z end

                local minvalue = math.huge 
                local intersect_v = nil

                for k,v in pairs(mirrors)do
                    if #v == 1 then
                        mirrors[k] = v[1]
                    else
                        mirrors[k] = nil 
                    end
                end

                for _, v in pairs(mirrors)do
                    local wall, seg = v.wall, v.seg
                    local _, p, is_true = seg:Intersect(vec)
                    if is_true then 
                        local value = dot(p - currentpos)
                        local distsq = DistXZSq(p, --[[firstframe and self.startpos or]] currentpos)
                        v.point = p 
                        v.value = value
                        if value < 0 and self.reflectprotect > 0 then
                            -- pass
                        elseif value >= 0 and distsq < 2.2 or value < 0 and distsq < 1 then 
                            if v.value < minvalue then 
                                minvalue = v.value
                                intersect_v = v
                            end
                        end
                    end
                end

                -- 防止穿墙
                if intersect_v ~= nil then 
                    for _,v in pairs(mirrors)do
                        if v.wall == intersect_v.wall and v.value ~= nil and v.value < minvalue then
                            minvalue = v.value
                            intersect_v = v 
                        end
                    end
                else
                    minvalue = nil
                    intersect_v = {}
                end

                local value = minvalue
                local intersect_wall = intersect_v.wall
                local intersect_point = intersect_v.point
                local intersect_seg  = intersect_v.seg

                -- print("TICK", GetTick())

                if value == nil then 
                    -- print("No mirror")
                else
                    local distsq = DistXZSq(currentpos, intersect_point)
                    local can = false
                    if value < 0 and self.reflectprotect > 0 then 
                        -- print("Protect")
                    elseif value < 0 and firstframe and distsq < 2.2 then
                        can = true
                    elseif value >= 0 and distsq < 2.2 or value < 0 and distsq < 1 then 
                        can = true
                    else
                        -- print("Dist Fail")
                    end

                    if can then
                        -- print("Reflect!", GetTick())
                        self:ReflectAtWall({wall = intersect_wall, point = intersect_point, seg = intersect_seg, value = value})
                        self.lastpos = self.inst:GetPosition()
                        return
                    end
                end
            end

            local center = (currentpos + lastpos)/2
            local offset = Vector3(dir.z, 0, -dir.x)*(self.width / 2)
            local rect = Polygon{
                currentpos + offset, currentpos - offset, 
                lastpos - offset, lastpos + offset,
            }

            local ents = TheSim:FindEntities(center.x, 0, center.z, len + self.width + 2,
                nil, {"INLIMBO", "FX"}, {"_combat", "_workable", "cattoy"})
            table.sort(ents, SortByDist(lastpos))
            for i,v in ipairs(ents)do
                
                if rect:IsEntityIn(v) and not self.reflectflag then
                    if self.hitcount < self.maxhits then 
                        self:Hit(v)
                    end
                end
            end
        end

        self.lastpos = self.inst:GetPosition()
    end

    if self.reflectprotect > 0 then
        -- self.inst:Show()
        self.reflectprotect = self.reflectprotect - 1
    end
end

local function FlashWall(inst)
    inst.AnimState:SetMultColour(1,0,0,1)
    inst:DoTaskInTime(2, function() inst.AnimState:SetMultColour(1,1,1,1)end)
end

local function FlashTarget(inst)
    inst.AnimState:SetMultColour(0,1,0,1)
    inst:DoTaskInTime(2, function() inst.AnimState:SetMultColour(1,1,1,1)end)
end

local function pfp(p1, p2)
    return math.atan2(p1.z - p2.z, p2.x - p1.x) / DEGREES
end


function HomuraProjectile:ReflectAtWall(data)
    local wall = data.wall
    local point = data.point
    local seg = data.seg
    local value = data.value

    if self.lastreflectwall == wall and self.reflectprotect > 0 then
        return
    else
        self.lastreflectwall = wall
    end

    -- FlashWall(wall)
    -- print("Reflect", GetTick(), wall)

    local angle1 = pfp(seg.p1, seg.p2) -- 镜面
    local angle2 = pfp(self.lastpos, self.inst:GetPosition()) -- 光

    -- self.inst:Hide()
    if value < 0 then
        self.inst.Physics:Teleport(point:Get())
    end
    self.inst.Transform:SetRotation(angle1*2 - angle2)

    self.reflectcount = self.reflectcount + 1
    self.reflectprotect = 1
    if wall.prefab ~= "wall_moonrock" then
        self.reflectcount_damagedown = self.reflectcount_damagedown + 1
    end
    self.rangebonus = self.rangebonus + self.range * 0.6
end

local function DebugFlash(target)
    if target.components.highlight == nil then
        target:AddComponent("highlight")
    end
    target.components.highlight:Flash(.2, .125, .1)
end    

function HomuraProjectile:Hit(target)
    if self.hits[target] == true then
        return
    else
        self.hits[target] = true
    end

    if target:HasTag("wall") then
        if self.maxreflects - self.reflectcount > 0 then
            return
        elseif self.lastreflectwall == target then 
            return
        elseif self.reflectprotect > 0 then
            return
        end
    end

    -- DebugFlash(target)

    -- 2021.7.1 穿透机制调整
    if target ~= self.player and 
        target.components.health and 
        target.components.combat and
        not target.components.health:IsDead() and
        not (target.components.domesticatable and target.components.domesticatable:IsDomesticated())  -- 2022.1.13 忽略牛牛
        and target.components.combat:CanBeAttacked(self.player) then 

        local numhits = math.ceil(target:GetPhysicsRadius(0))
        numhits = math.min(numhits, self.maxhits - self.hitcount)
        numhits = math.max(1, numhits)

        for i = 1, numhits do
            self:Attack(target)
            self.hitcount = self.hitcount + 1
        end
    end

    if self.hitcount == self.maxhits then
        self:OnMaxHits()
    end
end

local function IsNotDead(inst)
    return inst.components.health and not inst.components.health:IsDead()
end

function HomuraProjectile:Attack(target)
    -- print("Attack", GetTick(), target)
    -- FlashTarget(target)

    local attacker = self.player or CreateEntity()
    local isplayer = target:HasTag("player")
    local iswall = target:HasTag("wall")
    local damagemulter = isplayer and .33 or 1
    local freezable = target.components.freezable
    local isfrozen = freezable ~= nil and freezable:IsFrozen()
    local reflectmulter = 1 - self.reflectcount_damagedown * 0.25

    -- 2022.3.14 Magic arrow for wall
    if iswall and (self.inst.prefab == "homura_arrow" or self.inst.prefab == "homura_arrow_magic") then
        damagemulter = damagemulter /30
    end

    if self.has_silent then
        attacker:AddTag("homuraTag_silencer")
    end

    if not self.inst:HasTag("homuraTag_rpgpro") then
        if IsNotDead(target) then
            target.components.combat:GetAttacked(self.player, self.damage1 * damagemulter * reflectmulter, self.owner)
        end
    end

    if self.truedamage and IsNotDead(target) and target.components.combat ~= nil then
        attacker:AddTag("homuraTag_ignorearmor")
        -----
        local damage = self.truedamage * damagemulter
        local percent = 
            math.clamp(1-target.components.health.absorb,0,1)
            * math.clamp(1-target.components.health.externalabsorbmodifiers:Get(),0,1)
        if percent > 0 and percent < 1 then
            damage = damage / percent
        end
        target.components.combat:GetAttacked(attacker, damage, self.owner)
        -----
        attacker:RemoveTag("homuraTag_ignorearmor")
    end

    if self.coldness and freezable and not isfrozen and IsNotDead(target) then
        freezable:AddColdness(self.coldness)
    end

    -- add snowpea buff
    if self.inst.prefab == "homura_projectile_snowpea" and freezable then
        if not target.components.homura_snowpea_debuff then
            target:AddComponent("homura_snowpea_debuff")
        end
        target.components.homura_snowpea_debuff:AddDebuff()
    end

    attacker:RemoveTag("homuraTag_silencer")
end

function HomuraProjectile:Miss()
    local pos = self.inst:GetPosition()
    if self.miss_fx ~= nil then
        SpawnPrefab(self.miss_fx).Transform:SetPosition(pos:Get())
    elseif not self.no_miss_fx then
        SpawnPrefab("homura_miss_fx").Transform:SetPosition(pos:Get())
    end

    if self.has_wind then
        self:SpawnTornado(pos)
    end

    if self.onmissfn then
        self.onmissfn(self.inst, self.player, self.target)
    end

    self.inst:Remove()
end

function HomuraProjectile:OnMaxHits()
    if not self.inst:IsValid() then
        return
    end

    if self.onmaxhitsfn then
        self.onmaxhitsfn(self.inst, self.player, self.target)
    end

    self.inst:Remove()
end

function HomuraProjectile:SpawnTornado(pos)
    if self.tornado ~= nil and math.random() <= self.tornado then
        local tornado = SpawnPrefab("tornado")
        if self.player ~= nil then
            tornado.WINDSTAFF_CASTER = self.player
            tornado.WINDSTAFF_CASTER_ISPLAYER = true
            tornado.overridepkname = self.player:GetDisplayName()
            tornado.overridepkpet = true
        end
        tornado.AnimState:SetTime(10/30)
        tornado.Transform:SetPosition(pos:Get())
        tornado.components.knownlocations:RememberLocation("target", pos)
    end
end

local RANDOM_COLOURS = {
    {1,1,1},
    {1.00, 0.50, 0.50},
    {0.50, 0.50, 1.00},
    {0.75, 0.75, 0.25},
    {0.50, 1.00, 0.50},
    {0.25, 0.75, 0.75},
}

function HomuraProjectile:RecordTargetPosition()
    if self.target ~= nil and self.target:IsValid() and self.target.Transform ~= nil then
        self.targetpos = self.target:GetPosition()
        self.targetpos.y = 0
    end
    return self.targetpos
end

function HomuraProjectile:OnTrow(inst, owner, target)
    local projectile = inst.components.projectile
    local target = projectile.target

    self.target = target
    self:RecordTargetPosition()
    self.owner = owner  -- Gun

    if owner.components.combat == nil and owner.components.weapon ~= nil and owner.components.inventoryitem ~= nil then
        self.player = owner.components.inventoryitem.owner -- Homura
    end

    local buffed_data = owner.homura_projectile_data or owner.components.homura_weapon.buffed_data
    self.buffed_data = buffed_data
    for k,v in pairs(buffed_data)do
        self[k] = v 
    end

    self.maxrange = owner.components.weapon.hitrange

    --重定向
    if self.angle then
        local player = owner and owner.components.inventoryitem:GetGrandOwner()
        local angle = player and player.Transform:GetRotation() or inst.Transform:GetRotation() --玩家朝向
        local projectiletilt = self.angle == 0 and 0 or GetRandomMinMax(-self.angle, self.angle) 

        inst.Transform:SetRotation(angle + projectiletilt)
    end

    --重设速度
    if self.speed then
        inst.Physics:SetMotorVel(self.speed,0,0)
    end
    
    --重设距离
    if self.infinite_range then
        self.range = math.huge 
        self.inst:DoTaskInTime(10, function() self:Miss() end)
    elseif self.maxrange then
        self.range = self.maxrange * GetRandomMinMax(self.range_var or 1, 1)
    end
    
    -- 扣san
    local player = owner and owner.components.inventoryitem and owner.components.inventoryitem:GetGrandOwner()
    local sanity = player and player.components.sanity

    -- 子弹贴图
    if self.has_magic and self.sanitycost ~= nil then
        if not sanity or sanity.current < self.sanitycost then
            self.has_magic = false 
            self.num_magic = 0 
        else
            sanity:DoDelta(-self.sanitycost, true)
        end
    end
    -- 骑牛高度
    if player and player.components.rider and player.components.rider:IsRiding() then
        self.inst.Transform:SetPosition((self.inst:GetPosition() + Vector3(0, 2.2, 0)):Get())
        self.dropping = true
    end
    
    -- TODO 火箭炮雪花尾巴？
    if not self.inst:HasTag("homuraTag_rpgpro") then
        local function check(name, number) return (self["num_"..name] or 0) >= number end

        local anim = self.inst.AnimState
        local tail_colour = self.inst._tail_colour or {set = function() end}
        local bloom = function() anim:SetBloomEffectHandle("shaders/anim.ksh") end
        local light_override = function(i) anim:SetLightOverride(i or 1) end

        if self.inst.prefab == "homura_projectile_snowpea" then
            tail_colour:set(20)
        elseif self.inst.prefab == "homura_projectile_watergun" then
            -- skip anim setting
        elseif self.inst.prefab == "homura_projectile_tr_gun" then
            -- skip anim setting
        elseif check("laser", 1) then 
            anim:PlayAnimation("anim_light")
            bloom()
            light_override()
            -- random color
            local r,g,b = unpack(RANDOM_COLOURS[math.random(#RANDOM_COLOURS)])
            self.projctile_colour = {r,g,b,1}
            anim:SetMultColour(unpack(self.projctile_colour))
        elseif check("ice", 3) then
            anim:PlayAnimation('anim_ice_sp') 
            tail_colour:set(2)
        elseif check("ice", 2) then
            anim:PlayAnimation('anim_ice')
        elseif check("wind", 3) then
            tail_colour:set(3)
        elseif check("magic", 3) then
            anim:PlayAnimation("anim_magic_sp")
            bloom()
            light_override()
            tail_colour:set(1)
        elseif check("magic", 2) then
            anim:PlayAnimation("anim_magic")
            bloom()
            light_override()
        elseif self.inst.prefab == "homura_projectile_rifle" then
            anim:PlayAnimation("anim_light")
            bloom()
            light_override()
            tail_colour:set(4)
        end
    end

    --免疫时停
    if self.has_time then
        inst:AddTag("homuraTag_ignoretimemagic")
    elseif inst.components.ignoretimemagic ~= nil then
        inst.components.ignoretimemagic:SetProjectile(self.speed)
        inst.components.ignoretimemagic:LeaveOwner()
    end
    --追踪
    if self.has_homing then
        self.range = self.range * 5
    end
    -- snowpea range
    if owner.components.weapon.range_inf then
        self.range = 60
    end

    if self.onthrown ~= nil then
        self.onthrown(inst, owner, target)
    end

    self.lastpos = self.player and self.player:GetPosition() or self.inst:GetPosition()
    self.startpos = self.lastpos
    self.totaldist = 0

    if self.inst:HasTag("homuraTag_rpgpro") then
        self.maxreflects = 0
        self.maxhits = 1
    end
    
    self:OnUpdate(FRAMES) -- First hit / reflect
    self.inst:StartUpdatingComponent(self)
end

return HomuraProjectile

