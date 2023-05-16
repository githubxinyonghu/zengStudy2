local function PlayerSay(inst, str)
    if inst.components.talker and not inst:HasTag("mime") then
        inst.components.talker:Say(str)
    end
end

local GetCheckAmmoFn = require "homura.weapon".GetCheckAmmoFn

local SPEECH_HOMURA = SPEECH_HOMURA
local SPEECH_GENERIC = SPEECH_GENERIC

SPEECH_GENERIC.ACTIONFAIL.HOMURA_ADDBUFF_DESK = {
    NOTREAD = L and "Read the manual carefully before operating this precision instrument!" or "操作这种精密仪器前，应该先认真阅读操作手册!",
    OCCUPIED = L and "Someone is using the workbench." or "有人正在使用工作台。",
    NOCONTAINER = L and "The gun cannot install fitting." or "这把枪无法安装配件。"
}
SPEECH_GENERIC.ACTIONFAIL.HOMURA_ADDBUFF_INV = {
    NOTREAD = SPEECH_GENERIC.ACTIONFAIL.HOMURA_ADDBUFF_DESK.NOTREAD,
    NODESK = L and "This kind of professional operation requires a weapon bench." or "这种专业操作，得有个武器工作台才行。",
    NOCONTAINER = SPEECH_GENERIC.ACTIONFAIL.HOMURA_ADDBUFF_DESK.NOCONTAINER,
}
SPEECH_HOMURA.ACTIONFAIL.HOMURA_ADDBUFF_INV = {
    NOTREAD = SPEECH_GENERIC.ACTIONFAIL.HOMURA_ADDBUFF_DESK.NOTREAD,
    NODESK = L and "I need a work desk." or "材料齐全, 现在只缺一个工作台。",
    NOCONTAINER = L and "There's no fitting slot on this gun, too bad." or "枪上没有任何配件接口，很可惜.."
}

-- 此处仅检查有无标签
local function CheckPlayerHasReadBook(player, desk)
    if player and desk then
        if player:HasTag("homura") then
            return true
        end
        if desk:HasTag("homura_workdesk") then
            local i = desk.level
            if i ~= nil and player:HasTag("homuraTag_level"..i.."_builder") then
                return true
            end
        end
    end
end

-- 加载配件
-- 触发方法: 将武器放到工作台上
local ADDBUFF_DESK = Action({mount_valid = true}) 
ADDBUFF_DESK.id = "HOMURA_ADDBUFF_DESK"
ADDBUFF_DESK.str = L and "Modify" or "添加配件"
ADDBUFF_DESK.fn = function(act)
    if act.invobject and act.invobject:HasTag("homuraTag_no_container") then
        return false, "NOCONTAINER"
    end
    local gun = act.invobject
    local desk = act.target
    if desk == nil then
        return false
    end

    local i = desk.level or 0
    local player = act.doer
    -- check builder tag
    if not CheckPlayerHasReadBook(player, desk) then
        return false, "NOTREAD"
    end
    -- check desk owner
    if desk.user and desk.user ~= player then
        return false, "OCCUPIED"
    end
    gun.components.container:Open(act.doer)
    gun:PushEvent('homuraevt_openbuffslot',{desk = desk, player = player})
    return true
end

-- 加载配件
-- 触发方法: 将配件放在武器上（容器添加逻辑）
local ADDBUFF_INV = Action({mount_valid = true})
ADDBUFF_INV.id = "HOMURA_ADDBUFF_INV" 
ADDBUFF_INV.str = ADDBUFF_DESK.str
ADDBUFF_INV.fn = function (act)
    if act.target and act.target:HasTag("homuraTag_no_container") then
        return false, "NOCONTAINER"
    end

    if act.target and act.target.components.container:IsOpen() then
        return ACTIONS.STORE.fn(act)
    else
        -- check nearby workdesk
        local workdesk_free = FindEntity(act.doer, 3, function(inst) 
            return inst:HasTag("homura_workdesk") and inst.user == nil 
        end)
        local workdesk_using = FindEntity(act.doer, 3, function(inst)
            return inst:HasTag("homura_workdesk") and inst.user ~= nil
        end)

        if not workdesk_using and not workdesk_free then
            return false, "NODESK"
        end

        if workdesk_using and workdesk_using.user == act.doer then
            -- using, no need to recheck tag here.
            if workdesk_using.gun and workdesk_using.gun.components.homura_weapon then
                workdesk_using.gun.components.homura_weapon:DetachWorkdesk()
                workdesk_free = workdesk_using
            end
        end

        if workdesk_free then
            if not CheckPlayerHasReadBook(act.doer, workdesk_free) then
                return false, "NOTREAD"
            end

            act.target.components.container:Open(act.doer)
            act.target:PushEvent('homuraevt_openbuffslot',{desk = workdesk_free, player = act.doer})
            return ACTIONS.STORE.fn(act)
        else
            return false, "OCCUPIED"
        end
    end
