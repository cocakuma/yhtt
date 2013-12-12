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
require("server")
TUNING = require("tuning")

gClient = nil

local gRemoteView = nil
local gRemoteID = "0"

local gSimDt = 0
local gUpdateDt = 0
local gRenderDt = 0

ENT_ID = 0
function NextID()
	ENT_ID = ENT_ID + 1
	return ENT_ID
end	

function load()
	server_load()	
	gClient = startclient(getip(), getport())

	Renderer:Load()
end

paused = false

function love.keypressed(key)
	if key == "p" then
		paused = not paused
	end
	if key == "1" then

	elseif key == "2" then

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
	local pkg = beginpack()
	for k,v in pairs(input) do		
		if love.keyboard.isDown(k) then
			pkg = pack(pkg, k, 1)
		else
			pkg=pack(pkg, k, 0)
		end
	end
	pkg = endpack(pkg)
	send(gClient, pkg, 'input')
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
		ships[client.ID].input = input
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

function update( dt)	
	gSimDt = dt
	local start_time = socket.gettime()
	if paused then
		return
	end

	sendinput(gClient)
	updateserver(gServer)
	updateclient(gClient)	

	for i,client in pairs(gServer.clients) do
		receiveinput(client)		
	end		

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
			if circles_overlap(ship, obs) then
				ship:Collide(obs)
			end
		end
	end

	-- this is n^2 right now, yucky!
	for k, ship1 in pairs(ships) do
		for n, ship2 in pairs(ships) do
			if (n ~= k) then
				if circles_overlap(ship1, ship2) then
					ship1:Collide(ship2)
				end
			end
		end
		local oob = arena:OOB( ship1.position )
		if oob then
			local parent = ship1:GetTrueParent()
			parent:SetVelocities(ship1.velocity * -1)
			parent.position = ship1.position + oob + (parent.position - ship1.position)
			parent:ClampOffsets()
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
				if bullet.ship ~= ship and circles_overlap(bullet, ship) then
					ship:Hit(bullet)
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
	
	server_update()

	gUpdateDt = socket.gettime() - start_time
end

function draw()
	local start_time = socket.gettime()

	local id_message = nextmessage(gClient, 'ID')
	if id_message then
		gRemoteID = id_message
	end
	
	updateclient(gClient)		
	
	local message, remaining = nextmessage(gClient, 'view')
	while message do
		gRemoteView = unpack(1, message)
		message = nextmessage(gClient, 'view')
	end

	
	if gRemoteView then
		Renderer:Draw(function()		

			arena:Draw()

			for k,payload in pairs(gRemoteView.plds) do
				if payload.t == 0 then
					love.graphics.setColor(95,255,195,255)
				elseif payload.t == 1 then
					love.graphics.setColor(195,95,255,255)
				else
					love.graphics.setColor(255,255,255,255)
				end
				love.graphics.circle("fill", payload.x - (payload.r * .5), payload.y - (payload.r * .5), PAYLOAD_SIZE.rad, PAYLOAD_SIZE.segs )
				
				-- attachments
				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)
				for k,v in pairs(payload.l) do
					love.graphics.line(payload.x, payload.y, v.x, v.y)
				end
				love.graphics.setLineWidth(prevWidth)
			end

			for k,ship in pairs(gRemoteView.ships) do

				--team color
				if ship.t == 0 then
					love.graphics.setColor(55,255,155,255)
				else
					love.graphics.setColor(155,55,255,255)
				end

				--if ship.p == 1 then
					--love.graphics.setColor(55,255,155,255)
				--end
				
				-- the ship
				DrawTriangle(10, 6, ship.x, ship.y, ship.a)

				-- attachments
				local prevWidth = love.graphics.getLineWidth()
				love.graphics.setLineWidth(2)
				for k,v in pairs(ship.l) do
					love.graphics.line(ship.x, ship.y, v.x, v.y)
				end
				love.graphics.setLineWidth(prevWidth)

				-- shield
				if ship.h > 0 then
					love.graphics.setColor(ship.h*255,ship.h*255,255,255)
				else
					love.graphics.setColor(255,0,0,255)
				end
				love.graphics.circle("line", ship.x, ship.y, ship.r)
				
				-- thrusters
				if ship.it == 1 then -- TODO: detect whether or not a ship is thrusting!
					local flameLen = math.random()*0.8+0.2
					love.graphics.setColor(255,190,100,255)
					DrawTriangle(30*flameLen, 6, ship.x, ship.y, ship.a-math.pi, 15*flameLen+5, 0)
					love.graphics.setColor(255,255,255,255)
					DrawTriangle(20*flameLen, 4, ship.x, ship.y, ship.a-math.pi, 10*flameLen+5, 0)
				end

				if k == gRemoteID then
					Renderer:SetCameraPos(ship.x, ship.y)
				end
			end

			for k,bullet in pairs(gRemoteView.blts) do
				if bullet.t == 0 then
					love.graphics.setColor(155,255,155,255)
				else
					love.graphics.setColor(155,255,155,255)
				end
				DrawRectangle(8,3,bullet.x, bullet.y, bullet.a)
				local flameLen = math.random()*0.7+0.2
				love.graphics.setColor(255,190,100,255)
				DrawTriangle(15*flameLen, 3, bullet.x, bullet.y, bullet.a-math.pi, 7.2*flameLen+5, 0)
				love.graphics.setColor(255,255,255,255)
				DrawTriangle(10*flameLen, 2, bullet.x, bullet.y, bullet.a-math.pi, 5*flameLen+5, 0)				
			end

			for k,obstacle in pairs(gRemoteView.obs) do
				love.graphics.setColor(155,155,155,255)
				love.graphics.circle("fill", obstacle.x, obstacle.y, obstacle.r)				
			end
		end)
	end

	gRenderDt = socket.gettime() - start_time

	
	local remote_frame_id = 0
	if gRemoteView then
		remote_frame_id = gRemoteView.frame_id
	end
	local x = 1100
	local y = 50
	local y_delta = 15
	love.graphics.print("Frame Lag: "..gFrameID - remote_frame_id, x, y)	
	y = y + y_delta
	love.graphics.print("Sim Dt: "..gSimDt, x, y)	
	y = y + y_delta
	love.graphics.print("Update Dt: "..gUpdateDt, x, y)	
	y = y + y_delta
	love.graphics.print("Render Dt: "..gRenderDt, x, y)
	
	
end
