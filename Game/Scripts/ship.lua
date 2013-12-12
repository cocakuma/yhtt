require("util/vector2")
require("util/class")
require("bullet")

class("Ship")

function Ship:init(x, y, angle, team)
	self.ID = NextID()
	ships[self.ID] = self

	self.team = team

	self.verts = deepcopy(SHIP_VERTS)
	self.position = Vector2(x, y)
	self.velocity = Vector2(0,0)
	self.angle = angle --rads
	
	self.radius = 8

	self.thrustForce = TUNING.SHIP.THRUST
	self.thrust = Vector2(0,0)
	self.drag = TUNING.SHIP.DRAG
	self.turnSpeed = TUNING.SHIP.TURNSPEED

	self.thrusting = false
	self.turnLeft = false
	self.turnRight = false
	
	self.shoot = false
	self.canShoot = true
	self.canShoot_timer = TUNING.SHIP.SHOOT_COOLDOWN

	self.tryAttach = false
	self.tryDetach = false
	self.canAttach = true
	self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN

	self.children = {}
	self.parent = nil
end

function Ship:DoRotation()
	for i = 1, 3 do
		self.verts.x[i] = (SHIP_VERTS.x[i]*math.cos(self.angle)) - (SHIP_VERTS.y[i]*math.sin(self.angle))
		self.verts.y[i] = (SHIP_VERTS.x[i]*math.sin(self.angle)) + (SHIP_VERTS.y[i]*math.cos(self.angle))
	end
end

function Ship:CheckChildrenForDetachment()
	for k,v in pairs(self.children) do --Clean up any self.children that want to leave.
		if v.child then
			v.child:CheckChildrenForDetachment()
			if v.child.tryDetach then
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

	self.children[child] = {child = child, offset = offset}
	child.parent = self
	--add velocity up too
	local deltaVel = sumVelocities(child:GetChildVelocities()) + child.velocity

end

function Ship:RemoveChild(child)
	child.canAttach = false
	child.tryDetach = false
	child.parent = nil
	self.children[child] = nil
end

function Ship:AttachCooldown(dt)
	self.attach_Timer = self.canShoot_timer - dt
	if self.attach_Timer <= 0 then
		self.canAttach = true
		self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN
	end
end

function Ship:Attach()
	local pos = self.position
	for k,v in pairs(payloads) do
		if v and (v.friendly or v.neutral) then
			local distsq = pos:DistSq(v.position)
			if distsq <= (TUNING.SHIP.MAX_ATTACH_DISTANCE)^2 then
				--Congrats, you found something. Attach to it!
				local offset = v.position - pos
				v:GetChild(self, offset)
				break
			end
		end
	end

	for k,v in pairs(ships) do
		if v and v ~= self then-- and v.friendly and not false --[[IS CHILD OF ME?]] then
			local distsq = pos:DistSq(v.position)
			if distsq <= (TUNING.SHIP.MAX_ATTACH_DISTANCE)^2 then
				--Congrats, you found something. Attach to it!
				local offset = pos - v.position
				v:GetChild(self, offset)
				break
			end
		end
	end
end

function Ship:Detach()
	for k,v in pairs(self.children) do
		self:RemoveChild(v.child)
	end
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
	if love.keyboard.isDown("d") then
		self.turnLeft = true
	end
	if love.keyboard.isDown("a") then
		self.turnRight = true
	end
	if love.keyboard.isDown("w") then
		self.thrusting = true
	end
	if love.keyboard.isDown(" ") then
		self.shoot = true
	end
	if love.keyboard.isDown("f") then
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
		--self.velocity = self.velocity + self.thrust
		self:SetVelocities()
		self:ClampOffsets()
	end


	local velLen = self.velocity:Length()
	local dragdenom = 1 - (velLen * (self.drag * dt))
	local velLen = dragdenom == 0 and 0 or velLen / dragdenom
	self.velocity = velLen == 0 and Vector2(0,0) or self.velocity:GetNormalized() * velLen

	self.position = self.position + (self.velocity * dt)

	self:DoRotation()
end

function Ship:Draw()
	if self.team == 0 then
		love.graphics.setColor(55,255,155,255)
	else
		love.graphics.setColor(155,55,255,255)
	end
	love.graphics.polygon("fill", self.verts.x[1]+self.position.x,
									self.verts.y[1]+self.position.y,
									self.verts.x[2]+self.position.x,
									self.verts.y[2]+self.position.y,
									self.verts.x[3]+self.position.x,
									self.verts.y[3]+self.position.y )


	love.graphics.circle("line", self.position.x, self.position.y, self.radius)



	if false then -- draw velocity line
		love.graphics.setColor(255,0,0,255)
		love.graphics.line(self.position.x, self.position.y,
							self.position.x + self.velocity.x * 2, self.position.y + self.velocity.y * 2)
	end
end

function Ship:GetCircle()
	return Circle(self.position.x, self.position.y, self.radius)
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
