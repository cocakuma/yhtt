require("util/strict")
require("constants")
require("util/util")
require("util/mathutil")
require("ship")
require("physics")
require("payload")
require("obstacle")
require("render")
require("network")
require("arena")
require("input")
TUNING = require("tuning")

gServer = nil

arena = nil
bodies = {} --ships, payloads, etc
to_respawn = {}
bullets = {}
obstacles = {}

gFrameID = 0

ENT_ID = 0
function NextID()
	ENT_ID = ENT_ID + 1
	return ENT_ID
end	

function receiveinput(client)
	local message = nextmessage(client, 'input')
	while message do
		local input = unpack(1, message)
		message = nextmessage(client, 'input')
		if not client.ID then
			local ship = Ship(10, 10, 0)
			client.ID = ship.ID	
			send(client, tostring(client.ID), 'ID')
		end
		if bodies[client.ID] then
			bodies[client.ID].input = input
		end
	end	
end

function server_load()
	gIsServer = true
	gServer = startserver(getport())
	GenerateLevel()
end

function server_update(dt)
	local start_time = socket.gettime()

	for i,client in pairs(gServer.clients) do
		receiveinput(client)		
	end		

	-- pre-update
	-- check input and synchronize states
	for k,info in pairs(to_respawn) do
		info.ship:TryRespawn(dt)
	end

	for k,ship in pairs(bodies) do
		if ship.HandleInput then
			ship:HandleInput()
		end
	end

	-- update
	-- handle input, apply physics, gameplay
	for k,body in pairs(bodies) do
		body:Update(dt)
	end

	for k,bullet in pairs(bullets) do
		bullet:Update(dt)
	end

	-- post-update
	-- perform collisions, spawn/despawn entities
	for k,body in pairs(bodies) do
		for n,obs in pairs(obstacles) do
			if circles_overlap(body, obs) then
				body:Collide(obs)
			end
		end
		local oob = arena:OOB( body.position )
		if oob then
			local parent = body:GetTrueParent()
			parent:SetVelocities(body.velocity * -1)
			parent.position = body.position + oob + (parent.position - body.position)
			parent:ClampOffsets()
		end

		for n,otherbody in pairs(bodies) do
			if otherbody.ID > body.ID then -- only test each pair once
				if circles_overlap(body, otherbody) then
					body:Collide(otherbody)
					otherbody:Collide(body)
				end
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
			for k, body in pairs(bodies) do
				if bullet.ship ~= body and bullet.ship.team ~= body.team and circles_overlap(bullet, body) then
					body:Hit(bullet)
					table.insert(bulletToRemove, bullet)
					hit = true
				end
			end
		end

		if not hit then
			for n,obs in pairs(obstacles) do
				if circles_overlap(bullet, obs) then
					table.insert(bulletToRemove, bullet)
					hit = true
				end
			end
		end
	end

	for i,b in pairs(bulletToRemove) do
		b:Destroy()
	end


	package()
	updateserver(gServer)
	gFrameID = gFrameID + 1
end

function package()
	local pkg = beginpack()

	pkg = beginpacktable(pkg,'arena')
	pkg = arena:Pack(pkg)
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg, 'obs')
	for k,obs in pairs(obstacles) do
		pkg = beginpacktable(pkg, k)
		pkg = obs:Pack(pkg)
		pkg = endpacktable(pkg)
	end
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg, 'ships')		
	for k,body in pairs(bodies) do
		if body._classname == "Ship" then
			pkg = beginpacktable(pkg, k)
			pkg = body:Pack(pkg)
			pkg = endpacktable(pkg)
		end
	end
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg, 'blts')
	for k,bullet in pairs(bullets) do
		pkg = beginpacktable(pkg, k)
		pkg = bullet:Pack(pkg)
		pkg = endpacktable(pkg)
	end
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg, 'plds')
	for k,body in pairs(bodies) do
		if body._classname == "Payload" then
			pkg = beginpacktable(pkg, k)
			pkg = body:Pack(pkg)
			pkg = endpacktable(pkg)
		end
	end
	pkg = endpacktable(pkg)

	pkg = pack(pkg, 'frame_id', gFrameID)
	pkg = endpack(pkg)
	for i,client in pairs(gServer.clients) do
		send(client, pkg, 'view')
	end
end

function GenerateLevel()
	print('Generating Level.')

	arena = Arena(1600, 1600)

	for i=1,32 do
		local ship = Ship(100+20*i, 100, 0)
		ship.input = defaultinput()
	end

	for i=1,3 do
		local pl = Payload(arena.width/2, i*arena.height/4)
	end	

	local mirror = math.random() < 0.5
	for i=1,10 do
		local pos = Vector2(math.random()*arena.width, math.random()*arena.height)
		local rad = math.random()*100+40
		Obstacle(pos.x, pos.y, rad)
		Obstacle(arena.width-pos.x, (mirror and arena.height-pos.y or pos.y), rad)
	end
end

function circles_overlap(a, b)
	local r_total = a.radius + b.radius
	local delta_x = math.abs(a.position.x - b.position.x)
	if delta_x > r_total then
		return false
	end
	local delta_y = math.abs(a.position.y - b.position.y)
	if delta_y > r_total then
		return false
	end
	local r_total_sq = r_total * r_total
	local dist_sq = delta_x * delta_x + delta_y * delta_y
	return dist_sq <= r_total_sq
end
