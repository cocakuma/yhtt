require("util/vector2")
require("util/class")

class("Payload")

function Payload:init(x, y)
	self.rad = PAYLOAD_SIZE.rad
	self.mass = TUNING.PAYLOAD.MASS
	
	self.position = Vector2(x or 0, y or 0)
	self.velocity = Vector2(0,0)
	self.angle = 0 --rads

	self.PAYLOAD_STATE = "NEUTRAL"

end

function Payload:Update(dt)
	self.position = self.position + (self.velocity * dt)
end

function Payload:Pack(pkg)
	pkg = pack(pkg, 'x', self.position.x)
	pkg = pack(pkg, 'y', self.position.y)
	pkg = pack(pkg, 'r', self.rad)
	return pkg	
end