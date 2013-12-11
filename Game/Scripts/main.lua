require("util/strict")
require("ship")

aShip = {}

function love.load()

	aShip = Ship()

end

function love.update( dt)

	aShip:HandleInput()
	aShip:Update(dt)

end

function love.draw()
	
	aShip:Draw()

end
