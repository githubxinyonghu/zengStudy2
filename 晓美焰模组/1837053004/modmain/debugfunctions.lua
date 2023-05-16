local CMP = {
	homura_archer = true,
	homura_reader = true,
	homura_reinforcement = true,
}

function EntityScript:GetDebugString()
    local str = {}
    
    table.insert(str, tostring(self))
    table.insert(str, string.format(" age %2.2f %s", self:GetTimeAlive(), self:IsAsleep() and "<ASLEEP>" or ""))
    table.insert(str, "\n")
    
    if self.entity:GetDebugString() then
        table.insert(str, self.entity:GetDebugString())
    end

    table.insert(str, "Buffered Action: "..tostring(self.bufferedaction).."\n")

    if self.debugstringfn then
		table.insert(str, self.debugstringfn(self))
    end

    if self.sg then
        table.insert(str, "SG:" .. tostring(self.sg).."\n-----------\n")
    end

	local cmpkeys = {}
    for k,v in pairs(self.components) do
    	-- if CMP[k] then
    	if string.find(k, "homura") then
			table.insert(cmpkeys, k)
		end
	end
	table.sort(cmpkeys)
	for i,k in ipairs(cmpkeys) do
        if self.components[k].GetDebugString then
            table.insert(str, k..": "..tostring(self.components[k]:GetDebugString()).."\n")
        end
    end

    return table.concat(str, "")
end



AddPlayerPostInit(function(inst)
	do return end
	
	local debug_var = net_string(inst.GUID, "homura_debug_var")

	local function name()
		if TheWorld.ismastersim then
			return string.format("%.1f", inst.Transform:GetRotation())
		else
			return string.format("%.1f", inst.Transform:GetRotation())
		end
	end

	local function name()
		if inst.sg then
			return inst.sg.currentstate.name
		else
			return "-"
		end
	end

	local label = inst.entity:AddLabel()
	label:SetFontSize(32)
 	label:SetFont(DEFAULTFONT)
 	label:SetWorldOffset(0, 1, 0)
 	label:SetUIOffset(0, 0, 0)
 	label:SetColour(0.5, 1, 0.5)
 	label:Enable(true)

 	inst:DoPeriodicTask(0, function()
 		if TheWorld.ismastersim then
 			debug_var:set(name())
 			label:SetText(name())
 		else
 			label:SetText(string.format("current: %s\nserver: %s",
 				name(),
 				debug_var:value()))
 		end
 	end)
end)

do return end

function GLOBAL.sgdebug()
	local ent = TheInput:GetWorldEntityUnderMouse()
	
	if ent and ent.sg then

		local ent2 = CreateEntity()
		local lb = ent.entity:AddLabel()
		lb:SetFontSize(50)
     	lb:SetFont(DEFAULTFONT)
     	lb:SetWorldOffset(0, 5, 0)
     	lb:SetUIOffset(0, 0, 0)
     	lb:SetColour(0.5, 1, 0.5)
     	lb:Enable(true)

        ent2:DoPeriodicTask(0,function()
            lb:SetText(tostring(ent.sg.currentstate.name))
        end)
    end
end

local LW_LINKER = Class(function(self)
    self.AnimStateLinker = {}
end)

local LW_LINKER = LW_LINKER()

local addanimstate = Entity.AddPhysics
Entity.AddPhysics = function(ent, ...)
    local userdata = addanimstate(ent, ...)
    local GUID = ent:GetGUID()
    local inst = Ents[GUID]
    if inst and LW_LINKER then
    	if inst.Physics and LW_LINKER.AnimStateLinker[inst.Physics] then
    		LW_LINKER.AnimStateLinker[inst.Physics] = nil
    	end
        LW_LINKER.AnimStateLinker[userdata] = inst
    end
    return userdata
end
--if self.inst:HasTag('player') then
        --    print('go to state  '..arg[1])
        --    if arg[1] =='idle' then
            --for i,v in pairs(debug.getinfo(2)) do
            --    print(i,v)
            --end
        --end
        --end
function GLOBAL.phydebug()
	for k,v in pairs(Physics)do
		local oldfn = v 
		Physics[k] = function(a,...)
			if k ~= 'GetWorldPosition' and LW_LINKER.AnimStateLinker[a] and LW_LINKER.AnimStateLinker[a].prefab == 'boat'

				then
					print('call: ',k,'  args: ', ...)
            for i,vvv in pairs(debug.getinfo(2)) do
                print(i,vvv)
            end end
        	return oldfn(a,...)
        end
    end
end


AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(3,function() 
	if inst.components.knownfoods then
		for k, v in pairs(getmetatable(inst.components.knownfoods ))do
  		print('k:  ',k,'v:  ',v)
  		if type(v) == 'function' then
    		local old_v = v 
   			inst.components.knownfoods[k] = function(...)
      		print('run:  '..k)
      		old_v(...)
    		end
  		end
  			end
	end end)
end)

local hud = true
function GLOBAL.c_hud()
	if hud then
		--
	else
		---
	end
	hud = not hud 
end

