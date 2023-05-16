local function ForceGetAnimData(inst)
    local str = inst.entity:GetDebugString()
    local i1 = str:find('AnimState: ')
    if not i1 then
        print("WARNING: This inst does not have animstate!")
        return
    end

    local str_AnimState = str:sub(i1)

    local i2 = str_AnimState:find(' bank: ')
    local i3 = str_AnimState:find(' build: ')
    local i4 = str_AnimState:find(' anim: ')
    local i5 = str_AnimState:find(' anim/') --动画资源, 如果不是anim内的会get不到

    local bank = str_AnimState:sub(i2+7,i3-1)
    local build = str_AnimState:sub(i3+8,i4-1)
    local anim = str_AnimState:sub(i4+7,i5-1)

    return bank,build,anim
end


local AnimStateManager = Class(function(self, inst)
    self.lastanim = ""
    self.anim = ""
    self.bank = ""
    self.build = ""
    self.symbols = {}
    self.hiddensymbols = {}
    self.overridebuilds = {}

    if inst.AnimState then
        self.bank, self.build, self.anim = ForceGetAnimData(inst)
    end

    inst:DoTaskInTime(0,function(inst)
        inst.entity:AddAnimState()
    end)
end)


function AnimStateManager:PlayAnimation(anim,loop)
    self.lastanim = self.anim
    self.anim = anim
    self.loop = loop
end

function AnimStateManager:OverrideSymbol(override, build, symbol)
    self.symbols[override] = {build=build,symbol=symbol,}
end

function AnimStateManager:ClearOverrideSymbol(symbol)
    self.symbols[symbol] = nil
end

function AnimStateManager:Hide(symbol)
    self.hiddensymbols[symbol] = true
end

function AnimStateManager:Show(symbol)
    self.hiddensymbols[symbol] = false
end

function AnimStateManager:SetBank(bank)
    self.bank = bank
end

function AnimStateManager:SetBuild(build)
    self.build = build
end

function AnimStateManager:AddOverrideBuild(build)
    self.overridebuilds[build] = true
end

function AnimStateManager:ClearOverrideBuild(build)
    self.overridebuilds[build] = nil
end

function AnimStateManager:SetEntityAnimState(inst)
    local anim = inst.entity:AddAnimState()
    anim:SetBank(self.bank)
    anim:SetBuild(self.build)
    for k,v in pairs(self.overridebuilds)do
        anim:AddOverrideBuild(k)
    end
    for k,v in pairs(self.symbols)do
        anim:OverrideSymbol(k,v.build,v.symbol)
    end
    for k,v in pairs(self.hiddensymbols)do
        anim:Hide(k)
    end
end


return AnimStateManager
