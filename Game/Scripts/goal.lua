require("util/vector2")
require("util/class")

class("Goal")

function Goal:init(team, position, width, height)
	self.ID = NextID()
	goals[self.ID] = self

	self.team = team

	self.position = position

	self.width = width
	self.height = height

	self.left = self.position.x - self.width/2
	self.right = self.position.x + self.width/2
	self.top = self.position.y - self.height/2
	self.bottom = self.position.y + self.height/2
end

function Goal:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 'h', self.height)
	pkg = pack(pkg, 'w', self.width)
	pkg = pack(pkg, 't', self.team)
	return pkg
end

function Goal:Contains( position )
	return
		position.x > self.left and
		position.x < self.right and
		position.y > self.top and
		position.y < self.bottom
end
