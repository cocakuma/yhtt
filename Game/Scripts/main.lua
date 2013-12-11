require("util/strict")
require("constants")
require("util/util")
require("ship")
require("physics")
require("payload")
TUNING = require("tuning")

inputID = 1

ships = {}
bullets = {}
payloads = {}

function love.load()
	for i=1,32 do
		local ship = Ship(100+10*i, 100, 0)
		ship.ID = i
		table.insert(ships, ship)
	end

	for i=1,3 do
		local pl = Payload(math.random() * 640, math.random() * 860)
		table.insert(payloads, pl)
	end
end

paused = false

function love.keypressed(key)
	if key == "p" then
		paused = not paused
	end
end

function love.update( dt)
	if paused then
		return
	end

	-- pre-update
	-- check input and synchronize states
	for k,ship in ipairs(ships) do
		if ship.ID == inputID then
			ship:HandleInput()
		end
	end


	-- update
	-- handle input, apply physics, gameplay
	for k,ship in ipairs(ships) do
		ship:Update(dt)
	end

	for k,bullet in pairs(bullets) do
		bullet:Update(dt)
	end

	for k,pl in pairs(payloads) do
		pl:Update(dt)
	end


	-- post-update
	-- perform collisions, spawn/despawn entities
	print("\n\nPHYSICS!!!\n")
	for k=1,#ships-1 do
		for n=k+1,#ships do
			if Physics.OverlapCircles(ships[k]:GetCircle(), ships[n]:GetCircle() ) then
				print("colliding ",k,"<+>",n)
				ships[k]:Collide(ships[n])
				ships[n]:Collide(ships[k])
			end
		end
	end
end




function love.draw()
	for k,ship in pairs(ships) do
		ship:Draw()
	end

	for k,bullet in pairs(bullets) do
		bullet:Draw()
	end

	for k,pl in pairs(payloads) do
		pl:Draw()
	end

end
