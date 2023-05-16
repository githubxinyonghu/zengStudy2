require 'class'

local function quickset(shortname,name,desc,recipe)
    local prefab = "HOMURA_WEAPON_BUFF_"..shortname:upper()
    -- STRINGS.NAMES[prefab] = name 
    STRINGS.NAMES[prefab] = "◇" .. name 
    STRINGS.CHARACTERS["HOMURA_1"].DESCRIBE[prefab] = desc
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[prefab] = HOMURA_GLOBALS.LANGUAGE and "Nice fitting" or '一个精密的配件'
    STRINGS.RECIPE_DESC[prefab] = recipe
end

local buffstrings = HOMURA_GLOBALS.LANGUAGE and
{
    ice = {'Tiny refrigerator','So cold!','Cool bullets and rockets.'},
    wind = {'Winnower','Hate windy days?','The wind howling.'},
    code = {'Code editer','Copy the bonus from left fitting','Use lua script to do everything.'},
    -- graphite = {'石墨发射器'},
    magic = {'Magic circuit','Deal magic damage!','Injects magic into bullets.'},

    time = {'Sand glass','Fly in frozen time.','Resist time magic.'},
    lens = {'Lens','Focus to shoot.','Increases range and accuracy.'},
    eye_lens = {'E-Y-E','Target locked!','Advanced len for sniper rifles.'},
    homing = {'Projectile guider','Newton felt confused.','Turn the bullet around.'},
    knife = {'Knife','Use gun as a melee weapon.','Sharpen your gun.'},

    silent = {'Silencer','Silence!','Significantly reduces noise from shooting.'},
    waterproof = {'Waterproofer','My gun should be dry.','Keep weapon from dampness.'},
    flyingspeed = {'Electromagnetic accelerator','It\'s a small accelerator.','Speed up projectiles.'},
    clip = {'Super clip','Small, but huge.','Increase the ammunition capacity.'},
    mouse = {'Mouse macro','Is it cheat?','\"No plugins are used\"'},

    laser = {"Prism", "Do you want to see a rainbow?", "Simple optical system."},
    wormhole = {"Mini wormhole", "Its eyes roll!", "Can teleport small items."},
}
or
{
    ice = {'制冷装置','好冷！','急速降温（不含氟利昂）'},
    wind = {'风车','讨厌风大的日子吗？','狂风呼啸'},
    code = {'代码编辑器','代码敲得我头都突了。','没有什么是不能用一行代码来解决的'},
    -- graphite = {'石墨发射器'},
    magic = {'魔术回路','要用魔法打败魔法。','向子弹注入魔力，当心走火入魔！'},

    time = {'沙漏','子弹:\"我还能再飞一会儿!\"','提升子弹对时间魔法的抗性'},
    lens = {'红点准镜','我可以射的更准一点。','提高武器射程和命中率'},
    eye_lens = {'眼睛','我可以用它来锁定目标','狙击枪专用的高级瞄准镜'},
    homing = {'牛顿的棺材板','让子弹拐弯是有原理的... 出膛的一瞬间，\n手腕快速抖动，给子弹一个水平的加速度...','让子弹自动追踪目标！'},
    knife = {'刺刀','我拿着一把枪...砸人？','提升武器的近战攻击力'},

    silent = {'消音器','安静多了','大幅降低射击噪音'},
    waterproof = {'防水涂层','保持干燥','防止武器受潮'},
    flyingspeed = {'电磁加速线圈','安培力加速装置','提升子弹的出膛射速'},
    clip = {'四次元的弹夹','哇，这么小的弹夹，塞那么多子弹。','能塞很多的弹药'},
    mouse = {'鼠标宏','要不要我展示一下十枪一孔？','没有开挂'},

    laser = {"棱镜", "一束光，一道彩虹。", "简单的光学系统"},
    wormhole = {"迷你虫洞", "它的眼睛会动！", "可用于传送小物品"},
}
for shortname,strings in pairs(buffstrings)do
    quickset(shortname,strings[1],strings[2],strings[3])
end

----------------------------------------------------------------------------------------

local Buff = Class(function(self, data) 
    self.data = data

    self.stackable = data.stackable == true
    self.value = data.value
end)

function Buff:__tostring()
    return string.format("Buff: %s", self.name)
end

function Buff:ApplyOnData(data, stack)
    for k,v in pairs(self.data)do
        if k == "value" or k == "stackable" then
            -- pass
        elseif v == true then
            data[k] = true
        else
            data[k] = (data[k] or 0) + v * (self.stackable and stack or 1)
        end
    end
end

local ALLBUFF = 
{
    -- STACKABLE 
    ice         = Buff{coldness_ADD = 1.5, stackable = true},
    wind        = Buff{tornado_ADD = 5/100, stackable = true},
    flyingspeed = Buff{speed_MULT = 0.2, range_MULT = 0.1, maxhits_ADD = 1, stackable = true},  
    magic       = Buff{truedamage_ADD = 10, sanitycost_ADD = 1, stackable = true},

    -- FLAG 
    time        = Buff{},
    silent      = Buff{},
    waterproof  = Buff{value = -0.2},
    clip        = Buff{value = 5},
    mouse       = Buff{angle_REPLACE = 0},
    code        = Buff{},--@--
    eye_lens    = Buff{},
    homing      = Buff{damage1_MULT = -0.2},
    wormhole    = Buff{},
    laser       = Buff{maxreflects_REPLACE = 3},
    lens        = Buff{angle_MULT = -0.3, range_var_ADD = 0.1}, 
    knife       = Buff{damage2_ADD = 20},
}

for k,v in pairs(ALLBUFF)do
    v.name = k
end

HOMURA_GLOBALS.ALLBUFF = ALLBUFF

local function MakeBuff(name)
    local prefabname = "homura_weapon_buff_"..name
    local function fn() 
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local net   = inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "small", 0.1, 0.75)

        local s = 0.4
        -- trans:SetScale(s,s,s)
        anim:SetScale(s, s)

        anim:SetBank("homura_weapon_buff")
        anim:SetBuild("homura_weapon_buff")
        anim:PlayAnimation("idle", true)
        anim:OverrideSymbol('swap', resolvefilepath("images/homura_weapon_buff.xml"), prefabname..".tex")
        --anim:SetBloomEffectHandle("shaders/anim.ksh")
        
        inst:AddTag("homuraTag_buff")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("homura_weapon_buff")

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = 'images/homura_weapon_buff.xml'
        inst.components.inventoryitem.imagename = prefabname

        MakeHauntableLaunch(inst)
        
        inst.shortname = name
        inst.homura_weapon_buff = ALLBUFF[name]

        return inst
    end

    return Prefab(prefabname,fn,nil,nil)
end


local prefabs = {}

for name,v in pairs(ALLBUFF)do
    table.insert(prefabs, MakeBuff(name))
end

local function random()
    local name = GetRandomItem(table.getkeys(ALLBUFF))
    return SpawnPrefab("homura_weapon_buff_"..name)
end

table.insert(prefabs, Prefab("homura_weapon_buff_random", random))

return unpack(prefabs)

