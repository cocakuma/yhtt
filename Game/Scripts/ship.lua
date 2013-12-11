require("util/vector2")
require("util/class")

class("Ship")


function Ship:init()
	self.position = Vector2(100,100)
	self.velocity = Vector2(0,0)
	self.angle = 0 --rads

	self.thrust = TUNING.SHIP.THRUST
	self.drag = TUNING.SHIP.DRAG
	self.turnSpeed = TUNING.SHIP.TURNSPEED

	self.thrusting = false
	self.turnLeft = false
	self.turnRight = false

	self.verts = 
	{
		x = {-5, -5, 5}, 
		y = {-3, 3, 0}
	}

end

function Ship:DoRotation()
	for i = 1, 3 do
		self.verts.x[i] = (SHIP_VERTS.x[i]*math.cos(self.angle)) - (SHIP_VERTS.y[i]*math.sin(self.angle))
		self.verts.y[i] = (SHIP_VERTS.x[i]*math.sin(self.angle)) + (SHIP_VERTS.y[i]*math.cos(self.angle))
	end
end

function Ship:HandleInput( )
	if love.keyboard.isDown("a") then
		self.turnLeft = true
	end
	if love.keyboard.isDown("d") then
		self.turnRight = true
	end
	if love.keyboard.isDown("w") then
		self.thrusting = true
	end
end

function Ship:Update(dt)
	if self.turnLeft then
		self.turnLeft = false
		self.angle = self.angle + self.turnSpeed * dt
	end
	if self.turnRight then
		self.turnRight = false
		self.angle = self.angle - self.turnSpeed * dt
	end
	if self.thrusting then
		self.thrusting = false

		local thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
		local thrust = thrustVector * self.thrust
		thrust = thrust * dt
		self.velocity = self.velocity + thrust
	end

	local dragdenom = Vector2(1 - (self.velocity.x * (self.drag * dt)),
								1 - (self.velocity.y * (self.drag * dt))
								)
	self.velocity.x = dragdenom.x == 0 and 0 or self.velocity.x / dragdenom.x
	self.velocity.y = dragdenom.y == 0 and 0 or self.velocity.y / dragdenom.y
	print("vel", self.velocity)

	self.position = self.position + (self.velocity * dt)

	print("pos", self.position)

	
	self:DoRotation()
end

function Ship:Draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.polygon("fill", self.verts.x[1]+self.position.x,
									self.verts.y[1]+self.position.y,
									self.verts.x[2]+self.position.x,
									self.verts.y[2]+self.position.y,
									self.verts.x[3]+self.position.x,
									self.verts.y[3]+self.position.y )
	love.graphics.setColor(255,0,0,255)
	love.graphics.line(self.position.x, self.position.y,
						self.position.x + self.velocity.x * 10, self.position.y + self.velocity.y * 10)
end