function GLOBAL.c_ammo()
	--c_give('homura_rpg')
	--c_give('homura_rpg_ammo1',20)
	--c_give('homura_rpg_ammo2',20)
	--c_give('homura_pistol')
	--c_give('homura_gun')
	--c_give('homura_hmg')
	--c_give('homura_gun_ammo1',40)
	--c_give('homura_gun_ammo2',40)
	--c_give('homura_gun_ammo3',40)
	c_spawn('homura_workdesk')
	c_give('goldnugget',20)
	c_give('gunpowder',20)
	c_give('powcake',20)
end

function GLOBAL.c_treasure()
	local a = 0
	for _,v in pairs(Ents)do
		if v.prefab == 'buriedtreasure' then
			a = a+1
		end
	end
	print("TOTAL: "..a)
end
local function cdbug()
end

function GLOBAL.sfx(num)
	local t = {
		"dontstarve/cave/nightmare_warning",
        "dontstarve/cave/nightmare_full",
        "dontstarve/cave/nightmare_end",
   "dontstarve/cave/nightmare", "nightmare_loop"
	}
	GetPlayer().SoundEmitter:KillSound("DEBUG")
	GetPlayer().SoundEmitter:PlaySound(t[num] or '',"DEBUG",1)
end
function GLOBAL.dplayer()
	SetDebugEntity(GetPlayer())
	do return end
	local inst = GetPlayer()
	inst.entity:AddLabel()
      inst.Label:SetFontSize(30)
        inst.Label:SetFont(DEFAULTFONT)
       inst.Label:SetPos(0,0,0)
        inst.Label:SetColour(.5,1,.5)
        inst.Label:Enable(true)
        --inst.Label:SetText(num)
        
        inst:DoPeriodicTask(0,function()
            inst.Label:SetText(tostring(inst.components.animstatemanager.anim))
            print(inst.entity:GetDebugString())
            --print(inst.components.animstatemanager.anim)
        end)
	--[[
	GetPlayer():DoPeriodicTask(1,function(inst)
		local a,b = inst.components.playeractionpicker:DoGetMouseActions()
		if a then
			print("L:  "..a.action.id)
		end
		if b then
			print("R:  "..b.action.id)
		end
	end)
	--]]
end

function GLOBAL.reload()
	StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = SaveGameIndex:GetCurrentSaveSlot(), playeranim="failadventure"})
end

