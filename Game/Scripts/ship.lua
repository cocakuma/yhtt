
function MakeShip()
	ship = {}

	ship.x = 0
	ship.y = 0

	ship.update = function(dt)
		ship.x = ship.x + 100*dt
	end
	ship.draw = function()
		love.graphics.setColor(255,255,255,255)
		love.graphics.rectangle( "fill", ship.x-3, ship.y-3, 6, 6 )
	end

	return ship

end

