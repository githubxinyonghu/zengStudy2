local DeltaAngleAbs = require "homura.math".DeltaAngleAbs

local assets= 
{
    Asset("ANIM", "anim/homura_bomb.zip"),
    Asset("ATLAS","images/inventoryimages/homura_bomb_bomb.xml"),
    Asset("ATLAS","images/inventoryimages/homura_bomb_flash.xml"),
    Asset("ATLAS","images/inventoryimages/homura_bomb_fire.xml"),
}
--  air 空中动画
--  swap_XXX手持通道

local function quickset(prefab,name,desc_data,recipe)
    STRINGS.NAMES[prefab:upper()] = name 
    for cha,desc in pairs(desc_data)do
        STRINGS.CHARACTERS[cha:upper()].DESCRIBE[prefab:upper()] = desc
    end
    STRINGS.RECIPE_DESC[prefab:upper()] = recipe
end

if HOMURA_GLOBALS.LANGUAGE then
    quickset("HOMURA_BOMB_FLASH","Flashbang",
        {
            GENERIC = "The burning of magnesium is used to give out strong light.",
        },"Blinding everything around")

    quickset("HOMURA_BOMB_FIRE","Molotov",
        {
            GENERIC = "Looks dangerous.",
        },"Fire, Fire, Fire")

    quickset("HOMURA_BOMB_BOMB","Bomb",
        {
            GENERIC = "Keep away from yourself and others on thrown.",
        },"Make a magnificent explosion")
else
    quickset("HOMURA_BOMB_FLASH","闪光弹",
        {
            GENERIC = "a1高闪来一个好吗，秋梨膏。",
            HOMURA_1 = "利用镁的燃烧来释放强光。",
        },"放出刺眼的强光。")

    quickset("HOMURA_BOMB_FIRE","莫洛托夫鸡尾酒",
        {
            GENERIC = "这东西看起来很危险。",
            HOMURA_1 = "天干物燥, 小心火烛。",
        },"让火焰净化一切!")

    quickset("HOMURA_BOMB_BOMB","破片手雷",
        {
            GENERIC = "投掷时注意远离自己和他人。",
            HOMURA_1 = "我研究了一晚上就把它给做出来了。",
        },"住手! 这根本就不是魔法。")
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function commonfn(prefabname)  --触地即爆炸

    local function onthrown(inst)
        inst:AddTag("thrown")
        inst:PushEvent('homura.onthrown')
        inst.AnimState:PlayAnimation(prefabname.."_air",true)
        inst.Physics:SetFriction(.2)

        -- inst.components.health:SetInvincible(true)
        inst.components.ignoretimemagic:Set(2)
    end
    local function onequip(inst,owner)
        owner.AnimState:OverrideSymbol("swap_object", "homura_bomb", "swap_"..prefabname)
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end
    local function onunequip(inst,owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end

    local function onputininventory(inst)
        inst:RemoveTag('thrown')
        inst.AnimState:PlayAnimation(prefabname.."")
        inst.Physics:SetFriction(.1)
        -- inst.components.health:SetInvincible(true)
        inst.components.ignoretimemagic:SetInventory()
        inst.components.complexprojectile.attacker = nil
    end

    local function ondropped(inst)
        -- inst.components.health:SetInvincible(false)
    end

    local function onhit(inst)
        inst:PushEvent("hitground")
        -- if not inst.components.health:IsDead() then
        --     inst.components.health:SetInvincible(false)
        --     inst.components.health:DoDelta(-10, nil, nil, true)
        -- end
    end

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local snd = inst.entity:AddSoundEmitter()
    local net = inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med")

    anim:SetBuild("homura_bomb")
    anim:SetBank("homura_bomb")
    anim:PlayAnimation(prefabname)

    inst:AddTag("projectile")
    inst:AddTag("throwable")
    inst:AddTag("explosive")
    inst:AddTag("notarget")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(onhit)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(onputininventory)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/homura_bomb_"..prefabname..".xml"
    inst:ListenForEvent('ondropped', ondropped)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    -- inst:AddComponent("health")
    -- inst.components.health:SetMaxHealth(1)
    -- inst.components.health.vulnerabletopoisondamage = 1
    -- inst.components.health.canmurder = false
    -- inst.components.health.canheal = false
    -- inst.components.health.nofadeout = true

    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true

    inst:AddComponent("combat")

    inst:AddComponent("ignoretimemagic")

    return inst
end

local function PanicTick(inst)
    local combat = inst.components.combat
    if combat ~= nil then
        combat.lw_panictime = combat.lw_panictime - FRAMES
        combat:SetTarget(nil)
        if combat.lw_panictime <= 0 then
            combat.lw_panictask = combat.lw_panictask and combat.lw_panictask:Cancel() and nil 
        end
    end
    if inst.components.health ~= nil then
        inst.components.health:DoFireDamage(0, nil, true)
    end
end

local function CreateLight()
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddLight()
    
    inst.Light:Enable(true)
    inst.Light:SetIntensity(.2)
    inst.Light:SetColour(1,1,1)
    inst.Light:SetFalloff(.5)
    inst.Light:SetRadius(20)

    inst:DoTaskInTime(0.1, inst.Remove)

    return inst
end

local function lighthit(inst)
    inst:RemoveEventCallback("hitground", lighthit)
    
    local pos = inst:GetPosition()
    inst.SoundEmitter:PlaySound('lw_homura/flashbang/flash')
    SpawnPrefab("explode_small").Transform:SetPosition(pos:Get()) 
    CreateLight().Transform:SetPosition(pos:Get())

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 20, nil, {"FX", "NOCLICK", "DECOR", "INLIMBO",}, {"_combat", "shadowhand"})
    for k,v in pairs(ents) do
        if v.prefab == "shadowhand" then
            v:PushEvent("enterlight")
        elseif v.components.combat == nil or v.components.health == nil then
            -- pass
        elseif v.components.health:IsDead() then
            -- pass
        elseif v:HasTag('player') then
            local delta = DeltaAngleAbs(v.Transform:GetRotation(), v:GetAngleToPoint(pos))
            local dist = math.sqrt(v:GetDistanceSqToPoint(pos))
            if delta <= 75 then
                local time = dist <= 10 and 10 or (20 - dist)
                v.components.homura_lightshocked:SetTime(time)
            else
                v.components.homura_lightshocked:SetTime(nil)
            end
        elseif v:HasTag('shadow') then
            v.components.combat:GetAttacked(inst, 50, inst, 'lightshock')
        else
            local combat = v.components.combat
            -- Run panic task
            if not v:HasTag("homuraTag_lighshockimmune") then
                combat.lw_panictime = GetRandomMinMax(10,15)
                combat.lw_panictask = combat.lw_panictask and combat.lw_panictask:Cancel() and nil
                combat.lw_panictask = v:DoPeriodicTask(0, PanicTick)
            end
        end
    end
    
    inst:Remove()
