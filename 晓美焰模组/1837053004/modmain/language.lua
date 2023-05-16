if GetModConfigData("language") ~= "AUTO" then
    LANGUAGE_SETTING = GetModConfigData("language") == "ENG"
else
    -- system language
    local loc = require "languages/loc"
    local lan = loc and loc.GetLanguage and loc.GetLanguage()
    if lan == LANGUAGE.CHINESE_S or lan == LANGUAGE.CHINESE_S_RAIL then
        LANGUAGE_SETTING = false
    else
        LANGUAGE_SETTING = true
    end
end

L = LANGUAGE_SETTING -- For env
HOMURA_GLOBALS.L = LANGUAGE_SETTING -- For GLOBAL
HOMURA_GLOBALS.LANGUAGE = LANGUAGE_SETTING

local L = L 

function Loc(e, c)
	return L and e or c 
end