function GetWeapon(inst)
    return inst.replica.combat and inst.replica.combat:GetWeapon()
end

function CommonEquip()
    return EventHandler("equip", function(inst) inst.sg:GoToState("idle") end) 
end

function CommonUnequip()
    return EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end)
end

function CommonAnimover(name)
    return EventHandler("animover",function(inst) inst.sg:GoToState(name or "idle") end)
end

function CommonAnimQueueOver()
    return EventHandler("animqueueover", function(inst)
        if inst.AnimState:AnimDone()then 
            inst.sg:GoToState("idle")
        end
    end)
end

function CommonProjectileUpdate(inst, dt)
    if (inst.sg.statemem.projectiledelay or 0) > 0 then
        inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
        if inst.sg.statemem.projectiledelay <= 0 then
            if TheWorld.ismastersim then
                inst:PerformBufferedAction()
            else
                inst:ClearBufferedAction()
            end
            inst.sg:RemoveStateTag("abouttoattack")
        end
    end
end

function GetClientKey(inst, type)
    if type == "attack" then
        return inst.components.homura_clientkey.attack
    elseif type == "raction" then
        return inst.components.homura_clientkey.raction
    elseif type == "mouseover" then
        return inst.components.homura_clientkey.mouseover
    else
        assert(false, "Invalid param: "..tostring(type))
    end
end

local TOO_CLOSE_WARNING = L and "It's too close!" or "太近了! 会波及到我的!"

local function EventPostInit(self)
    local old_fn = self.actionhandlers[ACTIONS.ATTACK].deststate
    self.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action)

        local isdead = inst.replica.health and inst.replica.health:IsDead()
        local item = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local target = action.target
        local combat = inst.components.combat or inst.replica.combat

        local isblind = inst.replica.homura_lightshocked:IsBlind()

        if isblind and not isdead and target and target.prefab == 'fake_target_player' then
            return 'attack'
        end
        if isdead or not(item and target and item:IsValid() and target:IsValid() and combat) then
            return old_fn(inst, action)
        end

        if item.prefab == "homura_stickbang" then
            if inst.replica.rider:IsRiding() then
                return old_fn(inst, action)
            else
                return "homura_stickbang"
            end
        end

        if item.prefab == "homura_rpg" and item:HasTag('homuraTag_ranged') then
            if target and target:IsValid() and target:GetDistanceSqToInst(inst) <= 4*4 then
                combat:SetTarget(nil)
                if inst.components.talker then
                    if not inst.components.talker.widget and not inst.components.talker.task then
                        inst.components.talker:Say(TOO_CLOSE_WARNING)
                    elseif inst.components.talker.widget ~= nil and inst.components.talker.widget.text:GetString() ~= TOO_CLOSE_WARNING then
                        inst.components.talker:Say(TOO_CLOSE_WARNING)
                    elseif inst.components.locomotor then
                        inst.components.locomotor:Stop()
                    end
                end
                return
            else
                return "homura_rpg"
            end
        end

        if item.prefab == "homura_rifle" then
            if not item:HasTag("homuraTag_ranged") then
                return old_fn(inst, action)
            elseif inst.sg:HasStateTag("homura_sniping") then
                inst.sg.statemem.shoot = true
                return "homura_snipeshoot"
            elseif not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("abouttoattack") then
                return "homura_sniping"
            end
        end

        if item:HasTag('homuraTag_ranged') then
            -- 2021.12.24 Add new pistols
            if item.prefab == "homura_pistol"
                or item.prefab == "homura_snowpea"
                or item.prefab == "homura_shabby_pistol" then

                if not inst.sg:HasStateTag("homura_pistol_atk") then
                    return "homura_pistol_atk"
                else
                    return nil
                end
            elseif item.prefab == "homura_gun"
                or item.prefab == "homura_hmg"
                or item.prefab == "homura_tr_gun" then
                if not inst.sg:HasStateTag("homura_gun_atk") then
                    return "homura_gun_pre"
                else
                    return nil
                end
            elseif item.prefab == "homura_watergun" then
                if not inst.sg:HasStateTag("homura_watergun") then
                    return "homura_watergun"
                else
                    return nil
                end
            end
        end

        return old_fn(inst, action)
    end

    local attacked = self.events.attacked
    if attacked ~= nil then
        local old_handler = attacked.fn
        function attacked.fn(inst, data)
            local bugtracker_ignore_flag__fn = true
            if inst.sg:HasStateTag("homura_stickbang_hit") then
                return
            end
            return old_handler(inst, data)
        end
    end

    -- 2021.12.21 homura quick build
    local build = self.actionhandlers[ACTIONS.BUILD]
    local old_build_fn = build.deststate
    function build.deststate(inst, action)
        local rec = GetValidRecipe(action.recipe)
        if inst:HasTag("homura") then
            if type(rec.name) == "string" and string.find(rec.name, "homura_") then
                if rec.name ~= "homura_bow" then
                    return "domediumaction"
                end
            end
        end

        return old_build_fn(inst, action)
    end
end

AddStategraphPostInit("wilson", EventPostInit)
AddStategraphPostInit("wilson_client", EventPostInit)

modimport "modmain/SGrunutil.lua"
modimport 'modmain/SGrpg.lua'
modimport "modmain/SGwater.lua"
modimport 'modmain/SGpistol.lua'
modimport 'modmain/SGgun_pre.lua'
modimport 'modmain/SGgun.lua'
modimport "modmain/SGsnipe.lua"
modimport "modmain/SGstick.lua"
modimport "modmain/SGrush.lua"
modimport "modmain/SGbook.lua"
modimport "modmain/SGbow.lua"