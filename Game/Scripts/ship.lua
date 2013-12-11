require("util/vector2")
require("util/class")

class("Ship")

function Ship:init()
	self.position = Vector2(0,0)
	self.velocity = Vector2(0,0)
	self.angle = 0

	self.thrust = 10
	self.drag = 0.99

	self.thrusting = false

	self.verts = 
	{
		x = {0, 10, 5}, 
		y = {0, 0, 10}
	}

end


function Ship:HandleInput( )
	if love.keyboard.isDown("w") then
		self.thrusting = true
	end
end

function Ship:Update(dt)
	if self.thrusting then
		self.thrusting = false

		local thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
		local thrust = thrustVector * self.thrust
		thrust = thrust * dt
		self.velocity = self.velocity + thrust
	end

	self.position = self.position + (self.velocity * dt)
end

function Ship:Draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.polygon("fill", self.verts.x[1]+self.position.x,
									self.verts.y[1]+self.position.y,
									self.verts.x[2]+self.position.x,
									self.verts.y[2]+self.position.y,
									self.verts.x[3]+self.position.x,
									self.verts.y[3]+self.position.y )
end

