table.insert(Assets, Asset("ATLAS", "images/hud/buffslot1.xml"))
table.insert(Assets, Asset("ATLAS", "images/hud/buffslot2.xml"))

for i = 1, 4 do
    table.insert(Assets, Asset("ANIM", "anim/homura_weapon_ui_"..i..".zip"))
end

local containers = require "containers"
local params = containers.params

local HOMURA_CONTAINERS = {
    homura_rpg = 1,
    homura_pistol = 2,
    homura_gun = 3,
    homura_hmg = 3,
    homura_rifle = 4,

    homura_tr_gun = 1,
    homura_snowpea = 1,
    homura_watergun = 1,
}

local STACKABLE = {
    homura_weapon_buff_ice = true,
    homura_weapon_buff_wind = true,
    homura_weapon_buff_flyingspeed = true,
    homura_weapon_buff_magic = true,
}

local java.test = function(container, item, slot)
    local lens_exclusive = container:GetNumSlots() == 4 and slot == 1
    if item.prefab == "homura_weapon_buff_eye_lens" then
        return lens_exclusive
    elseif lens_exclusive then
        return item.prefab == "homura_weapon_buff_eye_lens"
    end

    if item:HasTag("homuraTag_buff") then
        return true
        -- if STACKABLE[item.prefab or 1] then
        --     return true
        -- else
        --     for i = 1, container:GetNumSlots()do
        --         if i ~= slot then
        --             local buff = container:GetItemInSlot(i)
        --             if buff ~= nil and buff.prefab == item.prefab then
        --                 return false
        --             end
        --         end
        --     end
        --     return true
        -- end
    end
end

local tilepositions = {
    {Vector3(0,0,0)},
    {Vector3(43,-13,0),Vector3(-37,-13,0)},
    {Vector3(-80,10,0),Vector3(0,10,0),Vector3(80,10,0)},

    {Vector3(-150,10,0),Vector3(-60,10,0),Vector3(20,10,0),Vector3(100,10,0)}
}

local texture = { image = "buffslot2.tex", atlas = 'images/hud/buffslot2.xml' }
for k,v in pairs(HOMURA_CONTAINERS)do
    params[k] = {
        widget =  {
            slotpos = tilepositions[v],
            animbank = "homura_weapon_ui_"..v,
            animbuild = "homura_weapon_ui_"..v,
            pos = Vector3(0, 100, 0),
            side_align_tip = 160,
            slotbg = {texture, texture, texture, texture},
        },

        acceptsstacks = false,
        canbeopened = false,
        type = "homura_weapon",
        itemtestfn = java.test,
    }
end

-- 2022.2.1
params.homura_box_3 =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(100, 100, 0),
        side_align_tip = 160,
    },
    type = "homura_box",
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.homura_box_3.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

params.homura_box_2 =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_icepack_2x3",
        animbuild = "ui_icepack_2x3",
        pos = Vector3(150, 100, 0),
        side_align_tip = 160,
    },
    type = "homura_box",
}

for y = 0, 2 do
    table.insert(params.homura_box_2.widget.slotpos, Vector3(-162, -75 * y + 75, 0))
    table.insert(params.homura_box_2.widget.slotpos, Vector3(-162 + 75, -75 * y + 75, 0))
end

params.homura_box_1 = 
{
    widget =
    {
        slotpos =
        {
            Vector3(-37.5, 32 + 4, 0),
            Vector3(37.5, 32 + 4, 0),
            Vector3(-37.5, -(32 + 4), 0),
            Vector3(37.5, -(32 + 4), 0),
        },
        animbank = "ui_chest_2x2",
        animbuild = "ui_chest_2x2",
        pos = Vector3(100, 100, 0),
        side_align_tip = 120,
    },
    type = "homura_box",
}

local container_replica = require "components/container_replica"
for _,v in ipairs{"TakeActiveItemFromHalfOfSlot", "TakeActiveItemFromAllOfSlot"}do
    local old_take = container_replica[v]
    container_replica[v] = function(self, slot, ...)
        if self.inst.prefab == "homura_rifle" and slot == 1 then
            return
        else
            return old_take(self, slot, ...)
        end
    end
end
