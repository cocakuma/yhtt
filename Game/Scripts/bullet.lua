require("util/vector2")
require("util/class")

class("Bullet")

local bulletID = 0

function Bullet:init(ship)
	self.ID = bulletID
	bulletID = bulletID + 1

	bullets[self.ID] = self

	self.size = deepcopy(BULLET_SIZE)
	self.speed = TUNING.BULLET.SPEED
	
	self.ship = ship or nil
	self.position = Vector2(ship.position.x or 0, ship.position.y or 0)
	self.angle = ship.angle or 0 --rads
	self.velocity = Vector2(0,0)
	
	local directionVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local dir = directionVector * self.speed
	self.velocity = directionVector * self.speed
end

function Bullet:Update(dt)
	self.position = self.position + (self.velocity * dt)
end

function Bullet:Draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.rectangle("fill", self.position.x - (self.size.x * .5), self.position.y- (self.size.y * .5), BULLET_SIZE.x, BULLET_SIZE.y )
end

function Bullet:Destroy()
	bullets[self.ID] = nil
end
