require("util/vector2")
require("util/class")

class("Bullet")

function Bullet:init(ship)
	self.ID = NextID()
	bullets[self.ID] = self


	self.particle_type = 0

	self.speed = TUNING.BULLET.SPEED
	self.thrustForce = TUNING.BULLET.THRUSTFORCE
	self.thrust = Vector2(0,0)
	self.ship = ship
	self.angle = ship.angle or 0 --rads
	self.team = ship.team

	self.angle = self.angle + (math.random() * TUNING.BULLET.RAND/2) - (math.random() * TUNING.BULLET.RAND)

	local offset = deepcopy(ship.shotoffset)
	offset.x = ship.shotoffset.x*math.cos(self.angle) - ship.shotoffset.y*math.sin(self.angle)
	offset.y = ship.shotoffset.x*math.sin(self.angle) + ship.shotoffset.y*math.cos(self.angle)	
	self.position = Vector2(ship.position.x or 0, ship.position.y or 0)
	self.position = self.position + offset
	self.velocity = Vector2(0,0)
	self.radius = 0
	self.turnSpeed = 3
	
	local directionVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local dir = directionVector * self.speed
	self.velocity = directionVector * self.speed
	self.velocity = ship.velocity + self.velocity

	self.target = self:LookForTarget()
end

function Bullet:LookForTarget()
	local bestTar = nil
	local bestDist = 300^2
	local bestDot = 0.8
	
	for k,v in pairs(bodies) do
		if v and not v:IsOnTeam(self.team) then
			local toTar = v.position - self.position
			local vec = Vector2(math.cos(self.angle), math.sin(self.angle))
			local dot = vec:Dot(toTar)
			dot = dot / (vec:Length() * toTar:Length())
			local dist = distsq(self.position, v.position)
			if dot > bestDot and dist <= bestDist then
				if dist <= bestDist then
					bestDist = dist
					bestDot = dot
					bestTar = v
				end
			end
		end
	end	

	return bestTar
end

function Bullet:Update(dt)

	self.target = self:LookForTarget()

	if self.target then		

		local targetAngle =  math.atan2(self.target.position.y - self.position.y, self.target.position.x - self.position.x)
		print(self.angle - targetAngle)
		local delta = (self.angle - targetAngle) * 8

		delta = math.min(delta, math.pi)
		delta = math.max(delta, -math.pi)

		if delta < 0 then
			self.angle = self.angle + self.turnSpeed * dt
		else
			self.angle = self.angle - self.turnSpeed * dt
		end

	end

	local thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local thrust = thrustVector * self.thrustForce
	self.thrust = thrust * dt

	self.velocity = self.velocity + self.thrust

	self.position = self.position + (self.velocity * dt)
end

function Bullet:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 't', self.team)
	pkg = pack(pkg, 'a', self.angle)
	return pkg
end	

function Bullet:Destroy()
	ParticleSystem(self)
	bullets[self.ID] = nil
end
