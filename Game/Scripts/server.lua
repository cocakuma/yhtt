require 'network'
require 'arena'

gServer = nil

arena = {}
ships = {}
bullets = {}
payloads = {}
obstacles = {}

gFrameID = 0

function server_load()
	gServer = startserver(getport())
	GenerateLevel()
end

function server_update()
	package()
	updateserver(gServer)
	gFrameID = gFrameID + 1
end

function package()
	local pkg = beginpack()

	pkg = beginpacktable(pkg, 'obs')
	for k,obs in pairs(obstacles) do
		pkg = beginpacktable(pkg, k)
		pkg = obs:Pack(pkg)
		pkg = endpacktable(pkg)
	end
	pkg = endpacktable(pkg)

	pkg = beginpacktable(pkg, 'ships')		
	for k,ship in pairs(ships) do
		pkg = beginpacktable(pkg, k)
		pkg = ship:Pack(pkg)
		pkg = endpacktable(pkg)
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
	for k,pl in pairs(payloads) do
		pkg = beginpacktable(pkg, k)
		pkg = pl:Pack(pkg)
		pkg = endpacktable(pkg)
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
		local pl = Payload(math.random() * 640, math.random() * 860)
		table.insert(payloads, pl)
	end	

	local mirror = math.random() < 0.5
	for i=1,10 do
		local pos = Vector2(math.random()*arena.width, math.random()*arena.height)
		local rad = math.random()*100+40
		Obstacle(pos.x, pos.y, rad)
		Obstacle(arena.width-pos.x, (mirror and arena.height-pos.y or pos.y), rad)
	end
end