-- updated at 2022.8.25

local Explosive = Class(function(self,inst)
    self.inst = inst
    self.explosiverange = 3
    self.explosivedamage = 200
    self.buildingdamage = 10
    self.lightonexplode = true
    self.onexplodefn = nil

    -- owner
    self.redirect_to_player = nil

    assert(inst.components.explosive == nil)
    inst.components.explosive = self
end)

function Explosive:SetOnExplodeFn(fn)
    self.onexplodefn = fn
end

local BURNT_CANT_TAGS = { "INLIMBO" }
function Explosive:OnBurnt()
    if not self.skip_camera_flash then
        for i, v in ipairs(AllPlayers) do
            local distSq = v:GetDistanceSqToInst(self.inst)
            local k = math.max(0, math.min(1, distSq / 400))
            local intensity = k * 0.75 * (k - 2) + 0.75 --easing.outQuad(k, 1, -1, 1)
            if intensity > 0 then
                v:ScreenFlash(intensity)
                v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 2)
            end
        end
    end

    if self.onexplodefn ~= nil then
        self.onexplodefn(self.inst)
    end

    local stacksize = self.inst.components.stackable ~= nil and self.inst.components.stackable:StackSize() or 1
    local totaldamage = self.explosivedamage * stacksize

    local x, y, z = self.inst.Transform:GetWorldPosition()
    if self.ignorey then
        y = 0
    end
    local ents = TheSim:FindEntities(x, y, z, self.explosiverange, nil, BURNT_CANT_TAGS)

    local world = TheWorld
    if world.components.dockmanager ~= nil then
        world.components.dockmanager:DamageDockAtPoint(x, y, z, totaldamage * 0.5 --[[homura_mult]])
    end

    for i, v in ipairs(ents) do
        if v ~= self.inst and v:IsValid() and not v:IsInLimbo() 
        and not (v:HasTag("player") and not HOMURA_GLOBALS.PLAYERDMG) then
            if v.components.workable ~= nil and v.components.workable:CanBeWorked() then
                v.components.workable:WorkedBy(self.inst, self.buildingdamage)
            end

            --Recheck valid after work
            if v:IsValid() and not v:IsInLimbo() then
                if self.lightonexplode and
                    v.components.fueled == nil and
                    v.components.burnable ~= nil and
                    not v.components.burnable:IsBurning() and
                    not v:HasTag("burnt") then
                    v.components.burnable:Ignite()
                end

                if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
                    local dmg = totaldamage
                    if v.components.explosiveresist ~= nil then
                        dmg = dmg * (1 - v.components.explosiveresist:GetResistance())
                        v.components.explosiveresist:OnExplosiveDamage(dmg, self.inst)
                    end
                    -- v.components.combat:GetAttacked(self.inst, dmg, nil)
                    v.components.combat:GetAttacked(self.redirect_to_player or self.inst, dmg, nil)
                end

                v:PushEvent("explosion", { explosive = self.inst })
            end
        end
    end

    local world = TheWorld
    for i = 1, stacksize do
        world:PushEvent("explosion", { damage = self.explosivedamage })
    end

    if self.inst.components.health ~= nil then
        world:PushEvent("entity_death", { inst = self.inst, explosive = true, })
        self.inst:PushEvent("death")
    end

    self.inst:Remove()
end

return Explosive