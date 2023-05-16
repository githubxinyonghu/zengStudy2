local L = HOMURA_GLOBALS.LANGUAGE

local function _GetGend(gender)
    if gender == 'FEMALE' then 
        return 'F'
    elseif gender == 'ROBOT' then
        return 'O'
    else
        return 'M'
    end
end

local function _GetStr(str)
    local t = {
        F = Loc('She', '她'),
        M = Loc('He',  '他'),
        O = Loc('It',  '它'),
    }
    return t[str]
end

local function traderpostinit(self)
    local old_can = self.AbleToAccept
    function self:AbleToAccept(...)
        if self.inst:HasTag('homuraTag_pause') 
            -- 2021.10.1
            and (self.inst:HasTag("_combat") or self.inst:HasTag("_health"))
            then
            if self.inst:HasTag('player') then
                return false, 'HOMURA_MAGIC_'.._GetGend(GetGenderStrings(self.inst.prefab))
            else
                return false, 'HOMURA_MAGIC_O'
            end
        else
            return old_can(self, ...)
        end
    end
end
AddComponentPostInit('trader', traderpostinit)

---时停期间禁交易
AddSimPostInit(function()

for k,v in pairs(STRINGS.CHARACTERS)do
    for kk,vv in pairs({'M','O','F'})do
        local str = _GetStr(vv) --她 他 它
        local str2 = L and ' can\'t move.' or "现在动不了。" --后
        if k == 'HOMURA_1' then
        	str2 = L and ' is trapped by magic.' or '被魔法束缚住了'
        end
        
        if not v.ACTIONFAIL then
            v.ACTIONFAIL = {}
        end

        v.ACTIONFAIL.GIVE = v.ACTIONFAIL.GIVE or {}
        v.ACTIONFAIL.GIVETOPLAYER = v.ACTIONFAIL.GIVETOPLAYER or {}
        v.ACTIONFAIL.GIVEALLTOPLAYER = v.ACTIONFAIL.GIVEALLTOPLAYER or {}
        
        local fullstr = str .. str2
        if k == 'WX78' then
            fullstr = L and "ERROR: OBJECT NOT RESPONDING" or '错误: 对象未响应'
        end

        v.ACTIONFAIL.GIVE['HOMURA_MAGIC_'..vv] = fullstr
        v.ACTIONFAIL.GIVETOPLAYER['HOMURA_MAGIC_'..vv] = fullstr
        v.ACTIONFAIL.GIVEALLTOPLAYER['HOMURA_MAGIC_'..vv] = fullstr
    end
end

end)

---无法喂食
local function GetRefuseString(doer, target)
    if doer.prefab == 'wx78' then
        return L and "ERROR: OBJECT NOT RESPONDING" or '错误: 对象未响应'
    end
    if target:HasTag('player') then
        if doer:HasTag('homura') then
            return _GetStr(_GetGend(target.prefab))..(L and' is trapped by magic.'or'被魔法束缚住了')
        else
            return _GetStr(_GetGend(target.prefab))..(L and' can\'t move.'or'现在动不了')
        end
    end
    return L and 'It can\'t move.' or '它现在动不了'
end

local old_fn = ACTIONS.FEEDPLAYER.fn 
ACTIONS.FEEDPLAYER.fn = function(act)
    if act.target and act.target:HasTag('homuraTag_pause') then
        if act.doer and act.doer.components.talker and act.doer.prefab ~= 'wes' then
            act.doer.components.talker:Say(GetRefuseString(act.doer, act.target))
            return true
        end
    end
    return old_fn(act)
end
