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
TUNING = require("tuning")

gClient = nil

local gRemoteView = nil
local gRemoteID = "0"

local gRenderDt = 0

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

function client_draw()
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
	love.graphics.print("Render Dt: "..gRenderDt, x, y)
end

function client_load()
	gClient = startclient(getip(), getport())
	Renderer:Load()	
end

function client_update()
	sendinput(gClient)
	updateclient(gClient)	
end