local function GetTableIndex(t,previouskey,fn,isdesc)
    local isdesc = false
    local str = ''
    local previouskeys = ''--输出嵌套表的k值
    for k,v in pairs(t)do
        --if fn(k) then
        if type(v) == 'string' then
            local NAME
            local previouskey1 = ''
            if previouskey ~= '' then
                previouskey1 = previouskey:sub(2) or ''
                NAME = type(STRINGS.NAMES[previouskey1])=='string' and STRINGS.NAMES[previouskey1]   
            end
            
            NAME = (NAME or (type(STRINGS.NAMES[k])=='string' and STRINGS.NAMES[k])) or ''
            NAME = NAME == "" and [["]] or [["   --]]..NAME

            str = str..(previouskey and previouskey..'.' or '')..k..[[ = "]]..v..(NAME)..(isdesc and'\nDESCRIBE' or'\n@')
        elseif type(v) == 'table' then 
            previouskeys = previouskeys..[["]]..k..[[",]] --记录嵌套表的k
            str = str..GetTableIndex(v,(previouskey and previouskey.."."or "").. k,function()return true end)
        --end
        end
    end
    return str,previouskeys
end

function GLOBAL.ch(time)
    --GetPlayer().HUD.puellaUI_playerflash:SetBlind(time)
    local str = ''
    for name, data in pairs(KnownModIndex.savedata.known_mods) do
		if data.enabled and not data.disabled_bad and not data.disabled_old and not data.disabled_incompatible_with_mode then
			--print(GetTableIndex(data.modinfo))
			for k,v in pairs(data.modinfo)do
				str = str..string.format("%s:   %s  \n",k,tostring(v))
			end

		end
	end
	print(str)
end
--GLOBAL.ch()

function GLOBAL.c_as(num)
	GetPlayer().AnimState:SetDeltaTimeMultiplier(num)
end

function GLOBAL.c1(a,b,...)
	return GLOBAL.c_spawn('heat_resistant_pill',1,...)
end

local num = 1
function GLOBAL.anim(str)
	--GetPlayer().sg:GoToState('kyouko_sweep_pre')
	--print(tostring(modname))
	--GetPlayer().sg:Stop()

	--GetPlayer().AnimState:PlayAnimation('side'..num)
	--GetPlayer():ListenForEvent('animover',function(inst)
		num = num + 1
	--	num = num == 4 and 1 or num
	--	inst.AnimState:PlayAnimation('side'..num)
	--end)
	GetPlayer().AnimState:PlayAnimation("run_loop",true)
	GetPlayer().sg:Stop()
	if math.mod(num,2)==0 then
		GetPlayer().sg:Start()
	end
	SetDebugEntity(GetPlayer())
end

function GLOBAL.lw()
	--GetPlayer().components.witchspawner:ForceReset()
	local inst = GetPlayer()
	inst:DoPeriodicTask(0, function(inst)
            for _,node in ipairs(inst.brain.bt.root.children)do
                    if node.name == 'ChaseAndAttack' then
                        --print('I get the node!')
                        print(node.max_attacks,node.numattacks)
                    end
                end
                end)
end


local function GetTableIndex(t,previouskey)
	local str = ''
	for k,v in pairs(t)do
		if type(v) == 'string' then
			local NAME
			if previouskey and previouskey:sub(1,4) == 'DESC' then
				local namestring = previouskey:sub(11)
				--print(namestring)
				
					NAME = type(STRINGS.NAMES[namestring])=='string' and STRINGS.NAMES[namestring]
					--print(NAME)
				
			end
			NAME = (NAME or (type(STRINGS.NAMES[k])=='string' and STRINGS.NAMES[k])) or ''

			str = str..(previouskey and previouskey..': ' or '')..k..'    '..(NAME)..'    '..v..'\n'
		elseif type(v) == 'table' then 
			str = str..GetTableIndex(v,(previouskey and previouskey..": "or "").. k)
		end
	end
	return str
end

function GLOBAL.hualao()
	GetPlayer():DoPeriodicTask(1,function(inst)
		inst.components.talker:Say('111')
	end)
end

function GLOBAL.pr1(...)
	local table = require 'speech_wilson'

	local str = GetTableIndex(table)
	print(str)
end
local old_cre = CreateEntity
function GLOBAL.CreateEntity(...)
	local ent = old_cre(...)
	if ent and ent.GUID then 
		if ent:HasTag('player') or ent:HasTag('wall') then 
			print(ent)
		end
	end
	return ent 
end
--[[
local oldsp = SpawnPrefab
function GLOBAL.SpawnPrefab(...)
	local ent = oldsp(...)
	if ent and ent.GUID 
--]]
function GLOBAL.debugkill() 
	GetPlayer():DoTaskInTime(2,function() GetPlayer().components.health:Kill() end)
end

function GLOBAL.c_sg(num)
	GetPlayer().components.soulgem.current = num or 0
	GetPlayer().components.soulgem:DoDelta(0)
end

function GLOBAL.debugdark()
	GetPlayer():DoTaskInTime(2,function() 
		GetPlayer().components.soulgem.current = 199
		GetPlayer().components.health:Kill()
	end)
end

function GLOBAL.debugent()
	local prefab = 'witch_qw_icon_sr'
	inst = DebugSpawn(prefab)
	inst.Transform:SetPosition(TheInput:GetWorldPosition():Get())
	SetDebugEntity(inst)

	
end

function GLOBAL.fz()
	local ui = Input:GetHUDEntityUnderMouse()
	if ui and ui.inst.AnimState then
		ui.inst.AnimState:SetScale(-1,1)
		ui:SetScale(-1)
	end
end

function debugpro(inst)
	local prefab1 = 'homura_missile1'
	local prefab2 = 'homura_missile2'
	inst.components.weapon.projectile = math.random()>0.5 and prefab1 or prefab2
	--inst:AddTag('homura_prototyper')
	--inst:AddTag("speargun")
end
--AddPrefabPostInit('icestaff',debugpro)
function GLOBAL.wd()
	GetPlayer().components.health:SetAbsorptionAmount(.99)
end
local a = true
function GLOBAL.killer()
	if a then
		a = false
		GetPlayer().components.combat:AddDamageModifier("DEBUG",100)
	else
		a = true
		GetPlayer().components.combat:AddDamageModifier("DEBUG",0)
	end
end

function GLOBAL.ph()
	print(GetDebugEntity():GetPosition().y)
end

function GLOBAL.placeon()
	local pos = TheInput:GetWorldEntityUnderMouse():GetPosition()
	GetDebugEntity().Transform:SetPosition(pos.x,10,pos.z)
	--GetPlayer().Transform:SetPosition(pos.x,10,pos.z)
	--MakeInventoryPhysics(GetPlayer())
end

local function printval(inst)
	inst:DoPeriodicTask(0,function()print(tostring(inst.components.playercontroller.directwalking)) end)
	
end

--AddPrefabPostInit('sayaka',printval)
function GLOBAL.DebugCom(inst,name)
	if not inst then 
		inst = GetPlayer()
	end
	if not inst.components[name]then
		return
	end
	local ignore = {"OnUpdate","UsingMouse","GetLeftMouseAction"}
	local function pass(name)
		for _,ig in pairs(ignore)do
			if ig == name then
				return false
			end
			return true
		end
	end
	for k,v in pairs(getmetatable(inst.components[name]))do
		if pass(k) and type(inst.components[name][k]) == "function" then
			inst.components[name][k] = function(...)
				print("Run:  "..tostring(k))
				return v(...)
			end
		end
	end
end

function GLOBAL.getgetget()
	c_give("golden_armor_mk")
	c_give("redgem", 20)
	c_give("bluegem", 20)
	c_give("purplegem", 20)
	c_give("golden_hat_mk")

end
--AddPrefabPostInit("sayaka",function(inst)GLOBAL.DebugCom(inst,"combat")end)