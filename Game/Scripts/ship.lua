--require("util/vector2")

function HandleInput( self )
	if love.keyboard.isDown("w") then
		self.thrusting = true
	end
end

function Update(self, dt)
	if self.thrusting then
		self.thrusting = false

		--thrustVector = Vector2(math.cos(self.angle), math.sin(self.angle))
		--thrust = thrustVector * self.thrust
		--thrust = thrust * dt
		--self.velocity = self.velocity + thrust
	end

	--ship.position = ship.position + (ship.velocity + dt)
end

function MakeShip()
	ship = {}

	ship.position = {x=0,y=0}
	ship.velocity = {x=0,y=0}
	ship.angle = 0

	ship.thrust = 10
	ship.drag = 0.99

	ship.thrusting = false

	ship.handleInput = function() HandleInput(ship) end
	ship.update = function(dt) Update(ship, dt) end


	ship.verts = 
	{
		x = {0, 10, 5}, 
		y = {0, 0, 10}
	}

	
	ship.draw = function()
		love.graphics.setColor(255,255,255,255)
		love.graphics.polygon("fill", ship.verts.x[1]+ship.position.x,
										ship.verts.y[1]+ship.position.y,
										ship.verts.x[2]+ship.position.x,
										ship.verts.y[2]+ship.position.y,
										ship.verts.x[3]+ship.position.x,
										ship.verts.y[3]+ship.position.y )
	end

	return ship
end

