require("util/strict")
require("constants")
require("util/util")
require("ship")
require("physics")
require("payload")
require("obstacle")
require("render")
require("arena")
TUNING = require("tuning")

inputID = -1

arena = {}
ships = {}
bullets = {}
payloads = {}
obstacles = {}

ENT_ID = 0
function NextID()
	ENT_ID = ENT_ID + 1
	return ENT_ID
end
	

function love.load()
	Renderer:Load()

	arena = Arena(1600, 1600)

	for i=1,32 do
		local ship = Ship(100+20*i, 100, 0)
		if inputID == -1 then
			inputID = ship.ID
		end
	end

	for i=1,3 do
		local pl = Payload(math.random() * 640, math.random() * 860)
		table.insert(payloads, pl)
	end
	
	for i=1,10 do
		Obstacle()
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
	for k,ship in pairs(ships) do
		if ship.ID == inputID then
			ship:HandleInput()
			Renderer:SetCameraPos(ship.position)
		end
	end


	-- update
	-- handle input, apply physics, gameplay
	for k,ship in pairs(ships) do
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
	for k,ship in pairs(ships) do
		for n,obs in pairs(obstacles) do
			if Physics.OverlapCircles(ship:GetCircle(), obs:GetCircle()) then
				ship:Collide(obs)
			end
		end
	end


	-- this is n^2 right now, yucky!
	for k, ship1 in pairs(ships) do
		for n, ship2 in pairs(ships) do
			if (n ~= k) then
				if Physics.OverlapCircles(ship1:GetCircle(), ship2:GetCircle() ) then
					ship1:Collide(ship2)
				end
			end
		end

		local oob = arena:OOB( ship1.position )
		if oob then
			ship1.position = ship1.position + oob
			ship1.velocity = ship1.velocity * -1
		end
	end

	local bulletToRemove = {}
	for k,bullet in pairs(bullets) do
		local hit = false
		if arena:OOB( bullet.position ) then
			table.insert(bulletToRemove, bullet)
			hit = true
		end

		if not hit then
			for k, ship in pairs(ships) do
				if bullet.ship ~= ship and Physics.PointInCircle(bullet.position, ship:GetCircle() ) then
					ship:Hit(bullet)
					table.insert(bulletToRemove, bullet)
					hit = true
				end
			end
		end

		if not hit then
			for n,obs in pairs(obstacles) do
				if Physics.PointInCircle(bullet.position, obs:GetCircle() ) then
					table.insert(bulletToRemove, bullet)
					hit = true
				end
			end
		end
	end

	for i,b in pairs(bulletToRemove) do
		b:Destroy()
	end
end




function love.draw()
	
	Renderer:Draw(function()
		
		arena:Draw()

		for k,obs in pairs(obstacles) do
			obs:Draw()
		end

		for k,ship in pairs(ships) do
			ship:Draw()
		end

		for k,bullet in pairs(bullets) do
			bullet:Draw()
		end

		for k,pl in pairs(payloads) do
			pl:Draw()
		end

	end)

end
