-- Recipe2 = Class(Recipe, function(self, name, ingredients, tech, config)

table.insert(Assets, Asset("ATLAS", "images/hud/homura_filter_buff.xml"))
AddRecipeFilter({ name = "HOMURA_BUFF", atlas = "images/hud/homura_filter_buff.xml", image = "homura_filter_buff.tex"})
STRINGS.UI.CRAFTING_FILTERS.HOMURA_BUFF = Loc("Fitting", "配件")

table.insert(Assets, Asset("ATLAS", "images/hud/homura_prototyper.xml"))

local prototyper_name = Loc("Thermal Weapons", "热武器")
AddPrototyperDef("homura_workdesk_1", {icon_atlas = "images/hud/homura_prototyper.xml", icon_image = "homura_prototyper.tex", is_crafting_station = true, filter_text = prototyper_name})
AddPrototyperDef("homura_workdesk_2", {icon_atlas = "images/hud/homura_prototyper.xml", icon_image = "homura_prototyper.tex", is_crafting_station = true, filter_text = prototyper_name})

local Ig = Ingredient
local TECHLEVEL = {[1] = TECH.HOMURA_TECH_ONE, [2] = TECH.HOMURA_TECH_THREE, [99] = TECH.LOST}
STRINGS.UI.CRAFTING_FILTERS.HOMURA_MUNITION = Loc("Munition", "军火")
STRINGS.UI.CRAFTING_STATION_FILTERS.HOMURA_WORKDESK = Loc("Thermal weapon workbench", "热武器工作台")

local function config(name, opts)
    local data = {
        atlas = "images/inventoryimages/"..name..".xml",
        image = name..".tex",
    }
    if opts then
        for k,v in pairs(opts)do
            data[k] = v
        end
    end
    return data
end

-- 怀表
AddRecipe2("homura_clock", {Ig("goldnugget", 1), Ig("gears", 1)}, TECH.NONE, config("homura_clock"))
AddRecipeToFilter("homura_clock", "MAGIC")

-- 魔法弓
if USEBOW then -- 2022.8.10 只在开启魔法弓时显示这个配方
AddRecipe2("homura_bow", {Ig("twigs", 2), Ig("silk", 2), Ig("purplegem", 1)}, TECH.NONE, config("homura_bow", {builder_tag = "homura_bowmaker"}))
AddRecipeToFilter("homura_bow", "MAGIC")
AddRecipeToFilter("homura_bow", "WEAPONS")
AddRecipeToFilter("homura_bow", CRAFTING_FILTERS.CHARACTER.name)
end

-- 基础工作台
AddRecipe2("homura_workdesk_1", {Ig("gunpowder", 1), Ig("papyrus", 2), Ig("log", 4)}, TECH.SCIENCE_ONE, config("homura_workdesk_1", {builder_tag = "homuraTag_workdesk_builder", placer = "homura_workdesk_1_placer"}))
AddRecipeToFilter("homura_workdesk_1", "PROTOTYPERS")
AddRecipeToFilter("homura_workdesk_1", "STRUCTURES")
-- >> HOMURA_MUNITION

-- 高级工作台
AddRecipe2("homura_workdesk_2", {Ig("gunpowder", 10), Ig("homura_wrench", 1, "images/inventoryimages/homura_wrench.xml"), Ig("transistor", 6)}, TECH.HOMURA_TECH_ONE, config("homura_workdesk_2", {builder_tag = "homuraTag_workdesk_builder", placer = "homura_workdesk_2_placer"}))
AddRecipeToFilter("homura_workdesk_2", "PROTOTYPERS")
AddRecipeToFilter("homura_workdesk_2", "STRUCTURES")
-- >> HOMURA_MUNITION

-- 支援信标 Lv1~Lv3
AddRecipe2("homura_tower_1", {Ig("boneshard", 8), Ig("transistor", 10), Ig("livinglog", 6)}, TECH.SCIENCE_TWO, config("homura_tower_1", {builder_tag = "homuraTag_level1_builder", min_spacing = 2.5, placer = "homura_tower_1_placer"}))
AddRecipeToFilter("homura_tower_1", "STRUCTURES")
-- >> HOMURA_MUNITION

AddRecipe2("homura_tower_2", {Ig("thulecite", 8), Ig("goldenpickaxe", 2), Ig("nightmarefuel", 32)}, TECH.LOST, config("homura_tower_2", {builder_tag = nil, min_spacing = 2.5, placer = "homura_tower_2_placer"}))
AddRecipeToFilter("homura_tower_2", "STRUCTURES")
-- >> HOMURA_MUNITION

AddRecipe2("homura_tower_3", {Ig("moonglass", 60), Ig("yellowgem", 3), Ig("lightninggoathorn", 6)}, TECH.LOST, config("homura_tower_3", {builder_tag = nil, min_spacing = 2.5, placer = "homura_tower_3_placer"}))
AddRecipeToFilter("homura_tower_3", "STRUCTURES")
-- >> HOMURA_MUNITION

-- trick
AddSimPostInit(function()
    AllRecipes["homura_tower_2"].builder_tag = "homuraTag_level1_builder"
    AllRecipes["homura_tower_3"].builder_tag = "homuraTag_level1_builder"
end)

-- 以下统统加入军火

-- 扳手
AddRecipe2("homura_wrench", {Ig("moonrocknugget", 8), Ig("nightmarefuel",4)}, TECHLEVEL[1], config("homura_wrench", {builder_tag = "homuraTag_workdesk_builder"}))

-- 操作手册
AddRecipe2("homura_book_1", {Ig("papyrus", 2), Ig("featherpencil", 1)}, TECHLEVEL[1], config("homura_book_1", {builder_tag = "homuraTag_workdesk_builder"}))
AddRecipe2("homura_book_2", {Ig("papyrus", 6), Ig("featherpencil", 1)}, TECHLEVEL[2], config("homura_book_2", {builder_tag = "homuraTag_workdesk_builder"}))
-- AddRecipeToFilter("homura_book_1", "HOMURA_MUNITION") -->>
-- AddRecipeToFilter("homura_book_2", "HOMURA_MUNITION")

-- 2021.6.1
-- AddRecipe("homura_gunpowder_recipetab", {Ig("gunpowder", 4), Ig("powcake", 10), Ig("guano", 1)}, HOMURA_TAB, TECH.HOMURA_TECH_ONE,
--     nil, nil, true, nil, "homuraTag_level1_builder",
--     "images/inventoryimages/homura_gunpowder.xml",
--     "homura_gunpowder.tex")
-- AddRecipe("homura_gunpowder_1", {Ig("gunpowder", 4), Ig("guano", 1)}, NIL_TAB, TECH.LOST, nil, nil, true, 4).product = "homura_gunpowder"
-- AddRecipe("homura_gunpowder_2", {Ig("powcake", 10),  Ig("guano", 1)}, NIL_TAB, TECH.LOST, nil, nil, true, 4).product = "homura_gunpowder"

--@-- 测试下能不能用》
-- local branch1 = AddDeconstructRecipe("homura_gunpowder_1", {Ig("gunpowder", 4), Ig("guano", 1)})
-- branch1.numtogive = 4
-- branch1.product = "homura_gunpowder"
-- local branch2 = AddDeconstructRecipe("homura_gunpowder_2", {Ig("powcake", 10), Ig("guano", 1)})
-- branch2.numtogive = 4
-- branch2.product = "homura_gunpowder"

-- AddRecipe('homura_detonator_fake',{Ig('gunpowder',1),Ig('powcake',2),Ig('goldnugget',1)}, HOMURA_TAB, TECH.HOMURA_TECH_ONE,nil,nil,true,nil,'homura',
--     'images/inventoryimages/homura_detonator.xml',
--     'homura_detonator.tex')
-- AddRecipe('homura_detonator1',{Ig('gunpowder',1),Ig('goldnugget',1)},NIL_TAB, TECH.LOST,nil,nil,true,4,nil,nil,nil,nil,'homura_detonator')
-- AddRecipe('homura_detonator2',{Ig('powcake',2),Ig('goldnugget',1)},NIL_TAB, TECH.LOST,nil,nil,true,4,nil,nil,nil,nil,'homura_detonator')

-- 军火 (枪/投掷物/弹药/火箭筒)
local function AddHomuraMunition(prefab, ingredients, level, opts)
    local data = config(prefab, opts)
    if level < 10 then
        data.builder_tag = "homuraTag_level"..level.."_builder"
    end
    data.nounlock = true

    AddRecipe2(prefab, ingredients, TECHLEVEL[level], data)

    if prefab ~= "homura_gunpowder" then
        AddRecipeToFilter(prefab, "WEAPONS")
    end
    -- AddRecipeToFilter(prefab, "HOMURA_MUNITION") -->>
end

local GUNPOWDER = function(i) return Ig("gunpowder", i or 1) end
local DETONATOR = function(i) return Ig("homura_detonator", i or 1, "images/inventoryimages/homura_detonator.xml") end
local AMMO1 = function(i)   return Ig("homura_gun_ammo1", i or 1, "images/inventoryimages/homura_gun_ammo1.xml") end
local BUFF = function(name) return Ig("homura_weapon_buff_"..name, 1, "images/homura_weapon_buff.xml") end

AddHomuraMunition("homura_gunpowder",   {Ig("powcake", 3)}, 1, {product = "gunpowder", atlas = GetInventoryItemAtlas("gunpowder.tex"), image = "gunpowder.tex"})

AddHomuraMunition("homura_detonator",   {Ig("gunpowder", 1), Ig("goldnugget", 1)}, 1, {numtogive = 4})
AddHomuraMunition("homura_bomb_bomb",   {DETONATOR(1), Ig("flint",2)}, 1)
AddHomuraMunition("homura_bomb_fire",   {DETONATOR(1), Ig("charcoal",2)}, 1)
AddHomuraMunition("homura_bomb_flash",  {DETONATOR(1), Ig("nitre",1)}, 1)
AddHomuraMunition("homura_stickbang",   {DETONATOR(1), Ig("twigs",1), Ig("stinger",1)}, 99)

AddHomuraMunition("homura_pistol",      {Ig("blowdart_pipe",1), AMMO1(7)}, 1)
AddHomuraMunition("homura_gun",         {Ig("blowdart_pipe",1), Ig("walrus_tusk",1), AMMO1(20)}, 1)
AddHomuraMunition("homura_hmg",         {Ig("blowdart_pipe",1), Ig("gears",2), AMMO1(80)}, 1)
AddHomuraMunition("homura_rifle",       {Ig("blowdart_pipe",1), BUFF("eye_lens"),AMMO1(5)}, 2)
AddHomuraMunition("homura_gun_ammo1",   {Ig("gunpowder", 1), Ig("goldnugget", 1)}, 1, {numtogive = 40})

AddHomuraMunition("homura_snowpea",     {Ig("oceanfish_medium_8_inv", 1), Ig("ice", 7), Ig("bluegem", 5)}, 99)
AddHomuraMunition("homura_tr_gun",      {Ig("eyemaskhat", 1), Ig("bonestew", 4)}, 99)
AddHomuraMunition("homura_watergun",    {Ig("premiumwateringcan", 1), Ig("homura_gun", 1, "images/inventoryimages/homura_gun.xml"), Ig("rope", 5)}, 99)

AddHomuraMunition("homura_rpg",         {Ig("blowdart_fire", 1), Ig("dragon_scales", 1), Ig("homura_rpg_ammo1", 1, "images/inventoryimages/homura_rpg_ammo1.xml")}, 2)
AddHomuraMunition("homura_rpg_ammo1",   {DETONATOR(5), Ig("charcoal",5), Ig("durian",1)}, 2, {numtogive = 5})

-- 配件
local function AddHomuraBuff(prefab, ingredients, level)
    local prefab = "homura_weapon_buff_"..prefab
    AddRecipe2(prefab, ingredients, TECHLEVEL[level], {
        builder_tag = "homuraTag_level"..level.."_BUILDER",
        atlas = "images/homura_weapon_buff.xml",
        image = prefab..".tex",
        nounlock = true,
    })
    AddRecipeToFilter(prefab, "HOMURA_BUFF")
end

table.foreach(
{
    lens    =   {Ig('log',1),Ig('berries_cooked',1),Ig('bluegem',1)},
    knife   =   {Ig('flint',10)},
    silent  =   {Ig('heatrock',1),Ig('charcoal',2)},
    flyingspeed = {Ig('trinket_6',6),Ig('redgem',1),Ig('bluegem',1)},
    ice     =   {Ig('icehat',1),Ig('bluegem',3),Ig('gears',1)},
    waterproof  = {Ig('beeswax',1),Ig('pigskin',2)},
},
function(k,v) AddHomuraBuff(k, v, 1) end)

table.foreach(
{
    code    =   {Ig('beardhair',16)}, 
    magic   =   {Ig('purplegem',4),Ig('nightmarefuel',6)},
    wind    =   {Ig('feather_crow',6),Ig('feather_robin',6),Ig('feather_robin_winter',6)},
    mouse   =   {Ig('cutreeds',29),BUFF("code"),Ig('goldnugget',1)},
    homing  =   {BUFF("eye_lens"),Ig('boards',10),},
    eye_lens=   {Ig('deerclops_eyeball',1),Ig('goldnugget',4),BUFF("lens")},
    clip    =   {Ig('nightmarefuel',40),Ig('boards',2)},
    time    =   {Ig('townportaltalisman',1), Ig('purplegem',1)},
    wormhole=   {Ig("monstermeat",4), Ig("purplegem", 3), Ig("houndstooth", 5)},
    laser   =   {Ig('moonglass', 10)},
},
function(k,v) AddHomuraBuff(k, v, 2) end)

-- for airdrop box
for i = 1, 3 do
    AddDeconstructRecipe("homura_box_"..i, {Ig("boards", 1)})
end

do return end

-- 饥荒角色专属道具
local function AddCrossoverRecipe(character, ...)
    local recipe = AddRecipe2(...)
    assert(recipe.builder_tag == nil)
    -- 该物品只能由 STRINGS.CHARACTER_TITLES[prefab] 制作
    recipe.builder_tag = "homura_crossover_builder_"..character

    AddRecipeToFilter(recipe.name, CRAFTING_FILTERS.CHARACTER.name)
    return recipe
end

AddCrossoverRecipe("wanda", "homura_timebomb",{

}, TECH.NONE, {}, {--[["HOMURA_MUNITION"]]})

if modname:find("homura") then
    AddPlayerPostInit(function(inst)
        if inst.prefab ~= nil then
            inst:AddTag("homura_crossover_builder_"..inst.prefab)
        end
    end)
end

-- DST_CHARACTERLIST =
-- {
--     "wilson",
--     "willow",
--     "wolfgang",
--     "wendy",
--     "wx78",
--     "wickerbottom",
--     "woodie",
--     "wes",
--     "waxwell",
--     "wathgrithr",
--     "webber",
--     "winona",
--     "warly",
--     "wortox",
--     "wormwood",
--     "wurt",
--     "walter",
--     "wanda",
--     "wonkey", --hidden internal char
-- }
