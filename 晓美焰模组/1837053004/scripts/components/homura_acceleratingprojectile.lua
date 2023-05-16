local AcceleratingProjectile = Class(function(self, inst)
	
    self.inst = inst
    self.speedup = false
    self.a = 1.03
    self.maxspeed = 100
    self.speed = 0
    
end)

function AcceleratingProjectile:SetComponentSpeed(s)
    self.inst.components.projectile:SetSpeed(s)
end

function AcceleratingProjectile:SetSpeed(s)
    self.inst.Physics:SetMotorVel(s,0,0)
    self.speed = s
end

function AcceleratingProjectile:GetPhysicsSpeed()
    return self.inst.Physics:GetMotorVel()
end

function AcceleratingProjectile:GetSpeedRate(rate)
    if self.ori_speed then
       -- print((self:GetPhysicsSpeed()/self.ori_speed-1)*rate+1)
        return (self:GetPhysicsSpeed()/self.ori_speed-1)*rate+1
    end
    return 1
end

function AcceleratingProjectile:Launch(attacker,target)
    local speed = self:GetPhysicsSpeed()
    self:SetComponentSpeed(speed)
    self.inst.components.projectile.launchoffset = Vector3(0,0,0)
    self.inst.components.projectile:Throw(attacker,target,self.inst)
    self.ori_speed = speed
    self.speedup = true
    self.inst:StartUpdatingComponent(self)
    if self.onlaunch then
        self.onlaunch(self.inst,attacker,target)
    end
end

function AcceleratingProjectile:StartUpdating()
    self.speedup = true
    self.ori_speed = self.inst.components.projectile.speed
    self.inst:StartUpdatingComponent(self)
end

function AcceleratingProjectile:OnUpdate(dt)
    if self.speedup then
        local speed = self:GetPhysicsSpeed()
        if speed >= self.maxspeed then
            self.speedup = false
        else
            local newspeed = speed * self.a
            self:SetSpeed(newspeed)
        end
    end   
end

function AcceleratingProjectile:OnSave()
    return {speed = self:GetPhysicsSpeed(),speedup = self.speedup}
end

function AcceleratingProjectile:OnLoad(data)
    if data then
        self:SetSpeed(data.speed)
        if data.speedup then 
            self:StartUpdating()
        end
    end
end

return AcceleratingProjectile
