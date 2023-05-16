local function PlayerSay(inst, str)
    if inst.components.talker and not inst:HasTag("mime") then
        inst.components.talker:Say(str)
    end
end

local function ExitSnipinngHandler()
    return EventHandler("homura_exitsniping", function(inst) inst.sg:GoToState("idle") end)
end

local function ShootHandler()
    return EventHandler("homuraevt_snipeshoot", function(inst, data)
        if inst.sg.statemem.preshoot then
            return
        elseif inst.components.homura_sniper and not inst.components.homura_sniper:IsReady() then
            return
        elseif inst:HasTag("homuraTag_snipeCD")then
            return
        end
        if data and data.x and data.z then
            local x, z = data.x, data.z
            inst.sg.statemem.shoot = true
            inst.sg:GoToState("homura_snipeshoot", data)
        end
    end)
end

local function PointFocus(inst)
    local action = inst:GetBufferedAction()
    local target = action and action.target
    local pos = action and action:GetActionPoint()
    if inst.HUD ~= nil then
        if target ~= nil then
            inst.HUD.homuraUI_focus:PointCursorAtTarget(target)
        elseif pos ~= nil then
            inst.HUD.homuraUI_focus:PointCursorAtTarget(pos)
        end
    end
end

local homura_snipe = State{
    name = "homura_sniping",
    tags = {"notalking", "abouttoattack", "homura_sniping", "busy"},

    onenter = function(inst)
        inst.components.locomotor:Stop()

        local action = inst:GetBufferedAction()
        local weapon = inst.components.combat:GetWeapon()

        if not (weapon and weapon:HasTag("homuraTag_ranged")) then
            inst.sg:RemoveStateTag("homura_sniping")
            inst.sg:RemoveStateTag("abouttoattack")
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("notalking")
            inst.sg:AddStateTag("idle")
            if action ~= nil then
                inst:PerformBufferedAction()
            else
                inst.sg:GoToState("idle")
            end
            return
        end

        inst.sg.statemem.weapon = weapon

        inst.AnimState:PlayAnimation("homura_gun_pre")
        inst.SoundEmitter:PlaySound("lw_homura/sfx/load_down_3d", nil, 0.7, true)

        PointFocus(inst)
        
        if not inst.components.homura_sniper:IsSniping() then
            inst.components.homura_sniper:StartSniping()
        end

    end,

    timeline = {
        TimeEvent(12*FRAMES,function(inst)
            if inst.sg.statemem.weapon ~= nil then
                inst.AnimState:PlayAnimation("homura_gun_focus",true)
                inst.sg:RemoveStateTag("busy")
                inst.sg:AddStateTag("idle") -- For inspect action
                inst:ClearBufferedAction()
                 
            end
        end),
    },

    events = 
    {
        CommonEquip(),
        CommonUnequip(),
        ExitSnipinngHandler(),
        ShootHandler(),
    },    

    onexit = function(inst)
        if not inst.sg.statemem.shoot then
            if inst.components.homura_sniper:IsSniping() then
                inst.components.homura_sniper:StopSniping()
            end 
        end
    end,
}

AddStategraphState("wilson", homura_snipe)

local homura_snipe_client = State{
    name = "homura_sniping",
    tags = {"notalking", "abouttoattack", "homura_sniping", "busy"},

    onenter = function(inst)
        inst.components.locomotor:Stop()
        local action = inst:GetBufferedAction()
        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if action ~= nil then
            inst:PerformPreviewBufferedAction()
        end

        inst.sg.statemem.weapon = weapon

        if not (weapon and weapon:HasTag("homuraTag_ranged")) then
            inst.sg:RemoveStateTag("homura_sniping")
            inst.sg:RemoveStateTag("abouttoattack")
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("notalking")
            inst.sg:AddStateTag("idle")
            inst.sg:GoToState("idle")
            return
        end

        inst.AnimState:PlayAnimation("homura_gun_pre")
        inst.SoundEmitter:PlaySound("lw_homura/sfx/load_down_3d",nil,0.7,true)

        PointFocus(inst)

    end,

    events = {
        ExitSnipinngHandler(),
        ShootHandler(),
    },

    timeline = {
        TimeEvent(12*FRAMES,function(inst)
            if inst.sg.statemem.weapon ~= nil then
                inst.sg:RemoveStateTag("busy")
                inst.sg:AddStateTag("idle") -- For inspect action
                inst.AnimState:PlayAnimation("homura_gun_focus",true)
                inst:ClearBufferedAction()
            end
        end),
    },

    onexit = function(inst)

    end,
}

