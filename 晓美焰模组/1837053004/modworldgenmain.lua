GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
if rawget(GLOBAL, "homura_modworldgenmain") then
	return false
else
	rawset(GLOBAL, "homura_modworldgenmain", true)
end

-- modimport "modmain/winsync"
modimport "modmain/configui"