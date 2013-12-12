require("util/vector2")
require("util/class")

class("Obstacle")

function Obstacle:init(x, y, radius)
	self.ID = NextID()
	obstacles[self.ID] = self

	self.radius = radius
	
	self.position = Vector2(x, y)
end

function Obstacle:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 'r', self.radius)
	return pkg
end