require("util/vector2")
require("util/class")

class("Obstacle")

function Obstacle:init(x, y, radius)
	self.ID = NextID()
	obstacles[self.ID] = self

	self.radius = radius
	
	self.position = Vector2(x, y)
end

function Obstacle:Draw(view)
	local obstacle_view = {}
	obstacle_view.position = {self.position.x, self.position.y}
	obstacle_view.radius = self.radius
	view.obstacles[self.ID] = obstacle_view
end

function Obstacle:GetCircle()
	return Circle(self.position.x, self.position.y, self.radius)
end
