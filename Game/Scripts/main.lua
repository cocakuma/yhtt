require("util/strict")
require("constants")
require("util/util")
require("util/mathutil")
require("ship")
require("physics")
require("payload")
require("obstacle")
require("render")
require("arena")
require("network")
local serpent = require("util/serpent")
TUNING = require("tuning")

arena = {}
ships = {}
bullets = {}
payloads = {}
obstacles = {}

gServer = nil
gClient = nil

local gRemoteView = nil

ENT_ID = 0
function NextID()
	ENT_ID = ENT_ID + 1
	return ENT_ID
end
	

function love.load()
	gServer = startserver()
	gClient = startclient()

	Renderer:Load()

	arena = Arena(1600, 1600)

	for i=1,32 do
		local ship = Ship(100+20*i, 100, 0)
		ship.input = defaultinput()
	end

	for i=1,3 do
		local pl = Payload(math.random() * 640, math.random() * 860)
		table.insert(payloads, pl)
	end
	
	GenerateLevel()
end

function GenerateLevel()
	local mirror = math.random() < 0.5
	for i=1,10 do
		local pos = Vector2(math.random()*arena.width, math.random()*arena.height)
		local rad = math.random()*100+40
		Obstacle(pos.x, pos.y, rad)
		Obstacle(arena.width-pos.x, (mirror and arena.height-pos.y or pos.y), rad)
	end
end


paused = false

function love.keypressed(key)
	if key == "p" then
		paused = not paused
	end
end

function defaultinput()
	local keys = { 'd', 'a', 'w', ' ', 'f' }
	local input = {}
	for i,k in pairs(keys) do
		input[k] = false
	end	
	return input
end

function sendinput(client)
	local input = defaultinput()
	for k,v in pairs(input) do
		input[k] = love.keyboard.isDown(k)
	end
	senddata(gClient, input)
end

function receiveinput(client)
	local message = nextmessage(client)
	while message do
		local input = unpack(message)
		message = nextmessage(client)
		if not client.ID then
			local ship = Ship(10, 10, 0)
			client.ID = ship.ID	
		end
		ships[client.ID].input = input
	end	
end

function love.update( dt)
	if paused then
		return
	end

	updateserver(gServer)
	updateclient(gClient)

	for i,client in pairs(gServer.clients) do
		receiveinput(client)		
	end	

	sendinput(gClient)

	-- pre-update
	-- check input and synchronize states
	for k,ship in pairs(ships) do
		ship:HandleInput()
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

			if not ship1.parent then
				ship1.position = ship1.position + oob
				ship1.velocity = ship1.velocity * -1
			else
				ship1.parent.position = ship1.position + oob + (ship1.parent.position - ship1.position)
				ship1.parent:ClampOffsets()
				ship1.parent.velocity = ship1.velocity * -1
			end

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

		local local_view = {}
		local_view.ships = {}
		local_view.bullets = {}

		for k,obs in pairs(obstacles) do
			obs:Draw()
		end

		arena:Draw()

		for k,ship in pairs(ships) do
			ship:Draw(local_view)
		end

		for k,bullet in pairs(bullets) do
			bullet:Draw(local_view)
		end

		for k,pl in pairs(payloads) do
			pl:Draw()
		end

		
		for i,client in pairs(gServer.clients) do	
			local_view.ID = client.ID		
			local view_dmp = serpent.dump(local_view)
			send(client, view_dmp)
		end	

		local message = nextmessage(gClient)
		while message do 
			gRemoteView = unpack(message)
			message = nextmessage(gClient)
		end

		if gRemoteView then
			local verts = deepcopy(SHIP_VERTS)
			for k,ship in pairs(gRemoteView.ships) do
				love.graphics.setColor(ship.color[1],ship.color[2],ship.color[3],ship.color[4])			
				for i = 1, 3 do
					verts.x[i] = (SHIP_VERTS.x[i]*math.cos(ship.angle)) - (SHIP_VERTS.y[i]*math.sin(ship.angle))
					verts.y[i] = (SHIP_VERTS.x[i]*math.sin(ship.angle)) + (SHIP_VERTS.y[i]*math.cos(ship.angle))
				end

				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)

				for k,v in pairs(ship.lines) do
					love.graphics.line(ship.position[1], ship.position[2], v[1], v[2])
				end

				love.graphics.setLineWidth(prevWidth)

				love.graphics.polygon("fill", 	verts.x[1]+ship.position[1],
												verts.y[1]+ship.position[2],
												verts.x[2]+ship.position[1],
												verts.y[2]+ship.position[2],
												verts.x[3]+ship.position[1],
												verts.y[3]+ship.position[2]  )

				love.graphics.circle("line", ship.position[1], ship.position[2], ship.radius)

				if ship.ID == gRemoteView.ID then
					Renderer:SetCameraPos(ship.position[1], ship.position[2])
				end
				--[[
				if false then -- draw velocity line
					love.graphics.setColor(255,0,0,255)
					love.graphics.line(ship.position.x, self.position.y,
						self.position.x + self.velocity.x * 2, self.position.y + self.velocity.y * 2)
				end	
				]]--		
			end

			for k,bullet in pairs(gRemoteView.bullets) do
				love.graphics.setColor(bullet.color[1],bullet.color[2],bullet.color[3],bullet.color[4])		
				love.graphics.rectangle("fill", bullet.position[1] - (bullet.size[1] * .5), bullet.position[2]- (bullet.size[2] * .5), BULLET_SIZE.x, BULLET_SIZE.y )	
			end
		end

	end)

end
