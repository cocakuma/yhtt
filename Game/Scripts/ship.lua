require("util/vector2")
require("util/class")
require("bullet")

class("Ship")

function Ship:init(x, y, angle)
	self.ID = NextID()
	ships[self.ID] = self

	self.verts = deepcopy(SHIP_VERTS)
	self.position = Vector2(x, y)
	self.velocity = Vector2(0,0)
	self.angle = angle --rads
	
	self.radius = 8

	self.thrust = TUNING.SHIP.THRUST
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
	self.attached = false
	self.attach_Timer = TUNING.SHIP.ATTACH_COOLDOWN

	self.children = {}
end

function Ship:DoRotation()
	for i = 1, 3 do
		self.verts.x[i] = (SHIP_VERTS.x[i]*math.cos(self.angle)) - (SHIP_VERTS.y[i]*math.sin(self.angle))
		self.verts.y[i] = (SHIP_VERTS.x[i]*math.sin(self.angle)) + (SHIP_VERTS.y[i]*math.cos(self.angle))
	end
end

function Ship:PollChildren()
	for k,v in pairs(children) do --Clean up any children that want to leave.
		if v.child then
			v.child:PollChildren()
			if v.child.tryDetach then
				self:RemoveChild(v.child)
			end
		end
	end

	local c_Thrusts = {}

	for k,v in pairs(children) do
		if v.child and v.child.velocity then
			local vels = child:PollChildren()
			for k,v in pairs(vels) do
				table.insert(c_Thrusts, v)
			end
		end
	end
	return c_Thrusts
end

function Ship:GetChild(child, offset)

	self.children[child] = {child = child, offset = offset}

end

function Ship:RemoveChild(child)
	child.attached = false
	child.canAttach = false
	child.tryDetach = false
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
	pos = self.position
	for k,v in pairs(payloads) do
		if v and (v.friendly or v.neutral) then
			local distsq = pos:DistSq(v.position)
			if distsq <= (TUNING.SHIP.MAX_ATTACH_DIST)^2 then
				--Congrats, you found something. Attach to it!
				local offset = v.position - pos
				v:GetChild(self, offset)
				return
			end
		end
	end

	for k,v in pairs(ships) do
		if v and v.friendly and not false --[[IS CHILD OF ME?]] then
			local distsq = pos:DistSq(v.position)
			local distsq = pos:DistSq(v.position)
			if distsq <= (TUNING.SHIP.MAX_ATTACH_DIST)^2 then
				--Congrats, you found something. Attach to it!
				local offset = v.position - pos
				v:GetChild(self, offset)
				return
			end
		end
	end
end

function Ship:Detach()
	for k,v in pairs(children) do
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
		if not self.attached then
			self.lookForAttach = true
		else
			self.detach = true
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
		local thrust = thrustVector * self.thrust
		thrust = thrust * dt
		self.velocity = self.velocity + thrust
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


	local velLen = self.velocity:Length()
	local dragdenom = 1 - (velLen * (self.drag * dt))
	local velLen = dragdenom == 0 and 0 or velLen / dragdenom
	self.velocity = velLen == 0 and Vector2(0,0) or self.velocity:GetNormalized() * velLen

	self.position = self.position + (self.velocity * dt)

	self:DoRotation()
end

function Ship:Draw()
	love.graphics.setColor(255,255,255,255)
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
	self.velocity = self.velocity + diff:GetNormalized() * 20
end

function Ship:Hit(bullet)
	self.velocity = self.velocity + bullet.velocity:GetNormalized() * 20
end
