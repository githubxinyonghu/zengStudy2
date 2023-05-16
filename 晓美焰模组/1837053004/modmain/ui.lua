table.insert(Assets, Asset("ANIM", "anim/homura_cd_percent.zip"))
table.insert(Assets, Asset("ANIM", "anim/homura_cd_flash.zip"))
table.insert(Assets, Asset("ANIM", "anim/homura_badge.zip"))

table.insert(Assets, Asset("ATLAS", "images/hud/homuraUI_focus.xml"))
table.insert(Assets, Asset("ATLAS", "images/hud/homuraUI_focus_ring.xml"))
table.insert(Assets, Asset("SHADER", "shaders/mami_circle.ksh"))

table.insert(Assets, Asset("ATLAS", "images/hud/homura_learning_formula.xml"))

local UIAnim = require "widgets/uianim"
local sk3 = require "widgets/puellaUI_skill_homura" --homura
local Flash = require "widgets/homuraUI_playerflash" --致盲
local Focus = require "widgets/homuraUI_focus"
local Mover = require "widgets/puellaUI_skill_base"
local Learning = require "widgets/homuraUI_learning"
local BarMeter = require "widgets/homuraUI_barmeter"

local function GetUIPosition(pos1,pos2,pos3)
    local min = math.min(pos1.x,pos2.x,pos3.x)
    local max = math.max(pos1.x,pos2.x,pos3.x)
    local y = math.max(pos1.y,pos2.y,pos3.y)
    if math.abs(pos1.y-pos2.y) < 5 and math.abs(pos2.y-pos3.y) < 5 then  --直线
        return Vector3(1.5*min-0.5*max,y,0)
    else
        return Vector3(2*min-max,y,0)
    end
end

local function Addsg(self)  --对暴食和熔炉模式需要进行优化
    if BANTIMEMAGIC then
        return
    end
    
    if self.owner and self.owner.prefab == 'homura_1' then
        local heartpos = self.heart:GetPosition()
        local brainpos = self.brain:GetPosition()
        local stomapos = self.stomach:GetPosition()
        local uipos = GetUIPosition(heartpos, brainpos, stomapos)

        self.puellaUI_skillicon = self:AddChild(sk3(self.owner))
        self.puellaUI_skillicon:SetPosition(uipos:Get())
        self.puellaUI_skillicon.mover.defalutPos = uipos

        self.puellaUI_skillicon_base = self:AddChild(Mover())
        self.puellaUI_skillicon_base:SetPosition(uipos:Get())
        self.puellaUI_skillicon_base.defalutPos = uipos
        self.puellaUI_skillicon_base.mainicon = self.puellaUI_skillicon
        self.puellaUI_skillicon_base.homuraUI_skillmover = self.puellaUI_skillicon.mover
        self.puellaUI_skillicon_base:MoveToBack()

        local mod = self.heart.maxnum ~= nil or self.heart.bg ~= nil or self.heart.max ~= nil
        if mod then 
            self.puellaUI_skillicon:SetScale(0.9)
            self.puellaUI_skillicon.MOD = 0.9
        end
    end

    local old_setghost = self.SetGhostMode
    function self:SetGhostMode(...)
        old_setghost(self, ...)
        if not self.puellaUI_skillicon then
            return 
        end
        if self.isghostmode then
            self.puellaUI_skillicon:Hide()
        else
            self.puellaUI_skillicon:Show()
        end
    end
end
AddClassPostConstruct("widgets/statusdisplays", Addsg)

AddClassPostConstruct("screens/playerhud", function(self)
    local old_createoverlays = self.CreateOverlays
    function self:CreateOverlays(owner)
        old_createoverlays(self,owner)

        self.homuraUI_learning = self.overlayroot:AddChild(Learning(owner))
        self.homuraUI_playerflash = self.overlayroot:AddChild(Flash(owner))
        self.homuraUI_focus = self.overlayroot:AddChild(Focus(owner))
        self.homuraUI_bar = self.popupstats_root:AddChild(BarMeter(owner))
    end

    local old_control = self.OnControl
    function self:OnControl(control, down)
        if self.homuraUI_focus and self.homuraUI_focus:OnControl(control, down) then
            return true
        else
            return old_control(self, control, down)
        end
    end
end)

