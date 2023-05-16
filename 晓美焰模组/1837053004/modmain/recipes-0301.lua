-- Recipe = Class(function(self, name, ingredients, tab, level, placer_or_more_data, min_spacing, nounlock, numtogive, builder_tag, atlas, image, testfn, product, build_mode, build_distance) -- do not add more params here, add them to "placer_or_more_data"

local Ig = Ingredient
local TECHLEVEL = {[1] = TECH.HOMURA_TECH_ONE, [2] = TECH.HOMURA_TECH_THREE, [99] = TECH.LOST}
STRINGS.HOMURA_TAB = Loc("Munition", "军火")
STRINGS.HOMURA_UPTOWER = Loc("Upgrade Beacon", "升级信标")

table.insert(Assets, Asset("ATLAS", "images/hud/homura_tab.xml" ))
table.insert(Assets, Asset("ATLAS", "images/hud/homura_uptower.xml"))

-- 怀表 [全员]
AddRecipe("homura_clock", {Ig("goldnugget",1), Ig("gears",1)}, RECIPETABS.MAGIC, TECH.NONE, nil, nil, nil, nil, nil, "images/inventoryimages/homura_clock.xml", "homura_clock.tex")

-- 魔法弓 [晓美焰sp]
AddRecipe("homura_bow", {Ig("twigs", 2), Ig("silk", 2), Ig("purplegem", 1)}, RECIPETABS.MAGIC, TECH.NONE, nil, nil, nil, nil, "homura_bowmaker", "images/inventoryimages/homura_bow.xml", "homura_bow.tex")

local HOMURA_TAB = AddRecipeTab( STRINGS.HOMURA_TAB, 100, "images/hud/homura_tab.xml", "homura_tab.tex", nil, true)
HOMURA_TAB.is_homura = true

local HOMURA_UPTOWER = AddRecipeTab(STRINGS.HOMURA_UPTOWER, 100, "images/hud/homura_uptower.xml", "homura_uptower.tex", nil, true)
HOMURA_UPTOWER.is_homura = true

local NIL_TAB = AddRecipeTab("ERROR", -1, "images/hud/homura_tab.xml", "homura_tab.tex", "homura_a_long_and_invalid_tag") -- 任何人都不应该拥有这个制造栏位

-- 基础工作台 [homura]
AddRecipe("homura_workdesk_1", {Ig("gunpowder",1), Ig("papyrus",2), Ig("log",4)}, HOMURA_TAB, TECH.SCIENCE_ONE,
    "homura_workdesk_1_placer", 2.5, nil, nil, "homuraTag_workdesk_builder",
    "images/inventoryimages/homura_workdesk_1.xml", 
    "homura_workdesk_1.tex")

-- 高级工作台 [homura]
AddRecipe("homura_workdesk_2", {Ig("gunpowder",10), Ig("homura_wrench",1, "images/inventoryimages/homura_wrench.xml"), Ig("transistor",6)}, HOMURA_TAB, TECH.HOMURA_TECH_ONE,
    "homura_workdesk_2_placer", 2.5, nil, nil, "homuraTag_workdesk_builder",
    "images/inventoryimages/homura_workdesk_2.xml",
    "homura_workdesk_2.tex")

-- 全息工作台
-- AddRecipe("homura_workdesk_portable", {}, HOMURA_TAB, TECHLEVEL[2],
--     "homura_workdesk_portable_placer", 2.5, nil, nil, "homuraTag_workdesk_builder",
--     "images/inventoryimages/homura_workdesk.xml",
--     "homura_workdesk.tex")

-- 支援信标
AddRecipe("homura_tower_1", {Ig("boneshard", 8), Ig("transistor", 10), Ig("livinglog", 6)}, HOMURA_TAB, TECH.SCIENCE_TWO,
    "homura_tower_1_placer", 2.5, nil, nil, "homuraTag_workdesk_builder",
    "images/inventoryimages/homura_tower_1.xml",
    "homura_tower_1.tex")
-- 2
AddRecipe("homura_tower_2_upgrade", {Ig("thulecite", 8), Ig("goldenpickaxe", 1), Ig("nightmarefuel", 32)}, HOMURA_UPTOWER, TECH.LOST,
    nil, nil, true, nil, "homuraTag_workdesk_builder",
    "images/inventoryimages1.xml", "hammer_mjolnir.tex")

-- 3
AddRecipe("homura_tower_3_upgrade", {Ig("moonglass", 60), Ig("yellowgem", 3), Ig("lightninggoathorn", 6)}, HOMURA_UPTOWER, TECH.LOST,
    nil, nil, true, nil, "homuraTag_workdesk_builder",
    "images/inventoryimages1.xml", "hammer_hammush.tex")

-- AddComponentPostInit("builder", function(self)
--     self.inst:ListenForEvent("techtreechange", function()
--         if self.current_prototyper ~= nil and self.current_prototyper:HasTag("homura_prototyper") then
--             if self.inst.player_classified then
--                 self.inst.player_classified.homura_prototyper_level:set(self.current_prototyper.level)
--             end
--         end
--     end)
-- end)

-- AddClassPostConstruct("components/builder_replica", function(self)
--     function self:Homura_GetWorkdeskLevel()
--         if self.inst.components.builder then
--             return self.inst.components.builder.homura_prototyper_level or 0
--         elseif self.classified then
--             return self.classified.homura_prototyper_level:value()
--         else
--             return 0
--         end
--     end

--     local old_canlearn = self.CanLearn
--     function self:CanLearn(recipename, ...)
--         if type(recipename) == "string" then
--             local _, _, i = string.find(recipename, "homura_book_(%d)")
--             if i ~= nil then
--                 return i == self:Homura_GetWorkdeskLevel()
--             end
--         end
--         return old_canlearn(self, recipename, ...)
--     end
-- end)

local function AddModRecipe(prefab, ingredients, level, num, ...)
    level = level or 1
    local tag = level == 99 and "homuraTag_level1_builder" or ("homuraTag_level"..level.."_BUILDER")

    return AddRecipe(prefab, ingredients, HOMURA_TAB, TECHLEVEL[level], nil, nil, true, num, tag,
    "images/inventoryimages/"..prefab..".xml",
    prefab..".tex", ...)
end

-- 扳手 [homura]
AddModRecipe("homura_wrench", {Ig("moonrocknugget", 8), Ig("nightmarefuel",4)}, 1).builder_tag = "homuraTag_workdesk_builder"

-- 操作手册 [homura]
AddModRecipe("homura_book_1", {Ig("papyrus", 2), Ig("featherpencil", 1)}, 1).builder_tag = "homuraTag_workdesk_builder"
AddModRecipe("homura_book_2", {Ig("papyrus", 6), Ig("featherpencil", 1)}, 2).builder_tag = "homuraTag_workdesk_builder"
-- book_3

local function AddHomuraBuff(buff, ingredients, level)
    level = level or 1
    local prefab = 'homura_weapon_buff_'..buff
    return AddRecipe(prefab, ingredients, HOMURA_TAB, TECHLEVEL[level], nil, nil, true, nil, "homuraTag_level"..level.."_BUILDER",
    "images/homura_weapon_buff.xml",
    prefab..".tex")
end

-- 2021.6.1
AddRecipe("homura_gunpowder_recipetab", {Ig("gunpowder", 4), Ig("powcake", 10), Ig("guano", 1)}, HOMURA_TAB, TECH.HOMURA_TECH_ONE,
    nil, nil, true, nil, "homuraTag_level1_builder",
    "images/inventoryimages/homura_gunpowder.xml",
    "homura_gunpowder.tex")
AddRecipe("homura_gunpowder_1", {Ig("gunpowder", 4), Ig("guano", 1)}, NIL_TAB, TECH.LOST, nil, nil, true, 4).product = "homura_gunpowder"
AddRecipe("homura_gunpowder_2", {Ig("powcake", 10),  Ig("guano", 1)}, NIL_TAB, TECH.LOST, nil, nil, true, 4).product = "homura_gunpowder"

-- AddRecipe('homura_detonator_fake',{Ig('gunpowder',1),Ig('powcake',2),Ig('goldnugget',1)}, HOMURA_TAB, TECH.HOMURA_TECH_ONE,nil,nil,true,nil,'homura',
--     'images/inventoryimages/homura_detonator.xml',
--     'homura_detonator.tex')
-- AddRecipe('homura_detonator1',{Ig('gunpowder',1),Ig('goldnugget',1)},NIL_TAB, TECH.LOST,nil,nil,true,4,nil,nil,nil,nil,'homura_detonator')
-- AddRecipe('homura_detonator2',{Ig('powcake',2),Ig('goldnugget',1)},NIL_TAB, TECH.LOST,nil,nil,true,4,nil,nil,nil,nil,'homura_detonator')

local GUNPOWDER = function() return Ig('homura_gunpowder',1,'images/inventoryimages/homura_gunpowder.xml') end
local DETONATOR = function(i) return Ig('homura_detonator',i or 1,'images/inventoryimages/homura_detonator.xml') end
AddModRecipe('homura_detonator', {GUNPOWDER(), Ig("goldnugget", 1)}, 1, 5) 
AddModRecipe('homura_bomb_bomb', {DETONATOR(), Ig('flint',4)})
AddModRecipe('homura_bomb_fire', {DETONATOR(), Ig('charcoal',3)})
AddModRecipe('homura_bomb_flash',{DETONATOR(), Ig('nitre',1)})
AddModRecipe("homura_stickbang", {DETONATOR(), Ig("twigs",1), Ig("stinger",1)}, 99)

AddModRecipe('homura_rpg',{Ig('blowdart_fire',1), Ig('dragon_scales',1),Ig('homura_rpg_ammo1',1,'images/inventoryimages/homura_rpg_ammo1.xml')},2)
AddModRecipe('homura_rpg_ammo1',{DETONATOR(5), Ig('log',2),Ig('durian',1)},2, 5)

local AMMO1 = function(num) return Ig('homura_gun_ammo1',num,'images/inventoryimages/homura_gun_ammo1.xml') end
local BUFF = function(name) return Ig("homura_weapon_buff_"..name, 1, "images/homura_weapon_buff.xml") end

AddModRecipe('homura_pistol',   {Ig('blowdart_pipe',1),AMMO1(7)},1)
AddModRecipe('homura_gun',      {Ig('blowdart_pipe',1),Ig('walrus_tusk',1), AMMO1(20)},1)
AddModRecipe('homura_hmg',      {Ig('blowdart_pipe',1),Ig('gears',2), AMMO1(80)},1)
AddModRecipe("homura_rifle",    {Ig("blowdart_pipe",1),BUFF("eye_lens"),AMMO1(5)}, 2)

AddModRecipe("homura_snowpea", {Ig("oceanfish_medium_8_inv", 1), Ig("ice", 7), Ig("bluegem", 5)}, 99)
AddModRecipe("homura_tr_gun", {Ig("eyemaskhat", 1), Ig("bonestew", 4)}, 99)
AddModRecipe("homura_watergun", {Ig("premiumwateringcan", 1), Ig("homura_gun", 1, "images/inventoryimages/homura_gun.xml"), Ig("rope", 5)}, 99)
AddModRecipe("homura_gun_ammo1", {GUNPOWDER(), Ig("goldnugget", 1)}, 1, 40)

-- AddModRecipe('homura_gun_ammo1',{Ig('gunpowder',1),Ig('goldnugget',2)},1,20)
-- AddModRecipe('homura_gun_ammo2',{AMMO1(40),Ig('homura_ammochain',1,'images/inventoryimages/homura_ammochain.xml')},2,40)

table.foreach(
{
    lens    = {Ig('log',1),Ig('berries_cooked',1),Ig('bluegem',1)},
    knife   = {Ig('flint',10)},
    silent  = {Ig('heatrock',1),Ig('charcoal',2)},
    flyingspeed = {Ig('trinket_6',6),Ig('redgem',1),Ig('bluegem',1)},
    ice     = {Ig('icehat',1),Ig('bluegem',3),Ig('gears',1)},
    waterproof  = {Ig('beeswax',1),Ig('pigskin',2)},
},
function(k,v) AddHomuraBuff(k, v, 1) end)

table.foreach(
{
    code    = {Ig('beardhair',16)}, 
    magic   = {Ig('purplegem',4),Ig('nightmarefuel',6)},
    wind    = {Ig('feather_crow',6),Ig('feather_robin',6),Ig('feather_robin_winter',6)},
    mouse   = {Ig('cutreeds',29),BUFF("code"),Ig('goldnugget',1)},
    homing  = {BUFF("eye_lens"),Ig('boards',10),},
    eye_lens= {Ig('deerclops_eyeball',1),Ig('goldnugget',4),BUFF("lens")},
    clip    = {Ig('nightmarefuel',40),Ig('boards',2)},
    time    = {Ig('townportaltalisman',1), Ig('purplegem',1)},
    wormhole= {Ig("monstermeat",4), Ig("purplegem", 3), Ig("houndstooth", 5)},
    laser   = {Ig('moonglass', 10)},
},
function(k,v) AddHomuraBuff(k, v, 2) end)

-- for box
for i = 1, 3 do
    AddRecipe("homura_box_"..i, {Ig("boards", 1)}, RECIPETABS.TOWN, TECH.LOST)
end

-- 2022.1.16 Move homura tab to bottom
AddClassPostConstruct("widgets/crafttabs", function(self)
    if self.tabs and self.tabs.tabs then
        for _,v in pairs(self.tabs.tabs)do
            if v.icon_atlas == "images/hud/homura_uptower.xml" then
                v:MoveToBack()
                break
            end
        end
        for _,v in pairs(self.tabs.tabs)do
            if v.icon_atlas == "images/hud/homura_tab.xml" then
                v:MoveToBack()
                break
            end
        end
    end
end)
