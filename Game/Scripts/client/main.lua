require 'client'
require 'socket'

function love.load()
	client_load()
end

function love.update(dt)
	client_update(dt)
end

local gDt = 0
local tick_time = 1 / 30
local last_tick = socket.gettime()
function love.draw()	
	while socket.gettime() - last_tick < tick_time do	
		updateclient(gClient)		
	end
	local this_tick = socket.gettime()
	gDt = this_tick - last_tick
	last_tick = this_tick
	client_draw()

	local x = 1100
	local y = 50
	local y_delta = 20
	love.graphics.print("Tick: "..round3(tick_time), x, y)
	y = y + y_delta
	love.graphics.print("DT: "..round3(gDt), x, y)
	y = y + y_delta
	love.graphics.print("Queued Frames: "..gQueuedFrames, x, y)
	y = y + y_delta	
	love.graphics.print("Render: "..round3(gRenderDt), x, y)
	y = y + y_delta	
end
