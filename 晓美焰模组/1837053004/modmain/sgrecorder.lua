local SGTagsToEntTags =
{
    ["attack"] = true,
    ["autopredict"] = true,
    ["busy"] = true,
    ["dirt"] = true,
    ["doing"] = true,
    ["fishing"] = true,
    ["flight"] = true,
    ["giving"] = true,
    ["hiding"] = true,
    ["idle"] = true,
    ["invisible"] = true,
    ["lure"] = true,
    ["moving"] = true,
    ["nibble"] = true,
    ["noattack"] = true,
    ["nopredict"] = true,
    ["pausepredict"] = true,
    ["sleeping"] = true,
    ["working"] = true,
    ["jumping"] = true,
}

AddGlobalClassPostConstruct('stategraph', 'StateGraphInstance', function(self)
    self.lw_sgmemorydata = {params = {}}

    local old_gotostate = self.GoToState
    function self:GoToState(newstate, p, ...)
        self.lw_nextupdatetick = nil

        local state = self.sg.states[newstate]
        if state == nil then 
            return old_gotostate(self, newstate, p, ...)
        end

        if not self.inst:HasTag("homuraTag_pause") then
            return old_gotostate(self, newstate, p, ...) 
        else
            --print(string.format('should enter state %s but stored.',newstate))
            local oldstate = self.currentstate or {}

            self.lw_sgmemorydata.onexit = oldstate.onexit
            self.lw_sgmemorydata.onenter = state.onenter
            self.lw_sgmemorydata.params = {p, ...}
            self.lw_sgmemorydata.statemem = self.statemem -- onexit函数可能会调用mem
            oldstate.onexit = function() return end
            state.onenter = function() return end

            old_gotostate(self, newstate, p, ...)
            
            oldstate.onexit = self.lw_sgmemorydata.onexit
            state.onenter = self.lw_sgmemorydata.onenter
        end
    end

    function self:Lw_TimeMagic_OnStop()
        local statemem = self.statemem 
        self.statemem = self.lw_sgmemorydata.statemem
        if self.lw_sgmemorydata.onexit then
            self.lw_sgmemorydata.onexit(self.inst)
        end
        self.statemem = statemem
        if self.lw_sgmemorydata.onenter then
            self.lw_sgmemorydata.onenter(self.inst, unpack(self.lw_sgmemorydata.params))
        end

        self.lw_sgmemorydata = {params = {}}
    end
end)
