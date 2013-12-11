require("util/strict")
require("ship")

aShip = {}

function love.load()

	aShip = MakeShip()

end

function love.update( dt)

	aShip.handleInput()
	aShip.update(dt)

end

function love.draw()
	
	aShip.draw()

end
