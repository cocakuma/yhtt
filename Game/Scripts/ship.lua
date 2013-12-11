function MakeShip()
	ship = {}

	ship.velocity = 
	{
		x = 50, 
		y = 50
	}

	ship.verts = 
	{
		x = {0, 10, 5}, 
		y = {0, 0, 10}
	}

	ship.update = function(dt)
		for k,v in pairs(ship.velocity) do			
			for i = 1, 3 do
				ship.verts[k][i] = ship.verts[k][i] + v * dt
			end			
		end
	end

	ship.draw = function()
		love.graphics.setColor(255,255,255,255)
		love.graphics.polygon("fill", ship.verts.x[1], ship.verts.y[1], ship.verts.x[2], ship.verts.y[2],ship.verts.x[3], ship.verts.y[3] )
	end

	return ship
end