end

local function FlashBomb()
    local inst = commonfn("flash")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent('hitground', lighthit)

    return inst
end

local function firehit(inst)
    inst:RemoveEventCallback("hitground", firehit)

    local pos = inst:GetPosition()
    local notags = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
    if not HOMURA_GLOBALS.PLAYERDMG then
        table.insert(notags, "PLAYER")
    end
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 5, nil, notags)
    for k,v in pairs(ents)do
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
    inst.components.lootdropper:DropLoot(pos)
    inst:Remove()
end

local function Fire()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargeBurnable(inst, 25 + math.random() * 5)
    MakeLargePropagator(inst)

    inst.components.burnable:SetOnIgniteFn(nil)
    inst.components.burnable:SetOnExtinguishFn(inst.Remove)
    inst.components.burnable:Ignite()

    return inst
end

local function fireloot(self)
    local loot = {}
    for i = 1, math.random(8, 10)do
        table.insert(loot, "homura_houndfire")
    end
    self:SetLoot(loot)
end

local function FireBomb()
    local inst = commonfn("fire")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("hitground", firehit)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLootSetupFn(fireloot)
    inst.components.lootdropper.GetRecipeLoot = function()return {} end

    return inst
end

local function bombhit(inst)
    inst:RemoveEventCallback("hitground", bombhit)

    SpawnPrefab("explode_small").Transform:SetPosition(inst:GetPosition():Get())

    inst.components.explosive.redirect_to_player = inst.components.complexprojectile.attacker
    inst.components.explosive:OnBurnt()
    inst:Remove()
end


local function Bomb()
    local inst = commonfn("bomb")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent('hitground', bombhit)

    inst:AddComponent("homura_explosive")

    inst.components.explosive.explosivedamage = 200
    inst.components.explosive.buildingdamage = 30
    inst.components.explosive.explosiverange = 3
    inst.components.explosive.lightonexplode = false
    inst.components.explosive.noremove = true
    
    return inst
end

return 
Prefab("homura_bomb_flash", FlashBomb,assets),
Prefab("homura_bomb_fire",  FireBomb,assets),
Prefab("homura_bomb_bomb",  Bomb,assets),

Prefab("homura_houndfire", Fire)
