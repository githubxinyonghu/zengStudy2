local L = locale ~= "zh" and locale ~= "zhr" -- true 英文  false 中文

version = "1.2.16" 
name = L and "Homura Akemi" or "晓美焰"
description = 
L and[[
1) Magical bow recipe is now invisible in common mode.
]]
or
[[
2023.1.24 补丁
* 修复供奉兔人神龛导致的游戏崩溃。
* 修复激活支援信标导致的游戏崩溃

b站搜索“老王天天写bug”，获取更多更新资讯。

mod介绍页:
https://dont-starve-mod.github.io/zh/homura_index/

先勾选mod，再点击右下角第三个按钮↘（小地球），可查阅详细介绍。
]]

author = "老王天天写bug"
forumthread = ""
api_version = 10

priority = -2029316030 - 209631439

dont_starve_compatible = false
dst_compatible = true

all_clients_require_mod = true

server_filter_tags = { 
    "character",
}

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

local ON = {description = L and "On" or "开", data = true}
local OFF = {description = L and "Off" or "关", data = false}
local SWITCH = function() return {ON, OFF} end
local ALPHA = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
local function keyslist(default)
    local list = {
        OFF,
        {description = default, data = default.."-default"},
    }
    for i = 1, #ALPHA do
        list[#list + 1] = {description = ALPHA[i], data = ALPHA[i]}
    end
    return list
end

-- local keyslist = {}
-- for i = 1,#ALPHA do keyslist[i] = {description = ALPHA[i], data = i + 64} end
local NUM_HEADER = 0
local HEADER = function(name)
    NUM_HEADER = NUM_HEADER + 1
    return {
        name = "h1."..NUM_HEADER,
        label = name,
        options = {
            {description="", data = true}
        },
        default = true,
    }
end

configuration_options =
{
    HEADER(L and "Basic" or "基础"),

    {
        name = "language",
        label = L and "Language" or "语言",
        hover = L and "Set language" or "设置语言",
        options =  {
            {description = L and "Auto" or "自动", data = "AUTO"},
            {description = "English", data = "ENG"},
            {description = "中文", data = "CHI"}, 
        },
        default = "AUTO",
    },

    {
        name = 'playerdmg',
        label = L and 'Fratricide' or '友伤',
        hover = L and 'AOE weapons can hurt your teammate' or '范围效果的武器能否伤害队友',
        options = SWITCH(),
        default = true,
    },

    {
        name = "bantimemagic",
        label = L and "The remade world" or "重塑后的世界",
        hover = L and "Homura carries a magical bow, but cannot stop time." or "晓美焰无法发动时间停止，但可以使用魔法弓",
        options = SWITCH(),
        default = false,
    },

    {
        name = "blast",
        label = L and "Time magic effect" or "时停特效",
        hover = L and "Special effect when time magic is activated" or "时停技能被发动时的特效表现",
        options = {
            {description = L and "Grey & Blast" or "灰色 + 冲击波", data = true},
            {description = L and "Grey" or "仅灰色", data = false},
        },
        default = true,
    },

    HEADER(L and "Key settings" or "按键"),

    {
        name = "skillkey_v2",
        label = L and "Skill key" or "技能键",
        hover = L and "Set hot key for skill" or "设置时停技能的键位",
        options = keyslist("L"),
        default = "L-default",
    },

    {
        name = "reloadkey_v2",
        label = L and "Reload key" or "填弹键",
        hover = L and "Set hot key for reload ammo" or "设置自动换弹的键位",
        options = keyslist("R"),
        default = "R-default",
    },
}