-- 武器耐久显示
local ItemTile = require "widgets/itemtile"
local old_refresh = ItemTile.Refresh
function ItemTile:Refresh(...)
    old_refresh(self, ...)
    if not self.item:HasTag("homuraTag_no_ammo") and self.item.replica.homura_weapon then
        self:SetPercent(self.item.replica.homura_weapon:GetPercent())
    end    
end

-- Focus ui 手柄适配
AddClassPostConstruct("widgets/inventorybar", function(self)
    local old_nav = self.CursorNav
    function self:CursorNav(...)
        if ThePlayer.HUD and ThePlayer.HUD.homuraUI_focus and ThePlayer.HUD.homuraUI_focus:LockInvBar() then
            return
        elseif ThePlayer.replica.homura_archer.aiming then
            return
        else
            return old_nav(self, ...)
        end
    end
end)

AddComponentPostInit("playercontroller", function(self)

    local old_control = self.OnControl
    function self:OnControl(control, down)
        if self:IsEnabled() and not IsPaused() and
            (control == CONTROL_ATTACK or control == CONTROL_PRIMARY or control == CONTROL_CONTROLLER_ATTACK) then
            if self.inst.HUD and self.inst.HUD.homuraUI_focus and not self.inst.HUD.homuraUI_focus:CanReleaseControl(control) then
                return 
            end 
        end 

        return old_control(self, control, down)
    end 

    local old_left = self.RotLeft
    function self:RotLeft()
        if TheCamera:CanControl() then
            self.inst:PushEvent("homuraevt_rotcamera")
        end
        old_left(self)
    end

    local old_right = self.RotRight
    function self:RotRight()
        if TheCamera:CanControl() then
            self.inst:PushEvent("homuraevt_rotcamera")
        end
        old_right(self)
    end


    local old_remote = self.RemoteAttackButton
    function self:RemoteAttackButton(target, force_attack, ...)
        if self.inst.HUD and self.inst.HUD.homuraUI_focus and self.inst.HUD.homuraUI_focus:CanShoot() then
            force_attack = true
        end
        return old_remote(self, target, force_attack, ...)
    end

    local old_update = self.UpdateControllerTargets
    function self:UpdateControllerTargets(...)
        old_update(self, ...)
        if not self.homura_hooked_UpdateControllerAttackTarget then
            self.homura_hooked_UpdateControllerAttackTarget = true
            -- hook at runtime
            for i = 1, 100 do
                local name, fn = debug.getupvalue(old_update, i)
                -- klei 并没有暴露出这个函数，所以得用些糟糕的方法去拿到它
                if name == "UpdateControllerAttackTarget" then
                    local function UpdateControllerAttackTarget(self, dt, x, y, z, dirx, dirz)
                        local vec = self.inst.HUD and self.inst.HUD.homuraUI_focus:GetFocusWorldPosition()
                        if vec then
                            local offset = Vector3(vec.x - x, 0, vec.z - z)
                            if offset:LengthSq() > 0 then
                                local offset, len = offset:GetNormalizedAndLength()
                                dirx, dirz = offset.x, offset.z
                                vec = Vector3(x, 0, z) + offset*math.max(0.5, math.min(len*0.8, len-4))

                                x, z = vec.x, vec.z
                            end
                        end
                        fn(self, dt, x, y, z, dirx, dirz)
                    end
                    debug.setupvalue(old_update, i, UpdateControllerAttackTarget)
                end

                if name == "UpdateControllerInteractionTarget" then
                    local function UpdateControllerInteractionTarget(self, dt, x, y, z, dirx, dirz)
                        local vec = self.inst.HUD and self.inst.HUD.homuraUI_focus:GetFocusWorldPosition()
                        if vec then
                            local offset = Vector3(vec.x - x, 0, vec.z - z)
                            if offset:LengthSq() > 0 then
                                local offset, len = offset:GetNormalizedAndLength()
                                dirx, dirz = offset.x, offset.z
                                vec = Vector3(x, 0, z) + offset*math.max(0.5, math.min(len*0.8, len-4))

                                x, z = vec.x, vec.z
                            end
                        end
                        fn(self, dt, x, y, z, dirx, dirz)
                    end
                    debug.setupvalue(old_update, i, UpdateControllerInteractionTarget)
                end

                if name == nil then
                    break
                end
            end
        end
    end
end)

