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
require("input")
TUNING = require("tuning")

gClient = nil

local gRemoteView = nil
local gRemoteID = "0"

local gRenderDt = 0

paused = false

local useMouse = false

function love.keypressed(key)
	if key == "p" then
		paused = not paused
	end
	if key == "w" then
		useMouse = false
	end
end

function love.mousepressed()
	useMouse = true
end

function sendinput(client)
	local input = defaultinput(useMouse)
	local pkg = beginpack()
	for k,v in pairs(input) do		
		if love.keyboard.isDown(k) then
			pkg = pack(pkg, k, 1)
		else
			pkg=pack(pkg, k, 0)
		end
	end

	pkg = pack(pkg, 'm', useMouse and 1 or 0)
	
	if useMouse then
		pkg = pack(pkg, 'm_x', love.mouse.getX())
		pkg = pack(pkg, 'm_y', love.mouse.getY())
		pkg = pack(pkg, 'm_r', love.mouse.isDown("r") and 1 or 0)
		pkg = pack(pkg, 'm_l', love.mouse.isDown("l") and 1 or 0)
	end

	pkg = endpack(pkg)
	send(client, pkg, 'input')
end

function client_draw()
	local start_time = socket.gettime()

	local id_message = nextmessage(gClient, 'ID')
	if id_message and gRemoteID == "0" then
		gRemoteID = id_message
	end
	
	updateclient(gClient)		
	
	local message, remaining = nextmessage(gClient, 'view')

	while remaining > 3 do		
		message, remaining = nextmessage(gClient, 'view')
	end

	if message then
		gRemoteView = unpack(1, message)
	end

	
	if gRemoteView then
		Renderer:Draw(function()		

			local arena = gRemoteView.arena
			love.graphics.setColor(125,55,55,255)
			local thickness = 5
			love.graphics.rectangle("fill", -thickness, -thickness, thickness, arena.h + thickness*2)
			love.graphics.rectangle("fill", -thickness, -thickness, arena.w + thickness*2, thickness)
			love.graphics.rectangle("fill", -thickness, arena.h, arena.w + thickness*2, thickness)
			love.graphics.rectangle("fill", arena.w, -thickness, thickness, arena.h + thickness*2)

			for k,payload in pairs(gRemoteView.plds) do
				if payload.t == 0 then
					love.graphics.setColor(95,255,195,255)
				elseif payload.t == 1 then
					love.graphics.setColor(195,95,255,255)
				else
					love.graphics.setColor(255,255,255,255)
				end
				love.graphics.circle("fill", payload.x, payload.y, PAYLOAD_SIZE.rad, PAYLOAD_SIZE.segs )
				
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

				if k == gRemoteID then
					love.graphics.setLineWidth(2)
				end
				love.graphics.circle("line", ship.x, ship.y, ship.r)
				love.graphics.setLineWidth(prevWidth)
				
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
					love.graphics.setColor(55,255,155,255)
				else
					love.graphics.setColor(155,55,255,255)
				end
				DrawRectangle(5,2,bullet.x, bullet.y, bullet.a)
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
	love.graphics.print("Render Dt: "..gRenderDt, x, y)
	y = y + y_delta

end

function client_load()
	gClient = startclient(getip(), getport())
	Renderer:Load()	
end

function client_update()
	sendinput(gClient)
	updateclient(gClient)	
end
