local name = "homura_1"
table.insert(PrefabFiles, name)

-- skin
table.insert(Assets, Asset( "ATLAS", "bigportraits/homura_1_moe.xml" ))
table.insert(Assets, Asset( "ATLAS", "bigportraits/homura_1_none.xml" ))
-- common
table.insert(Assets,Asset( "ATLAS", "images/saveslot_portraits/"..name..".xml" ))
table.insert(Assets,Asset( "ATLAS", "images/selectscreen_portraits/"..name..".xml" ))
table.insert(Assets,Asset( "ATLAS", "images/map_icons/"..name..".xml"))
table.insert(Assets,Asset( "ATLAS", "images/avatars/avatar_"..name..".xml"))
table.insert(Assets,Asset( "ATLAS", "images/avatars/avatar_ghost_"..name..".xml"))
table.insert(Assets,Asset( "ATLAS", "images/avatars/self_inspect_"..name..".xml"))
table.insert(Assets,Asset( "ATLAS", "images/names_"..name..".xml"))
table.insert(Assets,Asset( "ATLAS", "bigportraits/"..name.."_none.xml"))
table.insert(Assets,Asset( "ANIM" , "anim/"..name..".zip"))
table.insert(Assets,Asset( "ANIM" , "anim/ghost_"..name.."_build.zip"))
table.insert(CHARACTER_GENDERS.FEMALE, name)

-- 感谢bowcar提供的台词文件
STRINGS.CHARACTERS[string.upper(name)] = L and deepcopy(require 'speech_wilson') or require 'speech_homura_ch'
env.SPEECH_HOMURA = STRINGS.CHARACTERS[string.upper(name)]
env.SPEECH_GENERIC = STRINGS.CHARACTERS.GENERIC

AddMinimapAtlas("images/map_icons/"..name ..".xml")
AddModCharacter(name)

STRINGS.CHARACTER_TITLES[name] = L and "Mysterious transfer student" or "神秘的转校生"
STRINGS.CHARACTER_NAMES[name] = L and "Homura Akemi" or "晓美焰"
STRINGS.NAMES[string.upper(name)] = STRINGS.CHARACTER_NAMES[name]
STRINGS.CHARACTER_DESCRIPTIONS[name] = L and "*Masters making munitions.\n*Can control time." or "*制造和使用热兵器。\n*掌握控制时间的魔法。"
STRINGS.CHARACTER_QUOTES[name] = L and "\"No one believe the future, no one accept the truth about future...\"" or "\"谁都, 不会相信未来, 谁都, 无法接受未来, 那样的话，我就...\""

if BANTIMEMAGIC then
    STRINGS.CHARACTER_DESCRIPTIONS[name] = L and "*Masters making munitions.\n*Use a magical bow.\n*Cannot control time in this remade world." or "*制造和使用热兵器。\n*拥有一把魔法弓。\n*在重塑后的世界已无法控制时间。"
    STRINGS.CHARACTER_QUOTES[name] = L and "\"I will carry on her will and fight on.\"" or "\"我会继承她的意志，继续战斗下去。\""
    STRINGS.CHARACTERS[string.upper(name)].ANNOUNCE_INV_FULL = L and "I used to throw these things in the time shield." or "以前总把东西扔时之盾里，现在有点不习惯"
end

-- [qol]
-- STRINGS.CHARACTER_BIOS[name] = {
--     L and { title = "Birthday", desc = "February 22 (roughly)" } or { title = "生日", desc = "2月22日（大概）" },
--     L and { title = "Favorite Food", desc = "?"} or { title = "最喜欢的食物", desc = "?" },
--     { title = "Time", desc = "" },
-- }

if AddLoadingTip == nil then
    return
end

-- AddLoadingTip(<string_table>, <tip_id>, <tip_string>, <controltipdata>)

-- <string_table> can be one of the following:
-- LOADING_SCREEN_SURVIVAL_TIPS
-- LOADING_SCREEN_LORE_TIPS
-- LOADING_SCREEN_CONTROL_TIPS
-- LOADING_SCREEN_CONTROL_TIPS_CONSOLE
-- LOADING_SCREEN_CONTROL_TIPS_NOT_CONSOLE
-- STRINGS.UI.LOADING_SCREEN_OTHER_TIPS (It is recommended to use this table as it is reserved for custom loading tips.)
-- <tip_id> must be a unique ID name.
-- <tip_string> is the actual tip string to be displayed.
-- <controltipdata> is a table containing input control bindings to be used in the tip string. Refer to LOADING_SCREEN_CONTROL_TIP_KEYS in constants.lua and LOADING_SCREEN_CONTROL_TIPS in strings.lua for an example usage.
do return end

local LORES = STRINGS.UI.LOADING_SCREEN_LORE_TIPS

AddLoadingTip(LORES, "HOMURATIP_WX78", 
    "众人围着篝火闲聊时，晓美焰抱怨道：\"在见泷原，我的时间魔法很管用；可在这里，我只能控制一小片区域的时间。这是永恒领域的暗影魔法影响吗？\"\n"..
    "\"这是为了节约CPU算力\"WX-78缓缓说道。\n".. 
    "（没人能听懂它在讲什么）")

AddLoadingTip(LORES, "HOMURATIP_WANDA",
    "晓美焰对旺达女士那些能操纵时间的钟表很感兴趣，于是借了块溯源表，仔细拆解分析。\n"..
    "尽管最终没明白具体原理，但她还是成功把表给组装回去了，零件不多不少。")

AddLoadingTip(LORES, "HOMURATIP_WALTER",
    "沃尔特很快上手了晓美焰的魔法弓，并给出了五星好评：\"和我的弹弓很像，但不用随身携带弹药，真方便！\"")

AddLoadingTip(LORES, "HOMURATIP_WILLOW",
    "薇洛非常喜欢晓美焰的燃烧瓶，她很享受瞬间引起一片大火的感觉。")

AddLoadingTip(LORES, "")
local TIPS = STRINGS.UI.LOADING_SCREEN_OTHER_TIPS