end

AddAction(ADDBUFF_DESK)
AddStategraphActionHandler("wilson_client", ActionHandler(ADDBUFF_DESK, "give"))
AddStategraphActionHandler("wilson", ActionHandler(ADDBUFF_DESK, "give"))

AddAction(ADDBUFF_INV)
AddStategraphActionHandler("wilson_client", ActionHandler(ADDBUFF_INV, "give"))
AddStategraphActionHandler("wilson", ActionHandler(ADDBUFF_INV, "give"))

local function testfn_useitem(inst, doer, target, actions, right)
    if target:HasTag("homura_workdesk") and doer:HasTag("player") then
        table.insert(actions, ACTIONS.HOMURA_ADDBUFF_DESK)
    end
end

local function testfn_equipped(inst, doer, target, actions, right)
    testfn_useitem(inst, doer, target, actions, right)

    if right then
        if inst.prefab == "homura_rifle" and target:HasTag("_combat") and doer:HasTag("player") and not doer:HasTag("homuraTag_issniping") then
            table.insert(actions, ACTIONS.HOMURA_SNIPER)
        end
    end
end

AddComponentAction("USEITEM", "homura_weapon", testfn_useitem)
AddComponentAction("EQUIPPED", "homura_weapon", testfn_equipped)

local testfn = function(inst, doer, target, actions, right)
    if doer:HasTag('player') and (target:HasTag("homuraTag_gun") or target.prefab == "homura_rpg") then
        table.insert(actions, ACTIONS.HOMURA_ADDBUFF_INV)
    end
end

AddComponentAction("USEITEM", 'homura_weapon_buff', testfn)

----------------
----添加子弹-----
----------------
local ADD_AMMO = Action({mount_valid=true}) 
ADD_AMMO.id = "HOMURA_TAKEAMMO" ADD_AMMO.str = L and "Reload" or "填弹"
ADD_AMMO.fn = function(act)
    act.target.components.homura_weapon:OnAccept(act.invobject, act.doer)
    return true
end
AddAction(ADD_AMMO)
AddStategraphActionHandler("wilson_client", ActionHandler(ADD_AMMO, "give"))
AddStategraphActionHandler("wilson", ActionHandler(ADD_AMMO, "give"))

AddComponentAction("USEITEM", "homura_ammo", function(inst, doer, target, actions, right)
    if target:HasTag("homuraTag_fullammo") then
        return
    end
    if target.prefab == "homura_tr_gun" then
        return
    end

    if GetCheckAmmoFn(target)(inst) then
        table.insert(actions, ADD_AMMO)
    end
end)

AddPrefabPostInit("ice", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("homura_ammo")
    end
end)

-------------
--- 狙击 ----
-------------

local SNIPER = Action({mount_valid=true, distance=math.huge, priority = 100}) 
SNIPER.id = "HOMURA_SNIPER"
SNIPER.str = L and "Snipe" or "开镜"
SNIPER.fn = function(act)
    if act.invobject:HasTag("homuraTag_ranged") then
        act.doer.components.homura_sniper:StartSniping()
        return true
    else
        return false, "AMMO"
    end
end

SPEECH_GENERIC.ACTIONFAIL.HOMURA_SNIPER = {
    AMMO = L and "Add ammo first." or "得先装填子弹。",
}

AddAction(SNIPER)
AddStategraphActionHandler("wilson", ActionHandler(SNIPER, "homura_sniping"))
AddStategraphActionHandler("wilson_client", ActionHandler(SNIPER, "homura_sniping"))

AddComponentAction("POINT", "homura_weapon", function(inst, doer, pos, actions, right)
    if right then
        if inst.prefab == "homura_rifle" then
            if not doer:HasTag("homuraTag_issniping")then
                table.insert(actions, SNIPER)
            end
        end
    end
end)

AddPrefabPostInit("homura_rifle", function(inst)
    inst:AddTag("allow_action_on_impassable")
end)

-----------------
------ 阅读 ------
-----------------

