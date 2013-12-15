require("util/strict")
require("constants")
require("util/util")
require("util/mathutil")
require("ship")
require("payload")
require("goal")
require("obstacle")
require("render")
require("network")
require("arena")
require("gamestate")
TUNING = require("tuning")

gServer = nil


gFrameID = 0
gWorldPackage = nil

ENT_ID = 0
function NextID()
	ENT_ID = ENT_ID + 1
	return ENT_ID
end	

function receiveinput(client)
	local message = nextmessage(client, 'input')
	while message do
		print(message)
		local input = unpack(1, message)
		message = nextmessage(client, 'input')
		if bodies[input.cid] then
			client.ID = input.cid
		elseif client.ID == nil then
			local ship = Ship(0, 0, 0, 0)
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

	ResetGame(true)
end

function server_update(dt)
	local start_time = socket.gettime()

	for i,client in pairs(gServer.clients) do
		receiveinput(client)		
	end		

	-- pre-update
	-- check input and synchronize states
	if GAMESTATE.flow == FLOW.WARMUP then
		GAMESTATE.warmupTime = GAMESTATE.warmupTime - dt
		if GAMESTATE.warmupTime <= 0 then
			StartGame()
		end
	elseif GAMESTATE.flow == FLOW.WIN_0 or GAMESTATE.flow == FLOW.WIN_1 then
		GAMESTATE.warmupTime = GAMESTATE.warmupTime - dt
		if GAMESTATE.warmupTime <= 0 then
			ResetGame(true)
		end
	end


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

	for k, ptcl in pairs(particlesystems) do
		ptcl:Update(dt)
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
			local impactVel = body.velocity:Length()
			local parent = body:GetTrueParent()
			parent:SetVelocities(body.velocity * -1)
			parent.position = body.position + oob + (parent.position - body.position)
			parent:ClampOffsets()
			if body._classname == "Ship" then
				body:TakeDamage( impactVel * TUNING.DAMAGE.SHIP_ON_ROCK, arena )
			end
		end

		for n,otherbody in pairs(bodies) do
			if otherbody.ID > body.ID then -- only test each pair once
				if circles_overlap(body, otherbody) then
					body:Collide(otherbody)
					otherbody:Collide(body)
				end
			end
		end

		if body._classname == "Payload" then
			for n,goal in pairs(goals) do
				if goal:Contains(body.position) then
					ScoreAgainst(goal.team)
					body:Destroy()
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
					if not body.shielded then
						body:Hit(bullet)
						table.insert(bulletToRemove, bullet)
						hit = true
					else
						body:ShieldedHit(bullet)
					end
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

function ScoreAgainst(team)
	if team == 0 then
		team = 1
	else
		team = 0
	end

	GAMESTATE.points[team] = GAMESTATE.points[team] + 1
	print("Team",team,"scored a goal!")
	print("Score is now T0:",GAMESTATE.points[0],"to T1:",GAMESTATE.points[1],"out of",GAMESTATE.pointsToWin,"to win.")

	if GAMESTATE.points[0] == GAMESTATE.pointsToWin then
		EndGame(0)
	elseif GAMESTATE.points[1] == GAMESTATE.pointsToWin then
		EndGame(1)
	end
end

function EndGame(winningTeam)
	print("****\nGAME OVER! Team", winningTeam, "wins!\n****")
	if winningTeam == 0 then
		GAMESTATE.flow = FLOW.WIN_0
	else
		GAMESTATE.flow = FLOW.WIN_1
	end
	GAMESTATE.warmupTime = TUNING.GAME.VICTORY_TIME
end

function StartGame()
	print("****\nSTARTING A NEW GAME\n****")
	ResetGame(false)
end

function ResetGame(warmup)

	global("GAMESTATE")
	GAMESTATE = {
		flow = warmup and FLOW.WARMUP or FLOW.PLAYING,
		warmupTime = TUNING.GAME.WARMUP_TIME,
		pointsToWin = TUNING.GAME.POINTS_TO_WIN,
		points = {
			[0]=0,
			[1]=0
		},
	}

	global("arena")
	arena = nil
	global("bodies")
	bodies = {} --ships, payloads, etc
	global("to_respawn")
	to_respawn = {}
	global("bullets")
	bullets = {}
	global("obstacles")
	obstacles = {}
	global("goals")
	goals = {}
	global("particlesystems")
	particlesystems = {}

	gKillList = {}

	GenerateLevel()
