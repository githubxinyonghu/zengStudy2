table.insert(PrefabFiles, "homura_detonator")

-- 2021.6.1 调整合成路径
do return end





local function GetMode(inst)
	if inst and inst.player_classified then
		return inst.player_classified.homura_detonator_crafting_mode:value()
	else
		return 1
	end
end

local function PostInit(self)
	local old_can = self.CanBuild
	function self:CanBuild(recname, ...)
		if recname == 'homura_detonator_fake' then
            return old_can(self,'homura_detonator'..GetMode(self.inst), ...)
    	else
    		return old_can(self, recname, ...)
    	end
    end

    local old_build = self.DoBuild
    if not old_build then
    	return
    end

    function self:DoBuild(recname, ...)
    	if recname == 'homura_detonator_fake' then
    		return old_build(self,'homura_detonator'..GetMode(self.inst), ...)
    	else
    		return old_build(self, recname, ...)
    	end
    end
end

AddComponentPostInit('builder', PostInit)
AddClassPostConstruct('components/builder_replica', PostInit)

--修改界面
--顶部配方图标可点击来选择具体的合成材料
--如果这个配方暂时用不到，则显示为半透明
local RecipePopup = require "widgets/recipepopup" --鼠标移动到配方tab时，显示出的浮动面板
local old_set = RecipePopup.SetRecipe
function RecipePopup:SetRecipe(rec, owner)
	if old_set(self, rec, owner) == false then
		return false
	end

	if rec and rec.name == 'homura_detonator_fake' then

		local mode = GetMode(owner)
		--print(mode)
		self.desc:SetString(STRINGS.RECIPE_DESC['HOMURA_DETONATOR'..mode])

		local ing1, ing2
		for k, v in pairs(self.ing)do --这里存放了配方图标ui
			if v.ing.texture == 'gunpowder.tex' then --获取火药图标
				ing1 = v
			elseif v.ing.texture == 'powcake.tex' then --获取火药饼图标
				ing2 = v
			end
		end

		local function SetUnused(self) --变得半透明
			self.homuraFlag = true
			self.ing:SetTint(1,1,1,0.2)

			self.bg.oldtex = self.bg.texture
			self.bg:SetTexture(resolvefilepath("images/hud.xml"), "inv_slot.tex")
			self.bg:SetTint(1,1,1,0.2)

			self.quant.oldtext = self.quant.string
			self.quant:SetString("-/-")
			self.quant:SetColour(1,1,1,0.2)
		end

		local function SetUsed(self) --恢复原样
			if not self.homuraFlag then
				return
			else
				self.homuraFlag = nil
			end

			self.ing:SetTint(1,1,1,1)

			self.bg:SetTexture(resolvefilepath("images/hud.xml"), self.bg.oldtex)
			self.bg:SetTint(1,1,1,1)

			self.quant:SetString(self.quant.oldtext)
			self.quant:SetColour(self.bg.oldtex == "inv_slot.tex" and {1,1,1,1} or {1,155/255,155/255,1})
		end

		if mode == 1 then
			SetUnused(ing2)
		else
			SetUnused(ing1)
		end

		local ing = {ing1, ing2}
		local this = self
		for i = 1, 2 do

			local old_control = ing[i].OnControl
			ing[i].OnControl = function(self, control, down, ...)
				if old_control then
					old_control(self, control, down, ...)
				end
				if not self:IsEnabled() or not self.focus then return end
				if control == CONTROL_ACCEPT then
					if down then
						TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
						self:ScaleTo(1.1,0.9,0.1)
						self.down = true
					else
						if self.down then
							self.down = false
							self:ScaleTo(1,1,0)
							SendModRPCToServer(MOD_RPC['akemi_homura']['detonator'],i)
							if owner.replica.builder:CanBuild('homura_detonator'..i) then
								this.button:Enable()
							else
								this.button:Disable()
							end
							this.desc:SetString(STRINGS.RECIPE_DESC['HOMURA_DETONATOR'..i])
							SetUnused(ing[3-i])
							SetUsed(ing[i])
						end
					end
					return true
				end
			end

			ing[i].OnGainFocus = function(self)
				self:ScaleTo(1,1.1,0.1)
			end

			ing[i].OnLoseFocus = function(self)
				self:ScaleTo(1,1,0)
			end
		end
	end
end

AddModRPCHandler("akemi_homura", "detonator", function(inst, mode)
	if (mode == 1 or mode == 2) and inst.player_classified then
		inst.player_classified.homura_detonator_crafting_mode:set(mode)
    end
end)
