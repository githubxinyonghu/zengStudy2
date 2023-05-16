-- 该模块仅调试用，在mac系统不生效
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

-- OU_76561198817463174/KU_OdKe1JO

if TheNet == nil or TheNet:GetLocalUserName() ~= "老王天天写bug" then
	return
elseif CWD ~= nil and string.find(CWD, "dontstarve_steam.app") then
	return
else
	-- print(CWD)
end

local url = "http://8.131.61.37:90/" -- 公网ip

local function ListModFile(data)
	TheSim:QueryServer(url.."get-list/", function(result, i, code)
		if code == 200 then
			if result:sub(1,2) == "LW" then
				local list = json.decode(result:sub(3))
				data.setlist(list)
				return
			end
		end
		print("Server Error["..code.."]: "..tostring(result))
	end, "GET")
end

local function UpdateModFile(path, data)
	TheSim:QueryServer(url.."get-mod-file/"..path, function(result, i, code)
		if code == 200 then
			if result:sub(1,2) == "LW" then
				local f = io.open(MODROOT..path, "w")
				f:write(result:sub(3))
			else
				print("Server Error["..code.."]: "..tostring(result))
			end
		else
			print("Server Error["..code.."]: "..tostring(result))
		end

		data.getfilecb(path)
	end, "GET")
end

-- run --->
print("Auto update...")
local data = { }
function data.setlist(list)
	data.list = {}
	for path,v in pairs(list)do
		local time = TheSim:GetFileModificationTime(MODROOT..path)
		local timestamp = tonumber("0x"..time) or math.huge
		if timestamp + 4 < v then
			data.list[path] = true
		end
	end

	local size = GetTableSize(data.list)
	if size > 10 then
		print("Too many files to update, stop.")
		return
	else
		print("Updating "..size.." file(s)...")
		print("===============================")
		data.updatefile()
	end
end

function data.updatefile()
	local path,v = next(data.list)
	if path ~= nil then
		print("File: "..path)
		UpdateModFile(path, data)
	else
		print("============ Done =============")
	end
end

function data.getfilecb(path)
	data.list[path] = nil
	data.updatefile()
end

ListModFile(data) --> mainfn 
