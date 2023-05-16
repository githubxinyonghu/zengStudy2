-- 老王的留言:  

-- [1]
-- 晓美焰mod的源代码（包括 .lua, .ksh, .xml 文件）使用 WTFPL协议 (http://www.wtfpl.net)
-- 任何人都可以自由地修改和重新发布  
-- 请修改者自行处理代码变动引发的一切效果，我不提供任何技术支持  

-- [2]
-- 如果你想只是修改数值，请找这个 -> modmain/tuning.lua  
-- 切勿使用“记事本”修改代码，否则可能会发生游戏崩溃  
-- 推荐选择 Visual Studio Code，Sublime Text 4 等正经的代码编辑器  

-- [3]
-- anim/ 文件夹下的部分动画资源可能会被加密
-- 如果你引用了本mod的动画资源，你应在显著位置标明:
--     ```该 武器/道具/功能 的实现使用了饥荒联机版mod：晓美焰（https://steamcommunity.com/sharedfiles/filedetails/?id=1837053004）中的动画资源。```

-- 标注应同时出现在以下场景:
--   - mod源代码中，加载晓美焰mod动画资源（Assets）处
--   - mod介绍（包括创意工坊页面、更新动态、演示视频等）中，涉及晓美焰mod动画资源的部分

GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

GLOBAL.HOMURA_GLOBALS = 
{
    PLAYERDMG = GetModConfigData("playerdmg") or TheNet:GetPVPEnabled(),
}

-- 2021.12.1 new options to ban time magic
--[[是否禁用时停]] BANTIMEMAGIC = GetModConfigData("bantimemagic") or false 
--[[是否使用魔法弓]] USEBOW = BANTIMEMAGIC                         
HOMURA_GLOBALS.BANTIMEMAGIC = BANTIMEMAGIC
HOMURA_GLOBALS.USEBOW = USEBOW

Assets =
{
    Asset("ATLAS", "images/hud/homuraUI_mover.xml"),

    Asset("ANIM", "anim/puellaUI_flash.zip"),
    Asset("ANIM", "anim/puellaUI_homurafocus.zip"),

    Asset("ANIM", "anim/lw_player_pistol.zip"),
    Asset("ANIM", "anim/homura_gun_fire.zip"),
    Asset("ANIM", "anim/homura_gun_anim2.zip"),
    Asset("ANIM", "anim/player_homura_rush.zip"),

    Asset("ANIM", "anim/homura_buff_base.zip"),
    Asset("ATLAS", "images/homura_weapon_buff.xml"),
    Asset('ATLAS_BUILD',"images/homura_weapon_buff.xml", 64),

    Asset("SOUNDPACKAGE", "sound/lw_homura.fev"),
    Asset("SOUND", "sound/lw_homura.fsb"),

    -- skin
    Asset("ANIM", 'anim/homura_0.zip'),
    Asset("ANIM" ,'anim/homuraUI_skinbg.zip'),
}

PrefabFiles = {
    "homura_rpg",
    'homura_workdesk',
    'homura_clock',
    'homura_bombs',
    'homura_pistol',
    "homura_water",
    'homura_stickbang',
    'homura_stickbang_smoke',
    "homura_books",
    'homura_weapon_buffs',

    'homura_fake_target',

    -- "homura_bug"
}

AddMinimapAtlas("images/map_icons/homura_workdesk_1.xml")
AddMinimapAtlas("images/map_icons/homura_workdesk_2.xml")
AddMinimapAtlas("images/map_icons/homura_box.xml")

modimport "modmain/tuning.lua"      -- 数值设定 (角色三维/时停冷却/武器伤害) √
modimport "modmain/language.lua"    -- 语言设定 √
modimport "modmain/character.lua"   -- 注册角色 √
modimport "modmain/rpc.lua"         -- 客户端通讯 -
modimport "modmain/newtech.lua"     -- 科技 √
modimport "modmain/constants.lua"   -- 新的常量 √
modimport "modmain/recipes.lua"     -- 新配方 √
modimport "modmain/API.lua"         -- 钩子 -
modimport "modmain/timemagic.lua"   -- 时停 -
modimport "modmain/net.lua"         -- 网络变量 √
modimport "modmain/ui.lua"          -- 技能按钮
modimport "modmain/key.lua"         -- 技能快捷键 √
modimport "modmain/actions.lua"     -- 新动作
modimport "modmain/SGmain.lua"      -- 修改人物sg, 添加各种新的攻击类型 
modimport "modmain/container.lua"   -- 新容器 √
modimport "modmain/detonator.lua"   -- 雷管 √
modimport "modmain/gunpowder.lua"   -- 分支合成 √ ****
modimport "modmain/sgrecorder.lua"  -- 保证在时停期间不进入新sg
modimport 'modmain/skins.lua'       -- 眼镜焰皮肤 
modimport "modmain/postprocess.lua" -- 后处理 √
modimport "modmain/snowpea.lua"     -- 寒冰射手减速debuff 
modimport "modmain/bow.lua"         -- 弓箭
modimport "modmain/tower.lua"       -- 支援信标

modimport "modmain/strings.lua" 

-- debug modules
if modname == "homura-12.8" then
    modimport "modmain/debugfunctions.lua"
    modimport "modmain/debug.lua"
end
