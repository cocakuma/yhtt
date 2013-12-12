require("util/strict")
require("constants")
require("util/util")
require("ship")
require("physics")
require("payload")
require("obstacle")
require("render")
TUNING = require("tuning")

inputID = 1

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

	for i=1,32 do
		local ship = Ship(100+20*i, 100, 0)
		ship.ID = i
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
	for k,ship in ipairs(ships) do
		if ship.ID == inputID then
			ship:HandleInput()
			Renderer:SetCameraPos(ship.position)
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
	for k=1,#ships do
		for n,obs in pairs(obstacles) do
			if Physics.OverlapCircles(ships[k]:GetCircle(), obs:GetCircle()) then
				ships[k]:Collide(obs)
			end
		end
	end


	for k=1,#ships-1 do
		for n=k+1,#ships do
			if Physics.OverlapCircles(ships[k]:GetCircle(), ships[n]:GetCircle() ) then
				ships[k]:Collide(ships[n])
				ships[n]:Collide(ships[k])
			end
		end
	end

	local bulletToRemove = {}
	for k,bullet in pairs(bullets) do
		for n=1,#ships do
			if bullet.ship ~= ships[n] and Physics.PointInCircle(bullet.position, ships[n]:GetCircle() ) then
				ships[n]:Hit(bullet)
				table.insert(bulletToRemove, bullet)
			end
		end

		for n,obs in pairs(obstacles) do
			if Physics.PointInCircle(bullet.position, obs:GetCircle() ) then
				table.insert(bulletToRemove, bullet)
			end
		end
	end

	for i,b in pairs(bulletToRemove) do
		b:Destroy()
	end
end




function love.draw()
	
	Renderer:Draw(function()

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
