local ModManager = GLOBAL.ModManager
local old_link = ModManager.GetLinkForMod
function ModManager:GetLinkForMod(modname, ...)
	if modname == env.modname then
		local url = "https://dont-starve-mod.github.io/zh/homura_index/"
		local is_generic_url = false
		return function() GLOBAL.VisitURL(url) end, is_generic_url
	else
		return old_link(self, modname, ...)
	end
end

do return end

local ModConfigurationScreen = require "screens/redux/modconfigurationscreen"
AddClassPostConstruct("screens/redux/modconfigurationscreen", function(self)
	print("=======================")
	if self.modname ~= modname then
		return
	end

	local function iskey(name)
		return type(name) == "string" and string.match(name, ".+_v2$")
	end

	-- table.foreach(self.options, function(_, v)
	-- 	if iskey(v.name) then
	-- 		print(GLOBAL.json.encode(v))
	-- 	end
	-- end)
	-- table.foreach(self.optionwidgets, function(_, v)
	-- 	if iskey(v.name) then
	-- 		print(v)
	-- 	end
	-- end)

	local list = self.options_scroll_list

	local cached = {}
	local function Print(t, depth)
		for k,v in pairs(t) do
			print(string.rep(" ",depth)..tostring(k),":",v)
			if type(v) == "table" and k ~= "parent" and k ~= "children" then
				if not cached[v] then
					cached[v] = true
					Print(v, depth+1)
				end
			end
		end
	end

	Print(list, 0)
	print("--++--++")
	cached = {}
	Print(list.items, 0)

	-- for k,v in pairs(list)do
	-- 	if type(v) == "table" and v.UpdateWhilePaused ~= nil then
	-- 		print(k,v)
	-- 	end
	-- end

	print("-------------------")
end) 