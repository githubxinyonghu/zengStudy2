local function PlayPreSound(inst, prefab)
    if prefab ~= nil then
        local sfx, volume
        if prefab == "homura_gun"or prefab == "homura_hmg" then
            sfx = "lw_homura/sfx/load_down_3d"
            volume = .7
        elseif prefab == "homura_tr_gun" then
            sfx = "dontstarve/wilson/attack_weapon"
            volume = 1.0
        end
        
        inst.SoundEmitter:PlaySound(sfx, nil, volume, true)
    end
end

local pre = function(ismastersim) return State{
    name = "homura_gun_pre",
    tags = {"attack", "notalking", "abouttoattack", "autopredict"},
        
    onenter = function(inst)
        local action = inst:GetBufferedAction()
        local target = action and action.target
        local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local prefab = weapon and weapon.prefab

        if action ~= nil and not ismastersim then
            inst:PerformPreviewBufferedAction()
        end

        inst.components.locomotor:Stop()
       
        inst.AnimState:PlayAnimation("homura_gun_pre")
        PlayPreSound(inst, prefab)

        if target and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
        end

        inst.sg.statemem.weapon = weapon
    end,

    timeline =
    {
        TimeEvent(7*FRAMES, function(inst)
            inst.sg.statemem.atk = true
            local weapon = inst.sg.statemem.weapon
            if not weapon then
                inst.sg:GoToState("idle")
            elseif weapon.prefab == "homura_gun"
                or weapon.prefab == "homura_hmg"
                or weapon.prefab == "homura_tr_gun" then
                inst.sg:GoToState("homura_gun_atk")
            end
        end),
    },

    events = {
        CommonAnimover(),
        CommonEquip(),
        CommonUnequip(),
    },

    onexit = function(inst)
        if not inst.sg.statemem.atk then
            inst:ClearBufferedAction()
        end
    end,
}
end

AddStategraphState("wilson", pre(true))
AddStategraphState("wilson_client", pre(false))


local pst = function() return State{
    name = "homura_gun_pst",
    tags = {"notalking"},

    onenter = function(inst)
        inst.AnimState:PlayAnimation("homura_gun_pst")
        inst.sg:SetTimeout(5*FRAMES)
    end,

    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
}
end

AddStategraphState("wilson", pst())
AddStategraphState("wilson_client", pst())

