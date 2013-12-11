require("util/vector2")
require("util/class")

class("Payload")

function Payload:init(x, y)
	self.rad = PAYLOAD_SIZE.rad
	self.mass = TUNING.PAYLOAD.MASS
	
	self.position = Vector2(x or 0, y or 0)
	self.angle = 0 --rads
	self.velocity = Vector2(0,0)
end

function Payload:Update(dt)
	self.position = self.position + (self.velocity * dt)
end

function Payload:Draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.circle("fill", self.position.x - (self.rad * .5), self.position.y - (self.rad * .5), PAYLOAD_SIZE.rad, PAYLOAD_SIZE.segs )
end