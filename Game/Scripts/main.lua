require("ship")

aShip = {}

function love.load()

	aShip = MakeShip()

end

function love.update( dt)

	aShip.update(dt)

end

function love.draw()
	
	aShip.draw()

end
