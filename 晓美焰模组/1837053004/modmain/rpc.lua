local function bool(v) return not not v end

-- 2020.12.11
if BANTIMEMAGIC then

AddModRPCHandler("akemi_homura", "timepause", function(inst) end)

else

AddModRPCHandler("akemi_homura", "timepause", function(inst)
    if inst.components.homura_skill then
        inst.components.homura_skill:Trigger()
    end
end)

end

AddModRPCHandler("akemi_homura", "clientkey", function(inst, type, down)
    inst.components.homura_clientkey:OnRemoteKey(type, down)
end)

AddModRPCHandler("akemi_homura", "mouseover", function(inst, ent)
    inst.components.homura_clientkey:OnRemoteEnt(ent)
end)

AddModRPCHandler("akemi_homura", "mousexz", function(inst, x, z)
    if checknumber(x) and checknumber(z) then
        inst.components.homura_clientkey:OnRemoteXZ(x, z)
    end
end)

AddModRPCHandler("akemi_homura", "exitsniping", function(inst)
    if inst.components.homura_sniper and inst.components.homura_sniper:IsSniping() then 
        inst.components.homura_sniper:StopSniping()
    end 
end)

AddModRPCHandler("akemi_homura", "snipeshoot", function(inst, x, z)
    if checknumber(x) and checknumber(z) then
        inst:PushEvent("homuraevt_snipeshoot", {x = x, z = z})
    end
end)

AddModRPCHandler("akemi_homura", "autoreload", function(inst, ammo)
    if checkentity(ammo) then
        local weapon = inst.components.combat:GetWeapon()
        if weapon and weapon.components.homura_weapon and
           ammo.components.inventoryitem and ammo.components.inventoryitem:GetGrandOwner() == inst and 
           not inst.sg:HasStateTag("busy") then
            inst.components.locomotor:PushAction(BufferedAction(inst, weapon, ACTIONS.HOMURA_TAKEAMMO, ammo), true)
            -- inst:PushBufferedAction(BufferedAction(inst, weapon, ACTIONS.HOMURA_TAKEAMMO, ammo))
        end
    end
end)

-- AddPlayerPostInit(function(inst)
--     local function OnControl(control, down)
--         if control == CONTROL_ATTACK or control == CONTROL_CONTROLLER_ATTACK or control == CONTROL_PRIMARY then
--             down = bool(down) -- true, nil -> true, false
--             if control == CONTROL_PRIMARY then
--                 if inst.homura_mousepressed ~= down then
--                     inst.homura_mousepressed = down
--                     if not TheWorld.ismastersim then
--                         SendModRPCToServer(MOD_RPC.akemi_homura.mousepressed, down)
--                     end
--                 end
--             else
--                 if inst.homura_attackpressed ~= down then
--                     inst.homura_attackpressed = down
--                     if not TheWorld.ismastersim then
--                         SendModRPCToServer(MOD_RPC.akemi_homura.attackbutton, down)
--                     end
--                 end
--             end
--         end
--     end
--     inst:DoTaskInTime(0, function()
--         if inst == ThePlayer then
--             inst.homura_controlhandler = TheInput:AddGeneralControlHandler(OnControl)
--             inst:ListenForEvent("onremove", function(inst)
--                 if inst.homura_controlhandler then
--                     inst.homura_controlhandler:Remove()
--                 end
--             end)
--         end
--     end)
-- end)


-- AddComponentPostInit("playercontroller", function(self)
--     local old_update = self.OnUpdate
--     function self:OnUpdate(...)
--         old_update(self, ...)

--         local ent = TheInput:GetWorldEntityUnderMouse()
--         if ent ~= self.inst.homura_mouseover then
--             if TheWorld.ismastersim then
--                 self.inst.homura_mouseover = ent
--                 if not TheWorld.ismastersim then
--                     SendModRPCToServer( MOD_RPC.akemi_homura.mouseovertarget, ent)
--                 end
--             end
--         end
--     end
-- end)
