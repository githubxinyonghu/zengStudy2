local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local Flash = Class(Widget, function(self, owner)
    Widget._ctor(self, "Flash")

    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)

    self.owner = owner
	self:SetClickable(true)

	self.white = self:AddChild(UIAnim())
    self.white:GetAnimState():SetBuild("puellaUI_flash")
    self.white:GetAnimState():SetBank("vig")
    self.white:GetAnimState():PlayAnimation("insane", true)
    self.white:GetAnimState():SetMultColour(0,0,0,0)
    self.white:SetHAnchor(ANCHOR_MIDDLE)
    self.white:SetVAnchor(ANCHOR_MIDDLE)
    self.white:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC) --同vig
    -- 2021.10.22 对pause的兼容
    if AnimState.AnimateWhilePaused ~= nil then
        self.white:GetAnimState():AnimateWhilePaused(false)
    end
    self.white:Hide()

    self.SoundEmitter = self.inst.entity:AddSoundEmitter()

    self.alpha = 0

    self.inst:ListenForEvent('homura_lightshock_alpha', function(_, data) self:SetBlind(data.alpha) end, owner)
    self.inst:ListenForEvent('homura_lightshock_hit', function() self:OnHit() end, owner)
end)

function Flash:OnHit()
    self.inst.SoundEmitter:PlaySound('lw_homura/flashbang/hit')
end

function Flash:SetBlind(alpha)
    self.white:GetAnimState():SetMultColour(alpha, alpha, alpha, alpha)
    self.SoundEmitter:SetParameter('LOOP', 'intensity', alpha)
    if alpha > 0 then
        if self.alpha == 0 then
            self.white:Show()
            self:SetClickable(true)
            self.SoundEmitter:PlaySound('lw_homura/flashbang/loop', "LOOP")
        end
    else
        if self.alpha > 0 then
            self.white:Hide()
            self:SetClickable(false)
            self.SoundEmitter:KillSound('LOOP')
        end
    end
    self.alpha = alpha
end

-- function Flash:OnControl(ctrl, down)
--     if self.alpha > 0 then 
--         return true
--     end
-- end

return Flash