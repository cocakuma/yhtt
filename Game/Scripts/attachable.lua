require("util/vector2")
require("util/class")
require("particlesystem")

class("Attachable")

function Attachable:init(x, y, radius, mass)
	-- this is to allow ships to override their ID
	if self.ID == nil then
		self.ID = NextID()
	end
	bodies[self.ID] = self
	
	self.radius = radius
	self.mass = mass
	self.drag = TUNING.SHIP.DRAG
	
	self.position = Vector2(x or 0, y or 0)
	self.velocity = Vector2(0,0)
	self.thrust = Vector2(0,0)
	self.angle = 0 --rads

	self.team = -1

	self.tryAttach = false
	self.tryDetach = false
	self.wantsToDetach = false
	self.canAttach = true
	self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN

	self.children = {}
	self.parent = nil

end

function Attachable:GetMass()
	local m = self.mass
	for k,v in pairs(self.children) do
		m = m + v.child:GetMass()
	end
	return m
end

function Attachable:Update(dt)

	if not self.canAttach then
		self:AttachCooldown(dt)
	end

	if self.tryAttach and self.canAttach then
		self:Attach()
	elseif self.tryDetach and self.canAttach then
		self:Detach()
	end

	self.tryAttach = false
	self.tryDetach = false

	if not self.parent then
		self:CheckChildrenForDetachment()
		self:SetVelocities()
		local velLen = self.velocity:Length()
		local dragdenom = 1 - (velLen * (self.drag * dt))
		local velLen = dragdenom == 0 and 0 or velLen / dragdenom
		self.velocity = velLen == 0 and Vector2(0,0) or self.velocity:GetNormalized() * velLen
		self.position = self.position + (self.velocity * dt)		
		self:ClampOffsets()
	else
		self:ClampOffset()
	end

end

function Attachable:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 'r', self.radius)
	pkg = pack(pkg, 't', self.team)
	pkg = pack(pkg, 'p', self:HasParent() and 1 or 0)
	pkg = beginpacktable(pkg, 'l')
	for k,v in pairs(self.children) do
		pkg = beginpacktable(pkg, k)
		pkg = pack(pkg, 'x', v.child.position.x)
		pkg = pack(pkg, 'y', v.child.position.y)		
		pkg = endpacktable(pkg)
	end	
	pkg = endpacktable(pkg)
	return pkg	
end

function Attachable:IsChildOf(parent)

	if self.parent == parent then
		return true
	end

	for k,v in pairs(self.children) do
		if v.child:IsChildOf(parent) then
			return true
		end		
	end
end

function Attachable:CombineVelocities(other)

	local velDelta = Vector2(0,0)

	local other_Vel = other:GetChildVelocities()
	table.insert(other_Vel, other.velocity)

	local my_Vel = self:GetChildVelocities()
	table.insert(my_Vel, self.velocity)

	local velDelta = self.velocity * self:GetMass()
	local otherDelta = other.velocity * other:GetMass()
	local newVelocity = (velDelta+otherDelta) / (self:GetMass()+other:GetMass())
	--print("final", newVelocity)

	return newVelocity
end

function Attachable:CheckChildrenForDetachment()
	for k,v in pairs(self.children) do --Clean up any self.children that want to leave.
		if v.child then
			v.child:CheckChildrenForDetachment()
			if v.child.wantsToDetach == true then
				print(v.child.ID, "wants to detach from", self.ID, v.child.wantsToDetach)
				self:RemoveChild(v.child)
				if self.OnDetached then
					self:OnDetached(v.child)
				end
				if v.child.OnDetached then
					v.child:OnDetached(self)
				end
			end
		end
	end
end

function Attachable:GetTrueParent()
	if not self.parent then 
		return self
	else
		if self.parent and not self.parent.parent then
			return self.parent
		else
			return self.parent:GetTrueParent()
		end
	end
end

function Attachable:GetChildVelocities()
	local c_Vels = {}
	for k,v in pairs(self.children) do
		if v.child then
			local vels = v.child:GetChildVelocities()
			table.insert(vels, v.child.velocity)
			for k,v in pairs(vels) do
				table.insert(c_Vels, v)
			end
		end
	end
	return c_Vels
end

function Attachable:GetChildThrusts()
	local c_Thrusts = {}
	for k,v in pairs(self.children) do
		if v.child then
			local thrusts = v.child:GetChildThrusts()
			table.insert(thrusts, v.child.thrust)
			for k,v in pairs(thrusts) do
				table.insert(c_Thrusts, v)
			end
		end
	end
	return c_Thrusts
end

function Attachable:ClampOffsets()
	for k,v in pairs(self.children) do
		if v.child then
			v.child:ClampOffset()
			v.child:ClampOffsets()
		end
	end
end

function Attachable:ClampOffset()
	if self.parent then
		self.position = self.parent.position + self.parent.children[self].offset
	end
end

function Attachable:SetVelocities(override)
	if override then
		self.velocity = override
	else
		local childthrusts = self:GetChildThrusts()
		local thrust = sumThrusts(childthrusts)
		thrust = thrust + self.thrust
		self.velocity = self.velocity + (thrust / self:GetMass())
	end
	for k,v in pairs(self.children) do
		if v.child then
			v.child.velocity = self.velocity
		end
	end
end

function Attachable:GetChild(child, offset)

	print(self.ID, "got new child", child.ID)

	local newVel = self:CombineVelocities(child)

	self.children[child] = {child = child, offset = offset}
	child.parent = self
	--add velocity up too

	self.velocity = newVel
	
end

function Attachable:RemoveChild(child)	
	print(self.ID, "Remove Child: ", child.ID)
	child.canAttach = false
	child.wantsToDetach = false
	child.parent = nil
	self.children[child] = nil
end

function Attachable:AttachCooldown(dt)
	self.attach_Timer = self.attach_Timer - dt
	if self.attach_Timer <= 0 then
		self.canAttach = true
		self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN
	end
end

function Attachable:Attach()
	if not self.canAttach then
		return
	end

	local pos = self.position
	
	local best = nil
	local dist = TUNING.SHIP.MAX_ATTACH_DISTANCE^2

	for k,v in pairs(bodies) do
		if v and v ~= self and v:IsOnTeam(self.team) and not v:IsChildOf(self) then
			local distsq = pos:DistSq(v.position)
			if v._classname == "Payload" then
				if distsq <= TUNING.SHIP.MAX_ATTACH_DISTANCE^2 then
					best = v
					dist = distsq
				end
			elseif not best or best._classname ~= "Payload" then
				if distsq <= dist then
					best = v
					dist = distsq
				end
			end
		end
	end

	if best then
		local offset = pos - best.position
		self.se_attach = true
		best:GetChild(self, offset)
		if best.OnAttached then
			best:OnAttached(self)
		end
		if self.OnAttached then
			self:OnAttached(best)
		end
	end

	self.tryAttach = false
	self.canAttach = false
end

function Attachable:IsOnTeam(otherteam)
	return self.team == -1 or otherteam == -1 or self.team == otherteam
end

function Attachable:Detach()
	for k,v in pairs(self.children) do
		self.se_detach = true
		self:RemoveChild(v.child)
		if self.OnDetached then
			self:OnDetached(v.child)
		end
		if v.child.OnDetached then
			v.child:OnDetached(self)
		end
	end
	self.wantsToDetach = true
end

function Attachable:HasParent()
	return self.parent ~= nil
end
