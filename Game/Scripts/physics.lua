require("util/class")
require("util/vector2")

class("Circle")
function Circle:init(x, y, rad)
	self.x = x
	self.y = y
	self.rad = rad
end

Physics = {}

function Physics.OverlapCircles( circ1, circ2 )
	local dx = circ2.x - circ1.x
	local dy = circ2.y - circ1.y
	local r = circ1.rad + circ2.rad
	return ((dx*dx) + (dy*dy)) < r*r
end
