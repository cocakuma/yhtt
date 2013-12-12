require("util/vector2")
require("util/class")
require("bullet")

class("Ship")

function Ship:init(x, y, angle, team)
	self.ID = NextID()
	ships[self.ID] = self

	self.team = team

	self.position = Vector2(x, y)
	self.velocity = Vector2(0,0)
	self.angle = angle --rads

	self.health = math.random()
	
	self.radius = 8

	self.thrustForce = TUNING.SHIP.THRUST
	self.thrust = Vector2(0,0)
	self.drag = TUNING.SHIP.DRAG
	self.turnSpeed = TUNING.SHIP.TURNSPEED

	self.thrusting = false
	self.didThrust = false;
	self.turnLeft = false
	self.turnRight = false
	
	self.shoot = false
	self.canShoot = true
	self.canShoot_timer = TUNING.SHIP.SHOOT_COOLDOWN

	self.tryAttach = false
	self.tryDetach = false
	self.wantsToDetach = false
	self.canAttach = true
	self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN

	self.children = {}
	self.parent = nil
end

function Ship:IsChildOf(parent)

	if self.parent == parent then
		return true
	end

	for k,v in pairs(self.children) do
		if v.child:IsChildOf(parent) then
			return true
		end		
	end
end

function Ship:CombineVelocities(other)

	local velDelta = Vector2(0,0)

	local other_Vel = other:GetChildVelocities()
	table.insert(other_Vel, other.velocity)

	local my_Vel = self:GetChildVelocities()
	table.insert(my_Vel, self.velocity)

	if #my_Vel > #other_Vel then
		velDelta = self.velocity - other.velocity * (#other_Vel / #my_Vel)
	else
		velDelta = other.velocity - self.velocity * (#other_Vel / #my_Vel)
	end

	print(velDelta)

	return self.velocity + velDelta
end

function Ship:CheckChildrenForDetachment()
	for k,v in pairs(self.children) do --Clean up any self.children that want to leave.
		if v.child then
			v.child:CheckChildrenForDetachment()
			if v.child.wantsToDetach == true then
				print(v.child.ID, "wants to detach from", self.ID, v.child.wantsToDetach)
				self:RemoveChild(v.child)
			end
		end
	end
end

function Ship:GetChildThrusts()
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

function Ship:GetChildVelocities()
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

function Ship:ClampOffsets()
	for k,v in pairs(self.children) do
		if v.child then
			v.child.position = self.position + v.offset
			v.child:ClampOffsets()
		end
	end
end

function Ship:SetVelocities()
	local thrust = sumThrusts(self:GetChildThrusts())
	thrust = thrust + self.thrust
	self.velocity = self.velocity + thrust
	for k,v in pairs(self.children) do
		if v.child then
			v.child.velocity = self.velocity
		end
	end
end

function Ship:GetChild(child, offset)

	print(self.ID, "got new child", child.ID)

	local newVel = self:CombineVelocities(child)

	self.children[child] = {child = child, offset = offset}
	child.parent = self
	--add velocity up too

	self.velocity = newVel
	
end

function Ship:RemoveChild(child)	
	print(self.ID, "Remove Child: ", child.ID)
	child.canAttach = false
	child.wantsToDetach = false
	child.parent = nil
	self.children[child] = nil
end

function Ship:AttachCooldown(dt)
	self.attach_Timer = self.attach_Timer - dt
	if self.attach_Timer <= 0 then
		self.canAttach = true
		self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN
	end
end

function Ship:Attach()
	local pos = self.position

	-- for k,v in pairs(payloads) do
	-- 	if v and (v.friendly or v.neutral) then
	-- 		local distsq = pos:DistSq(v.position)
	-- 		if distsq <= (TUNING.SHIP.MAX_ATTACH_DISTANCE)^2 then
	-- 			--Congrats, you found something. Attach to it!
	-- 			local offset = v.position - pos
	-- 			v:GetChild(self, offset)
	-- 			break
	-- 		end
	-- 	end
	-- end
	
	local best = nil
	local dist = TUNING.SHIP.MAX_ATTACH_DISTANCE^2
	
	for k,v in pairs(ships) do
		if v and v ~= self and not v:IsChildOf(self) then
			local distsq = pos:DistSq(v.position)
			if distsq <= dist then
				best = v
				dist = distsq
			end
		end
	end

	if best then
		local offset = pos - best.position
		best:GetChild(self, offset)
	end

	self.tryAttach = false
	self.canAttach = false
end

function Ship:Detach()
	for k,v in pairs(self.children) do
		self:RemoveChild(v.child)
	end
	self.wantsToDetach = true
end

function Ship:ShootCooldown(dt)
	self.canShoot_timer = self.canShoot_timer - dt
	if self.canShoot_timer <= 0 then
		self.canShoot = true
		self.canShoot_timer = TUNING.SHIP.SHOOT_COOLDOWN
	end
end

function Ship:Shoot()
	self.canShoot = false
	local bullet = Bullet(self)
end

function Ship:HandleInput( )
	if self.input["d"] == 1 then
		self.turnLeft = true
	end
	if self.input["a"] == 1 then
		self.turnRight = true
	end
	if self.input["w"] == 1 then
		self.thrusting = true
		self.didThrust = true
	end
	if self.input[" "] == 1 then
		self.shoot = true
	end
	if self.input["f"] == 1 then
		if not self.parent then
			self.tryAttach = true
		else
			self.tryDetach = true
		end
	end
end

function Ship:Update(dt)
	if self.turnLeft then
		self.turnLeft = false
		self.angle = self.angle + self.turnSpeed * dt
	end
	if self.turnRight then
		self.turnRight = false
		self.angle = self.angle - self.turnSpeed * dt
	end
	if self.thrusting then
		self.thrusting = false
		local thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
		local thrust = thrustVector * self.thrustForce
		self.thrust = thrust * dt
	else
		self.thrust = Vector2(0,0)
	end

	if not self.canShoot then
		self:ShootCooldown(dt)
	end

	if self.shoot and self.canShoot then
		self:Shoot()
	end
	
	self.shoot = false

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
		--Parent will do it for you otherwise!
		self:CheckChildrenForDetachment()
		self:SetVelocities()
		self:ClampOffsets()
	end

	local velLen = self.velocity:Length()
	local dragdenom = 1 - (velLen * (self.drag * dt))
	local velLen = dragdenom == 0 and 0 or velLen / dragdenom
	self.velocity = velLen == 0 and Vector2(0,0) or self.velocity:GetNormalized() * velLen

	self.position = self.position + (self.velocity * dt)
end

function Ship:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 'r', self.r)
	pkg = pack(pkg, 't', self.team)
	pkg = pack(pkg, 'a', self.angle)
	pkg = pack(pkg, 'r', self.radius)
	pkg = pack(pkg, 'h', self.health)
	pkg = pack(pkg, 'it', self.didThrust and 1 or 0) --"input: thrust"
	self.didThrust = false;
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

function Ship:Collide(other)
	local diff = self.position - other.position
	diff.x = diff.x + math.random()*0.002-0.001
	diff.y = diff.y + math.random()*0.002-0.001

	if not self.parent then
		self.velocity = self.velocity + diff:GetNormalized() * 20
	else
		self.parent.velocity = self.parent.velocity + diff:GetNormalized() * 20
	end

end

function Ship:Hit(bullet)
	self.velocity = self.velocity + bullet.velocity:GetNormalized() * 20
end
