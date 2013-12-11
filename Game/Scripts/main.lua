require("util/strict")
require("constants")
require("util/util")
TUNING = require("tuning")
require("ship")
require("bullet")

aShip = {}
aBullet = {}

function love.load()

	aShip = Ship()
	aBullet = Bullet(nil, 100, 100, 0)

end

function love.update( dt)

	aShip:HandleInput()
	aShip:Update(dt)
	aBullet:Update(dt)

end

function love.draw()
	
	aShip:Draw()
	aBullet:Draw()

end
