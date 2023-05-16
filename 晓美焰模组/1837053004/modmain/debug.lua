-- GLOBAL.PRINT_SOURCE = true

if modname:find("workshop") then return end

-- 控制台命令
local homura_command = {
	fitting = function()
		for k,v in pairs(HOMURA_GLOBALS.ALLBUFF)do
			c_give("homura_weapon_buff_"..k)
		end
	end,

	gun = function()
		for _,v in pairs{"homura_pistol", "homura_gun", "homura_rifle", "homura_rpg"} do
			c_give(v)
		end
	end,

	gun2 = function()
		for _,v in ipairs{"homura_snowpea", "homura_tr_gun", "homura_watergun"} do
			c_give(v)
		end
	end,
}

for k,v in pairs(homura_command)do
	rawset(GLOBAL, "h_"..k, v)
end

AddClassPostConstruct("screens/consolescreen", function(self)
	self.console_edit:AddWordPredictionDictionary({words = table.getkeys(homura_command), delim = "h_", num_chars = 0})

	-- 通用
	self.console_edit:AddWordPredictionDictionary({words = {"SetBank", "SetBuild", "PlayAnimation"}, delim = "AnimState:", postfix = "(", skip_pre_delim_check = true})
end)

function GLOBAL.db()
	local player = c_spawn"wilson"
	local target = c_spawn"dummytarget"

	local gun = SpawnPrefab "homura_hmg"
	gun.components.homura_weapon.no_ammo = true
	player.components.inventory:GiveItem(gun)
	player.components.inventory:Equip(gun)

	player:DoPeriodicTask(1, function()
	player.components.locomotor:PushAction(BufferedAction(player, target, ACTIONS.ATTACK))
	end)
end

AddPlayerPostInit(function(inst)

	inst:AddTag("homura")

	TheWorld:DoPeriodicTask(1, function() for _,v in ipairs(AllPlayers)do if v.components.builder then v.components.builder.freebuildmode = true end end end)
	do return end

	inst.homura_sg_name = net_string(inst.GUID, "homura_sg_name")

	inst.homura_rush = net_bool(inst.GUID, "homura_rush")

	local label
	label = inst.entity:AddLabel()
	label:SetFontSize(32)
 	label:SetFont(DEFAULTFONT)
 	label:SetWorldOffset(0, 1, 0)
 	label:SetUIOffset(0, 0, 0)
 	label:SetColour(0.5, 1, 0.5)
 	label:Enable(true)

 	local function name()
 		return inst.sg and inst.sg.currentstate and inst.sg.currentstate.name or "-"
 	end

 	local function rush()
 		return inst.sg and inst.sg.statemem.homura_rush
 	end

 	inst:DoPeriodicTask(0, function()
 		if TheWorld.ismastersim then
 			inst.homura_sg_name:set(name())
 			inst.homura_rush:set(not not rush())
 		else
 			label:SetText(name().."/"..inst.homura_sg_name:value().."\n"
 				..tostring(rush()).."/"..tostring(inst.homura_rush:value()).."\n"
 				..tostring(inst:HasTag("homuraTag_rush")))
 		end
 	end)

 	-- inst:DoPeriodicTask(0, function()
 	-- 	if TheWorld.ismastersim then
 	-- 		inst.homura_sg_name:set(name())
 	-- 		label:SetText(name())
 	-- 	else
 	-- 		label:SetText(name().."/"..inst.homura_sg_name:value())
 	-- 	end
 	-- end)
end)

do return end

-- 指令
