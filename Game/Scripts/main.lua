require("util/strict")
require("constants")
require("util/util")
require("ship")
TUNING = require("tuning")


inputID = 1

function love.load()
	for i=1,32 do
		local ship = Ship()
		ship.ID = i
		table.insert(ships, ship)
	end
end

function love.update( dt)
	for k,ship in pairs(ships) do
		if ship.ID == inputID then
			ship:HandleInput()
		end
		ship:Update(dt)
	end
end

function love.draw()
	for k,ship in pairs(ships) do
		ship:Draw()
	end
end
