-- if false then
-- getmetatable(TheNet).__index.IsOnlineMode  = function ( ... ) return false end
-- getmetatable(TheNet).__index.IsOnlineMode  = function ( ... ) return true end
-- end

local isserver = TheNet:GetIsServer()
local client_choice = nil --用于在ui之间传递

local SKIN_INFO = {
    {name = 'none', fullname = 'homura_1_none', build = 'homura_1'},
    {name = 'moe', fullname = 'homura_1_moe', build = 'homura_0'},
}

SKIN_RARITY_COLORS["HOMURA_1_NONE"] = SKIN_RARITY_COLORS.Character
SKIN_RARITY_COLORS["HOMURA_1_MOE"] = { 150/255, 50/255, 200/255, 1 }

STRINGS.UI.RARITY['HOMURA_1_NONE'] = L and 'Classic' or '经典'
STRINGS.UI.RARITY['HOMURA_1_MOE'] = L and 'The beginning story' or '起始的物语'

STRINGS.SKIN_QUOTES['homura_1_moe'] = L and '"M-My name is Homura Akemi... please to meet you..."' 
or '"那个...我是...晓美焰, 请各位...多多指教!"'

STRINGS.SKIN_DESCRIPTIONS['homura_1_none'] = L and 'Traditional magic girl dress.' or '传统魔法少女服饰, 舒适轻便。'
STRINGS.SKIN_DESCRIPTIONS['homura_1_moe'] = L and 'Just moe.' or '除了萌, 找不到别的形容词了。'

local function GetSkinInfo(key, value) --传入id或键值对, 返回skin信息
    if not key then
        return
    end
    if type(key) == 'number' then
        return SKIN_INFO[key]
    end
    for i, info in pairs(SKIN_INFO) do
        if info[key] == value then return info, i end
    end
end

local function ID(skin_name)
    for i,v in ipairs(SKIN_INFO)do
        if v.fullname == skin_name or v.name == skin_name then
            return i
        end
    end
end

local function isskin(name)
    return type(name) == "string" and string.find(name, "homura_1")
end

local function ChangeModdedCharacterSkin(inst, id)
    local data = GetSkinInfo(id)
    if data then
        inst.components.skinner:SetSkinName(data.fullname)
    end
end

local function ChangePlayerSkinID(inst, id)
    -- print(('Call -> ChangePlayerSkinID  inst = %s id = %s'):format(tostring(inst),tostring(id)))
    if type(id) == 'number' then
        if isserver then
            ChangeModdedCharacterSkin(inst, id)
        else
            SendModRPCToServer(MOD_RPC.homuraRPC_skin.ChangeModdedSkin, id)
        end 
    end
end

--- 2021.3.6 优化
local function OnPlayerActivated(inst)
    if inst == ThePlayer and client_choice ~= nil then
        ChangePlayerSkinID(inst, ID(client_choice))
    end
end

AddPrefabPostInit("homura_1", function(inst)
    inst:ListenForEvent("playeractivated", OnPlayerActivated)
end)

AddModRPCHandler("homuraRPC_skin", "ChangeModdedSkin", ChangePlayerSkinID)

PREFAB_SKINS.homura_1 = {}

function HOMURA_GLOBALS.RegisterSkin(skin, skins, tags)
    -- none  moe  rib  evil
    local fullname = 'homura_1_' .. skin
    table.insert(PREFAB_SKINS.homura_1, fullname)
    STRINGS.SKIN_NAMES[fullname] = STRINGS.NAMES.HOMURA_1
    
    return CreatePrefabSkin(fullname, {
        base_prefab = 'homura_1',
        skins = skins,
        tags = tags,
        type = 'base',
        bigportrait = {symbol = fullname..".tex", build = "bigportraits/"..fullname..".xml"},
        build_name_override = skins.normal_skin,
        rarity = fullname:upper(),
        skip_item_gen = true,
        skip_giftable_gen = true,
    })
end

AddClassPostConstruct('widgets/redux/accountitemframe', function(self)
    --self          : AccountItemFrame
    --self.parent   : ItemImage 
    --self.2parent  : GRID
    --self.3parent  : list_root
    --self.4parent  : scissored_root
    --self.5parent  : TrueScrollList
    --self.6parent  : ItemExplorer
    --self.7parent  : ClothingExplorerPanel
    --self.8parent  : LoadoutRoot

    -- local old_act = self.SetActivityState
    -- function self:SetActivityState(is_active, is_owned, is_unlockable, is_dlc_owned, ...)
    --     is_owned = self.homuraVar_item ~= nil and true or is_owned
    --     old_act(self, is_active, is_owned, is_unlockable, is_dlc_owned, ...)
    -- end

    local old_r = self._SetRarity
    function self:_SetRarity(rarity)
        if rarity == 'HOMURA_1_NONE' then
            self:GetAnimState():OverrideSymbol('SWAP_frameBG', 'frame_BG', 'Character')
        elseif rarity == 'HOMURA_1_MOE' then
            self:GetAnimState():OverrideSymbol('SWAP_frameBG', 'homuraUI_skinbg', 'purple')
        else
            old_r(self, rarity)
        end
    end
end)

