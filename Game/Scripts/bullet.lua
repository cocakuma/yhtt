require("util/vector2")
require("util/class")

class("Bullet")

function Bullet:init(ship)
	self.ID = NextID()
	bullets[self.ID] = self

	self.size = deepcopy(BULLET_SIZE)
	self.speed = TUNING.BULLET.SPEED
	
	self.ship = ship or nil
	self.position = Vector2(ship.position.x or 0, ship.position.y or 0)
	self.angle = ship.angle or 0 --rads
	self.velocity = Vector2(0,0)
	self.radius = 0
	
	local directionVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local dir = directionVector * self.speed
	self.velocity = directionVector * self.speed
end

function Bullet:Update(dt)
	self.position = self.position + (self.velocity * dt)
end

function Bullet:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 't', self.team)
	pkg = pack(pkg, 'sx', self.size.x)
	pkg = pack(pkg, 'sy', self.size.y)
	return pkg
end	

function Bullet:Destroy()
	bullets[self.ID] = nil
end
