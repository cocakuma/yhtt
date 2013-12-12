require("util/vector2")
require("util/class")

class("Obstacle")

function Obstacle:init(x, y, radius)
	self.ID = NextID()
	obstacles[self.ID] = self

	self.radius = radius
	
	self.position = Vector2(x, y)
end

function Obstacle:Draw()
	love.graphics.setColor(155,155,155,255)
	love.graphics.circle("fill", self.position.x, self.position.y, self.radius)
end

function Obstacle:GetCircle()
	return Circle(self.position.x, self.position.y, self.radius)
end
