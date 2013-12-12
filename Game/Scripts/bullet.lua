require("util/vector2")
require("util/class")

class("Bullet")

function Bullet:init(ship)
	self.ID = NextID()
	bullets[self.ID] = self


	self.speed = TUNING.BULLET.SPEED
	self.thrustForce = TUNING.BULLET.THRUSTFORCE
	self.thrust = Vector2(0,0)
	self.ship = ship
	self.angle = ship.angle or 0 --rads
	local offset = deepcopy(ship.shotoffset)
	offset.x = offset.x*math.cos(self.angle) - offset.y*math.sin(self.angle)
	offset.y = offset.x*math.sin(self.angle) + offset.y*math.cos(self.angle)	
	self.position = Vector2(ship.position.x or 0, ship.position.y or 0)
	self.position = self.position + offset
	self.velocity = Vector2(0,0)
	self.radius = 0
	
	local directionVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local dir = directionVector * self.speed
	self.velocity = directionVector * self.speed
	local ship_Vel = deepcopy(ship.velocity)
	--ship.velocity = ship.velocity - (self.velocity * 2)
	self.velocity = ship_Vel + ship.velocity
end

function Bullet:Update(dt)

	local thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local thrust = thrustVector * self.thrustForce
	self.thrust = thrust * dt

	self.velocity = self.velocity + self.thrust

	self.position = self.position + (self.velocity * dt)
end

function Bullet:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 't', self.ship.team)
	pkg = pack(pkg, 'a', self.angle)
	return pkg
end	

function Bullet:Destroy()
	bullets[self.ID] = nil
end
