TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.HOMURA_1 = {}
STRINGS.CHARACTER_SURVIVABILITY.homura_1 = HOMURA_GLOBALS.L and "Normal" or "一般"

local MakePlayerCharacter = require "prefabs/player_common"

local common_postinit = function(inst)
    inst.MiniMapEntity:SetIcon( "homura_1.tex" )

    inst:AddTag("homura")
    inst:AddTag("homuraTag_workdesk_builder")

    -- inst:AddTag("homuraTag_level1_builder")
    -- inst:AddTag("homuraTag_level2_builder")
end

local master_postinit = function(inst)
    inst.soundsname = "wendy"

    inst.components.health:SetMaxHealth(TUNING.HOMURA_1_HEALTH)
    inst.components.hunger:SetMax(TUNING.HOMURA_1_HUNGER)
    inst.components.sanity:SetMax(TUNING.HOMURA_1_SANITY)
    inst.components.sanity.dapperness = TUNING.HOMURA_1_SANITY_REGEN

    inst:AddComponent("homura_skill")

    local old_calc = inst.components.combat.CalcDamage
    inst.components.combat.CalcDamage = function(self, target, weapon, ...)
        local v = 1
        if inst.components.rider and inst.components.rider:IsRiding() then
            --
        elseif weapon == nil then
            v = 0.75
        elseif weapon:HasTag("projectile") or weapon:HasTag("rangedweapon") then
            --
        elseif weapon.components.projectile then
            --
        elseif weapon.components.weapon and weapon.components.weapon.projectile then
            --
        else
            v = 0.75
        end
        return v* old_calc(self, target, weapon, ...)
    end
end

local skintags = {'homura_1', 'CHARACTER'}

return MakePlayerCharacter("homura_1", nil, nil, common_postinit, master_postinit),
HOMURA_GLOBALS.RegisterSkin('none', {normal_skin = 'homura_1', ghost_skin = 'ghost_homura_1_build'}, skintags),
HOMURA_GLOBALS.RegisterSkin('moe',  {normal_skin = 'homura_0', ghost_skin = 'ghost_homura_1_build'}, skintags)
