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
	
	local directionVector = Vector2(math.cos(self.angle), math.sin(self.angle))
	local dir = directionVector * self.speed
	self.velocity = directionVector * self.speed
end

function Bullet:Update(dt)
	self.position = self.position + (self.velocity * dt)
end

function Bullet:Draw(view)
	local bullet_view = {}
	if self.ship.team == 0 then
		bullet_view.color = {155,255,155,255}
	else
		bullet_view.color = {155,255,155,255}
	end
	
	bullet_view.position = {self.position.x, self.position.y}
	bullet_view.size = {self.size.x, self.size.y}
	
	view.bullets[self.ID] = bullet_view
end

function Bullet:Destroy()
	bullets[self.ID] = nil
end
