-- move back distance per second
local MOVE_PS = {
    homura_gun = .2,
    homura_hmg = .5,
    homura_tr_gun = .1,
}

-- shoots per second
local SHOOT_PS = {
    homura_gun = 10,
    homura_hmg = 20,
    homura_tr_gun = 7.5,
}

local HMG_MIN_SHOOTS = 3

local function Moveback(inst)
    local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local riding = inst.replica.rider ~= nil and inst.replica.rider:IsRiding()
    if weapon == nil then return end

    local prefab = weapon.prefab
    -- calc movement per shoot
    local length = MOVE_PS[prefab] ~= nil and MOVE_PS[prefab] / SHOOT_PS[prefab]
    if riding then
        length = length * 0.3
    end
    
    local pos = inst:GetPosition()
    local facing = inst.Transform:GetRotation()
    local angle = (facing + 270)*DEGREES
    local targetpos = pos + Vector3(length*math.sin(angle),0,length*math.cos(angle))
    inst.Transform:SetPosition(targetpos:Get())
end

local function AddExtraFx(inst, prefabname, offset, postfn) --offset传入格式(半径,高度,是否反向)
    local fx = SpawnPrefab(prefabname)
    local pos = inst:GetPosition()
    local angle = inst.Transform:GetRotation()*DEGREES
    local dir = offset.z < 0 and -1 or 1
    local radius = offset.x
    local height = offset.y

    offset = Vector3(math.cos(angle)*radius*dir, height, -math.sin(angle)*radius*dir)

    fx.Transform:SetRotation(inst.Transform:GetRotation())
    fx.Transform:SetPosition((offset+pos):Get())

    if postfn then
        postfn(inst, fx)
    end
end

local function PlayEmptySound(inst)
    inst.SoundEmitter:PlaySound("lw_homura/gun/empty", nil, nil, true)
end

local function PlayShootSound(inst, prefab, silent)
    if prefab ~= nil then
        local sfx, volume, looping
        if prefab == "homura_gun" then
            sfx = "lw_homura/gun/normal"
            volume = not silent and .7 or .2
        elseif prefab == "homura_hmg" then
            sfx = "lw_homura/hmg/loop"
            volume = not silent and .7 or .2
            looping = "homura_gun_atk_LOOP"
        elseif prefab == "homura_tr_gun" then
            sfx = "dontstarve/creatures/spat/spit" 
            volume = not silent and 1 or .3
        end

        if looping then
            if inst.sg.statemem.sfx == nil then
                inst.SoundEmitter:PlaySound(sfx, looping, volume, true)
                inst.sg.statemem.sfx = looping
            end
        else
            inst.SoundEmitter:PlaySound(sfx, nil, volume, true)
        end
    end
end

local function CheckWeaponCanRangeAttack(inst)
    local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return weapon ~= nil and weapon:HasTag("homuraTag_ranged")
end

local function CanTarget(inst, target, weapon)
    return target ~= nil and target:IsValid()
        and CanEntitySeeTarget(inst, target)
        and inst.replica.combat:CanTarget(target)
        -- and inst.replica.combat:CanHitTarget(target, weapon)
end

local function GetAttackTarget(inst)
    inst.sg:RemoveStateTag("attack")
    local target = inst.components.playercontroller ~= nil and inst.components.playercontroller:GetAttackTarget()
    inst.sg:AddStateTag("attack") 
    return target
end

local function CheckAttackTarget(inst)  
    local pressingattack = GetClientKey(inst, "attack")
    local mouseover = GetClientKey(inst, "mouseover")

    local statemem = inst.sg.statemem
    local action = statemem.action or {}
    local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local target = action.target

    -- if pressingattack then
        local newtarget
        if CanTarget(inst, mouseover, weapon) then
            newtarget = mouseover
        elseif CanTarget(inst, target, weapon) then
            return target
        else
            local target = GetAttackTarget(inst)
            if CanTarget(inst, target, weapon) then
                newtarget = target
            end
        end

        if newtarget then
            statemem.target = newtarget
            statemem.attacktarget = newtarget
            action.target = newtarget
            return newtarget
        end
    -- end

    return nil
end

local function CheckKeyDown(inst)
    return GetClientKey(inst, "attack") or GetClientKey(inst, "mouseover")
end

local function Shoot(inst, target)
    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if weapon.components.weapon then
        local pos = inst:GetPosition()
        local angle = -inst.Transform:GetRotation()* DEGREES
        pos = pos + Vector3(math.cos(angle), 0, math.sin(angle))

        pos = inst.components.homura_clientkey:GetWorldPosition() or pos

        if target == nil or not target:IsValid() then
            target = CreateEntity()
            target.entity:AddTransform():SetPosition(pos:Get())
            target.persists = false
            target:DoTaskInTime(0, target.Remove)
        end

        weapon.components.weapon:LaunchProjectile(inst, target)
    end
