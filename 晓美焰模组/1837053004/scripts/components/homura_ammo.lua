local HomuraAmmo = Class(function(self, inst)
    self.inst = inst
end)

function HomuraAmmo:OnConsume(num)
    local instance = self.inst.components.stackable:Get(num)
    if instance then 
        instance:Remove()
    else
        self.inst:Remove()
    end
end

return HomuraAmmo