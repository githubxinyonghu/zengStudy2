local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"

local COLOURS = {
    {1, 1, 1, 0.2},
    {1, 1, 1, 1},
    {0.25, 0.0, 0.5, 1},
}

local Bar = Class(Image, function(self)
    Image._ctor(self, "images/ui.xml", "white.tex")

    self:SetHRegPoint(ANCHOR_LEFT)
    self:SetVRegPoint(ANCHOR_MIDDLE)

    self:SetLength(0)
    self:SetPercent(0)
end)

function Bar:SetLength(i)
    self.length = i
    self:SetPosition(-i/2, 0)
    if self.p then
        self:SetPercent(self.p)
    end
end

function Bar:SetPercent(p)
    p = math.clamp(p, 0, 1)
    self.p = p
    self:SetSize(self.length* p, 4)
end

local BarMeter = Class(Widget, function(self, owner)
    Widget._ctor(self, "HomuraBarMeter")
    self.owner = owner
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.root = self:AddChild(Widget("root"))
    self.root:SetClickable(false)
    self.root:SetPosition(0, 40)

    -- self.center = self.root:AddChild(Image("images/ui.xml", "white.tex"))
    -- self.center:SetSize(300,300)
    -- self.center:SetTint(0,0,1,1)

    self.basic = self.root:AddChild(Bar())
    self.charge = self.root:AddChild(Bar())
    self.magic = self.root:AddChild(Bar())

    self.bars = {self.basic, self.charge, self.magic}
    for i,v in ipairs(self.bars) do
        v:SetTint(unpack(COLOURS[i]))
    end

    self.style = nil
    self:SetStyle("hidden")

    self.inst:ListenForEvent("homuraevt_barstyle", function(_, data)
        if data and data.style then
            self:SetStyle(data.style)
        end
    end, owner)

    self.inst:ListenForEvent("homuraevt_barpercent", function(_, data)
        if data and data.percent then
            self:SetPercent(data.percent)
        end
    end, owner)

    self.inst:ListenForEvent("homura_learning_percent", function(_, data)
        if data and data.percent then
            self:SetPercent(data.percent)
        end
    end, owner)

    self.inst:ListenForEvent("homura_startlearning", function()
        self:SetStyle("reader")
    end, owner)

    self.inst:ListenForEvent("homura_stoplearning", function()
        self:SetStyle("hidden")
    end, owner)
end)

function BarMeter:SetWorldPosition(pos)
    self.pos = pos
    self:SetPosition(TheSim:GetScreenPos(self.pos:Get()))
end

function BarMeter:SetLength(i)
    for _,v in ipairs(self.bars)do
        v:SetLength(i)
    end
end

function BarMeter:SetStyle(stype)
    if self.style == stype then
        return
    end
    self.style = stype

    if stype == "reader" or stype == "charge" then
        self:Show()
        self.charge:Show()
        self.magic:Hide()
        self:SetLength(stype == "reader" and 200 or 60)
    elseif stype == "magic" then
        self:Show()
        self.magic:Show()
        self.charge:Hide()
        self:SetLength(60)
    elseif stype == "hidden" then
        self:Hide()
    else
        print("BarMeter:SetStyle() -> skip")
    end
end

function BarMeter:Show()
    self:UpdatePosition()
    self.basic:SetPercent(1)
    self:StartUpdating()
    BarMeter._base.Show(self)
end

function BarMeter:Hide()
    self:StopUpdating()
    BarMeter._base.Hide(self)
end

function BarMeter:SetPercent(p)
    p = math.clamp(p, 0, 1)
    self.charge:SetPercent(p)
    self.magic:SetPercent(p)
end

-- function BarMeter:StartTimer(duration, starttime)
--     self.t = starttime or 0
--     self.duration = duration
--     self:StartUpdating()
--     self:OnUpdate(0)
-- end

-- function BarMeter:FadeOut(duration)
--     self.fadetime = duration or .2
--     self.fade = self.fadetime
--     self.flash = nil
--     self.flashtime = nil
--     self:OnUpdate(0)
-- end

-- function BarMeter:FlashOut(duration)
--     self.meter:GetAnimState():PlayAnimation("flash")
--     self.meter:GetAnimState():SetMultColour(unpack(COLOUR))
--     self.scaletime = duration or .5
--     self.scale = self.scaletime
--     self.flashtime = math.max(0, self.scaletime - self.meter:GetAnimState():GetCurrentAnimationLength())
--     self.flash = self.flashtime
--     self.fade = nil
--     self.fadetime = nil
--     self.t = self.duration
--     self:OnUpdate(0)
-- end

function BarMeter:UpdatePosition()
    if self.owner and self.owner:IsValid() then
        self:SetPosition(TheSim:GetScreenPos((self.owner:GetPosition() + Vector3(0, 2, 0)):Get()))
    end
end

function BarMeter:OnUpdate(dt)
    if getmetatable(TheNet).__index.IsServerPaused ~= nil and TheNet:IsServerPaused() then return end

    self:UpdatePosition()

    do return end

    -- if self.fade ~= nil then
    --     self.fade = math.max(0, self.fade - dt)
    --     if self.fade > 0 then
    --         local k = self.fade / self.fadetime
    --         self.meter:GetAnimState():SetMultColour(COLOUR[1], COLOUR[2], COLOUR[3], COLOUR[4] * k * k)
    --     else
    --         self:Kill()
    --     end
    -- elseif self.flash ~= nil then
    --     self.scale = math.max(0, self.scale - dt)
    --     local k = self.scale / self.scaletime
    --     k = 1.1 - k * k * .1
    --     self.meter:SetScale(k, k)
    --     if self.meter:GetAnimState():AnimDone() then
    --         self.flash = math.max(0, self.flash - dt)
    --         if self.flash > 0 then
    --             k = self.flash / self.flashtime
    --             self.meter:GetAnimState():SetMultColour(COLOUR[1], COLOUR[2], COLOUR[3], COLOUR[4] * k * k)
    --         else
    --             self:Kill()
    --         end
    --     end
    -- else
    --     self.t = math.min(self.t + dt, self.duration)
    --     self.meter:GetAnimState():SetPercent("progress", self.t / self.duration)
    -- end
end

return BarMeter