local old_set = SetSkinsOnAnim
function GLOBAL.SetSkinsOnAnim(anim_state, prefab, base_skin, clothing_names, skintype, default_build, ...)
    anim_state:ClearOverrideSymbol("headbase")
    anim_state:ClearOverrideSymbol("headbase_hat")
    old_set(anim_state, prefab, base_skin, clothing_names, skintype, default_build, ...)
    if base_skin == "homura_1" then
        if not USEBOW then
            anim_state:OverrideSymbol("headbase_hat", base_skin, "headbase")
        else
            anim_state:OverrideSymbol("headbase", base_skin, "headbase_hat")
        end
    end 
end

local old_fn = CompareRarities
function GLOBAL.CompareRarities(k1,k2)
    local w1, w2
    if isskin(k1) or isskin(k2) then
        return true
    end
    return old_fn(k1,k2)
end

-- BASE选择
AddClassPostConstruct("widgets/redux/itemexplorer", function(self)
    -- 强制设置为已拥有
    local old_fn = self._CreateWidgetDataListForItems
    function self:_CreateWidgetDataListForItems(...)
        local t = old_fn(self, ...)
        for _, data in ipairs(t)do
            if isskin(data.item_key) then
                data.is_owned = true
                data.owned_count = 1
            end
        end
        return t
    end

    --无视过滤
    local old_refresh = self.RefreshItems
    function self:RefreshItems(fn, ...)
        if self.primary_item_type == 'base' then
            local parent = self.parent
            if parent and parent.owner and parent.owner.currentcharacter == 'homura_1' then
                fn = function() return true end
            end
        end
        return old_refresh(self, fn, ...)
    end
end)

-- 绕过验证
do
    local inv = getmetatable(TheInventory).__index

    -- compatible with "表情全解锁" (id=2623277832)
    if type(TheInventory) == "table" and TheInventory.oldTheInventory ~= nil and type(inv) == "function" then
        inv = getmetatable(TheInventory.oldTheInventory).__index
    end

    local old_check = inv.CheckOwnership
    inv.CheckOwnership = function(inv, item, ...)
        if isskin(item) then
            return true
        end
        return old_check(inv, item, ...)
    end

    local old_check_cl = inv.CheckClientOwnership
    inv.CheckClientOwnership = function(inv, id, item, ...)
        if isskin(item) then
            return true
        end
        return old_check_cl(inv, id, item, ...)
    end

    local net = getmetatable(TheNet).__index
    local old_send = net.SendSpawnRequestToServer
    net.SendSpawnRequestToServer = function(net, char, skin_base, ...)
        if char == "homura_1" and isskin(skin_base) then
            client_choice = skin_base
        end
        return old_send(net, char, skin_base, ...)
    end

    local old_validate = ValidateSpawnPrefabRequest
    GLOBAL.ValidateSpawnPrefabRequest = function(id, prefab, base, ...)
        local rt = {old_validate(id, prefab, base, ...)}
        if isskin(base) then
            rt[2] = base
        end
        return unpack(rt)
    end
end

-- 立绘
local old_fn = GetPortraitNameForItem
function GLOBAL.GetPortraitNameForItem(key)
    if isskin(key) then
        return key
    else
        return old_fn(key)
    end
end

--皮肤界面
do
    local net = getmetatable(TheNet).__index
    local forceonline = function(val)
        if val then
            net.homura_IsOnlineMode = net.IsOnlineMode
            net.IsOnlineMode = function() return true end
        else
            if net.homura_IsOnlineMode ~= nil then
                net.IsOnlineMode = net.homura_IsOnlineMode
                net.homura_IsOnlineMode = nil
            end
        end
    end

    -- 换装大厅
    do 
        local LoadOutSelect = require('widgets/redux/loadoutselect') 
        local ctor = LoadOutSelect._ctor
        function LoadOutSelect._ctor(self, prefab, character, ...)
            local is_homura = character == "homura_1"
            if is_homura then 
                table.insert(DST_CHARACTERLIST, "homura_1")
                forceonline(true)
            end
            ctor(self, prefab, character, ...)
            if is_homura then
                table.removearrayvalue(DST_CHARACTERLIST, "homura_1")
                forceonline(false)
            end
        end

        local old_sel = LoadOutSelect._SelectSkin
        function LoadOutSelect:_SelectSkin(item_type, item_key, is_selected, is_owned)
            if isskin(item_key) then
                is_owned = true 
                is_selected = true
            end
            old_sel(self, item_type, item_key, is_selected, is_owned)
        end
    end

    -- 衣柜
    do
        local GridWardrobePopupScreen = require('screens/redux/wardrobepopupgridloadout')
        local ctor = GridWardrobePopupScreen._ctor
        function GridWardrobePopupScreen._ctor(self, owner_player, ...)
            local is_homura = owner_player and owner_player.prefab == "homura_1"
            if is_homura then
                forceonline(true)
            end
            ctor(self, owner_player, ...)
            if is_homura then
                forceonline(false)
            end
        end

        local old_close = GridWardrobePopupScreen.Close
        function GridWardrobePopupScreen:Close(...)
            local owner_player = self.owner_player
            local is_homura = owner_player and owner_player.prefab == "homura_1"
            if is_homura then
                forceonline(true)
            end
            old_close(self, owner_player, ...)
            if is_homura then
                forceonline(false)
            end
        end
    end
end