end

function package_world()
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

	pkg = beginpacktable(pkg, 'goals')
	for k,body in pairs(goals) do
		pkg = beginpacktable(pkg, k)
		pkg = body:Pack(pkg)
		pkg = endpacktable(pkg)
	end
	pkg = endpacktable(pkg)

	gWorldPackage = endpack(pkg)	

	for i,client in pairs(gServer.clients) do
		client.has_world = false
	end
end

gPackageDT = 0
function package()
	local start_time = socket.gettime()
	local pkg = beginpack()

	pkg = beginpacktable(pkg,'game')
	pkg = pack(pkg, 'f', GAMESTATE.flow)
	pkg = pack(pkg, 't', GAMESTATE.warmupTime)
	pkg = pack(pkg, 's0', GAMESTATE.points[0])
	pkg = pack(pkg, 's1', GAMESTATE.points[1])
	pkg = pack(pkg, 'st', GAMESTATE.pointsToWin)
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg,'kills')
	for k,v in pairs(gKillList) do
		pkg = beginpacktable(pkg,k)
		pkg = pack(pkg, 'usr', v)
		pkg = endpacktable(pkg)
	end
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg, 'ptcl')
	for k,obs in pairs(particlesystems) do
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
	pkg = pack(pkg, 'fps', gFps)
	pkg = endpack(pkg)
	for i,client in pairs(gServer.clients) do
		if not client.has_world then
			send(client, gWorldPackage, 'world_view')
			client.has_world = true
		end
		send(client, pkg, 'view')
	end
	gPackageDT = socket.gettime() - start_time
end

function CountTeams()
	local num = 0
	for k,v in pairs(gServer.clients) do		
		num = num + 1
	end
	return num
end

function ScaleToFit()
	local numShips = CountTeams()
	local t = numShips/TUNING.GAME.MAX_SHIPS
	local arenaSize = round(lerp(TUNING.GAME.MIN_ARENA_SIZE, TUNING.GAME.MAX_ARENA_SIZE, t),0)
	local payloadMass = numShips * TUNING.GAME.PAYLOAD_MASS_FACTOR + TUNING.PAYLOAD.BASE_MASS
	local numObstacles = round(lerp(8, 20, t))
	return {sz = arenaSize, plm = payloadMass, obs = numObstacles}
end

function GenerateLevel()
	print('Generating Level.')
	local gen = ScaleToFit()
	print(gen.sz, gen.pts, gen.plm)

	TUNING.PAYLOAD.MASS = gen.plm
	
	arena = Arena(gen.sz, gen.sz)
	goals = {
		Goal(0, Vector2(20,arena.height/2), 40, 600),
		Goal(1, Vector2(arena.width-20,arena.height/2), 40, 600),
	}

	for i,client in pairs(gServer.clients) do
		Ship(0,0,0,0,client.ID)
	end		
	
	for i=1,GAMESTATE.pointsToWin*2 - 1 do
		local pl = Payload(arena.width/2, i*arena.height/(GAMESTATE.pointsToWin*2))
	end	

	local mirror = math.random() < 0.5
	for i=1,gen.obs do
		local rad = math.random()*100+40
		local x = (40+rad)+(math.random()*((arena.width/2)-80-rad-rad))
		local pos = Vector2(x, math.random()*arena.height)
		Obstacle(pos.x, pos.y, rad)
		Obstacle(arena.width-pos.x, (mirror and arena.height-pos.y or pos.y), rad)
	end

	package_world()
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

function love.keypressed(key)
	if key == 'f5' then
		ResetGame(false)
	elseif key == 'f9' then 
		gFps = gFps * 2
	elseif key == 'f10' then
		gFps = gFps / 2
	end
	gTickTime = 1 / gFps
end
