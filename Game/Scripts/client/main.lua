require 'client'
require 'socket'

function love.load()
	client_load()
end

function love.update(dt)
	client_update(dt)
end

local last_tick = socket.gettime()
function love.draw()
	local tick_time = 1 / 30
	while socket.gettime() - last_tick < tick_time do	
		updateclient(gClient)		
	end
	last_tick = socket.gettime()
	client_draw()

	local x = 1100
	local y = 50
	local y_delta = 15
	love.graphics.print("Queued Frames: "..gQueuedFrames, x, y)
	y = y + y_delta	
	love.graphics.print("Render Dt: "..round3(gRenderDt), x, y)
	y = y + y_delta	
end