end

local atk = function(ismastersim) return State{
    name = "homura_gun_atk",
    tags = {"attack", "notalking", "abouttoattack", "homura_gun_atk"},

    onenter = function(inst)
        inst.components.locomotor:Stop()

        local action = inst:GetBufferedAction()
        local target = action and action.target
        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

if ismastersim then
        inst.AnimState:ClearOverrideSymbol("player_homura_gun_fire")
else    
        if action ~= nil then
            inst:PerformPreviewBufferedAction()
        end
end
        -- inst.AnimState:PlayAnimation("homura_gun_atk")


        if inst.components.combat and target ~= nil then
            inst.components.combat:SetTarget(target)
        end

        inst.sg.statemem.target = target
        inst.sg.statemem.attacktarget = target
        inst.sg.statemem.weapon = weapon

        -- for shoot
        inst.sg.statemem.tick = 1
        inst.sg.statemem.num_hits = 1

        if weapon and weapon.prefab == "homura_hmg" then
            inst.sg.statemem.num_hits = HMG_MIN_SHOOTS
        end
    end,

    onupdate = function(inst, dt)
        local target = CheckAttackTarget(inst)
        if target ~= nil then
            inst:FacePoint(target:GetPosition())
        end

        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local prefab = weapon and weapon.prefab
        local ranged = weapon and weapon:HasTag("homuraTag_ranged")
        local silent = weapon and weapon:HasTag("homuraTag_silentgun")

        if ranged and prefab and SHOOT_PS[prefab] then
            inst.sg.statemem.tick = inst.sg.statemem.tick + SHOOT_PS[prefab]* FRAMES
        else
            inst.sg.statemem.tick = inst.sg.statemem.tick + 6* FRAMES
        end

        if inst.sg.statemem.tick >= 1 then
            inst.sg.statemem.tick = inst.sg.statemem.tick - 1
            inst.sg:RemoveStateTag("abouttoattack")

            if not ranged then
                -- kill hmg loop sfx
                if inst.sg.statemem.sfx then
                    if inst.SoundEmitter:PlayingSound(inst.sg.statemem.sfx) then
                        inst.SoundEmitter:KillSound(inst.sg.statemem.sfx)
                    end
                end
                -- ammo is empty -> check whether F/LMB is pressing
                if CheckKeyDown(inst) then
                    inst.AnimState:ClearOverrideSymbol("player_homura_gun_fire")
                    inst.AnimState:PlayAnimation("homura_gun_atk")
                    PlayEmptySound(inst)
                    inst.sg.statemem.waitingexit = true
                else
                    inst.sg.statemem.exit = true
                    inst.sg:GoToState("homura_gun_pst")
                    return
                end
            else
                -- we have ammos -> shoot if F/LMB is pressing
                if CheckKeyDown(inst) or inst.sg.statemem.num_hits > 0 then
                    inst.sg.statemem.num_hits = inst.sg.statemem.num_hits - 1

                    if prefab ~= "homura_tr_gun" then
                        inst.AnimState:OverrideSymbol("player_homura_gun_fire", "player_homura_gun", "player_homura_gun_fire")
                    end
                    inst.AnimState:PlayAnimation("homura_gun_atk")
                    inst.replica.combat:CancelAttack()

                    if ismastersim then
                        Shoot(inst, target)
                        if prefab == "homura_gun" or prefab == "homura_hmg" then
                            AddExtraFx(inst, "homura_gun_light", Vector3(2,0,0))
                        end
                    end

                    PlayShootSound(inst, prefab, silent)
                    Moveback(inst)
                else
                    inst.sg.statemem.exit = true
                    inst.sg:GoToState("homura_gun_pst")
                    return
                end
            end
        end
    end,

    events = {
        CommonEquip(),
        CommonUnequip(),
    },

    onexit = function(inst)
        if inst.components.combat then
            inst.components.combat:SetTarget(nil)
        end
        inst.AnimState:ClearOverrideSymbol("player_homura_gun_fire")
        if inst.sg.statemem.sfx then
            if inst.SoundEmitter:PlayingSound(inst.sg.statemem.sfx) then
                inst.SoundEmitter:KillSound(inst.sg.statemem.sfx)
            end
        end
        inst:ClearBufferedAction()
    end,
}
end

AddStategraphState("wilson", atk(true))
AddStategraphState("wilson_client", atk(false))