local READ = Action({mount_valid = true})
READ.id = "HOMURA_READ"
READ.str = STRINGS.ACTIONS.READ
SPEECH_GENERIC.ACTIONFAIL.HOMURA_READ = {
    LEARNT = Loc("The above knowledge is very important and I will keep it in mind.", "上面的知识很重要，我会牢记在心的。"),
    DEPEND = Loc("It's too hard! I'd better learn some basics first.", "好难！我得先去学习一下基础手册。")
}
SPEECH_HOMURA.ACTIONFAIL.HOMURA_READ = {
    LEARNT = Loc("I already know the contents of this handbook.", "这本册子的内容我已经倒背如流了。"),
    DEPEND = Loc("Don't rush to success, master the knowledge of the primary manual first.", "学习不能急于求成，先掌握初级手册的知识吧。")
}
READ.fn = function(act)
    return act.doer.components.homura_reader:StartReading(act.invobject)
end

AddAction(READ)
AddStategraphActionHandler("wilson", ActionHandler(READ, "homura_book_open"))
AddStategraphActionHandler("wilson_client", ActionHandler(READ, "book_peruse"))

AddComponentAction("INVENTORY", "homura_book", function(inst, doer, actions)
    table.insert(actions, READ)
end)

--------------------
----- 弓箭蓄力 ------
--------------------

local BOW = Action({mount_valid = true, distance = math.huge--[[, instant = true]]})
BOW.id = "HOMURA_BOW"
BOW.str = {
    DEFAULT = Loc("String", "拉弓"),
    CONTROLLER = Loc("String (use right joystick to adjust collimation)", "拉弓（右摇杆调整准心）"),
}
BOW.strfn = function(act)
    return act.doer.components.playercontroller and act.doer.components.playercontroller.isclientcontrollerattached
        and "CONTROLLER" or "DEFAULT"
end
BOW.fn = function(act)
    return true
end

local function bow(inst)
    if not inst.sg:HasStateTag("homura_bow") then
        return "homura_bow_pre"
    end
end

AddAction(BOW)
AddStategraphActionHandler("wilson", ActionHandler(BOW, bow))
AddStategraphActionHandler("wilson_client", ActionHandler(BOW, bow))

AddComponentAction("POINT", "homura_bow", function(inst, doer, pos, actions, right)
    if right then
        if not doer:HasTag("homuraTag_bow_aiming") then
            table.insert(actions, BOW)
        end
    end
end)

AddPrefabPostInit("homura_bow", function(inst)
    inst:AddTag("allow_action_on_impassable")
end)

--------------------
---- 添加设计图 -----
--------------------

local SKETCH = Action({mount_valid = true})
SKETCH.id = "HOMURA_SKETCH"
SKETCH.str = Loc("Place", "添加图纸")
SKETCH.fn = function(act)
    if act.target.level == 1 then
        return false, "LEVEL"
    else
        return act.target:AddSketch(act.invobject)
    end
end

SPEECH_GENERIC.ACTIONFAIL.HOMURA_SKETCH = {
    LEVEL = L and "This workbench is not advanced enough." or "这个工作台还不够高级",
    HAS = L and "The weapon has been unlocked." or "这件武器已经解锁了"
}
SPEECH_HOMURA.ACTIONFAIL.HOMURA_SKETCH = {
    LEVEL = L and "I need to build an advanced workbench to use this sketch." or "我得建一个高级工作台才能利用这张图纸",
    HAS = L and "The weapon has been unlocked." or "我以前添加过相同的武器图纸",
}
AddAction(SKETCH)
AddStategraphActionHandler("wilson", ActionHandler(SKETCH, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(SKETCH, "give"))

AddComponentAction("USEITEM", "homura_sketch", function(inst, doer, target, actions)
    if target:HasTag("homura_workdesk") then
        table.insert(actions, SKETCH)
    end
end)

----------------
---- 呼叫空投 ---
----------------

local HELP = Action({mount_valid = true})
HELP.id = "HOMURA_HELP"
HELP.str = Loc("Call for airdrop", "呼叫空投")
HELP.fn = function(act)
    act.target.components.homura_reinforcement:Touch()
    return true
end

AddAction(HELP)
AddStategraphActionHandler("wilson", ActionHandler(HELP, "domediumaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(HELP, "domediumaction"))

AddComponentAction("SCENE", "homura_reinforcement", function(inst, doer, actions)
    if inst:HasTag("homuraTag_charge") then
        table.insert(actions, HELP)
    end
end)