AddStategraphState('wilson_client', homura_snipe_client)

local homura_shoot = State{
    name = "homura_snipeshoot",
    tags = {"notalking", "attack", "busy"},

    onenter = function(inst, data)
        inst.components.locomotor:Stop()

        local weapon = inst.components.combat:GetWeapon()

        if data and data.x and data.z then
            inst.sg.statemem.point = Vector3(data.x, 0, data.z)
        end
        inst.sg.statemem.preshoot = true

        inst.AnimState:OverrideSymbol("player_homura_gun_fire", "player_homura_gun", "player_homura_gun_fire")
        inst.AnimState:PlayAnimation("homura_gun_snipeshoot")
        
    end,

    timeline = {
        TimeEvent(2*FRAMES, function(inst)
            local action = inst:GetBufferedAction()
            local target = action and action.target
            local point = inst.sg.statemem.point

            inst.sg.statemem.preshoot = false
            
            if point ~= nil then
                inst:ForceFacePoint(point)
            elseif target ~= nil then
                inst:ForceFacePoint(target:GetPosition())
            end
            if not inst.components.homura_sniper:CheckCooldownAndEnter() then
                return
            end

            local weapon = inst.components.combat:GetWeapon()
            if weapon and weapon.prefab == "homura_rifle" and point then
                local target = CreateEntity()
                target.entity:AddTransform():SetPosition(point:Get())
                target.persists = false
                target:DoTaskInTime(0, target.Remove)

                -- 这里可能会有点问题
                weapon.components.weapon:LaunchProjectile(inst, target)
            end
            inst.SoundEmitter:PlaySound("lw_homura/focus/shoot", nil, 0.5, true)
            inst.components.homura_sniper:OnShoot()
            inst:ClearBufferedAction()
        end),
        TimeEvent(4*FRAMES, function(inst)
            inst.AnimState:PlayAnimation("homura_gun_focus", true)
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("abouttoattack")
            inst.sg:AddStateTag("homura_sniping")

            local weapon = inst.components.combat:GetWeapon()
            if not (weapon and weapon:HasTag("homuraTag_ranged")) then
                inst.sg:GoToState("idle")
            end
        end),
    },

    events = {
        CommonEquip(),
        CommonUnequip(),
        ExitSnipinngHandler(),
        ShootHandler(),
    },

    onexit = function(inst)
        if not inst.sg.statemem.shoot then
            if inst.components.homura_sniper:IsSniping() then
                inst.components.homura_sniper:StopSniping()
            end 
        end

        inst.AnimState:ClearOverrideSymbol("player_homura_gun_fire")
    end,
}

AddStategraphState("wilson", homura_shoot)

local homura_shoot_client = State{
    name = "homura_snipeshoot",
    tags = {"notalking", "attack", "busy"},

    onenter = function(inst, data)
        inst.components.locomotor:Stop()

        inst.sg.statemem.preshoot = true

        if data and data.x and data.z then
            inst.sg.statemem.point = Vector3(data.x, 0, data.z)
        end

        inst.AnimState:PlayAnimation("homura_gun_snipeshoot")
        inst:PerformPreviewBufferedAction()
    end,

    timeline = {
        TimeEvent(2*FRAMES, function(inst)
            local action = inst:GetBufferedAction()
            local target = action and action.target
            local point = inst.sg.statemem.point
            if point ~= nil then
                inst:ForceFacePoint(point)
            elseif target ~= nil then
                inst:ForceFacePoint(target:GetPosition())
            end
            inst.sg.statemem.preshoot = false
            
            inst:ClearBufferedAction()
            if inst:HasTag("homuraTag_snipeCD") then
                return
            end
            inst.SoundEmitter:PlaySound("lw_homura/focus/shoot", nil, 0.5, true)
        end),
        TimeEvent(4*FRAMES, function(inst)
            inst.AnimState:PlayAnimation("homura_gun_focus", true)
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("abouttoattack")
            inst.sg:AddStateTag("homura_sniping")

            local weapon = inst.replica.combat:GetWeapon()
            if not (weapon and weapon:HasTag("homuraTag_ranged")) then
                inst.sg:GoToState("idle")
            end
        end),
    },

    events = {
        ExitSnipinngHandler(),
        ShootHandler(),
    },
}

AddStategraphState("wilson_client", homura_shoot_client)
